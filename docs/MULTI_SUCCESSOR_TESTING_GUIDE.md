# Multi-Successor Testing Guide

**Last Updated**: 2025-01-02  
**Purpose**: Comprehensive guide for testing multi-successor succession planning scenarios in DAF Account Succession Management

---

## Table of Contents

1. [Overview](#overview)
2. [Multi-Successor Functionality](#multi-successor-functionality)
3. [Test Data Generation](#test-data-generation)
4. [Test Scenarios](#test-scenarios)
5. [Validation Checklist](#validation-checklist)
6. [Manual Test Scripts](#manual-test-scripts)
7. [Automated Test Coverage](#automated-test-coverage)
8. [Common Issues & Troubleshooting](#common-issues--troubleshooting)

---

## Overview

### What is Multi-Successor?

A multi-successor scenario occurs when a deceased donor's Donor-Advised Fund (DAF) assets are divided among **two or more successors** with specific allocation percentages.

**Key Characteristics**:

- Multiple `FinancialAccountRole` records with `Role = 'Successor'`
- Each successor has a `SuccessorAllocation__c` percentage (must sum to 100%)
- All successors must be responsive (have contact information)
- One primary successor is designated as the case contact

### Business Context

**Example**: Patricia Williams passes away with a $3.5M DAF account. Her will specifies:

- 50% to granddaughter Amanda Williams
- 50% to grandson Brandon Williams

Both Amanda and Brandon must be contacted, informed, and guided through the succession process.

---

## Multi-Successor Functionality

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

### Key Rules

1. **Allocation Validation**: All successor allocations must sum to exactly 100%
2. **Contact Requirements**: All successors must have email and phone
3. **Primary Contact**: First successor in the list becomes the primary case contact
4. **Role Requirement**: Each successor must have a separate `FinancialAccountRole` record
5. **No Unresponsive Successors**: Multi-successor scenarios require ALL successors to be responsive

---

## Test Data Generation

### Method 1: Generate Complete Dataset (Includes Multi-Successor)

```apex
// This creates EVERYTHING including 2 multi-successor scenarios
SuccessionTestDataFactory.SuccessionTestData dataset =
    SuccessionTestDataFactory.generateCompleteDataset();

// Dataset includes:
// - Patricia Williams → Amanda (50%) + Brandon (50%)
// - Harold Miller → Jessica (40%) + Andrew (35%) + Lauren (25%)
```

### Method 2: Generate Specific Multi-Successor Scenario

```apex
// Generates Patricia Williams with 2 successors (50/50 split)
SuccessionTestDataFactory.SuccessionScenarioData scenario =
    SuccessionTestDataFactory.generateMultipleSuccessorsScenario();

// Access the data
Account deceasedDonor = scenario.deceasedDonor;         // Patricia Williams
List<Account> successors = scenario.successors;          // [Amanda, Brandon]
FinServ__FinancialAccount__c daf = scenario.financialAccount;  // $3.5M account
List<FinServ__FinancialAccountRole__c> roles = scenario.roles;  // 3 roles
Case successionCase = scenario.successionCase;          // Case linked to Amanda
```

### Method 3: Create Custom Multi-Successor Scenario

```apex
// Step 1: Create deceased donor
Account donor = new SuccessionTestDataFactory.DeceasedDonorBuilder()
    .withName('Patricia', 'Williams')
    .withNetWorth(7000000)
    .withDateOfDeath(Date.today().addDays(-40))
    .asPremierDonor()
    .buildAndInsert();

// Step 2: Create financial account
FinServ__FinancialAccount__c daf =
    new SuccessionTestDataFactory.FinancialAccountBuilder(donor.Id)
        .withName('Williams Family Foundation Fund')
        .withProgram('ASDAF')
        .withBalance(3500000)
        .buildAndInsert();

// Step 3: Create primary owner role
new SuccessionTestDataFactory.FinancialAccountRoleBuilder(daf.Id)
    .asPrimaryOwner(donor.Id)
    .buildAndInsert();

// Step 4: Create multiple successors
Account amanda = new SuccessionTestDataFactory.SuccessorBuilder()
    .withName('Amanda', 'Williams')
    .withEmail('amanda.williams@email.example.com')
    .asResponsive()
    .buildAndInsert();

Account brandon = new SuccessionTestDataFactory.SuccessorBuilder()
    .withName('Brandon', 'Williams')
    .withEmail('brandon.williams@email.example.com')
    .asResponsive()
    .buildAndInsert();

// Step 5: Create successor roles with allocations
new SuccessionTestDataFactory.FinancialAccountRoleBuilder(daf.Id)
    .asSuccessor(amanda.Id)
    .withAllocation(50)
    .buildAndInsert();

new SuccessionTestDataFactory.FinancialAccountRoleBuilder(daf.Id)
    .asSuccessor(brandon.Id)
    .withAllocation(50)
    .buildAndInsert();

// Step 6: Create case (links to first successor)
Account amandaWithContact = [SELECT Id, PersonContactId
                             FROM Account WHERE Id = :amanda.Id];

Case successionCase = new SuccessionTestDataFactory.SuccessionCaseBuilder(
    donor.Id, daf.Id)
    .withSuccessor(amandaWithContact.PersonContactId)
    .withContactAttempts(2)
    .withContactEstablished()
    .withPathway('Final Grant')
    .withFormCompleted()
    .withEstateAdministrationRecordType()
    .buildAndInsert();
```

---

## Test Scenarios

### Scenario 1: Two-Way Split (50/50)

**Persona**: Patricia Williams → Amanda & Brandon Williams

**Details**:

- Deceased: Patricia Williams (Age 88, Premier Donor)
- Financial Account: $3.5M ASDAF
- Successors:
  - Amanda Williams (50%, Granddaughter)
  - Brandon Williams (50%, Grandson)
- Pathway: Final Grant
- Status: Contact Established

**Test Coverage**:

- ✅ Both successors created
- ✅ Both have 50% allocation
- ✅ Total allocation = 100%
- ✅ Both responsive (email + phone)
- ✅ Case links to Amanda (first successor)
- ✅ Tasks created for Amanda

**Generate**:

```apex
SuccessionTestDataFactory.SuccessionScenarioData scenario =
    SuccessionTestDataFactory.generateMultipleSuccessorsScenario();
```

### Scenario 2: Three-Way Split (40/35/25)

**Persona**: Harold Miller → Jessica, Andrew & Lauren

**Details**:

- Deceased: Harold Miller (Age 92, Premier Donor)
- Financial Account: $5.2M PMA
- Successors:
  - Jessica Miller (40%, Daughter)
  - Andrew Miller (35%, Son)
  - Lauren Thompson (25%, Granddaughter, different last name)
- Pathway: Final Grant
- Status: Contact Established

**Test Coverage**:

- ✅ Three successors created
- ✅ Allocations: 40%, 35%, 25%
- ✅ Total allocation = 100%
- ✅ All responsive
- ✅ Handles different last names
- ✅ Case links to Jessica (first successor)

**Generate**:

```apex
// This is included in generateCompleteDataset()
SuccessionTestDataFactory.SuccessionTestData dataset =
    SuccessionTestDataFactory.generateCompleteDataset();

// Find Harold Miller scenario
Account harold = [SELECT Id, FirstName, LastName
                  FROM Account
                  WHERE FirstName = 'Harold' AND LastName = 'Miller'
                  LIMIT 1];
```

### Scenario 3: Unequal Split (70/30)

**Custom Test Case**:

- Deceased: John Anderson
- Financial Account: $2M ASDAF
- Successors:
  - Primary beneficiary: 70%
  - Secondary beneficiary: 30%

**Generate**:

```apex
// Use custom generation pattern (see Method 3 above)
// Set allocations to 70 and 30
```

---

## Validation Checklist

### Pre-Generation Validation

Before generating multi-successor test data, verify:

- [ ] Admin has fixed `ChooseProspectTypeOnly` validation rule
- [ ] `GroupRecordTypeMapper` custom metadata includes `IndustriesBusiness`
- [ ] `PrimaryAndJointOwnerCannotBeSame` validation rule is corrected
- [ ] PersonAccount record type is enabled
- [ ] Financial Account object is accessible

### Post-Generation Validation

After generating test data, verify:

#### Deceased Donor

- [ ] `Deceased__c = TRUE`
- [ ] `Date_of_Death__c` is populated
- [ ] `IsPersonAccount = TRUE`
- [ ] Net worth is realistic (2-3x DAF balance)

#### Successors

- [ ] Exactly N successors created (where N = expected count)
- [ ] All have `Deceased__c = FALSE`
- [ ] All have `PersonEmail` populated
- [ ] All have `PersonMobilePhone` populated
- [ ] All have correct first/last names

#### Financial Account

- [ ] Balance matches expected amount
- [ ] Program matches expected program (ASDAF, PMA, etc.)
- [ ] `FinServ__PrimaryOwner__c` links to deceased donor
- [ ] `FinServ__JointOwner__c` is null

#### Financial Account Roles

- [ ] Exactly (N+1) roles created (N successors + 1 owner)
- [ ] One role with `FinServ__Role__c = 'Primary Owner'`
- [ ] N roles with `FinServ__Role__c = 'Successor'`
- [ ] Each successor role has `SuccessorAllocation__c` populated
- [ ] Sum of all `SuccessorAllocation__c` = 100

#### Case

- [ ] `Type = 'Named Successor Enactment'`
- [ ] `RecordType = 'Estate Administration'`
- [ ] `AccountId` links to deceased donor
- [ ] `FinServ__FinancialAccount__c` links to financial account
- [ ] `ContactId` links to first successor's `PersonContactId`
- [ ] `Contact_Established__c = TRUE`
- [ ] `Pathway_Confirmed__c` is populated

#### Tasks

- [ ] Contact attempt tasks created
- [ ] All tasks link to case
- [ ] All tasks link to first successor

---

## Manual Test Scripts

### Test Script 1: Verify Two-Way Split

**Objective**: Validate Patricia Williams 50/50 split scenario

**Steps**:

1. **Generate Data**

   ```apex
   SuccessionTestDataFactory.SuccessionScenarioData scenario =
       SuccessionTestDataFactory.generateMultipleSuccessorsScenario();
   ```

2. **Verify Deceased Donor**

   ```apex
   System.debug('Deceased Donor: ' + scenario.deceasedDonor.FirstName + ' ' +
                scenario.deceasedDonor.LastName);
   System.debug('Deceased: ' + scenario.deceasedDonor.Deceased__c);
   System.debug('Date of Death: ' + scenario.deceasedDonor.Date_of_Death__c);
   ```

   **Expected**: Patricia Williams, Deceased=TRUE, Date populated

3. **Verify Successors**

   ```apex
   System.debug('Successor Count: ' + scenario.successors.size());
   for (Account s : scenario.successors) {
       System.debug('  - ' + s.FirstName + ' ' + s.LastName);
       System.debug('    Email: ' + s.PersonEmail);
       System.debug('    Phone: ' + s.PersonMobilePhone);
   }
   ```

   **Expected**: 2 successors (Amanda, Brandon), both with email and phone

4. **Verify Financial Account**

   ```apex
   System.debug('Account Name: ' + scenario.financialAccount.Name);
   System.debug('Balance: ' + scenario.financialAccount.FinServ__Balance__c);
   System.debug('Program: ' + scenario.financialAccount.Program__c);
   ```

   **Expected**: Williams Family Foundation Fund, $3.5M, ASDAF

5. **Verify Roles & Allocations**

   ```apex
   System.debug('Total Roles: ' + scenario.roles.size());
   Decimal totalAllocation = 0;
   for (FinServ__FinancialAccountRole__c role : scenario.roles) {
       System.debug('  - Role: ' + role.FinServ__Role__c);
       if (role.FinServ__Role__c == 'Successor') {
           System.debug('    Allocation: ' + role.SuccessorAllocation__c + '%');
           totalAllocation += role.SuccessorAllocation__c;
       }
   }
   System.debug('Total Allocation: ' + totalAllocation + '%');
   ```

   **Expected**: 3 roles, 2 successors with 50% each, total = 100%

6. **Verify Case**

   ```apex
   System.debug('Case Type: ' + scenario.successionCase.Type);
   System.debug('Pathway: ' + scenario.successionCase.Pathway_Confirmed__c);
   System.debug('Contact Established: ' +
                scenario.successionCase.Contact_Established__c);

   // Check which successor is linked
   Account primaryContact = [SELECT Id, FirstName, LastName, PersonContactId
                             FROM Account
                             WHERE PersonContactId = :scenario.successionCase.ContactId];
   System.debug('Primary Contact: ' + primaryContact.FirstName + ' ' +
                primaryContact.LastName);
   ```

   **Expected**: Estate Administration, Final Grant, Contact=TRUE, Contact=Amanda

7. **Run Assertions**
   ```apex
   System.assertEquals(2, scenario.successors.size());
   System.assertEquals(100, totalAllocation);
   System.assertEquals('Amanda', scenario.successors[0].FirstName);
   System.assertEquals('Brandon', scenario.successors[1].FirstName);
   ```

### Test Script 2: Verify Complete Dataset Includes Multi-Successor

**Objective**: Validate complete dataset contains multi-successor scenarios

**Steps**:

1. **Generate Complete Dataset**

   ```apex
   SuccessionTestDataFactory.SuccessionTestData dataset =
       SuccessionTestDataFactory.generateCompleteDataset();
   ```

2. **Verify Counts**

   ```apex
   System.debug('Deceased Donors: ' + dataset.deceasedDonors.size());
   System.debug('Successors: ' + dataset.successors.size());
   System.debug('Financial Accounts: ' + dataset.financialAccounts.size());
   System.debug('Roles: ' + dataset.roles.size());
   System.debug('Cases: ' + dataset.successionCases.size());
   ```

   **Expected**: 15 donors, 20 successors, 15 accounts, 54+ roles, 15 cases

3. **Find Multi-Successor Accounts**

   ```apex
   Map<Id, List<FinServ__FinancialAccountRole__c>> accountToSuccessors =
       new Map<Id, List<FinServ__FinancialAccountRole__c>>();

   for (FinServ__FinancialAccountRole__c role : dataset.roles) {
       if (role.FinServ__Role__c == 'Successor') {
           if (!accountToSuccessors.containsKey(role.FinServ__FinancialAccount__c)) {
               accountToSuccessors.put(role.FinServ__FinancialAccount__c,
                   new List<FinServ__FinancialAccountRole__c>());
           }
           accountToSuccessors.get(role.FinServ__FinancialAccount__c).add(role);
       }
   }

   Integer multiSuccessorCount = 0;
   for (Id accountId : accountToSuccessors.keySet()) {
       if (accountToSuccessors.get(accountId).size() > 1) {
           multiSuccessorCount++;
           System.debug('Multi-Successor Account: ' + accountId);
           System.debug('  Successors: ' + accountToSuccessors.get(accountId).size());
       }
   }
   System.debug('Total Multi-Successor Accounts: ' + multiSuccessorCount);
   ```

   **Expected**: At least 2 multi-successor accounts (Patricia Williams, Harold Miller)

4. **Validate Allocations**

   ```apex
   for (Id accountId : accountToSuccessors.keySet()) {
       List<FinServ__FinancialAccountRole__c> successorRoles =
           accountToSuccessors.get(accountId);

       if (successorRoles.size() > 1) {
           Decimal total = 0;
           for (FinServ__FinancialAccountRole__c role : successorRoles) {
               total += role.SuccessorAllocation__c;
           }
           System.assert(total == 100,
               'Account ' + accountId + ' allocation != 100%: ' + total);
       }
   }
   ```

   **Expected**: All multi-successor accounts have allocations summing to 100%

---

## Automated Test Coverage

### Existing Test Methods

The following test methods are already implemented in `SuccessionTestDataFactory_Test.cls`:

#### 1. `testMultipleSuccessorsScenario_TwoWaySplit()`

**Coverage**:

- ✅ Generates Patricia Williams scenario
- ✅ Verifies 2 successors created
- ✅ Verifies correct names (Amanda, Brandon)
- ✅ Verifies both responsive
- ✅ Verifies financial account details
- ✅ Verifies 3 roles (1 owner + 2 successors)
- ✅ Verifies allocation sum = 100%
- ✅ Verifies case links to first successor

**Line Numbers**: 353-401

#### 2. `testMultipleSuccessors_AllocationValidation()`

**Coverage**:

- ✅ Generates complete dataset
- ✅ Finds all multi-successor accounts
- ✅ Validates each successor has allocation > 0
- ✅ Validates total allocation = 100% per account
- ✅ Fails if any account has invalid allocations

**Line Numbers**: 403-439

#### 3. `testMultipleSuccessors_AllResponsive()`

**Coverage**:

- ✅ Generates multi-successor scenario
- ✅ Verifies all successors have email
- ✅ Verifies all successors have mobile phone
- ✅ Ensures no unresponsive successors in multi-successor scenarios

**Line Numbers**: 441-453

#### 4. `testGenerateCompleteDataset()` (Updated)

**Coverage**:

- ✅ Verifies complete dataset includes multi-successor scenarios
- ✅ Validates Patricia Williams present
- ✅ Validates Harold Miller present
- ✅ Validates correct total counts (15 donors, 20 successors, etc.)

**Line Numbers**: 300-325

### Running Tests

```bash
# Run all tests in the test class
sf apex test run --test-name SuccessionTestDataFactory_Test --synchronous \
    --result-format human --code-coverage --target-org <YOUR_ORG>

# Run only multi-successor tests
sf apex test run --test-name SuccessionTestDataFactory_Test.testMultipleSuccessorsScenario_TwoWaySplit \
    --synchronous --result-format human --target-org <YOUR_ORG>

sf apex test run --test-name SuccessionTestDataFactory_Test.testMultipleSuccessors_AllocationValidation \
    --synchronous --result-format human --target-org <YOUR_ORG>

sf apex test run --test-name SuccessionTestDataFactory_Test.testMultipleSuccessors_AllResponsive \
    --synchronous --result-format human --target-org <YOUR_ORG>
```

### Expected Test Results

| Test Method                                   | Expected Result | Code Coverage |
| --------------------------------------------- | --------------- | ------------- |
| `testMultipleSuccessorsScenario_TwoWaySplit`  | ✅ PASS         | 95%+          |
| `testMultipleSuccessors_AllocationValidation` | ✅ PASS         | 90%+          |
| `testMultipleSuccessors_AllResponsive`        | ✅ PASS         | 85%+          |
| `testGenerateCompleteDataset`                 | ✅ PASS         | 98%+          |

---

## Common Issues & Troubleshooting

### Issue 1: Validation Rule Failures

**Symptom**: Test data generation fails with validation errors

**Root Causes**:

1. `ChooseProspectTypeOnly` blocks deceased donor creation
2. `PrimaryAndJointOwnerCannotBeSame` has null=null bug
3. Missing `GroupRecordTypeMapper` custom metadata

**Solutions**: See [AUTONOMOUS_RESOLUTION_SUMMARY.md](./AUTONOMOUS_RESOLUTION_SUMMARY.md)

### Issue 2: Allocations Don't Sum to 100%

**Symptom**: Test fails with `Total allocation must equal 100%`

**Root Cause**: Manual allocation percentages provided don't sum to 100

**Solution**:

```apex
// BAD: 50 + 40 = 90%
List<Decimal> allocations = new List<Decimal>{50, 40};

// GOOD: 50 + 50 = 100%
List<Decimal> allocations = new List<Decimal>{50, 50};

// GOOD: 40 + 35 + 25 = 100%
List<Decimal> allocations = new List<Decimal>{40, 35, 25};
```

### Issue 3: Case Not Linking to Successor

**Symptom**: Case `ContactId` is null or incorrect

**Root Cause**: Need to query `PersonContactId` after Account creation

**Solution**:

```apex
// WRONG: PersonContactId not available on insert result
Account successor = new SuccessorBuilder().buildAndInsert();
Case c = new SuccessionCaseBuilder(donor.Id, daf.Id)
    .withSuccessor(successor.PersonContactId)  // ❌ This is null!
    .buildAndInsert();

// CORRECT: Query PersonContactId after insert
Account successor = new SuccessorBuilder().buildAndInsert();
Account successorWithContact = [SELECT Id, PersonContactId
                                FROM Account WHERE Id = :successor.Id];
Case c = new SuccessionCaseBuilder(donor.Id, daf.Id)
    .withSuccessor(successorWithContact.PersonContactId)  // ✅ Correct!
    .buildAndInsert();
```

### Issue 4: Unresponsive Successors in Multi-Successor Scenario

**Symptom**: Test fails because successor lacks email or phone

**Root Cause**: Used `.asUnresponsive()` or forgot to set contact info

**Solution**:

```apex
// WRONG: Unresponsive successors
Account successor = new SuccessorBuilder()
    .asUnresponsive()  // ❌ This removes email and phone
    .buildAndInsert();

// CORRECT: Responsive successors
Account successor = new SuccessorBuilder()
    .withEmail('successor@example.com')
    .asResponsive()  // ✅ Sets email and phone
    .buildAndInsert();
```

### Issue 5: Missing Roles

**Symptom**: Test expects 3 roles but only finds 1 or 2

**Root Cause**: Forgot to create successor roles or primary owner role

**Solution**:

```apex
// Ensure ALL roles are created:

// 1. Primary Owner (REQUIRED)
new FinancialAccountRoleBuilder(daf.Id)
    .asPrimaryOwner(donor.Id)
    .buildAndInsert();

// 2. Successor 1 (REQUIRED)
new FinancialAccountRoleBuilder(daf.Id)
    .asSuccessor(successor1.Id)
    .withAllocation(50)
    .buildAndInsert();

// 3. Successor 2 (REQUIRED)
new FinancialAccountRoleBuilder(daf.Id)
    .asSuccessor(successor2.Id)
    .withAllocation(50)
    .buildAndInsert();
```

---

## Summary

### Key Takeaways

1. ✅ **Multi-successor functionality is fully implemented and public**
2. ✅ **generateCompleteDataset() includes 2 multi-successor scenarios by default**
3. ✅ **Comprehensive automated tests validate all multi-successor behavior**
4. ✅ **Manual test scripts available for validation**
5. ✅ **Allocation validation ensures data integrity**

### Quick Start

**Generate multi-successor test data in 1 line**:

```apex
SuccessionTestDataFactory.SuccessionScenarioData scenario =
    SuccessionTestDataFactory.generateMultipleSuccessorsScenario();
```

**Or include in complete dataset**:

```apex
SuccessionTestDataFactory.SuccessionTestData dataset =
    SuccessionTestDataFactory.generateCompleteDataset();
```

### Next Steps

1. ✅ Run automated tests to verify implementation
2. ✅ Execute manual test scripts to validate data
3. ✅ Review validation checklist before generation
4. ⚠️ Ensure admin has fixed validation rules (see AUTONOMOUS_RESOLUTION_SUMMARY.md)

---

**Questions? Issues?**  
See [AUTONOMOUS_RESOLUTION_SUMMARY.md](./AUTONOMOUS_RESOLUTION_SUMMARY.md) for validation rule fixes and troubleshooting.
