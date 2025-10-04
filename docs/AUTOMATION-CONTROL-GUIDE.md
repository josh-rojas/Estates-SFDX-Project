# Automation Control Guide

## Safe Data Loading with CumulusCI

**Purpose**: Prevent data load failures caused by triggers, validation rules, and workflows  
**Date**: 2025-01-31

---

## Problem Statement

When loading test data, background automation can cause failures:

### Common Issues

1. **Triggers** fire and create unexpected records
2. **Validation Rules** block records that would be valid in production
3. **Workflow Rules** send emails or create tasks
4. **Process Builders** execute complex logic
5. **Flows** trigger and modify data mid-load

### Impact

- Data load failures
- Incomplete test datasets
- Inconsistent test results
- Wasted development time

---

## Solution: Automation Control

CumulusCI flows now include automation control steps:

```yaml
flows:
  safe_data_load:
    steps:
      1: disable_triggers # Turn OFF automation
      2: load_data # Load test data safely
      3: enable_triggers # Turn ON automation
```

---

## Implementation

### Apex Trigger Control

**Mechanism**: `Apex_Trigger_Switch__mdt` Custom Metadata Type

**How It Works**:

```apex
// In each trigger
Boolean isActiveTrigger = Apex_Trigger_Switch__mdt.getInstance('Account')?.Active__c ?? true;
if(isActiveTrigger) {
    // Trigger logic only runs if Active__c = true
}
```

**CumulusCI Tasks**:

```yaml
disable_triggers:
  description: Disable all Apex triggers
  class_path: cumulusci.tasks.salesforce.update_metadata.UpdateMetadata
  options:
    metadata_type: CustomMetadata
    api_names:
      - Apex_Trigger_Switch.Account
      - Apex_Trigger_Switch.Case
      - Apex_Trigger_Switch.Task
    values:
      Active__c: false

enable_triggers:
  description: Re-enable all Apex triggers
  # ... (sets Active__c: true)
```

### Validation Rule Control

**Option 1**: Use `Database.DMLOptions` in Apex

```apex
Database.DMLOptions dml = new Database.DMLOptions();
dml.DuplicateRuleHeader.AllowSave = true;
Database.insert(records, dml);
```

**Option 2**: Temporarily deactivate via Metadata API

```bash
# Deactivate validation rules (manual)
sf project retrieve start --metadata ValidationRule
# Edit .validationRule-meta.xml files: <active>false</active>
sf project deploy start --metadata ValidationRule
```

**Option 3**: Use CumulusCI's built-in handling

```yaml
# CumulusCI automatically handles some validation rules
# via Bulk API settings
```

### Workflow & Process Builder Control

**Best Practice**: Use `Apex_Trigger_Switch__mdt` pattern

**Alternative**: Deactivate via Metadata API

```bash
# Retrieve workflows
sf project retrieve start --metadata WorkflowRule

# Deactivate (edit XML)
<active>false</active>

# Deploy
sf project deploy start --metadata WorkflowRule
```

### Flow Control

**Mechanism**: Flow activation status

**CumulusCI Approach**:

```yaml
# Flows are typically OK during test data load
# They respect trigger switches and run in test context
# If issues arise, deactivate specific flows:

deactivate_flows:
  class_path: cumulusci.tasks.salesforce.update_metadata.UpdateMetadata
  options:
    metadata_type: Flow
    api_names:
      - Case_Succession_Contact_Cadence
    values:
      status: Draft # Deactivates flow
```

---

## Usage Examples

### Safe Data Load (Recommended)

```bash
# Use flow with automation control
cci flow run succession_test_setup --org schwab-sandbox

# This automatically:
# 1. Disables triggers
# 2. Loads data
# 3. Re-enables triggers
```

### Manual Control (Advanced)

```bash
# Step 1: Disable automation
cci task run disable_triggers --org schwab-sandbox

# Step 2: Load data
cci task run load_succession_test_data --org schwab-sandbox

# Step 3: Re-enable automation
cci task run enable_triggers --org schwab-sandbox
```

### Verify Automation State

```bash
# Check trigger switches
cci task run run_soql_query \
  --query "SELECT DeveloperName, Active__c FROM Apex_Trigger_Switch__mdt" \
  --org schwab-sandbox

# Expected: All Active__c = true (after load complete)
```

---

## Troubleshooting

### Issue: Triggers still firing during load

**Cause**: Trigger doesn't check `Apex_Trigger_Switch__mdt`

**Solution**: Update trigger to check switch

```apex
trigger AccountTrigger on Account(before insert, after insert) {
  Boolean isActive = Apex_Trigger_Switch__mdt.getInstance('Account')
    ?.Active__c ?? true;
  if (!isActive)
    return; // Exit early if disabled

  // Trigger logic

}
```

### Issue: Validation rule blocking insert

**Cause**: Validation rule doesn't respect test context

**Solution**: Update validation rule formula

```
AND(
  NOT($Setup.Apex_Trigger_Switch__mdt.Account.Active__c),  // Skip if triggers disabled
  /* existing validation logic */
)
```

### Issue: Flow creating duplicate records

**Cause**: Flow triggers on record creation

**Solution**: Add flow entry criteria

```
AND(
  $Setup.Apex_Trigger_Switch__mdt.Case.Active__c = TRUE,  // Only run if enabled
  /* existing criteria */
)
```

### Issue: Automation not re-enabling

**Cause**: Task failed or was interrupted

**Solution**: Manually re-enable

```bash
# Force enable all triggers
cci task run enable_triggers --org schwab-sandbox

# Verify
cci task run run_soql_query \
  --query "SELECT DeveloperName, Active__c FROM Apex_Trigger_Switch__mdt WHERE Active__c = false" \
  --org schwab-sandbox

# Expected: 0 results (all enabled)
```

