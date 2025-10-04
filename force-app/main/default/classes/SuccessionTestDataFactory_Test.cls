/**
 * @description Test class for SuccessionTestDataFactory
 * @author Salesforce Architecture Team
 * @date 2025-01-31
 *
 * Tests all builder classes, scenario generators, and data integrity validation.
 * Ensures factory produces BRD-compliant test data with proper relationships.
 */
@IsTest
private class SuccessionTestDataFactory_Test {
  // ==================== BUILDER TESTS ====================

  @IsTest
  static void testDeceasedDonorBuilder_Defaults() {
    Test.startTest();
    Account donor = new SuccessionTestDataFactory.DeceasedDonorBuilder()
      .buildAndInsert();
    Test.stopTest();

    donor = [
      SELECT
        Id,
        FirstName,
        LastName,
        Type,
        Deceased__c,
        Date_of_Death__c,
        PersonEmail,
        PersonMailingCity,
        FinServ__NetWorth__c
      FROM Account
      WHERE Id = :donor.Id
    ];

    System.assertEquals('Donor', donor.Type, 'Should be Donor type');
    System.assertEquals(true, donor.Deceased__c, 'Should be marked deceased');
    System.assertNotEquals(
      null,
      donor.Date_of_Death__c,
      'Should have death date'
    );
    System.assertNotEquals(null, donor.PersonEmail, 'Should have email');
    System.assert(donor.FinServ__NetWorth__c > 0, 'Should have net worth');
  }

  @IsTest
  static void testDeceasedDonorBuilder_CustomValues() {
    Test.startTest();
    Account donor = new SuccessionTestDataFactory.DeceasedDonorBuilder()
      .withName('John', 'Doe')
      .withNetWorth(10000000)
      .withDateOfDeath(Date.today().addDays(-60))
      .withAddress('Boston', 'MA')
      .asPremierDonor()
      .buildAndInsert();
    Test.stopTest();

    donor = [
      SELECT
        Id,
        FirstName,
        LastName,
        PersonMailingCity,
        PersonMailingState,
        FinServ__NetWorth__c,
        Self_Qualified_Premier__c,
        FinServ__ClientCategory__c
      FROM Account
      WHERE Id = :donor.Id
    ];

    System.assertEquals(
      'John',
      donor.FirstName,
      'Should have custom first name'
    );
    System.assertEquals('Doe', donor.LastName, 'Should have custom last name');
    System.assertEquals(
      'Boston',
      donor.PersonMailingCity,
      'Should have custom city'
    );
    System.assertEquals(
      'MA',
      donor.PersonMailingState,
      'Should have custom state'
    );
    System.assertEquals(
      10000000,
      donor.FinServ__NetWorth__c,
      'Should have custom net worth'
    );
    System.assertEquals(
      true,
      donor.Self_Qualified_Premier__c,
      'Should be self-qualified premier'
    );
    System.assertEquals(
      'Platinum',
      donor.FinServ__ClientCategory__c,
      'Should be Platinum category'
    );
  }

  @IsTest
  static void testSuccessorBuilder_Defaults() {
    Test.startTest();
    Account successor = new SuccessionTestDataFactory.SuccessorBuilder()
      .buildAndInsert();
    Test.stopTest();

    successor = [
      SELECT Id, FirstName, LastName, Type, Deceased__c, PersonEmail
      FROM Account
      WHERE Id = :successor.Id
    ];

    System.assertEquals('Prospect', successor.Type, 'Should be Prospect type');
    System.assertEquals(false, successor.Deceased__c, 'Should not be deceased');
    System.assertNotEquals(null, successor.PersonEmail, 'Should have email');
  }

