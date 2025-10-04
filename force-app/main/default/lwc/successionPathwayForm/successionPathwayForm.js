/**
 * @description Parent LWC component for succession pathway form (multi-step wizard)
 * @author Claude Code
 * @date 2025-10-02
 *
 * USAGE:
 *   Experience Cloud page with URL parameter: ?t={encryptedToken}
 *   Validates token, loads case context, manages 7-step wizard navigation
 *
 * STEPS:
 *   1. Welcome & Token Validation
 *   2. Deceased Donor & Account Summary
 *   3. Successor Information Verification
 *   4. Pathway Selection (Final Grant | New DAF | Disclaim)
 *   5. Pathway-Specific Details
 *   6. Document Upload
 *   7. Review & E-Signature
 *
 * SECURITY:
 *   - Token-based authentication (no login required)
 *   - Guest user access via Experience Cloud
 *   - One-time use enforcement
 *
 * REVISION HISTORY
 * 2025-10-02 - Initial creation for LWC implementation
 */
import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import validateToken from '@salesforce/apex/SuccessionFormController.validateToken';
import getCaseContext from '@salesforce/apex/SuccessionFormController.getCaseContext';
import submitPathwaySelection from '@salesforce/apex/SuccessionFormController.submitPathwaySelection';
import captureIPAddress from '@salesforce/apex/SuccessionFormController.captureIPAddress';

export default class SuccessionPathwayForm extends NavigationMixin(LightningElement) {
    // Step management
    @track currentStep = 1;
    @track maxStepReached = 1; // Enables save-for-later
    totalSteps = 7;

    // Token & validation
    token = '';
    @track tokenValidation = null;
    @track isLoading = true;
    @track errorMessage = '';

    // Case context data
    @track caseContext = null;
    caseId = null;
    caseNumber = '';

    // Form data
    @track formData = {
        pathway: '', // 'Final Grant' | 'New DAF Account' | 'Disclaim Assets'
        grantBeneficiaries: [],
        newDAFEmail: '',
        termsAcknowledged: false,
        disclaimerReason: '',
        legalAttestation: false,
        signatureName: '',
        ipAddress: '',
        notes: '',
        uploadedFiles: []
    };

    // UI state
    @track showSuccessMessage = false;
    @track submissionResult = null;

    // Step configuration
    get steps() {
        return [
            { number: 1, label: 'Welcome', completed: this.currentStep > 1 },
            { number: 2, label: 'Account Summary', completed: this.currentStep > 2 },
            { number: 3, label: 'Your Information', completed: this.currentStep > 3 },
            { number: 4, label: 'Select Pathway', completed: this.currentStep > 4 },
            { number: 5, label: 'Details', completed: this.currentStep > 5 },
            { number: 6, label: 'Documents', completed: this.currentStep > 6 },
            { number: 7, label: 'Review & Sign', completed: this.currentStep > 7 }
        ];
    }

    // Step visibility flags
    get isStep1() { return this.currentStep === 1; }
    get isStep2() { return this.currentStep === 2; }
    get isStep3() { return this.currentStep === 3; }
    get isStep4() { return this.currentStep === 4; }
    get isStep5() { return this.currentStep === 5; }
    get isStep6() { return this.currentStep === 6; }
    get isStep7() { return this.currentStep === 7; }

    // Navigation state
    get isFirstStep() { return this.currentStep === 1; }
    get isLastStep() { return this.currentStep === this.totalSteps; }
    get canGoNext() { return !this.isLastStep && this.isStepValid(); }
    get isNextDisabled() { return !this.canGoNext; }
    get canGoPrevious() { return !this.isFirstStep && this.currentStep > 1; }

    // Progress calculation
    get progressPercent() {
        return Math.round((this.currentStep / this.totalSteps) * 100);
    }

    // Pathway-specific visibility
    get isFinalGrantPathway() { return this.formData.pathway === 'Final Grant'; }
    get isNewDAFPathway() { return this.formData.pathway === 'New DAF Account'; }
    get isDisclaimPathway() { return this.formData.pathway === 'Disclaim Assets'; }

    // Multiple successor warning
    get showMultipleSuccessorWarning() {
        return this.caseContext?.hasMultipleSuccessors === true;
    }

    /**
     * Lifecycle: Component initialization
     */
    connectedCallback() {
        this.extractTokenFromURL();
        this.validateTokenAndLoadContext();
    }

    /**
     * Extract token from URL parameter (?t=...)
     */
    extractTokenFromURL() {
        const urlParams = new URLSearchParams(window.location.search);
        this.token = urlParams.get('t') || '';

        if (!this.token) {
            this.errorMessage = 'No access token found in URL. Please use the link from your email.';
            this.isLoading = false;
        }
    }

    /**
     * Validate token and load case context
     */
    async validateTokenAndLoadContext() {
        if (!this.token) return;

        this.isLoading = true;

        try {
            // Step 1: Validate token
            const validation = await validateToken({ token: this.token });

            if (!validation.isValid) {
                this.errorMessage = validation.errorMessage;
                this.tokenValidation = validation;
                this.isLoading = false;
                return;
            }

            // Token valid - store case info
            this.caseId = validation.caseId;
            this.caseNumber = validation.caseNumber;
            this.tokenValidation = validation;

            // Step 2: Load case context
            const context = await getCaseContext({ caseId: this.caseId });
            this.caseContext = context;

            // Step 3: Capture IP address
            const ip = await captureIPAddress();
            this.formData.ipAddress = ip;

            this.isLoading = false;

        } catch (error) {
            this.errorMessage = 'An error occurred loading your information. Please try again or contact support.';
            console.error('Initialization error:', error);
            this.isLoading = false;
        }
    }

