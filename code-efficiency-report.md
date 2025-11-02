# Code Efficiency Report - Estates SFDX Project

**Date:** November 2, 2025  
**Analyzed By:** Devin  
**Repository:** josh-rojas/Estates-SFDX-Project

## Executive Summary

This report identifies several areas where the codebase could be optimized for better performance, maintainability, and efficiency. The analysis covers Apex classes, triggers, and Lightning Web Components across the Succession Management System.

## Identified Inefficiencies

### 1. Redundant SOQL Query in ContactCadenceController.saveAttemptOutcome()

**Location:** `ContactCadenceController.cls:690-699`

**Issue:** The method queries the Case record after upserting the Task, even though this query is only used when `contactEstablished` is true. This means the query executes unnecessarily in cases where contact was not established.

**Current Code:**

```apex
// Update parent case based on outcome
Case parentCase = [
  SELECT Id, Contact_Established__c, Contact_Established_Date__c, Contact_Attempt_Count__c
  FROM Case
  WHERE Id = :caseId
  LIMIT 1
];

// If contact established, update case
if (contactEstablished && !parentCase.Contact_Established__c) {
  parentCase.Contact_Established__c = true;
  parentCase.Contact_Established_Date__c = Date.today();
  update parentCase;
}
```

**Impact:**

- Unnecessary SOQL query consumption (counts against governor limits)
- Wasted database round-trip time
- Occurs on every contact attempt save, but only needed when contact is established

**Recommendation:** Move the SOQL query inside the conditional block so it only executes when needed.

---

### 2. Inefficient String Concatenation in Dynamic SOQL Queries

**Location:** `CaseHierarchyController.cls:83-103`

**Issue:** The method builds dynamic SOQL queries using string concatenation, which is less efficient and harder to maintain than using bind variables or query builder patterns.

**Current Code:**

```apex
String childQuery = 'SELECT Id, CaseNumber, Subject, Status, CreatedDate, ' +
    'ContactId, Contact.Name, Contact.Email, Contact.Phone, ' +
    'AccountId, Account.Name, ' +
    // ... more fields
    'FROM Case WHERE ParentId = :parentCaseId';

if (String.isNotBlank(excludeStatusString)) {
    List<String> excludedStatuses = excludeStatusString.split(',');
    List<String> escapedStatuses = new List<String>();
    for (String status : excludedStatuses) {
        escapedStatuses.add('\'' + String.escapeSingleQuotes(status.trim()) + '\'');
    }
    childQuery += ' AND Status NOT IN (' + String.join(escapedStatuses, ',') + ')';
}
```

**Impact:**

- More complex code that's harder to read and maintain
- Potential for SOQL injection if not carefully escaped
- Less efficient than using bind variables

**Recommendation:** Use bind variables or a more structured approach to building queries.

---

### 3. Multiple Iterations Over Same Data in JavaScript

**Location:** `caseHierarchyViewer.js:97-111`

**Issue:** The `totalBalance` getter iterates through all child cases to calculate the total. This same iteration happens in `childCasesWithProps` (lines 119-144), meaning the data is traversed multiple times unnecessarily.

**Current Code:**

```javascript
get totalBalance() {
  if (!this.hierarchyData || !this.hierarchyData.childCases) return "$0.00";

  let total = 0;
  this.hierarchyData.childCases.forEach((childData) => {
    if (childData.financialAccount && childData.financialAccount.FinServ__Balance__c) {
      total += childData.financialAccount.FinServ__Balance__c;
    }
  });

  return this.formatCurrency(total);
}

get childCasesWithProps() {
  if (!this.hierarchyData || !this.hierarchyData.childCases) return [];

  return this.hierarchyData.childCases.map((childData) => {
    // ... mapping logic
  });
}
```

**Impact:**

- Redundant iterations over the same dataset
- Unnecessary CPU cycles
- Could cause performance issues with large datasets

**Recommendation:** Calculate the total balance during the single iteration in `childCasesWithProps` and cache it.

---

### 4. Duplicate Task Creation Logic Across Three Methods

**Location:** `SuccessionTaskGenerator.cls:102-250`

**Issue:** The three methods `generateFinalGrantTasks()`, `generateNewDAFTasks()`, and `generateDisclaimTasks()` all follow the same pattern of creating Task lists with similar structure. This leads to significant code duplication.

**Current Pattern:**

```apex
private static List<Task> generateFinalGrantTasks(Id caseId, Id ownerId, Date startDate) {
  return new List<Task>{
    new Task(WhatId = caseId, OwnerId = ownerId, Subject = '...', Description = '...',
             Priority = 'High', ActivityDate = startDate.addDays(2), Status = 'Not Started'),
    new Task(WhatId = caseId, OwnerId = ownerId, Subject = '...', Description = '...',
             Priority = 'High', ActivityDate = startDate.addDays(5), Status = 'Not Started'),
    // ... more tasks
  };
}
```

**Impact:**

- Code duplication makes maintenance harder
- Changes to task structure require updates in three places
- Increased risk of inconsistencies

**Recommendation:** Create a helper method that accepts task configuration data and generates tasks, reducing duplication.

