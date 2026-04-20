/**
 * Tests for the trimmed SuccessionUtilities helper functions used by
 * the Succession Contact Cadence feature.
 */
@IsTest
private class SuccessionUtilities_Test {
  @TestSetup
  static void setupData() {
    // Minimal case used for ContentNote and Chatter tests
    insert new Case(Subject = 'Contact Cadence Case', Status = 'New', Origin = 'Phone');
  }

  @IsTest
  static void validateEmail_variations() {
    Test.startTest();
    SuccessionUtilities.EmailValidationResult valid = SuccessionUtilities.validateEmail(
      'test@example.com',
      false
    );
    SuccessionUtilities.EmailValidationResult optedOut = SuccessionUtilities.validateEmail(
      'opted@example.com',
      true
    );
    SuccessionUtilities.EmailValidationResult missing = SuccessionUtilities.validateEmail(
      null,
      false
    );
    SuccessionUtilities.EmailValidationResult invalid = SuccessionUtilities.validateEmail(
      'bad-email',
      false
    );
    Test.stopTest();

    System.assertEquals(true, valid.hasValidFormat, 'Valid email should pass format check');
    System.assertEquals(true, optedOut.hasOptedOut, 'Opt-out flag should be preserved');
    System.assertEquals(false, missing.hasEmail, 'Missing email should be flagged');
    System.assertEquals(false, invalid.hasValidFormat, 'Invalid format should be flagged');
  }

  @IsTest
  static void formatDateTime_supportedPatterns() {
    DateTime sample = DateTime.newInstance(2025, 1, 15, 10, 30, 45);

    Test.startTest();
    String displayVal = SuccessionUtilities.formatDateTime(sample, 'display');
    String shortVal = SuccessionUtilities.formatDateTime(sample, 'short');
    String longVal = SuccessionUtilities.formatDateTime(sample, 'long');
    String timestampVal = SuccessionUtilities.formatDateTime(sample, 'timestamp');
    Test.stopTest();

    System.assert(displayVal.contains('01/15/2025'), 'Display format should include date');
    System.assertEquals('2025-01-15', shortVal, 'Short format should be yyyy-MM-dd');
    System.assert(longVal.startsWith('2025-01-15'), 'Long format should include date');
    System.assert(timestampVal.contains('T'), 'Timestamp format should be ISO-like');
  }

  @IsTest
  static void buildContactAttemptArtifacts() {
    Test.startTest();
    String postBody = SuccessionUtilities.buildContactAttemptPostBody(2, true, 'Notes here');
    String noteBody = SuccessionUtilities.buildContactAttemptNoteBody(3, false, 'Follow up later');
    String noteTitle = SuccessionUtilities.buildContactAttemptNoteTitle(4);
    Integer attemptNum = SuccessionUtilities.extractIntegerFromDelimitedString(
      noteTitle,
      'Succession Contact Attempt ',
      ' - '
    );
    String notesSection = SuccessionUtilities.extractSectionContent(
      noteBody,
      'NOTES:',
      3
    );
    Test.stopTest();

    System.assert(postBody.contains('Attempt 2'), 'Post body should include attempt number');
    System.assert(noteBody.contains('Contact Not Established'), 'Note body should include outcome');
    System.assertEquals(4, attemptNum, 'Attempt number should parse from title');
    System.assertEquals('Follow up later', notesSection, 'Notes should be extracted');
  }

  @IsTest
  static void contentNote_and_chatterHelpers() {
    Case c = [SELECT Id FROM Case LIMIT 1];

    Test.startTest();
    Id noteId = SuccessionUtilities.createLinkedContentNote(
      c.Id,
      'Succession Contact Attempt 1 - 2025-01-01',
      'Test note body'
    );
    FeedItem textPost = SuccessionUtilities.createChatterPost(
      c.Id,
      'Contact cadence update',
      false
    );
    FeedItem linkPost = SuccessionUtilities.createChatterPostWithRecordLink(
      c.Id,
      'See related task',
      c.Id,
      'Case Link',
      false
    );
    Test.stopTest();

    System.assertNotEquals(null, noteId, 'ContentNote should be created');
    System.assertNotEquals(null, textPost, 'Chatter text post should be created');
    System.assertEquals('TextPost', textPost.Type, 'Text post type should be set');
    System.assertNotEquals(null, linkPost, 'Chatter link post should be created');
    System.assertEquals('LinkPost', linkPost.Type, 'Link post type should be set');
  }
}