  @IsTest
  static void testSuccessorBuilder_UnresponsiveProfile() {
    Test.startTest();
    Account successor = new SuccessionTestDataFactory.SuccessorBuilder()
      .withName('Jane', 'Smith')
      .asUnresponsive()
      .buildAndInsert();
    Test.stopTest();

    successor = [
      SELECT Id, FirstName, LastName, PersonEmail, PersonMobilePhone
      FROM Account
      WHERE Id = :successor.Id
    ];

    System.assertEquals('Jane', successor.FirstName, 'Should have custom name');
    System.assertEquals(
      null,
      successor.PersonEmail,
      'Should not have email (unresponsive)'
    );
    System.assertEquals(
      null,
      successor.PersonMobilePhone,
      'Should not have phone (unresponsive)'
    );
  }

  @IsTest
  static void testAdvisorFirmBuilder_Defaults() {
    Test.startTest();
    Account advisor = new SuccessionTestDataFactory.AdvisorFirmBuilder()
      .buildAndInsert();
    Test.stopTest();

    advisor = [
      SELECT Id, Name, Type, BillingCity, AS_Segment__c
      FROM Account
      WHERE Id = :advisor.Id
    ];

    System.assertEquals('Advisor', advisor.Type, 'Should be Advisor type');
    System.assertNotEquals(null, advisor.AS_Segment__c, 'Should have segment');
  }

  @IsTest
  static void testFinancialAccountBuilder_Defaults() {
    Account donor = new SuccessionTestDataFactory.DeceasedDonorBuilder()
      .buildAndInsert();

    Test.startTest();
    FinServ__FinancialAccount__c daf = new SuccessionTestDataFactory.FinancialAccountBuilder(
        donor.Id
      )
      .buildAndInsert();
    Test.stopTest();

    daf = [
      SELECT
        Id,
        Name,
        FinServ__FinancialAccountType__c,
        Program__c,
        FinServ__Balance__c,
        FinServ__PrimaryOwner__c
      FROM FinServ__FinancialAccount__c
      WHERE Id = :daf.Id
    ];

    System.assertEquals(
      'DAF/Donor Advised Fund',
      daf.FinServ__FinancialAccountType__c,
      'Should be DAF type'
    );
    System.assertEquals('ASDAF', daf.Program__c, 'Should default to ASDAF');
    System.assertEquals(
      donor.Id,
      daf.FinServ__PrimaryOwner__c,
      'Should link to primary owner'
    );
    System.assert(daf.FinServ__Balance__c > 0, 'Should have balance');
  }

  @IsTest
  static void testFinancialAccountBuilder_PMAProgram() {
    Account donor = new SuccessionTestDataFactory.DeceasedDonorBuilder()
      .buildAndInsert();

    Test.startTest();
    FinServ__FinancialAccount__c daf = new SuccessionTestDataFactory.FinancialAccountBuilder(
        donor.Id
      )
      .withProgram('PMA')
      .withBalance(3000000)
      .buildAndInsert();
    Test.stopTest();

    daf = [
      SELECT Id, Program__c, Separately_Managed_Account__c
      FROM FinServ__FinancialAccount__c
      WHERE Id = :daf.Id
    ];

    System.assertEquals('PMA', daf.Program__c, 'Should be PMA program');
    System.assertEquals(
      true,
      daf.Separately_Managed_Account__c,
      'PMA should set SMA flag'
    );
    // Note: SC_Premier_Service_DST__c is a formula field driven by Advisor flags
    // It requires FinAcct_Update_Batch to run after Advisor.SCF_Premier_Advisor__c is set
  }

