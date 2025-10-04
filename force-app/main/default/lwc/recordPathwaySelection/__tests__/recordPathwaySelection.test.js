import { createElement } from 'lwc';
import RecordPathwaySelection from 'c/recordPathwaySelection';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

// Mock Apex wire adapter
import { getRecord } from 'lightning/uiRecordApi';

// Mock the wire adapter
jest.mock(
    'lightning/uiRecordApi',
    () => {
        const { updateRecord: actualUpdateRecord } = jest.requireActual('lightning/uiRecordApi');
        return {
            updateRecord: jest.fn().mockResolvedValue({}),
            getRecord: jest.fn()
        };
    },
    { virtual: true }
);

describe('c-record-pathway-selection', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        // Reset mocks
        jest.clearAllMocks();
    });

    // Helper function to wait for async updates
    async function flushPromises() {
        return new Promise(resolve => setTimeout(resolve, 0));
    }

    it('renders with title and three pathway buttons', () => {
        const element = createElement('c-record-pathway-selection', {
            is: RecordPathwaySelection
        });
        element.recordId = '500xx000000000AAAA';
        document.body.appendChild(element);

        // Verify card title
        const card = element.shadowRoot.querySelector('lightning-card');
        expect(card.title).toBe('Record Succession Pathway Selection');

        // Verify all three buttons are present
        const buttons = element.shadowRoot.querySelectorAll('lightning-button[variant="brand"]');
        expect(buttons.length).toBe(3);

        const buttonLabels = Array.from(buttons).map(btn => btn.label);
        expect(buttonLabels).toContain('Final Grant');
        expect(buttonLabels).toContain('New DAF Account');
        expect(buttonLabels).toContain('Disclaim Assets');
    });

    it('updates Case with Final Grant pathway when button clicked', async () => {
        const element = createElement('c-record-pathway-selection', {
            is: RecordPathwaySelection
        });
        element.recordId = '500xx000000000AAAA';
        document.body.appendChild(element);

        // Mock getRecord to return case without contact established
        getRecord.emit({
            data: {
                fields: {
                    Contact_Established__c: { value: false }
                }
            }
        });

        await flushPromises();

        // Click Final Grant button
        const buttons = element.shadowRoot.querySelectorAll('lightning-button[variant="brand"]');
        const finalGrantButton = Array.from(buttons).find(btn => btn.label === 'Final Grant');
        finalGrantButton.click();

        await flushPromises();

        // Verify updateRecord was called with correct fields
        expect(updateRecord).toHaveBeenCalledTimes(1);
        const updateCall = updateRecord.mock.calls[0][0];
        expect(updateCall.fields.Pathway_Confirmed__c).toBe('Final Grant');
        expect(updateCall.fields.Contact_Established__c).toBe(true);
        expect(updateCall.fields.Contact_Established_Date__c).toBeDefined();
    });

    it('updates Case with New DAF Account pathway when button clicked', async () => {
        const element = createElement('c-record-pathway-selection', {
            is: RecordPathwaySelection
        });
        element.recordId = '500xx000000000AAAA';
        document.body.appendChild(element);

        // Mock getRecord to return case with contact already established
        getRecord.emit({
            data: {
                fields: {
                    Contact_Established__c: { value: true }
                }
            }
        });

        await flushPromises();

        // Click New DAF Account button
        const buttons = element.shadowRoot.querySelectorAll('lightning-button[variant="brand"]');
        const newDAFButton = Array.from(buttons).find(btn => btn.label === 'New DAF Account');
        newDAFButton.click();

        await flushPromises();

        // Verify updateRecord was called with only pathway field (contact already established)
        expect(updateRecord).toHaveBeenCalledTimes(1);
        const updateCall = updateRecord.mock.calls[0][0];
        expect(updateCall.fields.Pathway_Confirmed__c).toBe('New DAF Account');
        expect(updateCall.fields.Contact_Established__c).toBeUndefined();
    });

    it('updates Case with Disclaim Assets pathway when button clicked', async () => {
        const element = createElement('c-record-pathway-selection', {
            is: RecordPathwaySelection
        });
        element.recordId = '500xx000000000AAAA';
        document.body.appendChild(element);

        // Mock getRecord
        getRecord.emit({
            data: {
                fields: {
                    Contact_Established__c: { value: false }
                }
            }
        });

        await flushPromises();

        // Click Disclaim Assets button
        const buttons = element.shadowRoot.querySelectorAll('lightning-button[variant="brand"]');
        const disclaimButton = Array.from(buttons).find(btn => btn.label === 'Disclaim Assets');
        disclaimButton.click();

        await flushPromises();

        // Verify updateRecord was called
        expect(updateRecord).toHaveBeenCalledTimes(1);
        const updateCall = updateRecord.mock.calls[0][0];
        expect(updateCall.fields.Pathway_Confirmed__c).toBe('Disclaim Assets');
    });

    it('shows success toast and closes action on successful save', async () => {
        const element = createElement('c-record-pathway-selection', {
            is: RecordPathwaySelection
        });
        element.recordId = '500xx000000000AAAA';
        document.body.appendChild(element);

        // Mock getRecord
        getRecord.emit({
            data: {
                fields: {
                    Contact_Established__c: { value: true }
                }
            }
        });

        await flushPromises();

        const handler = jest.fn();
        element.addEventListener(ShowToastEvent.name, handler);

        // Click a button
        const buttons = element.shadowRoot.querySelectorAll('lightning-button[variant="brand"]');
        buttons[0].click();

        await flushPromises();

        // Verify success toast was fired
        expect(handler).toHaveBeenCalledTimes(1);
        const toastEvent = handler.mock.calls[0][0];
        expect(toastEvent.detail.variant).toBe('success');
        expect(toastEvent.detail.title).toBe('Success');
    });

    it('shows error message when update fails', async () => {
        updateRecord.mockRejectedValueOnce({
            body: { message: 'Field validation failed' }
        });

        const element = createElement('c-record-pathway-selection', {
            is: RecordPathwaySelection
        });
        element.recordId = '500xx000000000AAAA';
        document.body.appendChild(element);

        // Mock getRecord
        getRecord.emit({
            data: {
                fields: {
                    Contact_Established__c: { value: true }
                }
            }
        });

        await flushPromises();

        const handler = jest.fn();
        element.addEventListener(ShowToastEvent.name, handler);

        // Click a button
        const buttons = element.shadowRoot.querySelectorAll('lightning-button[variant="brand"]');
        buttons[0].click();

        await flushPromises();

        // Verify error toast was fired
        expect(handler).toHaveBeenCalledTimes(1);
        const toastEvent = handler.mock.calls[0][0];
        expect(toastEvent.detail.variant).toBe('error');
        expect(toastEvent.detail.title).toBe('Error Saving Pathway');
    });

    it('closes the action when Close button clicked', () => {
        const element = createElement('c-record-pathway-selection', {
            is: RecordPathwaySelection
        });
        element.recordId = '500xx000000000AAAA';
        document.body.appendChild(element);

        const handler = jest.fn();
        element.addEventListener(CloseActionScreenEvent.name, handler);

        // Click Close button
        const closeButton = element.shadowRoot.querySelector('lightning-button[label="Close"]');
        closeButton.click();

        // Verify close event was fired
        expect(handler).toHaveBeenCalledTimes(1);
    });
});
