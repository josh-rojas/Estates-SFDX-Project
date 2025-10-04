# LWC Succession Form - Complete Deployment Guide

## Overview

This guide documents the **Lightning Web Component (LWC)** implementation of the Succession Pathway Recommendation Form, replacing the previously planned OmniScript approach.

**Decision Rationale**: LWC chosen over OmniScript for:
- ✅ No OmniStudio licensing cost
- ✅ Better performance for external users
- ✅ More control over UX and validation
- ✅ Native integration with Experience Cloud
- ✅ Stable requirements (3+ years unchanged)

**Timeline**: 60-90 minutes for complete deployment

---

## Architecture

### Component Structure

```
successionPathwayForm (Parent)
├── successionAccountSummary (Step 2)
├── successionSuccessorInfo (Step 3)
├── successionPathwaySelector (Step 4)
├── successionGrantBeneficiaries (Step 5 - Final Grant)
├── successionNewDafDetails (Step 5 - New DAF)
├── successionDisclaimDetails (Step 5 - Disclaim)
├── successionDocumentUpload (Step 6)
└── successionReviewAndSign (Step 7)
```

### Apex Controllers

1. **SuccessionFormTokenGenerator** - AES256 token encryption, HMAC signatures
2. **SuccessionFormTokenValidator** - 10-step validation (expiration, tampering, one-time use)
3. **SuccessionFormController** - LWC data operations (with sharing for guest access)

### Security Model

- **Token-Based Authentication**: 30-day expiration, one-time use, HMAC tamper protection
- **Guest User Access**: via Experience Cloud, no Salesforce login required
- **Org-Specific Encryption**: Uses org ID in key generation (sandbox-safe)

---

## Components Inventory

### Apex Classes (3 files)

| File | Lines | Purpose |
|------|-------|---------|
| `SuccessionFormTokenGenerator.cls` | 217 | Generate secure tokens and unique URLs |
| `SuccessionFormTokenValidator.cls` | 224 | Validate tokens (10 checks) and enforce one-time use |
| `SuccessionFormController.cls` | 385 | LWC controller with @AuraEnabled methods |

**Total Apex**: 826 lines

### LWC Components (9 components x 3-4 files each = 30 files)

| Component | Files | Purpose |
|-----------|-------|---------|
| `successionPathwayForm` | 4 (js, html, css, xml) | Parent wizard, step navigation |
| `successionAccountSummary` | 3 (js, html, xml) | Step 2: Display account summary |
| `successionSuccessorInfo` | 3 (js, html, xml) | Step 3: Verify successor contact info |
| `successionPathwaySelector` | 4 (js, html, css, xml) | Step 4: Choose pathway (3 options) |
| `successionGrantBeneficiaries` | 4 (js, html, css, xml) | Step 5 (Final Grant): Dynamic grant table |
| `successionNewDafDetails` | 3 (js, html, xml) | Step 5 (New DAF): Email & terms |
| `successionDisclaimDetails` | 3 (js, html, xml) | Step 5 (Disclaim): Reason & attestation |
| `successionDocumentUpload` | 3 (js, html, xml) | Step 6: File upload with requirements |
| `successionReviewAndSign` | 4 (js, html, css, xml) | Step 7: Review & e-signature |

**Total LWC**: 30 files

---

## Custom Fields Required on Case Object

Deploy these fields before deploying Apex/LWC:

| API Name | Type | Length | Required | Description |
|----------|------|--------|----------|-------------|
| `Succession_Form_Token__c` | Text | 255 | No | Encrypted token (stored for audit) |
| `Token_Expiration__c` | DateTime | - | No | Token expiration timestamp |
| `Token_Used__c` | Checkbox | - | No | One-time use enforcement |
| `New_DAF_Email__c` | Email/Text | 255 | No | Email for new DAF account |
| `New_DAF_Terms_Acknowledged__c` | Checkbox | - | No | Terms acknowledgment flag |
| `New_DAF_Terms_Date__c` | DateTime | - | No | When terms were acknowledged |
| `Disclaimer_Reason__c` | Long Text Area | 1000 | No | Reason for disclaiming account |
| `Disclaimer_Legal_Attestation__c` | Checkbox | - | No | Legal attestation checkbox |
| `Disclaimer_Date__c` | DateTime | - | No | When disclaimer was submitted |

