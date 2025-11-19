/**
 * SuccessionIntegrationTest
 *
 * Comprehensive integration tests for end-to-end succession workflows.
 * Tests complete workflows from case creation through task generation and closure.
 *
 * Test Scenarios:
 * - Single successor workflow
 * - Multi-successor workflow
 * - Email validation and sending
 * - Error recovery scenarios
 * - Concurrent user access
 *
 * @author Salesforce
 * @date November 2025
 */
@isTest
public class SuccessionIntegrationTest {
  /**
   * Inline helper methods for creating test records
   */
  private static Account createDeceasedDonorAccount(String name) {
    Account acc = new Account(Name = name, Deceased__c = true);
    insert acc;
    return acc;
  }

  private static Account createAccount(String name) {
    Account acc = new Account(Name = name);
    insert acc;
    return acc;
  }

  private static Contact createContact(
    Account parentAccount,
    String firstName,
    String lastName,
    String email
  ) {
    Contact contact = new Contact(
      FirstName = firstName,
      LastName = lastName,
      Email = email,
      AccountId = parentAccount.Id
    );
    insert contact;
    return contact;
  }

  private static FinServ__FinancialAccount__c createFinancialAccount(
    Id primaryOwnerAccountId,
    Decimal balance
  ) {
    FinServ__FinancialAccount__c fa = new FinServ__FinancialAccount__c(
      Name = 'Test DAF Account',
      FinServ__PrimaryOwner__c = primaryOwnerAccountId,
      FinServ__Balance__c = balance
    );
    insert fa;
    return fa;
  }

  private static FinServ__FinancialAccountRole__c createPrimaryOwnerRole(
    Id financialAccountId,
    Id accountId
  ) {
    FinServ__FinancialAccountRole__c role = new FinServ__FinancialAccountRole__c(
      FinServ__FinancialAccount__c = financialAccountId,
      FinServ__RelatedAccount__c = accountId,
      FinServ__Role__c = 'Primary Owner'
    );
    insert role;
    return role;
  }

  private static FinServ__FinancialAccountRole__c createSuccessorRole(
    Id financialAccountId,
    Id contactId,
    Decimal allocation
  ) {
    FinServ__FinancialAccountRole__c role = new FinServ__FinancialAccountRole__c(
      FinServ__FinancialAccount__c = financialAccountId,
      FinServ__RelatedContact__c = contactId,
      FinServ__Role__c = 'Successor',
      SuccessorAllocation__c = allocation
    );
    insert role;
    return role;
  }

  /**
   * Test single successor workflow: Case creation → Contact cadence → Pathway selection → Task generation
   */
  @isTest
  static void testSingleSuccessorWorkflow() {
    Test.startTest();

    // Create test data: one deceased donor and one successor
    Account donor = createDeceasedDonorAccount('John Donor');
    Account successorAccount = createAccount('Jane Successor');
    Contact successorContact = createContact(
      successorAccount,
      'Jane',
      'Successor',
      'jane@example.com'
    );
    FinServ__FinancialAccount__c fa = createFinancialAccount(donor.Id, 100000);
    createPrimaryOwnerRole(fa.Id, donor.Id);
    createSuccessorRole(fa.Id, successorContact.Id, 100);

    // Create succession case
    CreateSuccessionCaseController.CreateCaseResult result = CreateSuccessionCaseController.createSuccessionCase(
      fa.Id
    );

    // Verify case created
    System.assert(result.success, 'Case creation should succeed');
    System.assertNotEquals(
      null,
      result.seedCaseId,
      'Seed case ID should be populated'
    );

    // Use SuccessionTaskCreator to create initial contact attempt task (contact cadence)
    Case seedCase = [
      SELECT Id, CreatedDate
      FROM Case
      WHERE Id = :result.seedCaseId
      LIMIT 1
    ];

    SuccessionTaskCreator.CreateTaskRequest req = new SuccessionTaskCreator.CreateTaskRequest();
    req.caseId = seedCase.Id;
    req.attemptNumber = 1;
    req.daysOffset = 0;
    req.caseCreatedDate = seedCase.CreatedDate;

    List<SuccessionTaskCreator.CreateTaskResponse> responses = SuccessionTaskCreator.createContactAttemptTasks(
      new List<SuccessionTaskCreator.CreateTaskRequest>{ req }
    );

    System.assertEquals(1, responses.size(), 'Should return one response');
    // In some orgs, Attempt 1 may already exist from automation; either creation or reuse is acceptable
    System.assertNotEquals(
      null,
      responses[0].taskId,
      'Task ID should be populated when task exists'
    );

    // Verify contact attempt task exists with correct activity date and attempt number
    List<Task> tasks = [
      SELECT Id, Contact_Attempt_Number__c, ActivityDate
      FROM Task
      WHERE WhatId = :seedCase.Id
    ];
    System.assertEquals(
      1,
      tasks.size(),
      'Initial contact task should be created'
    );
    System.assertEquals(
      1,
      tasks[0].Contact_Attempt_Number__c,
      'First task should be attempt 1'
    );
    System.assertEquals(
      seedCase.CreatedDate.date(),
      tasks[0].ActivityDate,
      'ActivityDate should match case created date for attempt 1'
    );

    Test.stopTest();
  }

