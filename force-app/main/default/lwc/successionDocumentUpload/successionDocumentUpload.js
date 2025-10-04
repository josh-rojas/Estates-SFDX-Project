/**
 * @description Step 6: Document Upload with pathway-specific requirements
 * @author Claude Code
 * @date 2025-10-02
 */
import { LightningElement, api } from 'lwc';

export default class SuccessionDocumentUpload extends LightningElement {
    @api pathway = '';
    @api uploadedFiles = [];

    // File upload configuration
    acceptedFormats = ['.pdf', '.jpg', '.jpeg', '.png', '.doc', '.docx'];
    maxFileSize = 5242880; // 5MB in bytes

    get requiredDocuments() {
        const baseDocuments = [
            'Death certificate (certified copy)',
            'Government-issued photo ID (driver\'s license or passport)'
        ];

        const pathwayDocs = {
            'Final Grant': [
                'Completed grant recommendation form (if applicable)',
                'Any additional supporting documentation for charities'
            ],
            'New DAF Account': [
                'W-9 tax form',
                'Proof of address (utility bill or bank statement)'
            ],
            'Disclaim Assets': [
                'Signed disclaimer affidavit',
                'Any legal documentation supporting disclaimer'
            ]
        };

        return [...baseDocuments, ...(pathwayDocs[this.pathway] || [])];
    }

    get uploadLabel() {
        return `Upload Required Documents (${this.pathway})`;
    }

    get uploadInstructions() {
        return `Please upload the following documents. Accepted formats: PDF, JPG, PNG, DOC, DOCX. Maximum file size: 5MB per file.`;
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        this.uploadedFiles = [...this.uploadedFiles, ...uploadedFiles];

        this.dispatchEvent(new CustomEvent('documentsuploaded', {
            detail: { files: this.uploadedFiles }
        }));

        // Show success message
        this.showToast('Success', `${uploadedFiles.length} file(s) uploaded successfully`, 'success');
    }

    handleRemoveFile(event) {
        const fileId = event.currentTarget.dataset.fileid;
        this.uploadedFiles = this.uploadedFiles.filter(f => f.documentId !== fileId);

        this.dispatchEvent(new CustomEvent('documentsuploaded', {
            detail: { files: this.uploadedFiles }
        }));
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new CustomEvent('showtoast', {
                detail: { title, message, variant },
                bubbles: true,
                composed: true
            })
        );
    }
}