  @IsTest
  static void testFinancialAccountRoleBuilder_SuccessorRole() {
    Account donor = new SuccessionTestDataFactory.DeceasedDonorBuilder()
      .buildAndInsert();
    Account successor = new SuccessionTestDataFactory.SuccessorBuilder()
      .buildAndInsert();
    FinServ__FinancialAccount__c daf = new SuccessionTestDataFactory.FinancialAccountBuilder(
        donor.Id
      )
      .buildAndInsert();

    Test.startTest();
    FinServ__FinancialAccountRole__c role = new SuccessionTestDataFactory.FinancialAccountRoleBuilder(
        daf.Id
      )
      .asSuccessor(successor.Id)
      .withAllocation(100)
      .buildAndInsert();
    Test.stopTest();

    role = [
      SELECT Id, FinServ__Role__c, FinServ__Active__c, SuccessorAllocation__c
      FROM FinServ__FinancialAccountRole__c
      WHERE Id = :role.Id
    ];

    System.assertEquals(
      'Successor',
      role.FinServ__Role__c,
      'Should be Successor role'
    );
    System.assertEquals(true, role.FinServ__Active__c, 'Should be active');
    System.assertEquals(
      100,
      role.SuccessorAllocation__c,
      'Should have 100% allocation'
    );
  }

  @IsTest
  static void testSuccessionCaseBuilder_Defaults() {
    Account donor = new SuccessionTestDataFactory.DeceasedDonorBuilder()
      .buildAndInsert();
    FinServ__FinancialAccount__c daf = new SuccessionTestDataFactory.FinancialAccountBuilder(
        donor.Id
      )
      .buildAndInsert();

    Test.startTest();
    Case successionCase = new SuccessionTestDataFactory.SuccessionCaseBuilder(
        donor.Id,
        daf.Id
      )
      .buildAndInsert();
    Test.stopTest();

    successionCase = [
      SELECT
        Id,
        Type,
        Status,
        AccountId,
        FinServ__FinancialAccount__c,
        Verification_Status__c,
        Contact_Attempt_Count__c
      FROM Case
      WHERE Id = :successionCase.Id
    ];

    System.assertEquals(
      'Named Successor Enactment',
      successionCase.Type,
      'Should be succession case type'
    );
    System.assertEquals(
      'In Progress',
      successionCase.Status,
      'Should default to In Progress'
    );
    System.assertEquals(
      donor.Id,
      successionCase.AccountId,
      'Should link to donor'
    );
    System.assertEquals(
      daf.Id,
      successionCase.FinServ__FinancialAccount__c,
      'Should link to financial account'
    );
    System.assertNotEquals(
      null,
      successionCase.Verification_Status__c,
      'Should have verification status'
    );
  }

  @IsTest
  static void testSuccessionCaseBuilder_CompleteWorkflow() {
    Account donor = new SuccessionTestDataFactory.DeceasedDonorBuilder()
      .buildAndInsert();
    Account successor = new SuccessionTestDataFactory.SuccessorBuilder()
      .buildAndInsert();
    FinServ__FinancialAccount__c daf = new SuccessionTestDataFactory.FinancialAccountBuilder(
        donor.Id
      )
      .buildAndInsert();

    Account successorWithContact = [
      SELECT Id, PersonContactId
      FROM Account
      WHERE Id = :successor.Id
    ];

    Test.startTest();
    Case successionCase = new SuccessionTestDataFactory.SuccessionCaseBuilder(
        donor.Id,
        daf.Id
      )
      .withSuccessor(successorWithContact.PersonContactId)
      .withContactAttempts(2)
      .withContactEstablished()
      .withPathway('Final Grant')
      .withFormCompleted()
      .buildAndInsert();
    Test.stopTest();

    successionCase = [
      SELECT
        Id,
        ContactId,
        Contact_Attempt_Count__c,
        Contact_Established__c,
        Pathway_Confirmed__c,
        Form_Sent_Date__c,
        Form_Completed_Date__c
      FROM Case
      WHERE Id = :successionCase.Id
    ];

    System.assertEquals(
      successorWithContact.PersonContactId,
      successionCase.ContactId,
      'Should link to successor contact'
    );
    System.assertEquals(
      2,
      successionCase.Contact_Attempt_Count__c,
      'Should have 2 contact attempts'
    );
    System.assertEquals(
      true,
      successionCase.Contact_Established__c,
      'Should have contact established'
    );
    System.assertEquals(
      'Final Grant',
      successionCase.Pathway_Confirmed__c,
      'Should have Final Grant pathway'
    );
    System.assertNotEquals(
      null,
      successionCase.Form_Sent_Date__c,
      'Should have form sent date'
    );
    System.assertNotEquals(
      null,
      successionCase.Form_Completed_Date__c,
      'Should have form completed date'
    );
  }

