public with sharing class ClaimService{
    /**
  * Submits a new claim.
  */
 public static Claim__c submitClaim(Id policyId, Decimal amount, String description) {
     if (policyId == null || amount == null || amount <= 0) {
         throw new AuraHandledException('Invalid claim submission.');
     }
     Claim__c claim = new Claim__c(
         Policy__c = policyId,
         Claim_Amount__c = amount,
         Description__c = description,
         Claim_Status__c = 'New'
     );
     insert claim;
     return claim;
 }

 /**
  * Approves or rejects a claim.
  */
 public static void reviewClaim(Id claimId, Boolean approve, String reviewerNote) {
     Claim__c claim = [SELECT Id, Claim_Status__c FROM Claim__c WHERE Id = :claimId LIMIT 1 FOR UPDATE];
     if (claim.Claim_Status__c != 'New') {
         throw new AuraHandledException('Only submitted claims can be reviewed.');
     }
     claim.Claim_Status__c = approve ? 'Approved' : 'Rejected';
     claim.Notes__c = reviewerNote;
     update claim;
 }

 /**
  * Settles an approved claim.
  */
 public static void settleClaim(Id claimId, Date settlementDate) {
     Claim__c claim = [SELECT Id, Claim_Status__c FROM Claim__c WHERE Id = :claimId LIMIT 1 FOR UPDATE];
     if (claim.Claim_Status__c != 'Approved') {
         throw new AuraHandledException('Only approved claims can be settled.');
     }
     claim.Claim_Status__c = 'Settled';
     claim.Incident_Date__c = settlementDate != null ? settlementDate : Date.today();
     update claim;
 }

}