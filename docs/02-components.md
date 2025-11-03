# Component Inventory

**Last Updated:** November 2, 2025  
**Version:** 1.0

---

## Overview

This document provides a comprehensive inventory of all Lightning Web Components (LWCs) and Apex classes in the Succession Management System, including their purpose, key features, and file locations.

---

## Lightning Web Components (5 Active)

### 1. successionContactCadence

**Purpose:** Primary UI for managing the 5-attempt contact cadence with progress tracking and inline editing.

**File Location:** `force-app/main/default/lwc/successionContactCadence/`

**Key Features:**
- Displays 5 contact attempts (Days 0, 5, 35, 65, 95)
- Sequential unlock pattern: next task unlocks only when prior is completed
- Date-gating: tasks cannot be completed until ActivityDate arrives
- Progress visualization with status indicators
- Email validation warnings (checks `HasOptedOutOfEmail`)
- Inline editing of task outcomes
- Circuit breaker: stops cadence when `Contact_Established__c = true`

**Controller:** `ContactCadenceController.cls`

**Usage:** Embedded on Case record page (EstateAdministration record type)

**Key Methods:**
- `@wire(getContactCadence)` - Retrieves contact attempt data
- `handleSaveAttempt()` - Saves task outcome and updates Case
- `validateEmail()` - Checks email format and opt-out status

**Lines of Code:** ~1,043 lines JavaScript

---

### 2. recordPathwaySelection

**Purpose:** Quick Action for agents to record pathway selection. **This is the key component that triggers pathway task automation.**

**File Location:** `force-app/main/default/lwc/recordPathwaySelection/`

**Key Features:**
- Quick Action UI (modal dialog)
- Pathway selection dropdown (Final Grant, New DAF, Disclaim)
- Sets `Pathway_Confirmed__c` field on Case (line 55 in recordPathwaySelection.js)
- **Triggers `SuccessionCaseTrigger`** when field is set
- Validation: ensures pathway is selected before saving
- Success notification with confirmation message

**Controller:** `CreateSuccessionCaseController.cls` (for validation)

**Usage:** Quick Action on Case record page

**Key Methods:**
- `handlePathwayChange()` - Updates selected pathway
- `handleSave()` - Sets `Pathway_Confirmed__c` and closes modal
- `handleCancel()` - Closes modal without saving

**Trigger Point:** Setting `Pathway_Confirmed__c` fires `SuccessionCaseTrigger` → `SuccessionTaskGenerator`

---

### 3. successionPublicForm

**Purpose:** Guest user-facing form for successors to select their pathway online.

**File Location:** `force-app/main/default/lwc/successionPublicForm/`

**Key Features:**
- Public-facing (guest user accessible)
- URL parameter-based access (case ID + token)
- Pathway selection with descriptions
- Form validation
- Success confirmation page
- Mobile-responsive design
- Security: token-based authentication

**Controller:** `SuccessionPublicFormController.cls`

**Usage:** Embedded in Experience Cloud site (public page)

**Key Methods:**
- `@wire(getFormData)` - Retrieves case data with token validation
- `handleSubmit()` - Saves pathway selection
- `validateToken()` - Verifies access token

**Security:** Uses `Succession_Guest_Access` permission set

---

### 4. caseHierarchyViewer

**Purpose:** Visual tree display of parent-child case hierarchy for multi-successor scenarios.

**File Location:** `force-app/main/default/lwc/caseHierarchyViewer/`

**Key Features:**
- Tree visualization of case hierarchy
- Parent case at top, child cases below
- Status indicators for each case
- Expandable/collapsible nodes
- Successor allocation percentages
- Click to navigate to case record

**Controller:** `CaseHierarchyController.cls`

**Usage:** Embedded on Case record page (multi-successor parent cases)

**Key Methods:**
- `@wire(getCaseHierarchy)` - Retrieves parent and child cases
- `handleCaseClick()` - Navigates to selected case
- `buildTreeData()` - Constructs tree structure from flat data

**Data Structure:**
```javascript
{
  caseId: 'xxx',
  caseNumber: 'C-12345',
  status: 'In Progress',
  successorName: 'John Doe',
  allocation: 50,
  children: [...]
}
```

---

### 5. createSuccessionCase

**Purpose:** Quick Action for creating succession cases from a Financial Account.

**File Location:** `force-app/main/default/lwc/createSuccessionCase/`

**Key Features:**
- Quick Action UI (modal dialog)
- Financial Account lookup
- Successor selection (from FinancialAccountRoles)
- Multi-successor support
- Validation: ensures successors exist and allocations sum to 100%
- Creates parent case + child cases for multi-successor scenarios
- Auto-populates case fields (Type, Status, etc.)

