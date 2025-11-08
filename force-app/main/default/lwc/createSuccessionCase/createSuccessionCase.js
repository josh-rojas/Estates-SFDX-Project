import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import { CloseActionScreenEvent } from "lightning/actions";
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

  @track isLoading = false;
  @track result = null;
  @track error = null;
  @track hasInvoked = false;

  /**
   * Required method for Quick Action invocation
   * Called automatically when Quick Action is clicked
   */
  @api
  invoke() {
    // Prevent duplicate invocations
    if (this.hasInvoked) {
      return;
    }
    this.hasInvoked = true;
    this.createCase();
  }

  /**
   * Call Apex method to create succession case
   */
  createCase() {
    if (!this.recordId) {
      this.showErrorToast("No Financial Account ID provided");
      return;
    }

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

        let errorMessage = "Unknown error occurred";
        if (error.body && error.body.message) {
          errorMessage = error.body.message;
        } else if (error.message) {
          errorMessage = error.message;
        }

        this.showErrorToast(errorMessage);
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

    // Close the Quick Action modal
    this.dispatchEvent(new CloseActionScreenEvent());

    // Navigate to parent case if multi-successor, otherwise navigate to the single case
    const targetCaseId = result.parentCaseId || result.seedCaseId;
    this.navigateToCase(targetCaseId);
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

    // Close the Quick Action modal
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  /**
   * Navigate to the created case record
   */
  navigateToCase(caseId) {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: caseId,
        objectApiName: "Case",
        actionName: "view"
      }
    });
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
      return "Contact cadence workflow has started automatically.";
    }
    return `${this.successorCount} successors detected. Parent and child cases created. Contact cadence workflows have started automatically for all child cases.`;
  }

  /**
   * Handle Close button click (for error state)
   */
  handleClose() {
    // Close the Quick Action modal
    this.dispatchEvent(new CloseActionScreenEvent());
  }
}
