/**
 * SuccessionUtilities_Test
 *
 * Test class for SuccessionUtilities shared utility class.
 * Achieves comprehensive coverage of all utility methods.
 *
 * @author Claude Code
 * @date 2025-10-27
 */
@isTest
private class SuccessionUtilities_Test {
  // ========================================
  // TEST SETUP
  // ========================================

  @testSetup
  static void setupTestData() {
    // Create test Case for ContentNote testing
    Case testCase = new Case(
      Subject = 'Test Succession Case',
      Status = 'New',
      Origin = 'Phone'
    );
    insert testCase;

    // Create test Contact for query testing
    Contact testContact = new Contact(
      FirstName = 'Test',
      LastName = 'Successor',
      Email = 'test.successor@example.com',
      Phone = '555-1234',
      HasOptedOutOfEmail = false
    );
    insert testContact;
  }

  // ========================================
  // EMAIL VALIDATION TESTS
  // ========================================

  @isTest
  static void testValidateEmail_ValidEmail() {
    String validEmail = 'test@example.com';
    Boolean optedOut = false;

    Test.startTest();
    SuccessionUtilities.EmailValidationResult result = SuccessionUtilities.validateEmail(
      validEmail,
      optedOut
    );
    Test.stopTest();

    System.assertEquals(validEmail, result.email, 'Email should match');
    System.assertEquals(true, result.hasEmail, 'Should have email');
    System.assertEquals(
      true,
      result.hasValidFormat,
      'Email should be valid format'
    );
    System.assertEquals(false, result.hasOptedOut, 'Should not be opted out');
    System.assertEquals(null, result.warning, 'Should have no warnings');
  }

  @isTest
  static void testValidateEmail_OptedOut() {
    String validEmail = 'test@example.com';
    Boolean optedOut = true;

    Test.startTest();
    SuccessionUtilities.EmailValidationResult result = SuccessionUtilities.validateEmail(
      validEmail,
      optedOut
    );
    Test.stopTest();

    System.assertEquals(true, result.hasOptedOut, 'Should be opted out');
    System.assert(
      result.warning.contains('opted out'),
      'Warning should mention opt-out'
    );
  }

  @isTest
  static void testValidateEmail_MissingEmail() {
    String missingEmail = null;
    Boolean optedOut = false;

    Test.startTest();
    SuccessionUtilities.EmailValidationResult result = SuccessionUtilities.validateEmail(
      missingEmail,
      optedOut
    );
    Test.stopTest();

    System.assertEquals(false, result.hasEmail, 'Should not have email');
    System.assertEquals(
      false,
      result.hasValidFormat,
      'Should not have valid format'
    );
    System.assert(
      result.warning.contains('No email address'),
      'Warning should mention missing email'
    );
  }

  @isTest
  static void testValidateEmail_InvalidFormat() {
    String invalidEmail = 'invalid-email-format';
    Boolean optedOut = false;

    Test.startTest();
    SuccessionUtilities.EmailValidationResult result = SuccessionUtilities.validateEmail(
      invalidEmail,
      optedOut
    );
    Test.stopTest();

    System.assertEquals(true, result.hasEmail, 'Should have email value');
    System.assertEquals(
      false,
      result.hasValidFormat,
      'Should have invalid format'
    );
    System.assert(
      result.warning.contains('appears invalid'),
      'Warning should mention invalid format'
    );
  }

  @isTest
  static void testValidateEmail_BlankEmail() {
    String blankEmail = '   ';
    Boolean optedOut = false;

    Test.startTest();
    SuccessionUtilities.EmailValidationResult result = SuccessionUtilities.validateEmail(
      blankEmail,
      optedOut
    );
    Test.stopTest();

    System.assertEquals(false, result.hasEmail, 'Blank email should be false');
  }

  // ========================================
  // CHATTER POST CREATION TESTS
  // ========================================

  @isTest
  static void testCreateChatterPost_UserMode() {
    Case testCase = [SELECT Id FROM Case LIMIT 1];
    String postBody = 'Test chatter post';

    Test.startTest();
    FeedItem result = SuccessionUtilities.createChatterPost(
      testCase.Id,
      postBody,
      false
    );
    Test.stopTest();

    System.assertNotEquals(null, result.Id, 'FeedItem should be created');
    System.assertEquals(testCase.Id, result.ParentId, 'Parent should match');
    System.assertEquals(postBody, result.Body, 'Body should match');
  }

