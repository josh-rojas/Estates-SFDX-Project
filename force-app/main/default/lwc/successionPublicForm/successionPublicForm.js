import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getFormData from "@salesforce/apex/SuccessionPublicFormController.getFormData";
import savePathwaySelection from "@salesforce/apex/SuccessionPublicFormController.savePathwaySelection";

export default class SuccessionPublicForm extends LightningElement {
  // URL parameters
  @api caseId = null;

  // Form data from Apex
  formData = null;
  loading = true;
  error = null;
  formSubmitted = false;

  // Enhanced error state
  errorState = {
    type: null, // 'url', 'network', 'server', 'validation', 'permission', 'notfound', 'alreadysubmitted'
    title: "",
    message: "",
    guidance: "",
    canRetry: false,
    contactSupport: true
  };

  // Retry tracking
  retryCount = 0;
  maxRetries = 3;

  // ASYNC OPERATION TRACKING: Store timeout ID for cleanup
  _retryTimeoutId = null;

  // Form fields
  selectedPathway = "";
  additionalNotes = "";

  // Pathway options
  pathwayOptions = [
    { label: "Final Grant to Charity", value: "Final Grant" },
    { label: "Transfer to New DAF Account", value: "New DAF Account" },
    { label: "Disclaim Successor Rights", value: "Disclaim Assets" }
  ];

  connectedCallback() {
    // Log form load attempt for debugging
    console.log("Succession Public Form: Component loaded");

    // Extract caseId from URL parameters
    const params = new URLSearchParams(window.location.search);
    this.caseId = params.get("caseId");

    console.log("Succession Public Form: Case ID from URL:", this.caseId);

    // Validate caseId before attempting to load data
    if (!this.caseId) {
      this.setError("url", "missing-parameter");
      this.loading = false;
      return; // Stop here - don't try to load data
    }

    if (!this.isValidSalesforceId(this.caseId)) {
      this.setError("url", "invalid-format");
      this.loading = false;
      return; // Stop here - don't try to load data
    }

    // CaseId is valid - load form data imperatively
    this.loadFormData();
  }

  /**
   * Clean up any pending timeouts when component is destroyed
   * Prevents memory leaks and errors from timeouts firing after unmount
   */
  disconnectedCallback() {
    if (this._retryTimeoutId) {
      clearTimeout(this._retryTimeoutId);
      this._retryTimeoutId = null;
    }
  }

  /**
   * Validate Salesforce ID format (15 or 18 characters)
   */
  isValidSalesforceId(id) {
    if (!id) return false;
    // Salesforce IDs are either 15 or 18 characters, alphanumeric
    const sfIdPattern = /^[a-zA-Z0-9]{15}([a-zA-Z0-9]{3})?$/;
    return sfIdPattern.test(id);
  }

  /**
   * Load form data imperatively (replaces @wire to prevent race condition)
   * This ensures we only call Apex AFTER validating the caseId from URL
   */
  async loadFormData() {
    this.loading = true;
    this.error = null;

    try {
      console.log("Succession Public Form: Loading data for case", this.caseId);

      // Call Apex imperatively with validated caseId
      const data = await getFormData({ caseId: this.caseId });

      console.log("Succession Public Form: Data loaded successfully");
      this.formData = data;
      this.retryCount = 0; // Reset retry count on success
    } catch (error) {
      const errorInfo = this.parseApexError(error);
      this.setError(errorInfo.type, errorInfo.subtype, errorInfo.originalError || error);
      this.formData = null;
    } finally {
      this.loading = false;
    }
  }

