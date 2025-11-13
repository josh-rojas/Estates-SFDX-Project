# Succession Management System v1.0

Complete succession management solution for Schwab Charitable Fund, built on Salesforce Financial Services Cloud.

## ⚠️ Current Automation Status

**Primary automation is trigger-based via Apex.** All flows present in this repository are marked as `Inactive` in source control. The system uses `SuccessionCaseTrigger` → `SuccessionTaskGenerator` for pathway task automation.

See [Architecture](#-architecture) section below for details.

## 🎯 Overview

Automated succession processing system managing deceased donor account transitions through three distinct pathways:

- **Disclaim** - Successor declines account ownership
- **New DAF** - Open new DAF account for successor
- **Final Grant** - Distribute funds to designated charities

## ✨ Key Features

- ✅ **Multi-Pathway Processing** - Three succession pathways with guided workflows
- ✅ **Trigger-Based Task Automation** - Pathway tasks auto-created via Apex trigger
- ✅ **Task-Based Contact Cadence** - Date-gated task system (Days 0, 5, 35, 65, 95)
- ✅ **SLA Tracking** - Real-time monitoring via list views (24h, 8h, 24h, 30d, 60d)
- ✅ **Hierarchical Case Management** - Multi-successor scenario handling
- ✅ **Demo-Optimized** - Simplified architecture for easy live demonstrations

## 📦 Components

### Apex Classes (Production: 8)

| Class                            | Purpose                                                    |
| -------------------------------- | ---------------------------------------------------------- |
| `CaseHierarchyController`        | Visualize multi-successor case hierarchies                 |
| `ContactCadenceController`       | Manage date-gated contact attempts                         |
| `CreateSuccessionCaseController` | Multi-successor case creation & validation                 |
| `SuccessionChatterPoster`        | Invocable Apex for Chatter notifications                   |
| `SuccessionPublicFormController` | Guest user form submission handler                         |
| `SuccessionTaskCreator`          | Invocable Apex for contact task creation                   |
| `SuccessionTaskGenerator`        | **PRIMARY AUTOMATION** - Pathway task creation via trigger |
| `SuccessionUtilities`            | Shared utility class (email, Chatter, etc)                 |

**Note:** Additional test classes exist in the codebase (e.g., `*_Test.cls`, `*Test.cls`).

### Trigger (1)

| Trigger                 | Purpose                                                             |
| ----------------------- | ------------------------------------------------------------------- |
| `SuccessionCaseTrigger` | Fires `SuccessionTaskGenerator` when `Pathway_Confirmed__c` changes |

**File:** `force-app/main/default/triggers/SuccessionCaseTrigger.trigger`

### Flow Automations (5 - All Inactive in Source Control)

**⚠️ All flows in this repository are marked as `Inactive` and exist for documentation/legacy reference only. Do NOT activate them for the standard demo path.**

| Flow                                       | Intended Purpose (if active)                     |
| ------------------------------------------ | ------------------------------------------------ |
| `Succession_Start_Contact_Process`         | Would create first contact task on case creation |
| `Succession_Schedule_Next_Contact`         | Would auto-create next task on completion        |
| `Succession_Mark_Contact_Established`      | Would set contact established flag               |
| `Succession_Close_Multi_Successor_Parent`  | Would auto-close parent cases                    |
| `Succession_Update_Case_Status_And_Notify` | Would update case status and post Chatter        |

**File Location:** `force-app/main/default/flows/`

**Legacy Flow Name Mapping:**

- Old docs may reference `Case_Create_Initial_Contact_Attempt` → now `Succession_Start_Contact_Process` (Inactive)
- Old docs may reference `Task_Create_Next_Contact_Attempt` → now `Succession_Schedule_Next_Contact` (Inactive)
- Old docs may reference `Case_Status_Coordination` → functionality in `Succession_Update_Case_Status_And_Notify` (Inactive)

### Lightning Web Components (Core Set)

| Component                  | Purpose                                                                         | File Path                                              |
| -------------------------- | ------------------------------------------------------------------------------- | ------------------------------------------------------ |
| `caseHierarchyViewer`      | Visual case hierarchy tree for multi-successor cases                            | `force-app/main/default/lwc/caseHierarchyViewer/`      |
| `createSuccessionCase`     | Quick action for creating succession cases                                      | `force-app/main/default/lwc/createSuccessionCase/`     |
| `recordPathwaySelection`   | **KEY COMPONENT** - Quick action pathway selector (sets `Pathway_Confirmed__c`) | `force-app/main/default/lwc/recordPathwaySelection/`   |
| `successionContactCadence` | **Primary UI** - Date-gated contact attempt tracker                             | `force-app/main/default/lwc/successionContactCadence/` |
| `successionPublicForm`     | Guest user pathway selection form                                               | `force-app/main/default/lwc/successionPublicForm/`     |

### Pathway Task Automation (Apex-Based)

**Replaces Action Plan Templates** - Tasks are now created via Apex trigger instead of Action Plan metadata.

When `Pathway_Confirmed__c` is set on a Case, `SuccessionCaseTrigger` fires and `SuccessionTaskGenerator` creates pathway-specific tasks:

| Pathway         | Tasks | Timeline | Implementation                                      |
| --------------- | ----- | -------- | --------------------------------------------------- |
| Final Grant     | 5     | Day 2-20 | `SuccessionTaskGenerator.generateFinalGrantTasks()` |
| New DAF Account | 4     | Day 2-18 | `SuccessionTaskGenerator.generateNewDAFTasks()`     |
| Disclaim Assets | 4     | Day 3-20 | `SuccessionTaskGenerator.generateDisclaimTasks()`   |

**File:** `force-app/main/default/classes/SuccessionTaskGenerator.cls` (lines 102-250)  
**Security:** Uses `SYSTEM_MODE` for task creation (lines 82, 92) to enable automation

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
   sf org login web --alias schwab-sandbox
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

### Core Documentation

| Document                                                                           | Description                                             |
| ---------------------------------------------------------------------------------- | ------------------------------------------------------- |
| [docs/00-quick-start.md](docs/00-quick-start.md)                                   | **Start here** - 5-minute setup and end-to-end test     |
| [docs/01-architecture-automation-data.md](docs/01-architecture-automation-data.md) | Complete system architecture with D2 diagrams           |
| [docs/02-components.md](docs/02-components.md)                                     | LWC and Apex class inventory with detailed descriptions |
| [docs/03-security.md](docs/03-security.md)                                         | Permission sets, Apex security modes, and compliance    |
| [docs/04-deployment-ci.md](docs/04-deployment-ci.md)                               | Deployment procedures and CI/CD with CumulusCI          |
| [docs/05-runbook.md](docs/05-runbook.md)                                           | Admin runbook for demos and troubleshooting             |
| [CLAUDE.md](CLAUDE.md)                                                             | AI assistant context and patterns                       |

### D2 Diagrams

All documentation includes embedded D2 diagrams showing architecture, automation flow, state machine, and data model.

- **Diagram sources:** `docs/diagrams/d2/*.d2`
- **Rendered diagrams:** `docs/diagrams/svg/*.svg`
- **Regenerate all:** `./scripts/render_d2.sh`
- **Documentation:** [docs/diagrams/README.md](docs/diagrams/README.md)

**Available Diagrams:**

- Component Architecture (UI → Controller → Automation → Data)
- Automation Sequence (Trigger-based pathway task creation)
- Case State Machine (4-phase workflow)
- Data Model ERD (Standard objects and relationships)

## 🧪 Testing


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

- Permission Sets: `Succession_Management_Access`, `Succession_Field_Access`, `Succession_Guest_Access`
- Field-Level Security on all succession fields
- Most Apex controllers use `WITH USER_MODE` for proper security enforcement
- **Exception:** `SuccessionTaskGenerator` uses `SYSTEM_MODE` for automated task creation (required for guest user scenarios)

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

- ✅ Most database operations use `WITH USER_MODE` (exception: `SuccessionTaskGenerator` uses `SYSTEM_MODE` for automation)
- ✅ Field-level security enforced
- ✅ Guest user access restricted to submission form only
- ✅ Permission sets control access: `Succession_Management_Access`, `Succession_Field_Access`, `Succession_Guest_Access`

## 🛠️ Development

### Project Structure

```
force-app/main/default/
├── classes/              # Apex classes (8 production + test classes)
├── triggers/             # Apex triggers (1: SuccessionCaseTrigger)
├── flows/                # Flow definitions (5 - all Inactive in source)
├── email/                # Email templates (6)
├── lwc/                  # Lightning Web Components (5 active)
├── objects/              # Object metadata & fields (standard objects only)
├── permissionsets/       # Permission sets (3)
├── quickActions/         # Quick Actions
└── [additional metadata]
```

**Note:** No `actionPlanTemplates/` directory - pathway tasks are created via `SuccessionTaskGenerator` Apex class.

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
**Last Updated:** November 2025  
**Target Org:** schwab-sandbox (josh.rojas.charfsc@schwab.com.fscjosh)