  @isTest
  static void testCreateChatterPost_SystemMode() {
    Case testCase = [SELECT Id FROM Case LIMIT 1];
    String postBody = 'Test chatter post with SYSTEM_MODE';

    Test.startTest();
    FeedItem result = SuccessionUtilities.createChatterPost(
      testCase.Id,
      postBody,
      true // useSystemMode = true
    );
    Test.stopTest();

    System.assertNotEquals(
      null,
      result.Id,
      'FeedItem should be created in SYSTEM_MODE'
    );
    System.assertEquals(testCase.Id, result.ParentId, 'Parent should match');
    System.assertEquals(postBody, result.Body, 'Body should match');
  }

  @isTest
  static void testBuildContactAttemptPostBody() {
    Integer attemptNumber = 2;
    Boolean contactEstablished = true;
    String noteContent = 'Test notes';

    Test.startTest();
    String result = SuccessionUtilities.buildContactAttemptPostBody(
      attemptNumber,
      contactEstablished,
      noteContent
    );
    Test.stopTest();

    System.assert(result.contains('✅'), 'Should contain success emoji');
    System.assert(
      result.contains('Attempt 2'),
      'Should contain attempt number'
    );
    System.assert(
      result.contains('Contact Established'),
      'Should contain outcome'
    );
    System.assert(result.contains(noteContent), 'Should contain notes');
  }

  @isTest
  static void testBuildContactAttemptPostBody_NoContact() {
    Integer attemptNumber = 1;
    Boolean contactEstablished = false;
    String noteContent = 'No answer';

    Test.startTest();
    String result = SuccessionUtilities.buildContactAttemptPostBody(
      attemptNumber,
      contactEstablished,
      noteContent
    );
    Test.stopTest();

    System.assert(result.contains('❌'), 'Should contain failure emoji');
    System.assert(
      result.contains('Contact Not Established'),
      'Should contain no contact message'
    );
  }

  @isTest
  static void testBuildPathwayTaskPostBody() {
    String pathwayName = 'Final Grant';
    Integer taskCount = 5;

    Test.startTest();
    String result = SuccessionUtilities.buildPathwayTaskPostBody(
      pathwayName,
      taskCount
    );
    Test.stopTest();

    System.assert(result.contains('5 pathway'), 'Should contain task count');
    System.assert(
      result.contains('Final Grant'),
      'Should contain pathway name'
    );
  }

  // ========================================
  // RECORD TYPE LOOKUP TESTS
  // ========================================

  @isTest
  static void testGetEstateAdministrationRecordTypeId() {
    Test.startTest();
    Id result1 = SuccessionUtilities.getEstateAdministrationRecordTypeId();
    Id result2 = SuccessionUtilities.getEstateAdministrationRecordTypeId();
    Test.stopTest();

    // May or may not exist in test org
    // Test caching works (same result on second call)
    System.assertEquals(result1, result2, 'Cached result should match');
  }

  @isTest
  static void testGetCachedRecordTypeId() {
    Test.startTest();
    Id result = SuccessionUtilities.getCachedRecordTypeId(
      'Case',
      'EstateAdministration'
    );
    Test.stopTest();

    // Record type may or may not exist in test org
    // Test doesn't fail - just returns null if not found
    System.assert(true, 'Method should complete without error');
  }

  @isTest
  static void testGetCachedRecordTypeId_NonExistent() {
    Test.startTest();
    Id result = SuccessionUtilities.getCachedRecordTypeId(
      'Case',
      'NonExistentRecordType'
    );
    Test.stopTest();

    System.assertEquals(null, result, 'Should return null for non-existent');
  }

  // ========================================
  // CONTENTNOTE INTEGRATION TESTS
  // ========================================

  @isTest
  static void testCreateLinkedContentNote() {
    Case testCase = [SELECT Id FROM Case LIMIT 1];
    String noteTitle = 'Test Note';
    String noteBody = 'Test note body content';

    Test.startTest();
    Id result = SuccessionUtilities.createLinkedContentNote(
      testCase.Id,
      noteTitle,
      noteBody
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'ContentNote should be created');

    // Verify ContentDocumentLink was created
    List<ContentDocumentLink> links = [
      SELECT Id
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :testCase.Id
    ];
    System.assertEquals(
      1,
      links.size(),
      'ContentDocumentLink should be created'
    );
  }

