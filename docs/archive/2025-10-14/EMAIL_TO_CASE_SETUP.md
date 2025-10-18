# Email-to-Case Setup for Succession Management

**Last Updated:** 2025-10-14
**Purpose:** Configuration guide for Email-to-Case with Omni-Channel routing

---

## 🎯 Overview

The Succession Management system uses **Email-to-Case** to automatically create Estate Administration cases from inbound emails. Emails route through **Omni-Channel** to intelligently distribute workload across the Estates team.

---

## 📧 Email-to-Case Configuration

### **Email Services Address**

**Recommended:** `estates@schwabcharitable.org` (org-specific email address)
**Fallback:** Use Salesforce-provided email address: `cases@[orgid].emailtocase.salesforce.com`

### **Routing Configuration**

**Email arrives at:** `estates@schwabcharitable.org`
↓
**Email-to-Case creates:** New Case (RecordType: Estate Administration)
↓
**Case assigned to:** Estate Cases queue
↓
**Omni-Channel routes to:** Most available agent (capacity-based)
↓
**Agent receives:** Push notification in Service Console

---

## ⚙️ Setup Steps

### **Step 1: Enable Email-to-Case**

1. **Setup → Feature Settings → Service → Email-to-Case**
2. Click **Edit**
3. Check ☑ **Enable Email-to-Case**
4. Check ☑ **Enable On-Demand Service** (for immediate processing)
5. Click **Save**

### **Step 2: Create Email-to-Case Routing Address**

1. **Setup → Email-to-Case → Routing Addresses**
2. Click **New**
3. Configure:
   - **Routing Name:** Estate Succession Cases
   - **Email Address:** `estates@schwabcharitable.org` (or org email)
   - **Save Email To:** Case (Task/Lead not needed)
   - **Case Origin:** Email
   - **Case Priority:** Medium (default)
   - **Task Priority:** Normal
   - **Case Record Type:** Estate Administration
   - **Create Task From Email:** ☐ Unchecked (we handle tasks via flows)
   - **Route to Queue:** ☑ Checked → Select **Estate Cases** queue
   - **Route to User:** ☐ Unchecked (use queue-based routing)
4. Click **Save**

### **Step 3: Configure Email Response Settings**

