# Flow Bug Fix Documentation

## Bug 3: Incorrect Date Calculation in Task_Create_Next_Contact_Attempt Flow

### Issue Description
The flow `Task_Create_Next_Contact_Attempt.flow-meta.xml` has a critical logic error in its date calculation formulas. The flow calculates task due dates based on the parent case's `CreatedDate`, but this is incorrect for the contact cadence timing.

### Current Problem
```xml
<expression>DATEVALUE({!Get_Parent_Case.CreatedDate}) + 5</expression>
```

This means:
- If a case was created 6 months ago
- But the contact attempt is happening now
- The next task would be scheduled for 5 days from 6 months ago (in the past)

### Correct Fix
The formulas should calculate dates from the current task's completion date, not the parent case creation date.

**Current (Incorrect):**
```xml
<expression>DATEVALUE({!Get_Parent_Case.CreatedDate}) + 5</expression>
```

**Should be (Correct):**
```xml
<expression>DATEVALUE({!$Record.CompletedDateTime}) + 5</expression>
```

### Impact
- Tasks may be scheduled in the past
- Contact cadence timing is incorrect
- Agents may not see tasks when they should be available
- Business process timing is broken

### Required Action
1. Open the flow in Flow Builder
2. Update all four date calculation formulas:
   - fxCalculateDay5: Change to `DATEVALUE({!$Record.CompletedDateTime}) + 5`
   - fxCalculateDay35: Change to `DATEVALUE({!$Record.CompletedDateTime}) + 35`
   - fxCalculateDay65: Change to `DATEVALUE({!$Record.CompletedDateTime}) + 65`
   - fxCalculateDay95: Change to `DATEVALUE({!$Record.CompletedDateTime}) + 95`
3. Test the flow to ensure proper date calculation
4. Activate the updated flow

### Alternative Approach
If `CompletedDateTime` is not available, consider using:
- `TODAY()` for current date-based calculation
- A custom field on the Case to track the last contact attempt date
- A more sophisticated date calculation based on the task's actual completion time