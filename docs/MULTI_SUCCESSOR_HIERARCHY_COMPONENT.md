# Multi-Successor Case Hierarchy Component

## Overview

Displays parent "Multi-Account Succession Master" cases with all child cases, financial accounts, and successors in a nested, indented hierarchy.

**Visual Structure:**

```
┌─ Parent Case ─────────────────────────────────┐
│ 🔵 Multi-Successor Coordination - Patricia   │
│ Status: In Progress | DAF: DAF-12345678      │
├───────────────────────────────────────────────┤
│ ▼ Child Cases (2)                            │
│   ┌─ Child Case #1 ───────────────────────┐  │
│   │ └─ Succession - Amanda (50%)          │  │
│   │    Status: New | Verification: Not... │  │
│   │    ├─ 📊 Financial Account            │  │
│   │    │   DAF-12345678 | $2,500,000      │  │
│   │    └─ 👤 Successors:                   │  │
│   │       • Amanda Williams | 50%          │  │
│   │         Role: Primary Successor        │  │
│   └────────────────────────────────────────┘  │
└───────────────────────────────────────────────┘
```

## Components Created

### 1. DataRaptor Extract: `SuccessionCaseHierarchy`

**File**: `force-app/main/default/omniDataTransforms/SuccessionCaseHierarchy.json`

**Purpose**: Fetches hierarchical data in a single query

**Input**:

- `ParentCaseId` (String, required) - Case ID where Type = "Multi-Account Succession Master"

**Output Structure**:

```json
{
  "ParentCase": {
    "Id": "...",
    "Subject": "Multi-Successor Coordination - Patricia Williams",
    "Status": "In Progress",
    "FinServ__FinancialAccount__r": {
      "Name": "DAF-12345678",
      "FinServ__TotalBalance__c": 2500000
    }
  },
  "ChildCases": [
    {
      "Subject": "Succession - Amanda Williams (50%)",
      "Status": "New",
      "Contact": {
        "Name": "Amanda Williams",
        "Email": "amanda@example.com"
      },
      "Verification_Status__c": "Not Started",
      "SLA_Status__c": "🟢 On Track",
      "FinServ__FinancialAccount__r": {...}
    }
  ],
  "Successors": [
    {
      "FinServ__RelatedContact__r": {
        "Name": "Amanda Williams",
        "Email": "amanda@example.com"
      },
      "SuccessorAllocation__c": 50,
      "FinServ__Role__c": "Primary Successor"
    }
  ],
  "TotalChildCases": 2,
  "TotalSuccessors": 2
}
```

**Queries Executed**:

1. Parent Case with Financial Account
2. All Child Cases (via ParentId relationship)
3. All Financial Account Roles with Role containing "Successor"

### 2. FlexCard: `MultiSuccessorCaseHierarchy`

**File**: `force-app/main/default/omniUiCard/MultiSuccessorCaseHierarchy.json`

**Purpose**: Displays nested hierarchy with collapsible sections

**Features**:

- ✅ Collapsible accordion for child cases
- ✅ Visual indentation (SLDS left padding)
- ✅ Icons for each level (🔵 parent, child, 📊 FA, 👤 successors)
- ✅ Responsive grid layout
- ✅ Automatic data binding from DataRaptor
- ✅ Real-time refresh capability

**Display Fields**:

- **Parent**: Subject, Status, DAF Name, Balance, Owner
- **Child Cases**: Subject, Status, Verification Status, SLA Status, Contact
- **Financial Account**: Name, Balance
- **Successors**: Name, Allocation %, Role, Email

## Deployment Instructions

### Step 1: Deploy Metadata (5 minutes)

#### Option A: Deploy via Salesforce CLI (Recommended)

```bash
# Navigate to project directory
cd "/Users/joshsmbp/Schwab Downloads/Estates SFDX Project"

# Deploy DataRaptor and FlexCard
sf project deploy start \
  --source-dir force-app/main/default/omniDataTransforms/SuccessionCaseHierarchy.json \
  --source-dir force-app/main/default/omniUiCard/MultiSuccessorCaseHierarchy.json \
  --target-org schwab-sandbox
```

#### Option B: Deploy via Package Manifest

```bash
# Use focused manifest for OmniStudio components
sf project deploy start \
  --manifest manifest/package-omnistudio-succession-hierarchy.xml \
  --target-org schwab-sandbox
```

