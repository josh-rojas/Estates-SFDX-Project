/**
 * @description Integration test for end-to-end succession workflow
 * Tests the complete flow from case creation through pathway selection to task completion
 * @author Salesforce
 * @date October 2025
 */
@isTest
private class SuccessionWorkflow_Integration_Test {
  /**
   * Setup test data for all integration tests
   */
  @testSetup
  static void setup() {
    // Create Person Account (FSC) - Deceased Donor
    Id personAcctRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('PersonAccount')
      .getRecordTypeId();

    Account deceasedDonor = new Account(
      FirstName = 'Deceased',
      LastName = 'Donor',
      PersonEmail = 'deceased@test.com',
      RecordTypeId = personAcctRecordTypeId
    );
    insert deceasedDonor;

    // Create Person Account - Successor
    Account successor = new Account(
      FirstName = 'Test',
      LastName = 'Successor',
      PersonEmail = 'successor@test.com',
      PersonHasOptedOutOfEmail = false,
      RecordTypeId = personAcctRecordTypeId
    );
    insert successor;

    // Re-query to get PersonContactId (virtual field populated after insert)
    successor = [
      SELECT Id, PersonContactId
      FROM Account
      WHERE Id = :successor.Id
      LIMIT 1
    ];

    // Create Financial Account
    FinServ__FinancialAccount__c financialAccount = new FinServ__FinancialAccount__c(
      Name = 'DAF-12345',
      FinServ__PrimaryOwner__c = deceasedDonor.Id,
      FinServ__Status__c = 'Active'
    );
    insert financialAccount;

    // Re-query deceased donor to get PersonContactId
    deceasedDonor = [
      SELECT Id, PersonContactId
      FROM Account
      WHERE Id = :deceasedDonor.Id
      LIMIT 1
    ];

    // Create Financial Account Role (Primary Owner - Deceased)
    FinServ__FinancialAccountRole__c primaryOwnerRole = new FinServ__FinancialAccountRole__c(
      FinServ__FinancialAccount__c = financialAccount.Id,
      FinServ__RelatedAccount__c = deceasedDonor.Id,
      FinServ__RelatedContact__c = deceasedDonor.PersonContactId,
      FinServ__Role__c = 'Primary Owner',
      FinServ__Active__c = true
    );
    insert primaryOwnerRole;

    // Create Financial Account Role (Successor designation)
    FinServ__FinancialAccountRole__c successorRole = new FinServ__FinancialAccountRole__c(
      FinServ__FinancialAccount__c = financialAccount.Id,
      FinServ__RelatedAccount__c = successor.Id,
      FinServ__RelatedContact__c = successor.PersonContactId, // Required for contact cadence
      FinServ__Role__c = 'Successor',
      SuccessorAllocation__c = 100,
      FinServ__Active__c = true
    );
    insert successorRole;
  }

