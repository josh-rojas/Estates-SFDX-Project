# 03 - Admin Runbook

**Last updated: October 15, 2025**

Complete administrative guide for Service Cloud setup, Email-to-Case configuration, and demo preparation.

---

## Related Diagrams

- Succession Phases (Mermaid): `diagrams/images/mermaid/succession-phases.png`
- Contact Cadence – Unlock Sequence (Mermaid): `diagrams/images/mermaid/contact-cadence-sequence.png`
- Status Coordination – State Machine (PlantUML): `diagrams/images/plantuml/status-coordination-state.png`
- Multi-Successor Case Hierarchy (PlantUML): `diagrams/images/plantuml/multi-successor-object.png`

![Succession Phases](diagrams/images/mermaid/succession-phases.png)
![Contact Cadence – Unlock Sequence](diagrams/images/mermaid/contact-cadence-sequence.png)
![Status Coordination – State Machine](diagrams/images/plantuml/status-coordination-state.png)
![Multi-Successor Case Hierarchy](diagrams/images/plantuml/multi-successor-object.png)

---

## Service Cloud Configuration

### SLA Management & Milestone Tracking

**Entitlement Process:** `Estate Succession SLA`

- **Status:** Active
- **Applies To:** All Estate Administration cases
- **Entry Point:** Case CreatedDate
- **Exit Criteria:** Case Status = Closed OR Canceled

**Milestone Definitions:**

| #   | Milestone Name                  | Trigger Field                                    | Target   | Business Context                                                      |
| --- | ------------------------------- | ------------------------------------------------ | -------- | --------------------------------------------------------------------- |
| 1   | **Verification Complete**       | `Verification_Status__c = "Complete - Verified"` | 24 hours | Agent must verify successor identity and documentation                |
| 2   | **Initial Contact Established** | `Contact_Established__c = true`                  | 8 hours  | Agent must successfully reach successor by phone                      |
| 3   | **Succession Form Sent**        | `Form_Sent_Date__c` populated                    | 24 hours | System sends email with public form link after contact established    |
| 4   | **Documentation Complete**      | `Form_Completed_Date__c` populated               | 30 days  | Successor completes online pathway selection form                     |
| 5   | **Final Resolution**            | `Status = "Closed"`                              | 60 days  | Case fully resolved (funds transferred per pathway)                   |

**Demo Talking Points:**

> "Schwab Charitable manages thousands of succession cases annually. Service Cloud SLAs ensure we maintain our commitment to donor families during difficult times."

**Demo Steps:**

1. Navigate to Estate Administration Case → Show Milestones related list
2. Open Milestones tab → Show real-time countdown timers
3. Highlight color coding: Green (on track), Yellow (at risk), Red (violated)
4. Click "✅ Begin Succession Processing" Quick Action
5. Show Verification Complete milestone completing in real-time

---

### Queue-Based Case Routing

**4 Queues Configured:**

| Queue Name       | Developer Name | Purpose                                 |
| ---------------- | -------------- | --------------------------------------- |
| **Estate**       | Estate         | Legacy queue for general estate cases   |
| **Estate Cases** | Estate_Cases   | Primary queue for succession workflow   |
| **Estates Chat** | Estates_Chat   | Live chat escalations from web visitors |
| **Service Case** | Service_Case   | General service requests                |

**Queue Members:** Frank Mendez, Caley Kurchinski, Christian Besmer, Josh Rojas (2 accounts)

**Demo Steps:**

1. Navigate to Estate Cases List View → Show queue column
2. Filter by "My Queue Items" vs "All Queue Items"
3. Click on unassigned case → Click "Accept" or "Change Owner"
4. Show case moving from queue to agent's "My Cases"

---

### Omni-Channel & Agent Presence

**Service Channel:** `Estate_Case_Channel`

- **Related Entity:** Case
- **Routing Priority:** Uses `Priority` field
- **Widget Behavior:** Does not minimize on accept

**Queue Routing Config:** `Estate_Cases_Routing`

