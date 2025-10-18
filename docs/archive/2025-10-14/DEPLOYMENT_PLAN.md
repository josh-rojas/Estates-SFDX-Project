# Succession Management System - Deployment Plan

**Target Org:** josh.rojas.charfsc@schwab.com.fscjosh (schwab-sandbox/fscjosh)  
**Date:** October 15, 2025  
**Version:** 1.0  

---

## 📋 Pre-Deployment Checklist

### Verify Prerequisites
- [x] Salesforce Financial Services Cloud enabled
- [x] System Administrator access
- [x] Salesforce CLI authenticated to target org
- [x] All tests passing locally (17/17 LWC, 6 Apex test classes)
- [x] No syntax errors in codebase
- [x] Manifest validated (185 lines, 10 metadata types)

### Backup & Safety
```bash
# 1. Take org snapshot (optional but recommended)
sf org snapshot create --name "Pre-Succession-Deploy-$(date +%Y%m%d)" \
  --source-org josh.rojas.charfsc@schwab.com.fscjosh

# 2. Verify no active deployments
sf project deploy report --target-org josh.rojas.charfsc@schwab.com.fscjosh
```

---

## 🚀 Deployment Steps

### Step 1: Validate Deployment (Dry Run)
**Duration:** ~5 minutes  
**Risk:** None (validation only)

```bash
cd "/Users/joshsmbp/Schwab Downloads/Estates SFDX Project"

# Validate with test execution
sf project deploy start \
  --manifest manifest/package.xml \
  --target-org josh.rojas.charfsc@schwab.com.fscjosh \
  --test-level RunLocalTests \
  --dry-run \
  --wait 30
```

**Success Criteria:**
- ✅ Status: "Succeeded"
- ✅ All Apex tests pass
- ✅ No deployment errors
- ✅ No conflicts reported

**If validation fails:** Review errors, fix issues, re-run validation

---

### Step 2: Deploy Metadata
**Duration:** ~10 minutes  
**Risk:** Low (no conflicts detected, isolated to Estate Administration)

```bash
# Execute deployment
sf project deploy start \
  --manifest manifest/package.xml \
  --target-org josh.rojas.charfsc@schwab.com.fscjosh \
  --wait 30
```

**Expected Output:**
```
Deployed Source
┌────────┬────────────────────────────────────┬──────┬───────────────────────┐
│ State  │ Name                               │ Type │ Path                  │
├────────┼────────────────────────────────────┼──────┼───────────────────────┤
│ Created│ CaseHierarchyController            │ Apex │ force-app/...         │
│ Created│ ContactCadenceController           │ Apex │ force-app/...         │
│ Created│ SuccessionPublicFormController     │ Apex │ force-app/...         │
│ Created│ successionContactCadence           │ LWC  │ force-app/...         │
│ Created│ Case_Assign_Pathway_Action_Plan    │ Flow │ force-app/...         │
│ ...    │ ...                                │ ...  │ ...                   │
└────────┴────────────────────────────────────┴──────┴───────────────────────┘

Status: Succeeded
```

**Monitor deployment:**
- Watch for "Status: Succeeded"
- Check for any warnings
- Verify component count matches manifest

---

## ⚙️ Post-Deployment Configuration

### Step 3: Assign Permission Sets
**Duration:** 2 minutes  
**Required for:** User access to components and fields

```bash
# Assign to your user
sf org assign permset \
  --name Succession_Management_Access \
  --target-org josh.rojas.charfsc@schwab.com.fscjosh

sf org assign permset \
  --name Succession_Field_Access \
  --target-org josh.rojas.charfsc@schwab.com.fscjosh

# Assign to other users as needed
# sf org assign permset --name Succession_Management_Access --on-behalf-of user@example.com
```

**Verify:**
- Setup → Users → [Your User] → Permission Set Assignments
- Confirm both permission sets listed

---