**Note**: If deployment fails with "Unknown metadata type," you may need to import via UI (see Step 2).

### Step 2: Activate in OmniStudio (UI - Required for some orgs)

#### Activate DataRaptor

1. Setup → OmniStudio → DataRaptors
2. Find "SuccessionCaseHierarchy"
3. Click Edit → Activate
4. Test with a Parent Case ID:
   ```json
   {
     "ParentCaseId": "500XXXXXXXXXXXXXXX"
   }
   ```
5. Verify output shows ParentCase, ChildCases, and Successors

#### Activate FlexCard

1. Setup → OmniStudio → FlexCards
2. Find "MultiSuccessorCaseHierarchy"
3. Click Edit → Preview
4. Test with recordId parameter
5. Click Activate when satisfied

**Alternative: Import via UI (if deployment doesn't work)**

1. Setup → OmniStudio → DataRaptors → Import
2. Upload `SuccessionCaseHierarchy.json`
3. Setup → OmniStudio → FlexCards → Import
4. Upload `MultiSuccessorCaseHierarchy.json`

### Step 3: Add to Lightning Record Page (5 minutes)

1. **Navigate to Parent Case Record Page**:
   - Setup → Object Manager → Case
   - Lightning Record Pages → Find page for EstateAdministration Record Type

2. **Add FlexCard Component**:
   - Edit page in Lightning App Builder
   - Drag "OmniScript FlexCard" component to page
   - **OR** drag generic "FlexCard" component (depends on OmniStudio version)

3. **Configure Component**:
   - FlexCard Name: `MultiSuccessorCaseHierarchy`
   - recordId: `{!recordId}` (auto-mapped to Case Id)
   - Display Type: Card

4. **Position on Page**:
   - Recommended: New tab "Succession Hierarchy"
   - Alternative: Below "Related" tab

5. **Set Visibility** (optional):
   - Filter: Type = "Multi-Account Succession Master"
   - Ensures only parent cases show the component

6. **Save and Activate**

### Step 4: Test with Multi-Successor Data (10 minutes)

#### Create Test Data via Apex

```apex
// Execute in Developer Console
SuccessionTestDataFactory.SuccessionScenarioData scenario =
    SuccessionTestDataFactory.generateMultipleSuccessorsScenario();

System.debug('Parent Case ID: ' + scenario.successionCase.Id);
```

**Expected Result**: Creates Patricia Williams (donor) with Amanda & Brandon as 50/50 successors

#### Verify Component Display

1. Navigate to the Parent Case created above
2. Open "Succession Hierarchy" tab (or wherever you placed the FlexCard)
3. Verify you see:
   - ✅ Parent case header with Financial Account details
   - ✅ "Child Cases (2)" accordion
   - ✅ Both child cases nested with indentation
   - ✅ Financial Account info under each child
   - ✅ Successor details with 50% allocations

#### Test Collapsible Sections

- Click accordion header to collapse/expand child cases
- Verify data persists when toggling

#### Test with Different Scenarios

```apex
// 3 successors (33.33% each)
// Manually create or modify test data

// 4 successors (25% each)
// Use SuccessionTestDataFactory to create custom allocations
```

## Troubleshooting

### DataRaptor Not Returning Data

**Symptoms**: FlexCard shows "No data" or blank

**Check**:

1. Parent Case Type must be "Multi-Account Succession Master"
2. Child Cases must have ParentId pointing to parent
3. Financial Account Roles must have FinServ**Active**c = TRUE
4. Role field must contain "Successor" (case-insensitive)

**Debug**:

```bash
# Test DataRaptor directly in OmniStudio UI
Setup → OmniStudio → DataRaptors → SuccessionCaseHierarchy → Preview

# Input:
{
  "ParentCaseId": "YOUR_CASE_ID"
}
```

### FlexCard Not Displaying on Record Page

**Symptoms**: Component doesn't appear

**Check**:

1. FlexCard is Active (not Draft)
2. Component visibility filter matches case Type
3. recordId is correctly mapped (should be automatic)
4. User has OmniStudio permissions

**Verify Permissions**:

```sql
-- Query user's OmniStudio access
SELECT Id, Name, PermissionSet.Name
FROM PermissionSetAssignment
WHERE AssigneeId = :$User.Id
  AND PermissionSet.Name LIKE '%OmniStudio%'
```

### Styling Issues (Indentation Not Showing)

**Symptoms**: All text appears flat without nesting

**Fix**:

1. Edit FlexCard in OmniStudio Designer
2. Verify custom CSS in stylingConfiguration:
   ```css
   .slds-p-left_large {
     padding-left: 2rem !important;
   }
   .slds-p-left_x-large {
     padding-left: 3rem !important;
   }
   ```
3. Ensure child blocks have correct class assignments

### Successor Data Not Matching Child Case

**Symptoms**: Successors appear multiple times or under wrong child

**Issue**: DataRaptor returns all successors, not filtered per child

**Fix**: The FlexCard repeater has a filter property:

```json
"filter": "$item.FinServ__FinancialAccount__c == $parent.FinServ__FinancialAccount__c"
```

Verify this is present in the JSON. If not, add manually in FlexCard Designer.

## Customization Options

### Add More Fields

Edit `SuccessionCaseHierarchy.json` to add fields to queryFields arrays:

**Example - Add Pathway to Child Cases**:

```json
{
  "name": "Extract_Child_Cases",
  "queryFields": [
    "Id",
    "Subject",
    "Pathway_Confirmed__c",  // ADD THIS
    ...
  ]
}
```

Then update FlexCard JSON to display:

```json
{
  "type": "text",
  "text": "Pathway: {$item.Pathway_Confirmed__c}",
  "class": "slds-col slds-size_1-of-3"
}
```

### Add Action Buttons

In FlexCard JSON, add buttons to navigate or trigger actions:

```json
{
  "type": "button",
  "label": "View Case",
  "variant": "brand",
  "action": {
    "type": "Navigate",
    "params": {
      "type": "standard__recordPage",
      "attributes": {
        "recordId": "{$item.Id}",
        "actionName": "view"
      }
    }
  }
}
```

### Change Color Coding

Modify styling based on field values:

```json
{
  "type": "text",
  "text": "{$item.SLA_Status__c}",
  "class": "slds-badge",
  "styleClass": "background-color: {$item.SLA_Status__c == '🔴 Critical' ? 'red' : 'green'};"
}
```

## Performance Considerations

**Data Volume**:

- DataRaptor executes 3 queries per load
- FlexCard caches results for session
- Recommended: Max 10 child cases per parent for optimal UX

**Large Orgs**:

- Add LIMIT clause to Extract_Child_Cases if needed
- Consider pagination for 20+ child cases

## Maintenance

### When to Update DataRaptor

- New fields added to Case, Financial Account, or Financial Account Role
- Business rules change (e.g., different Role values for successors)
- Performance optimization needed

### When to Update FlexCard

- Layout changes (new sections, reordering)
- Field display changes
- New actions/buttons needed
- Styling updates

### Version Control

Both components are JSON files in source control:

- DataRaptor: `force-app/main/default/omniDataTransforms/`
- FlexCard: `force-app/main/default/omniUiCard/`

Always commit changes to git after modifications.

## Related Documentation

- BRD: `~/Downloads/daf_succession_augmented_final_brd.md`
- Multi-Successor Flow: `Case_Multiple_Successors_Handler.flow-meta.xml`
- Test Data Factory: `SuccessionTestDataFactory.cls`
- CLAUDE.md: Architecture overview

## Support

For issues or enhancement requests:

1. Check Troubleshooting section above
2. Review OmniStudio documentation
3. Test with `SuccessionTestDataFactory` generated data
4. Verify all components are Active in OmniStudio

`★ Insight: FlexCards excel at data visualization with minimal code. The real power is in the DataRaptor's hierarchical query structure—once data is properly shaped, FlexCard display is straightforward. The nested repeater pattern allows unlimited depth without additional code.`

---

## Document Change History

**Update 2025-10-14**:

- Updated DataRaptor example to use `FinServ__RelatedContact__r` instead of `FinServ__RelatedAccount__r` for Person Account successors
- Changed email field reference from `PersonEmail` to `Email` (Contact object field)
- **FSC Compliance**: Person Account roles (Successor) now correctly use FinServ**RelatedContact**c field

**Original Date**: Unknown
**Last Updated**: 2025-10-14
