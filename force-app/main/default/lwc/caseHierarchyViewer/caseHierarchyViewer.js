import { LightningElement, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getCaseHierarchy from "@salesforce/apex/CaseHierarchyController.getCaseHierarchy";

/**
 * Generic Case Hierarchy Viewer
 *
 * Configurable component for displaying Case parent-child hierarchies.
 * Admins can configure which fields to display via component properties.
 *
 * Usage: Add to Lightning Record Page for any Case object
 */
export default class CaseHierarchyViewer extends NavigationMixin(
  LightningElement
) {
  @api recordId; // Parent case ID (automatically passed when on record page)

  // Configurable properties
  @api cardTitle = "Case Hierarchy";
  @api childCaseFields =
    "CaseNumber,Status,Contact_Attempt_Count__c,SLA_Status__c,Pathway_Confirmed__c";
  @api showFinancialAccounts = false;
  @api showAccountRoles = false;
  @api accountRoleLabel = "Designated Successors";
  @api roleFilter = "Successor";
  @api excludeStatuses = "";
  @api expandFirstChild = false;

  hierarchyData;
  error;
  isLoading = true;
  expandedSections = new Set();

  /**
   * Wire adapter to fetch case hierarchy data
   */
  @wire(getCaseHierarchy, {
    parentCaseId: "$recordId",
    childFieldNames: "$childCaseFields",
    includeFinancialAccounts: "$showFinancialAccounts",
    includeAccountRoles: "$showAccountRoles",
    roleFilterString: "$roleFilter",
    excludeStatusString: "$excludeStatuses"
  })
  wiredHierarchy({ error, data }) {
    this.isLoading = false;
    if (data) {
      this.hierarchyData = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.hierarchyData = undefined;
      console.error("Error loading case hierarchy:", error);
    }
  }

  /**
   * Check if component has data to display
   */
  get hasData() {
    return (
      this.hierarchyData &&
      this.hierarchyData.childCases &&
      this.hierarchyData.childCases.length > 0
    );
  }

  /**
   * Get formatted parent case title
   */
  get parentCaseTitle() {
    if (!this.hierarchyData || !this.hierarchyData.parentCase) return "";
    const parentCase = this.hierarchyData.parentCase;
    return `${parentCase.CaseNumber} - ${parentCase.Subject}`;
  }

  /**
   * Get child case count text
   */
  get childCaseCountText() {
    if (!this.hierarchyData || !this.hierarchyData.childCases) return "";
    const count = this.hierarchyData.childCases.length;
    return `${count} Successor Case${count === 1 ? "" : "s"}`;
  }

  /**
   * Get formatted total balance across all financial accounts
   */
  get totalBalance() {
    if (!this.hierarchyData || !this.hierarchyData.childCases) return "$0.00";

    let total = 0;
    const seenAccounts = new Set();

    this.hierarchyData.childCases.forEach((childData) => {
      const fa = childData.financialAccount;
      if (fa && fa.Id && !seenAccounts.has(fa.Id)) {
        seenAccounts.add(fa.Id);
        if (fa.FinServ__Balance__c) {
          total += fa.FinServ__Balance__c;
        }
      }
    });

    return this.formatCurrency(total);
  }

  /**
   * Get child case data with computed properties for template
   */
  get childCasesWithProps() {
    if (!this.hierarchyData || !this.hierarchyData.childCases) return [];

    return this.hierarchyData.childCases.map((childData) => {
      const caseRecord = childData.caseRecord;
      const financialAccount = childData.financialAccount;

      return {
        ...childData,
        // Computed properties
        isExpanded: this.expandedSections.has(caseRecord.Id),
        sectionId: `section-${caseRecord.Id}`,
        accountBalance: financialAccount
          ? this.formatCurrency(financialAccount.FinServ__Balance__c)
          : "N/A",
        accountNumber: financialAccount
          ? financialAccount.FinServ__FinancialAccountNumber__c
          : "N/A",
        contactName: caseRecord.Contact
          ? caseRecord.Contact.Name
          : "No Contact",
        contactEmail: caseRecord.Contact ? caseRecord.Contact.Email : "",
        contactPhone: caseRecord.Contact ? caseRecord.Contact.Phone : "",
        slaClass: this.getSLAClass(caseRecord.SLA_Status__c),
        pathwayClass: this.getPathwayClass(caseRecord.Pathway_Confirmed__c),
        hasSuccessors: childData.successors && childData.successors.length > 0,
        successorsWithProps: this.formatSuccessors(childData.successors),
        cardAriaLabel: `Navigate to case ${caseRecord.CaseNumber} for ${caseRecord.Contact ? caseRecord.Contact.Name : "No Contact"}`
      };
    });
  }

  /**
   * Format successors with computed properties
   */
  formatSuccessors(successors) {
    if (!successors) return [];

    return successors.map((successor) => ({
      ...successor,
      allocationDisplay: successor.allocationPercent
        ? `${successor.allocationPercent}%`
        : "Not specified",
      pathwayDisplay: successor.pathway || "Not selected"
    }));
  }

  /**
   * Navigate to case record from header click
   */
  navigateToCase(event) {
    event.preventDefault();
    event.stopPropagation();
    const caseId = event.currentTarget.dataset.caseId;

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
   * Handle keyboard navigation for case header (Enter/Space keys)
   */
  handleCardKeyDown(event) {
    // Only trigger on Enter or Space key
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      event.stopPropagation();
      // Trigger click handler
      this.navigateToCase(event);
    }
  }

  /**
   * Navigate to financial account record
   */
  navigateToAccount(event) {
    event.preventDefault();
    const accountId = event.currentTarget.dataset.accountId;

    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: accountId,
        objectApiName: "FinServ__FinancialAccount__c",
        actionName: "view"
      }
    });
  }

  /**
   * Get CSS class for SLA status badge
   */
  getSLAClass(slaStatus) {
    if (!slaStatus || typeof slaStatus !== "string") return "slds-badge";

    if (slaStatus.includes("🔴")) return "slds-badge sla-critical";
    if (slaStatus.includes("🟠")) return "slds-badge sla-at-risk";
    if (slaStatus.includes("🟡")) return "slds-badge sla-attention";
    if (slaStatus.includes("🟢")) return "slds-badge sla-on-track";
    if (slaStatus.includes("✓")) return "slds-badge sla-complete";

    return "slds-badge";
  }

  /**
   * Get CSS class for pathway badge
   */
  getPathwayClass(pathway) {
    if (!pathway || typeof pathway !== "string" || pathway === "Not Selected")
      return "slds-badge pathway-not-selected";
    if (pathway === "Final Grant") return "slds-badge pathway-final-grant";
    if (pathway === "New DAF Account") return "slds-badge pathway-new-daf";
    if (pathway === "Disclaim Assets") return "slds-badge pathway-disclaim";
    return "slds-badge";
  }

  /**
   * Get safe error message with null checks
   */
  get errorMessage() {
    return (
      this.error?.body?.message ||
      this.error?.message ||
      "Unknown error occurred"
    );
  }

  /**
   * Format currency value
   */
  formatCurrency(value) {
    if (value === null || value === undefined) return "$0.00";
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD",
      minimumFractionDigits: 2
    }).format(value);
  }
}
