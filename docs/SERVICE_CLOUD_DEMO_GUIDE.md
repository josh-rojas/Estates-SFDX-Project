# Service Cloud Demo Guide - Succession Management System

**Last Updated:** 2025-10-14
**Purpose:** Comprehensive guide for demonstrating Service Cloud features in the Succession Management demo

---

## 🎯 Overview

This demo showcases **Service Cloud features** integrated with the Succession Management workflow:
- ✅ **SLA Management** - Entitlement processes with milestone tracking
- ✅ **Queue-Based Routing** - Multi-queue case distribution
- ✅ **Omni-Channel** - Intelligent work routing and agent presence
- ✅ **Service Console** - Unified agent workspace

---

## 📊 Feature 1: SLA Management & Milestone Tracking

### **Configuration**

**Entitlement Process:** `Estate Succession SLA` (force-app/main/default/entitlementProcesses/Estate_Succession_SLA.entitlementProcess-meta.xml:1)
- **Status:** ✅ Active
- **Applies To:** All Estate Administration cases
- **Entry Point:** Case CreatedDate
- **Exit Criteria:** Case Status = Closed OR Canceled

### **Milestone Definitions**

| # | Milestone Name | Trigger Field | Target | Business Context |
|---|---------------|---------------|--------|-----------------|
| 1 | **Verification Complete** | `Verification_Status__c = "Complete - Verified"` | 24 hours | Agent must verify successor identity and documentation |
| 2 | **Initial Contact Established** | `Contact_Established__c = true` | 8 hours | Agent must successfully reach successor by phone (informational call) |
| 3 | **Succession Form Sent** | `Form_Sent_Date__c` populated | 24 hours | System sends email with public form link after contact established |
| 4 | **Documentation Complete** | `Form_Completed_Date__c` populated | 30 days | Successor completes online pathway selection form |
| 5 | **Final Resolution** | `Status = "Closed"` | 60 days | Case fully resolved (funds transferred per pathway) |

### **Demo Talking Points**

**SLA Value Proposition:**
> "Schwab Charitable manages thousands of succession cases annually. Service Cloud SLAs ensure we maintain our commitment to donor families during difficult times. Each milestone has specific time targets aligned with our service standards."

**Milestone #1 (24hr Verification):**
> "When a deceased donor notification arrives, our verification SLA ensures the agent completes identity verification within 24 hours. This protects against fraud while maintaining empathy for the bereaved."

**Milestone #2 (8hr Initial Contact):**
> "After verification, agents have 8 hours to establish contact with the successor. This initial call is informational only—we notify them of their designation, express condolences, and explain the three pathway options: Disclaim, New DAF, or Final Grant."

**Milestone #3 (24hr Form Sent):**
> "Once contact is established, the system automatically sends an email with a secure link to our online succession form. This milestone ensures the email is sent within 24 hours of successful phone contact."

**Milestone #4 (30-day Documentation):**
> "Successors have 30 days to complete the online form and select their pathway. Our contact cadence system tracks 5 scheduled follow-up attempts (Day 0, 5, 35, 65, 95) to ensure they don't miss this deadline."

**Milestone #5 (60-day Resolution):**
> "From case creation to final closure, our SLA target is 60 days. This includes pathway execution—whether that's transferring funds to a new DAF, issuing a final grant check, or processing a disclaimer."

### **Demo Steps**

1. **Navigate to Estate Administration Case**
   - Show case record with "Estate Succession SLA" entitlement visible
   - Point out the **Milestones** related list

2. **Open Milestones Component**
   - Click on Milestones tab
   - Show real-time countdown timers for active milestones
   - Highlight color coding: Green (on track), Yellow (at risk), Red (violated)

3. **Simulate Milestone Completion**
   - Click "✅ Begin Succession Processing" Quick Action
   - Show `Verification_Status__c` changing to "Complete - Verified"
   - **Result:** Milestone #1 completes, timer stops

4. **Show Milestone Violation Scenario**
   - Filter to "SLA Critical - Escalate" list view
   - Show cases with red violation indicators
   - Explain escalation workflow: "Cases in this view require manager intervention"

---

## 📮 Feature 2: Queue-Based Case Routing

### **Configuration**

