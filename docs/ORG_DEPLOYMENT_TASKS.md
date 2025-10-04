# Succession Management - Org Deployment Tasks

**Date Created:** October 2, 2025
**Org:** SchwabCharitableFundFSC (schwab-sandbox)
**Branch:** Claude-Succession-Branch
**Estimated Total Time:** 90 minutes

---

## 📋 Task Summary

| Phase | Tasks | Time | Status |
|-------|-------|------|--------|
| **Phase 1: Pre-Deployment** | Admin validation fixes | 7 min | ⬜ Pending |
| **Phase 2: Flow Deployment** | Deploy 4 succession flows | 15 min | ⬜ Pending |
| **Phase 3: Permissions** | Deploy permission set | 5 min | ⬜ Pending |
| **Phase 4: Testing** | End-to-end validation | 20 min | ⬜ Pending |

**Total:** ~47 minutes

---

## ⚠️ CRITICAL: Complete Phase 1 First

Phase 1 validation fixes are **BLOCKING** - test data generation and flows will fail without these fixes.

---

## Phase 1: Pre-Deployment Validation Fixes (7 minutes)

### Task 1.1: Fix ChooseProspectTypeOnly Validation Rule (5 min)

**Problem:** Blocks deceased donors with Type='Donor'

**Steps:**
1. Navigate to: **Setup → Object Manager → Account → Validation Rules**
2. Click: **ChooseProspectTypeOnly**
3. Click: **Edit**
4. Locate line 4 (after `IsPersonAccount = True,`)
5. **Add new line 5:**
   ```apex
   ISBLANK(Date_of_Death__c),
   ```

**Full Formula After Change:**
```apex
AND(
    $Profile.Name <> 'System Administrator',
    $Profile.Name <> 'Admin/PO',
    $Profile.Name <> 'Integration User',
    IsPersonAccount = True,
    ISBLANK(Date_of_Death__c),  ← NEW LINE
    (
        (ISNEW() && NOT(ISPICKVAL(Type, 'Prospect'))) ||
        (ISCHANGED(Type) && ISPICKVAL(PRIORVALUE(Type), "Prospect"))
    )
)
```

6. Click: **Save**

**Verification:**
```apex
// Run in Developer Console → Execute Anonymous
RecordType rt = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'PersonAccount' LIMIT 1];
Account donor = new Account(
    RecordTypeId = rt.Id,
    FirstName = 'Test',
    LastName = 'Deceased',
    PersonEmail = 'test@deceased.com',
    Type = 'Donor',
    Date_of_Death__c = Date.today().addDays(-30),
    Deceased__c = true
);
insert donor;
System.debug('✅ Fix #1 WORKS - Donor ID: ' + donor.Id);
delete donor;
```

**Expected:** `✅ Fix #1 WORKS - Donor ID: 001...`

---

### Task 1.2: Verify PrimaryAndJointOwnerCannotBeSame (2 min)

**Problem:** May have duplicate validation rules after previous fix attempts

**Steps:**
1. Navigate to: **Setup → Object Manager → Financial Account → Validation Rules**
2. Look for: **PrimaryAndJointOwnerCannotBeSame**

**Scenario A: Only ONE rule exists**
- Check the formula:
  - If it includes `NOT(ISBLANK(...))` checks → ✅ **Correct version, no action needed**
  - If it's just `FinServ__PrimaryOwner__c = FinServ__JointOwner__c` → ❌ **Buggy version**
    - Click **Edit** → Uncheck **Active** → **Save**

**Scenario B: TWO rules exist with same name**
1. Click the **FIRST** one:
   - If formula is just: `FinServ__PrimaryOwner__c = FinServ__JointOwner__c`
   - Click **Edit** → Uncheck **Active** → **Save**

2. Click the **SECOND** one:
   - If formula includes: `AND(NOT(ISBLANK(...))` logic
   - Ensure **Active** is checked

**Corrected Formula (for reference):**
```apex
AND(
    NOT(ISBLANK(FinServ__PrimaryOwner__c)),
    NOT(ISBLANK(FinServ__JointOwner__c)),
    FinServ__PrimaryOwner__c = FinServ__JointOwner__c
)
```

