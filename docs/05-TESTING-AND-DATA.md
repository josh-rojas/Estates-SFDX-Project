# 05 - Testing and Data

**Last updated: October 15, 2025**

Comprehensive guide for test data generation, multi-successor scenarios, and CumulusCI/Snowfakery implementation.

---

## Related Diagrams

- Multi-Successor Case Hierarchy (PlantUML): `diagrams/images/plantuml/multi-successor-object.png`
 - Data Model (ERD): `diagrams/images/erd/data-model.png`
- Contact Cadence – Unlock Sequence (Mermaid): `diagrams/images/mermaid/contact-cadence-sequence.png`

![Multi-Successor Case Hierarchy](diagrams/images/plantuml/multi-successor-object.png)
![Data Model](diagrams/images/erd/data-model.png)
![Contact Cadence – Unlock Sequence](diagrams/images/mermaid/contact-cadence-sequence.png)

---

## Quick Start

### Generate Test Data

```bash
# Load complete demo dataset
cci task run load_demo_ui_showcase --org schwab-sandbox

# Load specific scenarios
cci task run load_final_grant_scenario --org schwab-sandbox
cci task run load_multi_successor_scenario --org schwab-sandbox

# Verify data loaded
sf data query --query "SELECT COUNT() FROM Case WHERE RecordType.DeveloperName = 'EstateAdministration'" --target-org schwab-sandbox
```

### Validate Email Addresses

```bash
# Query Person Accounts without email
sf data query --query "SELECT Id, Name, PersonEmail FROM Account WHERE IsPersonAccount = true AND PersonEmail = null" --target-org schwab-sandbox

# Fix invalid emails
sf data update record --sobject Account --record-id <ID> --values "PersonEmail=test@schwabcharitable.org" --target-org schwab-sandbox
```

---

## Multi-Successor Testing

### Overview

A multi-successor scenario occurs when a deceased donor's DAF assets are divided among **two or more successors** with specific allocation percentages.

Diagram: Multi-Successor Case Hierarchy → `diagrams/images/plantuml/multi-successor-object.png`

**Key Characteristics:**
- Multiple `FinancialAccountRole` records with `Role = 'Successor'`
- Each successor has `SuccessorAllocation__c` percentage (must sum to 100%)
- All successors must be responsive (have contact information)
- One primary successor designated as case contact

**Example:** Patricia Williams passes away with $3.5M DAF. Her will specifies:
- 50% to granddaughter Amanda Williams
- 50% to grandson Brandon Williams

Both must be contacted and guided through succession.

---

### Data Model

```
Account (Deceased Donor: Patricia Williams)
    ├── FinancialAccount ($3.5M)
    │   ├── FinancialAccountRole (Primary Owner → Patricia)
    │   ├── FinancialAccountRole (Successor → Amanda, 50%)
    │   └── FinancialAccountRole (Successor → Brandon, 50%)
    ├── Case (Estate Administration)
    │   └── Contact: Amanda (Primary Contact)
    └── Tasks (Contact Attempts → Amanda)
```

**Key Rules:**
1. **Allocation Validation:** All successor allocations must sum to exactly 100%
2. **Contact Requirements:** All successors must have email and phone
3. **Primary Contact:** First successor becomes primary case contact
4. **Role Requirement:** Each successor needs separate `FinancialAccountRole` record
5. **No Unresponsive Successors:** Multi-successor requires ALL successors responsive

---

### Test Scenarios

#### Scenario 1: Patricia Williams (2 Successors)

```bash
# Generate complete dataset including Patricia Williams
cci task run load_demo_ui_showcase --org schwab-sandbox
```

**Setup:**
- Deceased Donor: Patricia Williams
- Successors: Amanda (50%), Brandon (50%)
- Financial Account: $3.5M DAF
- Case: Estate Administration
- Contact Cadence: Targets Amanda as primary

**Testing:**
1. Navigate to Case → Show `caseHierarchyViewer` component
2. Verify both successors display with 50% allocations
3. Record contact outcome for Amanda
4. Verify Brandon receives separate communication
5. Test independent pathway selections

---

#### Scenario 2: Harold Miller (3 Successors)

**Setup:**
- Deceased Donor: Harold Miller
- Successors: Jessica (40%), Andrew (35%), Lauren (25%)
- Financial Account: Multiple accounts
- Case: Parent case + 3 child cases

**Testing:**
1. Open parent case "Multi-Successor Coordination - Miller Estate"
2. Check Related Cases for 3 child cases
3. Verify different execution timelines per successor
4. Review cross-sibling Chatter coordination

---

### Manual Test Script

**Pre-Requisites:**
- [ ] Test data loaded (`cci task run load_multi_successor_scenario`)
- [ ] Permission sets assigned (`Succession_Management_Access`)
- [ ] Logged in as demo agent user

