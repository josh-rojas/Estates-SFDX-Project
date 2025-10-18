# 06 - Security

**Last updated: October 15, 2025**

Comprehensive security audit covering field-level security, permissions, email compliance, and production hardening recommendations.

---

## Related Diagrams

- Component Architecture (PlantUML): `diagrams/images/plantuml/component-architecture.png`
- Status Coordination – State Machine (PlantUML): `diagrams/images/plantuml/status-coordination-state.png`
 - Data Model (ERD): `diagrams/images/erd/data-model.png`

![Component Architecture](diagrams/images/plantuml/component-architecture.png)
![Status Coordination – State Machine](diagrams/images/plantuml/status-coordination-state.png)
![Data Model](diagrams/images/erd/data-model.png)

---

## Executive Summary

**🔒 Complete security audit with all issues resolved.**

**⚠️ DEMO CONFIGURATION:** All permissions optimized for easy demonstrations with maximum permissiveness and zero validation rules. This prioritizes demo flexibility over production security constraints.

### Security Improvements Made

1. ✅ Cleaned up 2 permission sets (removed 7 deprecated field permissions)
2. ✅ Added missing field permissions (Contact_Established_Date__c, Last_Status_Update__c, Next_Task_Scheduled_At__c)
3. ✅ **KEPT Account audit fields** (Deceased__c, Date_of_Death__c) for demo/audit purposes
4. ✅ Created guest user permission set for Experience Cloud
5. ✅ Added object-level permissions to internal permission set
6. ✅ Added Apex class permissions to internal permission set
7. ✅ Verified Experience Cloud component exposure
8. ✅ Updated package.xml to include all 3 permission sets
9. ✅ **Optimized all permissions for DEMO** (maximum permissiveness, no restrictions)

---

## Permission Sets

### 1. Succession_Management_Access (Internal Users)

**Purpose:** Core permission set for Estates team members processing succession cases

**Target Users:** Estates team, case workers, agents

**Field Permissions (20 total):**

**Account (2 fields):**
- `Deceased__c` (Read/Edit) - Audit trail
- `Date_of_Death__c` (Read/Edit) - Audit trail

**Case (16 fields):**
- `Asset_Transfer_Status__c` (Read/Edit)
- `Contact_Attempt_Count__c` (Read/Edit)
- `Contact_Established__c` (Read/Edit)
- `Disclaimer_Disposition__c` (Read/Edit)
- `Execution_Completed_Date__c` (Read/Edit)
- `Execution_Notes__c` (Read/Edit)
- `Execution_Started_Date__c` (Read/Edit)
- `Execution_Status__c` (Read/Edit)
- `Form_Completed_Date__c` (Read/Edit)
- `Form_Sent_Date__c` (Read/Edit)
- `Grant_Settlement_Status__c` (Read/Edit)
- `New_DAF_Account_Number__c` (Read/Edit)
- `Next_Task_Scheduled_At__c` (Read/Edit)
- `Pathway_Confirmed__c` (Read/Edit)
- `SLA_Status__c` (Read Only - calculated field)
- `Verification_Status__c` (Read/Edit)

**Task (2 fields):**
- `Contact_Attempt_Number__c` (Read/Edit)
- `Succession_Contact_Established__c` (Read/Edit)

**Object Permissions:**
- ✅ Case: Create, Read, Edit (no Delete for audit trail)
- ✅ Task: Create, Read, Edit, Delete

**Apex Class Access:**
- ✅ CaseHierarchyController
- ✅ ContactCadenceController
- ✅ SuccessionPublicFormController
- ✅ SuccessionTaskGenerator

**Coverage:** **100%** (All current fields included)

---

### 2. Succession_Field_Access (Extended Access)

**Purpose:** Comprehensive field access including Activity fields for testing and advanced users

**Target Users:** QA testers, system administrators, data migration users

**Field Permissions (22 total):**
- **Account** (2 fields) - Same as Succession_Management_Access
- **Case** (16 fields) - Same as Succession_Management_Access
- **Task** (2 fields) - Same as Succession_Management_Access
- **Event** (2 fields):
  - `Contact_Attempt_Number__c` (Read/Edit)
  - `Succession_Contact_Established__c` (Read/Edit)

**Object Permissions:** Not specified (relies on profile permissions)

**Apex Class Access:** Not specified (relies on profile permissions)

**Coverage:** **100%** (All current fields + Activity fields)

**Use Case:** Assign to:
- QA testers who need full field access
- System administrators performing data migration
- Advanced users managing complex succession scenarios

