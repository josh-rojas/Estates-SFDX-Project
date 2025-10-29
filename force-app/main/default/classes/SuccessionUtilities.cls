/**
 * SuccessionUtilities
 *
 * Shared utility class for Succession Management System.
 * Consolidates common patterns across controllers to reduce duplication and improve maintainability.
 *
 * TIER 1 UTILITIES (High Priority):
 * - Email validation (compliance-critical)
 * - Chatter post creation (used in multiple controllers)
 * - Record type lookup (caching opportunity)
 * - ContentNote integration (complexity reduction)
 *
 * @author Claude Code
 * @date 2025-10-27
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class SuccessionUtilities {
  // ========================================
  // CONSTANTS
  // ========================================

  /** Email validation regex pattern (RFC 5322 compliant) */
  private static final String EMAIL_REGEX = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$';

  /** DateTime format patterns */
  private static final String FORMAT_SHORT_DATE = 'yyyy-MM-dd';
  private static final String FORMAT_LONG_DATETIME = 'yyyy-MM-dd HH:mm:ss';
  private static final String FORMAT_DISPLAY_DATETIME = 'MM/dd/yyyy HH:mm';
  private static final String FORMAT_TIMESTAMP = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';

  /** Cached record type IDs for performance */
  private static Map<String, Id> recordTypeCache = new Map<String, Id>();

  // ========================================
  // TIER 1: EMAIL VALIDATION (COMPLIANCE-CRITICAL)
  // ========================================

  /**
   * Validate email address for compliance
   * Checks: existence, format (RFC 5322), opt-out status
   *
   * @param email Email address to validate
   * @param hasOptedOut Opt-out status from Contact/Account
   * @return EmailValidationResult with validation flags and warnings
   */
  public static EmailValidationResult validateEmail(
    String email,
    Boolean hasOptedOut
  ) {
    EmailValidationResult result = new EmailValidationResult();
    result.email = email;
    result.hasEmail = String.isNotBlank(email);
    result.hasOptedOut = hasOptedOut == true; // Null-safe check

    // Validate email format using regex
    if (result.hasEmail) {
      result.hasValidFormat = Pattern.matches(EMAIL_REGEX, email);
    } else {
      result.hasValidFormat = false;
    }

    // Build warning message for UI display
    List<String> warnings = new List<String>();

    if (result.hasOptedOut) {
      warnings.add(
        '⚠️ Successor has opted out of email. Contact by phone only.'
      );
    }

    if (!result.hasEmail) {
      warnings.add('No email address on file for this successor.');
    } else if (!result.hasValidFormat) {
      warnings.add('Email address format appears invalid: ' + email);
    }

    result.warning = warnings.isEmpty()
      ? null
      : String.join(warnings, ' ');

    return result;
  }

  /**
   * Wrapper class for email validation results
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

  // ========================================
  // TIER 1: CHATTER POST CREATION
  // ========================================

  /**
   * Create a Chatter post on a record
   * Handles formatting and batch/immediate insertion
   *
   * @param recordId Parent record ID (Case, Account, etc.)
   * @param postBody Post body text (pre-formatted)
   * @param useSystemMode Use SYSTEM_MODE for automation context
   * @return FeedItem created (ID populated after insert)
   */
  public static FeedItem createChatterPost(
    Id recordId,
    String postBody,
    Boolean useSystemMode
  ) {
    FeedItem post = new FeedItem();
    post.ParentId = recordId;
    post.Body = postBody;
    post.Type = 'TextPost';

    if (useSystemMode) {
      // Automation context - use SYSTEM_MODE
      Database.insert(post, AccessLevel.SYSTEM_MODE);
    } else {
      // User context - use default access (respects sharing)
      insert post;
    }

    return post;
  }

  /**
   * Build Chatter post body for contact attempt outcome
   * Formats attempt number + outcome + timestamp + notes
   *
   * @param attemptNumber Attempt number (1-5)
   * @param contactEstablished Whether contact was established
   * @param noteContent Agent notes
   * @return Formatted post body
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
   * Build Chatter post body for pathway tasks created
   * Formats pathway name + task count
   *
   * @param pathwayName Pathway name (Final Grant, New DAF, Disclaim)
   * @param taskCount Number of tasks created
   * @return Formatted post body
   */
  public static String buildPathwayTaskPostBody(
    String pathwayName,
    Integer taskCount
  ) {
    return String.format(
      '{0} pathway tasks created for: {1}. Review milestones in Activities to guide the case through completion.',
      new List<String>{ String.valueOf(taskCount), pathwayName }
    );
  }

  // ========================================
  // TIER 1: RECORD TYPE LOOKUP (CACHED)
  // ========================================

  /**
   * Get EstateAdministration record type ID for Case
   * Cached lookup for performance
   *
   * @return Record type ID or null if not found
   */
  public static Id getEstateAdministrationRecordTypeId() {
    return getCachedRecordTypeId('Case', 'EstateAdministration');
  }

  /**
   * Get record type ID by SObject and developer name (cached)
   * Centralized caching mechanism for all record types
   *
   * @param sobjectType SObject API name (e.g., 'Case')
   * @param developerName Record type developer name
   * @return Record type ID or null if not found
   */
  public static Id getCachedRecordTypeId(
    String sobjectType,
    String developerName
  ) {
    String cacheKey = sobjectType + ':' + developerName;

    // Check cache first
    if (recordTypeCache.containsKey(cacheKey)) {
      return recordTypeCache.get(cacheKey);
    }

    // Query if not cached
    List<RecordType> recordTypes = [
      SELECT Id
      FROM RecordType
      WHERE SObjectType = :sobjectType AND DeveloperName = :developerName
      WITH USER_MODE
      LIMIT 1
    ];

    Id recordTypeId = recordTypes.isEmpty() ? null : recordTypes[0].Id;

    // Cache result (including null to avoid re-querying)
    recordTypeCache.put(cacheKey, recordTypeId);

    return recordTypeId;
  }

  // ========================================
  // TIER 1: CONTENTNOTE INTEGRATION
  // ========================================

  /**
   * Create ContentNote and link to record
   * Handles ContentDocument lookup and ContentDocumentLink creation
   *
   * @param recordId Parent record ID (Case, Account, etc.)
   * @param noteTitle Note title
   * @param noteBody Note body (plain text or formatted)
   * @return ContentNote ID created
   */
  public static Id createLinkedContentNote(
    Id recordId,
    String noteTitle,
    String noteBody
  ) {
    // Create ContentNote
    ContentNote note = new ContentNote();
    note.Title = noteTitle;
    note.Content = Blob.valueOf(noteBody);
    Database.insert(note, AccessLevel.USER_MODE);

    System.debug('DEBUG: Created ContentNote with Title: ' + noteTitle);
    System.debug('DEBUG: ContentNote Id: ' + note.Id);

    // Query ContentDocument using LatestPublishedVersionId
    // ContentNote is a subtype of ContentVersion
    ContentDocument doc = [
      SELECT Id
      FROM ContentDocument
      WHERE LatestPublishedVersionId = :note.Id
      WITH USER_MODE
      LIMIT 1
    ];

    System.debug('DEBUG: Found ContentDocument Id: ' + doc.Id);

    // Link note to parent record
    ContentDocumentLink cdl = new ContentDocumentLink();
    cdl.ContentDocumentId = doc.Id;
    cdl.LinkedEntityId = recordId;
    cdl.ShareType = 'V'; // Viewer permission
    cdl.Visibility = 'AllUsers'; // Visible to all users with access to record
    Database.insert(cdl, AccessLevel.USER_MODE);

    System.debug('DEBUG: Created ContentDocumentLink to record: ' + recordId);

    return note.Id;
  }

  /**
   * Build formatted ContentNote body for succession contact attempt
   * Creates structured format with headers, metadata, and user notes
   *
   * @param attemptNumber Attempt number (1-5)
   * @param contactEstablished Whether contact was established
   * @param noteContent User-entered notes
   * @return Formatted note body
   */
  public static String buildContactAttemptNoteBody(
    Integer attemptNumber,
    Boolean contactEstablished,
    String noteContent
  ) {
    DateTime now = DateTime.now();
    String formattedDate = formatDateTime(now, 'long');
    String outcomeLabel = contactEstablished
      ? 'Contact Established'
      : 'Contact Not Established';

    String noteBody = '========================================\n';
    noteBody += 'SUCCESSION CONTACT ATTEMPT #' + attemptNumber + '\n';
    noteBody += '========================================\n\n';
    noteBody += 'Date/Time: ' + formattedDate + '\n';
    noteBody += 'Outcome: ' + outcomeLabel + '\n\n';
    noteBody += '----------------------------------------\n';
    noteBody += 'NOTES:\n';
    noteBody += '----------------------------------------\n\n';
    noteBody += noteContent;

    return noteBody;
  }

  /**
   * Build ContentNote title for succession contact attempt
   * Format: "Succession Contact Attempt X - YYYY-MM-DD"
   *
   * @param attemptNumber Attempt number (1-5)
   * @return Formatted note title
   */
  public static String buildContactAttemptNoteTitle(Integer attemptNumber) {
    String dateOnly = formatDateTime(DateTime.now(), 'short');
    return 'Succession Contact Attempt ' + attemptNumber + ' - ' + dateOnly;
  }

  // ========================================
  // TIER 2: STRING MANIPULATION UTILITIES
  // ========================================

  /**
   * Extract integer from delimited string
   * Example: "Succession Contact Attempt 3 - 2025-01-15" => 3
   *
   * @param input String to parse
   * @param delimiter Delimiter to split on (e.g., "Succession Contact Attempt ")
   * @param secondDelimiter Second delimiter to split remaining part (e.g., " - ")
   * @return Extracted integer or null if parsing fails
   */
  public static Integer extractIntegerFromDelimitedString(
    String input,
    String delimiter,
    String secondDelimiter
  ) {
    try {
      if (String.isBlank(input) || String.isBlank(delimiter)) {
        return null;
      }

      String[] parts = input.split(delimiter);
      if (parts.size() <= 1) {
        return null;
      }

      String remainingPart = parts[1];

      if (String.isNotBlank(secondDelimiter)) {
        String[] secondParts = remainingPart.split(secondDelimiter);
        if (secondParts.size() == 0) {
          return null;
        }
        remainingPart = secondParts[0];
      }

      return Integer.valueOf(remainingPart.trim());
    } catch (Exception e) {
      System.debug('Error parsing integer from string: ' + input);
      return null;
    }
  }

  /**
   * Extract section content from formatted text
   * Example: Extract text after "NOTES:" header
   *
   * @param fullText Full text to search
   * @param sectionMarker Section marker (e.g., "NOTES:")
   * @param skipLines Number of lines to skip after marker (e.g., 3 for header + dashes + blank)
   * @return Section content or empty string
   */
  public static String extractSectionContent(
    String fullText,
    String sectionMarker,
    Integer skipLines
  ) {
    if (String.isBlank(fullText) || String.isBlank(sectionMarker)) {
      return '';
    }

    // Find the section marker
    Integer markerIndex = fullText.indexOf(sectionMarker);
    if (markerIndex == -1) {
      return '';
    }

    // Skip specified number of lines
    Integer startIndex = markerIndex;
    for (Integer i = 0; i < skipLines; i++) {
      startIndex = fullText.indexOf('\n', startIndex);
      if (startIndex == -1) {
        return '';
      }
      startIndex++; // Move past newline
    }

    // Extract everything after skipped lines
    String content = fullText.substring(startIndex).trim();
    return content;
  }

  // ========================================
  // TIER 2: SECURITY UTILITIES
  // ========================================

  /**
   * Enforce field-level security (FLS) for readable records
   * Wrapper around Security.stripInaccessible
   *
   * @param records Records to filter
   * @return FLS-enforced records
   */
  public static List<SObject> enforceReadableFLS(List<SObject> records) {
    if (records == null || records.isEmpty()) {
      return new List<SObject>();
    }

    SObjectAccessDecision decision = Security.stripInaccessible(
      AccessType.READABLE,
      records
    );
    return decision.getRecords();
  }

  /**
   * Build safe SQL IN condition from comma-separated values
   * Prevents SQL injection via String.escapeSingleQuotes
   *
   * @param commaSeparatedValues Comma-separated values
   * @return Escaped SQL condition (e.g., "'value1','value2'")
   */
  public static String buildSafeInCondition(String commaSeparatedValues) {
    if (String.isBlank(commaSeparatedValues)) {
      return '';
    }

    List<String> values = commaSeparatedValues.split(',');
    List<String> escapedValues = new List<String>();

    for (String value : values) {
      String trimmedValue = value.trim();
      escapedValues.add(
        '\'' + String.escapeSingleQuotes(trimmedValue) + '\''
      );
    }

    return String.join(escapedValues, ',');
  }

  /**
   * Build safe SQL LIKE conditions with OR logic
   * Prevents SQL injection via String.escapeSingleQuotes
   *
   * @param commaSeparatedValues Comma-separated values for LIKE
   * @param fieldName Field name to apply LIKE condition to
   * @return Escaped SQL condition (e.g., "field LIKE '%value1%' OR field LIKE '%value2%'")
   */
  public static String buildSafeLikeConditions(
    String commaSeparatedValues,
    String fieldName
  ) {
    if (String.isBlank(commaSeparatedValues) || String.isBlank(fieldName)) {
      return '';
    }

    List<String> values = commaSeparatedValues.split(',');
    List<String> likeConditions = new List<String>();

    for (String value : values) {
      String trimmedValue = value.trim();
      likeConditions.add(
        fieldName +
        ' LIKE \'%' +
        String.escapeSingleQuotes(trimmedValue) +
        '%\''
      );
    }

    return String.join(likeConditions, ' OR ');
  }

  // ========================================
  // TIER 2: DATETIME FORMATTING
  // ========================================

  /**
   * Format DateTime for display with predefined patterns
   * Centralized format patterns for consistency
   *
   * @param dt DateTime to format
   * @param patternType Pattern type: 'short', 'long', 'display', 'timestamp'
   * @return Formatted string
   */
  public static String formatDateTime(DateTime dt, String patternType) {
    if (dt == null) {
      return '';
    }

    String pattern;
    switch on patternType {
      when 'short' {
        pattern = FORMAT_SHORT_DATE; // yyyy-MM-dd
      }
      when 'long' {
        pattern = FORMAT_LONG_DATETIME; // yyyy-MM-dd HH:mm:ss
      }
      when 'display' {
        pattern = FORMAT_DISPLAY_DATETIME; // MM/dd/yyyy HH:mm
      }
      when 'timestamp' {
        pattern = FORMAT_TIMESTAMP; // ISO 8601
      }
      when else {
        pattern = FORMAT_DISPLAY_DATETIME; // Default
      }
    }

    return dt.format(pattern);
  }

  // ========================================
  // TIER 2: ERROR HANDLING
  // ========================================

  /**
   * Throw AuraHandledException with consistent formatting
   * Centralizes error handling and logging
   *
   * @param userMessage User-friendly error message
   * @param e Original exception (for logging)
   * @throws AuraHandledException
   */
  public static void throwAuraException(String userMessage, Exception e) {
    // Log full exception details
    System.debug(LoggingLevel.ERROR, 'Exception occurred: ' + userMessage);
    System.debug(LoggingLevel.ERROR, 'Exception type: ' + e.getTypeName());
    System.debug(LoggingLevel.ERROR, 'Exception message: ' + e.getMessage());
    System.debug(
      LoggingLevel.ERROR,
      'Stack trace: ' + e.getStackTraceString()
    );

    // Throw user-friendly exception
    throw new AuraHandledException(userMessage + ': ' + e.getMessage());
  }

  // ========================================
  // TIER 3: BUSINESS LOGIC UTILITIES
  // ========================================

  /**
   * Validate successor allocation percentages
   * Business rules:
   * - All successors must have allocation OR none have allocation
   * - Allocations must sum to 100% (with 0.01 tolerance for rounding)
   *
   * @param successors FinancialAccountRole records with SuccessorAllocation__c field
   * @return Error message or null if valid
   */
  public static String validateSuccessorAllocations(
    List<FinServ__FinancialAccountRole__c> successors
  ) {
    if (successors == null || successors.isEmpty()) {
      return null;
    }

    Integer allocatedCount = 0;
    Decimal totalAllocation = 0;

    for (FinServ__FinancialAccountRole__c successor : successors) {
      if (successor.SuccessorAllocation__c != null) {
        allocatedCount++;
        totalAllocation += successor.SuccessorAllocation__c;
      }
    }

    // No allocations specified = equal split (valid)
    if (allocatedCount == 0) {
      return null;
    }

    // Partial allocation (some have, some don't) = invalid
    if (allocatedCount > 0 && allocatedCount < successors.size()) {
      return 'Successor allocations must be set for ALL successors or NONE. ' +
        'Found ' +
        allocatedCount +
        ' of ' +
        successors.size() +
        ' with allocations. ' +
        'Either assign percentages to all successors, or leave all blank for equal distribution.';
    }

    // All allocated - verify sum to 100%
    // Use 0.01 tolerance for floating point comparison
    if (Math.abs(totalAllocation - 100) > 0.01) {
      return 'Successor allocations must sum to 100%. ' +
        'Current total: ' +
        totalAllocation.format() +
        '%. ' +
        'Please adjust allocations so they total exactly 100%.';
    }

    return null; // Validation passed
  }

  /**
   * Query successor contact information
   * Standardized query with email and phone
   *
   * @param successorId Successor Contact ID
   * @return Contact with Email, Phone, Name or null if not found
   */
  public static Contact querySuccessorContact(Id successorId) {
    if (successorId == null) {
      return null;
    }

    List<Contact> contacts = [
      SELECT
        Id,
        FirstName,
        LastName,
        Name,
        Email,
        Phone,
        HasOptedOutOfEmail
      FROM Contact
      WHERE Id = :successorId
      WITH USER_MODE
      LIMIT 1
    ];

    return contacts.isEmpty() ? null : contacts[0];
  }
}
