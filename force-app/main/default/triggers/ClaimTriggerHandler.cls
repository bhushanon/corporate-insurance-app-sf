public with sharing class ClaimTriggerHandler {

    // Simple recursion guard for after-context operations (history inserts).
    private static Boolean isRunning = false;

    public static void beforeInsert(List<Claim__c> newList) {
        if (newList == null || newList.isEmpty()) return;

        // 1) Defaults
        for (Claim__c c : newList) {
            // Claim_Number__c: if missing, generate a readable key (external id field in our object spec)
            if (InsuranceSObjectUtil.fieldExists('Claim__c', 'Claim_Number__c')
                && (String) c.get('Claim_Number__c') == null) {
                InsuranceSObjectUtil.safePut(c, 'Claim_Number__c', InsuranceSObjectUtil.generateKey('CLM-', 8));
            }

            // Reported_Date__c default = today (if field exists)
            if (InsuranceSObjectUtil.fieldExists('Claim__c', 'Reported_Date__c')
                && c.get('Reported_Date__c') == null) {
                InsuranceSObjectUtil.safePut(c, 'Reported_Date__c', Date.today());
            }

            // Claim_Status__c default = 'New' (if field exists and not set)
            if (InsuranceSObjectUtil.fieldExists('Claim__c', 'Claim_Status__c')
                && (String) c.get('Claim_Status__c') == null) {
                InsuranceSObjectUtil.safePut(c, 'Claim_Status__c', 'New');
            }
        }

        // 2) If Policy__c is provided but Customer__c is blank, try deriving Customer/Employer from Policy
        linkFromPolicy(newList, null);
    }

    public static void beforeUpdate(List<Claim__c> newList, Map<Id, Claim__c> oldMap) {
        if (newList == null || newList.isEmpty()) return;

        // 1) Derive Customer/Employer from Policy if needed
        linkFromPolicy(newList, oldMap);

        // 2) If status transitions to Settled, set Settled_On__c if available and empty
        Boolean hasStatus = InsuranceSObjectUtil.fieldExists('Claim__c', 'Claim_Status__c');
        Boolean hasSettledOn = InsuranceSObjectUtil.fieldExists('Claim__c', 'Settled_On__c');

        if (hasStatus && hasSettledOn) {
            for (Claim__c c : newList) {
                Claim__c oldC = oldMap != null ? oldMap.get(c.Id) : null;
                if (oldC == null) continue;

                String oldStatus = (String) oldC.get('Claim_Status__c');
                String newStatus = (String) c.get('Claim_Status__c');

                if (oldStatus != newStatus
                    && newStatus != null
                    && newStatus.equalsIgnoreCase('Settled')
                    && c.get('Settled_On__c') == null) {
                    InsuranceSObjectUtil.safePut(c, 'Settled_On__c', System.now());
                }
            }
        }
    }

    public static void beforeDelete(List<Claim__c> oldList) {
        // No-op for now
    }

    public static void afterInsert(List<Claim__c> newList) {
        // Write history for "created" event if Claim_History__c exists
        writeHistory(newList, null, 'CREATED');
    }

    public static void afterUpdate(List<Claim__c> newList, Map<Id, Claim__c> oldMap) {
        // Write history when status changes
        writeHistory(newList, oldMap, 'UPDATED');
    }

    public static void afterDelete(List<Claim__c> oldList, Map<Id, Claim__c> oldMap) {
        // Optional: history on delete (skip by default to avoid noise)
    }

    public static void afterUndelete(List<Claim__c> newList) {
        // Optional: history on undelete
    }

    // -------------------------
    // Internal helpers
    // -------------------------

    /**
     * If Policy__c is populated and Customer__c / Employer__c are empty,
     * populate them from Policy__c.Customer__c / Policy__c.Employer__c (if those fields exist).
     */
    private static void linkFromPolicy(List<Claim__c> claims, Map<Id, Claim__c> oldMap) {
        if (claims == null || claims.isEmpty()) return;

        Boolean claimHasPolicy = InsuranceSObjectUtil.fieldExists('Claim__c', 'Policy__c');
        Boolean claimHasCustomer = InsuranceSObjectUtil.fieldExists('Claim__c', 'Customer__c');
        Boolean claimHasEmployer = InsuranceSObjectUtil.fieldExists('Claim__c', 'Employer__c');

        if (!claimHasPolicy) return;

        // collect policy ids where we need enrichment
        Set<Id> policyIds = new Set<Id>();
        for (Claim__c c : claims) {
            Id polId = (Id) c.get('Policy__c');
            if (polId == null) continue;

            Boolean needsCustomer = claimHasCustomer && c.get('Customer__c') == null;
            Boolean needsEmployer = claimHasEmployer && c.get('Employer__c') == null;

            // Only enrich when something is missing
            if (needsCustomer || needsEmployer) {
                policyIds.add(polId);
            }
        }
        if (policyIds.isEmpty()) return;

        // Policy fields availability
        Boolean policyHasCustomer = InsuranceSObjectUtil.fieldExists('Policy__c', 'Customer__c');
        Boolean policyHasEmployer = InsuranceSObjectUtil.fieldExists('Policy__c', 'Employer__c');

        // Nothing to enrich if Policy doesn't have these fields
        if (!policyHasCustomer && !policyHasEmployer) return;

        Map<Id, Policy__c> polMap = new Map<Id, Policy__c>();
        String soql = 'SELECT Id'
            + (policyHasCustomer ? ', Customer__c' : '')
            + (policyHasEmployer ? ', Employer__c' : '')
            + ' FROM Policy__c WHERE Id IN :policyIds';

        for (Policy__c p : Database.query(soql)) {
            polMap.put(p.Id, p);
        }

        for (Claim__c c : claims) {
            Id polId = (Id) c.get('Policy__c');
            if (polId == null) continue;
            Policy__c p = polMap.get(polId);
            if (p == null) continue;

            if (claimHasCustomer && c.get('Customer__c') == null && policyHasCustomer) {
                InsuranceSObjectUtil.safePut(c, 'Customer__c', p.get('Customer__c'));
            }
            if (claimHasEmployer && c.get('Employer__c') == null && policyHasEmployer) {
                InsuranceSObjectUtil.safePut(c, 'Employer__c', p.get('Employer__c'));
            }
        }
    }

    /**
     * Writes Claim_History__c records if the object exists.
     * This is schema-safe: it only sets fields that exist on Claim_History__c.
     *
     * Expected (optional) fields on Claim_History__c that we'll try to set:
     * - Claim__c (Lookup)
     * - Event_Type__c (Text/Picklist)
     * - Old_Status__c (Text/Picklist)
     * - New_Status__c (Text/Picklist)
     * - Changed_On__c (DateTime)
     * - Changed_By__c (Lookup(User))
     * - Notes__c (LongTextArea)
     */
    private static void writeHistory(List<Claim__c> newList, Map<Id, Claim__c> oldMap, String eventType) {
        if (isRunning) return;
        isRunning = true;
        try {
            if (newList == null || newList.isEmpty()) return;
            if (!InsuranceSObjectUtil.objectExists('Claim_History__c')) return;

            Boolean hasStatus = InsuranceSObjectUtil.fieldExists('Claim__c', 'Claim_Status__c');

            List<SObject> historyToInsert = new List<SObject>();

            for (Claim__c c : newList) {
                String oldStatus = null;
                String newStatus = null;

                if (hasStatus) {
                    newStatus = (String) c.get('Claim_Status__c');
                    if (oldMap != null && oldMap.containsKey(c.Id)) {
                        oldStatus = (String) oldMap.get(c.Id).get('Claim_Status__c');
                    }
                }

                // For updates, only log when status changes (keeps history meaningful)
                if (eventType == 'UPDATED' && hasStatus) {
                    if (oldStatus == newStatus || (oldStatus != null && oldStatus.equals(newStatus))) {
                        continue;
                    }
                }

                Map<String, Object> fields = new Map<String, Object>();
                fields.put('Claim__c', c.Id);
                fields.put('Event_Type__c', eventType);

                if (hasStatus) {
                    fields.put('Old_Status__c', oldStatus);
                    fields.put('New_Status__c', newStatus);
                }

                fields.put('Changed_On__c', System.now());
                fields.put('Changed_By__c', UserInfo.getUserId());

                SObject hist = InsuranceSObjectUtil.newHistoryRecord('Claim_History__c', fields);
                if (hist != null) historyToInsert.add(hist);
            }

            if (!historyToInsert.isEmpty()) {
                insert historyToInsert;
            }
        } finally {
            isRunning = false;
        }
    }
}