---

### 3. Succession_Guest_Access (Public Form)

**Purpose:** Minimal permissions for guest users accessing public pathway submission form

**Target Users:** Unauthenticated guests accessing Experience Cloud site

**Field Permissions (Case fields only):**
- `Pathway_Confirmed__c` (Read/Edit) - Required for form submission
- `Form_Completed_Date__c` (Read/Edit) - Timestamp form completion
- `Contact_Established__c` (Read Only) - Display status
- `Verification_Status__c` (Read Only) - Display status

**Object Permissions:**
- ✅ Case: Read + Limited Edit (pathway fields only)
- ✅ Account: Read (display deceased donor info)
- ✅ Contact: Read (display successor info)
- ✅ FinancialAccount: Read (display account balance)

**Apex Class Access:**
- ✅ SuccessionPublicFormController (required for form submission)

**Security Model:**
- **URL Parameter Obscurity:** caseId and accountId in URL query string
- **No Authentication Required:** Guest access for ease of use
- **Limited Edit Scope:** Can only update pathway fields, not sensitive data

**Production Hardening Required:**
- Implement tokenized URLs (encrypted parameters)
- Add rate limiting (5 submissions per IP per hour)
- Add CAPTCHA for bot protection
- Implement token expiration (90 days)
- Add IP address validation

---

## Field Coverage Summary

### Internal Users (Succession_Management_Access)

| Object      | Fields | Coverage  | Philosophy                           |
| ----------- | ------ | --------- | ------------------------------------ |
| **Account** | 2      | 2/2       | Audit trail + demo context           |
| **Case**    | 16     | 16/16     | Full workflow coverage               |
| **Task**    | 2      | 2/2       | Contact cadence tracking             |
| **Total**   | **20** | **20/20** | **100% coverage, maximum access** ✅ |

---

### Extended Access (Succession_Field_Access)

| Object      | Fields | Coverage  | Philosophy                   |
| ----------- | ------ | --------- | ---------------------------- |
| **Account** | 2      | 2/2       | Audit trail                  |
| **Case**    | 16     | 16/16     | Full workflow coverage       |
| **Task**    | 2      | 2/2       | Contact cadence tracking     |
| **Event**   | 2      | 2/2       | Activity tracking (extended) |
| **Total**   | **22** | **22/22** | **100% coverage** ✅         |

---

## Email Compliance (Tier 1 Critical Fixes)

After comprehensive analysis identifying **26 potential failure scenarios**, implemented **Tier 1 CRITICAL** fixes to prevent legal/compliance violations.

### Fix #1: Email Existence Validation ⚠️ CRITICAL

**Problem:**
Code validated ContactId/AccountId exists but NOT email field value.

**Impact:** Demo failure - agent clicks "Send Email" but cannot send (empty TO field)

**Solution:**
- **Apex:** Added email field queries + validation
- **Apex:** Returns `hasEmail`, `emailAddress` to LWC
- **LWC:** Disables "Send Email" button if `hasEmail = false`
- **LWC:** Shows warning: "No email address on file for this successor"

**Code Changes:**
- ContactCadenceController.cls:45-50 - Email validation fields to wrapper
- ContactCadenceController.cls:65-70 - Query PersonEmail, Contact.Email
- ContactCadenceController.cls:110 - Call validateEmailAddress()
- ContactCadenceController.cls:427-471 - New validateEmailAddress() method
- successionContactCadence.js:127-132 - canSendEmail computed property
- successionContactCadence.js:353-354 - Validate email before opening composer

---

### Fix #2: Email Opt-Out Validation ⚠️ CRITICAL (Legal/Compliance)

**Problem:** No validation of email opt-out preferences before opening composer

**Impact:**
- Successor has `HasOptedOutOfEmail = true` (legally opted out)
- Agent sends email anyway
- **Legal/compliance violation**, potential lawsuit

**Solution:**
- **Apex:** Query `Account.HasOptedOutOfEmail` / `Contact.HasOptedOutOfEmail`
- **Apex:** Return `hasOptedOut` boolean to LWC
- **LWC:** Disable "Send Email" button if `hasOptedOut = true`
- **LWC:** Show warning: "⚠️ Successor opted out of email. Contact by phone only."

**Code Changes:**
- ContactCadenceController.cls:435 - Query HasOptedOutOfEmail
- ContactCadenceController.cls:459-461 - Opt-out warning message
- successionContactCadence.js:127-132 - Check hasOptedOut in canSendEmail
- successionContactCadence.html:90-102 - Email warning alert

