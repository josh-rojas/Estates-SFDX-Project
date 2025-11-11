/**
 * CreateSuccessionCaseController
 *
 * Apex controller for FinancialAccount Quick Action to create succession cases.
 * Handles both single and multi-successor scenarios in pure Apex (no flows).
 *
 * Single Successor: Creates one Case (Type = "Named Successor Enactment")
 * Multi-Successor: Creates parent Case (Type = "Multi-Account Succession Master")
 *                  + child Cases for each successor
 *
 * @author Claude Code
 * @date 2025-01-27
 * @version 2.0 - Refactored to handle multi-successor in Apex
 */
public with sharing class CreateSuccessionCaseController {
  /**
   * Wrapper class for Quick Action result
   */
  public class CreateCaseResult {
    @AuraEnabled
    public Boolean success { get; set; }
    @AuraEnabled
    public String message { get; set; }
    @AuraEnabled
    public Id seedCaseId { get; set; }
    @AuraEnabled
    public Id parentCaseId { get; set; }
    @AuraEnabled
    public Integer successorCount { get; set; }
  }

  /**
   * Main entry point for Quick Action
   * Handles both single and multi-successor scenarios
   *
   * @param financialAccountId - ID of the FinancialAccount
   * @return CreateCaseResult with success status and case information
   */
  @AuraEnabled
  public static CreateCaseResult createSuccessionCase(Id financialAccountId) {
    try {
      System.debug(
        'Starting createSuccessionCase for FA: ' + financialAccountId
      );

      // Validate requirements
      String validationError = validateRequirements(financialAccountId);
      if (String.isNotBlank(validationError)) {
        System.debug('Validation failed: ' + validationError);
        return createErrorResult(validationError);
      }

      // Get deceased donor account
      Id deceasedOwnerAccountId = getDeceasedDonorAccount(financialAccountId);
      if (deceasedOwnerAccountId == null) {
        return createErrorResult(
          'No deceased primary owner found on this financial account'
        );
      }

      // Get successors and validate allocation
      List<FinServ__FinancialAccountRole__c> successors = getSuccessors(
        financialAccountId
      );
      if (successors.isEmpty()) {
        return createErrorResult(
          'No active successors designated on this financial account'
        );
      }

      // Validate allocation totals using SuccessionUtilities
      String allocationError = SuccessionUtilities.validateSuccessorAllocations(
        successors
      );
      if (String.isNotBlank(allocationError)) {
        return createErrorResult(allocationError);
      }

      // Get Estate Administration record type (cached for performance)
      Id estateAdminRecordTypeId = SuccessionUtilities.getEstateAdministrationRecordTypeId();
      if (estateAdminRecordTypeId == null) {
        return createErrorResult('Estate Administration record type not found');
      }

      // Get FinancialAccount name for subject
      String financialAccountName = getFinancialAccountName(financialAccountId);

      // Branch based on successor count
      if (successors.size() == 1) {
        // Single successor - create one case
        return createSingleSuccessorCase(
          successors[0],
          deceasedOwnerAccountId,
          financialAccountId,
          financialAccountName,
          estateAdminRecordTypeId
        );
      } else {
        // Multiple successors - create parent + children
        return createMultiSuccessorCases(
          successors,
          deceasedOwnerAccountId,
          financialAccountId,
          financialAccountName,
          estateAdminRecordTypeId
        );
      }
    } catch (Exception e) {
      System.debug('Exception occurred: ' + e.getMessage());
      System.debug('Stack trace: ' + e.getStackTraceString());
      return createErrorResult(
        'Error creating succession case: ' +
          e.getMessage() +
          ' (Line: ' +
          e.getLineNumber() +
          ')'
      );
    }
  }

  /**
   * Create error result wrapper
   */
  private static CreateCaseResult createErrorResult(String message) {
    CreateCaseResult errorResult = new CreateCaseResult();
    errorResult.success = false;
    errorResult.message = message;
    return errorResult;
  }

  /**
   * Create single successor case
   */
  private static CreateCaseResult createSingleSuccessorCase(
    FinServ__FinancialAccountRole__c successor,
    Id deceasedOwnerAccountId,
    Id financialAccountId,
    String financialAccountName,
    Id estateAdminRecordTypeId
  ) {
    // Get ContactId for successor
    Id contactId = getContactIdForSuccessor(successor);

    // Validate ContactId exists - critical for contact cadence workflow
    if (contactId == null) {
      return createErrorResult(
        'Successor contact not found. Please ensure the successor has a Related Contact or is linked to a Person Account.'
      );
    }

    // Create case
    Case successionCase = new Case(
      RecordTypeId = estateAdminRecordTypeId,
      Type = 'Named Successor Enactment',
      Subject = financialAccountName + ' - Named Successor Enactment',
      Status = 'New',
      Origin = 'Financial Account',
      Priority = 'Medium',
      AccountId = deceasedOwnerAccountId,
      Deceased_Donor__c = deceasedOwnerAccountId,
      ContactId = contactId,
      Successor__c = contactId,
      FinServ__FinancialAccount__c = financialAccountId,
      Verification_Status__c = 'Complete - Verified',
      Description = 'Succession case created from Financial Account.'
    );

    Database.insert(successionCase, AccessLevel.USER_MODE);

    // Return success
    CreateCaseResult successResult = new CreateCaseResult();
    successResult.success = true;
    successResult.message = 'Case created successfully! Contact cadence workflow has started automatically.';
    successResult.seedCaseId = successionCase.Id;
    successResult.successorCount = 1;
    return successResult;
  }

  /**
   * Create multi-successor cases (parent + children)
   */
  private static CreateCaseResult createMultiSuccessorCases(
    List<FinServ__FinancialAccountRole__c> successors,
    Id deceasedOwnerAccountId,
    Id financialAccountId,
    String financialAccountName,
    Id estateAdminRecordTypeId
  ) {
    // Create parent case
    Case parentCase = new Case(
      RecordTypeId = estateAdminRecordTypeId,
      Type = 'Multi-Account Succession Master',
      Subject = financialAccountName + ' - Multi-Account Succession Master',
      Status = 'In Progress',
      Origin = 'Financial Account',
      Priority = 'Medium',
      AccountId = deceasedOwnerAccountId,
      FinServ__FinancialAccount__c = financialAccountId,
      Description = 'Multi-successor coordination case. ' +
        successors.size() +
        ' successors identified for this DAF account. Individual succession cases created for each successor with independent contact cadence and pathway selection.'
    );

    Database.insert(parentCase, AccessLevel.USER_MODE);

    // Create child cases for each successor
    List<Case> childCases = new List<Case>();
    Integer skippedCount = 0;

    for (FinServ__FinancialAccountRole__c successor : successors) {
      Id contactId = getContactIdForSuccessor(successor);

      // Skip successors without valid ContactId (cannot run contact cadence)
      if (contactId == null) {
        System.debug(
          'Warning: Skipping successor without valid ContactId: ' + successor.Id
        );
        skippedCount++;
        continue;
      }

      Case childCase = new Case(
        RecordTypeId = estateAdminRecordTypeId,
        Type = 'Named Successor Enactment',
        Subject = financialAccountName + ' - Named Successor Enactment',
        Status = 'New',
        Origin = 'Financial Account',
        Priority = 'Medium',
        AccountId = deceasedOwnerAccountId,
        Deceased_Donor__c = deceasedOwnerAccountId,
        ContactId = contactId,
        Successor__c = contactId,
        FinServ__FinancialAccount__c = financialAccountId,
        ParentId = parentCase.Id,
        Verification_Status__c = 'Complete - Verified',
        Description = 'Succession case for successor. Part of multi-successor coordination under parent case. ' +
          (successor.SuccessorAllocation__c != null
            ? 'Allocation: ' + successor.SuccessorAllocation__c + '%'
            : 'Equal allocation assumed unless otherwise specified in financial account roles.')
      );

      childCases.add(childCase);
    }

    // Validate at least one child case was created
    if (childCases.isEmpty()) {
      return createErrorResult(
        'No valid successor contacts found. Please ensure at least one successor has a Related Contact or is linked to a Person Account.'
      );
    }

    Database.insert(childCases, AccessLevel.USER_MODE);

    // Return success
    CreateCaseResult successResult = new CreateCaseResult();
    successResult.success = true;

    String warningMessage = skippedCount > 0
      ? ' (' +
        skippedCount +
        ' successor(s) skipped due to missing contact information)'
      : '';

    successResult.message =
      'Parent case and ' +
      childCases.size() +
      ' child cases created successfully.' +
      warningMessage +
      ' Contact cadence workflows have started automatically for all child cases.';
    successResult.parentCaseId = parentCase.Id;
    successResult.seedCaseId = childCases[0].Id;
    successResult.successorCount = childCases.size();
    return successResult;
  }

  /**
   * Get ContactId for a successor (handles Person Accounts)
   */
  private static Id getContactIdForSuccessor(
    FinServ__FinancialAccountRole__c successor
  ) {
    Id contactId = successor.FinServ__RelatedContact__c;

    // If no RelatedContact, try to get PersonContactId from Account
    if (contactId == null && successor.FinServ__RelatedAccount__c != null) {
      List<Account> successorAccounts = [
        SELECT PersonContactId, IsPersonAccount
        FROM Account
        WHERE Id = :successor.FinServ__RelatedAccount__c
        WITH USER_MODE
        LIMIT 1
      ];

      if (!successorAccounts.isEmpty()) {
        SObjectAccessDecision decision = Security.stripInaccessible(
          AccessType.READABLE,
          successorAccounts
        );
        List<Account> filteredAccounts = (List<Account>) decision.getRecords();
        if (!filteredAccounts.isEmpty()) {
          contactId = filteredAccounts[0].PersonContactId;
        }
      }
    }

    return contactId;
  }

  /**
   * Validate all requirements before creating case
   *
   * @param financialAccountId - ID of the FinancialAccount
   * @return Error message if validation fails, null if valid
   */
  private static String validateRequirements(Id financialAccountId) {
    // Check for existing cases (idempotency)
    List<Case> existingCases = [
      SELECT Id
      FROM Case
      WHERE
        FinServ__FinancialAccount__c = :financialAccountId
        AND (Type = 'Named Successor Enactment'
        OR Type = 'Multi-Account Succession Master')
        AND IsClosed = FALSE
      WITH USER_MODE
      LIMIT 1
    ];

    if (!existingCases.isEmpty()) {
      return 'A succession case already exists for this financial account';
    }

    return null; // All validations passed
  }

  /**
   * Get deceased donor account ID
   *
   * @param financialAccountId - ID of the FinancialAccount
   * @return Account ID of deceased primary owner, or null if not found
   *
   * Note: Uses SYSTEM_MODE for Deceased__c field access since this is a
   * system-level business logic check (similar to SuccessionTaskGenerator).
   * The Deceased__c field is a critical system field for succession workflows.
   */
  private static Id getDeceasedDonorAccount(Id financialAccountId) {
    List<FinServ__FinancialAccountRole__c> deceasedOwners = [
      SELECT FinServ__RelatedAccount__c, FinServ__RelatedAccount__r.Deceased__c
      FROM FinServ__FinancialAccountRole__c
      WHERE
        FinServ__FinancialAccount__c = :financialAccountId
        AND FinServ__Role__c LIKE '%Primary%'
        AND FinServ__RelatedAccount__r.Deceased__c = TRUE
      WITH SYSTEM_MODE
      ORDER BY CreatedDate DESC
      LIMIT 2
    ];

    if (deceasedOwners.size() > 1) {
      System.debug(
        'Warning: Multiple deceased primary owners found for FA ' +
        financialAccountId
      );
    }

    if (deceasedOwners.isEmpty()) {
      return null;
    }

    return deceasedOwners[0].FinServ__RelatedAccount__c;
  }

  /**
   * Get active successors for the financial account
   *
   * @param financialAccountId - ID of the FinancialAccount
   * @return List of successor FinancialAccountRole records
   */
  private static List<FinServ__FinancialAccountRole__c> getSuccessors(
    Id financialAccountId
  ) {
    List<FinServ__FinancialAccountRole__c> successors = [
      SELECT
        Id,
        FinServ__RelatedContact__c,
        FinServ__RelatedAccount__c,
        SuccessorAllocation__c
      FROM FinServ__FinancialAccountRole__c
      WHERE
        FinServ__FinancialAccount__c = :financialAccountId
        AND FinServ__Role__c LIKE '%Successor%'
        AND FinServ__Active__c = TRUE
      WITH USER_MODE
      ORDER BY CreatedDate ASC
    ];

    // Enforce field-level security
    SObjectAccessDecision decision = Security.stripInaccessible(
      AccessType.READABLE,
      successors
    );
    return decision.getRecords();
  }

  /**
   * Get FinancialAccount name for case subject
   *
   * @param financialAccountId - ID of the FinancialAccount
   * @return FinancialAccount name
   */
  private static String getFinancialAccountName(Id financialAccountId) {
    List<FinServ__FinancialAccount__c> accounts = [
      SELECT Name
      FROM FinServ__FinancialAccount__c
      WHERE Id = :financialAccountId
      WITH USER_MODE
      LIMIT 1
    ];

    return accounts.isEmpty() ? 'Unknown Financial Account' : accounts[0].Name;
  }
}
