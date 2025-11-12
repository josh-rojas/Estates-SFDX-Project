# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Succession Management System v1.0** - A Salesforce Financial Services Cloud application for Schwab Charitable Fund that automates deceased donor account transitions through three succession pathways: Final Grant, New DAF Account, and Disclaim Assets.

**Environment:** Demo/sandbox environment optimized for live demonstrations
**Target Org:** schwab-sandbox (josh.rojas.charfsc@schwab.com.fscjosh)

## ⚠️ Critical: Demo Environment

This is a demonstration project built in a sandbox environment:

- **Demo-first development** - Features designed to showcase capabilities
- **No validation rules** - Removed to prevent blocking demo scenarios
- **Simplified workflows** - Optimized for demonstration clarity
- **Email validation enforced** - Prevents demo failures with opted-out users
- **DO NOT add production constraints** - Keep demos flexible and easy to execute

## Core Architecture

### Data Model - Standard Objects Only

The system uses **only standard Salesforce objects** - no custom objects:

**Case (Record Type: EstateAdministration)**
- Type: "Named Successor Enactment" or "Multi-Account Succession Master"
- Custom fields track 5-phase workflow progression
- Parent-child hierarchy for multi-successor scenarios

**Account (Person Accounts - FSC)**
- Individual donors using Person Account model
- Fields: PersonEmail, PersonMobilePhone, PersonHasOptedOutOfEmail
- Virtual Contact relationship via PersonContactId

**FinancialAccount (FinServ__FinancialAccount__c)**
- DAF accounts with balance tracking
- Links to Account via FinServ__PrimaryOwner__c

**FinancialAccountRole (FinServ__FinancialAccountRole__c)**
- Successor designation with allocation percentages
- Custom field: SuccessorAllocation__c (percentage)

**Task**
- Contact attempt tracking with custom fields
- Contact_Attempt_Number__c (1-5)
- Succession_Contact_Established__c (outcome tracking)
- ActivityDate for date-gating

### 4-Phase Workflow (Automatic Start)

**Workflow starts automatically when case is created** - No manual verification step required. The CreateSuccessionCaseController validates successors and allocations during case creation, so verification is implicit and complete before the case is created.

**Phase 1: Contact Cadence** (5 attempts over 95 days)
- Day 0, 5, 35, 65, 95 contact schedule
- First contact task created automatically when case is created
- Phone calls are **informational only** - agent cannot accept pathway decisions
- successionContactCadence LWC displays progress + email validation
- Tasks created automatically by flows

**Phase 2: Pathway Selection**
- Email sent automatically when contact established
- Successor completes public form (successionPublicForm LWC)
- Three pathways: Final Grant, New DAF Account, Disclaim Assets

**Phase 3: Pathway Execution**
- SuccessionTaskGenerator creates pathway-specific tasks
- Final Grant: 5 tasks over 20 days
- New DAF: 4 tasks over 18 days
- Disclaim: 4 tasks over 20 days

**Phase 4: Case Closure**
- All pathway tasks completed
- Financial account status updated
- Case closed

## Multi-Successor Pattern

**Critical Pattern:** When 2+ successors exist:

1. `CreateSuccessionCaseController` (Apex) detects multiple FinancialAccountRole records
2. Creates parent case (Type: "Multi-Account Succession Master")
3. Creates child case for each successor (Type: "Named Successor Enactment")
4. Each child case has independent workflow
5. Parent auto-closes when all children complete (Flow: `Case_Parent_Closure_Handler`)

**Component:** `caseHierarchyViewer` LWC displays parent + child hierarchy

**Note:** Multi-successor detection was migrated from Flow to Apex for better performance and complex logic handling.

## Apex Classes (8 active, 1 deprecated)

### ContactCadenceController
**Purpose:** Manages contact attempt data + email validation
**Key Methods:**
- `getContactCadence()` - Returns 5 attempts with date-gating + email validation
- `saveAttemptOutcome()` - Saves contact outcome, creates ContentNote + Chatter post
- `validateEmailAddress()` - Checks email existence, format, opt-out status

**Email Validation:** CRITICAL compliance feature
- Validates PersonEmail/Contact.Email exists
- Checks HasOptedOutOfEmail field (legal requirement)
- Regex validation for email format
- Returns warnings for UI display