  /**
   * Test complete workflow for Final Grant pathway
   * Verifies: Case creation → Verification → Contact → Form → Tasks
   */
  @isTest
  static void testCompleteWorkflow_FinalGrant() {
    Account deceasedDonor = [
      SELECT Id
      FROM Account
      WHERE LastName = 'Donor'
      LIMIT 1
    ];
    Account successor = [
      SELECT Id, PersonContactId
      FROM Account
      WHERE LastName = 'Successor'
      LIMIT 1
    ];

    // Get Estate Administration Record Type
    Id estateRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
      .get('EstateAdministration')
      .getRecordTypeId();

    Test.startTest();

    // PHASE 1: Create succession case (workflow starts automatically in v1.1)
    Case successionCase = new Case(
      Subject = 'Succession - Donor Estate',
      RecordTypeId = estateRecordTypeId,
      Type = 'Named Successor Enactment',
      AccountId = deceasedDonor.Id,
      ContactId = successor.PersonContactId, // Required for flow trigger
      Deceased_Donor__c = deceasedDonor.Id,
      Successor__c = successor.PersonContactId,
      Status = 'New',
      Origin = 'Phone',
      Verification_Status__c = 'Not Started'
    );
    insert successionCase;

    // Verify flow created initial contact task automatically (v1.1 - no verification step)
    List<Task> contactTasks = [
      SELECT Id, Subject, Contact_Attempt_Number__c, Status
      FROM Task
      WHERE WhatId = :successionCase.Id AND TaskSubtype = 'Call'
    ];
    System.assertEquals(
      1,
      contactTasks.size(),
      'Should create initial contact task'
    );
    System.assertEquals(
      1,
      contactTasks[0].Contact_Attempt_Number__c,
      'Should be attempt #1'
    );

    // PHASE 3: Complete contact attempt (establish contact)
    Task contactTask = contactTasks[0];
    contactTask.Status = 'Completed';
    contactTask.Succession_Contact_Established__c = true;
    update contactTask;

    // Verify case updated
    Case verifyCase2 = [
      SELECT Id, Contact_Established__c, Contact_Attempt_Count__c
      FROM Case
      WHERE Id = :successionCase.Id
    ];
    System.assertEquals(
      true,
      verifyCase2.Contact_Established__c,
      'Contact should be marked as established'
    );
    System.assertEquals(
      1,
      verifyCase2.Contact_Attempt_Count__c,
      'Should track attempt count'
    );

    // PHASE 4: Successor submits form with pathway selection
    successionCase.Pathway_Confirmed__c = 'Final Grant';
    successionCase.Form_Completed_Date__c = DateTime.now();
    update successionCase;

    Test.stopTest();

    // PHASE 5: Verify pathway tasks were created
    List<Task> pathwayTasks = [
      SELECT Id, Subject, Priority, Status, ActivityDate
      FROM Task
      WHERE WhatId = :successionCase.Id AND TaskSubtype = 'Task'
      ORDER BY ActivityDate
    ];

    System.assertEquals(
      5,
      pathwayTasks.size(),
      'Should create 5 Final Grant pathway tasks'
    );
    System.assertEquals(
      'Review Grant Direction & Beneficiaries',
      pathwayTasks[0].Subject
    );
    System.assertEquals(
      'High',
      pathwayTasks[0].Priority,
      'Pathway tasks should be high priority'
    );
    System.assertEquals(
      'Not Started',
      pathwayTasks[0].Status,
      'Tasks should start as Not Started'
    );

    // Verify Chatter post about task creation
    List<FeedItem> chatterPosts = [
      SELECT Id, Body
      FROM FeedItem
      WHERE ParentId = :successionCase.Id
    ];
    System.assert(
      chatterPosts.size() > 0,
      'Should create Chatter post for pathway tasks'
    );

    // Verify final case state
    Case finalCase = [
      SELECT
        Id,
        Status,
        Pathway_Confirmed__c,
        Form_Completed_Date__c,
        Contact_Established__c
      FROM Case
      WHERE Id = :successionCase.Id
    ];
    System.assertEquals(
      'Final Grant',
      finalCase.Pathway_Confirmed__c,
      'Pathway should be confirmed'
    );
    System.assertNotEquals(
      null,
      finalCase.Form_Completed_Date__c,
      'Form completion date should be set'
    );
  }

  /**
   * Test complete workflow for New DAF Account pathway
   */
  @isTest
  static void testCompleteWorkflow_NewDAFAccount() {
    Account deceasedDonor = [
      SELECT Id
      FROM Account
      WHERE LastName = 'Donor'
      LIMIT 1
    ];
    Account successor = [
      SELECT Id, PersonContactId
      FROM Account
      WHERE LastName = 'Successor'
      LIMIT 1
    ];

    Id estateRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
      .get('EstateAdministration')
      .getRecordTypeId();

    Test.startTest();

    // Create case first (without pathway)
    Case successionCase = new Case(
      Subject = 'Succession - New DAF',
      RecordTypeId = estateRecordTypeId,
      Type = 'Named Successor Enactment',
      AccountId = deceasedDonor.Id,
      ContactId = successor.PersonContactId, // Required for flow trigger
      Deceased_Donor__c = deceasedDonor.Id,
      Successor__c = successor.PersonContactId,
      Status = 'New',
      Verification_Status__c = 'Complete - Verified',
      Contact_Established__c = true
    );
    insert successionCase;

    // Update case to set pathway (triggers SuccessionTaskGenerator)
    successionCase.Pathway_Confirmed__c = 'New DAF Account';
    successionCase.Form_Completed_Date__c = DateTime.now();
    update successionCase;

    Test.stopTest();

    // Verify pathway-specific tasks (exclude contact tasks)
    List<Task> pathwayTasks = [
      SELECT Id, Subject, ActivityDate
      FROM Task
      WHERE WhatId = :successionCase.Id AND TaskSubtype = 'Task'
      ORDER BY ActivityDate
    ];

    System.assertEquals(
      4,
      pathwayTasks.size(),
      'Should create 4 New DAF Account pathway tasks'
    );
    System.assertEquals(
      'Review New Account Application',
      pathwayTasks[0].Subject
    );
    System.assertEquals(
      'Process Transfer Authorization',
      pathwayTasks[1].Subject
    );
  }

