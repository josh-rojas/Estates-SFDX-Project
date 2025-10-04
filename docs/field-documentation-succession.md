# DAF Account Succession Management - Field Documentation
**Generated**: January 31, 2025  
**BRD Reference**: `/docs/product/daf-account-succession-brd.md`

---

## Overview

This document provides comprehensive help text and descriptions for all succession-specific fields and objects in the DAF Account Succession Management system. All fields are aligned with the Business Requirements Document (BRD) and follow DAFGiving360 naming conventions.

---

## Account Object Fields

### 1. Date_of_Death__c
**Field Type**: Date  
**Object**: Account (Person Account)

**Description** (Admin-facing):
> BRD Phase 1: Captures the date when a donor Person Account holder passed away. This field initiates the DAF Account Succession Management workflow as defined in the BRD. Used by succession flows to calculate processing timelines and trigger Phase 1: Verification activities.

**Inline Help Text** (User-facing):
> Enter the date of death for the account holder. This will trigger the succession process. Format: MM/DD/YYYY. Required for Phase 1: Verification per BRD succession requirements.

**BRD Reference**: Section 3.1 - Phase 1: Initial Contact and Verification  
**Related Fields**: `Deceased__c`

---

### 2. Deceased__c
**Field Type**: Checkbox  
**Object**: Account (Person Account)

**Description** (Admin-facing):
> BRD Phase 1: Boolean indicator that marks a Person Account as deceased. When set to TRUE, triggers the DAF Account Succession Management workflow automation. This field works in conjunction with Date_of_Death__c to initiate succession case creation and beneficiary notification processes per BRD requirements.

**Inline Help Text** (User-facing):
> Check this box to mark the account holder as deceased and begin the succession process. This will trigger Phase 1: Verification activities as defined in the BRD.

**BRD Reference**: Section 3.1 - Phase 1: Initial Contact and Verification  
**Related Fields**: `Date_of_Death__c`

---

## Error_Notification__e Platform Event Fields

### 3. Error_Message__c
**Field Type**: Text (255)  
**Object**: Error_Notification__e (Platform Event)

**Description** (Admin-facing):
> BRD Error Handling: Contains the detailed error message text from succession workflow failures. This field captures the error summary for platform events generated during DAF Account Succession Management processes. Used by administrators to diagnose and resolve issues in succession automation flows.

**Inline Help Text** (User-facing):
> System-generated error message. Review this text to understand what went wrong in the succession workflow. Contact your administrator if this error persists.

**BRD Reference**: Section 8.1 - Technical Constraints (Error Handling)  
**Related Object**: `Flow_Error__c`

---

### 4. Flow_Name__c
**Field Type**: Text (255)  
**Object**: Error_Notification__e (Platform Event)

**Description** (Admin-facing):
> BRD Error Handling: Identifies the specific Flow or Process Builder that generated the error during succession workflow execution. This field helps administrators trace errors back to their source within the DAF Account Succession Management automation framework.

**Inline Help Text** (User-facing):
> The name of the automation flow where the error occurred. Use this to identify which succession workflow phase encountered an issue.

**BRD Reference**: Section 8.1 - Technical Constraints (Error Handling)  
**Related Object**: `Flow_Error__c`

---

### 5. Record_Id__c
**Field Type**: Text (18)  
**Object**: Error_Notification__e (Platform Event)

**Description** (Admin-facing):
> BRD Error Handling: Stores the Salesforce record ID of the Account, Case, or related object that encountered an error during succession processing. This field provides context for debugging succession workflow failures by linking the error to specific donor accounts or succession cases.

**Inline Help Text** (User-facing):
> The ID of the record that caused the error. Click to navigate to the affected account or succession case for troubleshooting.

**BRD Reference**: Section 8.1 - Technical Constraints (Error Handling)  
**Related Objects**: `Account`, `Case`, `Flow_Error__c`

---

### 6. Severity__c
**Field Type**: Text (20)  
**Object**: Error_Notification__e (Platform Event)

**Description** (Admin-facing):
> BRD Error Handling: Classifies the error severity level for succession workflow failures. Values include Critical (blocks succession processing), High (requires immediate attention), Medium (impacts functionality), and Low (informational). Used to prioritize error resolution in DAF Account Succession Management processes.

**Inline Help Text** (User-facing):
> Error priority level: Critical = Succession process blocked, High = Immediate action required, Medium = Review within 24 hours, Low = Informational only.

**BRD Reference**: Section 8.1 - Technical Constraints (Error Handling)  
**Values**: Critical, High, Medium, Low

---

## Summary of Changes

### Fields Updated (6 total)

| Object | Field | Previous State | Update Type |
|--------|-------|---------------|-------------|
| Account | Date_of_Death__c | No description or help text | Added both |
| Account | Deceased__c | No description or help text | Added both |
| Error_Notification__e | Error_Message__c | Basic description only | Enhanced both |
| Error_Notification__e | Flow_Name__c | Basic description only | Enhanced both |
| Error_Notification__e | Record_Id__c | Basic description only | Enhanced both |
| Error_Notification__e | Severity__c | Basic description only | Enhanced both |

---

## Previously Documented Fields

The following succession-specific fields already had comprehensive BRD-aligned documentation and did not require updates:

### Case Object (10 fields)
- `Contact_Established__c`
- `Pathway_Confirmed__c`
- `Verification_Status__c`
- `Form_Sent_Date__c`
- `Form_Completed_Date__c`
- `SLA_Status__c` (Formula)
- `Contact_Attempt_Count__c`
- `Contact_Established_Date__c`
- `Last_Contact_Attempt__c`
- `Next_Contact_Due__c`

### Task/Activity Objects (2 fields)
- `Contact_Attempt_Number__c`
- `Succession_Contact_Established__c`

### Flow_Error__c Custom Object (8 fields)
- `Error_Message__c`
- `Error_Timestamp__c`
- `Error_Type__c`
- `Flow_Name__c`
- `Record_Id__c`
- `Resolved__c`
- `Severity__c`
- `User__c`

---

## Implementation Notes

1. **BRD Alignment**: All descriptions reference the specific BRD phase or section they support
2. **Consistency**: Help text follows the same pattern as existing succession fields
3. **User Experience**: Inline help text is written for Estate Operations staff (the primary users)
4. **Admin Context**: Descriptions provide technical context for system administrators
5. **Traceability**: Each field includes BRD section references for audit purposes

---

## Deployment Checklist

- [x] Update Account.Date_of_Death__c metadata
- [x] Update Account.Deceased__c metadata
- [x] Update Error_Notification__e.Error_Message__c metadata
- [x] Update Error_Notification__e.Flow_Name__c metadata
- [x] Update Error_Notification__e.Record_Id__c metadata
- [x] Update Error_Notification__e.Severity__c metadata
- [ ] Deploy to sandbox for testing
- [ ] Validate help text displays correctly in UI
- [ ] Update training materials
- [ ] Deploy to production

---

## Related Documentation

- **BRD**: `/docs/product/daf-account-succession-brd.md`
- **Flow Reviews**: `/docs/reviews/succession-flows-*.md`
- **Metadata Location**: `/force-app/main/default/objects/`

---

*End of Documentation*
