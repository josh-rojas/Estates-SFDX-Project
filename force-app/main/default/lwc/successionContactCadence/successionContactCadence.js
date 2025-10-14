import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getContactCadence from '@salesforce/apex/ContactCadenceController.getContactCadence';
import saveAttemptOutcome from '@salesforce/apex/ContactCadenceController.saveAttemptOutcome';

/**
 * Succession Contact Cadence
 *
 * Displays 5-attempt contact cadence as progress bar + kanban card grid.
 * Allows inline editing of current attempt outcome.
 *
 * Usage: Add to Succession Management tab on Case record page
 */
export default class SuccessionContactCadence extends NavigationMixin(LightningElement) {
    @api recordId; // Case ID (automatically passed when on record page)

    cadenceData;
    wiredCadenceResult;
    error;
    isLoading = true;

    @track editingAttemptId = null; // Which attempt is being edited
    @track editingAttemptNumber = null; // Attempt number being edited
    @track highestAttemptStarted = 0; // Highest attempt user has started (locks previous)
    @track contactMadeValue = ''; // Radio button value ('yes' or 'no')
    @track notes = ''; // Textarea state
    @track pendingEmailAttemptNumber = null; // Stores attempt number for optional email sending
    @track isNavigatingToEmail = false; // True when opening email composer (prevents double-click)
    
    // Store timeout reference for cleanup
    emailNavigationTimeout;

    // Radio button options for "Was contact made?"
    contactMadeOptions = [
        { label: 'Yes', value: 'yes' },
        { label: 'No', value: 'no' }
    ];

    /**
     * Wire adapter to fetch contact cadence data
     */
    @wire(getContactCadence, { caseId: '$recordId' })
    wiredCadence(result) {
        this.wiredCadenceResult = result;
        this.isLoading = false;

        if (result.data) {
            this.cadenceData = result.data;
            this.error = undefined;

            // Initialize highestAttemptStarted to first incomplete attempt
            if (this.cadenceData.attempts && this.highestAttemptStarted === 0) {
                const firstIncomplete = this.cadenceData.attempts.find(a => !a.isCompleted);
                if (firstIncomplete) {
                    this.highestAttemptStarted = firstIncomplete.attemptNumber;
                }
            }
        } else if (result.error) {
            this.error = result.error;
            this.cadenceData = undefined;
            console.error('Error loading contact cadence:', result.error);
        }
    }

    /**
     * Check if record type is invalid
     */
    get showInvalidRecordType() {
        return this.cadenceData && this.cadenceData.isValidRecordType === false;
    }

    /**
     * Get invalid record type message
     */
    get invalidRecordTypeMessage() {
        return this.cadenceData?.invalidRecordTypeMessage || '';
    }

    /**
     * Check if component has data to display
     */
    get hasData() {
        return this.cadenceData &&
               this.cadenceData.isValidRecordType !== false &&
               this.cadenceData.attempts &&
               this.cadenceData.attempts.length > 0;
    }

    /**
     * Get progress percentage (0-100)
     */
    get progressPercent() {
        if (!this.cadenceData) return 0;

        if (this.cadenceData.contactEstablished) {
            return 100; // Contact established = 100% complete
        }

        // Calculate based on current attempt (0-5)
        const current = this.cadenceData.currentAttemptNumber || 0;
        return (current / 5) * 100;
    }

    /**
     * Get progress bar width style
     */
    get progressBarStyle() {
        return `width: ${this.progressPercent}%`;
    }

    /**
     * Get progress status text
     */
    get progressStatusText() {
        if (!this.cadenceData) return '';

        if (this.cadenceData.contactEstablished) {
            return '✓ Contact Established';
        }

        const current = this.cadenceData.currentAttemptNumber || 0;
        return `Attempt ${current} of 5`;
    }

    /**
     * Check if email sending is available (all validation passed)
     */
    get canSendEmail() {
        if (!this.cadenceData) return false;
        return this.cadenceData.hasEmail &&
               this.cadenceData.hasValidEmailFormat &&
               !this.cadenceData.hasOptedOut;
    }

    /**
     * Check if there are email warnings to display
     */
    get hasEmailWarning() {
        return this.cadenceData?.emailWarning != null;
    }

    /**
     * Get email warning message
     */
    get emailWarningMessage() {
        return this.cadenceData?.emailWarning || '';
    }

