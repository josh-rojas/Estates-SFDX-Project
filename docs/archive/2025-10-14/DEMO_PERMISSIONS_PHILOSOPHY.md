# Demo Permissions Philosophy

**Date**: October 14, 2025  
**Project**: Succession Management System v1.0  
**Environment**: Sandbox/Demo Only

---

## ⚠️ DEMO-FIRST APPROACH

This project is **explicitly configured for demonstration purposes** with the following principles:

### 1. **Maximum Permissiveness**

All permission sets grant **maximum access** to facilitate easy demonstrations:

- ✅ **No restrictive permissions** that would block demo scenarios
- ✅ **Full edit access** to all fields (except calculated fields)
- ✅ **No field-level restrictions** that would require workarounds
- ✅ **Permissive object access** for all internal users

**Rationale**: Demo scenarios often require rapid data manipulation, edge case testing, and the ability to "undo" actions quickly. Restrictive permissions would slow down demonstrations and create unnecessary friction.

---

### 2. **Zero Validation Rules**

**NO validation rules are included in this project.**

- ❌ No required fields (beyond Salesforce standard requirements)
- ❌ No format validations
- ❌ No business logic constraints
- ❌ No complex formula validations

**Rationale**: Validation rules can block demo scenarios, create "gotcha" moments during live presentations, and require extensive test data preparation. For demos, we prioritize flexibility over data integrity.

---

### 3. **Audit Fields Included**

**Account Fields** (Person Account):

- ✅ `Deceased__c` (Checkbox) - Marks deceased donors
- ✅ `Date_of_Death__c` (Date) - Records date of death

**Purpose**: These fields provide valuable audit trail information and context for Person Accounts in the succession workflow, even though they're not actively used in automation flows.

**Use Cases**:

- Quick visual indicator on Account record
- Historical reference for compliance
- Manual reporting and data analysis
- Demo narrative context ("This donor passed away on...")

---

### 4. **Guest User Access**

**Succession_Guest_Access** permission set is designed for **public form demonstrations**:

- ✅ **Permissive read access** to display pre-filled form data
- ✅ **Limited edit access** to submit pathway selection
- ✅ **No authentication required** (URL parameter obscurity only)

**Security Trade-off**: URL parameter obscurity is sufficient for demo purposes. Production would require tokenized URLs, rate limiting, and CAPTCHA.

---

## Permission Set Strategy

### Succession_Management_Access (Internal Users)

**Target Users**: Estates team members, case workers, agents

**Permissions**:

- ✅ Account: Read/Edit (Deceased\_\_c, Date_of_Death\_\_c)
- ✅ Case: Create, Read, Edit (no Delete for audit trail)
- ✅ Task: Create, Read, Edit, Delete
- ✅ All 18 Case custom fields: Read/Edit
- ✅ All 2 Task custom fields: Read/Edit
- ✅ All 3 Apex controllers: Enabled

**Philosophy**: Internal users should never be blocked from performing their work during demos. Full edit access ensures smooth demonstrations.

---

### Succession_Field_Access (Extended Access)

**Target Users**: QA testers, system administrators, data migration users

**Permissions**:

- ✅ All permissions from Succession_Management_Access
- ✅ Event (Activity) fields: Read/Edit
- ✅ Account audit fields: Read/Edit

**Philosophy**: Extended permission set for users who need broader access across objects and field types.

---

### Succession_Guest_Access (Public Form)

**Target Users**: Guest users accessing public pathway submission form

**Permissions**:

- ✅ Case: Read + Limited Edit (pathway fields only)
- ✅ Account, Contact, FinancialAccount: Read
- ✅ SuccessionPublicFormController: Enabled

**Philosophy**: Minimal permissions for public-facing form, but still permissive enough for demo scenarios.

---

## What This Means for Production

**⚠️ If deploying to production, you MUST:**

1. **Add Validation Rules**:
   - Required field validations
   - Format validations (email, phone, SSN)
   - Business logic constraints
   - Cross-object validation rules

2. **Restrict Permissions**:
   - Limit edit access to sensitive fields
   - Add read-only permissions where appropriate
   - Implement profile-based access controls
   - Add View All Records / Modify All Records restrictions

3. **Enhance Guest User Security**:
   - Implement tokenized URLs (encrypted parameters)
   - Add rate limiting (e.g., 5 submissions per IP per hour)
   - Add CAPTCHA for bot protection
   - Implement token expiration (e.g., 90 days)
   - Add IP address validation

4. **Add Audit Trails**:
   - Enable Field History Tracking on critical fields
   - Create custom audit logging for guest submissions
   - Implement security event monitoring

5. **Add Approval Processes**:
   - Multi-step approvals for pathway changes
   - Manager approval for high-value accounts
   - Compliance review for complex cases

6. **Implement Data Governance**:
   - Data retention policies
   - PII handling procedures
   - Encryption for sensitive fields
   - Access logs and monitoring

---

## Demo Best Practices

### During Demonstrations

1. **Emphasize the Demo Nature**:
   - Explain this is a sandbox environment
   - Point out that production would have additional security
   - Highlight the intentional permissiveness

2. **Showcase Flexibility**:
   - Demonstrate ability to modify data on-the-fly
   - Show how easy it is to correct mistakes
   - Highlight the speed of the workflow

3. **Address Security Questions Proactively**:
   - Acknowledge URL parameter obscurity limitation
   - Explain production would use tokenized URLs
   - Point out absence of validation rules is intentional

### Data Preparation

1. **Use CumulusCI Test Data**:

   ```bash
   cci task run load_demo_ui_showcase
   ```

2. **Verify Email Addresses**:
   - All Person Accounts must have valid email format
   - Check `HasOptedOutOfEmail = false`
   - See `DEMO_PREP_CHECKLIST.md`

3. **Pre-populate Account Audit Fields**:
   - Set `Deceased__c = true` on test accounts
   - Set `Date_of_Death__c` to recent date
   - Creates realistic demo narrative

---

## Field Coverage Summary

### Internal Users (Succession_Management_Access)

| Object      | Fields | Coverage  | Philosophy                           |
| ----------- | ------ | --------- | ------------------------------------ |
| **Account** | 2      | 2/2       | Audit trail + demo context           |
| **Case**    | 18     | 18/18     | Full workflow coverage               |
| **Task**    | 2      | 2/2       | Contact cadence tracking             |
| **Total**   | **22** | **22/22** | **100% coverage, maximum access** ✅ |

### Extended Access (Succession_Field_Access)

| Object      | Fields | Coverage  | Philosophy                   |
| ----------- | ------ | --------- | ---------------------------- |
| **Account** | 2      | 2/2       | Audit trail                  |
| **Case**    | 18     | 18/18     | Full workflow coverage       |
| **Task**    | 2      | 2/2       | Contact cadence tracking     |
| **Event**   | 2      | 2/2       | Activity tracking (extended) |
| **Total**   | **24** | **24/24** | **100% coverage** ✅         |

---

## Conclusion

**This project prioritizes DEMO FLEXIBILITY over production security.**

- ✅ **Maximum permissions** for easy demonstrations
- ✅ **Zero validation rules** to prevent demo blockers
- ✅ **Audit fields included** for context and reporting
- ✅ **Permissive guest access** for public form demos
- ⚠️ **NOT production-ready** without additional hardening

**For Production**: Add validation rules, restrict permissions, enhance guest user security, and implement comprehensive audit trails.

---

**Related Documentation**:

- `CLAUDE.md` - Project architecture and demo configuration
- `SECURITY_AUDIT_2025-10-14.md` - Permission set details
- `DEMO_PREP_CHECKLIST.md` - Pre-demo setup guide



