/**
 * @description Step 3: Successor Information Verification
 * @author Claude Code
 * @date 2025-10-02
 */
import { LightningElement, api } from "lwc";

export default class SuccessionSuccessorInfo extends LightningElement {
  @api caseContext;

  get formattedPhone() {
    if (!this.caseContext?.successorPhone) return "N/A";

    // Format phone number (XXX) XXX-XXXX
    const cleaned = this.caseContext.successorPhone.replace(/\D/g, "");
    const match = cleaned.match(/^(\d{3})(\d{3})(\d{4})$/);

    if (match) {
      return `(${match[1]}) ${match[2]}-${match[3]}`;
    }

    return this.caseContext.successorPhone;
  }
}
