# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## ⚠️ Important: Demo/Sandbox Project

**This is a demonstration project built in a sandbox environment for:**
- Estates team management review and demonstration
- Product management team evaluation and feedback

**Key Considerations:**
- ⚠️ **This use case may NOT be deployed to production** - This is a proof-of-concept/demo system
- 🎯 **Optimized for easy live demonstrations** - All configurations prioritize demo flexibility over production constraints
- ✅ **NO validation rules included** - All validation rules have been intentionally removed to prevent blocking demo scenarios
- 🔧 **Sandbox-only configuration** - Not production-ready, not intended for production use
- 🎪 **Demo-first development** - Features are designed to showcase capabilities, not enforce strict business rules

**When making changes:**
- DO NOT add validation rules (they block demo scenarios)
- DO NOT add complex approval processes
- DO NOT add production security constraints that would interfere with demos
- DO prioritize user experience and visual demonstration value
- DO keep workflows simple and easy to explain during live demos

**Target Org:** schwab-sandbox (josh.rojas.charfsc@schwab.com.fscjosh) - Demo environment only

## Project Overview

**Succession Management System v1.0** - A Salesforce Financial Services Cloud solution for Schwab Charitable Fund that automates deceased donor account transitions through three succession pathways: Disclaim, New DAF, and Final Grant.

## Essential Commands

### Salesforce Deployment

```bash
# Authenticate to org
sf org login web --alias succession-org

# Deploy all metadata
sf project deploy start --manifest manifest/package.xml

# Deploy specific components
sf project deploy start --source-dir force-app/main/default/classes
sf project deploy start --source-dir force-app/main/default/lwc
sf project deploy start --source-dir force-app/main/default/flows

# Validate deployment (no changes)
sf project deploy validate --manifest manifest/package.xml

# Retrieve metadata from org
sf project deploy start --target-org sandbox
```

### Testing & Quality

```bash
# Run Apex tests
sf apex run test --test-level RunLocalTests --code-coverage

# Run LWC unit tests
npm run test:unit

# Run LWC tests in watch mode
npm run test:unit:watch

# Generate coverage report
npm run test:unit:coverage

# Lint JavaScript
npm run lint

# Format all code
npm run prettier

# Verify formatting
npm run prettier:verify
```

### CumulusCI Workflows

```bash
# Complete deployment with test data
cci flow run deploy_succession

# Deploy without test data
cci flow run deploy_succession_no_data

# Load specific test scenarios
cci task run load_final_grant_scenario
cci task run load_multi_successor_scenario
cci task run load_sla_escalation_scenario
cci task run load_demo_ui_showcase

# Complete QA setup
cci flow run qa_full_setup

# CI pipelines
cci flow run ci_succession_feature    # Feature branches
cci flow run ci_succession_main       # Main branch
```

### Permission Sets

```bash
# Assign required permission sets
sf org assign permset --name Succession_Management_Access
sf org assign permset --name Succession_Field_Access
```

### Lightning Local Development

```bash
# Start local dev server with hot reload
sf lightning dev app --name <componentName>

# Example for specific component
sf lightning dev app --name successionContactCadence

# With record context
sf lightning dev app --name successionContactCadence --record-id <CaseId>
```

## Architecture & Code Organization

### Core Data Model

**No Custom Objects** - System uses standard Salesforce objects:
- **Case** (Record Type: `EstateAdministration`)
  - **Case Types:**
    - `Named Successor Enactment` - Single or multiple successors
    - `Multi-Account Succession Master` - Parent case for coordinating multiple child cases
  - Succession-specific fields for pathway tracking, contact cadence, SLA management
  - Three pathways: Disclaim, New DAF, Final Grant
- **Account** - **Person Accounts (typical)** or Business Accounts
  - **Person Account:** Individual donor (most common in Financial Services Cloud)
  - **Business Account:** Organization donor (rare for succession cases)
  - **Person Account Fields:** PersonEmail, PersonMobilePhone, HasOptedOutOfEmail, etc. accessible via virtual Contact relationship