  // ==================== SCENARIO TESTS ====================

  @IsTest
  static void testGenerateHappyPathFinalGrant() {
    Test.startTest();
    SuccessionTestDataFactory.SuccessionScenarioData scenario = SuccessionTestDataFactory.generateHappyPathFinalGrant();
    Test.stopTest();

    // Verify deceased donor
    System.assertNotEquals(
      null,
      scenario.deceasedDonor,
      'Should have deceased donor'
    );
    System.assertEquals(
      'Margaret',
      scenario.deceasedDonor.FirstName,
      'Should be Margaret Thompson'
    );
    System.assertEquals(
      true,
      scenario.deceasedDonor.Deceased__c,
      'Should be deceased'
    );

    // Verify successor
    System.assertEquals(
      1,
      scenario.successors.size(),
      'Should have 1 successor'
    );
    System.assertEquals(
      'Jennifer',
      scenario.successors[0].FirstName,
      'Should be Jennifer Thompson'
    );

    // Verify financial account
    System.assertNotEquals(
      null,
      scenario.financialAccount,
      'Should have financial account'
    );
    System.assertEquals(
      'Thompson Family Fund',
      scenario.financialAccount.Name,
      'Should have correct fund name'
    );
    System.assertEquals(
      2500000,
      scenario.financialAccount.FinServ__Balance__c,
      'Should have correct balance'
    );

    // Verify roles
    System.assertEquals(
      3,
      scenario.roles.size(),
      'Should have 3 roles (owner, successor, advisor)'
    );

    // Verify case
    System.assertNotEquals(
      null,
      scenario.successionCase,
      'Should have succession case'
    );
    System.assertEquals(
      'Final Grant',
      scenario.successionCase.Pathway_Confirmed__c,
      'Should be Final Grant pathway'
    );
    System.assertEquals(
      true,
      scenario.successionCase.Contact_Established__c,
      'Should have contact established'
    );
  }

  @IsTest
  static void testGenerateNewDAFScenario() {
    Test.startTest();
    SuccessionTestDataFactory.SuccessionScenarioData scenario = SuccessionTestDataFactory.generateNewDAFScenario();
    Test.stopTest();

    System.assertNotEquals(
      null,
      scenario.deceasedDonor,
      'Should have deceased donor'
    );
    System.assertEquals(
      'Robert',
      scenario.deceasedDonor.FirstName,
      'Should be Robert Chen'
    );

    System.assertEquals(
      1,
      scenario.successors.size(),
      'Should have 1 successor'
    );
    System.assertEquals(
      'Lisa',
      scenario.successors[0].FirstName,
      'Should be Lisa Chen'
    );

    System.assertEquals(
      'New DAF Account',
      scenario.successionCase.Pathway_Confirmed__c,
      'Should be New DAF pathway'
    );
    System.assertEquals(
      2,
      scenario.successionCase.Contact_Attempt_Count__c,
      'Should have 2 contact attempts'
    );
  }

  @IsTest
  static void testGenerateDisclaimScenario() {
    Test.startTest();
    SuccessionTestDataFactory.SuccessionScenarioData scenario = SuccessionTestDataFactory.generateDisclaimScenario();
    Test.stopTest();

    System.assertNotEquals(
      null,
      scenario.deceasedDonor,
      'Should have deceased donor'
    );
    System.assertEquals(
      'Elizabeth',
      scenario.deceasedDonor.FirstName,
      'Should be Elizabeth Martinez'
    );

    System.assertEquals(
      'Disclaim Assets',
      scenario.successionCase.Pathway_Confirmed__c,
      'Should be Disclaim pathway'
    );
    System.assertEquals(
      'Closed',
      scenario.successionCase.Status,
      'Should be closed case'
    );
  }