  /**
   * Categorize and set detailed error information
   */
  setError(type, subtype, originalError = null) {
    console.error("Succession Public Form Error:", {
      type,
      subtype,
      originalError,
      caseId: this.caseId,
      retryCount: this.retryCount
    });

    // URL Errors
    if (type === "url") {
      if (subtype === "missing-parameter") {
        this.errorState = {
          type: "url",
          title: "Missing Case Information",
          message:
            "The link you used is missing required information (Case ID).",
          guidance:
            "This usually means the link is incomplete or was copied incorrectly. Please check your email for the complete link, or access this form through the link provided by our Estate Administration team.",
          canRetry: false,
          contactSupport: true
        };
      } else if (subtype === "invalid-format") {
        this.errorState = {
          type: "url",
          title: "Invalid Link Format",
          message:
            "The Case ID in the link appears to be invalid or corrupted.",
          guidance:
            "The link may have been modified or copied incorrectly. Please use the original link from your email.",
          canRetry: false,
          contactSupport: true
        };
      }
    }

    // Not Found Errors
    else if (type === "notfound") {
      this.errorState = {
        type: "notfound",
        title: "Case Not Found",
        message:
          "We couldn't find a succession case matching this link. The case may have been deleted or the link may have expired.",
        guidance:
          "This link may be outdated. If you recently received this link, please contact our Estate Administration team.",
        canRetry: false,
        contactSupport: true
      };
    }

    // Permission Errors
    else if (type === "permission") {
      this.errorState = {
        type: "permission",
        title: "Access Denied",
        message:
          "You don't have permission to access this succession case form.",
        guidance:
          "This could mean the case is assigned to a different successor, or access has been restricted.",
        canRetry: false,
        contactSupport: true
      };
    }

    // Already Submitted
    else if (type === "alreadysubmitted") {
      this.errorState = {
        type: "alreadysubmitted",
        title: "Form Already Submitted",
        message:
          "This succession pathway selection has already been submitted and cannot be changed.",
        guidance:
          "Your selection was recorded successfully. If you need to make changes, please contact our Estate Administration team.",
        canRetry: false,
        contactSupport: true
      };
    }

    // Network Errors
    else if (type === "network") {
      this.errorState = {
        type: "network",
        title: "Connection Problem",
        message:
          "We're having trouble connecting to our servers. This could be due to a network issue on your end or temporary server maintenance.",
        guidance:
          "Please check your internet connection and try again. If the problem persists, try again in a few minutes.",
        canRetry: this.retryCount < this.maxRetries,
        contactSupport: true
      };
    }

    // Server Errors
    else if (type === "server") {
      this.errorState = {
        type: "server",
        title: "System Error",
        message:
          "Our system encountered an unexpected error while processing your request.",
        guidance:
          "This is likely a temporary issue. Please try again in a few minutes. If the problem continues, contact our support team.",
        canRetry: this.retryCount < this.maxRetries,
        contactSupport: true
      };
    }

    // Validation Errors
    else if (type === "validation") {
      this.errorState = {
        type: "validation",
        title: "Validation Error",
        message: originalError?.message || "There was a problem with the data submitted.",
        guidance:
          "Please review your selections and try again. If you continue to see this error, contact our Estate Administration team.",
        canRetry: false,
        contactSupport: true
      };
    }

    // Unknown/Generic Errors
    else {
      this.errorState = {
        type: "unknown",
        title: "Unexpected Error",
        message:
          originalError?.message ||
          "An unexpected error occurred while loading the form.",
        guidance:
          "Please try refreshing the page. If the problem persists, contact our Estate Administration team.",
        canRetry: this.retryCount < this.maxRetries,
        contactSupport: true
      };
    }

    // Set the error message for template binding
    this.error = this.errorState.message;
  }

  /**
   * Parse error from Apex response
   */
  parseApexError(error) {
    console.error("Apex Error Details:", error);

    // Check for specific error patterns
    const errorMessage = error?.body?.message || error?.message || "";

    // Case not found
    if (
      errorMessage.includes("not found") ||
      errorMessage.includes("does not exist") ||
      error?.status === 404
    ) {
      return { type: "notfound", subtype: null };
    }

    // Permission issues
    if (
      errorMessage.includes("permission") ||
      errorMessage.includes("access denied") ||
      errorMessage.includes("INSUFFICIENT_ACCESS") ||
      error?.status === 403
    ) {
      return { type: "permission", subtype: null };
    }

    // Already submitted
    if (
      errorMessage.includes("already submitted") ||
      errorMessage.includes("already completed") ||
      errorMessage.includes("DUPLICATE")
    ) {
      return { type: "alreadysubmitted", subtype: null };
    }

    // Validation errors
    if (
      errorMessage.includes("FIELD_CUSTOM_VALIDATION_EXCEPTION") ||
      errorMessage.includes("REQUIRED_FIELD_MISSING") ||
      errorMessage.includes("validation")
    ) {
      return { type: "validation", subtype: null };
    }

    // Network errors
    if (
      error?.status === 0 ||
      errorMessage.includes("NetworkError") ||
      errorMessage.includes("timeout")
    ) {
      return { type: "network", subtype: null };
    }

    // Server errors
    if (error?.status >= 500 || errorMessage.includes("UNABLE_TO_LOCK_ROW")) {
      return { type: "server", subtype: null };
    }

    // Default to unknown
    return { type: "unknown", subtype: null, originalError: error };
  }

