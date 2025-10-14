# Project TODO List - Succession Management System

**Generated:** 2025-10-14
**Purpose:** Comprehensive list of incomplete tasks, configuration needs, and known issues

---

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
  - Read access to: Case, Account, Contact, FinServ__FinancialAccount__c, FinServ__FinancialAccountRole__c
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

**Status:** ⚠️ NEEDS REVIEW

**Components Present:** 12 LWC components

**Usage Analysis Needed:**
- [ ] `recordPathwaySelection` - Used as Quick Action? Still needed?
- [ ] `successionAccountSummary` - Where is this displayed?
- [ ] `successionDisclaimDetails` - Part of deprecated Succession_Pathway_Selection_Flow?
- [ ] `successionNewDafDetails` - Part of deprecated Succession_Pathway_Selection_Flow?
- [ ] `successionGrantBeneficiaries` - Part of deprecated Succession_Pathway_Selection_Flow?
- [ ] `successionPathwaySelector` - Part of deprecated Succession_Pathway_Selection_Flow?
- [ ] `successionReviewAndSign` - Part of deprecated Succession_Pathway_Selection_Flow?
- [ ] `successionSuccessorInfo` - Part of deprecated Succession_Pathway_Selection_Flow?

**Action Needed:**
- [ ] Review CLAUDE.md flow inventory (lines 221-242)
- [ ] Determine if components 3-8 above are used in active workflows
- [ ] Consider removing unused components (or document their purpose)

**Impact:** Low priority - components don't hurt anything if unused, but clarifying their purpose improves maintainability

---

### 8. ⚠️ **Flow Error Handler Reference**

**Status:** ⚠️ DOCUMENTATION CONFLICT

**Issue:** CLAUDE.md line 496 says "Always call `Flow_Error_Handler` subflow for error handling"

**But:** CLAUDE.md line 596 says "No error handling infrastructure: Removed custom error logging (Flow_Error__c object, Error_Notification__e event, Flow_Error_Handler flow)"

**Action Needed:**
- [ ] Verify if Flow_Error_Handler flow still exists in org
- [ ] Update CLAUDE.md to remove conflicting guidance (line 496)
- [ ] Confirm flows use native Salesforce error logging only

**Impact:** Documentation accuracy - does not block demo

---

### 9. ⚠️ **SLA Configuration Alignment**

**Status:** ⚠️ DOCUMENTATION vs METADATA MISMATCH

**CLAUDE.md line 524-527 states:**
```
SLA Configuration
Configured in Setup → Entitlement Processes → Estate Succession SLA:
- Initial Response: 24 hours
- Standard Resolution: 90 days
- Critical Escalation: 80 days
```

**But entitlement process metadata shows:**
```xml
<milestoneName>Verification Complete</milestoneName>
<minutesToComplete>1440</minutesToComplete>  <!-- 24 hours = 1 day -->

<milestoneName>Initial Contact Established</milestoneName>
<minutesToComplete>480</minutesToComplete>  <!-- 8 hours -->

<milestoneName>Succession Form Sent</milestoneName>
<minutesToComplete>1440</minutesToComplete>  <!-- 24 hours = 1 day -->

<milestoneName>Documentation Complete</milestoneName>
<minutesToComplete>43200</minutesToComplete>  <!-- 30 days -->

<milestoneName>Final Resolution</milestoneName>
<minutesToComplete>86400</minutesToComplete>  <!-- 60 days -->
```

**Action Needed:**
- [ ] Update CLAUDE.md lines 524-527 to match actual milestone configuration
- [ ] Verify milestones align with business requirements (or update metadata if incorrect)

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
- `manifest/package-service-cloud-features.xml` - Service Cloud metadata only
- `manifest/package-succession-*.xml` - Targeted deployments

**Pre-Deployment Checklist:**
- [x] Backup files removed
- [x] Deprecated flow set to Obsolete
- [x] Unused profiles removed (26 files)
- [x] Email templates cleaned up
- [x] Apex classes have test coverage
- [x] LWC components have metadata files

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

| Category | Count | Status |
|----------|-------|--------|
| **HIGH PRIORITY Tasks** | 5 | ❌ NOT STARTED |
| **MEDIUM PRIORITY Tasks** | 4 | ⚠️ NEEDS REVIEW |
| **LOW PRIORITY Tasks** | 3 | ✅ DOCUMENTED |
| **Deployment Tasks** | 3 | ✅ READY |
| **Demo-Specific Tasks** | 3 | ⏳ PENDING |
| **Known Issues** | 3 | ℹ️ DOCUMENTED |
| **TOTAL ITEMS** | 21 | |

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
