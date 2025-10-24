# Case: Status Coordination

## Flow Diagram

```mermaid
%% If you read this, your Markdown visualizer does not handle MermaidJS syntax.
%% - If you are in VS Code, install extension `Markdown Preview Mermaid Support` at https://marketplace.visualstudio.com/items?itemName=bierner.markdown-mermaid
%% - If you are using sfdx-hardis, try to define env variable `MERMAID_MODES=cli,docker` ,then run again the command to regenerate markdown with SVG images.
%% - If you are within mkdocs-material, define mermaid plugin in `mkdocs.yml` as described in https://squidfunk.github.io/mkdocs-material/extensions/mermaid/
%% - As a last resort, you can copy-paste this MermaidJS code into https://mermaid.live/ to see the flow diagram

flowchart TB
START(["START<br/><b>AutoLaunched Flow</b></br>Type: <b> Record After Save</b>"]):::startClass
click START "#general-information" "223498634"

Update_Status_to_In_Progress_Phase1[("🛠️ <em></em><br/>Update Status to In Progress (Phase 1)")]:::recordUpdates
click Update_Status_to_In_Progress_Phase1 "#update_status_to_in_progress_phase1" "3714381834"

Update_Status_to_Awaiting_Response[("🛠️ <em></em><br/>Update Status to Awaiting Response")]:::recordUpdates
click Update_Status_to_Awaiting_Response "#update_status_to_awaiting_response" "2978601167"

Update_Status_to_In_Review[("🛠️ <em></em><br/>Update Status to In Review")]:::recordUpdates
click Update_Status_to_In_Review "#update_status_to_in_review" "238878231"

Update_Status_to_In_Progress_Phase4[("🛠️ <em></em><br/>Update Status to In Progress (Phase 4)")]:::recordUpdates
click Update_Status_to_In_Progress_Phase4 "#update_status_to_in_progress_phase4" "1762768416"

Update_Status_to_Closed[("🛠️ <em></em><br/>Update Status to Closed")]:::recordUpdates
click Update_Status_to_Closed "#update_status_to_closed" "4100471445"

Check_Phase_Transitions{"🔀 <em></em><br/>Check Phase Transitions"}:::decisions
click Check_Phase_Transitions "#check_phase_transitions" "2505826640"

Update_Status_to_In_Progress_Phase1 --> END_Update_Status_to_In_Progress_Phase1
Update_Status_to_Awaiting_Response --> END_Update_Status_to_Awaiting_Response
Update_Status_to_In_Review --> END_Update_Status_to_In_Review
Update_Status_to_In_Progress_Phase4 --> END_Update_Status_to_In_Progress_Phase4
Update_Status_to_Closed --> END_Update_Status_to_Closed
Check_Phase_Transitions --> |"Phase 1→2: Verification Complete"| Update_Status_to_In_Progress_Phase1
Check_Phase_Transitions --> |"Phase 2→3: Contact Established"| Update_Status_to_Awaiting_Response
Check_Phase_Transitions --> |"Phase 3→4: Form Completed"| Update_Status_to_In_Review
Check_Phase_Transitions --> |"Phase 4→5: Pathway Selected"| Update_Status_to_In_Progress_Phase4
Check_Phase_Transitions --> |"Phase 5→Complete: Execution Done"| Update_Status_to_Closed
Check_Phase_Transitions --> |"No Status Change Needed"| END_Check_Phase_Transitions
START -->  Check_Phase_Transitions
END_Update_Status_to_In_Progress_Phase1(( END )):::endClass
END_Update_Status_to_Awaiting_Response(( END )):::endClass
END_Update_Status_to_In_Review(( END )):::endClass
END_Update_Status_to_In_Progress_Phase4(( END )):::endClass
END_Update_Status_to_Closed(( END )):::endClass
END_Check_Phase_Transitions(( END )):::endClass


classDef actionCalls fill:#D4E4FC,color:black,text-decoration:none,max-height:100px
classDef assignments fill:#FBEED7,color:black,text-decoration:none,max-height:100px
classDef collectionProcessors fill:#F0E3FA,color:black,text-decoration:none,max-height:100px
classDef customErrors fill:#FFE9E9,color:black,text-decoration:none,max-height:100px
classDef decisions fill:#FDEAF6,color:black,text-decoration:none,max-height:100px
classDef loops fill:#FDEAF6,color:black,text-decoration:none,max-height:100px
classDef recordCreates fill:#FFF8C9,color:black,text-decoration:none,max-height:100px
classDef recordDeletes fill:#FFF8C9,color:black,text-decoration:none,max-height:100px
classDef recordLookups fill:#EDEAFF,color:black,text-decoration:none,max-height:100px
classDef recordUpdates fill:#FFF8C9,color:black,text-decoration:none,max-height:100px
classDef screens fill:#DFF6FF,color:black,text-decoration:none,max-height:100px
classDef subflows fill:#D4E4FC,color:black,text-decoration:none,max-height:100px
classDef startClass fill:#D9F2E6,color:black,text-decoration:none,max-height:100px
classDef endClass fill:#F9BABA,color:black,text-decoration:none,max-height:100px
classDef transforms fill:#FDEAF6,color:black,text-decoration:none,max-height:100px


```

<!-- Flow description -->

## General Information

