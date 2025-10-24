# Case - Create Initial Contact Attempt

## Flow Diagram

```mermaid
%% If you read this, your Markdown visualizer does not handle MermaidJS syntax.
%% - If you are in VS Code, install extension `Markdown Preview Mermaid Support` at https://marketplace.visualstudio.com/items?itemName=bierner.markdown-mermaid
%% - If you are using sfdx-hardis, try to define env variable `MERMAID_MODES=cli,docker` ,then run again the command to regenerate markdown with SVG images.
%% - If you are within mkdocs-material, define mermaid plugin in `mkdocs.yml` as described in https://squidfunk.github.io/mkdocs-material/extensions/mermaid/
%% - As a last resort, you can copy-paste this MermaidJS code into https://mermaid.live/ to see the flow diagram

flowchart TB
START(["START<br/><b>AutoLaunched Flow</b></br>Type: <b> Record After Save</b>"]):::startClass
click START "#general-information" "3011775246"

Check_Should_Start_Workflow{"🔀 <em></em><br/>Should Start Workflow?"}:::decisions
click Check_Should_Start_Workflow "#check_should_start_workflow" "2871581068"

Create_Attempt_1_Task[("➕ <em></em><br/>Create Attempt 1 Task")]:::recordCreates
click Create_Attempt_1_Task "#create_attempt_1_task" "1670065399"

START -->  Check_Should_Start_Workflow
Check_Should_Start_Workflow --> |"Yes - Start Workflow"| Create_Attempt_1_Task
Check_Should_Start_Workflow --> |"No - Exit"| END_Check_Should_Start_Workflow
Create_Attempt_1_Task --> END_Create_Attempt_1_Task
END_Check_Should_Start_Workflow(( END )):::endClass
END_Create_Attempt_1_Task(( END )):::endClass


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
|Record Trigger Type| Create And Update|
|Label|Case - Create Initial Contact Attempt|
|Status|Active|
|Filter Formula|AND(<br/>    RecordType.DeveloperName = "EstateAdministration",<br/>    TEXT({!$Record.Type}) = "Named Successor Enactment",<br/>    NOT(ISBLANK({!$Record.ContactId})),<br/>    NOT(ISBLANK({!$Record.Successor__c})),<br/>    NOT({!$Record.IsClosed}),<br/>    OR(<br/>        ISNEW(),<br/>        ISCHANGED({!$Record.Verification_Status__c})<br/>    )<br/>)|
|Description|Seeds Attempt 1 (Day 0) when Verification_Status__c becomes "Complete - Verified" on an Estate Administration case. Guards against duplicates via Contact_Attempt_Count__c IS NULL. Triggers on create or when the verification field changes. Adds Builder UI metadata for clarity.|
| Builder Type (PM)|LightningFlowBuilder|
| Canvas Mode (PM)|AUTO_LAYOUT_CANVAS|
| Origin Builder Type (PM)|LightningFlowBuilder|
|Connector|[Check_Should_Start_Workflow](#check_should_start_workflow)|
|Next Node|[Check_Should_Start_Workflow](#check_should_start_workflow)|


## Flow Nodes Details

### Check_Should_Start_Workflow

|<!-- -->|<!-- -->|
|:---|:---|
|Type|Decision|
|Label|Should Start Workflow?|
|Default Connector Label|No - Exit|


#### Rule Start_Workflow (Yes - Start Workflow)

|<!-- -->|<!-- -->|
|:---|:---|
|Connector|[Create_Attempt_1_Task](#create_attempt_1_task)|
|Condition Logic|and|




|Condition Id|Left Value Reference|Operator|Right Value|
|:-- |:-- |:--:|:--: |
|1|$Record.Verification_Status__c| Equal To|Complete - Verified|
|2|$Record.Contact_Attempt_Count__c| Is Null|✅|




### Create_Attempt_1_Task

|<!-- -->|<!-- -->|
|:---|:---|
|Type|Record Create|
|Object|Task|
|Label|Create Attempt 1 Task|
|Store Output Automatically|✅|


#### Input Assignments

|Field|Value|
|:-- |:--: |
|WhatId|$Record.Id|
|Subject|Succession Contact - Attempt 1 (Day 0)|
|Status|Not Started|
|Priority|High|
|ActivityDate|$Flow.CurrentDate|
|Contact_Attempt_Number__c|1|
|Description|Contact attempt for succession case.|








___

_Documentation generated from branch main by [sfdx-hardis](https://sfdx-hardis.cloudity.com), featuring [salesforce-flow-visualiser](https://github.com/toddhalfpenny/salesforce-flow-visualiser)_