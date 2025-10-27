/**
 * SuccessionTaskCreator_Test
 *
 * Comprehensive test coverage for SuccessionTaskCreator invocable Apex class.
 * Tests task creation, duplicate prevention, bulk operations, and error handling.
 *
 * @author Claude Code
 * @date 2025-10-27
 */
@isTest
private class SuccessionTaskCreator_Test {
  /**
   * Test data setup - creates Case with EstateAdministration record type
   */
  @TestSetup
  static void makeData() {
    // Create test case
    Id recordTypeId = SuccessionUtilities.getEstateAdministrationRecordTypeId();
    Case testCase = new Case(
      RecordTypeId = recordTypeId,
      Subject = 'Test Estate Administration Case',
      Status = 'New',
      Origin = 'Phone'
    );
    insert testCase;
  }

  // ========================================
  // HAPPY PATH TESTS
  // ========================================

  /**
   * Test single task creation - Attempt 2 (Day 5)
   * Verifies task created with correct fields and ActivityDate calculation
   */
  @isTest
  static void testCreateSingleTask_Attempt2() {
    Case testCase = [SELECT Id, CreatedDate FROM Case LIMIT 1];

    SuccessionTaskCreator.CreateTaskRequest request = new SuccessionTaskCreator.CreateTaskRequest();
    request.caseId = testCase.Id;
    request.attemptNumber = 2;
    request.daysOffset = 5;
    request.caseCreatedDate = testCase.CreatedDate;

    Test.startTest();
    List<SuccessionTaskCreator.CreateTaskResponse> responses = SuccessionTaskCreator.createContactAttemptTasks(
      new List<SuccessionTaskCreator.CreateTaskRequest>{ request }
    );
    Test.stopTest();

    // Verify response
    System.assertEquals(1, responses.size(), 'Should return 1 response');
    SuccessionTaskCreator.CreateTaskResponse response = responses[0];
    System.assertEquals(
      true,
      response.taskCreated,
      'Task should be created'
    );
    System.assertNotEquals(null, response.taskId, 'Task ID should be set');
    System.assertEquals(
      'Task for Attempt 2 created successfully',
      response.message,
      'Success message should be set'
    );

    // Verify task created in database
    Task createdTask = [
      SELECT
        Id,
        WhatId,
        Subject,
        Status,
        Priority,
        ActivityDate,
        Contact_Attempt_Number__c
      FROM Task
      WHERE Id = :response.taskId
    ];

    System.assertEquals(
      testCase.Id,
      createdTask.WhatId,
      'Task should be linked to case'
    );
    System.assertEquals(
      'Succession Contact Attempt 2',
      createdTask.Subject,
      'Subject should be correct'
    );
    System.assertEquals(
      'Not Started',
      createdTask.Status,
      'Status should be Not Started'
    );
    System.assertEquals('High', createdTask.Priority, 'Priority should be High');
    System.assertEquals(
      2,
      createdTask.Contact_Attempt_Number__c,
      'Attempt number should be 2'
    );

    // Verify ActivityDate calculation (CreatedDate + 5 days)
    Date expectedDate = testCase.CreatedDate.date().addDays(5);
    System.assertEquals(
      expectedDate,
      createdTask.ActivityDate,
      'ActivityDate should be CreatedDate + 5 days'
    );
  }