  get hasError() {
    return this.error !== null;
  }

  get isFormReady() {
    return (
      !this.loading && !this.hasError && this.formData && !this.formSubmitted
    );
  }

  /**
   * Retry loading the form data
   */
  handleRetry() {
    if (this.retryCount >= this.maxRetries) {
      this.showToast(
        "Maximum Retries Reached",
        "Please refresh the page or contact support for assistance.",
        "warning"
      );
      return;
    }

    this.retryCount++;
    console.log(`Succession Public Form: Retry attempt ${this.retryCount}/${this.maxRetries}`);

    // Reset error state
    this.error = null;
    this.errorState = {
      type: null,
      title: "",
      message: "",
      guidance: "",
      canRetry: false,
      contactSupport: true
    };

    // Reload data
    this.loadFormData();
  }

  get accountBalanceFormatted() {
    if (this.formData?.accountBalance) {
      return new Intl.NumberFormat("en-US", {
        style: "currency",
        currency: "USD"
      }).format(this.formData.accountBalance);
    }
    return "$0.00";
  }

  get allocationPercentageFormatted() {
    if (this.formData?.allocationPercentage) {
      return `${this.formData.allocationPercentage}%`;
    }
    return "0%";
  }

  get isSubmitDisabled() {
    return !this.selectedPathway || this.loading;
  }

  /**
   * Get last 6 characters of caseId for support reference
   */
  get caseIdSuffix() {
    if (!this.caseId) return "N/A";
    return this.caseId.slice(-6);
  }

  handlePathwayChange(event) {
    this.selectedPathway = event.detail.value;
  }

  handleNotesChange(event) {
    this.additionalNotes = event.target.value;
  }

  async handleSubmit() {
    console.log("Succession Public Form: Submitting pathway selection:", {
      caseId: this.caseId,
      pathway: this.selectedPathway,
      hasNotes: !!this.additionalNotes
    });

    this.loading = true;

    try {
      // Build form data JSON
      const formDataJson = JSON.stringify({
        additionalNotes: this.additionalNotes
      });

      // Call Apex to save pathway selection
      const result = await savePathwaySelection({
        caseId: this.caseId,
        pathwaySelection: this.selectedPathway,
        formData: formDataJson
      });

      console.log("Succession Public Form: Submission successful");

      // Show success message
      this.showToast("Success", result, "success");

      this.formSubmitted = true;
    } catch (error) {
      console.error("Succession Public Form: Submission failed:", error);

      // Parse and categorize the error
      const errorInfo = this.parseApexError(error);
      this.setError(errorInfo.type, errorInfo.subtype, errorInfo.originalError || error);

      // Show detailed error toast
      this.showToast(
        this.errorState.title,
        `${this.errorState.message} ${this.errorState.guidance}`,
        "error"
      );
    } finally {
      this.loading = false;
    }
  }

  /**
   * Show toast notification
   */
  showToast(title, message, variant) {
    this.dispatchEvent(
      new ShowToastEvent({
        title,
        message,
        variant,
        mode: variant === "error" ? "sticky" : "dismissable"
      })
    );
  }

  handleCancel() {
    // Confirm cancellation with user
    const confirmed = confirm(
      "Are you sure you want to cancel? Your selections will not be saved."
    );

    if (confirmed) {
      // Reset form
      this.selectedPathway = "";
      this.additionalNotes = "";

      // Show cancellation message with clear instructions
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Form Cancelled",
          message: "Your selections were not saved. You may now close this browser tab. If you need assistance, please contact our Estate Administration team.",
          variant: "info",
          mode: "sticky" // Keep message visible
        })
      );

      // BROWSER LIMITATION: window.close() only works if window was opened by JavaScript
      // Most browsers block window.close() for user-opened tabs for security reasons
      // Alternative: Show clear message instructing user to close tab manually
      // Attempting window.close() anyway in case it works (e.g., popup windows)
      try {
        window.close();
        // If close succeeds, great! If not, user sees the toast message above
      } catch (e) {
        // window.close() blocked - user will see toast message instructing manual close
        console.log("window.close() blocked by browser - user must close tab manually");
      }
    }
  }
}
