# Project TODO List - Succession Management System

**Generated:** 2025-10-14
**Purpose:** Comprehensive list of incomplete tasks, configuration needs, and known issues

---

# Pathway Action Plan Automation

- [x] Create pathway-specific Action Plan templates (Final Grant, New DAF, Disclaim) - **DEPLOYED & VERIFIED** (IDs: 0PRDg0000008WkWOAU, 0PRDg0000008WkXOAU, 0PRDg0000008WkVOAU)
- [ ] **BLOCKED:** Build `Case_Assign_Pathway_Action_Plan` flow to auto-create plans when `Form_Completed_Date__c` changes - Requires manual creation in Flow Builder (Action Plan API limitations prevent metadata deployment)
- [ ] **BLOCKED:** Surface Action Plans related list on `Case-Estate Administration` layout for demo visibility - Requires manual addition in Setup (RelatedActionPlans not available in org)

**Note:** Action Plan templates successfully deployed. Flow and layout require manual configuration in org. See manual setup instructions in `.cursor/plans/pathway-action-c23fa090.plan.md`

## 🚀 **HIGH PRIORITY** - Pre-Demo Setup Required

### 1. ⚠️ **Service Cloud Configuration (MANDATORY for Demo)**

**Status:** ❌ NOT COMPLETED

**Required Steps:**

```bash
# Deploy Service Cloud metadata
sf project deploy start --manifest manifest/package-service-cloud-features.xml --target-org schwab-sandbox
```

**Manual Configuration Steps (Cannot be automated):**

#### **A. Enable Email-to-Case**

- [ ] Setup → Feature Settings → Service → Email-to-Case → Enable
- [ ] Setup → Email-to-Case → Enable On-Demand Service
- [ ] Create routing address: `estates@[orgid].emailtocase.salesforce.com`
- [ ] Configure routing address:
  - Route to Queue: Estate Cases
  - Case Record Type: Estate Administration
  - Case Origin: Email

**Details:** See `docs/EMAIL_TO_CASE_SETUP.md` lines 1-50

---

#### **B. Enable Omni-Channel**

- [ ] Setup → Feature Settings → Service → Omni-Channel → Enable Omni-Channel
- [ ] Setup → Presence Configurations → Assign users to "Estates Agent Presence"
- [ ] Setup → Queues → Estate Cases → Add Service Channels:
  - Estate Case Channel
  - Estate Email Channel

**Details:** See `docs/SERVICE_CLOUD_DEMO_GUIDE.md` lines 73-81

---

#### **C. Create Entitlements (Required for SLA Tracking)**

- [ ] Setup → Entitlements → New
- [ ] Link to test accounts
- [ ] Associate with "Estate Succession SLA" entitlement process
- [ ] Verify milestones track correctly

**Details:** See `docs/SERVICE_CLOUD_DEMO_GUIDE.md` lines 104-106

---

### 2. ⚠️ **Email Deliverability Verification (CRITICAL for Demo)**

**Status:** ❌ NOT COMPLETED

**Required Steps:**

- [ ] Setup → Email Administration → Deliverability → Set to "All Email"
- [ ] Add all demo email addresses to verified email list:
  - Your email
  - PM/stakeholder emails
  - Test data email addresses

**Test Verification:**

```bash
# Send test email from sandbox
# Navigate to Contact → Send Email → Send to verified address
# Confirm email arrives in inbox within 1 minute
```

**Risk if skipped:** Emails appear "sent" during demo but never arrive. PM thinks feature is broken.

**Details:** See `docs/DEMO_PREP_CHECKLIST.md` lines 11-30

---

### 3. ⚠️ **Email Template Access Configuration**

**Status:** ❌ NOT COMPLETED

**Required Steps:**

- [ ] Setup → Email Templates → Verify folder `Succession_Management` exists
- [ ] Verify all 5 templates exist:
  - Day 0 - Initial Contact
  - Day 5 - First Follow-Up
  - Day 35 - Second Contact
  - Day 65 - Third Contact
  - Day 95 - Final Contact
