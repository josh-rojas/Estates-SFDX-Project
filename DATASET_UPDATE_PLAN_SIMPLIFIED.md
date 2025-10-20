# Dataset Update Plan - SIMPLIFIED FOR DEMO

**Created:** October 18, 2025  
**Scope:** Demo-focused updates only  
**Philosophy:** Keep it simple - only update fields ACTUALLY USED by components

---

## Reality Check: What's Actually Used?

### ✅ Fields ACTIVELY Used by Flows/LWCs (8 fields)
1. **Verification_Status__c** - Triggers workflow start
2. **Contact_Attempt_Count__c** - Tracks attempts, used in caseHierarchyViewer
3. **Contact_Established__c** - Gate field for flows
4. **Contact_Established_Date__c** - Audit timestamp
5. **Form_Sent_Date__c** - Email tracking
6. **Form_Completed_Date__c** - Form submission tracking  
7. **Pathway_Confirmed__c** - Selected pathway (Final Grant/New DAF/Disclaim)
8. **SLA_Status__c** - Used in caseHierarchyViewer LWC for visual indicators

### ❌ Fields DEPLOYED but NOT Used (8 fields)
1. **Next_Task_Scheduled_At__c** - Intended for scheduled automation (NOT USED)
2. **Grant_Settlement_Status__c** - Complex multi-step tracking (NOT USED in flows/LWCs)
3. **Execution_Started_Date__c** - Manual tracking only
4. **Execution_Completed_Date__c** - Manual tracking only
5. **Execution_Notes__c** - Manual notes field
6. **Execution_Status__c** - Exists but flows don't reference it
7. **Asset_Transfer_Status__c** - Complex tracking (NOT USED in automation)
8. **Disclaimer_Disposition__c** - Manual tracking for disclaim pathway

**Conclusion:** These fields are "display only" for manual data entry, not used by automation.

---

## SIMPLIFIED Update Plan - Demo Focus Only

### Phase 1: Fix Critical Data Load Issues (30 MIN)

#### Task 1.1: Update succession_mapping.yml - Add ONLY Used Fields

**File:** `datasets/succession_mapping.yml`

**Add These Mappings (4 fields that exist in recipes but missing from mapping):**
```yaml
Insert Case:
  sf_object: Case
  table: Case
  fields:
    # ... existing fields ...
    Contact_Established_Date__c: ContactEstablishedDate
    Execution_Status__c: Execution_Status__c  # For display only
    Asset_Transfer_Status__c: Asset_Transfer_Status__c  # For display only
    Grant_Settlement_Status__c: Grant_Settlement_Status__c  # For display only
```

**SKIP:** Next_Task_Scheduled_At__c, Execution_Started/Completed_Date__c, Execution_Notes__c, Disclaimer_Disposition__c, New_DAF_Account_Number__c  
**Reason:** Not used by automation, add manual complexity to demos

---

#### Task 1.2: Fix Invalid Picklist Values - Asset_Transfer_Status__c

**Problem:** Recipes use non-existent values  
**Solution:** Use simplest valid values or set to "Not Applicable"

**Valid Values:**
- Not Applicable
- New Account Verified
- Journal Entry Created
- Transfer In Progress
- Both Accounts Updated
- Relationship Established

**Simplified Approach - Set Everything to "Not Applicable":**

This works for demos because:
- Final Grant pathway = "Not Applicable" (no asset transfer)
- New DAF pathway = Can set manually if showing that pathway
- Disclaim pathway = Can set manually if showing that pathway

**Files to Update (3 lines total):**

**succession_data.recipe.yml - Line ~590:**
```yaml
# Settlement Pending Case
Asset_Transfer_Status__c: Not Applicable  # Was: Transfer Completed
```

**succession_data.recipe.yml - Line ~650:**
```yaml
# New DAF In Progress Case  
Asset_Transfer_Status__c: Not Applicable  # Was: Transfer Initiated (or keep "Transfer In Progress" if showcasing New DAF)
```

**multi_successor_scenario.recipe.yml - Line ~150 & ~190:**
```yaml
# Amanda (Final Grant)
Asset_Transfer_Status__c: Not Applicable  # Was: Completed

# Brandon (New DAF)
Asset_Transfer_Status__c: Not Applicable  # Was: Transfer Completed (or use "Relationship Established" if showcasing)
```

---

### Phase 2: Add Minimal Dual Entry Point Test (15 MIN - OPTIONAL)

**File:** `datasets/demo_ui_showcase.recipe.yml`

