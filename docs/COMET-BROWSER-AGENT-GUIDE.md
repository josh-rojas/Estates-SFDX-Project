# Comet Browser Agent - Post-Deployment Guide

**Target Org:** josh.rojas.charfsc@schwab.com.fscjosh (schwab-sandbox/fscjosh)  
**Org URL:** https://schwabcharitablefund--fscjosh.sandbox.lightning.force.com  
**Last Updated:** October 15, 2025

---

## Overview

This guide provides step-by-step instructions for a Comet browser agent to complete post-deployment configuration tasks in the Salesforce org. Each task includes detailed navigation, UI element identification, expected states, and verification steps.

---

## Pre-Execution Checklist

### Authentication
- **Login URL:** `https://test.salesforce.com`
- **Username:** `josh.rojas.charfsc@schwab.com.fscjosh`
- **Password:** [Secure credential - retrieve from environment]
- **Security Token:** May be required if IP not whitelisted

### Expected Landing Page
After login, you should see Lightning Experience with:
- App Launcher (waffle icon) in top left
- Global search bar in top center
- User profile icon in top right
- Navigation bar with tabs (Home, Chatter, etc.)

---

## Task 1: Assign Permission Sets to Current User

**Duration:** 2-3 minutes  
**Criticality:** HIGH - Required for system access

### Navigation Steps

1. **Open Setup**
   - Locate gear icon ⚙️ in top-right corner
   - Click gear icon
   - Click "Setup" from dropdown menu
   - **Verification:** URL changes to `/lightning/setup/SetupOneHome/home`
   - **Verification:** Left sidebar shows "Setup Home" with search box

2. **Navigate to Users**
   - In left sidebar Setup search box, type: `users`
   - Wait for autocomplete suggestions to appear (500ms delay)
   - Click on "Users" under "ADMINISTRATION" section
   - **Verification:** URL contains `/lightning/setup/ManageUsers/home`
   - **Verification:** Page shows "Users" header with list view picker

3. **Find Current User**
   - In the users list, look for table with columns: Full Name, Alias, Username, etc.
   - Locate row with Username: `josh.rojas.charfsc@schwab.com.fscjosh`
   - Click on the Full Name hyperlink in that row
   - **Verification:** URL changes to `/lightning/setup/ManageUsers/page?address=%2F[USER_ID]`
   - **Verification:** Page shows user detail with tabs: Detail, Permission Set Assignments, etc.

4. **Open Permission Set Assignments**
   - Locate tab navigation below user name
   - Click tab labeled "Permission Set Assignments"
   - **Verification:** URL updates with `?tab=PermissionSetAssignments` or similar
   - **Verification:** Related list shows "Permission Set Assignments" with "Edit Assignments" button

5. **Assign First Permission Set: Succession_Management_Access**
   - Click button "Edit Assignments"
   - **Verification:** Modal or new page opens with two lists: "Available Permission Sets" (left) and "Enabled Permission Sets" (right)
   - In "Available Permission Sets" list (left side), scroll to find "Succession Management Access"
   - **Element Identification:** Look for text containing "Succession Management Access" in a selectable list item
   - Click on "Succession Management Access" to select it
   - **Verification:** Item should highlight/select
   - Click "Add" button (arrow button pointing right, between the two lists)
   - **Verification:** "Succession Management Access" moves from left list to right list "Enabled Permission Sets"

6. **Assign Second Permission Set: Succession_Field_Access**
   - Still in the Edit Assignments interface
   - In "Available Permission Sets" list, scroll to find "Succession Field Access"
   - Click on "Succession Field Access" to select it
   - Click "Add" button
   - **Verification:** "Succession Field Access" appears in right list "Enabled Permission Sets"

7. **Save Permission Set Assignments**
   - Click "Save" button (typically bottom-right of modal/page)
   - **Verification:** Returns to user detail page
   - **Verification:** Permission Set Assignments section now shows 2 new rows:
     - "Succession Management Access"
     - "Succession Field Access"
   - **Verification:** Success toast/message appears (green banner at top): "Permission sets assigned successfully" or similar

