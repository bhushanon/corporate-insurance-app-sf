trigger ClaimTrigger on Claim__c (before update, after update) {
    // Enforce status transitions before update
    if (Trigger.isBefore && Trigger.isUpdate) {
        ClaimTriggerHandler.handleBeforeUpdate(Trigger.old, Trigger.new);
    }
    // Audit logging after update
    if (Trigger.isAfter && Trigger.isUpdate) {
        ClaimTriggerHandler.handleAfterUpdate(Trigger.old, Trigger.new);
    }
}