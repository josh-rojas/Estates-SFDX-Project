# Implementation Plan

[Overview]
Fix metadata and test warnings by downgrading the Case actionable list definition file to the GA ActionableListDefinition schema and resolving LWC test/lint issues, while documenting precise file changes and testing steps for a clean validate pipeline.

The Case actionable list definition currently uses an unsupported root element (ActionableListDefinition2), causing XML schema validation failures during deploy/validate. LWC unit tests raise LWC1702 warnings flagged in the task context; we will ensure the test setup and mocks align with sfdx-lwc-jest, and address SLDS utility class guidance in the public form CSS either by selective replacements or by documenting acceptance criteria for current styles in this sprint. This plan details exact changes, signatures, and order so implementation can proceed without more discovery.

[Types]
No Apex type system changes are required; only metadata XML structure and JavaScript test scaffolding considerations apply.

No new Apex classes, interfaces, or enums are introduced. The ActionableListDefinition metadata structure is defined per Metadata API (GA) with the ActionableListDefinition root element and its children (actionableListDatasetColumns, datasetName, masterLabel, batchCalcJobDefinition, isActive, objectName). JavaScript test files maintain existing exports and mocks; no TS/Flow type updates are introduced.

[Files]
We will modify one metadata file and optionally adjust CSS utility classes; Jest config and package.json remain valid.

- New files to be created:
  - None.

- Existing files to be modified:
  - force-app/main/default/actionableListDefinitions/Case.actionableListDefinition-meta.xml
    - Replace root element ActionableListDefinition2 with ActionableListDefinition.
    - Maintain the xmlns="http://soap.sforce.com/2006/04/metadata".
    - Preserve all actionableListDatasetColumns and terminal fields.
    - Validate element ordering per Metadata API where required (root children ordering: actionableListDatasetColumns*, batchCalcJobDefinition?, datasetName, isActive, masterLabel, objectName).

  - force-app/main/default/lwc/successionPublicForm/successionPublicForm.css (optional, if team opts to align with SLDS guidance now)
    - Apply minimal SLDS utility class replacements for comments flagged:
      - Prefer slds-var- tokens when feasible; where custom design is intentional, leave as-is and document rationale.

- Files to be deleted or moved:
  - None.

- Configuration file updates:
  - None required. Existing jest.config.js and package.json scripts are suitable.
  - If SLDS class enforcement is desired later, consider eslint rules or stylelint configuration in a follow-up change.

[Functions]
No function signatures change; test files remain functionally equivalent.

- New functions: None.
- Modified functions: None (LWC tests remain as-is; mocks are compatible with @salesforce/sfdx-lwc-jest 7.x).
- Removed functions: None.

[Classes]
No Apex/LWC classes require changes for this fix scope.

- New classes: None.
- Modified classes: None.
- Removed classes: None.

[Dependencies]
No new packages or dependency changes required.

The repo already uses @salesforce/sfdx-lwc-jest ^7.0.2 and a valid jest.config.js. No schema packages are required for metadata validation; correctness is ensured by conforming to the GA element names and structure.

[Testing]
Unit tests will be executed via existing scripts; metadata will be validated by sf deploy --dry-run or PR checks.

- Execute npm run validate (lint + unit tests).
- Optionally run sf project deploy validate (or use MCP deploy_metadata with NoTestRun) to ensure metadata compiles server-side.
- Confirm no LWC1702 errors appear. If warnings persist, confirm they are informational and not blocking; capture test output.

[Implementation Order]
Execute metadata correction first, then optional CSS adjustments, then run tests and validation.

1. Update force-app/main/default/actionableListDefinitions/Case.actionableListDefinition-meta.xml
   - Replace <ActionableListDefinition2> with <ActionableListDefinition> and ensure closing tag matches.
   - Preserve child elements and order: actionableListDatasetColumns*, batchCalcJobDefinition?, datasetName, isActive, masterLabel, objectName.
   - Save and format via Prettier XML plugin (auto-run with existing hooks).

2. Decide on CSS action:
   - If aligning now: selectively replace custom spacing/utility with SLDS slds-var-* equivalents where trivial and non-breaking.
   - Else: document acceptance of current styles for this iteration (no file changes).

3. Run local validations:
   - npm run lint
   - npm run test:unit (or npm run validate)
   - Ensure no schema errors and that Jest passes.

4. Optional org validation (no deployment):
   - Use MCP deploy_metadata with NoTestRun or sf project deploy validate to confirm metadata compiles in the target org.

5. Prepare commit message documenting the schema downgrade and any CSS notes.