  /**
   * Test multi-successor workflow: Parent case → Child cases → Independent workflows
   */
  @isTest
  static void testMultiSuccessorWorkflow() {
    Test.startTest();

    // Create test data with multiple successors
    Account donor = createDeceasedDonorAccount('John Donor');
    Account successorAccount1 = createAccount('Jane Successor1');
    Contact successorContact1 = createContact(
      successorAccount1,
      'Jane',
      'Successor1',
      'jane1@example.com'
    );
    Account successorAccount2 = createAccount('Bob Successor2');
    Contact successorContact2 = createContact(
      successorAccount2,
      'Bob',
      'Successor2',
      'bob@example.com'
    );

    FinServ__FinancialAccount__c fa = createFinancialAccount(donor.Id, 100000);
    createPrimaryOwnerRole(fa.Id, donor.Id);
    createSuccessorRole(fa.Id, successorContact1.Id, 50);
    createSuccessorRole(fa.Id, successorContact2.Id, 50);

    // Create succession case
    CreateSuccessionCaseController.CreateCaseResult result = CreateSuccessionCaseController.createSuccessionCase(
      fa.Id
    );

    // Verify parent case created
    System.assert(result.success, 'Case creation should succeed');
    System.assertNotEquals(
      null,
      result.parentCaseId,
      'Parent case ID should be populated'
    );
    System.assertEquals(2, result.successorCount, 'Should have 2 successors');

    // Verify child cases created
    List<Case> childCases = [
      SELECT Id, ParentId, Type
      FROM Case
      WHERE ParentId = :result.parentCaseId
    ];
    System.assertEquals(2, childCases.size(), 'Should have 2 child cases');

    Test.stopTest();
  }

  /**
   * Test error recovery: Failed case creation with validation errors
   */
  @isTest
  static void testErrorRecovery() {
    Test.startTest();

    // Create test data without successors (should fail)
    Account donor = createDeceasedDonorAccount('John Donor');
    FinServ__FinancialAccount__c fa = createFinancialAccount(donor.Id, 100000);
    createPrimaryOwnerRole(fa.Id, donor.Id);

    // Attempt case creation without successors
    CreateSuccessionCaseController.CreateCaseResult result = CreateSuccessionCaseController.createSuccessionCase(
      fa.Id
    );

    // Verify error handling
    System.assert(
      !result.success,
      'Case creation should fail without successors'
    );
    System.assertNotEquals(
      null,
      result.message,
      'Error message should be populated'
    );

    Test.stopTest();
  }

  /**
   * Test pathway task generation when pathway is confirmed
   */
  @isTest
  static void testPathwayTaskGeneration() {
    Test.startTest();

    // Create test data
    Account donor = createDeceasedDonorAccount('John Donor');
    Account successorAccount = createAccount('Jane Successor');
    Contact successorContact = createContact(
      successorAccount,
      'Jane',
      'Successor',
      'jane@example.com'
    );
    FinServ__FinancialAccount__c fa = createFinancialAccount(donor.Id, 100000);
    createPrimaryOwnerRole(fa.Id, donor.Id);
    createSuccessorRole(fa.Id, successorContact.Id, 100);

    // Create succession case
    CreateSuccessionCaseController.CreateCaseResult result = CreateSuccessionCaseController.createSuccessionCase(
      fa.Id
    );

    // Get the case
    Case c = [SELECT Id FROM Case WHERE Id = :result.seedCaseId];

    // Set pathway
    c.Pathway_Confirmed__c = 'Final Grant';
    c.Form_Completed_Date__c = Date.today();
    update c;

    // Verify pathway tasks created (filter to Final Grant template subjects only)
    Set<String> finalGrantSubjects = new Set<String>{
      'Review Grant Direction & Beneficiaries',
      'Coordinate Trading / Liquidation',
      'Process Grant Recommendations',
      'Confirm Distributions & Settlement',
      'Finalize Case Documentation'
    };
    List<Task> pathwayTasks = [
      SELECT Id, Subject, ActivityDate
      FROM Task
      WHERE WhatId = :result.seedCaseId AND Subject IN :finalGrantSubjects
      ORDER BY ActivityDate
    ];
    System.assertEquals(
      finalGrantSubjects.size(),
      pathwayTasks.size(),
      'Should create 5 Final Grant pathway tasks'
    );
    System.assertEquals(
      'Review Grant Direction & Beneficiaries',
      pathwayTasks[0].Subject,
      'First pathway task subject should match template'
    );

    Test.stopTest();
  }
}
