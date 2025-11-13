# Admin Runbook

**Last Updated:** November 2, 2025  
**Version:** 1.0

---

## Overview

This runbook provides step-by-step procedures for administrators to set up, configure, and troubleshoot the Succession Management System. It includes demo preparation, common tasks, and troubleshooting guides.

---

## Demo Preparation

### Pre-Demo Setup (30 minutes)

#### 1. Verify Deployment

```bash
# Check deployment status
sf project deploy report --target-org demo-org

# Verify Apex tests passed
sf apex run test --test-level RunLocalTests --target-org demo-org
```

#### 2. Assign Permission Sets

```bash
# Assign to demo user
sf org assign permset --name Succession_Management_Access --target-org demo-org --on-behalf-of demo.user@example.com
```

#### 3. Load Demo Data

```bash
# Using CumulusCI
cci task run load_demo_ui_showcase --org demo-org

# Or manually create test data (see below)
```

#### 4. Configure Page Layouts

**Manual Steps:**
1. Navigate to Setup → Object Manager → Case → Page Layouts
2. Edit "Estate Administration Layout"
3. Add Quick Actions:
   - Create Succession Case
   - Record Pathway Selection
4. Add Related Lists:
   - Tasks
   - Case Hierarchy (for multi-successor)
5. Save and assign to EstateAdministration record type

#### 5. Test End-to-End Flow

**Test Scenario:**
1. Create Financial Account with successor
2. Create succession case
3. Complete contact attempts
4. Select pathway
5. Verify pathway tasks created
6. Complete pathway tasks
7. Close case

---

## Manual Test Data Creation

### Create Person Account (Deceased Donor)

