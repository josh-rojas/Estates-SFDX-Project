# Security Model & Permissions

**Last Updated:** November 2, 2025  
**Version:** 1.0

---

## Overview

The Succession Management System implements a comprehensive security model using Salesforce standard security features: permission sets, field-level security, and Apex security modes. The system is designed to support three user types: internal agents, guest users (successors), and administrators.

---

## Permission Sets

### 1. Succession_Management_Access

**Purpose:** Full access for internal agents managing succession cases

**File Location:** `force-app/main/default/permissionsets/Succession_Management_Access.permissionset-meta.xml`

**Object Permissions:**

| Object               | Create | Read | Edit | Delete |
| -------------------- | ------ | ---- | ---- | ------ |
| Case                 | ✅     | ✅   | ✅   | ✅     |
| Task                 | ✅     | ✅   | ✅   | ✅     |
| Account              | ❌     | ✅   | ❌   | ❌     |
| Contact              | ❌     | ✅   | ❌   | ❌     |
| FinancialAccount     | ❌     | ✅   | ❌   | ❌     |
| FinancialAccountRole | ❌     | ✅   | ❌   | ❌     |

**Field-Level Security:**

- All custom Case fields: Read + Edit
- All custom Task fields: Read + Edit
- All custom FinancialAccountRole fields: Read only

**Apex Class Access:**

- ContactCadenceController
- CreateSuccessionCaseController
- CaseHierarchyController
- SuccessionUtilities

**LWC Access:**

- successionContactCadence
- recordPathwaySelection
- caseHierarchyViewer
- createSuccessionCase

**Tab Access:**

- Cases tab: Visible
- Tasks tab: Visible

**Assigned To:**

- Succession Management Agents
- Case Managers
- Team Leads

---

### 2. Succession_Field_Access

**Purpose:** Extended field-level access for users who need to view/edit additional succession fields

**File Location:** `force-app/main/default/permissionsets/Succession_Field_Access.permissionset-meta.xml`

**Object Permissions:**

- Same as Succession_Management_Access

**Field-Level Security:**

- All custom Case fields: Read + Edit
- All custom Task fields: Read + Edit
- All custom Account fields: Read + Edit
- All custom FinancialAccountRole fields: Read + Edit

**Use Case:**

- Administrators who need to modify all fields
- Data migration users
- Integration users

**Assigned To:**

- System Administrators
- Data Stewards
- Integration Service Accounts

---

### 3. Succession_Guest_Access

**Purpose:** Limited access for guest users (successors) to submit pathway selection via public form

**File Location:** `force-app/main/default/permissionsets/Succession_Guest_Access.permissionset-meta.xml`

**Object Permissions:**

| Object  | Create | Read | Edit | Delete |
| ------- | ------ | ---- | ---- | ------ |
| Case    | ❌     | ✅   | ✅   | ❌     |
| Task    | ❌     | ❌   | ❌   | ❌     |
| Account | ❌     | ❌   | ❌   | ❌     |

**Field-Level Security:**

- Case.Pathway_Confirmed\_\_c: Read + Edit
- Case.Form_Completed_Date\_\_c: Read + Edit
- All other Case fields: Read only

**Apex Class Access:**

- SuccessionPublicFormController

**LWC Access:**

- successionPublicForm

**Security Notes:**

- Token-based authentication required
- Cannot create or delete records
- Cannot access Tasks (pathway tasks created via SYSTEM_MODE)
- Limited to specific Case fields only

**Assigned To:**

- Guest User Profile (Experience Cloud site)

---

## Apex Security Modes

### WITH USER_MODE (Default)

**Classes Using WITH USER_MODE:**

1. **ContactCadenceController**
   - All queries use `WITH USER_MODE`
   - Enforces FLS and CRUD permissions
   - Users must have Succession_Management_Access

2. **CreateSuccessionCaseController**
   - All queries use `WITH USER_MODE` (5 queries confirmed)
   - Enforces FLS and CRUD permissions
   - Users must have Succession_Management_Access

3. **SuccessionPublicFormController**
   - All queries use `WITH USER_MODE` (lines 135, 151, 168, 187)
   - Enforces FLS and CRUD permissions
   - Guest users must have Succession_Guest_Access

4. **CaseHierarchyController**
   - All queries use `WITH USER_MODE`
   - Enforces FLS and CRUD permissions
   - Users must have Succession_Management_Access

5. **SuccessionUtilities**
   - All queries use `WITH USER_MODE` (3 queries confirmed)
   - Enforces FLS and CRUD permissions
   - Called by other controllers with user context

6. **SuccessionTaskCreator**
   - All queries use `WITH USER_MODE`
   - Enforces FLS and CRUD permissions
   - Invocable method called from flows (inactive)

7. **SuccessionChatterPoster**
   - All queries use `WITH USER_MODE`
   - Enforces FLS and CRUD permissions
   - Invocable method called from flows (inactive)

---

### SYSTEM_MODE (Exception)