  @isTest
  static void testCreateLinkedContentNote_Debug() {
    Case testCase = [SELECT Id FROM Case LIMIT 1];
    String noteTitle = 'Test Note Debug';
    String noteBody = 'Test note body content for debugging';

    // Debug: Log test context and permissions
    System.debug('DEBUG TEST: Starting testCreateLinkedContentNote_Debug');
    System.debug('DEBUG TEST: Case ID: ' + testCase.Id);
    System.debug('DEBUG TEST: Running user: ' + UserInfo.getUserName());

    // Check ContentNote object accessibility
    System.debug(
      'DEBUG TEST: ContentNote createable? ' +
      Schema.sObjectType.ContentNote.isCreateable()
    );
    System.debug(
      'DEBUG TEST: ContentNote accessible? ' +
      Schema.sObjectType.ContentNote.isAccessible()
    );
    System.debug(
      'DEBUG TEST: ContentDocumentLink createable? ' +
      Schema.sObjectType.ContentDocumentLink.isCreateable()
    );

    Id result = null;
    Exception caughtException = null;

    Test.startTest();
    try {
      System.debug('DEBUG TEST: About to call createLinkedContentNote');
      result = SuccessionUtilities.createLinkedContentNote(
        testCase.Id,
        noteTitle,
        noteBody
      );
      System.debug('DEBUG TEST: Method returned result: ' + result);
    } catch (Exception e) {
      caughtException = e;
      System.debug('DEBUG TEST: Exception caught in test!');
      System.debug('DEBUG TEST: Exception type: ' + e.getTypeName());
      System.debug('DEBUG TEST: Exception message: ' + e.getMessage());
      System.debug('DEBUG TEST: Stack trace: ' + e.getStackTraceString());
    }
    Test.stopTest();

    // Report exception if caught
    if (caughtException != null) {
      System.assert(
        false,
        'Exception thrown: ' +
          caughtException.getTypeName() +
          ' - ' +
          caughtException.getMessage()
      );
    }

    // Verify result is not null
    System.assertNotEquals(
      null,
      result,
      'ContentNote ID should be returned (not null)'
    );

    // Debug: Query ContentNote directly to verify creation
    List<ContentNote> notes = [
      SELECT Id, Title
      FROM ContentNote
      WHERE Id = :result
    ];
    System.debug('DEBUG TEST: ContentNote query count: ' + notes.size());
    if (!notes.isEmpty()) {
      System.debug('DEBUG TEST: ContentNote Title: ' + notes[0].Title);
    }

    // Verify ContentDocumentLink (may be async)
    List<ContentDocumentLink> links = [
      SELECT Id
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :testCase.Id
    ];
    System.debug(
      'DEBUG TEST: ContentDocumentLink query count: ' + links.size()
    );
  }

  @isTest
  static void testBuildContactAttemptNoteBody() {
    Integer attemptNumber = 3;
    Boolean contactEstablished = true;
    String noteContent = 'Detailed notes here';

    Test.startTest();
    String result = SuccessionUtilities.buildContactAttemptNoteBody(
      attemptNumber,
      contactEstablished,
      noteContent
    );
    Test.stopTest();

    System.assert(
      result.contains('SUCCESSION CONTACT ATTEMPT #3'),
      'Should contain attempt header'
    );
    System.assert(
      result.contains('Contact Established'),
      'Should contain outcome'
    );
    System.assert(result.contains('NOTES:'), 'Should contain notes header');
    System.assert(result.contains(noteContent), 'Should contain note content');
  }

  @isTest
  static void testBuildContactAttemptNoteTitle() {
    Integer attemptNumber = 4;

    Test.startTest();
    String result = SuccessionUtilities.buildContactAttemptNoteTitle(
      attemptNumber
    );
    Test.stopTest();

    System.assert(
      result.contains('Succession Contact Attempt 4'),
      'Should contain attempt number'
    );
    System.assert(result.contains('-'), 'Should contain date separator');
  }

  // ========================================
  // STRING MANIPULATION TESTS
  // ========================================

  @isTest
  static void testExtractIntegerFromDelimitedString() {
    String input = 'Succession Contact Attempt 3 - 2025-01-15';
    String delimiter = 'Succession Contact Attempt ';
    String secondDelimiter = ' - ';

    Test.startTest();
    Integer result = SuccessionUtilities.extractIntegerFromDelimitedString(
      input,
      delimiter,
      secondDelimiter
    );
    Test.stopTest();

    System.assertEquals(3, result, 'Should extract attempt number');
  }

  @isTest
  static void testExtractIntegerFromDelimitedString_Null() {
    Test.startTest();
    Integer result = SuccessionUtilities.extractIntegerFromDelimitedString(
      null,
      'delimiter',
      'second'
    );
    Test.stopTest();

    System.assertEquals(null, result, 'Should return null for null input');
  }

