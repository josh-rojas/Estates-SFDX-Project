import { LightningElement, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getFormData from "@salesforce/apex/SuccessionPublicFormController.getFormData";
import savePathwaySelection from "@salesforce/apex/SuccessionPublicFormController.savePathwaySelection";

export default class SuccessionPublicForm extends LightningElement {
  // URL parameters
  caseId = null;

  // Form data from Apex
  formData = null;
  loading = true;
  error = null;
  formSubmitted = false;

  // Form fields
  selectedPathway = "";
  additionalNotes = "";

  // Pathway options
  pathwayOptions = [
    { label: "Final Grant to Charity", value: "Final Grant" },
    { label: "Transfer to New DAF Account", value: "New DAF" },
    { label: "Disclaim Successor Rights", value: "Disclaim" }
  ];

  connectedCallback() {
    // Extract caseId from URL parameters
    const params = new URLSearchParams(window.location.search);
    this.caseId = params.get("caseId");

    if (!this.caseId) {
      this.error = "Invalid URL: Case ID parameter is missing";
      this.loading = false;
    }
  }

  @wire(getFormData, { caseId: "$caseId" })
  wiredFormData({ error, data }) {
    this.loading = false;

    if (data) {
      this.formData = data;
      this.error = null;
    } else if (error) {
      this.error = error.body?.message || "Error loading form data";
      this.formData = null;
    }
  }

  get hasError() {
    return this.error !== null;
  }

  get isFormReady() {
    return (
      !this.loading && !this.hasError && this.formData && !this.formSubmitted
    );
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

  handlePathwayChange(event) {
    this.selectedPathway = event.detail.value;
  }

  handleNotesChange(event) {
    this.additionalNotes = event.target.value;
  }

  async handleSubmit() {
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

      // Show success message
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Success",
          message: result,
          variant: "success"
        })
      );

      this.formSubmitted = true;
    } catch (error) {
      // Show error message
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error Submitting Form",
          message:
            error.body?.message ||
            "An error occurred while submitting the form",
          variant: "error"
        })
      );
    } finally {
      this.loading = false;
    }
  }

  handleCancel() {
    // Reset form
    this.selectedPathway = "";
    this.additionalNotes = "";
  }
}
