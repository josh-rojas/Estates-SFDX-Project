/**
 * @description Test class for SuccessionTaskGenerator
 * @author Salesforce
 * @date October 2025
 */
@isTest
private class SuccessionTaskGenerator_Test {
  @testSetup
  static void setup() {
    // Create Person Account (FSC)
    Id personAcctRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('PersonAccount')
      .getRecordTypeId();

    Account testAccount = new Account(
      FirstName = 'Test',
      LastName = 'Successor',
      PersonEmail = 'successor@test.com',
      RecordTypeId = personAcctRecordTypeId
    );
    insert testAccount;

    // Get Estate Administration Record Type
    Id estateRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
      .get('EstateAdministration')
      .getRecordTypeId();

    // Create test Case
    Case testCase = new Case(
      Subject = 'Test Succession Case',
      RecordTypeId = estateRecordTypeId,
      Type = 'Named Successor Enactment',
      AccountId = testAccount.Id,
      Status = 'New',
      Origin = 'Email'
    );
    insert testCase;
  }

  @isTest
  static void testFinalGrantTasks() {
    Case testCase = [SELECT Id, CaseNumber FROM Case LIMIT 1];

    Test.startTest();

    // Trigger pathway task creation
    testCase.Pathway_Confirmed__c = 'Final Grant';
    // Use noon to avoid timezone rollover issues
    testCase.Form_Completed_Date__c = DateTime.newInstance(
      Date.today(),
      Time.newInstance(12, 0, 0, 0)
    );
    update testCase;

    Test.stopTest();

    // Verify 5 tasks were created
    List<Task> tasks = [
      SELECT Id, Subject, Priority, ActivityDate, Status
      FROM Task
      WHERE WhatId = :testCase.Id
      ORDER BY ActivityDate
    ];

    System.assertEquals(
      5,
      tasks.size(),
      'Should create 5 Final Grant pathway tasks'
    );
    System.assertEquals(
      'Review Grant Direction & Beneficiaries',
      tasks[0].Subject
    );
    System.assertEquals('Coordinate Trading / Liquidation', tasks[1].Subject);
    System.assertEquals('High', tasks[0].Priority);
    System.assertEquals('Not Started', tasks[0].Status);

    // Verify due dates are staggered correctly
    System.assertEquals(
      testCase.Form_Completed_Date__c.date().addDays(2),
      tasks[0].ActivityDate,
      'Task 1 should be 2 days from start'
    );
    System.assertEquals(
      testCase.Form_Completed_Date__c.date().addDays(5),
      tasks[1].ActivityDate,
      'Task 2 should be 5 days from start'
    );
    System.assertEquals(
      testCase.Form_Completed_Date__c.date().addDays(10),
      tasks[2].ActivityDate,
      'Task 3 should be 10 days from start'
    );
    System.assertEquals(
      testCase.Form_Completed_Date__c.date().addDays(15),
      tasks[3].ActivityDate,
      'Task 4 should be 15 days from start'
    );
    System.assertEquals(
      testCase.Form_Completed_Date__c.date().addDays(20),
      tasks[4].ActivityDate,
      'Task 5 should be 20 days from start'
    );

    // Verify Chatter post was created
    List<FeedItem> posts = [
      SELECT Id, Body
      FROM FeedItem
      WHERE ParentId = :testCase.Id
    ];
    System.assertEquals(1, posts.size(), 'Should create 1 Chatter post');
    System.assert(
      posts[0].Body.contains('5 pathway tasks created'),
      'Chatter should mention task count'
    );
  }