    /**
     * Get attempts with computed properties for template
     */
    get attemptsWithProps() {
        if (!this.cadenceData || !this.cadenceData.attempts) return [];

        return this.cadenceData.attempts.map(attempt => {
            // Check if this attempt is being edited
            // Match by task ID if exists, or by attempt number if no task yet
            const isEditing = (attempt.taskRecord?.Id && this.editingAttemptId === attempt.taskRecord.Id) ||
                              (this.editingAttemptNumber === attempt.attemptNumber);

            // Determine if this attempt is locked (user has progressed past it)
            const isLocked = attempt.attemptNumber < this.highestAttemptStarted;

            // Determine if this is the current editable attempt
            const isCurrentEditable = attempt.attemptNumber === this.highestAttemptStarted && !attempt.isCompleted;

            return {
                ...attempt,
                // Card state classes
                cardClass: this.getCardClass(attempt),
                progressNodeClass: this.getProgressNodeClass(attempt),

                // Editing state - override isCurrent based on highestAttemptStarted
                isCurrent: isCurrentEditable,
                isEditing: isEditing,
                showEditForm: isEditing && isCurrentEditable, // Only show form if editing AND current
                showReadOnly: attempt.isCompleted || isLocked, // Read-only if completed OR locked
                showDisabled: attempt.attemptNumber > this.highestAttemptStarted, // Pending if beyond current

                // Display properties
                completionIcon: attempt.isCompleted ? '✓' : '',
                currentIcon: attempt.isCurrent ? '⏺' : '',
                pendingIcon: attempt.isPending ? '○' : '',

                // Task details
                hasTask: attempt.taskRecord != null,
                taskNotes: attempt.taskRecord?.Description || '',
                dueDate: attempt.formattedDueDate || 'Not scheduled'
            };
        });
    }

    /**
     * Get CSS class for attempt card
     */
    getCardClass(attempt) {
        let baseClass = 'attempt-card slds-box slds-p-around_medium slds-m-bottom_small';

        if (attempt.isCompleted) {
            return baseClass + ' card-completed';
        } else if (attempt.isCurrent) {
            return baseClass + ' card-current';
        } else if (attempt.isPending) {
            return baseClass + ' card-pending';
        }

        return baseClass;
    }

    /**
     * Get CSS class for progress bar node
     */
    getProgressNodeClass(attempt) {
        if (attempt.isCompleted) {
            return 'progress-node node-completed';
        } else if (attempt.isCurrent) {
            return 'progress-node node-current';
        } else {
            return 'progress-node node-pending';
        }
    }

    /**
     * Handle Edit button click
     */
    handleEdit(event) {
        const taskId = event.currentTarget.dataset.taskId;
        const attemptNumber = parseInt(event.currentTarget.dataset.attemptNumber, 10);

        this.editingAttemptId = taskId;
        this.editingAttemptNumber = attemptNumber;

        // Lock all previous attempts by updating highestAttemptStarted
        if (attemptNumber > this.highestAttemptStarted) {
            this.highestAttemptStarted = attemptNumber;
        }

        this.contactMadeValue = '';
        this.notes = '';
    }

    /**
     * Handle Cancel button click
     */
    handleCancel() {
        this.editingAttemptId = null;
        this.editingAttemptNumber = null;
        this.contactMadeValue = '';
        this.notes = '';
    }

    /**
     * Handle radio button change
     */
    handleContactMadeChange(event) {
        this.contactMadeValue = event.detail.value;
    }

    /**
     * Handle notes textarea change
     */
    handleNotesChange(event) {
        this.notes = event.target.value;
    }

    /**
     * Get contact established boolean from radio value
     */
    get contactEstablished() {
        return this.contactMadeValue === 'yes';
    }

