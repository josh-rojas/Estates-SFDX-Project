/**
 * @description Step 5 (New DAF): Email and Terms Acknowledgment
 * @author Claude Code
 * @date 2025-10-02
 */
import { LightningElement, api } from 'lwc';

export default class SuccessionNewDafDetails extends LightningElement {
    @api email = '';
    @api termsAcknowledged = false;

    handleEmailChange(event) {
        this.email = event.target.value;
        this.notifyParent();
    }

    handleTermsChange(event) {
        this.termsAcknowledged = event.target.checked;
        this.notifyParent();
    }

    notifyParent() {
        this.dispatchEvent(new CustomEvent('dafemailupdated', {
            detail: {
                email: this.email,
                termsAcknowledged: this.termsAcknowledged
            }
        }));
    }

    get isValid() {
        return this.email && this.termsAcknowledged && this.isValidEmail(this.email);
    }

    isValidEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    }
}