  /**
   * Test single task creation - Attempt 3 (Day 35)
   * Verifies different attempt number and days offset
   */
  @isTest
  static void testCreateSingleTask_Attempt3() {
    Case testCase = [SELECT Id, CreatedDate FROM Case LIMIT 1];

    SuccessionTaskCreator.CreateTaskRequest request = new SuccessionTaskCreator.CreateTaskRequest();
    request.caseId = testCase.Id;
    request.attemptNumber = 3;
    request.daysOffset = 35;
    request.caseCreatedDate = testCase.CreatedDate;

    Test.startTest();
    List<SuccessionTaskCreator.CreateTaskResponse> responses = SuccessionTaskCreator.createContactAttemptTasks(
      new List<SuccessionTaskCreator.CreateTaskRequest>{ request }
    );
    Test.stopTest();

    Task createdTask = [
      SELECT Subject, Contact_Attempt_Number__c, ActivityDate
      FROM Task
      WHERE Id = :responses[0].taskId
    ];

    System.assertEquals(
      'Succession Contact Attempt 3',
      createdTask.Subject,
      'Subject should be Attempt 3'
    );
    System.assertEquals(
      3,
      createdTask.Contact_Attempt_Number__c,
      'Attempt number should be 3'
    );

    Date expectedDate = testCase.CreatedDate.date().addDays(35);
    System.assertEquals(
      expectedDate,
      createdTask.ActivityDate,
      'ActivityDate should be CreatedDate + 35 days'
    );
  }

  /**
   * Test single task creation - Attempt 4 (Day 65)
   */
  @isTest
  static void testCreateSingleTask_Attempt4() {
    Case testCase = [SELECT Id, CreatedDate FROM Case LIMIT 1];

    SuccessionTaskCreator.CreateTaskRequest request = new SuccessionTaskCreator.CreateTaskRequest();
    request.caseId = testCase.Id;
    request.attemptNumber = 4;
    request.daysOffset = 65;
    request.caseCreatedDate = testCase.CreatedDate;

    Test.startTest();
    List<SuccessionTaskCreator.CreateTaskResponse> responses = SuccessionTaskCreator.createContactAttemptTasks(
      new List<SuccessionTaskCreator.CreateTaskRequest>{ request }
    );
    Test.stopTest();

    Task createdTask = [
      SELECT Subject, Contact_Attempt_Number__c, ActivityDate
      FROM Task
      WHERE Id = :responses[0].taskId
    ];

    System.assertEquals(
      'Succession Contact Attempt 4',
      createdTask.Subject,
      'Subject should be Attempt 4'
    );
    System.assertEquals(
      4,
      createdTask.Contact_Attempt_Number__c,
      'Attempt number should be 4'
    );

    Date expectedDate = testCase.CreatedDate.date().addDays(65);
    System.assertEquals(
      expectedDate,
      createdTask.ActivityDate,
      'ActivityDate should be CreatedDate + 65 days'
    );
  }

  /**
   * Test single task creation - Attempt 5 (Day 95)
   */
  @isTest
  static void testCreateSingleTask_Attempt5() {
    Case testCase = [SELECT Id, CreatedDate FROM Case LIMIT 1];

    SuccessionTaskCreator.CreateTaskRequest request = new SuccessionTaskCreator.CreateTaskRequest();
    request.caseId = testCase.Id;
    request.attemptNumber = 5;
    request.daysOffset = 95;
    request.caseCreatedDate = testCase.CreatedDate;

    Test.startTest();
    List<SuccessionTaskCreator.CreateTaskResponse> responses = SuccessionTaskCreator.createContactAttemptTasks(
      new List<SuccessionTaskCreator.CreateTaskRequest>{ request }
    );
    Test.stopTest();

    Task createdTask = [
      SELECT Subject, Contact_Attempt_Number__c, ActivityDate
      FROM Task
      WHERE Id = :responses[0].taskId
    ];

    System.assertEquals(
      'Succession Contact Attempt 5',
      createdTask.Subject,
      'Subject should be Attempt 5'
    );
    System.assertEquals(
      5,
      createdTask.Contact_Attempt_Number__c,
      'Attempt number should be 5'
    );

    Date expectedDate = testCase.CreatedDate.date().addDays(95);
    System.assertEquals(
      expectedDate,
      createdTask.ActivityDate,
      'ActivityDate should be CreatedDate + 95 days'
    );
  }

  // ========================================
  // BULK OPERATION TESTS
  // ========================================

