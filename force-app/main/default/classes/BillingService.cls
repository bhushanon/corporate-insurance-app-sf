public with sharing class BillingService {
    /**
     * Aggregates premiums for a list of policies.
     */
    public static Decimal aggregatePremiums(List<Id> policyIds) {
        if (policyIds == null || policyIds.isEmpty()) return 0;
        AggregateResult ar = [
            SELECT SUM(Annual_Premium__c) total 
            FROM Policy__c 
            WHERE Id IN :policyIds AND Policy_Status__c = 'Active'
        ];
        return (Decimal)ar.get('total');
    }

    /**
     * Generates a billing record for a customer.
     */
    public static Billing__c generateBilling(Id customerId, Decimal amount, Date billDate) {
        if (customerId == null || amount == null || amount <= 0) {
            throw new AuraHandledException('Invalid billing parameters.');
        }
        Billing__c bill = new Billing__c(
            //Customer__c = customerId,
            //Amount__c = amount,
            Billing_Period_Start__c = billDate != null ? billDate : Date.today(),
            Payment_Status__c = 'Paid'
        );
        insert bill;
        return bill;
    }
}