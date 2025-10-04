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

        // Query the parent case for contact established status
        Case parentCase = [
            SELECT Id, Contact_Established__c, Contact_Attempt_Count__c, Status
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

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

                // Determine current vs pending vs completed
                if (t.IsClosed) {
                    attemptData.isCurrent = false;
                    attemptData.isPending = false;
                } else {
                    // Uncompleted task - is it current or pending?
                    attemptData.isCurrent = (i == currentAttempt);
                    attemptData.isPending = (i > currentAttempt);
                }
            } else {
                // No task created yet - must be pending
                attemptData.taskRecord = null;
                attemptData.isCompleted = false;
                attemptData.isCurrent = false;
                attemptData.isPending = true;
                attemptData.statusLabel = 'Not Scheduled';
            }

            cadenceData.attempts.add(attemptData);
        }

        return cadenceData;
    }

    /**
     * Save the outcome of a contact attempt
     *
     * @param taskId - ID of the task being updated
     * @param contactEstablished - Whether contact was successfully established
     * @param notes - Agent notes about the attempt
     * @return Success message or error
     */
    @AuraEnabled
    public static String saveAttemptOutcome(Id taskId, Boolean contactEstablished, String notes) {
        try {
            // Query the task and parent case
            Task attemptTask = [
                SELECT Id, WhatId, Status, Succession_Contact_Established__c, Description
                FROM Task
                WHERE Id = :taskId
                LIMIT 1
            ];

            // Update task
            attemptTask.Status = 'Completed';
            attemptTask.Succession_Contact_Established__c = contactEstablished;

            // Append notes to existing description
            if (String.isNotBlank(notes)) {
                String timestamp = DateTime.now().format('yyyy-MM-dd HH:mm');
                String newNote = '[' + timestamp + '] ' + notes;

                if (String.isNotBlank(attemptTask.Description)) {
                    attemptTask.Description += '\n\n' + newNote;
                } else {
                    attemptTask.Description = newNote;
                }
            }

            update attemptTask;

            // If contact was established, update parent case
            // (This will trigger Task_Succession_Contact_Update flow, but we'll also update directly)
            if (contactEstablished && attemptTask.WhatId != null) {
                Case parentCase = [
                    SELECT Id, Contact_Established__c, Contact_Established_Date__c
                    FROM Case
                    WHERE Id = :attemptTask.WhatId
                    LIMIT 1
                ];

                if (!parentCase.Contact_Established__c) {
                    parentCase.Contact_Established__c = true;
                    parentCase.Contact_Established_Date__c = DateTime.now();
                    update parentCase;
                }
            }

            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException('Error saving outcome: ' + e.getMessage());
        }
    }
}
