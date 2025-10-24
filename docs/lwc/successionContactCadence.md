---
hide:
  - path
---

<!-- This file is auto-generated. if you do not want it to be overwritten, set TRUE in the line below -->
<!-- DO_NOT_OVERWRITE_DOC=FALSE -->

## successionContactCadence

<!-- LWC description -->

## JS Documentation

## Members

<dl>
<dt><a href="#showInvalidRecordType">showInvalidRecordType</a></dt>
<dd><p>Check if record type is invalid</p>
</dd>
<dt><a href="#invalidRecordTypeMessage">invalidRecordTypeMessage</a></dt>
<dd><p>Get invalid record type message</p>
</dd>
<dt><a href="#hasData">hasData</a></dt>
<dd><p>Check if component has data to display</p>
</dd>
<dt><a href="#hasScheduledTasks">hasScheduledTasks</a></dt>
<dd><p>Check if any tasks are actually scheduled (not just placeholder attempts)</p>
</dd>
<dt><a href="#progressPercent">progressPercent</a></dt>
<dd><p>Get progress percentage (0-100)</p>
</dd>
<dt><a href="#progressBarStyle">progressBarStyle</a></dt>
<dd><p>Get progress bar width style
Fills to each completed node&#39;s position
Nodes are at: 0%, 25%, 50%, 75%, 100%</p>
</dd>
<dt><a href="#sendEmailButtonLabel">sendEmailButtonLabel</a></dt>
<dd><p>Get send email button label</p>
</dd>
<dt><a href="#progressStatusText">progressStatusText</a></dt>
<dd><p>Get progress status text</p>
</dd>
<dt><a href="#progressNodesClass">progressNodesClass</a></dt>
<dd><p>CSS class for progress bar fill based on completion</p>
</dd>
<dt><a href="#showProgressLine">showProgressLine</a></dt>
<dd><p>Show progress line when there are completed attempts and current attempt</p>
</dd>
<dt><a href="#pendingEmailTemplateLabel">pendingEmailTemplateLabel</a></dt>
<dd><p>Template label hint for the pending email prompt (desktop)</p>
</dd>
<dt><a href="#canSendEmail">canSendEmail</a></dt>
<dd><p>Check if email sending is available (all validation passed)</p>
</dd>
<dt><a href="#hasEmailWarning">hasEmailWarning</a></dt>
<dd><p>Check if there are email warnings to display</p>
</dd>
<dt><a href="#emailWarningMessage">emailWarningMessage</a></dt>
<dd><p>Get email warning message</p>
</dd>
<dt><a href="#attemptsWithProps">attemptsWithProps</a></dt>
<dd><p>Get attempts with computed properties for template
PERFORMANCE: Memoized to prevent unnecessary recalculations</p>
</dd>
<dt><a href="#contactEstablished">contactEstablished</a></dt>
<dd><p>Get contact established boolean from radio value</p>
</dd>
</dl>

## Functions

