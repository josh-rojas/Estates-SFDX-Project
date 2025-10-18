# Snowfakery Test Data Recipes

## Estates SFDX Project - Succession Management

This directory contains Snowfakery recipes for generating test data for the DAF Account Succession Management system.

---

## Quick Start

### Generate Test Data Locally

```bash
# Generate and preview data (no org load)
snowfakery succession_data.recipe.yml --output-format txt

# Generate JSON output
snowfakery succession_data.recipe.yml --output-format json --output-file output.json

# Load data into org via CumulusCI
cci task run load_succession_test_data --org schwab-sandbox
```

### Verify Data Loaded

```bash
# Count deceased donors
cci task run run_soql_query \
  --query "SELECT COUNT() FROM Account WHERE Type = 'Donor' AND Deceased__c = true" \
  --org schwab-sandbox

# Count succession cases
cci task run run_soql_query \
  --query "SELECT COUNT() FROM Case WHERE Type = 'Named Successor Enactment'" \
  --org schwab-sandbox
```

---

## Files

### `succession_mapping.yml`

**Purpose**: Maps Snowfakery-generated data to Salesforce objects

**Key Mappings**:

- `Account` → Person Accounts (Deceased Donors, Successors) & Business Accounts (Advisor Firms)
- `FinancialAccount` → `FinServ__FinancialAccount__c` (DAF accounts)
- `FinancialAccountRole` → `FinServ__FinancialAccountRole__c` (Owner, Successor, Advisor roles)
- `Case` → Succession cases with Estate Administration record type
- `Task` → Contact attempt tasks
- `Event` → Succession planning meetings
- `FeedItem` → Chatter posts

**Lookup Resolution**:

- Uses `RecordType.DeveloperName` for record type lookups
- Uses `LastName` or `Name` for Account lookups
- Uses `friends` pattern for relationship resolution

### `succession_data.recipe.yml`

**Purpose**: Main test data recipe generating complete succession scenarios

**Generated Data**:

- **5 Deceased Donors** (Person Accounts)
  - Type = "Donor"
  - Deceased\_\_c = true
  - Date_of_Death\_\_c within last 90 days
  - Net worth $750K - $10M
  - Client categories: Gold, Platinum, Silver

- **5 Living Successors** (Person Accounts)
  - Type = "Prospect"
  - Deceased\_\_c = false
  - Responsive (has email/phone)
  - Area of Interest = "Family Philanthropy / Legacy Planning"

- **3 Advisor Firms** (Business Accounts)
  - Type = "Advisor"
  - Segments: Star, Premium, Select
  - Regions: NY METRO, SO. CALIFORNIA, FLORIDA, HEARTLAND, PACIFIC NORTHWEST

- **5 Financial Accounts** (DAF)
  - Programs: ASDAF, ISDAF, PMA
  - Balance: $50K - $5M
  - Linked to deceased donors as primary owners

- **13 Financial Account Roles**
  - 5 Primary Owner roles (deceased donors)
  - 5 Successor roles (100% allocation)
  - 3 Advisor roles

- **5 Succession Cases**
  - Type = "Named Successor Enactment"
  - Record Type = "Estate Administration"
  - Contact attempts: 1-4
  - Pathways: Final Grant, New DAF Account, Disclaim Assets, Not Selected
  - Mix of contact established (true/false)

- **10 Contact Attempt Tasks**
  - Types: Call, Email
  - Statuses: Completed
  - Contact attempt numbers: 1-4
  - Call dispositions: Left Voicemail, Spoke with Contact, No Answer

- **3 Succession Meetings** (Events)
  - Future meetings (next 30 days)
  - Virtual meetings (Zoom)
  - 60-minute duration

- **5 Chatter Posts** (FeedItems)
  - Posted on Cases
  - Internal visibility
  - Succession-related updates

---

## Data Relationships

```
Account (Deceased Donor)
├── FinServ__FinancialAccount__c (DAF)
│   ├── FinServ__FinancialAccountRole__c (Primary Owner → Deceased Donor)
│   ├── FinServ__FinancialAccountRole__c (Successor → Living Successor)
│   └── FinServ__FinancialAccountRole__c (Advisor → Advisor Firm)
├── Case (Succession Case)
│   ├── Task (Contact Attempts)
│   ├── Event (Meetings)
│   └── FeedItem (Chatter Posts)
└── Contact (PersonContact - auto-created)

Account (Living Successor)
└── Contact (PersonContact - auto-created)

Account (Advisor Firm)
```

