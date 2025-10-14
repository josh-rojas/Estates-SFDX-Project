<!-- c23fa090-5a16-4426-b06a-f337047b4f47 4a79d112-74c5-48d9-832c-2eb66572d2f2 -->

# Fix, Deploy, and Test Pathway Action Plans

## 1. Fix XML Typo in New DAF Template

**File:** `force-app/main/default/actionPlanTemplates/Succession_New_DAF_Account_Pathway.apt-meta.xml`

**Issue:** Line 98 has `<itemType>` instead of `<itemEntityType>Task</itemEntityType>`

**Fix:**

```98:force-app/main/default/actionPlanTemplates/Succession_New_DAF_Account_Pathway.apt-meta.xml
            <itemEntityType>Task</itemEntityType>
```

## 2. Deploy Metadata to Sandbox Org

Deploy all three new components to `schwab-sandbox` org:

**Command 1:** Deploy Action Plan Templates

```bash
sf project deploy start --source-dir force-app/main/default/actionPlanTemplates --target-org schwab-sandbox
```

**Command 2:** Deploy the new Flow

```bash
sf project deploy start --source-dir force-app/main/default/flows/Case_Assign_Pathway_Action_Plan.flow-meta.xml --target-org schwab-sandbox
```

**Command 3:** Deploy updated Case Layout

```bash
sf project deploy start --source-dir "force-app/main/default/layouts/Case-Estate Administration Layout.layout-meta.xml" --target-org schwab-sandbox
```

## 3. Verify Deployment Success

**Query Action Plan Templates:**

```bash
sf data query --query "SELECT Id, Name, UniqueName FROM ActionPlanTemplate WHERE UniqueName LIKE 'Succession%'" --target-org schwab-sandbox
```

Expected: 3 templates returned (Final Grant, New DAF Account, Disclaim Assets)

**Verify Flow is Active:**

```bash
sf data query --query "SELECT Id, Label, Status FROM Flow WHERE Label = 'Case Assign Pathway Action Plan'" --use-tooling-api --target-org schwab-sandbox
```

Expected: Status = "Active"

## 4. Load Test Data (If Needed)

If no test cases exist with completed forms:

```bash
cci task run load_final_grant_scenario --org schwab-sandbox
```

This creates a case with `Form_Completed_Date__c` set and `Pathway_Confirmed__c = "Final Grant"`

## 5. Test Action Plan Auto-Creation

**Open Sandbox Org:**

```bash
sf org open --target-org schwab-sandbox
```

**Test Steps:**

1. Navigate to a Case with `RecordType = EstateAdministration` and `Type = Named Successor Enactment`
2. Manually update `Form_Completed_Date__c` to today's date
3. Set `Pathway_Confirmed__c` to one of: "Final Grant", "New DAF Account", or "Disclaim Assets"
4. Save the Case
5. Refresh the page and scroll to **Action Plan** related list
6. Verify:
   - Action Plan instance created with correct template name
   - Tasks are created with relative due dates (+2, +5, +10, etc. days from `Form_Completed_Date__c`)
   - Tasks are assigned to Case Owner
   - Chatter post confirms Action Plan assignment

**Repeat for all 3 pathways** to ensure routing logic works correctly.

## 6. Commit Changes to Git

Once testing is successful:

```bash
git add force-app/main/default/actionPlanTemplates/
git add force-app/main/default/flows/Case_Assign_Pathway_Action_Plan.flow-meta.xml
git add "force-app/main/default/layouts/Case-Estate Administration Layout.layout-meta.xml"
git add CLAUDE.md docs/PROJECT_TODOS.md
git commit -m "feat: Add pathway-specific Action Plans with auto-assignment flow

- Created 3 Action Plan Templates (Final Grant, New DAF Account, Disclaim Assets)
- Implemented Case_Assign_Pathway_Action_Plan flow triggered by Form_Completed_Date__c
- Added ActionPlanState field and ActionPlan related list to Case layout
- Tasks provide broad guidance milestones rather than rigid checklists
- All tasks assigned to Case Owner with relative due dates
- Fixed XML typo in New DAF template (line 98)"
```

## Success Criteria

- ✅ All 3 Action Plan Templates deploy without errors
- ✅ Flow activates successfully
- ✅ Case layout displays Action Plan related list
- ✅ Test cases trigger Action Plan creation automatically
- ✅ All 3 pathways route to correct templates
- ✅ Tasks have correct due dates and assignments
- ✅ Chatter confirmation posts appear

### To-dos

- [x] Create 3 Action Plan Templates in Salesforce Setup (Final Grant, New DAF Account, Disclaim Assets) - DEPLOYED & VERIFIED
- [ ] **BLOCKED:** Create Case_Assign_Pathway_Action_Plan flow with decision logic for 3 pathways - Requires manual creation in Flow Builder due to Action Plan API limitations
- [ ] **BLOCKED:** Add Action Plans related list to Estate Administration case page layout - Requires manual addition in Setup (RelatedActionPlans not available via metadata)
- [x] Add new flow to Flow Inventory in CLAUDE.md - COMPLETED
- [ ] **PENDING:** Verify test scenarios include Form_Completed_Date__c to trigger action plans - Depends on flow creation (step 2)
- [ ] **PENDING:** Test all 3 pathway action plans trigger correctly from public form submission - Depends on flow creation (step 2)

## Manual Configuration Required

### A. Create Flow in Flow Builder

The Case_Assign_Pathway_Action_Plan flow cannot be deployed via metadata due to Action Plan API XML structure limitations. Create manually:

1. Setup → Flows → New Flow → Record-Triggered Flow
2. Object: Case, Trigger: After Save, Entry: `Form_Completed_Date__c` ISCHANGED
3. Decision element with 3 outcomes checking `Pathway_Confirmed__c`
4. Create Records elements using template IDs:
   - Succession_Final_Grant_Pathway: 0PRDg0000008WkWOAU
   - Succession_New_DAF_Account_Pathway: 0PRDg0000008WkXOAU
   - Succession_Disclaim_Assets_Pathway: 0PRDg0000008WkVOAU

### B. Add Related List to Layout

1. Setup → Object Manager → Case → Page Layouts → Estate Administration Layout
2. Drag "Action Plans" related list to layout
3. Configure columns: Name, ActionPlanStatus, StartDate, CompletionPercentage