  @IsTest
  static void testGenerateSLAEscalationScenario() {
    Test.startTest();
    SuccessionTestDataFactory.SuccessionScenarioData scenario = SuccessionTestDataFactory.generateSLAEscalationScenario();
    Test.stopTest();

    System.assertNotEquals(
      null,
      scenario.deceasedDonor,
      'Should have deceased donor'
    );
    System.assertEquals(
      'James',
      scenario.deceasedDonor.FirstName,
      'Should be James OConnor'
    );

    System.assertEquals(
      1,
      scenario.successors.size(),
      'Should have 1 successor'
    );
    System.assertEquals(
      'Sean',
      scenario.successors[0].FirstName,
      'Should be Sean OConnor'
    );
    System.assertEquals(
      null,
      scenario.successors[0].PersonEmail,
      'Successor should be unresponsive'
    );

    System.assertEquals(
      true,
      scenario.successionCase.IsEscalated,
      'Should be escalated'
    );
    System.assertEquals(
      4,
      scenario.successionCase.Contact_Attempt_Count__c,
      'Should have 4 contact attempts'
    );
  }

  @IsTest
  static void testGenerateCompleteDataset() {
    Test.startTest();
    SuccessionTestDataFactory.SuccessionTestData dataset = SuccessionTestDataFactory.generateCompleteDataset();
    Test.stopTest();

    // Verify dataset contains all scenarios (updated counts as of 2025-01-02)
    System.assertEquals(
      15,
      dataset.deceasedDonors.size(),
      'Should have 15 deceased donors'
    );
    System.assertEquals(
      20,
      dataset.successors.size(),
      'Should have 20 successors (includes multi-successor scenarios)'
    );
    System.assertEquals(
      8,
      dataset.advisorFirms.size(),
      'Should have 8 advisor firms'
    );
    System.assertEquals(
      15,
      dataset.financialAccounts.size(),
      'Should have 15 financial accounts'
    );
    System.assert(dataset.roles.size() >= 54, 'Should have 54+ roles');
    System.assertEquals(
      15,
      dataset.successionCases.size(),
      'Should have 15 succession cases'
    );

    // Verify specific scenarios are present
    List<String> donorFirstNames = new List<String>();
    for (Account donor : dataset.deceasedDonors) {
      donorFirstNames.add(donor.FirstName);
    }
    System.assert(
      donorFirstNames.contains('Margaret'),
      'Should contain Margaret Thompson (Happy Path)'
    );
    System.assert(
      donorFirstNames.contains('Robert'),
      'Should contain Robert Chen (New DAF)'
    );
    System.assert(
      donorFirstNames.contains('Elizabeth'),
      'Should contain Elizabeth Martinez (Disclaim)'
    );
    System.assert(
      donorFirstNames.contains('James'),
      'Should contain James OConnor (SLA Escalation)'
    );
    System.assert(
      donorFirstNames.contains('Patricia'),
      'Should contain Patricia Williams (Multi-Successor 50/50)'
    );
    System.assert(
      donorFirstNames.contains('Harold'),
      'Should contain Harold Miller (Multi-Successor 3-way)'
    );
    System.assert(
      donorFirstNames.contains('David'),
      'Should contain David Lee (Fast-Track)'
    );
  }

  // ==================== DATA INTEGRITY TESTS ====================

  @IsTest
  static void testDataIntegrity_AllDeceasedDonorsHaveDeathDate() {
    SuccessionTestDataFactory.SuccessionTestData dataset = SuccessionTestDataFactory.generateCompleteDataset();

    for (Account donor : dataset.deceasedDonors) {
      System.assertEquals(
        true,
        donor.Deceased__c,
        'All deceased donors should have Deceased__c = TRUE'
      );
      System.assertNotEquals(
        null,
        donor.Date_of_Death__c,
        'All deceased donors should have Date_of_Death__c'
      );
    }
  }