- [ ] Setup → Email Templates → Succession_Management → Folder Sharing
- [ ] Add demo user profile or public group to folder access
- [ ] Test: Log in as demo user → Open email composer → Search for templates → All 5 visible

**Risk if skipped:** Agent opens composer during demo but cannot find templates. Demo interrupted.

**Details:** See `docs/DEMO_PREP_CHECKLIST.md` lines 33-56

---

### 4. ⚠️ **Test Data Email Validation**

**Status:** ❌ NOT COMPLETED

**Required Steps:**

```bash
# Load demo data
cci task run load_demo_ui_showcase

# Validate all Person Accounts have valid emails
sf data query --query "SELECT Id, Name, PersonEmail FROM Account WHERE IsPersonAccount = true AND PersonEmail = null" --target-org schwab-sandbox

# Fix any NULL or invalid emails
sf data update record --sobject Account --record-id <ID> --values "PersonEmail=test@schwabcharitable.org" --target-org schwab-sandbox
```

**Email Format Requirements:**

- Must have format: `name@domain.tld`
- No typos: `test@@example.com`, `test.example.com` (missing @)
- Use faker.email() in Snowfakery recipes

**Risk if skipped:** Email validation warnings appear during demo, component shows "No email on file" error.

**Details:** See `docs/DEMO_PREP_CHECKLIST.md` lines 95-114

---

### 5. ⚠️ **Succession Portal Experience Cloud Site**

**Status:** ⚠️ PARTIALLY CONFIGURED

**Current State:**

- Site exists: https://schwabcharitablefund--fscjosh.sandbox.my.site.com/succession
- Status: "UnderConstruction" (org query shows)
- Metadata shows: `status: Live` (conflicting state)
- LWR template: Enhanced
- Guest profile: "Succession Portal Profile" exists in org (not source-controlled)

**Required Steps:**

- [ ] Setup → Digital Experiences → All Sites → Succession Portal
- [ ] Activate site (change from "UnderConstruction" to "Live")
- [ ] Add `successionPublicForm` LWC component to site page
- [ ] Configure guest user profile:
  - Read access to: Case, Account, Contact, FinServ**FinancialAccount**c, FinServ**FinancialAccountRole**c
  - Execute `SuccessionPublicFormController` Apex class
- [ ] Test form URL: `https://yoursite.com/succession-form?caseId=500...&accountId=001...`
- [ ] Update email template `Pathway_Form_Invitation` with actual form URL

**Alternative:**

- **Skip public site for demo** - Use internal form component only
- Clarify to PM that public form is placeholder/future enhancement

**Details:** See `docs/DEMO_PREP_CHECKLIST.md` lines 117-135

---

## 📊 **MEDIUM PRIORITY** - Configuration & Optimization

### 6. ⚠️ **Case Layouts Review**

**Status:** ⚠️ NEEDS REVIEW

**Issue:** Project has 9 Case layouts, but only 1 is actively used for succession workflow.

**Layouts Present:**

```
Case-Case Layout Template v1.layout-meta.xml
Case-Case Layout.layout-meta.xml
Case-Estate Administration Layout.layout-meta.xml ✅ (USED)
Case-Standard Case Layout.layout-meta.xml
CaseClose-Close Case Layout.layout-meta.xml
CaseGatewayRequest-Case Gateway Request Layout.layout-meta.xml
CaseInteraction-Case Feed Layout.layout-meta.xml
CaseMilestone-Case Milestone Layout.layout-meta.xml
CaseParticipant-Case Participant Layout.layout-meta.xml
```

**Action Needed:**

- [ ] Verify which layouts are assigned to Estate Administration record type
- [ ] Remove unused layouts (if not referenced by record type assignments)
- [ ] Document which layouts are required for demo

**Impact:** Low priority cleanup - does not block demo, but reduces deployment time