### Step 4: Configure Experience Cloud Site
**Duration:** 10 minutes  
**Required for:** Public form functionality

#### 4A. Publish Site
1. Setup → Digital Experiences → All Sites
2. Click **Succession Portal**
3. Click **Builder**
4. Add new page or edit homepage:
   - Component: `successionPublicForm`
   - Route: `/succession` (already configured)
5. Click **Publish**

#### 4B. Assign Guest User Permission Set
1. Setup → Digital Experiences → All Sites
2. Click **Succession Portal** → **Administration**
3. Click **Members** → **Guest User Profile**
4. Click **Assign Permission Sets**
5. Select: `Succession_Guest_Access`
6. Click **Save**

**Verify:**
- Visit: https://schwabcharitablefund--fscjosh.sandbox.my.site.com/succession
- Page loads without errors
- Form displays (may show error without valid caseId param - expected)

---

### Step 5: Verify Flow Activation
**Duration:** 2 minutes  
**All flows should be Active**

```bash
# Query flow status
sf data query \
  --query "SELECT DeveloperName, ProcessType, Status FROM FlowDefinitionView WHERE DeveloperName LIKE 'Case_%' OR DeveloperName LIKE 'Task_%' ORDER BY DeveloperName" \
  --target-org josh.rojas.charfsc@schwab.com.fscjosh \
  --result-format table
```

**Expected:** All 10 flows show `Status = Active`

---

### Step 6: Load Demo Test Data (Optional)
**Duration:** 5 minutes  
**Purpose:** Populate sandbox with succession scenarios

```bash
# Load comprehensive demo data
cci task run load_demo_ui_showcase

# OR load specific scenario
# cci task run load_final_grant_scenario
# cci task run load_multi_successor_scenario
```

---

## ✅ Validation & Testing

### Step 7: Smoke Test - End-to-End Workflow
**Duration:** 15 minutes

#### 7A. Create Test Case
1. Navigate to Service Console
2. Create new Case:
   - Record Type: **Estate Administration**
   - Type: **Named Successor Enactment**
   - Account: [Select Person Account with email]
3. Save

**Expected:**
- ✅ Flow `Case_Estate_Administration_Defaults` sets default values
- ✅ Flow `Case_Create_Initial_Contact_Attempt` creates Task #1 (Day 0)
- ✅ Task appears in related list

#### 7B. Test Contact Cadence
1. Navigate to Case → **Succession Management** tab
2. Component `successionContactCadence` loads
3. Click **Edit** on Attempt 1
4. Select **Yes** (Contact Established)
5. Add notes, click **Save**

**Expected:**
- ✅ Task status = Completed
- ✅ Case.Contact_Established__c = TRUE
- ✅ Chatter post created
- ✅ Email sent with form URL

#### 7C. Test Public Form
1. Check email (or manually navigate):
   - https://schwabcharitablefund--fscjosh.sandbox.my.site.com/succession?caseId=[CASE_ID]
2. Select pathway: **Final Grant**
3. Submit form

**Expected:**
- ✅ Case.Pathway_Confirmed__c = "Final Grant"
- ✅ Case.Form_Completed_Date__c = NOW
- ✅ Action Plan created automatically
- ✅ Chatter post on case

#### 7D. Test Multi-Successor (Optional)
1. Create Case with 2+ FinancialAccountRoles (Role=Successor)
2. Save

**Expected:**
- ✅ Parent case created (Type=Multi-Account Succession Master)
- ✅ Child cases created (1 per successor)
- ✅ View hierarchy in `caseHierarchyViewer` component

---

## 🔧 Troubleshooting

### Common Issues

#### Issue: Permission Set Assignment Fails
```
Error: No permission set with name Succession_Management_Access found
```
**Solution:** Verify deployment succeeded, check Setup → Permission Sets

