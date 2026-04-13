public with sharing class PolicyService{
    /**
 * Creates a new policy and returns the record.
 */
public static Policy__c createPolicy(Id customerId, Id productId, Date startDate) {
    if (customerId == null || productId == null || startDate == null) {
        throw new AuraHandledException('Missing required fields for policy creation.');
    }
    Policy__c policy = new Policy__c(
        Customer__c = customerId,
        Insurance_Product__c = productId,
        Effective_Date__c = startDate,
        Policy_Status__c = 'Draft'
    );
    insert policy;
    return policy;
}

/**
 * Activates a policy.
 */
public static void activatePolicy(Id policyId) {
    Policy__c policy = [SELECT Id, Policy_Status__c FROM Policy__c WHERE Id = :policyId LIMIT 1 FOR UPDATE];
    if (policy.Policy_Status__c != 'Draft') {
        throw new AuraHandledException('Only draft policies can be activated.');
    }
    policy.Policy_Status__c = 'Active';
    update policy;
}

/**
 * Cancels, lapses, or reinstates a policy.
 */
public static void updatePolicyStatus(Id policyId, String newStatus) {
    Set<String> allowed = new Set<String>{'Cancelled', 'Lapsed', 'Reinstated'};
    if (!allowed.contains(newStatus)) {
        throw new AuraHandledException('Invalid status update.');
    }
    Policy__c policy = [SELECT Id, Policy_Status__c FROM Policy__c WHERE Id = :policyId LIMIT 1 FOR UPDATE];
    policy.Policy_Status__c = newStatus;
    update policy;
}

}