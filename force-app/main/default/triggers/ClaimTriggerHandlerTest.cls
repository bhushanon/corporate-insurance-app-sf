@IsTest
private class ClaimTriggerHandlerTest {

    @IsTest
    static void test_beforeInsert_defaults_and_policyLinking_bulk() {
        // --- Setup required parent records (Customer, Product, Policy) ---

        Customer__c cust = new Customer__c();
        cust.Name = 'Test Customer';
        // Customer_Number__c is optional; but set to avoid uniqueness collisions if the org enforces rules
        if (Schema.SObjectType.Customer__c.fields.getMap().containsKey('Customer_Number__c')) {
            cust.put('Customer_Number__c', 'CUST-' + String.valueOf(Crypto.getRandomInteger()).replace('-', ''));
        }
        insert cust;

        Insurance_Product__c prod = new Insurance_Product__c();
        prod.Name = 'Test Product';
        insert prod;

        // Employer is optional in Policy__c; create only if object exists, dynamically.
        Id employerId;
        if (Schema.getGlobalDescribe().containsKey('Employer__c')) {
            SObject emp = Schema.getGlobalDescribe().get('Employer__c').newSObject();
            // try common "Name" field (standard on custom objects)
            emp.put('Name', 'Test Employer');
            insert emp;
            employerId = (Id) emp.get('Id');
        }

        Policy__c pol = new Policy__c();
        pol.Name = 'Test Policy';
        // Required fields from our object definition
        pol.put('Policy_Number__c', 'POL-' + String.valueOf(Crypto.getRandomInteger()).replace('-', ''));
        pol.put('Customer__c', cust.Id);
        pol.put('Insurance_Product__c', prod.Id);
        pol.put('Effective_Date__c', Date.today());

        // Optional employer
        if (employerId != null && Schema.SObjectType.Policy__c.fields.getMap().containsKey('Employer__c')) {
            pol.put('Employer__c', employerId);
        }
        insert pol;

        // --- Create Claims in BULK ---
        Claim__c c1 = new Claim__c();
        c1.Name = 'Claim 1';
        c1.put('Policy__c', pol.Id);
        // Leave Customer__c blank to test linking from Policy
        // Leave Claim_Number__c blank to test generation
        // Leave Reported_Date__c blank to test defaulting
        // Leave Claim_Status__c blank to test default

        Claim__c c2 = new Claim__c();
        c2.Name = 'Claim 2';
        c2.put('Policy__c', pol.Id);

        Test.startTest();
        insert new List<Claim__c>{ c1, c2 };
        Test.stopTest();

        // --- Verify outcomes ---
        List<Claim__c> insertedClaims = [
            SELECT Id,
                   Claim_Number__c,
                   Reported_Date__c,
                   Claim_Status__c,
                   Customer__c,
                   Employer__c,
                   Policy__c
            FROM Claim__c
            WHERE Id IN :new List<Id>{ c1.Id, c2.Id }
        ];

        System.assertEquals(2, insertedClaims.size(), 'Two claims should be inserted');

        for (Claim__c c : insertedClaims) {
            System.assertNotEquals(null, c.Claim_Number__c, 'Claim_Number__c should be auto-generated when blank');
            System.assertNotEquals(null, c.Reported_Date__c, 'Reported_Date__c should default when blank');
            System.assertEquals('New', c.Claim_Status__c, 'Claim_Status__c should default to New when blank');
            System.assertEquals(pol.Id, c.Policy__c, 'Policy__c should remain set');
            System.assertEquals(cust.Id, c.Customer__c, 'Customer__c should be derived from Policy when blank');

            // Employer__c is optional; only assert if present on both objects and created.
            if (employerId != null && Schema.SObjectType.Claim__c.fields.getMap().containsKey('Employer__c')) {
                System.assertEquals(employerId, c.Employer__c, 'Employer__c should be derived from Policy when blank');
            }
        }

        // --- Optional: verify history creation if Claim_History__c exists ---
        if (Schema.getGlobalDescribe().containsKey('Claim_History__c')) {
            // We do not assume any specific field schema on Claim_History__c.
            // At minimum, the handler attempts to insert history records on create.
            // We'll just assert that at least one record exists for these claim IDs if Claim__c lookup exists.
            Map<String, Schema.SObjectField> histFields =
                Schema.getGlobalDescribe().get('Claim_History__c').getDescribe().fields.getMap();

            if (histFields.containsKey('Claim__c')) {
                List<SObject> hist = Database.query(
                    'SELECT Id FROM Claim_History__c WHERE Claim__c IN :new List<Id>{ c1.Id, c2.Id }'
                );
                System.assert(hist.size() >= 1, 'At least one Claim_History__c record should exist after insert');
            }
        }
    }

    @IsTest
    static void test_beforeUpdate_settled_sets_settledOn() {
        // Setup minimal required parent records
        Customer__c cust = new Customer__c(Name = 'Cust For Update');
        insert cust;

        Insurance_Product__c prod = new Insurance_Product__c(Name = 'Prod For Update');
        insert prod;

        Policy__c pol = new Policy__c();
        pol.Name = 'Policy For Update';
        pol.Policy_Number__c = 'POL-UPD-' + String.valueOf(Crypto.getRandomInteger()).replace('-', '');
        pol.Customer__c = cust.Id;
        pol.Insurance_Product__c = prod.Id;
        pol.Effective_Date__c = Date.today();
        insert pol;

        Claim__c c = new Claim__c();
        c.Name = 'Claim For Update';
        c.Policy__c = pol.Id;
        c.Claim_Status__c = 'New';
        // ensure Settled_On__c starts null
        if (Schema.SObjectType.Claim__c.fields.getMap().containsKey('Settled_On__c')) {
            c.put('Settled_On__c', null);
        }
        insert c;

        // Update status to Settled and verify Settled_On__c stamped
        c.Claim_Status__c = 'Settled';

        Test.startTest();
        update c;
        Test.stopTest();

        Claim__c updated = [
            SELECT Id, Claim_Status__c, Settled_On__c
            FROM Claim__c
            WHERE Id = :c.Id
        ];

        System.assertEquals('Settled', updated.Claim_Status__c, 'Status should be updated to Settled');

        if (Schema.SObjectType.Claim__c.fields.getMap().containsKey('Settled_On__c')) {
            System.assertNotEquals(null, updated.Settled_On__c, 'Settled_On__c should be set when status changes to Settled');
        }
    }
}