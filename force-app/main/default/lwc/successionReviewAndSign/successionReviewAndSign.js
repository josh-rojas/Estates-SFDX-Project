/**
 * @description Step 7: Review and E-Signature
 * @author Claude Code
 * @date 2025-10-02
 */
import { LightningElement, api, track } from "lwc";

export default class SuccessionReviewAndSign extends LightningElement {
  @api caseContext;
  @api formData;
  @api signatureName = "";

  @track notes = "";
  @track signatureAcknowledged = false;

  get formattedBalance() {
    if (!this.caseContext?.accountBalance) return "$0.00";
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD",
      minimumFractionDigits: 2
    }).format(this.caseContext.accountBalance);
  }

  get totalGrants() {
    if (!this.formData?.grantBeneficiaries) return "$0.00";
    const total = this.formData.grantBeneficiaries.reduce(
      (sum, b) => sum + (parseFloat(b.amount) || 0),
      0
    );
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD",
      minimumFractionDigits: 2
    }).format(total);
  }

  get isFinalGrant() {
    return this.formData?.pathway === "Final Grant";
  }

  get isNewDAF() {
    return this.formData?.pathway === "New DAF Account";
  }

  get isDisclaim() {
    return this.formData?.pathway === "Disclaim Assets";
  }

  get currentDateTime() {
    return new Date().toLocaleString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      timeZoneName: "short"
    });
  }

  get isValid() {
    return (
      this.signatureName &&
      this.signatureName.trim().length > 0 &&
      this.signatureAcknowledged
    );
  }

  handleSignatureChange(event) {
    this.signatureName = event.target.value;
    this.notifyParent();
  }

  handleAcknowledgmentChange(event) {
    this.signatureAcknowledged = event.target.checked;
  }

  handleNotesChange(event) {
    this.notes = event.target.value;
    this.dispatchEvent(
      new CustomEvent("notesupdate", {
        detail: { notes: this.notes }
      })
    );
  }

  notifyParent() {
    this.dispatchEvent(
      new CustomEvent("signaturecaptured", {
        detail: { signatureName: this.signatureName }
      })
    );
  }
}
