/**
 * @description LWC component for generating succession test data via UI
 * @author Salesforce Architecture Team
 * @date 2025-01-31
 */
import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import generateCompleteDataset from '@salesforce/apex/SuccessionTestDataController.generateCompleteDataset';
import generateHappyPathFinalGrant from '@salesforce/apex/SuccessionTestDataController.generateHappyPathFinalGrant';
import generateNewDAFScenario from '@salesforce/apex/SuccessionTestDataController.generateNewDAFScenario';
import generateDisclaimScenario from '@salesforce/apex/SuccessionTestDataController.generateDisclaimScenario';
import generateSLAEscalationScenario from '@salesforce/apex/SuccessionTestDataController.generateSLAEscalationScenario';
import deleteAllTestData from '@salesforce/apex/SuccessionTestDataController.deleteAllTestData';

export default class SuccessionTestDataGenerator extends LightningElement {
    @track isGenerating = false;
    @track generationResult = null;
    @track showResult = false;
    
    scenarios = [
        {
            label: 'Complete Dataset (All Scenarios)',
            value: 'complete',
            description: '15 donors, 20 successors, 8 advisor firms, 18 DAFs, 54+ roles, 15 cases across 6 scenario types',
            icon: 'standard:dataset'
        },
        {
            label: 'Happy Path - Final Grant',
            value: 'happyPath',
            description: 'Margaret Thompson → Jennifer Thompson (Final Grant pathway)',
            icon: 'standard:success'
        },
        {
            label: 'New DAF Account',
            value: 'newDAF',
            description: 'Robert Chen → Lisa Chen (New DAF Account pathway)',
            icon: 'standard:account'
        },
        {
            label: 'Disclaim Assets',
            value: 'disclaim',
            description: 'Elizabeth Martinez → Carlos Martinez (Disclaim pathway, closed)',
            icon: 'standard:opportunity'
        },
        {
            label: 'SLA Escalation',
            value: 'slaEscalation',
            description: 'James O\'Connor → Sean O\'Connor (Unresponsive, escalated)',
            icon: 'standard:case'
        }
    ];
    
    get isProcessing() {
        return this.isGenerating;
    }
    
    get resultClass() {
        if (!this.generationResult) return '';
        return this.generationResult.success ? 'slds-box slds-theme_success' : 'slds-box slds-theme_error';
    }
    
    handleGenerateData(event) {
        const scenarioType = event.target.dataset.scenario;
        this.generateScenario(scenarioType);
    }
    
    async generateScenario(scenarioType) {
        this.isGenerating = true;
        this.showResult = false;
        this.generationResult = null;
        
        try {
            let result;
            
            switch(scenarioType) {
                case 'complete':
                    result = await generateCompleteDataset();
                    break;
                case 'happyPath':
                    result = await generateHappyPathFinalGrant();
                    break;
                case 'newDAF':
                    result = await generateNewDAFScenario();
                    break;
                case 'disclaim':
                    result = await generateDisclaimScenario();
                    break;
                case 'slaEscalation':
                    result = await generateSLAEscalationScenario();
                    break;
                default:
                    throw new Error('Invalid scenario type');
            }
            
            this.generationResult = {
                success: true,
                message: result.message,
                details: result.details
            };
            
            this.showToast('Success', result.message, 'success');
            
        } catch (error) {
            this.generationResult = {
                success: false,
                message: 'Error generating test data',
                details: error.body?.message || error.message
            };
            
            this.showToast('Error', error.body?.message || error.message, 'error');
        } finally {
            this.isGenerating = false;
            this.showResult = true;
        }
    }
    
    async handleDeleteAll() {
        if (!confirm('Are you sure you want to delete ALL succession test data? This action cannot be undone.')) {
            return;
        }
        
        this.isGenerating = true;
        this.showResult = false;
        
        try {
            const result = await deleteAllTestData();
            
            this.generationResult = {
                success: true,
                message: 'Test data deleted successfully',
                details: result.message
            };
            
            this.showToast('Success', 'All test data has been deleted', 'success');
            
        } catch (error) {
            this.generationResult = {
                success: false,
                message: 'Error deleting test data',
                details: error.body?.message || error.message
            };
            
            this.showToast('Error', error.body?.message || error.message, 'error');
        } finally {
            this.isGenerating = false;
            this.showResult = true;
        }
    }
    
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}
