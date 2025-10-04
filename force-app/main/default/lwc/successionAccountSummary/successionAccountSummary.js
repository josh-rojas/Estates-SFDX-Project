/**
 * @description Step 2: Account Summary display
 * @author Claude Code
 * @date 2025-10-02
 */
import { LightningElement, api } from 'lwc';

export default class SuccessionAccountSummary extends LightningElement {
    @api caseContext;

    get formattedBalance() {
        if (!this.caseContext?.accountBalance) return '$0.00';
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 2
        }).format(this.caseContext.accountBalance);
    }

    get formattedDateOfDeath() {
        if (!this.caseContext?.dateOfDeath) return 'N/A';
        return new Date(this.caseContext.dateOfDeath).toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    }
}