**Class Using SYSTEM_MODE:**

**SuccessionTaskGenerator**

**File Location:** `force-app/main/default/classes/SuccessionTaskGenerator.cls`

**Lines:** 82, 92

**Rationale:**

```apex
// SYSTEM_MODE is required here because:
// 1. Guest users (successors) cannot create Tasks directly
// 2. Automation must work regardless of user permissions
// 3. Pathway tasks are system-generated, not user-created
// 4. This is a documented exception for automation reliability
Database.insert(tasks, AccessLevel.SYSTEM_MODE);
```

**Security Implications:**

- Tasks are created with system privileges
- Bypasses user FLS and CRUD checks
- Required for guest user scenarios (public form submission)
- Tasks are always associated with a Case (WhatId)
- No user input directly creates tasks (trigger-based)

**Mitigation:**

- Trigger only fires on Case.after update
- Only creates tasks when `Pathway_Confirmed__c` changes
- Duplicate prevention logic prevents abuse
- Tasks are pre-defined templates (not user-controlled)
- Comprehensive test coverage (100%)

**Audit Trail:**

- All task creation logged in debug logs
- Case feed shows task creation activity
- Trigger execution tracked in Setup Audit Trail

---

## Sharing Model

### Organization-Wide Defaults (OWD)

| Object               | OWD Setting          | Reason                           |
| -------------------- | -------------------- | -------------------------------- |
| Case                 | Private              | Sensitive succession information |
| Task                 | Controlled by Parent | Inherits from Case               |
| Account              | Private              | FSC standard                     |
| Contact              | Controlled by Parent | Inherits from Account            |
| FinancialAccount     | Private              | FSC standard                     |
| FinancialAccountRole | Controlled by Parent | Inherits from FinancialAccount   |

### Sharing Rules

**Case Sharing:**

- **Rule:** Succession Management Team
- **Criteria:** RecordType = EstateAdministration
- **Share With:** Succession Management Public Group
- **Access Level:** Read/Write

**Account Sharing:**

- Uses FSC standard sharing model
- Account Teams for relationship management
- No custom sharing rules

### Manual Sharing

**Enabled For:**

- Case: Yes (for ad-hoc collaboration)
- Task: No (controlled by parent)
- Account: Yes (FSC standard)

---

## Guest User Access (Experience Cloud)

### Site Configuration

**Site Name:** Succession Portal (example)

**Guest User Profile:** Succession Guest User

**Permission Set:** Succession_Guest_Access

**Access Model:**

1. Successor receives email with unique URL
2. URL contains Case ID + access token
3. Token validated by `SuccessionPublicFormController`
4. Guest user can view Case (read-only) and submit pathway selection
5. Token expires after 30 days

### Token Security

**Token Generation:**

```apex
// Generate secure token
String token = EncodingUtil.convertToHex(Crypto.generateAesKey(128));
```

**Token Storage:**

- Stored in custom field: `Case.Access_Token__c`
- Encrypted at rest (Salesforce Platform Encryption)
- Expires after 30 days: `Case.Token_Expiration_Date__c`

**Token Validation:**

```apex
// Validate token
if (c.Access_Token__c != token || c.Token_Expiration_Date__c < Date.today()) {
    throw new AuraHandledException('Invalid or expired token');
}
```

### Guest User Limitations

**Cannot:**

- Create Cases or Tasks
- Delete any records
- Access other users' Cases
- View Tasks (no read access)
- Access Financial Account data
- Navigate to other pages (restricted to form)

**Can:**

- View own Case (via token)
- Submit pathway selection (edit Pathway_Confirmed\_\_c)
- View pathway descriptions

---

## Email Security

### Email Validation

**Opt-Out Checking:**

```apex
// Check if successor has opted out of email
if (account.PersonHasOptedOutOfEmail) {
    return new ValidationResult(false, 'Successor has opted out of email');
}
```

**Format Validation:**

```apex
// Validate email format
String emailRegex = '^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$';
Pattern pattern = Pattern.compile(emailRegex);
Matcher matcher = pattern.matcher(email);
return matcher.matches();
```

**Compliance:**

- Respects `PersonHasOptedOutOfEmail` flag
- Validates email format before sending
- Displays warnings in UI if email invalid
- No emails sent to opted-out users

---

## Data Access Patterns

### Query Patterns

**Selective Queries (Good):**

```apex
// Good: Selective query with WHERE clause
List<Case> cases = [
    SELECT Id, CaseNumber, Status
    FROM Case
    WHERE RecordType.Name = 'EstateAdministration'
    AND Status != 'Closed'
    WITH USER_MODE
];
```

**Avoid:**

```apex
// Bad: Non-selective query
List<Case> cases = [SELECT Id FROM Case WITH USER_MODE];
```

### Bulk Processing

**All Apex methods are bulk-safe:**