<dl>
<dt><a href="#validateForm">validateForm()</a></dt>
<dd><p>Enhanced form validation
PERFORMANCE: Validates form data before API calls</p>
</dd>
<dt><a href="#wiredCadence">wiredCadence()</a></dt>
<dd><p>Wire adapter to fetch contact cadence data</p>
</dd>
<dt><a href="#getCardClass">getCardClass()</a></dt>
<dd><p>Get CSS class for attempt card
ENHANCED: Differentiates between successful and unsuccessful contact attempts</p>
</dd>
<dt><a href="#getProgressNodeClass">getProgressNodeClass()</a></dt>
<dd><p>Get CSS class for progress bar node</p>
</dd>
<dt><a href="#handleEdit">handleEdit()</a></dt>
<dd><p>Handle Edit button click
PERFORMANCE: Uses centralized state management</p>
</dd>
<dt><a href="#handleCancel">handleCancel()</a></dt>
<dd><p>Handle Cancel button click
PERFORMANCE: Uses centralized state management</p>
</dd>
<dt><a href="#handleContactMadeChange">handleContactMadeChange()</a></dt>
<dd><p>Handle radio button change
PERFORMANCE: Uses centralized state management</p>
</dd>
<dt><a href="#handleNotesChange">handleNotesChange()</a></dt>
<dd><p>Handle notes textarea change
PERFORMANCE: Uses centralized state management</p>
</dd>
<dt><a href="#toggleCollapse">toggleCollapse()</a></dt>
<dd><p>Toggle collapsible state
PERFORMANCE: Uses centralized state management</p>
</dd>
<dt><a href="#formatRemaining">formatRemaining()</a></dt>
<dd><p>Utility: format remaining ms to a compact string (e.g., &quot;12d 4h&quot;)</p>
</dd>
<dt><a href="#connectedCallback">connectedCallback()</a></dt>
<dd><p>Handle component initialization and data loading
Countdowns are calculated on-demand when data changes, not with timers</p>
</dd>
<dt><a href="#disconnectedCallback">disconnectedCallback()</a></dt>
<dd><p>Clean up any async handles if component is destroyed</p>
</dd>
<dt><a href="#handleSaveOutcome">handleSaveOutcome()</a></dt>
<dd><p>Handle Save Outcome button click
ENHANCED: Includes comprehensive error handling and performance optimizations
FIX: Properly advances to next attempt after save</p>
</dd>
<dt><a href="#showToastWithEmailOption">showToastWithEmailOption()</a></dt>
<dd><p>Show toast with option to send follow-up email</p>
</dd>
<dt><a href="#handleSendEmail">handleSendEmail()</a></dt>
<dd><p>Handle Send Email button click
Includes double-click prevention and email validation</p>
</dd>
<dt><a href="#handleSkipEmail">handleSkipEmail()</a></dt>
<dd><p>Handle Skip Email button click
This is the ONLY way to dismiss the email prompt (keeps it visible if agent closes composer)</p>
</dd>
<dt><a href="#openListEmailDialog">openListEmailDialog()</a></dt>
<dd><p>Open Send List Email dialog with appropriate template based on attempt number</p>
<p>FIX: Uses direct URL navigation to email composer
This avoids the &quot;Invalid template returned by render()&quot; error</p>
<p>NOTE: This handles both Person Accounts and Business Accounts with Contacts.</p>
<ul>
<li>Person Account: Opens email composer for Account</li>
<li>Business Account: Opens email composer for Contact</li>
</ul>
</dd>
<dt><a href="#showToast">showToast()</a></dt>
<dd><p>Show toast notification</p>
</dd>
</dl>

<a name="showInvalidRecordType"></a>

## showInvalidRecordType
Check if record type is invalid

**Kind**: global variable  
<a name="invalidRecordTypeMessage"></a>

## invalidRecordTypeMessage
Get invalid record type message

**Kind**: global variable  
<a name="hasData"></a>

## hasData
Check if component has data to display

**Kind**: global variable  
<a name="hasScheduledTasks"></a>

## hasScheduledTasks
Check if any tasks are actually scheduled (not just placeholder attempts)

**Kind**: global variable  
<a name="progressPercent"></a>

## progressPercent
Get progress percentage (0-100)

**Kind**: global variable  
<a name="progressBarStyle"></a>

## progressBarStyle
Get progress bar width style
Fills to each completed node's position
Nodes are at: 0%, 25%, 50%, 75%, 100%

**Kind**: global variable  
<a name="sendEmailButtonLabel"></a>

## sendEmailButtonLabel
Get send email button label

**Kind**: global variable  
<a name="progressStatusText"></a>

## progressStatusText
Get progress status text

**Kind**: global variable  
<a name="progressNodesClass"></a>

## progressNodesClass
CSS class for progress bar fill based on completion

**Kind**: global variable  
<a name="showProgressLine"></a>

## showProgressLine
Show progress line when there are completed attempts and current attempt

**Kind**: global variable  
<a name="pendingEmailTemplateLabel"></a>

## pendingEmailTemplateLabel
Template label hint for the pending email prompt (desktop)

**Kind**: global variable  
<a name="canSendEmail"></a>

## canSendEmail
Check if email sending is available (all validation passed)

