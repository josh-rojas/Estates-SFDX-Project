# Destructive Changes: Remove Analytics Components

**Date**: October 4, 2025  
**Target Org**: schwab-sandbox  
**Purpose**: Remove analytics and reporting components from the org

---

## Components to be Removed

### 1. **Apex Classes** (3 classes)

- `SuccessionProcessingEngineBatch` - Batch processing for succession tasks
- `SuccessionProcessingEngineScheduler` - Scheduler for batch automation
- `SuccessionWorkflow_Snowfakery_Test` - Test class for Snowfakery workflows

### 2. **Batch Calculation Job Definitions** (1 definition)

- `SuccessionSLACalculation` - SLA monitoring calculations

### 3. **Batch Calculation View Definitions** (7 definitions)

- `SuccessionActiveCases`
- `SuccessionAwaitingForm`
- `SuccessionContactNotEstablished`
- `SuccessionMultiSuccessorMaster`
- `SuccessionPathwayMetrics`
- `SuccessionSLAAtRisk`
- `SuccessionVerificationPending`

### 4. **List Views** (20 list views)

**Pathway-specific views:**

- Case.Succession_Final_Grant
- Case.Succession_Final_Grant_Pathway
- Case.Succession_New_DAF
- Case.Succession_New_DAF_Pathway
- Case.Succession_Disclaim
- Case.Succession_Disclaim_Pathway

**Phase-based views:**

- Case.Succession_Awaiting_Contact
- Case.Succession_Awaiting_Form
- Case.Succession_Form_Pending
- Case.Succession_Form_Completed
- Case.Succession_Documentation_Pending
- Case.Succession_Pending_Contact

**SLA monitoring views:**

- Case.Succession_SLA_At_Risk
- Case.Succession_SLA_Critical
- Case.Succession_SLA_Needs_Attention

**Multi-successor views:**

- Case.Succession_Multi_Successor
- Case.Succession_Multi_Successor_Master

**Operational views:**

- Case.Succession_My_Cases
- Case.Succession_Needs_Review
- Case.Succession_Ready_For_Execution

### 5. **Reports** (11 reports)

- Succession_At_Risk_Cases
- Succession_Awaiting_Form_Cases
- Succession_Critical_Cases
- Succession_Disclaim_Pathway
- Succession_Final_Grant_Pathway
- Succession_Form_Completed_Cases
- Succession_Multi_Successor_Cases
- Succession_Needs_Attention_Cases
- Succession_New_DAF_Pathway
- Succession_Pending_Contact_Cases
- Succession_Processing_Engine_Overview

### 6. **Report Folder** (1 folder)

- Succession_Management_Reports

---

## Total Components to Remove

- **Apex Classes**: 3
- **Batch Calc Job Defs**: 1
- **Batch Calc View Defs**: 7
- **List Views**: 20
- **Reports**: 11
- **Report Folders**: 1
- **TOTAL**: 43 components

---

## Deployment Command

```bash
# Navigate to project directory
cd "/Users/joshsmbp/Schwab Downloads/Estates SFDX Project"

# Deploy destructive changes (VALIDATE FIRST)
sf project deploy validate \
  --manifest manifest/package-empty.xml \
  --pre-destructive-changes manifest/destructiveChanges-analytics.xml \
  --target-org schwab-sandbox

# If validation succeeds, deploy
sf project deploy start \
  --manifest manifest/package-empty.xml \
  --pre-destructive-changes manifest/destructiveChanges-analytics.xml \
  --target-org schwab-sandbox
```

---

## Impact Analysis

### ⚠️ **CRITICAL WARNINGS**

1. **Batch Processing Removed**
   - No automated task creation will occur
   - SLA monitoring calculations will stop
   - Need manual task management

2. **Reports & Dashboards**
   - All succession analytics will be unavailable
   - Executive dashboards may break if they reference these reports
   - Users won't have visibility into succession metrics

3. **List Views Removed**
   - Users will need to create custom filters manually
   - No quick access to pathway-specific or SLA-based case views
   - Operations team loses tracking capabilities

### ✅ **What Will Remain**

- Core succession workflows (contact cadence flows)
- Case fields and validation rules
- Test data factory
- Email templates
- Multi-successor handler flow
- Permission sets
- Core automation flows

### 🔄 **Rollback Plan**

If you need to restore these components:

```bash
# Restore from commits 6, 9, and 10
git checkout Claude-Succession-Branch

# Deploy batch processing
sf project deploy start --source-dir force-app/main/default/classes/SuccessionProcessingEngine* --target-org schwab-sandbox

# Deploy list views
sf project deploy start --manifest manifest/package-new-list-views.xml --target-org schwab-sandbox

# Deploy reports
sf project deploy start --source-dir force-app/main/default/reports/Succession_Management_Reports/ --target-org schwab-sandbox
```

---

## Pre-Deployment Checklist

- [ ] Verify no scheduled jobs are running (SuccessionProcessingEngineScheduler)
- [ ] Check if any dashboards reference these reports
- [ ] Notify operations team of list view removal
- [ ] Document any custom views users have created based on these
- [ ] Backup report configurations if needed
- [ ] Test deployment in sandbox first (already in sandbox ✓)

---

## Post-Deployment Actions

1. **Verify Removal**:

   ```bash
   # Check Apex classes removed
   sf data query --query "SELECT Id, Name FROM ApexClass WHERE Name LIKE 'SuccessionProcessing%'" --target-org schwab-sandbox --use-tooling-api

   # Check reports removed
   sf data query --query "SELECT Id, Name FROM Report WHERE Name LIKE 'Succession%'" --target-org schwab-sandbox
   ```

2. **Clean up local files** (optional):
   ```bash
   # Remove from source control
   git rm -r force-app/main/default/batchCalc*
   git rm force-app/main/default/classes/SuccessionProcessingEngine*
   git rm -r force-app/main/default/objects/Case/listViews/Succession_*
   git rm -r force-app/main/default/reports/Succession_Management_Reports/
   git commit -m "chore: remove analytics components from source after org deletion"
   ```

---

## Questions?

Contact the development team before proceeding with this destructive deployment.

**Last Updated**: October 4, 2025  
**Prepared By**: Claude Code  
**Status**: Ready for validation deployment
