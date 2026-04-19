# Succession Contact Cadence (LWC)

This repository has been trimmed to only the contact cadence experience: a Lightning Web Component and its supporting Apex classes, metadata, and tests. It tracks up to five contact attempts on a Case, surfaces wait periods, and lets agents record outcomes with ContentNotes and Chatter updates.

## What’s Included

- **LWC:** `successionContactCadence` (contact attempt tracker)
- **Apex:** `ContactCadenceController`, `SuccessionUtilities`, `SuccessionLogger` (+ tests)
- **Metadata:**  
  - Case record type `EstateAdministration` (uses business process `Estate_Administration`)  
  - Case fields: `Contact_Attempt_Count__c`, `Contact_Established__c`, `Contact_Established_Date__c`, `Form_Sent_Date__c`, `Successor__c`  
  - Task/Activity fields: `Contact_Attempt_Number__c`, `Succession_Contact_Established__c`  
  - Custom metadata type `Succession_Contact_Cadence__mdt` with wait-duration records (attempts 2–5)

## Deploy

1. Authenticate to your target org:  
   `sf org login web --alias cadence-org --set-default`
2. Deploy the trimmed package:  
   `sf project deploy start --manifest manifest/package.xml`

## Test

- LWC tests: `npm test`
- Apex tests:  
  `sf apex run test --tests ContactCadenceController_Test,SuccessionUtilities_Test,SuccessionLogger_Test --code-coverage`

## Usage Notes

- Component expects Cases with record type `EstateAdministration` and type `Succession Management` or `Named Successor Enactment`.
- Email validation uses Case.Account/Contact email + opt-out fields; warnings surface in the UI.
- ContentNotes and Chatter posts are created when saving attempt outcomes; Task descriptions keep a backup of notes.
