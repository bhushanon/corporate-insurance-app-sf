// EmployeeDashboardController.cls
public class EmployeeDashboardController {
    public List<Policy__c> myPolicies {get;set;}
    public Id customerId {get;set;} // Set via custom setting or URL param in real deployment

    public EmployeeDashboardController() {
        customerId = '003XXXXXXXXXXXX'; // Demo - replace with real lookup
        myPolicies = [SELECT Policy_Number__c, Status__c, Premium_Amount__c, Policy_Start_Date__c 
                      FROM Policy__c WHERE Customer__c = :customerId ORDER BY CreatedDate DESC];
    }

    public PageReference startEnrollment() {
        return Page.Enrollment;
    }
}