---
hide:
  - path
---

## Lightning Web Components

| Component | Description | Exposed | Targets |
| :-------- | :---------- | :-----: | :------------- |
| [successionPublicForm](successionPublicForm.md) | Public succession pathway selection form for successors. Accessible without login via Experience Cloud or public Site. Displays account information and allows selection between Final Grant, New DAF Account, or Disclaim Assets pathways. | ✅ | lightningCommunity__Page, lightningCommunity__Default |
| [successionContactCadence](successionContactCadence.md) | Displays 5-attempt contact cadence as progress bar and kanban card grid for Succession Management cases. Allows inline editing of contact attempt outcomes. | ✅ | lightning__RecordPage, lightning__AppPage, lightning__HomePage |
| [successionAccountSummary](successionAccountSummary.md) | Displays deceased donor account information and financial account details during succession processing. Shows account balances, successor allocations, and relationship information for verification before pathway selection. | ❌ |  |
| [recordPathwaySelection](recordPathwaySelection.md) | Quick Action for agents to record succession pathway selection after verbal conversation. Simple manual override for Final Grant, New DAF Account, or Disclaim Assets. | ✅ | lightning__RecordAction |
| [createSuccessionCase](createSuccessionCase.md) | Lightning Web Component for FinancialAccount Quick Action to create succession cases. Handles loading, error, and success states with automatic case navigation. | ✅ | lightning__RecordAction |
| [caseHierarchyViewer](caseHierarchyViewer.md) | Configurable hierarchy viewer for any Case with parent-child relationships. Admins can select which child Case fields to display via component properties. | ✅ | lightning__RecordPage, lightning__AppPage, lightning__HomePage |
| [beginSuccessionProcessing](beginSuccessionProcessing.md) |  | ✅ | lightning__RecordAction |


_Documentation generated from branch main with [sfdx-hardis](https://sfdx-hardis.cloudity.com) by [Cloudity](https://cloudity.com) command [`sf hardis:doc:project2markdown`](https://sfdx-hardis.cloudity.com/hardis/doc/project2markdown/)_
