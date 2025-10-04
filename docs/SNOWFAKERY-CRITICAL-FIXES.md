# Snowfakery Critical Fixes

## Required Actions to Complete Data Loading

**Date**: 2025-01-31  
**Priority**: HIGH  
**Status**: 3 fixes needed for successful data load

---

## Issue Summary

Snowfakery recipes are syntactically correct and generate valid data, but org-specific constraints prevent loading:

1. ✅ **FIXED**: Validation rule (Contact_Attempt_Count = 0)
2. ⏳ **NEEDS FIX**: Contact Cadence Flow triggers during load
3. ⏳ **NEEDS FIX**: Record Type permissions

---

## Fix #1: Disable Contact Cadence Flow ⚠️ CRITICAL

### Problem

`Case_Succession_Contact_Cadence` flow triggers when Cases are inserted, causing:

- "CANNOT_EXECUTE_FLOW_TRIGGER" errors
- "Probably Limit Exceeded or 0 recipients" errors
- Data load failures

### Solution

Temporarily deactivate the flow before loading data:

```bash
# Step 1: Retrieve flow
sf project retrieve start \
  --metadata Flow:Case_Succession_Contact_Cadence \
  --target-org schwab-sandbox

# Step 2: Edit flow status to Draft
# File: force-app/main/default/flows/Case_Succession_Contact_Cadence.flow-meta.xml
# Change: <status>Active</status> to <status>Draft</status>

# Step 3: Deploy deactivated flow
sf project deploy start \
  --metadata Flow:Case_Succession_Contact_Cadence \
  --target-org schwab-sandbox

# Step 4: Load data
cci task run load_demo_ui_showcase \
  --org schwab-sandbox \
  --drop_missing_schema True \
  --ignore_row_errors True

# Step 5: Reactivate flow
# Change back to: <status>Active</status>
sf project deploy start \
  --metadata Flow:Case_Succession_Contact_Cadence \
  --target-org schwab-sandbox
```

### Alternative: Use Custom Metadata Switch

If triggers check `Apex_Trigger_Switch__mdt`, flows should too:

```xml
<!-- Add to flow entry criteria -->
<filters>
    <field>$Setup.Apex_Trigger_Switch__mdt.Case.Active__c</field>
    <operator>EqualTo</operator>
    <value>
        <booleanValue>true</booleanValue>
    </value>
</filters>
```

---

## Fix #2: Grant Record Type Access

### Problem

Task RecordTypeId (ClientAssociateTask) not accessible:

- "INVALID_CROSS_REFERENCE_KEY: this ID value isn't valid for the user"

### Solution Option A: Remove Record Type from Mapping

```yaml
# In datasets/succession_mapping.yml
Insert Task:
  sf_object: Task
  table: Task
  fields:
    # ... other fields ...
  # Remove this line:
  # record_type: ClientAssociateTask
```

### Solution Option B: Grant Access via Profile/Permission Set

```bash
# Query to find which profile user has
cci task run run_soql_query \
  --query "SELECT Profile.Name FROM User WHERE Username = 'josh.rojas.charfsc@schwab.com.fscjosh'" \
  --org schwab-sandbox

# Then grant ClientAssociateTask record type access to that profile
```

---

## Fix #3: Handle Person Account Friends Pattern

### Problem

Friends pattern creates placeholder Account records without required fields:

- Business Accounts missing `LastName` (they use `Name`)
- Duplicate detection rules triggering

### Solution: Simplify Recipe Structure

Remove `friends` and use direct ID references after Account creation:

```yaml
# Current (causes issues):
- object: FinancialAccount
  friends:
    - object: Account
      nickname: DeceasedDonor

# Better approach:
- object: Account
  nickname: DeceasedDonor
  # ... fields ...

- object: FinancialAccount
  fields:
    # ... other fields ...
    # Lookup handled by mapping file
```

The mapping file handles lookups via `key_field: id`.

---

## Quick Win: Load Simpler Recipe

Create a minimal recipe without flows/validation issues:

```yaml
# datasets/simple_test.recipe.yml
- object: Account
  count: 1
  fields:
    FirstName: Test
    LastName: Donor
    Type: Donor
    Deceased__c: true
    Date_of_Death__c:
      date_between:
        start_date: -30d
        end_date: -30d
    PersonEmail: test@example.com
    FinServ__Status__c: Closed
```

Load it:

```bash
cci task run load_succession_test_data \
  --org schwab-sandbox \
  --generator_yaml datasets/simple_test.recipe.yml \
  --drop_missing_schema True
```

---

## Recommended Action Plan

### Immediate (30 minutes)

1. ✅ Deactivate `Case_Succession_Contact_Cadence` flow
2. ✅ Remove `record_type` from Task mapping
3. ✅ Load data with flags: `--drop_missing_schema True --ignore_row_errors True`
4. ✅ Verify data in org
5. ✅ Reactivate flow

### Short Term (This Week)

6. ⏳ Refine recipes to avoid friends pattern issues
7. ⏳ Add flow entry criteria to check Apex_Trigger_Switch\_\_mdt
8. ⏳ Grant record type permissions
9. ⏳ Test LWC components with loaded data

### Medium Term (Next 2 Weeks)

10. ⏳ Create permission set for Snowfakery data loading
11. ⏳ Document org-specific requirements
12. ⏳ Train team on Snowfakery approach
13. ⏳ Deprecate non-functional TestDataFactory

---

## Success Criteria

- [ ] Data loads without errors
- [ ] All 5 scenarios represented in org
- [ ] LWC components display correctly
- [ ] No manual cleanup needed
- [ ] Process documented for team

---

**Next Action**: Deactivate Contact Cadence flow, then retry data load.

---

**Document Version**: 1.0  
**Last Updated**: 2025-01-31  
**Maintained By**: Salesforce Architecture Team
