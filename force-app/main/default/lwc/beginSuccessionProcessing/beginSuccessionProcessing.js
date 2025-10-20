import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from "lightning/actions";
import updateCase from "@salesforce/apex/BeginSuccessionProcessingController.updateVerificationStatus";

export default class BeginSuccessionProcessing extends LightningElement {
  @api recordId;
  isLoading = false;

  handleClick() {
    this.isLoading = true;

    updateCase({ caseId: this.recordId })
      .then((result) => {
        if (result.success) {
          this.showToast("Success", result.message, "success");
          this.dispatchEvent(new CloseActionScreenEvent());
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
