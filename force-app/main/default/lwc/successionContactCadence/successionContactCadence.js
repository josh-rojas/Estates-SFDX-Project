import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import { refreshApex } from "@salesforce/apex";
import getContactCadence from "@salesforce/apex/ContactCadenceController.getContactCadence";
import saveAttemptOutcome from "@salesforce/apex/ContactCadenceController.saveAttemptOutcome";

/**
 * Succession Contact Cadence
 *
 * Displays 5-attempt contact cadence as progress bar + kanban card grid.
 * Allows inline editing of current attempt outcome.
 *
 * Usage: Add to Succession Management tab on Case record page
 */
export default class SuccessionContactCadence extends NavigationMixin(LightningElement) {
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
  @track _memoizedProgress = null;
  @track _memoizedAnalytics = null;

  // ERROR HANDLING: Enhanced error state
  @track errorState = {
    hasError: false,
    errorType: null,
    errorMessage: "",
    retryCount: 0,
    canRetry: false,
    lastErrorTime: null
  };

  // Client-side wait durations in milliseconds (per feedback)
  // 1->2 = 5 days, else 30 days
  static ATTEMPT_WAIT_MS = {
    2: 5 * 24 * 60 * 60 * 1000, // attempt 2 unlocks 5 days after attempt 1 completed
    3: 30 * 24 * 60 * 60 * 1000, // attempt 3 unlocks 30 days after attempt 2 completed
    4: 30 * 24 * 60 * 60 * 1000, // attempt 4 unlocks 30 days after attempt 3 completed
    5: 30 * 24 * 60 * 60 * 1000 // attempt 5 unlocks 30 days after attempt 4 completed
  };

  // Countdown interval timer id (single ticker for perf)
  countdownIntervalId = null;

  // ERROR HANDLING: Enhanced error management methods
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

