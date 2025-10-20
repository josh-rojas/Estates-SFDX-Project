## Copilot instructions for this repository

Purpose: give short, actionable rules so an AI coding agent can be productive immediately in this Salesforce Financial Services Cloud demo project.

- Read high-level docs first: `AGENTS.md`, `CLAUDE.md`, and `README.md` (root). They contain architecture, constraints, and commands.

- Key constraints (must follow):
  - Demo sandbox rules: DO NOT add validation rules, approval processes, or production security constraints.
  - Do NOT introduce custom objects. This project intentionally uses standard Salesforce objects only (Case, Account/PersonAccount, Task, FinancialAccount, FinancialAccountRole).
  - Email compliance: always validate email before sending (see regex below and `PersonHasOptedOutOfEmail`).

- Quick commands (use exact commands in docs):
  - Deploy metadata: `sf project deploy start --manifest manifest/package.xml`
  - Run Apex tests: `sf apex run test --test-level RunLocalTests --code-coverage`
  - LWC unit tests / lint: `npm run test:unit`, `npm run lint`, `npm run prettier`
  - CumulusCI test data: `cci task run load_demo_ui_showcase` or `cci task run load_succession_test_data`

- File / component locations to inspect and modify:
  - Apex classes: `force-app/main/default/classes/`
  - LWC components: `force-app/main/default/lwc/` (active: `successionContactCadence`, `caseHierarchyViewer`, `successionPublicForm`, `recordPathwaySelection`)
  - Flows: `force-app/main/default/flows/` (look for names like `Case_Create_Initial_Contact_Attempt`, `Task_Create_Next_Contact_Attempt`, `Case_Multiple_Successors_Handler`)
  - Action Plan Templates: `force-app/main/default/actionPlanTemplates/`
  - Dataset recipes & mapping: `datasets/` (e.g. `datasets/succession_demo.recipe.yml`, `datasets/succession_mapping.yml`)
  - Deployment manifest: `manifest/package.xml`

- Important architectural patterns (why it is structured this way):
  - Uses only standard objects to simplify org maintenance and demo portability.
  - Flows are used for scheduled/contact cadence and multi-successor orchestration so business logic is visible to admins (search `Task_Create_Next_Contact_Attempt`).
  - LWCs are thin UIs backed by `@AuraEnabled` Apex cacheable methods and `@wire` for initial load; use `refreshApex()` after mutations.

- Code/PR rules specific to this repo:
  - Apex: all DB operations must run WITH USER_MODE (see `AGENTS.md`/`CLAUDE.md`). Enforce FLS, use try/catch, and annotate read methods with `@AuraEnabled(cacheable=true)` when appropriate.
  - LWC: prefix components with `succession` where applicable. Use NavigationMixin for navigation and Lightning Data Service for CRUD where possible.
  - Flows: include gate/decision checks (e.g., check `Contact_Established__c` before scheduling next task).

- Email validation specifics (copyable):
  - Regex: `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`
  - Check for presence of `PersonEmail` (PersonAccount) or Contact.Email and the opt-out field `PersonHasOptedOutOfEmail` / `HasOptedOutOfEmail` before enabling send.

- Multi-successor pattern to follow (common change area):
  - Flow `Case_Multiple_Successors_Handler` creates a parent `Multi-Account Succession Master` and child `Named Successor Enactment` records. Use `caseHierarchyViewer` LWC only for parent cases.

- How to find examples and patterns quickly:
  - Search for exact flow/class/component names from docs (e.g. `Case_Create_Initial_Contact_Attempt`, `ContactCadenceController`, `successionContactCadence`).
  - Inspect `force-app/main/default/lwc/*/` for UI patterns (date-gating, consecutive attempt locking).

- Testing & verification tips:
  - Use `sf apex run test` for Apex. Use `npm run test:unit` for LWC Jest tests.
  - Use the CumulusCI recipes under `datasets/` to generate demo data that matches expected PersonAccount + FinancialAccountRole shapes.
  - When deploying changes, prefer deploying focused source dirs (classes / lwc / flows) instead of whole manifest for faster feedback: `sf project deploy start --source-dir force-app/main/default/classes`.

- PR notes for reviewers (short):
  - Ensure no validation rules were added. Verify Apex uses WITH USER_MODE and respects FLS. Confirm LWC uses `@wire`/`refreshApex` and that email send UI checks opt-out.

If anything in these notes is unclear or you want me to expand any section (flows, Apex patterns, LWC examples, or deployment steps), say which section and I'll iterate.
