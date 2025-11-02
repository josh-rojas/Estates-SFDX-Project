# Deployment & CI/CD

**Last Updated:** November 2, 2025  
**Version:** 1.0

---

## Overview

This document provides comprehensive deployment instructions and CI/CD guidance for the Succession Management System. The system uses Salesforce CLI (sf) for deployments and CumulusCI for advanced automation and test data generation.

---

## Prerequisites

### Required Tools

1. **Salesforce CLI (sf)**
   ```bash
   # Install via npm
   npm install -g @salesforce/cli
   
   # Verify installation
   sf --version
   ```

2. **Git**
   ```bash
   # Verify installation
   git --version
   ```

3. **Node.js & npm** (for LWC development)
   ```bash
   # Verify installation
   node --version
   npm --version
   ```

4. **CumulusCI** (optional, for advanced automation)
   ```bash
   # Install via pip
   pip install cumulusci
   
   # Verify installation
   cci version
   ```

5. **D2** (for diagram regeneration)
   ```bash
   # Install D2
   curl -fsSL https://d2lang.com/install.sh | sh -s --
   
   # Verify installation
   d2 --version
   ```

---

## Quick Deployment

### 1. Authenticate to Target Org

```bash
# Authenticate via web browser
sf org login web --alias succession-org

# Or use JWT for CI/CD
sf org login jwt --username user@example.com \
  --jwt-key-file server.key \
  --client-id <connected-app-client-id> \
  --alias succession-org
```

### 2. Deploy All Metadata

```bash
# Deploy all metadata to target org
sf project deploy start --target-org succession-org

# Or deploy specific components
sf project deploy start --source-dir force-app/main/default --target-org succession-org
```

### 3. Assign Permission Sets

```bash
# Assign permission sets to users
sf org assign permset --name Succession_Management_Access --target-org succession-org
sf org assign permset --name Succession_Field_Access --target-org succession-org
```

### 4. Load Demo Data (Optional)

```bash
# Using CumulusCI
cci task run load_demo_ui_showcase --org succession-org

# Or manually create test data via UI
```

---

## Detailed Deployment Steps

### Step 1: Clone Repository

```bash
# Clone the repository
git clone https://github.com/josh-rojas/Estates-SFDX-Project.git
cd Estates-SFDX-Project
```

### Step 2: Install Dependencies

```bash
# Install npm dependencies (for LWC development)
npm install

# Install CumulusCI (optional)
pip install cumulusci
```

### Step 3: Configure Target Org

```bash
# Authenticate to target org
sf org login web --alias succession-org --set-default

# Verify authentication
sf org display --target-org succession-org
```

### Step 4: Validate Deployment

```bash
# Validate deployment without deploying (dry run)
sf project deploy validate --manifest manifest/package.xml --target-org succession-org

# Check validation results
sf project deploy report --target-org succession-org
```

### Step 5: Deploy Metadata

```bash
# Deploy all metadata
sf project deploy start --manifest manifest/package.xml --target-org succession-org

# Monitor deployment
sf project deploy report --target-org succession-org
```

### Step 6: Post-Deployment Configuration

```bash
# Assign permission sets
sf org assign permset --name Succession_Management_Access --target-org succession-org
sf org assign permset --name Succession_Field_Access --target-org succession-org

# Create public group (if needed)
# Manual step: Setup → Public Groups → New → "Succession Management Team"

# Configure sharing rules (if needed)
# Manual step: Setup → Sharing Settings → Case Sharing Rules
```

### Step 7: Verify Deployment

```bash
# Run Apex tests
sf apex run test --test-level RunLocalTests --code-coverage --target-org succession-org

# Check test results
sf apex get test --test-run-id <test-run-id> --target-org succession-org
```

---

## Deployment Manifest

### Package.xml Structure

**File Location:** `manifest/package.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>*</members>
        <name>ApexClass</name>
    </types>
    <types>
        <members>*</members>
        <name>ApexTrigger</name>
    </types>
    <types>
        <members>*</members>
        <name>LightningComponentBundle</name>
    </types>
    <types>
        <members>*</members>
        <name>Flow</name>
    </types>
    <types>
        <members>*</members>
        <name>PermissionSet</name>
    </types>
    <types>
        <members>*</members>
        <name>CustomObject</name>
    </types>
    <types>
        <members>*</members>
        <name>EmailTemplate</name>
    </types>
    <types>
        <members>*</members>
        <name>QuickAction</name>
    </types>
    <version>65.0</version>
</Package>
```

### Deployed Components

**Apex Classes (8 production + 8 test):**
- ContactCadenceController + Test
- CreateSuccessionCaseController + Test
- SuccessionPublicFormController + Test
- CaseHierarchyController + Test
- SuccessionTaskGenerator + Test
- SuccessionTaskCreator + Test
- SuccessionChatterPoster + Test
- SuccessionUtilities + Test