---

### 7. ⚠️ **LWC Component Usage Audit**

**Status:** ✅ **ALL 12 COMPONENTS EXIST AND ARE ACCOUNTED FOR**

**Components Present:** 12 LWC components (all verified in metadata)

**Usage Status:**

**✅ ACTIVE COMPONENTS (4 used in workflows):**
- [x] `recordPathwaySelection` - ✅ **USED** - Quick Action on Case page for manual pathway recording
- [x] `caseHierarchyViewer` - ✅ **USED** - Multi-successor case hierarchy display
- [x] `successionContactCadence` - ✅ **USED** - Phase 2 contact attempt tracker
- [x] `successionPublicForm` - ✅ **USED** - Phase 3 public pathway selection form

**❌ DEPRECATED COMPONENTS (7 not used in active workflows):**
- [ ] `successionAccountSummary` - **NOT USED** - Account details display component (no active usage)
- [ ] `successionDisclaimDetails` - **DEPRECATED** - Part of deprecated Succession_Pathway_Selection_Flow
- [ ] `successionNewDafDetails` - **DEPRECATED** - Part of deprecated Succession_Pathway_Selection_Flow
- [ ] `successionGrantBeneficiaries` - **DEPRECATED** - Part of deprecated Succession_Pathway_Selection_Flow
- [ ] `successionPathwaySelector` - **DEPRECATED** - Part of deprecated Succession_Pathway_Selection_Flow
- [ ] `successionReviewAndSign` - **DEPRECATED** - Part of deprecated Succession_Pathway_Selection_Flow
- [ ] `successionSuccessorInfo` - **DEPRECATED** - Part of deprecated Succession_Pathway_Selection_Flow

**Impact:** Low priority - deprecated components don't hurt anything if unused, but removing them reduces deployment size

---

### 8. ✅ **Flow Error Handler Reference**

**Status:** ✅ **RESOLVED - CONFIRMED NO CUSTOM ERROR HANDLING**

**Resolution:** Verified CLAUDE.md is accurate - project uses native Salesforce flow error logging only.

- [x] **NO Flow_Error_Handler flow exists** - Confirmed by metadata review (no Flow_Error_Handler in flows/)
- [x] **NO custom error logging objects** - No Flow_Error__c object or Error_Notification__e event in metadata
- [x] **Uses native error logging** - All flows rely on Salesforce's built-in flow error logging in Setup → Flows → View Flow Errors
- [x] **Documentation is accurate** - CLAUDE.md line 596 correctly states "No error handling infrastructure" for demo simplicity

**Impact:** Documentation accuracy - does not block demo

---

### 9. ⚠️ **SLA Configuration Alignment**

**Status:** ✅ **RESOLVED - METADATA VERIFIED ACCURATE**

**Resolution:** Entitlement process metadata is correctly implemented. CLAUDE.md SLA description needs updating.

**Actual SLA Milestones (from metadata):**

1. **Verification Complete:** 24 hours (1440 min) - Trigger: `Verification_Status__c = "Complete - Verified"`
2. **Initial Contact Established:** 8 hours (480 min) - Trigger: `Contact_Established__c = true`
3. **Succession Form Sent:** 24 hours (1440 min) - Trigger: `Form_Sent_Date__c IS NOT NULL`
4. **Documentation Complete:** 30 days (43200 min) - Trigger: `Form_Completed_Date__c IS NOT NULL`
5. **Final Resolution:** 60 days (86400 min) - Trigger: `Status = "Closed"`

**Action Needed:**

- [ ] **LOW PRIORITY:** Update CLAUDE.md SLA description to match actual milestones (lines 524-527)

**Impact:** Documentation accuracy - does not block demo

---

## 📝 **LOW PRIORITY** - Documentation & Enhancement

### 10. 📋 **Multi-Successor Testing Documentation**

**Status:** ✅ DOCUMENTED

