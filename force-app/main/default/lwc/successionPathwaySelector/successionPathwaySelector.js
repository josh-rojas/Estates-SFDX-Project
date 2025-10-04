/**
 * @description Step 4: Pathway Selection (Final Grant | New DAF | Disclaim)
 * @author Claude Code
 * @date 2025-10-02
 */
import { LightningElement, api, track } from 'lwc';

export default class SuccessionPathwaySelector extends LightningElement {
    @api selectedPathway = '';
    @track expandedSections = {
        finalGrant: false,
        newDAF: false,
        disclaim: false
    };

    pathways = [
        {
            value: 'Final Grant',
            label: 'Final Grant',
            icon: 'utility:gift',
            description: 'Distribute the account balance to qualified charitable organizations',
            details: [
                'You select the charitable beneficiaries and grant amounts',
                'Total grants must equal the account balance (±5%)',
                'Minimum grant amount: $50 per charity',
                'Schwab Charitable processes grants within 2-3 weeks',
                'Tax deduction goes to the original donor\'s estate'
            ],
            bestFor: 'Honoring the donor\'s charitable legacy by immediately distributing assets'
        },
        {
            value: 'New DAF Account',
            label: 'New DAF Account',
            icon: 'utility:account',
            description: 'Transfer the account to yourself as a new donor-advised fund',
            details: [
                'The account transfers to you as the new donor',
                'You gain full control to make grants over time',
                'Original account name and history preserved',
                'You can make additional contributions in the future',
                'Tax deductions for future grants belong to you'
            ],
            bestFor: 'Continuing the donor\'s philanthropic mission under your stewardship'
        },
        {
            value: 'Disclaim Assets',
            label: 'Disclaim Assets',
            icon: 'utility:cancel_transfer',
            description: 'Decline the account per Schwab Charitable bylaws',
            details: [
                'You formally disclaim your successor designation',
                'Assets distributed per Schwab Charitable bylaws (Article 8.3)',
                'Typically goes to alternate successor or residual beneficiary',
                'Irrevocable decision once submitted',
                'Must provide legal attestation'
            ],
            bestFor: 'When you cannot or choose not to accept the successor role'
        }
    ];

    get isFinalGrantSelected() {
        return this.selectedPathway === 'Final Grant';
    }

    get isNewDAFSelected() {
        return this.selectedPathway === 'New DAF Account';
    }

    get isDisclaimSelected() {
        return this.selectedPathway === 'Disclaim Assets';
    }

    handlePathwaySelect(event) {
        const pathway = event.currentTarget.dataset.pathway;
        this.selectedPathway = pathway;

        // Notify parent component
        this.dispatchEvent(new CustomEvent('pathwayselected', {
            detail: { pathway }
        }));
    }

    handleToggleSection(event) {
        const pathway = event.currentTarget.dataset.pathway;

        // Toggle the section
        if (pathway === 'finalGrant') {
            this.expandedSections.finalGrant = !this.expandedSections.finalGrant;
        } else if (pathway === 'newDAF') {
            this.expandedSections.newDAF = !this.expandedSections.newDAF;
        } else if (pathway === 'disclaim') {
            this.expandedSections.disclaim = !this.expandedSections.disclaim;
        }
    }

    get finalGrantExpanded() {
        return this.expandedSections.finalGrant;
    }

    get newDAFExpanded() {
        return this.expandedSections.newDAF;
    }

    get disclaimExpanded() {
        return this.expandedSections.disclaim;
    }
}
