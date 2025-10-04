# Succession Management System v1.0

Complete succession management solution for Schwab Charitable Fund, built on Salesforce Financial Services Cloud.

## 🎯 Overview

Automated succession processing system managing deceased donor account transitions through three distinct pathways:
- **Disclaim** - Successor declines account ownership
- **New DAF** - Open new DAF account for successor
- **Final Grant** - Distribute funds to designated charities

## ✨ Key Features

- ✅ **Multi-Pathway Processing** - Three succession pathways with guided workflows
- ✅ **Automated Contact Cadence** - Scheduled outreach (Days 0, 5, 35, 65, 95)
- ✅ **SLA Tracking** - Real-time monitoring with critical escalations
- ✅ **Secure External Forms** - Token-validated successor form submission
- ✅ **Hierarchical Case Management** - Multi-successor scenario handling
- ✅ **Experience Cloud Portal** - Self-service succession form portal
- ✅ **Comprehensive Error Handling** - Centralized logging and monitoring

## 📦 Components

### Apex Classes (8)
| Class | Purpose |
|-------|---------|
| `CaseHierarchyController` | Visualize case hierarchy relationships |
| `ContactCadenceController` | Track contact attempt history |
| `SuccessionFormController` | Process external form submissions |
| `SuccessionFormTokenGenerator` | Generate secure access tokens |
| `SuccessionFormTokenValidator` | Validate token authenticity |
| `SuccessionTestDataController` | LWC test data generation |
| `SuccessionTestDataFactory` | Apex test data factory |
| `SuccessionTestDataFactory_Test` | Factory unit tests |

### Flow Automations (9)
| Flow | Trigger |
|------|---------|
| `Case_Multiple_Successors_Handler` | Multi-successor orchestration |
| `Case_Send_Succession_Form` | Form delivery automation |
| `Case_Succession_Contact_Cadence` | Contact scheduling |
| `Case_Succession_Critical_Escalation` | Critical case escalation |
| `Case_Succession_Processing_Metrics` | Analytics tracking |
| `Case_Succession_Segment_Transition` | Pathway transitions |
| `Flow_Error_Handler` | Centralized error handling |
| `Succession_Pathway_Selection_Flow` | Pathway selection workflow |
| `Task_Succession_Contact_Update` | Contact attempt tracking |

### Lightning Web Components (13)
- `caseHierarchyViewer` - Visual case hierarchy tree
- `recordPathwaySelection` - Quick action pathway selector
- `successionAccountSummary` - Account details display
- `successionContactCadence` - Contact attempt tracker
- `successionDisclaimDetails` - Disclaim pathway form
- `successionDocumentUpload` - Document management
- `successionGrantBeneficiaries` - Beneficiary management
- `successionNewDafDetails` - New DAF pathway form
- `successionPathwayForm` - Main form container
- `successionPathwaySelector` - Pathway selection wizard
- `successionReviewAndSign` - Final review & signature
- `successionSuccessorInfo` - Successor information form
- `successionTestDataGenerator` - Test data generation UI

### Custom Objects (2)
- `Flow_Error__c` - Flow error logging with severity tracking
- `Error_Notification__e` - Platform event for error notifications

## 🚀 Quick Start

### Prerequisites
- Salesforce Financial Services Cloud
- System Administrator access
- Salesforce CLI (`sf`) installed

### Installation

1. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd "Estates SFDX Project"
   ```

2. **Authenticate to Org**
   ```bash
   sf org login web --alias succession-org
   ```

3. **Deploy Metadata**
   ```bash
   sf project deploy start --manifest manifest/package.xml
   ```

4. **Assign Permission Sets**
   ```bash
   sf org assign permset --name Succession_Management_Access
   sf org assign permset --name Succession_Field_Access
   ```

5. **Configure Experience Cloud** (See [Experience Cloud Setup](docs/EXPERIENCE_CLOUD_DEPLOYMENT.md))

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [Architecture Overview](docs/SUCCESSION_FLOW_ARCHITECTURE.md) | Complete flow architecture and data model |
| [Experience Cloud Setup](docs/EXPERIENCE_CLOUD_DEPLOYMENT.md) | Portal configuration guide |
| [Field Documentation](docs/field-documentation-succession.md) | Custom field definitions |
| [Multi-Successor Guide](docs/MULTI_SUCCESSOR_HIERARCHY_COMPONENT.md) | Hierarchical case management |
| [Testing Guide](docs/MULTI_SUCCESSOR_TESTING_GUIDE.md) | Testing scenarios and data generation |
| [Deployment Tasks](docs/ORG_DEPLOYMENT_TASKS.md) | Manual configuration steps |

## 🧪 Testing

### Generate Test Data
1. Navigate to **Succession Test Data Generator** tab
2. Select scenario:
   - Basic Succession
   - Multi-Successor
   - SLA Escalation
   - Final Grant
3. Click **Generate Data**

### Using CumulusCI (Optional)
```bash
# Load test data
cci task run snowfakery --recipe datasets/succession_data.recipe.yml

# Run all succession tests
cci task run robot --test tests/succession/
```

## 🏗️ Architecture

### Data Model
```
Case (Record Type: Estate Administration)
├── Succession-specific fields
├── Contact cadence tracking
├── SLA management
└── Pathway selection

Task/Activity
├── Contact attempt tracking
└── Succession activity types

Flow_Error__c
└── Centralized error logging

Error_Notification__e (Platform Event)
└── Real-time error notifications
```

### Security Model
- Permission Sets: `Succession_Management_Access`, `Succession_Field_Access`
- Field-Level Security on all succession fields
- Guest user permissions for Experience Cloud portal
- Token-based authentication for external forms

## 🔧 Configuration

### SLA Rules
Configure in Setup → Entitlement Processes → **Estate Succession SLA**
- Initial Response: 24 hours
- Standard Resolution: 90 days
- Critical Escalation: 80 days

### Email Templates
All templates located in `Succession_Management` and `Succession_Templates` folders

### Contact Cadence Schedule
- Day 0: Initial contact attempt
- Day 5: First follow-up
- Day 35: Second contact
- Day 65: Third contact
- Day 95: Final contact

## 📊 Monitoring

### Flow Errors
- Navigate to **Flow Errors** tab
- Review errors by severity: Critical, Warning, Info
- Track resolution status

### SLA Dashboard
- Use list views: "SLA At Risk", "SLA Critical Escalate"
- Monitor case age and contact attempt counts

## 🔐 Security

- ✅ All database operations use `WITH USER_MODE`
- ✅ Field-level security enforced
- ✅ Token-based form authentication
- ✅ Secure token generation with expiration
- ✅ Guest user access restricted to submission form only

## 🛠️ Development

### Project Structure
```
force-app/main/default/
├── classes/              # Apex classes
├── flows/                # Flow definitions
├── email/                # Email templates
├── lwc/                  # Lightning Web Components
├── objects/              # Object metadata & fields
├── experiences/          # Experience Cloud site
├── permissionsets/       # Permission sets
└── [additional metadata]
```

### Build Commands
```bash
# Deploy to sandbox
sf project deploy start --target-org sandbox

# Run Apex tests
sf apex run test --test-level RunLocalTests --code-coverage

# Validate deployment
sf project deploy validate --manifest manifest/package.xml
```

## 📈 Roadmap

- [ ] Enhanced analytics dashboard
- [ ] Mobile app support
- [ ] Multi-language support
- [ ] Integration with document management system
- [ ] Advanced workflow automation

## 👥 Support

For questions or issues:
1. Check documentation in `/docs`
2. Review Flow Error logs
3. Contact: [support contact]

## 📝 License

Proprietary - Schwab Charitable Fund

---

**Version:** 1.0.0  
**Last Updated:** October 2025  
**Target Org:** schwab-sandbox (josh.rojas.charfsc@schwab.com.fscjosh)