---

## Customization

### Adjust Record Counts

Edit the `count` parameter in the recipe:

```yaml
- object: Account
  nickname: DeceasedDonor
  count: 10 # Change from 5 to 10
```

### Modify Field Values

Edit field definitions:

```yaml
FinServ__NetWorth__c:
  random_number:
    min: 1000000 # Increase minimum
    max: 20000000 # Increase maximum
```

### Add New Scenarios

Create a new recipe file (e.g., `custom_scenario.recipe.yml`) and add a task to `cumulusci.yml`:

```yaml
tasks:
  load_custom_scenario:
    class_path: cumulusci.tasks.bulkdata.generate_and_load_data_from_yaml.GenerateAndLoadDataFromYaml
    options:
      mapping: datasets/succession_mapping.yml
      recipe: datasets/custom_scenario.recipe.yml
```

---

## Email Validation Test Coverage

The succession system enforces strict email validation and compliance requirements to prevent legal violations (CAN-SPAM, GDPR) and improve user experience. Test data includes scenarios to verify all validation states.

### Test Scenarios

#### 1. Invalid Email Format (`succession_data.recipe.yml`)

**Successor**: `Successor_InvalidEmail` (Lisa Chen)  
**Email**: `lisa.chen@invaliddomain` (missing TLD)  
**Case**: "Email Test - Invalid Email Format"

**Expected Behavior**:
- Email warning alert appears: "Email address format appears invalid: lisa.chen@invaliddomain"
- "Send Email" button disabled
- Format validation regex fails: `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`

#### 2. No Email Address (`succession_data.recipe.yml`)

**Successor**: `Successor_NoEmail` (Sarah Rodriguez)  
**Email**: `null`  
**Case**: "Email Test - No Email Address"

**Expected Behavior**:
- Email warning alert appears: "No email address on file for this successor"
- "Send Email" button disabled
- Email existence check fails

#### 3. Opted Out of Email (`succession_data.recipe.yml`)

**Successor**: `Successor_OptedOut` (Emily Anderson)  
**Email**: `emily.anderson@email.example.com` (valid format)  
**Opt-Out Status**: `PersonHasOptedOutOfEmail = true`  
**Case**: "Email Test - Opted Out of Email"

**Expected Behavior**:
- Email warning alert appears: "⚠️ Successor has opted out of email. Contact by phone only."
- "Send Email" button disabled
- **CRITICAL**: Compliance enforcement prevents legal violations

#### 4. Unresponsive Successor with Multiple Issues (`sla_escalation_scenario.recipe.yml`)