---

### 5. Unnecessary ContentNote Query Complexity

**Location:** `ContactCadenceController.cls:248-316`

**Issue:** The `queryAndMapNotes()` method performs a complex multi-step query process: first querying ContentDocumentLink, then extracting IDs, then querying ContentVersion. This could be simplified with a more direct query approach.

**Current Code:**

```apex
List<ContentDocumentLink> cdLinks = [
  SELECT ContentDocumentId
  FROM ContentDocumentLink
  WHERE LinkedEntityId = :caseId
  ORDER BY SystemModstamp DESC
];

Set<Id> docIds = new Set<Id>();
for (ContentDocumentLink cdl : cdLinks) {
  docIds.add(cdl.ContentDocumentId);
}

List<ContentVersion> contentVersions = [
  SELECT Id, Title, VersionData, FileType
  FROM ContentVersion
  WHERE ContentDocumentId IN :docIds AND IsLatest = TRUE AND FileType = 'SNOTE'
  ORDER BY CreatedDate DESC
];
```

**Impact:**

- Two separate SOQL queries when one might suffice
- Additional loop to extract IDs
- More complex code flow

**Recommendation:** Consider using a subquery or relationship query to reduce the number of SOQL calls.

---

### 6. Hardcoded Wait Durations in JavaScript

**Location:** `successionContactCadence.js:79-84`

**Issue:** Contact cadence wait durations are hardcoded in JavaScript, duplicating business logic that should be centralized. The comment even acknowledges this should be in Custom Metadata.

**Current Code:**

```javascript
static ATTEMPT_WAIT_MS = {
  2: 5 * 24 * 60 * 60 * 1000,  // 5 days
  3: 30 * 24 * 60 * 60 * 1000, // 30 days
  4: 30 * 24 * 60 * 60 * 1000, // 30 days
  5: 30 * 24 * 60 * 60 * 1000  // 30 days
};
```

**Impact:**

- Business logic duplicated between Apex flows and JavaScript
- Changes require code deployment instead of admin configuration
- Risk of inconsistency between systems

**Recommendation:** Move to Custom Metadata Type for centralized configuration.

---

### 7. Excessive Debug Logging in Production Code

**Location:** Multiple files, especially `ContactCadenceController.cls:251-315`

**Issue:** The code contains numerous `System.debug()` statements that execute in production, consuming CPU time and log storage even when not needed.

**Example:**

```apex
System.debug('DEBUG: Querying notes for Case: ' + caseId);
System.debug('DEBUG: Found ' + cdLinks.size() + ' ContentDocumentLinks');
System.debug('DEBUG: Found ' + contentVersions.size() + ' ContentNotes (FileType=SNOTE)');
System.debug('DEBUG: Processing ContentVersion with Title: ' + title);
System.debug('DEBUG: Extracted attempt number: ' + attemptNum);
System.debug('DEBUG: Content preview (first 200 chars): ' + content.substring(0, Math.min(200, content.length())));
System.debug('DEBUG: Extracted user notes: ' + userNotes);
System.debug('DEBUG: Added notes for attempt ' + attemptNum);
System.debug('DEBUG: Final notesByAttempt map size: ' + notesByAttempt.size());
```

**Impact:**

- Unnecessary CPU consumption
- Increased log storage costs
- Cluttered debug logs making real issues harder to find

**Recommendation:** Use logging levels appropriately and consider removing debug statements or wrapping them in conditional checks.

---

### 8. Memoization Implementation Could Be Improved

**Location:** `successionContactCadence.js:476-482`

**Issue:** The memoization implementation uses a simple flag (`dataChanged`) that gets reset, but doesn't properly invalidate when state changes that should trigger recalculation.

**Current Code:**

```javascript
get attemptsWithProps() {
  if (!this.cadenceData || !this.cadenceData.attempts) return [];

  // PERFORMANCE: Check if we can use memoized result
  if (this._memoizedAttempts && !this.state.performance.dataChanged) {
    return this._memoizedAttempts;
  }
  // ... calculation
}
```

**Impact:**

- Potential for stale data if state changes aren't properly tracked
- Memoization flag never gets reset after use
- Complex state management that's error-prone

**Recommendation:** Use a more robust memoization strategy or computed property pattern.

---

## Priority Recommendations

1. **High Priority:** Fix redundant SOQL query in ContactCadenceController (Issue #1) - Easy fix with immediate governor limit benefits
2. **Medium Priority:** Consolidate task generation logic (Issue #4) - Improves maintainability significantly
3. **Medium Priority:** Optimize JavaScript iterations (Issue #3) - Performance improvement for UI
4. **Low Priority:** Move wait durations to Custom Metadata (Issue #6) - Better long-term architecture
5. **Low Priority:** Clean up debug logging (Issue #7) - Reduces noise and resource consumption

## Conclusion

The codebase is generally well-structured with good separation of concerns. The identified inefficiencies are mostly minor optimizations that would improve performance and maintainability. The most impactful fix would be addressing the redundant SOQL query, which provides immediate benefits with minimal risk.
