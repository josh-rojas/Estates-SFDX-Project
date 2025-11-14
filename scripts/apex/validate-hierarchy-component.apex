/**
 * Validation Script: Multi-Successor Hierarchy Component
 *
 * Purpose: Validates that the SuccessionCaseHierarchy DataRaptor
 *          can successfully query all necessary data for display
 *
 * Usage:
 *   1. Execute in Developer Console: Anonymous Apex
 *   2. Review debug output for any issues
 *   3. Use generated test data or provide your own Case ID
 *
 * Expected Output:
 *   ✅ Parent Case found
 *   ✅ Child Cases found (X cases)
 *   ✅ Financial Account linked
 *   ✅ Successors found (Y successors)
 *   ✅ All allocations sum to 100%
 */

System.debug('═══════════════════════════════════════════════════════════');
System.debug('Multi-Successor Hierarchy Component Validation');
System.debug('═══════════════════════════════════════════════════════════\n');

// STEP 1: Locate existing test data (no auto-generation)
System.debug('STEP 1: Finding or Creating Test Data...');
System.debug('─────────────────────────────────────────────────────────────');

List<Case> parentCases = [
    SELECT Id, CaseNumber, Subject, Type, Status
    FROM Case
    WHERE Type = 'Multi-Account Succession Master'
    AND ParentId = NULL
    ORDER BY CreatedDate DESC
    LIMIT 1
];

String parentCaseId;

if (parentCases.isEmpty()) {
    System.debug('⚠️  No existing parent cases found.');
    System.debug('   This validation script no longer auto-generates data.');
    System.debug('   Please create a parent "Multi-Account Succession Master" case and re-run.');
    return;
} else {
    parentCaseId = parentCases[0].Id;
    System.debug('✅ Found existing parent case: ' + parentCases[0].CaseNumber + ' - ' + parentCases[0].Subject);
}

System.debug('   Using Parent Case ID: ' + parentCaseId + '\n');

// STEP 2: Validate Parent Case Structure
System.debug('STEP 2: Validating Parent Case...');
System.debug('─────────────────────────────────────────────────────────────');

List<Case> parentCaseDetails = [
    SELECT Id, CaseNumber, Subject, Status, Type, Owner.Name,
           AccountId, Account.Name,
           FinServ__FinancialAccount__c,
           FinServ__FinancialAccount__r.Name,
           FinServ__FinancialAccount__r.FinServ__Balance__c
    FROM Case
    WHERE Id = :parentCaseId
];

if (parentCaseDetails.isEmpty()) {
    System.debug('❌ Parent case not found with ID: ' + parentCaseId);
    return;
}

Case parentCase = parentCaseDetails[0];

System.debug('✅ Parent Case Retrieved');
System.debug('   Case Number: ' + parentCase.CaseNumber);
System.debug('   Subject: ' + parentCase.Subject);
System.debug('   Status: ' + parentCase.Status);
System.debug('   Type: ' + parentCase.Type);
System.debug('   Owner: ' + parentCase.Owner.Name);

if (parentCase.AccountId != null) {
    System.debug('   Account: ' + parentCase.Account.Name);
} else {
    System.debug('   ⚠️  No Account linked');
}

if (parentCase.FinServ__FinancialAccount__c != null) {
    System.debug('✅ Financial Account Linked');
    System.debug('   FA Name/Number: ' + parentCase.FinServ__FinancialAccount__r.Name);
    System.debug('   Balance: $' + parentCase.FinServ__FinancialAccount__r.FinServ__Balance__c);
} else {
    System.debug('❌ No Financial Account linked - DataRaptor will fail!');
}

System.debug('');

// STEP 3: Validate Child Cases
System.debug('STEP 3: Validating Child Cases...');
System.debug('─────────────────────────────────────────────────────────────');

List<Case> childCases = [
    SELECT Id, CaseNumber, Subject, Status, Type,
           ContactId, Contact.Name, Contact.Email, Contact.Phone,
           Verification_Status__c, Contact_Established__c,
           Pathway_Confirmed__c, SLA_Status__c,
           Contact_Attempt_Count__c,
           FinServ__FinancialAccount__c,
           FinServ__FinancialAccount__r.Name
    FROM Case
    WHERE ParentId = :parentCaseId
    AND Type = 'Named Successor Enactment'
    ORDER BY Subject
];

