public class ClaimTriggerHandler {
    public static void handleBeforeUpdate(List<Claim__c> oldList, List<Claim__c> newList) {
        for (Integer i = 0; i < newList.size(); i++) {
            Claim__c oldRec = oldList[i];
            Claim__c newRec = newList[i];
            // Example: Only allow certain status transitions
            if (oldRec.Claim_Status__c == 'Submitted' && newRec.Claim_Status__c == 'Approved') {
                // Allowed
            } else if (oldRec.Claim_Status__c == 'Approved' && newRec.Claim_Status__c == 'Paid') {
                // Allowed
            } else if (oldRec.Claim_Status__c != newRec.Claim_Status__c) {
                newRec.addError('Invalid status transition from ' + oldRec.Claim_Status__c + ' to ' + newRec.Claim_Status__c);
            }
        }
    }

    public static void handleAfterUpdate(List<Claim__c> oldList, List<Claim__c> newList) {
        List<Claim_History__c> logs = new List<Claim_History__c>();
        for (Integer i = 0; i < newList.size(); i++) {
            Claim__c oldRec = oldList[i];
            Claim__c newRec = newList[i];
            if (oldRec.Claim_Status__c != newRec.Claim_Status__c) {
                logs.add(new Claim_History__c(
                    Claim__c = newRec.Id,
                    Changed_By__c = UserInfo.getUserId(),
                    Changed_On__c = System.now(),
                    Old_Status__c = oldRec.Claim_Status__c,
                    New_Status__c = newRec.Claim_Status__c
                ));
            }
        }
        if (!logs.isEmpty()) {
            insert logs;
        }
    }
}