---

## Best Practices

### 1. Always Use Flows (Not Individual Tasks)

```bash
# Good - Uses flow with automation control
cci flow run succession_test_setup --org schwab-sandbox

# Risky - No automation control
cci task run load_succession_test_data --org schwab-sandbox
```

### 2. Verify Automation State After Load

```bash
# Check all switches are enabled
cci task run run_soql_query \
  --query "SELECT DeveloperName, Active__c FROM Apex_Trigger_Switch__mdt" \
  --org schwab-sandbox
```

### 3. Use `ignore_failure: true` for Control Tasks

```yaml
steps:
  1:
    task: disable_triggers
    ignore_failure: true # Don't fail if already disabled
  2:
    task: load_data
  3:
    task: enable_triggers
    ignore_failure: true # Don't fail if already enabled
```

### 4. Document Automation Dependencies

```yaml
# In recipe comments
# NOTE: This recipe assumes:
# - Account triggers disabled (creates Person Accounts)
# - Case validation rules disabled (allows test data patterns)
# - Contact Cadence flow disabled (prevents auto-task creation)
```

### 5. Test with Automation Enabled

After loading data, re-enable automation and test:

```bash
# Load data (automation disabled)
cci flow run succession_test_setup --org schwab-sandbox

# Re-enable (done automatically by flow)
# Now test with automation active
cci task run run_tests --org schwab-sandbox
```

---

## Automation Inventory

### Triggers (Controlled via Apex_Trigger_Switch\_\_mdt)

| Trigger              | Object      | Impact During Load           | Control       |
| -------------------- | ----------- | ---------------------------- | ------------- |
| `AccountTrigger`     | Account     | Lead auto-conversion         | ✅ Controlled |
| `CaseTrigger`        | Case        | Multiple successor detection | ✅ Controlled |
| `TaskTrigger`        | Task        | Contact attempt counting     | ✅ Controlled |
| `LeadTrigger`        | Lead        | Assignment rules             | ✅ Controlled |
| `OpportunityTrigger` | Opportunity | Contribution tracking        | ✅ Controlled |

### Flows (May Need Manual Control)

| Flow                               | Trigger         | Impact During Load         | Recommendation                     |
| ---------------------------------- | --------------- | -------------------------- | ---------------------------------- |
| `Case_Succession_Contact_Cadence`  | Case After Save | Auto-creates tasks         | ⚠️ May need deactivation           |
| `Case_Multiple_Successors_Handler` | Case After Save | Creates parent/child cases | ✅ OK - needed for multi-successor |
| `Task_Succession_Contact_Update`   | Task After Save | Updates case fields        | ⚠️ May need deactivation           |

### Validation Rules

| Rule                               | Object           | Impact                                      | Recommendation                   |
| ---------------------------------- | ---------------- | ------------------------------------------- | -------------------------------- |
| `PrimaryAndJointOwnerCannotBeSame` | FinancialAccount | Blocks if JointOwner = PrimaryOwner         | ✅ Recipe sets JointOwner = null |
| `Next_Contact_Due_Required`        | Case             | Requires field when contact not established | ✅ Recipe includes field         |

---

## Migration from TestDataFactory

### TestDataFactory Approach

```apex
// TestDataFactory handled automation internally
Database.DMLOptions dml = new Database.DMLOptions();
dml.DuplicateRuleHeader.AllowSave = true;
Database.insert(record, dml);
```

### Snowfakery Approach

```yaml
# CumulusCI flow handles automation externally
flows:
  succession_test_setup:
    steps:
      1: disable_triggers
      2: load_data
      3: enable_triggers
```

**Advantage**: Centralized control, no code changes needed

---

## Validation Checklist

Before deploying to production:

- [ ] All triggers check `Apex_Trigger_Switch__mdt`
- [ ] Validation rules respect test context
- [ ] Flows have proper entry criteria
- [ ] CumulusCI flows include automation control
- [ ] Documentation updated
- [ ] Team trained on safe loading procedures
- [ ] Rollback plan documented

---

## Emergency Procedures

### If Data Load Fails Mid-Process

```bash
# 1. Stop the load (Ctrl+C)

# 2. Re-enable automation immediately
cci task run enable_triggers --org schwab-sandbox

# 3. Clean up partial data
cci task run delete_data \
  --objects Case,Task,FinServ__FinancialAccountRole__c,FinServ__FinancialAccount__c,Account \
  --where "LastName LIKE '%_Attempt%'" \
  --org schwab-sandbox

# 4. Verify automation enabled
cci task run run_soql_query \
  --query "SELECT DeveloperName, Active__c FROM Apex_Trigger_Switch__mdt WHERE Active__c = false" \
  --org schwab-sandbox

# 5. Retry with flow (includes automation control)
cci flow run succession_test_setup --org schwab-sandbox
```

### If Automation Stuck Disabled

```bash
# Force enable all triggers
cci task run enable_triggers --org schwab-sandbox

# Verify all enabled
cci task run run_soql_query \
  --query "SELECT COUNT() FROM Apex_Trigger_Switch__mdt WHERE Active__c = false" \
  --org schwab-sandbox

# Expected: 0
```

---

## Resources

- [CumulusCI Metadata Tasks](https://cumulusci.readthedocs.io/en/stable/tasks.html#metadata-tasks)
- [Salesforce Bulk API 2.0](https://developer.salesforce.com/docs/atlas.en-us.api_asynch.meta/api_asynch/)
- [Custom Metadata Types](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_custommetadata.htm)

---

**Document Version**: 1.0  
**Last Updated**: 2025-01-31  
**Maintained By**: Salesforce Architecture Team