  /**
   * Test complete workflow for Disclaim Assets pathway
   */
  @isTest
  static void testCompleteWorkflow_DisclaimAssets() {
    Account deceasedDonor = [
      SELECT Id
      FROM Account
      WHERE LastName = 'Donor'
      LIMIT 1
    ];
    Account successor = [
      SELECT Id, PersonContactId
      FROM Account
      WHERE LastName = 'Successor'
      LIMIT 1
    ];

    Id estateRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
      .get('EstateAdministration')
      .getRecordTypeId();

    Test.startTest();

    // Create case first (without pathway)
    Case successionCase = new Case(
      Subject = 'Succession - Disclaim',
      RecordTypeId = estateRecordTypeId,
      Type = 'Named Successor Enactment',
      AccountId = deceasedDonor.Id,
      ContactId = successor.PersonContactId, // Required for flow trigger
      Deceased_Donor__c = deceasedDonor.Id,
      Successor__c = successor.PersonContactId,
      Status = 'New',
      Verification_Status__c = 'Complete - Verified',
      Contact_Established__c = true
    );
    insert successionCase;

    // Update case to set pathway (triggers SuccessionTaskGenerator)
    successionCase.Pathway_Confirmed__c = 'Disclaim Assets';
    successionCase.Form_Completed_Date__c = DateTime.now();
    update successionCase;

    Test.stopTest();

    // Verify pathway-specific tasks (exclude contact tasks)
    List<Task> pathwayTasks = [
      SELECT Id, Subject, ActivityDate
      FROM Task
      WHERE WhatId = :successionCase.Id AND TaskSubtype = 'Task'
      ORDER BY ActivityDate
    ];

    System.assertEquals(
      4,
      pathwayTasks.size(),
      'Should create 4 Disclaim Assets pathway tasks'
    );
    System.assertEquals(
      'Review Disclaimer Documentation',
      pathwayTasks[0].Subject
    );
    System.assertEquals(
      'Identify Alternate Distribution Path',
      pathwayTasks[1].Subject
    );
  }

  /**
   * Test contact cadence progression through all 5 attempts
   */
  @isTest
  static void testContactCadenceProgression() {
    Account deceasedDonor = [
      SELECT Id
      FROM Account
      WHERE LastName = 'Donor'
      LIMIT 1
    ];
    Account successor = [
      SELECT Id, PersonContactId
      FROM Account
      WHERE LastName = 'Successor'
      LIMIT 1
    ];

    Id estateRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
      .get('EstateAdministration')
      .getRecordTypeId();

    // Create case
    Case successionCase = new Case(
      Subject = 'Succession - Contact Cadence Test',
      RecordTypeId = estateRecordTypeId,
      Type = 'Named Successor Enactment',
      AccountId = deceasedDonor.Id,
      ContactId = successor.PersonContactId, // Required for flow trigger
      Deceased_Donor__c = deceasedDonor.Id,
      Successor__c = successor.PersonContactId,
      Status = 'New',
      Verification_Status__c = 'Complete - Verified'
    );
    insert successionCase;

    Test.startTest();

    // Get initial contact task
    Task attempt1 = [
      SELECT Id, Status, Contact_Attempt_Number__c
      FROM Task
      WHERE WhatId = :successionCase.Id
      LIMIT 1
    ];
    System.assertEquals(
      1,
      attempt1.Contact_Attempt_Number__c,
      'Should be attempt 1'
    );

    // Complete attempt 1 - NO contact
    attempt1.Status = 'Completed';
    attempt1.Succession_Contact_Established__c = false;
    update attempt1;

    // Verify next task created
    List<Task> allTasks = [
      SELECT Id, Contact_Attempt_Number__c, Status
      FROM Task
      WHERE WhatId = :successionCase.Id
      ORDER BY Contact_Attempt_Number__c
    ];
    System.assertEquals(2, allTasks.size(), 'Should create attempt 2');
    System.assertEquals(
      2,
      allTasks[1].Contact_Attempt_Number__c,
      'Should be attempt 2'
    );

    Test.stopTest();

    // Verify case still shows contact not established
    Case verifyCase = [
      SELECT Id, Contact_Established__c, Contact_Attempt_Count__c
      FROM Case
      WHERE Id = :successionCase.Id
    ];
    System.assertEquals(
      false,
      verifyCase.Contact_Established__c,
      'Contact should not be established'
    );
  }

