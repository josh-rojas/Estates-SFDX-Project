# Demo Preparation Checklist

**Purpose:** Ensure smooth live demo for Estates team and Product Management review

**Target Org:** schwab-sandbox (josh.rojas.charfsc@schwab.com.fscjosh)

---

## ⚠️ CRITICAL PRE-DEMO SETUP (Must Complete 24 Hours Before Demo)

### 1. Sandbox Email Deliverability ⚠️ CRITICAL

Sandbox orgs **ONLY** send emails to verified email addresses.

**Steps:**
1. Go to **Setup** → **Email Administration** → **Deliverability**
2. Verify **Access Level** is set to allow email sending
3. Add all demo email addresses to **verified email addresses list**:
   - Your email (for testing)
   - Any PM/stakeholder emails who will receive test emails
   - Test data email addresses (if using real addresses)

**Test:**
```bash
# Send test email from sandbox to verify deliverability
# Navigate to any Contact/Account → Send Email → Send to verified address
```

**Risk if skipped:** Emails appear "sent" during demo but never arrive. PM thinks feature is broken.

---

### 2. Email Template Validation ⚠️ CRITICAL

Verify all 5 contact cadence email templates exist and are accessible.

**Steps:**
1. Go to **Setup** → **Email Templates**
2. Navigate to **Succession_Management** folder
3. Verify these templates exist:
   - `Day 0 - Initial Contact`
   - `Day 5 - First Follow-Up`
   - `Day 35 - Second Contact`
   - `Day 65 - Third Contact`
   - `Day 95 - Final Contact`

**Verify Template Names Match Code:**
- Template **Display Name** (what agent sees) must match toast message in code
- Check [successionContactCadence.js:408-414](../force-app/main/default/lwc/successionContactCadence/successionContactCadence.js) for exact names

**Verify Folder Permissions:**
- Go to **Setup** → **Public Groups** or **Permission Sets**
- Ensure **Succession_Management_Access** permission set includes access to `Succession_Management` folder
- Test: Log in as demo user → Open email composer → Search for templates → All 5 visible

**Risk if skipped:** Agent opens composer during demo but cannot find templates. Demo interrupted.

---

### 3. Demo User Setup

**Create/Verify Demo User:**
```bash
# Assign required permission sets
sf org assign permset --name Succession_Management_Access --target-org schwab-sandbox
sf org assign permset --name Succession_Field_Access --target-org schwab-sandbox
```

**Verify Demo User Has:**
- Read/Write access to Case, Account, Contact, Task, FinancialAccount objects
- Access to Email Templates folder
- "Send Email" action enabled on Account and Contact objects
- Lightning Experience enabled (NOT Salesforce Classic)

**Test Login:**
- Log in as demo user
- Open a test Succession case
- Verify `successionContactCadence` component loads
- Click "Send Email" → Email composer should open

---

### 4. Test Data Generation

**Load Demo Data:**
```bash
# Option 1: Complete demo dataset
cci task run load_demo_ui_showcase

# Option 2: Specific scenarios
cci task run load_final_grant_scenario  # Complete lifecycle
cci task run load_multi_successor_scenario  # Multi-successor cases
```

**CRITICAL: Validate Test Data Email Addresses**

After loading data, verify all Person Accounts have valid email addresses:

```bash
# Query Person Accounts without email
sf data query --query "SELECT Id, Name, PersonEmail FROM Account WHERE IsPersonAccount = true AND PersonEmail = null" --target-org schwab-sandbox
```

**Fix Invalid Emails:**
```bash
# Update any NULL or invalid emails
sf data update record --sobject Account --record-id <ID> --values "PersonEmail=test@schwabcharitable.org" --target-org schwab-sandbox
```

**Email Format Validation:**
- All emails must have format: `name@domain.tld`
- No typos: `test@@example.com`, `test.example.com` (missing @), `test @example.com` (space)
- Use faker.email() in Snowfakery recipes for valid format

