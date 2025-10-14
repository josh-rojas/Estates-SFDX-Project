# SLA Formula Bug Fix Documentation

## Bug 5: Logic Error in SLA Status Formula

### Issue Description
The `SLA_Status__c` formula field calculates SLA status based on case creation date (`TODAY() - DATEVALUE(CreatedDate)`), but for succession management cases, the SLA should be based on contact attempt timing, not case age.

### Current Problem
```xml
<formula>IF(Contact_Established__c, "✓ Complete",
  IF(Contact_Attempt_Count__c >= 4, "🔴 Critical - Escalate to Compliance",
    IF(TODAY() - DATEVALUE(CreatedDate) > 65, "🔴 Critical - Escalate",
      IF(TODAY() - DATEVALUE(CreatedDate) > 35, "🟠 At Risk",
        IF(TODAY() - DATEVALUE(CreatedDate) > 5, "🟡 Attention Needed",
          "🟢 On Track"
        )
      )
    )
  )
)</formula>
```

### Issues with Current Logic
1. **Case Age vs Contact Timing**: A case created 6 months ago but with recent contact attempts should not be "Critical" based on case age
2. **Inconsistent with Contact Cadence**: The contact cadence is Day 0, 5, 35, 65, 95, but SLA uses 5, 35, 65 days from case creation
3. **Business Logic Mismatch**: SLA should reflect contact attempt progress, not case age

### Correct Fix
The formula should be based on contact attempt timing, not case creation date:

```xml
<formula>IF(Contact_Established__c, "✓ Complete",
  IF(Contact_Attempt_Count__c >= 4, "🔴 Critical - Escalate to Compliance",
    IF(Contact_Attempt_Count__c >= 3, "🔴 Critical - Escalate",
      IF(Contact_Attempt_Count__c >= 2, "🟠 At Risk",
        IF(Contact_Attempt_Count__c >= 1, "🟡 Attention Needed",
          "🟢 On Track"
        )
      )
    )
  )
)</formula>
```

### Alternative Approach
If date-based SLA is still needed, consider using a custom field that tracks the last contact attempt date:

```xml
<formula>IF(Contact_Established__c, "✓ Complete",
  IF(Contact_Attempt_Count__c >= 4, "🔴 Critical - Escalate to Compliance",
    IF(ISBLANK(Last_Contact_Attempt_Date__c), "🟢 On Track",
      IF(TODAY() - DATEVALUE(Last_Contact_Attempt_Date__c) > 30, "🔴 Critical - Escalate",
        IF(TODAY() - DATEVALUE(Last_Contact_Attempt_Date__c) > 15, "🟠 At Risk",
          IF(TODAY() - DATEVALUE(Last_Contact_Attempt_Date__c) > 5, "🟡 Attention Needed",
            "🟢 On Track"
          )
        )
      )
    )
  )
)</formula>
```

### Required Action
1. Update the formula field to use contact attempt count instead of case creation date
2. Test with various scenarios to ensure proper SLA status calculation
3. Consider adding a custom field to track last contact attempt date if date-based SLA is needed
4. Update field description and help text to reflect the new logic