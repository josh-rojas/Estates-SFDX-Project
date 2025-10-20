// Update the Begin Succession Processing Quick Action to use Lightning Component
System.debug('Starting Quick Action update...');

// Get the existing Quick Action
List<QuickAction> quickActions = [
  SELECT Id, Type, LightningComponent 
  FROM QuickAction 
  WHERE Name = 'Begin_Succession_Processing' 
  AND SObjectType = 'Case'
  LIMIT 1
];

if (!quickActions.isEmpty()) {
  QuickAction qa = quickActions[0];
  System.debug('Found Quick Action: ' + qa.Id);
  
  // Update to Lightning Component type
  qa.Type = 'LightningComponent';
  qa.LightningComponent = 'c:beginSuccessionProcessing';
  
  try {
    update qa;
    System.debug('Quick Action updated successfully');
  } catch (Exception e) {
    System.debug('Error updating Quick Action: ' + e.getMessage());
  }
} else {
  System.debug('Quick Action not found');
}
