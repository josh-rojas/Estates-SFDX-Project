# Validation Issues - Current Status Report

**Generated**: 2025-01-02 08:13 MST  
**Org**: schwab-sandbox (josh.rojas.charfsc@schwab.com.fscjosh)  
**Test Method**: Live validation test via Anonymous Apex  

---

## Executive Summary

**ALL 3 VALIDATION ISSUES STILL EXIST** ❌

Despite previous autonomous resolution attempts, validation tests confirm that all three blocking issues are still active in the org. Test data generation continues to fail at multiple points.

---

## Issue #1: GroupRecordTypeMapper - IndustriesBusiness ❌ STILL EXISTS

### Evidence from Debug Log

```
21:57:03.285|SOQL_EXECUTE_BEGIN|SELECT FinServ__AccountRecordType__c, FinServ__AccountRecordTypeNamespace__c 
                                FROM GroupRecordTypeMapper__mdt
21:57:03.285|SOQL_EXECUTE_END|Rows:2  ← Query returns 2 rows

21:57:03.113|DML_END|[337]  ← Business Account insert attempt
21:57:03.113|USER_DEBUG|AdvisorFirmBuilder insert errors: 
    (Database.Error[getMessage=FinServ.AccountTrigger: execution of BeforeInsert

    caused by: FinServ.MoiExceptionWrapper.ValidationException: 
    Your account record type is missing, a duplicate, or invalid. 
    Ask your admin to check the group record type configurations in Setup.
```

### Analysis

1. **SOQL Query Returns 2 Rows**: The query for `GroupRecordTypeMapper__mdt` returns 2 records, suggesting the deployment may have worked
2. **But Trigger Still Fails**: Despite returning 2 rows, the FinServ.AccountTrigger still throws the validation exception
3. **Root Cause Hypothesis**: 
   - The deployed custom metadata may not have the correct field values
   - The trigger may be checking a different field or namespace
   - There may be a cache issue requiring org refresh

### Status
❌ **STILL BLOCKED** - Business Account creation fails

### Next Steps
1. **Verify Custom Metadata Deployment**:
   ```apex
   List<FinServ__GroupRecordTypeMapper__mdt> mappers = 
       [SELECT Label, FinServ__AccountRecordType__c, FinServ__AccountRecordTypeNamespace__c 
        FROM FinServ__GroupRecordTypeMapper__mdt];
   for (FinServ__GroupRecordTypeMapper__mdt m : mappers) {
       System.debug(m.Label + ' = ' + m.FinServ__AccountRecordType__c + 
                    ' (Namespace: ' + m.FinServ__AccountRecordTypeNamespace__c + ')');
   }
   ```

2. **Check if IndustriesBusiness mapping exists with correct values**

3. **Possible Solutions**:
   - Re-deploy the custom metadata with correct namespace values
   - Clear org cache (requires admin)
   - Check if FinServ package has different custom metadata type

---

## Issue #2: ChooseProspectTypeOnly Validation Rule ❌ STILL EXISTS

### Evidence from Debug Log

```
21:57:03.113|VALIDATION_RULE|03d5f000000hmsa|ChooseProspectTypeOnly
21:57:03.113|VALIDATION_FORMULA|AND($Profile.Name <> 'System Administrator', 
    $Profile.Name <> 'Admin/PO', 
    $Profile.Name <> 'Integration User', 
    IsPersonAccount = True,
    (
      (ISNEW() &&  NOT(ISPICKVAL(Type, 'Prospect'))) ||
      (ISCHANGED( Type ) && ISPICKVAL(PRIORVALUE(Type), "Prospect"))
    )
  )|Type=Donor , $Profile.Name=Test , IsPersonAccount=1
21:57:03.113|VALIDATION_FAIL  ← BLOCKS DECEASED DONOR

21:57:03.113|USER_DEBUG|DeceasedDonorBuilder insert errors: 
    (Database.Error[getMessage=You can only select "Prospect" from the "Type" picklist value])
```

### Analysis

- **Validation Rule ID**: `03d5f000000hmsa`
- **Formula Evaluation**: The rule fires when `IsPersonAccount = True` AND `Type != 'Prospect'`
- **Current Behavior**: Deceased donors with `Type = 'Donor'` are blocked
- **Profile Check**: Rule does NOT exclude "Test" profile (only excludes System Administrator, Admin/PO, Integration User)

### Status
❌ **CRITICAL BLOCKER** - Deceased donor creation impossible

### Required Fix (ADMIN ONLY)

**Option 1: Exclude Deceased Donors**
```apex
AND(
    $Profile.Name <> 'System Administrator',
    $Profile.Name <> 'Admin/PO',
    $Profile.Name <> 'Integration User',
    IsPersonAccount = True,
    ISBLANK(Date_of_Death__c),  // ← ADD THIS LINE
    (
        (ISNEW() &&  NOT(ISPICKVAL(Type, 'Prospect'))) ||
        (ISCHANGED( Type ) && ISPICKVAL(PRIORVALUE(Type), "Prospect"))
    )
)
```

