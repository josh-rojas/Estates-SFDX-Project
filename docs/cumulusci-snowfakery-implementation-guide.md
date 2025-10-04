# CumulusCI & Snowfakery Implementation Guide

## Replacing TestDataFactory with Declarative Test Data Generation

**Project**: Estates SFDX Project - Succession Management  
**Date**: 2025-01-31  
**Author**: Salesforce Architecture Team

---

## Executive Summary

This guide documents the migration from the imperative `SuccessionTestDataFactory` Apex class (2,476 lines) to a declarative CumulusCI + Snowfakery approach for test data generation.

### Benefits of This Approach

1. **Declarative over Imperative**: YAML recipes instead of Apex code
2. **Reusability**: Same recipes work for scratch orgs, sandboxes, and tests
3. **Maintainability**: Easier to update data patterns without Apex knowledge
4. **Version Control**: Clear diffs in YAML vs. complex Apex changes
5. **Industry Standard**: CumulusCI is the Salesforce.org standard for CI/CD
6. **Separation of Concerns**: Data generation separate from test logic

---

## Architecture Overview

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
│           │                            │                     │
│           ▼                            ▼                     │
│  ┌──────────────────┐         ┌──────────────────┐         │
│  │  Task Execution  │────────▶│  Data Mapping    │         │
│  │  (cci task run)  │         │  (mapping.yml)   │         │
│  └──────────────────┘         └──────────────────┘         │
│           │                            │                     │
│           └────────────┬───────────────┘                     │
│                        │                                     │
│                        ▼                                     │
│              ┌──────────────────┐                           │
│              │  Salesforce Org  │                           │
│              │  (Bulk API Load) │                           │
│              └──────────────────┘                           │
└─────────────────────────────────────────────────────────────┘
```

---

## File Structure

```
Estates SFDX Project/
├── cumulusci.yml                          # CumulusCI configuration
├── datasets/                              # Test data recipes
│   ├── succession_mapping.yml             # Object → Salesforce mapping
│   ├── succession_data.recipe.yml         # Main test data recipe
│   ├── happy_path_scenario.recipe.yml     # Happy path scenario
│   ├── sla_escalation_scenario.recipe.yml # SLA escalation scenario
│   └── multi_successor_scenario.recipe.yml# Multiple successors scenario
├── docs/
│   ├── snowfakery-data-model-analysis.md  # Data model documentation
│   └── cumulusci-snowfakery-implementation-guide.md  # This file
└── force-app/main/default/classes/
    ├── SuccessionTestDataFactory.cls      # DEPRECATED - kept for reference
    └── SuccessionTestDataFactory_Test.cls # TO BE UPDATED
```

---

## Installation & Setup

### Prerequisites

- Python 3.12+ installed
- pipx installed (`brew install pipx`)
- Salesforce CLI installed
- Authenticated to target org (`sf org login web`)

### Step 1: Install CumulusCI

```bash
# Install CumulusCI via pipx (already done)
pipx install cumulusci

# Verify installation
cci version
# Expected: CumulusCI version: 4.6.0
```

### Step 2: Initialize CumulusCI Project

```bash
# Navigate to project root
cd "/Users/joshsmbp/Schwab Downloads/Estates SFDX Project"

# Connect CumulusCI to your org
cci org connect schwab-sandbox --default

# Verify connection
cci org list
```

### Step 3: Validate Configuration

```bash
# List available tasks
cci task list

# Verify custom tasks are registered
cci task info load_succession_test_data
```

---

## Snowfakery Recipe Structure

### Basic Syntax

```yaml
# Object definition
- object: ObjectName
  nickname: UniqueNickname # Used for references
  count: 5 # Number of records to create
  fields:
    FieldName: value
    AnotherField:
      fake: FakerMethod # Use Faker library
    PicklistField:
      random_choice:
        - Option1
        - Option2
  friends: # Relationships
    - object: RelatedObject
      nickname: RelatedNickname