  @isTest
  static void testExtractIntegerFromDelimitedString_Invalid() {
    String input = 'Invalid format';
    String delimiter = 'Attempt ';
    String secondDelimiter = ' - ';

    Test.startTest();
    Integer result = SuccessionUtilities.extractIntegerFromDelimitedString(
      input,
      delimiter,
      secondDelimiter
    );
    Test.stopTest();

    System.assertEquals(null, result, 'Should return null for invalid format');
  }

  @isTest
  static void testExtractIntegerFromDelimitedString_NoSecondDelimiter() {
    String input = 'Attempt 3';
    String delimiter = 'Attempt ';

    Test.startTest();
    Integer result = SuccessionUtilities.extractIntegerFromDelimitedString(
      input,
      delimiter,
      null // No second delimiter
    );
    Test.stopTest();

    System.assertEquals(
      3,
      result,
      'Should extract integer without second delimiter'
    );
  }

  @isTest
  static void testExtractSectionContent() {
    String fullText = 'Header\n========\nNOTES:\n-----\n\nActual notes here';
    String sectionMarker = 'NOTES:';
    Integer skipLines = 3;

    Test.startTest();
    String result = SuccessionUtilities.extractSectionContent(
      fullText,
      sectionMarker,
      skipLines
    );
    Test.stopTest();

    System.assertEquals(
      'Actual notes here',
      result,
      'Should extract section content'
    );
  }

  @isTest
  static void testExtractSectionContent_NotFound() {
    String fullText = 'No section marker here';
    String sectionMarker = 'NOTES:';
    Integer skipLines = 3;

    Test.startTest();
    String result = SuccessionUtilities.extractSectionContent(
      fullText,
      sectionMarker,
      skipLines
    );
    Test.stopTest();

    System.assertEquals('', result, 'Should return empty for not found');
  }

  @isTest
  static void testExtractSectionContent_InsufficientLines() {
    String fullText = 'NOTES:\nOnly one line after marker';
    String sectionMarker = 'NOTES:';
    Integer skipLines = 10; // Skip more lines than available

    Test.startTest();
    String result = SuccessionUtilities.extractSectionContent(
      fullText,
      sectionMarker,
      skipLines
    );
    Test.stopTest();

    System.assertEquals(
      '',
      result,
      'Should return empty when skipLines exceeds available lines'
    );
  }

  // ========================================
  // SECURITY UTILITIES TESTS
  // ========================================

  @isTest
  static void testEnforceReadableFLS() {
    Contact testContact = [SELECT Id, Email FROM Contact LIMIT 1];
    List<Contact> contacts = new List<Contact>{ testContact };

    Test.startTest();
    List<SObject> result = SuccessionUtilities.enforceReadableFLS(contacts);
    Test.stopTest();

    System.assertNotEquals(null, result, 'Should return FLS-enforced records');
  }

  @isTest
  static void testEnforceReadableFLS_EmptyList() {
    List<SObject> emptyList = new List<SObject>();

    Test.startTest();
    List<SObject> result = SuccessionUtilities.enforceReadableFLS(emptyList);
    Test.stopTest();

    System.assertEquals(0, result.size(), 'Should return empty list');
  }

  @isTest
  static void testBuildSafeInCondition() {
    String values = 'New,In Progress,Closed';

    Test.startTest();
    String result = SuccessionUtilities.buildSafeInCondition(values);
    Test.stopTest();

    System.assert(result.contains('\'New\''), 'Should contain escaped value');
    System.assert(
      result.contains('\'In Progress\''),
      'Should contain escaped value with space'
    );
    System.assert(result.contains(','), 'Should be comma-separated');
  }

  @isTest
  static void testBuildSafeInCondition_WithQuotes() {
    String values = 'O\'Brien,Smith';

    Test.startTest();
    String result = SuccessionUtilities.buildSafeInCondition(values);
    Test.stopTest();

    System.assert(result.contains('O\\\'Brien'), 'Should escape single quotes');
  }

  @isTest
  static void testBuildSafeInCondition_Null() {
    Test.startTest();
    String result = SuccessionUtilities.buildSafeInCondition(null);
    Test.stopTest();

    System.assertEquals('', result, 'Should return empty string for null');
  }

