/**
 * SuccessionPerformanceTestSuite
 *
 * Performance-oriented tests for high-volume succession scenarios.
 * These tests exercise bulk behavior for case creation and contact
 * task creation while staying within Salesforce governor limits.
 */
@IsTest
public class SuccessionPerformanceTestSuite {
  @IsTest
  static void testBulkCaseCreationPerformance() {
    // Use a moderate volume that meaningfully exercises bulk behavior
    // without approaching DML statement limits.
    // Volume chosen to exercise bulk behavior while staying well under SOQL limits
    Integer caseCount = 10;

    // Deceased donor accounts
    List<Account> donors = new List<Account>();
    for (Integer i = 0; i < caseCount; i++) {
      donors.add(new Account(Name = 'Perf Donor ' + i, Deceased__c = true));
    }
    insert donors;

    // Successor accounts
    List<Account> successorAccounts = new List<Account>();
    for (Integer i = 0; i < caseCount; i++) {
      successorAccounts.add(new Account(Name = 'Perf Successor ' + i));
    }
    insert successorAccounts;

    // Successor contacts (one per successor account)
    List<Contact> successorContacts = new List<Contact>();
    for (Integer i = 0; i < caseCount; i++) {
      successorContacts.add(
        new Contact(
          FirstName = 'Succ ' + i,
          LastName = 'User',
          Email = 'perf.successor' + i + '@example.com',
          AccountId = successorAccounts[i].Id
        )
      );
    }
    insert successorContacts;

    // Financial accounts
    List<FinServ__FinancialAccount__c> financialAccounts = new List<FinServ__FinancialAccount__c>();
    for (Integer i = 0; i < caseCount; i++) {
      financialAccounts.add(
        new FinServ__FinancialAccount__c(
          Name = 'Perf DAF ' + i,
          FinServ__PrimaryOwner__c = donors[i].Id,
          FinServ__Balance__c = 100000
        )
      );
    }
    insert financialAccounts;

    // Primary owner + successor roles
    List<FinServ__FinancialAccountRole__c> roles = new List<FinServ__FinancialAccountRole__c>();
    for (Integer i = 0; i < caseCount; i++) {
      roles.add(
        new FinServ__FinancialAccountRole__c(
          FinServ__FinancialAccount__c = financialAccounts[i].Id,
          FinServ__RelatedAccount__c = donors[i].Id,
          FinServ__Role__c = 'Primary Owner'
        )
      );
    }
    for (Integer i = 0; i < caseCount; i++) {
      roles.add(
        new FinServ__FinancialAccountRole__c(
          FinServ__FinancialAccount__c = financialAccounts[i].Id,
          FinServ__RelatedContact__c = successorContacts[i].Id,
          FinServ__Role__c = 'Successor',
          SuccessorAllocation__c = 100
        )
      );
    }
    insert roles;

    Test.startTest();
    List<CreateSuccessionCaseController.CreateCaseResult> results =
      new List<CreateSuccessionCaseController.CreateCaseResult>();
    for (FinServ__FinancialAccount__c fa : financialAccounts) {
      CreateSuccessionCaseController.CreateCaseResult result = CreateSuccessionCaseController.createSuccessionCase(
        fa.Id
      );
      results.add(result);
    }
    Test.stopTest();

    // Validate all calls succeeded and seeded a case
    for (CreateSuccessionCaseController.CreateCaseResult result : results) {
      System.assert(
        result.success,
        'Bulk case creation should succeed. Message: ' + result.message
      );
      System.assertNotEquals(
        null,
        result.seedCaseId,
        'Seed case ID should be populated for each result'
      );
    }

    Integer createdCount = [
      SELECT COUNT()
      FROM Case
      WHERE FinServ__FinancialAccount__c IN :financialAccounts
    ];
    System.assertEquals(
      caseCount,
      createdCount,
      'Should create one succession case per financial account'
    );
  }

  @IsTest
  static void testBulkContactTaskCreationPerformance() {
    Integer caseCount = 20;
    Integer attemptsPerCase = 5; // 100 tasks total

    // Create simple cases (no financial account dependency needed)
    List<Case> cases = new List<Case>();
    for (Integer i = 0; i < caseCount; i++) {
      cases.add(
        new Case(Subject = 'Perf Contact Case ' + i, Status = 'New', Origin = 'Phone')
      );
    }
    insert cases;

    // Re-query to get CreatedDate values
    cases = [
      SELECT Id, CreatedDate
      FROM Case
      WHERE Id IN :cases
    ];

    List<SuccessionTaskCreator.CreateTaskRequest> requests =
      new List<SuccessionTaskCreator.CreateTaskRequest>();

    Integer[] offsets = new Integer[]{ 0, 5, 35, 65, 95 };

    for (Case c : cases) {
      for (Integer attempt = 1; attempt <= attemptsPerCase; attempt++) {
        SuccessionTaskCreator.CreateTaskRequest req = new SuccessionTaskCreator.CreateTaskRequest();
        req.caseId = c.Id;
        req.attemptNumber = attempt;
        req.daysOffset = offsets[attempt - 1];
        req.caseCreatedDate = c.CreatedDate;
        requests.add(req);
      }
    }

    Test.startTest();
    List<SuccessionTaskCreator.CreateTaskResponse> responses = SuccessionTaskCreator.createContactAttemptTasks(
      requests
    );
    Test.stopTest();

    System.assertEquals(
      requests.size(),
      responses.size(),
      'Should return one response per request for bulk contact tasks'
    );

    Integer createdTaskCount = [
      SELECT COUNT()
      FROM Task
      WHERE WhatId IN :cases
    ];
    System.assertEquals(
      requests.size(),
      createdTaskCount,
      'Should create one Task per request in bulk scenario'
    );
  }
}