```

### Key Snowfakery Features

1. **Faker Integration**: Realistic fake data

   ```yaml
   FirstName:
     fake: FirstName
   Email:
     fake: Email
   ```

2. **Random Choices**: Picklist values

   ```yaml
   Status:
     random_choice:
       - Active
       - Inactive
   ```

3. **Conditional Logic**: If/then/else

   ```yaml
   SomeField:
     if:
       - choice:
           when: ${{OtherField == 'Value'}}
           pick: ResultA
       - choice:
           pick: ResultB
   ```

4. **Relationships**: Friends pattern

   ```yaml
   friends:
     - object: Account
       nickname: DeceasedDonor
   ```

5. **Date Ranges**: Relative dates
   ```yaml
   Date_of_Death__c:
     date_between:
       start_date: -90d
       end_date: -10d
   ```

---

## Data Loading Process

### Method 1: Command Line (Development)

```bash
# Load all succession test data
cci task run load_succession_test_data --org schwab-sandbox

# Load specific scenario
cci task run load_happy_path_data --org schwab-sandbox

# Load with custom options
cci task run load_succession_test_data \
  --org schwab-sandbox \
  --num_records 10
```

### Method 2: From Apex Tests (Automated)

```apex
@IsTest
private class SuccessionTestDataFactory_Test {
  @TestSetup
  static void setupTestData() {
    // Option A: Load via CumulusCI task (requires external process)
    // Not recommended for unit tests - use for integration tests

    // Option B: Use Snowfakery directly via HTTP callout
    // Requires custom Apex wrapper (see SnowfakeryDataLoader.cls)

    // Option C: Hybrid approach - load once, query in tests
    // RECOMMENDED for most scenarios
  }

  @IsTest
  static void testHappyPathScenario() {
    // Query pre-loaded data
    List<Case> successionCases = [
      SELECT Id, Type, Pathway_Confirmed__c, Contact_Established__c
      FROM Case
      WHERE
        Type = 'Named Successor Enactment'
        AND Pathway_Confirmed__c = 'Final Grant'
      LIMIT 1
    ];

    System.assertEquals(
      1,
      successionCases.size(),
      'Should have happy path case'
    );
    System.assertEquals(true, successionCases[0].Contact_Established__c);
  }
}
```

### Method 3: CI/CD Pipeline (GitHub Actions)

```yaml
# .github/workflows/test.yml
name: Run Tests with CumulusCI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Install CumulusCI
        run: pip install cumulusci

      - name: Create Scratch Org
        run: cci org scratch dev test-org

      - name: Deploy Metadata
        run: cci task run deploy --org test-org

      - name: Load Test Data
        run: cci task run load_succession_test_data --org test-org

      - name: Run Apex Tests
        run: cci task run run_tests --org test-org

      - name: Delete Scratch Org
        run: cci org scratch_delete test-org
```

---

## Migration Strategy

### Phase 1: Parallel Operation (CURRENT)

- Keep `SuccessionTestDataFactory.cls` (mark as `@Deprecated`)
- Create Snowfakery recipes alongside
- Update NEW tests to use Snowfakery
- Existing tests continue using factory

### Phase 2: Gradual Migration

- Identify test classes using factory
- Update one test class at a time
- Validate test coverage remains ≥75%
- Document any behavioral differences

### Phase 3: Complete Cutover

- Remove `@TestSetup` methods using factory
- Delete `SuccessionTestDataFactory.cls`
- Update all documentation
- Train team on Snowfakery approach

---

## Test Class Migration Example

### Before (Using TestDataFactory)

```apex
@IsTest
private class MySuccessionTest {
  @TestSetup
  static void setup() {
    // 50+ lines of Apex code
    SuccessionTestDataFactory.SuccessionScenarioData scenario = SuccessionTestDataFactory.generateHappyPathFinalGrant();

    // Manual assertions on setup data
    System.assertNotEquals(null, scenario.deceasedDonor);
    System.assertNotEquals(null, scenario.financialAccount);
  }

