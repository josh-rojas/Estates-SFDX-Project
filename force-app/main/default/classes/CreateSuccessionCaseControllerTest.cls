/**
 * CreateSuccessionCaseControllerTest
 *
 * Test class for CreateSuccessionCaseController Quick Action functionality.
 * Tests validation scenarios, single/multi-successor cases, and async flow orchestration.
 *
 * @author Claude Code
 * @date 2025-01-27
 */
@isTest
public class CreateSuccessionCaseControllerTest {
  /**
   * Test data setup for all test methods
   */
  @TestSetup
  static void setupTestData() {
    // Get Person Account RecordType
    RecordType personAccountRT = [
      SELECT Id 
      FROM RecordType 
      WHERE SObjectType = 'Account' 
      AND IsPersonType = true 
      LIMIT 1
    ];
    
    // Create Person Accounts (deceased donor and successors)
    List<Account> accounts = new List<Account>();

    // Deceased donor account
    Account deceasedDonor = new Account(
      RecordTypeId = personAccountRT.Id,
      FirstName = 'John',
      LastName = 'Deceased',
      PersonEmail = 'john.deceased@example.com',
      PersonHasOptedOutOfEmail = false,
      Deceased__c = true
    );
    accounts.add(deceasedDonor);

    // Successor accounts
    Account successor1 = new Account(
      RecordTypeId = personAccountRT.Id,
      FirstName = 'Jane',
      LastName = 'Successor1',
      PersonEmail = 'jane.successor1@example.com',
      PersonHasOptedOutOfEmail = false
    );
    accounts.add(successor1);

    Account successor2 = new Account(
      RecordTypeId = personAccountRT.Id,
      FirstName = 'Bob',
      LastName = 'Successor2',
      PersonEmail = 'bob.successor2@example.com',
      PersonHasOptedOutOfEmail = false
    );
    accounts.add(successor2);

    insert accounts;

    // Create FinancialAccount
    FinServ__FinancialAccount__c financialAccount = new FinServ__FinancialAccount__c(
      Name = 'Test DAF Account',
      FinServ__FinancialAccountNumber__c = 'DAF-12345',
      FinServ__Balance__c = 100000
    );
    insert financialAccount;

    // Create FinancialAccountRoles
    List<FinServ__FinancialAccountRole__c> roles = new List<FinServ__FinancialAccountRole__c>();

    // Deceased primary owner (with EndDate to indicate deceased)
    FinServ__FinancialAccountRole__c primaryOwner = new FinServ__FinancialAccountRole__c(
      FinServ__FinancialAccount__c = financialAccount.Id,
      FinServ__RelatedAccount__c = deceasedDonor.Id,
      FinServ__Role__c = 'Primary Owner',
      FinServ__Active__c = true,
      FinServ__EndDate__c = Date.today().addDays(-30) // Deceased 30 days ago
    );
    roles.add(primaryOwner);

    // Successor 1
    FinServ__FinancialAccountRole__c successorRole1 = new FinServ__FinancialAccountRole__c(
      FinServ__FinancialAccount__c = financialAccount.Id,
      FinServ__RelatedContact__c = successor1.PersonContactId,
      FinServ__Role__c = 'Successor',
      FinServ__Active__c = true,
      SuccessorAllocation__c = 50
    );
    roles.add(successorRole1);

    // Successor 2
    FinServ__FinancialAccountRole__c successorRole2 = new FinServ__FinancialAccountRole__c(
      FinServ__FinancialAccount__c = financialAccount.Id,
      FinServ__RelatedContact__c = successor2.PersonContactId,
      FinServ__Role__c = 'Successor',
      FinServ__Active__c = true,
      SuccessorAllocation__c = 50
    );
    roles.add(successorRole2);

    insert roles;
  }

