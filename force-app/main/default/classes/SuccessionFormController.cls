/**
 * @description Apex controller for succession pathway form LWC components
 * @author Claude Code
 * @date 2025-10-02
 *
 * SECURITY: with sharing enforces record-level security for guest user access
 *
 * USAGE (from LWC):
 *   import validateToken from '@salesforce/apex/SuccessionFormController.validateToken';
 *   import getCaseContext from '@salesforce/apex/SuccessionFormController.getCaseContext';
 *   import submitPathwaySelection from '@salesforce/apex/SuccessionFormController.submitPathwaySelection';
 *
 * REVISION HISTORY
 * 2025-10-02 - Initial creation for LWC implementation
 */
public with sharing class SuccessionFormController {

    /**
     * @description Validates token and returns basic case info
     * @param token The encrypted token from URL parameter
     * @return TokenValidation wrapper with validation status
     */
    @AuraEnabled
    public static TokenValidation validateToken(String token) {
        TokenValidation result = new TokenValidation();

        try {
            SuccessionFormTokenValidator.ValidationResult validation =
                SuccessionFormTokenValidator.validateToken(token);

            result.isValid = validation.isValid;
            result.caseId = validation.caseId;
            result.caseNumber = validation.caseNumber;
            result.errorMessage = validation.errorMessage;
            result.isExpired = validation.isExpired;
            result.isAlreadyUsed = validation.isAlreadyUsed;

        } catch (Exception e) {
            result.isValid = false;
            result.errorMessage = 'An error occurred validating your access link. Please try again or contact support.';
            System.debug(LoggingLevel.ERROR, 'Token validation error: ' + e.getMessage());
        }

        return result;
    }

    /**
     * @description Loads complete case context for form display
     * @param caseId The validated Case ID
     * @return CaseContext wrapper with all necessary data
     */
    @AuraEnabled(cacheable=true)
    public static CaseContext getCaseContext(Id caseId) {
        CaseContext context = new CaseContext();

        try {
            // Query Case with all related data
            Case c = [
                SELECT Id, CaseNumber, Type, Status,
                       AccountId, Account.Name, Account.Date_of_Death__c,
                       ContactId, Contact.Name, Contact.Email, Contact.Phone,
                       FinServ__FinancialAccount__c,
                       FinServ__FinancialAccount__r.Name,
                       FinServ__FinancialAccount__r.FinServ__Balance__c,
                       FinServ__FinancialAccount__r.FinServ__Status__c,
                       Contact_Established_Date__c,
                       Verification_Status__c
                FROM Case
                WHERE Id = :caseId
                LIMIT 1
            ];

            context.caseId = c.Id;
            context.caseNumber = c.CaseNumber;

            // Deceased Donor Info
            context.deceasedDonorName = c.Account.Name;
            context.dateOfDeath = c.Account.Date_of_Death__c;

            // Successor Info
            context.successorName = c.Contact.Name;
            context.successorEmail = c.Contact.Email;
            context.successorPhone = c.Contact.Phone;

            // Financial Account Info
            context.financialAccountName = c.FinServ__FinancialAccount__r.Name;
            context.accountBalance = c.FinServ__FinancialAccount__r.FinServ__Balance__c;
            context.accountStatus = c.FinServ__FinancialAccount__r.FinServ__Status__c;
            context.financialAccountId = c.FinServ__FinancialAccount__c;

            // Check for multiple successors
            context.hasMultipleSuccessors = checkForMultipleSuccessors(c.FinServ__FinancialAccount__c);

            if (context.hasMultipleSuccessors) {
                context.successorCount = getSuccessorCount(c.FinServ__FinancialAccount__c);
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error loading case context: ' + e.getMessage());
            throw new AuraHandledException('Unable to load case information. Please contact support.');
        }

        return context;
    }

    /**
     * @description Checks if financial account has multiple successors
     * @param financialAccountId The financial account ID
     * @return True if multiple active successors exist
     */
    private static Boolean checkForMultipleSuccessors(Id financialAccountId) {
        Integer count = [
            SELECT COUNT()
            FROM FinServ__FinancialAccountRole__c
            WHERE FinServ__FinancialAccount__c = :financialAccountId
            AND FinServ__Role__c LIKE '%Successor%'
            AND FinServ__Active__c = true
        ];
        return count > 1;
    }

    /**
     * @description Gets count of active successors
     * @param financialAccountId The financial account ID
     * @return Number of active successors
     */
    private static Integer getSuccessorCount(Id financialAccountId) {
        return [
            SELECT COUNT()
            FROM FinServ__FinancialAccountRole__c
            WHERE FinServ__FinancialAccount__c = :financialAccountId
            AND FinServ__Role__c LIKE '%Successor%'
            AND FinServ__Active__c = true
        ];
    }

    /**
     * @description Submits pathway selection and creates necessary records
     * @param submission PathwaySubmission wrapper with all form data
     * @return SubmissionResult wrapper with success status
     */
    @AuraEnabled
    public static SubmissionResult submitPathwaySelection(PathwaySubmission submission) {
        SubmissionResult result = new SubmissionResult();

        Savepoint sp = Database.setSavepoint();

        try {
            // Update Case with pathway selection
            Case c = new Case(
                Id = submission.caseId,
                Pathway_Confirmed__c = submission.pathway,
                Form_Completed_Date__c = DateTime.now(),
                Status = getStatusForPathway(submission.pathway),
                Execution_Notes__c = submission.notes
            );

            update c;

            // Process pathway-specific data
            if (submission.pathway == 'Final Grant') {
                createGrantTransactions(submission);
            } else if (submission.pathway == 'New DAF Account') {
                saveNewDAFPreferences(submission);
            } else if (submission.pathway == 'Disclaim Assets') {
                saveDisclaimerDetails(submission);
            }

            // Create review task for operations team
            createReviewTask(submission);

            // Mark token as used (one-time use enforcement)
            SuccessionFormTokenValidator.markTokenAsUsed(submission.caseId);

            result.success = true;
            result.caseNumber = [SELECT CaseNumber FROM Case WHERE Id = :submission.caseId].CaseNumber;
            result.message = 'Your succession pathway selection has been submitted successfully. Our team will review your submission within 2 business days.';

        } catch (Exception e) {
            Database.rollback(sp);
            result.success = false;
            result.message = 'An error occurred submitting your form. Please try again or contact support.';
            result.errorDetails = e.getMessage();
            System.debug(LoggingLevel.ERROR, 'Submission error: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
        }

        return result;
    }

    /**
     * @description Creates grant transaction records for Final Grant pathway
     * @param submission PathwaySubmission with grant beneficiaries
     */
    private static void createGrantTransactions(PathwaySubmission submission) {
        if (submission.grantBeneficiaries == null || submission.grantBeneficiaries.isEmpty()) {
            throw new IllegalArgumentException('No grant beneficiaries provided');
        }

        // Validate total grant amounts
        Decimal totalGrantAmount = 0;
        for (GrantBeneficiary beneficiary : submission.grantBeneficiaries) {
            totalGrantAmount += beneficiary.amount;
        }

        // Get account balance for validation
        Decimal accountBalance = [
            SELECT FinServ__Balance__c
            FROM FinServ__FinancialAccount__c
            WHERE Id = :submission.financialAccountId
        ].FinServ__Balance__c;

        // Validate total is within 5% of balance
        Decimal allowedVariance = accountBalance * 0.05;
        if (Math.abs(totalGrantAmount - accountBalance) > allowedVariance) {
            throw new IllegalArgumentException('Total grant amount must equal account balance (±5%)');
        }

        // Create grant transaction records
        List<FinServ__FinancialAccountTransaction__c> transactions = new List<FinServ__FinancialAccountTransaction__c>();

        for (GrantBeneficiary beneficiary : submission.grantBeneficiaries) {
            String description = 'Succession Grant - ' + beneficiary.charityName;
            if (String.isNotBlank(beneficiary.purpose)) {
                description += ' (' + beneficiary.purpose + ')';
            }
            if (String.isNotBlank(beneficiary.ein)) {
                description += ' - EIN: ' + beneficiary.ein;
            }

            FinServ__FinancialAccountTransaction__c txn = new FinServ__FinancialAccountTransaction__c(
                FinServ__FinancialAccount__c = submission.financialAccountId,
                Charity__c = beneficiary.charityName,
                FinServ__Amount__c = beneficiary.amount,
                FinServ__Description__c = description,
                FinServ__TransactionType__c = 'Grant',
                FinServ__TransactionStatus__c = 'Pending Review',
                FinServ__PostDate__c = Date.today(),
                Source__c = 'Succession Form'
            );

            transactions.add(txn);
        }

        insert transactions;
    }

    /**
     * @description Saves New DAF account preferences
     * @param submission PathwaySubmission with DAF preferences
     */
    private static void saveNewDAFPreferences(PathwaySubmission submission) {
        Case c = new Case(
            Id = submission.caseId,
            New_DAF_Email__c = submission.newDAFEmail,
            New_DAF_Terms_Acknowledged__c = submission.termsAcknowledged,
            New_DAF_Terms_Date__c = DateTime.now()
        );
        update c;
    }

    /**
     * @description Saves disclaimer details
     * @param submission PathwaySubmission with disclaimer info
     */
    private static void saveDisclaimerDetails(PathwaySubmission submission) {
        Case c = new Case(
            Id = submission.caseId,
            Disclaimer_Reason__c = submission.disclaimerReason,
            Disclaimer_Legal_Attestation__c = submission.legalAttestation,
            Disclaimer_Date__c = DateTime.now()
        );
        update c;
    }

    /**
     * @description Gets appropriate Case status for pathway
     * @param pathway The selected pathway
     * @return Case status string
     */
    private static String getStatusForPathway(String pathway) {
        if (pathway == 'Final Grant') {
            return 'Documentation - Final Grant';
        } else if (pathway == 'New DAF Account') {
            return 'Documentation - New DAF';
        } else if (pathway == 'Disclaim Assets') {
            return 'Documentation - Disclaimer';
        }
        return 'Form Received - Legal Review';
    }

    /**
     * @description Creates review task for operations team
     * @param submission PathwaySubmission data
     */
    private static void createReviewTask(PathwaySubmission submission) {
        Task reviewTask = new Task(
            WhatId = submission.caseId,
            Subject = 'Review Succession Form Submission - ' + submission.pathway,
            Description = 'Successor has completed the succession pathway form.\n\n' +
                         'Pathway Selected: ' + submission.pathway + '\n' +
                         'Submitted: ' + DateTime.now().format() + '\n\n' +
                         'Next Steps:\n' +
                         '1. Verify document uploads\n' +
                         '2. Review pathway selection\n' +
                         '3. Coordinate with compliance if needed',
            Priority = 'High',
            Status = 'Not Started',
            ActivityDate = Date.today().addDays(2)
        );
        insert reviewTask;
    }

    /**
     * @description Captures IP address of form submitter
     * @return Client IP address
     */
    @AuraEnabled
    public static String captureIPAddress() {
        // Get IP address from request headers
        String ipAddress = 'Unknown';
        try {
            // This works in Experience Cloud context
            ipAddress = Auth.SessionManagement.getCurrentSession().get('SourceIp');
        } catch (Exception e) {
            System.debug('Could not retrieve IP address: ' + e.getMessage());
        }
        return ipAddress;
    }

    // Wrapper classes for LWC communication

    public class TokenValidation {
        @AuraEnabled public Boolean isValid;
        @AuraEnabled public Id caseId;
        @AuraEnabled public String caseNumber;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public Boolean isExpired;
        @AuraEnabled public Boolean isAlreadyUsed;
    }

    public class CaseContext {
        @AuraEnabled public Id caseId;
        @AuraEnabled public String caseNumber;
        @AuraEnabled public String deceasedDonorName;
        @AuraEnabled public Date dateOfDeath;
        @AuraEnabled public String successorName;
        @AuraEnabled public String successorEmail;
        @AuraEnabled public String successorPhone;
        @AuraEnabled public String financialAccountName;
        @AuraEnabled public Id financialAccountId;
        @AuraEnabled public Decimal accountBalance;
        @AuraEnabled public String accountStatus;
        @AuraEnabled public Boolean hasMultipleSuccessors;
        @AuraEnabled public Integer successorCount;
    }

    public class PathwaySubmission {
        @AuraEnabled public Id caseId;
        @AuraEnabled public Id financialAccountId;
        @AuraEnabled public String pathway; // 'Final Grant', 'New DAF Account', 'Disclaim Assets'
        @AuraEnabled public List<GrantBeneficiary> grantBeneficiaries; // For Final Grant
        @AuraEnabled public String newDAFEmail; // For New DAF
        @AuraEnabled public Boolean termsAcknowledged; // For New DAF
        @AuraEnabled public String disclaimerReason; // For Disclaim
        @AuraEnabled public Boolean legalAttestation; // For Disclaim
        @AuraEnabled public String signatureName;
        @AuraEnabled public String ipAddress;
        @AuraEnabled public String notes;
    }

    public class GrantBeneficiary {
        @AuraEnabled public String charityName;
        @AuraEnabled public String ein;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public String purpose;
    }

    public class SubmissionResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public String caseNumber;
        @AuraEnabled public String errorDetails;
    }
}