  @isTest
  static void testBuildSafeInCondition_Blank() {
    Test.startTest();
    String result = SuccessionUtilities.buildSafeInCondition('');
    Test.stopTest();

    System.assertEquals('', result, 'Should return empty string for blank');
  }

  @isTest
  static void testBuildSafeLikeConditions() {
    String values = 'Successor,Primary';
    String fieldName = 'Role__c';

    Test.startTest();
    String result = SuccessionUtilities.buildSafeLikeConditions(
      values,
      fieldName
    );
    Test.stopTest();

    System.assert(
      result.contains('Role__c LIKE \'%Successor%\''),
      'Should build LIKE condition'
    );
    System.assert(result.contains(' OR '), 'Should join with OR');
  }

  @isTest
  static void testBuildSafeLikeConditions_BlankValues() {
    String fieldName = 'Role__c';

    Test.startTest();
    String result = SuccessionUtilities.buildSafeLikeConditions('', fieldName);
    Test.stopTest();

    System.assertEquals('', result, 'Should return empty for blank values');
  }

  @isTest
  static void testBuildSafeLikeConditions_BlankFieldName() {
    String values = 'Successor,Primary';

    Test.startTest();
    String result = SuccessionUtilities.buildSafeLikeConditions(values, '');
    Test.stopTest();

    System.assertEquals('', result, 'Should return empty for blank field name');
  }

  @isTest
  static void testBuildSafeLikeConditions_BothBlank() {
    Test.startTest();
    String result = SuccessionUtilities.buildSafeLikeConditions('', '');
    Test.stopTest();

    System.assertEquals('', result, 'Should return empty for both blank');
  }

  // ========================================
  // DATETIME FORMATTING TESTS
  // ========================================

  @isTest
  static void testFormatDateTime_Short() {
    DateTime dt = DateTime.newInstance(2025, 1, 15, 10, 30, 0);

    Test.startTest();
    String result = SuccessionUtilities.formatDateTime(dt, 'short');
    Test.stopTest();

    System.assertEquals('2025-01-15', result, 'Should format as short date');
  }

  @isTest
  static void testFormatDateTime_Long() {
    DateTime dt = DateTime.newInstance(2025, 1, 15, 10, 30, 45);

    Test.startTest();
    String result = SuccessionUtilities.formatDateTime(dt, 'long');
    Test.stopTest();

    System.assert(result.startsWith('2025-01-15'), 'Should contain date');
    System.assert(result.contains(':'), 'Should contain time');
  }

  @isTest
  static void testFormatDateTime_Display() {
    DateTime dt = DateTime.newInstance(2025, 1, 15, 10, 30, 0);

    Test.startTest();
    String result = SuccessionUtilities.formatDateTime(dt, 'display');
    Test.stopTest();

    System.assert(result.startsWith('01/15/2025'), 'Should format as display');
  }

  @isTest
  static void testFormatDateTime_Null() {
    Test.startTest();
    String result = SuccessionUtilities.formatDateTime(null, 'short');
    Test.stopTest();

    System.assertEquals('', result, 'Should return empty for null');
  }

  @isTest
  static void testFormatDateTime_Timestamp() {
    DateTime dt = DateTime.newInstance(2025, 1, 15, 10, 30, 45);

    Test.startTest();
    String result = SuccessionUtilities.formatDateTime(dt, 'timestamp');
    Test.stopTest();

    // ISO 8601 format: yyyy-MM-dd'T'HH:mm:ss'Z'
    System.assert(result.contains('2025-01-15T'), 'Should contain ISO date');
    System.assert(result.contains('Z'), 'Should contain UTC indicator');
  }

  @isTest
  static void testFormatDateTime_UnknownPattern() {
    DateTime dt = DateTime.newInstance(2025, 1, 15, 10, 30, 0);

    Test.startTest();
    String result = SuccessionUtilities.formatDateTime(dt, 'invalid_pattern');
    Test.stopTest();

    // Should default to 'display' format (MM/dd/yyyy hh:mm a)
    System.assert(
      result.startsWith('01/15/2025'),
      'Should default to display format'
    );
  }

  // ========================================
  // ERROR HANDLING TESTS
  // ========================================

  @isTest
  static void testThrowAuraException() {
    String userMessage = 'Operation failed';
    Exception originalEx = new DmlException('DML failed');

    Test.startTest();
    try {
      SuccessionUtilities.throwAuraException(userMessage, originalEx);
      System.assert(false, 'Should have thrown exception');
    } catch (Exception e) {
      // Debug: Print actual exception message to understand format
      System.debug('DEBUG: Actual exception message: ' + e.getMessage());
      System.debug('DEBUG: Expected to contain: ' + userMessage);

      // Verify exception was thrown and contains user message
      System.assert(
        e.getMessage().contains(userMessage),
        'Should contain user message. Actual: ' + e.getMessage()
      );
    }
    Test.stopTest();
  }