### Troubleshooting

**Issue:** Permission sets not found in Available list
- **Cause:** Permission sets failed to deploy
- **Action:** Abort task, report error: "Permission sets not deployed to org"

**Issue:** "Add" button is disabled
- **Cause:** Permission set not selected
- **Action:** Ensure permission set is highlighted/selected before clicking Add

**Issue:** Save button missing
- **Cause:** Wrong page/modal
- **Action:** Look for "Cancel" button to reset, or navigate back to Step 4

### Verification Commands (CLI Fallback)
```bash
# Verify permission sets exist
sf data query --query "SELECT Id, Name, Label FROM PermissionSet WHERE Name LIKE 'Succession%'" --target-org josh.rojas.charfsc@schwab.com.fscjosh

# Verify assignments
sf data query --query "SELECT PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId IN (SELECT Id FROM User WHERE Username = 'josh.rojas.charfsc@schwab.com.fscjosh') AND PermissionSet.Name LIKE 'Succession%'" --target-org josh.rojas.charfsc@schwab.com.fscjosh
```

---

## Task 2: Test Pathway Task Automation

**Duration:** 5-7 minutes  
**Criticality:** HIGH - Validates core functionality

### Navigation Steps

1. **Navigate to Cases**
   - Click App Launcher (waffle icon) in top-left
   - **Verification:** Modal opens with "Search apps and items..." search box
   - In search box, type: `Service Console`
   - **Verification:** "Service Console" app appears in search results
   - Click "Service Console"
   - **Verification:** URL changes to `/lightning/app/[APP_ID]`
   - **Verification:** Navigation bar shows "Service Console" with tabs

2. **Navigate to Cases Tab**
   - In navigation bar, click "Cases" tab
   - **Alternative:** If Cases tab not visible, click + icon and search for "Cases"
   - **Verification:** URL contains `/Case/` or `/list?`
   - **Verification:** Page shows "Cases" header with list view picker

3. **Create New Case**
   - Click "New" button (top-right area, usually blue button)
   - **Verification:** Modal or new page opens with "New Case" header
   - **Verification:** Form shows "Record Type" selection

4. **Select Estate Administration Record Type**
   - **If Record Type selection appears:**
     - Locate radio button or option for "Estate Administration"
     - Click on "Estate Administration" option
     - Click "Next" button
   - **If no Record Type selection:**
     - Form opens directly (Estate Administration may be default)
   - **Verification:** Form shows Case edit fields with "Estate Administration" as Record Type

5. **Fill Case Details**
   - **Account (Required):**
     - Click "Account" lookup field (magnifying glass icon)
     - **Verification:** Lookup modal opens with search box
     - Type a Person Account name (search existing accounts)
     - **Example search:** Type first few letters of any existing account
     - Click on an account from search results
     - **Verification:** Account name populates in Account field
   
   - **Type (Required):**
     - Click "Type" picklist dropdown
     - Select "Named Successor Enactment"
     - **Verification:** "Named Successor Enactment" appears in Type field
   
   - **Origin (Required if visible):**
     - Click "Origin" picklist dropdown
     - Select "Email" or "Phone" or "Web"
     - **Verification:** Origin value populated
   
   - **Subject (Optional):**
     - Click "Subject" text field
     - Type: `Test Pathway Task Automation - Oct 15`
     - **Verification:** Text appears in Subject field

6. **Save Case**
   - Click "Save" button (top-right, blue button)
   - **Verification:** Page redirects to Case detail view
   - **Verification:** URL changes to `/Case/[CASE_ID]/view`
   - **Verification:** Page header shows Case Number (e.g., "00001234")
   - **Verification:** Success toast appears: "Case was created"

7. **Capture Case Number**
   - **Element:** Page header shows "Case [NUMBER]"
   - **Action:** Store Case Number for verification
   - **Example:** "00001234"

8. **Locate Pathway Field**
   - Scroll down to find "Phase 3: Pathway Selection" section
   - **Alternative:** Use Quick Find in page (Ctrl/Cmd+F), search for "Succession Pathway"
   - Locate field labeled "Succession Pathway"
   - **Verification:** Field currently shows "Not Selected" (default value)