**Note**: These fields supplement the existing succession fields (`Contact_Established__c`, `Pathway_Confirmed__c`, `Form_Completed_Date__c`, etc.)

---

## Deployment Steps

### Phase 1: Deploy Custom Fields (10 minutes)

**Option A: Via CLI**

```bash
# Create manifest for new Case fields
sf project deploy start \
  --source-dir force-app/main/default/objects/Case/fields \
  --target-org schwab-sandbox
```

**Option B: Via Setup UI**

1. Navigate: Setup → Object Manager → Case → Fields & Relationships
2. Create each field per table above
3. Add to EstateAdministration page layout (optional, for agent visibility)

**Verification**:
```bash
sf data query \
  --query "SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Case' AND QualifiedApiName LIKE '%Succession%' OR QualifiedApiName LIKE '%DAF%' OR QualifiedApiName LIKE '%Disclaimer%' OR QualifiedApiName LIKE '%Token%'" \
  --target-org schwab-sandbox
```

---

### Phase 2: Deploy Apex Classes (10 minutes)

```bash
# Deploy all 3 Apex classes
sf project deploy start \
  --source-dir force-app/main/default/classes/SuccessionForm* \
  --target-org schwab-sandbox
```

**Files Deployed**:
- `SuccessionFormTokenGenerator.cls` + `-meta.xml`
- `SuccessionFormTokenValidator.cls` + `-meta.xml`
- `SuccessionFormController.cls` + `-meta.xml`

**Expected Output**:
```
Deployed Source
├── SuccessionFormTokenGenerator.cls
├── SuccessionFormTokenValidator.cls
└── SuccessionFormController.cls

Component Failures: 0
```

---

### Phase 3: Deploy LWC Components (15 minutes)

```bash
# Deploy all LWC components
sf project deploy start \
  --source-dir force-app/main/default/lwc/succession* \
  --target-org schwab-sandbox
```

**Files Deployed**: 30 files across 9 components

**Verification**:
```bash
# List deployed LWC components
sf data query \
  --query "SELECT DeveloperName, Description FROM LightningComponentBundle WHERE DeveloperName LIKE 'succession%'" \
  --target-org schwab-sandbox
```

Expected: 9 components (successionPathwayForm, successionAccountSummary, successionSuccessorInfo, successionPathwaySelector, successionGrantBeneficiaries, successionNewDafDetails, successionDisclaimDetails, successionDocumentUpload, successionReviewAndSign)

---

### Phase 4: Experience Cloud Setup (20-30 minutes)

#### A. Create Experience Cloud Site (if not exists)

1. **Setup** → Digital Experiences → All Sites → New
2. **Template**: Customer Account Portal (or Self-Service)
3. **Name**: DAF Succession Portal
4. **URL**: `succession` (results in: `yourorg.force.com/succession`)
5. **Click Create**

#### B. Configure Guest User Profile

1. **Setup** → Digital Experiences → All Sites → Workspaces → Administration → Preferences**
2. **Guest User Profile**: Click "View Profile"
3. **Add Apex Class Access**:
   - SuccessionFormTokenGenerator
   - SuccessionFormTokenValidator
   - SuccessionFormController
4. **Add Object Permissions**:
   - Case: Read (no create/edit needed for form submission)
   - Contact: Read
   - Account: Read
   - FinServ__FinancialAccount__c: Read
   - FinServ__FinancialAccountRole__c: Read
   - FinServ__FinancialAccountTransaction__c: Create (for grant transactions)
5. **Add Field-Level Security**: Grant read access to all Case fields used in form

#### C. Create Form Page

1. **Builder → Pages → New Page**
2. **Page Type**: Standard Page
3. **Page Name**: Succession Form
4. **URL**: `succession-form`
5. **Add Component**: Drag `successionPathwayForm` to page
6. **Save & Publish**

#### D. Test Guest User Access

```bash
# Get site guest user URL
sf data query \
  --query "SELECT GuestUserId, UrlPathPrefix FROM Network WHERE Name = 'DAF Succession Portal'" \
  --target-org schwab-sandbox
```