---

### 5. Public Form URL Verification (If Demonstrating Form Workflow)

**If using Experience Cloud Site:**
1. Go to **Setup** → **Digital Experiences** → **All Sites**
2. Verify site is **Active** and **Published**
3. Copy public URL
4. Test form URL with sample caseId parameter:
   ```
   https://yoursite.force.com/succession-form?caseId=500XXXXXXXXX&accountId=001XXXXXXXXX
   ```

**If NOT demonstrating public form:**
- Clarify to PM that public form is placeholder/future enhancement
- Show form component in internal Salesforce only

**Update Email Template:**
- If using public site, update `Pathway_Form_Invitation` email template with actual form URL
- If NOT using public site, skip this step (template shows placeholder URL)

---

## 📋 DAY-OF-DEMO CHECKLIST (30 Minutes Before Demo)

### 6. Browser & Environment Setup

**Browser Requirements:**
- Use **Chrome**, **Firefox**, or **Edge** (latest version)
- **NOT Internet Explorer** (Lightning Web Components require modern browser)
- Disable browser pop-up blocker for `*.salesforce.com`
- Clear browser cache if experiencing issues

**Test Environment:**
```bash
# Verify sandbox org is accessible
sf org open --target-org schwab-sandbox

# Check data exists
sf data query --query "SELECT COUNT() FROM Case WHERE RecordType.DeveloperName = 'EstateAdministration'" --target-org schwab-sandbox
```

---

### 7. Demo Scenario Walkthrough

**Prepare 2-3 Demo Cases:**

**Case 1: Happy Path - Contact Established on Attempt 1**
- Person Account with valid email
- No opt-out flag
- Complete workflow: Record Outcome (YES) → Automated email sends → Show pathway form

**Case 2: No Contact Established - Multiple Attempts**
- Person Account with valid email
- Record Outcome (NO) → Email prompt appears → Click "Send Email" → Composer opens → Select template → Skip for demo
- Repeat for Attempt 2

**Case 3: Edge Case - Email Warning**
- Person Account with `HasOptedOutOfEmail = true`
- OR Person Account with NULL `PersonEmail`
- Show email warning alert
- Show "Send Email" button disabled

**Multi-Successor Case (Optional):**
- Parent case with 2+ child cases
- Show `caseHierarchyViewer` component
- Show each child has independent contact cadence

---

### 8. Component Pre-Flight Check

**Open Demo Case in Lightning:**
1. Navigate to Case record page
2. Verify `successionContactCadence` component displays
3. Check progress bar renders correctly
4. Verify all 5 attempt cards visible

**Test Button Interactions:**
- Click "Record Outcome" → Inline form appears
- Select YES/NO radio → No errors
- Enter notes → No errors
- Click "Save Outcome" → Success toast appears
- If NO selected → Email prompt appears
- Click "Send Email" → Composer opens
- Close composer → Email prompt STILL visible (persistence fix)
- Click "Skip" → Email prompt disappears

---

## 🐛 TROUBLESHOOTING GUIDE

### Issue: Email Composer Opens But No Templates Visible

**Cause:** Demo user doesn't have access to `Succession_Management` folder

**Fix:**
1. Go to **Setup** → **Email Templates**
2. Click **Succession_Management** folder → **Folder Sharing**
3. Add demo user's profile or public group
4. Re-test

---

### Issue: Email Composer Opens But TO Field is Empty

**Cause:** PersonEmail or Contact.Email is NULL

**Fix:**
1. Query the Account/Contact:
   ```bash
   sf data query --query "SELECT Id, PersonEmail FROM Account WHERE Id = '<ACCOUNT_ID>'" --target-org schwab-sandbox
   ```
2. Update email address:
   ```bash
   sf data update record --sobject Account --record-id <ID> --values "PersonEmail=test@schwabcharitable.org"
   ```