1. Navigate to Accounts tab
2. Click "New"
3. Select "Person Account" record type
4. Fill in:
   - First Name: "John"
   - Last Name: "Donor"
   - Email: "john.donor@example.com"
   - Deceased__c: ✅ (checked)
   - Date_of_Death__c: (today's date - 30 days)
5. Save

### Create Person Account (Successor)

1. Navigate to Accounts tab
2. Click "New"
3. Select "Person Account" record type
4. Fill in:
   - First Name: "Jane"
   - Last Name: "Successor"
   - Email: "jane.successor@example.com"
   - Deceased__c: ❌ (unchecked)
5. Save

### Create Financial Account

1. Navigate to Financial Accounts tab
2. Click "New"
3. Fill in:
   - Name: "Donor Charitable Fund"
   - Primary Owner: (select deceased donor account)
   - Status: "Active"
   - Balance: $100,000
4. Save

### Create Financial Account Role (Successor)

1. Open Financial Account record
2. Navigate to "Financial Account Roles" related list
3. Click "New"
4. Fill in:
   - Financial Account: (auto-populated)
   - Related Contact: (select successor contact)
   - Role: "Successor"
   - Active: ✅ (checked)
   - Successor Allocation %: 100
5. Save

### Create Succession Case

1. Open Financial Account record
2. Click "Create Succession Case" Quick Action
3. Select successor
4. Click "Create"
5. Verify case created with:
   - Record Type: Estate Administration
   - Type: "Named Successor Enactment"
   - Status: "New"
   - Contact: Successor contact

---

## Common Administrative Tasks

### Task 1: Assign Permission Sets to New Users

```bash
# Via Salesforce CLI
sf org assign permset --name Succession_Management_Access --target-org prod --on-behalf-of new.user@example.com

# Or via UI:
# Setup → Users → [Select User] → Permission Set Assignments → Edit Assignments
```

### Task 2: Create Public Group for Sharing

**Manual Steps:**
1. Navigate to Setup → Public Groups
2. Click "New"
3. Fill in:
   - Label: "Succession Management Team"
   - Group Name: "Succession_Management_Team"
4. Add members (users or roles)
5. Save

### Task 3: Configure Sharing Rule

**Manual Steps:**
1. Navigate to Setup → Sharing Settings
2. Click "Case Sharing Rules" → "New"
3. Fill in:
   - Label: "Succession Management Team Access"
   - Rule Name: "Succession_Management_Team_Access"
   - Criteria: RecordType = "EstateAdministration"
   - Share with: "Succession Management Team" (public group)
   - Access Level: Read/Write
4. Save

### Task 4: Activate Flows (If Needed)

**Manual Steps:**
1. Navigate to Setup → Flows
2. Find flow: "Succession_Start_Contact_Process"
3. Click "Activate"
4. Repeat for other flows if needed

**Note:** Flows are currently Inactive. Primary automation is trigger-based.

### Task 5: Configure Email Templates

**Manual Steps:**
1. Navigate to Setup → Email Templates
2. Navigate to "Succession_Management" folder
3. Edit templates as needed:
   - Day 0 Contact Attempt
   - Day 5 Contact Attempt
   - Day 35 Contact Attempt
   - Day 65 Contact Attempt
   - Day 95 Contact Attempt
   - Pathway Form Invitation
4. Update merge fields, branding, and content
5. Save

### Task 6: Monitor Flow Errors

**Manual Steps:**
1. Navigate to Setup → Flows
2. Click "Flow Errors" tab
3. Review errors by:
   - Severity (Critical, Warning, Info)
   - Flow name
   - Error date
4. Investigate and resolve errors

### Task 7: Export Case Data

```bash
# Using Salesforce CLI Data Export
sf data export tree --query "SELECT Id, CaseNumber, Status, Pathway_Confirmed__c FROM Case WHERE RecordType.Name = 'EstateAdministration'" --output-dir ./export --target-org prod

# Or use Data Loader (UI-based)
```

### Task 8: Bulk Update Cases

```bash
# Using Salesforce CLI
sf data update bulk --sobject Case --csv-file cases.csv --target-org prod

# Or use Data Loader (UI-based)
```

---

## Troubleshooting Guide

### Issue: Pathway Tasks Not Created

**Symptoms:**
- User selects pathway via recordPathwaySelection LWC
- No tasks created on Case

**Diagnosis:**
1. Check if `Pathway_Confirmed__c` field was set
2. Check if trigger is active
3. Review debug logs for errors

**Resolution:**
```bash
# Enable debug logs
sf apex log tail --target-org prod

# Reproduce issue
# Review logs for errors in SuccessionCaseTrigger or SuccessionTaskGenerator
```

**Common Causes:**
- Trigger not deployed or inactive
- User lacks permission to create Tasks
- Duplicate prevention logic blocking creation
- Field value didn't change (was already set)

**Fix:**
1. Verify trigger deployed: Setup → Apex Triggers → SuccessionCaseTrigger
2. Check user permissions: Setup → Users → [User] → Permission Sets
3. Clear existing pathway tasks if duplicate prevention blocking
4. Ensure `Pathway_Confirmed__c` changed from null to value

---

### Issue: Guest User Cannot Submit Form

**Symptoms:**
- Guest user receives "Insufficient Access" error
- Form doesn't load or submit fails

**Diagnosis:**
1. Check if Succession_Guest_Access permission set assigned to guest user profile
2. Verify token is valid and not expired
3. Check sharing settings for Case

**Resolution:**
1. Assign permission set:
   - Setup → Profiles → [Guest User Profile] → Permission Set Assignments
   - Add "Succession_Guest_Access"
2. Verify token:
   - Open Case record
   - Check `Access_Token__c` field
   - Check `Token_Expiration_Date__c` (must be future date)
3. Check sharing:
   - Setup → Sharing Settings → Case → Organization-Wide Defaults
   - Ensure guest user has access via sharing rule or manual share

---

### Issue: Contact Cadence Not Displaying

**Symptoms:**
- successionContactCadence LWC shows blank or error
- Tasks not loading

**Diagnosis:**
1. Check if contact attempt tasks exist
2. Review debug logs for query errors
3. Verify user has access to Tasks

**Resolution:**
1. Create contact attempt tasks manually:
   - Navigate to Case → Tasks → New
   - Subject: "Contact Attempt #1"
   - Contact_Attempt_Number__c: 1
   - ActivityDate: (today)
   - Status: "Not Started"
2. Check user permissions:
   - Setup → Users → [User] → Permission Sets
   - Verify "Succession_Management_Access" assigned
3. Review debug logs:
   ```bash
   sf apex log tail --target-org prod
   ```

---

### Issue: Multi-Successor Parent Case Not Closing

**Symptoms:**
- All child cases are Closed
- Parent case remains Open

**Diagnosis:**
1. Check if all child cases have Status = "Closed" or "Canceled"
2. Verify parent case has ParentId = null (is actually parent)
3. Check if flow "Succession_Close_Multi_Successor_Parent" is active

**Resolution:**
1. Verify child case statuses:
   ```sql
   SELECT Id, CaseNumber, Status, ParentId
   FROM Case
   WHERE ParentId = '<parent-case-id>'
   ```
2. If flow is inactive, manually close parent case:
   - Open parent case
   - Change Status to "Closed"
   - Save
3. If flow should be active, activate it:
   - Setup → Flows → Succession_Close_Multi_Successor_Parent → Activate

**Note:** Flow is currently Inactive. Manual closure required.

---

### Issue: Email Validation Warnings

**Symptoms:**
- successionContactCadence shows email validation warning
- "Successor has opted out of email" message

**Diagnosis:**
1. Check successor Account.PersonHasOptedOutOfEmail field
2. Verify email format is valid

**Resolution:**
1. Update opt-out status:
   - Open successor Account record
   - Uncheck "Email Opt Out" (PersonHasOptedOutOfEmail)
   - Save
2. Verify email format:
   - Open successor Account record
   - Check PersonEmail field
   - Ensure format: name@domain.com
3. Re-check in successionContactCadence LWC

---

### Issue: Apex Test Failures

**Symptoms:**
- Deployment fails due to test failures
- Test coverage below 75%

**Diagnosis:**
1. Run tests locally to identify failures
2. Review test error messages
3. Check if test data setup is correct

**Resolution:**
```bash
# Run specific test class
sf apex run test --tests ContactCadenceController_Test --target-org prod --detailed-coverage

# Review test results
sf apex get test --test-run-id <test-run-id> --target-org prod

# Fix test class and redeploy
```

**Common Causes:**
- Test data not set up correctly
- Validation rules blocking test data
- Governor limits exceeded in tests
- Hardcoded IDs in test classes

**Fix:**
1. Review test class setup methods
2. Use `@TestSetup` for test data creation
3. Avoid hardcoded IDs (use dynamic queries)
4. Ensure bulk-safe test methods (200+ records)

---

### Issue: LWC Not Displaying on Page

**Symptoms:**
- LWC component not visible on Case record page
- Error message in console

**Diagnosis:**
1. Check if LWC is added to page layout
2. Verify user has access to LWC
3. Review browser console for JavaScript errors

**Resolution:**
1. Add LWC to page layout:
   - Setup → Object Manager → Case → Lightning Record Pages
   - Edit "Estate Administration Record Page"
   - Drag LWC component to page
   - Save and activate
2. Check user permissions:
   - Setup → Users → [User] → Permission Sets
   - Verify "Succession_Management_Access" assigned
3. Review browser console:
   - Open browser developer tools (F12)
   - Check Console tab for errors
   - Fix JavaScript errors in LWC code

---

## Performance Optimization

### Monitor Query Performance

**Check SOQL Queries:**
1. Navigate to Setup → System Overview → System Logs
2. Filter by "SOQL_EXECUTE_BEGIN"
3. Identify slow queries (>1 second)
4. Add indexes or optimize WHERE clauses

**Optimize Queries:**
```apex
// Bad: Non-selective query
List<Case> cases = [SELECT Id FROM Case];

// Good: Selective query with indexed field
List<Case> cases = [
    SELECT Id, CaseNumber, Status
    FROM Case
    WHERE RecordType.Name = 'EstateAdministration'
    AND Status != 'Closed'
    AND CreatedDate = LAST_N_DAYS:30
];
```

### Monitor Apex Performance

**Check Apex Execution Time:**
1. Navigate to Setup → Apex Jobs
2. Review job duration and status
3. Identify long-running jobs

**Optimize Apex:**
- Use bulk processing (avoid loops)
- Minimize SOQL queries (use maps)
- Avoid nested loops
- Use efficient data structures

### Monitor LWC Performance

**Check LWC Load Time:**
1. Open browser developer tools (F12)
2. Navigate to Network tab
3. Reload page
4. Check LWC bundle load time

**Optimize LWC:**
- Use `@wire` with `cacheable=true`
- Minimize imperative Apex calls
- Use Lightning Data Service when possible
- Lazy load components

---

## Backup & Recovery

### Backup Procedures

**Weekly Backup:**
```bash
# Export all Case data
sf data export tree --query "SELECT Id, CaseNumber, Status, Pathway_Confirmed__c, (SELECT Id, Subject, Status FROM Tasks) FROM Case WHERE RecordType.Name = 'EstateAdministration'" --output-dir ./backup/$(date +%Y%m%d) --target-org prod
```

**Monthly Backup:**
```bash
# Full metadata backup
sf project retrieve start --target-org prod --output-dir ./backup/metadata/$(date +%Y%m%d)
```

### Recovery Procedures

**Restore Case Data:**
```bash
# Import Case data from backup
sf data import tree --plan ./backup/20251102/Case-plan.json --target-org prod
```

**Restore Metadata:**
```bash
# Deploy metadata from backup
sf project deploy start --source-dir ./backup/metadata/20251102 --target-org prod
```

---

## Monitoring Dashboard

### Key Metrics to Track

1. **Case Volume:**
   - Total cases created (daily, weekly, monthly)
   - Cases by pathway (Final Grant, New DAF, Disclaim)
   - Cases by status (New, In Progress, Closed)

2. **Contact Cadence:**
   - Contact attempt success rate (% of cases where contact established)
   - Average attempts to establish contact
   - Cases stuck in contact cadence (>95 days)

3. **Pathway Execution:**
   - Average time to complete pathway tasks
   - Pathway task completion rate
   - Cases stuck in pathway execution

4. **SLA Compliance:**
   - % of cases meeting Initial Response SLA (24 hours)
   - % of cases meeting Pathway Selection SLA (30 days)
   - % of cases meeting Standard Resolution SLA (90 days)

5. **System Health:**
   - Apex test coverage (target: 95%+)
   - Flow error rate (target: <1%)
   - Debug log error rate (target: <0.1%)

### Create Reports

**Report 1: Cases by Status**
1. Navigate to Reports tab
2. Click "New Report"
3. Select "Cases" report type
4. Add filters:
   - Record Type = "EstateAdministration"
5. Group by: Status
6. Add chart: Donut chart
7. Save as "Succession Cases by Status"

**Report 2: Pathway Distribution**
1. Navigate to Reports tab
2. Click "New Report"
3. Select "Cases" report type
4. Add filters:
   - Record Type = "EstateAdministration"
   - Pathway_Confirmed__c ≠ null
5. Group by: Pathway_Confirmed__c
6. Add chart: Bar chart
7. Save as "Succession Pathway Distribution"

**Report 3: SLA Compliance**
1. Navigate to Reports tab
2. Click "New Report"
3. Select "Cases" report type
4. Add filters:
   - Record Type = "EstateAdministration"
5. Add formula fields:
   - Initial Response Met: IF(CreatedDate + 1 > Contact_Established_Date__c, "Yes", "No")
6. Group by: Initial Response Met
7. Save as "Succession SLA Compliance"

---

## Maintenance Schedule

### Daily Tasks
- [ ] Monitor debug logs for errors
- [ ] Review flow error logs
- [ ] Check case queue for stuck cases

### Weekly Tasks
- [ ] Review SLA compliance reports
- [ ] Backup case data
- [ ] Review user feedback
- [ ] Update documentation (if needed)

### Monthly Tasks
- [ ] Full metadata backup
- [ ] Review and optimize queries
- [ ] Update email templates (if needed)
- [ ] Review permission set assignments
- [ ] Conduct security audit

### Quarterly Tasks
- [ ] Review and update runbook
- [ ] Conduct disaster recovery drill
- [ ] Review and optimize page layouts
- [ ] Update training materials
- [ ] Conduct user satisfaction survey

---

## Emergency Contacts

### Escalation Path

**Level 1: Developer**
- Review debug logs
- Fix code issues
- Deploy hotfixes

**Level 2: Team Lead**
- Coordinate with stakeholders
- Approve emergency deployments
- Escalate to architect if needed

**Level 3: Architect**
- Review system design
- Approve major changes
- Escalate to Salesforce support if needed

**Level 4: Salesforce Support**
- Critical platform issues
- Performance degradation
- Data loss incidents

---

**Document Status:** Last verified November 2, 2025 | Commit: [current]