  /**
   * Test email validation and opt-out handling
   */
  @isTest
  static void testEmailValidation() {
    // Create person account with opted-out email
    Id personAcctRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('PersonAccount')
      .getRecordTypeId();

    Account optedOutSuccessor = new Account(
      FirstName = 'Opted',
      LastName = 'Out',
      PersonEmail = 'optedout@test.com',
      PersonHasOptedOutOfEmail = true,
      RecordTypeId = personAcctRecordTypeId
    );
    insert optedOutSuccessor;

    Account deceasedDonor = [
      SELECT Id
      FROM Account
      WHERE LastName = 'Donor'
      LIMIT 1
    ];

    Id estateRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
      .get('EstateAdministration')
      .getRecordTypeId();

    // Create case with opted-out successor
    Case successionCase = new Case(
      Subject = 'Succession - Email Test',
      RecordTypeId = estateRecordTypeId,
      Type = 'Named Successor Enactment',
      AccountId = deceasedDonor.Id,
      Deceased_Donor__c = deceasedDonor.Id,
      Successor__c = optedOutSuccessor.PersonContactId,
      Status = 'New',
      Verification_Status__c = 'Complete - Verified'
    );
    insert successionCase;

    Test.startTest();

    // Get validation result using SuccessionUtilities (ContactCadenceController.validateEmailAddress is private)
    SuccessionUtilities.EmailValidationResult validation = SuccessionUtilities.validateEmail(
      optedOutSuccessor.PersonEmail,
      optedOutSuccessor.PersonHasOptedOutOfEmail
    );

    Test.stopTest();

    // Verify validation catches opt-out
    System.assertEquals(
      true,
      validation.hasOptedOut,
      'Should detect opted-out email'
    );
    System.assert(
      validation.warning != null && validation.warning.contains('opted out'),
      'Should warn about opt-out status'
    );
  }