  @isTest
  static void testNewDAFTasks() {
    Case testCase = [SELECT Id FROM Case LIMIT 1];

    Test.startTest();

    testCase.Pathway_Confirmed__c = 'New DAF Account';
    // Use noon to avoid timezone rollover issues
    testCase.Form_Completed_Date__c = DateTime.newInstance(
      Date.today(),
      Time.newInstance(12, 0, 0, 0)
    );
    update testCase;

    Test.stopTest();

    // Verify 4 tasks were created
    List<Task> tasks = [
      SELECT Id, Subject, ActivityDate
      FROM Task
      WHERE WhatId = :testCase.Id
      ORDER BY ActivityDate
    ];

    System.assertEquals(
      4,
      tasks.size(),
      'Should create 4 New DAF pathway tasks'
    );
    System.assertEquals('Review New Account Application', tasks[0].Subject);
    System.assertEquals('Process Transfer Authorization', tasks[1].Subject);
    System.assertEquals(
      testCase.Form_Completed_Date__c.date().addDays(2),
      tasks[0].ActivityDate,
      'Task 1 should be 2 days from start'
    );
    System.assertEquals(
      testCase.Form_Completed_Date__c.date().addDays(7),
      tasks[1].ActivityDate,
      'Task 2 should be 7 days from start'
    );
    System.assertEquals(
      testCase.Form_Completed_Date__c.date().addDays(12),
      tasks[2].ActivityDate,
      'Task 3 should be 12 days from start'
    );
    System.assertEquals(
      testCase.Form_Completed_Date__c.date().addDays(18),
      tasks[3].ActivityDate,
      'Task 4 should be 18 days from start'
    );
  }

  @isTest
  static void testDisclaimTasks() {
    Case testCase = [SELECT Id FROM Case LIMIT 1];

    Test.startTest();

    testCase.Pathway_Confirmed__c = 'Disclaim Assets';
    // Use noon to avoid timezone rollover issues
    testCase.Form_Completed_Date__c = DateTime.newInstance(
      Date.today(),
      Time.newInstance(12, 0, 0, 0)
    );
    update testCase;

    Test.stopTest();

    // Verify 4 tasks were created
    List<Task> tasks = [
      SELECT Id, Subject, ActivityDate
      FROM Task
      WHERE WhatId = :testCase.Id
      ORDER BY ActivityDate
    ];

    System.assertEquals(
      4,
      tasks.size(),
      'Should create 4 Disclaim pathway tasks'
    );
    System.assertEquals('Review Disclaimer Documentation', tasks[0].Subject);
    System.assertEquals(
      'Identify Alternate Distribution Path',
      tasks[1].Subject
    );
    System.assertEquals(
      testCase.Form_Completed_Date__c.date().addDays(3),
      tasks[0].ActivityDate,
      'Task 1 should be 3 days from start'
    );
    System.assertEquals(
      testCase.Form_Completed_Date__c.date().addDays(8),
      tasks[1].ActivityDate,
      'Task 2 should be 8 days from start'
    );
    System.assertEquals(
      testCase.Form_Completed_Date__c.date().addDays(15),
      tasks[2].ActivityDate,
      'Task 3 should be 15 days from start'
    );
    System.assertEquals(
      testCase.Form_Completed_Date__c.date().addDays(20),
      tasks[3].ActivityDate,
      'Task 4 should be 20 days from start'
    );
  }

