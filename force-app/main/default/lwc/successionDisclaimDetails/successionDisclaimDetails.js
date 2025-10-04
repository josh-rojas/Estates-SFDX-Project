/**
 * @description Step 5 (Disclaim): Disclaimer Reason and Legal Attestation
 * @author Claude Code
 * @date 2025-10-02
 */
import { LightningElement, api } from 'lwc';

export default class SuccessionDisclaimDetails extends LightningElement {
    @api reason = '';
    @api legalAttestation = false;

    handleReasonChange(event) {
        this.reason = event.target.value;
        this.notifyParent();
    }

    handleAttestationChange(event) {
        this.legalAttestation = event.target.checked;
        this.notifyParent();
    }

    notifyParent() {
        this.dispatchEvent(new CustomEvent('disclaimerupdated', {
            detail: {
                reason: this.reason,
                legalAttestation: this.legalAttestation
            }
        }));
    }

    get isValid() {
        return this.reason && this.reason.trim().length > 0 && this.legalAttestation;
    }
}
