/**
 * @description Test class for SuccessionPublicFormController
 * @author Estate Administration Team
 * @date 2025
 */
@isTest
private class SuccessionPublicFormController_Test {

    @TestSetup
    static void setupTestData() {
        // Create test account (deceased donor)
        Account testAccount = new Account(
            LastName = 'Test Donor',
            PersonEmail = 'testdonor@example.com'
        );
        insert testAccount;

        // Create successor contact
        Contact successorContact = new Contact(
            FirstName = 'Jane',
            LastName = 'Successor',
            Email = 'jane.successor@example.com',
            Phone = '555-0100'
        );
        insert successorContact;

        // Create financial account
        FinServ__FinancialAccount__c finAccount = new FinServ__FinancialAccount__c(
            Name = 'Test DAF Account',
            FinServ__PrimaryOwner__c = testAccount.Id,
            FinServ__Balance__c = 1000000,
            FinServ__FinancialAccountNumber__c = 'DAF-123456'
        );
        insert finAccount;

        // Create financial account role (successor)
        FinancialAccountRole__c successorRole = new FinancialAccountRole__c(
            FinancialAccount__c = finAccount.Id,
            RelatedContact__c = successorContact.Id,
            Role__c = 'Successor',
            SuccessorAllocation__c = 100
        );
        insert successorRole;

        // Get EstateAdministration record type
        Id estateRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('EstateAdministration').getRecordTypeId();

        // Create succession case
        Case successionCase = new Case(
            RecordTypeId = estateRecordTypeId,
            Type = 'Named Successor Enactment',
            Subject = 'Succession Case for ' + testAccount.Name,
            Status = 'New',
            AccountId = testAccount.Id,
            ContactId = successorContact.Id,
            FinServ__FinancialAccount__c = finAccount.Id,
            Contact_Established__c = true
        );
        insert successionCase;
    }

    @isTest
    static void testGetFormData_Success() {
        // Get test case
        Case testCase = [SELECT Id FROM Case WHERE Type = 'Named Successor Enactment' LIMIT 1];

        Test.startTest();
        SuccessionPublicFormController.FormData result = SuccessionPublicFormController.getFormData(testCase.Id);
        Test.stopTest();

        // Verify results
        System.assertNotEquals(null, result, 'FormData should not be null');
        System.assertEquals(testCase.Id, result.caseId, 'Case ID should match');
        System.assertEquals('Test Donor', result.accountName, 'Account name should match');
        System.assertEquals('Jane Successor', result.successorName, 'Successor name should match');
        System.assertEquals('jane.successor@example.com', result.successorEmail, 'Successor email should match');
        System.assertEquals('Test DAF Account', result.financialAccountName, 'Financial account name should match');
        System.assertEquals(1000000, result.accountBalance, 'Account balance should match');
        System.assertEquals(100, result.allocationPercentage, 'Allocation percentage should match');
    }

    @isTest
    static void testGetFormData_BlankCaseId() {
        Test.startTest();
        try {
            SuccessionPublicFormController.getFormData('');
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Case ID is required'), 'Should throw case ID required error');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetFormData_InvalidCaseId() {
        Test.startTest();
        try {
            SuccessionPublicFormController.getFormData('500000000000000AAA');
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Case not found'), 'Should throw case not found error');
        }
        Test.stopTest();
    }

    @isTest
    static void testSavePathwaySelection_FinalGrant() {
        // Get test case
        Case testCase = [SELECT Id FROM Case WHERE Type = 'Named Successor Enactment' LIMIT 1];

        // Prepare form data
        Map<String, Object> formFields = new Map<String, Object>{
            'additionalNotes' => 'Please process as Final Grant to Red Cross'
        };
        String formDataJson = JSON.serialize(formFields);

        Test.startTest();
        String result = SuccessionPublicFormController.savePathwaySelection(
            testCase.Id,
            'Final Grant',
            formDataJson
        );
        Test.stopTest();

        // Verify results
        System.assertEquals('Pathway selection saved successfully', result, 'Should return success message');

        // Verify case was updated
        Case updatedCase = [
            SELECT Id, Pathway_Selection__c, Pathway_Confirmed__c, Form_Completed_Date__c, Status, Description
            FROM Case
            WHERE Id = :testCase.Id
        ];

        System.assertEquals('Final Grant', updatedCase.Pathway_Selection__c, 'Pathway should be set');
        System.assertEquals(true, updatedCase.Pathway_Confirmed__c, 'Pathway confirmed should be true');
        System.assertNotEquals(null, updatedCase.Form_Completed_Date__c, 'Form completed date should be set');
        System.assertEquals('Pathway Selection Received', updatedCase.Status, 'Status should be updated');
        System.assertEquals('Please process as Final Grant to Red Cross', updatedCase.Description, 'Notes should be saved');
    }

    @isTest
    static void testSavePathwaySelection_NewDAF() {
        Case testCase = [SELECT Id FROM Case WHERE Type = 'Named Successor Enactment' LIMIT 1];

        Test.startTest();
        String result = SuccessionPublicFormController.savePathwaySelection(
            testCase.Id,
            'New DAF',
            null
        );
        Test.stopTest();

        System.assertEquals('Pathway selection saved successfully', result);

        Case updatedCase = [SELECT Pathway_Selection__c, Pathway_Confirmed__c FROM Case WHERE Id = :testCase.Id];
        System.assertEquals('New DAF', updatedCase.Pathway_Selection__c);
        System.assertEquals(true, updatedCase.Pathway_Confirmed__c);
    }

    @isTest
    static void testSavePathwaySelection_Disclaim() {
        Case testCase = [SELECT Id FROM Case WHERE Type = 'Named Successor Enactment' LIMIT 1];

        Test.startTest();
        String result = SuccessionPublicFormController.savePathwaySelection(
            testCase.Id,
            'Disclaim',
            null
        );
        Test.stopTest();

        System.assertEquals('Pathway selection saved successfully', result);

        Case updatedCase = [SELECT Pathway_Selection__c, Pathway_Confirmed__c FROM Case WHERE Id = :testCase.Id];
        System.assertEquals('Disclaim', updatedCase.Pathway_Selection__c);
        System.assertEquals(true, updatedCase.Pathway_Confirmed__c);
    }

    @isTest
    static void testSavePathwaySelection_BlankCaseId() {
        Test.startTest();
        try {
            SuccessionPublicFormController.savePathwaySelection('', 'Final Grant', null);
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Case ID is required'));
        }
        Test.stopTest();
    }

    @isTest
    static void testSavePathwaySelection_BlankPathway() {
        Case testCase = [SELECT Id FROM Case WHERE Type = 'Named Successor Enactment' LIMIT 1];

        Test.startTest();
        try {
            SuccessionPublicFormController.savePathwaySelection(testCase.Id, '', null);
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Pathway selection is required'));
        }
        Test.stopTest();
    }
}