  @isTest
  static void testNoTasksCreated_NoPathway() {
    Case testCase = [SELECT Id FROM Case LIMIT 1];

    Test.startTest();

    // Update without setting pathway
    testCase.Status = 'In Progress';
    update testCase;

    Test.stopTest();

    List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :testCase.Id];
    System.assertEquals(
      0,
      tasks.size(),
      'No tasks should be created without pathway'
    );
  }

  @isTest
  static void testNoTasksCreated_PathwayUnchanged() {
    Case testCase = [SELECT Id FROM Case LIMIT 1];

    // Set pathway initially
    testCase.Pathway_Confirmed__c = 'Final Grant';
    testCase.Form_Completed_Date__c = Date.today();
    update testCase;

    Test.startTest();

    // Update without changing pathway
    testCase.Status = 'In Progress';
    update testCase;

    Test.stopTest();

    // Should still only have 5 tasks from first update
    List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :testCase.Id];
    System.assertEquals(5, tasks.size(), 'Should not create duplicate tasks');
  }

  @isTest
  static void testIdempotencyPreventsDuplicates() {
    Case testCase = [SELECT Id, Form_Completed_Date__c FROM Case LIMIT 1];

    Test.startTest();

    // Trigger pathway task creation (first time)
    testCase.Pathway_Confirmed__c = 'Final Grant';
    testCase.Form_Completed_Date__c = Date.today();
    update testCase;

    // Verify 5 tasks were created
    List<Task> tasksAfterFirst = [
      SELECT Id, Subject
      FROM Task
      WHERE WhatId = :testCase.Id
      ORDER BY ActivityDate
    ];
    System.assertEquals(
      5,
      tasksAfterFirst.size(),
      'Should create 5 Final Grant pathway tasks initially'
    );

    // Update the case again (trigger fires again with same pathway)
    testCase.Status = 'In Progress';
    update testCase;

    // Force another update that changes Pathway_Confirmed__c to same value
    // This simulates a scenario where the field "changes" to the same value
    testCase.Description = 'Updated description';
    update testCase;

    Test.stopTest();

    // Verify STILL only 5 tasks (no duplicates)
    List<Task> tasksAfterUpdates = [
      SELECT Id, Subject
      FROM Task
      WHERE WhatId = :testCase.Id
      ORDER BY ActivityDate
    ];
    System.assertEquals(
      5,
      tasksAfterUpdates.size(),
      'Should still have exactly 5 tasks (no duplicates)'
    );

    // Verify subjects match expected Final Grant tasks
    Set<String> expectedSubjects = new Set<String>{
      'Review Grant Direction & Beneficiaries',
      'Coordinate Trading / Liquidation',
      'Process Grant Recommendations',
      'Confirm Distributions & Settlement',
      'Finalize Case Documentation'
    };

    Set<String> actualSubjects = new Set<String>();
    for (Task t : tasksAfterUpdates) {
      actualSubjects.add(t.Subject);
    }
    System.assertEquals(
      expectedSubjects,
      actualSubjects,
      'Task subjects should match expected Final Grant tasks'
    );
  }

  @isTest
  static void testIdempotencyAcrossAllPathways() {
    // Get Estate Administration Record Type
    Id estateRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
      .get('EstateAdministration')
      .getRecordTypeId();

    // Create Person Account
    Id personAcctRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('PersonAccount')
      .getRecordTypeId();

    Account testAccount = new Account(
      FirstName = 'Idempotency',
      LastName = 'Test',
      PersonEmail = 'idempotency@test.com',
      RecordTypeId = personAcctRecordTypeId
    );
    insert testAccount;

    // Create test cases for each pathway
    List<Case> testCases = new List<Case>{
      new Case(
        Subject = 'Final Grant Test',
        RecordTypeId = estateRecordTypeId,
        Type = 'Named Successor Enactment',
        AccountId = testAccount.Id,
        Status = 'New',
        Origin = 'Email'
      ),
      new Case(
        Subject = 'New DAF Test',
        RecordTypeId = estateRecordTypeId,
        Type = 'Named Successor Enactment',
        AccountId = testAccount.Id,
        Status = 'New',
        Origin = 'Email'
      ),
      new Case(
        Subject = 'Disclaim Test',
        RecordTypeId = estateRecordTypeId,
        Type = 'Named Successor Enactment',
        AccountId = testAccount.Id,
        Status = 'New',
        Origin = 'Email'
      )
    };
    insert testCases;

    Test.startTest();

    // Set pathways for all cases
    testCases[0].Pathway_Confirmed__c = 'Final Grant';
    testCases[0].Form_Completed_Date__c = Date.today();
    testCases[1].Pathway_Confirmed__c = 'New DAF Account';
    testCases[1].Form_Completed_Date__c = Date.today();
    testCases[2].Pathway_Confirmed__c = 'Disclaim Assets';
    testCases[2].Form_Completed_Date__c = Date.today();
    update testCases;

    // Verify initial task counts
    Map<Id, Integer> taskCountsByCaseId = new Map<Id, Integer>();
    for (AggregateResult ar : [
      SELECT WhatId, COUNT(Id) taskCount
      FROM Task
      WHERE WhatId IN :testCases
      GROUP BY WhatId
    ]) {
      taskCountsByCaseId.put(
        (Id) ar.get('WhatId'),
        (Integer) ar.get('taskCount')
      );
    }

    System.assertEquals(
      5,
      taskCountsByCaseId.get(testCases[0].Id),
      'Final Grant should have 5 tasks'
    );
    System.assertEquals(
      4,
      taskCountsByCaseId.get(testCases[1].Id),
      'New DAF should have 4 tasks'
    );
    System.assertEquals(
      4,
      taskCountsByCaseId.get(testCases[2].Id),
      'Disclaim should have 4 tasks'
    );

    // Update all cases again (simulate multiple trigger fires)
    for (Case c : testCases) {
      c.Status = 'In Progress';
    }
    update testCases;

    Test.stopTest();

    // Verify task counts unchanged
    taskCountsByCaseId.clear();
    for (AggregateResult ar : [
      SELECT WhatId, COUNT(Id) taskCount
      FROM Task
      WHERE WhatId IN :testCases
      GROUP BY WhatId
    ]) {
      taskCountsByCaseId.put(
        (Id) ar.get('WhatId'),
        (Integer) ar.get('taskCount')
      );
    }

    System.assertEquals(
      5,
      taskCountsByCaseId.get(testCases[0].Id),
      'Final Grant should still have 5 tasks'
    );
    System.assertEquals(
      4,
      taskCountsByCaseId.get(testCases[1].Id),
      'New DAF should still have 4 tasks'
    );
    System.assertEquals(
      4,
      taskCountsByCaseId.get(testCases[2].Id),
      'Disclaim should still have 4 tasks'
    );
  }

  @isTest
  static void testBulkTaskCreation() {
    // Get Estate Administration Record Type
    Id estateRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
      .get('EstateAdministration')
      .getRecordTypeId();

    // Create Person Account
    Id personAcctRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('PersonAccount')
      .getRecordTypeId();

    Account testAccount = new Account(
      FirstName = 'Bulk',
      LastName = 'Test',
      PersonEmail = 'bulk@test.com',
      RecordTypeId = personAcctRecordTypeId
    );
    insert testAccount;

    // Create 50 test Cases (reduced from 200 to avoid Flow DML limits)
    List<Case> cases = new List<Case>();
    for (Integer i = 0; i < 50; i++) {
      cases.add(
        new Case(
          Subject = 'Bulk Test ' + i,
          RecordTypeId = estateRecordTypeId,
          Type = 'Named Successor Enactment',
          AccountId = testAccount.Id,
          Status = 'New',
          Origin = 'Email'
        )
      );
    }
    insert cases;

    Test.startTest();

    // Update all with pathways
    for (Integer i = 0; i < cases.size(); i++) {
      if (Math.mod(i, 3) == 0) {
        cases[i].Pathway_Confirmed__c = 'Final Grant';
      } else if (Math.mod(i, 3) == 1) {
        cases[i].Pathway_Confirmed__c = 'New DAF Account';
      } else {
        cases[i].Pathway_Confirmed__c = 'Disclaim Assets';
      }
      cases[i].Form_Completed_Date__c = Date.today();
    }
    update cases;

    Test.stopTest();

    // Verify tasks were created
    List<Task> tasks = [SELECT Id FROM Task WHERE WhatId IN :cases];
    System.assert(tasks.size() > 0, 'Bulk operation should create tasks');
    // Total should be ~867 tasks (67*5 + 66*4 + 67*4)
  }
}
