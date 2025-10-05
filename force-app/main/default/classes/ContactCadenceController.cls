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
        @AuraEnabled public String formattedDueDate { get; set; }
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

        // Query the parent case with record type validation
        Case parentCase = [
            SELECT Id, RecordType.DeveloperName, Type, Contact_Established__c,
                   Contact_Attempt_Count__c, Status
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

        cadenceData.isValidRecordType = true;
        cadenceData.contactEstablished = parentCase.Contact_Established__c;
        cadenceData.caseStatus = parentCase.Status;
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
                // Mark as completed if task is closed, regardless of whether contact was established
                // This makes Attempts 1-2 read-only even if they had negative outcomes
                attemptData.isCompleted = t.IsClosed;
                attemptData.statusLabel = t.Status;
                attemptData.formattedDueDate = t.ActivityDate != null
                    ? t.ActivityDate.format()
                    : '';

                // Determine current vs pending vs completed
                if (t.IsClosed) {
                    // Completed attempts are never editable (read-only)
                    attemptData.isCurrent = false;
                    attemptData.isPending = false;
                } else {
                    // Uncompleted task - is it the first incomplete?
                    // Only the first incomplete attempt is editable
                    attemptData.isCurrent = (i == firstIncompleteAttempt);
                    attemptData.isPending = (i > firstIncompleteAttempt);
                }
            } else {
                // No task created yet
                attemptData.taskRecord = null;
                attemptData.isCompleted = false;
                // If this is the first incomplete, make it current (editable)
                attemptData.isCurrent = (i == firstIncompleteAttempt);
                attemptData.isPending = (i > firstIncompleteAttempt);
                attemptData.statusLabel = attemptData.isCurrent ? 'Ready' : 'Not Scheduled';
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

            // Create ContentNote if notes were provided
            if (String.isNotBlank(notes)) {
                createContactAttemptNote(caseId, attemptNumber, contactEstablished, notes);
            }

            // Update parent case based on outcome
            Case parentCase = [
                SELECT Id, Contact_Established__c, Contact_Established_Date__c,
                       Contact_Attempt_Count__c, Next_Contact_Due__c, Next_Task_Scheduled_At__c
                FROM Case
                WHERE Id = :caseId
                LIMIT 1
            ];

            Boolean needsCaseUpdate = false;

            if (contactEstablished) {
                // Contact established - stop cadence
                if (!parentCase.Contact_Established__c) {
                    parentCase.Contact_Established__c = true;
                    parentCase.Contact_Established_Date__c = DateTime.now();
                    parentCase.Next_Task_Scheduled_At__c = null; // Clear any pending task
                    needsCaseUpdate = true;
                }
            } else if (attemptNumber < 5) {
                // Negative outcome and not last attempt
                // Next attempt is immediately available in UI (via LWC state)
                // But actual Task record will be created 2 minutes later by scheduled flow
                // This gives agent time to correct mistakes

                parentCase.Next_Task_Scheduled_At__c = DateTime.now().addMinutes(2);
                needsCaseUpdate = true;
            }

            if (needsCaseUpdate) {
                update parentCase;
            }

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
}