**4 Queues Configured:**

| Queue Name | Developer Name | Purpose | Objects Supported |
|-----------|----------------|---------|-------------------|
| **Estate** | Estate | Legacy queue for general estate cases | Case |
| **Estate Cases** | Estate_Cases | Primary queue for succession workflow | Case |
| **Estates Chat** | Estates_Chat | Live chat escalations from web visitors | LiveChatTranscript |
| **Service Case** | Service_Case | General service requests | Case |

**Queue Members (5 agents):**
- Frank Mendez (frank.mendez.charfsc@schwab.com.fscjosh)
- Caley Kurchinski (caley.kurchinski.charfsc@schwab.com.fscjosh)
- Christian Besmer (christian.besmer.charfsc@schwab.com.fscjosh)
- Josh Rojas (josh.rojas.charfsc@schwab.com.fscjosh)
- Josh Rojas (schwab_sandbox@chrysostom.io)

### **Demo Talking Points**

**Queue Routing Value:**
> "Service Cloud queues enable load balancing across our Estates team. When high-value succession cases arrive, they're automatically routed to the 'Estate Cases' queue where our most experienced agents can claim them."

**Multi-Channel Queuing:**
> "Notice we have separate queues for different channels—cases, chat transcripts. This allows us to staff appropriately based on channel demand. For example, during tax season, we might allocate more agents to the chat queue for immediate donor assistance."

**Specialized Routing:**
> "The 'Estate Cases' queue specifically handles our Named Successor Enactment cases—these require specialized training because agents must navigate sensitive conversations with grieving families."

### **Demo Steps**

1. **Navigate to Estate Cases List View**
   - App Launcher → Estate Cases
   - Show queue column with "Estate Cases" displayed
   - Filter by "My Queue Items" vs "All Queue Items"

2. **Demonstrate Case Claiming**
   - Click on unassigned case
   - Click "Accept" or "Change Owner"
   - Show case moving from queue to agent's "My Cases"

3. **Show Queue Performance Metrics**
   - Navigate to Reports & Dashboards → Service Cloud Dashboards
   - Show queue backlog chart (cases awaiting assignment)
   - Show average time in queue metric

---

## 🎧 Feature 3: Omni-Channel & Agent Presence

### **Configuration**

**Service Channel:** `Estate_Case_Channel` (force-app/main/default/serviceChannels/Estate_Case_Channel.serviceChannel-meta.xml:1)
- **Related Entity:** Case
- **Routing Priority:** Uses `Priority` field for secondary routing
- **Widget Behavior:** Does not minimize on accept (agent sees full case immediately)

