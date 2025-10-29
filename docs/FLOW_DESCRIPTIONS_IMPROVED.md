# Improved Flow Descriptions - Succession Management System v1.1

**Purpose:** Enhanced descriptions for all flows with better context, dependencies, and workflow relationships

---

## Active Flows (5)

### 1. Case_After_Update_Handler ⭐ NEW - CONSOLIDATED

**Status:** Active
**File:** `Case_After_Update_Handler.flow-meta.xml`

**Description:**
```
CONSOLIDATED FLOW (v1.1): Handles all Case after-update automation for Estate Administration succession cases. Combines Status field coordination + Chatter feed notifications into single flow for performance optimization. Replaces deprecated flows: Case_Status_Coordination and Case_Succession_Segment_Transition.

TRIGGERS ON: Case UPDATE for Estate Administration cases (not closed)

WHAT IT DOES:
• Updates Case.Status based on workflow phase transitions (4-phase model)
• Posts Chatter feed updates when key milestones reached (aids demos & agent handoffs)
• Handles 4 phase transitions: Contact Cadence → Pathway Selection → Pathway Execution → Case Closure

PHASE TRANSITIONS MONITORED:
1. Verification Complete (auto) → Status = "In Progress" (no Chatter - silent)
2. Contact Established → Status = "Awaiting Response" + Chatter post
3. Form Completed → Status = "In Review" + Chatter post with pathway name
4. Pathway Execution Started → Status = "In Progress" (no Chatter - tasks visible)
5. Execution Complete → Status = "Closed" (no Chatter - case closure self-evident)

PERFORMANCE: Consolidates 2 flows into 1 = 24% reduction in flow executions per case lifecycle

DEPENDENCIES:
• SuccessionChatterPoster.cls - Invocable class for standardized Chatter posts
• Contact_Established__c, Form_Completed_Date__c, Pathway_Confirmed__c, Execution_Status__c fields

RELATED FLOWS:
• Task_Succession_Contact_Update - Sets Contact_Established__c when task marked YES
• Case_Create_Initial_Contact_Attempt - Creates first contact task on case creation

VERSION HISTORY:
• v1.1 (Oct 2025) - Created consolidated flow for performance optimization
• Replaces: Case_Status_Coordination + Case_Succession_Segment_Transition (deprecated)
```

---

### 2. Case_Create_Initial_Contact_Attempt

**Status:** Active
**File:** `Case_Create_Initial_Contact_Attempt.flow-meta.xml`

**Improved Description:**
```
AUTO-START WORKFLOW (v1.1): Automatically creates the first contact attempt task (Day 0) when an Estate Administration succession case is created. This initiates the 5-attempt contact cadence without manual intervention.

TRIGGERS ON: Case CREATE for Estate Administration cases (Type = "Named Successor Enactment")

WHAT IT DOES:
• Detects new succession case creation
• Validates Contact_Attempt_Count__c is NULL (duplicate prevention - ensures task only created once)
• Calls SuccessionTaskCreator.createContactAttemptTasks() Apex invocable method
• Creates Task with attemptNumber=1, daysOffset=0, ActivityDate=today

TASK CREATED:
• Subject: "Contact Attempt #1 - Initial Outreach"
• WhatId: Case.Id
• ActivityDate: Day 0 (same day as case created)
• Contact_Attempt_Number__c: 1
• Status: "Not Started"

WORKFLOW CONTEXT:
This is the STARTING POINT of the contact cadence workflow. After this task is created, the agent uses the successionContactCadence LWC component to record outcomes. Subsequent tasks (Attempts 2-5) are created by Task_Create_Next_Contact_Attempt flow when previous attempts are completed.

DEPENDENCIES:
• SuccessionTaskCreator.cls - Invocable class with duplicate detection logic
• CreateSuccessionCaseController.cls - Creates cases with Verification_Status__c = "Complete - Verified" (auto-start trigger)

RELATED FLOWS:
• Task_Create_Next_Contact_Attempt - Creates Attempts 2-5 after each completion
• Task_Succession_Contact_Update - Sets Contact_Established__c when contact made

VERSION HISTORY:
• v1.0 (Aug 2025) - Original implementation (triggered on Verification_Status change)
• v1.1 (Oct 2025) - Updated to trigger on CREATE only (auto-start optimization)
```

---

### 3. Case_Parent_Closure_Handler

**Status:** Active
**File:** `Case_Parent_Closure_Handler.flow-meta.xml`