Open incognito browser:
`https://yourorg.force.com/succession/succession-form?t={testToken}`

---

### Phase 5: Generate Test Token & Test End-to-End (15 minutes)

#### A. Create Test Data

```apex
// Execute in Developer Console: Anonymous Apex
SuccessionTestDataFactory.SuccessionScenarioData scenario =
    SuccessionTestDataFactory.generateHappyPathFinalGrant();

System.debug('Case ID: ' + scenario.successionCase.Id);
System.debug('Financial Account Balance: ' + scenario.financialAccount.FinServ__Balance__c);
```

#### B. Mark Contact Established

```apex
// Required before token generation
Case c = new Case(
    Id = scenario.successionCase.Id,
    Contact_Established__c = true,
    Contact_Established_Date__c = DateTime.now()
);
update c;
```

#### C. Generate Token

```apex
String token = SuccessionFormTokenGenerator.generateToken(scenario.successionCase.Id);
String url = SuccessionFormTokenGenerator.generateFormURL(scenario.successionCase.Id);

System.debug('Token: ' + token);
System.debug('Form URL: ' + url);
```

#### D. Test Form Submission

1. **Open URL in incognito browser**
2. **Step 1 (Welcome)**: Token validates → Click Next
3. **Step 2 (Account Summary)**: Verify deceased donor name, account balance → Click Next
4. **Step 3 (Successor Info)**: Verify successor contact info → Click Next
5. **Step 4 (Pathway Selection)**: Select "Final Grant" → Click Next
6. **Step 5 (Grant Details)**: Add 2 beneficiaries:
   - American Red Cross, $250,000, "Disaster Relief"
   - Doctors Without Borders, $250,000, "Medical Aid"
   - Click "Distribute Evenly" to auto-fill amounts
   - Verify total = account balance (green indicator)
   - Click Next
7. **Step 6 (Documents)**: Upload death certificate PDF → Click Next
8. **Step 7 (Review & Sign)**: Review all details → Type full name → Check attestation → Click Submit
9. **Success Message**: "Your succession pathway selection has been submitted successfully"

#### E. Verify Backend Records

```apex
// Check Case updated
Case result = [
    SELECT Id, Pathway_Confirmed__c, Form_Completed_Date__c,
           Status, Token_Used__c, Execution_Notes__c
    FROM Case
    WHERE Id = :scenario.successionCase.Id
];

System.debug('Pathway: ' + result.Pathway_Confirmed__c); // "Final Grant"
System.debug('Completed: ' + result.Form_Completed_Date__c); // DateTime.now()
System.debug('Status: ' + result.Status); // "Documentation - Final Grant"
System.debug('Token Used: ' + result.Token_Used__c); // true

// Check grant transactions created
List<FinServ__FinancialAccountTransaction__c> grants = [
    SELECT Id, Charity__c, FinServ__Amount__c, FinServ__TransactionStatus__c
    FROM FinServ__FinancialAccountTransaction__c
    WHERE FinServ__FinancialAccount__c = :scenario.financialAccount.Id
];

System.debug('Grants Created: ' + grants.size()); // 2
System.debug('Grant 1: ' + grants[0].Charity__c + ' - $' + grants[0].FinServ__Amount__c);
System.debug('Grant 2: ' + grants[1].Charity__c + ' - $' + grants[1].FinServ__Amount__c);

// Check review task created
List<Task> tasks = [
    SELECT Id, Subject, Priority, Status, ActivityDate
    FROM Task
    WHERE WhatId = :scenario.successionCase.Id
    AND Subject LIKE 'Review Succession Form%'
];

System.debug('Tasks Created: ' + tasks.size()); // 1
System.debug('Task Priority: ' + tasks[0].Priority); // "High"
System.debug('Task Due: ' + tasks[0].ActivityDate); // Today + 2 days
```

**Expected Results**:
- ✅ Case: `Pathway_Confirmed__c = "Final Grant"`, `Token_Used__c = true`
- ✅ Grant Transactions: 2 records, Status = "Pending Review"
- ✅ Task: "Review Succession Form Submission - Final Grant" (Priority: High, Due: 2 days)

---

## Testing All 3 Pathways

### Pathway 1: Final Grant (Tested Above)

