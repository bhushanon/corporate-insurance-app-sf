public class BillingService {
    /**
     * Generates a Billing__c record for the given Employer Id by summing active Policy__c Premium_Amount__c.
     * @param emp Employer Id
     */
    public static void gen(Id emp) {
        AggregateResult r = [
            SELECT SUM(Premium_Amount__c) t
            FROM Policy__c
            WHERE Customer__r.Employer__c = :emp
                AND Status__c = 'Active'
        ];
        insert new Billing__c(
            Employer__c = emp,
            Total_Premium__c = (Decimal) r.get('t'),
            Payment_Status__c = 'Unpaid'
        );
    }
}