- **Contact** - Only used with Business Accounts (Person Accounts don't have separate Contact records)
  - **Contact Fields:** Email, HasOptedOutOfEmail, etc.
- **FinancialAccountRole** - Successor designation with allocation percentages (`SuccessorAllocation__c`)
- **Task/Activity** - Contact attempt tracking with custom fields

**Person Account Note:** Most succession cases use Person Accounts (individual donors). The system auto-detects `Account.IsPersonAccount` and uses `Account.SendEmail` action instead of `Contact.SendEmail`.

**Email Compliance Note:** System enforces email opt-out compliance by validating `HasOptedOutOfEmail` field before allowing email sending. This prevents legal/compliance violations.

### Multi-Successor Architecture Pattern

**Critical Design Pattern** - System handles scenarios where a DAF account has 2+ successors:

**Data Structure:**
```
Account (Deceased Donor)
├── FinancialAccount ($3.5M)
│   ├── FinancialAccountRole (Primary Owner → Deceased)
│   ├── FinancialAccountRole (Successor → Amanda, 50%)
│   └── FinancialAccountRole (Successor → Brandon, 50%)
├── Case (Type: "Multi-Account Succession Master")  ← Parent Case
│   ├── Child Case #1 (Type: "Named Successor Enactment", Contact: Amanda)
│   │   └── Tasks (Contact Attempts → Amanda)
│   └── Child Case #2 (Type: "Named Successor Enactment", Contact: Brandon)
│       └── Tasks (Contact Attempts → Brandon)
```

**Key Rules:**
1. **Single Successor:** Case Type = `Named Successor Enactment` (standard workflow)
2. **Multiple Successors:**
   - Flow `Case_Multiple_Successors_Handler` detects 2+ FinancialAccountRole records with Role = "Successor"
   - Creates parent case (Type: `Multi-Account Succession Master`)
   - Creates child case for each successor (Type: `Named Successor Enactment`)
   - Each child case gets independent contact cadence and SLA tracking
3. **Allocation Validation:** All `SuccessorAllocation__c` percentages must sum to 100%
4. **Hierarchy Component:** `caseHierarchyViewer` displays parent + all child cases in nested tree view

**Flow Trigger:**
```apex
// Case_Multiple_Successors_Handler.flow-meta.xml
Entry Criteria:
- RecordType = "EstateAdministration"
- Type = "Named Successor Enactment"
- Count of FinancialAccountRole (Role = "Successor") > 1
```

### Flow Architecture Pattern

**Self-Terminating Scheduled Paths** - Key architectural pattern:
- 4 record-triggered flows orchestrate the 5-phase workflow
- Scheduled paths include decision nodes that check "gate" fields
- Flows exit gracefully if conditions not met (e.g., `Contact_Established__c = TRUE`)
- No custom orchestration objects needed

**Contact Cadence Pattern (Phase 2: Informational Contact Only):**
- **Purpose:** Phone calls are INFORMATIONAL ONLY - Agent notifies successor of designation, expresses condolences, explains three pathway options. Agent CANNOT accept pathway instructions over phone.
- **Schedule:** Day 0, 5, 35, 65, 95 (max 5 attempts)
- **Task Creation Flow:**
  - **Attempt 1:** Auto-created by `Case_Create_Initial_Contact_Attempt` flow via **dual entry points:**
    - **Automatic:** Case CREATED with `Verification_Status__c = "Complete - Verified"` → Workflow starts immediately
    - **Manual:** Agent clicks "✅ Begin Succession Processing" Quick Action → Sets `Verification_Status__c = "Complete - Verified"` → Workflow starts
  - **Duplicate Prevention:** Flow checks `Contact_Attempt_Count__c` is NULL before creating Task #1 (prevents double-triggering)
  - **Attempts 2-5:** Auto-created by `Task_Create_Next_Contact_Attempt` flow IMMEDIATELY when previous attempt completed, BUT with ActivityDate set to scheduled date (Day 5, 35, 65, 95)
- **Date-Gating:** Agent CANNOT complete a task until its ActivityDate arrives. UI shows countdown: "Available in X days"
- **UI Component:** `successionContactCadence` LWC displays 5-attempt progress bar + kanban cards with lock states
- **Apex Controller:** `ContactCadenceController` provides attempt data, calculates date-gating, saves outcomes, **validates email compliance**
- **Task Management:** Each attempt has Task record with `Contact_Attempt_Number__c` (1-5) and scheduled `ActivityDate`
- **Sequential Lock Pattern:**
  - **Completed attempts** → Read-only display with status + notes
  - **Current attempt (date arrived)** → "Record Outcome" button enabled
  - **Current attempt (date not arrived)** → Locked with countdown display
  - **Future attempts** → Show "Waiting for previous attempt" message
- **Outcome Recording:** Agent marks "Contact Established" YES/NO + optional notes
  - **Positive Outcome (YES):** Sets `Contact_Established__c = TRUE` on Case → Triggers `Case_Send_Succession_Form` flow → Sends email with public form link
  - **Negative Outcome (NO):** Task marked complete, Flow immediately creates next task (with future date)
- **Circuit Breaker Flow:** `Task_Succession_Contact_Update` monitors Task updates and sets `Contact_Established__c` on Case when agent marks contact successful

**Public Form Workflow (Phase 3: Online Pathway Selection):**
- **Email Delivery:** `Case_Send_Succession_Form` flow sends email with link to public form
- **Form URL:** Contains URL parameters: `?caseId=500...&accountId=001...` (no tokens, relies on parameter obscurity)
- **Guest User Access:** Form accessible without login via Experience Cloud or public Site
- **Form Pre-Fill:** `SuccessionPublicFormController` reads URL params, queries Case/Account/FinancialAccount/Successor data, pre-fills form
- **LWC Component:** `successionPublicForm` displays pre-filled data + 3 pathway radio buttons + notes field
- **Form Submission:** Apex saves `Pathway_Selection__c`, sets `Pathway_Confirmed__c=TRUE`, updates `Form_Completed_Date__c`, changes Status to "Pathway Selection Received"
- **Agent Cannot Override:** Pathway selection MUST come from online form. Phone conversations are informational only.

**Flow Inventory (6 active flows):**
1. **`Case_Create_Initial_Contact_Attempt`** - Creates Attempt 1 task via dual entry points (CREATE or UPDATE)
   - **Trigger:** Case CREATE or UPDATE, `RecordType=EstateAdministration`, `Type=Named Successor Enactment`
   - **Entry Criteria:** `Verification_Status__c = "Complete - Verified"` AND `Contact_Attempt_Count__c` is NULL
   - **Dual Entry Points:**
     - **Automatic:** Case created with `Verification_Status__c = "Complete - Verified"` → Task #1 created immediately
     - **Manual:** Agent clicks "✅ Begin Succession Processing" Quick Action → Sets field → Task #1 created
   - **Action:** Creates Task with `Contact_Attempt_Number__c=1`, `ActivityDate=TODAY`, `Priority=High`
   - **Updates:** Sets `Contact_Attempt_Count__c=1` on Case
   - **Duplicate Prevention:** `Contact_Attempt_Count__c` check prevents re-triggering if field changes again
2. **`Task_Create_Next_Contact_Attempt`** - Creates next task when current attempt completed
   - **Trigger:** Task Update, `Status=Completed`, `Contact_Attempt_Number__c NOT NULL`
   - **Gate Check:** `Contact_Established__c=FALSE` (stops creating tasks if contact made)
   - **Action:** Creates next task (Attempt 2-5) with ActivityDate calculated from Case.CreatedDate
   - **Date Formulas:** Day 5 = CreatedDate + 5, Day 35 = +35, Day 65 = +65, Day 95 = +95
   - **Priority:** Attempts 2-3 = High, Attempts 4-5 = Urgent
3. **`Task_Succession_Contact_Update`** - Circuit breaker flow
   - **Trigger:** Task Update, `Status ISCHANGED to 'Completed'`, `Contact_Attempt_Number__c NOT NULL`
   - **Action:** Updates parent Case `Contact_Established__c=TRUE` if `Task.Succession_Contact_Established__c=TRUE`
   - **Cascade Effect:** Setting `Contact_Established__c=TRUE` triggers `Case_Send_Succession_Form` flow
4. **`Case_Multiple_Successors_Handler`** - Multi-successor orchestration (creates parent + child cases)
5. **`Case_Send_Succession_Form`** - Email delivery automation with public form link
   - **Trigger:** Case Update, `Contact_Established__c ISCHANGED to TRUE`
   - **Action:** Sends email with form URL (includes caseId parameter), updates `Form_Sent_Date__c`
   - **Email Content:** Notifies successor, explains 3 pathways, includes form link, clarifies phone calls are informational only
6. **`Case_Succession_Segment_Transition`** - Pathway transitions after form submission
7. **`Succession_Pathway_Selection_Flow`** - (DEPRECATED - pathway selection now handled by public form)
8. **`Case_Assign_Pathway_Action_Plan`** - Auto-creates pathway-specific Action Plan when `Form_Completed_Date__c` changes (public form submission)

### Component Architecture

**Apex Classes (3):**
- **Internal Controllers:** `CaseHierarchyController`, `ContactCadenceController`
- **Public Form Controller:** `SuccessionPublicFormController` - Guest user access with URL parameters
- **Security Model:** ALL use `WITH USER_MODE` for database operations, enforce FLS

**ContactCadenceController Email Validation Features:**
- Queries `PersonEmail` (Person Account) or `Contact.Email` (Business Account)
- Queries `HasOptedOutOfEmail` for compliance enforcement
- Validates email format using regex: `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`
- Returns validation data via `ContactCadenceData` wrapper:
  - `emailAddress` (String) - The actual email address
  - `hasEmail` (Boolean) - True if email exists and not blank
  - `hasValidEmailFormat` (Boolean) - True if passes regex validation
  - `hasOptedOut` (Boolean) - True if HasOptedOutOfEmail = true
  - `emailWarning` (String) - User-friendly warning message for UI display

**LWC Components (12):**
All prefixed with `succession` except `caseHierarchyViewer` and `recordPathwaySelection`:

- **`successionContactCadence`** - **Contact attempt tracker** (Phase 2 primary UI - INFORMATIONAL ONLY)
  - **Purpose:** Records contact outcomes (YES/NO), NOT pathway selection
  - **Visual Design:** Progress bar (0-100%) + 5 kanban-style attempt cards + email warning alerts
  - **Wire Adapter:** `@wire(getContactCadence)` fetches all 5 attempts from `ContactCadenceController`
  - **Email Validation Features:**
    - **Email Warning Alert:** Displays at top if `hasEmailWarning = true`
      - Warning shown for: Opted-out users, missing email, invalid email format
      - Icon: `utility:warning` with yellow alert styling
      - Message examples:
        - "⚠️ Successor has opted out of email. Contact by phone only."
        - "No email address on file for this successor."
        - "Email address format appears invalid: test@example"
    - **Email Existence Check:** `canSendEmail` computed property validates all criteria
    - **Opt-Out Protection:** "Send Email" button disabled if `hasOptedOut = true`
    - **Format Validation:** Button disabled if email format invalid
    - **Double-Click Prevention:** `isNavigatingToEmail` state disables button during navigation
    - **Loading State:** Button shows "Opening..." + spinner when email composer launching
  - **Sequential Lock UX:**
    - Completed attempts (positive OR negative) → Read-only display with status + notes
    - Current attempt (first incomplete) → "Record Outcome" button → Inline edit form
    - Future attempts → Disabled "Not Scheduled" state
  - **State Management:** `highestAttemptStarted` tracks user progression, prevents editing previous attempts
  - **Inline Form:** Radio buttons (YES/NO for "Was contact made?") + Textarea (optional notes) + Save/Cancel
  - **Outcome Handling:**
    - Calls `saveAttemptOutcome()` → Updates Task.Status='Completed' + Creates ContentNote + Chatter post
    - **YES:** Sets `Task.Succession_Contact_Established__c=TRUE` → Flow triggers automatic form invitation email → **No email prompt shown** → Contact cadence STOPS
    - **NO:** Flow creates next task (with future date) → **Shows "Send Email?" prompt with buttons** → Contact cadence continues
  - **Optional Email Prompt (NO outcomes only):**
    - **Trigger:** Appears in component immediately after saving NO outcome
    - **UI:** Blue info alert with "Send follow-up email? (Optional)" message
    - **Buttons:**
      - **"Send Email"** → Opens Salesforce email composer with Contact/Account pre-filled
        - Disabled if `canSendEmail = false` (email validation failed)
        - Shows loading spinner during navigation
        - Prevents double-click with 2-second timeout
      - **"Skip"** → Dismisses prompt, agent continues to next case
    - **Email Prompt Persistence:** Prompt STAYS VISIBLE even if agent closes composer without sending
      - Only clicking "Skip" explicitly dismisses the prompt
      - Allows agent to change mind and re-open composer
    - **Email Composer Behavior:**
      - **Person Account (typical):** Opens `Account.SendEmail` action with `Case.AccountId`
      - **Business Account + Contact:** Opens `Contact.SendEmail` action with `Case.ContactId`
      - **Auto-Detection:** Component checks `Account.IsPersonAccount` flag to determine which to use
      - Recipient is pre-filled automatically
      - **Agent must manually select template** from dropdown in composer
      - Toast message shows template name as reminder (e.g., "Person Account email opening. Select template: 'Day 0 - Initial Contact'")
      - **Why manual selection:** Lightning Experience does not support pre-selecting templates via URL parameters
    - **Email Templates Available (in Succession_Management folder):**
      - Attempt 1 → `Day 0 - Initial Contact`
      - Attempt 2 → `Day 5 - First Follow-Up`
      - Attempt 3 → `Day 35 - Second Contact`
      - Attempt 4 → `Day 65 - Third Contact`
      - Attempt 5 → `Day 95 - Final Contact`
    - **Scalability:** Works for high-volume agents (50+ cases/day) - no auto-opening windows, no pop-up blockers
    - **Agent Control:** Fully optional - agent decides per-case whether to send email
  - **Record Type Validation:** Only displays for `EstateAdministration` + `Named Successor Enactment` cases

- **`successionPublicForm`** - **Public pathway selection form** (Phase 3 primary UI - PATHWAY COLLECTION)
  - **Purpose:** Guest user form for successors to select pathway (Final Grant, New DAF, Disclaim)
  - **Access:** No login required, reads caseId from URL parameter
  - **Pre-Fill:** Displays account info, balance, allocation, successor name from database
  - **Form Fields:** 3 pathway radio buttons + optional notes textarea
  - **Submission:** Calls `SuccessionPublicFormController.savePathwaySelection()` → Updates Case
  - **Security:** Uses URL parameter obscurity (no tokens), guest user Apex with USER_MODE
  - **Deployment:** Experience Cloud or public Site with guest user profile

- `caseHierarchyViewer` - **Multi-successor hierarchy tree** - Displays parent "Multi-Account Succession Master" case with all child cases, financial accounts, and successors in nested view
- `recordPathwaySelection` - Quick action pathway selector (internal agent use)
- `successionAccountSummary` - Account details display
- `successionDisclaimDetails`, `successionNewDafDetails` - Pathway-specific forms
- `successionGrantBeneficiaries` - Beneficiary management for Final Grant pathway
- `successionPathwaySelector` - Pathway selection wizard (internal agent use)
- `successionReviewAndSign` - Final review & signature
- `successionSuccessorInfo` - Successor information form

**Component Communication Pattern:**
- Parent: `successionPathwayForm` (main container)
- Children: Pathway-specific components communicate via custom events
- Use `@wire` for Case and Contact data
- Use `getRecord` from `lightning/uiRecordApi` for Case data

### Manifest Strategy

Multiple deployment manifests in `manifest/` directory:
- `package.xml` - Complete deployment
- `package-succession-*.xml` - Targeted deployments (fields-only, flows, permissions, etc.)
- `destructiveChanges*.xml` - Staged destructive changes (flows first, then remaining)

Use targeted manifests for incremental deployments to reduce deployment time.

### Public Form Deployment

Public-facing succession pathway form accessible without login:
- **Recommended Approach:** Experience Cloud Site with guest user access OR Force.com Site
- **Form URL Pattern:** `https://yoursite.com/succession-form?caseId=500...&accountId=001...`
- **LWC Component:** `successionPublicForm` (exposed for Community/Site pages)
- **Apex Controller:** `SuccessionPublicFormController` (guest user accessible)
- **Security:** URL parameter obscurity (no authentication tokens), guest user permissions
- **Setup Steps:**
  1. Create Experience Cloud Site or Force.com Site
  2. Configure guest user profile with read access to Case, Account, Contact, FinancialAccount objects
  3. Add `successionPublicForm` LWC to site page
  4. Update email template in `Case_Send_Succession_Form` flow with actual form URL

## Test Data Generation

### Via CumulusCI + Snowfakery
```bash
cci task run load_succession_test_data          # Complete dataset
cci task run load_final_grant_scenario          # Phase 1-5 complete lifecycle
cci task run load_multi_successor_scenario      # Multiple successors with splits
cci task run load_sla_escalation_scenario       # Unresponsive successor
cci task run load_demo_ui_showcase              # UI component demo data
```

**CRITICAL for Demo:** Ensure all test data Person Accounts have valid email addresses in correct format. See [DEMO_PREP_CHECKLIST.md](docs/DEMO_PREP_CHECKLIST.md) for validation steps.

## Development Workflow

### Making Code Changes

1. **Create/edit components** in `force-app/main/default/`
2. **Run tests locally:**
   - Apex: Cannot run locally, deploy and test in org
   - LWC: `npm run test:unit` before committing
3. **Lint and format:** Pre-commit hooks auto-run via Husky
4. **Deploy:** Use targeted manifests or specific directories
5. **Test in org:** Assign permission sets, use test data generator

### LWC Development Pattern

```bash
# Terminal 1: Start local dev server
sf lightning dev app --name successionContactCadence

# Terminal 2: Edit files in VS Code
# Save → Auto-reload in browser

# Terminal 3: Deploy Apex changes when needed
sf project deploy start --source-dir force-app/main/default/classes
```

### Pre-Commit Hooks

Husky + lint-staged automatically runs:
- Prettier formatting on all files
- ESLint on LWC/Aura JS files
- Jest tests on modified LWC components

To bypass (not recommended): `git commit --no-verify`

## Critical Patterns & Conventions

### Multi-Successor Pattern
- **Detection:** `Case_Multiple_Successors_Handler` flow counts FinancialAccountRole records where Role = "Successor"
- **Parent Case Creation:** When count > 1, creates parent case with Type = "Multi-Account Succession Master"
- **Child Case Creation:** One child case per successor, each with independent workflow
- **Case Hierarchy:** Use `ParentId` field to link child cases to parent
- **Testing:** Always test with `load_multi_successor_scenario` data to verify parent-child relationships
- **Component Display:** `caseHierarchyViewer` should only be used on parent cases

### Contact Cadence Development Pattern
- **LWC State Management:**
  - Use `@wire(getContactCadence)` with `refreshApex()` after saves
  - Display logic based on `isCurrent`, `isLocked`, `isPending`, `isCompleted` flags
  - Show countdown text for locked tasks: `attempt.countdownText`
  - Use `canSendEmail` computed property to validate email availability
  - Use `hasEmailWarning` / `emailWarningMessage` for displaying validation errors
- **Apex Controller Pattern:**
  - `getContactCadence()` calculates date-gating: `Date.today() vs Task.ActivityDate`
  - Returns `isLocked=true` if task exists but `ActivityDate > today`
  - Returns `daysUntilAvailable` and `countdownText` for UI display
  - First incomplete attempt with arrived date gets `isCurrent=true`
  - **Email Validation:** Calls `validateEmailAddress()` method to check:
    - Email existence (PersonEmail or Contact.Email not NULL)
    - Email format validity (regex validation)
    - Opt-out status (HasOptedOutOfEmail field)
- **Task Field Pattern:**
  - `Contact_Attempt_Number__c` (Number, 1-5) - Identifies attempt sequence
  - `ActivityDate` (Date) - Scheduled date, gates when agent can complete
  - `Succession_Contact_Established__c` (Checkbox) - Triggers circuit breaker flow
  - `Description` (Long Text) - Appends timestamped notes, also creates ContentNote
- **Flow Pattern (Task Creation):**
  - `Case_Create_Initial_Contact_Attempt`: Creates Attempt 1 via **dual entry points** (CREATE and UPDATE triggers)
    - **Automatic Entry:** Case created with `Verification_Status__c = "Complete - Verified"` → Task #1 created immediately
    - **Manual Entry:** Agent clicks "✅ Begin Succession Processing" Quick Action → Sets field → Task #1 created
  - Duplicate prevention: Checks `Contact_Attempt_Count__c` is NULL before creating task
  - `Task_Create_Next_Contact_Attempt`: Triggered by Task completion, creates next task
  - Uses formulas to calculate ActivityDate: `DATEVALUE(Case.CreatedDate) + [days]`
  - Gate check: `Contact_Established__c=FALSE` (stops creating if contact made)
- **Date-Gating Pattern:**
  - Tasks created immediately but locked until ActivityDate arrives
  - Apex calculates `today.daysBetween(ActivityDate)` for countdown
  - LWC shows lock icon + countdown for future-dated tasks
  - "Record Outcome" button only enabled when date arrives

### Email Validation & Compliance Pattern ⚠️ CRITICAL

**Tier 1 Critical Fixes** (Implemented 2025-10-14) - See [TIER_1_FIXES_SUMMARY.md](docs/TIER_1_FIXES_SUMMARY.md) for complete details.

**Fix #1: Email Existence Validation**
- **Apex:** `ContactCadenceController.validateEmailAddress()` checks PersonEmail/Contact.Email is not NULL/blank
- **LWC:** `canSendEmail` computed property returns false if `hasEmail = false`
- **UI:** "Send Email" button disabled, warning shown: "No email address on file for this successor"

**Fix #2: Email Opt-Out Validation (Legal/Compliance)**
- **Apex:** Queries `Account.HasOptedOutOfEmail` or `Contact.HasOptedOutOfEmail`
- **LWC:** `canSendEmail` returns false if `hasOptedOut = true`
- **UI:** "Send Email" button disabled, warning shown: "⚠️ Successor opted out of email. Contact by phone only."
- **Purpose:** Prevents legal/compliance violations by blocking emails to users who opted out

**Fix #3: Email Format Validation**
- **Apex:** Regex validation: `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`
- **LWC:** `canSendEmail` returns false if `hasValidEmailFormat = false`
- **UI:** "Send Email" button disabled, warning shown: "Email address format appears invalid: [email]"

**Fix #4: Double-Click Prevention**
- **LWC:** `isNavigatingToEmail` state variable prevents multiple composer windows
- **UI:** Button shows "Opening..." + spinner, disabled for 2 seconds during navigation
- **Purpose:** Prevents confusing UX from multiple email composers opening

**Fix #5: Email Prompt Persistence**
- **LWC:** `pendingEmailAttemptNumber` NOT cleared when composer opens
- **LWC:** Only cleared when agent clicks "Skip" button explicitly
- **Purpose:** Allows agent to re-open composer if they close it without sending

**Testing Email Validation:**
- Test with Person Account: NULL PersonEmail → Button disabled
- Test with opted-out user: HasOptedOutOfEmail=true → Warning shown
- Test with invalid format: email="test@example" → Format error shown
- Test double-click: Click "Send Email" 3 times rapidly → Only 1 composer opens

### Quick Action Pattern (`recordPathwaySelection`)
- Component allows agents to record pathway selection via Quick Action button
- If `Contact_Established__c` is FALSE, sets it to TRUE automatically
- Uses standard `LastModifiedDate` for audit trail (no custom date field)
- Sets `Pathway_Confirmed__c` to selected pathway value
- Triggers downstream flows (form email, action plan assignment)
- **Component Location:** `force-app/main/default/lwc/recordPathwaySelection/`
- **Use Case:** Agent-facing Quick Action for fast pathway recording after phone conversation
- **Fields Updated:**
  - `Pathway_Confirmed__c` - Selected pathway (Final Grant, New DAF Account, Disclaim Assets)
  - `Contact_Established__c` - Auto-set to TRUE if not already established
  - `LastModifiedDate` - Auto-updated by Salesforce when Contact_Established__c changes
- **No Custom Date Tracking:** Relies on standard Salesforce audit fields for simplicity

### Flow Development
- **Always** call `Flow_Error_Handler` subflow for error handling
- Use scheduled paths with decision node gates (don't rely on "always execute")
- Set `Contact_Attempt_Count__c` for cadence tracking
- Check `Contact_Established__c` gate field before executing scheduled actions
- **Multi-successor flows:** Ensure flows check Case Type to avoid triggering on parent "Multi-Account Succession Master" cases

### Apex Security
- **Required:** ALL database operations use `WITH USER_MODE`
- **Required:** Enforce field-level security
- **Required:** Use `@AuraEnabled(cacheable=true)` for read operations
- **Required:** Use `try/catch` and proper error handling
- **Email Validation:** Always validate opt-out status before sending emails (compliance requirement)

### LWC Patterns
- Use `@wire` for data retrieval when possible
- Implement proper error handling in `@wire` error handlers
- Use Lightning Data Service (LDS) for CRUD operations
- Follow naming: `succession<FeatureName>` pattern
- **Email Validation:** Use computed properties (`canSendEmail`, `hasEmailWarning`) for validation logic
- **Double-Click Prevention:** Use state variables and button disable logic to prevent duplicate actions

### Permission Sets
Always test with proper permission sets assigned:
- `Succession_Management_Access` - Full access to succession features
- `Succession_Field_Access` - Field-level access
- **Email Template Access:** Ensure permission sets include access to `Succession_Management` email template folder

### SLA Configuration
Configured in Setup → Entitlement Processes → **Estate Succession SLA**:
- Initial Response: 24 hours
- Standard Resolution: 90 days
- Critical Escalation: 80 days

## Documentation Reference

### Core Documentation (docs/)

**Critical References:**
- **`DEMO_PREP_CHECKLIST.md`** - ⚠️ **CRITICAL** Pre-demo setup checklist (sandbox email verification, template validation, test data)
- **`PERSON_ACCOUNT_FIXES.md`** - ⚠️ **CRITICAL** FSC Person Account compatibility fixes (flows, Apex, Snowfakery mapping)
- **`TIER_1_FIXES_SUMMARY.md`** - Email validation & compliance fixes technical reference
- **`snowfakery-data-model-analysis.md`** - ⚠️ **CRITICAL** Complete object relationships, FSC field standards, Snowfakery guide (updated 2025-10-14)

**Component & Testing Guides:**
- `MULTI_SUCCESSOR_HIERARCHY_COMPONENT.md` - OmniStudio case hierarchy component guide
- `MULTI_SUCCESSOR_TESTING_GUIDE.md` - Comprehensive multi-successor testing scenarios (677 lines)
- `field-documentation-succession.md` - All custom field definitions with help text and BRD references

**Implementation Guides:**
- `AUTOMATION-CONTROL-GUIDE.md` - CumulusCI automation control during data loading
- `cumulusci-snowfakery-implementation-guide.md` - CumulusCI/Snowfakery setup and usage guide
- `CUMULUSCI_CICD_GUIDE.md` - CI/CD pipeline reference (GitHub Actions workflows)

**Audit & Change History:**
- `DOCUMENTATION_AUDIT_2025-10-14.md` - Documentation audit and cleanup summary

**Before Demo:** Complete all steps in [DEMO_PREP_CHECKLIST.md](docs/DEMO_PREP_CHECKLIST.md) at least 24 hours before presentation.

## Monitoring & Debugging

### Flow Errors
- Navigate to Setup → Environments → Flows → View Flow Errors
- Review native Salesforce flow error logs
- Check error details for stack traces and retry options

### SLA Monitoring
- List views: "SLA At Risk", "SLA Critical Escalate"
- Monitor `Contact_Attempt_Count__c` and case age

### Debug Logs
```bash
# Enable debug logs for your user
sf data query --query "SELECT Id, Name FROM User WHERE Username = 'josh.rojas.charfsc@schwab.com.fscjosh'" --use-tooling-api

# View recent logs
sf apex get log --number 1
```

### Email Validation Debugging
```bash
# Check Person Account email
sf data query --query "SELECT Id, Name, PersonEmail, HasOptedOutOfEmail FROM Account WHERE Id = '<ACCOUNT_ID>'" --target-org schwab-sandbox

# Check Contact email
sf data query --query "SELECT Id, Email, HasOptedOutOfEmail FROM Contact WHERE Id = '<CONTACT_ID>'" --target-org schwab-sandbox

# Find accounts without email
sf data query --query "SELECT Id, Name FROM Account WHERE IsPersonAccount = true AND PersonEmail = null" --target-org schwab-sandbox
```

## Known Issues & Workarounds

- **Node.js v24.x incompatibility:** Use Node.js v20.x (LTS) for Lightning Local Development
- **Multi-successor scenarios:** Ensure parent case created before child cases (hierarchy pattern)
- **Sandbox email deliverability:** Emails only sent to verified addresses in sandbox - see [DEMO_PREP_CHECKLIST.md](docs/DEMO_PREP_CHECKLIST.md)

## Demo Configuration Notes

- **No validation rules:** All validation rules have been removed from this project to facilitate easy live demonstrations. Do not add them back.
- **No automated escalation flows:** Critical case escalations are visible via the "🔴 Critical - Escalate" list view instead of automated emails/Chatter posts
- **No error handling infrastructure:** Removed custom error logging (Flow_Error__c object, Error_Notification__e event, Flow_Error_Handler flow) - native Salesforce flow error logs are sufficient for demo
- **No processing metrics flow:** Analytics handled via reports, not automated Case.Description updates
- **Simplified public form:** Uses URL parameter obscurity instead of token-based authentication for demo simplicity
- **Simplified workflows:** Flows are designed for demo clarity, not production rigor
- **Test data via CumulusCI:** Use Snowfakery recipes in `datasets/` directory for consistent demo data generation
- **Email validation enforced:** System validates opt-out status, email existence, and format to prevent demo failures

## End-to-End Workflow Summary

**Critical Workflow Rules:**
1. **Phone calls are INFORMATIONAL ONLY** - Agent notifies successor, explains options, expresses condolences. Agent CANNOT accept pathway instructions over phone.
2. **Pathway selection MUST come from online public form** - No phone-based pathway recording, no wet signature alternative in this demo version.
3. **Contact cadence component records YES/NO outcomes** - "Was contact made?" (not pathway selection)
4. **Email includes public form link** - Successor completes form independently after phone call
5. **Email validation enforced** - System prevents sending to opted-out users or invalid email addresses (compliance requirement)

**Integration Chain:**
1. **Agent creates Case** → `Verification_Status__c` defaults to "Not Started"
2. **Agent clicks "✅ Begin Succession Processing" Quick Action button** → Sets `Verification_Status__c = "Complete - Verified"`
3. Flow `Case_Create_Initial_Contact_Attempt` (**UPDATE trigger** on `Verification_Status__c ISCHANGED`) → Creates Task #1 (Day 0)
4. Agent uses `successionContactCadence` LWC → Records contact outcome (YES/NO + notes)
   - **Email Validation Check:** Component validates email exists, format valid, not opted-out
   - **If validation fails:** Email warning alert shown, "Send Email" button disabled
   - **If NO (and validation passes):** Component shows "Send follow-up email?" prompt with **"Send Email"** and **"Skip"** buttons
   - **Agent choice:** Click "Send Email" to open composer with pre-filled template OR click "Skip" to continue
   - **Email prompt persistence:** Prompt stays visible even if agent closes composer (only "Skip" dismisses it)
   - **Scalable:** No auto-opening windows, works for high-volume processing (50+ cases/day)
5. If YES: Flow `Task_Succession_Contact_Update` → Sets `Contact_Established__c = TRUE`
6. Flow `Case_Send_Succession_Form` (triggered by `Contact_Established__c` change) → **Automatically sends email** with form link (uses `Pathway_Form_Invitation` template)
7. Successor clicks link → Opens `successionPublicForm` LWC (guest user access)
8. Successor selects pathway → `SuccessionPublicFormController.savePathwaySelection()` → Updates Case
9. Case status changes to "Pathway Selection Received" → Flow `Case_Succession_Segment_Transition` continues workflow

**Dual Entry Points:**

**Manual Entry (Quick Action):**
- **🎯 Intentional Start:** Agent explicitly controls when succession processing begins
- **👁️ Visible Entry Point:** Large "✅ Begin Succession Processing" Quick Action button on case page
- **📋 Agent Control:** Cases can remain in "Not Started" until agent is ready
- **🎪 Demo-Friendly:** Visible button demonstrates clear workflow entry point during live presentations

**Automatic Entry (Case Creation):**
- **🚀 Natural Workflow:** Creating case with `Verification_Status__c = "Complete - Verified"` starts workflow immediately
- **📊 Bulk Processing:** External systems can create cases that auto-start workflow (e.g., Email-to-Case, API integrations)
- **⚡ Streamlined:** No extra click needed when case is ready to process
- **🎪 Demo-Friendly:** Can demonstrate end-to-end workflow from single case creation

**Email Strategy:**
- **Automated:** Pathway form invitation email (Step 6) - System automatically sends when contact is established
  - Uses `Pathway_Form_Invitation` template
  - Includes public form link with caseId parameter
  - Agent cannot skip or modify this email (critical workflow trigger)
  - **Validation:** System checks email validity before sending
- **Optional (Agent Choice):** Contact cadence emails (Day 0, 5, 35, 65, 95)
  - **Trigger:** When agent records "NO" outcome, component shows blue info alert: "Send follow-up email? (Optional)"
  - **Email Validation:** Component validates email before showing prompt
    - If opted-out: Warning shown, button disabled
    - If no email: Warning shown, button disabled
    - If invalid format: Warning shown, button disabled
  - **Agent Choice:** Click **"Send Email"** button to open composer OR click **"Skip"** button to dismiss
  - **Pre-Filled (if sent):** Contact recipient + template manually selected in composer
  - **Templates:** `Day 0 - Initial Contact`, `Day 5 - First Follow-Up`, `Day 35 - Second Contact`, `Day 65 - Third Contact`, `Day 95 - Final Contact`
  - **Scalability:** No auto-opening windows = works for high-volume agents (50+ cases/day)
  - **Truly Optional:** Agent can process 50 cases and skip all emails without interruption
  - **Persistence:** Email prompt stays visible until agent clicks "Skip" (allows changing mind)

**Note:** There is no formal validation/verification phase. Cases arrive with all required documents already attached in 90%+ of scenarios (death certificate, ID, etc.). However, workflow does NOT start automatically - agent must click the "✅ Begin Succession Processing" Quick Action button to intentionally begin the contact cadence.

## Field Simplification

### **Removed Contact Cadence Fields**
The following Case fields were removed after transitioning from scheduled flow-based contact cadence to task-based approach:

- ❌ **`Next_Contact_Due__c`** - Obsolete with task-based approach (use `Task.ActivityDate` instead)
- ❌ **`Last_Contact_Attempt__c`** - Can be derived from `MAX(Task.CompletedDateTime)` if needed

**Kept Contact Cadence Fields:**
- ✅ **`Contact_Established__c`** (Checkbox) - Gate field for flows, marks when successor contact is successful
- ✅ **`Contact_Established_Date__c`** (DateTime) - Important audit/compliance timestamp, actively set by flows and Apex
- ✅ **`Contact_Attempt_Count__c`** (Number) - Tracks total attempts for reporting and SLA monitoring

**Task-Based Approach:**
- Each contact attempt is a Task record with `Contact_Attempt_Number__c` (1-5)
- Tasks have `ActivityDate` for scheduled date (date-gating)
- Tasks have `Succession_Contact_Established__c` checkbox to mark positive outcomes
- Query Task records for contact history instead of using Case summary fields

### **Removed Document Collection Fields**
The following Case fields were removed because there is no formal document collection/verification phase. In 85-90% of cases, required documents (death certificate, ID, successor designation) are already attached when the case is created:

- ❌ **`Documents_Complete__c`** - Checkbox for document completion status
- ❌ **`Documents_Received__c`** - Multi-select picklist tracking specific documents
- ❌ **`Document_Review_Status__c`** - Picklist for review workflow (Not Started, In Review, Approved, etc.)
- ❌ **`Document_Reviewer__c`** - User lookup for document reviewer assignment
- ❌ **`Documents_Complete_Date__c`** - Timestamp for document completion

**Kept Verification Field (Simplified):**
- ✅ **`Verification_Status__c`** - Simplified to 2 values: "Not Started" (default) → "Complete - Verified"
  - **Purpose:** Manual workflow trigger field controlled by Quick Action (NOT actual verification process)
  - **Default Value:** "Not Started" - ensures workflow does not begin automatically
  - **Manual Trigger:** Agent clicks "✅ Begin Succession Processing" Quick Action button to set value to "Complete - Verified"
  - **Flow Trigger:** `Case_Create_Initial_Contact_Attempt` flow (UPDATE trigger with ISCHANGED filter) creates Task #1 when agent changes this field
  - **Design Philosophy:** Provides visible, intentional entry point for workflow start despite 90%+ of cases arriving ready to process

**Removed Components:**
- ❌ **`successionDocumentUpload`** LWC component - No document upload workflow needed
- ❌ **`Succession_Documentation_Request`** email template - No document request emails needed
- ❌ **`Awaiting Verification`** list view - Verification is instant, not a queue

## Case Status Values

**Estate Administration Record Type** uses 8 simplified status values optimized for demo clarity:

- **New** - Case created, agent hasn't started processing
- **In Progress** - Agent clicked "Begin Succession Processing", active work (contact cadence, pathway execution)
- **Awaiting Response** - Form sent to successor, waiting for pathway selection
- **In Review** - Agent reviewing pathway selection or documents
- **On Hold** - Paused for external dependency
- **Escalated** - Sent to compliance/management (4+ contact attempts, 65+ days)
- **Closed** - Succession successfully completed
- **Canceled** - Succession abandoned (successor disclaimed, case withdrawn)

**Status Workflow Mapping:**
- **Phase 1-2** (Contact Cadence): "In Progress"
- **Phase 3** (Form Sent): "Awaiting Response"
- **Phase 3** (Form Received): "In Review"
- **Phase 4** (Pathway Execution): "In Progress"
- **Phase 5** (Complete): "Closed"
- **Edge Cases**: "On Hold", "Escalated", "Canceled"

**Business Process:** `Estate_Administration` restricts Status picklist to these 8 values for cleaner UX.