    this.showErrorToast(this.errorState.errorMessage);
  }

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

  retryLastOperation() {
    if (this.errorState.canRetry) {
      this.clearError();
      // Trigger data refresh
      refreshApex(this.wiredCadenceResult);
    }
  }

  /**
   * Enhanced form validation
   * PERFORMANCE: Validates form data before API calls
   */
  validateForm() {
    const errors = [];

    if (!this.state.editing.contactMade) {
      errors.push("Please select whether contact was made");
    }

    if (
      this.state.editing.contactMade === "no" &&
      !this.state.editing.notes.trim()
    ) {
      errors.push("Please provide notes when contact was not made");
    }

    if (this.state.editing.notes.length > 255) {
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

      // Start or restart countdown ticker when data loads
      this.startCountdownTicker();

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
   * Get progress percentage (0-100)
   */
  get progressPercent() {
    if (!this.cadenceData) return 0;

    if (this.cadenceData.contactEstablished) {
      return 100; // Contact established = 100% complete
    }

    // Calculate based on completed attempts (0-5)
    const completedAttempts = this.cadenceData.attempts
      ? this.cadenceData.attempts.filter((attempt) => attempt.isCompleted)
          .length
      : 0;
    return (completedAttempts / 5) * 100;
  }

  /**
   * Get enhanced thermometer progress with partial completion
   * Fills to encapsulate each node (0%, 25%, 50%, 75%, 100%)
   */
  get thermometerProgress() {
    if (!this.cadenceData) return 0;

    if (this.cadenceData.contactEstablished) {
      return 100; // Contact established = 100% complete
    }

    const attempts = this.cadenceData.attempts || [];

    // Only count completed attempts (25% per completed attempt)
    const completedAttempts = attempts.filter(
      (attempt) => attempt.isCompleted
    ).length;

    // Progress should only be based on completed attempts
    // No partial progress for current attempt until it's actually completed
    return completedAttempts * 25;
  }

  /**
   * Get progress bar width style
   */
  get progressBarStyle() {
    return `width: ${this.progressPercent}%`;
  }

  /**
   * Get thermometer progress bar width style
   */
  get thermometerProgressStyle() {
    return `width: ${this.thermometerProgress}%`;
  }

  /**
   * Get send email button label
   */
  get sendEmailButtonLabel() {
    return this.isNavigatingToEmail ? "Opening..." : "Open Email";
  }

  /**
   * Get progress status text
   */
  get progressStatusText() {
    if (!this.cadenceData) return "";

    if (this.cadenceData.contactEstablished) {
      return "✓ Contact Established";
    }

    const completedAttempts = this.cadenceData.attempts
      ? this.cadenceData.attempts.filter((attempt) => attempt.isCompleted)
          .length
      : 0;
    const current = this.cadenceData.currentAttemptNumber || 0;
    return `${completedAttempts} of 5 completed (Attempt ${current} current)`;
  }

  /**
   * Show progress line when there are completed attempts and current attempt
   */
  get showProgressLine() {
    if (!this.cadenceData || !this.cadenceData.attempts) return false;

    const hasCompleted = this.cadenceData.attempts.some(
      (attempt) => attempt.isCompleted
    );
    const hasCurrent = this.cadenceData.attempts.some(
      (attempt) => attempt.isCurrent
    );

    return hasCompleted && hasCurrent;
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
    return this.pendingEmailAttemptNumber
      ? map[this.pendingEmailAttemptNumber]
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
      if (a.isCompleted && a.completedDateISO) {
        // completedDateISO should be an ISO string if available; otherwise, server can add later
        prevCompletionByAttempt.set(
          a.attemptNumber,
          Date.parse(a.completedDateISO)
        );
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

      // Determine if this attempt is locked (user has progressed past it)
      const isLocked =
        attempt.attemptNumber < this.state.ui.highestAttemptStarted;

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
            hasCountdown: remainingMs > 0 && !attempt.isCurrent,
            remainingMs,
            totalMs,
            percent: pct,
            // Simple formatted remaining (days/hours)
            formatted: this.formatRemaining(remainingMs),
            unlockAtISO: new Date(endMs).toISOString()
          };
        }
      }

      return {
        ...attempt,
        countdown,
        // Card state classes
        cardClass: this.getCardClass({
          ...attempt,
          isCompleted: uiIsCompleted,
          isCurrent: uiIsCurrent,
          isPending: uiIsPending
        }),
        progressNodeClass: this.getProgressNodeClass({
          ...attempt,
          isCompleted: uiIsCompleted,
          isCurrent: uiIsCurrent,
          isPending: uiIsPending
        }),

        // Editing state - override isCurrent based on highestAttemptStarted (UI)
        isCurrent: uiIsCurrent,
        // Ensure exclusivity for UI booleans used in template/icon rendering
        isCompleted: uiIsCompleted,
        isPending: uiIsPending,
        isEditing: isEditing,
        showEditForm: isEditing && isCurrentEditable, // Only show form if editing AND current
        showReadOnly: attempt.isCompleted || isLocked, // Read-only if completed OR locked
        showDisabled:
          attempt.attemptNumber > this.state.ui.highestAttemptStarted, // Pending if beyond current

        // Display properties
        completionIcon: uiIsCompleted ? "✓" : "",
        currentIcon: uiIsCurrent ? "⏺" : "",
        pendingIcon: uiIsPending ? "○" : "",

        // Task details
        hasTask: attempt.taskRecord != null,
        taskNotes: attempt.userNotes || "", // User notes from ContentNote
        dueDate: attempt.formattedDueDate || "Not scheduled"
      };
    });

    // PERFORMANCE: Cache the result for future renders
    this._memoizedAttempts = result;
    this.state.performance.dataChanged = false;

    return result;
  }

  /**
   * Get CSS class for attempt card
   */
  getCardClass(attempt) {
    let baseClass =
      "attempt-card slds-box slds-var-p-around_medium slds-var-m-bottom_small";

    if (attempt.isCompleted) {
      return baseClass + " card-completed";
    } else if (attempt.isCurrent) {
      return baseClass + " card-current";
    } else if (attempt.isPending) {
      return baseClass + " card-pending";
    }

    return baseClass;
  }

  /**
   * Get CSS class for progress bar node
   */
  getProgressNodeClass(attempt) {
    if (attempt.isCompleted) {
      return "progress-node node-completed";
    }
    if (attempt.isCurrent) {
      return "progress-node node-current";
    }
    return "progress-node node-pending";
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

  get toggleButtonLabel() {
    return this.state.ui.isCollapsed ? "Show Details" : "Hide Details";
  }

  get collapsibleContentClass() {
    const baseClass =
      "slds-card__body slds-card__body_inner collapsible-content";
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
   * Utility: format remaining ms to a compact string (e.g., "12d 4h")
   */
  formatRemaining(ms) {
    const d = Math.floor(ms / (24 * 60 * 60 * 1000));
    const h = Math.floor((ms % (24 * 60 * 60 * 1000)) / (60 * 60 * 1000));
    const m = Math.floor((ms % (60 * 60 * 1000)) / (60 * 1000));
    if (d > 0) return `${d}d ${h}h`;
    if (h > 0) return `${h}h ${m}m`;
    return `${m}m`;
  }

  // Filter out system-generated description text, keep user notes
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
   */
  disconnectedCallback() {
    // No cleanup needed as we're not using any async operations
  }

  /**
   * Handle Save Outcome button click
   * ENHANCED: Includes comprehensive error handling and performance optimizations
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

          // Flow Task_Create_Next_Contact_Attempt will auto-create next task
          // No need to manually enable next attempt

          // PERFORMANCE: Reset editing state using centralized state
          this.state.editing.attemptId = null;
          this.state.editing.attemptNumber = null;
          this.state.editing.contactMade = "";
          this.state.editing.notes = "";

          // PERFORMANCE: Mark data as changed to invalidate memoization
          this.state.performance.dataChanged = true;

          // Refresh data
          return refreshApex(this.wiredCadenceResult);
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
    if (this.isNavigatingToEmail) {
      console.log("Email composer already opening, ignoring duplicate click");
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
    this.pendingEmailAttemptNumber = null;
    this.isNavigatingToEmail = false; // Reset navigation state
    this.showToast("Email Skipped", "You can process the next case", "info");
  }

  /**
   * Open Send List Email dialog with appropriate template based on attempt number
   *
   * NOTE: This handles both Person Accounts and Business Accounts with Contacts.
   * - Person Account: Uses Account.SendEmail action with AccountId
   * - Business Account: Uses Contact.SendEmail action with ContactId
   * Template cannot be pre-selected in Lightning Experience (manual selection required).
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

    // Determine recordId and objectApiName based on account type
    let recordId;
    let objectApiName;

    if (isPersonAccount) {
      // Person Account: use AccountId
      recordId = accountId;
      objectApiName = "Account";
    } else {
      // Business Account: use ContactId
      recordId = contactId;
      objectApiName = "Contact";
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

    // Map attempt numbers to email template display names
    const templateMap = {
      1: "Day 0 - Initial Contact",
      2: "Day 5 - First Follow-Up",
      3: "Day 35 - Second Contact",
      4: "Day 65 - Third Contact",
      5: "Day 95 - Final Contact"
    };

    const templateDisplayName = templateMap[attemptNumber];

    // Set navigation state to prevent double-click
    this.isNavigatingToEmail = true;

    // Navigate to Send Email action
    // For Person Account: Opens Account.SendEmail with AccountId
    // For Business Account: Opens Contact.SendEmail with ContactId
    try {
      this[NavigationMixin.Navigate]({
        type: "standard__recordAction",
        attributes: {
          recordId: recordId,
          objectApiName: objectApiName,
          actionName: `${objectApiName}.SendEmail`
        }
      });

      // NOTE: Do NOT clear pendingEmailAttemptNumber here
      // Keep email prompt visible in case agent closes composer without sending
      // Only clear when agent explicitly clicks "Skip" button

      // Show reminder about which template to select
      const recipientType = isPersonAccount ? "Person Account" : "Contact";
      this.showToast(
        "Email Composer Opening",
        `${recipientType} email opening. Select template: "${templateDisplayName}"`,
        "info"
      );

      // Reset navigation state after short delay (allow composer to open)
      // Note: We're leaving this timeout as it's needed for UX purposes to reset the navigation state
      // after the email composer opens, but it's not critical for core functionality
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      setTimeout(() => {
        this.isNavigatingToEmail = false;
      }, 2000);
    } catch (error) {
      console.error("Error navigating to email composer:", error);
      this.isNavigatingToEmail = false; // Reset on error
      this.showToast(
        "Error",
        `Failed to open email composer: ${error.message || "Unknown error"}`,
        "error"
      );
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
