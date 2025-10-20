// Simple Demo Data Creation - Succession Management
// Run via: sf apex run --file datasets/create_demo_data.apex --target-org schwab-sandbox

// Get RecordType IDs
Id personAccountRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'PersonAccount' LIMIT 1].Id;
Id estateAdminRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Case' AND DeveloperName = 'EstateAdministration' LIMIT 1].Id;
Id defaultBusinessHours = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1].Id;

// SCENARIO 1: Happy Path - Final Grant
Account donor1 = new Account(
    RecordTypeId = personAccountRT,
    FirstName = 'Margaret',
    LastName = 'Thompson [HAPPY PATH - Final Grant]',
    PersonEmail = 'margaret.thompson@legacy.example.com',
    Deceased__c = true
);
insert donor1;

Case case1 = new Case(
    RecordTypeId = estateAdminRT,
    AccountId = donor1.Id,
    BusinessHoursId = defaultBusinessHours,
    Type = 'Named Successor Enactment',
    Subject = '[DEMO 1] Happy Path - Thompson Estate - Final Grant',
    Status = 'In Progress',
    Origin = 'Phone',
    Verification_Status__c = 'Complete - Verified',
    Contact_Attempt_Count__c = 1,
    Contact_Established__c = true,
    Contact_Established_Date__c = DateTime.now().addDays(-8),
    Form_Sent_Date__c = DateTime.now().addDays(-8),
    Form_Completed_Date__c = DateTime.now().addDays(-6),
    Pathway_Confirmed__c = 'Final Grant',
    Execution_Status__c = 'In Progress'
);
insert case1;

// SCENARIO 2: Manual Entry - Not Started
Account donor2 = new Account(
    RecordTypeId = personAccountRT,
    FirstName = 'Robert',
    LastName = 'Wilson [MANUAL ENTRY TEST]',
    PersonEmail = 'robert.wilson@legacy.example.com',
    Deceased__c = true
);
insert donor2;

Case case2 = new Case(
    RecordTypeId = estateAdminRT,
    AccountId = donor2.Id,
    BusinessHoursId = defaultBusinessHours,
    Type = 'Named Successor Enactment',
    Subject = '[DEMO 2] Manual Entry - Wilson Estate - Click Quick Action',
    Status = 'New',
    Origin = 'Phone',
    Verification_Status__c = 'Not Started',
    Contact_Attempt_Count__c = 0,
    Contact_Established__c = false,
    Pathway_Confirmed__c = 'Not Selected',
    Execution_Status__c = 'Not Started'
);
insert case2;

// SCENARIO 3: Contact Cadence - Multiple Attempts
Account donor3 = new Account(
    RecordTypeId = personAccountRT,
    FirstName = 'James',
    LastName = 'Anderson [CONTACT CADENCE TEST]',
    PersonEmail = 'james.anderson@legacy.example.com',
    Deceased__c = true
);
insert donor3;

Case case3 = new Case(
    RecordTypeId = estateAdminRT,
    AccountId = donor3.Id,
    BusinessHoursId = defaultBusinessHours,
    Type = 'Named Successor Enactment',
    Subject = '[DEMO 4] Contact Cadence - Anderson Estate - 3 Attempts',
    Status = 'In Progress',
    Origin = 'Phone',
    Verification_Status__c = 'Complete - Verified',
    Contact_Attempt_Count__c = 3,
    Contact_Established__c = false,
    Pathway_Confirmed__c = 'Not Selected',
    Execution_Status__c = 'Not Started'
);
insert case3;

// Create Tasks for Cadence Test
List<Task> tasks = new List<Task>{
    new Task(
        WhatId = case3.Id,
        Subject = '[DEMO 4] Contact Attempt 1 - No Answer',
        Status = 'Completed',
        ActivityDate = Date.today().addDays(-17),
        Contact_Attempt_Number__c = 1,
        Succession_Contact_Established__c = false
    ),
    new Task(
        WhatId = case3.Id,
        Subject = '[DEMO 4] Contact Attempt 2 - Left Voicemail',
        Status = 'Completed',
        ActivityDate = Date.today().addDays(-12),
        Contact_Attempt_Number__c = 2,
        Succession_Contact_Established__c = false
    ),
    new Task(
        WhatId = case3.Id,
        Subject = '[DEMO 4] Contact Attempt 3 - Still No Contact',
        Status = 'Completed',
        ActivityDate = Date.today().addDays(-3),
        Contact_Attempt_Number__c = 3,
        Succession_Contact_Established__c = false
    )
};
insert tasks;

System.debug('✅ Demo data created successfully!');
System.debug('Created 3 Accounts: Thompson, Wilson, Anderson');
System.debug('Created 3 Cases: DEMO 1, DEMO 2, DEMO 4');
System.debug('Created 3 Tasks for contact cadence test');