    /**
     * Handle Save Outcome button click
     */
    handleSaveOutcome(event) {
        const taskId = event.currentTarget.dataset.taskId;
        const attemptNumber = this.editingAttemptNumber;
        const contactWasEstablished = this.contactEstablished;

        // Notes are optional - user can save with or without notes
        this.isLoading = true;

        saveAttemptOutcome({
            caseId: this.recordId,
            taskId: taskId,
            attemptNumber: attemptNumber,
            contactEstablished: contactWasEstablished,
            notes: this.notes
        })
            .then(() => {
                // If contact was NOT established (NO selected), show option to send email
                if (!contactWasEstablished) {
                    this.pendingEmailAttemptNumber = attemptNumber;
                    this.showToastWithEmailOption(attemptNumber);
                } else {
                    this.showToast('Success', 'Contact attempt outcome saved', 'success');
                }

                // Flow Task_Create_Next_Contact_Attempt will auto-create next task
                // No need to manually enable next attempt

                // Reset editing state
                this.editingAttemptId = null;
                this.editingAttemptNumber = null;
                this.contactMadeValue = '';
                this.notes = '';

                // Refresh data
                return refreshApex(this.wiredCadenceResult);
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
                console.error('Error saving outcome:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Show toast with option to send follow-up email
     */
    showToastWithEmailOption(attemptNumber) {
        const templateMap = {
            1: 'Day 0 Initial Contact',
            2: 'Day 5 First Follow-Up',
            3: 'Day 35 Second Contact',
            4: 'Day 65 Third Contact',
            5: 'Day 95 Final Contact'
        };

        const templateLabel = templateMap[attemptNumber];

        this.showToast(
            'Outcome Saved',
            `Next task created. Send ${templateLabel} email? (Optional)`,
            'success'
        );
    }

    /**
     * Handle Send Email button click
     * Includes double-click prevention and email validation
     */
    handleSendEmail(event) {
        // Prevent double-click (button already disabled during navigation)
        if (this.isNavigatingToEmail) {
            console.log('Email composer already opening, ignoring duplicate click');
            return;
        }

        // Validate email is available
        if (!this.canSendEmail) {
            this.showToast('Error', this.emailWarningMessage || 'Email sending not available', 'error');
            return;
        }

        const attemptNumber = parseInt(event.currentTarget.dataset.attemptNumber, 10);
        this.openListEmailDialog(attemptNumber);
    }

    /**
     * Handle Skip Email button click
     * This is the ONLY way to dismiss the email prompt (keeps it visible if agent closes composer)
     */
    handleSkipEmail() {
        this.pendingEmailAttemptNumber = null;
        this.isNavigatingToEmail = false; // Reset navigation state
        this.showToast('Email Skipped', 'You can process the next case', 'info');
    }

    /**
     * Open Send List Email dialog with appropriate template based on attempt number
     *
     * NOTE: This handles both Person Accounts and Business Accounts with Contacts.
     * - Person Account: Uses Account.SendEmail action with AccountId
     * - Business Account: Uses Contact.SendEmail action with ContactId
     * Template cannot be pre-selected in Lightning Experience (manual selection required).
     */
    openListEmailDialog(attemptNumber) {
        // Validate cadence data exists
        if (!this.cadenceData) {
            this.showToast('Error', 'Cannot open email composer: Case data not loaded', 'error');
            console.error('Cannot open list email: cadenceData is null or undefined');
            return;
        }

        // Determine which record to use based on account type
        const isPersonAccount = this.cadenceData.isPersonAccount;
        const accountId = this.cadenceData.accountId;
        const contactId = this.cadenceData.contactId;

        // Determine recordId and objectApiName based on account type
        let recordId;
        let objectApiName;

        if (isPersonAccount) {
            // Person Account: use AccountId
            recordId = accountId;
            objectApiName = 'Account';
        } else {
            // Business Account: use ContactId
            recordId = contactId;
            objectApiName = 'Contact';
        }

        // Validate recordId exists
        if (!recordId) {
            const errorMsg = isPersonAccount
                ? 'Cannot open email composer: Account ID not found on case. Ensure Case has an Account.'
                : 'Cannot open email composer: Contact ID not found on case. Ensure Case has a Contact.';
            this.showToast('Error', errorMsg, 'error');
            console.error('Cannot open list email: Record ID not found', {
                isPersonAccount,
                accountId,
                contactId,
                caseId: this.recordId
            });
            return;
        }

        // Map attempt numbers to email template display names
        const templateMap = {
            1: 'Day 0 - Initial Contact',
            2: 'Day 5 - First Follow-Up',
            3: 'Day 35 - Second Contact',
            4: 'Day 65 - Third Contact',
            5: 'Day 95 - Final Contact'
        };

        const templateDisplayName = templateMap[attemptNumber];

        // Set navigation state to prevent double-click
        this.isNavigatingToEmail = true;

        // Navigate to Send Email action
        // For Person Account: Opens Account.SendEmail with AccountId
        // For Business Account: Opens Contact.SendEmail with ContactId
        try {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordAction',
                attributes: {
                    recordId: recordId,
                    objectApiName: objectApiName,
                    actionName: `${objectApiName}.SendEmail`
                }
            });

            // NOTE: Do NOT clear pendingEmailAttemptNumber here
            // Keep email prompt visible in case agent closes composer without sending
            // Only clear when agent explicitly clicks "Skip" button

            // Show reminder about which template to select
            const recipientType = isPersonAccount ? 'Person Account' : 'Contact';
            this.showToast(
                'Email Composer Opening',
                `${recipientType} email opening. Select template: "${templateDisplayName}"`,
                'info'
            );

            // Reset navigation state after short delay (allow composer to open)
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            this.emailNavigationTimeout = setTimeout(() => {
                this.isNavigatingToEmail = false;
            }, 2000);
        } catch (error) {
            console.error('Error navigating to email composer:', error);
            this.isNavigatingToEmail = false; // Reset on error
            this.showToast(
                'Error',
                `Failed to open email composer: ${error.message || 'Unknown error'}`,
                'error'
            );
        }
    }

    /**
     * Show toast notification
     */
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

    disconnectedCallback() {
        // Cleanup timeout when component is destroyed
        if (this.emailNavigationTimeout) {
            clearTimeout(this.emailNavigationTimeout);
            this.emailNavigationTimeout = null;
        }
    }
}