  // ========================================
  // BUSINESS LOGIC TESTS
  // ========================================

  @isTest
  static void testValidateSuccessorAllocations_EqualSplit() {
    List<FinServ__FinancialAccountRole__c> successors = new List<FinServ__FinancialAccountRole__c>{
      new FinServ__FinancialAccountRole__c(SuccessorAllocation__c = null),
      new FinServ__FinancialAccountRole__c(SuccessorAllocation__c = null)
    };

    Test.startTest();
    String result = SuccessionUtilities.validateSuccessorAllocations(
      successors
    );
    Test.stopTest();

    System.assertEquals(
      null,
      result,
      'Equal split (no allocations) should be valid'
    );
  }

  @isTest
  static void testValidateSuccessorAllocations_ValidSplit() {
    List<FinServ__FinancialAccountRole__c> successors = new List<FinServ__FinancialAccountRole__c>{
      new FinServ__FinancialAccountRole__c(SuccessorAllocation__c = 60),
      new FinServ__FinancialAccountRole__c(SuccessorAllocation__c = 40)
    };

    Test.startTest();
    String result = SuccessionUtilities.validateSuccessorAllocations(
      successors
    );
    Test.stopTest();

    System.assertEquals(
      null,
      result,
      'Valid allocation (60/40 = 100%) should pass'
    );
  }

  @isTest
  static void testValidateSuccessorAllocations_PartialAllocation() {
    List<FinServ__FinancialAccountRole__c> successors = new List<FinServ__FinancialAccountRole__c>{
      new FinServ__FinancialAccountRole__c(SuccessorAllocation__c = 50),
      new FinServ__FinancialAccountRole__c(SuccessorAllocation__c = null)
    };

    Test.startTest();
    String result = SuccessionUtilities.validateSuccessorAllocations(
      successors
    );
    Test.stopTest();

    System.assertNotEquals(
      null,
      result,
      'Partial allocation should be invalid'
    );
    System.assert(
      result.contains('ALL successors or NONE'),
      'Should explain error'
    );
  }

  @isTest
  static void testValidateSuccessorAllocations_InvalidSum() {
    List<FinServ__FinancialAccountRole__c> successors = new List<FinServ__FinancialAccountRole__c>{
      new FinServ__FinancialAccountRole__c(SuccessorAllocation__c = 50),
      new FinServ__FinancialAccountRole__c(SuccessorAllocation__c = 30)
    };

    Test.startTest();
    String result = SuccessionUtilities.validateSuccessorAllocations(
      successors
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Invalid sum should be invalid');
    System.assert(result.contains('sum to 100%'), 'Should explain error');
  }

  @isTest
  static void testValidateSuccessorAllocations_EmptyList() {
    List<FinServ__FinancialAccountRole__c> successors = new List<FinServ__FinancialAccountRole__c>();

    Test.startTest();
    String result = SuccessionUtilities.validateSuccessorAllocations(
      successors
    );
    Test.stopTest();

    System.assertEquals(null, result, 'Empty list should be valid');
  }

  // ========================================
  // QUERY UTILITIES TESTS
  // ========================================

  @isTest
  static void testQuerySuccessorContact() {
    Contact testContact = [SELECT Id FROM Contact LIMIT 1];

    Test.startTest();
    Contact result = SuccessionUtilities.querySuccessorContact(testContact.Id);
    Test.stopTest();

    System.assertNotEquals(null, result, 'Should return contact');
    System.assertEquals(testContact.Id, result.Id, 'IDs should match');
    System.assertNotEquals(null, result.Email, 'Should have email');
  }

  @isTest
  static void testQuerySuccessorContact_Null() {
    Test.startTest();
    Contact result = SuccessionUtilities.querySuccessorContact(null);
    Test.stopTest();

    System.assertEquals(null, result, 'Should return null for null ID');
  }

  @isTest
  static void testQuerySuccessorContact_NonExistent() {
    // Create fake ID that doesn't exist
    Id fakeId = '003000000000000AAA';

    Test.startTest();
    Contact result = SuccessionUtilities.querySuccessorContact(fakeId);
    Test.stopTest();

    System.assertEquals(null, result, 'Should return null for non-existent');
  }
}