  /**
   * Test bulk task creation - 4 tasks for Attempts 2-5
   * Verifies bulk operations work correctly
   */
  @isTest
  static void testCreateBulkTasks_FourAttempts() {
    Case testCase = [SELECT Id, CreatedDate FROM Case LIMIT 1];

    // Build 4 requests for Attempts 2-5
    List<SuccessionTaskCreator.CreateTaskRequest> requests = new List<SuccessionTaskCreator.CreateTaskRequest>();

    // Attempt 2 (Day 5)
    SuccessionTaskCreator.CreateTaskRequest req2 = new SuccessionTaskCreator.CreateTaskRequest();
    req2.caseId = testCase.Id;
    req2.attemptNumber = 2;
    req2.daysOffset = 5;
    req2.caseCreatedDate = testCase.CreatedDate;
    requests.add(req2);

    // Attempt 3 (Day 35)
    SuccessionTaskCreator.CreateTaskRequest req3 = new SuccessionTaskCreator.CreateTaskRequest();
    req3.caseId = testCase.Id;
    req3.attemptNumber = 3;
    req3.daysOffset = 35;
    req3.caseCreatedDate = testCase.CreatedDate;
    requests.add(req3);

    // Attempt 4 (Day 65)
    SuccessionTaskCreator.CreateTaskRequest req4 = new SuccessionTaskCreator.CreateTaskRequest();
    req4.caseId = testCase.Id;
    req4.attemptNumber = 4;
    req4.daysOffset = 65;
    req4.caseCreatedDate = testCase.CreatedDate;
    requests.add(req4);

    // Attempt 5 (Day 95)
    SuccessionTaskCreator.CreateTaskRequest req5 = new SuccessionTaskCreator.CreateTaskRequest();
    req5.caseId = testCase.Id;
    req5.attemptNumber = 5;
    req5.daysOffset = 95;
    req5.caseCreatedDate = testCase.CreatedDate;
    requests.add(req5);

    Test.startTest();
    List<SuccessionTaskCreator.CreateTaskResponse> responses = SuccessionTaskCreator.createContactAttemptTasks(
      requests
    );
    Test.stopTest();

    // Verify 4 responses
    System.assertEquals(4, responses.size(), 'Should return 4 responses');

    // Verify all tasks created successfully
    for (SuccessionTaskCreator.CreateTaskResponse response : responses) {
      System.assertEquals(
        true,
        response.taskCreated,
        'All tasks should be created'
      );
      System.assertNotEquals(
        null,
        response.taskId,
        'All task IDs should be set'
      );
    }

    // Verify 4 tasks in database
    List<Task> createdTasks = [
      SELECT Id, Contact_Attempt_Number__c, ActivityDate
      FROM Task
      WHERE WhatId = :testCase.Id
      ORDER BY Contact_Attempt_Number__c
    ];

    System.assertEquals(4, createdTasks.size(), 'Should create 4 tasks');

    // Verify attempt numbers are correct
    System.assertEquals(
      2,
      createdTasks[0].Contact_Attempt_Number__c,
      'First task should be Attempt 2'
    );
    System.assertEquals(
      3,
      createdTasks[1].Contact_Attempt_Number__c,
      'Second task should be Attempt 3'
    );
    System.assertEquals(
      4,
      createdTasks[2].Contact_Attempt_Number__c,
      'Third task should be Attempt 4'
    );
    System.assertEquals(
      5,
      createdTasks[3].Contact_Attempt_Number__c,
      'Fourth task should be Attempt 5'
    );

    // Verify ActivityDate calculations
    System.assertEquals(
      testCase.CreatedDate.date().addDays(5),
      createdTasks[0].ActivityDate,
      'Attempt 2 should be +5 days'
    );
    System.assertEquals(
      testCase.CreatedDate.date().addDays(35),
      createdTasks[1].ActivityDate,
      'Attempt 3 should be +35 days'
    );
    System.assertEquals(
      testCase.CreatedDate.date().addDays(65),
      createdTasks[2].ActivityDate,
      'Attempt 4 should be +65 days'
    );
    System.assertEquals(
      testCase.CreatedDate.date().addDays(95),
      createdTasks[3].ActivityDate,
      'Attempt 5 should be +95 days'
    );
  }