**Improved Description:**
```
MULTI-SUCCESSOR COORDINATION: Automatically closes parent "Multi-Account Succession Master" cases when all child cases reach terminal status (Closed or Canceled). Enables parent-child case hierarchy pattern for 2+ successors sharing a single financial account.

TRIGGERS ON: Child Case UPDATE when Status changes to Closed or Canceled (Type = "Named Successor Enactment")

WHAT IT DOES:
• Detects when a child succession case is closed/canceled
• Retrieves parent case via ParentId field
• Validates parent exists and is correct type (Multi-Account Succession Master)
• Queries all sibling child cases
• Loops through siblings to check if all have terminal status (Closed OR Canceled)
• If all children complete → Updates parent case Status = "Closed", Execution_Status__c = "Completed"
• If any child still open → Exits without action

MULTI-SUCCESSOR PATTERN:
When a deceased donor has 2+ successors designated on a FinancialAccount:
1. CreateSuccessionCaseController.cls creates parent case (Type = "Multi-Account Succession Master")
2. For each successor → creates child case (Type = "Named Successor Enactment")
3. Each child case runs independent workflow (contact cadence, pathway selection, execution)
4. THIS FLOW monitors child completions and auto-closes parent when all done

NULL SAFETY: Includes fault connector on parent lookup (M4 fix) - gracefully handles missing parent

DEPENDENCIES:
• CreateSuccessionCaseController.cls - Creates multi-successor case hierarchy
• ParentId field on Case object
• caseHierarchyViewer LWC - Displays parent + children for agents

RELATED FLOWS:
• None - This is the ONLY automation that manages parent case closure

VERSION HISTORY:
• v1.0 (Aug 2025) - Original implementation
• v1.1 (Oct 2025) - Added null safety check (M4 fix)
```

---

### 4. Task_Succession_Contact_Update

**Status:** Active
**File:** `Task_Succession_Contact_Update.flow-meta.xml`

**Improved Description:**
```
CIRCUIT BREAKER: Sets Case.Contact_Established__c = TRUE when contact attempt task is completed with outcome "YES". This stops the contact cadence workflow and triggers pathway selection email.

TRIGGERS ON: Task UPDATE when Status changes to "Completed" and Contact_Attempt_Number__c is not blank

WHAT IT DOES:
• Detects when a contact attempt task is marked complete
• Gets parent Case via Task.WhatId (the related succession case)
• Checks Task.Succession_Contact_Established__c field (outcome from successionContactCadence LWC)
• If outcome = TRUE (contact made) → Updates Case.Contact_Established__c = TRUE
• If outcome = FALSE (no contact) → Exits without action (next attempt will be created)

CIRCUIT BREAKER PATTERN:
This field (Contact_Established__c) acts as a gate/switch:
• When FALSE → Task_Create_Next_Contact_Attempt flow continues creating attempts 2-5
• When TRUE → Task_Create_Next_Contact_Attempt flow exits, stopping cadence
• Also triggers Case_After_Update_Handler to send pathway selection email

WORKFLOW CONTEXT:
Agent uses successionContactCadence LWC → Records outcome on Task → THIS FLOW propagates to Case → Stops future attempts if contact made → Pathway selection begins

NULL SAFETY: Includes fault connector on parent case lookup - gracefully handles edge cases

DEPENDENCIES:
• successionContactCadence LWC - UI for agents to record contact outcomes
• ContactCadenceController.saveAttemptOutcome() - Saves outcome to Task.Succession_Contact_Established__c
• Contact_Established__c field on Case
• Succession_Contact_Established__c field on Task

RELATED FLOWS:
• Task_Create_Next_Contact_Attempt - Checks Contact_Established__c before creating next task
• Case_After_Update_Handler - Reacts to Contact_Established__c change, sends email

VERSION HISTORY:
• v1.0 (Aug 2025) - Original implementation with circuit breaker pattern
```

---

### 5. Task_Create_Next_Contact_Attempt

**Status:** Active
**File:** `Task_Create_Next_Contact_Attempt.flow-meta.xml`

