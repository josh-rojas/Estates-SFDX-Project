# Succession Management System v1.0

Complete succession management solution for Schwab Charitable Fund, built on Salesforce Financial Services Cloud.

## 🎯 Overview

Automated succession processing system managing deceased donor account transitions through three distinct pathways:

- **Disclaim** - Successor declines account ownership
- **New DAF** - Open new DAF account for successor
- **Final Grant** - Distribute funds to designated charities

## ✨ Key Features

- ✅ **Multi-Pathway Processing** - Three succession pathways with guided workflows
- ✅ **Task-Based Contact Cadence** - Date-gated task system (Days 0, 5, 35, 65, 95)
- ✅ **SLA Tracking** - Real-time monitoring via list views
- ✅ **Hierarchical Case Management** - Multi-successor scenario handling
- ✅ **Demo-Optimized** - Simplified architecture for easy live demonstrations

## 📦 Components

### Apex Classes (2)

| Class                      | Purpose                                    |
| -------------------------- | ------------------------------------------ |
| `CaseHierarchyController`  | Visualize multi-successor case hierarchies |
| `ContactCadenceController` | Manage date-gated contact attempts         |

### Flow Automations (6)

| Flow                                  | Trigger                                     |
| ------------------------------------- | ------------------------------------------- |
| `Case_Create_Initial_Contact_Attempt` | Creates first contact task on case creation |
| `Task_Create_Next_Contact_Attempt`    | Auto-creates next task on completion        |
| `Task_Succession_Contact_Update`      | Circuit breaker for contact established     |
| `Case_Multiple_Successors_Handler`    | Multi-successor orchestration               |
| `Case_Send_Succession_Form`           | Form delivery automation                    |
| `Case_Succession_Segment_Transition`  | Pathway transitions                         |

### Lightning Web Components (11)

Internal agent UI components:

- `caseHierarchyViewer` - Visual case hierarchy tree for multi-successor cases
- `recordPathwaySelection` - Quick action pathway selector
- `successionAccountSummary` - Account details display
- `successionContactCadence` - **Primary UI** - Date-gated contact attempt tracker
- `successionDisclaimDetails` - Disclaim pathway form
- `successionDocumentUpload` - Document management
- `successionGrantBeneficiaries` - Beneficiary management
- `successionNewDafDetails` - New DAF pathway form
- `successionPathwaySelector` - Pathway selection wizard
- `successionReviewAndSign` - Final review & signature
- `successionSuccessorInfo` - Successor information form

### Custom Objects

**None** - Uses standard Salesforce objects only (Case, Task, Contact, Account, FinancialAccount, FinancialAccountRole)

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

5. **Load Demo Test Data** (Optional)
   ```bash
   cci task run load_demo_ui_showcase
   ```

## 📚 Documentation

| Document                                                             | Description                                                          |
| -------------------------------------------------------------------- | -------------------------------------------------------------------- |
| [CLAUDE.md](CLAUDE.md)                                               | **Primary guide** for Claude Code - Commands, architecture, patterns |
| [Architecture Overview](docs/SUCCESSION_FLOW_ARCHITECTURE.md)        | Complete flow architecture and data model                            |
| [Field Documentation](docs/field-documentation-succession.md)        | Custom field definitions                                             |
| [Multi-Successor Guide](docs/MULTI_SUCCESSOR_HIERARCHY_COMPONENT.md) | Hierarchical case management                                         |
| [Testing Guide](docs/MULTI_SUCCESSOR_TESTING_GUIDE.md)               | Testing scenarios and data generation                                |

## 🧪 Testing

### Using CumulusCI + Snowfakery

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
├── Type: "Named Successor Enactment" or "Multi-Account Succession Master"
├── Succession-specific fields (pathway, contact cadence, SLA)
└── ParentId (for multi-successor child cases)

Task (Contact Attempts)
├── Contact_Attempt_Number__c (1-5)
├── ActivityDate (date-gating)
└── Succession_Contact_Established__c (outcome)

FinancialAccountRole
├── Role: "Successor"
└── SuccessorAllocation__c (percentage)
```

### Security Model

- Permission Sets: `Succession_Management_Access`, `Succession_Field_Access`
- Field-Level Security on all succession fields
- All Apex uses `WITH USER_MODE` for proper security enforcement

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
├── classes/              # Apex classes (2)
├── flows/                # Flow definitions (6)
├── email/                # Email templates
├── lwc/                  # Lightning Web Components (11)
├── objects/              # Object metadata & fields (standard objects only)
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