9. **Edit Case to Set Pathway**
   - Click "Edit" button (top-right area, near Save)
   - **Verification:** Form enters edit mode (fields become editable)
   - **Alternative:** Click pencil icon ✏️ next to "Succession Pathway" field for inline edit

10. **Set Pathway Value**
    - Click "Succession Pathway" picklist dropdown
    - **Verification:** Dropdown shows options:
      - Not Selected
      - Final Grant
      - New DAF Account
      - Disclaim Assets
    - Click "Final Grant" option
    - **Verification:** "Final Grant" selected in dropdown

11. **Set Form Completed Date (Optional but Recommended)**
    - Locate "Form Completed Date" field (may be in same section)
    - Click on the field
    - **If datetime picker appears:**
      - Click "Today" button or select current date
      - Set time to current time
    - **Verification:** Form_Completed_Date__c populated with current datetime

12. **Save Case Update**
    - Click "Save" button
    - **Verification:** Page returns to view mode
    - **Verification:** "Succession Pathway" field now shows "Final Grant"
    - **Verification:** Success toast: "Case was saved"

13. **Wait for Trigger Execution**
    - **Delay:** Wait 3-5 seconds for trigger to complete
    - **Purpose:** Allow SuccessionCaseTrigger to fire and create tasks

14. **Verify Tasks Were Created**
    - Scroll to "Activity" or "Activities" related list section
    - **Alternative section names:** "Open Activities", "Activity Timeline", "Tasks"
    - **Verification:** Related list shows 5 new tasks with subjects:
      1. "Review Grant Direction & Beneficiaries" (Due Date: Today + 2 days)
      2. "Coordinate Trading / Liquidation" (Due Date: Today + 5 days)
      3. "Process Grant Recommendations" (Due Date: Today + 10 days)
      4. "Confirm Distributions & Settlement" (Due Date: Today + 15 days)
      5. "Finalize Case Documentation" (Due Date: Today + 20 days)
    - **Verification:** All tasks show Status = "Not Started"
    - **Verification:** All tasks show Priority (2 High, 3 Normal)

15. **Verify Chatter Post**
    - Locate "Chatter" tab or "Feed" section on Case page
    - Click "Chatter" tab if not already visible
    - **Verification:** Most recent post shows:
      - Author: Automated Process or system user
      - Message contains: "5 pathway tasks created for: Final Grant"
      - Timestamp: Within last few minutes

16. **Take Screenshot (Evidence)**
    - **Capture:** Full Case detail page showing:
      - Case Number
      - Succession Pathway = "Final Grant"
      - 5 tasks in Activities
      - Chatter post confirmation
    - **Save as:** `pathway-automation-test-[TIMESTAMP].png`

### Expected Results

✅ **Success Criteria:**
- 5 tasks created automatically
- Task subjects match template
- Due dates staggered correctly (2, 5, 10, 15, 20 days)
- Chatter post confirms automation
- No errors in UI

❌ **Failure Indicators:**
- No tasks created → Trigger not firing
- Wrong number of tasks → Pathway value mismatch
- No Chatter post → Trigger error or Chatter issue
- Error toast message → Check debug logs

### Troubleshooting

**Issue:** No tasks created after 10 seconds
- **Action:** Navigate to Setup → Debug Logs → New
- Create debug log for current user
- Repeat Case update (change pathway to "New DAF Account")
- Check debug log for "SuccessionTaskGenerator" entries
- Report error with log details

**Issue:** Only some tasks created (e.g., 3 of 5)
- **Cause:** Partial trigger failure or governor limits
- **Action:** Check Activities list for exact count
- Report partial failure with actual vs expected count

**Issue:** Cannot edit Succession Pathway field
- **Cause:** Permission sets not assigned (Task 1 failed)
- **Action:** Abort Task 2, return to Task 1

---

## Task 3: Test Multi-Successor Scenario (Optional)

**Duration:** 8-10 minutes  
**Criticality:** MEDIUM - Validates advanced functionality

