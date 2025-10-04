/**
 * CaseHierarchyController
 *
 * Apex controller for caseHierarchyViewer LWC component.
 * Retrieves parent case with all child cases, financial accounts, and successors.
 *
 * Used for Multi-Account Succession Master cases to display full hierarchy:
 * Parent Case → Child Cases → Financial Accounts → Successors (with allocations)
 */
public with sharing class CaseHierarchyController {

    /**
     * Wrapper for case hierarchy data
     */
    public class CaseHierarchyData {
        @AuraEnabled public Case parentCase { get; set; }
        @AuraEnabled public List<ChildCaseData> childCases { get; set; }
    }

    /**
     * Wrapper for child case with related data
     */
    public class ChildCaseData {
        @AuraEnabled public Case caseRecord { get; set; }
        @AuraEnabled public FinServ__FinancialAccount__c financialAccount { get; set; }
        @AuraEnabled public List<SuccessorData> successors { get; set; }
    }

    /**
     * Wrapper for successor with allocation
     */
    public class SuccessorData {
        @AuraEnabled public String successorName { get; set; }
        @AuraEnabled public String successorEmail { get; set; }
        @AuraEnabled public String successorPhone { get; set; }
        @AuraEnabled public Decimal allocationPercent { get; set; }
        @AuraEnabled public String pathway { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Id caseId { get; set; }
    }

    /**
     * Get complete case hierarchy for a parent case
     *
     * @param parentCaseId - ID of the parent Multi-Account Succession Master case
     * @return CaseHierarchyData with complete hierarchy
     */
    @AuraEnabled(cacheable=true)
    public static CaseHierarchyData getCaseHierarchy(Id parentCaseId) {
        try {
            CaseHierarchyData hierarchyData = new CaseHierarchyData();

            // Query parent case
            hierarchyData.parentCase = [
                SELECT Id, CaseNumber, Subject, Status, CreatedDate,
                       AccountId, Account.Name,
                       FinServ__FinancialAccount__c, FinServ__FinancialAccount__r.Name,
                       FinServ__FinancialAccount__r.FinServ__Balance__c,
                       Type, RecordType.Name
                FROM Case
                WHERE Id = :parentCaseId
                LIMIT 1
            ];

            // Query all child cases
            List<Case> childCases = [
                SELECT Id, CaseNumber, Subject, Status, CreatedDate,
                       ContactId, Contact.Name, Contact.Email, Contact.Phone,
                       AccountId, Account.Name,
                       FinServ__FinancialAccount__c, FinServ__FinancialAccount__r.Name,
                       FinServ__FinancialAccount__r.FinServ__Balance__c,
                       FinServ__FinancialAccount__r.FinServ__FinancialAccountNumber__c,
                       Pathway_Confirmed__c, Contact_Established__c, SLA_Status__c,
                       Contact_Attempt_Count__c, Last_Contact_Attempt__c
                FROM Case
                WHERE ParentId = :parentCaseId
                ORDER BY CreatedDate ASC
            ];

            // Get all related financial account IDs
            Set<Id> financialAccountIds = new Set<Id>();
            for (Case childCase : childCases) {
                if (childCase.FinServ__FinancialAccount__c != null) {
                    financialAccountIds.add(childCase.FinServ__FinancialAccount__c);
                }
            }

            // Query financial accounts with full details
            Map<Id, FinServ__FinancialAccount__c> financialAccountMap = new Map<Id, FinServ__FinancialAccount__c>([
                SELECT Id, Name, FinServ__Balance__c,
                       FinServ__FinancialAccountNumber__c,
                       FinServ__Status__c, FinServ__ProductName__c
                FROM FinServ__FinancialAccount__c
                WHERE Id IN :financialAccountIds
            ]);

            // Query all successor roles for these financial accounts
            Map<Id, List<FinServ__FinancialAccountRole__c>> successorsByAccount = new Map<Id, List<FinServ__FinancialAccountRole__c>>();

            List<FinServ__FinancialAccountRole__c> allRoles = [
                SELECT Id, FinServ__FinancialAccount__c, FinServ__RelatedContact__c,
                       FinServ__RelatedContact__r.Name, FinServ__RelatedContact__r.Email,
                       FinServ__RelatedContact__r.Phone,
                       FinServ__Role__c, FinServ__Active__c,
                       SuccessorAllocation__c
                FROM FinServ__FinancialAccountRole__c
                WHERE FinServ__FinancialAccount__c IN :financialAccountIds
                  AND FinServ__Role__c LIKE '%Successor%'
                  AND FinServ__Active__c = TRUE
                ORDER BY SuccessorAllocation__c DESC NULLS LAST
            ];

            // Group successors by financial account
            for (FinServ__FinancialAccountRole__c role : allRoles) {
                if (!successorsByAccount.containsKey(role.FinServ__FinancialAccount__c)) {
                    successorsByAccount.put(role.FinServ__FinancialAccount__c, new List<FinServ__FinancialAccountRole__c>());
                }
                successorsByAccount.get(role.FinServ__FinancialAccount__c).add(role);
            }

            // Build child case data with successors
            hierarchyData.childCases = new List<ChildCaseData>();

            for (Case childCase : childCases) {
                ChildCaseData childData = new ChildCaseData();
                childData.caseRecord = childCase;

                // Add financial account if exists
                if (childCase.FinServ__FinancialAccount__c != null) {
                    childData.financialAccount = financialAccountMap.get(childCase.FinServ__FinancialAccount__c);

                    // Add successors for this financial account
                    childData.successors = new List<SuccessorData>();
                    List<FinServ__FinancialAccountRole__c> accountSuccessors =
                        successorsByAccount.get(childCase.FinServ__FinancialAccount__c);

                    if (accountSuccessors != null) {
                        for (FinServ__FinancialAccountRole__c role : accountSuccessors) {
                            SuccessorData successor = new SuccessorData();
                            successor.successorName = role.FinServ__RelatedContact__r.Name;
                            successor.successorEmail = role.FinServ__RelatedContact__r.Email;
                            successor.successorPhone = role.FinServ__RelatedContact__r.Phone;
                            successor.allocationPercent = role.SuccessorAllocation__c;
                            successor.pathway = childCase.Pathway_Confirmed__c;
                            successor.status = childCase.Status;
                            successor.caseId = childCase.Id;

                            childData.successors.add(successor);
                        }
                    }
                }

                hierarchyData.childCases.add(childData);
            }

            return hierarchyData;

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving case hierarchy: ' + e.getMessage());
        }
    }
}
