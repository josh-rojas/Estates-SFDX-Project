import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import { refreshApex } from "@salesforce/apex";
import getContactCadence from "@salesforce/apex/ContactCadenceController.getContactCadence";
import saveAttemptOutcome from "@salesforce/apex/ContactCadenceController.saveAttemptOutcome";
import markFormEmailSent from "@salesforce/apex/ContactCadenceController.markFormEmailSent";

/**
 * Succession Contact Cadence
 *
 * Displays 5-attempt contact cadence as progress bar + kanban card grid.
 * Allows inline editing of current attempt outcome.
 *
 * Usage: Add to Succession Management tab on Case record page
 *
 * @author DAFGiving360
 * @date 2025-10-27
 */
export default class SuccessionContactCadence extends NavigationMixin(
  LightningElement
) {
  @api recordId; // Case ID (automatically passed when on record page)

  cadenceData;
  wiredCadenceResult;
  error;
  isLoading = true;

  // PERFORMANCE: Centralized state management
  @track state = {
    editing: {
      attemptId: null,
      attemptNumber: null,
      contactMade: "",
      notes: ""
    },
    ui: {
      isCollapsed: false,
      isNavigatingToEmail: false,
      pendingEmailAttempt: null,
      highestAttemptStarted: 0
    },
    performance: {
      dataChanged: false,
      lastRenderTime: 0
    }
  };

  // PERFORMANCE: Memoization cache
  @track _memoizedAttempts = null;

  // ERROR HANDLING: Enhanced error state
  @track errorState = {
    hasError: false,
    errorType: null,
    errorMessage: "",
    retryCount: 0,
    canRetry: false,
    lastErrorTime: null
  };

  // ASYNC OPERATION TRACKING: Store timeout IDs for cleanup
  _refreshTimeoutId = null;
  _emailNavigationTimeoutId = null;

  /**
   * BUSINESS LOGIC: Contact cadence wait durations (configured per compliance requirements)
   *
   * Rationale for wait periods:
   * - Attempt 1→2: 5 days - Quick follow-up while initial contact is fresh
   * - Attempts 2→3, 3→4, 4→5: 30 days - Allows reasonable time for response without pressure
   *
   * Total cadence duration: 95 days (5 + 30 + 30 + 30 days)
   *
   * CONFIGURATION NOTE: These durations are hardcoded to match Task.ActivityDate values
   * set by flows (Case_Create_Initial_Contact_Attempt, Task_Create_Next_Contact_Attempt).
   * Any changes here must be coordinated with corresponding flow date formulas.
   *
   * FUTURE ENHANCEMENT: Consider moving to Custom Metadata Type for admin configuration
   * without code deployment (Succession_Contact_Cadence__mdt with Wait_Days__c field)
   */
  static ATTEMPT_WAIT_MS = {
    2: 5 * 24 * 60 * 60 * 1000, // 5 days (attempt 2 unlocks after attempt 1)
    3: 30 * 24 * 60 * 60 * 1000, // 30 days (attempt 3 unlocks after attempt 2)
    4: 30 * 24 * 60 * 60 * 1000, // 30 days (attempt 4 unlocks after attempt 3)
    5: 30 * 24 * 60 * 60 * 1000 // 30 days (attempt 5 unlocks after attempt 4)
  };

  /**
   * Centralized error handler for all component operations
   *
   * Categorizes errors, increments retry counter, and displays user-friendly messages.
   * Maintains error state for UI rendering and retry logic.
   *
   * @param {Error} error - The error object from Apex call or JavaScript operation
   * @param {string} context - Context where error occurred (method name) for debugging
   * @returns {void}
   *
   * @example
   * this.handleError(error, 'handleSaveOutcome');
   */
  handleError(error, context = "") {
    console.error(`Contact Cadence Error [${context}]:`, error);

    this.errorState = {
      hasError: true,
      errorType: this.categorizeError(error),
      errorMessage: this.getUserFriendlyMessage(error),
      retryCount: this.errorState.retryCount + 1,
      canRetry: this.errorState.retryCount < 3,
      lastErrorTime: Date.now()
    };

    this.showToast("Error", this.errorState.errorMessage, "error");
  }

  /**
   * Categorizes error type based on error properties
   *
   * Maps Salesforce error codes and messages to user-friendly error types.
   * Used for conditional error handling and appropriate user messaging.
   *
   * @param {Error} error - Error object to categorize
   * @returns {string} Error type: PERMISSION|VALIDATION|DUPLICATE|SERVER|NOT_FOUND|FORBIDDEN|UNKNOWN
   *
   * @private
   */
  categorizeError(error) {
    if (error.body?.message?.includes("INSUFFICIENT_ACCESS"))
      return "PERMISSION";
    if (error.body?.message?.includes("REQUIRED_FIELD_MISSING"))
      return "VALIDATION";
    if (error.body?.message?.includes("DUPLICATE_VALUE")) return "DUPLICATE";
    if (error.status === 500) return "SERVER";
    if (error.status === 404) return "NOT_FOUND";
    if (error.status === 403) return "FORBIDDEN";
    return "UNKNOWN";
  }

  /**
   * Converts technical error types into user-friendly messages
   *
   * Provides actionable guidance for each error type. Messages are non-technical
   * and guide users toward resolution.
   *
   * @param {Error} error - Error object to generate message for
   * @returns {string} User-friendly error message with guidance
   *
   * @private
   */
  getUserFriendlyMessage(error) {
    const errorType = this.categorizeError(error);

    switch (errorType) {
      case "PERMISSION":
        return "You do not have permission to perform this action. Please contact your administrator.";
      case "VALIDATION":
        return "Please check your input and try again. Some required information may be missing.";
      case "DUPLICATE":
        return "This action has already been completed. Please refresh the page to see the latest updates.";
      case "SERVER":
        return "A server error occurred. Please try again in a few moments.";
      case "NOT_FOUND":
        return "The requested information could not be found. Please refresh the page.";
      case "FORBIDDEN":
        return "Access denied. You may not have the necessary permissions.";
      default:
        return "An unexpected error occurred. Please try again or contact support if the problem persists.";
    }
  }

  /**
   * Resets error state to initial values
   *
   * Called after successful operations or when user manually dismisses errors.
   * Allows component to return to normal operation after error recovery.
   *
   * @returns {void}
   */
  clearError() {
    this.errorState = {
      hasError: false,
      errorType: null,
      errorMessage: "",
      retryCount: 0,
      canRetry: false,
      lastErrorTime: null
    };
  }

  /**
   * Retries the last failed operation by refreshing data
   *
   * Only allows retry if under maximum retry limit (3 attempts).
   * Clears error state and triggers data refresh via wire adapter.
   *
   * @returns {void}
   */
  retryLastOperation() {
    if (this.errorState.canRetry) {
      this.clearError();
      // Trigger data refresh
      refreshApex(this.wiredCadenceResult);
    }
  }

  /**
   * Validates contact attempt outcome form before submission
   *
   * Business rules:
   * - Contact made selection is required
   * - Notes are required when contact was NOT made
   * - Notes cannot exceed 255 characters (Salesforce field limit)
   *
   * PERFORMANCE: Prevents unnecessary API calls for invalid data
   *
   * @returns {{isValid: boolean, errors: string[]}} Validation result with error messages
   *
   * @example
   * const validation = this.validateForm();
   * if (!validation.isValid) {
   *   this.showToast('Error', validation.errors.join(', '), 'error');
   * }
   */
  validateForm() {
    const errors = [];

    if (!this.state.editing.contactMade) {
      errors.push("Please select whether contact was made");
    }

    if (
      this.state.editing.contactMade === "no" &&
      (!this.state.editing.notes || !this.state.editing.notes.trim())
    ) {
      errors.push("Please provide notes when contact was not made");
    }

    if (this.state.editing.notes && this.state.editing.notes.length > 255) {
      errors.push("Notes cannot exceed 255 characters");
    }

    return {
      isValid: errors.length === 0,
      errors: errors
    };
  }

  // Radio button options for "Was contact made?"
  contactMadeOptions = [
    { label: "Yes", value: "yes" },
    { label: "No", value: "no" }
  ];

  /**
   * Wire adapter to fetch contact cadence data
   */
  @wire(getContactCadence, { caseId: "$recordId" })
  wiredCadence(result) {
    this.wiredCadenceResult = result;
    this.isLoading = false;

    if (result.data) {
      this.cadenceData = result.data;
      this.error = undefined;
      this.clearError(); // Clear any previous errors

      // PERFORMANCE: Mark data as changed to invalidate memoization
      this.state.performance.dataChanged = true;

      // Initialize highestAttemptStarted to first incomplete attempt
      if (
        this.cadenceData.attempts &&
        this.state.ui.highestAttemptStarted === 0
      ) {
        const firstIncomplete = this.cadenceData.attempts.find(
          (a) => !a.isCompleted
        );
        if (firstIncomplete) {
          this.state.ui.highestAttemptStarted = firstIncomplete.attemptNumber;
        }
      }
    } else if (result.error) {
      this.handleError(result.error, "wiredCadence");
      this.cadenceData = undefined;
    }
  }

  /**
   * Check if record type is invalid
   */
  get showInvalidRecordType() {
    return this.cadenceData && this.cadenceData.isValidRecordType === false;
  }

  /**
   * Get invalid record type message
   */
  get invalidRecordTypeMessage() {
    return this.cadenceData?.invalidRecordTypeMessage || "";
  }

  /**
   * Check if component has data to display
   */
  get hasData() {
    return (
      this.cadenceData &&
      this.cadenceData.isValidRecordType !== false &&
      this.cadenceData.attempts &&
      this.cadenceData.attempts.length > 0
    );
  }

  /**
   * Check if any tasks are actually scheduled (not just placeholder attempts)
   */
  get hasScheduledTasks() {
    if (!this.cadenceData || !this.cadenceData.attempts) return false;

    // Check if any attempt has an actual task record (not just placeholder)
    return this.cadenceData.attempts.some(
      (attempt) => attempt.taskRecord !== null
    );
  }

  /**
   * Get send email button label
   */
  get sendEmailButtonLabel() {
    return this.state.ui.isNavigatingToEmail ? "Opening..." : "Open Email";
  }

  /**
   * Template label hint for the pending email prompt (desktop)
   */
  get pendingEmailTemplateLabel() {
    const map = {
      1: "Day 0 - Initial Contact",
      2: "Day 5 - First Follow-Up",
      3: "Day 35 - Second Contact",
      4: "Day 65 - Third Contact",
      5: "Day 95 - Final Contact"
    };
    return this.state.ui.pendingEmailAttempt
      ? map[this.state.ui.pendingEmailAttempt]
      : "";
  }

  /**
   * Check if email sending is available (all validation passed)
   */
  get canSendEmail() {
    if (!this.cadenceData) return false;
    return (
      this.cadenceData.hasEmail &&
      this.cadenceData.hasValidEmailFormat &&
      !this.cadenceData.hasOptedOut
    );
  }

  /**
   * Check if there are email warnings to display
   */
  get hasEmailWarning() {
    return this.cadenceData?.emailWarning != null;
  }

  /**
   * Get email warning message
   */
  get emailWarningMessage() {
    return this.cadenceData?.emailWarning || "";
  }

  /**
   * Get safe error message with null checks
   */
  get errorMessage() {
    return this.error?.body?.message || this.error?.message || "";
  }

  /**
   * Get attempts with computed properties for template
   * PERFORMANCE: Memoized to prevent unnecessary recalculations
   */
  get attemptsWithProps() {
    if (!this.cadenceData || !this.cadenceData.attempts) return [];

    // PERFORMANCE: Check if we can use memoized result
    if (this._memoizedAttempts && !this.state.performance.dataChanged) {
      return this._memoizedAttempts;
    }

    // Build a map of previous completions by attempt number for countdown start
    const prevCompletionByAttempt = new Map();
    for (const a of this.cadenceData.attempts) {
      if (a.isCompleted && a.taskRecord?.CompletedDateTime) {
        const parsedDate = Date.parse(a.taskRecord.CompletedDateTime);
        if (!isNaN(parsedDate)) {
          prevCompletionByAttempt.set(a.attemptNumber, parsedDate);
        }
      }
    }

    // Compute props
    const result = this.cadenceData.attempts.map((attempt) => {
      // Check if this attempt is being edited
      // Match by task ID if exists, or by attempt number if no task yet
      const isEditing =
        (attempt.taskRecord?.Id &&
          this.state.editing.attemptId === attempt.taskRecord?.Id) ||
        this.state.editing.attemptNumber === attempt.attemptNumber;

      // Determine if this is the current editable attempt
      const isCurrentEditable =
        attempt.attemptNumber === this.state.ui.highestAttemptStarted &&
        !attempt.isCompleted;

      // Normalize visual state (mutually exclusive flags for UI)
      // Source flags from server may overlap when we override current status client-side.
      const uiIsCompleted = !!attempt.isCompleted;
      const uiIsCurrent = !uiIsCompleted && !!isCurrentEditable;
      const uiIsPending = !uiIsCompleted && !uiIsCurrent;

      // Compute countdown for attempts > 1 that are not yet current and not completed
      // Start time = previous attempt completion timestamp
      // Duration = ATTEMPT_WAIT_MS mapping
      let countdown = null;
      if (attempt.attemptNumber > 1) {
        const prevAttemptNum = attempt.attemptNumber - 1;
        const startMs = prevCompletionByAttempt.get(prevAttemptNum);
        const requiredWait =
          SuccessionContactCadence.ATTEMPT_WAIT_MS[attempt.attemptNumber] ??
          30 * 24 * 60 * 60 * 1000; // default 30d safety

        if (startMs && !attempt.isCompleted) {
          const now = Date.now();
          const endMs = startMs + requiredWait;
          const remainingMs = Math.max(0, endMs - now);
          const totalMs = requiredWait;
          const pct =
            totalMs > 0
              ? Math.min(
                  100,
                  Math.round(((totalMs - remainingMs) / totalMs) * 100)
                )
              : 0;

          countdown = {
            hasCountdown: remainingMs > 0 && !uiIsCurrent,
            remainingMs,
            totalMs,
            percent: pct,
            // Simple formatted remaining (days/hours)
            formatted: this.formatRemaining(remainingMs),
            unlockAtISO: new Date(endMs).toISOString()
          };
        }
      }

      // Calculate if date has arrived (for current attempt)
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      let isDateArrived = false;

      if (attempt.taskRecord && attempt.taskRecord.ActivityDate) {
        const activityDate = new Date(attempt.taskRecord.ActivityDate);
        activityDate.setHours(0, 0, 0, 0);
        isDateArrived = activityDate <= today;
      }

      // Determine if this attempt is locked (has task but date hasn't arrived and not completed)
      const isLocked =
        !!attempt.taskRecord && !isDateArrived && !attempt.isCompleted;

      // FIX: If attempt is locked, it should NOT be current (prevents duplicate countdown bars)
      // Locked attempts should show only the locked card, not the current card
      const finalIsCurrent = uiIsCurrent && !isLocked;

      const mappedAttempt = {
        ...attempt,
        countdown,
        // Card state classes
        cardClass: this.getCardClass({
          ...attempt,
          isCompleted: uiIsCompleted,
          isCurrent: finalIsCurrent,
          isPending: uiIsPending
        }),

        // Editing state - override isCurrent based on highestAttemptStarted (UI)
        isCurrent: finalIsCurrent, // FIX: Use finalIsCurrent instead of uiIsCurrent to exclude locked attempts
        // Ensure exclusivity for UI booleans used in template/icon rendering
        isCompleted: uiIsCompleted,
        isPending: uiIsPending,
        isEditing: isEditing,
        showEditForm: isEditing && isCurrentEditable, // Only show form if editing AND current
        showReadOnly: attempt.isCompleted && !isLocked, // FIX: Read-only ONLY if completed (not locked)
        showDisabled:
          attempt.attemptNumber > this.state.ui.highestAttemptStarted, // Pending if beyond current
        isDateArrived: isDateArrived, // Whether the activity date has arrived
        isLocked: isLocked, // Task exists but date hasn't arrived

        // Display properties
        completionIcon: uiIsCompleted ? "✓" : "",
        currentIcon: finalIsCurrent ? "⏺" : "", // FIX: Use finalIsCurrent to match isCurrent property
        pendingIcon: uiIsPending ? "○" : "",

        // Task details
        hasTask: attempt.taskRecord != null,
        taskNotes: attempt.userNotes || "", // User notes from ContentNote
        dueDate: attempt.formattedDueDate || "Not scheduled"
      };

      return mappedAttempt;
    });

    // PERFORMANCE: Cache the result for future renders
    this._memoizedAttempts = result;
    this.state.performance.dataChanged = false;

    return result;
  }

  /**
   * Get CSS class for attempt card
   * ENHANCED: Differentiates between successful and unsuccessful contact attempts
   */
  getCardClass(attempt) {
    let baseClass =
      "attempt-card slds-box slds-var-p-around_medium slds-var-m-bottom_small";

    if (attempt.isCompleted) {
      // Check if contact was established (successful) or not (unsuccessful)
      const contactEstablished =
        attempt.taskRecord?.Succession_Contact_Established__c;
      if (contactEstablished === false) {
        return baseClass + " card-completed-negative";
      }
      return baseClass + " card-completed";
    } else if (attempt.isCurrent) {
      return baseClass + " card-current";
    } else if (attempt.isPending) {
      return baseClass + " card-pending";
    }

    return baseClass;
  }

  /**
   * Handle Edit button click
   * PERFORMANCE: Uses centralized state management
   */
  handleEdit(event) {
    try {
      const taskId = event.currentTarget.dataset.taskId;
      const attemptNumber = parseInt(
        event.currentTarget.dataset.attemptNumber,
        10
      );

      // PERFORMANCE: Update centralized state
      this.state.editing.attemptId = taskId;
      this.state.editing.attemptNumber = attemptNumber;

      // Lock all previous attempts by updating highestAttemptStarted
      if (attemptNumber > this.state.ui.highestAttemptStarted) {
        this.state.ui.highestAttemptStarted = attemptNumber;
      }

      this.state.editing.contactMade = "";
      this.state.editing.notes = "";

      // PERFORMANCE: Mark data as changed to invalidate memoization
      this.state.performance.dataChanged = true;
    } catch (error) {
      this.handleError(error, "handleEdit");
    }
  }

  /**
   * Handle Cancel button click
   * PERFORMANCE: Uses centralized state management
   */
  handleCancel() {
    try {
      // PERFORMANCE: Reset editing state
      this.state.editing.attemptId = null;
      this.state.editing.attemptNumber = null;
      this.state.editing.contactMade = "";
      this.state.editing.notes = "";

      // PERFORMANCE: Mark data as changed to invalidate memoization
      this.state.performance.dataChanged = true;
    } catch (error) {
      this.handleError(error, "handleCancel");
    }
  }

  /**
   * Handle radio button change
   * PERFORMANCE: Uses centralized state management
   */
  handleContactMadeChange(event) {
    try {
      this.state.editing.contactMade = event.detail.value;
      this.state.performance.dataChanged = true;
    } catch (error) {
      this.handleError(error, "handleContactMadeChange");
    }
  }

  /**
   * Handle notes textarea change
   * PERFORMANCE: Uses centralized state management
   */
  handleNotesChange(event) {
    try {
      this.state.editing.notes = event.target.value;
      this.state.performance.dataChanged = true;
    } catch (error) {
      this.handleError(error, "handleNotesChange");
    }
  }

  /**
   * Get contact established boolean from radio value
   */
  get contactEstablished() {
    return this.state.editing.contactMade === "yes";
  }

  // PERFORMANCE: Getters removed - use state properties directly in template

  get toggleIcon() {
    return this.state.ui.isCollapsed
      ? "utility:chevronright"
      : "utility:chevrondown";
  }

  get toggleTitle() {
    return this.state.ui.isCollapsed
      ? "Expand Contact Cadence"
      : "Collapse Contact Cadence";
  }

  get collapsibleContentClass() {
    const baseClass = "collapsible-content";
    return this.state.ui.isCollapsed ? `${baseClass} collapsed` : baseClass;
  }

  /**
   * Toggle collapsible state
   * PERFORMANCE: Uses centralized state management
   */
  toggleCollapse() {
    this.state.ui.isCollapsed = !this.state.ui.isCollapsed;
    this.state.performance.dataChanged = true;
  }

  /**
   * Formats milliseconds into human-readable compact time string
   *
   * Displays the two largest units for clarity (e.g., "12d 4h" not "12d 4h 30m").
   * Used for countdown timers showing time remaining until attempt unlocks.
   *
   * @param {number} ms - Milliseconds to format
   * @returns {string} Formatted string (e.g., "12d 4h", "3h 25m", "45m")
   *
   * @example
   * formatRemaining(1123200000) // Returns "13d 0h"
   * formatRemaining(11700000)   // Returns "3h 15m"
   * formatRemaining(2700000)    // Returns "45m"
   */
  formatRemaining(ms) {
    const d = Math.floor(ms / (24 * 60 * 60 * 1000));
    const h = Math.floor((ms % (24 * 60 * 60 * 1000)) / (60 * 60 * 1000));
    const m = Math.floor((ms % (60 * 60 * 1000)) / (60 * 1000));
    if (d > 0) return `${d}d ${h}h`;
    if (h > 0) return `${h}h ${m}m`;
    return `${m}m`;
  }

  /**
   * Filters out system-generated text from Task descriptions to extract user notes
   *
   * Task.Description contains both system-generated instruction text and agent notes.
   * This method removes known system patterns to isolate the actual agent notes.
   *
   * DUAL STORAGE PATTERN: User notes are stored in both Task.Description (immediate)
   * and ContentNote (structured). This filter extracts notes from Description field.
   *
   * @param {string} description - Full Task.Description field value
   * @returns {string} User notes only (empty string if no user notes present)
   *
   * @private
   */
  filterUserNotes(description) {
    if (!description) return "";

    // System-generated text patterns to remove
    const systemPatterns = [
      "Initial contact attempt (Day 0). Agent can complete this task immediately.",
      "Contact attempt 2 scheduled for Day 5. Agent cannot complete this task until the scheduled date arrives.",
      "Contact attempt 3 scheduled for Day 35. Agent cannot complete this task until the scheduled date arrives.",
      "Contact attempt 4 scheduled for Day 65. Agent cannot complete this task until the scheduled date arrives.",
      "Contact attempt 5 scheduled for Day 95. Agent cannot complete this task until the scheduled date arrives.",
      "Contact attempt for succession case."
    ];

    let filteredDescription = description;

    // Remove each system pattern
    systemPatterns.forEach((pattern) => {
      filteredDescription = filteredDescription.replace(pattern, "").trim();
    });

    // If only system text was present, return empty string
    return filteredDescription.length > 0 ? filteredDescription : "";
  }

  /**
   * Handle component initialization and data loading
   * Countdowns are calculated on-demand when data changes, not with timers
   */
  connectedCallback() {
    this.state.ui.isCollapsed = false;
  }

  /**
   * Clean up any async handles if component is destroyed
   * Prevents memory leaks and errors from timeouts firing after unmount
   */
  disconnectedCallback() {
    // Clear any pending timeouts
    if (this._refreshTimeoutId) {
      clearTimeout(this._refreshTimeoutId);
      this._refreshTimeoutId = null;
    }
    if (this._emailNavigationTimeoutId) {
      clearTimeout(this._emailNavigationTimeoutId);
      this._emailNavigationTimeoutId = null;
    }
  }

  /**
   * Handle Save Outcome button click
   * ENHANCED: Includes comprehensive error handling and performance optimizations
   * FIX: Properly advances to next attempt after save
   */
  handleSaveOutcome(event) {
    try {
      const taskId = event.currentTarget.dataset.taskId;
      const attemptNumber = this.state.editing.attemptNumber;
      const contactWasEstablished = this.contactEstablished;

      // PERFORMANCE: Validate form before making API call
      const validation = this.validateForm();
      if (!validation.isValid) {
        this.showToast(
          "Validation Error",
          validation.errors.join(", "),
          "error"
        );
        return;
      }

      // Notes are optional - user can save with or without notes
      this.isLoading = true;
      this.clearError(); // Clear any previous errors

      saveAttemptOutcome({
        caseId: this.recordId,
        taskId: taskId,
        attemptNumber: attemptNumber,
        contactEstablished: contactWasEstablished,
        notes: this.state.editing.notes
      })
        .then(() => {
          // If contact was NOT established (NO selected), show option to send email
          if (!contactWasEstablished) {
            this.state.ui.pendingEmailAttempt = attemptNumber;
            this.showToastWithEmailOption(attemptNumber);
          } else {
            this.showToast(
              "Success",
              "Contact attempt outcome saved",
              "success"
            );
          }

          // FIX: Advance to next attempt only after successful save
          // This prevents attempt 2 from being editable while attempt 1 is still being saved
          this.state.ui.highestAttemptStarted = attemptNumber + 1;

          // PERFORMANCE: Reset editing state using centralized state
          this.state.editing.attemptId = null;
          this.state.editing.attemptNumber = null;
          this.state.editing.contactMade = "";
          this.state.editing.notes = "";

          // PERFORMANCE: Mark data as changed to invalidate memoization
          this.state.performance.dataChanged = true;

          // FIX: Add delay before refreshApex to allow ContentNote indexing
          // ContentNotes may take a moment to be indexed by Salesforce
          // Task.Description is saved immediately, so notes will appear after delay
          // TECHNICAL LIMITATION: Salesforce ContentNote indexing is asynchronous
          // 1.5s delay allows time for ContentVersion -> ContentDocument linkage
          // Alternative considered: Poll API, but adds complexity for minimal UX benefit
          // eslint-disable-next-line @lwc/lwc/no-async-operation
          this._refreshTimeoutId = setTimeout(() => {
            refreshApex(this.wiredCadenceResult)
              .then(() => {
                console.log("Contact cadence data refreshed with notes");
                this._refreshTimeoutId = null;
              })
              .catch((refreshError) => {
                console.error("Error refreshing cadence data:", refreshError);
                this._refreshTimeoutId = null;
                // Still show success, but note refresh failed
                this.showToast(
                  "Partial Success",
                  "Outcome saved but display refresh failed. Please refresh the page to see notes.",
                  "warning"
                );
              });
          }, 1500); // 1.5 second delay for ContentNote indexing
        })
        .catch((error) => {
          this.handleError(error, "handleSaveOutcome");
          this.isLoading = false;
        })
        .finally(() => {
          this.isLoading = false;
        });
    } catch (error) {
      this.handleError(error, "handleSaveOutcome");
      this.isLoading = false;
    }
  }

  /**
   * Show toast with option to send follow-up email
   */
  showToastWithEmailOption(attemptNumber) {
    const templateMap = {
      1: "Day 0 Initial Contact",
      2: "Day 5 First Follow-Up",
      3: "Day 35 Second Contact",
      4: "Day 65 Third Contact",
      5: "Day 95 Final Contact"
    };

    const templateLabel = templateMap[attemptNumber];

    this.showToast(
      "Outcome Saved",
      `Next task created. Send ${templateLabel} email? (Optional)`,
      "success"
    );
  }

  /**
   * Handle Send Email button click
   * Includes double-click prevention and email validation
   */
  handleSendEmail(event) {
    // Prevent double-click (button already disabled during navigation)
    if (this.state.ui.isNavigatingToEmail) {
      return;
    }

    // Validate email is available
    if (!this.canSendEmail) {
      this.showToast(
        "Error",
        this.emailWarningMessage || "Email sending not available",
        "error"
      );
      return;
    }

    const attemptNumber = parseInt(
      event.currentTarget.dataset.attemptNumber,
      10
    );
    this.openListEmailDialog(attemptNumber);
  }

  /**
   * Handle Skip Email button click
   * This is the ONLY way to dismiss the email prompt (keeps it visible if agent closes composer)
   */
  handleSkipEmail() {
    this.state.ui.pendingEmailAttempt = null;
    this.state.ui.isNavigatingToEmail = false; // Reset navigation state
    this.showToast("Email Skipped", "You can process the next case", "info");
  }

  /**
   * Open Lightning Email Composer with appropriate context
   *
   * Uses Quick Action navigation pattern (Account.SendEmail / Contact.SendEmail) for reliability.
   * This ensures stable composer opening across all Salesforce environments and org configurations.
   *
   * NOTE: This handles both Person Accounts and Business Accounts with Contacts.
   * - Person Account: Uses Account.SendEmail Quick Action
   * - Business Account: Uses Contact.SendEmail Quick Action
   *
   * TEMPLATE SELECTION: Opens composer with manual template selection UX.
   * Agent must select template from dropdown. Pre-selection not implemented because:
   * - Requires EmailTemplate API lookup (additional SOQL query + performance impact)
   * - Template IDs vary across orgs (deployment complexity)
   * - Manual selection ensures agent reviews template before sending (compliance benefit)
   * - Quick Action pattern doesn't support automatic template selection
   *
   * IMPLEMENTATION NOTE: Changed from standard__composer to Quick Action pattern to fix
   * "Page doesn't exist" navigation errors in certain org configurations.
   */
  openListEmailDialog(attemptNumber) {
    // Validate cadence data exists
    if (!this.cadenceData) {
      this.showToast(
        "Error",
        "Cannot open email composer: Case data not loaded",
        "error"
      );
      console.error("Cannot open list email: cadenceData is null or undefined");
      return;
    }

    // Determine which record to use based on account type
    const isPersonAccount = this.cadenceData.isPersonAccount;
    const accountId = this.cadenceData.accountId;
    const contactId = this.cadenceData.contactId;

    // Determine recordId for recipient context based on account type
    let recordId;

    if (isPersonAccount) {
      // Person Account: use AccountId
      // IMPORTANT: Enhanced Email must be enabled in org for Account email sending
      recordId = accountId;
    } else {
      // Business Account: use ContactId
      recordId = contactId;
    }

    // Validate recordId exists
    if (!recordId) {
      const errorMsg = isPersonAccount
        ? "Cannot open email composer: Account ID not found on case. Ensure Case has an Account."
        : "Cannot open email composer: Contact ID not found on case. Ensure Case has a Contact.";
      this.showToast("Error", errorMsg, "error");
      console.error("Cannot open list email: Record ID not found", {
        isPersonAccount,
        accountId,
        contactId,
        caseId: this.recordId
      });
      return;
    }

    // Map attempt numbers to email template display names (for toast message)
    const templateMap = {
      1: "Day 0 - Initial Contact",
      2: "Day 5 - First Follow-Up",
      3: "Day 35 - Second Contact",
      4: "Day 65 - Third Contact",
      5: "Day 95 - Final Contact"
    };

    const templateDisplayName = templateMap[attemptNumber];

    // Set navigation state to prevent double-click
    this.state.ui.isNavigatingToEmail = true;

    try {
      // FIX: Use Quick Action navigation pattern for better cross-environment compatibility
      // standard__composer sometimes fails with "Page doesn't exist" error in certain orgs
      // Quick Action pattern (Account.SendEmail / Contact.SendEmail) is more reliable

      // Determine which action to use based on record type
      const actionName = isPersonAccount
        ? "Account.SendEmail"
        : "Contact.SendEmail";

      this[NavigationMixin.Navigate]({
        type: "standard__quickAction",
        attributes: {
          actionName: actionName,
          objectApiName: isPersonAccount ? "Account" : "Contact",
          recordId: recordId // Recipient: Contact or Account (Person Account)
          // Note: relatedEntityId not available in quick action pattern
          // Agent must manually reference Case fields if needed
        }
      });

      // NOTE: Do NOT clear pendingEmailAttempt here
      // Keep email prompt visible in case agent closes composer without sending
      // Only clear when agent explicitly clicks "Skip" button

      // Show reminder about which template to select
      this.showToast(
        "Email Composer Opening",
        `Opening email composer. Select template: "${templateDisplayName}"`,
        "info"
      );

      // NOTE: No Chatter post created for optional contact cadence emails
      // Pathway form invitation email (automated) is handled separately by Flow

      // Reset navigation state after short delay (allow composer to open)
      // UX Enhancement: Prevents double-clicking "Send Email" button while composer loads
      // 2s delay allows email composer window to fully load before re-enabling button
      // Alternative considered: Navigation complete event, but not available for email composer
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      this._emailNavigationTimeoutId = setTimeout(() => {
        this.state.ui.isNavigatingToEmail = false;
        this._emailNavigationTimeoutId = null;
      }, 2000);
    } catch (error) {
      console.error("Error navigating to email composer:", error);
      this.state.ui.isNavigatingToEmail = false; // Reset on error
      this.showToast(
        "Error",
        `Failed to open email composer: ${error.message || "Unknown error"}`,
        "error"
      );
    }
  }

  /**
   * Mark pathway form email as sent
   * Calls Apex to set Form_Sent_Date__c and create Chatter notification
   * Called after email composer opens successfully
   */
  async markEmailSent() {
    try {
      const result = await markFormEmailSent({ caseId: this.recordId });
      console.log("Form email marked as sent:", result);

      // Refresh cadence data to update UI
      if (this.wiredCadenceResult) {
        await refreshApex(this.wiredCadenceResult);
      }
    } catch (error) {
      // Log error but don't show toast to avoid interrupting agent workflow
      console.error("Error marking form email as sent:", error);
      // If this fails, the automatic flow will handle it when Contact_Established__c = true
    }
  }

  /**
   * Show toast notification
   */
  showToast(title, message, variant) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: title,
        message: message,
        variant: variant
      })
    );
  }
}