  @IsTest
  static void testSuccessionWorkflow() {
    // Query data created in setup
    Case successionCase = [SELECT Id FROM Case LIMIT 1];

    Test.startTest();
    // Test logic
    Test.stopTest();

    // Assertions
  }
}
```

### After (Using Snowfakery)

```apex
@IsTest
private class MySuccessionTest {
  // No @TestSetup needed - data loaded externally

  @IsTest
  static void testSuccessionWorkflow() {
    // Query pre-loaded data by characteristics
    Case successionCase = [
      SELECT Id, Type, Pathway_Confirmed__c
      FROM Case
      WHERE
        Type = 'Named Successor Enactment'
        AND Pathway_Confirmed__c = 'Final Grant'
        AND Contact_Established__c = TRUE
      LIMIT 1
    ];

    System.assertNotEquals(
      null,
      successionCase,
      'Happy path case should exist'
    );

    Test.startTest();
    // Test logic
    Test.stopTest();

    // Assertions
  }
}
```

---

## Troubleshooting

### Issue: "No such column" error in mapping

**Cause**: Field doesn't exist in org or incorrect API name

**Solution**:

```bash
# Query org to verify field exists
cci task run run_soql_query \
  --query "SELECT Id, FieldName__c FROM ObjectName LIMIT 1" \
  --org schwab-sandbox
```

### Issue: "Required field missing" error

**Cause**: Snowfakery recipe missing required field

**Solution**: Check object metadata

```bash
# Describe object
sf sobject describe Account --target-org schwab-sandbox
```

### Issue: Lookup relationship not resolving

**Cause**: Referenced record not created yet or nickname mismatch

**Solution**: Verify creation order in recipe

```yaml
# Create parent first
- object: Account
  nickname: ParentAccount

# Then child with reference
- object: ChildObject
  friends:
    - object: Account
      nickname: ParentAccount # Must match exactly
```

### Issue: PersonContactId not available

**Cause**: Person Account auto-creates Contact, but ID not immediately available

**Solution**: Use post-load SOQL or separate Contact creation

```yaml
# Option 1: Query after Account creation
# (Requires custom post-load script)

# Option 2: Reference Account in mapping
# Mapping file handles PersonContactId lookup
```

---

## Best Practices

### 1. Use Meaningful Nicknames

```yaml
# Good
- object: Account
  nickname: DeceasedDonorMargaret

# Bad
- object: Account
  nickname: acc1
```

### 2. Leverage Macros for Constants

```yaml
# Define once
- macro: EstateAdminRecordType
  value: EstateAdministration

# Use everywhere
RecordType.DeveloperName: ${{EstateAdminRecordType}}
```

### 3. Keep Recipes Focused

- One recipe per scenario
- Separate base data from scenario-specific data
- Use recipe includes for shared patterns

### 4. Document Field Choices

```yaml
Type: Donor # Must be "Donor" for deceased accounts per BRD
Deceased__c: true # Required to trigger succession workflow
```

### 5. Validate Data After Load

```bash
# Run validation queries
cci task run run_soql_query \
  --query "SELECT COUNT() FROM Case WHERE Type = 'Named Successor Enactment'" \
  --org schwab-sandbox
```

---

## Performance Considerations

### Bulk API Limits

- CumulusCI uses Bulk API 2.0
- Default batch size: 200 records
- Adjust in `cumulusci.yml` if needed:

```yaml
tasks:
  load_succession_test_data:
    options:
      batch_size: 100 # Reduce if hitting limits