**Option 2: Create Custom Permission Bypass**
```apex
AND(
    $Profile.Name <> 'System Administrator',
    $Profile.Name <> 'Admin/PO',
    $Profile.Name <> 'Integration User',
    NOT($Permission.Bypass_Prospect_Type_Validation),  // ← ADD THIS
    IsPersonAccount = True,
    (
        (ISNEW() &&  NOT(ISPICKVAL(Type, 'Prospect'))) ||
        (ISCHANGED( Type ) && ISPICKVAL(PRIORVALUE(Type), "Prospect"))
    )
)
```

### Admin Steps
1. Setup → Object Manager → Account → Validation Rules
2. Find: **ChooseProspectTypeOnly** (ID: `03d5f000000hmsa`)
3. Click **Edit**
4. Update formula with Option 1 or Option 2
5. Click **Save**
6. Test deceased donor creation

---

## Issue #3: PrimaryAndJointOwnerCannotBeSame Validation Rule ❌ STILL EXISTS

### Evidence from Debug Log

```
21:57:06.200|VALIDATION_RULE|03d5f000000pwY1|PrimaryAndJointOwnerCannotBeSame
21:57:06.200|VALIDATION_FORMULA|FinServ__PrimaryOwner__c = FinServ__JointOwner__c
    |FinServ__JointOwner__c=null , FinServ__PrimaryOwner__c=null
21:57:06.200|VALIDATION_FAIL  ← null = null → TRUE!

21:57:06.200|EXCEPTION_THROWN|System.DmlException: Insert failed. 
    First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, 
    The primary and joint owner must be different.: []
```

### Analysis

- **Validation Rule ID**: `03d5f000000pwY1` (OLD BUGGY RULE)
- **Logic Bug**: `null = null` evaluates to `TRUE`, causing false positive
- **Current Formula**: `FinServ__PrimaryOwner__c = FinServ__JointOwner__c`
- **Problem**: When both fields are null (normal for Individual accounts), validation fails

### Status
❌ **BLOCKS FINANCIAL ACCOUNT CREATION** - Impacts all succession scenarios

### Previous Resolution Attempt

The autonomous system:
1. ✅ Created corrected validation rule metadata (ID: `03dDg000000AvCpIAK`)
2. ✅ Deployed destructive changes manifest
3. ❌ **OLD RULE STILL ACTIVE** - Deployment did not replace/deactivate old rule

### Required Fix (ADMIN ONLY)

**Step 1: Verify Duplicate Rules Exist**
```sql
SELECT Id, ValidationName, Active 
FROM ValidationRule 
WHERE EntityDefinitionId = 'FinServ__FinancialAccount__c' 
  AND ValidationName LIKE '%PrimaryAndJoint%'
```

**Expected Result**: TWO rules with same name:
- Old Rule: `03d5f000000pwY1` (buggy formula, Active=TRUE)
- New Rule: `03dDg000000AvCpIAK` (corrected formula, Active=TRUE/FALSE)

**Step 2: Deactivate Old Rule**
1. Setup → Object Manager → Financial Account → Validation Rules
2. Find: **PrimaryAndJointOwnerCannotBeSame** (ID: `03d5f000000pwY1`)
3. Click **Deactivate**

**Step 3: Activate New Rule (if not already active)**
1. Find: **PrimaryAndJointOwnerCannotBeSame** (ID: `03dDg000000AvCpIAK`)
2. Click **Activate**

**Corrected Formula** (in new rule):
```apex
AND(
    NOT(ISBLANK(FinServ__PrimaryOwner__c)),
    NOT(ISBLANK(FinServ__JointOwner__c)),
    FinServ__PrimaryOwner__c = FinServ__JointOwner__c
)
```

This formula only validates when **BOTH** fields have values AND they're equal (correct behavior).

---

## Test Execution Flow & Failures

### Test Flow Diagram

```
generateHappyPathFinalGrant()
  ↓
Step 1: Create Advisor Firm (Business Account)
  → RecordType: IndustriesBusiness ✓ Found
  → Insert Attempt... ❌ FAIL
  → Error: "Your account record type is missing, a duplicate, or invalid"
  ↓
Step 2: Create Deceased Donor (PersonAccount)
  → RecordType: PersonAccount ✓ Found
  → Type: Donor
  → Insert Attempt... ❌ FAIL
  → Error: "You can only select Prospect from the Type picklist value"
  → Validation Rule: ChooseProspectTypeOnly (03d5f000000hmsa)
  ↓
Step 3: Create Financial Account
  → PrimaryOwner: null
  → JointOwner: null
  → Insert Attempt... ❌ FAIL
  → Error: "The primary and joint owner must be different"
  → Validation Rule: PrimaryAndJointOwnerCannotBeSame (03d5f000000pwY1)
  → Logic Bug: null = null → TRUE
  ↓
FATAL_ERROR: Test data generation aborted
```

### Cascade Effect

All three issues are **sequential blockers**:
1. Issue #1 blocks advisor firm creation → Skipped (uses DML options to continue)
2. Issue #2 blocks deceased donor creation → Skipped (uses DML options to continue)
3. Issue #3 blocks financial account creation → **FATAL** (Cannot continue without donor/account)