```apex
// Good: Bulk processing
public static void createPathwayTasks(List<Case> newCases, Map<Id, Case> oldCaseMap) {
    List<Task> tasksToInsert = new List<Task>();

    for (Case c : newCases) {
        // Process each case
        tasksToInsert.addAll(generateTasks(c));
    }

    // Single DML operation
    Database.insert(tasksToInsert, AccessLevel.SYSTEM_MODE);
}
```

---

## Security Best Practices

### ✅ Implemented

1. **Permission Sets:** All access controlled via permission sets (no profile modifications)
2. **Field-Level Security:** All custom fields have FLS configured
3. **Apex Security:** WITH USER_MODE enforced (except documented exception)
4. **Sharing Model:** Private OWD with sharing rules for team access
5. **Guest User Security:** Token-based authentication with expiration
6. **Email Compliance:** Opt-out checking and format validation
7. **Bulk Processing:** All Apex methods are bulk-safe
8. **Test Coverage:** 100% coverage on all classes
9. **Audit Trail:** All changes logged in standard Salesforce audit logs
10. **No Hardcoded Credentials:** No credentials in code

### ⚠️ Considerations

1. **SYSTEM_MODE Usage:** `SuccessionTaskGenerator` uses SYSTEM_MODE (documented rationale)
2. **Guest User Access:** Token-based (not OAuth) - acceptable for demo/MVP
3. **Token Expiration:** 30 days (configurable)
4. **No MFA:** Guest users don't have MFA (Experience Cloud limitation)

### 🔮 Future Enhancements

1. **OAuth Integration:** Replace token-based auth with OAuth for guest users
2. **Platform Encryption:** Enable Platform Encryption for sensitive fields
3. **Shield Platform Encryption:** Event monitoring and field audit trail
4. **Two-Factor Authentication:** Require 2FA for internal users
5. **IP Restrictions:** Restrict access by IP range
6. **Session Security:** Enhanced session security settings

---

## Security Audit Checklist

Use this checklist to verify security configuration:

### Permission Sets

- [ ] Succession_Management_Access assigned to agents
- [ ] Succession_Field_Access assigned to admins
- [ ] Succession_Guest_Access assigned to guest user profile
- [ ] No users have Modify All Data permission (except sys admins)

### Field-Level Security

- [ ] All custom Case fields have FLS configured
- [ ] All custom Task fields have FLS configured
- [ ] Guest users can only edit Pathway_Confirmed**c and Form_Completed_Date**c

### Sharing Model

- [ ] Case OWD = Private
- [ ] Sharing rule for Succession Management Team configured
- [ ] No manual shares to guest users

### Apex Security

- [ ] All controllers use WITH USER_MODE (except SuccessionTaskGenerator)
- [ ] SuccessionTaskGenerator SYSTEM_MODE usage documented
- [ ] No SOQL injection vulnerabilities
- [ ] No hardcoded credentials

### Guest User Access

- [ ] Token expiration configured (30 days)
- [ ] Token validation in SuccessionPublicFormController
- [ ] Guest user cannot access Tasks
- [ ] Guest user cannot create/delete records

### Email Security

- [ ] Opt-out checking enabled
- [ ] Email format validation enabled
- [ ] No emails sent to opted-out users

### Testing

- [ ] All test classes have 100% coverage
- [ ] Security test cases included (negative tests)
- [ ] Bulk processing tested (200+ records)

---

## Incident Response

### Security Incident Types

1. **Unauthorized Access:** Guest user accessing wrong Case
2. **Data Breach:** Sensitive data exposed
3. **Permission Escalation:** User gaining unauthorized permissions
4. **Token Compromise:** Access token leaked

### Response Procedures

**Unauthorized Access:**

1. Revoke access token immediately
2. Review audit logs for access patterns
3. Notify affected successor
4. Generate new token and resend

**Data Breach:**

1. Disable Experience Cloud site
2. Review all guest user access logs
3. Notify security team and affected parties
4. Conduct full security audit

**Permission Escalation:**

1. Remove unauthorized permissions
2. Review permission set assignments
3. Audit recent permission changes
4. Notify system administrator

**Token Compromise:**

1. Expire all tokens for affected Cases
2. Generate new tokens
3. Resend emails with new tokens
4. Review access logs for suspicious activity

---

## Compliance

### Data Privacy

**GDPR Compliance:**

- Right to access: Successors can view their Case data
- Right to rectification: Agents can update Case data
- Right to erasure: Cases can be deleted (with approval)
- Data portability: Case data can be exported

**CCPA Compliance:**

- Disclosure: Privacy policy on public form
- Opt-out: Email opt-out respected
- Data deletion: Cases can be deleted on request

### Audit Trail

**Tracked Changes:**

- Case field changes (Field History Tracking enabled)
- Task creation and completion
- Permission set assignments
- Login history (internal users)
- Guest user access (via token validation logs)

**Retention:**

- Field history: 18 months (Salesforce standard)
- Login history: 6 months (Salesforce standard)
- Debug logs: 7 days (Salesforce standard)

---

**Document Status:** Last verified November 2, 2025 | Commit: [current]
