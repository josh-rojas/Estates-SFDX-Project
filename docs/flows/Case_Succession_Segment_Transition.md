# Case: Succession Segment Transition

## Flow Diagram

```mermaid
%% If you read this, your Markdown visualizer does not handle MermaidJS syntax.
%% - If you are in VS Code, install extension `Markdown Preview Mermaid Support` at https://marketplace.visualstudio.com/items?itemName=bierner.markdown-mermaid
%% - If you are using sfdx-hardis, try to define env variable `MERMAID_MODES=cli,docker` ,then run again the command to regenerate markdown with SVG images.
%% - If you are within mkdocs-material, define mermaid plugin in `mkdocs.yml` as described in https://squidfunk.github.io/mkdocs-material/extensions/mermaid/
%% - As a last resort, you can copy-paste this MermaidJS code into https://mermaid.live/ to see the flow diagram

flowchart TB
START(["START<br/><b>AutoLaunched Flow</b></br>Type: <b> Record After Save</b>"]):::startClass
click START "#general-information" "1564659628"

Post_Transition_to_Chatter("⚡ <em></em><br/>Post Transition to Chatter"):::actionCalls
click Post_Transition_to_Chatter "#post_transition_to_chatter" "4105938069"

Set_Contact_Established_Message[\"🟰 <em></em><br/>Set Contact Established Message"/]:::assignments
click Set_Contact_Established_Message "#set_contact_established_message" "2830306782"

Set_Form_Completed_Message[\"🟰 <em></em><br/>Set Form Completed Message"/]:::assignments
click Set_Form_Completed_Message "#set_form_completed_message" "1118982619"

Which_Transition_Occurred{"🔀 <em></em><br/>Which Transition Occurred?"}:::decisions
click Which_Transition_Occurred "#which_transition_occurred" "3081253824"

Is_Segment_Transition{"🔀 <em></em><br/>Is Segment Transition?"}:::decisions
click Is_Segment_Transition "#is_segment_transition" "3495838679"

Post_Transition_to_Chatter --> END_Post_Transition_to_Chatter
Set_Contact_Established_Message --> Post_Transition_to_Chatter
Set_Form_Completed_Message --> Post_Transition_to_Chatter
Which_Transition_Occurred --> |"Contact Established Transition"| Set_Contact_Established_Message
Which_Transition_Occurred --> |"Form Completed Transition"| Set_Form_Completed_Message
Which_Transition_Occurred --> |"Other Transition"| END_Which_Transition_Occurred
Is_Segment_Transition --> |"Transition Detected"| Which_Transition_Occurred
Is_Segment_Transition --> |"No Transition"| END_Is_Segment_Transition
START -->  Is_Segment_Transition
END_Post_Transition_to_Chatter(( END )):::endClass
END_Which_Transition_Occurred(( END )):::endClass
END_Is_Segment_Transition(( END )):::endClass


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
|Label|Case: Succession Segment Transition|
|Status|Active|
|Filter Formula|AND(<br/>    RecordType.DeveloperName = "EstateAdministration",<br/>    IsClosed = FALSE<br/>)|
|Description|Logs key succession segment transitions and notifies the case feed. Triggers on Estate Administration cases when Contact_Established__c, Form_Completed_Date__c, or Pathway_Confirmed__c change. Posts a concise Chatter message indicating the new segment and next action to aid demo narration and agent handoffs.|
|Environments|Default|
|Interview Label|Case: Succession Segment Transition {!$Flow.CurrentDateTime}|
| Builder Type (PM)|LightningFlowBuilder|
| Canvas Mode (PM)|AUTO_LAYOUT_CANVAS|
| Origin Builder Type (PM)|LightningFlowBuilder|
|Connector|[Is_Segment_Transition](#is_segment_transition)|
|Next Node|[Is_Segment_Transition](#is_segment_transition)|


## Variables

|Name|Data Type|Is Collection|Is Input|Is Output|Object Type|Description|
|:-- |:--:|:--:|:--:|:--:|:--:|:--  |
|ChatterMessage|String|⬜|⬜|⬜|<!-- -->|<!-- -->|


## Flow Nodes Details

### Post_Transition_to_Chatter

|<!-- -->|<!-- -->|
|:---|:---|
|Type|Action Call|
|Label|Post Transition to Chatter|
|Action Type|Chatter Post|
|Action Name|chatterPost|
|Flow Transaction Model|CurrentTransaction|
|Name Segment|chatterPost|
|Version Segment|1|
|Text (input)|ChatterMessage|
|Subject Name Or Id (input)|$Record.Id|


### Set_Contact_Established_Message

|<!-- -->|<!-- -->|
|:---|:---|
|Type|Assignment|
|Label|Set Contact Established Message|
|Connector|[Post_Transition_to_Chatter](#post_transition_to_chatter)|


#### Assignments

|Assign To Reference|Operator|Value|
|:-- |:--:|:--: |
|ChatterMessage| Assign|📞 ✅ Workflow Transition: Contact established with successor. Case moved to "Awaiting Form" segment. Next: Send pathway selection form.|




### Set_Form_Completed_Message

|<!-- -->|<!-- -->|
|:---|:---|
|Type|Assignment|
|Label|Set Form Completed Message|
|Connector|[Post_Transition_to_Chatter](#post_transition_to_chatter)|


#### Assignments

|Assign To Reference|Operator|Value|
|:-- |:--:|:--: |
|ChatterMessage| Assign|✅ 📋 Workflow Transition: Pathway form completed. Pathway: {!$Record.Pathway_Confirmed__c}. Case moved to "Form Completed" segment. Next: Gather required documentation.|




### Which_Transition_Occurred

|<!-- -->|<!-- -->|
|:---|:---|
|Type|Decision|
|Label|Which Transition Occurred?|
|Default Connector Label|Other Transition|


#### Rule Contact_Established_Transition (Contact Established Transition)

|<!-- -->|<!-- -->|
|:---|:---|
|Connector|[Set_Contact_Established_Message](#set_contact_established_message)|
|Condition Logic|and|




|Condition Id|Left Value Reference|Operator|Right Value|
|:-- |:-- |:--:|:--: |
|1|$Record.Contact_Established__c| Equal To|✅|
|2|$Record__Prior.Contact_Established__c| Equal To|⬜|




#### Rule Form_Completed_Transition (Form Completed Transition)

|<!-- -->|<!-- -->|
|:---|:---|
|Connector|[Set_Form_Completed_Message](#set_form_completed_message)|
|Condition Logic|and|




|Condition Id|Left Value Reference|Operator|Right Value|
|:-- |:-- |:--:|:--: |
|1|$Record.Form_Completed_Date__c| Is Null|⬜|
|2|$Record__Prior.Form_Completed_Date__c| Is Null|✅|




### Is_Segment_Transition

|<!-- -->|<!-- -->|
|:---|:---|
|Type|Decision|
|Label|Is Segment Transition?|
|Default Connector Label|No Transition|


#### Rule Transition_Detected (Transition Detected)

|<!-- -->|<!-- -->|
|:---|:---|
|Connector|[Which_Transition_Occurred](#which_transition_occurred)|
|Condition Logic|or|




|Condition Id|Left Value Reference|Operator|Right Value|
|:-- |:-- |:--:|:--: |
|1|$Record.Contact_Established__c| Not Equal To|$Record__Prior.Contact_Established__c|
|2|$Record.Form_Completed_Date__c| Is Changed|✅|
|3|$Record.Pathway_Confirmed__c| Is Changed|✅|








___

_Documentation generated from branch main by [sfdx-hardis](https://sfdx-hardis.cloudity.com), featuring [salesforce-flow-visualiser](https://github.com/toddhalfpenny/salesforce-flow-visualiser)_