**Apex Triggers (1):**
- SuccessionCaseTrigger

**Lightning Web Components (5):**
- successionContactCadence
- recordPathwaySelection
- successionPublicForm
- caseHierarchyViewer
- createSuccessionCase

**Flows (5 - Inactive):**
- Succession_Start_Contact_Process
- Succession_Schedule_Next_Contact
- Succession_Mark_Contact_Established
- Succession_Close_Multi_Successor_Parent
- Succession_Update_Case_Status_And_Notify

**Permission Sets (3):**
- Succession_Management_Access
- Succession_Field_Access
- Succession_Guest_Access

**Custom Fields:**
- Case: ~16 fields
- Task: 2 fields
- Account: 2 fields
- FinancialAccountRole: 1 field

**Email Templates (6):**
- 5 contact cadence templates
- 1 pathway form invitation template

**Quick Actions:**
- Case.Create_Succession_Case
- Case.Record_Pathway_Selection

---

## CumulusCI Deployment

### CumulusCI Configuration

**File Location:** `cumulusci.yml`

### Available Flows

```bash
# List all available flows
cci flow list

# View flow details
cci flow info deploy_succession
```

### Deploy with CumulusCI

```bash
# Connect to org
cci org connect succession-org

# Deploy metadata
cci flow run deploy_succession --org succession-org

# Deploy without test data
cci flow run deploy_succession_no_data --org succession-org
```

### Load Test Data

```bash
# Load demo data
cci task run load_demo_ui_showcase --org succession-org

# Load specific dataset
cci task run snowfakery --recipe datasets/succession_data.recipe.yml --org succession-org
```

---

## CI/CD Pipeline

### GitHub Actions (Not Currently Configured)

**Note:** CI/CD is not currently configured for this repository. Below is a recommended configuration.

**Recommended Workflow:**

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Salesforce CLI
        run: npm install -g @salesforce/cli
      
      - name: Authenticate to Dev Hub
        run: |
          echo "${{ secrets.SFDX_AUTH_URL }}" > auth.txt
          sf org login sfdx-url --sfdx-url-file auth.txt --alias devhub --set-default-dev-hub
      
      - name: Create Scratch Org
        run: sf org create scratch --definition-file config/project-scratch-def.json --alias scratch-org --set-default
      
      - name: Deploy Metadata
        run: sf project deploy start --target-org scratch-org
      
      - name: Run Apex Tests
        run: sf apex run test --test-level RunLocalTests --code-coverage --target-org scratch-org
      
      - name: Delete Scratch Org
        if: always()
        run: sf org delete scratch --target-org scratch-org --no-prompt
```

### Required Secrets

**GitHub Secrets to Configure:**
- `SFDX_AUTH_URL` - Salesforce authentication URL for Dev Hub

**Generate Auth URL:**
```bash
# Authenticate to Dev Hub
sf org login web --alias devhub --set-default-dev-hub

# Display auth URL
sf org display --verbose --target-org devhub
```

---

## Testing

### Run Apex Tests

```bash
# Run all tests
sf apex run test --test-level RunLocalTests --code-coverage --target-org succession-org

# Run specific test class
sf apex run test --tests ContactCadenceController_Test --target-org succession-org

# Run tests with detailed output
sf apex run test --test-level RunLocalTests --code-coverage --detailed-coverage --target-org succession-org
```

### Test Coverage Requirements

**Current Coverage:**
- All production classes: 100% coverage
- Overall org coverage: 95%+

**Minimum Requirements:**
- Production classes: 75% (Salesforce minimum)
- Recommended: 85%+ for production deployments

### Run LWC Tests

```bash
# Run LWC unit tests
npm run test:unit

# Run LWC tests with coverage
npm run test:unit:coverage

# Run LWC tests in watch mode
npm run test:unit:watch
```

---

## Environment-Specific Configuration

### Sandbox Deployment

```bash
# Authenticate to sandbox
sf org login web --alias sandbox --instance-url https://test.salesforce.com

# Deploy to sandbox
sf project deploy start --target-org sandbox

# Assign permission sets
sf org assign permset --name Succession_Management_Access --target-org sandbox
```

### Production Deployment

```bash
# Authenticate to production
sf org login web --alias production

# Validate deployment (required for production)
sf project deploy validate --manifest manifest/package.xml --target-org production --test-level RunLocalTests

# Deploy to production (after validation)
sf project deploy start --manifest manifest/package.xml --target-org production --test-level RunLocalTests

# Monitor deployment
sf project deploy report --target-org production
```

### Scratch Org Development

```bash
# Create scratch org
sf org create scratch --definition-file config/project-scratch-def.json --alias scratch-org --set-default --duration-days 30

# Deploy to scratch org
sf project deploy start --target-org scratch-org