**Verification:**
```apex
// Run in Developer Console → Execute Anonymous
// (After Task 1.1 passes)
Account donor = [SELECT Id FROM Account WHERE LastName = 'Deceased' LIMIT 1];
FinServ__FinancialAccount__c fa = new FinServ__FinancialAccount__c(
    Name = 'Test DAF',
    FinServ__PrimaryOwner__c = donor.Id,
    FinServ__JointOwner__c = null,
    FinServ__Ownership__c = 'Individual'
);
insert fa;
System.debug('✅ Fix #2 WORKS - FA ID: ' + fa.Id);
delete fa;
```

**Expected:** `✅ Fix #2 WORKS - FA ID: a0g...`

---

### ✅ Phase 1 Checkpoint

**Run Combined Verification:**
```apex
// Developer Console → Execute Anonymous
System.debug('=== PHASE 1 VERIFICATION ===');

try {
    // Test 1: Deceased Donor
    RecordType rt = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'PersonAccount' LIMIT 1];
    Account donor = new Account(RecordTypeId = rt.Id, FirstName = 'Verify', LastName = 'Test', PersonEmail = 'verify@test.com', Type = 'Donor', Date_of_Death__c = Date.today().addDays(-30), Deceased__c = true);
    insert donor;
    System.debug('✅ PHASE 1 TEST 1: Deceased donor creation PASSED');

    // Test 2: Financial Account
    FinServ__FinancialAccount__c fa = new FinServ__FinancialAccount__c(Name = 'Verify DAF', FinServ__PrimaryOwner__c = donor.Id, FinServ__JointOwner__c = null, FinServ__Ownership__c = 'Individual');
    insert fa;
    System.debug('✅ PHASE 1 TEST 2: Financial account creation PASSED');

    // Cleanup
    delete fa;
    delete donor;

    System.debug('🎉 PHASE 1 COMPLETE - All validation fixes working!');
} catch (Exception e) {
    System.debug('❌ PHASE 1 FAILED: ' + e.getMessage());
    System.debug('Review fixes in docs/QUICK_FIX_GUIDE.md');
}
```

**Expected Output:** `🎉 PHASE 1 COMPLETE - All validation fixes working!`

**If Failed:** Review `docs/QUICK_FIX_GUIDE.md` and `docs/VALIDATION_ISSUES_FINAL_STATUS.md`

---

## Phase 2: Flow Deployment (15 minutes)

### Task 2.1: Deploy Succession Flows via CLI (10 min)

**Important:** Run from project root directory

```bash
# Set current directory (if needed)
cd "/Users/joshsmbp/Schwab Downloads/Estates SFDX Project"

# Deploy Flow 1: Contact Cadence
sf project deploy start \
  --source-dir force-app/main/default/flows/Case_Succession_Contact_Cadence.flow-meta.xml \
  --target-org schwab-sandbox \
  --wait 10

# Deploy Flow 2: Task Update (Circuit Breaker)
sf project deploy start \
  --source-dir force-app/main/default/flows/Task_Succession_Contact_Update.flow-meta.xml \
  --target-org schwab-sandbox \
  --wait 10

# Deploy Flow 3: Send Form
sf project deploy start \
  --source-dir force-app/main/default/flows/Case_Send_Succession_Form.flow-meta.xml \
  --target-org schwab-sandbox \
  --wait 10

# Deploy Flow 4: Multi-Successor Handler
sf project deploy start \
  --source-dir force-app/main/default/flows/Case_Multiple_Successors_Handler.flow-meta.xml \
  --target-org schwab-sandbox \
  --wait 10
```

**Alternative: Deploy All Flows at Once (faster)**
```bash
sf project deploy start \
  --source-dir force-app/main/default/flows/Case_Succession_Contact_Cadence.flow-meta.xml,force-app/main/default/flows/Task_Succession_Contact_Update.flow-meta.xml,force-app/main/default/flows/Case_Send_Succession_Form.flow-meta.xml,force-app/main/default/flows/Case_Multiple_Successors_Handler.flow-meta.xml \
  --target-org schwab-sandbox \
  --wait 10
```