  /**
   * Test single successor case creation
   */
  @isTest
  static void testSingleSuccessorCaseCreation() {
    // Get test data
    FinServ__FinancialAccount__c fa = [
      SELECT Id
      FROM FinServ__FinancialAccount__c
      LIMIT 1
    ];

    // Remove one successor to test single successor scenario
    List<FinServ__FinancialAccountRole__c> successors = [
      SELECT Id
      FROM FinServ__FinancialAccountRole__c
      WHERE FinServ__Role__c = 'Successor'
    ];
    delete successors[1]; // Remove second successor

    Test.startTest();
    CreateSuccessionCaseController.CreateCaseResult result = CreateSuccessionCaseController.createSuccessionCase(
      fa.Id
    );
    Test.stopTest();

    // Verify result
    System.assert(result.success, 'Case creation should succeed');
    System.assertNotEquals(
      null,
      result.seedCaseId,
      'Seed case ID should be returned'
    );
    System.assertEquals(1, result.successorCount, 'Should detect 1 successor');

    // Verify case was created
    List<Case> cases = [
      SELECT
        Id,
        Type,
        Status,
        Verification_Status__c,
        FinServ__FinancialAccount__c,
        AccountId,
        ContactId,
        Subject
      FROM Case
      WHERE FinServ__FinancialAccount__c = :fa.Id
    ];

    System.assertEquals(1, cases.size(), 'Should create 1 case');
    System.assertEquals('Named Successor Enactment', cases[0].Type);
    System.assertEquals('Complete - Verified', cases[0].Verification_Status__c);
    System.assertEquals(fa.Id, cases[0].FinServ__FinancialAccount__c);

    // Verify ContactId mapping (should be first successor's Contact ID)
    Account firstSuccessor = [
      SELECT PersonContactId
      FROM Account
      WHERE LastName = 'Successor1'
      LIMIT 1
    ];
    System.assertEquals(firstSuccessor.PersonContactId, cases[0].ContactId);

    // Verify AccountId mapping (should be deceased donor's Account)
    Account deceasedDonor = [
      SELECT Id
      FROM Account
      WHERE LastName = 'Deceased'
      LIMIT 1
    ];
    System.assertEquals(deceasedDonor.Id, cases[0].AccountId);
  }

  /**
   * Test multiple successors case creation with flow orchestration
   */
  @isTest
  static void testMultipleSuccessorsCaseCreation() {
    // Get test data
    FinServ__FinancialAccount__c fa = [
      SELECT Id
      FROM FinServ__FinancialAccount__c
      LIMIT 1
    ];

    Test.startTest();
    CreateSuccessionCaseController.CreateCaseResult result = CreateSuccessionCaseController.createSuccessionCase(
      fa.Id
    );
    Test.stopTest(); // Forces async flows to complete

    // Verify result
    System.assert(result.success, 'Case creation should succeed');
    System.assertNotEquals(
      null,
      result.seedCaseId,
      'Seed case ID should be returned'
    );
    System.assertEquals(2, result.successorCount, 'Should detect 2 successors');

    // Verify seed case was created
    List<Case> seedCases = [
      SELECT
        Id,
        Type,
        Status,
        Verification_Status__c,
        FinServ__FinancialAccount__c,
        AccountId,
        ContactId,
        Subject,
        ParentId
      FROM Case
      WHERE
        FinServ__FinancialAccount__c = :fa.Id
        AND Type = 'Named Successor Enactment'
        AND ParentId = NULL
    ];

    System.assertEquals(1, seedCases.size(), 'Should create 1 seed case');
    System.assertEquals(
      'Complete - Verified',
      seedCases[0].Verification_Status__c
    );

    // Verify parent case was created by flow
    List<Case> parentCases = [
      SELECT Id, Type, Status, Subject
      FROM Case
      WHERE
        FinServ__FinancialAccount__c = :fa.Id
        AND Type = 'Multi-Account Succession Master'
    ];

    System.assertEquals(1, parentCases.size(), 'Should create 1 parent case');
    System.assertEquals('In Progress', parentCases[0].Status);

    // Verify child cases were created by flow
    List<Case> childCases = [
      SELECT Id, Type, Status, ParentId, ContactId
      FROM Case
      WHERE
        FinServ__FinancialAccount__c = :fa.Id
        AND Type = 'Named Successor Enactment'
        AND ParentId != NULL
    ];

    System.assertEquals(2, childCases.size(), 'Should create 2 child cases');
    System.assertEquals(
      parentCases[0].Id,
      childCases[0].ParentId,
      'Child should link to parent'
    );
    System.assertEquals(
      parentCases[0].Id,
      childCases[1].ParentId,
      'Child should link to parent'
    );
  }

  /**
   * Test idempotency - prevent duplicate cases
   */
  @isTest
  static void testIdempotencyCheck() {
    // Get test data
    FinServ__FinancialAccount__c fa = [
      SELECT Id
      FROM FinServ__FinancialAccount__c
      LIMIT 1
    ];

    // Create first case
    Test.startTest();
    CreateSuccessionCaseController.CreateCaseResult result1 = CreateSuccessionCaseController.createSuccessionCase(
      fa.Id
    );
    Test.stopTest();

    System.assert(result1.success, 'First case creation should succeed');

    // Try to create second case
    CreateSuccessionCaseController.CreateCaseResult result2 = CreateSuccessionCaseController.createSuccessionCase(
      fa.Id
    );

    System.assert(!result2.success, 'Second case creation should fail');
    System.assert(
      result2.message.contains('already exists'),
      'Should return duplicate error'
    );
  }

