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

**Last Updated**: 2025-01-31  
**Maintained By**: Salesforce Architecture Team
