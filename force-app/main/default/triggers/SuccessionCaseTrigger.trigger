/**
 * @description Trigger for Succession Management Case automation
 * @author Salesforce
 * @date October 2025
 */
trigger SuccessionCaseTrigger on Case (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        SuccessionTaskGenerator.createPathwayTasks(Trigger.new, Trigger.oldMap);
    }
}
