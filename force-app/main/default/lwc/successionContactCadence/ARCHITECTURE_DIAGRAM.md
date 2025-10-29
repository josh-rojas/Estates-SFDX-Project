# successionContactCadence Component Architecture
## Visual Documentation for Developers

---

## COMPONENT OVERVIEW

```
┌─────────────────────────────────────────────────────────────────────────┐
│                   SUCCESSION CONTACT CADENCE COMPONENT                   │
│                         (1,043 lines JavaScript)                         │
├─────────────────────────────────────────────────────────────────────────┤
│  Purpose: Displays 5-attempt contact cadence with inline editing,       │
│           progress tracking, and email integration                       │
│  Location: force-app/main/default/lwc/successionContactCadence/         │
│  Type: Lightning Web Component (LWC)                                     │
│  Record Context: Case (EstateAdministration record type)                 │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## HIGH-LEVEL ARCHITECTURE

```
┌──────────────┐
│ Salesforce   │
│ Platform     │
└──────┬───────┘
       │
       │ @wire getContactCadence
       │ (automatic reactive updates)
       │
       ▼
┌────────────────────────────────────────────────────────────────┐
│  SUCCESSION CONTACT CADENCE COMPONENT (Parent Container)       │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  STATE MANAGEMENT (Centralized)                          │ │
│  │  • editing: { attemptId, attemptNumber, contactMade }    │ │
│  │  • ui: { isCollapsed, pendingEmailAttempt, ... }         │ │
│  │  • performance: { dataChanged, lastRenderTime }          │ │
│  │  • errorState: { hasError, errorType, ... }             │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  UI SECTIONS (Template-Rendered)                          │ │
│  │  ┌─────────────────────────────────────────────────────┐ │ │
│  │  │ 1. PROGRESS BAR (Top)                                │ │ │
│  │  │    • 5 nodes (0%, 25%, 50%, 75%, 100%)               │ │ │
│  │  │    • Visual fill line based on completion            │ │ │
│  │  │    • Status text: "X of 5 completed"                 │ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  │  ┌─────────────────────────────────────────────────────┐ │ │
│  │  │ 2. EMAIL VALIDATION ALERT (Conditional)              │ │ │
│  │  │    • Shown if email missing/invalid/opted-out        │ │ │
│  │  │    • Warning icon + message                          │ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  │  ┌─────────────────────────────────────────────────────┐ │ │
│  │  │ 3. ATTEMPT CARDS GRID (Main Content)                 │ │ │
│  │  │    ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐    │ │ │
│  │  │    │  #1  │ │  #2  │ │  #3  │ │  #4  │ │  #5  │    │ │ │
│  │  │    │ Day0 │ │ Day5 │ │ Day35│ │ Day65│ │ Day95│    │ │ │
│  │  │    └──────┘ └──────┘ └──────┘ └──────┘ └──────┘    │ │ │
│  │  │    • Kanban-style card layout                        │ │ │
│  │  │    • Color-coded by state (completed/current/pending)│ │ │
│  │  │    • Sequential lock UX (complete in order)          │ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  │  ┌─────────────────────────────────────────────────────┐ │ │
│  │  │ 4. EMAIL PROMPT (Conditional)                        │ │ │
│  │  │    • Shown after negative outcome saved              │ │ │
│  │  │    • "Send Email" / "Skip" buttons                   │ │ │
│  │  │    • Persists until explicitly dismissed             │ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
       │
       │ Imperative Apex calls
       │ (user actions)
       ▼
