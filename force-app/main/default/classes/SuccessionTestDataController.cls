/**
 * @description Apex controller for Succession Test Data Generator LWC
 * @author Salesforce Architecture Team
 * @date 2025-01-31
 * 
 * Provides @AuraEnabled methods to generate test data from the UI.
 * Calls SuccessionTestDataFactory methods and returns formatted results.
 * 
 * **IMPORTANT:** This controller should only be used in Sandbox environments.
 * Add organization-level controls to prevent use in production.
 */
public with sharing class SuccessionTestDataController {
    
    /**
     * @description Result wrapper for UI display
     */
    public class GenerationResult {
        @AuraEnabled public String message;
        @AuraEnabled public String details;
        @AuraEnabled public Boolean success;
    }
    
    /**
     * @description Generate complete test dataset (all 4 scenarios)
     * @return GenerationResult with success status and details
     */
    @AuraEnabled
    public static GenerationResult generateCompleteDataset() {
        try {
            SuccessionTestDataFactory.SuccessionTestData dataset = 
                SuccessionTestDataFactory.generateCompleteDataset();
            
            GenerationResult result = new GenerationResult();
            result.success = true;
            result.message = 'Complete Dataset Generated Successfully';
            result.details = String.format(
                'Created: {0} deceased donors, {1} living successors, {2} advisor firms, {3} financial accounts (ASDAF/ISDAF/PMA), {4} roles, {5} succession cases, {6} contact attempt tasks, {7} Chatter posts across 6 scenario types',
                new List<String>{
                    String.valueOf(dataset.deceasedDonors.size()),
                    String.valueOf(dataset.successors.size()),
                    String.valueOf(dataset.advisorFirms.size()),
                    String.valueOf(dataset.financialAccounts.size()),
                    String.valueOf(dataset.roles.size()),
                    String.valueOf(dataset.successionCases.size()),
                    String.valueOf(dataset.contactTasks.size()),
                    String.valueOf(dataset.chatterPosts.size())
                }
            );
            
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error generating complete dataset: ' + e.getMessage());
        }
    }
    
    /**
     * @description Generate Happy Path - Final Grant scenario
     * @return GenerationResult with success status and details
     */
    @AuraEnabled
    public static GenerationResult generateHappyPathFinalGrant() {
        try {
            SuccessionTestDataFactory.SuccessionScenarioData scenario = 
                SuccessionTestDataFactory.generateHappyPathFinalGrant();
            
            GenerationResult result = new GenerationResult();
            result.success = true;
            result.message = 'Happy Path Scenario Generated';
            result.details = String.format(
                'Created: Margaret Thompson (donor), Jennifer Thompson (successor), Thompson Family Fund ($2.5M), Final Grant pathway case',
                new List<String>{}
            );
            
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error generating Happy Path scenario: ' + e.getMessage());
        }
    }
    
    /**
     * @description Generate New DAF Account scenario
     * @return GenerationResult with success status and details
     */
    @AuraEnabled
    public static GenerationResult generateNewDAFScenario() {
        try {
            SuccessionTestDataFactory.SuccessionScenarioData scenario = 
                SuccessionTestDataFactory.generateNewDAFScenario();
            
            GenerationResult result = new GenerationResult();
            result.success = true;
            result.message = 'New DAF Account Scenario Generated';
            result.details = String.format(
                'Created: Robert Chen (donor), Lisa Chen (successor), Chen Charitable Account ($750K), New DAF Account pathway case',
                new List<String>{}
            );
            
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error generating New DAF scenario: ' + e.getMessage());
        }
    }
    
    /**
     * @description Generate Disclaim Assets scenario
     * @return GenerationResult with success status and details
     */
    @AuraEnabled
    public static GenerationResult generateDisclaimScenario() {
        try {
            SuccessionTestDataFactory.SuccessionScenarioData scenario = 
                SuccessionTestDataFactory.generateDisclaimScenario();
            
            GenerationResult result = new GenerationResult();
            result.success = true;
            result.message = 'Disclaim Assets Scenario Generated';
            result.details = String.format(
                'Created: Elizabeth Martinez (donor), Carlos Martinez (successor), Martinez Family Foundation ($1.2M), Disclaim pathway case (Closed)',
                new List<String>{}
            );
            
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error generating Disclaim scenario: ' + e.getMessage());
        }
    }
    
    /**
     * @description Generate SLA Escalation scenario
     * @return GenerationResult with success status and details
     */
    @AuraEnabled
    public static GenerationResult generateSLAEscalationScenario() {
        try {
            SuccessionTestDataFactory.SuccessionScenarioData scenario = 
                SuccessionTestDataFactory.generateSLAEscalationScenario();
            
            GenerationResult result = new GenerationResult();
            result.success = true;
            result.message = 'SLA Escalation Scenario Generated';
            result.details = String.format(
                'Created: James O\'Connor (donor), Sean O\'Connor (successor - unresponsive), O\'Connor Charitable Fund ($250K), Escalated case (4 contact attempts)',
                new List<String>{}
            );
            
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error generating SLA Escalation scenario: ' + e.getMessage());
        }
    }
    
    /**
     * @description Generate Multiple Successors scenario
     * @return GenerationResult with success status and details
     *
     * **IMPORTANT**: Creates ONE initial Case. The Case_Multiple_Successors_Handler Flow
     * automatically detects multiple FinancialAccountRoles and creates:
     * - Parent "Multi-Account Succession Master" Case
     * - Converts initial Case to Child 1
     * - Creates Child 2 Case for second successor
     * - Adds both successors as Case Team Members
     */
    @AuraEnabled
    public static GenerationResult generateMultipleSuccessorsScenario() {
        try {
            SuccessionTestDataFactory.SuccessionScenarioData scenario =
                SuccessionTestDataFactory.generateMultipleSuccessorsScenario();

            GenerationResult result = new GenerationResult();
            result.success = true;
            result.message = 'Multiple Successors Scenario Generated';
            result.details = String.format(
                'Created: Patricia Williams (donor), Amanda & Brandon Williams (2 successors, 50/50 split), Williams Family Foundation Fund ($3.5M). Flow will auto-create parent/child case structure.',
                new List<String>{}
            );

            return result;

        } catch (Exception e) {
            throw new AuraHandledException('Error generating Multiple Successors scenario: ' + e.getMessage());
        }
    }

    /**
     * @description Delete all succession test data
     * @return GenerationResult with deletion status
     *
     * Deletes all test data created by the factory. Identifies test records by:
     * - Account names containing 'Thompson', 'Chen', 'Martinez', 'OConnor', 'Lee', 'Williams'
     * - Case Type = 'Named Successor Enactment' or 'Multi-Account Succession Master'
     */
    @AuraEnabled
    public static GenerationResult deleteAllTestData() {
        try {
            Integer deletedCount = 0;
            
            // Delete Chatter posts first (FeedItems are automatically deleted when parent is deleted, but we can delete explicitly)
            List<Case> testCasesForChatter = [
                SELECT Id FROM Case WHERE Type = 'Named Successor Enactment'
            ];
            if (!testCasesForChatter.isEmpty()) {
                List<FeedItem> chatterPosts = [
                    SELECT Id FROM FeedItem 
                    WHERE ParentId IN :testCasesForChatter
                ];
                delete chatterPosts;
                deletedCount += chatterPosts.size();
            }
            
            // Delete contact attempt tasks (before cases)
            // Note: Subject is encrypted, so we query all Tasks related to test cases instead
            List<Task> testTasks = [
                SELECT Id
                FROM Task
                WHERE WhatId IN (SELECT Id FROM Case WHERE Type = 'Named Successor Enactment')
            ];
            delete testTasks;
            deletedCount += testTasks.size();
            
            // Delete succession cases (including multi-successor parent/child cases)
            // Note: Subject is encrypted, so we can't filter on it
            List<Case> testCases = [
                SELECT Id
                FROM Case
                WHERE Type IN ('Named Successor Enactment', 'Multi-Account Succession Master')
            ];
            delete testCases;
            deletedCount += testCases.size();
            
            // Delete financial account roles
            List<String> testAccountNames = new List<String>{
                '%Thompson%', '%Chen%', '%Martinez%', '%OConnor%', '%Lee%', '%Williams%',
                '%Anderson%', '%Rodriguez%', '%Johnson%', '%White%', '%Brown%', '%Davis%',
                '%Taylor%', '%Wilson%', '%Miller%',
                '%Donor%', '%Successor%', '%Advisor%'
            };
            
            // Use dynamic SOQL to handle variable number of name patterns
            String whereClause = 'WHERE (';
            for (Integer i = 0; i < testAccountNames.size(); i++) {
                if (i > 0) whereClause += ' OR ';
                whereClause += 'Name LIKE \'' + testAccountNames[i] + '\'';
            }
            whereClause += ')';
            
            List<Account> testAccounts = Database.query(
                'SELECT Id FROM Account ' + whereClause
            );
            
            // Get related financial accounts
            // Note: Name is encrypted, so we only filter by Primary Owner
            List<FinServ__FinancialAccount__c> testDAFs = [
                SELECT Id 
                FROM FinServ__FinancialAccount__c 
                WHERE FinServ__PrimaryOwner__c IN :testAccounts
            ];
            
            // Delete financial account roles
            if (!testDAFs.isEmpty()) {
                List<FinServ__FinancialAccountRole__c> testRoles = [
                    SELECT Id 
                    FROM FinServ__FinancialAccountRole__c 
                    WHERE FinServ__FinancialAccount__c IN :testDAFs
                ];
                delete testRoles;
                deletedCount += testRoles.size();
                
                // Delete financial accounts
                delete testDAFs;
                deletedCount += testDAFs.size();
            }
            
            // Delete accounts
            delete testAccounts;
            deletedCount += testAccounts.size();
            
            GenerationResult result = new GenerationResult();
            result.success = true;
            result.message = 'Test Data Deleted Successfully';
            result.details = String.format(
                'Deleted {0} total records (chatter posts, tasks, cases, accounts, financial accounts, roles)',
                new List<String>{ String.valueOf(deletedCount) }
            );
            
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting test data: ' + e.getMessage());
        }
    }
}