  /**
   * Test bulk task creation across multiple cases
   * Verifies bulk operations work with different case IDs
   */
  @isTest
  static void testCreateBulkTasks_MultipleCases() {
    // Create 2 additional test cases
    Id recordTypeId = SuccessionUtilities.getEstateAdministrationRecordTypeId();
    List<Case> additionalCases = new List<Case>{
      new Case(
        RecordTypeId = recordTypeId,
        Subject = 'Test Case 2',
        Status = 'New',
        Origin = 'Phone'
      ),
      new Case(
        RecordTypeId = recordTypeId,
        Subject = 'Test Case 3',
        Status = 'New',
        Origin = 'Phone'
      )
    };
    insert additionalCases;

    List<Case> allCases = [SELECT Id, CreatedDate FROM Case];
    System.assertEquals(3, allCases.size(), 'Should have 3 cases');

    // Create request for each case (Attempt 2)
    List<SuccessionTaskCreator.CreateTaskRequest> requests = new List<SuccessionTaskCreator.CreateTaskRequest>();
    for (Case c : allCases) {
      SuccessionTaskCreator.CreateTaskRequest req = new SuccessionTaskCreator.CreateTaskRequest();
      req.caseId = c.Id;
      req.attemptNumber = 2;
      req.daysOffset = 5;
      req.caseCreatedDate = c.CreatedDate;
      requests.add(req);
    }

    Test.startTest();
    List<SuccessionTaskCreator.CreateTaskResponse> responses = SuccessionTaskCreator.createContactAttemptTasks(
      requests
    );
    Test.stopTest();

    // Verify 3 responses (one per case)
    System.assertEquals(3, responses.size(), 'Should return 3 responses');

    for (SuccessionTaskCreator.CreateTaskResponse response : responses) {
      System.assertEquals(
        true,
        response.taskCreated,
        'All tasks should be created'
      );
    }

    // Verify 3 tasks created (one per case)
    List<Task> createdTasks = [
      SELECT Id, WhatId
      FROM Task
      WHERE WhatId IN :allCases
    ];
    System.assertEquals(3, createdTasks.size(), 'Should create 3 tasks');

    // Verify each case has one task
    Set<Id> caseIds = new Set<Id>();
    for (Task t : createdTasks) {
      caseIds.add(t.WhatId);
    }
    System.assertEquals(
      3,
      caseIds.size(),
      'Each case should have one task'
    );
  }

  // ========================================
  // DUPLICATE PREVENTION TESTS
  // ========================================

  /**
   * Test duplicate prevention - task already exists
   * Verifies no duplicate task created when one already exists
   */
  @isTest
  static void testDuplicatePrevention_TaskExists() {
    Case testCase = [SELECT Id, CreatedDate FROM Case LIMIT 1];

    // Create existing task for Attempt 2
    Task existingTask = new Task(
      WhatId = testCase.Id,
      Subject = 'Succession Contact Attempt 2',
      Status = 'Not Started',
      Priority = 'High',
      ActivityDate = testCase.CreatedDate.date().addDays(5),
      Contact_Attempt_Number__c = 2
    );
    insert existingTask;

    // Try to create the same task via invocable method
    SuccessionTaskCreator.CreateTaskRequest request = new SuccessionTaskCreator.CreateTaskRequest();
    request.caseId = testCase.Id;
    request.attemptNumber = 2;
    request.daysOffset = 5;
    request.caseCreatedDate = testCase.CreatedDate;

    Test.startTest();
    List<SuccessionTaskCreator.CreateTaskResponse> responses = SuccessionTaskCreator.createContactAttemptTasks(
      new List<SuccessionTaskCreator.CreateTaskRequest>{ request }
    );
    Test.stopTest();

    // Verify response indicates task already exists
    System.assertEquals(1, responses.size(), 'Should return 1 response');
    SuccessionTaskCreator.CreateTaskResponse response = responses[0];
    System.assertEquals(
      false,
      response.taskCreated,
      'Task should NOT be created (already exists)'
    );
    System.assertEquals(
      existingTask.Id,
      response.taskId,
      'Should return existing task ID'
    );
    System.assertEquals(
      'Task for Attempt 2 already exists',
      response.message,
      'Message should indicate task exists'
    );

    // Verify only 1 task exists (no duplicate created)
    List<Task> tasks = [
      SELECT Id
      FROM Task
      WHERE WhatId = :testCase.Id AND Contact_Attempt_Number__c = 2
    ];
    System.assertEquals(1, tasks.size(), 'Should only have 1 task (no duplicate)');
    System.assertEquals(
      existingTask.Id,
      tasks[0].Id,
      'Should be the original task'
    );
  }