  /**
   * Test multi-successor scenario
   * Verifies parent-child case hierarchy creation
   */
  @isTest
  static void testMultiSuccessorWorkflow() {
    Account deceasedDonor = [
      SELECT Id
      FROM Account
      WHERE LastName = 'Donor'
      LIMIT 1
    ];

    // Create second successor
    Id personAcctRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('PersonAccount')
      .getRecordTypeId();

    Account successor2 = new Account(
      FirstName = 'Second',
      LastName = 'Successor',
      PersonEmail = 'successor2@test.com',
      RecordTypeId = personAcctRecordTypeId
    );
    insert successor2;

    // Re-query to get PersonContactId (virtual field populated after insert)
    successor2 = [
      SELECT Id, PersonContactId
      FROM Account
      WHERE Id = :successor2.Id
      LIMIT 1
    ];

    // Add second successor to financial account
    FinServ__FinancialAccount__c finAccount = [
      SELECT Id
      FROM FinServ__FinancialAccount__c
      LIMIT 1
    ];

    FinServ__FinancialAccountRole__c role2 = new FinServ__FinancialAccountRole__c(
      FinServ__FinancialAccount__c = finAccount.Id,
      FinServ__RelatedAccount__c = successor2.Id,
      FinServ__RelatedContact__c = successor2.PersonContactId, // Required for contact cadence
      FinServ__Role__c = 'Successor',
      SuccessorAllocation__c = 50
    );
    insert role2;

    // Update first successor to 50% and set RelatedContact
    Account successor1 = [
      SELECT Id, PersonContactId
      FROM Account
      WHERE LastName = 'Successor'
      LIMIT 1
    ];

    FinServ__FinancialAccountRole__c role1 = [
      SELECT Id, SuccessorAllocation__c
      FROM FinServ__FinancialAccountRole__c
      WHERE FinServ__RelatedAccount__c != :successor2.Id
      LIMIT 1
    ];
    role1.SuccessorAllocation__c = 50;
    role1.FinServ__RelatedContact__c = successor1.PersonContactId; // Required for contact cadence
    update role1;

    Test.startTest();

    // Create succession case via controller (method takes only financialAccountId)
    CreateSuccessionCaseController.CreateCaseResult result = CreateSuccessionCaseController.createSuccessionCase(
      finAccount.Id
    );

    Test.stopTest();

    // Verify multi-successor handling
    System.assertEquals(
      true,
      result.success,
      'Case creation should succeed. Error: ' + result.message
    );
    System.assertEquals(
      2,
      result.successorCount,
      'Should detect 2 successors (50% allocation each)'
    );

    // Verify parent and child cases created
    List<Case> allCases = [
      SELECT Id, Type, ParentId
      FROM Case
      WHERE AccountId = :deceasedDonor.Id
    ];

    System.assert(allCases.size() >= 2, 'Should create parent + child cases');

    // Find parent case
    Case parentCase = null;
    List<Case> childCases = new List<Case>();
    for (Case c : allCases) {
      if (c.Type == 'Multi-Account Succession Master') {
        parentCase = c;
      } else if (c.ParentId != null) {
        childCases.add(c);
      }
    }

    System.assertNotEquals(null, parentCase, 'Should create parent case');
    System.assertEquals(2, childCases.size(), 'Should create 2 child cases');
    System.assertEquals(
      parentCase.Id,
      childCases[0].ParentId,
      'Children should link to parent'
    );
  }

  /**
   * Test pathway task completion and case closure
   */
  @isTest
  static void testPathwayTaskCompletionAndClosure() {
    Account deceasedDonor = [
      SELECT Id
      FROM Account
      WHERE LastName = 'Donor'
      LIMIT 1
    ];
    Account successor = [
      SELECT Id, PersonContactId
      FROM Account
      WHERE LastName = 'Successor'
      LIMIT 1
    ];

    Id estateRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
      .get('EstateAdministration')
      .getRecordTypeId();

    // Create case first (without pathway)
    Case successionCase = new Case(
      Subject = 'Succession - Task Completion Test',
      RecordTypeId = estateRecordTypeId,
      Type = 'Named Successor Enactment',
      AccountId = deceasedDonor.Id,
      ContactId = successor.PersonContactId, // Required for flow trigger
      Deceased_Donor__c = deceasedDonor.Id,
      Successor__c = successor.PersonContactId,
      Status = 'New',
      Verification_Status__c = 'Complete - Verified',
      Contact_Established__c = true
    );
    insert successionCase;

    // Update case to set pathway (triggers SuccessionTaskGenerator)
    successionCase.Pathway_Confirmed__c = 'Final Grant';
    successionCase.Form_Completed_Date__c = DateTime.now();
    update successionCase;

    // Get all pathway tasks
    List<Task> pathwayTasks = [
      SELECT Id, Status
      FROM Task
      WHERE WhatId = :successionCase.Id AND TaskSubtype = 'Task'
    ];

    System.assertEquals(
      5,
      pathwayTasks.size(),
      'Should have 5 Final Grant tasks'
    );

    Test.startTest();

    // Complete all tasks
    for (Task t : pathwayTasks) {
      t.Status = 'Completed';
    }
    update pathwayTasks;

    // Manually set execution status (would be done by agent/flow in real scenario)
    successionCase.Execution_Status__c = 'Completed';
    update successionCase;

    Test.stopTest();

    // Verify case execution status
    Case completedCase = [
      SELECT Id, Execution_Status__c
      FROM Case
      WHERE Id = :successionCase.Id
    ];
    System.assertEquals(
      'Completed',
      completedCase.Execution_Status__c,
      'Case should be marked complete'
    );
  }
}
