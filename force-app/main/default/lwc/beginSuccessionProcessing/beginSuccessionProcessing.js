import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from "lightning/actions";
import updateCase from "@salesforce/apex/BeginSuccessionProcessingController.updateVerificationStatus";

export default class BeginSuccessionProcessing extends LightningElement {
  @api recordId;
  isLoading = false;
  _closeTimeoutId = null; // Store timeout ID for cleanup

  /**
   * Clean up any pending timeouts when component is destroyed
   * Prevents memory leaks and "Cannot read property of undefined" errors
   */
  disconnectedCallback() {
    if (this._closeTimeoutId) {
      clearTimeout(this._closeTimeoutId);
      this._closeTimeoutId = null;
    }
  }

  handleClick() {
    this.isLoading = true;

    updateCase({ caseId: this.recordId })
      .then((result) => {
        if (result.success) {
          this.showToast("Success", result.message, "success");

          // UX Enhancement: Delay modal close by 2 seconds so user can read success message
          // This prevents the modal from closing before the toast is visible
          // Alternative considered: Use toast onclose event, but toast timing is inconsistent
          // eslint-disable-next-line @lwc/lwc/no-async-operation
          this._closeTimeoutId = setTimeout(() => {
            this.dispatchEvent(new CloseActionScreenEvent());
            this._closeTimeoutId = null;
          }, 2000);
        } else {
          this.showToast("Error", result.message, "error");
        }
      })
      .catch((error) => {
        console.error("Error updating verification status:", error);
        this.showToast(
          "Error",
          "An error occurred while starting succession processing",
          "error"
        );
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  showToast(title, message, variant) {
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(event);
  }
}