  /**
   * Test duplicate prevention with bulk operations
   * Verifies mixed scenario: some tasks exist, some don't
   */
  @isTest
  static void testDuplicatePrevention_MixedScenario() {
    Case testCase = [SELECT Id, CreatedDate FROM Case LIMIT 1];

    // Create existing tasks for Attempts 2 and 4
    List<Task> existingTasks = new List<Task>{
      new Task(
        WhatId = testCase.Id,
        Subject = 'Succession Contact Attempt 2',
        Status = 'Not Started',
        Priority = 'High',
        ActivityDate = testCase.CreatedDate.date().addDays(5),
        Contact_Attempt_Number__c = 2
      ),
      new Task(
        WhatId = testCase.Id,
        Subject = 'Succession Contact Attempt 4',
        Status = 'Not Started',
        Priority = 'High',
        ActivityDate = testCase.CreatedDate.date().addDays(65),
        Contact_Attempt_Number__c = 4
      )
    };
    insert existingTasks;

    // Try to create tasks for Attempts 2, 3, 4, 5
    List<SuccessionTaskCreator.CreateTaskRequest> requests = new List<SuccessionTaskCreator.CreateTaskRequest>();

    for (
      Integer i = 0;
      i < 4;
      i++
    ) {
      SuccessionTaskCreator.CreateTaskRequest req = new SuccessionTaskCreator.CreateTaskRequest();
      req.caseId = testCase.Id;
      req.attemptNumber = i + 2; // Attempts 2, 3, 4, 5
      req.daysOffset = (i == 0)
        ? 5
        : (i == 1) ? 35 : (i == 2) ? 65 : 95;
      req.caseCreatedDate = testCase.CreatedDate;
      requests.add(req);
    }

    Test.startTest();
    List<SuccessionTaskCreator.CreateTaskResponse> responses = SuccessionTaskCreator.createContactAttemptTasks(
      requests
    );
    Test.stopTest();

    // Verify 4 responses
    System.assertEquals(4, responses.size(), 'Should return 4 responses');

    // Verify Attempts 2 and 4 were skipped (already exist)
    System.assertEquals(
      false,
      responses[0].taskCreated,
      'Attempt 2 should be skipped'
    );
    System.assertEquals(
      'Task for Attempt 2 already exists',
      responses[0].message,
      'Message should indicate Attempt 2 exists'
    );

    System.assertEquals(
      false,
      responses[2].taskCreated,
      'Attempt 4 should be skipped'
    );
    System.assertEquals(
      'Task for Attempt 4 already exists',
      responses[2].message,
      'Message should indicate Attempt 4 exists'
    );

    // Verify Attempts 3 and 5 were created
    System.assertEquals(
      true,
      responses[1].taskCreated,
      'Attempt 3 should be created'
    );
    System.assertEquals(
      'Task for Attempt 3 created successfully',
      responses[1].message,
      'Message should indicate Attempt 3 created'
    );

    System.assertEquals(
      true,
      responses[3].taskCreated,
      'Attempt 5 should be created'
    );
    System.assertEquals(
      'Task for Attempt 5 created successfully',
      responses[3].message,
      'Message should indicate Attempt 5 created'
    );

    // Verify total of 4 tasks in database (2 existing + 2 new)
    List<Task> allTasks = [
      SELECT Id, Contact_Attempt_Number__c
      FROM Task
      WHERE WhatId = :testCase.Id
      ORDER BY Contact_Attempt_Number__c
    ];
    System.assertEquals(4, allTasks.size(), 'Should have 4 total tasks');
    System.assertEquals(
      2,
      allTasks[0].Contact_Attempt_Number__c,
      'Task 1 should be Attempt 2'
    );
    System.assertEquals(
      3,
      allTasks[1].Contact_Attempt_Number__c,
      'Task 2 should be Attempt 3'
    );
    System.assertEquals(
      4,
      allTasks[2].Contact_Attempt_Number__c,
      'Task 3 should be Attempt 4'
    );
    System.assertEquals(
      5,
      allTasks[3].Contact_Attempt_Number__c,
      'Task 4 should be Attempt 5'
    );
  }