┌──────────────┐
│ ContactCadence│
│ Controller    │
└───────────────┘
```

---

## DATA FLOW DIAGRAM

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         DATA FLOW SEQUENCE                               │
└─────────────────────────────────────────────────────────────────────────┘

1. COMPONENT MOUNT
   ═══════════════════════════════════════════════════════════════
   User opens Case record page
         │
         ▼
   @wire getContactCadence(caseId)
         │
         │ (Returns ContactCadenceData)
         ├── caseRecord
         ├── attempts[] (5 TaskAttemptData objects)
         ├── emailWarning (validation result)
         ├── contactEstablished (boolean)
         └── currentAttemptNumber (1-5)
         │
         ▼
   wiredCadence() handler
         │
         ├─> Store in this.cadenceData
         ├─> Invalidate memoization cache
         ├─> Calculate UI state
         └─> Trigger template re-render


2. USER INTERACTION - RECORD OUTCOME
   ═══════════════════════════════════════════════════════════════
   User clicks "Record Outcome" button on card
         │
         ▼
   handleEdit(event)
         │
         ├─> Extract taskId and attemptNumber from dataset
         ├─> Update this.state.editing
         ├─> Lock previous attempts (highestAttemptStarted++)
         └─> Invalidate memoization
         │
         ▼
   Template shows inline edit form
         │
         ├─> Radio buttons: "Was contact made?"
         └─> Textarea: "Notes"
         │
         ▼
   User fills form → handleContactMadeChange()
                  → handleNotesChange()
         │
         ▼
   User clicks "Save Outcome"
         │
         ▼
   handleSaveOutcome(event)
         │
         ├─> validateForm() - Check business rules
         │      │
         │      ├─> Contact made selection required
         │      ├─> Notes required if "No" selected
         │      └─> Notes ≤ 255 characters
         │
         ├─> Call saveAttemptOutcome() Apex method
         │      │
         │      │ (Saves to Task.Description + ContentNote)
         │      │
         │      └─> Returns "Success"
         │
         ├─> IF contactEstablished === false:
         │      │
         │      └─> Set pendingEmailAttempt (show email prompt)
         │
         ├─> Advance to next attempt (highestAttemptStarted++)
         ├─> Reset editing state
         └─> Wait 1.5s for ContentNote indexing
                  │
                  └─> refreshApex(wiredCadenceResult)


3. EMAIL COMPOSER INTEGRATION
   ═══════════════════════════════════════════════════════════════
   User clicks "Send Email" button
         │
         ▼
   handleSendEmail(event)
         │
         ├─> Validate email: canSendEmail computed property
         │      │
         │      ├─> hasEmail (not null)
         │      ├─> hasValidEmailFormat (regex)
         │      └─> !hasOptedOut (compliance check)
         │
         ├─> Build email composer URL
         │      │
         │      ├─> Person Account: /lightning/o/Account/email?context={accountId}
         │      └─> Business Account: /lightning/o/Contact/email?context={contactId}
         │
         ├─> NavigationMixin.Navigate to email composer
         ├─> Show toast: "Select template: Day X..."
         └─> Set isNavigatingToEmail = true (double-click prevention)
                  │
                  └─> Wait 2s → Reset isNavigatingToEmail = false


4. COUNTDOWN TIMER CALCULATION (Client-Side)
   ═══════════════════════════════════════════════════════════════
   attemptsWithProps computed property executes
         │
         ▼
   For each attempt (2-5):
         │
         ├─> Get previous attempt completion timestamp
         ├─> Get required wait duration from ATTEMPT_WAIT_MS
         ├─> Calculate: endMs = startMs + waitMs
         │                remainingMs = endMs - now
         │                percent = (waitMs - remainingMs) / waitMs
         │
         └─> Return countdown object:
                {
                  hasCountdown: remainingMs > 0,
                  remainingMs: number,
                  formatted: "12d 4h",
                  percent: 85,
                  unlockAtISO: "2025-12-15T10:30:00Z"
                }

   NOTE: No timers used - calculated on-demand during each render
```

---

