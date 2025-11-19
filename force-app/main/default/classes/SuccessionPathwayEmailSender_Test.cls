/**
 * SuccessionPathwayEmailSender_Test
 *
 * Focused tests for SuccessionPathwayEmailSender invocable email sender.
 */
@isTest
private class SuccessionPathwayEmailSender_Test {
  @isTest
  static void testSendPathwayFormEmail_PersonAccount_Success() {
    Id personRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('PersonAccount')
      .getRecordTypeId();

    Account successor = new Account(
      RecordTypeId = personRtId,
      FirstName = 'Jane',
      LastName = 'Successor',
      PersonEmail = 'jane.successor@example.com',
      PersonHasOptedOutOfEmail = false
    );
    insert successor;

    successor = [
      SELECT Id, PersonContactId
      FROM Account
      WHERE Id = :successor.Id
    ];

    FinServ__FinancialAccount__c fa = new FinServ__FinancialAccount__c(
      Name = 'Test DAF',
      FinServ__PrimaryOwner__c = successor.Id
    );
    insert fa;

    Id estateRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
      .get('EstateAdministration')
      .getRecordTypeId();

    Case c = new Case(
      RecordTypeId = estateRtId,
      Type = 'Named Successor Enactment',
      Status = 'New',
      Origin = 'Phone',
      AccountId = successor.Id,
      ContactId = successor.PersonContactId,
      Successor__c = successor.PersonContactId,
      FinServ__FinancialAccount__c = fa.Id
    );
    insert c;

    SuccessionPathwayEmailSender.EmailRequest req = new SuccessionPathwayEmailSender.EmailRequest();
    req.caseId = c.Id;

    Test.startTest();
    List<SuccessionPathwayEmailSender.EmailResponse> responses = SuccessionPathwayEmailSender.sendPathwayFormEmail(
      new List<SuccessionPathwayEmailSender.EmailRequest>{ req }
    );
    Test.stopTest();

    System.assertEquals(1, responses.size(), 'One response expected');
    System.assertEquals(
      true,
      responses[0].success,
      'Email should send successfully'
    );
    System.assertNotEquals(
      null,
      responses[0].emailSentDate,
      'Email sent date should be set'
    );

    Case updated = [
      SELECT Form_Sent_Date__c
      FROM Case
      WHERE Id = :c.Id
    ];
    System.assertNotEquals(
      null,
      updated.Form_Sent_Date__c,
      'Form_Sent_Date__c should be populated'
    );
  }

  @isTest
  static void testSendPathwayFormEmail_NoSuccessor() {
    Account acc = new Account(Name = 'No Successor Account');
    insert acc;

    Contact contact = new Contact(
      FirstName = 'No',
      LastName = 'Successor',
      Email = 'no.successor@example.com',
      AccountId = acc.Id
    );
    insert contact;

    Id estateRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
      .get('EstateAdministration')
      .getRecordTypeId();

    Case c = new Case(
      RecordTypeId = estateRtId,
      Type = 'Named Successor Enactment',
      Status = 'New',
      Origin = 'Phone',
      AccountId = acc.Id,
      ContactId = contact.Id
      // Successor__c intentionally left null
    );
    insert c;

    SuccessionPathwayEmailSender.EmailRequest req = new SuccessionPathwayEmailSender.EmailRequest();
    req.caseId = c.Id;

    Test.startTest();
    List<SuccessionPathwayEmailSender.EmailResponse> responses = SuccessionPathwayEmailSender.sendPathwayFormEmail(
      new List<SuccessionPathwayEmailSender.EmailRequest>{ req }
    );
    Test.stopTest();

    System.assertEquals(1, responses.size());
    System.assertEquals(
      false,
      responses[0].success,
      'Should fail when no successor'
    );
    System.assertEquals('No successor found on case', responses[0].message);
  }

