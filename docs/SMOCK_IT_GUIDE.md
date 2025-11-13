# Smock-it Test Data Generation Guide

## Overview

Smock-it is a Salesforce CLI plugin that generates synthetic test data for Salesforce orgs. This guide covers installation, configuration, and usage of smock-it for the Estate Administration system.

## Installation

### Install Smock-it Plugin

```bash
sf plugins install smock-it
```

When prompted about the unsigned plugin, type `y` to confirm installation.

### Verify Installation

```bash
sf plugins | grep smock-it
```

You should see:

```
smock-it 3.0.3
```

## Available Commands

Smock-it provides several commands for test data generation:

### Core Commands

1. **Template Initialization**

   ```bash
   sf smockit template init --default
   ```

   Creates the default directory structure and template file.

2. **Template Validation**

   ```bash
   sf smockit template validate -t <template-name> -a <org-alias>
   ```

   Validates template against Salesforce org schema.

3. **Data Generation**

   ```bash
   sf smockit data generate -t <template-name> -a <org-alias>
   ```

   Generates test data based on template configuration.

4. **Data Upload**

   ```bash
   sf smockit data upload -u <file-name> -a <org-alias> -s <sobject>
   ```

   Uploads generated data to Salesforce org.

5. **AI-Powered Template Generation**
   ```bash
   sf smockit promptify
   ```
   Generates templates using plain English prompts.

### Template Management Commands

- `sf smockit template print` - Display template contents
- `sf smockit template upsert` - Update template configurations
- `sf smockit template remove` - Remove template values

## Directory Structure

After initialization, smock-it creates the following structure:

```
data_gen/
├── templates/
│   ├── default_data_template.json
│   ├── estate_administration_template.json
│   └── estate_administration_simple.json
└── output/
    └── generated_output.json
```

## Template Configuration

### Basic Template Structure

```json
{
  "namespaceToExclude": [],
  "outputFormat": ["csv", "json"],
  "count": 10,
  "sObjects": [
    {
      "Account": {
        "count": 20,
        "fieldsToExclude": ["Fax", "Website"],
        "fieldsToConsider": {
          "PersonEmail": ["test@example.com"],
          "PersonMobilePhone": ["555-0101"]
        },
        "pickLeftFields": true
      }
    }
  ]
}
```

### Template Properties

- **namespaceToExclude**: Array of namespaces to exclude from data generation
- **outputFormat**: Output formats (csv, json, or both)
- **count**: Global default record count
- **sObjects**: Array of object configurations

### Object Configuration

Each object can specify:

- **count**: Number of records to generate
- **fieldsToExclude**: Fields to skip during generation
- **fieldsToConsider**: Specific values for fields
- **pickLeftFields**: Whether to pick leftmost fields in field list

## Estate Administration Templates

### Template 1: Comprehensive Template

**File**: `estate_administration_template.json`

Generates comprehensive test data including:

- 20 Person Accounts with email addresses
- 15 Financial Accounts (DAF accounts)
- 25 Financial Account Roles (successors)
- 12 Estate Administration Cases
- 30 Tasks (contact attempts and pathway tasks)

**Usage**:

```bash
sf smockit template validate -t estate_administration_template -a schwab-sandbox
sf smockit data generate -t estate_administration_template -a schwab-sandbox
```

**Note**: This template includes custom field values that may need adjustment based on your org's picklist values.

### Template 2: Simplified Template

**File**: `estate_administration_simple.json`

Generates basic test data with standard picklist values:

- 20 Person Accounts
- 15 Financial Accounts
- 10 Cases
- 20 Tasks

**Usage**:

```bash
sf smockit template validate -t estate_administration_simple -a schwab-sandbox
sf smockit data generate -t estate_administration_simple -a schwab-sandbox
```

**Recommended**: Start with this template for initial testing.

## Workflow

### Step 1: Initialize Templates

```bash
cd ~/repos/Estates-SFDX-Project
sf smockit template init --default
```

### Step 2: Validate Template

Before generating data, validate your template against the org:

```bash
sf smockit template validate -t estate_administration_simple -a schwab-sandbox
```

This will check:

- Object existence
- Field accessibility
- Picklist value validity
- Data type compatibility

### Step 3: Generate Data

```bash
sf smockit data generate -t estate_administration_simple -a schwab-sandbox
```

Generated files will be saved to `data_gen/output/`:

- `generated_output.json` - JSON format
- `*.csv` files - CSV format (if specified in template)

### Step 4: Review Generated Data

```bash
cat data_gen/output/generated_output.json | jq '.' | head -100
```

### Step 5: Upload Data (Optional)

To upload specific object data:

```bash
sf smockit data upload -u generated_output.json -a schwab-sandbox -s Account
```

## Troubleshooting

### Common Issues

#### 1. Picklist Value Errors

**Error**: `Value(s) 'X' not found in the picklist value set for 'Y' field`

**Solution**: Query the org to get valid picklist values:

```bash
sf sobject describe -s <Object> -o schwab-sandbox --json | grep -A 30 "picklistValues"
```