1. **Setup → Email-to-Case → Settings**
2. Configure:
   - **Email Thread:** ☑ Enabled (keeps email conversations threaded to case)
   - **Automated Case User:** Select service account user (e.g., Automated Process)
   - **Notify Case Owners:** ☑ Checked (optional - can be handled by Omni-Channel push)
   - **HTML Email:** ☑ Accept (enables rich-text emails)
   - **Unauthorized Sender:** Create new case (don't reject - may be legitimate successor)
3. Click **Save**

### **Step 4: Link Service Channel to Queue**

1. **Setup → Queues → Estate Cases**
2. Scroll to **Supported Channels** section
3. Click **Add** next to Service Channels
4. Select:
   - ☑ **Estate Case Channel** (for case-based routing)
   - ☑ **Estate Email Channel** (for email-based routing)
5. Click **Save**

### **Step 5: Enable Omni-Channel for Email Routing**

1. **Setup → Omni-Channel Settings**
2. Check ☑ **Enable Omni-Channel**
3. Click **Save**

### **Step 6: Assign Presence Configuration to Users**

1. **Setup → Presence Configurations**
2. Click **New**
3. Configure:
   - **Configuration Name:** Estates Agent Presence
   - **Developer Name:** Estates_Agent_Presence
   - **Capacity:** 5 (agents can handle 5 concurrent email cases)
   - **Agent Work Interruptions:** Critical interruptions only
4. Click **Save**
5. Click **Assigned Users** → Add Estates team members

---

## 📊 Email-to-Case Workflow

### **Scenario 1: Deceased Donor Notification**

**Email From:** advisor@schwab.com
**Subject:** Deceased Donor - Account #12345 (John Doe)
**Body:**

```
Dear Estates Team,

Please be advised that account holder John Doe (Account #12345)
passed away on October 1, 2025. Death certificate attached.

Designated successor: Amanda Doe (daughter)
Contact: amanda.doe@email.com | (555) 123-4567

Please process succession per account designation.

Best regards,
Financial Advisor Name
```

**System Actions:**

1. Email-to-Case creates new Case:
   - **Record Type:** Estate Administration
   - **Type:** Named Successor Enactment
   - **Origin:** Email
   - **Queue:** Estate Cases
   - **Description:** Email body content
   - **Subject:** "Deceased Donor - Account #12345 (John Doe)"
2. Omni-Channel detects unassigned case in queue
3. System calculates agent availability:
   - Agent A: 2/5 capacity (40% utilized)
   - Agent B: 4/5 capacity (80% utilized)
   - Agent C: Offline (0% available)
4. **Result:** Case routes to Agent A (most available)
5. Agent A receives push notification in Service Console
6. Agent A clicks "Accept" → Case opens in new tab
7. Email body + attachment (death certificate) visible in Case feed

### **Scenario 2: Successor Inquiry Email**

**Email From:** amanda.doe@email.com
**Subject:** Question about succession options for John Doe account
**Body:**

```
Hello,

I received your email about my designation as successor for my
father John Doe's DAF account. I have questions about the three
options (Disclaim, New DAF, Final Grant). Can someone call me?

Thank you,
Amanda Doe
(555) 123-4567
```

**System Actions:**

1. Email-to-Case creates new Case
2. Case assigned to Estate Cases queue
3. Omni-Channel routes to most available agent
4. Agent receives push notification
5. Agent accepts → Sees email content
6. Agent calls Amanda using phone number in email
7. Agent records contact outcome in `successionContactCadence` component

---

## 🎨 Demo Scenarios

### **Demo Flow 1: Live Email-to-Case Creation (5 minutes)**

**Setup:**

- Have pre-written email ready in Gmail/Outlook
- Open Service Console with Omni-Channel widget visible
- Agent status set to "Available - Case"

**Live Demo:**

1. **Send email** to `estates@schwabcharitable.org` from external account
2. **Subject:** "Deceased Donor Notification - DEMO ACCOUNT"
3. **Body:** Include death certificate mention, successor name, contact info
4. **Wait 10-30 seconds** (On-Demand Email-to-Case processes immediately)
5. **Show Omni-Channel widget** lighting up with incoming work
6. **Agent clicks Accept** → Case opens
7. **Show email content** in case feed with original sender, subject, body

**Talking Points:**

> "Notice how the email was instantly converted to a case and routed to me as the most available agent. The original email content is preserved in the case feed, including attachments. This eliminates manual case creation and ensures no email falls through the cracks."

### **Demo Flow 2: Email Thread Management (3 minutes)**

**Setup:**

- Use existing case created from email

**Live Demo:**

1. Open email-created case
2. Click **Send Email** action in case feed
3. Send reply to original sender
4. **External user replies** to email
5. Show reply automatically attached to same case (threading)

**Talking Points:**

> "Service Cloud maintains email threading—when the successor replies, their response automatically attaches to the existing case. This creates a complete audit trail of all communications."

---

## 📋 Pre-Demo Checklist

**Setup (24 hours before):**

- [ ] Enable Email-to-Case in org (Setup → Email-to-Case)
- [ ] Create routing address: `estates@schwabcharitable.org`
- [ ] Link Estate Cases queue to Estate Case Channel + Estate Email Channel
- [ ] Assign Estates Agent Presence config to demo user
- [ ] Test email routing: Send test email → Verify case created

**Day of Demo:**

- [ ] Log in as demo agent in Service Console
- [ ] Open Omni-Channel widget
- [ ] Set status to "Available - Case"
- [ ] Open Gmail/Outlook in separate window (for live email send)
- [ ] Have pre-written email drafted (don't send yet)

**During Demo:**

- [ ] Send email live during presentation (wait 10-30 seconds for processing)
- [ ] Accept case via Omni-Channel
- [ ] Show email content in case feed
- [ ] Demonstrate threading by replying to sender

---

## 🔧 Troubleshooting

**Issue:** Email not creating case

- **Fix:** Setup → Email-to-Case → Email Logs (check for errors)
- **Fix:** Verify routing address matches sender's "To:" address exactly
- **Fix:** Check email isn't marked as spam (Setup → Deliverability)

**Issue:** Case created but not routing via Omni-Channel

- **Fix:** Verify queue has Service Channel assigned (Setup → Queues → Estate Cases)
- **Fix:** Verify agent status is "Available - Case" (not Busy/Away/Offline)
- **Fix:** Verify agent has capacity available (check Omni-Channel widget)

**Issue:** Email thread not attaching to case

- **Fix:** Setup → Email-to-Case → Settings → Enable Email Thread
- **Fix:** Verify original email includes case number in subject (e.g., "Re: [Case:00001234]")

**Issue:** Attachments not saving to case

- **Fix:** Setup → Email Attachments → Enable "Save Email Attachments"
- **Fix:** Check file size limits (max 25MB per email)
- **Fix:** Verify attachment types allowed (PDF, DOC, JPG, PNG)

---

## 📚 Additional Resources

- **Salesforce Help:** [Set Up Email-to-Case](https://help.salesforce.com/s/articleView?id=sf.customizesupport_email.htm)
- **Trailhead Module:** [Email Integration](https://trailhead.salesforce.com/en/content/learn/modules/service_email)
- **Omni-Channel Routing:** [Route Email Messages](https://help.salesforce.com/s/articleView?id=sf.omnichannel_routing_email.htm)

---

## 🎯 Key Demo Talking Points

**Opening:**

> "Schwab Charitable receives dozens of deceased donor notifications daily via email. Manual case creation is time-consuming and error-prone. With Email-to-Case and Omni-Channel, we've automated this entirely."

**During Live Email Send:**

> "Watch what happens when I send this email to our estates inbox... [wait 15 seconds]... there it is! Omni-Channel instantly pushed this to me because I had the most available capacity. The system knew Agent B was handling 4 cases and Agent C was on break."

**Email Threading:**

> "Notice the original email is preserved here in the case feed. When Amanda replies, her response will automatically attach to this same case. No more searching through inboxes to find email chains."

**Closing:**

> "This automation saves our team 2-3 hours daily and ensures we never miss an email. Every deceased donor notification becomes a tracked case with full accountability."

---

**Document Owner:** Josh Rojas (josh.rojas.charfsc@schwab.com.fscjosh)
**Last Updated:** 2025-10-14
