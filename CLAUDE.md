# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build, Test, and Deployment Commands

### Testing

```bash
# LWC/JavaScript tests
npm test                           # Run all LWC Jest tests
npm run test:unit:watch            # Watch mode for development
npm run test:unit:coverage         # Generate coverage report

# Apex tests (use Salesforce CLI)
sf apex run test --test-level RunLocalTests --code-coverage
sf apex run test --tests ClassName_Test  # Run single test class
```

### Linting & Formatting

```bash
npm run lint                       # Run ESLint + Prettier checks
npm run format                     # Auto-fix all formatting issues
npm run lint:apex                  # Apex static analysis via SF Scanner
npm run validate                   # Full validation: lint + test
```

### Salesforce Deployment

```bash
# Deploy to org
sf project deploy start --manifest manifest/package.xml

# Deploy and validate without tests
sf project deploy start --target-org sandbox

# Validate deployment (check-only)
sf project deploy validate --manifest manifest/package.xml

# Retrieve metadata from org
sf project retrieve start --manifest manifest/package.xml
```

### Permission Set Assignment

```bash
sf org assign permset --name Succession_Management_Access
sf org assign permset --name Succession_Field_Access
```

## Architecture Overview

**Technology Stack:** Salesforce Financial Services Cloud (API v65.0) using SFDX source format

**Key Principle:** This is a **standard-objects-only** implementation. No custom objects are used. All functionality is built on Case, Task, Account, Contact, FinancialAccount, and FinancialAccountRole.

### Primary Automation Pattern

The system uses **trigger-based Apex automation** as its primary mechanism:

1. **SuccessionCaseTrigger** (after update) → monitors `Case.Pathway_Confirmed__c` changes
2. **SuccessionTaskGenerator.createPathwayTasks()** → creates pathway-specific milestone tasks
3. **Contact cadence auto-progression** → `ContactCadenceController.saveAttemptOutcome()` creates next attempt tasks
4. Tasks are standard Salesforce Tasks (no Action Plan Templates)

**Important:** All Flow metadata in `force-app/main/default/flows/` is marked as `Inactive`. Flows were replaced with Apex automation for better performance and bulk processing.

### Pathway Task Generation

When `Pathway_Confirmed__c` is set on a Case, the trigger automatically creates a series of milestone tasks:

- **Final Grant:** 5 tasks over 20 days (Day 2, 5, 8, 15, 20)
- **New DAF Account:** 4 tasks over 18 days (Day 2, 5, 12, 18)
- **Disclaim Assets:** 4 tasks over 20 days (Day 3, 7, 14, 20)

Implementation: [SuccessionTaskGenerator.cls](force-app/main/default/classes/SuccessionTaskGenerator.cls) lines 102-250

### Contact Cadence Pattern

Contact attempts are managed via **Apex automation** with **Custom Metadata Type** configuration:

- Days offset from case creation (0, 5, 35, 65, 95)
- **Auto-progression**: Next attempt task automatically created when current attempt completes
- **Idempotency**: Prevents duplicate tasks on repeated saves
- Custom Metadata (`Succession_Contact_Cadence__mdt`) defines wait durations
- Email validation with Person Account vs Contact field resolution

Controller: [ContactCadenceController.cls](force-app/main/default/classes/ContactCadenceController.cls)
UI Component: [successionContactCadence LWC](force-app/main/default/lwc/successionContactCadence/)

### Multi-Successor Pattern

Cases support hierarchical structures for multiple successors:

- Parent Case: `Type = "Multi-Account Succession Master"`
- Child Cases: `Type = "Named Successor Enactment"` with `ParentId` populated
- UI: [caseHierarchyViewer LWC](force-app/main/default/lwc/caseHierarchyViewer/)

## Code Architecture

### Apex Classes (9 production classes + 12 test classes)

**Controllers (5):**

- `CaseHierarchyController` - Apex controller for case hierarchy visualization
- `ContactCadenceController` - Contact attempt task management
- `CreateSuccessionCaseController` - Multi-successor case creation
- `SuccessionPublicFormController` - Guest user pathway form handler
- `SuccessionPathwayEmailSender` - Pathway-based email sending

**Automation & Invocables (2):**

- `SuccessionTaskGenerator` - **PRIMARY** pathway task automation (trigger handler)
- `SuccessionTaskCreator` - @InvocableMethod for contact task creation

**Utilities & Helpers (2):**

