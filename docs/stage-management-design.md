# Stage Management Design (Concept Only)

This document models how Salesforce Stage Management COULD represent the Succession Case lifecycle. It is **concept-only**, **not active**, and must not change runtime behavior without explicit approval.

## Target Scope

- Object: `Case`
- Record Type: `EstateAdministration`
- Types:
  - `Named Successor Enactment` (primary)
  - `Multi-Account Succession Master` (parent summary)

## Proposed Stages

1. `Created`
2. `Contact_Cadence`
3. `Pathway_Pending`
4. `Pathway_Selected`
5. `Execution_In_Progress`
6. `Closed`

## Mapping to Existing Logic

- Transitions must:
  - Call existing Apex (`CreateSuccessionCaseController`, `ContactCadenceController`, `SuccessionPublicFormController`, `SuccessionTaskGenerator`, `SuccessionUtilities`).
  - Never create tasks or send emails directly in Stage logic.
  - Respect multi-successor rules (parent stage derived from children).
  - Preserve `SuccessionCaseTrigger` → `SuccessionTaskGenerator` as the only task-creation trigger.

## Implementation Guidance

- When Stage Management metadata is officially available and stable:
  - Create stage definitions that mirror the stages above.
  - Add assignment rules scoped to EstateAdministration / Named Successor Enactment.
  - Keep them **inactive** until validated in a sandbox.
  - Ensure all actions delegate to existing Apex utilities instead of duplicating logic.

This file is documentation-only and should guide future configuration, not drive current automation.
