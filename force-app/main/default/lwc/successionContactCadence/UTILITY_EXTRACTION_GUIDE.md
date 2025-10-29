# Utility Function Extraction Guide
## successionContactCadence Component

This document identifies pure utility functions that could be extracted to separate modules for improved reusability and testability.

---

## EXTRACTABLE UTILITY FUNCTIONS

### 1. Time Formatting Utilities
**Module:** `c/successionTimeUtils`

**Functions to Extract:**
```javascript
/**
 * @module c/successionTimeUtils
 * @description Time formatting utilities for succession workflow
 */

/**
 * Formats milliseconds to human-readable compact string
 * @param {number} ms - Milliseconds
 * @returns {string} Formatted time (e.g., "12d 4h", "3h 25m")
 */
export function formatRemainingTime(ms) {
  const d = Math.floor(ms / (24 * 60 * 60 * 1000));
  const h = Math.floor((ms % (24 * 60 * 60 * 1000)) / (60 * 60 * 1000));
  const m = Math.floor((ms % (60 * 60 * 1000)) / (60 * 1000));
  if (d > 0) return `${d}d ${h}h`;
  if (h > 0) return `${h}h ${m}m`;
  return `${m}m`;
}

/**
 * Calculates countdown progress percentage
 * @param {number} startMs - Start timestamp
 * @param {number} endMs - End timestamp
 * @param {number} nowMs - Current timestamp
 * @returns {number} Progress percentage (0-100)
 */
export function calculateCountdownProgress(startMs, endMs, nowMs) {
  const totalMs = endMs - startMs;
  const elapsedMs = nowMs - startMs;
  if (totalMs <= 0) return 100;
  return Math.min(100, Math.round((elapsedMs / totalMs) * 100));
}
```

**Current Location:** `successionContactCadence.js:780-787`
**Reusability:** HIGH - Could be used by other workflow components
**Dependencies:** None (pure function)

---

### 2. Text Processing Utilities
**Module:** `c/successionTextUtils`

**Functions to Extract:**
```javascript
/**
 * @module c/successionTextUtils
 * @description Text processing utilities for succession notes
 */

/**
 * Filters system-generated text from Task descriptions
 * @param {string} description - Full task description
 * @param {string[]} systemPatterns - Patterns to filter out
 * @returns {string} User notes only
 */
export function filterSystemText(description, systemPatterns) {
  if (!description) return "";

  let filtered = description;
  systemPatterns.forEach((pattern) => {
    filtered = filtered.replace(pattern, "").trim();
  });

  return filtered.length > 0 ? filtered : "";
}

/**
 * System-generated text patterns for contact attempts
 */
export const CONTACT_ATTEMPT_SYSTEM_PATTERNS = [
  "Initial contact attempt (Day 0). Agent can complete this task immediately.",
  "Contact attempt 2 scheduled for Day 5. Agent cannot complete this task until the scheduled date arrives.",
  "Contact attempt 3 scheduled for Day 35. Agent cannot complete this task until the scheduled date arrives.",
  "Contact attempt 4 scheduled for Day 65. Agent cannot complete this task until the scheduled date arrives.",
  "Contact attempt 5 scheduled for Day 95. Agent cannot complete this task until the scheduled date arrives.",
  "Contact attempt for succession case."
];
```

**Current Location:** `successionContactCadence.js:803-825`
**Reusability:** MEDIUM - Specific to succession workflow but pattern is reusable
**Dependencies:** None (pure function)

---

### 3. Currency Formatting Utilities
**Module:** `c/lwcCurrencyUtils` (shared utility)

**Functions to Extract:**
```javascript
/**
 * @module c/lwcCurrencyUtils
 * @description Currency formatting utilities (reusable across components)
 */

/**
 * Formats number as USD currency
 * @param {number} value - Numeric value
 * @returns {string} Formatted currency (e.g., "$1,234.56")
 */
export function formatCurrency(value) {
  if (value === null || value === undefined) return "$0.00";
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
    minimumFractionDigits: 2
  }).format(value);
}
```

**Current Location:** `caseHierarchyViewer.js:249-256`
**Reusability:** HIGH - Universal utility for all LWC components
**Dependencies:** None (uses browser Intl API)

---

### 4. Error Handling Utilities
**Module:** `c/successionErrorUtils`