---

### Task 2.2: Verify Flows Active in Org (5 min)

**Steps:**
1. Navigate to: **Setup → Flows**
2. Search: "Succession"
3. Verify the following flows show **Status: Active**:
   - ☐ Case: Succession Contact Cadence
   - ☐ Task: Succession Contact Update
   - ☐ Case: Send Succession Form
   - ☐ Case - Multiple Successors Handler

**Check Flow Trigger Criteria:**

Click **Case: Succession Contact Cadence** → View:
- Entry Criteria: `RecordType = EstateAdministration AND Type = "Named Successor Enactment" AND Verification_Status = "Complete - Verified"`
- Trigger: Record is created
- Scheduled Paths: 4 paths (Day 5, 35, 65, 95)

---

### ✅ Phase 2 Checkpoint

**Verify via SOQL:**
```sql
SELECT DeveloperName, ProcessType, Status, TriggerType
FROM FlowDefinitionView
WHERE DeveloperName LIKE '%Succession%'
ORDER BY DeveloperName
```

**Expected Results:**
| DeveloperName | Status | TriggerType |
|---------------|--------|-------------|
| Case_Multiple_Successors_Handler | Active | RecordAfterSave |
| Case_Send_Succession_Form | Active | RecordAfterSave |
| Case_Succession_Contact_Cadence | Active | RecordAfterSave |
| Task_Succession_Contact_Update | Active | RecordAfterSave |

---

## Phase 3: Permission Set Deployment (5 minutes)

### Task 3.1: Deploy Permission Set

```bash
sf project deploy start \
  --source-dir force-app/main/default/permissionsets/Succession_Field_Access.permissionset-meta.xml \
  --target-org schwab-sandbox \
  --wait 5
```

---

### Task 4.2: Assign Permission Set to Users

1. Navigate to: **Setup → Permission Sets**
2. Click: **Succession Field Access**
3. Click: **Manage Assignments**
4. Click: **Add Assignments**
5. Select users who need access (Estate Administration team)
6. Click: **Assign**

**Checkpoint:**
- ☐ Permission set deployed
- ☐ Assigned to relevant users (Estate Admin team)

---

## Phase 4: End-to-End Testing (20 minutes)

### Test Scenario 1: Single Successor - Final Grant (10 min)

**Generate Test Data:**
```apex
SuccessionTestDataFactory.SuccessionScenarioData scenario =
    SuccessionTestDataFactory.generateHappyPathFinalGrant();

System.debug('=== TEST SCENARIO 1: SINGLE SUCCESSOR ===');
System.debug('Deceased Donor: ' + scenario.deceasedDonor.Name);
System.debug('Successor: ' + scenario.successor.Name);
System.debug('DAF Account: ' + scenario.dafAccount.Name);
System.debug('Case ID: ' + scenario.successionCase.Id);
System.debug('Case Number: ' + scenario.successionCase.CaseNumber);
```

**Test Steps:**

1. **Phase 1: Verification**
   - Navigate to Case (use Case ID from above)
   - Verify: RecordType = "Estate Administration", Type = "Named Successor Enactment"
   - Set: `Verification_Status__c = "Complete - Verified"`
   - Click: **Save**
   - **Expected:** Contact Cadence flow triggers → Attempt 1 task created

2. **Phase 2: Contact & Pathway**
   - View Tasks tab → Find "Succession Contact - Attempt 1"
   - Mark: `Status = "Completed"`, `Succession_Contact_Established__c = TRUE`
   - Click: **Save**
   - **Expected:**
     - Task Update flow triggers
     - Case updated: `Contact_Established__c = TRUE`
     - Send Form flow triggers: `Form_Sent_Date__c` populated
     - Email sent (check debug logs)

3. **Phase 3: Form Submission**
   - Click: Quick Action "Send Succession Form" (or access embedded OmniScript)
   - Complete form:
     - Pathway: Final Grant
     - Add 2 beneficiaries (total = account balance)
     - Upload documents
     - E-sign
     - Submit
   - **Expected:**
     - Success message
     - Case: `Pathway_Confirmed__c = "Final Grant"`
     - 2 Grant transactions created