**Test Steps:**

1. **Verify Multi-Successor Detection:**
   - Navigate to Patricia Williams' Case
   - Open `caseHierarchyViewer` component
   - Confirm 2 successors display: Amanda (50%), Brandon (50%)
   - Verify allocation percentages sum to 100%

2. **Test Contact Cadence:**
   - Open `successionContactCadence` component
   - Record Outcome for Attempt 1: "Contact Established = YES"
   - Verify Contact_Established__c = TRUE on case
   - Verify Form_Sent_Date__c populated

3. **Test Independent Pathways:**
   - Amanda selects "Final Grant" pathway
   - Brandon selects "New DAF Account" pathway
   - Verify pathways recorded separately on child cases
   - Verify parent case shows coordination status

4. **Test Execution Coordination:**
   - Mark Amanda's pathway "In Progress"
   - Mark Brandon's pathway "Completed"
   - Verify parent case remains "In Progress" until all children complete
   - Close both child cases
   - Verify parent case auto-closes

---

### Common Issues

**Issue:** Allocations don't sum to 100%

- **Cause:** Incorrect SuccessorAllocation__c values
- **Fix:** Query roles, recalculate allocations:

```bash
sf data query --query "SELECT Id, Role, SuccessorAllocation__c FROM FinServ__FinancialAccountRole__c WHERE FinServ__FinancialAccount__c = '<ACCOUNT_ID>'"
```

**Issue:** caseHierarchyViewer shows "No successors found"

- **Cause:** Missing FinancialAccountRole records
- **Fix:** Verify roles exist with Role = "Successor"

**Issue:** Contact cadence targets wrong successor

- **Cause:** Primary contact not set correctly
- **Fix:** Verify Case.ContactId matches primary successor Contact

---

## CumulusCI & Snowfakery

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    CumulusCI Framework                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────┐         ┌──────────────────┐         │
│  │  cumulusci.yml   │────────▶│  Snowfakery      │         │
│  │  Configuration   │         │  Recipe Engine   │         │
│  └──────────────────┘         └──────────────────┘         │
│           │                            │                     │
│           ▼                            ▼                     │
│  ┌──────────────────┐         ┌──────────────────┐         │
│  │  Task Execution  │────────▶│  Data Mapping    │         │
│  │  (cci task run)  │         │  (mapping.yml)   │         │
│  └──────────────────┘         └──────────────────┘         │
│           │                            │                     │
│           └────────────┬───────────────┘                     │
│                        ▼                                     │
│              ┌──────────────────┐                           │
│              │  Salesforce Org  │                           │
│              │  (Bulk API Load) │                           │
│              └──────────────────┘                           │
└─────────────────────────────────────────────────────────────┘
```

---

### File Structure

```
Estates SFDX Project/
├── cumulusci.yml                          # CumulusCI configuration
├── datasets/                              # Test data recipes
│   ├── succession_mapping.yml             # Object → Salesforce mapping
│   ├── succession_data.recipe.yml         # Main test data recipe
│   ├── happy_path_scenario.recipe.yml     # Happy path
│   ├── sla_escalation_scenario.recipe.yml # SLA escalation
│   └── multi_successor_scenario.recipe.yml# Multiple successors
```

---

### Installation

**Prerequisites:**
- Python 3.12+
- pipx (`brew install pipx`)
- Salesforce CLI
- Authenticated org (`sf org login web`)

**Install CumulusCI:**

```bash
# Install via pipx
pipx install cumulusci

# Verify
cci version
# Expected: CumulusCI version: 4.6.0
```

**Initialize Project:**

```bash
cd "/Users/joshsmbp/Schwab Downloads/Estates SFDX Project"

# Initialize (if not done)
cci project init

# Connect org
cci org connect schwab-sandbox
```

---

### Generate Test Data Locally

```bash
# Preview data without loading to org
snowfakery succession_data.recipe.yml --output-format txt

# Generate JSON
snowfakery succession_data.recipe.yml --output-format json --output-file output.json