    /**
     * Navigation: Next step
     */
    handleNext() {
        if (!this.isStepValid()) {
            this.showToast('Error', 'Please complete all required fields before proceeding.', 'error');
            return;
        }

        this.currentStep++;
        this.maxStepReached = Math.max(this.maxStepReached, this.currentStep);
        this.scrollToTop();
    }

    /**
     * Navigation: Previous step
     */
    handlePrevious() {
        if (this.currentStep > 1) {
            this.currentStep--;
            this.scrollToTop();
        }
    }

    /**
     * Navigation: Save for later
     */
    handleSaveForLater() {
        // Store form state in browser localStorage
        const formState = {
            currentStep: this.currentStep,
            formData: this.formData,
            savedAt: new Date().toISOString()
        };

        localStorage.setItem(`succession_form_${this.caseId}`, JSON.stringify(formState));

        this.showToast('Success', 'Your progress has been saved. You can return to this form using the same link within 30 days.', 'success');
    }

    /**
     * Restore saved form state
     */
    restoreSavedState() {
        const savedState = localStorage.getItem(`succession_form_${this.caseId}`);

        if (savedState) {
            try {
                const state = JSON.parse(savedState);
                this.formData = state.formData;
                this.currentStep = state.currentStep;
                this.maxStepReached = state.currentStep;

                this.showToast('Info', 'Your previous progress has been restored.', 'info');
            } catch (error) {
                console.error('Error restoring saved state:', error);
            }
        }
    }

    /**
     * Form submission
     */
    async handleSubmit() {
        if (!this.isStepValid()) {
            this.showToast('Error', 'Please complete all required fields.', 'error');
            return;
        }

        this.isLoading = true;

        try {
            const submission = {
                caseId: this.caseId,
                financialAccountId: this.caseContext.financialAccountId,
                pathway: this.formData.pathway,
                grantBeneficiaries: this.formData.grantBeneficiaries,
                newDAFEmail: this.formData.newDAFEmail,
                termsAcknowledged: this.formData.termsAcknowledged,
                disclaimerReason: this.formData.disclaimerReason,
                legalAttestation: this.formData.legalAttestation,
                signatureName: this.formData.signatureName,
                ipAddress: this.formData.ipAddress,
                notes: this.formData.notes
            };

            const result = await submitPathwaySelection({ submission });

            if (result.success) {
                this.submissionResult = result;
                this.showSuccessMessage = true;

                // Clear saved state
                localStorage.removeItem(`succession_form_${this.caseId}`);

                this.showToast('Success', result.message, 'success');
            } else {
                this.errorMessage = result.message;
                this.showToast('Error', result.message, 'error');
            }

        } catch (error) {
            this.errorMessage = 'An error occurred submitting your form. Please try again or contact support.';
            console.error('Submission error:', error);
            this.showToast('Error', this.errorMessage, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Step validation logic
     */
    isStepValid() {
        switch (this.currentStep) {
            case 1:
                return this.tokenValidation?.isValid === true;

            case 2:
                return true; // Read-only summary

            case 3:
                return true; // Pre-populated successor info

            case 4:
                return this.formData.pathway !== '';

            case 5:
                if (this.isFinalGrantPathway) {
                    return this.formData.grantBeneficiaries.length > 0 &&
                           this.validateGrantTotals();
                } else if (this.isNewDAFPathway) {
                    return this.formData.newDAFEmail !== '' &&
                           this.formData.termsAcknowledged === true;
                } else if (this.isDisclaimPathway) {
                    return this.formData.disclaimerReason !== '' &&
                           this.formData.legalAttestation === true;
                }
                return false;

            case 6:
                return true; // Document upload optional

            case 7:
                return this.formData.signatureName !== '';

            default:
                return false;
        }
    }

    /**
     * Validate grant totals (±5% of account balance)
     */
    validateGrantTotals() {
        if (!this.caseContext?.accountBalance) return false;

        const totalGrants = this.formData.grantBeneficiaries.reduce(
            (sum, grant) => sum + (parseFloat(grant.amount) || 0),
            0
        );

        const balance = this.caseContext.accountBalance;
        const allowedVariance = balance * 0.05;

        return Math.abs(totalGrants - balance) <= allowedVariance;
    }

    /**
     * Event handlers: Child component communication
     */
    handlePathwaySelected(event) {
        this.formData.pathway = event.detail.pathway;
    }

    handleGrantBeneficiariesUpdated(event) {
        this.formData.grantBeneficiaries = event.detail.beneficiaries;
    }

    handleDAFEmailUpdated(event) {
        this.formData.newDAFEmail = event.detail.email;
        this.formData.termsAcknowledged = event.detail.termsAcknowledged;
    }

    handleDisclaimerUpdated(event) {
        this.formData.disclaimerReason = event.detail.reason;
        this.formData.legalAttestation = event.detail.legalAttestation;
    }

    handleDocumentsUploaded(event) {
        this.formData.uploadedFiles = event.detail.files;
    }

    handleSignatureCaptured(event) {
        this.formData.signatureName = event.detail.signatureName;
    }

    handleNotesUpdated(event) {
        this.formData.notes = event.detail.notes;
    }

    /**
     * Utility: Scroll to top of form
     */
    scrollToTop() {
        window.scrollTo({ top: 0, behavior: 'smooth' });
    }

    /**
     * Utility: Show toast notification
     */
    showToast(title, message, variant) {
        // Using custom event for Experience Cloud toast
        this.dispatchEvent(
            new CustomEvent('showtoast', {
                detail: { title, message, variant },
                bubbles: true,
                composed: true
            })
        );
    }
}