4. **Verify Scheduled Paths Terminated:**
   ```sql
   SELECT Id, Subject, Status, Contact_Attempt_Number__c
   FROM Task
   WHERE WhatId = '500XXXXXXXXXXXXXXX'
   ORDER BY Contact_Attempt_Number__c
   ```
   **Expected:** Only 1 task (Attempt 1), no tasks for Attempt 2-5 created

**Checklist:**
- ☐ Contact cadence triggered on verification
- ☐ Task completion set Contact_Established__c
- ☐ Form email sent automatically
- ☐ OmniScript submission successful
- ☐ Grant transactions created
- ☐ Future scheduled paths did not create tasks

---

### Test Scenario 2: Multiple Successors - Hierarchy (10 min)

**Generate Test Data:**
```apex
SuccessionTestDataFactory.SuccessionScenarioData scenario =
    SuccessionTestDataFactory.generateMultipleSuccessorsScenario();

System.debug('=== TEST SCENARIO 2: MULTIPLE SUCCESSORS ===');
System.debug('Deceased Donor: ' + scenario.deceasedDonor.Name);
System.debug('DAF Account: ' + scenario.dafAccount.Name);
System.debug('Case ID (will become child): ' + scenario.successionCase.Id);

// Query created hierarchy
List<Case> parentCases = [SELECT Id, CaseNumber, Subject, Type
                          FROM Case
                          WHERE Type = 'Multi-Account Succession Master'
                          ORDER BY CreatedDate DESC LIMIT 1];
if (!parentCases.isEmpty()) {
    System.debug('Parent Case ID: ' + parentCases[0].Id);
    System.debug('Parent Case Number: ' + parentCases[0].CaseNumber);
}

List<Case> childCases = [SELECT Id, CaseNumber, ContactId, ParentId
                         FROM Case
                         WHERE ParentId = :parentCases[0].Id];
System.debug('Child Cases Created: ' + childCases.size());
```

**Test Steps:**

1. **Verify Hierarchy Created:**
   ```sql
   -- Find parent case
   SELECT Id, CaseNumber, Subject, Type
   FROM Case
   WHERE Type = 'Multi-Account Succession Master'
   ORDER BY CreatedDate DESC
   LIMIT 1

   -- Find child cases
   SELECT Id, CaseNumber, Subject, Contact.Name, ParentId
   FROM Case
   WHERE ParentId = '500XXXXXXXXXXXXXXX'  -- Use parent case ID
   ```
   **Expected:**
   - 1 Parent case (Type = "Multi-Account Succession Master")
   - 3 Child cases (original + 2 new)
   - Each child has different ContactId

2. **Verify Case Team Members:**
   ```sql
   SELECT Id, ParentId, Member.Name, TeamRole.Name
   FROM CaseTeamMember
   WHERE ParentId = '500XXXXXXXXXXXXXXX'  -- Use parent case ID
   ```
   **Expected:** 3 members (all successors), TeamRole = "Successor"

3. **Test Independent Contact Cadences:**
   - For each child case:
     - Set `Verification_Status__c = "Complete - Verified"`
     - Verify: Attempt 1 task created for EACH child independently

4. **Test Independent Form Submission:**
   - Child 1: Complete form → Select "New DAF Account"
   - Child 2: Complete form → Select "Final Grant"
   - Verify: Each child has its own `Pathway_Confirmed__c` value

**Checklist:**
- ☐ Multi-Successor Handler created parent case
- ☐ 3 child cases exist (1 original + 2 new)
- ☐ 3 CaseTeamMembers added to parent
- ☐ Each child triggers independent contact cadence
- ☐ Each successor can select different pathway

---

### ✅ Phase 5 Final Verification

