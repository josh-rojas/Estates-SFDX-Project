# Experience Cloud Deployment Guide: Succession Portal

**Purpose:** Deploy and configure the Succession Portal Experience Cloud site for token-based succession pathway form submissions.

**Time Estimate:** 30-45 minutes
**Complexity:** Medium
**Prerequisites:** Experience Cloud license enabled, System Administrator access

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Pre-Deployment Checklist](#pre-deployment-checklist)
3. [Deployment Steps](#deployment-steps)
4. [Post-Deployment Configuration](#post-deployment-configuration)
5. [Testing](#testing)
6. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### Site Structure

```
Succession Portal (Experience Cloud Site)
├── URL: https://{org-domain}.my.site.com/succession
├── Type: LWR (Lightning Web Runtime) - headless, modern
├── Access: Guest users only (token-based authentication)
└── Page: /succession/form?t={encryptedToken}
    └── Component: c:successionPathwayForm (7-step wizard)
```

### Components Deployed

| Component | Type | Purpose |
|-----------|------|---------|
| `Succession Portal.network` | Network | Experience Cloud site settings |
| `Succession_Portal.site` | CustomSite | Site definition & URL config |
| `Succession Portal Profile.profile` | Profile | Guest user permissions |
| `Succession_Portal1.site` | ExperienceBundle | Site pages, branding, layout |
| `successionPathwayForm` | LWC | Form component (7-step wizard) |
| `SuccessionFormController` | Apex | Form backend logic |

### Security Model

- **No login required** - Token-based access only
- **One-time use tokens** - Expire after 30 days or submission
- **Guest user profile** - Minimal read-only permissions
- **HTTPS enforced** - All connections encrypted
- **XSS/Clickjacking protection** - Enabled by default

---

## Pre-Deployment Checklist

### ✅ Required Licenses

- [ ] Experience Cloud licenses available (check Setup → Company Information → User Licenses)
- [ ] Guest User License available (automatically included with Experience Cloud)

### ✅ Required Permissions

- [ ] System Administrator profile
- [ ] "Customize Application" permission
- [ ] "Manage Profiles and Permission Sets" permission

### ✅ Domain Setup

- [ ] My Domain configured and deployed (Setup → My Domain)
- [ ] Custom domain verified (if using custom URL)

### ✅ Email Configuration

- [ ] Organization-Wide Email Address configured for `noreply@schwabcharitable.org`
- [ ] Email deliverability set to "All Email" (Setup → Email Administration → Deliverability)

---

## Deployment Steps

### Step 1: Deploy Experience Cloud Metadata (10 min)

**Option A: Deploy via CLI (Recommended)**

```bash
# Navigate to project directory
cd "/Users/joshsmbp/Schwab Downloads/Estates SFDX Project"

# Deploy Experience Cloud components
sf project deploy start \
  --manifest manifest/package-experience-cloud-succession.xml \
  --target-org schwab-sandbox \
  --wait 15

# Expected output: "Status: Succeeded" with 7+ components deployed
```

**Option B: Deploy via VS Code**

1. Right-click `manifest/package-experience-cloud-succession.xml`
2. Select "SFDX: Deploy Source in Manifest to Org"
3. Wait for deployment confirmation

**Verification:**

```bash
# Verify deployment
sf project deploy report --target-org schwab-sandbox

# Should show:
# ✓ Network: Succession Portal
# ✓ CustomSite: Succession_Portal
# ✓ Profile: Succession Portal Profile
# ✓ ExperienceBundle: Succession_Portal1
```

---

### Step 2: Activate Experience Cloud (5 min)

**Via Setup UI:**

1. Navigate to **Setup → Digital Experiences → All Sites**
2. Locate "Succession Portal"
3. Click **Builder** (opens Experience Builder)
4. Click **Settings** (gear icon, top-right)
5. General Settings:
   - Site Name: `Succession Portal`
   - Status: **Activate** (toggle to Active)
   - Default Language: English
6. Click **Save**

**Expected Result:**
✓ Site status changes to "Active"
✓ Site URL becomes accessible: `https://{org-domain}.my.site.com/succession`

---

### Step 3: Configure Guest User Profile (10 min)

**Assign Apex Class Access:**

1. **Setup → Profiles → Succession Portal Profile**
2. Scroll to **Enabled Apex Class Access**
3. Click **Edit**
4. Add these classes to "Enabled Apex Classes":
   - `SuccessionFormController`
   - `SuccessionFormTokenValidator`
   - `SuccessionFormTokenGenerator`
5. **Save**

**Verify Object Permissions:**

| Object | Read | Create | Edit | Delete |
|--------|------|--------|------|--------|
| Case | ✓ | ✗ | ✗ | ✗ |
| Account | ✓ | ✗ | ✗ | ✗ |
| FinServ__FinancialAccount__c | ✓ | ✗ | ✗ | ✗ |

**Field-Level Security (Case):**

- `Pathway_Confirmed__c` → Visible, Read-Only
- `Form_Sent_Date__c` → Visible, Read-Only
- `Form_Completed_Date__c` → Visible, Read-Only
- `Contact_Established__c` → Visible, Read-Only
- `Verification_Status__c` → Visible, Read-Only

---

### Step 4: Update Site Settings (5 min)

**Cache Settings (Performance):**

1. **Setup → Digital Experiences → All Sites → Succession Portal → Administration**
2. Click **Preferences**
3. Enable caching:
   - Cache Public Pages: **ON**
   - Cache Authenticated Pages: **OFF** (not applicable)
   - Page Caching TTL: `300 seconds` (5 minutes)
4. **Save**

**Security Settings:**

1. **Setup → Digital Experiences → All Sites → Succession Portal → Administration**
2. Click **Security & Privacy**
3. Verify settings:
   - HTTPS Redirect: **Enabled**
   - Content Security Policy: **Enabled**
   - Referrer-Policy: **Enabled**
   - X-Content-Type-Options: **Enabled**
   - Browser XSS Protection: **Enabled**
4. **Save**

---

### Step 5: Configure URL Parameters (2 min)

**Enable Query Parameters:**

1. Open **Experience Builder** (Setup → Digital Experiences → All Sites → Builder)
2. Navigate to **Succession_Form** page
3. Click **Settings** (page settings, not site settings)
4. Under **Advanced**, enable:
   - Allow URL Parameters: **ON**
   - Allowed Parameters: `t` (token parameter)
5. **Publish** the site

---

## Post-Deployment Configuration

### Configure Email Templates

**Create Welcome Email Template:**

```apex
// Email sent when form link is generated
Subject: Your Succession Pathway Form - Action Required

Dear {!Contact.FirstName},

As a named successor for the DAF account of {!Case.Deceased_Donor_Name__c},
please complete your succession pathway recommendation at:

{!Case.Succession_Form_URL__c}

This secure link expires in 30 days. Your submission will be reviewed by our
Estate Administration team within 2 business days.

Questions? Reply to this email or call (800) 746-6216.

Best regards,
Schwab Charitable Estate Administration Team
```

**Assign to Flow:**

1. Update `Case_Send_Succession_Form.flow-meta.xml`
2. Set email template ID in "Send Email" action
3. Deploy flow update

---

## Testing

### Test Plan: End-to-End Form Submission

**Step 1: Generate Test Token**

```apex
// Execute in Developer Console (Anonymous Apex)
Case testCase = [SELECT Id FROM Case WHERE Type = 'Succession Management' LIMIT 1];
String token = SuccessionFormTokenGenerator.generateToken(testCase.Id);
System.debug('Test URL: https://schwabcharitable-succession.my.site.com/succession/form?t=' + token);
```

**Step 2: Access Form (Guest User)**

1. Open incognito/private browser window
2. Navigate to test URL from Step 1
3. Verify:
   - ✓ Page loads without login
   - ✓ Token validation succeeds
   - ✓ Case context displays correctly
   - ✓ Progress bar shows Step 1/7

**Step 3: Complete Form**

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Click "Next" | Step 2: Account Summary displays |
| 2 | Review account info | Balance, donor name visible |
| 3 | Review successor info | Name, contact info pre-populated |
| 4 | Select pathway | Final Grant / New DAF / Disclaim options |
| 5 | Enter pathway details | Conditional fields display |
| 6 | Upload documents (optional) | File upload works |
| 7 | Sign & submit | Success message displays |

**Step 4: Verify Submission**

```sql
-- Query Case record
SELECT Id, Pathway_Confirmed__c, Form_Completed_Date__c,
       SuccessorFormStatus__c
FROM Case
WHERE Id = :testCaseId
```

**Expected Results:**
- `Pathway_Confirmed__c` = User's selection
- `Form_Completed_Date__c` = Today's date/time
- `SuccessorFormStatus__c` = "Completed"

---

### Security Testing

**Token Validation Tests:**

| Test Case | Expected Result |
|-----------|----------------|
| Valid token, first use | ✓ Form loads |
| Valid token, second use | ✗ "Already submitted" error |
| Expired token (>30 days) | ✗ "Link expired" error |
| Invalid/tampered token | ✗ "Invalid link" error |
| Missing token parameter | ✗ "Access denied" error |

**Test Script:**

```apex
// Test expired token
SuccessionFormTokenValidator.TokenValidation result =
    SuccessionFormTokenValidator.validateToken('expired-token-here');

System.assertEquals(false, result.isValid);
System.assertEquals(true, result.isExpired);
```

---

## Troubleshooting

### Issue: "Site Not Found" Error

**Symptoms:**
- URL returns 404 error
- Site not listed in All Sites

**Resolution:**
1. Verify deployment: `sf project deploy report --target-org schwab-sandbox`
2. Check Network status: Setup → Digital Experiences → All Sites
3. Ensure My Domain is deployed
4. Verify `urlPathPrefix` = "succession" in Network metadata

---

### Issue: "Access Denied" or "Insufficient Privileges"

**Symptoms:**
- Guest user sees error when accessing form
- Console shows `System.NoAccessException`

**Resolution:**
1. Verify guest profile: Setup → Profiles → Succession Portal Profile
2. Check Apex class access:
   ```bash
   # Query profile permissions
   sf data query --query \
     "SELECT Parent.Name, ApexClass.Name
      FROM SetupEntityAccess
      WHERE ParentId IN (SELECT Id FROM Profile WHERE Name = 'Succession Portal Profile')" \
     --target-org schwab-sandbox
   ```
3. Ensure Case object permissions include Read access
4. Verify field-level security for all Case succession fields

---

### Issue: Component Not Rendering

**Symptoms:**
- Page loads but form component is blank
- Browser console shows LWC errors

**Resolution:**
1. Check component deployment:
   ```bash
   sf project deploy report --target-org schwab-sandbox | grep successionPathwayForm
   ```
2. Verify component is available to guest users:
   - Setup → Lightning Components → successionPathwayForm
   - Check "Available for Experience Cloud Sites"
3. Clear Experience Builder cache:
   - Open Builder → Settings → Performance → Clear Cache
   - Re-publish site

---

### Issue: Token Property Error

**Symptoms:**
- Error: "The 'token' property doesn't exist on the component"

**Resolution:**
1. This error occurs when component is deployed outside Experience Cloud context
2. Verify component is accessed via Experience Cloud URL (not direct LWC preview)
3. Check `successionPathwayForm.js`:
   ```javascript
   // Ensure token is declared as property (not @track)
   token = '';  // Correct
   @track token = '';  // Incorrect for Experience Cloud
   ```

---

### Issue: Form Submission Fails

**Symptoms:**
- Submit button disabled or shows error
- No Case update after submission

**Resolution:**
1. Check browser console for errors
2. Verify Apex controller permissions
3. Test backend directly:
   ```apex
   // Test submission logic
   Map<String, Object> submission = new Map<String, Object>{
       'caseId' => testCaseId,
       'pathway' => 'Final Grant',
       'signatureName' => 'Test User'
   };
   SuccessionFormController.submitPathwaySelection(submission);
   ```
4. Review Apex debug logs (Setup → Debug Logs)

---

## URL Examples

**Development:**
```
https://schwabcharitable-dev.sandbox.my.site.com/succession/form?t={token}
```

**UAT/Staging:**
```
https://schwabcharitable-uat.sandbox.my.site.com/succession/form?t={token}
```

**Production:**
```
https://succession.schwabcharitable.org/form?t={token}
```

---

## Next Steps

After successful deployment:

1. ✅ **Update Email Templates** - Add site URL to automated emails
2. ✅ **Configure Domain** - Set up custom domain (e.g., succession.schwabcharitable.org)
3. ✅ **Load Testing** - Test with 100+ concurrent users
4. ✅ **Monitor Analytics** - Enable Google Analytics tracking
5. ✅ **Document Runbook** - Create operational procedures for support team

---

## Support Contacts

| Area | Contact | Email |
|------|---------|-------|
| Experience Cloud Administration | IT Admin Team | it-admin@schwabcharitable.org |
| Succession Flow Issues | Estate Administration | estates@schwabcharitable.org |
| Apex/LWC Bugs | Development Team | dev-team@schwabcharitable.org |

---

**Document Version:** 1.0
**Last Updated:** 2025-10-03
**Author:** Claude Code (Anthropic)
**Review Cycle:** Quarterly or after major releases