**Key Validation**: Total grants ±5% of account balance

### Pathway 2: New DAF Account

```apex
// Step 4: Select "New DAF Account"
// Step 5: Enter email "successor@example.com", check terms
// Step 7: Submit

// Verify
Case newDAF = [SELECT New_DAF_Email__c, New_DAF_Terms_Acknowledged__c FROM Case WHERE Id = :caseId];
System.debug('Email: ' + newDAF.New_DAF_Email__c); // "successor@example.com"
System.debug('Terms: ' + newDAF.New_DAF_Terms_Acknowledged__c); // true
```

### Pathway 3: Disclaim Assets

```apex
// Step 4: Select "Disclaim Assets"
// Step 5: Enter reason "Unable to accept responsibility", check attestation
// Step 7: Submit

// Verify
Case disclaim = [SELECT Disclaimer_Reason__c, Disclaimer_Legal_Attestation__c FROM Case WHERE Id = :caseId];
System.debug('Reason: ' + disclaim.Disclaimer_Reason__c); // "Unable to accept responsibility"
System.debug('Attestation: ' + disclaim.Disclaimer_Legal_Attestation__c); // true
```

---

## Token Validation Edge Cases

### Test Case 1: Expired Token

```apex
// Generate token with past expiration
DateTime pastDate = DateTime.now().addDays(-31);
// Modify SuccessionFormTokenGenerator.TOKEN_EXPIRATION_DAYS temporarily to -31
String expiredToken = SuccessionFormTokenGenerator.generateToken(caseId);

// Open form with expired token
// Expected: "This link has expired. Please contact support for a new link."
```

### Test Case 2: Token Reuse (One-Time Use)

```apex
// Generate token
String token = SuccessionFormTokenGenerator.generateToken(caseId);

// Submit form successfully (Token_Used__c = true)

// Attempt to open form again with same token
// Expected: "This link has already been used. Your form was previously submitted."
```

### Test Case 3: Tampered Token

```apex
// Generate valid token
String validToken = SuccessionFormTokenGenerator.generateToken(caseId);

// Manually modify token (simulate tampering)
String tamperedToken = validToken.substring(0, validToken.length() - 5) + 'XXXXX';

// Open form with tampered token
// Expected: "Invalid or corrupted token"
```

### Test Case 4: Contact Not Established

```apex
// Create case without Contact_Established__c = true
Case newCase = scenario.successionCase;
newCase.Contact_Established__c = false;
update newCase;

// Generate token
String token = SuccessionFormTokenGenerator.generateToken(newCase.Id);

// Open form
// Expected: "This form cannot be accessed at this time. Our team needs to establish contact first."
```

---

## Troubleshooting

### Issue 1: "No access token found in URL"

**Symptom**: Error message on page load

**Cause**: URL missing `?t={token}` parameter

**Fix**: Ensure URL format is `https://yourorg.force.com/succession/succession-form?t={token}`

---

### Issue 2: Guest User Permission Error

**Symptom**: "Insufficient Privileges" or blank page

**Debug**:
```bash
# Check guest user profile
sf data query \
  --query "SELECT Profile.Name, Profile.UserLicense.Name FROM User WHERE Id = '{guestUserId}'" \
  --target-org schwab-sandbox
```

**Fix**: Add Apex class access and object permissions to Guest User Profile (see Phase 4B)

---

### Issue 3: Grant Transactions Not Created

**Symptom**: Form submits successfully but no FinServ__FinancialAccountTransaction__c records

**Debug**:
```apex
// Check picklist values exist
Schema.DescribeFieldResult transactionType = FinServ__FinancialAccountTransaction__c.FinServ__TransactionType__c.getDescribe();
List<Schema.PicklistEntry> typeValues = transactionType.getPicklistValues();

Boolean hasGrant = false;
for (Schema.PicklistEntry entry : typeValues) {
    if (entry.getValue() == 'Grant') {
        hasGrant = true;
        break;
    }
}
System.debug('Grant picklist value exists: ' + hasGrant);
```

**Fix**: Add "Grant" to `FinServ__TransactionType__c` picklist

---

### Issue 4: "Total grants exceed account balance"

**Symptom**: Validation error on Step 5 (Final Grant)

