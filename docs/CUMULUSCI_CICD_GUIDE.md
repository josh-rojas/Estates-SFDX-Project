# CumulusCI Deployment & CI/CD Guide

Complete guide for deploying Succession Management using CumulusCI and GitHub Actions CI/CD pipelines.

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [CumulusCI Deployment Flows](#cumulusci-deployment-flows)
- [CI/CD Pipelines](#cicd-pipelines)
- [Setup Instructions](#setup-instructions)
- [Deployment Scenarios](#deployment-scenarios)
- [Troubleshooting](#troubleshooting)

## 🚀 Quick Start

### Prerequisites

- CumulusCI installed (`pip install cumulusci`)
- Dev Hub org authenticated
- GitHub repository access (for CI/CD)

### Basic Deployment

```bash
# Connect to your org
cci org connect my-sandbox

# Deploy everything with test data
cci flow run deploy_succession --org my-sandbox

# Or deploy without test data
cci flow run deploy_succession_no_data --org my-sandbox
```

## 📦 CumulusCI Deployment Flows

### Deployment Flows

| Flow                            | Description                    | Use Case                    |
| ------------------------------- | ------------------------------ | --------------------------- |
| `deploy_succession`             | Full deployment with test data | Development/QA environments |
| `deploy_succession_no_data`     | Metadata + permissions only    | Production/Staging          |
| `deploy_succession_incremental` | Fast incremental updates       | Quick iterations            |
| `uninstall_succession`          | Remove all components          | Cleanup/reset               |

### CI/CD Flows

| Flow                    | Description               | Triggered By        |
| ----------------------- | ------------------------- | ------------------- |
| `ci_succession_feature` | Feature branch validation | PR/feature branches |
| `ci_succession_main`    | Main branch full test     | Merge to main       |
| `ci_succession_release` | Release validation        | Version tags        |

### QA/Staging Flows

| Flow             | Description                    | Use Case                  |
| ---------------- | ------------------------------ | ------------------------- |
| `qa_full_setup`  | Complete QA with all scenarios | Full QA environment       |
| `staging_deploy` | Staging with smoke tests       | Pre-production validation |

### Test Data Flows

| Flow                     | Description          | Data Loaded            |
| ------------------------ | -------------------- | ---------------------- |
| `succession_test_setup`  | Standard test data   | Basic succession cases |
| `final_grant_test_setup` | Final grant scenario | Complete pathway       |
| `demo_setup`             | UI demo data         | LWC component testing  |
| `load_all_scenarios`     | All test scenarios   | Comprehensive testing  |

## 🔄 CI/CD Pipelines

### Feature Branch Pipeline

**Trigger:** Push to `feature/**` or `bugfix/**` branches, PRs to `main`

**Workflow:** `.github/workflows/feature-ci.yml`

**Steps:**

1. ✅ Checkout code
2. ✅ Setup Python & CumulusCI
3. ✅ Create scratch org (7 days)
4. ✅ Deploy & test (`ci_succession_feature`)
5. ✅ Run code quality checks (PMD, security scan)
6. ✅ Upload test results
7. ✅ Delete scratch org

**Coverage:** 75% minimum

### Main Branch Pipeline

**Trigger:** Push to `main` branch

**Workflow:** `.github/workflows/main-ci.yml`

**Steps:**

1. ✅ Create QA scratch org (30 days)
2. ✅ Full deployment with test data
3. ✅ Run comprehensive tests
4. ✅ Generate release notes
5. ✅ **Deploy to Schwab Sandbox** (if tests pass)
6. ✅ Run smoke tests
7. ✅ Comment deployment status on commit

**Environments:**

- `qa-main`: Scratch org for validation
- `schwab-sandbox`: Persistent sandbox

### Release Pipeline

**Trigger:** Push tag `v*.*.*` or manual workflow dispatch

**Workflow:** `.github/workflows/release.yml`

**Steps:**

1. ✅ Create GitHub Release
2. ✅ Validate deployment (check-only)
3. ⚠️ **Request approval** (2 approvers required)
4. ✅ Deploy to production
5. ✅ Run production tests
6. ✅ Assign permission sets
7. ✅ Create deployment artifact
8. ✅ Notify success/failure

**Environments:**

- `production`: Production org
- `uat`: User acceptance testing
- `staging`: Pre-production

## ⚙️ Setup Instructions

### 1. Configure GitHub Secrets

Navigate to **Settings → Secrets and variables → Actions**

#### Required Secrets

| Secret             | Description               | How to Generate                   |
| ------------------ | ------------------------- | --------------------------------- |
| `DEVHUB_AUTH_URL`  | Dev Hub authentication    | `sf org display --verbose --json` |
| `SANDBOX_AUTH_URL` | Sandbox authentication    | `sf org display --verbose --json` |
| `PROD_AUTH_URL`    | Production authentication | `sf org display --verbose --json` |
| `UAT_AUTH_URL`     | UAT authentication        | `sf org display --verbose --json` |
| `PROD_APPROVERS`   | Production approvers      | `user1,user2`                     |

#### Generate Auth URL

```bash
# Authenticate to org
sf org login web --alias my-org

# Get auth URL
sf org display --target-org my-org --verbose --json

# Extract "sfdxAuthUrl" from output
```

### 2. Configure GitHub Environments

#### Sandbox Environment

- **Protection rules:** None
- **Secrets:** `SANDBOX_AUTH_URL`

#### Production Environment

- **Protection rules:**
  - ✅ Required reviewers (2 minimum)
  - ✅ Wait timer (5 minutes)
- **Secrets:** `PROD_AUTH_URL`, `PROD_APPROVERS`

#### UAT Environment

- **Protection rules:** Required reviewers (1)
- **Secrets:** `UAT_AUTH_URL`

### 3. Configure CumulusCI Locally

```bash
# Authenticate Dev Hub
sf org login web --alias devhub --set-default-dev-hub

# Connect CumulusCI
cci org connect devhub

# Verify configuration
cci project info
```

## 📖 Deployment Scenarios

### Scenario 1: New Development Environment

```bash
# Create scratch org
cci org scratch dev my-dev --default

# Deploy with test data
cci flow run deploy_succession --org my-dev

# Open org
cci org browser my-dev
```

### Scenario 2: QA Environment with All Scenarios

```bash
# Create QA scratch org (30 days)
cci org scratch qa my-qa --default

# Deploy with all test data
cci flow run qa_full_setup --org my-qa

# Verify deployment
cci org info my-qa
```

### Scenario 3: Staging Deployment

```bash
# Connect to staging
cci org connect staging

# Deploy without test data
cci flow run staging_deploy --org staging

# Run smoke tests
cci task run run_tests --org staging --test-name-match "%_TEST"
```

### Scenario 4: Production Deployment

```bash
# Connect to production
cci org connect production

# Validate deployment (check-only)
cci task run deploy --org production --path force-app/main/default --check-only

# Deploy (no test data in production)
cci flow run deploy_succession_no_data --org production

# Assign permissions
cci task run assign_permission_sets \
  --org production \
  --api-names "Succession_Management_Access,Succession_Field_Access"
```

### Scenario 5: Quick Update (Incremental)

```bash
# For rapid iteration - only deploy changed components
cci flow run deploy_succession_incremental --org my-sandbox

# This deploys:
# - Apex classes
# - LWC components
# - Flows
# - Assigns permissions
```

### Scenario 6: Uninstall/Cleanup

```bash
# Remove all succession components
cci flow run uninstall_succession --org my-sandbox

# WARNING: This is destructive!
```

## 🧪 Testing Scenarios

### Load Individual Scenarios

```bash
# Final Grant pathway
cci task run load_final_grant_scenario --org my-org

# Multi-successor case
cci task run load_multi_successor_scenario --org my-org

# SLA escalation
cci task run load_sla_escalation_scenario --org my-org

# Demo UI data
cci task run load_demo_ui_showcase --org my-org
```

### Load All Scenarios

```bash
# Load comprehensive test data
cci flow run load_all_scenarios --org my-org
```

## 🛠️ Troubleshooting

### Issue: Deployment Fails

**Solution:**

```bash
# Check deployment status
cci task info deploy

# View logs
cci org info my-org

# Retry with debug
cci flow run deploy_succession --org my-org --debug
```

### Issue: Test Coverage Below 75%

**Solution:**

```bash
# Run tests locally
cci task run run_tests --org my-org

# Check coverage
cci task run run_tests --org my-org --coverage

# Fix tests and redeploy
```

### Issue: Scratch Org Creation Fails

**Solution:**

```bash
# Verify Dev Hub
cci org info devhub

# Check scratch org limits
sf org list limits --target-org devhub

# Try with different config
cci org scratch dev my-dev --config config/project-scratch-def.json
```

### Issue: Permission Assignment Fails

**Solution:**

```bash
# Assign manually
sf org assign permset --name Succession_Management_Access
sf org assign permset --name Succession_Field_Access

# Or via CumulusCI
cci task run assign_permission_sets \
  --api-names "Succession_Management_Access,Succession_Field_Access"
```

### Issue: CI/CD Pipeline Fails

**Check:**

1. ✅ GitHub Secrets configured correctly
2. ✅ SFDX Auth URLs are valid
3. ✅ Dev Hub has scratch org capacity
4. ✅ GitHub environments set up
5. ✅ Required approvers configured

**View Logs:**

- GitHub Actions → Workflow run → Job → Step logs

## 📊 Monitoring

### Track Deployments

```bash
# List all orgs
cci org list

# Check org info
cci org info my-org

# View scratch org details
cci org scratch_list
```

### View Test Results

```bash
# Run tests with detailed output
cci task run run_tests --org my-org --json

# Generate test report
cci task run robot --org my-org --outputdir results
```

## 🔐 Security Best Practices

1. **Never commit auth URLs** - Use GitHub Secrets
2. **Rotate credentials** regularly
3. **Use separate orgs** for each environment
4. **Limit production access** - Require approvals
5. **Audit deployments** - Review logs and artifacts

## 📚 Additional Resources

- [CumulusCI Documentation](https://cumulusci.readthedocs.io/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Salesforce CLI Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/)
- [Project README](../README.md)
- [Component Inventory](SUCCESSION_COMPONENT_INVENTORY.md)

---

**Version:** 1.0  
**Last Updated:** October 2025  
**Status:** ✅ Production Ready