  // ========================================
  // ACTIVITYDATE CALCULATION TESTS
  // ========================================

  /**
   * Test ActivityDate calculation with past CreatedDate
   * Verifies date math works correctly for older cases
   */
  @isTest
  static void testActivityDateCalculation_PastDate() {
    Case testCase = [SELECT Id FROM Case LIMIT 1];

    // Use past date (30 days ago)
    DateTime pastDate = DateTime.now().addDays(-30);

    SuccessionTaskCreator.CreateTaskRequest request = new SuccessionTaskCreator.CreateTaskRequest();
    request.caseId = testCase.Id;
    request.attemptNumber = 3;
    request.daysOffset = 35;
    request.caseCreatedDate = pastDate;

    Test.startTest();
    List<SuccessionTaskCreator.CreateTaskResponse> responses = SuccessionTaskCreator.createContactAttemptTasks(
      new List<SuccessionTaskCreator.CreateTaskRequest>{ request }
    );
    Test.stopTest();

    Task createdTask = [
      SELECT ActivityDate
      FROM Task
      WHERE Id = :responses[0].taskId
    ];

    // Verify ActivityDate = pastDate + 35 days (5 days from now)
    Date expectedDate = pastDate.date().addDays(35);
    System.assertEquals(
      expectedDate,
      createdTask.ActivityDate,
      'ActivityDate should be calculated from provided CreatedDate'
    );
  }

  /**
   * Test ActivityDate calculation with future CreatedDate
   * Edge case: CreatedDate in future (should still calculate correctly)
   */
  @isTest
  static void testActivityDateCalculation_FutureDate() {
    Case testCase = [SELECT Id FROM Case LIMIT 1];

    // Use future date (10 days from now)
    DateTime futureDate = DateTime.now().addDays(10);

    SuccessionTaskCreator.CreateTaskRequest request = new SuccessionTaskCreator.CreateTaskRequest();
    request.caseId = testCase.Id;
    request.attemptNumber = 2;
    request.daysOffset = 5;
    request.caseCreatedDate = futureDate;

    Test.startTest();
    List<SuccessionTaskCreator.CreateTaskResponse> responses = SuccessionTaskCreator.createContactAttemptTasks(
      new List<SuccessionTaskCreator.CreateTaskRequest>{ request }
    );
    Test.stopTest();

    Task createdTask = [
      SELECT ActivityDate
      FROM Task
      WHERE Id = :responses[0].taskId
    ];

    // Verify ActivityDate = futureDate + 5 days (15 days from now)
    Date expectedDate = futureDate.date().addDays(5);
    System.assertEquals(
      expectedDate,
      createdTask.ActivityDate,
      'ActivityDate should handle future CreatedDate'
    );
  }

