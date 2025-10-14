import { LightningElement, api, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

import CASE_ID_FIELD from '@salesforce/schema/Case.Id';
import PATHWAY_CONFIRMED_FIELD from '@salesforce/schema/Case.Pathway_Confirmed__c';
import CONTACT_ESTABLISHED_FIELD from '@salesforce/schema/Case.Contact_Established__c';
import CONTACT_ESTABLISHED_DATE_FIELD from '@salesforce/schema/Case.Contact_Established_Date__c';

const FIELDS = [
    PATHWAY_CONFIRMED_FIELD,
    CONTACT_ESTABLISHED_FIELD
];

export default class RecordPathwaySelection extends LightningElement {
    @api recordId; // Case record ID passed from Quick Action

    selectedPathway = '';
    isLoading = false;
    
    // Store timeout reference for cleanup
    closeTimeout;
    errorMessage = '';

    // Wire to get current Case field values
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    caseRecord;

    /**
     * Handler for Final Grant pathway selection
     */
    handleFinalGrant() {
        this.updatePathway('Final Grant');
    }

    /**
     * Handler for New DAF Account pathway selection
     */
    handleNewDAF() {
        this.updatePathway('New DAF Account');
    }

    /**
     * Handler for Disclaim Assets pathway selection
     */
    handleDisclaim() {
        this.updatePathway('Disclaim Assets');
    }

    /**
     * Update the Case record with selected pathway
     * @param {string} pathway - The selected pathway value
     */
    async updatePathway(pathway) {
        this.isLoading = true;
        this.errorMessage = '';
        this.selectedPathway = '';

        const fields = {};
        fields[CASE_ID_FIELD.fieldApiName] = this.recordId;
        fields[PATHWAY_CONFIRMED_FIELD.fieldApiName] = pathway;

        // If contact was not previously established, mark it now
        if (!this.caseRecord?.data?.fields?.Contact_Established__c?.value) {
            fields[CONTACT_ESTABLISHED_FIELD.fieldApiName] = true;
            fields[CONTACT_ESTABLISHED_DATE_FIELD.fieldApiName] = new Date().toISOString();
        }

        const recordInput = { fields };

        try {
            await updateRecord(recordInput);

            this.selectedPathway = pathway;

            // Show success toast
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: `Succession pathway recorded: ${pathway}`,
                    variant: 'success'
                })
            );

            // Auto-close the Quick Action after 1.5 seconds
            this.closeTimeout = setTimeout(() => {
                this.handleClose();
            }, 1500);

        } catch (error) {
            this.errorMessage = error.body?.message || 'Error updating Case record';

            // Show error toast
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error Saving Pathway',
                    message: this.errorMessage,
                    variant: 'error',
                    mode: 'sticky'
                })
            );
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Close the Quick Action modal
     */
    handleClose() {
        // Clear any pending timeout
        if (this.closeTimeout) {
            clearTimeout(this.closeTimeout);
            this.closeTimeout = null;
        }
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    disconnectedCallback() {
        // Cleanup timeout when component is destroyed
        if (this.closeTimeout) {
            clearTimeout(this.closeTimeout);
            this.closeTimeout = null;
        }
    }
}