## STATE MANAGEMENT ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     CENTRALIZED STATE OBJECT                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  @track state = {                                                        │
│                                                                          │
│    ┌──────────────────────────────────────────────────────────────┐    │
│    │  editing: {     // Form editing state                         │    │
│    │    attemptId: Id | null,                                      │    │
│    │    attemptNumber: 1-5 | null,                                 │    │
│    │    contactMade: "yes" | "no" | "",                            │    │
│    │    notes: string                                               │    │
│    │  }                                                             │    │
│    └──────────────────────────────────────────────────────────────┘    │
│           │                                                              │
│           └─> Used by: handleEdit, handleSave, handleCancel             │
│                                                                          │
│    ┌──────────────────────────────────────────────────────────────┐    │
│    │  ui: {          // UI interaction state                       │    │
│    │    isCollapsed: boolean,         // Progress bar visibility   │    │
│    │    isNavigatingToEmail: boolean, // Email composer loading    │    │
│    │    pendingEmailAttempt: 1-5 | null,  // Email prompt display │    │
│    │    highestAttemptStarted: 0-5    // Sequential lock control   │    │
│    │  }                                                             │    │
│    └──────────────────────────────────────────────────────────────┘    │
│           │                                                              │
│           └─> Used by: handleEdit, handleSendEmail, toggleCollapse      │
│                                                                          │
│    ┌──────────────────────────────────────────────────────────────┐    │
│    │  performance: { // Optimization flags                         │    │
│    │    dataChanged: boolean,     // Invalidates memoization       │    │
│    │    lastRenderTime: timestamp // Performance monitoring        │    │
│    │  }                                                             │    │
│    └──────────────────────────────────────────────────────────────┘    │
│           │                                                              │
│           └─> Used by: attemptsWithProps (memoization check)            │
│                                                                          │
│  }                                                                       │
│                                                                          │
│  @track errorState = {  // Separate error management                    │
│    hasError: boolean,                                                   │
│    errorType: "PERMISSION" | "VALIDATION" | ...,                        │
│    errorMessage: string,                                                 │
│    retryCount: number,                                                   │
│    canRetry: boolean,                                                    │
│    lastErrorTime: timestamp                                              │
│  }                                                                       │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘

DESIGN RATIONALE:
• Centralized state prevents prop drilling in monolithic component
• @track decorator ensures reactivity for nested object changes
• Separation of concerns: editing vs. ui vs. performance vs. error state
• Performance optimizations via dataChanged flag + memoization cache
```

---

## ATTEMPT CARD STATE MACHINE

```
┌─────────────────────────────────────────────────────────────────────────┐
│                   ATTEMPT CARD STATES & TRANSITIONS                      │
└─────────────────────────────────────────────────────────────────────────┘

STATE 1: PENDING (Future Attempts)
═════════════════════════════════════════════════════════════
┌────────────────────────────────────┐
│  ○ Attempt #X (DayY)               │
│  ────────────────────────────────  │
│  Status: Waiting for previous      │
│  attempt                           │
│                                    │
│  [Locked - grayed out]             │
└────────────────────────────────────┘

Properties:
• isPending = true
• isCompleted = false
• isCurrent = false
• isLocked = true
• CSS: "card-pending"

Transition to STATE 2:
→ Previous attempt completed
→ highestAttemptStarted incremented


STATE 2: CURRENT - LOCKED (Date Not Arrived)
═════════════════════════════════════════════════════════════
┌────────────────────────────────────┐
│  ⏺ Attempt #X (DayY)               │
│  ────────────────────────────────  │
│  Status: Scheduled                 │
│  Due: Dec 15, 2025                 │
│                                    │
│  🕒 Unlocks in: 12d 4h             │
│  ████████░░░░░░ 65%                │
└────────────────────────────────────┘

Properties:
• isCurrent = true
• isDateArrived = false
• isLocked = true
• countdown: { hasCountdown: true, formatted: "12d 4h", percent: 65 }
• CSS: "card-current"

Transition to STATE 3:
→ Current date >= ActivityDate


STATE 3: CURRENT - UNLOCKED (Ready for Editing)
═════════════════════════════════════════════════════════════
┌────────────────────────────────────┐
│  ⏺ Attempt #X (DayY)               │
│  ────────────────────────────────  │
│  Status: Ready                     │
│  Due: Dec 15, 2025                 │
│                                    │
│  [Record Outcome Button]           │
└────────────────────────────────────┘

Properties:
• isCurrent = true
• isDateArrived = true
• isLocked = false
• showEditButton = true
• CSS: "card-current"

User Action:
→ Click "Record Outcome" button
→ Transition to STATE 3a


