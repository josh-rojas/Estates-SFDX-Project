// Ultra-Simple Demo Data - Use Existing Accounts
// Run via: sf apex run --file datasets/simple_demo_data.apex --target-org josh.rojas.charfsc@schwab.com.fscjosh

Id estateAdminRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Case' AND DeveloperName = 'EstateAdministration' LIMIT 1].Id;
Id defaultBusinessHours = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1].Id;

// Get existing Person Accounts
List<Account> existingAccounts = [SELECT Id, Name FROM Account WHERE IsPersonAccount = true LIMIT 5];

if (existingAccounts.isEmpty()) {
    System.debug('ERROR: No Person Accounts found. Create at least 3 Person Accounts first.');
    return;
}

// Create simple demo cases using existing accounts
List<Case> demoCases = new List<Case>();

// DEMO 1: Happy Path
demoCases.add(new Case(
    RecordTypeId = estateAdminRT,
    AccountId = existingAccounts[0].Id,
    BusinessHoursId = defaultBusinessHours,
    Type = 'Named Successor Enactment',
    Subject = '[DEMO 1] Happy Path - Contact Established - Final Grant Selected',
    Status = 'In Progress',
    Origin = 'Phone',
    Priority = 'Medium',
    Description = 'SCENARIO: Contact made on first attempt, Final Grant pathway selected',
    Verification_Status__c = 'Complete - Verified',
    Contact_Attempt_Count__c = 1,
    Contact_Established__c = true,
    Contact_Established_Date__c = DateTime.now().addDays(-8),
    Form_Sent_Date__c = DateTime.now().addDays(-8),
    Form_Completed_Date__c = DateTime.now().addDays(-6),
    Pathway_Confirmed__c = 'Final Grant',
    Execution_Status__c = 'In Progress'
));

// DEMO 2: Manual Entry Test
if (existingAccounts.size() > 1) {
    demoCases.add(new Case(
        RecordTypeId = estateAdminRT,
        AccountId = existingAccounts[1].Id,
        BusinessHoursId = defaultBusinessHours,
        Type = 'Named Successor Enactment',
        Subject = '[DEMO 2] Manual Entry - Click Begin Succession Processing',
        Status = 'New',
        Origin = 'Phone',
        Priority = 'Medium',
        Description = 'SCENARIO: Verification = Not Started. Test Quick Action workflow trigger',
        Verification_Status__c = 'Not Started',
        Contact_Attempt_Count__c = 0,
        Contact_Established__c = false,
        Pathway_Confirmed__c = 'Not Selected',
        Execution_Status__c = 'Not Started'
    ));
}

// DEMO 3: Contact Cadence - Multiple Attempts
if (existingAccounts.size() > 2) {
    demoCases.add(new Case(
        RecordTypeId = estateAdminRT,
        AccountId = existingAccounts[2].Id,
        BusinessHoursId = defaultBusinessHours,
        Type = 'Named Successor Enactment',
        Subject = '[DEMO 4] Contact Cadence - 3 Attempts No Contact Yet',
        Status = 'In Progress',
        Origin = 'Phone',
        Priority = 'High',
        Description = 'SCENARIO: 3 contact attempts, no success yet. Tests contact cadence LWC',
        Verification_Status__c = 'Complete - Verified',
        Contact_Attempt_Count__c = 3,
        Contact_Established__c = false,
        Pathway_Confirmed__c = 'Not Selected',
        Execution_Status__c = 'Not Started'
    ));
}

// DEMO 4: New DAF Pathway
if (existingAccounts.size() > 3) {
    demoCases.add(new Case(
        RecordTypeId = estateAdminRT,
        AccountId = existingAccounts[3].Id,
        BusinessHoursId = defaultBusinessHours,
        Type = 'Named Successor Enactment',
        Subject = '[DEMO 5] New DAF Pathway - Account Created',
        Status = 'In Progress',
        Origin = 'Phone',
        Priority = 'Medium',
        Description = 'SCENARIO: New DAF pathway selected, new account number assigned',
        Verification_Status__c = 'Complete - Verified',
        Contact_Attempt_Count__c = 1,
        Contact_Established__c = true,
        Contact_Established_Date__c = DateTime.now().addDays(-30),
        Form_Sent_Date__c = DateTime.now().addDays(-30),
        Form_Completed_Date__c = DateTime.now().addDays(-27),
        Pathway_Confirmed__c = 'New DAF Account',
        Execution_Status__c = 'In Progress',
        New_DAF_Account_Number__c = 'DAF-98765001'
    ));
}

insert demoCases;

// Create Tasks for Contact Cadence demo
if (demoCases.size() > 2) {
    List<Task> cadenceTasks = new List<Task>{
        new Task(
            WhatId = demoCases[2].Id,
            Subject = '[DEMO 4] Contact Attempt 1 - No Answer',
            Status = 'Completed',
            ActivityDate = Date.today().addDays(-17),
            Contact_Attempt_Number__c = 1,
            Succession_Contact_Established__c = false,
            Description = 'Day 0 - No answer, left voicemail'
        ),
        new Task(
            WhatId = demoCases[2].Id,
            Subject = '[DEMO 4] Contact Attempt 2 - Left Voicemail',
            Status = 'Completed',
            ActivityDate = Date.today().addDays(-12),
            Contact_Attempt_Number__c = 2,
            Succession_Contact_Established__c = false,
            Description = 'Day 5 - Still no contact'
        ),
        new Task(
            WhatId = demoCases[2].Id,
            Subject = '[DEMO 4] Contact Attempt 3 - No Contact',
            Status = 'Completed',
            ActivityDate = Date.today().addDays(-3),
            Contact_Attempt_Number__c = 3,
            Succession_Contact_Established__c = false,
            Description = 'Day 35 - Urgent follow-up needed'
        )
    };
    insert cadenceTasks;
}

System.debug('✅ SUCCESS! Created ' + demoCases.size() + ' demo cases');
System.debug('Navigate to Cases and search for "[DEMO" to find test cases');