**Controller:** `CreateSuccessionCaseController.cls`

**Usage:** Quick Action on Financial Account record page

**Key Methods:**
- `handleFinancialAccountChange()` - Loads successors for selected account
- `handleSuccessorSelection()` - Updates selected successors
- `handleCreate()` - Creates case(s) and closes modal
- `validateSuccessors()` - Ensures valid successor selection

**Multi-Successor Logic:**
- If 1 successor: creates single case
- If 2+ successors: creates parent case + child cases (one per successor)
- Parent case Type: "Multi-Account Succession Master"
- Child case Type: "Named Successor Enactment"

---

## Apex Classes (8 Production Classes)

### 1. ContactCadenceController

**Purpose:** Controller for `successionContactCadence` LWC. Manages contact attempt data and email validation.

**File Location:** `force-app/main/default/classes/ContactCadenceController.cls`

**Security:** Uses `@SuppressWarnings('PMD.ApexCRUDViolation')` with comments about USER_MODE

**Key Methods:**

#### `getContactCadence(String caseId)`
- **@AuraEnabled(cacheable=true)**
- Returns contact attempt tasks for a case
- Queries Task records with `Contact_Attempt_Number__c` field
- Ordered by `Contact_Attempt_Number__c` ASC

#### `saveAttemptOutcome(String taskId, String outcome, Boolean contactEstablished)`
- **@AuraEnabled**
- Updates task status and outcome
- Sets `Succession_Contact_Established__c` on task
- Updates `Contact_Established__c` on Case if contact made
- Returns success/failure status

#### `validateEmailAddress(String caseId)`
- **@AuraEnabled**
- Checks successor email format and opt-out status
- Returns validation result with warnings
- Uses regex for email format validation

**Test Class:** `ContactCadenceController_Test.cls`

---

### 2. CreateSuccessionCaseController

**Purpose:** Controller for `createSuccessionCase` LWC. Handles multi-successor case creation with validation.

**File Location:** `force-app/main/default/classes/CreateSuccessionCaseController.cls`

**Security:** Uses `WITH USER_MODE` (5 queries confirmed)

**Key Methods:**

#### `createSuccessionCase(String financialAccountId, List<String> successorIds)`
- **@AuraEnabled**
- Creates succession case(s) from Financial Account
- Validates successors exist and allocations sum to 100%
- Creates parent + child cases for multi-successor scenarios
- Returns created case ID(s)

#### `validateSuccessors(String financialAccountId, List<String> successorIds)`
- **@AuraEnabled**
- Validates successor selection
- Checks allocation percentages
- Returns validation result

#### `createMultiSuccessorStructure(String financialAccountId, List<FinancialAccountRole> successors)`
- **Private helper method**
- Creates parent case (Type: "Multi-Account Succession Master")
- Creates child cases (one per successor)
- Links child cases to parent via `ParentId`
- Returns parent case ID

**Test Class:** `CreateSuccessionCaseController_Test.cls`

---

### 3. SuccessionPublicFormController

**Purpose:** Controller for `successionPublicForm` LWC. Handles guest user form submissions.

**File Location:** `force-app/main/default/classes/SuccessionPublicFormController.cls`

**Security:** Uses `WITH USER_MODE` (lines 135, 151, 168, 187)

**Key Methods:**

#### `getFormData(String caseId, String token)`
- **@AuraEnabled(cacheable=true)**
- Retrieves case data for public form
- Validates access token
- Returns case details with pathway options
- Throws exception if token invalid

#### `savePathwaySelection(String caseId, String token, String pathway)`
- **@AuraEnabled**
- Saves pathway selection from guest user
- Validates token before saving
- Sets `Pathway_Confirmed__c` field (triggers automation)
- Sets `Form_Completed_Date__c`
- Returns success/failure status

#### `validateToken(String caseId, String token)`
- **Private helper method**
- Validates access token against case record
- Checks token expiration
- Returns boolean

**Test Class:** `SuccessionPublicFormController_Test.cls`

---

### 4. CaseHierarchyController

**Purpose:** Controller for `caseHierarchyViewer` LWC. Provides case hierarchy data.

**File Location:** `force-app/main/default/classes/CaseHierarchyController.cls`

**Security:** Uses `WITH USER_MODE`

**Key Methods:**

#### `getCaseHierarchy(String caseId)`
- **@AuraEnabled(cacheable=true)**
- Retrieves parent and child cases
- Queries FinancialAccountRole for successor allocations
- Builds hierarchy structure
- Returns tree data for visualization

