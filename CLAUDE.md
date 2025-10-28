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

### 5-Phase Workflow

**Phase 1: Verification** (Auto-completed in 90% of cases)
- Agent clicks "✅ Begin Succession Processing" Quick Action
- Sets Verification_Status__c = "Complete - Verified"
- Triggers workflow start

**Phase 2: Contact Cadence** (5 attempts over 95 days)
- Day 0, 5, 35, 65, 95 contact schedule
- Phone calls are **informational only** - agent cannot accept pathway decisions
- successionContactCadence LWC displays progress + email validation
- Tasks created automatically by flows

**Phase 3: Pathway Selection**
- Email sent automatically when contact established
- Successor completes public form (successionPublicForm LWC)
- Three pathways: Final Grant, New DAF Account, Disclaim Assets

**Phase 4: Pathway Execution**
- SuccessionTaskGenerator creates pathway-specific tasks
- Final Grant: 5 tasks over 20 days
- New DAF: 4 tasks over 18 days
- Disclaim: 4 tasks over 20 days

**Phase 5: Case Closure**
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

## Apex Classes (8 total)

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
**Purpose:** Workflow trigger via Quick Action
**Key Method:**
- `updateVerificationStatus()` - Sets Verification_Status__c = "Complete - Verified"

**Pattern:** Simple controller for Quick Action button
**Duplicate Prevention:** Checks if already verified before updating

### SuccessionTaskCreator
**Purpose:** Invocable Apex for flow-based contact task creation
**Key Method:**
- `createContactAttemptTasks()` - Creates contact attempt tasks from flows with duplicate prevention

**Pattern:** Invocable method for flow optimization (alternative to trigger-based approach)
**Usage:** Called from `Task_Create_Next_Contact_Attempt` flow
**Features:**
- Bulk processing support
- Duplicate prevention (checks for existing tasks)
- Date-gated scheduling (Days 0, 5, 35, 65, 95)
- Response wrapper with success/skip status

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

## Lightning Web Components (6 active)

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
**Location:** `force-app/main/default/lwc/beginSuccessionProcessing/`
**Purpose:** Quick Action to trigger workflow start
**Features:**
- Single "Begin Succession Processing" button
- Updates Verification_Status__c to trigger flows
- Shows workflow steps that will be initiated
- Duplicate prevention with error messages

**Usage:** Placed on Case record page for Estate Administration record type

## Flow Automation (6 active flows)

**Note:** Two flows were migrated to Apex for better performance:
- `Case_Estate_Administration_Defaults` → Implemented in `CreateSuccessionCaseController.cls`
- `Case_Multiple_Successors_Handler` → Implemented in `CreateSuccessionCaseController.cls`

This migration improves complex logic handling, validation, and reduces flow complexity.

### Case_Create_Initial_Contact_Attempt
**Trigger:** Case CREATE or UPDATE when Verification_Status__c = "Complete - Verified"
**Purpose:** Creates Task #1 (Day 0 contact attempt)
**Duplicate Prevention:** Checks Contact_Attempt_Count__c is NULL

### Task_Create_Next_Contact_Attempt
**Trigger:** Task UPDATE when Status = "Completed"
**Purpose:** Creates next contact task (Day 5, 35, 65, 95)
**Gate Check:** Contact_Established__c = FALSE (stops if contact made)
**Date Formula:** DATEVALUE(Case.CreatedDate) + [days]

### Task_Succession_Contact_Update
**Trigger:** Task UPDATE when Status = "Completed"
**Purpose:** Circuit breaker - sets Contact_Established__c on Case
**Condition:** Task.Succession_Contact_Established__c = TRUE

### Case_Parent_Closure_Handler
**Trigger:** Child case Status = "Closed" or "Canceled"
**Purpose:** Auto-closes parent when all children complete
**Pattern:** Queries all siblings, checks if all have terminal status

### Case_Status_Coordination
**Trigger:** Case UPDATE (field changes)
**Purpose:** Automatic Status field coordination based on phase progression
**Status Mapping:**
- Verification complete → "In Progress"
- Contact + form sent → "Awaiting Response"
- Form completed → "In Review"
- Pathway execution → "In Progress"
- Execution complete → "Closed"

### Case_Succession_Segment_Transition
**Trigger:** Case UPDATE when pathway-related fields change
**Purpose:** Manages pathway transitions and status updates

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

### Testing

```bash
# Run Apex tests
sf apex run test --test-level RunLocalTests --code-coverage

# Run LWC tests
npm run test:unit

# Watch mode
npm run test:unit:watch

# Coverage report
npm run test:unit:coverage

# Lint
npm run lint

# Format code
npm run prettier
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
- Attempt 1: Created by `Case_Create_Initial_Contact_Attempt` flow
- Attempts 2-5: Created by `Task_Create_Next_Contact_Attempt` flow
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
- `field-documentation-succession.md` - Complete field reference
- `PERSON_ACCOUNT_FIXES.md` - FSC Person Account compatibility
- `TIER_1_FIXES_SUMMARY.md` - Email validation fixes
- `MULTI_SUCCESSOR_TESTING_GUIDE.md` - Multi-successor scenarios

## End-to-End Workflow Summary

1. **Case Created** → Verification_Status__c = "Not Started"
2. **Agent Clicks Quick Action** → Sets Verification_Status__c = "Complete - Verified"
3. **Flow Creates Task #1** → Contact cadence begins (Day 0)
4. **Agent Records Outcome** → Uses successionContactCadence LWC
5. **If Contact Made (YES)** → Flow sets Contact_Established__c = TRUE
6. **Flow Sends Email** → Automatic pathway form invitation
7. **Successor Completes Form** → successionPublicForm LWC
8. **Pathway Tasks Created** → SuccessionTaskGenerator (trigger-based)
9. **Agent Completes Tasks** → Pathway execution
10. **Case Closed** → Execution_Status__c = "Completed"

## Version & Status

- **Version:** 1.0.0
- **API Version:** 65.0
- **Last Updated:** October 2025
- **Environment:** Demo/Sandbox
- **Status:** Active demonstration system