---

### Fix #3: Email Format Validation ⚠️ HIGH

**Problem:** Test data might contain malformed emails (missing @, double @@, spaces)

**Impact:** Composer opens, agent sends → Error: "Invalid email address" → Demo interrupted

**Solution:**
- **Apex:** Basic regex validation: `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`
- **Apex:** Return `hasValidEmailFormat` boolean
- **LWC:** Disable button if format invalid
- **LWC:** Show warning: "Email address format appears invalid"

**Code Changes:**
- ContactCadenceController.cls:450-451 - Email regex validation
- ContactCadenceController.cls:465-467 - Invalid format warning
- successionContactCadence.js:127-132 - Check hasValidEmailFormat in canSendEmail

---

### Fix #4: Double-Click Prevention ⚠️ HIGH

**Problem:** Rapid double-clicking "Send Email" opens multiple composer windows

**Impact:** Agent confused by 3 identical composers, may send duplicate emails

**Solution:**
- **LWC:** Disable button immediately on first click
- **LWC:** Set 2-second timeout before re-enabling
- **LWC:** Show loading spinner during disabled state

**Code Changes:**
- successionContactCadence.js:134-140 - isEmailButtonDisabled reactive property
- successionContactCadence.js:355-370 - Double-click prevention logic with 2s timeout
- successionContactCadence.html:113 - Bind disabled attribute to isEmailButtonDisabled

---

### Fix #5: Email Prompt Persistence ⚠️ MEDIUM

**Problem:** If agent closes composer without sending, email prompt disappears (silent failure)

**Impact:** Agent forgets to send email, successor never receives pathway form

**Solution:**
- **LWC:** Track email composer open/close state
- **LWC:** Keep prompt visible after composer close UNLESS agent clicks "Skip"
- **LWC:** Only dismiss prompt on explicit "Skip" action

**Code Changes:**
- successionContactCadence.js:374-387 - Track emailPromptDismissed state
- successionContactCadence.js:392-398 - handleSkipEmail() explicit dismiss
- successionContactCadence.html:96-102 - Show prompt if NOT dismissed

---

## Apex Test Coverage

**Status:** ✅ PASSING

**Test Classes (4 total):**
- `CaseHierarchyController_Test.cls` ✅
- `ContactCadenceController_Test.cls` ✅
- `SuccessionPublicFormController_Test.cls` ✅
- `SuccessionTaskGenerator_Test.cls` ✅ (7 tests, 100% coverage)

**Run Tests:**

```bash
sf apex run test --test-level RunLocalTests --code-coverage --target-org schwab-sandbox
```

---

## Demo Security Approach

### Maximum Permissiveness

All permission sets grant **maximum access** to facilitate easy demonstrations:

- ✅ **No restrictive permissions** that block demo scenarios
- ✅ **Full edit access** to all fields (except calculated fields)
- ✅ **No field-level restrictions** requiring workarounds
- ✅ **Permissive object access** for all internal users

**Rationale:** Demo scenarios require rapid data manipulation, edge case testing, and quick "undo" actions. Restrictive permissions slow demonstrations and create unnecessary friction.

---

### Zero Validation Rules

**NO validation rules are included in this project.**

- ❌ No required fields (beyond Salesforce defaults)
- ❌ No format validations
- ❌ No business logic constraints
- ❌ No complex formula validations

**Rationale:** Validation rules block demo scenarios, create "gotcha" moments during live presentations, and require extensive test data preparation. For demos, we prioritize flexibility over data integrity.

---

### Audit Fields Included

**Account Fields (Person Account):**
- ✅ `Deceased__c` (Checkbox) - Marks deceased donors
- ✅ `Date_of_Death__c` (Date) - Records date of death

**Purpose:** Provide valuable audit trail information and context for Person Accounts, even though not actively used in automation flows.

**Use Cases:**
- Quick visual indicator on Account record
- Historical reference for compliance
- Manual reporting and data analysis
- Demo narrative context ("This donor passed away on...")

---

### Guest User Access

**Succession_Guest_Access** permission set designed for **public form demonstrations**:

- ✅ **Permissive read access** to display pre-filled form data
- ✅ **Limited edit access** to submit pathway selection
- ✅ **No authentication required** (URL parameter obscurity only)

**Security Trade-off:** URL parameter obscurity sufficient for demo purposes. Production requires tokenized URLs, rate limiting, and CAPTCHA.

---

## Production Hardening