### CaseHierarchyController
**Purpose:** Displays parent-child case hierarchy for multi-successor scenarios
**Key Method:**
- `getCaseHierarchy()` - Returns parent + all child cases with financial accounts

### SuccessionPublicFormController
**Purpose:** Guest user form for pathway selection (no authentication)
**Key Methods:**
- `getFormData()` - Pre-fills form with case/account/successor data
- `savePathwaySelection()` - Saves pathway selection, triggers workflow

**Security:** Uses URL parameter obscurity (caseId) for guest access

### SuccessionTaskGenerator
**Purpose:** Creates pathway-specific tasks when pathway selected
**Pattern:** Trigger-based task creation (called from Case trigger)
**Templates:**
- Final Grant: 5 tasks (Day 2-20)
- New DAF: 4 tasks (Day 2-18)
- Disclaim: 4 tasks (Day 3-20)

### CreateSuccessionCaseController
**Purpose:** Multi-successor case creation with validation
**Key Methods:**
- `createSuccessionCase()` - Creates single or multi-successor cases
- `validateSuccessors()` - Validates allocation percentages and contact data
- `createMultiSuccessorStructure()` - Creates parent + child case hierarchy

**Pattern:** Replaces Flow-based case creation for better complex logic handling
**Validation:** Checks 100% allocation total, successor contact existence

### BeginSuccessionProcessingController
**Status:** DEPRECATED - No longer needed as of v1.1
**Legacy Purpose:** Workflow trigger via Quick Action

**Note:** The verification phase was removed in v1.1. Workflows now start automatically when cases are created. This controller and its associated Quick Action (beginSuccessionProcessing) are retained for backward compatibility but are no longer used in the standard workflow.

### SuccessionTaskCreator
**Purpose:** Invocable Apex for flow-based contact task creation
**Key Method:**
- `createContactAttemptTasks()` - Creates contact attempt tasks from flows with duplicate prevention

**Pattern:** Invocable method for flow-based task creation
**Usage:** Invocable Apex class for contact task creation (referenced by inactive flows)
**Features:**
- Bulk processing support with centralized logic
- Advanced duplicate prevention (bulk query with composite keys)
- Date-gated scheduling (Days 0, 5, 35, 65, 95)
- Response wrapper with success/skip status and error messages
- Eliminates code duplication (replaced 400+ lines of flow XML)

### SuccessionChatterPoster
**Purpose:** Invocable Apex for posting succession workflow transition messages to Chatter
**Key Method:**
- `postTransitions()` - Posts workflow transition messages with standardized formatting

**Pattern:** Invocable method for Chatter transition notifications
**Usage:** **ACTIVE** - Called from `Case_After_Update_Handler` flow (consolidated flow in v1.1)
**Transition Types:**
- `CONTACT_ESTABLISHED` - Successor contact made, ready to send form
- `FORM_COMPLETED` - Pathway form submitted by successor
- `PATHWAY_CONFIRMED` - Pathway execution tasks generated
- `VERIFICATION_COMPLETE` - Verification phase completed
- `EXECUTION_COMPLETE` - All pathway tasks completed
**Features:**
- Centralized message templates with emojis and formatting
- Uses SuccessionUtilities.createChatterPost() for consistency
- Optional pathway name and additional context
- Response wrapper with success/failure status
- Replaces hardcoded strings in flows with reusable Apex
**Note:** Referenced by inactive flows in this codebase

### SuccessionUtilities
**Purpose:** Shared utility class for common patterns
**Key Methods:**
- `validateEmail()` - Email compliance validation (RFC 5322 format, opt-out check)
- `createChatterPost()` - Standardized Chatter post creation
- `getRecordTypeId()` - Cached record type lookup for performance
- `createContentNote()` - ContentNote creation with error handling

**Pattern:** Static utility methods with WITH SHARING for security
**Refactored From:** ContactCadenceController, CreateSuccessionCaseController
**Benefits:** Reduces code duplication, centralizes validation logic, improves maintainability

## Lightning Web Components (5 active, 1 deprecated)

### successionContactCadence
**Location:** `force-app/main/default/lwc/successionContactCadence/`
**Purpose:** PRIMARY UI - Contact attempt tracker with email validation
**Features:**
- Progress bar (0-100%)
- 5 kanban-style attempt cards
- Sequential lock UX (complete attempts in order)
- Email validation warnings
- Optional email sending after negative outcomes
- Double-click prevention for email composer