**Kind**: global variable  
<a name="hasEmailWarning"></a>

## hasEmailWarning
Check if there are email warnings to display

**Kind**: global variable  
<a name="emailWarningMessage"></a>

## emailWarningMessage
Get email warning message

**Kind**: global variable  
<a name="attemptsWithProps"></a>

## attemptsWithProps
Get attempts with computed properties for template
PERFORMANCE: Memoized to prevent unnecessary recalculations

**Kind**: global variable  
<a name="contactEstablished"></a>

## contactEstablished
Get contact established boolean from radio value

**Kind**: global variable  
<a name="validateForm"></a>

## validateForm()
Enhanced form validation
PERFORMANCE: Validates form data before API calls

**Kind**: global function  
<a name="wiredCadence"></a>

## wiredCadence()
Wire adapter to fetch contact cadence data

**Kind**: global function  
<a name="getCardClass"></a>

## getCardClass()
Get CSS class for attempt card
ENHANCED: Differentiates between successful and unsuccessful contact attempts

**Kind**: global function  
<a name="getProgressNodeClass"></a>

## getProgressNodeClass()
Get CSS class for progress bar node

**Kind**: global function  
<a name="handleEdit"></a>

## handleEdit()
Handle Edit button click
PERFORMANCE: Uses centralized state management

**Kind**: global function  
<a name="handleCancel"></a>

## handleCancel()
Handle Cancel button click
PERFORMANCE: Uses centralized state management

**Kind**: global function  
<a name="handleContactMadeChange"></a>

## handleContactMadeChange()
Handle radio button change
PERFORMANCE: Uses centralized state management

**Kind**: global function  
<a name="handleNotesChange"></a>

## handleNotesChange()
Handle notes textarea change
PERFORMANCE: Uses centralized state management

**Kind**: global function  
<a name="toggleCollapse"></a>

## toggleCollapse()
Toggle collapsible state
PERFORMANCE: Uses centralized state management

**Kind**: global function  
<a name="formatRemaining"></a>

## formatRemaining()
Utility: format remaining ms to a compact string (e.g., "12d 4h")

**Kind**: global function  
<a name="connectedCallback"></a>

## connectedCallback()
Handle component initialization and data loading
Countdowns are calculated on-demand when data changes, not with timers

**Kind**: global function  
<a name="disconnectedCallback"></a>

## disconnectedCallback()
Clean up any async handles if component is destroyed

**Kind**: global function  
<a name="handleSaveOutcome"></a>

## handleSaveOutcome()
Handle Save Outcome button click
ENHANCED: Includes comprehensive error handling and performance optimizations
FIX: Properly advances to next attempt after save

**Kind**: global function  
<a name="showToastWithEmailOption"></a>

## showToastWithEmailOption()
Show toast with option to send follow-up email

**Kind**: global function  
<a name="handleSendEmail"></a>

## handleSendEmail()
Handle Send Email button click
Includes double-click prevention and email validation

**Kind**: global function  
<a name="handleSkipEmail"></a>

## handleSkipEmail()
Handle Skip Email button click
This is the ONLY way to dismiss the email prompt (keeps it visible if agent closes composer)

**Kind**: global function  
<a name="openListEmailDialog"></a>

## openListEmailDialog()
Open Send List Email dialog with appropriate template based on attempt number

FIX: Uses direct URL navigation to email composer
This avoids the "Invalid template returned by render()" error

NOTE: This handles both Person Accounts and Business Accounts with Contacts.
- Person Account: Opens email composer for Account
- Business Account: Opens email composer for Contact

**Kind**: global function  
<a name="showToast"></a>

## showToast()
Show toast notification

**Kind**: global function  


## Files

- `successionContactCadence.css`
- `successionContactCadence.html`
- `successionContactCadence.js`
- `successionContactCadence.js-meta.xml`



_Documentation generated with [sfdx-hardis](https://sfdx-hardis.cloudity.com), by [Cloudity](https://www.cloudity.com/) & [friends](https://github.com/hardisgroupcom/sfdx-hardis/graphs/contributors)_