**Cause**: Total grant amounts differ from account balance by >5%

**Fix**: Use "Distribute Evenly" button or manually adjust amounts until green checkmark appears

---

### Issue 5: File Upload Fails

**Symptom**: Document upload times out or fails silently

**Debug**: Check guest user ContentDocument permissions

**Fix**:
1. Setup → Guest User Profile → Object Permissions
2. Enable: ContentDocument (Create), ContentVersion (Create, Read)
3. Enable: ContentDocumentLink (Create, Read)

---

## Post-Deployment Checklist

- [ ] All 9 custom Case fields deployed and visible
- [ ] 3 Apex classes deployed (SuccessionFormTokenGenerator, SuccessionFormTokenValidator, SuccessionFormController)
- [ ] 9 LWC components deployed (30 files total)
- [ ] Experience Cloud site created ("DAF Succession Portal")
- [ ] Guest user profile configured (Apex classes, objects, fields)
- [ ] Succession form page created (`/succession-form`)
- [ ] End-to-end test completed (Final Grant pathway)
- [ ] Token validation edge cases tested (expired, reused, tampered)
- [ ] New DAF pathway tested
- [ ] Disclaim pathway tested
- [ ] Grant transaction creation verified
- [ ] Review task creation verified

---

## Integration with Existing Flows

### Flow: Case_Send_Succession_Form

**Update Required**: Modify email template to include token-based URL

```apex
// Add Invocable Action to flow after Contact_Established__c updates
SuccessionFormTokenGenerator.TokenRequest req = new SuccessionFormTokenGenerator.TokenRequest();
req.caseId = {!$Record.Id};

List<SuccessionFormTokenGenerator.TokenResult> results = SuccessionFormTokenGenerator.generateTokensForFlow(new List<SuccessionFormTokenGenerator.TokenRequest>{req});

// Use results[0].formURL in email template
```

**Email Template Update**:
```html
<p>Dear {!Contact.Name},</p>

<p>Thank you for speaking with us about the succession of the donor-advised fund account for {!Account.Name}.</p>

<p>Please complete your succession pathway recommendation using the secure link below. This link is unique to you and will expire in 30 days.</p>

<p><a href="{!Case.Succession_Form_URL__c}">Complete Succession Form</a></p>

<p>If you have questions, please contact us at 1-800-746-6216.</p>

<p>Best regards,<br/>Schwab Charitable Estate Administration Team</p>
```

---

## Architecture Decisions

### Why LWC over OmniScript?

| Factor | LWC | OmniScript |
|--------|-----|------------|
| **Licensing Cost** | $0 (native Salesforce) | Requires OmniStudio add-on |
| **Performance** | Faster (native components) | Slower (interpreted JSON) |
| **Customization** | Full control over validation/UX | Limited to OmniStudio patterns |
| **External Access** | Native Experience Cloud support | Requires additional setup |
| **Maintenance** | Standard Salesforce deployment | Requires OmniStudio expertise |
| **Testability** | Jest + Apex tests | Limited testing options |

**Winner**: LWC for external, stable use case with no licensing cost

### Why Token-Based Auth over Salesforce Login?

- **User Experience**: Successors don't need to create/remember Salesforce credentials
- **Security**: One-time use, expiring tokens prevent unauthorized access
- **Audit Trail**: Token usage tracked via `Token_Used__c`, `Form_Completed_Date__c`
- **Compliance**: HMAC signatures prevent URL tampering

---

## Related Documentation

- **BRD**: `~/Downloads/daf_succession_augmented_final_brd.md`
- **Flow Architecture**: `docs/SUCCESSION_FLOW_ARCHITECTURE.md`
- **Test Data**: `docs/test-data-factory-usage.md`
- **Multi-Successor**: `docs/MULTI_SUCCESSOR_HIERARCHY_COMPONENT.md`
- **Org Deployment Tasks**: `docs/ORG_DEPLOYMENT_TASKS.md`

---

`★ Insight: LWC implementation trades OmniStudio's low-code simplicity for production-grade control. The 9-component architecture demonstrates composition—each step is an isolated, testable unit. Token-based authentication eliminates the "create account" friction that kills form completion rates for external users.`