- **Routing Model:** Most Available
- **Capacity Weight:** 1 (each case consumes 1 capacity unit)
- **Capacity Percentage:** 100%
- **Push Timeout:** 0 (no automatic rejection)

**Presence User Config:** `Estates_Agent_Presence`

- **Capacity:** 3 (agents can handle 3 concurrent cases)
- **Interruption Level:** 3 (allows interruptions for high-priority)
- **Assigned To:** Standard User profile + Succession_Management_Access permission set

**Demo Steps:**

1. Open Service Console → Show Omni-Channel widget at bottom
2. Set status to "Available" → Widget shows "Ready to receive work" (0/3)
3. Create new Estate Administration case in queue → Omni-Channel lights up
4. Agent accepts → Case opens in new tab, capacity updates (1/3)
5. Demonstrate workload protection by accepting 3 cases (3/3 capacity)

---

### Service Console Workspace

**App:** Succession Management (Lightning Console App)

- **Utility Bar:** Omni-Channel widget, Notes, History
- **Navigation:** Cases, Accounts, Contacts, Reports, Dashboards
- **Record Pages:** Optimized for multi-tab navigation

**Demo Steps:**

1. App Launcher → "Succession Management" app
2. Show utility bar at bottom with Omni-Channel, Notes, History
3. Open case → Opens in Tab 1
4. Click Account name → Opens in subtab under Tab 1
5. Show breadcrumb navigation at top

---

## Email-to-Case Setup

### Configuration Steps

**Step 1: Enable Email-to-Case**

1. Setup → Feature Settings → Service → Email-to-Case
2. Click **Edit**
3. Check ☑ **Enable Email-to-Case**
4. Check ☑ **Enable On-Demand Service** (immediate processing)
5. Click **Save**

**Step 2: Create Routing Address**

1. Setup → Email-to-Case → Routing Addresses → New
2. Configure:
   - **Routing Name:** Estate Succession Cases
   - **Email Address:** `estates@schwabcharitable.org`
   - **Save Email To:** Case
   - **Case Origin:** Email
   - **Case Priority:** Medium
   - **Case Record Type:** Estate Administration
   - **Route to Queue:** ☑ Estate Cases queue
   - **Route to User:** ☐ Unchecked
3. Click **Save**

**Step 3: Email Response Settings**

1. Setup → Email-to-Case → Settings
2. Configure:
   - **Email Thread:** ☑ Enabled
   - **Automated Case User:** Automated Process
   - **Notify Case Owners:** ☑ Checked
   - **HTML Email:** ☑ Accept
   - **Unauthorized Sender:** Create new case
3. Click **Save**

**Step 4: Link Service Channel to Queue**

1. Setup → Queues → Estate Cases
2. Supported Channels section → Add Service Channels
3. Select: ☑ Estate Case Channel, ☑ Estate Email Channel
4. Click **Save**

**Step 5: Enable Omni-Channel**

1. Setup → Omni-Channel Settings
2. Check ☑ **Enable Omni-Channel**
3. Click **Save**

**Step 6: Assign Presence Configuration**

1. Setup → Presence Configurations → New
2. Configure:
   - **Configuration Name:** Estates Agent Presence
   - **Developer Name:** Estates_Agent_Presence
   - **Capacity:** 5
   - **Agent Work Interruptions:** Critical interruptions only
3. Click **Save** → Assigned Users → Add team members

---

### Email-to-Case Workflow

**Example Email:**

```
From: advisor@schwab.com
Subject: Deceased Donor - Account #12345 (John Doe)

Dear Estates Team,

Please be advised that account holder John Doe (Account #12345)
passed away on October 1, 2025. Death certificate attached.

Designated successor: Amanda Doe (daughter)
Contact: amanda.doe@email.com | (555) 123-4567

Best regards,
Financial Advisor Name
```

**System Actions:**

1. Email-to-Case creates new Case:
   - Record Type: Estate Administration
   - Type: Named Successor Enactment
   - Origin: Email
   - Queue: Estate Cases
   - Description: Email body content