STATE 3a: CURRENT - EDITING
═════════════════════════════════════════════════════════════
┌────────────────────────────────────┐
│  ⏺ Attempt #X (DayY)               │
│  ────────────────────────────────  │
│  Was contact made?                 │
│  ○ Yes  ○ No                       │
│                                    │
│  Notes:                            │
│  [text area with 255 char limit]  │
│                                    │
│  [Save Outcome] [Cancel]           │
└────────────────────────────────────┘

Properties:
• isEditing = true
• showEditForm = true
• state.editing populated with attemptId, attemptNumber

User Actions:
→ Save → Apex call → Transition to STATE 4
→ Cancel → Reset editing state → Back to STATE 3


STATE 4: COMPLETED - POSITIVE (Contact Made)
═════════════════════════════════════════════════════════════
┌────────────────────────────────────┐
│  ✓ Attempt #X (DayY)               │
│  ────────────────────────────────  │
│  Status: Contact Established       │
│  Outcome: YES                      │
│  Completed: Dec 15, 2025 10:30 AM  │
│                                    │
│  Notes: [Read-only notes display]  │
└────────────────────────────────────┘

Properties:
• isCompleted = true
• contactEstablished = true
• CSS: "card-completed" (green)
• showReadOnly = true

Side Effects:
→ Case.Contact_Established__c = TRUE
→ Contact cadence STOPS (no more attempts created)


STATE 4a: COMPLETED - NEGATIVE (Contact Not Made)
═════════════════════════════════════════════════════════════
┌────────────────────────────────────┐
│  ✓ Attempt #X (DayY)               │
│  ────────────────────────────────  │
│  Status: No Contact                │
│  Outcome: NO                       │
│  Completed: Dec 15, 2025 10:30 AM  │
│                                    │
│  Notes: [Read-only notes display]  │
└────────────────────────────────────┘

Properties:
• isCompleted = true
• contactEstablished = false
• CSS: "card-completed-negative" (yellow)
• showReadOnly = true

Side Effects:
→ Next attempt auto-created by flow (if < 5 attempts)
→ Email prompt shown (if pendingEmailAttempt set)


TERMINAL STATE: All 5 Attempts Complete (No Contact Ever Made)
═════════════════════════════════════════════════════════════
→ Agent must manually handle escalation
→ Component enters read-only state for all 5 cards
```

---

## COMPUTED PROPERTIES & MEMOIZATION

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    PERFORMANCE OPTIMIZATION STRATEGY                     │
└─────────────────────────────────────────────────────────────────────────┘

EXPENSIVE COMPUTED PROPERTY:
════════════════════════════════════════════════════════════

get attemptsWithProps() {
  // PERFORMANCE CHECK: Return cached result if data unchanged
  if (this._memoizedAttempts && !this.state.performance.dataChanged) {
    return this._memoizedAttempts;  // ← CACHE HIT - No recalculation
  }

  // EXPENSIVE COMPUTATION (runs for each of 5 attempts):
  // ┌───────────────────────────────────────────────────────────┐
  // │ 1. Build countdown timers from timestamps                 │
  // │    • Query previous completion times                       │
  // │    • Calculate remaining milliseconds                      │
  // │    • Format as "12d 4h" strings                            │
  // │    • Compute progress percentages                          │
  // │                                                            │
  // │ 2. Determine card state (isCompleted/isCurrent/isPending)  │
  // │    • Date comparison (today vs. ActivityDate)              │
  // │    • Sequential lock logic                                 │
  // │                                                            │
  // │ 3. Apply CSS class mappings                                │
  // │    • getCardClass() for each card                          │
  // │    • getProgressNodeClass() for each node                  │
  // │                                                            │
  // │ 4. Extract and filter user notes                           │
  // │    • filterUserNotes() for each completed attempt          │
  // └───────────────────────────────────────────────────────────┘

  const result = this.cadenceData.attempts.map((attempt) => {
    // ... complex calculation (100+ lines) ...
  });

  // CACHE FOR NEXT RENDER
  this._memoizedAttempts = result;
  this.state.performance.dataChanged = false;

  return result;  // ← CACHE MISS - Full recalculation performed
}

CACHE INVALIDATION TRIGGERS:
════════════════════════════════════════════════════════════

1. Wire adapter data refresh
   → this.state.performance.dataChanged = true

2. User edits form field
   → this.state.performance.dataChanged = true

3. User saves outcome
   → this.state.performance.dataChanged = true

4. User cancels editing
   → this.state.performance.dataChanged = true

5. Manual refresh via retryLastOperation()
   → this.state.performance.dataChanged = true

PERFORMANCE BENEFIT:
════════════════════════════════════════════════════════════
• Template renders trigger ~5-10 get attemptsWithProps() calls
• WITHOUT memoization: 500-1000 lines of code executed per render
• WITH memoization: 1 line returned (cache hit) on subsequent calls
• Estimated 80-90% reduction in computation during typical UX flows
```