  @IsTest
  static void testDataIntegrity_AllSuccessorsNotDeceased() {
    SuccessionTestDataFactory.SuccessionTestData dataset = SuccessionTestDataFactory.generateCompleteDataset();

    for (Account successor : dataset.successors) {
      System.assertEquals(
        false,
        successor.Deceased__c,
        'All successors should have Deceased__c = FALSE'
      );
    }
  }

  // ==================== MULTI-SUCCESSOR TESTS ====================

  @IsTest
  static void testMultipleSuccessorsScenario_TwoWaySplit() {
    Test.startTest();
    SuccessionTestDataFactory.SuccessionScenarioData scenario = SuccessionTestDataFactory.generateMultipleSuccessorsScenario();
    Test.stopTest();

    // Verify deceased donor
    System.assertNotEquals(
      null,
      scenario.deceasedDonor,
      'Should have deceased donor'
    );
    System.assertEquals(
      'Patricia',
      scenario.deceasedDonor.FirstName,
      'Should be Patricia Williams'
    );
    System.assertEquals(
      true,
      scenario.deceasedDonor.Deceased__c,
      'Should be deceased'
    );

    // Verify multiple successors
    System.assertEquals(
      2,
      scenario.successors.size(),
      'Should have exactly 2 successors'
    );
    System.assertEquals(
      'Amanda',
      scenario.successors[0].FirstName,
      'First successor should be Amanda'
    );
    System.assertEquals(
      'Brandon',
      scenario.successors[1].FirstName,
      'Second successor should be Brandon'
    );

    // Verify both successors are responsive
    for (Account successor : scenario.successors) {
      System.assertNotEquals(
        null,
        successor.PersonEmail,
        'Successor should have email (responsive)'
      );
    }

    // Verify financial account
    System.assertNotEquals(
      null,
      scenario.financialAccount,
      'Should have financial account'
    );
    System.assertEquals(
      'Williams Family Foundation Fund',
      scenario.financialAccount.Name,
      'Should have correct fund name'
    );
    System.assertEquals(
      3500000,
      scenario.financialAccount.FinServ__Balance__c,
      'Should have correct balance'
    );
    System.assertEquals(
      'ASDAF',
      scenario.financialAccount.Program__c,
      'Should have correct program'
    );

    // Verify roles (1 primary owner + 2 successors = 3 total)
    System.assertEquals(
      3,
      scenario.roles.size(),
      'Should have 3 roles (1 owner + 2 successors)'
    );

    // Verify allocation percentages sum to 100%
    Decimal totalAllocation = 0;
    Integer successorRoleCount = 0;
    for (FinServ__FinancialAccountRole__c role : scenario.roles) {
      if (role.FinServ__Role__c == 'Successor') {
        successorRoleCount++;
        System.assertNotEquals(
          null,
          role.SuccessorAllocation__c,
          'Successor role should have allocation'
        );
        totalAllocation += role.SuccessorAllocation__c;
      }
    }
    System.assertEquals(
      2,
      successorRoleCount,
      'Should have exactly 2 successor roles'
    );
    System.assertEquals(
      100,
      totalAllocation,
      'Total successor allocation should be 100%'
    );

    // Verify case links to first successor
    System.assertNotEquals(
      null,
      scenario.successionCase,
      'Should have succession case'
    );
    System.assertEquals(
      'Final Grant',
      scenario.successionCase.Pathway_Confirmed__c,
      'Should be Final Grant pathway'
    );
    System.assertEquals(
      true,
      scenario.successionCase.Contact_Established__c,
      'Should have contact established'
    );
  }