#### Issue: Experience Site 404
```
Site not found
```
**Solution:**
- Setup → Digital Experiences → Succession Portal → **Activate**
- Verify subdomain: `schwabcharitablefund-succession`
- Verify URL path: `/succession`

#### Issue: Flow Not Triggering
**Check:**
1. Setup → Process Automation → Flows → [Flow Name]
2. Verify Status = **Active**
3. Check Debug Logs for flow execution

#### Issue: Action Plan Not Created
**Check:**
1. Action Plan Templates exist:
   - Setup → Action Plans → Templates
   - Verify: `Succession_Final_Grant_Pathway`, `Succession_New_DAF_Account_Pathway`, `Succession_Disclaim_Assets_Pathway`
2. Flow `Case_Assign_Pathway_Action_Plan` is Active
3. Case.Pathway_Confirmed__c matches template name exactly

---

## 📊 Post-Deployment Validation Checklist

- [ ] All 10 flows Active
- [ ] Permission sets deployed and assigned
- [ ] Experience site published and accessible
- [ ] Guest permission set assigned to site profile
- [ ] 3 Apex classes deployed with test classes
- [ ] 5 LWC components available
- [ ] 3 Action Plan templates exist
- [ ] Custom fields visible on Case layout
- [ ] Smoke test completed successfully
- [ ] Multi-successor scenario tested (optional)

---

## 🔄 Rollback Plan

### If deployment fails or issues arise:

#### Option 1: Quick Rollback (Deactivate Flows)
```bash
# Deactivate all succession flows
sf data update record \
  --sobject FlowDefinitionView \
  --record-id [FLOW_ID] \
  --values "Status=Draft" \
  --target-org josh.rojas.charfsc@schwab.com.fscjosh
```

#### Option 2: Full Rollback (Destructive Changes)
```bash
# Create destructive changes manifest
cat > destructiveChanges.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>CaseHierarchyController</members>
        <members>ContactCadenceController</members>
        <members>SuccessionPublicFormController</members>
        <name>ApexClass</name>
    </types>
    <types>
        <members>successionContactCadence</members>
        <members>successionPublicForm</members>
        <members>caseHierarchyViewer</members>
        <members>recordPathwaySelection</members>
        <members>successionAccountSummary</members>
        <name>LightningComponentBundle</name>
    </types>
    <types>
        <members>Case_Assign_Pathway_Action_Plan</members>
        <members>Case_Create_Initial_Contact_Attempt</members>
        <members>Case_Estate_Administration_Defaults</members>
        <members>Case_Multiple_Successors_Handler</members>
        <members>Case_Parent_Closure_Handler</members>
        <members>Case_Send_Succession_Form</members>
        <members>Case_Status_Coordination</members>
        <members>Case_Succession_Segment_Transition</members>
        <members>Task_Create_Next_Contact_Attempt</members>
        <members>Task_Succession_Contact_Update</members>
        <name>Flow</name>
    </types>
    <version>65.0</version>
</Package>
EOF

# Deploy destructive changes
sf project deploy start \
  --manifest destructiveChanges.xml \
  --target-org josh.rojas.charfsc@schwab.com.fscjosh
```

**Note:** Custom fields and Action Plan templates can remain (no impact if unused)

---

## 📞 Support Contacts

**Deployment Issues:**  
- Check Salesforce Debug Logs
- Review Flow Error Logs (Setup → Process Automation → Automation Home → Flow Errors)

**Questions:**  
- Review AGENTS.md for architecture details
- Check docs/EMAIL_TO_CASE_SETUP.md for Service Cloud config

---

## 🎯 Success Metrics

**Deployment successful if:**
- ✅ 3 Apex classes deployed (0 errors)
- ✅ 5 LWC components available
- ✅ 10 flows Active
- ✅ Experience site loads
- ✅ Contact cadence UI functional
- ✅ Public form submits pathway selection
- ✅ Action Plans auto-created on pathway selection

**Total Deployment Time:** ~40 minutes (including testing)