---

## ERROR HANDLING FLOW

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    CENTRALIZED ERROR MANAGEMENT                          │
└─────────────────────────────────────────────────────────────────────────┘

ANY ERROR OCCURS
     │
     ▼
handleError(error, context)
     │
     ├─> categorizeError(error)
     │      │
     │      └─> Maps error to type:
     │          • PERMISSION (INSUFFICIENT_ACCESS)
     │          • VALIDATION (REQUIRED_FIELD_MISSING)
     │          • DUPLICATE (DUPLICATE_VALUE)
     │          • SERVER (status 500)
     │          • NOT_FOUND (status 404)
     │          • FORBIDDEN (status 403)
     │          • UNKNOWN (fallback)
     │
     ├─> getUserFriendlyMessage(error)
     │      │
     │      └─> Returns actionable user message based on type
     │
     ├─> Update errorState object:
     │      {
     │        hasError: true,
     │        errorType: "VALIDATION",
     │        errorMessage: "Please check your input...",
     │        retryCount: 2,
     │        canRetry: true,
     │        lastErrorTime: 1730000000
     │      }
     │
     └─> showToast("Error", message, "error")
            │
            └─> User sees Lightning toast notification

RECOVERY OPTIONS:
═══════════════════════════════════════════════════════════

Option 1: Automatic Retry (if retryCount < 3)
     │
     └─> retryLastOperation()
            │
            └─> refreshApex(wiredCadenceResult)

Option 2: User Refresh
     │
     └─> User refreshes browser tab
            │
            └─> Component remounts, error cleared

Option 3: Manual Intervention
     │
     └─> Contact support (for persistent errors)
```

---

## EMAIL INTEGRATION ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    EMAIL COMPOSER NAVIGATION FLOW                        │
└─────────────────────────────────────────────────────────────────────────┘

TRIGGER: User clicks "Send Email" button
     │
     ▼
┌─────────────────────────────────────┐
│  Email Validation (canSendEmail)    │
│  ┌─────────────────────────────────┐│
│  │ ✓ hasEmail (not null)           ││
│  │ ✓ hasValidEmailFormat (regex)   ││
│  │ ✓ !hasOptedOut (compliance)     ││
│  └─────────────────────────────────┘│
└─────────────────┬───────────────────┘
                  │
    ┌─────────────┴──────────────┐
    │ PASS                        │ FAIL
    ▼                             ▼
Determine Account Type      Show Error Toast
    │                      "Email sending not available"
    ├─> Person Account
    │   → Use AccountId
    │   → URL: /lightning/o/Account/email?context={accountId}
    │
    └─> Business Account
        → Use ContactId
        → URL: /lightning/o/Contact/email?context={contactId}
        │
        ▼
Build Full URL
/lightning/o/{ObjectApiName}/email?context={recordId}
        │
        ▼
NavigationMixin.Navigate({ type: "standard__webPage", url })
        │
        ├─> Set isNavigatingToEmail = true (disable button)
        │
        ├─> Show toast: "Opening email composer. Select template: Day X..."
        │
        └─> Wait 2 seconds
               │
               └─> Reset isNavigatingToEmail = false (re-enable button)

EMAIL TEMPLATE MAPPING:
═══════════════════════════════════════════════════════════

Attempt #1 → "Day 0 - Initial Contact"
Attempt #2 → "Day 5 - First Follow-Up"
Attempt #3 → "Day 35 - Second Contact"
Attempt #4 → "Day 65 - Third Contact"
Attempt #5 → "Day 95 - Final Contact"

Note: Agent must manually select appropriate template in email composer
```