2. Omni-Channel detects unassigned case
3. Routes to most available agent (Agent A: 2/5 capacity)
4. Agent receives push notification in Service Console
5. Agent accepts → Case opens with email body + attachments

---

## Demo Preparation

### 24 Hours Before Demo

**Critical Setup:**

- [ ] Deploy Service Cloud metadata: `sf project deploy start --manifest manifest/package-service-cloud-features.xml`
- [ ] Verify Estate Succession SLA is active (Setup → Entitlement Processes)
- [ ] Create test entitlements for demo accounts (Setup → Entitlements → New)
- [ ] Assign queue members to all 4 queues (Setup → Queues)
- [ ] Enable Omni-Channel (Setup → Feature Settings → Service → Omni-Channel)
- [ ] Assign Omni-Channel presence to demo user (Setup → Presence Configurations)

**Email Configuration:**

- [ ] Setup → Email Administration → Deliverability → Set to "All Email"
- [ ] Add all demo email addresses to verified email list:
   - Your email
   - PM/stakeholder emails
   - Test data email addresses

**Email Template Access:**

- [ ] Setup → Email Templates → Verify `Succession_Management` folder exists
- [ ] Verify all 5 templates exist:
   - Day 0 - Initial Contact
   - Day 5 - First Follow-Up
   - Day 35 - Second Contact
   - Day 65 - Third Contact
   - Day 95 - Final Contact
- [ ] Setup → Email Templates → Succession_Management → Folder Sharing
- [ ] Add demo user profile/public group to folder access
- [ ] Test: Log in as demo user → Open email composer → All 5 templates visible

**Test Data:**

```bash
# Load demo data
cci task run load_demo_ui_showcase

# Validate Person Accounts have valid emails
sf data query --query "SELECT Id, Name, PersonEmail FROM Account WHERE IsPersonAccount = true AND PersonEmail = null" --target-org schwab-sandbox

# Fix any NULL/invalid emails
sf data update record --sobject Account --record-id <ID> --values "PersonEmail=test@schwabcharitable.org" --target-org schwab-sandbox
```

**Email Format Requirements:**
- Must have format: `name@domain.tld`
- No typos: `test@@example.com`, `test.example.com` (missing @)
- Use faker.email() in Snowfakery recipes

---

### 1 Hour Before Demo

**Environment Setup:**

- [ ] Load test data: `cci task run load_demo_ui_showcase`
- [ ] Verify at least 3 unassigned cases in "Estate Cases" queue
- [ ] Verify SLA milestones are calculating correctly
- [ ] Log in as demo agent user in Service Console
- [ ] Open Omni-Channel widget, verify presence statuses appear
- [ ] Set status to "Offline" until demo begins

**Keep Open:**

- [ ] Service Console in Tab 1
- [ ] Setup → Entitlement Processes in Tab 2
- [ ] Reports → Queue Metrics dashboard in Tab 3

**Demo Cases:**

**Case 1: Happy Path**
- Person Account with valid email
- No opt-out flag
- Workflow: Record Outcome (YES) → Email sends → Show pathway form

**Case 2: Multiple Attempts**
- Person Account with valid email
- Record Outcome (NO) → Email prompt → Click "Send Email" → Composer opens

**Case 3: Edge Case**
- Person Account with `HasOptedOutOfEmail = true` OR NULL email
- Show email warning alert
- Show "Send Email" button disabled

**Multi-Successor Case (Optional):**
- Parent case with 2+ child cases
- Show `caseHierarchyViewer` component
- Each child has independent contact cadence

---

### Day-of-Demo Checklist

**30 Minutes Before:**

- [ ] Sandbox email deliverability verified (test email sent and received)
- [ ] All 5 email templates accessible to demo user
- [ ] Demo user has both permission sets assigned
- [ ] 3 demo cases prepared
- [ ] Browser configured (modern browser, pop-ups allowed)
- [ ] Test data email addresses valid
- [ ] Component loads correctly on demo case
- [ ] "Send Email" button opens composer
- [ ] Email templates visible in composer dropdown

**Component Pre-Flight Check:**

