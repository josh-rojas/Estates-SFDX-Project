# Task: Succession Contact Update

## Flow Diagram

```mermaid
%% If you read this, your Markdown visualizer does not handle MermaidJS syntax.
%% - If you are in VS Code, install extension `Markdown Preview Mermaid Support` at https://marketplace.visualstudio.com/items?itemName=bierner.markdown-mermaid
%% - If you are using sfdx-hardis, try to define env variable `MERMAID_MODES=cli,docker` ,then run again the command to regenerate markdown with SVG images.
%% - If you are within mkdocs-material, define mermaid plugin in `mkdocs.yml` as described in https://squidfunk.github.io/mkdocs-material/extensions/mermaid/
%% - As a last resort, you can copy-paste this MermaidJS code into https://mermaid.live/ to see the flow diagram

flowchart TB
START(["START<br/><b>AutoLaunched Flow</b></br>Type: <b> Record After Save</b>"]):::startClass
click START "#general-information" "2697526076"

Check_Contact_Established{"🔀 <em></em><br/>Check Contact Established"}:::decisions
click Check_Contact_Established "#check_contact_established" "862694928"

Get_Parent_Case[("🔍 <em></em><br/>Get Parent Case")]:::recordLookups
click Get_Parent_Case "#get_parent_case" "289344333"

Update_Contact_Established[("🛠️ <em></em><br/>Update Contact Established")]:::recordUpdates
click Update_Contact_Established "#update_contact_established" "1832207521"

Check_Contact_Established --> |"Contact Was Established"| Update_Contact_Established
Check_Contact_Established --> |"Contact Not Established"| END_Check_Contact_Established
Get_Parent_Case --> Check_Contact_Established
Get_Parent_Case -. Fault .->Check_Contact_Established
Update_Contact_Established --> END_Update_Contact_Established
START -->  Get_Parent_Case
END_Check_Contact_Established(( END )):::endClass
END_Update_Contact_Established(( END )):::endClass


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
|Object|Task|
|Process Type| Auto Launched Flow|
|Trigger Type| Record After Save|
|Record Trigger Type| Update|
|Label|Task: Succession Contact Update|
|Status|Active|
|Filter Formula|AND(<br/>    ISCHANGED({!$Record.Status}),<br/>    TEXT({!$Record.Status}) = "Completed",<br/>    NOT(ISBLANK({!$Record.Contact_Attempt_Number__c}))<br/>)|
|Description|Sets Case.Contact_Established__c when a Task is completed with Succession_Contact_Established__c = TRUE. Acts as circuit breaker to stop the cadence. Includes fault connector for parent case lookup.|
|Environments|Default|
|Interview Label|Task: Succession Contact Update {!$Flow.CurrentDateTime}|
| Builder Type (PM)|LightningFlowBuilder|
| Canvas Mode (PM)|AUTO_LAYOUT_CANVAS|
| Origin Builder Type (PM)|LightningFlowBuilder|
|Connector|[Get_Parent_Case](#get_parent_case)|
|Next Node|[Get_Parent_Case](#get_parent_case)|


## Flow Nodes Details

### Check_Contact_Established

|<!-- -->|<!-- -->|
|:---|:---|
|Type|Decision|
|Label|Check Contact Established|
|Default Connector Label|Contact Not Established|


#### Rule Contact_Was_Established (Contact Was Established)

|<!-- -->|<!-- -->|
|:---|:---|
|Connector|[Update_Contact_Established](#update_contact_established)|
|Condition Logic|and|




|Condition Id|Left Value Reference|Operator|Right Value|
|:-- |:-- |:--:|:--: |
|1|$Record.Succession_Contact_Established__c| Equal To|✅|




### Get_Parent_Case

|<!-- -->|<!-- -->|
|:---|:---|
|Type|Record Lookup|
|Object|Case|
|Label|Get Parent Case|
|Assign Null Values If No Records Found|⬜|
|Fault Connector|[Check_Contact_Established](#check_contact_established)|
|Get First Record Only|✅|
|Store Output Automatically|✅|
|Connector|[Check_Contact_Established](#check_contact_established)|


#### Filters (logic: **and**)

|Filter Id|Field|Operator|Value|
|:-- |:-- |:--:|:--: |
|1|Id| Equal To|$Record.WhatId|




### Update_Contact_Established

|<!-- -->|<!-- -->|
|:---|:---|
|Type|Record Update|
|Object|Case|
|Label|Update Contact Established|


#### Filters (logic: **and**)

|Filter Id|Field|Operator|Value|
|:-- |:-- |:--:|:--: |
|1|Id| Equal To|$Record.WhatId|




#### Input Assignments

|Field|Value|
|:-- |:--: |
|Contact_Established__c|✅|








___

_Documentation generated from branch main by [sfdx-hardis](https://sfdx-hardis.cloudity.com), featuring [salesforce-flow-visualiser](https://github.com/toddhalfpenny/salesforce-flow-visualiser)_