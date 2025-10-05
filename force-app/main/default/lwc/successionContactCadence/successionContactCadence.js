import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
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
export default class SuccessionContactCadence extends LightningElement {
    @api recordId; // Case ID (automatically passed when on record page)

    cadenceData;
    wiredCadenceResult;
    error;
    isLoading = true;

    @track editingAttemptId = null; // Which attempt is being edited
    @track editingAttemptNumber = null; // Attempt number being edited
    @track highestAttemptStarted = 0; // Highest attempt user has started (locks previous)
    @track contactEstablished = false; // Checkbox state
    @track notes = ''; // Textarea state

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

        this.contactEstablished = false;
        this.notes = '';
    }

    /**
     * Handle Cancel button click
     */
    handleCancel() {
        this.editingAttemptId = null;
        this.editingAttemptNumber = null;
        this.contactEstablished = false;
        this.notes = '';
    }

    /**
     * Handle checkbox change
     */
    handleCheckboxChange(event) {
        this.contactEstablished = event.target.checked;
    }

    /**
     * Handle notes textarea change
     */
    handleNotesChange(event) {
        this.notes = event.target.value;
    }

    /**
     * Handle Save Outcome button click
     */
    handleSaveOutcome(event) {
        const taskId = event.currentTarget.dataset.taskId;

        // Notes are optional - user can save with or without notes
        this.isLoading = true;

        saveAttemptOutcome({
            caseId: this.recordId,
            taskId: taskId,
            attemptNumber: this.editingAttemptNumber,
            contactEstablished: this.contactEstablished,
            notes: this.notes
        })
            .then(() => {
                this.showToast('Success', 'Contact attempt outcome saved', 'success');

                // If contact NOT established and not on last attempt, immediately enable next attempt
                if (!this.contactEstablished && this.editingAttemptNumber < 5) {
                    this.highestAttemptStarted = this.editingAttemptNumber + 1;
                }

                // Reset editing state
                this.editingAttemptId = null;
                this.editingAttemptNumber = null;
                this.contactEstablished = false;
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
}