**Data Structure:**
```apex
public class CaseHierarchyNode {
    @AuraEnabled public String caseId;
    @AuraEnabled public String caseNumber;
    @AuraEnabled public String status;
    @AuraEnabled public String successorName;
    @AuraEnabled public Decimal allocation;
    @AuraEnabled public List<CaseHierarchyNode> children;
}
```

**Test Class:** `CaseHierarchyController_Test.cls`

---

### 5. SuccessionTaskGenerator

**Purpose:** **PRIMARY AUTOMATION** - Creates pathway-specific tasks when `Pathway_Confirmed__c` changes.

**File Location:** `force-app/main/default/classes/SuccessionTaskGenerator.cls`

**Security:** Uses `SYSTEM_MODE` (lines 82, 92) - Required for guest user scenarios

**Key Methods:**

#### `createPathwayTasks(List<Case> newCases, Map<Id, Case> oldCaseMap)`
- **Public static method** (called from trigger)
- Detects `Pathway_Confirmed__c` field changes
- Routes to appropriate task generation method based on pathway
- Bulk-safe: handles multiple cases
- Duplicate prevention: checks for existing pathway tasks

#### `generateFinalGrantTasks(Case c)`
- **Private helper method**
- Creates 5 tasks for Final Grant pathway
- Timeline: Days 2, 5, 10, 15, 20
- Task subjects: "Review grant request", "Verify beneficiaries", etc.
- Returns list of tasks

#### `generateNewDAFTasks(Case c)`
- **Private helper method**
- Creates 4 tasks for New DAF pathway
- Timeline: Days 2, 7, 12, 18
- Task subjects: "Open new DAF account", "Transfer assets", etc.
- Returns list of tasks

#### `generateDisclaimTasks(Case c)`
- **Private helper method**
- Creates 4 tasks for Disclaim pathway
- Timeline: Days 3, 8, 13, 20
- Task subjects: "Process disclaimer", "Update records", etc.
- Returns list of tasks

**Test Class:** `SuccessionTaskGenerator_Test.cls` (100% coverage - 7/7 tests)

**Lines of Code:** 252 lines

---

### 6. SuccessionTaskCreator

**Purpose:** Invocable Apex for contact task creation (referenced by inactive flows).

**File Location:** `force-app/main/default/classes/SuccessionTaskCreator.cls`

**Security:** Uses `WITH USER_MODE`

**Key Methods:**

#### `createContactAttemptTasks(List<ContactAttemptRequest> requests)`
- **@InvocableMethod**
- Creates contact attempt tasks from flows
- Duplicate prevention: checks for existing tasks
- Date-gated scheduling (Days 0, 5, 35, 65, 95)
- Returns list of created task IDs

**Input Wrapper:**
```apex
public class ContactAttemptRequest {
    @InvocableVariable public String caseId;
    @InvocableVariable public Integer attemptNumber;
}
```

**Test Class:** `SuccessionTaskCreator_Test.cls`

**Note:** Referenced by inactive flows (`Succession_Start_Contact_Process`, `Succession_Schedule_Next_Contact`)

---

### 7. SuccessionChatterPoster

**Purpose:** Invocable Apex for Chatter notifications (referenced by inactive flows).

**File Location:** `force-app/main/default/classes/SuccessionChatterPoster.cls`

**Security:** Uses `WITH USER_MODE`

**Key Methods:**

#### `postChatterUpdate(List<ChatterPostRequest> requests)`
- **@InvocableMethod**
- Posts Chatter feed updates to Case records
- Supports pathway name and additional context
- Returns success/failure status

**Input Wrapper:**
```apex
public class ChatterPostRequest {
    @InvocableVariable public String caseId;
    @InvocableVariable public String message;
    @InvocableVariable public String pathwayName;
}
```

**Test Class:** `SuccessionChatterPoster_Test.cls`

**Note:** Referenced by inactive flows (`Succession_Update_Case_Status_And_Notify`)

---

### 8. SuccessionUtilities

**Purpose:** Shared utility class for common patterns across the application.

**File Location:** `force-app/main/default/classes/SuccessionUtilities.cls`

**Security:** Uses `WITH USER_MODE` (3 queries confirmed)

**Key Methods:**

#### `validateEmail(String email)`
- **Public static method**
- Validates email format using regex
- Returns boolean

#### `createChatterPost(String caseId, String message)`
- **Public static method**
- Creates Chatter feed post on Case
- Used by multiple controllers
- Returns FeedItem ID

