/**
 * CreateSuccessionCaseController
 *
 * Apex controller for FinancialAccount Quick Action to create succession cases.
 * Creates a single seed case and lets existing flows handle multi-successor orchestration.
 *
 * @author Claude Code
 * @date 2025-01-27
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
    public Integer successorCount { get; set; }
  }

  /**
   * Main entry point for Quick Action
   * Creates a single seed case and lets existing flows handle orchestration
   *
   * @param financialAccountId - ID of the FinancialAccount
   * @return CreateCaseResult with success status and case information
   */
  @AuraEnabled
  public static CreateCaseResult createSuccessionCase(Id financialAccountId) {
    try {
      System.debug('Starting createSuccessionCase for FA: ' + financialAccountId);
      
      // Validate requirements
      String validationError = validateRequirements(financialAccountId);
      if (String.isNotBlank(validationError)) {
        System.debug('Validation failed: ' + validationError);
        CreateCaseResult errorResult = new CreateCaseResult();
        errorResult.success = false;
        errorResult.message = validationError;
        return errorResult;
      }

      // Get deceased donor account
      Id deceasedOwnerAccountId = getDeceasedDonorAccount(financialAccountId);
      if (deceasedOwnerAccountId == null) {
        CreateCaseResult errorResult = new CreateCaseResult();
        errorResult.success = false;
        errorResult.message = 'No deceased primary owner found on this financial account';
        return errorResult;
      }

      // Get successors and validate allocation
      List<FinServ__FinancialAccountRole__c> successors = getSuccessors(financialAccountId);
      if (successors.isEmpty()) {
        CreateCaseResult errorResult = new CreateCaseResult();
        errorResult.success = false;
        errorResult.message = 'No active successors designated on this financial account';
        return errorResult;
      }

      // Validate allocation totals (optional but recommended)
      String allocationError = validateSuccessorAllocations(successors);
      if (String.isNotBlank(allocationError)) {
        CreateCaseResult errorResult = new CreateCaseResult();
        errorResult.success = false;
        errorResult.message = allocationError;
        return errorResult;
      }

      // Get first successor (deterministic selection)
      FinServ__FinancialAccountRole__c firstSuccessor = successors[0];

      // Get Estate Administration record type
      Id estateAdminRecordTypeId = getEstateAdministrationRecordTypeId();
      System.debug('Record Type ID: ' + estateAdminRecordTypeId);
      
      if (estateAdminRecordTypeId == null) {
        CreateCaseResult errorResult = new CreateCaseResult();
        errorResult.success = false;
        errorResult.message = 'Estate Administration record type not found';
        return errorResult;
      }

      // Get FinancialAccount name for subject
      String financialAccountName = getFinancialAccountName(financialAccountId);
      System.debug('Financial Account Name: ' + financialAccountName);
      
      // Determine ContactId - use RelatedContact if available, otherwise get PersonContactId from Account
      Id contactId = firstSuccessor.FinServ__RelatedContact__c;
      System.debug('First successor RelatedContact: ' + contactId);
      System.debug('First successor RelatedAccount: ' + firstSuccessor.FinServ__RelatedAccount__c);
      
      if (contactId == null && firstSuccessor.FinServ__RelatedAccount__c != null) {
        System.debug('Querying PersonContactId from Account');
        List<Account> successorAccounts = [
          SELECT PersonContactId, IsPersonAccount
          FROM Account 
          WHERE Id = :firstSuccessor.FinServ__RelatedAccount__c
          LIMIT 1
        ];
        
        System.debug('Found accounts: ' + successorAccounts.size());
        
        // Enforce field-level security
        if (!successorAccounts.isEmpty()) {
          System.debug('Account IsPersonAccount: ' + successorAccounts[0].IsPersonAccount);
          System.debug('Account PersonContactId: ' + successorAccounts[0].PersonContactId);
          
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
      
      System.debug('Final ContactId to use: ' + contactId);

      // Create seed case
      Case seedCase = new Case(
        RecordTypeId = estateAdminRecordTypeId,
        Type = 'Named Successor Enactment',
        Subject = financialAccountName + ' - Named Successor Enactment',
        Status = 'New',
        Origin = 'Financial Account',
        Priority = 'Medium',
        AccountId = deceasedOwnerAccountId, // Deceased donor (NOT successor)
        ContactId = contactId, // Direct Contact ID or PersonContactId
        FinServ__FinancialAccount__c = financialAccountId,
        Verification_Status__c = 'Complete - Verified', // Auto-starts workflow
        Description = 'Succession case created from Financial Account. ' +
                     (successors.size() > 1 ? successors.size() + ' successors identified.' : '')
      );

      // Insert seed case with USER_MODE to enforce FLS
      Database.insert(seedCase, AccessLevel.USER_MODE);

      // Return success result
      CreateCaseResult successResult = new CreateCaseResult();
      successResult.success = true;
      successResult.message = 'Case created successfully' + 
                 (successors.size() > 1 ? '. ' + successors.size() + ' successors detected - parent coordination case and child cases will be created automatically.' : '. Contact cadence will begin automatically.');
      successResult.seedCaseId = seedCase.Id;
      successResult.successorCount = successors.size();
      return successResult;

    } catch (Exception e) {
      System.debug('Exception occurred: ' + e.getMessage());
      System.debug('Stack trace: ' + e.getStackTraceString());
      CreateCaseResult errorResult = new CreateCaseResult();
      errorResult.success = false;
      errorResult.message = 'Error creating succession case: ' + e.getMessage() + ' (Line: ' + e.getLineNumber() + ')';
      return errorResult;
    }
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
      WHERE FinServ__FinancialAccount__c = :financialAccountId 
      AND (Type = 'Named Successor Enactment' OR Type = 'Multi-Account Succession Master')
      AND IsClosed = false
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
   */
  private static Id getDeceasedDonorAccount(Id financialAccountId) {
    List<FinServ__FinancialAccountRole__c> deceasedOwners = [
      SELECT FinServ__RelatedAccount__c, FinServ__RelatedAccount__r.Deceased__c
      FROM FinServ__FinancialAccountRole__c
      WHERE FinServ__FinancialAccount__c = :financialAccountId
      AND FinServ__Role__c LIKE '%Primary%'
      AND FinServ__RelatedAccount__r.Deceased__c = true
      LIMIT 1
    ];

    return deceasedOwners.isEmpty() ? null : deceasedOwners[0].FinServ__RelatedAccount__c;
  }

  /**
   * Get active successors for the financial account
   *
   * @param financialAccountId - ID of the FinancialAccount
   * @return List of successor FinancialAccountRole records
   */
  private static List<FinServ__FinancialAccountRole__c> getSuccessors(Id financialAccountId) {
    List<FinServ__FinancialAccountRole__c> successors = [
      SELECT Id, FinServ__RelatedContact__c, FinServ__RelatedAccount__c, SuccessorAllocation__c
      FROM FinServ__FinancialAccountRole__c
      WHERE FinServ__FinancialAccount__c = :financialAccountId
      AND FinServ__Role__c LIKE '%Successor%'
      AND FinServ__Active__c = true
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
   * Validate that successor allocations sum to 100%
   *
   * @param successors - List of successor FinancialAccountRole records
   * @return Error message if validation fails, null if valid
   */
  private static String validateSuccessorAllocations(List<FinServ__FinancialAccountRole__c> successors) {
    Decimal totalAllocation = 0;
    for (FinServ__FinancialAccountRole__c s : successors) {
      totalAllocation += (s.SuccessorAllocation__c != null ? s.SuccessorAllocation__c : 0);
    }
    
    if (totalAllocation != 100) {
      return 'Successor allocations must sum to 100%. Current total: ' + totalAllocation + '%';
    }
    
    return null; // Validation passed
  }

  /**
   * Get Estate Administration record type ID
   *
   * @return Record type ID for Estate Administration
   */
  private static Id getEstateAdministrationRecordTypeId() {
    List<RecordType> recordTypes = [
      SELECT Id 
      FROM RecordType 
      WHERE SObjectType = 'Case' 
      AND DeveloperName = 'EstateAdministration'
      LIMIT 1
    ];
    
    return recordTypes.isEmpty() ? null : recordTypes[0].Id;
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
      LIMIT 1
    ];
    
    return accounts.isEmpty() ? 'Unknown Financial Account' : accounts[0].Name;
  }
}