**Email Validation Display:**
- Warning alert shown if opted-out, missing email, or invalid format
- "Send Email" button disabled when validation fails
- Email prompt persists until agent clicks "Skip"

**Key Pattern:** Date-gating - tasks locked until ActivityDate arrives

### caseHierarchyViewer
**Location:** `force-app/main/default/lwc/caseHierarchyViewer/`
**Purpose:** Displays multi-successor hierarchy tree
**Features:**
- Parent case + all child cases
- Financial account details
- Successor allocations
- Expandable sections

**Usage:** Add to parent "Multi-Account Succession Master" cases only

### successionPublicForm
**Location:** `force-app/main/default/lwc/successionPublicForm/`
**Purpose:** Guest user pathway selection form
**Features:**
- Reads caseId from URL parameter
- Pre-fills account + successor data
- Three pathway radio buttons
- Optional notes field

**Deployment:** Experience Cloud Site or Force.com Site with guest user access

### recordPathwaySelection
**Location:** `force-app/main/default/lwc/recordPathwaySelection/`
**Purpose:** Quick Action for agents to record pathway
**Features:**
- Three buttons (Final Grant, New DAF, Disclaim)
- Auto-sets Contact_Established__c if not set
- Updates Pathway_Confirmed__c field

**Usage:** Agent-facing Quick Action for fast pathway recording

### createSuccessionCase
**Location:** `force-app/main/default/lwc/createSuccessionCase/`
**Purpose:** Quick Action for creating succession cases from Financial Account
**Features:**
- Financial account selection
- Deceased donor validation
- Successor detection and display
- Multi-successor allocation validation

**Usage:** Placed on FinancialAccount record page as Quick Action

### beginSuccessionProcessing
**Status:** DEPRECATED - No longer needed as of v1.1
**Location:** `force-app/main/default/lwc/beginSuccessionProcessing/`
**Legacy Purpose:** Quick Action to trigger workflow start

**Note:** The verification phase was removed in v1.1. Workflows now start automatically when cases are created. This component is retained for backward compatibility but is no longer used in the standard workflow. Consider removing this Quick Action from Case record page layouts.

## Quick Actions for FinancialAccountRole Creation

**Purpose:** Enable creation of Financial Account Role records (successors, beneficiaries, co-owners) from multiple contexts with field pre-population.

**⚠️ Person Account Note:** This project uses Person Accounts (Financial Services Cloud). The virtual Contact (PersonContactId) is automatically populated when creating roles from Person Account context.

### Quick Actions (3 total)

#### 1. Object-Level Quick Action
**File:** `FinServ__FinancialAccountRole__c.New_Financial_Account_Role.quickAction-meta.xml`
**Label:** New Financial Account Role
**Context:** FinancialAccountRole list views and record pages
**Fields:**
- FinServ__FinancialAccount__c (Required)
- FinServ__RelatedContact__c (Required)
- FinServ__Role__c (Required - Successor, Primary Owner, Beneficiary, etc.)
- SuccessorAllocation__c (Optional - percentage for multi-successor scenarios)
- FinServ__Active__c (Optional - defaults to true)
- FinServ__StartDate__c (Optional)
- FinServ__EndDate__c (Optional)

**Availability:**
- FinancialAccountRole object home page
- FinancialAccountRole list views (All, Successors, etc.)
- FinancialAccountRole record pages (via Clone)

---