# Load to org
cci task run load_succession_test_data --org schwab-sandbox
```

---

### Key Snowfakery Recipes

#### succession_data.recipe.yml

**Generates:**
- **5 Deceased Donors** (Person Accounts)
  - Type = "Donor"
  - Deceased__c = true
  - Date_of_Death__c within last 90 days
  - Net worth $750K - $10M

- **5 Living Successors** (Person Accounts)
  - Type = "Prospect"
  - Responsive (has email/phone)
  - Area of Interest = "Family Philanthropy"

- **5 Financial Accounts** (DAF)
  - Balance: $50K - $5M
  - Programs: ASDAF, ISDAF, PMA

- **13 Financial Account Roles**
  - 5 Primary Owner (deceased)
  - 5 Successor (100% allocation)
  - 3 Advisor

- **5 Succession Cases**
  - Type = "Named Successor Enactment"
  - Record Type = "Estate Administration"
  - Mix of pathways: Final Grant, New DAF, Disclaim

- **10 Contact Attempt Tasks**
  - Types: Call, Email
  - Dispositions: Left Voicemail, Spoke with Contact

---

#### Email Validation Test Coverage

**Scenario 1: Invalid Email Format**

- Successor: Lisa Chen
- Email: `lisa.chen@invaliddomain` (missing TLD)
- Case: "Email Test - Invalid Email Format"
- **Expected:** Warning alert, "Send Email" disabled

**Scenario 2: No Email Address**

- Successor: Sarah Rodriguez
- Email: `null`
- Case: "Email Test - No Email Address"
- **Expected:** Warning alert, "Send Email" disabled

**Scenario 3: Opted Out**

- Successor: Emily Anderson
- Email: `emily.anderson@email.example.com`
- Opt-Out: `PersonHasOptedOutOfEmail = true`
- Case: "Email Test - Opted Out of Email"
- **Expected:** Compliance warning, "Send Email" disabled

**How to Test:**

1. Load data: `cci task run load_succession_test_data`
2. Search for "Email Test -" cases
3. Open case → Navigate to Contact Cadence tab
4. Verify warning alerts display
5. Verify "Send Email" button disabled

---

#### Execution Status Test Coverage

**Scenario 1: Settlement Pending**

- Case: "Execution Status - Settlement Pending"
- Pathway: Final Grant
- Status: `Execution_Status__c = "Settlement Pending"`
- Progress: Funds transferred, awaiting approval

**Scenario 2: New DAF In Progress**

- Case: "Execution Status - New DAF In Progress"
- Pathway: New DAF Account
- Status: `Execution_Status__c = "In Progress"`
- Progress: Transfer initiated

**Scenario 3: Disclaim On Hold**

- Case: "Execution Status - Disclaim Assets On Hold"
- Pathway: Disclaim Assets
- Status: `Execution_Status__c = "On Hold"`
- Progress: Legal documentation required

**Scenario 4: Final Grant Completed**

- Case: "Thompson Estate Succession"
- Pathway: Final Grant
- Status: `Execution_Status__c = "Completed"`
- Progress: Full lifecycle with tasks, milestones, documents

---

### Data Relationships

```
Account (Deceased Donor)
├── FinServ__FinancialAccount__c (DAF)
│   ├── FinServ__FinancialAccountRole__c (Primary Owner)
│   ├── FinServ__FinancialAccountRole__c (Successor)
│   └── FinServ__FinancialAccountRole__c (Advisor)
├── Case (Succession Case)
│   ├── Task (Contact Attempts)
│   ├── Event (Meetings)
│   └── FeedItem (Chatter Posts)
└── Contact (PersonContact - auto-created)
```

---

### Customization

**Adjust Record Counts:**

```yaml
- object: Account
  nickname: DeceasedDonor
  count: 10 # Change from 5 to 10
```

**Modify Field Values:**

```yaml
FinServ__NetWorth__c:
  random_number:
    min: 1000000 # Increase minimum
    max: 20000000 # Increase maximum
```

**Add New Scenarios:**

Create `custom_scenario.recipe.yml` and add task to `cumulusci.yml`:

```yaml
tasks:
  load_custom_scenario:
    class_path: cumulusci.tasks.bulkdata.generate_and_load_data_from_yaml.GenerateAndLoadDataFromYaml
    options:
      mapping: datasets/succession_mapping.yml
      recipe: datasets/custom_scenario.recipe.yml
