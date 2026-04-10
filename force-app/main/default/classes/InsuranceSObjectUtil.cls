public with sharing class InsuranceSObjectUtil {

    /** True if an sObject exists in the org */
    public static Boolean objectExists(String apiName) {
        return Schema.getGlobalDescribe().containsKey(apiName);
    }

    /** True if a field exists on an sObject */
    public static Boolean fieldExists(String sObjectApiName, String fieldApiName) {
        if (!objectExists(sObjectApiName)) return false;
        Schema.SObjectType t = Schema.getGlobalDescribe().get(sObjectApiName);
        return t.getDescribe().fields.getMap().containsKey(fieldApiName);
    }

    /** Safe put: only sets the field if it exists */
    public static void safePut(SObject sobj, String fieldApiName, Object value) {
        if (sobj == null) return;
        Map<String, Schema.SObjectField> fmap = sobj.getSObjectType().getDescribe().fields.getMap();
        if (fmap != null && fmap.containsKey(fieldApiName)) {
            sobj.put(fieldApiName, value);
        }
    }

    /** Create a history record safely (object + fields may vary between orgs) */
    public static SObject newHistoryRecord(String historyObjectApiName, Map<String, Object> fieldValues) {
        if (!objectExists(historyObjectApiName)) return null;

        SObject hist = Schema.getGlobalDescribe().get(historyObjectApiName).newSObject();
        Map<String, Schema.SObjectField> fmap = hist.getSObjectType().getDescribe().fields.getMap();

        if (fieldValues != null) {
            for (String k : fieldValues.keySet()) {
                if (fmap.containsKey(k)) {
                    hist.put(k, fieldValues.get(k));
                }
            }
        }
        return hist;
    }

    /** Generate a reasonably unique human-readable key */
    public static String generateKey(String prefix, Integer digits) {
        if (digits == null || digits <= 0) digits = 6;
        Integer max = (Integer) Math.pow(10, digits) - 1;
        Integer n = Math.mod(Math.abs(Crypto.getRandomInteger()), max);
        String padded = String.valueOf(n).leftPad(digits, '0');
        return (prefix == null ? '' : prefix) + padded;
    }
}