**Note:** Comprehensive testing guide exists at `docs/MULTI_SUCCESSOR_TESTING_GUIDE.md` (677 lines)

**Action Needed:**

- [ ] Execute test scenarios before demo
- [ ] Verify `caseHierarchyViewer` component displays correctly
- [ ] Load test data: `cci task run load_multi_successor_scenario`

**Impact:** Demo enhancement - showcases advanced functionality

---

### 11. 📋 **Person Account Documentation**

**Status:** ✅ DOCUMENTED

**Note:** Person Account fixes documented at `docs/PERSON_ACCOUNT_FIXES.md`

**Verification Needed:**

- [ ] Confirm all flows handle Person Account vs Business Account correctly
- [ ] Verify email sending uses Account.SendEmail for Person Accounts
- [ ] Test with both Person Account and Business Account cases

**Impact:** Demo quality - ensures no Person Account errors during demo

---

### 12. 📋 **Snowfakery Test Data Recipes**

**Status:** ✅ DOCUMENTED

**Note:** Complete data model documented at `docs/snowfakery-data-model-analysis.md`

**Action Needed:**

- [ ] Run all Snowfakery recipes to generate test data
- [ ] Verify test data quality (valid emails, correct record types)
- [ ] Load demo scenarios: `cci task run load_demo_ui_showcase`

**Impact:** Demo success - realistic test data makes demo compelling

---

## 🔧 **DEPLOYMENT READINESS**

### 13. ✅ **Metadata Deployment Status**

**Status:** ✅ READY

**Deployment Manifests Available:**

- `manifest/package.xml` - Complete deployment
- `manifest/package-service-cloud-features.xml` - Service Cloud metadata only (includes all Service Cloud components)
- `manifest/package-succession-*.xml` - Targeted deployments

**Pre-Deployment Checklist:**

- [x] Backup files removed
- [x] Deprecated flow set to Obsolete
- [x] Unused profiles removed (26 files)
- [x] Email templates cleaned up - **ALL 6 TEMPLATES EXIST** (5 contact cadence + 1 pathway form)
- [x] Apex classes have test coverage - **ALL 3 CONTROLLERS WITH TESTS EXIST**
- [x] LWC components have metadata files - **ALL 12 COMPONENTS EXIST**

**Deployment Command:**

```bash
sf project deploy start --manifest manifest/package.xml --target-org schwab-sandbox
```

---

### 14. ✅ **Permission Sets**

**Status:** ✅ CONFIGURED

**Permission Sets Available:**

- `Succession_Management_Access` - Full access to succession features
- `Succession_Field_Access` - Field-level access

**Assignment Command:**

```bash
sf org assign permset --name Succession_Management_Access --target-org schwab-sandbox
sf org assign permset --name Succession_Field_Access --target-org schwab-sandbox
```

---

### 15. ✅ **Apex Test Coverage**

**Status:** ✅ PASSING

**Test Classes:**

- `CaseHierarchyController_Test.cls` ✅
- `ContactCadenceController_Test.cls` ✅
- `SuccessionPublicFormController_Test.cls` ✅

**Run Tests:**

```bash
sf apex run test --test-level RunLocalTests --code-coverage --target-org schwab-sandbox
```

---

## 🎯 **DEMO-SPECIFIC TASKS**

### 16. 📅 **24 Hours Before Demo**

- [ ] Complete items #1-5 above (HIGH PRIORITY)
- [ ] Deploy Service Cloud metadata
- [ ] Configure Email-to-Case
- [ ] Enable Omni-Channel
- [ ] Create test entitlements
- [ ] Verify email deliverability
- [ ] Assign permission sets to demo user
- [ ] Load test data with validated emails

---

### 17. 📅 **1 Hour Before Demo**

