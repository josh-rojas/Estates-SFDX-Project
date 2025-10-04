# Quick Fix Guide - Validation Issues

**Last Updated**: 2025-01-02  
**Estimated Time**: 7 minutes (Issues #2 and #3 only)

---

## ⚡ Priority Fixes (Required for Test Data Generation)

### 🔴 Fix #1: ChooseProspectTypeOnly (5 minutes) - CRITICAL

**What it does**: Blocks deceased donors with Type='Donor'

**Steps**:
1. Setup → Quick Find: `Object Manager` → **Account** → **Validation Rules**
2. Click **ChooseProspectTypeOnly**
3. Click **Edit**
4. Find line 4 in the formula (after `IsPersonAccount = True,`)
5. Add new line: `ISBLANK(Date_of_Death__c),`

**Before**:
```apex
AND(
    $Profile.Name <> 'System Administrator',
    $Profile.Name <> 'Admin/PO',
    $Profile.Name <> 'Integration User',
    IsPersonAccount = True,
    (
        (ISNEW() && NOT(ISPICKVAL(Type, 'Prospect'))) ||
        (ISCHANGED(Type) && ISPICKVAL(PRIORVALUE(Type), "Prospect"))
    )
)
```

**After** (add line 5):
```apex
AND(
    $Profile.Name <> 'System Administrator',
    $Profile.Name <> 'Admin/PO',
    $Profile.Name <> 'Integration User',
    IsPersonAccount = True,
    ISBLANK(Date_of_Death__c),  ← ADD THIS LINE
    (
        (ISNEW() && NOT(ISPICKVAL(Type, 'Prospect'))) ||
        (ISCHANGED(Type) && ISPICKVAL(PRIORVALUE(Type), "Prospect"))
    )
)
```

6. Click **Save**

---

### 🟡 Fix #2: PrimaryAndJointOwnerCannotBeSame (2 minutes) - HIGH

**What it does**: Blocks financial accounts when both owners are null (null=null bug)

**Steps**:
1. Setup → Quick Find: `Object Manager` → **Financial Account** → **Validation Rules**
2. Look for **PrimaryAndJointOwnerCannotBeSame**
3. Check the formula:
   - If formula is just: `FinServ__PrimaryOwner__c = FinServ__JointOwner__c` → **This is the buggy rule**
   - Click **Edit** → **Uncheck Active** → **Save**

4. If you see a second PrimaryAndJointOwnerCannotBeSame rule with formula:
   ```apex
   AND(
       NOT(ISBLANK(FinServ__PrimaryOwner__c)),
       NOT(ISBLANK(FinServ__JointOwner__c)),
       FinServ__PrimaryOwner__c = FinServ__JointOwner__c
   )
   ```
   This is the corrected rule → Make sure **Active** is checked

---

## ✅ Quick Verification

After fixes, test with this code:

**Developer Console** → **Debug** → **Open Execute Anonymous Window**:

```apex
System.debug('=== QUICK VERIFICATION ===');

// Test deceased donor
try {
    RecordType rt = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'PersonAccount' LIMIT 1];
    Account donor = new Account(RecordTypeId = rt.Id, FirstName = 'Test', LastName = 'Fix', PersonEmail = 'test@example.com', Type = 'Donor', Date_of_Death__c = Date.today().addDays(-30), Deceased__c = true);
    insert donor;
    System.debug('✅ Fix #1 WORKS');
    
    // Test financial account
    FinServ__FinancialAccount__c fa = new FinServ__FinancialAccount__c(Name = 'Test', FinServ__PrimaryOwner__c = donor.Id, FinServ__JointOwner__c = null, FinServ__Ownership__c = 'Individual');
    insert fa;
    System.debug('✅ Fix #2 WORKS');
    
    delete fa;
    delete donor;
    System.debug('🎉 ALL FIXED!');
} catch (Exception e) {
    System.debug('❌ ERROR: ' + e.getMessage());
}
```

**Expected Output**: `🎉 ALL FIXED!`

---

## 📋 Summary

| Fix | Time | Impact |
|-----|------|--------|
| #1: ChooseProspectTypeOnly | 5 min | Unblocks deceased donor creation |
| #2: PrimaryAndJointOwner | 2 min | Unblocks financial account creation |

**Total**: 7 minutes

After these fixes, test data generation should work!

---

## 🆘 If You Get Stuck

Check the detailed instructions in `docs/VALIDATION_ISSUES_CURRENT_STATUS.md` or run the diagnostic queries I provided.