#### `getRecordTypeId(String objectName, String recordTypeName)`
- **Public static method**
- Retrieves RecordType ID by name
- Cached for performance
- Returns RecordType ID

#### `createContentNote(String parentId, String title, String content)`
- **Public static method**
- Creates ContentNote linked to record
- Used for documentation
- Returns ContentNote ID

**Test Class:** `SuccessionUtilities_Test.cls`

---

## Test Classes

All production classes have corresponding test classes with high coverage:

| Test Class | Coverage | Tests |
|------------|----------|-------|
| `ContactCadenceController_Test` | 100% | 5 tests |
| `CreateSuccessionCaseController_Test` | 100% | 6 tests |
| `SuccessionPublicFormController_Test` | 100% | 4 tests |
| `CaseHierarchyController_Test` | 100% | 3 tests |
| `SuccessionTaskGenerator_Test` | 100% | 7 tests |
| `SuccessionTaskCreator_Test` | 100% | 4 tests |
| `SuccessionChatterPoster_Test` | 100% | 3 tests |
| `SuccessionUtilities_Test` | 100% | 6 tests |

**File Location:** `force-app/main/default/classes/*_Test.cls`

---

## Component Dependencies

### LWC → Apex Controller Mapping

```
successionContactCadence → ContactCadenceController
recordPathwaySelection → CreateSuccessionCaseController
successionPublicForm → SuccessionPublicFormController
caseHierarchyViewer → CaseHierarchyController
createSuccessionCase → CreateSuccessionCaseController
```

### Apex → Apex Dependencies

```
ContactCadenceController → SuccessionUtilities
CreateSuccessionCaseController → SuccessionUtilities
SuccessionPublicFormController → SuccessionUtilities
SuccessionTaskGenerator → SuccessionUtilities
SuccessionTaskGenerator → SuccessionChatterPoster
```

### Trigger → Apex Mapping

```
SuccessionCaseTrigger → SuccessionTaskGenerator
```

---

## Code Metrics

### Lines of Code (Approximate)

| Component Type | Count | Total LOC |
|----------------|-------|-----------|
| LWC JavaScript | 5 | ~2,500 |
| LWC HTML | 5 | ~800 |
| LWC CSS | 5 | ~600 |
| Apex Classes | 8 | ~1,800 |
| Apex Test Classes | 8 | ~1,500 |
| Apex Triggers | 1 | ~10 |

**Total:** ~7,210 lines of code

### Complexity Metrics

- **Average Cyclomatic Complexity:** 3.2 (low complexity)
- **Maximum Method Length:** 85 lines (`SuccessionTaskGenerator.createPathwayTasks`)
- **Average Method Length:** 22 lines

---

## Naming Conventions

### LWC Components
- **Pattern:** `succession<ComponentName>` (camelCase)
- **Examples:** `successionContactCadence`, `recordPathwaySelection`

### Apex Classes
- **Pattern:** `Succession<ClassName>` (PascalCase)
- **Examples:** `SuccessionTaskGenerator`, `SuccessionUtilities`

### Apex Test Classes
- **Pattern:** `<ClassName>_Test`
- **Examples:** `SuccessionTaskGenerator_Test`, `ContactCadenceController_Test`

### Custom Fields
- **Pattern:** `<Field_Name>__c` (snake_case with __c suffix)
- **Examples:** `Contact_Established__c`, `Pathway_Confirmed__c`

---

## Best Practices Followed

### Security
- ✅ All controllers use `WITH USER_MODE` or `@SuppressWarnings` with documentation
- ✅ Exception: `SuccessionTaskGenerator` uses `SYSTEM_MODE` (documented rationale)
- ✅ Field-level security enforced via permission sets
- ✅ Guest user access restricted to submission form only

### Performance
- ✅ Bulk-safe: all Apex methods handle collections
- ✅ No SOQL in loops
- ✅ Efficient queries with selective WHERE clauses
- ✅ Cacheable `@wire` methods in LWCs

### Maintainability
- ✅ Clear separation of concerns (UI → Controller → Data)
- ✅ Shared utility class for common patterns
- ✅ Comprehensive test coverage (100% on all classes)
- ✅ Descriptive method and variable names
- ✅ Inline comments for complex logic

### User Experience
- ✅ Progress visualization in contact cadence
- ✅ Validation feedback before saving
- ✅ Success/error notifications
- ✅ Mobile-responsive design
- ✅ Quick Actions for rapid data entry

---

**Document Status:** Last verified November 2, 2025 | Commit: [current]