### Prerequisites
- Need a Person Account with 2+ FinancialAccountRoles (Role = "Successor")
- OR skip this task if test data not available

### Navigation Steps

1. **Navigate to Cases**
   - Follow Task 2, Steps 1-2 (Service Console → Cases)

2. **Create New Case with Multiple Successors**
   - Click "New" button
   - Select "Estate Administration" record type
   - Click "Next"

3. **Fill Case Details**
   - **Account:** Select an account that has multiple successors configured
   - **Type:** "Named Successor Enactment"
   - **Subject:** `Test Multi-Successor - [TIMESTAMP]`
   - Click "Save"

4. **Verify Multi-Successor Detection**
   - **Expected Behavior:** Flow `Case_Multiple_Successors_Handler` should detect 2+ successors
   - **Expected Result:** 
     - Parent case created with Type = "Multi-Account Succession Master"
     - Child cases created (1 per successor)
   - **Verification Steps:**
     - Check Case Type field → Should show "Multi-Account Succession Master"
     - Scroll to "Cases" related list → Should show child cases
     - Click on child case → Should have ParentId pointing to master case

5. **Verify Case Hierarchy Component**
   - On parent Case detail page
   - Locate "Succession Management" tab or custom component area
   - **Verification:** `caseHierarchyViewer` component should display tree structure showing parent + children

6. **Take Screenshot**
   - Capture hierarchy view with parent and child cases

### Troubleshooting

**Issue:** Only 1 case created (no children)
- **Cause:** Account has only 1 successor OR flow not triggered
- **Action:** Verify Account has 2+ FinancialAccountRoles with Role="Successor"

---

## Task 4: Verify Contact Cadence UI

**Duration:** 3-4 minutes  
**Criticality:** MEDIUM - Validates primary agent UI

### Navigation Steps

1. **Open Any Estate Administration Case**
   - Navigate to Cases (Task 2, Steps 1-2)
   - Click on any existing Estate Administration case
   - **Alternative:** Use case from Task 2

2. **Locate Succession Management Tab**
   - On Case detail page, look for tab navigation below record header
   - **Tab options may include:** Details, Related, Chatter, + custom tabs
   - Click tab labeled "Succession Management"
   - **Alternative:** If no custom tab, component may be on "Details" tab in a section

3. **Verify Contact Cadence Component**
   - **Component:** `successionContactCadence`
   - **Expected UI Elements:**
     - Table showing contact attempts (Attempt 1-5)
     - Columns: Attempt #, Scheduled Date, Status, Outcome, Notes
     - Edit buttons for each attempt
     - Sequential unlock pattern (only Day 0 editable initially)
   
4. **Test Contact Attempt Interaction**
   - Click "Edit" button on Attempt 1 (Day 0)
   - **Verification:** Edit modal/form opens
   - **Expected Fields:**
     - Contact Established: Yes/No radio buttons
     - Contact Notes: Text area
     - Contact Date: Date field (auto-populated)
   - **Action:** Select "Yes" for Contact Established
   - Type in Notes: `Test contact cadence - [TIMESTAMP]`
   - Click "Save" button

5. **Verify Automation Triggers**
   - **Expected Behavior:** Flow `Task_Succession_Contact_Update` sets Contact_Established__c = TRUE
   - **Verification Steps:**
     - Page refreshes/updates
     - Contact Attempt 1 shows "Completed" status
     - Contact Established checkbox on Case shows TRUE
     - Chatter post appears: "Contact established with successor"

6. **Take Screenshot**
   - Capture contact cadence component showing completed attempt

### Troubleshooting

**Issue:** Succession Management tab not found
- **Cause:** FlexiPage not assigned to record type
- **Action:** Check Related tab or Details tab for component

**Issue:** Component shows "Error loading data"
- **Cause:** Apex controller error or permission issue
- **Action:** Open browser console (F12), check for JavaScript errors
- Report error with console log

---

## Task 5: Verify Permission Set Field Access

**Duration:** 2-3 minutes  
**Criticality:** MEDIUM - Validates FLS setup

### Navigation Steps

