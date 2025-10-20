# Manual Quick Action Setup Instructions

## Why Manual Setup is Required

The `FinServ__FinancialAccount__c` object is a **managed object** from the Salesforce Financial Services Cloud package. Quick Actions on managed objects cannot be deployed via metadata - they must be created manually in the org.

## Setup Steps

### 1. Navigate to Object Manager
1. Go to **Setup** (gear icon)
2. In Quick Find, search for **Object Manager**
3. Find and click **Financial Accounts** (`FinServ__FinancialAccount__c`)

### 2. Create the Quick Action
1. In the left sidebar, click **Buttons, Links, and Actions**
2. Click **New Action** button
3. Configure the action:
   - **Action Type:** Lightning Component
   - **Lightning Component:** `createSuccessionCase` (from dropdown)
   - **Height:** 250 (pixels)
   - **Label:** `Create Succession Case` (or use emoji: `🏛️ Create Succession Case`)
   - **Name:** `Create_Succession_Case`
   - **Description:** "Creates succession case for this financial account. Validates requirements (deceased owner, designated successors, no existing case) and auto-starts workflow."
4. Click **Save**

### 3. Add to Page Layout
1. Still in Object Manager → Financial Accounts
2. Click **Page Layouts**
3. Click on the layout you want to edit (typically **Financial Account Layout**)
4. In the page layout editor, find the **Salesforce Mobile and Lightning Experience Actions** section
5. From the **Mobile & Lightning Actions** palette, drag **Create Succession Case** to the section
6. Click **Save**

### 4. Verify Permissions
Ensure users have the `Succession_Management_Access` permission set assigned:

```bash
sf org assign permset --name Succession_Management_Access --target-org schwab-sandbox
```

## Testing the Quick Action

1. Navigate to any Financial Account record
2. Look for the **Create Succession Case** button in the highlights panel or actions menu
3. Click the button
4. The action will:
   - Validate the financial account has a deceased primary owner
   - Validate there are active successors
   - Check for existing open succession cases
   - Create the seed case and trigger multi-successor orchestration if needed

## Expected Behavior

### Single Successor
- Creates 1 case with Type = "Named Successor Enactment"
- Sets `Verification_Status__c = "Complete - Verified"` (auto-starts workflow)
- Creates Day 0 Task automatically

### Multiple Successors
- Creates parent case (Type = "Multi-Account Succession Master")
- Creates child cases for each successor (Type = "Named Successor Enactment")
- Each child case has independent contact cadence

## Troubleshooting

### "No deceased primary owner found"
- Ensure the Account linked to the Primary Owner role has `Deceased__c = true`

### "No active successors found"
- Check FinancialAccountRoles for records with:
  - `FinServ__Role__c` containing "Successor"
  - `FinServ__Active__c = true`

### "Case already exists"
- An open succession case already exists for this Financial Account
- Check Cases related to this Financial Account

### "Allocation must sum to 100%"
- All successor roles must have `SuccessorAllocation__c` values that total 100%

## Components Deployed

✅ **Apex Classes:**
- `CreateSuccessionCaseController` - Main controller with validation logic
- `CreateSuccessionCaseControllerTest` - Test class

✅ **LWC Component:**
- `createSuccessionCase` - Quick Action UI component

✅ **Permission Set:**
- `Succession_Management_Access` - Includes Apex class access

## Support

For issues or questions, check:
- `/Users/joshsmbp/Schwab Downloads/Estates SFDX Project/CREATE_SUCCESSION_CASE_IMPLEMENTATION_SUMMARY.md`
- Debug logs: `sf apex get log --number 1 --target-org schwab-sandbox`