```

### Record Count Guidelines

- **Unit Tests**: 5-10 records per object
- **Integration Tests**: 50-100 records per object
- **Performance Tests**: 1000+ records per object

### Optimization Tips

1. **Minimize Lookups**: Use `friends` pattern efficiently
2. **Batch Related Records**: Create in logical groups
3. **Disable Triggers**: Use `Apex_Trigger_Switch__mdt` during load
4. **Parallel Loading**: CumulusCI handles automatically

---

## Maintenance & Updates

### Updating Recipes

1. Modify YAML file
2. Test locally: `cci task run load_succession_test_data --org dev`
3. Commit changes
4. CI/CD validates automatically

### Adding New Scenarios

1. Create new recipe file: `datasets/new_scenario.recipe.yml`
2. Add task to `cumulusci.yml`:
   ```yaml
   tasks:
     load_new_scenario:
       class_path: cumulusci.tasks.bulkdata.generate_and_load_data_from_yaml.GenerateAndLoadDataFromYaml
       options:
         mapping: datasets/succession_mapping.yml
         recipe: datasets/new_scenario.recipe.yml
   ```
3. Document in this guide

### Versioning

- Tag recipe versions in git
- Document breaking changes
- Maintain backward compatibility when possible

---

## Resources

### Official Documentation

- [CumulusCI Documentation](https://cumulusci.readthedocs.io/)
- [Snowfakery Documentation](https://snowfakery.readthedocs.io/)
- [Salesforce Bulk API 2.0](https://developer.salesforce.com/docs/atlas.en-us.api_asynch.meta/api_asynch/)

### Internal Resources

- [Data Model Analysis](./snowfakery-data-model-analysis.md)
- [BRD Document](../docs/product/daf-account-succession-brd.md)
- [Test Data Plan](../docs/test-data-plan-succession.md)

### Community

- [CumulusCI Trailblazer Community](https://trailhead.salesforce.com/trailblazer-community/groups/0F94S000000kHi2SAE)
- [Snowfakery GitHub](https://github.com/SFDO-Tooling/Snowfakery)

---

## Appendix A: Complete Task Reference

### Available CumulusCI Tasks

```bash
# List all tasks
cci task list

# Get task details
cci task info <task_name>

# Run task
cci task run <task_name> --org <org_alias>
```

### Custom Tasks (Defined in cumulusci.yml)

| Task Name                   | Description                       | Recipe File                           |
| --------------------------- | --------------------------------- | ------------------------------------- |
| `load_succession_test_data` | Load complete succession dataset  | `succession_data.recipe.yml`          |
| `load_happy_path_data`      | Load happy path scenario only     | `happy_path_scenario.recipe.yml`      |
| `load_multi_successor_data` | Load multiple successors scenario | `multi_successor_scenario.recipe.yml` |
| `load_sla_escalation_data`  | Load SLA escalation scenario      | `sla_escalation_scenario.recipe.yml`  |

---

## Appendix B: Faker Methods Reference

Common Faker methods used in recipes:

| Method          | Example Output           | Use Case           |
| --------------- | ------------------------ | ------------------ |
| `FirstName`     | "Margaret"               | Person first names |
| `LastName`      | "Thompson"               | Person last names  |
| `Email`         | "margaret@example.com"   | Email addresses    |
| `PhoneNumber`   | "(555) 123-4567"         | Phone numbers      |
| `Company`       | "Pacific Heritage Group" | Business names     |
| `StreetAddress` | "123 Main St"            | Street addresses   |
| `City`          | "San Francisco"          | City names         |
| `Postcode`      | "94102"                  | Postal codes       |
| `RandomNumber`  | 42                       | Numeric values     |

Full list: [Faker Documentation](https://faker.readthedocs.io/)

---

## Appendix C: Migration Checklist

- [ ] CumulusCI installed and configured
- [ ] Org connected: `cci org connect schwab-sandbox`
- [ ] Mapping file created and validated
- [ ] Base recipe created and tested
- [ ] Scenario recipes created
- [ ] Test data loaded successfully
- [ ] Test classes identified for migration
- [ ] First test class migrated and passing
- [ ] All test classes migrated
- [ ] TestDataFactory marked `@Deprecated`
- [ ] Documentation updated
- [ ] Team trained on new approach
- [ ] CI/CD pipeline updated
- [ ] TestDataFactory deleted

---

**Document Version**: 1.0  
**Last Updated**: 2025-01-31  
**Next Review**: 2025-04-30
