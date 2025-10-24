---
hide:
  - path
---

## Flows

| Object | Name      | Type | Description |
| :----  | :-------- | :--: | :---------- | 
| Case | [Case_Create_Initial_Contact_Attempt](Case_Create_Initial_Contact_Attempt.md) |  Record After Save | Seeds Attempt 1 (Day 0) when Verification_Status__c becomes "Complete - Verified" on an Estate Administration case. Guards against duplicates via Contact_Attempt_Count__c IS NULL. Triggers on create or when the verification field changes. Adds Builder UI metadata for clarity. |
| Case | [Case_Parent_Closure_Handler](Case_Parent_Closure_Handler.md) |  Record After Save | Monitors child case status changes and automatically closes the parent Multi-Account Succession Master case when all child Named Successor Enactment cases reach terminal status (Closed or Canceled). |
| Case | [Case_Status_Coordination](Case_Status_Coordination.md) |  Record After Save | Automatically coordinates Case Status field updates across the 5-phase succession workflow. Updates Status based on phase-tracking field changes (Verification_Status__c, Contact_Established__c, Form_Completed_Date__c, Pathway_Confirmed__c, Execution_Status__c). |
| Case | [Case_Succession_Segment_Transition](Case_Succession_Segment_Transition.md) |  Record After Save | Logs key succession segment transitions and notifies the case feed. Triggers on Estate Administration cases when Contact_Established__c, Form_Completed_Date__c, or Pathway_Confirmed__c change. Posts a concise Chatter message indicating the new segment and next action to aid demo narration and agent handoffs. |
| Task | [Task_Create_Next_Contact_Attempt](Task_Create_Next_Contact_Attempt.md) |  Record After Save | Creates the next contact attempt when the current attempt Task is completed. Schedules ActivityDate off Case.CreatedDate (Day 5/35/65/95). Exits when contact established or after Attempt 5. Includes fault connector for parent case lookup. |
| Task | [Task_Succession_Contact_Update](Task_Succession_Contact_Update.md) |  Record After Save | Sets Case.Contact_Established__c when a Task is completed with Succession_Contact_Established__c = TRUE. Acts as circuit breaker to stop the cadence. Includes fault connector for parent case lookup. |

_Documentation generated from branch main with [sfdx-hardis](https://sfdx-hardis.cloudity.com) by [Cloudity](https://cloudity.com) command [`sf hardis:doc:project2markdown`](https://sfdx-hardis.cloudity.com/hardis/doc/project2markdown/)_