|<!-- -->|<!-- -->|
|:---|:---|
|Object|Case|
|Process Type| Auto Launched Flow|
|Trigger Type| Record After Save|
|Record Trigger Type| Update|
|Label|Case: Status Coordination|
|Status|Active|
|Filter Formula|AND(<br/>    RecordType.DeveloperName = "EstateAdministration",<br/>    IsClosed = FALSE<br/>)|
|Description|Automatically coordinates Case Status field updates across the 5-phase succession workflow. Updates Status based on phase-tracking field changes (Verification_Status__c, Contact_Established__c, Form_Completed_Date__c, Pathway_Confirmed__c, Execution_Status__c).|
|Environments|Default|
|Interview Label|Case: Status Coordination {!$Flow.CurrentDateTime}|
| Builder Type (PM)|LightningFlowBuilder|
| Canvas Mode (PM)|AUTO_LAYOUT_CANVAS|
| Origin Builder Type (PM)|LightningFlowBuilder|
|Connector|[Check_Phase_Transitions](#check_phase_transitions)|
|Next Node|[Check_Phase_Transitions](#check_phase_transitions)|


## Flow Nodes Details

### Update_Status_to_In_Progress_Phase1

|<!-- -->|<!-- -->|
|:---|:---|
|Type|Record Update|
|Label|Update Status to In Progress (Phase 1)|
|Input Reference|$Record|


#### Input Assignments

|Field|Value|
|:-- |:--: |
|Status|In Progress|




### Update_Status_to_Awaiting_Response

|<!-- -->|<!-- -->|
|:---|:---|
|Type|Record Update|
|Label|Update Status to Awaiting Response|
|Input Reference|$Record|


#### Input Assignments

|Field|Value|
|:-- |:--: |
|Status|Awaiting Response|




### Update_Status_to_In_Review

|<!-- -->|<!-- -->|
|:---|:---|
|Type|Record Update|
|Label|Update Status to In Review|
|Input Reference|$Record|


#### Input Assignments

|Field|Value|
|:-- |:--: |
|Status|In Review|




### Update_Status_to_In_Progress_Phase4

|<!-- -->|<!-- -->|
|:---|:---|
|Type|Record Update|
|Label|Update Status to In Progress (Phase 4)|
|Input Reference|$Record|


#### Input Assignments

|Field|Value|
|:-- |:--: |
|Status|In Progress|




### Update_Status_to_Closed

|<!-- -->|<!-- -->|
|:---|:---|
|Type|Record Update|
|Label|Update Status to Closed|
|Input Reference|$Record|


#### Input Assignments

|Field|Value|
|:-- |:--: |
|Status|Closed|




### Check_Phase_Transitions

|<!-- -->|<!-- -->|
|:---|:---|
|Type|Decision|
|Label|Check Phase Transitions|
|Default Connector Label|No Status Change Needed|


#### Rule Phase_1_to_2_Verification_Complete (Phase 1→2: Verification Complete)

|<!-- -->|<!-- -->|
|:---|:---|
|Connector|[Update_Status_to_In_Progress_Phase1](#update_status_to_in_progress_phase1)|
|Condition Logic|and|




|Condition Id|Left Value Reference|Operator|Right Value|
|:-- |:-- |:--:|:--: |
|1|$Record.Verification_Status__c| Is Changed|✅|
|2|$Record.Verification_Status__c| Equal To|Complete - Verified|




#### Rule Phase_2_to_3_Contact_Established (Phase 2→3: Contact Established)

|<!-- -->|<!-- -->|
|:---|:---|
|Connector|[Update_Status_to_Awaiting_Response](#update_status_to_awaiting_response)|
|Condition Logic|and|




|Condition Id|Left Value Reference|Operator|Right Value|
|:-- |:-- |:--:|:--: |
|1|$Record.Contact_Established__c| Is Changed|✅|
|2|$Record.Contact_Established__c| Equal To|✅|
|3|$Record.Form_Sent_Date__c| Is Null|⬜|




#### Rule Phase_3_to_4_Form_Completed (Phase 3→4: Form Completed)

|<!-- -->|<!-- -->|
|:---|:---|
|Connector|[Update_Status_to_In_Review](#update_status_to_in_review)|
|Condition Logic|and|




|Condition Id|Left Value Reference|Operator|Right Value|
|:-- |:-- |:--:|:--: |
|1|$Record.Form_Completed_Date__c| Is Changed|✅|
|2|$Record.Form_Completed_Date__c| Is Null|⬜|




#### Rule Phase_4_to_5_Pathway_Selected (Phase 4→5: Pathway Selected)

|<!-- -->|<!-- -->|
|:---|:---|
|Connector|[Update_Status_to_In_Progress_Phase4](#update_status_to_in_progress_phase4)|
|Condition Logic|and|




|Condition Id|Left Value Reference|Operator|Right Value|
|:-- |:-- |:--:|:--: |
|1|$Record.Pathway_Confirmed__c| Is Changed|✅|
|2|$Record.Pathway_Confirmed__c| Not Equal To|Not Selected|




#### Rule Phase_5_to_Complete_Execution_Done (Phase 5→Complete: Execution Done)

|<!-- -->|<!-- -->|
|:---|:---|
|Connector|[Update_Status_to_Closed](#update_status_to_closed)|
|Condition Logic|and|




|Condition Id|Left Value Reference|Operator|Right Value|
|:-- |:-- |:--:|:--: |
|1|$Record.Execution_Status__c| Is Changed|✅|
|2|$Record.Execution_Status__c| Equal To|Completed|








___

_Documentation generated from branch main by [sfdx-hardis](https://sfdx-hardis.cloudity.com), featuring [salesforce-flow-visualiser](https://github.com/toddhalfpenny/salesforce-flow-visualiser)_