  /**
   * Test ActivityDate calculation with zero days offset
   * Edge case: daysOffset = 0 (same day as CreatedDate)
   */
  @isTest
  static void testActivityDateCalculation_ZeroDaysOffset() {
    Case testCase = [SELECT Id, CreatedDate FROM Case LIMIT 1];

    SuccessionTaskCreator.CreateTaskRequest request = new SuccessionTaskCreator.CreateTaskRequest();
    request.caseId = testCase.Id;
    request.attemptNumber = 1;
    request.daysOffset = 0; // Same day
    request.caseCreatedDate = testCase.CreatedDate;

    Test.startTest();
    List<SuccessionTaskCreator.CreateTaskResponse> responses = SuccessionTaskCreator.createContactAttemptTasks(
      new List<SuccessionTaskCreator.CreateTaskRequest>{ request }
    );
    Test.stopTest();

    Task createdTask = [
      SELECT ActivityDate
      FROM Task
      WHERE Id = :responses[0].taskId
    ];

    // Verify ActivityDate = CreatedDate (no offset)
    Date expectedDate = testCase.CreatedDate.date();
    System.assertEquals(
      expectedDate,
      createdTask.ActivityDate,
      'ActivityDate should equal CreatedDate when offset is 0'
    );
  }

  // ========================================
  // EDGE CASE AND ERROR HANDLING TESTS
  // ========================================

  /**
   * Test with empty request list
   * Verifies graceful handling of empty input
   */
  @isTest
  static void testEmptyRequestList() {
    List<SuccessionTaskCreator.CreateTaskRequest> emptyRequests = new List<SuccessionTaskCreator.CreateTaskRequest>();

    Test.startTest();
    List<SuccessionTaskCreator.CreateTaskResponse> responses = SuccessionTaskCreator.createContactAttemptTasks(
      emptyRequests
    );
    Test.stopTest();

    System.assertEquals(
      0,
      responses.size(),
      'Should return empty response list'
    );

    // Verify no tasks created
    List<Task> tasks = [SELECT Id FROM Task];
    System.assertEquals(
      0,
      tasks.size(),
      'Should not create any tasks'
    );
  }

  /**
   * Test with invalid case ID
   * Verifies DML error handling
   */
  @isTest
  static void testInvalidCaseId() {
    // Use a fake ID (Account ID instead of Case ID)
    Id fakeId = '001000000000000AAA';

    SuccessionTaskCreator.CreateTaskRequest request = new SuccessionTaskCreator.CreateTaskRequest();
    request.caseId = fakeId;
    request.attemptNumber = 2;
    request.daysOffset = 5;
    request.caseCreatedDate = DateTime.now();

    Test.startTest();
    List<SuccessionTaskCreator.CreateTaskResponse> responses = SuccessionTaskCreator.createContactAttemptTasks(
      new List<SuccessionTaskCreator.CreateTaskRequest>{ request }
    );
    Test.stopTest();

    // Verify error response
    System.assertEquals(1, responses.size(), 'Should return 1 response');
    SuccessionTaskCreator.CreateTaskResponse response = responses[0];
    System.assertEquals(
      false,
      response.taskCreated,
      'Task should NOT be created'
    );
    System.assertEquals(null, response.taskId, 'Task ID should be null');
    System.assert(
      response.message.contains('Error creating task'),
      'Message should indicate error'
    );
  }

  /**
   * Test with negative attempt number
   * Edge case: attemptNumber < 1
   */
  @isTest
  static void testNegativeAttemptNumber() {
    Case testCase = [SELECT Id, CreatedDate FROM Case LIMIT 1];

    SuccessionTaskCreator.CreateTaskRequest request = new SuccessionTaskCreator.CreateTaskRequest();
    request.caseId = testCase.Id;
    request.attemptNumber = -1; // Invalid
    request.daysOffset = 5;
    request.caseCreatedDate = testCase.CreatedDate;

    Test.startTest();
    List<SuccessionTaskCreator.CreateTaskResponse> responses = SuccessionTaskCreator.createContactAttemptTasks(
      new List<SuccessionTaskCreator.CreateTaskRequest>{ request }
    );
    Test.stopTest();

    // Verify task created (no validation on attempt number in class)
    // This is acceptable since flow will validate inputs
    System.assertEquals(1, responses.size(), 'Should return 1 response');
    System.assertEquals(
      true,
      responses[0].taskCreated,
      'Task created (validation in flow, not Apex)'
    );

    Task createdTask = [
      SELECT Contact_Attempt_Number__c
      FROM Task
      WHERE Id = :responses[0].taskId
    ];
    System.assertEquals(
      -1,
      createdTask.Contact_Attempt_Number__c,
      'Negative number persisted (flow should validate)'
    );
  }