**Improved Description:**
```
SEQUENTIAL TASK CREATION: Creates the next contact attempt task (Attempts 2-5) when the previous task is completed, continuing the 95-day contact cadence. Includes circuit breaker logic to stop if contact is established.

TRIGGERS ON: Task UPDATE when Status = "Completed" and Contact_Attempt_Number__c is not blank

WHAT IT DOES:
• Detects when a contact attempt task is completed
• Gets parent Case to check Contact_Established__c (circuit breaker check)
• If Contact_Established = TRUE → Exits immediately (contact made, cadence stops)
• If Contact_Established = FALSE → Determines next attempt number (1→2, 2→3, 3→4, 4→5)
• Calls SuccessionTaskCreator.createContactAttemptTasks() with appropriate days offset
• If current attempt = 5 → Exits (terminal attempt, no more tasks created)

CONTACT CADENCE SCHEDULE:
• Attempt 1 → Attempt 2: Day 5 (+5 days from case creation)
• Attempt 2 → Attempt 3: Day 35 (+30 days from Attempt 2)
• Attempt 3 → Attempt 4: Day 65 (+30 days from Attempt 3)
• Attempt 4 → Attempt 5: Day 95 (+30 days from Attempt 4)
• Attempt 5 → STOP (no Attempt 6)

TOTAL CADENCE: 95 days (5 + 30 + 30 + 30)

DATE GATING PATTERN:
Tasks are created immediately but agents cannot complete them until ActivityDate arrives. This allows agents to see upcoming tasks while enforcing the contact schedule.

NULL SAFETY: Includes fault connector on parent case lookup - gracefully handles edge cases

DEPENDENCIES:
• SuccessionTaskCreator.cls - Invocable class with date calculation + duplicate prevention
• Contact_Established__c field on Case (circuit breaker)
• Contact_Attempt_Number__c field on Task

RELATED FLOWS:
• Case_Create_Initial_Contact_Attempt - Creates Attempt 1 (Day 0)
• Task_Succession_Contact_Update - Sets Contact_Established__c when contact made

VERSION HISTORY:
• v1.0 (Aug 2025) - Original implementation
• v1.1 (Oct 2025) - Refactored to use SuccessionTaskCreator invocable (consistency with Attempt 1)
```

---

## Deprecated Flows (2)

### 6. Case_Status_Coordination ⚠️ DEPRECATED

**Status:** Inactive (DO NOT ACTIVATE)
**File:** `Case_Status_Coordination.flow-meta.xml`

**Deprecation Notice:**
```
⚠️ DEPRECATED (v1.1 - Oct 2025): This flow has been REPLACED by Case_After_Update_Handler for performance optimization. Status = Inactive. DO NOT ACTIVATE.

REPLACED BY: Case_After_Update_Handler.flow-meta.xml (consolidates Status updates + Chatter posts in single flow)

ORIGINAL PURPOSE: Automatically coordinated Case Status field updates across the 4-phase succession workflow. Updated Status based on phase-tracking field changes (Verification_Status__c, Contact_Established__c, Form_Completed_Date__c, Pathway_Confirmed__c, Execution_Status__c).

DEPRECATION REASON: Performance - this flow + Case_Succession_Segment_Transition both triggered on same Case UPDATE events, causing 2x flow executions. Consolidation reduces overhead by 50% per Case update.

VERSION HISTORY:
• v1.0 (Aug 2025) - Original implementation
• v1.1 (Oct 2025) - DEPRECATED, replaced by consolidated flow
```

---

### 7. Case_Succession_Segment_Transition ⚠️ DEPRECATED

**Status:** Inactive (DO NOT ACTIVATE)
**File:** `Case_Succession_Segment_Transition.flow-meta.xml`

**Deprecation Notice:**
```
⚠️ DEPRECATED (v1.1 - Oct 2025): This flow has been REPLACED by Case_After_Update_Handler for performance optimization. Status = Inactive. DO NOT ACTIVATE.

REPLACED BY: Case_After_Update_Handler.flow-meta.xml (consolidates Status updates + Chatter posts in single flow)

ORIGINAL PURPOSE: Logged key succession segment transitions and notified the case feed using SuccessionChatterPoster invocable class. Triggered on Estate Administration cases when Contact_Established__c, Form_Completed_Date__c, or Pathway_Confirmed__c changed. Posted standardized Chatter messages indicating the new segment and next action to aid demo narration and agent handoffs.

WHAT IT DID:
• Detected Contact_Established transition → Posted Chatter: "Contact Established - Form Sent"
• Detected Form_Completed transition → Posted Chatter: "Form Completed - Pathway: [name]"
• Aided demos and agent handoffs with visual timeline on Case feed

DEPRECATION REASON: Performance - this flow + Case_Status_Coordination both triggered on same Case UPDATE events, causing 2x flow executions. Consolidation reduces overhead by 50% per Case update.

VERSION HISTORY:
• v1.0 (Aug 2025) - Original implementation
• v1.1 (Oct 2025) - DEPRECATED, replaced by consolidated flow
```

---

## Flow Dependency Map