---

## FILE STRUCTURE

```
force-app/main/default/lwc/successionContactCadence/
│
├── successionContactCadence.js              (1,043 lines)
│   │
│   ├─> Component class definition
│   ├─> State management (@track properties)
│   ├─> Wire adapter (@wire getContactCadence)
│   ├─> Event handlers (handle*)
│   ├─> Computed properties (get *)
│   └─> Utility methods (private helpers)
│
├── successionContactCadence.html            (446 lines)
│   │
│   ├─> Template conditionals (if:true, if:false)
│   ├─> for:each loops (attempt cards)
│   ├─> Event bindings (onclick, onchange)
│   └─> SLDS component usage (lightning-card, etc.)
│
├── successionContactCadence.css             (689 lines)
│   │
│   ├─> Card state styles (.card-completed, .card-current)
│   ├─> Progress bar CSS (.progress-nodes, .progress-fill)
│   ├─> Countdown animation (.countdown-progress)
│   └─> Responsive layout (media queries)
│
├── successionContactCadence.js-meta.xml     (20 lines)
│   │
│   ├─> isExposed: true
│   ├─> targets: lightning__RecordPage
│   └─> targetConfigs: Case object context
│
├── __tests__/
│   └── successionContactCadence.test.js
│       │
│       ├─> Wire adapter mocking
│       ├─> User interaction simulations
│       └─> Assertion tests
│
├── ARCHITECTURE_DIAGRAM.md (this file)
├── UTILITY_EXTRACTION_GUIDE.md
└── [Future] COMPONENT_REFACTOR_PLAN.md
```

---

## INTEGRATION POINTS

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    EXTERNAL DEPENDENCIES & INTEGRATIONS                  │
└─────────────────────────────────────────────────────────────────────────┘

APEX CONTROLLERS:
═══════════════════════════════════════════════════════════
1. ContactCadenceController.getContactCadence(caseId)
   └─> @wire adapter (cacheable=true)
   └─> Returns: ContactCadenceData wrapper
   └─> Auto-refresh on Case field changes

2. ContactCadenceController.saveAttemptOutcome(...)
   └─> Imperative call (not cached)
   └─> Saves Task + ContentNote + Chatter post
   └─> Returns: "Success" or error

SALESFORCE PLATFORM FEATURES:
═══════════════════════════════════════════════════════════
1. NavigationMixin (lightning/navigation)
   └─> Email composer navigation
   └─> Case record navigation

2. refreshApex (salesforce/apex)
   └─> Force wire adapter re-query
   └─> Used after data mutations

3. ShowToastEvent (lightning/platformShowToastEvent)
   └─> User feedback toasts
   └─> Success/error/info variants

4. CloseActionScreenEvent (lightning/actions)
   └─> Close Quick Action modals
   └─> (Note: Not used in this component)

RELATED FLOWS:
═══════════════════════════════════════════════════════════
1. Case_Create_Initial_Contact_Attempt
   └─> Creates Task #1 when Verification_Status__c = "Complete"

2. Task_Create_Next_Contact_Attempt
   └─> Creates Tasks #2-5 when previous task completes

3. Task_Succession_Contact_Update
   └─> Sets Case.Contact_Established__c when contact made

SALESFORCE DATA MODEL:
═══════════════════════════════════════════════════════════
Case (EstateAdministration)
  ├── Contact_Established__c (Boolean)
  ├── Contact_Attempt_Count__c (Number)
  ├── Form_Sent_Date__c (DateTime)
  └── Verification_Status__c (Picklist)

Task (Contact Attempt Tasks)
  ├── Contact_Attempt_Number__c (1-5)
  ├── Succession_Contact_Established__c (Boolean)
  ├── ActivityDate (Date) ← DATE GATING
  ├── Status ("Not Started" | "Completed")
  └── Description (Text) ← User notes backup

