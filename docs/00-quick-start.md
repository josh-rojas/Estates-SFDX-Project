# Quick Start Guide

**Last Updated:** November 2, 2025  
**Version:** 1.0

---

## Overview

This guide will help you get the Succession Management System up and running in under 30 minutes. Follow these steps to deploy, configure, and test the system.

---

## Prerequisites

Before you begin, ensure you have:

- ✅ Salesforce org with Financial Services Cloud enabled
- ✅ Salesforce CLI installed (`sf` command)
- ✅ Git installed
- ✅ Admin access to target org

---

## 5-Minute Setup

### Step 1: Clone Repository

```bash
git clone https://github.com/josh-rojas/Estates-SFDX-Project.git
cd Estates-SFDX-Project
```

### Step 2: Authenticate to Org

```bash
# Authenticate via web browser
sf org login web --alias succession-org --set-default

# Verify authentication
sf org display
```

### Step 3: Deploy Metadata

```bash
# Deploy all metadata
sf project deploy start --target-org succession-org

# This will deploy:
# - 8 Apex classes + 8 test classes
# - 1 Apex trigger
# - 5 Lightning Web Components
# - 5 Flows (Inactive)
# - 3 Permission Sets
# - Custom fields on Case, Task, Account, FinancialAccountRole
# - Email templates
# - Quick Actions
```

### Step 4: Assign Permission Sets

```bash
# Assign to yourself
sf org assign permset --name Succession_Management_Access --target-org succession-org
sf org assign permset --name Succession_Field_Access --target-org succession-org
```

### Step 5: Open Org and Test

```bash
# Open org in browser
sf org open --target-org succession-org
```

**You're ready to go!** 🎉

---

## End-to-End Test Scenario

### Scenario: Single Successor - Final Grant Pathway

**Time:** 10 minutes

#### 1. Create Person Accounts

**Deceased Donor:**
1. Navigate to **Accounts** tab
2. Click **New**
3. Select **Person Account** record type
4. Fill in:
   - First Name: `John`
   - Last Name: `Donor`
   - Email: `john.donor@example.com`
   - Deceased: ✅ (checked)
   - Date of Death: `(today - 30 days)`
5. **Save**

**Successor:**
1. Navigate to **Accounts** tab
2. Click **New**
3. Select **Person Account** record type
4. Fill in:
   - First Name: `Jane`
   - Last Name: `Successor`
   - Email: `jane.successor@example.com`
5. **Save**

#### 2. Create Financial Account

1. Navigate to **Financial Accounts** tab
2. Click **New**
3. Fill in:
   - Name: `Donor Charitable Fund`
   - Primary Owner: `John Donor` (deceased account)
   - Status: `Active`
   - Balance: `$100,000`
4. **Save**

#### 3. Create Financial Account Role (Successor)

1. Open **Donor Charitable Fund** record
2. Navigate to **Financial Account Roles** related list
3. Click **New**
4. Fill in:
   - Financial Account: (auto-populated)
   - Related Contact: `Jane Successor` (contact)
   - Role: `Successor`
   - Active: ✅ (checked)
   - Successor Allocation %: `100`
5. **Save**

#### 4. Create Succession Case

1. Open **Donor Charitable Fund** record
2. Click **Create Succession Case** Quick Action (top right)
3. Select successor: `Jane Successor`
4. Click **Create**
5. **Verify:**
   - Case created with Record Type: `Estate Administration`
   - Type: `Named Successor Enactment`
   - Status: `New`
   - Contact: `Jane Successor`

#### 5. Complete Contact Cadence

1. Open the newly created Case
2. Scroll to **Succession Contact Cadence** component
3. Click **Complete** on "Contact Attempt #1"
4. Select outcome: `Contact Established`
5. Check **Contact Established** checkbox
6. Click **Save**
7. **Verify:**
   - Contact_Established__c = `true` on Case
   - Status changed to `Awaiting Response`
   - Remaining contact attempts disabled (circuit breaker)

#### 6. Select Pathway