1. **Navigate to Setup → Permission Sets**
   - Open Setup (gear icon → Setup)
   - In Quick Find box, type: `permission sets`
   - Click "Permission Sets" under USERS section
   - **Verification:** URL contains `/PermSets/home`
   - **Verification:** Page shows list of permission sets

2. **Open Succession_Management_Access**
   - In permission sets list, click "Succession Management Access"
   - **Verification:** Permission set detail page loads
   - **Verification:** Header shows "Succession Management Access"

3. **Verify Object Settings**
   - In permission set detail, look for "Object Settings" section or tab
   - Click "Object Settings"
   - **Expected:** Should see list including:
     - Case
     - Task
     - Account
     - FinancialAccount (or similar FSC objects)

4. **Check Case Field Permissions**
   - In Object Settings, click "Case"
   - **Verification:** Shows Case object permissions page
   - Click "Edit" or view field permissions section
   - **Expected Fields with Read + Edit access:**
     - Asset_Transfer_Status__c ✅ Read ✅ Edit
     - Contact_Attempt_Count__c ✅ Read ✅ Edit
     - Contact_Established__c ✅ Read ✅ Edit
     - Pathway_Confirmed__c ✅ Read ✅ Edit
     - Form_Completed_Date__c ✅ Read ✅ Edit
     - (and 11 more custom fields)
   - **Verification:** All succession fields show checkmarks for both Read and Edit

5. **Verify Apex Class Access**
   - Go back to permission set detail page
   - Find "Apex Class Access" section
   - **Verification:** Should show:
     - CaseHierarchyController ✅ Enabled
     - ContactCadenceController ✅ Enabled
     - SuccessionPublicFormController ✅ Enabled
     - SuccessionTaskGenerator ✅ Enabled

6. **Take Screenshot**
   - Capture permission set detail showing object and apex access

### Troubleshooting

**Issue:** Custom fields not listed
- **Cause:** Fields not deployed or permission set not updated
- **Action:** Report missing fields

---

## Task 6: Verify Email Template Accessibility

**Duration:** 2-3 minutes  
**Criticality:** LOW - Nice to have

### Navigation Steps

1. **Navigate to Email Templates**
   - Open Setup (gear icon → Setup)
   - Quick Find: type `email templates`
   - Click "Classic Email Templates" or "Email Templates"
   - **Verification:** URL contains `/email/author/`
   - **Verification:** Page shows email template folders

2. **Open Succession_Management Folder**
   - In folder list (left sidebar or main area), locate "Succession Management" folder
   - Click "Succession Management"
   - **Verification:** Folder opens showing templates inside

3. **Verify Templates Exist (6 expected)**
   - **Expected Templates:**
     1. Day 0 Initial Contact ✅
     2. Day 5 First Follow Up ✅
     3. Day 35 Second Contact ✅
     4. Day 65 Third Contact ✅
     5. Day 95 Final Contact ✅
     6. Pathway Form Invitation ✅
   - **Verification:** All 6 templates appear in folder
   - **Verification:** Each template shows "Type: Text" or "HTML"

4. **Preview Pathway Form Invitation Template**
   - Click on "Pathway Form Invitation" template name
   - **Verification:** Template preview/edit page opens
   - **Expected Content:**
     - Subject line mentions "Succession Pathway"
     - Body includes merge fields: {!Case.CaseNumber}, {!Account.Name}
     - Body includes URL with caseId parameter
     - Signature: "Estate Administration Team"

5. **Test Send Email (Optional)**
   - From a Case record, try sending email using template:
     - Open any Case from Task 2
     - Click "Send an Email" action (may be in dropdown)
     - Select "Pathway Form Invitation" template
     - **Verification:** Email preview populates with Case data
   - **Do NOT actually send** (test mode only)
   - Click "Cancel"

### Troubleshooting

**Issue:** Folder not found
- **Cause:** Email templates not deployed
- **Action:** Report error: "Succession_Management folder missing"

**Issue:** Merge fields show as {!Field.Name} instead of values
- **Cause:** Expected behavior in template editor
- **Action:** This is normal, merge fields resolve at send time

---