  @isTest
  static void testSendPathwayFormEmail_InvalidEmail_BusinessAccount() {
    Account acc = new Account(Name = 'Business Successor Account');
    insert acc;

    Contact contact = new Contact(
      FirstName = 'Invalid',
      LastName = 'Email',
      Email = 'invalid-email-format',
      HasOptedOutOfEmail = false,
      AccountId = acc.Id
    );
    insert contact;

    Id estateRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
      .get('EstateAdministration')
      .getRecordTypeId();

    Case c = new Case(
      RecordTypeId = estateRtId,
      Type = 'Named Successor Enactment',
      Status = 'New',
      Origin = 'Phone',
      AccountId = acc.Id,
      ContactId = contact.Id,
      Successor__c = contact.Id
    );
    insert c;

    SuccessionPathwayEmailSender.EmailRequest req = new SuccessionPathwayEmailSender.EmailRequest();
    req.caseId = c.Id;

    Test.startTest();
    List<SuccessionPathwayEmailSender.EmailResponse> responses = SuccessionPathwayEmailSender.sendPathwayFormEmail(
      new List<SuccessionPathwayEmailSender.EmailRequest>{ req }
    );
    Test.stopTest();

    System.assertEquals(1, responses.size());
    System.assertEquals(
      false,
      responses[0].success,
      'Invalid email should fail validation'
    );
    System.assert(
      responses[0].message != null &&
      responses[0].message.contains('appears invalid'),
      'Message should indicate invalid email format'
    );
  }

  @isTest
  static void testSendPathwayFormEmail_OptedOut_BusinessAccount() {
    Account acc = new Account(Name = 'Opted Out Account');
    insert acc;

    Contact contact = new Contact(
      FirstName = 'Opted',
      LastName = 'Out',
      Email = 'opted.out@example.com',
      HasOptedOutOfEmail = true,
      AccountId = acc.Id
    );
    insert contact;

    Id estateRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
      .get('EstateAdministration')
      .getRecordTypeId();

    Case c = new Case(
      RecordTypeId = estateRtId,
      Type = 'Named Successor Enactment',
      Status = 'New',
      Origin = 'Phone',
      AccountId = acc.Id,
      ContactId = contact.Id,
      Successor__c = contact.Id
    );
    insert c;

    SuccessionPathwayEmailSender.EmailRequest req = new SuccessionPathwayEmailSender.EmailRequest();
    req.caseId = c.Id;

    Test.startTest();
    List<SuccessionPathwayEmailSender.EmailResponse> responses = SuccessionPathwayEmailSender.sendPathwayFormEmail(
      new List<SuccessionPathwayEmailSender.EmailRequest>{ req }
    );
    Test.stopTest();

    System.assertEquals(1, responses.size());
    System.assertEquals(
      false,
      responses[0].success,
      'Opted-out successor should not receive email'
    );
    System.assertEquals(
      'Cannot send email: Successor has opted out of email communications',
      responses[0].message
    );
  }

  @isTest
  static void testSendPathwayFormEmail_AlreadySent() {
    Id personRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('PersonAccount')
      .getRecordTypeId();

    Account successor = new Account(
      RecordTypeId = personRtId,
      FirstName = 'Already',
      LastName = 'Sent',
      PersonEmail = 'already.sent@example.com',
      PersonHasOptedOutOfEmail = false
    );
    insert successor;

    successor = [
      SELECT Id, PersonContactId
      FROM Account
      WHERE Id = :successor.Id
    ];

    FinServ__FinancialAccount__c fa = new FinServ__FinancialAccount__c(
      Name = 'Test DAF',
      FinServ__PrimaryOwner__c = successor.Id
    );
    insert fa;

    Id estateRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
      .get('EstateAdministration')
      .getRecordTypeId();

    Case c = new Case(
      RecordTypeId = estateRtId,
      Type = 'Named Successor Enactment',
      Status = 'New',
      Origin = 'Phone',
      AccountId = successor.Id,
      ContactId = successor.PersonContactId,
      Successor__c = successor.PersonContactId,
      FinServ__FinancialAccount__c = fa.Id,
      Form_Sent_Date__c = Date.today().addDays(-5)
    );
    insert c;

    SuccessionPathwayEmailSender.EmailRequest req = new SuccessionPathwayEmailSender.EmailRequest();
    req.caseId = c.Id;

    Test.startTest();
    List<SuccessionPathwayEmailSender.EmailResponse> responses = SuccessionPathwayEmailSender.sendPathwayFormEmail(
      new List<SuccessionPathwayEmailSender.EmailRequest>{ req }
    );
    Test.stopTest();

    System.assertEquals(1, responses.size());
    System.assertEquals(
      false,
      responses[0].success,
      'Should not send email when already sent'
    );
    System.assertEquals(
      'Pathway form email already sent for this case',
      responses[0].message,
      'Message should indicate email already sent'
    );
    System.assertNotEquals(
      null,
      responses[0].emailSentDate,
      'Should return original sent date'
    );
  }
}
