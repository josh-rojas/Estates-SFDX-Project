# Org Configuration Notes

## GroupRecordTypeMapper Validation Issue

### Status: REQUIRES ADMIN ACTION ⚠️

### Issue Summary
The schwab-sandbox org has a **Financial Services Cloud trigger validation** that prevents Business Account creation due to misconfigured `GroupRecordTypeMapper__mdt` custom metadata.

### Error Message
```
FinServ.MoiExceptionWrapper.ValidationException: Your account record type is missing, 
a duplicate, or invalid. Ask your admin to check the group record type configurations in Setup.
```

### Technical Details

**Trigger Source**: `FinServ.AccountTrigger` (BeforeInsert event)  
**Validation Location**: Line 1479 in debug logs - `SELECT FinServ__AccountRecordType__c, FinServ__AccountRecordTypeNamespace__c FROM GroupRecordTypeMapper__mdt`

**Affected Account Types**:
- ✅ **Person Accounts** - Work correctly with `PersonAccount` record type (0125f000000iCDUAA2)
- ❌ **Business Accounts** - Fail validation with `IndustriesBusiness` record type (0125f000000iBlaAAE)

**Working Account Types in Org**:
| Record Type ID | Developer Name | API Name | Works? |
|----------------|---------------|----------|---------|
| 0125f000000iBlbAAE | IndustriesHousehold | Household | Unknown |
| 0125f000000iBlcAAE | IndustriesIndividual | Individual | Unknown |
| 0125f000000iCDUAA2 | PersonAccount | Person Account | ✅ YES |
| 0125f000000iBlaAAE | IndustriesBusiness | Business | ❌ NO |

### Code Changes Made

The test data factory **was successfully updated** to address this issue:

1. **Added PersonAccount Record Type Support** (Lines 18-50)
   ```apex
   private static Id personAccountRecordTypeId;
   private static Id businessAccountRecordTypeId;
   ```

2. **Updated DeceasedDonorBuilder** (Lines 85-89)
   ```apex
   // Set PersonAccount record type (required for Person Accounts)
   if (personAccountRecordTypeId != null) {
       donor.RecordTypeId = personAccountRecordTypeId;
   }
   ```

3. **Updated SuccessorBuilder** (Lines 175-178)
   ```apex
   // Set PersonAccount record type (required for Person Accounts)
   if (personAccountRecordTypeId != null) {
       successor.RecordTypeId = personAccountRecordTypeId;
   }
   ```

4. **Updated AdvisorFirmBuilder** (Lines 273-276)
   ```apex
   // Set Business record type (required for Business Accounts)
   if (businessAccountRecordTypeId != null) {
       firm.RecordTypeId = businessAccountRecordTypeId;
   }
   ```

### Root Cause

The Financial Services Cloud package includes a `GroupRecordTypeMapper__mdt` custom metadata type that maps Business Account record types to valid configurations. The org's metadata is either:

1. **Missing required entries** for the `IndustriesBusiness` record type
2. **Has duplicate entries** causing ambiguity
3. **Has invalid record type references**

### Verification Testing

**Test 1: Person Account Creation** ✅
```apex
Id personRecordTypeId = [SELECT Id FROM RecordType 
                        WHERE SobjectType = 'Account' 
                        AND DeveloperName = 'PersonAccount' LIMIT 1].Id;
Account testPerson = new Account(
    RecordTypeId = personRecordTypeId,
    FirstName = 'Test',
    LastName = 'Donor',
    PersonEmail = 'test@test.com'
);
insert testPerson; // SUCCESS!
```

**Test 2: Business Account Creation** ❌
```apex
Id businessRecordTypeId = [SELECT Id FROM RecordType 
                          WHERE SobjectType = 'Account' 
                          AND DeveloperName = 'IndustriesBusiness' LIMIT 1].Id;
Account testFirm = new Account(
    RecordTypeId = businessRecordTypeId,
    Name = 'Test Advisor Firm',
    Type = 'Advisor'
);
insert testFirm; // FAILS WITH VALIDATION ERROR
```

### Resolution Required

**Admin Action Needed:**

1. Navigate to **Setup → Custom Metadata Types → GroupRecordTypeMapper**
2. Review existing records for the `IndustriesBusiness` record type
3. Verify that:
   - `FinServ__AccountRecordType__c` field contains valid value
   - `FinServ__AccountRecordTypeNamespace__c` is correctly set
   - No duplicate entries exist
4. Fix or recreate the metadata record as needed

**Alternative Workaround:**

If Business Accounts are not critical for testing, the test data factory could be modified to:
- Skip AdvisorFirm creation entirely
- Use Person Accounts with Type='Advisor' instead (non-standard but would work)

### Impact on Test Data Factory

**Current Status:**
- ✅ Code is correct and properly deployed
- ✅ Person Account builders work perfectly (DeceasedDonorBuilder, SuccessorBuilder)
- ❌ Business Account builder blocked by org validation (AdvisorFirmBuilder)
- ❌ Cannot generate complete test datasets until org config is fixed

**Affected Scenarios:**
- All scenario generators that create AdvisorFirm records:
  - `generateHappyPathFinalGrant()`
  - `generateNewDAFScenario()`
  - `generateDisclaimScenario()`
  - `generateSLAEscalationScenario()`
  - `generateCompleteDataset()`

### Testing Recommendation

Once the `GroupRecordTypeMapper__mdt` metadata is fixed by an admin:

1. Run this validation test:
   ```apex
   SuccessionTestDataFactory.SuccessionScenarioData result = 
       SuccessionTestDataFactory.generateHappyPathFinalGrant();
   System.debug('✅ SUCCESS! Created: ' + result.deceasedDonor.Name);
   ```

2. If successful, proceed with full dataset generation:
   ```apex
   SuccessionTestDataFactory.SuccessionTestData fullData = 
       SuccessionTestDataFactory.generateCompleteDataset();
   ```

### Files Modified (Successfully Deployed)

| File | Lines Changed | Deploy ID | Status |
|------|---------------|-----------|--------|
| SuccessionTestDataFactory.cls | +52 lines | 0AfDg00001N9J1rKAF | ✅ Success |
| SuccessionTestDataController.cls | (no changes needed) | - | - |

### References

- **BRD**: `/docs/product/daf-account-succession-brd.md`
- **Test Data Plan**: `/docs/test-data-plan-succession.md`
- **Deployment Log**: Lines 21:52:11 - 21:52:14 (Deploy 0AfDg00001N9J1rKAF)
- **Debug Log**: Lines 21:52:24 - 21:52:42 (Failed Business Account insert)
- **Debug Log**: Lines 21:53:06 - 21:53:11 (Successful Person Account insert/delete)

---

**Last Updated**: 2025-10-02  
**Org**: schwab-sandbox (josh.rojas.charfsc@schwab.com.fscjosh)  
**Issue Status**: Awaiting admin resolution of GroupRecordTypeMapper__mdt configuration