**Functions to Extract:**
```javascript
/**
 * @module c/successionErrorUtils
 * @description Centralized error categorization and messaging
 */

/**
 * Categorizes error type from Salesforce error object
 * @param {Error} error - Error object
 * @returns {string} Error type constant
 */
export function categorizeError(error) {
  if (error.body?.message?.includes("INSUFFICIENT_ACCESS")) return "PERMISSION";
  if (error.body?.message?.includes("REQUIRED_FIELD_MISSING")) return "VALIDATION";
  if (error.body?.message?.includes("DUPLICATE_VALUE")) return "DUPLICATE";
  if (error.status === 500) return "SERVER";
  if (error.status === 404) return "NOT_FOUND";
  if (error.status === 403) return "FORBIDDEN";
  return "UNKNOWN";
}

/**
 * Error type constants
 */
export const ERROR_TYPES = {
  PERMISSION: "PERMISSION",
  VALIDATION: "VALIDATION",
  DUPLICATE: "DUPLICATE",
  SERVER: "SERVER",
  NOT_FOUND: "NOT_FOUND",
  FORBIDDEN: "FORBIDDEN",
  UNKNOWN: "UNKNOWN"
};

/**
 * User-friendly error messages by type
 */
export const ERROR_MESSAGES = {
  PERMISSION: "You do not have permission to perform this action. Please contact your administrator.",
  VALIDATION: "Please check your input and try again. Some required information may be missing.",
  DUPLICATE: "This action has already been completed. Please refresh the page to see the latest updates.",
  SERVER: "A server error occurred. Please try again in a few moments.",
  NOT_FOUND: "The requested information could not be found. Please refresh the page.",
  FORBIDDEN: "Access denied. You may not have the necessary permissions.",
  UNKNOWN: "An unexpected error occurred. Please try again or contact support if the problem persists."
};

/**
 * Gets user-friendly message for error
 * @param {Error} error - Error object
 * @returns {string} User-friendly message
 */
export function getUserFriendlyMessage(error) {
  const errorType = categorizeError(error);
  return ERROR_MESSAGES[errorType] || ERROR_MESSAGES.UNKNOWN;
}
```

**Current Location:** `successionContactCadence.js:125-167`
**Reusability:** HIGH - Applicable to all components with Apex integration
**Dependencies:** None (pure functions)

---

### 5. CSS Class Utilities
**Module:** `c/successionStyleUtils`

**Functions to Extract:**
```javascript
/**
 * @module c/successionStyleUtils
 * @description CSS class generation utilities
 */

/**
 * Generates CSS class for attempt card based on state
 * @param {Object} attemptState - Attempt state object
 * @param {boolean} attemptState.isCompleted - Is attempt completed
 * @param {boolean} attemptState.isCurrent - Is current attempt
 * @param {boolean} attemptState.isPending - Is pending attempt
 * @param {boolean} attemptState.contactEstablished - Was contact made (for completed)
 * @returns {string} CSS class string
 */
export function getAttemptCardClass(attemptState) {
  const baseClass = "attempt-card slds-box slds-var-p-around_medium slds-var-m-bottom_small";

  if (attemptState.isCompleted) {
    if (attemptState.contactEstablished === false) {
      return baseClass + " card-completed-negative";
    }
    return baseClass + " card-completed";
  } else if (attemptState.isCurrent) {
    return baseClass + " card-current";
  } else if (attemptState.isPending) {
    return baseClass + " card-pending";
  }

  return baseClass;
}

/**
 * Generates CSS class for progress node based on state
 * @param {Object} nodeState - Node state object
 * @returns {string} CSS class string
 */
export function getProgressNodeClass(nodeState) {
  if (nodeState.isCompleted) return "progress-node node-completed";
  if (nodeState.isCurrent) return "progress-node node-current";
  return "progress-node node-pending";
}
```

**Current Location:** `successionContactCadence.js:639-678`
**Reusability:** MEDIUM - Specific to succession UI patterns
**Dependencies:** None (pure functions)

---

## EXTRACTION BENEFITS

| Utility Module | Lines Saved | Test Complexity | Reusability | Priority |
|----------------|-------------|-----------------|-------------|----------|
| successionTimeUtils | ~40 | Low | High | High |
| successionTextUtils | ~35 | Low | Medium | Medium |
| lwcCurrencyUtils | ~15 | Low | High | High |
| successionErrorUtils | ~80 | Medium | High | High |
| successionStyleUtils | ~60 | Low | Medium | Low |

**Total Lines Reducible:** ~230 lines (22% of component)

---

## EXTRACTION STRATEGY (If Pursued)

### Phase 1: High-Value, Low-Risk Extractions
1. **currencyUtils** - Universal, no dependencies
2. **timeUtils** - Pure functions, well-tested pattern

### Phase 2: Medium-Value Extractions
3. **errorUtils** - Requires careful testing of error handling
4. **textUtils** - Specific patterns but reusable structure

### Phase 3: Low-Priority Extractions
5. **styleUtils** - Low reusability, tightly coupled to component CSS

### Testing Requirements
- Unit tests for each utility module
- Integration tests in consuming components
- Regression tests for existing functionality

---

## CURRENT RECOMMENDATION

**DO NOT EXTRACT** at this time due to:
1. Component is stable and working well
2. Extraction requires comprehensive testing (8-12 hours)
3. Risk of introducing bugs in production-critical component
4. Marginal readability improvement vs. high effort

**Future Trigger Points:**
- When building second component needing same utilities
- During planned refactoring sprint with testing budget
- If component exceeds 1,500 lines (currently 1,043)

---

## ALTERNATIVE IMPROVEMENTS (Implemented)

Instead of extraction, we've improved code quality via:
✅ Comprehensive JSDoc annotations (20+ methods documented)
✅ Inline comments explaining business logic
✅ Architecture diagram (see ARCHITECTURE_DIAGRAM.md)
✅ Utility extraction guide (this document)

These provide 80% of the benefit with 5% of the risk.