if (childCases.isEmpty()) {
    System.debug('❌ No child cases found!');
    System.debug('   Expected: Cases with ParentId = ' + parentCaseId);
    System.debug('   Check: Case_Multiple_Successors_Handler flow execution');
} else {
    System.debug('✅ Found ' + childCases.size() + ' child case(s):\n');

    for (Case childCase : childCases) {
        System.debug('   Child Case: ' + childCase.CaseNumber + ' - ' + childCase.Subject);
        System.debug('   ├─ Status: ' + childCase.Status);
        System.debug('   ├─ Contact: ' + childCase.Contact.Name);

        if (childCase.Contact.Email != null) {
            System.debug('   │  Email: ' + childCase.Contact.Email);
        }

        System.debug('   ├─ Verification: ' + childCase.Verification_Status__c);
        System.debug('   ├─ Contact Established: ' + childCase.Contact_Established__c);
        System.debug('   ├─ Pathway: ' + (childCase.Pathway_Confirmed__c != null ? childCase.Pathway_Confirmed__c : 'Not Selected'));
        System.debug('   ├─ SLA Status: ' + (childCase.SLA_Status__c != null ? childCase.SLA_Status__c : 'N/A'));

        if (childCase.FinServ__FinancialAccount__c != null) {
            System.debug('   └─ Financial Account: ' + childCase.FinServ__FinancialAccount__r.Name);
        } else {
            System.debug('   └─ ⚠️  No Financial Account linked');
        }

        System.debug('');
    }
}

// STEP 4: Validate Financial Account Roles (Successors)
System.debug('STEP 4: Validating Successors...');
System.debug('─────────────────────────────────────────────────────────────');

if (parentCase.FinServ__FinancialAccount__c == null) {
    System.debug('❌ Skipping - no Financial Account to query roles from');
} else {
    List<FinServ__FinancialAccountRole__c> successors = [
        SELECT Id, Name,
               FinServ__RelatedAccount__c,
               FinServ__RelatedAccount__r.Name,
               FinServ__RelatedAccount__r.PersonEmail,
               FinServ__RelatedAccount__r.PersonMobilePhone,
               FinServ__Role__c,
               SuccessorAllocation__c,
               FinServ__Active__c
        FROM FinServ__FinancialAccountRole__c
        WHERE FinServ__FinancialAccount__c = :parentCase.FinServ__FinancialAccount__c
        AND FinServ__Role__c LIKE '%Successor%'
        AND FinServ__Active__c = TRUE
        ORDER BY SuccessorAllocation__c DESC
    ];

    if (successors.isEmpty()) {
        System.debug('❌ No active successors found!');
        System.debug('   Expected: FinancialAccountRole records with Role containing "Successor"');
        System.debug('   Tip: Create successor FinancialAccountRole records for the account linked to the parent case');
    } else {
        System.debug('✅ Found ' + successors.size() + ' successor(s):\n');

        Decimal totalAllocation = 0;

        for (FinServ__FinancialAccountRole__c successor : successors) {
            System.debug('   Successor: ' + successor.FinServ__RelatedAccount__r.Name);
            System.debug('   ├─ Allocation: ' + successor.SuccessorAllocation__c + '%');
            System.debug('   ├─ Role: ' + successor.FinServ__Role__c);

            if (successor.FinServ__RelatedAccount__r.PersonEmail != null) {
                System.debug('   ├─ Email: ' + successor.FinServ__RelatedAccount__r.PersonEmail);
            }

            if (successor.FinServ__RelatedAccount__r.PersonMobilePhone != null) {
                System.debug('   └─ Phone: ' + successor.FinServ__RelatedAccount__r.PersonMobilePhone);
            } else {
                System.debug('   └─ Phone: (not provided)');
            }

            System.debug('');

            if (successor.SuccessorAllocation__c != null) {
                totalAllocation += successor.SuccessorAllocation__c;
            }
        }

        System.debug('   Total Allocation: ' + totalAllocation + '%');

        if (totalAllocation == 100) {
            System.debug('   ✅ Allocations sum to 100%');
        } else {
            System.debug('   ⚠️  Allocations do NOT sum to 100% (found ' + totalAllocation + '%)');
        }
    }
}

System.debug('');

// STEP 5: Summary and Next Steps
System.debug('═══════════════════════════════════════════════════════════');
System.debug('VALIDATION SUMMARY');
System.debug('═══════════════════════════════════════════════════════════\n');

System.debug('Parent Case ID for FlexCard testing: ' + parentCaseId);
System.debug('');

System.debug('Next Steps:');
System.debug('1. Deploy DataRaptor and FlexCard to org');
System.debug('2. Navigate to Case: ' + (parentCase != null ? parentCase.CaseNumber : ''));
System.debug('3. Verify FlexCard displays hierarchy correctly');
System.debug('4. Test accordion collapse/expand functionality');
System.debug('');

System.debug('DataRaptor Test Input:');
System.debug('{');
System.debug('  "ParentCaseId": "' + parentCaseId + '"');
System.debug('}');
System.debug('');

System.debug('Use this in: Setup → OmniStudio → DataRaptors → SuccessionCaseHierarchy → Preview');
System.debug('');
System.debug('═══════════════════════════════════════════════════════════');
