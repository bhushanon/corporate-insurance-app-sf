public class PolicyTriggerHandler {
    public static void handleAfterUpdate(
        List<Policy__c> oldList,
        List<Policy__c> newList,
        Map<Id, Policy__c> oldMap,
        Map<Id, Policy__c> newMap
    ) {
        List<Policy__c> toActivate = new List<Policy__c>();
        List<Policy_History__c> histories = new List<Policy_History__c>();

        for (Integer i = 0; i < newList.size(); i++) {
            Policy__c oldRec = oldList[i];
            Policy__c newRec = newList[i];

            // Activate policy if payment received and not already active
            if (oldRec.Policy_Status__c != 'Active'
                && newRec.Policy_Status__c != 'Active'
                && oldRec.Annual_Premium__c == null
                && newRec.Annual_Premium__c != null
            ) {
                newRec.Policy_Status__c = 'Active';
                toActivate.add(newRec);
            }

            // Write history on any update
            Policy_History__c hist = new Policy_History__c(
                Policy__c = newRec.Id,
                Policy_History_Changes__c = UserInfo.getUserId(),
                Changed_On__c = System.now(),
                Old_Value__c = oldRec.Policy_Status__c,
                New_Value__c = newRec.Policy_Status__c
            );
            histories.add(hist);
        }

        if (!toActivate.isEmpty()) {
            update toActivate;
        }
        if (!histories.isEmpty()) {
            insert histories;
        }
    }
}