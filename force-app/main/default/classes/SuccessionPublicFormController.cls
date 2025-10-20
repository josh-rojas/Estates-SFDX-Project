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
                SELECT Id, CaseNumber, Subject, Status, Type,
                       AccountId, Account.Name, Account.PersonEmail, Account.Phone,
                       Account.FirstName, Account.LastName, Account.IsPersonAccount,
                       ContactId, Contact.Name, Contact.Email, Contact.Phone,
                       FinServ__FinancialAccount__c,
                       FinServ__FinancialAccount__r.Name,
                       FinServ__FinancialAccount__r.FinServ__Balance__c,
                       FinServ__FinancialAccount__r.FinServ__FinancialAccountNumber__c,
                       RecordType.DeveloperName
                FROM Case
                WHERE Id = :caseId
                  AND RecordType.DeveloperName = 'EstateAdministration'
                  AND Type = 'Named Successor Enactment'
                WITH USER_MODE
                LIMIT 1
            ];

            if (cases.isEmpty()) {
                throw new AuraHandledException('Case not found or invalid case type');
            }

            Case c = cases[0];

            // Determine successor lookup ID based on account type
            Id successorLookupId;
            Boolean isPersonAccount = (c.Account != null && c.Account.IsPersonAccount);

            if (isPersonAccount) {
                // Person Account: Query using Account.PersonContactId
                List<Account> successorAccounts = [
                    SELECT PersonContactId
                    FROM Account
                    WHERE Id = :c.AccountId
                    WITH USER_MODE
                    LIMIT 1
                ];
                successorLookupId = !successorAccounts.isEmpty() ? successorAccounts[0].PersonContactId : null;
            } else {
                // Business Account: Use Case.ContactId
                successorLookupId = c.ContactId;
            }

            // Query successor financial account role
            List<FinServ__FinancialAccountRole__c> successorRoles = [
                SELECT Id, FinServ__Role__c, SuccessorAllocation__c,
                       FinServ__RelatedContact__c, FinServ__RelatedContact__r.Name,
                       FinServ__RelatedContact__r.Email, FinServ__RelatedContact__r.Phone
                FROM FinServ__FinancialAccountRole__c
                WHERE FinServ__FinancialAccount__c = :c.FinServ__FinancialAccount__c
                  AND FinServ__Role__c = 'Successor'
                  AND FinServ__RelatedContact__c = :successorLookupId
                WITH USER_MODE
                LIMIT 1
            ];

            // Build response wrapper
            FormData data = new FormData();
            data.caseId = c.Id;
            data.caseNumber = c.CaseNumber;
            data.accountName = c.Account.Name;

            // Use Person Account fields if applicable, otherwise use Contact fields
            if (isPersonAccount) {
                data.successorName = c.Account.FirstName + ' ' + c.Account.LastName;
                data.successorEmail = c.Account.PersonEmail;
                data.successorPhone = c.Account.Phone;
            } else {
                data.successorName = c.Contact.Name;
                data.successorEmail = c.Contact.Email;
                data.successorPhone = c.Contact.Phone;
            }

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
            System.debug('Error in getFormData: ' + e.getMessage());
            throw new AuraHandledException('Error loading form data: ' + e.getMessage());
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
    public static String savePathwaySelection(String caseId, String pathwaySelection, String formData) {
        try {
            if (String.isBlank(caseId)) {
                throw new AuraHandledException('Case ID is required');
            }

            if (String.isBlank(pathwaySelection)) {
                throw new AuraHandledException('Pathway selection is required');
            }

            // Query case to verify it exists and is valid
            List<Case> cases = [
                SELECT Id, Status, Pathway_Confirmed__c
                FROM Case
                WHERE Id = :caseId
                  AND RecordType.DeveloperName = 'EstateAdministration'
                  AND Type = 'Named Successor Enactment'
                WITH USER_MODE
                LIMIT 1
            ];

            if (cases.isEmpty()) {
                throw new AuraHandledException('Case not found or invalid case type');
            }

            Case c = cases[0];

            // Update case with pathway selection
            // Pathway_Confirmed__c is a picklist that stores the pathway choice
            // Valid values: "Not Selected", "Final Grant", "New DAF Account", "Disclaim Assets"
            c.Pathway_Confirmed__c = pathwaySelection;
            c.Form_Completed_Date__c = System.now();
            c.Status = 'Pathway Selection Received';

            // Parse additional form data if provided
            if (String.isNotBlank(formData)) {
                Map<String, Object> formFields = (Map<String, Object>) JSON.deserializeUntyped(formData);

                // Map form fields to Case fields
                if (formFields.containsKey('additionalNotes')) {
                    c.Description = (String) formFields.get('additionalNotes');
                }

                // Add more field mappings as needed based on pathway-specific requirements
            }

            update as user c;

            return 'Pathway selection saved successfully';

        } catch (Exception e) {
            System.debug('Error in savePathwaySelection: ' + e.getMessage());
            throw new AuraHandledException('Error saving pathway selection: ' + e.getMessage());
        }
    }

    /**
     * @description Wrapper class for form data response
     */
    public class FormData {
        @AuraEnabled public String caseId;
        @AuraEnabled public String caseNumber;
        @AuraEnabled public String accountName;
        @AuraEnabled public String successorName;
        @AuraEnabled public String successorEmail;
        @AuraEnabled public String successorPhone;
        @AuraEnabled public String financialAccountName;
        @AuraEnabled public String financialAccountNumber;
        @AuraEnabled public Decimal accountBalance;
        @AuraEnabled public Decimal allocationPercentage;
    }
}