---

## Recommendations

### Immediate Actions (ADMIN REQUIRED)

| Priority | Issue | Action | Time | Impact |
|----------|-------|--------|------|--------|
| 1 - CRITICAL | Issue #2: ChooseProspectTypeOnly | Update validation formula | 5 min | Unblocks deceased donor creation |
| 2 - HIGH | Issue #3: PrimaryAndJointOwner | Deactivate old rule | 2 min | Unblocks financial account creation |
| 3 - MEDIUM | Issue #1: GroupRecordTypeMapper | Verify/redeploy metadata | 10 min | Unblocks business account creation |

**Total Admin Time**: ~17 minutes

### Verification Script

After admin fixes, run this test:

```apex
System.debug('=== VALIDATION FIX VERIFICATION ===');

// Test 1: Business Account
try {
    RecordType bizRT = [SELECT Id FROM RecordType 
                        WHERE SobjectType = 'Account' 
                        AND DeveloperName = 'IndustriesBusiness' LIMIT 1];
    Account biz = new Account(
        RecordTypeId = bizRT.Id,
        Name = 'Test Firm ' + System.now().getTime(),
        Type = 'Firm'
    );
    insert biz;
    System.debug('✅ Issue #1 FIXED: Business Account created: ' + biz.Id);
    delete biz;
} catch (Exception e) {
    System.debug('❌ Issue #1 STILL EXISTS: ' + e.getMessage());
}

// Test 2: Deceased Donor
try {
    RecordType personRT = [SELECT Id FROM RecordType 
                           WHERE SobjectType = 'Account' 
                           AND DeveloperName = 'PersonAccount' LIMIT 1];
    Account donor = new Account(
        RecordTypeId = personRT.Id,
        FirstName = 'Test',
        LastName = 'Donor_' + System.now().getTime(),
        PersonEmail = 'test@example.com',
        Type = 'Donor',
        Date_of_Death__c = Date.today().addDays(-30),
        Deceased__c = true
    );
    insert donor;
    System.debug('✅ Issue #2 FIXED: Deceased Donor created: ' + donor.Id);
    
    // Test 3: Financial Account (requires donor from Test 2)
    FinServ__FinancialAccount__c fa = new FinServ__FinancialAccount__c(
        Name = 'Test FA ' + System.now().getTime(),
        FinServ__PrimaryOwner__c = donor.Id,
        FinServ__JointOwner__c = null,
        FinServ__Ownership__c = 'Individual'
    );
    insert fa;
    System.debug('✅ Issue #3 FIXED: Financial Account created: ' + fa.Id);
    
    delete fa;
    delete donor;
} catch (Exception e) {
    System.debug('❌ Issue #2 or #3 STILL EXISTS: ' + e.getMessage());
}

System.debug('=== VERIFICATION COMPLETE ===');
```

**Expected Output (After Fixes)**:
```
✅ Issue #1 FIXED: Business Account created: 001XXXXXXXXXXXXX
✅ Issue #2 FIXED: Deceased Donor created: 001XXXXXXXXXXXXX
✅ Issue #3 FIXED: Financial Account created: a0XXXXXXXXXXXXXX
=== VERIFICATION COMPLETE ===
```

---

## Why Autonomous Resolution Failed

### Technical Limitations

1. **Custom Metadata Deployment**:
   - Metadata deployed successfully but may have incorrect field values
   - No way to verify deployment contents via anonymous Apex
   - May require namespace qualification (FinServ__)

2. **Validation Rule Updates**:
   - Cannot update existing validation rules via code
   - Cannot deactivate validation rules programmatically
   - Metadata API deployment created duplicate rule instead of replacing

3. **Safety Constraints**:
   - Validation rules are business logic requiring stakeholder approval
   - Risk of breaking existing workflows
   - Cannot be modified without admin intervention

### What Was Attempted

| Action | Status | Outcome |
|--------|--------|---------|
| Deploy GroupRecordTypeMapper metadata | ✅ Deployed | ❌ Still fails (incorrect values?) |
| Deploy corrected validation rule | ✅ Deployed | ❌ Created duplicate, old rule still active |
| Create code workaround | ✅ Deployed | ❌ Insufficient (validation fires before code) |
| Deploy destructive changes | ✅ Deployed | ❌ Did not deactivate old rule |

---

## Conclusion

**Status**: **0 of 3 issues resolved** ❌

All three validation issues remain active blockers. Test data generation continues to fail at multiple sequential points. **Administrator intervention is required** to update validation rules and verify custom metadata deployment.

**Next Steps**:
1. Admin follows fix instructions in this document
2. Admin runs verification script
3. If verification passes, test data generation should succeed
4. Document any additional issues discovered

**Estimated Total Time to Resolution**: 17 minutes (admin work)

---

**Report Generated By**: Autonomous Validation System  
**Last Updated**: 2025-01-02 08:13 MST  
**Status**: All Issues Still Exist - Admin Action Required
