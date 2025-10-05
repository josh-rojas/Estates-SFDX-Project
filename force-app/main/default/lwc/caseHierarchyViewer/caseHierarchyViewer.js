import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getCaseHierarchy from '@salesforce/apex/CaseHierarchyController.getCaseHierarchy';

/**
 * Generic Case Hierarchy Viewer
 *
 * Configurable component for displaying Case parent-child hierarchies.
 * Admins can configure which fields to display via component properties.
 *
 * Usage: Add to Lightning Record Page for any Case object
 */
export default class CaseHierarchyViewer extends NavigationMixin(LightningElement) {
    @api recordId; // Parent case ID (automatically passed when on record page)

    // Configurable properties
    @api cardTitle = 'Case Hierarchy';
    @api childCaseFields = 'CaseNumber,Status,Contact_Attempt_Count__c,SLA_Status__c,Pathway_Confirmed__c';
    @api showFinancialAccounts = true;
    @api showAccountRoles = true;
    @api accountRoleLabel = 'Designated Successors';
    @api roleFilter = 'Successor';
    @api excludeStatuses = '';
    @api expandFirstChild = true;

    hierarchyData;
    error;
    isLoading = true;
    expandedSections = new Set(); // Track which sections are expanded

    /**
     * Wire adapter to fetch case hierarchy data
     */
    @wire(getCaseHierarchy, {
        parentCaseId: '$recordId',
        childFieldNames: '$childCaseFields',
        includeFinancialAccounts: '$showFinancialAccounts',
        includeAccountRoles: '$showAccountRoles',
        roleFilterString: '$roleFilter',
        excludeStatusString: '$excludeStatuses'
    })
    wiredHierarchy({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.hierarchyData = data;
            this.error = undefined;
            // Auto-expand first child case by default if configured
            if (this.expandFirstChild && data.childCases && data.childCases.length > 0) {
                this.expandedSections.add(data.childCases[0].caseRecord.Id);
            }
        } else if (error) {
            this.error = error;
            this.hierarchyData = undefined;
            console.error('Error loading case hierarchy:', error);
        }
    }

    /**
     * Check if component has data to display
     */
    get hasData() {
        return this.hierarchyData && this.hierarchyData.childCases && this.hierarchyData.childCases.length > 0;
    }

    /**
     * Get formatted parent case title
     */
    get parentCaseTitle() {
        if (!this.hierarchyData || !this.hierarchyData.parentCase) return '';
        const parentCase = this.hierarchyData.parentCase;
        return `${parentCase.CaseNumber} - ${parentCase.Subject}`;
    }

    /**
     * Get child case count text
     */
    get childCaseCountText() {
        if (!this.hierarchyData || !this.hierarchyData.childCases) return '';
        const count = this.hierarchyData.childCases.length;
        return `${count} Successor Case${count === 1 ? '' : 's'}`;
    }

    /**
     * Get formatted total balance across all financial accounts
     */
    get totalBalance() {
        if (!this.hierarchyData || !this.hierarchyData.childCases) return '$0.00';

        let total = 0;
        this.hierarchyData.childCases.forEach(childData => {
            if (childData.financialAccount && childData.financialAccount.FinServ__Balance__c) {
                total += childData.financialAccount.FinServ__Balance__c;
            }
        });

        return this.formatCurrency(total);
    }

    /**
     * Get child case data with computed properties for template
     */
    get childCasesWithProps() {
        if (!this.hierarchyData || !this.hierarchyData.childCases) return [];

        return this.hierarchyData.childCases.map(childData => {
            const caseRecord = childData.caseRecord;
            const financialAccount = childData.financialAccount;

            return {
                ...childData,
                // Computed properties
                isExpanded: this.expandedSections.has(caseRecord.Id),
                sectionId: `section-${caseRecord.Id}`,
                accountBalance: financialAccount ? this.formatCurrency(financialAccount.FinServ__Balance__c) : 'N/A',
                accountNumber: financialAccount ? financialAccount.FinServ__FinancialAccountNumber__c : 'N/A',
                contactName: caseRecord.Contact ? caseRecord.Contact.Name : 'No Contact',
                contactEmail: caseRecord.Contact ? caseRecord.Contact.Email : '',
                contactPhone: caseRecord.Contact ? caseRecord.Contact.Phone : '',
                slaClass: this.getSLAClass(caseRecord.SLA_Status__c),
                pathwayClass: this.getPathwayClass(caseRecord.Pathway_Confirmed__c),
                hasSuccessors: childData.successors && childData.successors.length > 0,
                successorsWithProps: this.formatSuccessors(childData.successors)
            };
        });
    }

    /**
     * Format successors with computed properties
     */
    formatSuccessors(successors) {
        if (!successors) return [];

        return successors.map(successor => ({
            ...successor,
            allocationDisplay: successor.allocationPercent ? `${successor.allocationPercent}%` : 'Not specified',
            pathwayDisplay: successor.pathway || 'Not selected'
        }));
    }

    /**
     * Toggle expand/collapse for a child case section
     */
    handleToggleSection(event) {
        const caseId = event.currentTarget.dataset.caseId;

        if (this.expandedSections.has(caseId)) {
            this.expandedSections.delete(caseId);
        } else {
            this.expandedSections.add(caseId);
        }

        // Force re-render
        this.expandedSections = new Set(this.expandedSections);
    }

    /**
     * Navigate to case record
     */
    navigateToCase(event) {
        event.preventDefault();
        const caseId = event.currentTarget.dataset.caseId;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: caseId,
                objectApiName: 'Case',
                actionName: 'view'
            }
        });
    }

    /**
     * Navigate to financial account record
     */
    navigateToAccount(event) {
        event.preventDefault();
        const accountId = event.currentTarget.dataset.accountId;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: accountId,
                objectApiName: 'FinServ__FinancialAccount__c',
                actionName: 'view'
            }
        });
    }

    /**
     * Get CSS class for SLA status badge
     */
    getSLAClass(slaStatus) {
        if (!slaStatus) return 'slds-badge';

        if (slaStatus.includes('🔴')) return 'slds-badge sla-critical';
        if (slaStatus.includes('🟠')) return 'slds-badge sla-at-risk';
        if (slaStatus.includes('🟡')) return 'slds-badge sla-attention';
        if (slaStatus.includes('🟢')) return 'slds-badge sla-on-track';
        if (slaStatus.includes('✓')) return 'slds-badge sla-complete';

        return 'slds-badge';
    }

    /**
     * Get CSS class for pathway badge
     */
    getPathwayClass(pathway) {
        if (!pathway || pathway === 'Not Selected') return 'slds-badge pathway-not-selected';
        if (pathway === 'Final Grant') return 'slds-badge pathway-final-grant';
        if (pathway === 'New DAF Account') return 'slds-badge pathway-new-daf';
        if (pathway === 'Disclaim Assets') return 'slds-badge pathway-disclaim';
        return 'slds-badge';
    }

    /**
     * Format currency value
     */
    formatCurrency(value) {
        if (value === null || value === undefined) return '$0.00';
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 2
        }).format(value);
    }
}
