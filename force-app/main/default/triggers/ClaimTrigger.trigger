trigger ClaimTrigger on Claim__c (
    before insert, before update, before delete,
    after insert, after update, after delete,
    after undelete
) {
    // Keep trigger thin; delegate to handler for readability, testability, and bulk-safety.
    // (Pattern aligned with internal trigger best practices.) [1](https://publicisgroupe-my.sharepoint.com/personal/chakelly_publicisgroupe_net/_layouts/15/Doc.aspx?sourcedoc=%7BAE150697-7B16-4226-A694-7F752D0D3F6D%7D&file=Coding%20Guidelines(V1.5).docx&action=default&mobileredirect=true&DefaultItemOpen=1)

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            ClaimTriggerHandler.beforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            ClaimTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
        } else if (Trigger.isDelete) {
            ClaimTriggerHandler.beforeDelete(Trigger.old);
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            ClaimTriggerHandler.afterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            ClaimTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        } else if (Trigger.isDelete) {
            ClaimTriggerHandler.afterDelete(Trigger.old, Trigger.oldMap);
        } else if (Trigger.isUndelete) {
            ClaimTriggerHandler.afterUndelete(Trigger.new);
        }
    }
}