```

---

## Workflow Entry Point Testing

The succession system supports **dual entry points**:

1. **Automatic Entry:** Case created with `Verification_Status__c = "Complete - Verified"` → Workflow starts immediately
2. **Manual Entry:** Agent clicks "✅ Begin Succession Processing" → Workflow starts on demand

### Test Scenario: Manual Entry

**Case:** "Workflow Test - Not Started (Manual Entry)"

**Initial State:**
- `Verification_Status__c = "Not Started"`
- `Contact_Attempt_Count__c = null`
- No Task records

**Test Steps:**

1. Load data: `cci task run load_succession_test_data`
2. Search for "Workflow Test - Not Started"
3. Open case, verify `Verification_Status__c = "Not Started"`
4. Verify no Tasks exist
5. Click "✅ Begin Succession Processing"
6. Verify `Verification_Status__c` → "Complete - Verified"
7. Wait 5-10 seconds for flow
8. Refresh page, verify Task #1 created
9. Verify `Contact_Attempt_Count__c = 1`

**Test Duplicate Prevention:**

- Click Quick Action again
- Verify **no second task created** (flow gate: `Contact_Attempt_Count__c` NOT NULL)

---

## Advanced Scenarios

### Multi-Generational Family Network

**Wilson Family:**
- Grandparent: Robert Wilson (Deceased 1995, original DAF owner)
- Parent: Patricia Wilson (Deceased 2024, inherited DAF)
- Children: Amanda & Brandon Wilson (current successors, 50% each)

**Features:**
- Multi-generational account history
- Historical FinancialAccountRole records
- 25+ year advisor relationship
- Complex inheritance with sibling successors

---

### Multiple DAF Accounts per Donor

**Harrington Family:**
- Margaret Harrington: Physician with 3 specialized DAF accounts
  - Medical Research Fund ($2.5M) - Cancer research
  - Education Excellence Fund ($1.8M) - STEM education
  - Environmental Conservation Fund ($1.2M) - Biodiversity
- Single Successor: James Harrington inherits all 3
- **Test Coverage:** Multi-account coordination, pathway consolidation

---

### Trust-Based Succession

**Thornton Family Trust:**
- Corporate Trustee: Pacific Trust & Investment Company ($50B AUM)
- Trust-Held DAF: Assets within revocable trust
- Multiple Beneficiaries: Primary (60%) + Contingent (40%)
- **Test Coverage:** Trust administration workflows, beneficiary notifications

---

### International Succession

**Dubois International:**
- French Citizen Successor: Isabelle Dubois (Paris-based)
- US-France Tax Treaty: Cross-border inheritance
- International Wire Instructions: EUR transfers to European charities
- Global Health Alliance: UK-based charity receiving grant
- **Test Coverage:** International compliance, currency exchange, tax treaties

---

## Troubleshooting

### Issue: "No such column" error

- **Cause:** Field doesn't exist or incorrect API name
- **Fix:** Verify field exists:

```bash
sf sobject describe Account --target-org schwab-sandbox | grep FieldName
```

### Issue: Lookup relationship not resolving

- **Cause:** Referenced record not created yet or nickname mismatch
- **Fix:** Check creation order and nickname spelling

### Issue: Required field missing

- **Cause:** Validation rule requires field
- **Fix:** Add field to recipe with appropriate value

### Issue: RecordType not found

- **Cause:** RecordType DeveloperName doesn't match org
- **Fix:** Query org for correct DeveloperName:

```bash
sf data query --query "SELECT DeveloperName FROM RecordType WHERE SobjectType = 'Account'" --target-org schwab-sandbox
```

---

## Best Practices

1. **Test Locally First:** Always preview before loading

```bash
snowfakery succession_data.recipe.yml --output-format txt
```

2. **Use Meaningful Nicknames:**

```yaml
nickname: DeceasedDonorMargaret  # Good
nickname: acc1                    # Bad
```

3. **Document Field Choices:**

```yaml
Type: Donor # Must be "Donor" for deceased accounts per BRD
```

4. **Validate After Load:**

```bash
sf data query --query "SELECT COUNT() FROM Case WHERE RecordType.DeveloperName = 'EstateAdministration'" --target-org schwab-sandbox
```

5. **Version Control:**

```bash
git add datasets/
git commit -m "feat: add multi-successor scenario to Snowfakery recipe"
```

---

## Resources

- **Snowfakery Documentation:** https://snowfakery.readthedocs.io/
- **CumulusCI Documentation:** https://cumulusci.readthedocs.io/
- **Faker Library:** https://faker.readthedocs.io/
- **datasets/README.md:** Complete recipe documentation with examples
- **cumulusci-snowfakery-implementation-guide.md:** Migration from TestDataFactory

---

## Key Commands Reference

```bash
# Load complete demo dataset
cci task run load_demo_ui_showcase --org schwab-sandbox

# Load specific scenarios
cci task run load_final_grant_scenario --org schwab-sandbox
cci task run load_multi_successor_scenario --org schwab-sandbox
cci task run load_sla_escalation_scenario --org schwab-sandbox

# Query data
sf data query --query "SELECT COUNT() FROM Case WHERE RecordType.DeveloperName = 'EstateAdministration'" --target-org schwab-sandbox

# Validate emails
sf data query --query "SELECT Id, Name, PersonEmail FROM Account WHERE IsPersonAccount = true AND PersonEmail = null" --target-org schwab-sandbox

# Update records
sf data update record --sobject Account --record-id <ID> --values "PersonEmail=test@schwabcharitable.org" --target-org schwab-sandbox

# Preview recipe locally
snowfakery succession_data.recipe.yml --output-format txt

# Generate JSON
snowfakery succession_data.recipe.yml --output-format json --output-file output.json
```