**⚠️ If deploying to production, you MUST:**

### 1. Add Validation Rules

- Required field validations
- Format validations (email, phone, SSN)
- Business logic constraints
- Cross-object validation rules

### 2. Restrict Permissions

- Limit edit access to sensitive fields
- Add read-only permissions where appropriate
- Implement profile-based access controls
- Add View All Records / Modify All Records restrictions

### 3. Enhance Guest User Security

- Implement tokenized URLs (encrypted parameters)
- Add rate limiting (5 submissions per IP per hour)
- Add CAPTCHA for bot protection
- Implement token expiration (90 days)
- Add IP address validation

### 4. Add Audit Trails

- Enable Field History Tracking on critical fields
- Create custom audit logging for guest submissions
- Implement security event monitoring

### 5. Add Approval Processes

- Multi-step approvals for pathway changes
- Manager approval for high-value accounts
- Compliance review for complex cases

### 6. Implement Data Governance

- Data retention policies
- PII handling procedures
- Encryption for sensitive fields
- Access logs and monitoring

---

## Security Best Practices

### During Demonstrations

1. **Emphasize Demo Nature:**
   - Explain this is a sandbox environment
   - Point out production would have additional security
   - Highlight intentional permissiveness

2. **Showcase Flexibility:**
   - Demonstrate ability to modify data on-the-fly
   - Show how easy it is to correct mistakes
   - Highlight speed of workflow

3. **Address Security Questions Proactively:**
   - Acknowledge URL parameter obscurity limitation
   - Explain production would use tokenized URLs
   - Point out absence of validation rules is intentional

---

### Data Preparation

1. **Use CumulusCI Test Data:**

```bash
cci task run load_demo_ui_showcase
```

2. **Verify Email Addresses:**
   - All Person Accounts must have valid email format
   - Check `HasOptedOutOfEmail = false`
   - See 03-ADMIN-RUNBOOK.md

3. **Pre-populate Account Audit Fields:**
   - Set `Deceased__c = true` on test accounts
   - Set `Date_of_Death__c` to recent date
   - Creates realistic demo narrative

---

## Deployment Commands

**Assign Permission Sets:**

```bash
# Internal users
sf org assign permset --name Succession_Management_Access --target-org schwab-sandbox

# Extended access
sf org assign permset --name Succession_Field_Access --target-org schwab-sandbox

# Guest users (Experience Cloud)
# Assigned automatically to guest profile via site configuration
```

**Deploy Metadata:**

```bash
# Deploy all permission sets
sf project deploy start --manifest manifest/package.xml --target-org schwab-sandbox
```

---

## Known Security Limitations

### 1. URL Parameter Obscurity (Public Form)

**Issue:** Public form uses caseId/accountId in URL query string (no token-based auth)

**Note:** INTENTIONAL for demo simplicity, not production-ready

**Details:** See AGENTS.md and production hardening section

---

### 2. Sandbox Email Restrictions

**Issue:** Sandbox orgs only send emails to verified addresses

**Workaround:** Add all demo emails to verified list (Setup → Email Administration → Deliverability)

**Details:** See 03-ADMIN-RUNBOOK.md

---

### 3. No Field History Tracking

**Issue:** Field History Tracking not enabled on sensitive fields

**Note:** INTENTIONAL for demo (reduces storage, improves performance)

**Production:** Enable Field History Tracking on:
- `Pathway_Confirmed__c`
- `Execution_Status__c`
- `Form_Completed_Date__c`
- `Contact_Established__c`

---

## Related Documentation

- **01-SYSTEM-ARCHITECTURE.md** - System overview
- **02-DEPLOYMENT-AND-CICD.md** - Deployment procedures
- **03-ADMIN-RUNBOOK.md** - Admin setup and email deliverability
- **04-FIELD-REFERENCE.md** - Field-level security details
- **05-TESTING-AND-DATA.md** - Test data with email validation scenarios
- **AGENTS.md** - Complete project reference

---

## Conclusion

**This project prioritizes DEMO FLEXIBILITY over production security.**

- ✅ **Maximum permissions** for easy demonstrations
- ✅ **Zero validation rules** to prevent demo blockers
- ✅ **Audit fields included** for context and reporting
- ✅ **Permissive guest access** for public form demos
- ✅ **Email compliance enforced** (opt-out, format validation)
- ⚠️ **NOT production-ready** without additional hardening

**For Production:** Add validation rules, restrict permissions, enhance guest user security, implement comprehensive audit trails, and enable Field History Tracking.