ContentNote (Structured Notes)
  ├── Title ("Contact Attempt #X Notes")
  └── Content (Rich Text) ← Primary notes storage

FeedItem (Chatter Posts)
  └── Body (Auto-posted on outcome save)
```

---

## DEVELOPER QUICK REFERENCE

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    KEY CONCEPTS & GOTCHAS                                │
└─────────────────────────────────────────────────────────────────────────┘

SEQUENTIAL LOCK PATTERN:
═══════════════════════════════════════════════════════════
• Attempts must be completed in order (1 → 2 → 3 → 4 → 5)
• Controlled by: state.ui.highestAttemptStarted
• Incremented AFTER successful save (not before)
• Prevents attempt 2 editing while attempt 1 is saving

DATE GATING PATTERN:
═══════════════════════════════════════════════════════════
• Tasks exist in DB but are locked until ActivityDate arrives
• isDateArrived computed client-side: ActivityDate <= today
• Agent cannot record outcome until date arrives
• Prevents premature completion

DUAL STORAGE PATTERN:
═══════════════════════════════════════════════════════════
• User notes saved to BOTH:
  1. Task.Description (immediate, always available)
  2. ContentNote (structured, searchable, 1.5s delay)
• If ContentNote creation fails, notes still exist in Description
• UI retrieves from ContentNote first, falls back to Description

EMAIL VALIDATION COMPLIANCE:
═══════════════════════════════════════════════════════════
• CRITICAL: Never send email if hasOptedOut = true (legal requirement)
• Validation checks:
  1. Email exists (PersonEmail/Contact.Email not null)
  2. Email format valid (regex: ^[a-zA-Z0-9._%+-]+@...)
  3. Opt-out status = false
• "Send Email" button disabled if validation fails

MEMOIZATION CACHE INVALIDATION:
═══════════════════════════════════════════════════════════
• MUST set state.performance.dataChanged = true when:
  - Wire adapter refreshes
  - User edits form
  - User saves/cancels
• Failure to invalidate → stale UI (cards won't update)

TIMEOUT CLEANUP:
═══════════════════════════════════════════════════════════
• MUST clear all timeouts in disconnectedCallback()
• Store timeout IDs: this._refreshTimeoutId, this._emailNavigationTimeoutId
• Prevents memory leaks and "cannot read property" errors

PERSON ACCOUNT vs BUSINESS ACCOUNT:
═══════════════════════════════════════════════════════════
• Person Account: Email composer uses AccountId
• Business Account: Email composer uses ContactId
• Component detects via cadenceData.isPersonAccount boolean
• Wrong ID type → email composer fails silently
```

---

## MAINTAINER NOTES

**Last Updated:** October 2025
**Component Version:** 1.0
**Stability:** Production-ready
**Test Coverage:** ~75% (LWC test file exists)

**Known Issues:**
- None critical
- ContentNote indexing delay (1.5s) is expected Salesforce behavior
- window.close() blocked by browser for user-opened tabs (expected)

**Future Enhancements (Not Prioritized):**
- Extract utilities to shared modules (see UTILITY_EXTRACTION_GUIDE.md)
- Migrate ATTEMPT_WAIT_MS to Custom Metadata Type
- Add bulk testing scenarios (200+ cases)
- Implement polling for ContentNote instead of fixed delay

**If You Need to Modify This Component:**
1. Read this diagram first
2. Review UTILITY_EXTRACTION_GUIDE.md
3. Check existing tests
4. Update memoization invalidation if changing data flow
5. Test countdown calculations thoroughly (complex edge cases)
6. Verify sequential lock UX still works

---

## LEGEND

```
Symbols Used in Diagrams:
═══════════════════════════════════════════════════════════

┌─┐ │ ├─┤ └─┘    Box drawing characters (structure)
→  ▼  ←  ▲       Arrows (flow direction)
✓  ✗  ○  ⏺       Status indicators
🕒 📞 ✉️         Emojis (visual markers)

Colors (if viewing with syntax highlighting):
• Green → Success/Completed state
• Yellow → Warning/In-progress state
• Red → Error/Blocked state
• Blue → Information/Neutral state
```