- `SuccessionUtilities` - Shared methods (email validation, Chatter posts, ContentNotes)
- `SuccessionChatterPoster` - @InvocableMethod for Chatter notifications

**Test Classes (12):**
All test classes follow naming convention `ClassName_Test.cls` or `ClassNameTest.cls` and include:

- Unit tests with `@TestSetup` methods for shared test data
- Integration tests (`SuccessionIntegrationTest`, `SuccessionWorkflow_Integration_Test`)
- Performance test suite (`SuccessionPerformanceTestSuite`)

### Lightning Web Components (5)

| Component                  | Purpose                                                     | Location                                               |
| -------------------------- | ----------------------------------------------------------- | ------------------------------------------------------ |
| `successionContactCadence` | Primary UI - Date-gated contact attempt tracker             | `force-app/main/default/lwc/successionContactCadence/` |
| `recordPathwaySelection`   | Quick action pathway selector (sets `Pathway_Confirmed__c`) | `force-app/main/default/lwc/recordPathwaySelection/`   |
| `caseHierarchyViewer`      | Visual case hierarchy tree                                  | `force-app/main/default/lwc/caseHierarchyViewer/`      |
| `createSuccessionCase`     | Multi-successor case creation form                          | `force-app/main/default/lwc/createSuccessionCase/`     |
| `successionPublicForm`     | Guest user pathway selection                                | `force-app/main/default/lwc/successionPublicForm/`     |

### Custom Fields (23 across Case, Task, Account)

**Case Fields (14):**

- `Pathway_Confirmed__c` - **Trigger field** for automation (Final Grant, New DAF, Disclaim)
- `Contact_Attempt_Count__c`, `Contact_Established__c`, `Contact_Established_Date__c`
- `Form_Sent_Date__c`, `Form_Completed_Date__c`
- `Successor__c`, `Successor_Email__c`, `Successor_Phone__c`
- `Execution_Status__c`, `Verification_Status__c`, `SLA_Status__c`
- `Deceased_Donor__c` (lookup to Account)
- `New_DAF_Account_Number__c`

**Task Fields (2):**

- `Contact_Attempt_Number__c` (1-5)
- `Succession_Contact_Established__c` (checkbox)

See [manifest/package.xml](manifest/package.xml) for complete metadata inventory.

## Security Model

### Apex Security Patterns

**Default:** `WITH USER_MODE` or `AccessLevel.USER_MODE` on all Database operations
**Exception:** `SuccessionTaskGenerator` uses `SYSTEM_MODE` (lines 82, 92) for automated task creation in guest user scenarios

### Permission Sets

- `Succession_Management_Access` - Core app access for case workers
- `Succession_Field_Access` - Field-level security on succession fields
- `Succession_Guest_Access` - Limited access for external form submission

## Idempotency & Data Integrity

### Duplicate Prevention

- **Cases**: `CreateSuccessionCaseController` validates no existing cases for Financial Account before creation (SYSTEM_MODE query + just-in-time recheck)
- **Contact Attempts**: `ContactCadenceController` checks for existing `Contact_Attempt_Number__c` before creating next attempt
- **Pathway Tasks**: `SuccessionTaskGenerator` queries existing tasks by Subject before creating pathway series

### Timezone Handling

All date calculations use `Date.newInstance(year, month, day)` for timezone-safe arithmetic across global orgs.

### Accessibility (WCAG 2.1 AA Compliant)

- LWC components use `aria-live` regions for screen reader announcements
- No reliance on unreliable Experience Cloud toasts
- Accessible modal dialogs (no `window.confirm()`)
- Full keyboard navigation support

## Code Style & Patterns

### Apex Conventions

- **Naming:** PascalCase for classes, camelCase for methods/properties, UPPER_CASE for constants
- **Test classes:** Must include `_Test` or `Test` suffix
- **Static utilities:** Shared methods in `SuccessionUtilities`
- **Invocable methods:** Use `@InvocableMethod` with `@InvocableVariable` for Flow integration
- **Error handling:** Try/catch with descriptive AuraHandledExceptions for LWC communication

### LWC Patterns

- **Data retrieval:** `@wire` decorators with `cacheable: true` for read operations
- **State management:** `@track` for reactive properties
- **Validation:** Computed getters (e.g., `get canSendEmail()`)
- **Navigation:** Import `NavigationMixin` for page navigation
- **Refresh:** Use `refreshApex()` after mutations
- **Button protection:** Implement double-click prevention on async operations

