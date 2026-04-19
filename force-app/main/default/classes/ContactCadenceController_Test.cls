/**
 * Focused tests for the ContactCadenceController now that the repository
 * only ships the contact cadence experience.
 */
@IsTest
private class ContactCadenceController_Test {
  private static Id estateRecordTypeId;
  private static Id validCaseId;
  private static Id optedOutCaseId;
  private static Id noEmailCaseId;
  private static Id wrongTypeCaseId;
  private static Id noAccountCaseId;

  @TestSetup
  static void setupData() {
    estateRecordTypeId = getEstateRecordTypeId();

    // Primary account/contact with good email
    Account primaryAccount = new Account(Name = 'Estate Primary');
    insert primaryAccount;
    Contact primaryContact = new Contact(
      FirstName = 'Amanda',
      LastName = 'Williams',
      AccountId = primaryAccount.Id,
      Email = 'amanda.williams@example.com',
      HasOptedOutOfEmail = false
    );
    insert primaryContact;

    // Opted-out contact
    Account optedAccount = new Account(Name = 'Opted Account');
    insert optedAccount;
    Contact optedContact = new Contact(
      FirstName = 'Brandon',
      LastName = 'Williams',
      AccountId = optedAccount.Id,
      Email = 'brandon.williams@example.com',
      HasOptedOutOfEmail = true
    );
    insert optedContact;

    // No-email contact
    Account noEmailAccount = new Account(Name = 'No Email Account');
    insert noEmailAccount;
    Contact noEmailContact = new Contact(
      FirstName = 'Charlie',
      LastName = 'Williams',
      AccountId = noEmailAccount.Id
    );
    insert noEmailContact;

    // Cases for each scenario
    List<Case> cases = new List<Case>{
      new Case(
        RecordTypeId = estateRecordTypeId,
        Type = 'Succession Management',
        Subject = 'Valid Contact Cadence',
        Status = 'New',
        AccountId = primaryAccount.Id,
        ContactId = primaryContact.Id,
        Successor__c = primaryContact.Id,
        Contact_Established__c = false,
        Contact_Attempt_Count__c = 0
      ),
      new Case(
        RecordTypeId = estateRecordTypeId,
        Type = 'Succession Management',
        Subject = 'Opted Out Contact',
        Status = 'New',
        AccountId = optedAccount.Id,
        ContactId = optedContact.Id,
        Successor__c = optedContact.Id,
        Contact_Established__c = false,
        Contact_Attempt_Count__c = 0
      ),
      new Case(
        RecordTypeId = estateRecordTypeId,
        Type = 'Succession Management',
        Subject = 'No Email Contact',
        Status = 'New',
        AccountId = noEmailAccount.Id,
        ContactId = noEmailContact.Id,
        Successor__c = noEmailContact.Id,
        Contact_Established__c = false,
        Contact_Attempt_Count__c = 0
      ),
      new Case(
        RecordTypeId = estateRecordTypeId,
        Type = 'Other',
        Subject = 'Wrong Type Case',
        Status = 'New',
        AccountId = primaryAccount.Id
      ),
      new Case(
        RecordTypeId = estateRecordTypeId,
        Type = 'Succession Management',
        Subject = 'Missing Account Case',
        Status = 'New'
      )
    };
    insert cases;

    validCaseId = cases[0].Id;
    optedOutCaseId = cases[1].Id;
    noEmailCaseId = cases[2].Id;
    wrongTypeCaseId = cases[3].Id;
    noAccountCaseId = cases[4].Id;

    // Seed attempt tasks for the valid case
    List<Task> tasks = new List<Task>{
      new Task(
        WhatId = validCaseId,
        Subject = 'Succession Contact Attempt 1',
        Contact_Attempt_Number__c = 1,
        ActivityDate = Date.today(),
        Status = 'Completed',
        Succession_Contact_Established__c = true,
        Description = '[2025-10-14 10:00] Reached successor, explained pathways'
      ),
      new Task(
        WhatId = validCaseId,
        Subject = 'Succession Contact Attempt 2',
        Contact_Attempt_Number__c = 2,
        ActivityDate = Date.today().addDays(5),
        Status = 'Completed',
        Succession_Contact_Established__c = false,
        Description = '[2025-10-19 14:00] No answer, left voicemail'
      ),
      new Task(
        WhatId = validCaseId,
        Subject = 'Succession Contact Attempt 3',
        Contact_Attempt_Number__c = 3,
        ActivityDate = Date.today().addDays(35),
        Status = 'Not Started',
        Succession_Contact_Established__c = false
      )
    };
    insert tasks;
  }