  /**
   * Test validation - no deceased owner
   */
  @isTest
  static void testNoDeceasedOwnerValidation() {
    // Get test data and remove EndDate to simulate no deceased owner
    FinServ__FinancialAccount__c fa = [
      SELECT Id
      FROM FinServ__FinancialAccount__c
      LIMIT 1
    ];

    List<FinServ__FinancialAccountRole__c> primaryRoles = [
      SELECT Id
      FROM FinServ__FinancialAccountRole__c
      WHERE FinServ__Role__c LIKE '%Primary%'
    ];

    for (FinServ__FinancialAccountRole__c role : primaryRoles) {
      role.FinServ__EndDate__c = null; // Remove EndDate
    }
    update primaryRoles;

    Test.startTest();
    CreateSuccessionCaseController.CreateCaseResult result = CreateSuccessionCaseController.createSuccessionCase(
      fa.Id
    );
    Test.stopTest();

    System.assert(!result.success, 'Should fail without deceased owner');
    System.assert(
      result.message.contains('No deceased primary owner'),
      'Should return deceased owner error'
    );
  }

  /**
   * Test validation - no successors
   */
  @isTest
  static void testNoSuccessorsValidation() {
    // Get test data and remove successors
    FinServ__FinancialAccount__c fa = [
      SELECT Id
      FROM FinServ__FinancialAccount__c
      LIMIT 1
    ];

    List<FinServ__FinancialAccountRole__c> successorRoles = [
      SELECT Id
      FROM FinServ__FinancialAccountRole__c
      WHERE FinServ__Role__c = 'Successor'
    ];
    delete successorRoles;

    Test.startTest();
    CreateSuccessionCaseController.CreateCaseResult result = CreateSuccessionCaseController.createSuccessionCase(
      fa.Id
    );
    Test.stopTest();

    System.assert(!result.success, 'Should fail without successors');
    System.assert(
      result.message.contains('No active successors'),
      'Should return successors error'
    );
  }

  /**
   * Test allocation validation - invalid totals
   */
  @isTest
  static void testAllocationValidation() {
    // Get test data and set invalid allocations
    FinServ__FinancialAccount__c fa = [
      SELECT Id
      FROM FinServ__FinancialAccount__c
      LIMIT 1
    ];

    List<FinServ__FinancialAccountRole__c> successorRoles = [
      SELECT Id, SuccessorAllocation__c
      FROM FinServ__FinancialAccountRole__c
      WHERE FinServ__Role__c = 'Successor'
    ];

    // Set invalid allocations (should sum to 100% but we'll set to 80%)
    successorRoles[0].SuccessorAllocation__c = 40;
    successorRoles[1].SuccessorAllocation__c = 40;
    update successorRoles;

    Test.startTest();
    CreateSuccessionCaseController.CreateCaseResult result = CreateSuccessionCaseController.createSuccessionCase(
      fa.Id
    );
    Test.stopTest();

    System.assert(!result.success, 'Should fail with invalid allocations');
    System.assert(
      result.message.contains('must sum to 100%'),
      'Should return allocation error'
    );
    System.assert(result.message.contains('80%'), 'Should show current total');
  }

  /**
   * Test allocation validation - null allocations (should default to 0)
   */
  @isTest
  static void testNullAllocationValidation() {
    // Get test data and set null allocations
    FinServ__FinancialAccount__c fa = [
      SELECT Id
      FROM FinServ__FinancialAccount__c
      LIMIT 1
    ];

    List<FinServ__FinancialAccountRole__c> successorRoles = [
      SELECT Id, SuccessorAllocation__c
      FROM FinServ__FinancialAccountRole__c
      WHERE FinServ__Role__c = 'Successor'
    ];

    // Set null allocations
    for (FinServ__FinancialAccountRole__c role : successorRoles) {
      role.SuccessorAllocation__c = null;
    }
    update successorRoles;

    Test.startTest();
    CreateSuccessionCaseController.CreateCaseResult result = CreateSuccessionCaseController.createSuccessionCase(
      fa.Id
    );
    Test.stopTest();

    System.assert(!result.success, 'Should fail with null allocations');
    System.assert(
      result.message.contains('must sum to 100%'),
      'Should return allocation error'
    );
    System.assert(
      result.message.contains('0%'),
      'Should show current total as 0%'
    );
  }

  /**
   * Test exception handling
   */
  @isTest
  static void testExceptionHandling() {
    // Test with invalid FinancialAccount ID
    Test.startTest();
    CreateSuccessionCaseController.CreateCaseResult result = CreateSuccessionCaseController.createSuccessionCase(
      '001000000000000'
    ); // Invalid ID
    Test.stopTest();

    System.assert(!result.success, 'Should fail with invalid ID');
    System.assert(
      result.message.contains('Error creating succession case'),
      'Should return error message'
    );
  }
}