1. Open demo case in Lightning
2. Verify `successionContactCadence` component displays
3. Check progress bar renders correctly
4. Verify all 5 attempt cards visible
5. Test button interactions:
   - Click "Record Outcome" → Inline form appears
   - Select YES/NO radio → No errors
   - Enter notes → No errors
   - Click "Save Outcome" → Success toast
   - If NO selected → Email prompt appears
   - Click "Send Email" → Composer opens
   - Close composer → Email prompt STILL visible
   - Click "Skip" → Email prompt disappears

---

## Troubleshooting

### Omni-Channel widget not appearing

- **Fix:** Setup → Feature Settings → Service → Enable Omni-Channel
- **Fix:** Setup → Presence Configurations → Assign user to Estates Agent Presence

### Milestones not completing

- **Fix:** Verify entitlement record exists (Case → Entitlements related list)
- **Fix:** Verify Estate Succession SLA is active

### Cases not routing via Omni-Channel

- **Fix:** Verify Service Channel assigned to queue (Setup → Queues → Edit)
- **Fix:** Verify agent status is "Available" (not Busy/Away/Offline)
- **Fix:** Verify agent capacity not at maximum

### Email Composer Opens But No Templates

- **Cause:** Demo user doesn't have folder access
- **Fix:** Setup → Email Templates → Succession_Management → Folder Sharing → Add user

### Email Composer Opens But TO Field Empty

- **Cause:** PersonEmail or Contact.Email is NULL
- **Fix:** Query Account/Contact → Update email address:

```bash
sf data update record --sobject Account --record-id <ID> --values "PersonEmail=test@schwabcharitable.org"
```

### "Email Issue: Successor has opted out"

- **Cause:** `HasOptedOutOfEmail = true`
- **Fix (if unintended):**

```bash
sf data update record --sobject Account --record-id <ID> --values "HasOptedOutOfEmail=false"
```

- **OR demonstrate as feature:** Show how system prevents opt-out violations

### Component Shows "Invalid Record Type"

- **Cause:** Case RecordType not `EstateAdministration` or Type not correct
- **Fix:** Verify:

```bash
sf data query --query "SELECT Id, RecordType.DeveloperName, Type FROM Case WHERE Id = '<CASE_ID>'"
```

---

## Permissions Philosophy

### Demo-First Approach

This project is **explicitly configured for demonstration purposes** with maximum permissiveness:

- ✅ **No restrictive permissions** that block demo scenarios
- ✅ **Full edit access** to all fields (except calculated)
- ✅ **No field-level restrictions** requiring workarounds
- ✅ **Permissive object access** for all internal users

**Zero Validation Rules:**

- ❌ No required fields (beyond Salesforce defaults)
- ❌ No format validations
- ❌ No business logic constraints

**Rationale:** Demo scenarios require rapid data manipulation, edge case testing, and quick "undo" actions. Restrictive permissions slow demonstrations.

### Permission Set Strategy

**Succession_Management_Access (Internal Users):**
- Target: Estates team, case workers, agents
- Permissions: Account (Deceased__c, Date_of_Death__c), Case (16 fields), Task (2 fields)
- Object Access: Case (Create/Read/Edit), Task (Create/Read/Edit/Delete)
- Apex: All 4 controllers enabled (CaseHierarchy, ContactCadence, SuccessionPublicForm, SuccessionTaskGenerator)

**Succession_Field_Access (Extended Access):**
- Target: QA testers, admins, data migration users
- Permissions: All from Management Access + Event fields

**Succession_Guest_Access (Public Form):**
- Target: Guest users accessing public form
- Permissions: Case (Read + Limited Edit), Account/Contact/FinancialAccount (Read)

---

## Production Readiness

**⚠️ If deploying to production, you MUST:**

1. **Add Validation Rules:**
   - Required field validations
   - Format validations (email, phone, SSN)
   - Business logic constraints
   - Cross-object validation rules

2. **Restrict Permissions:**
   - Limit edit access to sensitive fields
   - Add read-only permissions where appropriate
   - Implement profile-based access controls
   - Add View All Records / Modify All Records restrictions