**Run Comprehensive Test Script:**
```apex
System.debug('=== FINAL VERIFICATION ===');

// Check flows active
List<FlowDefinitionView> flows = [SELECT DeveloperName, Status FROM FlowDefinitionView WHERE DeveloperName LIKE '%Succession%'];
System.debug('Active Succession Flows: ' + flows.size());

// Check OmniStudio components
// (Manual check in Setup → OmniStudio)

// Check permission set
List<PermissionSet> ps = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Succession_Field_Access'];
System.debug('Permission Set Deployed: ' + (!ps.isEmpty()));

// Check test data works
try {
    SuccessionTestDataFactory.SuccessionScenarioData test =
        SuccessionTestDataFactory.generateHappyPathFinalGrant();
    System.debug('✅ Test Data Generation: WORKING');

    // Cleanup
    delete test.successionCase;
    delete test.dafAccount;
    delete test.successor;
    delete test.deceasedDonor;
} catch (Exception e) {
    System.debug('❌ Test Data Generation: FAILED - ' + e.getMessage());
}

System.debug('🎉 DEPLOYMENT COMPLETE!');
```

---

## 📊 Deployment Completion Checklist

### Pre-Deployment
- ☐ Phase 1 validation fixes applied
- ☐ Phase 1 verification script passed

### Core Deployment
- ☐ 4 succession flows deployed and active
- ☐ 3 DataRaptors imported and active
- ☐ 1 OmniScript imported and active
- ☐ OmniScript accessible on Case page
- ☐ Permission set deployed and assigned

### Testing
- ☐ Single successor end-to-end test passed
- ☐ Multiple successors hierarchy test passed
- ☐ Contact cadence automation verified
- ☐ Form submission creates grant transactions
- ☐ Scheduled paths self-terminate correctly

### Documentation
- ☐ All docs reviewed: `docs/SUCCESSION_FLOW_ARCHITECTURE.md`
- ☐ Troubleshooting guide accessible: `docs/OMNISTUDIO_COMPLETE_DEPLOYMENT.md`

---

## 🆘 Troubleshooting Quick Reference

| Issue | Check | Solution |
|-------|-------|----------|
| **Deceased donor creation fails** | Validation rule ChooseProspectTypeOnly | Add `ISBLANK(Date_of_Death__c)` condition |
| **Financial account creation fails** | PrimaryAndJointOwnerCannotBeSame | Verify corrected version active |
| **Contact cadence not triggering** | Flow entry criteria | Verify `Verification_Status__c = "Complete - Verified"` |
| **Task completion doesn't update Case** | Task flow trigger | Verify `Contact_Attempt_Number__c` populated on task |
| **Form access denied** | Case field | Ensure `Contact_Established__c = TRUE` |
| **OmniScript preview fails** | DataRaptor | Test SuccessionContextLoad with valid Case ID |
| **Grant transactions not created** | Picklist values | Verify TransactionType = "Grant", TransactionStatus = "Pending Review" |
| **Hierarchy not created** | FinancialAccountRole | Verify ≥2 active successors with Role = "Successor" |

---

## 📚 Related Documentation

- **Flow Architecture:** `docs/SUCCESSION_FLOW_ARCHITECTURE.md`
- **OmniStudio Deployment:** `docs/OMNISTUDIO_COMPLETE_DEPLOYMENT.md`
- **Validation Fixes:** `docs/QUICK_FIX_GUIDE.md`
- **Test Data:** `docs/test-data-factory-usage.md`
- **Multi-Successor Details:** `docs/MULTI_SUCCESSOR_HIERARCHY_COMPONENT.md`

---

## ✅ Success Criteria

**Deployment is complete when:**
1. ✅ All validation fixes applied and verified
2. ✅ All 4 flows show Status = Active in org
3. ✅ OmniStudio components imported and tested
4. ✅ Single successor test completes end-to-end
5. ✅ Multiple successors create proper hierarchy
6. ✅ Permission set assigned to users
7. ✅ No errors in debug logs during testing

**Estimated Total Time:** 90 minutes
**Actual Time:** _________ minutes

---

**Questions or Issues?** Review troubleshooting guides or check flow architecture documentation.

**Production Readiness:** After successful sandbox testing, repeat deployment steps in production org.