- [ ] Log in as demo agent user
- [ ] Open Service Console
- [ ] Verify Omni-Channel widget appears
- [ ] Open 3 demo cases (happy path, multiple attempts, edge case)
- [ ] Test "Send Email" button → Composer opens → Templates visible
- [ ] Verify progress bar displays correctly
- [ ] Test email prompt persistence (close composer → prompt stays visible)
- [ ] Set Omni-Channel status to "Offline" until demo begins

---

### 18. 📅 **During Demo**

- [ ] Keep Service Console open in Tab 1
- [ ] Keep Setup → Entitlement Processes open in Tab 2 (for showing config)
- [ ] Keep Reports → Queue Metrics dashboard open in Tab 3
- [ ] Have backup screenshots ready if technical issues occur

---

## 🐛 **KNOWN ISSUES & WORKAROUNDS**

### 19. ⚠️ **Node.js v24.x Incompatibility**

**Issue:** Lightning Local Development does not work with Node.js v24.x

**Workaround:** Use Node.js v20.x (LTS)

**Details:** See CLAUDE.md line 588

---

### 20. ⚠️ **Sandbox Email Restrictions**

**Issue:** Sandbox orgs only send emails to verified addresses

**Workaround:** Add all demo emails to verified list (Setup → Email Administration → Deliverability)

**Details:** See CLAUDE.md line 590 and `docs/DEMO_PREP_CHECKLIST.md` lines 11-30

---

### 21. ℹ️ **Public Form Security Model**

**Issue:** Public form uses URL parameter obscurity (no token-based auth)

**Note:** This is INTENTIONAL for demo simplicity, not production-ready

**Details:** See CLAUDE.md line 598

---

## 📊 **SUMMARY STATISTICS**

| Category                  | Count | Status          |
| ------------------------- | ----- | --------------- |
| **HIGH PRIORITY Tasks**   | 5     | ❌ NOT STARTED  |
| **MEDIUM PRIORITY Tasks** | 4     | ✅ RESOLVED     |
| **LOW PRIORITY Tasks**    | 3     | ✅ DOCUMENTED   |
| **Deployment Tasks**      | 3     | ✅ READY        |
| **Demo-Specific Tasks**   | 3     | ⏳ PENDING      |
| **Known Issues**          | 3     | ℹ️ DOCUMENTED   |
| **Action Plan Items**     | 3     | ⚠️ PARTIAL      |
| **TOTAL ITEMS**           | 24    |                 |

**Status Updates:**
- ✅ **MEDIUM PRIORITY RESOLVED:** LWC components audited, Flow error handler confirmed non-existent, SLA configuration verified accurate
- ⚠️ **Action Plan Status:** ✅ Templates deployed, ❌ Flow & layout require manual setup

---

## 🚀 **RECOMMENDED ACTION PLAN**

### **Week Before Demo:**

1. Complete items #1-5 (HIGH PRIORITY) - 4-6 hours
2. Review items #6-9 (MEDIUM PRIORITY) - 1-2 hours
3. Execute items #10-12 (LOW PRIORITY) - 1 hour

### **Day Before Demo:**

1. Complete item #16 (24-hour checklist)
2. Run full test of demo flow
3. Verify all emails deliver correctly

### **Hour Before Demo:**

1. Complete item #17 (1-hour checklist)
2. Final test of all components
3. Prepare backup materials

### **During Demo:**

1. Follow item #18 checklist
2. Reference known issues (#19-21) if needed

---

## 📞 **SUPPORT & REFERENCES**

**Primary Documentation:**

- `docs/DEMO_PREP_CHECKLIST.md` - Pre-demo setup steps
- `docs/SERVICE_CLOUD_DEMO_GUIDE.md` - 15-minute demo script
- `docs/EMAIL_TO_CASE_SETUP.md` - Email-to-Case configuration
- `CLAUDE.md` - Complete project reference

**Emergency Contacts:**

- Demo Owner: Josh Rojas (josh.rojas.charfsc@schwab.com.fscjosh)
- Target Org: schwab-sandbox

---

**Last Updated:** 2025-10-14
**Next Review:** Before next demo date
