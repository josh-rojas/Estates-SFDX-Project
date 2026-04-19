/**
 * SuccessionUtilities
 *
 * Minimal helper functions used by the Succession Contact Cadence experience.
 * Includes email validation, ContentNote creation, Chatter posting, and
 * small formatting helpers shared by the ContactCadenceController.
 */
public with sharing class SuccessionUtilities {
  private static final String EMAIL_REGEX = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$';
  private static final String FORMAT_SHORT_DATE = 'yyyy-MM-dd';
  private static final String FORMAT_LONG_DATETIME = 'yyyy-MM-dd HH:mm:ss';
  private static final String FORMAT_DISPLAY_DATETIME = 'MM/dd/yyyy HH:mm';
  private static final String FORMAT_TIMESTAMP = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';

  /**
   * Wrapper class for email validation results returned to LWC.
   */
  public class EmailValidationResult {
    @AuraEnabled
    public String email { get; set; }
    @AuraEnabled
    public Boolean hasEmail { get; set; }
    @AuraEnabled
    public Boolean hasValidFormat { get; set; }
    @AuraEnabled
    public Boolean hasOptedOut { get; set; }
    @AuraEnabled
    public String warning { get; set; }
  }

  /**
   * Validate an email address for existence, format, and opt-out status.
   */
  public static EmailValidationResult validateEmail(
    String email,
    Boolean hasOptedOut
  ) {
    EmailValidationResult result = new EmailValidationResult();
    result.email = email;
    result.hasEmail = String.isNotBlank(email);
    result.hasOptedOut = hasOptedOut == true;

    if (result.hasEmail) {
      result.hasValidFormat = Pattern.matches(EMAIL_REGEX, email);
    } else {
      result.hasValidFormat = false;
    }

    List<String> warnings = new List<String>();

    if (result.hasOptedOut) {
      warnings.add('⚠️ Successor has opted out of email. Contact by phone only.');
    }
    if (!result.hasEmail) {
      warnings.add('No email address on file for this successor.');
    } else if (!result.hasValidFormat) {
      warnings.add('Email address format appears invalid: ' + email);
    }

    result.warning = warnings.isEmpty() ? null : String.join(warnings, ' ');
    return result;
  }

  /**
   * Format DateTime values using a small set of supported patterns.
   */
  public static String formatDateTime(DateTime dt, String pattern) {
    if (dt == null) {
      return '';
    }

    switch on pattern {
      when 'short' {
        return dt.format(FORMAT_SHORT_DATE);
      }
      when 'long' {
        return dt.format(FORMAT_LONG_DATETIME);
      }
      when 'timestamp' {
        return dt.format(FORMAT_TIMESTAMP);
      }
      when else {
        return dt.format(FORMAT_DISPLAY_DATETIME);
      }
    }
  }

  /**
   * Create a simple Chatter text post.
   */
  public static FeedItem createChatterPost(
    Id recordId,
    String postBody,
    Boolean useSystemMode
  ) {
    if (recordId == null || String.isBlank(postBody)) {
      return null;
    }

    FeedItem post = new FeedItem();
    post.ParentId = recordId;
    post.Body = postBody;
    post.Type = 'TextPost';

    if (useSystemMode) {
      Database.insert(post, AccessLevel.SYSTEM_MODE);
    } else {
      insert post;
    }

    return post;
  }

  /**
   * Convenience overload that defaults to user mode.
   */
  public static FeedItem createChatterPost(Id recordId, String postBody) {
    return createChatterPost(recordId, postBody, false);
  }

  /**
   * Create a Chatter post with a clickable record link.
   */
  public static FeedItem createChatterPostWithRecordLink(
    Id parentId,
    String baseMessage,
    Id linkRecordId,
    String linkTitle,
    Boolean useSystemMode
  ) {
    if (parentId == null || String.isBlank(baseMessage)) {
      return null;
    }

    if (linkRecordId == null || String.isBlank(linkTitle)) {
      return createChatterPost(parentId, baseMessage, useSystemMode);
    }

    String recordUrl = buildLightningRecordUrl(linkRecordId);
    if (String.isBlank(recordUrl)) {
      return createChatterPost(parentId, baseMessage, useSystemMode);
    }

    FeedItem post = new FeedItem();
    post.ParentId = parentId;
    post.Body = baseMessage;
    post.Type = 'LinkPost';
    post.Title = linkTitle;
    post.LinkUrl = recordUrl;

    if (useSystemMode) {
      Database.insert(post, AccessLevel.SYSTEM_MODE);
    } else {
      insert post;
    }

    return post;
  }

  /**
   * Build Lightning record URL for hyperlinking.
   */
  private static String buildLightningRecordUrl(Id recordId) {
    if (recordId == null) {
      return '';
    }

    try {
      String sObjectName = recordId.getSObjectType().getDescribe().getName();
      return '/lightning/r/' + sObjectName + '/' + recordId + '/view';
    } catch (Exception e) {
      return '';
    }
  }

  /**
   * Build Chatter post body summarizing a contact attempt.
   */
  public static String buildContactAttemptPostBody(
    Integer attemptNumber,
    Boolean contactEstablished,
    String noteContent
  ) {
    DateTime now = DateTime.now();
    String formattedDateTime = formatDateTime(now, 'display');
    String outcomeEmoji = contactEstablished ? '✅' : '❌';
    String outcomeText = contactEstablished
      ? 'Contact Established'
      : 'Contact Not Established';

    return String.format(
      '{0} Succession Contact Attempt {1}\n\n' +
        'Time: {2}\n' +
        'Outcome: {3}\n\n' +
        'Agent Notes:\n{4}',
      new List<String>{
        outcomeEmoji,
        String.valueOf(attemptNumber),
        formattedDateTime,
        outcomeText,
        noteContent
      }
    );
  }

  /**
   * Build ContentNote body for a contact attempt.
   */
  public static String buildContactAttemptNoteBody(
    Integer attemptNumber,
    Boolean contactEstablished,
    String noteContent
  ) {
    String header = 'SUCCESSION CONTACT ATTEMPT #' + attemptNumber;
    String outcome = contactEstablished
      ? 'Contact Established'
      : 'Contact Not Established';
    String dateLine = 'Date: ' + Date.today().format();

    return header +
      '\n----------------------------\n' +
      'Outcome: ' +
      outcome +
      '\n' +
      dateLine +
      '\n\nNOTES:\n-----\n\n' +
      (noteContent == null ? '' : noteContent);
  }

  /**
   * Build ContentNote title for a contact attempt.
   * Example: "Succession Contact Attempt 3 - 2025-01-15"
   */
  public static String buildContactAttemptNoteTitle(Integer attemptNumber) {
    String dateOnly = Date.today().format();
    return 'Succession Contact Attempt ' + attemptNumber + ' - ' + dateOnly;
  }

  /**
   * Extract an integer between one or two delimiters.
   */
  public static Integer extractIntegerFromDelimitedString(
    String input,
    String delimiter,
    String secondDelimiter
  ) {
    if (String.isBlank(input) || String.isBlank(delimiter)) {
      return null;
    }

    Integer start = input.indexOf(delimiter);
    if (start == -1) {
      return null;
    }
    start += delimiter.length();

    Integer end = secondDelimiter == null
      ? input.length()
      : input.indexOf(secondDelimiter, start);
    if (end == null || end == -1) {
      end = input.length();
    }

    try {
      return Integer.valueOf(input.substring(start, end));
    } catch (Exception e) {
      return null;
    }
  }

  /**
   * Extract content that follows a marker, skipping the supplied number of lines.
   */
  public static String extractSectionContent(
    String fullContent,
    String sectionMarker,
    Integer skipLines
  ) {
    if (String.isBlank(fullContent) || String.isBlank(sectionMarker)) {
      return '';
    }

    List<String> lines = fullContent.split('\\n');
    Integer markerIndex = -1;

    for (Integer i = 0; i < lines.size(); i++) {
      if (lines[i].contains(sectionMarker)) {
        markerIndex = i;
        break;
      }
    }

    if (markerIndex == -1) {
      return '';
    }

    Integer startIndex = markerIndex + (skipLines == null ? 0 : skipLines);
    if (startIndex >= lines.size()) {
      return '';
    }

    List<String> contentLines = lines.subList(startIndex, lines.size());
    return String.join(contentLines, '\n').trim();
  }

  /**
   * Create a ContentNote and link it to the specified parent record.
   */
  public static Id createLinkedContentNote(
    Id recordId,
    String noteTitle,
    String noteBody
  ) {
    if (recordId == null) {
      return null;
    }

    ContentNote note = new ContentNote();
    note.Title = noteTitle;
    note.Content = Blob.valueOf(noteBody == null ? '' : noteBody);
    Database.insert(note, AccessLevel.USER_MODE);

    // ContentDocument is created asynchronously; attempt to link immediately if available.
    List<ContentDocument> docs = [
      SELECT Id
      FROM ContentDocument
      WHERE LatestPublishedVersionId = :note.Id
      LIMIT 1
    ];

    if (!docs.isEmpty()) {
      ContentDocumentLink link = new ContentDocumentLink();
      link.ContentDocumentId = docs[0].Id;
      link.LinkedEntityId = recordId;
      link.ShareType = 'V';
      link.Visibility = 'AllUsers';
      Database.insert(link, AccessLevel.USER_MODE);
    }

    return note.Id;
  }
}
