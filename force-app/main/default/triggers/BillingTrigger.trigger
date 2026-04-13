trigger BillingTrigger on Billing__c (after insert, after update, after delete, after undelete) {
    // Update billing totals after changes
    if (Trigger.isAfter) {
        BillingTriggerHandler.updateTotals(Trigger.isDelete ? Trigger.old : Trigger.new);
    }
}