# Snowfakery Data Model Analysis

## Estates SFDX Project - Succession Management

**Date**: 2025-01-31  
**Purpose**: Document complete object relationships and field dependencies for CumulusCI/Snowfakery implementation

---

## Object Relationship Hierarchy

```
Account (Deceased Donor - Person Account)
├── FinServ__FinancialAccount__c (DAF Account)
│   ├── FinServ__FinancialAccountRole__c (Primary Owner → Deceased Donor)
│   ├── FinServ__FinancialAccountRole__c (Successor → Living Successor)
│   └── FinServ__FinancialAccountRole__c (Advisor → Advisor Firm)
├── Case (Succession Case)
│   ├── Task (Contact Attempts)
│   ├── Event (Meetings)
│   └── FeedItem (Chatter Posts)
└── Contact (PersonContact - auto-created with Person Account)

Account (Living Successor - Person Account)
└── Contact (PersonContact - auto-created)

Account (Advisor Firm - Business Account)
```

---

## Core Objects & Key Fields

### 1. Account (Person Account - Deceased Donor)

**Record Type**: `PersonAccount`

**Critical Fields**:

- `FirstName`, `LastName`, `Salutation` - Identity
- `PersonBirthdate` - Demographics
- `Type` = "Donor" - Account classification
- `Deceased__c` = true - **REQUIRED** for succession
- `Date_of_Death__c` - **REQUIRED** triggers succession workflow
- `PersonEmail`, `PersonMobilePhone`, `PersonHomePhone` - Contact info
- `PersonMailingStreet/City/State/PostalCode/Country` - Address
- `FinServ__ClientCategory__c` - Gold/Platinum/Silver
- `FinServ__NetWorth__c` - Financial profile
- `FinServ__Status__c` = "Closed" - Account status
- `FinServ__InvestmentObjectives__c` - Investment profile
- `FinServ__RiskTolerance__c` - Risk profile
- `DAF_Accounts__c` - Count of DAF accounts
- `Self_Qualified_Premier__c` - Premier service flag (drives formula fields)

**Relationships**:

- Parent to `FinServ__FinancialAccount__c` (via `FinServ__PrimaryOwner__c`)
- Parent to `Case` (via `AccountId` and `Deceased_Donor__c`)
- Auto-creates `Contact` record (PersonContactId)

---

### 2. Account (Person Account - Living Successor)

**Record Type**: `PersonAccount`

**Critical Fields**:

- `FirstName`, `LastName`, `Salutation` - Identity
- `PersonBirthdate` - Demographics
- `Type` = "Prospect" - Account classification
- `Deceased__c` = false - **REQUIRED** (living person)
- `PersonEmail`, `PersonMobilePhone` - **REQUIRED** for contact
- `PersonMailingStreet/City/State/PostalCode/Country` - Address
- `FinServ__ClientCategory__c` - Typically "Silver"
- `Area_of_Interest__c` - "Family Philanthropy / Legacy Planning"
- `PersonHasOptedOutOfEmail` = false - Contact preferences
- `PersonDoNotCall` = false - Contact preferences

**Relationships**:

- Referenced by `FinServ__FinancialAccountRole__c` (Successor role)
- Referenced by `Case.ContactId` (via PersonContactId)
- Auto-creates `Contact` record (PersonContactId)

---

### 3. Account (Business Account - Advisor Firm)

**Record Type**: `IndustriesBusiness`

**Critical Fields**:

- `Name` - Firm name
- `Type` = "Advisor" - Account classification
- `Phone` - Contact number
- `BillingStreet/City/State/PostalCode/Country` - Address
- `AS_Segment__c` - Star/Premium/Select
- `AS_Region__c` - NY METRO, SO. CALIFORNIA, FLORIDA, etc.
- `FinServ__Status__c` = "Active" - Firm status

**Relationships**:

- Referenced by `FinServ__FinancialAccount__c.Advisor__c`
- Referenced by `FinServ__FinancialAccountRole__c` (Advisor role)

---

### 4. FinServ**FinancialAccount**c (DAF Account)

**Managed Package Object** (Financial Services Cloud)

**Critical Fields**:

- `Name` - Account name (e.g., "Thompson Family Fund")
- `FinServ__FinancialAccountNumber__c` - Unique account number (DAF-########)
- `FinServ__FinancialAccountType__c` = "DAF/Donor Advised Fund"
- `Program__c` - ASDAF, ISDAF, or PMA
- `FinServ__Status__c` - Active or "Frozen - Pending Estate Settlement"
- `FinServ__Balance__c` - Current balance (min $50,000)
- `Balance_As_Of__c` - Balance date
- `FinServ__OpenDate__c` - Account opening date
- `First_Contribution_Date__c` - First contribution
- `Most_Recent_Grant_Date__c` - Last grant date
- Grant category fields (Lifetime totals):
  - `Arts_Culture_Humanities_Lifetime__c`
  - `Education_Lifetime__c`
  - `Health_Lifetime__c`
  - `Human_Services_Lifetime__c`
  - `Religion_Related_Lifetime__c`
  - `Environmental_and_Animals_Lifetime__c`
- `FinServ__PrimaryOwner__c` - **REQUIRED** Lookup to Account (Deceased Donor)
- `FinServ__Ownership__c` = "Individual" - Ownership type
- `FinServ__JointOwner__c` - Must be null (validation rule)
- `Advisor__c` - Lookup to Account (Advisor Firm)
- `Separately_Managed_Account__c` - true if Program = PMA
- `Legacy_Account__c` - Legacy flag
- `Beneficiary_Account__c` - Beneficiary flag

**Validation Rules**:

- `PrimaryAndJointOwnerCannotBeSame` - Prevents same owner in both fields

**Relationships**:

- Child of `Account` (via `FinServ__PrimaryOwner__c`)
- Parent to `FinServ__FinancialAccountRole__c`
- Referenced by `Case.FinServ__FinancialAccount__c`

---

### 5. FinServ**FinancialAccountRole**c

**Managed Package Object** (Financial Services Cloud)

**Critical Fields**:

- `FinServ__FinancialAccount__c` - **REQUIRED** Lookup to Financial Account
- `FinServ__RelatedAccount__c` - **REQUIRED** Lookup to Account
- `FinServ__Role__c` - **REQUIRED** Role type:
  - "Primary Owner" - Deceased donor
  - "Successor" - Living successor
  - "Advisor" - Advisor firm
- `FinServ__Active__c` = true - Active status
- `FinServ__StartDate__c` - Role start date
- `SuccessorAllocation__c` - Percentage allocation (for Successor roles only)

**Relationships**:

- Child of `FinServ__FinancialAccount__c`
- References `Account` (any type)

**Business Rules**:

- Multiple successors must have allocations summing to 100%
- Primary Owner role links to deceased donor
- Successor role links to living successor(s)
- Advisor role links to advisor firm

---

### 6. Case (Succession Case)

**Record Type**: `EstateAdministration`

**Critical Fields**:

- `Type` = "Named Successor Enactment" - **REQUIRED**
- `Subject` - Case title
- `Status` - New, In Progress, Closed
- `Priority` - Medium, High
- `Origin` - Phone, Email, etc.
- `AccountId` - **REQUIRED** Lookup to Account (Deceased Donor)
- `ContactId` - Lookup to Contact (Successor's PersonContactId)
- `FinServ__FinancialAccount__c` - **REQUIRED** Lookup to Financial Account
- `Deceased_Donor__c` - Lookup to Account (Deceased Donor) - redundant but used
- `Verification_Status__c` - "Complete - Verified", "Pending Verification"
- `Contact_Attempt_Count__c` - Number (1-5) - tracks contact attempts
- `Contact_Established__c` - Boolean - contact success flag
- `Contact_Established_Date__c` - DateTime - when contact made
- `Pathway_Confirmed__c` - Picklist:
  - "Not Selected" (default)
  - "Final Grant"
  - "New DAF Account"
  - "Disclaim Assets"
- `Form_Sent_Date__c` - DateTime - when form sent
- `Form_Completed_Date__c` - DateTime - when form completed
- `Next_Contact_Due__c` - Date - next scheduled contact
- `Last_Contact_Attempt__c` - DateTime - last attempt timestamp
- `Notification_Source__c` - How we learned of death
- `Description` - Case notes
- `IsEscalated` - Boolean - escalation flag
- `ClosedDate` - DateTime - case closure

**Validation Rules**:

- `Next_Contact_Due__c` required when `Contact_Established__c` = false AND `Contact_Attempt_Count__c` < 5

**Relationships**:

- Child of `Account` (via `AccountId`)
- References `Contact` (via `ContactId`)
- References `FinServ__FinancialAccount__c`
- Parent to `Task`, `Event`, `FeedItem`

**Flow Triggers**:

- `Case_Succession_Contact_Cadence` - Manages contact attempt scheduling
- `Case_Multiple_Successors_Handler` - Creates parent/child cases for multiple successors
- `Case_Succession_Critical_Escalation` - Escalates after 4+ failed attempts

---

### 7. Task (Contact Attempts)

**Record Type**: `ClientAssociateTask`

**Critical Fields**:

- `WhatId` - **REQUIRED** Lookup to Case
- `WhoId` - **REQUIRED** Lookup to Contact (Successor)
- `Subject` - Task description
- `Status` - Open, In Progress, Completed, Cancelled
- `Priority` - Normal, High
- `Type` - Call, Meeting, Other
- `TaskSubtype` - Call, Email, Task, LinkedIn
- `ActivityDate` - Date of activity
- `Contact_Attempt_Number__c` - Number (1-5) - which attempt
- `Succession_Contact_Established__c` - Boolean - success flag
- `CallType` - Internal, Inbound, Outbound
- `CallDisposition` - Left Voicemail, Spoke with Contact, No Answer
- `CallDurationInSeconds` - Duration if successful
- `Description` - Task notes

**Relationships**:

- Child of `Case` (via `WhatId`)
- References `Contact` (via `WhoId`)

**Flow Integration**:

- Completion triggers `Task_Succession_Contact_Update` flow
- Updates `Case.Contact_Attempt_Count__c`
- If `Succession_Contact_Established__c` = true, updates `Case.Contact_Established__c`

---

### 8. Event (Meetings)

**Record Type**: `ClientAssociateEvent`

**Critical Fields**:

- `WhatId` - Lookup to Case
- `WhoId` - Lookup to Contact (Successor)
- `Subject` - Meeting title
- `StartDateTime` - **REQUIRED** Start time
- `EndDateTime` - **REQUIRED** End time
- `DurationInMinutes` - Duration
- `Location` - Meeting location
- `Type` - Meeting, Client
- `ShowAs` - Busy, Free
- `Description` - Meeting notes

**Relationships**:

- Child of `Case` (via `WhatId`)
- References `Contact` (via `WhoId`)

---

### 9. FeedItem (Chatter Posts)

**Standard Object**

**Critical Fields**:

- `ParentId` - **REQUIRED** Lookup to Case or Account
- `Type` = "TextPost"
- `Body` - Post content
- `Visibility` = "InternalUsers"

**Relationships**:

- Child of `Case` or `Account` (via `ParentId`)

---

## Critical Data Dependencies

### Dependency Chain for Test Data Creation

1. **Create Accounts First** (no dependencies):
   - Deceased Donor (Person Account)
   - Living Successor (Person Account)
   - Advisor Firm (Business Account)

2. **Query PersonContactId** (auto-created with Person Accounts):
   - Query `Account.PersonContactId` for Deceased Donor
   - Query `Account.PersonContactId` for Living Successor

3. **Create Financial Account** (depends on Accounts):
   - Requires `FinServ__PrimaryOwner__c` = Deceased Donor Id
   - Optional `Advisor__c` = Advisor Firm Id

4. **Create Financial Account Roles** (depends on Financial Account + Accounts):
   - Primary Owner Role: Links Financial Account → Deceased Donor
   - Successor Role: Links Financial Account → Living Successor
   - Advisor Role: Links Financial Account → Advisor Firm

5. **Create Case** (depends on Accounts + Financial Account + Contact):
   - Requires `AccountId` = Deceased Donor Id
   - Requires `FinServ__FinancialAccount__c` = Financial Account Id
   - Requires `ContactId` = Successor PersonContactId
   - Optional `Deceased_Donor__c` = Deceased Donor Id

6. **Create Tasks** (depends on Case + Contact):
   - Requires `WhatId` = Case Id
   - Requires `WhoId` = Successor PersonContactId

7. **Create Events** (depends on Case + Contact):
   - Requires `WhatId` = Case Id
   - Requires `WhoId` = Successor PersonContactId

8. **Create FeedItems** (depends on Case or Account):
   - Requires `ParentId` = Case Id or Account Id

---

## Snowfakery Implementation Notes

### Key Challenges

1. **PersonContactId Auto-Creation**:
   - Person Accounts auto-create Contact records
   - PersonContactId is NOT available immediately in Snowfakery
   - **Solution**: Use `friends` to reference the same Account, then lookup Contact separately OR use post-load SOQL

2. **Record Type Resolution**:
   - Must use `RecordType.DeveloperName` in mapping
   - Snowfakery recipe uses macro for record type names
   - Mapping file resolves via lookup table

3. **Managed Package Fields**:
   - FinServ\_\_ prefix indicates Financial Services Cloud package
   - Fields may not be customizable
   - Must respect package field constraints

4. **Validation Rules**:
   - `PrimaryAndJointOwnerCannotBeSame` on FinServ**FinancialAccount**c
   - Must explicitly set `FinServ__JointOwner__c` = null
   - `Next_Contact_Due__c` required when contact not established

5. **Formula Fields**:
   - `SC_Premier_Service_DST__c` is formula-driven
   - Cannot be set directly in test data
   - Depends on related Advisor flags

6. **Multi-Successor Scenarios**:
   - Allocations must sum to 100%
   - Requires careful Snowfakery logic
   - May trigger `Case_Multiple_Successors_Handler` flow

---

## Recommended Snowfakery Strategy

### Approach 1: Sequential Creation with Lookups (RECOMMENDED)

```yaml
# 1. Create all Accounts
- object: Account (Deceased Donors)
- object: Account (Successors)
- object: Account (Advisors)

# 2. Create Financial Accounts (lookup to Accounts)
- object: FinancialAccount
  friends:
    - Account (Deceased Donor)

# 3. Create Financial Account Roles (lookup to both)
- object: FinancialAccountRole
  friends:
    - FinancialAccount
    - Account

# 4. Create Cases (lookup to Accounts + FinancialAccount)
# NOTE: ContactId requires post-load SOQL or separate Contact creation
- object: Case
  friends:
    - Account (Deceased Donor)
    - FinancialAccount

# 5. Create Tasks/Events (lookup to Case)
- object: Task
  friends:
    - Case

# 6. Create FeedItems (lookup to Case)
- object: FeedItem
  friends:
    - Case
```

### Approach 2: Post-Load Contact Resolution

After Snowfakery loads Accounts, run SOQL to get PersonContactIds, then load Cases/Tasks/Events with correct ContactId references.

---

## Test Data Scenarios

### Scenario 1: Happy Path - Final Grant

- 1 Deceased Donor (Premier, $2.5M net worth)
- 1 Living Successor (responsive, email/phone)
- 1 Advisor Firm
- 1 Financial Account ($2.5M balance, ASDAF)
- 3 Financial Account Roles (Owner, Successor, Advisor)
- 1 Case (Contact Established, Pathway = Final Grant, Form Completed)
- 3 Tasks (1 call attempt, 1 email, 1 form review)
- 1 Event (succession planning meeting)
- 3 FeedItems (case updates)

### Scenario 2: SLA Escalation

- 1 Deceased Donor
- 1 Living Successor (unresponsive, no email/phone)
- 1 Financial Account
- 3 Financial Account Roles
- 1 Case (NOT Contact Established, 4+ attempts, IsEscalated = true)
- 4 Tasks (4 failed call attempts)
- 2 FeedItems (escalation posts)

### Scenario 3: Multiple Successors

- 1 Deceased Donor
- 2 Living Successors (50/50 split)
- 1 Financial Account
- 4 Financial Account Roles (1 Owner, 2 Successors, 1 Advisor)
- 1 Case (initial case for first successor)
- NOTE: Flow creates parent case + child case for second successor

---

## Next Steps

1. ✅ Create `cumulusci.yml` configuration
2. ✅ Create `datasets/succession_mapping.yml` mapping file
3. ✅ Create `datasets/succession_data.recipe.yml` Snowfakery recipe
4. ⏳ Test data load with `cci task run load_succession_test_data`
5. ⏳ Create scenario-specific recipes (happy_path, sla_escalation, multi_successor)
6. ⏳ Update test classes to use CumulusCI data loading
7. ⏳ Document migration from TestDataFactory to Snowfakery

---

**Document Version**: 1.0  
**Last Updated**: 2025-01-31  
**Author**: Salesforce Architecture Team
