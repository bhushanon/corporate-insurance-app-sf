public with sharing class EligibilityValidator{
    /**
    * Checks if employer is active.
    */
   public static Boolean isEmployerActive(Id employerId) {
       if (employerId == null) return false;
       Employer__c emp = [SELECT Id, State__c FROM Employer__c WHERE Id = :employerId LIMIT 1];
       return emp.State__c == 'Active';
   }

   /**
    * Checks if product is valid for enrollment.
    */
   public static Boolean isProductValid(Id productId, Date asOfDate) {
       if (productId == null || asOfDate == null) return false;
       Insurance_Product__c prod = [
           SELECT Id, Effective_From__c, Effective_To__c 
           FROM Insurance_Product__c 
           WHERE Id = :productId LIMIT 1
       ];
       return prod.Effective_From__c <= asOfDate && 
              (prod.Effective_To__c == null || prod.Effective_To__c >= asOfDate);
   }

   /**
    * Checks if add-on is mapped to product.
    */
   public static Boolean isAddonMapped(Id productId, Id addonId) {
       if (productId == null || addonId == null) return false;
       List<Insurance_Product__c> mapping = [
           SELECT Id FROM Insurance_Product__c 
           WHERE Id =:productId
       ];
       return !mapping.isEmpty();
   }

}