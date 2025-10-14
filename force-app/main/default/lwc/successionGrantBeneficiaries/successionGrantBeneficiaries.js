/**
 * @description Step 5 (Final Grant): Grant Beneficiaries Table
 * @author Claude Code
 * @date 2025-10-02
 *
 * Dynamic table allowing add/remove beneficiaries with real-time validation
 */
import { LightningElement, api, track } from "lwc";

export default class SuccessionGrantBeneficiaries extends LightningElement {
  @api beneficiaries = [];
  @api accountBalance = 0;

  @track _beneficiaries = [];
  nextId = 1;

  // Minimum grant amount per charity
  MIN_GRANT_AMOUNT = 50;

  connectedCallback() {
    // Initialize with one empty row if no beneficiaries
    if (!this.beneficiaries || this.beneficiaries.length === 0) {
      this.addBeneficiary();
    } else {
      this._beneficiaries = [...this.beneficiaries];
    }
  }

  get totalGrantAmount() {
    return this._beneficiaries.reduce(
      (sum, b) => sum + (parseFloat(b.amount) || 0),
      0
    );
  }

  get formattedTotalGrant() {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD",
      minimumFractionDigits: 2
    }).format(this.totalGrantAmount);
  }

  get formattedAccountBalance() {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD",
      minimumFractionDigits: 2
    }).format(this.accountBalance);
  }

  get remainingBalance() {
    return this.accountBalance - this.totalGrantAmount;
  }

  get formattedRemainingBalance() {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD",
      minimumFractionDigits: 2
    }).format(this.remainingBalance);
  }

  get balanceStatus() {
    const variance = Math.abs(this.remainingBalance);
    const allowedVariance = this.accountBalance * 0.05; // 5%

    if (variance <= allowedVariance) {
      return "balanced"; // Green
    } else if (variance <= allowedVariance * 2) {
      return "warning"; // Yellow
    } 
      return "error"; // Red
    
  }

  get isBalanced() {
    return this.balanceStatus === "balanced";
  }

  get balanceMessage() {
    if (this.isBalanced) {
      return `Total grants match account balance within allowed variance (±5%)`;
    } else if (this.remainingBalance > 0) {
      return `You have ${this.formattedRemainingBalance} remaining to allocate`;
    } 
      return `Total grants exceed account balance by ${Math.abs(this.remainingBalance).toFixed(2)}`;
    
  }

  addBeneficiary() {
    this._beneficiaries.push({
      id: this.nextId++,
      charityName: "",
      ein: "",
      amount: "",
      purpose: ""
    });
    this.notifyParent();
  }

  removeBeneficiary(event) {
    const id = parseInt(event.currentTarget.dataset.id, 10);
    this._beneficiaries = this._beneficiaries.filter((b) => b.id !== id);

    // Ensure at least one row
    if (this._beneficiaries.length === 0) {
      this.addBeneficiary();
    }

    this.notifyParent();
  }

  handleInputChange(event) {
    const id = parseInt(event.currentTarget.dataset.id, 10);
    const field = event.currentTarget.dataset.field;
    const value = event.target.value;

    const beneficiary = this._beneficiaries.find((b) => b.id === id);
    if (beneficiary) {
      beneficiary[field] = value;
    }

    this.notifyParent();
  }

  handleAmountChange(event) {
    const id = parseInt(event.currentTarget.dataset.id, 10);
    let value = parseFloat(event.target.value) || 0;

    // Validate minimum amount
    if (value > 0 && value < this.MIN_GRANT_AMOUNT) {
      value = this.MIN_GRANT_AMOUNT;
    }

    const beneficiary = this._beneficiaries.find((b) => b.id === id);
    if (beneficiary) {
      beneficiary.amount = value;
    }

    this.notifyParent();
  }

  handleDistributeEvenly() {
    if (this._beneficiaries.length === 0) return;

    const evenAmount = this.accountBalance / this._beneficiaries.length;

    this._beneficiaries.forEach((b) => {
      b.amount = evenAmount.toFixed(2);
    });

    this.notifyParent();
  }

  notifyParent() {
    // Filter out empty rows
    const validBeneficiaries = this._beneficiaries.filter(
      (b) =>
        b.charityName &&
        b.amount &&
        parseFloat(b.amount) >= this.MIN_GRANT_AMOUNT
    );

    this.dispatchEvent(
      new CustomEvent("beneficiariesupdated", {
        detail: { beneficiaries: validBeneficiaries }
      })
    );
  }
}