  private static Id getEstateRecordTypeId() {
    Map<String, Schema.RecordTypeInfo> infoByDevName = Case.SObjectType.getDescribe()
      .getRecordTypeInfosByDeveloperName();
    if (infoByDevName.containsKey('EstateAdministration')) {
      return infoByDevName.get('EstateAdministration').getRecordTypeId();
    }
    return Case.SObjectType.getDescribe().getRecordTypeInfos()[0].getRecordTypeId();
  }

  @IsTest
  static void getContactCadence_validCase() {
    Test.startTest();
    ContactCadenceController.ContactCadenceData data = ContactCadenceController.getContactCadence(
      validCaseId
    );
    Test.stopTest();

    System.assertEquals(true, data.isValidRecordType, 'Record type should be valid');
    System.assertEquals(5, data.totalAttempts, 'All attempts should be returned');
    System.assertEquals(5, data.attempts.size(), 'Attempt list size should be 5');
    System.assertEquals(
      true,
      data.hasEmail,
      'Valid case should report an email address'
    );
  }

  @IsTest
  static void getContactCadence_optedOutAndMissingEmail() {
    Test.startTest();
    ContactCadenceController.ContactCadenceData opted = ContactCadenceController.getContactCadence(
      optedOutCaseId
    );
    ContactCadenceController.ContactCadenceData missingEmail = ContactCadenceController.getContactCadence(
      noEmailCaseId
    );
    Test.stopTest();

    System.assertEquals(true, opted.hasOptedOut, 'Opted-out contact should be flagged');
    System.assertEquals(false, missingEmail.hasEmail, 'Missing email should be flagged');
  }

  @IsTest
  static void getContactCadence_invalidCases() {
    Test.startTest();
    ContactCadenceController.ContactCadenceData wrongType = ContactCadenceController.getContactCadence(
      wrongTypeCaseId
    );
    ContactCadenceController.ContactCadenceData noAccount = ContactCadenceController.getContactCadence(
      noAccountCaseId
    );
    Test.stopTest();

    System.assertEquals(false, wrongType.isValidRecordType, 'Wrong type should be invalid');
    System.assertEquals(false, noAccount.isValidRecordType, 'Missing account should be invalid');
  }

  @IsTest
  static void saveAttemptOutcome_createsNextAttempt() {
    Test.startTest();
    String result = ContactCadenceController.saveAttemptOutcome(
      validCaseId,
      null,
      4,
      false,
      'Attempt 4 notes'
    );
    Test.stopTest();

    System.assertEquals('Success', result, 'Outcome should return success');

    List<Task> createdTasks = [
      SELECT Contact_Attempt_Number__c, Status
      FROM Task
      WHERE WhatId = :validCaseId
      ORDER BY Contact_Attempt_Number__c
    ];
    System.assert(
      createdTasks.anyMatch(t -> t.Contact_Attempt_Number__c == 4 && t.Status == 'Completed'),
      'Attempt 4 should be completed'
    );
    System.assert(
      createdTasks.anyMatch(t -> t.Contact_Attempt_Number__c == 5),
      'Next attempt should be created when contact not established'
    );
  }

  @IsTest
  static void saveAttemptOutcome_contactEstablishedStopsNext() {
    Test.startTest();
    String result = ContactCadenceController.saveAttemptOutcome(
      validCaseId,
      null,
      5,
      true,
      'Attempt 5 notes'
    );
    Test.stopTest();

    System.assertEquals('Success', result, 'Outcome should return success');

    Case updatedCase = [
      SELECT Contact_Established__c
      FROM Case
      WHERE Id = :validCaseId
    ];
    System.assertEquals(
      true,
      updatedCase.Contact_Established__c,
      'Case should be marked contact established'
    );
  }

  @IsTest
  static void markFormEmailSent_setsDate() {
    Test.startTest();
    String message = ContactCadenceController.markFormEmailSent(validCaseId);
    Test.stopTest();

    Case updatedCase = [SELECT Form_Sent_Date__c FROM Case WHERE Id = :validCaseId];
    System.assertNotEquals(null, updatedCase.Form_Sent_Date__c, 'Form sent date should be set');
    System.assert(message.startsWith('Pathway form email'), 'Message should confirm update');
  }

  @IsTest
  static void getAttemptWaitDurations_fromMetadata() {
    Test.startTest();
    Map<Integer, Integer> durations = ContactCadenceController.getAttemptWaitDurations();
    Test.stopTest();

    System.assertEquals(5, durations.get(2), 'Attempt 2 wait should be 5 days');
    System.assertEquals(30, durations.get(3), 'Attempt 3 wait should be 30 days');
    System.assertEquals(30, durations.get(4), 'Attempt 4 wait should be 30 days');
    System.assertEquals(30, durations.get(5), 'Attempt 5 wait should be 30 days');
  }
}
