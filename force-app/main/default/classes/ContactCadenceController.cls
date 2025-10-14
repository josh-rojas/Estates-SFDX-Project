/**
 * ContactCadenceController
 *
 * Apex controller for successionContactCadence LWC component.
 * Provides methods for retrieving contact attempt tasks and saving outcomes.
 *
 * @author Claude Code
 * @date 2025-10-02
 */
public with sharing class ContactCadenceController {

    /**
     * Wrapper class for task data with computed properties
     */
    public class TaskAttemptData {
        @AuraEnabled public Task taskRecord { get; set; }
        @AuraEnabled public Integer attemptNumber { get; set; }
        @AuraEnabled public String attemptLabel { get; set; }
        @AuraEnabled public String dayLabel { get; set; }
        @AuraEnabled public String statusLabel { get; set; }
        @AuraEnabled public Boolean isCompleted { get; set; }
        @AuraEnabled public Boolean isCurrent { get; set; }
        @AuraEnabled public Boolean isPending { get; set; }
        @AuraEnabled public Boolean isLocked { get; set; }  // Task exists but date hasn't arrived
        @AuraEnabled public String formattedDueDate { get; set; }
        @AuraEnabled public Integer daysUntilAvailable { get; set; }  // Days until task can be completed
        @AuraEnabled public String countdownText { get; set; }  // Human-readable countdown
    }

    /**
     * Wrapper class for contact cadence data
     */
    public class ContactCadenceData {
        @AuraEnabled public Boolean isValidRecordType { get; set; }
        @AuraEnabled public String invalidRecordTypeMessage { get; set; }
        @AuraEnabled public List<TaskAttemptData> attempts { get; set; }
        @AuraEnabled public Integer currentAttemptNumber { get; set; }
        @AuraEnabled public Integer totalAttempts { get; set; }
        @AuraEnabled public Boolean contactEstablished { get; set; }
        @AuraEnabled public String caseStatus { get; set; }
        @AuraEnabled public Id contactId { get; set; }  // Contact ID for Business Account + Contact model
        @AuraEnabled public Id accountId { get; set; }  // Account ID (used for Person Accounts)
        @AuraEnabled public Boolean isPersonAccount { get; set; }  // True if Case.Account is Person Account

        // Email validation fields
        @AuraEnabled public String emailAddress { get; set; }  // The actual email address
        @AuraEnabled public Boolean hasEmail { get; set; }  // True if email exists and is not blank
        @AuraEnabled public Boolean hasValidEmailFormat { get; set; }  // True if email format is valid
        @AuraEnabled public Boolean hasOptedOut { get; set; }  // True if recipient opted out of email
        @AuraEnabled public String emailWarning { get; set; }  // Warning message about email issues
    }

    /**
     * Retrieve contact attempt tasks for a succession case
     *
     * @param caseId - ID of the succession case
     * @return ContactCadenceData with tasks and metadata
     */
    @AuraEnabled(cacheable=true)
    public static ContactCadenceData getContactCadence(Id caseId) {
        ContactCadenceData cadenceData = new ContactCadenceData();
        cadenceData.attempts = new List<TaskAttemptData>();

        // Query the parent case with record type validation and email fields
        Case parentCase = [
            SELECT Id, RecordType.DeveloperName, Type, Contact_Established__c,
                   Contact_Attempt_Count__c, Status, ContactId, AccountId,
                   Account.IsPersonAccount, Account.PersonEmail, Account.HasOptedOutOfEmail,
                   Contact.Email, Contact.HasOptedOutOfEmail
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        // Validate record type
        if (parentCase.RecordType.DeveloperName != 'EstateAdministration') {
            cadenceData.isValidRecordType = false;
            cadenceData.invalidRecordTypeMessage =
                'This component is only available for Estate Administration cases.';
            return cadenceData;
        }

        // Validate case type
        if (parentCase.Type != 'Succession Management' &&
            parentCase.Type != 'Named Successor Enactment') {
            cadenceData.isValidRecordType = false;
            cadenceData.invalidRecordTypeMessage =
                'This component is only available for Succession Management or Named Successor Enactment cases.';
            return cadenceData;
        }

        // Validate Case has an Account (required for email functionality)
        if (parentCase.AccountId == null) {
            cadenceData.isValidRecordType = false;
            cadenceData.invalidRecordTypeMessage =
                'This case does not have an associated Account. Please assign an Account to enable email functionality.';
            return cadenceData;
        }

        cadenceData.isValidRecordType = true;
        cadenceData.contactEstablished = parentCase.Contact_Established__c;
        cadenceData.caseStatus = parentCase.Status;
        cadenceData.contactId = parentCase.ContactId;  // For Business Account + Contact model
        cadenceData.accountId = parentCase.AccountId;  // For Person Account model

        // Safely check if Account is Person Account (null-safe)
        cadenceData.isPersonAccount = (parentCase.Account != null && parentCase.Account.IsPersonAccount);

        // CRITICAL: Validate email existence and opt-out status
        validateEmailAddress(parentCase, cadenceData);

        cadenceData.totalAttempts = 5; // BRD defines 5-attempt cadence

        // Query all contact attempt tasks
        List<Task> attemptTasks = [
            SELECT Id, Subject, Status, ActivityDate, Description,
                   Contact_Attempt_Number__c, Succession_Contact_Established__c,
                   IsClosed, CompletedDateTime
            FROM Task
            WHERE WhatId = :caseId
              AND Contact_Attempt_Number__c != NULL
            ORDER BY Contact_Attempt_Number__c ASC
        ];

        // Map tasks to attempt numbers (1-5)
        Map<Integer, Task> tasksByAttempt = new Map<Integer, Task>();
        for (Task t : attemptTasks) {
            Integer attemptNum = Integer.valueOf(t.Contact_Attempt_Number__c);
            tasksByAttempt.put(attemptNum, t);
        }

        // Build attempt data for all 5 attempts
        Integer currentAttempt = parentCase.Contact_Attempt_Count__c != null
            ? Integer.valueOf(parentCase.Contact_Attempt_Count__c)
            : 0;

        cadenceData.currentAttemptNumber = currentAttempt;

        // Map attempt numbers to BRD day labels
        Map<Integer, String> attemptDays = new Map<Integer, String>{
            1 => 'Day 0',
            2 => 'Day 5',
            3 => 'Day 35',
            4 => 'Day 65',
            5 => 'Day 95'
        };

        // Find first incomplete attempt (this will be the ONLY editable attempt)
        // Previous attempts are read-only even if contact wasn't established (negative outcome)
        // This prevents users from re-editing completed attempts and maintains sequential workflow
        Integer firstIncompleteAttempt = null;
        if (!parentCase.Contact_Established__c) {
            for (Integer i = 1; i <= 5; i++) {
                // Check if task is closed (Status='Completed'), regardless of outcome
                if (!tasksByAttempt.containsKey(i) || !tasksByAttempt.get(i).IsClosed) {
                    firstIncompleteAttempt = i;
                    break;
                }
            }
        }

        for (Integer i = 1; i <= 5; i++) {
            TaskAttemptData attemptData = new TaskAttemptData();
            attemptData.attemptNumber = i;
            attemptData.attemptLabel = 'Attempt ' + i;
            attemptData.dayLabel = attemptDays.get(i);

            // Check if task exists for this attempt
            if (tasksByAttempt.containsKey(i)) {
                Task t = tasksByAttempt.get(i);
                attemptData.taskRecord = t;
                attemptData.isCompleted = t.IsClosed;
                attemptData.statusLabel = t.Status;
                attemptData.formattedDueDate = t.ActivityDate != null
                    ? t.ActivityDate.format()
                    : '';

                // Date-gating logic: Check if task's ActivityDate has arrived
                Date today = Date.today();
                Boolean dateHasArrived = (t.ActivityDate != null && t.ActivityDate <= today);

                // Calculate days until available (if not yet arrived)
                if (!dateHasArrived && t.ActivityDate != null) {
                    Integer daysRemaining = today.daysBetween(t.ActivityDate);
                    attemptData.daysUntilAvailable = daysRemaining;
                    attemptData.countdownText = 'Available in ' + daysRemaining + ' day' + (daysRemaining == 1 ? '' : 's');
                } else {
                    attemptData.daysUntilAvailable = 0;
                    attemptData.countdownText = '';
                }

                // Determine current vs locked vs pending vs completed
                if (t.IsClosed) {
                    // Completed attempts are never editable (read-only)
                    attemptData.isCompleted = true;
                    attemptData.isCurrent = false;
                    attemptData.isPending = false;
                    attemptData.isLocked = false;
                } else if (i == firstIncompleteAttempt) {
                    // This is the first incomplete attempt
                    if (dateHasArrived) {
                        // Date has arrived - agent can complete
                        attemptData.isCurrent = true;
                        attemptData.isLocked = false;
                        attemptData.isPending = false;
                    } else {
                        // Date hasn't arrived yet - task is locked
                        attemptData.isCurrent = false;
                        attemptData.isLocked = true;
                        attemptData.isPending = false;
                    }
                } else {
                    // Future attempts (not first incomplete)
                    attemptData.isCurrent = false;
                    attemptData.isPending = true;
                    attemptData.isLocked = false;
                }
            } else {
                // No task created yet - waiting for previous attempt to complete
                attemptData.taskRecord = null;
                attemptData.isCompleted = false;
                attemptData.isCurrent = false;
                attemptData.isPending = true;
                attemptData.isLocked = false;
                attemptData.statusLabel = 'Waiting for Previous Attempt';
                attemptData.countdownText = 'Complete previous attempts first';
                attemptData.daysUntilAvailable = null;
            }

            cadenceData.attempts.add(attemptData);
        }

        return cadenceData;
    }

    /**
     * Save the outcome of a contact attempt
     *
     * @param caseId - ID of the parent case
     * @param taskId - ID of the task being updated (null if creating new)
     * @param attemptNumber - Attempt number (1-5)
     * @param contactEstablished - Whether contact was successfully established
     * @param notes - Agent notes about the attempt
     * @return Success message or error
     */
    @AuraEnabled
    public static String saveAttemptOutcome(
        Id caseId,
        Id taskId,
        Integer attemptNumber,
        Boolean contactEstablished,
        String notes
    ) {
        try {
            Task attemptTask;

            // If taskId is null, create new task immediately (agent is recording outcome)
            if (taskId == null) {
                attemptTask = new Task(
                    WhatId = caseId,
                    Subject = 'Succession Contact Attempt ' + attemptNumber,
                    Contact_Attempt_Number__c = attemptNumber,
                    Status = 'Completed',
                    Succession_Contact_Established__c = contactEstablished,
                    ActivityDate = Date.today()
                );
            } else {
                // Query existing task
                attemptTask = [
                    SELECT Id, WhatId, Status, Succession_Contact_Established__c, Description
                    FROM Task
                    WHERE Id = :taskId
                    LIMIT 1
                ];

                // Update task
                attemptTask.Status = 'Completed';
                attemptTask.Succession_Contact_Established__c = contactEstablished;
            }

            // Add/append notes
            if (String.isNotBlank(notes)) {
                String timestamp = DateTime.now().format('yyyy-MM-dd HH:mm');
                String newNote = '[' + timestamp + '] ' + notes;

                if (String.isNotBlank(attemptTask.Description)) {
                    attemptTask.Description += '\n\n' + newNote;
                } else {
                    attemptTask.Description = newNote;
                }
            }

            upsert attemptTask;

            // Create ContentNote and Chatter post if notes were provided
            if (String.isNotBlank(notes)) {
                createContactAttemptNote(caseId, attemptNumber, contactEstablished, notes);
                createChatterPost(caseId, attemptNumber, contactEstablished, notes);
            }

            // Update parent case based on outcome
            Case parentCase = [
                SELECT Id, Contact_Established__c, Contact_Established_Date__c,
                       Contact_Attempt_Count__c
                FROM Case
                WHERE Id = :caseId
                LIMIT 1
            ];

            // If contact established, update case
            // Task_Succession_Contact_Update flow will handle this too, but we update here for immediate feedback
            if (contactEstablished && !parentCase.Contact_Established__c) {
                parentCase.Contact_Established__c = true;
                parentCase.Contact_Established_Date__c = DateTime.now();
                update parentCase;
            }

            // Flow Task_Create_Next_Contact_Attempt will auto-create next task when this task completes
            // No manual intervention needed

            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException('Error saving outcome: ' + e.getMessage());
        }
    }

    /**
     * Create a ContentNote record for the contact attempt
     *
     * @param caseId - Case record ID
     * @param attemptNumber - Attempt number (1-5)
     * @param contactEstablished - Whether contact was established
     * @param noteContent - Note content
     */
    private static void createContactAttemptNote(
        Id caseId,
        Integer attemptNumber,
        Boolean contactEstablished,
        String noteContent
    ) {
        // Format timestamp for note title and content
        DateTime now = DateTime.now();
        String formattedDate = now.format('yyyy-MM-dd HH:mm:ss');
        String dateOnly = now.format('yyyy-MM-dd');

        // Determine outcome label
        String outcomeLabel = contactEstablished ? 'Contact Established' : 'Contact Not Established';

        // Create note title
        String noteTitle = 'Succession Contact Attempt ' + attemptNumber + ' - ' + dateOnly;

        // Create note body with structured format
        String noteBody = '========================================\n';
        noteBody += 'SUCCESSION CONTACT ATTEMPT #' + attemptNumber + '\n';
        noteBody += '========================================\n\n';
        noteBody += 'Date/Time: ' + formattedDate + '\n';
        noteBody += 'Outcome: ' + outcomeLabel + '\n\n';
        noteBody += '----------------------------------------\n';
        noteBody += 'NOTES:\n';
        noteBody += '----------------------------------------\n\n';
        noteBody += noteContent;

        // Create ContentNote
        ContentNote note = new ContentNote();
        note.Title = noteTitle;
        note.Content = Blob.valueOf(noteBody);
        insert note;

        // Link note to Case
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentNote WHERE Id = :note.Id].ContentDocumentId;
        cdl.LinkedEntityId = caseId;
        cdl.ShareType = 'V'; // Viewer permission
        cdl.Visibility = 'AllUsers'; // Visible to all users with access to the record
        insert cdl;
    }

    /**
     * Create a Chatter post on the Case for the contact attempt
     *
     * @param caseId - Case record ID
     * @param attemptNumber - Attempt number (1-5)
     * @param contactEstablished - Whether contact was established
     * @param noteContent - Note content
     */
    private static void createChatterPost(
        Id caseId,
        Integer attemptNumber,
        Boolean contactEstablished,
        String noteContent
    ) {
        // Format timestamp and outcome
        DateTime now = DateTime.now();
        String formattedDateTime = now.format('MM/dd/yyyy HH:mm');
        String outcomeEmoji = contactEstablished ? '✅' : '❌';
        String outcomeText = contactEstablished ? 'Contact Established' : 'Contact Not Established';

        // Build Chatter post body
        String postBody = String.format(
            '{0} Succession Contact Attempt {1}\n\n' +
            'Time: {2}\n' +
            'Outcome: {3}\n\n' +
            'Agent Notes:\n{4}',
            new List<String>{
                outcomeEmoji,
                String.valueOf(attemptNumber),
                formattedDateTime,
                outcomeText,
                noteContent
            }
        );

        // Create FeedItem (Chatter post)
        FeedItem post = new FeedItem();
        post.ParentId = caseId;
        post.Body = postBody;
        post.Type = 'TextPost';
        insert post;
    }

    /**
     * Validate email address existence, format, and opt-out status
     *
     * @param parentCase - Case record with Account and Contact relationships
     * @param cadenceData - ContactCadenceData to populate with email validation results
     */
    private static void validateEmailAddress(Case parentCase, ContactCadenceData cadenceData) {
        String email = null;
        Boolean optedOut = false;

        // Determine email address based on account type
        if (cadenceData.isPersonAccount && parentCase.Account != null) {
            // Person Account: use PersonEmail field
            email = parentCase.Account.PersonEmail;
            optedOut = parentCase.Account.HasOptedOutOfEmail == true;
        } else if (!cadenceData.isPersonAccount && parentCase.Contact != null) {
            // Business Account: use Contact.Email field
            email = parentCase.Contact.Email;
            optedOut = parentCase.Contact.HasOptedOutOfEmail == true;
        }

        // Check if email exists and is not blank
        cadenceData.hasEmail = String.isNotBlank(email);
        cadenceData.emailAddress = email;
        cadenceData.hasOptedOut = optedOut;

        // Validate email format using regex (basic RFC 5322 pattern)
        // Pattern matches: local-part@domain.tld
        if (cadenceData.hasEmail) {
            String emailPattern = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$';
            cadenceData.hasValidEmailFormat = Pattern.matches(emailPattern, email);
        } else {
            cadenceData.hasValidEmailFormat = false;
        }

        // Build warning message for UI
        List<String> warnings = new List<String>();

        if (optedOut) {
            warnings.add('⚠️ Successor has opted out of email. Contact by phone only.');
        }

        if (!cadenceData.hasEmail) {
            warnings.add('No email address on file for this successor.');
        } else if (!cadenceData.hasValidEmailFormat) {
            warnings.add('Email address format appears invalid: ' + email);
        }

        // Set warning message (null if no issues)
        cadenceData.emailWarning = warnings.isEmpty() ? null : String.join(warnings, ' ');
    }
}
