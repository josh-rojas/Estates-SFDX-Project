# GitHub Copilot Instructions for Estates-SFDX-Project

## 1. Big Picture

- This repo is the "Succession Management System" on Salesforce FSC for deceased donor account transitions.
- End-to-end flow: Case creation → contact cadence → guest/agent pathway selection → pathway task generation → case closure.
- Design is demo-first: use only standard/FSC objects, keep automation simple, predictable, and easy to walk through live.

## 2. Core Architecture & Ownership

- Apex controllers + LWCs, with one primary trigger pipeline.
- Key Apex (`force-app/main/default/classes/`):
  - `CreateSuccessionCaseController`: single vs. multi-successor case creation.
  - `ContactCadenceController`: 5-step, date-gated contact cadence + email validation.
  - `SuccessionPublicFormController`: guest pathway form load/submit.
  - `SuccessionTaskGenerator`: creates pathway-specific tasks when `Pathway_Confirmed__c` changes.
  - `SuccessionUtilities`: record type lookup, email compliance, Chatter, ContentNote helpers.
- Key LWCs (`force-app/main/default/lwc/`):
  - `createSuccessionCase`, `successionContactCadence`, `recordPathwaySelection`, `successionPublicForm`, `caseHierarchyViewer`.
- Trigger: `SuccessionCaseTrigger` → `SuccessionTaskGenerator` only. Do not add other triggers or duplicate logic in flows.

## 3. Non-Obvious Rules (Must Follow)

- All flows in `force-app/main/default/flows/` are INACTIVE; automation is Apex/trigger-based.
- Use `WITH USER_MODE` / `AccessLevel.USER_MODE` for Apex queries + DML, except `SuccessionTaskGenerator` (intentionally SYSTEM_MODE).
- Person Accounts: use `PersonContactId` whenever a Contact is required; do not create separate Contacts for these cases.
- Multi-successor pattern: when multiple successors, always create one parent `Multi-Account Succession Master` + child `Named Successor Enactment` cases; keep hierarchy consistent for `caseHierarchyViewer`.
- Email is compliance-critical: before any send/enable, validate presence, format, and opt-out using existing patterns (`SuccessionUtilities.validateEmail`, `ContactCadenceController.validateEmailAddress`).
- Do not introduce strict validation rules or breaking changes that would block scripted demo paths.

## 4. Implementation Patterns

- New Apex controllers: mirror `CreateSuccessionCaseController` / `SuccessionPublicFormController`:
  - `@AuraEnabled(cacheable=true)` for reads, DTO-style wrapper classes, centralized utility calls, USER_MODE.
- New LWCs: follow SLDS usage + patterns from `successionContactCadence` and `recordPathwaySelection`; call existing Apex controllers when possible.
- Pathway/task changes: extend `SuccessionTaskGenerator` with focused `generateXxxTasks` methods + tests in `SuccessionTaskGenerator_Test.cls` instead of new flows.

## 5. Stage Management (Design-Only, Optional)

- You MAY model the 4-phase lifecycle using Stage Management for documentation or future use, but DO NOT enable it or change runtime behavior without approval.
- If modeled, define clear stages for `Case` (EstateAdministration, `Named Successor Enactment`):
  - `Created` → `Contact_Cadence` → `Pathway_Pending` → `Pathway_Selected` → `Execution_In_Progress` → `Closed`.
- Stage transitions MUST:
  - Call existing Apex (e.g., `SuccessionUtilities`, `SuccessionTaskGenerator`) instead of duplicating task/email logic.
  - Respect multi-successor rules: parent stages derived from child stages; no independent parent-only automation.
  - Preserve trigger as single source for pathway tasks; no new task-creating triggers/flows.

## 6. Workflows & Commands

- Deploy: `sf project deploy start --manifest manifest/package.xml` (target alias e.g. `schwab-sandbox`).
- Run Apex tests: `sf apex run test --test-level RunLocalTests --code-coverage`.
- LWC tests: `npm run test:unit`.
- Lint/format: `npm run lint`, `npm run prettier`, `npm run prettier:verify`.

## 7. References for Agents

- `AGENTS.md`: concise architecture, commands, key rules.
- `CLAUDE.md`: deep-dive patterns (multi-successor, flows→Apex migration, LWCs).
- `README.md` + `docs/0x-*.md`: setup, diagrams, deployment, and runbook details.

Always align new code with these patterns instead of inventing new architectures.