Update your template with valid values.

#### 2. Field Not Found Errors

**Error**: `Fields do not exist or cannot be accessed: X`

**Solution**:

- Verify field API names using `sf sobject describe`
- Check field-level security permissions
- For Person Accounts, use `PersonEmail`, `PersonMobilePhone`, etc. instead of standard Contact fields

#### 3. RecordType Errors

**Error**: `RecordTypeId` field validation errors

**Solution**: Remove RecordTypeId from `fieldsToConsider` or query for valid RecordType IDs:

```bash
sf data query -q "SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType='Case'" -o schwab-sandbox
```

#### 4. UserLicense Errors

**Error**: `Failed to insert records for UserLicense`

**Solution**: This is a known limitation. UserLicense is a system object that cannot be directly inserted. The error can be ignored as other data is still generated successfully.

### Validation Best Practices

1. **Always validate templates before generating data**

   ```bash
   sf smockit template validate -t <template> -a <org-alias>
   ```

2. **Start with simple templates** and gradually add complexity

3. **Query org for valid values** before adding to templates:

   ```bash
   # Get picklist values
   sf sobject describe -s Case -o schwab-sandbox --json | grep -A 50 '"name": "Status"'

   # Get existing records for reference
   sf data query -q "SELECT Id, Status, Type FROM Case LIMIT 5" -o schwab-sandbox
   ```

4. **Test with small record counts** first, then scale up

## Person Account Considerations

The Estate Administration system uses Person Accounts (Financial Services Cloud). When creating templates:

### Person Account Fields

Use these field names for Person Accounts:

- `PersonEmail` (not `Email`)
- `PersonMobilePhone` (not `MobilePhone`)
- `PersonHasOptedOutOfEmail` (not `HasOptedOutOfEmail`)
- `PersonContactId` (virtual Contact relationship)

### Example Person Account Configuration

```json
{
  "Account": {
    "count": 10,
    "fieldsToConsider": {
      "PersonEmail": ["test1@example.com", "test2@example.com"],
      "PersonMobilePhone": ["555-0101", "555-0102"],
      "PersonHasOptedOutOfEmail": [false, false]
    }
  }
}
```

## Custom Field Considerations

### Estate Administration Custom Fields

The following custom fields are available on Case objects:

- `Verification_Status__c` - Picklist
- `Contact_Established__c` - Checkbox
- `Contact_Attempt_Count__c` - Number
- `Pathway_Confirmed__c` - Picklist
- `Execution_Status__c` - Picklist
- `Deceased_Donor__c` - Lookup(Account)
- `Successor__c` - Lookup(Contact)

### Financial Account Custom Fields

- `Deceased__c` - Checkbox (on Account)
- `Date_of_Death__c` - Date (on Account)
- `SuccessorAllocation__c` - Percent (on FinancialAccountRole)

### Task Custom Fields

- `Contact_Attempt_Number__c` - Number
- `Succession_Contact_Established__c` - Checkbox

**Note**: Some custom fields may not be accessible via smock-it due to field-level security or object permissions. Verify field accessibility before adding to templates.

## Advanced Usage

### Using Promptify for AI-Generated Templates

Smock-it includes an AI-powered template generator:

```bash
sf smockit promptify
```

Example prompts:

- "Generate 100 Person Accounts with valid email addresses and phone numbers"
- "Create 50 Financial Accounts with balances between $50,000 and $1,000,000"
- "Generate Estate Administration Cases with various statuses"

### Filtering and Exclusions

Exclude specific objects or namespaces:

```json
{
  "namespaceToExclude": ["FinServ"],
  "sObjects": [
    {
      "Account": {
        "fieldsToExclude": ["Fax", "Website", "Jigsaw"]
      }
    }
  ]
}
```

### Multiple Output Formats

Generate both CSV and JSON:

```json
{
  "outputFormat": ["csv", "json"]
}
```

## Integration with Existing Test Data

The Estate Administration system already has test data generation via CumulusCI and Snowfakery:

```bash
# CumulusCI test data
cci task run load_succession_test_data

# Demo data
cci task run load_demo_ui_showcase
```

Smock-it provides an alternative approach with:

- Simpler JSON-based configuration
- Direct Salesforce CLI integration
- No Python dependencies
- Faster iteration for ad-hoc testing

## Resources

- **Smock-it GitHub**: https://github.com/concretios/smock-it
- **Smock-it Wiki**: https://github.com/concretios/smock-it/wiki
- **NPM Package**: https://www.npmjs.com/package/smock-it

## Summary

Smock-it is now installed and configured for the Estate Administration system. Two templates are available:

1. **estate_administration_template.json** - Comprehensive template with custom fields
2. **estate_administration_simple.json** - Simplified template with standard fields

Both templates are validated against the schwab-sandbox org and ready for use.

### Quick Start

```bash
# Validate template
sf smockit template validate -t estate_administration_simple -a schwab-sandbox

# Generate data
sf smockit data generate -t estate_administration_simple -a schwab-sandbox

# Review output
ls -la data_gen/output/
```