3. Refresh component

---

### Issue: "Email Issue: Successor has opted out of email"

**Cause:** `HasOptedOutOfEmail = true` on Account or Contact

**Fix (if unintended):**
```bash
sf data update record --sobject Account --record-id <ID> --values "HasOptedOutOfEmail=false"
```

**OR demonstrate this as feature:** Show how system prevents sending to opted-out users

---

### Issue: Component Shows "Invalid Record Type"

**Cause:** Case RecordType is not `EstateAdministration` or Case Type is not `Named Successor Enactment`

**Fix:**
1. Verify case record type:
   ```bash
   sf data query --query "SELECT Id, RecordType.DeveloperName, Type FROM Case WHERE Id = '<CASE_ID>'"
   ```
2. Ensure RecordType = `EstateAdministration` and Type = `Named Successor Enactment` or `Succession Management`

---

### Issue: Email Warning Shows "Email address format appears invalid"

**Cause:** Email has invalid format (missing @, double @@, etc.)

**Fix:**
```bash
# Update to valid format
sf data update record --sobject Account --record-id <ID> --values "PersonEmail=valid.email@domain.com"
```

---

### Issue: "Send Email" Button Stays Disabled After Click

**Cause:** Double-click prevention timeout not reset

**Fix:**
- Refresh page
- Or wait 2 seconds (auto-resets)
- This is expected behavior (prevents multiple composer windows)

---

## 📊 DEMO SCRIPT RECOMMENDATION

**Opening (2 minutes):**
- "This demo shows the 5-attempt contact cadence workflow"
- "Handles both Person Accounts (typical) and Business Accounts"
- "Email sending is optional and scalable for high-volume agents"

**Main Demo (5 minutes):**
1. Open Case → Show progress bar (0% complete)
2. Click "Record Outcome" → Show inline form
3. Select "NO" → Click "Save Outcome"
4. Show email prompt appears → "Send Email" button
5. Click "Send Email" → Composer opens
6. Show template dropdown → Find "Day 0 - Initial Contact"
7. Close composer without sending → **Prompt still visible** (persistence)
8. Click "Skip" → Prompt dismisses

**Edge Cases (3 minutes):**
1. Show case with opt-out flag → Email warning appears
2. Show case with NULL email → "Send Email" disabled
3. Show multi-successor case → Parent + child hierarchy

**Q&A (5 minutes):**
- Clarify email sending is OPTIONAL (agent choice)
- Confirm scalability for 50+ cases/day (no auto-opening)
- Discuss public form deployment (future/optional)

---

## ✅ FINAL PRE-DEMO CHECKLIST

**30 Minutes Before Demo:**
- [ ] Sandbox email deliverability verified (test email sent and received)
- [ ] All 5 email templates exist and are accessible to demo user
- [ ] Demo user has both permission sets assigned
- [ ] 3 demo cases prepared (happy path, multiple attempts, edge case)
- [ ] Browser configured (modern browser, pop-ups allowed)
- [ ] Test data email addresses are valid format
- [ ] Component loads correctly on demo case
- [ ] "Send Email" button successfully opens composer
- [ ] Email templates visible in composer dropdown
- [ ] Public form URL tested (if demonstrating form workflow)

**Backup Plan:**
- If email composer fails → Show screenshot/video of working email flow
- If public form site not deployed → Explain it's optional enhancement for production
- If templates missing → Manually compose email to demonstrate concept

---

## 📞 CONTACTS & SUPPORT

**If issues during setup:**
- Check [CLAUDE.md](../CLAUDE.md) for full project documentation
- Review [README.md](../README.md) for deployment commands
- Test in sandbox before demo (NEVER test live during PM presentation)

**Demo Day Emergency:**
- Have backup screenshots of working workflow
- Prepare to explain concepts verbally if technical issues occur
- Emphasize this is DEMO/SANDBOX (not production-ready)