**Successor**: `Successor_Sean_Unresponsive` (Sean O'Connor)  
**Email**: `null`  
**Opt-Out Status**: `PersonHasOptedOutOfEmail = true`  
**Case**: "Succession - OConnor Estate (ESCALATED)"

**Expected Behavior**:
- Combines null email + opted-out status
- Tests worst-case email validation scenario
- Agent must use phone contact only

### How to Test Email Validation

1. **Load test data**:
   ```bash
   cci task run load_succession_test_data --org schwab-sandbox
   ```

2. **Navigate to test cases**:
   - Search for "Email Test -" in Cases list view
   - Open case → Navigate to "Contact Cadence" tab
   - Verify email warning alert displays at top
   - Verify "Send Email" button is disabled

3. **Test valid email scenario**:
   - Open any standard case (e.g., "Thompson Estate")
   - Successor should have valid email (e.g., `jennifer.thompson@email.example.com`)
   - No warning should appear
   - "Send Email" button should be enabled

4. **Verify Business Account logic** (when implemented):
   - Business Account cases should check `Contact.Email` instead of `Account.PersonEmail`
   - Component should detect `IsPersonAccount = false`

### Email Validation Fields

- **Person Account**: `Account.PersonEmail`, `Account.HasOptedOutOfEmail`
- **Business Account**: `Contact.Email`, `Contact.HasOptedOutOfEmail`
- **Validation Method**: `ContactCadenceController.validateEmailAddress()`
- **UI Component**: `successionContactCadence` LWC

---

## Execution Status & Pathway Test Coverage

Test data includes comprehensive scenarios showing different execution statuses and pathway completions. Each scenario demonstrates realistic workflow progression from contact through final settlement.

### Test Scenarios

#### 1. Settlement Pending (`succession_data.recipe.yml`)

**Case**: "Execution Status - Settlement Pending"  
**Pathway**: Final Grant to National Education Foundation  
**Status**: `Execution_Status__c = "Settlement Pending"`  
**Progress**: Funds transferred, awaiting final approval

**Expected Behavior**:
- Case shows in "Settlement Pending" status
- `Grant_Settlement_Status__c = "Pending Review"`
- Charity contact assigned (Robert Chen)
- Shows realistic in-flight execution state

#### 2. New DAF In Progress (`succession_data.recipe.yml`)

**Case**: "Execution Status - New DAF In Progress"  
**Pathway**: New DAF Account creation  
**Status**: `Execution_Status__c = "In Progress"`  
**Progress**: Transfer initiated, account creation pending

**Expected Behavior**:
- Case shows "In Progress" status
- `Asset_Transfer_Status__c = "Transfer Initiated"`
- New DAF account number generated
- Demonstrates New DAF pathway workflow

#### 3. Disclaim Assets On Hold (`succession_data.recipe.yml`)

**Case**: "Execution Status - Disclaim Assets On Hold"  
**Pathway**: Disclaim Assets (no beneficiary)  
**Status**: `Execution_Status__c = "On Hold"`  
**Progress**: Legal documentation required

**Expected Behavior**:
- Case shows "On Hold" status
- `Asset_Transfer_Status__c = "Documentation Required"`
- Demonstrates disclaimer workflow with legal holds

#### 4. Final Grant Completed (`final_grant_scenario.recipe.yml`)

**Case**: "Thompson Estate Succession"  
**Pathway**: Final Grant to Bay Area Arts Collective  
**Status**: `Execution_Status__c = "Completed"`  
**Progress**: Full lifecycle from contact through disbursement

**Expected Behavior**:
- Complete task history (Phase 3-5 tasks)
- Milestone Chatter posts
- Document attachments (death cert, form, grant confirmation)
- Future follow-up Event
- Case closed with `Status = "Closed"`

#### 5. Multi-Successor Different Pathways (`multi_successor_scenario.recipe.yml`)

**Parent Case**: "Multi-Successor Coordination - Williams Estate"  
**Child Cases**:
- Amanda Williams: Final Grant ($1.75M) to National Education Foundation
- Brandon Williams: New DAF ($1.75M) account creation

**Expected Behavior**:
- Parent case coordinates both child cases
- Cross-sibling Chatter posts showing status updates
- Different execution timelines for each pathway
- Allocation validation (50% + 50% = 100%)

### How to Test Execution Status

1. **Load test data**:
   ```bash
   cci task run load_succession_test_data --org schwab-sandbox
   ```

2. **Check status progression**:
   - Search for "Execution Status -" in Cases list view
   - Verify each case shows correct execution status
   - Check associated Tasks, Events, and Chatter posts
   - Verify charity contacts are properly assigned

3. **Test multi-successor coordination**:
   - Open "Multi-Successor Coordination - Williams Estate"
   - Check Related Cases for child cases
   - Verify different pathways per successor
   - Review cross-sibling Chatter coordination

4. **Test complete lifecycle**:
   - Open "Thompson Estate Succession"
   - Verify all tasks completed
   - Check document attachments
   - Review milestone Chatter posts
   - Confirm case closure

### Execution Status Fields

- **Case.Status**: Overall case status (New, In Progress, Closed)
- **Execution_Status__c**: Detailed execution phase (Not Started, In Progress, Settlement Pending, Completed, On Hold)
- **Asset_Transfer_Status__c**: Transfer progress (Not Started, Transfer Initiated, Transfer Completed, Documentation Required)
- **Grant_Settlement_Status__c**: Settlement approval (Not Started, Pending Review, Approved, Funds Disbursed)
- **Execution_Completed_Date__c**: Completion timestamp
- **Pathway_Confirmed__c**: Selected succession pathway
- **Charity_Account__c**: Beneficiary charity account
- **Charity_Contact__c**: Primary charity contact

---

## Family & Advisor Relationship Networks

Test data includes sophisticated relationship networks demonstrating real-world succession scenarios.

### Multi-Generational Family Network (`succession_data.recipe.yml`)

**Wilson Family Scenario**:
- **Grandparent**: Robert Wilson (Deceased 1995, original DAF owner)
- **Parent**: Patricia Wilson (Deceased 2024, inherited DAF)
- **Children**: Amanda & Brandon Wilson (current successors, 50% each)

**Key Features**:
- Multi-generational account history
- Historical FinancialAccountRole records showing ownership transitions
- 25+ year advisor relationship (Wilson Family Advisors)
- Complex inheritance scenario with sibling successors

### Advisor Network Management

**Pacific Wealth Advisors**:
- Manages 5 client DAF accounts
- Mix of active accounts and succession cases
- Demonstrates advisor dashboard use cases
- Shows bulk case management scenarios

**Testing Family Relationships**:

1. **Load test data**:
   ```bash
   cci task run load_succession_test_data --org schwab-sandbox
   ```

2. **Explore family network**:
   - Search for "Wilson" in Accounts
   - Examine FinancialAccount roles across generations
   - Review account history and advisor relationships
   - Test succession case with family context

3. **Verify advisor network**:
   - Search for "Pacific Wealth" in Accounts
   - Check FinancialAccount roles for advisor relationships
   - Verify multiple client management

### Advanced Complex Scenarios

#### **Multiple DAF Accounts per Donor** (`succession_data.recipe.yml`)

**Harrington Family Scenario**:
- **Margaret Harrington**: Physician with 3 specialized DAF accounts
  - Medical Research Fund ($2.5M) - Cancer research focus
  - Education Excellence Fund ($1.8M) - STEM education
  - Environmental Conservation Fund ($1.2M) - Biodiversity protection
- **Single Successor**: James Harrington inherits all 3 accounts
- **Test Coverage**: Multi-account coordination, pathway consolidation

#### **Trust-Based Succession** (`succession_data.recipe.yml`)

**Thornton Family Trust Scenario**:
- **Corporate Trustee**: Pacific Trust & Investment Company ($50B AUM)
- **Trust-Held DAF**: Assets within revocable trust structure
- **Multiple Beneficiaries**: Primary (60%) + Contingent (40%)
- **Trustee Role**: Corporate trustee manages DAF administration
- **Test Coverage**: Trust administration workflows, beneficiary notifications

#### **International Succession** (`succession_data.recipe.yml`)

**Dubois International Scenario**:
- **French Citizen Successor**: Isabelle Dubois (Paris-based)
- **US-France Tax Treaty**: Cross-border inheritance requirements
- **International Wire Instructions**: EUR transfers to European charities
- **Global Health Alliance**: UK-based charity receiving grant
- **Test Coverage**: International compliance, currency exchange, tax treaties

#### **Professional Executor Involvement** (`succession_data.recipe.yml`)

**Kensington Estate Scenario**:
- **Professional Executor**: Sterling & Associates Estate Law firm
- **Fiduciary Authority**: Executor makes DAF grant decisions per will
- **Multiple Account Types**: Individual ownership + Trust-held DAFs
- **Legal Coordination**: Estate attorney coordinates with DAF administrator
- **Test Coverage**: Professional executor workflows, fiduciary authority

### Relationship Data Structure

**Person-to-Person Relationships**:
- Family inheritance chains and multi-generational successions
- Successor designations with allocation percentages
- Contact preferences and communication history
- Professional executor relationships

**Business-to-Person Relationships**:
- Advisor-client relationships (25+ year partnerships)
- Charity-beneficiary relationships (grant recipient coordination)
- Professional service provider networks (law firms, trust companies)
- Corporate trustee relationships

**Account-to-Account Relationships**:
- DAF ownership transitions and historical role changes
- Advisor firm hierarchies and client portfolio management
- Charity organization networks and grant partnerships
- Trust structures with multiple beneficiaries
- International account relationships and cross-border holdings

**Complex Inheritance Patterns**:
- Multi-account successions (3+ DAFs per donor)
- Trust-based successions with corporate trustees
- International successions with tax treaty implications
- Professional executor coordination
- Contingent beneficiary arrangements

---

## Workflow Entry Point Testing

The succession system supports **dual entry points** for starting the contact cadence workflow:

1. **Automatic Entry**: Case created with `Verification_Status__c = "Complete - Verified"` → Workflow starts immediately
2. **Manual Entry**: Agent clicks "✅ Begin Succession Processing" Quick Action → Workflow starts on demand

Test data includes scenarios to verify both entry points work correctly and prevent duplicate task creation.

### Test Scenario: "Not Started" Cases

#### Case: "Workflow Test - Not Started (Manual Entry)"

**Successor**: `Successor_NotStarted` (Ryan Taylor)  
**Deceased Donor**: `DeceasedDonor_NotStarted` (Jennifer Taylor)  
**Initial State**:
- `Verification_Status__c = "Not Started"` (default value)
- `Contact_Attempt_Count__c = null`
- `Contact_Established__c = false`
- **No Task records exist**

**Purpose**: Tests manual Quick Action entry point workflow

### How to Test Workflow Entry Points

#### Test Manual Entry (Quick Action):

1. **Load test data**:
   ```bash
   cci task run load_succession_test_data --org schwab-sandbox
   ```

2. **Navigate to "Not Started" case**:
   - Search for "Workflow Test - Not Started" in Cases
   - Open case
   - Verify `Verification_Status__c = "Not Started"`
   - Verify no Tasks exist (empty Related list)

3. **Click Quick Action**:
   - Click "✅ Begin Succession Processing" button
   - Observe `Verification_Status__c` changes to "Complete - Verified"
   - Wait 5-10 seconds for flow to execute

4. **Verify Task creation**:
   - Refresh page
   - Verify Task #1 created automatically (Subject: "Contact Attempt 1 - Initial Outreach")
   - Verify `Contact_Attempt_Count__c = 1`
   - Verify `ActivityDate = TODAY`

5. **Test duplicate prevention**:
   - Click Quick Action again (or change `Verification_Status__c` manually)
   - Verify **no second task created** (flow gate check: `Contact_Attempt_Count__c` NOT NULL)

#### Test Automatic Entry (Case Creation):

1. **Create case with "Complete - Verified" status**:
   ```bash
   # Use Salesforce UI or Data Loader
   # Set Verification_Status__c = "Complete - Verified" on create
   ```

2. **Verify immediate workflow start**:
   - Task #1 should be created automatically (no button click needed)
   - `Contact_Attempt_Count__c = 1`

### Workflow Entry Point Logic

**Flow**: `Case_Create_Initial_Contact_Attempt`  
**Trigger**: Case CREATE or UPDATE, `Verification_Status__c ISCHANGED to "Complete - Verified"`  
**Gate Check**: `Contact_Attempt_Count__c = NULL` (prevents duplicate task creation)  
**Action**: Creates Task with `Contact_Attempt_Number__c = 1`, `ActivityDate = TODAY`

**Quick Action**: Sets `Verification_Status__c = "Complete - Verified"` → Triggers flow via UPDATE

---

## Troubleshooting

### Issue: "No such column" error

**Cause**: Field doesn't exist or incorrect API name in mapping

**Solution**: Verify field exists in org

```bash
sf sobject describe Account --target-org schwab-sandbox | grep FieldName
```

### Issue: Lookup relationship not resolving

**Cause**: Referenced record not created yet or nickname mismatch

**Solution**: Check creation order and nickname spelling in recipe

### Issue: Required field missing

**Cause**: Salesforce validation rule requires field

**Solution**: Add field to recipe with appropriate value

### Issue: RecordType not found

**Cause**: RecordType DeveloperName doesn't match org

**Solution**: Query org for correct DeveloperName

```bash
cci task run run_soql_query \
  --query "SELECT DeveloperName FROM RecordType WHERE SobjectType = 'Account'" \
  --org schwab-sandbox
```

---

## Best Practices

1. **Test Locally First**: Always test recipe generation before loading to org

   ```bash
   snowfakery succession_data.recipe.yml --output-format txt
   ```

2. **Use Meaningful Nicknames**: Makes recipes easier to understand

   ```yaml
   nickname: DeceasedDonorMargaret  # Good
   nickname: acc1                    # Bad
   ```

3. **Document Field Choices**: Add comments explaining business rules

   ```yaml
   Type: Donor # Must be "Donor" for deceased accounts per BRD
   ```

4. **Validate After Load**: Query org to verify data

   ```bash
   cci task run run_soql_query --query "SELECT COUNT() FROM Case" --org schwab-sandbox
   ```

5. **Version Control**: Commit recipe changes with clear messages
   ```bash
   git add datasets/
   git commit -m "feat: add multi-successor scenario to Snowfakery recipe"
   ```

---

## Resources

- [Snowfakery Documentation](https://snowfakery.readthedocs.io/)
- [CumulusCI Documentation](https://cumulusci.readthedocs.io/)
- [Faker Library](https://faker.readthedocs.io/) - For fake data generation
- [Project Implementation Guide](../docs/cumulusci-snowfakery-implementation-guide.md)
- [Data Model Analysis](../docs/snowfakery-data-model-analysis.md)

---

**Last Updated**: 2025-10-14  
**Maintained By**: Salesforce Architecture Team