3. **Enhance Guest User Security:**
   - Implement tokenized URLs (encrypted parameters)
   - Add rate limiting (5 submissions per IP per hour)
   - Add CAPTCHA for bot protection
   - Implement token expiration (90 days)
   - Add IP address validation

4. **Add Audit Trails:**
   - Enable Field History Tracking on critical fields
   - Create custom audit logging for guest submissions
   - Implement security event monitoring

5. **Add Approval Processes:**
   - Multi-step approvals for pathway changes
   - Manager approval for high-value accounts
   - Compliance review for complex cases

---

## HIGH Priority Tasks (Pre-Demo)

### 1. Service Cloud Configuration (MANDATORY)

**Status:** ❌ NOT COMPLETED

```bash
sf project deploy start --manifest manifest/package-service-cloud-features.xml --target-org schwab-sandbox
```

**Manual Steps (Cannot be automated):**

**A. Enable Email-to-Case:**
- [ ] Setup → Service → Email-to-Case → Enable
- [ ] Enable On-Demand Service
- [ ] Create routing address: `estates@[orgid].emailtocase.salesforce.com`
- [ ] Configure routing to Estate Cases queue with Estate Administration record type

**B. Enable Omni-Channel:**
- [ ] Setup → Service → Omni-Channel → Enable
- [ ] Assign users to "Estates Agent Presence"
- [ ] Add Service Channels to Estate Cases queue (Estate Case Channel, Estate Email Channel)

**C. Create Entitlements:**
- [ ] Setup → Entitlements → New
- [ ] Link to test accounts
- [ ] Associate with "Estate Succession SLA"

### 2. Email Deliverability (CRITICAL)

**Risk:** Emails appear "sent" but never arrive. PM thinks feature is broken.

- [ ] Setup → Email Administration → Deliverability → Set to "All Email"
- [ ] Add demo email addresses to verified list

**Test:**
```bash
# Send test email from sandbox, confirm arrives within 1 minute
```

### 3. Email Template Access

**Risk:** Agent opens composer but cannot find templates. Demo interrupted.

- [ ] Verify `Succession_Management` folder exists
- [ ] Verify all 5 templates exist (Day 0, 5, 35, 65, 95)
- [ ] Add demo user to folder access
- [ ] Test: Log in as demo user → Open composer → All 5 visible

### 4. Test Data Email Validation

**Risk:** Email validation warnings during demo, component shows errors.

```bash
cci task run load_demo_ui_showcase

sf data query --query "SELECT Id, Name, PersonEmail FROM Account WHERE IsPersonAccount = true AND PersonEmail = null"

sf data update record --sobject Account --record-id <ID> --values "PersonEmail=test@schwabcharitable.org"
```

### 5. Succession Portal Experience Cloud Site

**Status:** ⚠️ PARTIALLY CONFIGURED

**Current State:**
- Site exists: https://schwabcharitablefund--fscjosh.sandbox.my.site.com/succession
- Status: "UnderConstruction"

**Required Steps:**
- [ ] Setup → Digital Experiences → All Sites → Succession Portal → Activate
- [ ] Add `successionPublicForm` LWC to site page
- [ ] Configure guest user profile (Read: Case, Account, Contact, FinancialAccount; Execute: SuccessionPublicFormController)
- [ ] Test form URL
- [ ] Update `Pathway_Form_Invitation` email template with actual URL

**Alternative:** Skip public site for demo, use internal form only

---

## Resources

- **Salesforce Help:** [Service Cloud Basics](https://help.salesforce.com/s/articleView?id=sf.service_cloud_basics.htm)
- **Trailhead:** [Omni-Channel Routing](https://trailhead.salesforce.com/en/content/learn/modules/omni-channel-routing)
- **Trailhead:** [Set Up Entitlement Management](https://trailhead.salesforce.com/en/content/learn/projects/set-up-entitlement-management)

**Demo Owner:** Josh Rojas (josh.rojas.charfsc@schwab.com.fscjosh)  
**Target Org:** schwab-sandbox
