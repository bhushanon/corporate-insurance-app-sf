trigger PolicyTrigger on Policy__c (after update) {
    // Activate policy on payment and write history
    if (Trigger.isAfter && Trigger.isUpdate) {
		PolicyTriggerHandler.handleAfterUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
    }
}