## Task 7: Create Debug Log for Monitoring

**Duration:** 2 minutes  
**Criticality:** LOW - For troubleshooting

### Navigation Steps

1. **Navigate to Debug Logs**
   - Open Setup
   - Quick Find: `debug logs`
   - Click "Debug Logs" under ENVIRONMENTS
   - **Verification:** URL contains `/ApexDebugLogs/home`

2. **Create New Debug Log**
   - Click "New" button
   - **Traced Entity Type:** Select "User"
   - **Traced Entity:** Search for and select current user (josh.rojas.charfsc@schwab.com.fscjosh)
   - **Start Date:** Today's date
   - **Expiration Date:** Tomorrow or 1 week later
   - **Debug Level:** Select "SFDC_DevConsole" or create custom with:
     - Apex Code: DEBUG
     - Database: INFO
     - Workflow: INFO
     - Validation: INFO

3. **Save Debug Log**
   - Click "Save"
   - **Verification:** Debug log appears in list with status "Active"

---

## Task 8: Verify Flexipage Deployment

**Duration:** 3 minutes  
**Criticality:** LOW - Optional UI check

### Navigation Steps

1. **Navigate to Lightning App Builder**
   - Open Setup
   - Quick Find: `lightning app builder`
   - Click "Lightning App Builder"
   - **Verification:** Shows list of Lightning pages

2. **Locate Succession Management Record Page**
   - In pages list, search or scroll for "Succession Management Record Page"
   - **Verification:** Page appears with type "Record Page"
   - Click on page name

3. **Verify Components on Page**
   - **Expected Components:**
     - successionContactCadence (primary component)
     - caseHierarchyViewer (for multi-successor cases)
     - Standard Lightning components (Related Lists, etc.)
   - **Verification:** Components appear in page structure on left panel

4. **Check Page Assignment**
   - Click "Activation..." button (top-right)
   - **Verification:** Shows activation settings
   - **Expected Assignment:**
     - App: Service Console
     - Record Type: Estate Administration
     - Default: May be set as default for record type
   - Click "Cancel" or close

---

## Post-Execution Summary Report

After completing all tasks, generate a summary:

### Report Template

```markdown
# Post-Deployment Execution Report

**Execution Date:** [TIMESTAMP]
**Org:** josh.rojas.charfsc@schwab.com.fscjosh
**Agent:** Comet Browser Agent

## Task Completion Status

- [ ] Task 1: Assign Permission Sets - [STATUS] - [DURATION]
  - Succession_Management_Access: [✅/❌]
  - Succession_Field_Access: [✅/❌]
  
- [ ] Task 2: Test Pathway Task Automation - [STATUS] - [DURATION]
  - Case Created: [CASE_NUMBER]
  - Tasks Created: [COUNT]/5 expected
  - Chatter Post: [✅/❌]
  
- [ ] Task 3: Test Multi-Successor - [STATUS/SKIPPED] - [DURATION]
  - Parent Case: [CASE_NUMBER or N/A]
  - Child Cases: [COUNT or N/A]
  
- [ ] Task 4: Verify Contact Cadence UI - [STATUS] - [DURATION]
  - Component Loaded: [✅/❌]
  - Edit Functional: [✅/❌]
  
- [ ] Task 5: Verify Permission Sets - [STATUS] - [DURATION]
  - Field Access: [COUNT] fields verified
  - Apex Access: [COUNT] classes verified
  
- [ ] Task 6: Verify Email Templates - [STATUS] - [DURATION]
  - Templates Found: [COUNT]/6 expected
  
- [ ] Task 7: Create Debug Log - [STATUS] - [DURATION]
- [ ] Task 8: Verify Flexipage - [STATUS] - [DURATION]

## Evidence
- Screenshots: [COUNT] files
- Case IDs: [LIST]
- Debug Logs: [LOG_IDS]

## Issues Encountered
[LIST ANY ERRORS OR UNEXPECTED BEHAVIOR]

## Recommendations
[NEXT STEPS OR CONFIGURATION NEEDED]
```

---

## Common Salesforce UI Element Selectors

For Comet browser automation, these selectors may help:

### Setup Navigation
```
Gear Icon: button[title="Setup"]
Setup Search: input[placeholder*="Search Setup"]
Setup Menu Item: a[data-target*="[MENU_ITEM]"]
```

### Case Detail Page
```
Edit Button: button[name="Edit"]
Save Button: button[name="SaveEdit"]
Tab Navigation: a[data-tab-name="[TAB_NAME]"]
Field Label: label:contains("Succession Pathway")
Picklist Dropdown: button[aria-label*="Succession Pathway"]
Related List: article[aria-label*="Activity"]
```

### Modals & Forms
```
Modal Header: h2[class*="slds-modal__header"]
Save Button in Modal: button[title="Save"]
Cancel Button: button[title="Cancel"]
Lookup Search: input[placeholder*="Search"]
```

### List Views
```
New Button: div[title="New"]
List View Dropdown: button[title*="List View Controls"]
Search Box: input[name="search"]
```

---

## Error Handling Protocol

### Critical Errors (Abort Execution)
- Unable to login
- Setup not accessible
- Permission sets missing from org

### Recoverable Errors (Retry with Delay)
- Page load timeout → Retry 3x with 5s delay
- Element not found → Refresh page, retry 2x
- Save button disabled → Check required fields, retry

### Non-Blocking Errors (Log and Continue)
- Optional field not visible
- Related list empty (may be expected)
- Screenshot capture failed

---

## Success Verification Checklist

After all tasks complete, verify:

- [x] 2 permission sets assigned to user
- [x] Case created successfully with Estate Administration record type
- [x] Pathway set to "Final Grant"
- [x] 5 tasks created automatically (Review Grant Direction, Coordinate Trading, Process Grant, Confirm Distributions, Finalize Case)
- [x] Task due dates: +2, +5, +10, +15, +20 days from today
- [x] Chatter post confirms "5 pathway tasks created"
- [x] Contact cadence component loads and functions
- [x] 6 email templates accessible in Succession_Management folder

**Overall Success Rate Target:** 7/8 tasks (87.5%+)

---

## CLI Verification Commands (Fallback)

If browser automation fails, use these CLI commands:

```bash
# Verify permission set assignments
sf data query --query "SELECT PermissionSet.Name FROM PermissionSetAssignment WHERE Assignee.Username = 'josh.rojas.charfsc@schwab.com.fscjosh' AND PermissionSet.Name LIKE 'Succession%'" --target-org josh.rojas.charfsc@schwab.com.fscjosh

# Verify trigger deployed
sf data query --query "SELECT Name, Status FROM ApexTrigger WHERE Name = 'SuccessionCaseTrigger'" --target-org josh.rojas.charfsc@schwab.com.fscjosh --use-tooling-api

# Verify flows active
sf data query --query "SELECT DeveloperName, Status FROM FlowDefinitionView WHERE DeveloperName LIKE 'Case_%' OR DeveloperName LIKE 'Task_%'" --target-org josh.rojas.charfsc@schwab.com.fscjosh --use-tooling-api

# Check if test case has tasks
sf data query --query "SELECT Id, Subject, ActivityDate, Status FROM Task WHERE WhatId = '[CASE_ID]' ORDER BY ActivityDate" --target-org josh.rojas.charfsc@schwab.com.fscjosh
```

---

## Estimated Total Execution Time

- **Minimum Path** (Tasks 1, 2, 4, 5): 12-15 minutes
- **Full Path** (All 8 tasks): 25-30 minutes
- **With Troubleshooting:** Add 10-15 minutes buffer

---

## Next Steps After Completion

1. **Share Evidence:**
   - Upload screenshots to shared folder
   - Export execution report
   - Share Case URLs for manual review

2. **Production Readiness:**
   - If all tests pass → System ready for demo/production
   - If failures → Review troubleshooting section and fix issues

3. **Optional Enhancements:**
   - Configure Experience Cloud site (manual - not in scope)
   - Set up Service Cloud queues (manual - not in scope)
   - Load demo data via CumulusCI (see docs/05-TESTING-AND-DATA.md)