  /**
   * Test with very large days offset
   * Edge case: daysOffset = 365 (1 year later)
   */
  @isTest
  static void testLargeDaysOffset() {
    Case testCase = [SELECT Id, CreatedDate FROM Case LIMIT 1];

    SuccessionTaskCreator.CreateTaskRequest request = new SuccessionTaskCreator.CreateTaskRequest();
    request.caseId = testCase.Id;
    request.attemptNumber = 2;
    request.daysOffset = 365; // 1 year
    request.caseCreatedDate = testCase.CreatedDate;

    Test.startTest();
    List<SuccessionTaskCreator.CreateTaskResponse> responses = SuccessionTaskCreator.createContactAttemptTasks(
      new List<SuccessionTaskCreator.CreateTaskRequest>{ request }
    );
    Test.stopTest();

    Task createdTask = [
      SELECT ActivityDate
      FROM Task
      WHERE Id = :responses[0].taskId
    ];

    Date expectedDate = testCase.CreatedDate.date().addDays(365);
    System.assertEquals(
      expectedDate,
      createdTask.ActivityDate,
      'Should handle large day offsets'
    );
  }

  /**
   * Test governor limits - bulk creation of 200 tasks
   * Verifies bulk operations don't hit limits
   */
  @isTest
  static void testGovernorLimits_BulkCreation() {
    // Create 50 test cases (will create 4 tasks each = 200 total)
    Id recordTypeId = SuccessionUtilities.getEstateAdministrationRecordTypeId();
    List<Case> bulkCases = new List<Case>();
    for (Integer i = 0; i < 50; i++) {
      bulkCases.add(
        new Case(
          RecordTypeId = recordTypeId,
          Subject = 'Bulk Test Case ' + i,
          Status = 'New',
          Origin = 'Phone'
        )
      );
    }
    insert bulkCases;

    // Build requests for 200 tasks (4 per case)
    List<SuccessionTaskCreator.CreateTaskRequest> requests = new List<SuccessionTaskCreator.CreateTaskRequest>();
    for (Case c : bulkCases) {
      for (Integer attemptNum = 2; attemptNum <= 5; attemptNum++) {
        SuccessionTaskCreator.CreateTaskRequest req = new SuccessionTaskCreator.CreateTaskRequest();
        req.caseId = c.Id;
        req.attemptNumber = attemptNum;
        req.daysOffset = (attemptNum == 2)
          ? 5
          : (attemptNum == 3) ? 35 : (attemptNum == 4) ? 65 : 95;
        req.caseCreatedDate = DateTime.now();
        requests.add(req);
      }
    }

    Test.startTest();
    List<SuccessionTaskCreator.CreateTaskResponse> responses = SuccessionTaskCreator.createContactAttemptTasks(
      requests
    );
    Test.stopTest();

    // Verify all 200 responses
    System.assertEquals(
      200,
      responses.size(),
      'Should return 200 responses'
    );

    // Verify all tasks created
    Integer successCount = 0;
    for (SuccessionTaskCreator.CreateTaskResponse response : responses) {
      if (response.taskCreated) {
        successCount++;
      }
    }
    System.assertEquals(
      200,
      successCount,
      'All 200 tasks should be created'
    );

    // Verify 200 tasks in database
    List<Task> allTasks = [SELECT Id FROM Task];
    System.assertEquals(
      200,
      allTasks.size(),
      'Should have 200 tasks in database'
    );

    // Verify SOQL query count (should use bulk queries)
    System.assert(
      Limits.getQueries() < 10,
      'Should use minimal SOQL queries via bulk operations'
    );
  }
}
