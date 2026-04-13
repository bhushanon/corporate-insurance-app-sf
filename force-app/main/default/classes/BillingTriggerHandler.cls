public class BillingTriggerHandler {
    public static void updateTotals(List<Billing__c> billings) {
        Set<Id> policyIds = new Set<Id>();
        for (Billing__c b : billings) {
            if (b.Employer__c != null) policyIds.add(b.Employer__c);
        }
        if (policyIds.isEmpty()) return;

        // Aggregate totals for each policy
        Map<Id, Decimal> totals = new Map<Id, Decimal>();
        for (AggregateResult ar : [
            SELECT Employer__c, SUM(Total_Premium__c) total
            FROM Billing__c
            WHERE Employer__c IN :policyIds
            GROUP BY Employer__c
        ]) {
            totals.put((Id)ar.get('Policy__c'), (Decimal)ar.get('total'));
        }

        List<Policy__c> toUpdate = new List<Policy__c>();
        for (Id pid : totals.keySet()) {
            toUpdate.add(new Policy__c(Id = pid, Coverage_Amount__c = totals.get(pid)));
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}