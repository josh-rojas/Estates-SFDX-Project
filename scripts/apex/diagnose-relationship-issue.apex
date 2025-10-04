// Diagnostic script to identify relationship redundancy
// Run this in Anonymous Apex to see exactly what's happening

try {
    // Test 1: Create deceased donor
    Account deceased = new Account(
        RecordTypeId = '0125f000000iCDUAA2', // PersonAccount
        FirstName = 'Test',
        LastName = 'Deceased',
        Type = 'Donor',
        Deceased__c = true
    );
    Database.SaveResult sr1 = Database.insert(deceased, false);
    System.debug('===== DECEASED DONOR INSERT =====');
    System.debug('Success: ' + sr1.isSuccess());
    if (!sr1.isSuccess()) {
        for (Database.Error err : sr1.getErrors()) {
            System.debug('Error: ' + err.getMessage());
            System.debug('Fields: ' + err.getFields());
        }
    } else {
        System.debug('Deceased ID: ' + sr1.getId());
    }
    
    // Test 2: Create Financial Account with Primary Owner
    if (sr1.isSuccess()) {
        FinServ__FinancialAccount__c fa = new FinServ__FinancialAccount__c(
            Name = 'Test FA',
            FinServ__PrimaryOwner__c = sr1.getId(),
            FinServ__FinancialAccountType__c = 'Donor Advised Fund',
            FinServ__Status__c = 'Active',
            Program__c = 'ASDAF'
        );
        Database.SaveResult sr2 = Database.insert(fa, false);
        System.debug('\n===== FINANCIAL ACCOUNT INSERT =====');
        System.debug('Success: ' + sr2.isSuccess());
        if (!sr2.isSuccess()) {
            for (Database.Error err : sr2.getErrors()) {
                System.debug('Error: ' + err.getMessage());
                System.debug('Fields: ' + err.getFields());
            }
        } else {
            System.debug('Financial Account ID: ' + sr2.getId());
            
            // Query back to see what was actually saved
            FinServ__FinancialAccount__c faQueried = [
                SELECT Id, Name, FinServ__PrimaryOwner__c, FinServ__JointOwner__c
                FROM FinServ__FinancialAccount__c 
                WHERE Id = :sr2.getId()
            ];
            System.debug('PrimaryOwner__c: ' + faQueried.FinServ__PrimaryOwner__c);
            System.debug('JointOwner__c: ' + faQueried.FinServ__JointOwner__c);
            System.debug('Are they equal? ' + (faQueried.FinServ__PrimaryOwner__c == faQueried.FinServ__JointOwner__c));
            
            // Test 3: Create Financial Account Role for Primary Owner
            FinServ__FinancialAccountRole__c role = new FinServ__FinancialAccountRole__c(
                FinServ__FinancialAccount__c = sr2.getId(),
                FinServ__RelatedAccount__c = sr1.getId(),
                FinServ__Role__c = 'Primary Owner',
                FinServ__Active__c = true,
                FinServ__StartDate__c = Date.today()
            );
            Database.SaveResult sr3 = Database.insert(role, false);
            System.debug('\n===== FINANCIAL ACCOUNT ROLE INSERT =====');
            System.debug('Success: ' + sr3.isSuccess());
            if (!sr3.isSuccess()) {
                for (Database.Error err : sr3.getErrors()) {
                    System.debug('Error: ' + err.getMessage());
                    System.debug('Fields: ' + err.getFields());
                }
            } else {
                System.debug('Role ID: ' + sr3.getId());
                System.debug('Is this a redundant relationship? YES - both FA.PrimaryOwner__c AND FARole exist');
            }
        }
    }
    
} catch (Exception e) {
    System.debug('EXCEPTION: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}