### Test Data Strategy

- Use `@TestSetup` methods for shared test data
- Smock-it plugin available for bulk test data generation (see [docs/SMOCK_IT_GUIDE.md](docs/SMOCK_IT_GUIDE.md))
- Test data must include proper FinancialAccountRole relationships

## D2 Diagrams

The codebase includes D2 diagrams for architecture visualization:

**Diagram Sources:** `docs/diagrams/d2/*.d2`
**Rendered SVGs:** `docs/diagrams/svg/*.svg`

**Available Diagrams:**

- `architecture.d2` - Component architecture (UI → Controller → Automation → Data)
- `automation_sequence.d2` - Trigger-based pathway task creation flow
- `case_state.d2` - 4-phase case state machine
- `data_model_erd.d2` - ERD showing standard object relationships

**Regenerate all diagrams:**

```bash
./scripts/render_d2.sh
```

**Use TALA layout engine (if available):**

```bash
D2_LAYOUT=tala ./scripts/render_d2.sh
```

## Common Development Tasks

### Adding a New Custom Field

1. Create field metadata: `force-app/main/default/objects/Case/fields/MyField__c.field-meta.xml`
2. Add field to relevant permission sets
3. Update `manifest/package.xml` to include the new field
4. Update test classes to include the field in test scenarios

### Adding a New Apex Class

1. Create class: `force-app/main/default/classes/MyClass.cls`
2. Create test class: `force-app/main/default/classes/MyClass_Test.cls`
3. Use `WITH USER_MODE` for all Database operations (unless automation requires SYSTEM_MODE)
4. Add both files to `manifest/package.xml`
5. Run tests: `sf apex run test --tests MyClass_Test`

### Adding a New LWC Component

1. Create component: `force-app/main/default/lwc/myComponent/`
2. Create test: `force-app/main/default/lwc/myComponent/__tests__/myComponent.test.js`
3. Add to `manifest/package.xml`
4. Run tests: `npm test`

### Modifying Pathway Task Generation

To change tasks created by pathway automation:

1. Edit [SuccessionTaskGenerator.cls](force-app/main/default/classes/SuccessionTaskGenerator.cls)
2. Modify one of these methods:
   - `generateFinalGrantTasks()` (lines 102-146)
   - `generateNewDAFTasks()` (lines 148-187)
   - `generateDisclaimTasks()` (lines 189-228)
3. Update corresponding test: [SuccessionTaskGenerator_Test.cls](force-app/main/default/classes/SuccessionTaskGenerator_Test.cls)
4. Deploy and run tests

### Updating Contact Cadence Schedule

Contact cadence is defined in Custom Metadata:

1. Edit records in `force-app/main/default/customMetadata/`
   - `Succession_Contact_Cadence.Attempt_2.md-meta.xml`
   - `Succession_Contact_Cadence.Attempt_3.md-meta.xml`
   - `Succession_Contact_Cadence.Attempt_4.md-meta.xml`
   - `Succession_Contact_Cadence.Attempt_5.md-meta.xml`
2. Fields to modify:
   - `Days_Offset__c` - Days from case creation
   - `Email_Template_ID__c` - Template for automated emails
   - `Attempt_Label__c` - Display label

## Important Notes

### Demo Environment Constraints

- **No validation rules** - System allows flexible data entry for demo purposes
- **Simplified security** - Some controllers suppress PMD.ApexCRUDViolation warnings
- **Production readiness** - Additional validation and constraints should be added for production use

### Flow Metadata Status

All flows in `force-app/main/default/flows/` are marked as `Inactive` in source control. The primary automation is trigger-based via `SuccessionCaseTrigger` → `SuccessionTaskGenerator`. Flows are preserved for reference but are not active in the org.

### Working with Financial Services Cloud

- Requires FSC license
- Uses standard FSC objects: FinancialAccount, FinancialAccountRole
- Person Account configuration may be required for proper Contact/Account relationships
- Case Record Type: "Estate Administration" must exist

### MCP Salesforce Tools

If Salesforce MCP tools are available, they can be used for:

- Querying records: `mcp__salesforce__salesforce_query_records`
- Describing objects: `mcp__salesforce__salesforce_describe_object`
- Running Apex tests: `mcp__salesforce__salesforce_execute_anonymous`
- Managing debug logs: `mcp__salesforce__salesforce_manage_debug_logs`

Always prefer MCP tools over manual SOQL/Apex execution when available.