1. On the Case record, click **Record Pathway Selection** Quick Action
2. Select pathway: `Final Grant`
3. Click **Save**
4. **Verify:**
   - Pathway_Confirmed__c = `Final Grant` on Case
   - **5 pathway tasks created automatically** (trigger-based automation)
   - Tasks visible in Tasks related list:
     - Day 2: Review grant request
     - Day 5: Verify beneficiaries
     - Day 10: Process grant paperwork
     - Day 15: Coordinate with finance
     - Day 20: Finalize grant distribution
   - Chatter post: "Pathway tasks created for Final Grant"

#### 7. Complete Pathway Tasks

1. Navigate to **Tasks** related list
2. Complete each task:
   - Click task → Change Status to `Completed` → Save
3. After all tasks completed:
   - Set Execution_Status__c = `Completed`
   - Set Status = `Closed`
4. **Verify:**
   - All pathway tasks completed
   - Case Status = `Closed`
   - Execution_Completed_Date__c populated

**✅ Test Complete!** You've successfully tested the end-to-end succession workflow.

---

## Key Components to Explore

### 1. Succession Contact Cadence (LWC)

**Location:** Case record page → Succession Contact Cadence component

**Features:**
- 5 contact attempts (Days 0, 5, 35, 65, 95)
- Sequential unlock pattern
- Date-gating (can't complete until ActivityDate)
- Progress visualization
- Circuit breaker (stops when contact established)

**Try:**
- Complete contact attempts in sequence
- Try to complete future attempts (should be disabled)
- Mark contact established (should disable remaining attempts)

### 2. Record Pathway Selection (Quick Action)

**Location:** Case record page → Quick Actions → Record Pathway Selection

**Features:**
- Pathway dropdown (Final Grant, New DAF, Disclaim)
- **Triggers automation** when saved
- Sets Pathway_Confirmed__c field

**Try:**
- Select different pathways
- Observe different task templates created

### 3. Case Hierarchy Viewer (LWC)

**Location:** Case record page → Case Hierarchy component (multi-successor cases only)

**Features:**
- Tree visualization of parent-child cases
- Status indicators
- Successor allocation percentages

**Try:**
- Create multi-successor case (2+ successors)
- View hierarchy on parent case

### 4. Succession Public Form (Guest User)

**Location:** Experience Cloud site (requires setup)

**Features:**
- Public-facing pathway selection form
- Token-based authentication
- Mobile-responsive

**Note:** Requires Experience Cloud site configuration (not covered in quick start)

---

## Understanding the Automation

### Trigger-Based Automation

**Primary Mechanism:**
```
User sets Pathway_Confirmed__c
    ↓
SuccessionCaseTrigger fires (after update)
    ↓
SuccessionTaskGenerator.createPathwayTasks()
    ↓
4-5 pathway tasks created (SYSTEM_MODE)
    ↓
Chatter notification posted
```

**Key Files:**
- Trigger: `force-app/main/default/triggers/SuccessionCaseTrigger.trigger`
- Generator: `force-app/main/default/classes/SuccessionTaskGenerator.cls`

**Why SYSTEM_MODE?**
- Guest users (successors) cannot create Tasks directly
- Automation must work regardless of user permissions
- Tasks are system-generated, not user-created

### Inactive Flows

**5 flows exist but are Inactive:**
- Succession_Start_Contact_Process
- Succession_Schedule_Next_Contact
- Succession_Mark_Contact_Established
- Succession_Close_Multi_Successor_Parent
- Succession_Update_Case_Status_And_Notify

**Why Inactive?**
- System migrated to trigger-based automation
- Flows retained for reference
- Primary automation is more reliable and performant

---

## Multi-Successor Scenario

### Test Multi-Successor Case

**Time:** 15 minutes

#### 1. Create Additional Successor

1. Navigate to **Accounts** tab
2. Create another Person Account:
   - First Name: `Bob`
   - Last Name: `Successor`
   - Email: `bob.successor@example.com`
3. **Save**

#### 2. Add Second Financial Account Role

1. Open **Donor Charitable Fund** record
2. Navigate to **Financial Account Roles** related list
3. Click **New**
4. Fill in:
   - Related Contact: `Bob Successor`
   - Role: `Successor`
   - Active: ✅
   - Successor Allocation %: `50`
5. **Save**
6. Update Jane Successor's allocation to `50`

#### 3. Create Multi-Successor Case

1. Open **Donor Charitable Fund** record
2. Click **Create Succession Case** Quick Action
3. Select both successors: `Jane Successor`, `Bob Successor`
4. Click **Create**
5. **Verify:**
   - **Parent case** created (Type: "Multi-Account Succession Master")
   - **2 child cases** created (one per successor)
   - Child cases linked to parent via ParentId
   - Each child case has Contact = respective successor

#### 4. View Case Hierarchy

1. Open parent case
2. Scroll to **Case Hierarchy** component
3. **Verify:**
   - Tree shows parent at top
   - 2 child cases below
   - Allocation percentages (50% each)
   - Status indicators for each case

#### 5. Complete Child Cases

1. Complete workflow for each child case:
   - Contact cadence
   - Pathway selection
   - Pathway tasks
   - Close case
2. **Verify:**
   - When all child cases closed, parent case should be manually closed
   - (Auto-closure flow is inactive)

---

## Common Issues & Solutions

### Issue: Pathway Tasks Not Created

**Symptom:** Selected pathway but no tasks created

**Solution:**
1. Verify trigger is active: Setup → Apex Triggers → SuccessionCaseTrigger
2. Check debug logs: `sf apex log tail --target-org succession-org`
3. Verify Pathway_Confirmed__c field changed from null to value
4. Check user has permission to view Tasks

### Issue: Contact Cadence Not Showing

**Symptom:** Succession Contact Cadence component is blank

**Solution:**
1. Verify component added to page layout: Setup → Object Manager → Case → Lightning Record Pages
2. Check user has Succession_Management_Access permission set
3. Verify contact attempt tasks exist on Case

### Issue: Quick Actions Not Visible

**Symptom:** Create Succession Case or Record Pathway Selection not showing

**Solution:**
1. Add Quick Actions to page layout: Setup → Object Manager → Case → Page Layouts → Estate Administration Layout
2. Verify user has access to LWC components
3. Clear browser cache and reload

---

## Next Steps

### Learn More

1. **Architecture:** Read `docs/01-architecture-automation-data.md` for detailed system architecture
2. **Components:** Read `docs/02-components.md` for LWC and Apex class details
3. **Security:** Read `docs/03-security.md` for permission sets and security model
4. **Deployment:** Read `docs/04-deployment-ci.md` for advanced deployment options
5. **Admin Guide:** Read `docs/05-runbook.md` for troubleshooting and maintenance

### Customize

1. **Email Templates:** Setup → Email Templates → Succession_Management folder
2. **Page Layouts:** Setup → Object Manager → Case → Page Layouts
3. **Sharing Rules:** Setup → Sharing Settings → Case Sharing Rules
4. **Workflows:** Activate flows if needed (Setup → Flows)

### Extend

1. **Add Custom Fields:** Extend Case or Task with additional fields
2. **Create Reports:** Build dashboards for SLA tracking and metrics
3. **Integrate:** Connect with external systems via APIs
4. **Automate:** Build additional flows or triggers for custom logic

---

## Support

### Getting Help

**Documentation:**
- Architecture: `docs/01-architecture-automation-data.md`
- Components: `docs/02-components.md`
- Security: `docs/03-security.md`
- Deployment: `docs/04-deployment-ci.md`
- Runbook: `docs/05-runbook.md`

**Troubleshooting:**
- Check debug logs: `sf apex log tail`
- Review flow errors: Setup → Flows → Flow Errors tab
- Test Apex: `sf apex run test --test-level RunLocalTests`

**Community:**
- GitHub Issues: https://github.com/josh-rojas/Estates-SFDX-Project/issues
- Salesforce Trailblazer Community

---

**Document Status:** Last verified November 2, 2025 | Commit: [current]
