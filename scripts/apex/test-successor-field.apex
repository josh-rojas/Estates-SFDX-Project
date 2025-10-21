// Test script to check if Successor__c field assignment works
List<Contact> contacts = [SELECT Id FROM Contact LIMIT 1];
List<Case> cases = [SELECT Id, Successor__c FROM Case LIMIT 1];
if (!cases.isEmpty() && !contacts.isEmpty()) {
  Case testCase = cases[0];
  Contact testContact = contacts[0];
  System.debug('Before: Successor__c = ' + testCase.Successor__c);
  System.debug('Will assign Contact ID: ' + testContact.Id);

  // Try to set the field with a Contact ID
  testCase.Successor__c = testContact.Id;
  update testCase;

  // Query again to see if it was set
  Case updatedCase = [
    SELECT Id, Successor__c
    FROM Case
    WHERE Id = :testCase.Id
  ];
  System.debug('After: Successor__c = ' + updatedCase.Successor__c);
}