**Add 1 Simple Test Case:**
```yaml
# Manual Entry Point Test
- object: Case
  nickname: Case_ManualEntry_Simple
  fields:
    RecordType.DeveloperName: ${{EstateAdministrationRecordType}}
    Type: Named Successor Enactment
    Subject: Quick Action Test - Click Begin Processing
    Status: New
    Verification_Status__c: Not Started  # Agent must click Quick Action
    Contact_Attempt_Count__c: 0
    Contact_Established__c: false
    Pathway_Confirmed__c: Not Selected
    Form_Sent_Date__c: null
    Form_Completed_Date__c: null
    Description: "Demo case for testing 'Begin Succession Processing' Quick Action. Start with Verification = Not Started, click action, verify task created."
  # ... minimal Account/FA setup ...
```

---

## What to SKIP (Overcomplicated for Demo)

### ❌ DON'T Add:
1. **Next_Task_Scheduled_At__c** - Intended for complex scheduled automation we don't use
2. **Execution_Started/Completed_Date__c** - Manual tracking, not used by flows
3. **Execution_Notes__c** - Long text field for manual notes
4. **SLA_Status__c scenarios** - Field exists but no SLA automation in place
5. **Grant_Settlement_Status__c scenarios** - Too granular for demo (MyQ coordination, T+1 settlement)
6. **Disclaimer_Disposition__c** - Disclaim pathway is edge case
7. **Complex hierarchy scenarios** - Parent/child works, don't need grandchildren
8. **QuickAction workflow sequences** - Individual actions work, don't need all 5 in one case

### ✅ DO Keep Simple:
1. **Fix invalid picklist values** (breaks data load)
2. **Add Contact_Established_Date__c mapping** (used in flows)
3. **Keep existing test scenarios** (they work, just fix invalid values)
4. **Maybe add 1 manual entry test case** (if time permits)

---

## Simplified Implementation Checklist

### ✅ MUST DO (30 minutes)

- [ ] **1.1** Update `succession_mapping.yml` - Add Contact_Established_Date__c mapping
- [ ] **1.2** Fix `succession_data.recipe.yml` - Change 2 Asset_Transfer_Status__c values to "Not Applicable"
- [ ] **1.3** Fix `multi_successor_scenario.recipe.yml` - Change 2 Asset_Transfer_Status__c values to "Not Applicable"  
- [ ] **1.4** Test: `snowfakery datasets/succession_data.recipe.yml --output-format txt | head -50`
- [ ] **1.5** Load data: `cci task run load_succession_test_data --org schwab-sandbox`

### 🤔 MAYBE DO (15 minutes - if useful for demos)

- [ ] **2.1** Add 1 simple "Manual Entry" test case to demo_ui_showcase.recipe.yml
- [ ] **2.2** Test Quick Action workflow with that case

### ❌ DON'T DO (waste of time)

- ❌ Don't add Next_Task_Scheduled_At__c scenarios
- ❌ Don't add complex SLA breach scenarios
- ❌ Don't add Grant_Settlement_Status__c multi-step tracking
- ❌ Don't add Execution_Notes__c to every case
- ❌ Don't create comprehensive UI state matrix
- ❌ Don't add grandchild case hierarchies
- ❌ Don't add 10 new test scenarios

---

## Minimal Viable Changes

### File 1: datasets/succession_mapping.yml

**Add 1 line:**
```yaml
Contact_Established_Date__c: ContactEstablishedDate
```

### File 2: datasets/succession_data.recipe.yml

**Change 2 lines (~590, ~650):**
```yaml
Asset_Transfer_Status__c: Not Applicable  # Both invalid value fixes
```

### File 3: datasets/multi_successor_scenario.recipe.yml

**Change 2 lines (~150, ~190):**
```yaml
Asset_Transfer_Status__c: Not Applicable  # Both invalid value fixes
```

**Total Changes: 5 lines across 3 files**

---

## Verification (5 minutes)

```bash
# Test generation
snowfakery datasets/succession_data.recipe.yml --mapping datasets/succession_mapping.yml --output-format txt | head -100

# Load to org
cci task run load_succession_test_data --org schwab-sandbox

# Verify
sf data query --query "SELECT Subject, Asset_Transfer_Status__c FROM Case WHERE Type = 'Named Successor Enactment' LIMIT 10" --target-org josh.rojas.charfsc@schwab.com.fscjosh
```

**Expected:** No errors, all cases load successfully

---

## Total Effort: 45 Minutes (vs 6.5 hours in complex plan)

- ✅ Fixes critical data load issues
- ✅ Maintains existing test coverage
- ✅ Keeps demos simple and clear
- ✅ No overcomplicated scenarios

---

## Recommendation

**Use this simplified plan instead of the comprehensive one.**

The fields exist for potential future use, but for demo purposes:
- Fix what's broken (invalid picklist values)
- Add what's missing (Contact_Established_Date__c mapping)
- Leave the rest alone (manual tracking fields don't need test data)

**Guiding Principle:** Demo simplicity > comprehensive test coverage

---

**Status:** READY TO IMPLEMENT (45 min effort)
