import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import createSuccessionCase from "@salesforce/apex/CreateSuccessionCaseController.createSuccessionCase";

/**
 * Create Succession Case Quick Action Component
 *
 * Lightning Web Component for FinancialAccount Quick Action.
 * Creates succession case and handles loading/error/success states.
 *
 * Usage: Quick Action on FinancialAccount record page
 */
export default class CreateSuccessionCase extends NavigationMixin(
  LightningElement
) {
  @api recordId; // FinancialAccount ID (passed automatically by Quick Action)

  @track isLoading = true;
  @track result = null;
  @track error = null;

  /**
   * Required method for Quick Action invocation
   * Called automatically when Quick Action is clicked
   */
  @api
  invoke() {
    this.createCase();
  }

  /**
   * Create succession case on component initialization
   */
  connectedCallback() {
    this.createCase();
  }

  /**
   * Call Apex method to create succession case
   */
  createCase() {
    this.isLoading = true;
    this.error = null;
    this.result = null;

    createSuccessionCase({ financialAccountId: this.recordId })
      .then((result) => {
        this.result = result;
        this.isLoading = false;

        if (result.success) {
          this.showSuccessToast(result);
        } else {
          this.showErrorToast(result.message);
        }
      })
      .catch((error) => {
        this.error = error;
        this.isLoading = false;
        this.showErrorToast(
          error.body?.message || error.message || "Unknown error occurred"
        );
        console.error("Error creating succession case:", error);
      });
  }

  /**
   * Show success toast and navigate to case
   */
  showSuccessToast(result) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Success",
        message: result.message,
        variant: "success"
      })
    );

    // Navigate to the created case
    this.navigateToCase(result.seedCaseId);
  }

  /**
   * Show error toast
   */
  showErrorToast(message) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Error",
        message: message,
        variant: "error"
      })
    );
  }

  /**
   * Navigate to the created case record
   */
  navigateToCase(caseId) {
    try {
      this[NavigationMixin.Navigate]({
        type: "standard__recordPage",
        attributes: {
          recordId: caseId,
          objectApiName: "Case",
          actionName: "view"
        }
      });
    } catch (error) {
      console.error("Error navigating to case:", error);
      // Don't show error to user - case was created successfully
    }
  }

  /**
   * Get loading state
   */
  get showLoading() {
    return this.isLoading;
  }

  /**
   * Get error state
   */
  get showError() {
    return this.error && !this.isLoading;
  }

  /**
   * Get success state
   */
  get showSuccess() {
    return this.result && this.result.success && !this.isLoading;
  }

  /**
   * Get error message
   */
  get errorMessage() {
    return this.error?.body?.message || this.error?.message || "Unknown error";
  }

  /**
   * Get success message
   */
  get successMessage() {
    return this.result?.message || "Case created successfully";
  }

  /**
   * Get successor count for display
   */
  get successorCount() {
    return this.result?.successorCount || 0;
  }

  /**
   * Get successor info text
   */
  get successorInfo() {
    if (this.successorCount === 0) return "";
    if (this.successorCount === 1) {
      return "Contact cadence will begin automatically.";
    }
    return `${this.successorCount} successors detected - parent coordination case and child cases will be created automatically.`;
  }

  /**
   * Handle Close button click (for error state)
   */
  handleClose() {
    // Close the Quick Action modal
    this.dispatchEvent(new CustomEvent("close"));
  }
}