#### 2. FinancialAccount Context Quick Action
**File:** `FinServ__FinancialAccount__c.New_Account_Role.quickAction-meta.xml`
**Label:** New Account Role
**Context:** FinancialAccount record pages and related lists
**Pre-populated:** FinServ__FinancialAccount__c (automatically from parent record)
**Fields Shown:**
- FinServ__RelatedContact__c (Required - select Person Account's virtual contact)
- FinServ__Role__c (Required)
- SuccessorAllocation__c (Optional)
- FinServ__Active__c (Optional)
- FinServ__StartDate__c (Optional)
- FinServ__EndDate__c (Optional)

**Usage:** Create roles for a specific financial account without manually selecting the account

**Where to Add:**
1. Setup → Object Manager → Financial Account → Lightning Record Pages
2. Edit existing page → Highlights Panel → Mobile & Lightning Actions
3. Add "New Account Role" to action list
4. Also available on FinancialAccountRole related lists on any object's page layout

---

#### 3. Person Account (Account) Context Quick Action
**File:** `Account.New_Financial_Account_Role.quickAction-meta.xml`
**Label:** New Financial Account Role
**Context:** Person Account record pages
**Pre-populated:** FinServ__RelatedContact__c (automatically via Account.PersonContactId)
**Fields Shown:**
- FinServ__FinancialAccount__c (Required - select which account this person is a successor/beneficiary for)
- FinServ__Role__c (Required)
- SuccessorAllocation__c (Optional)
- FinServ__Active__c (Optional)
- FinServ__StartDate__c (Optional)
- FinServ__EndDate__c (Optional)

**Usage:** Designate a Person Account as successor/beneficiary across multiple financial accounts

**Where to Add:**
1. Setup → Object Manager → Account → Lightning Record Pages
2. Edit existing Person Account page → Highlights Panel → Mobile & Lightning Actions
3. Add "New Financial Account Role" to action list
4. Works with Person Account model - automatically links to PersonContactId

---

### Adding Quick Actions to Existing Lightning Pages

**Financial Services Cloud Note:** Account and FinancialAccount objects use FSC default Lightning pages. Quick Actions must be added via Setup:

**For FinancialAccount Pages:**
```
Setup → Object Manager → FinServ__FinancialAccount__c → Lightning Record Pages
→ Edit active page → Highlights Panel (top of page)
→ Override Global Publisher Layout → Add "New Account Role"
```

**For Person Account Pages:**
```
Setup → Object Manager → Account → Lightning Record Pages
→ Edit Person Account page → Highlights Panel
→ Override Global Publisher Layout → Add "New Financial Account Role"
```

**For Related Lists:**
Quick Actions automatically appear in related list action menus when:
- Related list is added to any Lightning page
- "Enable inline editing" is checked on related list component
- Action bar is enabled on the related list

---

### List Views

#### All Financial Account Roles
**File:** `All_Financial_Account_Roles.listView-meta.xml`
**Columns:**
- Name
- Financial Account
- Related Contact
- Role
- Successor Allocation %
- Active
- Start Date
- End Date
**Filter:** None (shows all roles)

#### Successors
**File:** `Successors.listView-meta.xml`
**Columns:**
- Name
- Financial Account
- Related Contact
- Successor Allocation %
- Active
- Start Date
**Filter:** Role = "Successor"
**Usage:** Quick access to all successor designations for succession planning

## Flow Automation (5 flows - All Inactive in Source Control)

**⚠️ IMPORTANT: All flows in this repository are marked as `Inactive` in source control.** The system's primary automation is trigger-based via `SuccessionCaseTrigger` → `SuccessionTaskGenerator`.

**Migration History:**

**v1.0 → Apex Migration:**
- `Case_Estate_Administration_Defaults` → Implemented in `CreateSuccessionCaseController.cls`
- `Case_Multiple_Successors_Handler` → Implemented in `CreateSuccessionCaseController.cls`
- Reason: Complex logic handling, validation, reduced flow complexity

**Current State:**
- All flows present in source control are Inactive
- Primary automation is trigger-based (see SuccessionCaseTrigger + SuccessionTaskGenerator)
- Flow files exist for reference but are not active in this codebase

### Succession_Start_Contact_Process (Inactive)
**File:** `force-app/main/default/flows/Succession_Start_Contact_Process.flow-meta.xml`
**Status:** Inactive in source control
**Intended Purpose:** Would create Task #1 (Day 0 contact attempt) automatically via SuccessionTaskCreator invocable class
**Legacy Name:** Previously referenced as `Case_Create_Initial_Contact_Attempt` in older docs

### Succession_Schedule_Next_Contact (Inactive)
**File:** `force-app/main/default/flows/Succession_Schedule_Next_Contact.flow-meta.xml`
**Status:** Inactive in source control
**Intended Purpose:** Would create next contact task (Day 5, 35, 65, 95) via SuccessionTaskCreator invocable class
**Legacy Name:** Previously referenced as `Task_Create_Next_Contact_Attempt` in older docs

### Succession_Mark_Contact_Established (Inactive)
**File:** `force-app/main/default/flows/Succession_Mark_Contact_Established.flow-meta.xml`
**Status:** Inactive in source control
**Intended Purpose:** Would set Contact_Established__c on Case when task marked as successful

### Succession_Close_Multi_Successor_Parent (Inactive)
**File:** `force-app/main/default/flows/Succession_Close_Multi_Successor_Parent.flow-meta.xml`
**Status:** Inactive in source control
**Intended Purpose:** Would auto-close parent case when all child cases complete
**Legacy Name:** Previously referenced as `Case_Parent_Closure_Handler` in older docs

### Succession_Update_Case_Status_And_Notify (Inactive)
**File:** `force-app/main/default/flows/Succession_Update_Case_Status_And_Notify.flow-meta.xml`
**Status:** Inactive in source control
**Intended Purpose:** Would update Case.Status based on workflow phase transitions and post Chatter notifications
**Legacy Names:** Previously referenced as `Case_Status_Coordination`, `Case_Succession_Segment_Transition`, or `Case_After_Update_Handler` in older docs

**Note:** The flow `Case_After_Update_Handler` mentioned in older documentation does not exist in this repository.

## Essential Commands

### Salesforce Deployment

```bash
# Authenticate
sf org login web --alias succession-org

# Deploy all metadata
sf project deploy start --manifest manifest/package.xml

# Deploy specific components
sf project deploy start --source-dir force-app/main/default/classes
sf project deploy start --source-dir force-app/main/default/lwc
sf project deploy start --source-dir force-app/main/default/flows

# Retrieve from org
sf project deploy start --target-org schwab-sandbox
```

### Code Quality & Testing

```bash
# Run Apex tests
sf apex run test --test-level RunLocalTests --code-coverage

# LWC tests and code quality (see docs/LINTING_AND_FORMATTING.md for details)
npm run cleanup           # Clean up code formatting
npm test                  # Run LWC tests
npm run auto-test         # Auto-test as you code (watch mode)
npm run ready-to-commit   # Pre-commit validation (format + lint + test)
npm run full-check        # Complete validation with coverage + security scan
```

### Permission Sets

```bash
# Assign required permission sets
sf org assign permset --name Succession_Management_Access
sf org assign permset --name Succession_Field_Access
```

### CumulusCI Workflows

```bash
# Complete deployment with test data
cci flow run deploy_succession

# Deploy without test data
cci flow run deploy_succession_no_data

# Load demo data
cci task run load_demo_ui_showcase

# QA environment setup
cci flow run qa_full_setup
```

## Critical Development Patterns

### Email Validation & Compliance (CRITICAL)

**Always validate email before sending:**
1. Check email exists (PersonEmail or Contact.Email not NULL)
2. Validate format: `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`
3. **Check opt-out status** (PersonHasOptedOutOfEmail / HasOptedOutOfEmail)
4. Display warnings in UI
5. Disable "Send Email" button if validation fails

**Legal Requirement:** Never send emails to opted-out users

### Contact Cadence Development

**Task Creation Pattern:**
- Attempt 1: Would be created by `Succession_Start_Contact_Process` flow (Inactive)
- Attempts 2-5: Would be created by `Succession_Schedule_Next_Contact` flow (Inactive)
- Tasks created immediately but **date-gated** via ActivityDate
- Agent cannot complete task until ActivityDate arrives

**UI Display Pattern:**
- Completed attempts → Read-only with notes
- Current attempt (date arrived) → "Record Outcome" button enabled
- Current attempt (date not arrived) → Locked with countdown
- Future attempts → "Waiting for previous attempt"

**Email Sending Pattern:**
- Automated: Pathway form invitation (when contact established)
- Optional: Contact cadence emails (agent choice after negative outcomes)
- Validation: Always check canSendEmail computed property
- Persistence: Email prompt stays visible until "Skip" clicked

### Apex Security Requirements

**ALL Apex classes must:**
- Use `WITH USER_MODE` for database operations
- Use `Database.query(queryString, AccessLevel.USER_MODE)` for dynamic queries
- Use `Database.insert/update(records, AccessLevel.USER_MODE)` for DML
- Enforce field-level security
- Use `@AuraEnabled(cacheable=true)` for read operations
- Implement proper try/catch error handling

### LWC Best Practices

**Data Retrieval:**
- Use `@wire` for initial data load
- Use `refreshApex()` after mutations
- Cache with `cacheable=true` Apex methods

**Navigation:**
- Use NavigationMixin for page navigation
- Person Account emails: `Account.SendEmail` action
- Business Account emails: `Contact.SendEmail` action

**State Management:**
- Track editing state with `@track` properties
- Use computed properties for validation (`get canSendEmail()`)
- Reset state after save operations

### Flow Development Guidelines

**Self-Terminating Scheduled Paths:**
- Use decision nodes to check gate fields
- Exit gracefully if conditions not met
- Example: Check `Contact_Established__c` before creating next task

**Multi-Successor Flows:**
- Check Case Type to avoid triggering on parent cases
- Use `Type = "Named Successor Enactment"` filter
- Parent case Type = "Multi-Account Succession Master"

## Test Data Generation

### Via CumulusCI + Snowfakery

```bash
# Load complete dataset
cci task run load_succession_test_data

# Load demo data (UI showcase)
cci task run load_demo_ui_showcase
```

**Mapping:** `datasets/succession_mapping.yml`
**Recipe:** `datasets/succession_demo.recipe.yml`

**Objects Created:**
- Person Accounts with valid emails
- FinancialAccounts with balances
- FinancialAccountRoles (successors)
- Cases with various workflow states
- Tasks for contact attempts

## Known Issues & Workarounds

**Sandbox Email Deliverability:**
- Emails only sent to verified addresses
- Verify test emails in Sandbox Settings before demo

**Person Account Fields:**
- Use PersonEmail, PersonMobilePhone (not Contact fields)
- Query PersonContactId for FinancialAccountRole lookups

**Multi-Successor Scenarios:**
- Ensure parent case created before children
- Use caseHierarchyViewer only on parent cases

## Quick Reference: Key Fields

**Case Fields:**
- `Verification_Status__c` - Workflow trigger ("Not Started", "Complete - Verified")
- `Contact_Established__c` - Gate field (stops contact cadence)
- `Contact_Attempt_Count__c` - Tracks attempt number (1-5)
- `Form_Sent_Date__c` - Email sent timestamp
- `Form_Completed_Date__c` - Pathway selection timestamp
- `Pathway_Confirmed__c` - Selected pathway
- `Execution_Status__c` - Pathway execution progress

**Task Fields:**
- `Contact_Attempt_Number__c` - Attempt sequence (1-5)
- `Succession_Contact_Established__c` - Outcome (YES/NO)
- `ActivityDate` - Date-gating field

**Account Fields (Person Account):**
- `PersonEmail` - Email address
- `PersonHasOptedOutOfEmail` - Opt-out status (compliance)
- `PersonContactId` - Virtual Contact lookup

## Documentation Reference

**Core Docs (docs/):**
- `README.md` - Project overview and quick start
- `LINTING_AND_FORMATTING.md` - Code quality guide with jargon-free npm script explanations (for stakeholders and year 1 devs)
- `field-documentation-succession.md` - Complete field reference
- `PERSON_ACCOUNT_FIXES.md` - FSC Person Account compatibility
- `TIER_1_FIXES_SUMMARY.md` - Email validation fixes
- `MULTI_SUCCESSOR_TESTING_GUIDE.md` - Multi-successor scenarios
- `FLOW_DESCRIPTIONS_IMPROVED.md` - Comprehensive flow documentation with dependencies, workflow relationships, and migration notes (v1.1)

## End-to-End Workflow Summary

1. **Case Created** → CreateSuccessionCaseController validates successors and creates case
2. **Workflow Starts Automatically** → Flow creates Task #1 (Day 0 contact attempt) immediately
3. **Agent Records Outcome** → Uses successionContactCadence LWC
4. **If Contact Made (YES)** → Flow sets Contact_Established__c = TRUE
5. **Flow Sends Email** → Automatic pathway form invitation
6. **Successor Completes Form** → successionPublicForm LWC
7. **Pathway Tasks Created** → SuccessionTaskGenerator (trigger-based)
8. **Agent Completes Tasks** → Pathway execution
9. **Case Closed** → Execution_Status__c = "Completed"

**Key Improvement in v1.1:** Verification phase removed - workflow now starts automatically when case is created. No manual "Begin Succession Processing" step required.

## Version & Status

- **Version:** 1.1.0 - Automatic workflow start (verification phase removed)
- **API Version:** 65.0
- **Last Updated:** October 2025
- **Environment:** Demo/Sandbox
- **Status:** Active demonstration system
