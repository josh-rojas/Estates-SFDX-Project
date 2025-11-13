/**
 * SuccessionTaskCreator
 *
 * Invocable Apex class for creating succession contact attempt tasks from flows.
 * Provides reusable task creation logic for flow-based task creation (flows are Inactive in production).
 *
 * USAGE: Call from Flow using "Create Contact Attempt Task" action
 *
 * @author Claude Code
 * @date 2025-10-27
 */
public with sharing class SuccessionTaskCreator {
  /**
   * Request wrapper for flow inputs
   */
  public class CreateTaskRequest {
    @InvocableVariable(
      label='Case ID'
      description='ID of the parent Case'
      required=true
    )
    public Id caseId;

    @InvocableVariable(
      label='Attempt Number'
      description='Contact attempt number (1-5)'
      required=true
    )
    public Integer attemptNumber;

    @InvocableVariable(
      label='Days Offset'
      description='Number of days from case creation (0, 5, 35, 65, or 95)'
      required=true
    )
    public Integer daysOffset;

    @InvocableVariable(
      label='Case Created Date'
      description='Case.CreatedDate for calculating ActivityDate'
      required=true
    )
    public DateTime caseCreatedDate;
  }

  /**
   * Response wrapper for flow outputs
   */
  public class CreateTaskResponse {
    @InvocableVariable(
      label='Task Created'
      description='True if task was created, false if skipped (already exists)'
    )
    public Boolean taskCreated;

    @InvocableVariable(
      label='Task ID'
      description='ID of created task (null if skipped)'
    )
    public Id taskId;

    @InvocableVariable(label='Message' description='Status message')
    public String message;
  }

  /**
   * Create contact attempt task if it doesn't already exist
   * Invocable method callable from flows
   *
   * @param requests List of task creation requests (supports bulk)
   * @return List of responses indicating success/skip
   */
  @InvocableMethod(
    label='Create Contact Attempt Task'
    description='Creates a succession contact attempt task if it does not already exist. Includes duplicate prevention.'
    category='Succession Management'
  )
  public static List<CreateTaskResponse> createContactAttemptTasks(
    List<CreateTaskRequest> requests
  ) {
    List<CreateTaskResponse> responses = new List<CreateTaskResponse>();

    // Collect all case IDs and attempt numbers for bulk queries
    Set<Id> caseIds = new Set<Id>();
    Map<String, CreateTaskRequest> requestMap = new Map<String, CreateTaskRequest>();

    for (CreateTaskRequest req : requests) {
      caseIds.add(req.caseId);
      String key = req.caseId + '_' + req.attemptNumber;
      requestMap.put(key, req);
    }

    // Query existing tasks in bulk (duplicate prevention)
    Map<String, Task> existingTasks = queryExistingTasks(caseIds, requestMap);

    // Process each request
    List<Task> tasksToCreate = new List<Task>();
    Map<String, CreateTaskResponse> pendingResponses = new Map<String, CreateTaskResponse>();

    for (CreateTaskRequest req : requests) {
      String key = req.caseId + '_' + req.attemptNumber;
      CreateTaskResponse response = new CreateTaskResponse();

      // Check if task already exists
      if (existingTasks.containsKey(key)) {
        response.taskCreated = false;
        response.taskId = existingTasks.get(key).Id;
        response.message =
          'Task for Attempt ' +
          req.attemptNumber +
          ' already exists';
        responses.add(response);
      } else {
        // Create new task
        Task newTask = buildContactAttemptTask(req);
        tasksToCreate.add(newTask);
        pendingResponses.put(key, response);
      }
    }

    // Insert tasks in bulk
    if (!tasksToCreate.isEmpty()) {
      try {
        Database.insert(tasksToCreate, AccessLevel.USER_MODE);

        // Update responses with created task IDs
        Integer index = 0;
        for (CreateTaskRequest req : requests) {
          String key = req.caseId + '_' + req.attemptNumber;
          if (pendingResponses.containsKey(key)) {
            CreateTaskResponse response = pendingResponses.get(key);
            response.taskCreated = true;
            response.taskId = tasksToCreate[index].Id;
            response.message =
              'Task for Attempt ' +
              req.attemptNumber +
              ' created successfully';
            responses.add(response);
            index++;
          }
        }
      } catch (DmlException e) {
        // Handle errors - return failure responses
        for (String key : pendingResponses.keySet()) {
          CreateTaskResponse response = pendingResponses.get(key);
          response.taskCreated = false;
          response.taskId = null;
          response.message = 'Error creating task: ' + e.getMessage();
          responses.add(response);
        }
      }
    }

    return responses;
  }

  /**
   * Query existing tasks for duplicate prevention
   * Bulk query for all case IDs and attempt numbers
   *
   * @param caseIds Set of case IDs
   * @param requestMap Map of requests by key (caseId_attemptNumber)
   * @return Map of existing tasks by key
   */
  private static Map<String, Task> queryExistingTasks(
    Set<Id> caseIds,
    Map<String, CreateTaskRequest> requestMap
  ) {
    Map<String, Task> existingTasks = new Map<String, Task>();

    // Extract attempt numbers from requests
    Set<Decimal> attemptNumbers = new Set<Decimal>();
    for (CreateTaskRequest req : requestMap.values()) {
      attemptNumbers.add(req.attemptNumber);
    }

    // Query existing tasks
    List<Task> tasks = [
      SELECT Id, WhatId, Contact_Attempt_Number__c
      FROM Task
      WHERE WhatId IN :caseIds AND Contact_Attempt_Number__c IN :attemptNumbers
      WITH USER_MODE
    ];

    // Map by caseId_attemptNumber
    for (Task task : tasks) {
      String key =
        task.WhatId +
        '_' +
        Integer.valueOf(task.Contact_Attempt_Number__c);
      existingTasks.put(key, task);
    }

    return existingTasks;
  }

  /**
   * Build contact attempt task record
   * Calculates ActivityDate based on case created date + days offset
   *
   * @param req Task creation request
   * @return Task record ready for insert
   */
  private static Task buildContactAttemptTask(CreateTaskRequest req) {
    // Calculate activity date from case created date + days offset
    Date activityDate = req.caseCreatedDate.date().addDays(req.daysOffset);

    // Build task
    Task newTask = new Task();
    newTask.WhatId = req.caseId;
    newTask.Subject = 'Succession Contact Attempt ' + req.attemptNumber;
    newTask.Status = 'Not Started';
    newTask.Priority = 'High';
    newTask.ActivityDate = activityDate;
    newTask.Contact_Attempt_Number__c = req.attemptNumber;

    return newTask;
  }
}
