# Case: Parent Closure Handler

## Flow Diagram

```mermaid
%% If you read this, your Markdown visualizer does not handle MermaidJS syntax.
%% - If you are in VS Code, install extension `Markdown Preview Mermaid Support` at https://marketplace.visualstudio.com/items?itemName=bierner.markdown-mermaid
%% - If you are using sfdx-hardis, try to define env variable `MERMAID_MODES=cli,docker` ,then run again the command to regenerate markdown with SVG images.
%% - If you are within mkdocs-material, define mermaid plugin in `mkdocs.yml` as described in https://squidfunk.github.io/mkdocs-material/extensions/mermaid/
%% - As a last resort, you can copy-paste this MermaidJS code into https://mermaid.live/ to see the flow diagram

flowchart TB
START(["START<br/><b>AutoLaunched Flow</b></br>Type: <b> Record After Save</b>"]):::startClass
click START "#general-information" "2396485186"

Set_Has_Open_Child_True[\"🟰 <em></em><br/>Set Has Open Child = True"/]:::assignments
click Set_Has_Open_Child_True "#set_has_open_child_true" "974388132"

All_Children_Complete{"🔀 <em></em><br/>All Children Complete?"}:::decisions
click All_Children_Complete "#all_children_complete" "309638401"

Check_If_Child_Is_Open{"🔀 <em></em><br/>Check If Child Is Open"}:::decisions
click Check_If_Child_Is_Open "#check_if_child_is_open" "375678152"

Loop_Through_Children{{"🔁 <em></em><br/>Loop Through Children"}}:::loops
click Loop_Through_Children "#loop_through_children" "2705723338"

Get_All_Child_Cases[("🔍 <em></em><br/>Get All Child Cases")]:::recordLookups
click Get_All_Child_Cases "#get_all_child_cases" "2111071563"

Get_Parent_Case[("🔍 <em></em><br/>Get Parent Case")]:::recordLookups
click Get_Parent_Case "#get_parent_case" "3358477199"

Update_Parent_Case_Closed[("🛠️ <em></em><br/>Update Parent Case to Closed")]:::recordUpdates
click Update_Parent_Case_Closed "#update_parent_case_closed" "3624773906"

Set_Has_Open_Child_True --> END_Set_Has_Open_Child_True
All_Children_Complete --> |"All Closed or Canceled"| Update_Parent_Case_Closed
All_Children_Complete --> |"Has Open Children"| END_All_Children_Complete
Check_If_Child_Is_Open --> |"Child Still Open"| Set_Has_Open_Child_True
Check_If_Child_Is_Open --> |"Child Is Complete"| Loop_Through_Children
Loop_Through_Children --> |"For Each"|Check_If_Child_Is_Open
Loop_Through_Children ---> |"After Last"|All_Children_Complete
Get_All_Child_Cases --> Loop_Through_Children
Get_All_Child_Cases -. Fault .->Loop_Through_Children
Get_Parent_Case --> Get_All_Child_Cases
Get_Parent_Case -. Fault .->Get_All_Child_Cases
Update_Parent_Case_Closed --> END_Update_Parent_Case_Closed
START -->  Get_Parent_Case
END_Set_Has_Open_Child_True(( END )):::endClass
END_All_Children_Complete(( END )):::endClass
END_Update_Parent_Case_Closed(( END )):::endClass


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
|Label|Case: Parent Closure Handler|
|Status|Active|
|Filter Formula|AND(<br/>    RecordType.DeveloperName = "EstateAdministration",<br/>    TEXT({!$Record.Type}) = "Named Successor Enactment",<br/>    NOT(ISBLANK({!$Record.ParentId})),<br/>    ISCHANGED({!$Record.Status}),<br/>    OR(<br/>        TEXT({!$Record.Status}) = "Closed",<br/>        TEXT({!$Record.Status}) = "Canceled"<br/>    )<br/>)|
|Description|Monitors child case status changes and automatically closes the parent Multi-Account Succession Master case when all child Named Successor Enactment cases reach terminal status (Closed or Canceled).|
|Environments|Default|
|Interview Label|Case: Parent Closure Handler {!$Flow.CurrentDateTime}|
| Builder Type (PM)|LightningFlowBuilder|
| Canvas Mode (PM)|AUTO_LAYOUT_CANVAS|
| Origin Builder Type (PM)|LightningFlowBuilder|
|Connector|[Get_Parent_Case](#get_parent_case)|
|Next Node|[Get_Parent_Case](#get_parent_case)|


## Variables

|Name|Data Type|Is Collection|Is Input|Is Output|Object Type|Description|
|:-- |:--:|:--:|:--:|:--:|:--:|:--  |
|varHasOpenChild|Boolean|⬜|⬜|⬜|<!-- -->|<!-- -->|


## Flow Nodes Details

### Set_Has_Open_Child_True

|<!-- -->|<!-- -->|
|:---|:---|
|Type|Assignment|
|Label|Set Has Open Child = True|


#### Assignments

|Assign To Reference|Operator|Value|
|:-- |:--:|:--: |
|varHasOpenChild| Assign|✅|




### All_Children_Complete

|<!-- -->|<!-- -->|
|:---|:---|
|Type|Decision|
|Label|All Children Complete?|
|Default Connector Label|Has Open Children|


#### Rule All_Closed_or_Canceled (All Closed or Canceled)

|<!-- -->|<!-- -->|
|:---|:---|
|Connector|[Update_Parent_Case_Closed](#update_parent_case_closed)|
|Condition Logic|and|




|Condition Id|Left Value Reference|Operator|Right Value|
|:-- |:-- |:--:|:--: |
|1|varHasOpenChild| Equal To|⬜|




### Check_If_Child_Is_Open

|<!-- -->|<!-- -->|
|:---|:---|
|Type|Decision|
|Label|Check If Child Is Open|
|Default Connector|[Loop_Through_Children](#loop_through_children)|
|Default Connector Label|Child Is Complete|


#### Rule Child_Still_Open (Child Still Open)

|<!-- -->|<!-- -->|
|:---|:---|
|Connector|[Set_Has_Open_Child_True](#set_has_open_child_true)|
|Condition Logic|and|




|Condition Id|Left Value Reference|Operator|Right Value|
|:-- |:-- |:--:|:--: |
|1|Loop_Through_Children.Status| Not Equal To|Closed|
|2|Loop_Through_Children.Status| Not Equal To|Canceled|




### Loop_Through_Children

|<!-- -->|<!-- -->|
|:---|:---|
|Type|Loop|
|Label|Loop Through Children|
|Collection Reference|[Get_All_Child_Cases](#get_all_child_cases)|
|Iteration Order|Asc|
|Next Value Connector|[Check_If_Child_Is_Open](#check_if_child_is_open)|
|No More Values Connector|[All_Children_Complete](#all_children_complete)|


### Get_All_Child_Cases

|<!-- -->|<!-- -->|
|:---|:---|
|Type|Record Lookup|
|Object|Case|
|Label|Get All Child Cases|
|Assign Null Values If No Records Found|⬜|
|Fault Connector|[Loop_Through_Children](#loop_through_children)|
|Get First Record Only|⬜|
|Queried Fields|- Id<br/>- Status<br/>- Type<br/>|
|Store Output Automatically|✅|
|Connector|[Loop_Through_Children](#loop_through_children)|


#### Filters (logic: **and**)

|Filter Id|Field|Operator|Value|
|:-- |:-- |:--:|:--: |
|1|ParentId| Equal To|$Record.ParentId|
|2|RecordType.DeveloperName| Equal To|EstateAdministration|




### Get_Parent_Case

|<!-- -->|<!-- -->|
|:---|:---|
|Type|Record Lookup|
|Object|Case|
|Label|Get Parent Case|
|Assign Null Values If No Records Found|⬜|
|Fault Connector|[Get_All_Child_Cases](#get_all_child_cases)|
|Get First Record Only|✅|
|Queried Fields|- Id<br/>- Status<br/>- Type<br/>|
|Store Output Automatically|✅|
|Connector|[Get_All_Child_Cases](#get_all_child_cases)|


#### Filters (logic: **and**)

|Filter Id|Field|Operator|Value|
|:-- |:-- |:--:|:--: |
|1|Id| Equal To|$Record.ParentId|
|2|Type| Equal To|Multi-Account Succession Master|
|3|Status| Not Equal To|Closed|




### Update_Parent_Case_Closed

|<!-- -->|<!-- -->|
|:---|:---|
|Type|Record Update|
|Object|Case|
|Label|Update Parent Case to Closed|


#### Filters

|Filter Id|Field|Operator|Value|
|:-- |:-- |:--:|:--: |
|1|Id| Equal To|Get_Parent_Case.Id|




#### Input Assignments

|Field|Value|
|:-- |:--: |
|Execution_Status__c|Completed|
|Status|Closed|








___

_Documentation generated from branch main by [sfdx-hardis](https://sfdx-hardis.cloudity.com), featuring [salesforce-flow-visualiser](https://github.com/toddhalfpenny/salesforce-flow-visualiser)_