  @IsTest
  static void testMultipleSuccessors_AllocationValidation() {
    SuccessionTestDataFactory.SuccessionTestData dataset = SuccessionTestDataFactory.generateCompleteDataset();

    // Find all financial accounts with multiple successors
    Map<Id, List<FinServ__FinancialAccountRole__c>> accountToSuccessorRoles = new Map<Id, List<FinServ__FinancialAccountRole__c>>();

    for (FinServ__FinancialAccountRole__c role : dataset.roles) {
      if (role.FinServ__Role__c == 'Successor') {
        if (
          !accountToSuccessorRoles.containsKey(
            role.FinServ__FinancialAccount__c
          )
        ) {
          accountToSuccessorRoles.put(
            role.FinServ__FinancialAccount__c,
            new List<FinServ__FinancialAccountRole__c>()
          );
        }
        accountToSuccessorRoles.get(role.FinServ__FinancialAccount__c)
          .add(role);
      }
    }

    // Validate allocation for accounts with multiple successors
    for (Id accountId : accountToSuccessorRoles.keySet()) {
      List<FinServ__FinancialAccountRole__c> successorRoles = accountToSuccessorRoles.get(
        accountId
      );

      if (successorRoles.size() > 1) {
        Decimal totalAllocation = 0;
        for (FinServ__FinancialAccountRole__c role : successorRoles) {
          System.assertNotEquals(
            null,
            role.SuccessorAllocation__c,
            'Multi-successor role must have allocation'
          );
          System.assert(
            role.SuccessorAllocation__c > 0,
            'Allocation must be greater than 0'
          );
          totalAllocation += role.SuccessorAllocation__c;
        }
        System.assertEquals(
          100,
          totalAllocation,
          'Total allocation for account ' + accountId + ' must equal 100%'
        );
      }
    }
  }

  @IsTest
  static void testMultipleSuccessors_AllResponsive() {
    SuccessionTestDataFactory.SuccessionScenarioData scenario = SuccessionTestDataFactory.generateMultipleSuccessorsScenario();

    // All successors in multi-successor scenarios should be responsive
    for (Account successor : scenario.successors) {
      System.assertNotEquals(
        null,
        successor.PersonEmail,
        'Multi-successor must have email address'
      );
      System.assertNotEquals(
        null,
        successor.PersonMobilePhone,
        'Multi-successor must have mobile phone'
      );
    }
  }

  @IsTest
  static void testDataIntegrity_FinancialAccountsHavePrimaryOwner() {
    SuccessionTestDataFactory.SuccessionTestData dataset = SuccessionTestDataFactory.generateCompleteDataset();

    for (FinServ__FinancialAccount__c daf : dataset.financialAccounts) {
      System.assertNotEquals(
        null,
        daf.FinServ__PrimaryOwner__c,
        'All financial accounts should have primary owner'
      );
      System.assert(
        daf.FinServ__Balance__c >= 50000,
        'All financial accounts should meet minimum balance'
      );
    }
  }

  @IsTest
  static void testDataIntegrity_RolesHaveValidTypes() {
    SuccessionTestDataFactory.SuccessionTestData dataset = SuccessionTestDataFactory.generateCompleteDataset();

    Set<String> validRoles = new Set<String>{
      'Successor',
      'Advisor',
      'Primary Owner'
    };

    for (FinServ__FinancialAccountRole__c role : dataset.roles) {
      System.assert(
        validRoles.contains(role.FinServ__Role__c),
        'Role should be valid type: ' + role.FinServ__Role__c
      );
      System.assertEquals(
        true,
        role.FinServ__Active__c,
        'All roles should be active'
      );
    }
  }

  @IsTest
  static void testDataIntegrity_CasesHaveCorrectType() {
    SuccessionTestDataFactory.SuccessionTestData dataset = SuccessionTestDataFactory.generateCompleteDataset();

    for (Case successionCase : dataset.successionCases) {
      System.assertEquals(
        'Named Successor Enactment',
        successionCase.Type,
        'All cases should be succession type'
      );
      System.assertNotEquals(
        null,
        successionCase.AccountId,
        'All cases should link to account'
      );
      System.assertNotEquals(
        null,
        successionCase.FinServ__FinancialAccount__c,
        'All cases should link to financial account'
      );
    }
  }
}
