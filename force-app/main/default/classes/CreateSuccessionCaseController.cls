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
      // Validate requirements
      String validationError = validateRequirements(financialAccountId);
      if (String.isNotBlank(validationError)) {
        return new CreateCaseResult {
          success = false,
          message = validationError
        };
      }

      // Get deceased donor account
      Id deceasedOwnerAccountId = getDeceasedDonorAccount(financialAccountId);
      if (deceasedOwnerAccountId == null) {
        return new CreateCaseResult {
          success = false,
          message = 'No deceased primary owner found on this financial account'
        };
      }

      // Get successors and validate allocation
      List<FinServ__FinancialAccountRole__c> successors = getSuccessors(financialAccountId);
      if (successors.isEmpty()) {
        return new CreateCaseResult {
          success = false,
          message = 'No active successors designated on this financial account'
        };
      }

      // Validate allocation totals (optional but recommended)
      String allocationError = validateSuccessorAllocations(successors);
      if (String.isNotBlank(allocationError)) {
        return new CreateCaseResult {
          success = false,
          message = allocationError
        };
      }

      // Get first successor (deterministic selection)
      FinServ__FinancialAccountRole__c firstSuccessor = successors[0];

      // Get Estate Administration record type
      Id estateAdminRecordTypeId = getEstateAdministrationRecordTypeId();

      // Get FinancialAccount name for subject
      String financialAccountName = getFinancialAccountName(financialAccountId);

      // Create seed case
      Case seedCase = new Case(
        RecordTypeId = estateAdminRecordTypeId,
        Type = 'Named Successor Enactment',
        Subject = financialAccountName + ' - Named Successor Enactment',
        Status = 'New',
        Origin = 'Financial Account',
        Priority = 'Medium',
        AccountId = deceasedOwnerAccountId, // Deceased donor (NOT successor)
        ContactId = firstSuccessor.FinServ__RelatedContact__c, // Direct Contact ID
        FinServ__FinancialAccount__c = financialAccountId,
        Verification_Status__c = 'Complete - Verified', // Auto-starts workflow
        Description = 'Succession case created from Financial Account. ' +
                     (successors.size() > 1 ? successors.size() + ' successors identified.' : '')
      );

      // Insert seed case with USER_MODE to enforce FLS
      Database.insert(seedCase, AccessLevel.USER_MODE);

      // Return success result
      return new CreateCaseResult {
        success = true,
        message = 'Case created successfully' + 
                 (successors.size() > 1 ? '. ' + successors.size() + ' successors detected - parent coordination case and child cases will be created automatically.' : '. Contact cadence will begin automatically.'),
        seedCaseId = seedCase.Id,
        successorCount = successors.size()
      };

    } catch (Exception e) {
      return new CreateCaseResult {
        success = false,
        message = 'Error creating succession case: ' + e.getMessage()
      };
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
   */
  private static Id getDeceasedDonorAccount(Id financialAccountId) {
    List<FinServ__FinancialAccountRole__c> deceasedOwners = [
      SELECT FinServ__RelatedAccount__c
      FROM FinServ__FinancialAccountRole__c
      WHERE FinServ__FinancialAccount__c = :financialAccountId
      AND FinServ__Role__c LIKE '%Primary%'
      AND FinServ__EndDate__c != null
      WITH USER_MODE
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
    return [
      SELECT Id, FinServ__RelatedContact__c, SuccessorAllocation__c
      FROM FinServ__FinancialAccountRole__c
      WHERE FinServ__FinancialAccount__c = :financialAccountId
      AND FinServ__Role__c = 'Successor'
      AND FinServ__Active__c = true
      ORDER BY CreatedDate ASC
      WITH USER_MODE
    ];
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
    RecordType estateAdminRT = [
      SELECT Id 
      FROM RecordType 
      WHERE SObjectType = 'Case' 
      AND DeveloperName = 'EstateAdministration'
      WITH USER_MODE
      LIMIT 1
    ];
    
    return estateAdminRT.Id;
  }

  /**
   * Get FinancialAccount name for case subject
   *
   * @param financialAccountId - ID of the FinancialAccount
   * @return FinancialAccount name
   */
  private static String getFinancialAccountName(Id financialAccountId) {
    FinServ__FinancialAccount__c fa = [
      SELECT Name 
      FROM FinServ__FinancialAccount__c 
      WHERE Id = :financialAccountId
      WITH USER_MODE
      LIMIT 1
    ];
    
    return fa.Name;
  }
}