**Queue Routing Config:** `Estate_Cases_Routing` (force-app/main/default/queueRoutingConfigs/Estate_Cases_Routing.queueRoutingConfig-meta.xml:1)
- **Routing Model:** Most Available (cases route to agent with most available capacity)
- **Capacity Weight:** 1 (each case consumes 1 capacity unit)
- **Capacity Percentage:** 100% (uses full agent capacity)
- **Push Timeout:** 0 (no automatic rejection if agent doesn't respond)

**Presence User Config:** `Estates_Agent_Presence` (force-app/main/default/presenceUserConfigs/Estates_Agent_Presence.presenceUserConfig-meta.xml:1)
- **Capacity:** 3 (agents can handle up to 3 concurrent cases)
- **Interruption Level:** 3 (allows interruptions for high-priority cases)
- **Assigned To:** Standard User profile + Succession_Management_Access permission set

### **Demo Talking Points**

**Omni-Channel Value:**
> "Omni-Channel transforms how our agents work. Instead of manually searching queues, Service Cloud intelligently pushes the right case to the right agent based on availability, skills, and workload. This increases efficiency and reduces burnout."

**Capacity-Based Routing:**
> "Each agent has a capacity of 3 cases. The system tracks their current workload—if they're handling 2 cases and a new high-priority succession comes in, they'll receive it. But if they're already at capacity (3 cases), the next available agent gets it."

**Most Available Algorithm:**
> "Our routing uses the 'Most Available' model. If Agent A has 1 case and Agent B has 2, the next case routes to Agent A. This ensures even distribution and prevents any single agent from becoming overwhelmed."

**Real-Time Presence:**
> "Agents control their presence status—Available, Busy, On Break, In Training. When they go to lunch, they set status to 'On Break' and stop receiving cases. When they return, they switch back to 'Available' and cases flow in."

### **Demo Steps**

1. **Open Omni-Channel Widget (Service Console)**
   - Log in as agent user
   - Service Console shows Omni-Channel widget at bottom of screen
   - Show presence status dropdown: Available, Busy, Away, Offline

2. **Set Status to Available**
   - Click status dropdown → Select "Available"
   - Widget shows: "Ready to receive work" with capacity indicator (0/3)

3. **Simulate Incoming Case**
   - Create new Estate Administration case assigned to "Estate Cases" queue
   - **Result:** Omni-Channel widget lights up with incoming work alert
   - Show case details in preview panel
   - Agent clicks "Accept" → Case opens in new tab
   - Capacity updates: (1/3)

4. **Show Multi-Case Handling**
   - Repeat step 3 to accept second case
   - Capacity updates: (2/3)
   - Show agent toggling between case tabs in Service Console
   - Demonstrate how agent can see all open cases at once

5. **Demonstrate Workload Protection**
   - Accept third case → Capacity at max (3/3)
   - Create fourth case in queue
   - **Result:** Current agent does NOT receive fourth case (at capacity)
   - Switch to second agent's screen → They receive the fourth case

---

## 🖥️ Feature 4: Service Console Workspace

### **Configuration**

**App:** Succession Management (Lightning Console App)
- **Utility Bar:** Includes Omni-Channel widget, Notes, History
- **Navigation:** Cases, Accounts, Contacts, Reports, Dashboards
- **Record Pages:** Optimized for multi-tab navigation

### **Demo Talking Points**

**Console Value:**
> "The Service Console provides agents with everything they need in one unified workspace. They can handle multiple cases simultaneously using tabs, access customer history instantly, and take notes without leaving the screen."

**Omni Presence Inbox:**
> "The Omni Presence inbox (Omni-Channel widget) sits in the utility bar—always visible regardless of which tab the agent is on. This ensures they never miss an incoming case, even if they're deep in research on another account."

**Contextual Productivity:**
> "Notice how the console layout surfaces the most critical information at the top—case status, SLA countdown, succession pathway. Agents can complete 90% of their work without scrolling."

### **Demo Steps**

1. **Open Service Console**
   - App Launcher → "Succession Management" app
   - Show utility bar at bottom (Omni-Channel, Notes, History)

2. **Multi-Tab Navigation**
   - Open Estate Administration case → Opens in Tab 1
   - Click on Account name → Opens in subtab under Tab 1
   - Click on Contact → Opens in new subtab
   - Show breadcrumb navigation at top of screen

3. **Omni Presence Inbox Demo**
   - Collapse Omni-Channel widget → Still shows notification badge
   - Accept incoming case → Opens in new primary tab
   - Show agent switching between tabs without losing context

4. **Integrated Productivity Tools**
   - Open Notes utility → Take case notes visible across all tabs
   - Open History utility → Show recent case activity feed

---

## 🎬 Full Demo Flow (15-minute presentation)

### **Act 1: Case Arrives (0-3 minutes)**
1. Show incoming case in "Estate Cases" queue (unassigned)
2. Agent sets Omni-Channel status to "Available"
3. Case routes to agent via Omni-Channel push notification
4. Agent accepts case → Opens in Service Console

### **Act 2: SLA Tracking (3-7 minutes)**
5. Show Milestones component with 5 milestones, all pending
6. Agent clicks "✅ Begin Succession Processing" Quick Action
7. Milestone #1 (Verification Complete) → Completes in real-time
8. Show green checkmark and completion timestamp
9. Navigate to "SLA At Risk" list view → Show other cases with yellow warnings
10. Navigate to "SLA Critical - Escalate" list view → Show red violations

### **Act 3: Contact Cadence Workflow (7-12 minutes)**
11. Agent uses `successionContactCadence` LWC component
12. Record Attempt #1 outcome: "Contact Established = YES"
13. Milestone #2 (Initial Contact Established) → Completes
14. System automatically sends email with form link
15. Milestone #3 (Succession Form Sent) → Completes

### **Act 4: Multi-Case Handling (12-15 minutes)**
16. Agent accepts second case from queue (capacity: 2/3)
17. Show agent toggling between case tabs in console
18. Agent completes outcome on first case → Capacity drops to (1/3)
19. Agent sets status to "On Break" → Stops receiving new cases
20. Wrap up: "This is how Service Cloud enables Schwab Charitable to handle high-volume succession cases with empathy and efficiency."

---

## 📋 Pre-Demo Checklist

**24 Hours Before Demo:**
- [ ] Deploy Service Cloud metadata: `sf project deploy start --manifest manifest/package-service-cloud-features.xml`
- [ ] Verify Estate Succession SLA is active in Setup → Entitlement Processes
- [ ] Create test entitlements for demo accounts (Setup → Entitlements → New)
- [ ] Assign queue members to all 4 queues (Setup → Queues)
- [ ] Enable Omni-Channel in Setup → Feature Settings → Service → Omni-Channel
- [ ] Assign Omni-Channel presence to demo user (Setup → Presence Configurations)

**1 Hour Before Demo:**
- [ ] Load test data: `cci task run load_demo_ui_showcase`
- [ ] Verify at least 3 unassigned cases in "Estate Cases" queue
- [ ] Verify SLA milestones are calculating correctly (check existing case)
- [ ] Log in as demo agent user in Service Console
- [ ] Open Omni-Channel widget, verify presence statuses appear
- [ ] Set status to "Offline" until demo begins

**During Demo:**
- [ ] Keep Service Console open in Tab 1
- [ ] Keep Setup → Entitlement Processes open in Tab 2 (for showing config)
- [ ] Keep Reports → Queue Metrics dashboard open in Tab 3

---

## 🔧 Troubleshooting

**Issue:** Omni-Channel widget not appearing
- **Fix:** Setup → Feature Settings → Service → Enable Omni-Channel
- **Fix:** Setup → Presence Configurations → Assign user to Estates Agent Presence config

**Issue:** Milestones not completing when criteria met
- **Fix:** Verify entitlement record exists on case (Case → Entitlements related list)
- **Fix:** Verify Estate Succession SLA entitlement process is active

**Issue:** Cases not routing via Omni-Channel
- **Fix:** Verify Service Channel is assigned to queue (Setup → Queues → Edit → Service Channels)
- **Fix:** Verify agent status is "Available" (not Busy/Away/Offline)
- **Fix:** Verify agent capacity not at maximum (check Omni-Channel widget)

**Issue:** Queue not showing in list view
- **Fix:** Verify queue members include demo user (Setup → Queues → Estate Cases → Members)
- **Fix:** Verify Case record type is "Estate Administration"

---

## 📚 Additional Resources

- **Salesforce Help:** [Service Cloud Basics](https://help.salesforce.com/s/articleView?id=sf.service_cloud_basics.htm)
- **Trailhead Module:** [Omni-Channel Routing](https://trailhead.salesforce.com/en/content/learn/modules/omni-channel-routing)
- **Trailhead Project:** [Set Up Entitlement Management](https://trailhead.salesforce.com/en/content/learn/projects/set-up-entitlement-management)
- **Admin Guide:** [Service Console Customization](https://help.salesforce.com/s/articleView?id=sf.console_lex_customize.htm)

---

## 📝 Demo Script Notes

**Opening Statement:**
> "Today I'll show you how Schwab Charitable leverages Service Cloud to manage thousands of deceased donor succession cases with empathy, efficiency, and compliance. We'll see SLA tracking, intelligent queue routing, Omni-Channel work distribution, and the unified agent console."

**Closing Statement:**
> "As you've seen, Service Cloud transforms succession case management from a manual, error-prone process into an intelligent, automated workflow. SLAs ensure we meet our service commitments, queues balance workload, and Omni-Channel ensures the right agent gets the right case at the right time. This system allows our small team to handle high volumes without sacrificing the personal touch that donor families deserve."

---

**Document Owner:** Josh Rojas (josh.rojas.charfsc@schwab.com.fscjosh)
**Demo Environment:** schwab-sandbox
**Last Reviewed:** 2025-10-14