# Assign permission sets
sf org assign permset --name Succession_Management_Access --target-org scratch-org

# Open scratch org
sf org open --target-org scratch-org

# Delete scratch org (when done)
sf org delete scratch --target-org scratch-org --no-prompt
```

---

## Rollback Procedures

### Rollback Strategy

**Option 1: Destructive Changes**
```bash
# Create destructive changes manifest
# File: manifest/destructiveChanges.xml

# Deploy destructive changes
sf project deploy start --manifest manifest/package.xml --post-destructive-changes manifest/destructiveChanges.xml --target-org succession-org
```

**Option 2: Restore from Backup**
```bash
# Use Salesforce Data Loader or Workbench to restore data
# Manually deactivate triggers/flows via Setup UI
```

**Option 3: Revert to Previous Version**
```bash
# Checkout previous version
git checkout <previous-commit-hash>

# Deploy previous version
sf project deploy start --target-org succession-org
```

---

## Troubleshooting

### Common Deployment Issues

**Issue:** Deployment fails with "FIELD_CUSTOM_VALIDATION_EXCEPTION"
- **Cause:** Validation rule blocking deployment
- **Solution:** Deactivate validation rules before deployment, reactivate after

**Issue:** Deployment fails with "INSUFFICIENT_ACCESS"
- **Cause:** User lacks deployment permissions
- **Solution:** Ensure user has "Modify All Data" or "Author Apex" permission

**Issue:** Apex tests fail during deployment
- **Cause:** Test data issues or code changes
- **Solution:** Run tests locally, fix failing tests, redeploy

**Issue:** LWC components not deploying
- **Cause:** Missing meta.xml files or incorrect structure
- **Solution:** Verify LWC structure (js, html, css, meta.xml files)

**Issue:** Permission sets not assigning
- **Cause:** Permission set not deployed or user not found
- **Solution:** Verify permission set deployed, check user exists

### Debug Logs

```bash
# Enable debug logs for user
sf apex log tail --target-org succession-org

# Get recent debug logs
sf apex log list --target-org succession-org

# Get specific debug log
sf apex log get --log-id <log-id> --target-org succession-org
```

---

## Diagram Regeneration

### Regenerate D2 Diagrams

```bash
# Render all diagrams with default layout (elk)
./scripts/render_d2.sh

# Render with TALA layout (if available)
D2_LAYOUT=tala ./scripts/render_d2.sh

# Render specific diagram
export PATH="$HOME/.local/bin:$PATH"
d2 --layout elk --theme 200 --pad 20 --sketch=false docs/diagrams/d2/architecture.d2 docs/diagrams/svg/architecture.svg
```

**See:** `docs/diagrams/README.md` for detailed instructions

---

## Best Practices

### Pre-Deployment Checklist

- [ ] All Apex tests passing locally
- [ ] LWC tests passing
- [ ] Code reviewed and approved
- [ ] Deployment validated in sandbox
- [ ] Permission sets configured
- [ ] Sharing rules configured
- [ ] Email templates deployed
- [ ] Quick Actions deployed
- [ ] Documentation updated

### Post-Deployment Checklist

- [ ] Apex tests passing in target org (95%+ coverage)
- [ ] Permission sets assigned to users
- [ ] Sharing rules active
- [ ] Flows activated (if needed)
- [ ] Email templates accessible
- [ ] Quick Actions visible on page layouts
- [ ] Test end-to-end workflow
- [ ] Monitor debug logs for errors

### Deployment Windows

**Recommended:**
- Sandbox: Anytime
- Production: Off-peak hours (weekends, evenings)
- Critical fixes: Coordinate with stakeholders

**Avoid:**
- During business hours (9 AM - 5 PM)
- During month-end/quarter-end processing
- During major Salesforce releases

---

## Monitoring

### Post-Deployment Monitoring

**Monitor for 24-48 hours after deployment:**

1. **Debug Logs:** Check for errors in Apex execution
2. **Flow Errors:** Monitor flow error logs (Setup → Flow Errors)
3. **User Feedback:** Collect feedback from agents
4. **Performance:** Monitor page load times and query performance
5. **Data Quality:** Verify data integrity

### Key Metrics

- **Deployment Success Rate:** % of successful deployments
- **Test Coverage:** % of code covered by tests
- **Deployment Time:** Average time to deploy
- **Rollback Rate:** % of deployments requiring rollback
- **Error Rate:** Errors per 1000 transactions

---

## Support

### Deployment Support

**For deployment issues:**
1. Check debug logs
2. Review deployment report
3. Consult troubleshooting section
4. Contact Salesforce support (if needed)

**Escalation Path:**
1. Developer → Team Lead
2. Team Lead → Architect
3. Architect → Salesforce Support

---

**Document Status:** Last verified November 2, 2025 | Commit: [current]