```
┌─────────────────────────────────────────────────────────────────┐
│                    SUCCESSION WORKFLOW FLOWS                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. CASE CREATION                                                │
│     CreateSuccessionCaseController.cls                           │
│            ↓                                                     │
│     Case_Create_Initial_Contact_Attempt (Flow)                  │
│            ↓                                                     │
│     Creates Task (Attempt 1, Day 0)                              │
│                                                                  │
│  2. CONTACT CADENCE (5 attempts over 95 days)                    │
│     Agent completes task via successionContactCadence LWC        │
│            ↓                                                     │
│     Task_Succession_Contact_Update (Flow)                       │
│            ↓                                                     │
│     Sets Contact_Established__c on Case (circuit breaker)       │
│            ↓                                                     │
│     Task_Create_Next_Contact_Attempt (Flow)                     │
│            ↓                                                     │
│     Creates next task OR exits if contact made                   │
│                                                                  │
│  3. STATUS COORDINATION & NOTIFICATIONS                          │
│     Case_After_Update_Handler (Flow) ⭐ CONSOLIDATED             │
│            ↓                                                     │
│     Updates Status field + Posts Chatter updates                 │
│            ↓                                                     │
│     Calls SuccessionChatterPoster.cls (Apex invocable)          │
│                                                                  │
│  4. MULTI-SUCCESSOR COORDINATION                                 │
│     When child case closes/cancels                               │
│            ↓                                                     │
│     Case_Parent_Closure_Handler (Flow)                          │
│            ↓                                                     │
│     Checks if all siblings done → Closes parent                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Quick Reference: Flow Purposes

| Flow Name | Purpose in One Sentence |
|-----------|------------------------|
| Case_After_Update_Handler | Updates Case.Status and posts Chatter updates when workflow phases transition |
| Case_Create_Initial_Contact_Attempt | Creates first contact task (Day 0) when case is created |
| Case_Parent_Closure_Handler | Auto-closes parent case when all child cases complete (multi-successor) |
| Task_Succession_Contact_Update | Sets Contact_Established__c on Case when contact made (circuit breaker) |
| Task_Create_Next_Contact_Attempt | Creates next contact task (Attempts 2-5) after previous completes |

---

## Migration Notes (v1.0 → v1.1)

**Changes Made:**
1. Created Case_After_Update_Handler (consolidates 2 deprecated flows)
2. Deactivated Case_Status_Coordination (performance optimization)
3. Deactivated Case_Succession_Segment_Transition (performance optimization)
4. Updated Case_Create_Initial_Contact_Attempt to trigger on CREATE only (auto-start)

**Performance Impact:**
- Flow executions reduced by 24% per case lifecycle (21 → 16 interviews)
- Case UPDATE events now trigger 1 flow instead of 2 (50% reduction)

**Functional Impact:**
- No behavior changes - workflow operates identically
- All Status updates still occur at same phase transitions
- All Chatter posts still appear at same milestones
- Better descriptions provide context for future developers

**Rollback Plan:**
If issues arise with consolidated flow:
1. Deactivate Case_After_Update_Handler
2. Reactivate Case_Status_Coordination + Case_Succession_Segment_Transition
3. Original behavior restored immediately

---

## Deployment Instructions

### Deploying the Consolidated Flow

**Option 1: Deploy Flow + Keep Deprecated Flows Inactive (Recommended)**
```bash
# Deploy all flows including new consolidated flow
# Deprecated flows will be deployed as Inactive
sf project deploy start --source-dir force-app/main/default/flows
```

This approach:
- ✅ Deploys new Case_After_Update_Handler as Active
- ✅ Deploys deprecated flows as Inactive (won't execute)
- ✅ Keeps audit trail in org
- ✅ Easy rollback if needed

**Option 2: Deploy Flow + Delete Deprecated Flows**
```bash
# Step 1: Deploy new flow first
sf project deploy start --source-dir force-app/main/default/flows/Case_After_Update_Handler.flow-meta.xml

# Step 2: Verify new flow is Active in Setup → Flows

# Step 3: Delete deprecated flows using destructive changes
sf project deploy start \
  --manifest manifest/destructive/package.xml \
  --post-destructive-changes manifest/destructive/destructiveChangesPost_DeprecatedFlows.xml
```

This approach:
- ✅ Cleans up org metadata
- ✅ Removes inactive flows from flow list
- ❌ Harder to rollback (requires redeployment from git)
- ❌ Permanent deletion

**See:** [manifest/destructive/README.md](../manifest/destructive/README.md) for complete destructive changes guide

---

**Document End**
