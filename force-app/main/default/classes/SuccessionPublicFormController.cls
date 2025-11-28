/**
 * @description Public form controller for guest user access to succession pathway form.
 *              Uses URL parameters (caseId, accountId, etc.) to pre-fill form data.
 *              No token-based authentication - relies on URL parameter obscurity.
 * @author Estate Administration Team
 * @date 2025
 */
public with sharing class SuccessionPublicFormController {
  /**
   * @description Fetches case and related data for public form pre-filling
   * @param caseId Salesforce Case ID from URL parameter
   * @return FormData wrapper with case, account, financial account, and successor info
   */
  @AuraEnabled(cacheable=true)
  public static FormData getFormData(String caseId) {
    try {
      if (String.isBlank(caseId)) {
        throw new AuraHandledException('Case ID is required');
      }

      // Query case with all related data including Person Account fields
      List<Case> cases = [
        SELECT
          Id,
          CaseNumber,
          Subject,
          Status,
          Type,
          AccountId,
          Account.Name,
          Account.PersonEmail,
          Account.Phone,
          Account.FirstName,
          Account.LastName,
          Account.IsPersonAccount,
          ContactId,
          Contact.Name,
          Contact.Email,
          Contact.Phone,
          Successor__c,
          FinServ__FinancialAccount__c,
          FinServ__FinancialAccount__r.Name,
          FinServ__FinancialAccount__r.FinServ__Balance__c,
          FinServ__FinancialAccount__r.FinServ__FinancialAccountNumber__c,
          RecordType.DeveloperName
        FROM Case
        WHERE
          Id = :caseId
          AND RecordType.DeveloperName = 'EstateAdministration'
          AND Type = 'Named Successor Enactment'
        WITH USER_MODE
        LIMIT 1
      ];

      if (cases.isEmpty()) {
        throw new AuraHandledException('Case not found or invalid case type');
      }

      Case c = cases[0];

      // PERSON ACCOUNT SUPPORT: Query the successor's Contact to determine account type
      // Case.AccountId points to the deceased donor, NOT the successor
      // Case.Successor__c is a Contact lookup (PersonContactId for Person Accounts)
      Id successorLookupId = c.Successor__c;

      String successorName = null;
      String successorEmail = null;
      String successorPhone = null;
      Boolean isSuccessorPersonAccount = false;
      Id successorAccountId = null;

      // Query the successor Contact to get their Account and determine if Person Account
      if (successorLookupId != null) {
        List<Contact> successorContacts = [
          SELECT
            Id,
            Name,
            Email,
            Phone,
            AccountId,
            Account.IsPersonAccount,
            Account.PersonEmail,
            Account.FirstName,
            Account.LastName,
            Account.Phone
          FROM Contact
          WHERE Id = :successorLookupId
          WITH USER_MODE
          LIMIT 1
        ];

        if (!successorContacts.isEmpty()) {
          Contact successorContact = successorContacts[0];
          isSuccessorPersonAccount =
            successorContact.Account?.IsPersonAccount ?? false;
          successorAccountId = successorContact.AccountId;

          if (isSuccessorPersonAccount) {
            // Person Account: Use Account fields from successor's Account
            String firstName = successorContact.Account.FirstName != null
              ? successorContact.Account.FirstName
              : '';
            String lastName = successorContact.Account.LastName != null
              ? successorContact.Account.LastName
              : '';
            successorName = (firstName + ' ' + lastName).trim();
            successorEmail = successorContact.Account.PersonEmail;
            successorPhone = successorContact.Account.Phone;
          } else {
            // Business Account: Use Contact fields
            successorName = successorContact.Name;
            successorEmail = successorContact.Email;
            successorPhone = successorContact.Phone;
          }
        }
      }

      // Query successor financial account role
      // Person Account: Filter by RelatedAccount__c (successor's Account)
      // Business Account: Filter by RelatedContact__c (successor's Contact)
      List<FinServ__FinancialAccountRole__c> successorRoles = new List<FinServ__FinancialAccountRole__c>();

      if (isSuccessorPersonAccount && successorAccountId != null) {
        // Person Account: Query by successor's RelatedAccount
        // Use exact match with SuccessionUtilities.ROLE_SUCCESSOR constant
        // instead of LIKE pattern for precise role filtering
        successorRoles = [
          SELECT
            Id,
            FinServ__Role__c,
            SuccessorAllocation__c,
            FinServ__RelatedAccount__c
          FROM FinServ__FinancialAccountRole__c
          WHERE
            FinServ__FinancialAccount__c = :c.FinServ__FinancialAccount__c
            AND FinServ__Role__c = :SuccessionUtilities.ROLE_SUCCESSOR
            AND FinServ__RelatedAccount__c = :successorAccountId
          WITH USER_MODE
          LIMIT 1
        ];
      } else if (!isSuccessorPersonAccount && successorLookupId != null) {
        // Business Account: Query by RelatedContact
        // Use exact match with SuccessionUtilities.ROLE_SUCCESSOR constant
        // instead of LIKE pattern for precise role filtering
        successorRoles = [
          SELECT
            Id,
            FinServ__Role__c,
            SuccessorAllocation__c,
            FinServ__RelatedContact__c,
            FinServ__RelatedContact__r.Name,
            FinServ__RelatedContact__r.Email,
            FinServ__RelatedContact__r.Phone
          FROM FinServ__FinancialAccountRole__c
          WHERE
            FinServ__FinancialAccount__c = :c.FinServ__FinancialAccount__c
            AND FinServ__Role__c = :SuccessionUtilities.ROLE_SUCCESSOR
            AND FinServ__RelatedContact__c = :successorLookupId
          WITH USER_MODE
          LIMIT 1
        ];
      }

      // Build response wrapper
      FormData data = new FormData();
      data.caseId = c.Id;
      data.caseNumber = c.CaseNumber;
      data.accountName = c.Account != null ? c.Account.Name : null;
      data.successorName = successorName;
      data.successorEmail = successorEmail;
      data.successorPhone = successorPhone;

      if (c.FinServ__FinancialAccount__c != null) {
        data.financialAccountName = c.FinServ__FinancialAccount__r.Name;
        data.financialAccountNumber = c.FinServ__FinancialAccount__r.FinServ__FinancialAccountNumber__c;
        data.accountBalance = c.FinServ__FinancialAccount__r.FinServ__Balance__c;
      }

      if (!successorRoles.isEmpty()) {
        data.allocationPercentage = successorRoles[0].SuccessorAllocation__c;
      }

      return data;
    } catch (Exception e) {
      SuccessionLogger.error('Error in getFormData: ' + e.getMessage());
      throw new AuraHandledException(
        'Error loading form data: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Saves pathway selection and form data submitted by successor
   * @param caseId Salesforce Case ID
   * @param pathwaySelection Selected pathway (Final Grant, New DAF, Disclaim)
   * @param formData JSON string with additional form fields
   * @return Success message
   */
  @AuraEnabled
  public static String savePathwaySelection(
    String caseId,
    String pathwaySelection,
    String formData
  ) {
    try {
      if (String.isBlank(caseId)) {
        throw new AuraHandledException('Case ID is required');
      }

      if (String.isBlank(pathwaySelection)) {
        throw new AuraHandledException('Pathway selection is required');
      }

      // Query case to verify it exists and is valid
      // SYSTEM_MODE required because:
      // 1. This is a guest user context (public form submission)
      // 2. Guest users have limited sharing access to Case records
      // 3. Must find case regardless of sharing rules to allow pathway selection
      List<Case> cases = [
        SELECT Id, Status, Pathway_Confirmed__c
        FROM Case
        WHERE
          Id = :caseId
          AND RecordType.DeveloperName = 'EstateAdministration'
          AND Type = 'Named Successor Enactment'
        WITH SYSTEM_MODE
        LIMIT 1
      ];

      if (cases.isEmpty()) {
        throw new AuraHandledException('Case not found or invalid case type');
      }

      Case c = cases[0];

      // Map pathway selection to full picklist values
      // Pathway_Confirmed__c picklist values: "Not Selected", "Final Grant", "New DAF Account", "Disclaim Assets"
      // Support both short names (from UI) and full picklist values
      String pathwayValue = pathwaySelection;
      if (pathwaySelection == 'New DAF') {
        pathwayValue = 'New DAF Account';
      } else if (pathwaySelection == 'Disclaim') {
        pathwayValue = 'Disclaim Assets';
      }
      // 'Final Grant' is already the correct picklist value

      // Update case with pathway selection
      c.Pathway_Confirmed__c = pathwayValue;
      c.Form_Completed_Date__c = Date.today();
      c.Status = 'Awaiting Response';

      // Parse additional form data if provided
      if (String.isNotBlank(formData)) {
        Map<String, Object> formFields = (Map<String, Object>) JSON.deserializeUntyped(
          formData
        );

        // Map form fields to Case fields
        if (formFields.containsKey('additionalNotes')) {
          c.Description = (String) formFields.get('additionalNotes');
        }

        // Add more field mappings as needed based on pathway-specific requirements
      }

      // SYSTEM_MODE required because:
      // 1. This is a guest user context (public form submission)
      // 2. Guest users have limited sharing access to Case records
      // 3. Must ensure pathway selection is saved regardless of sharing rules
      Database.update(c, AccessLevel.SYSTEM_MODE);

      return 'Pathway selection saved successfully';
    } catch (Exception e) {
      SuccessionLogger.error(
        'Error in savePathwaySelection: ' + e.getMessage()
      );
      throw new AuraHandledException(
        'Error saving pathway selection: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Wrapper class for form data response
   */
  public class FormData {
    @AuraEnabled
    public String caseId;
    @AuraEnabled
    public String caseNumber;
    @AuraEnabled
    public String accountName;
    @AuraEnabled
    public String successorName;
    @AuraEnabled
    public String successorEmail;
    @AuraEnabled
    public String successorPhone;
    @AuraEnabled
    public String financialAccountName;
    @AuraEnabled
    public String financialAccountNumber;
    @AuraEnabled
    public Decimal accountBalance;
    @AuraEnabled
    public Decimal allocationPercentage;
  }
}
