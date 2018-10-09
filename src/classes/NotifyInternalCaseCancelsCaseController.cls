//Used to csp-2484 email template show case and Feature Request cancelled info
public without sharing class NotifyInternalCaseCancelsCaseController {
    public Id caseId {get;set;}
    public Case currentCase {
		get{
			if (currentCase == null) {
					currentCase = new Case();
			}
			//csp-2484 Find case and Feature Request cancelled info by case id 
			List<Case> caseList = [SELECT Id, Account.Name, CaseNumber, Owner.Name, RecordType.Name, Contact.Name, Saved_By__c, Outcome__c, Thread_ID__c, Rep_Type__c, 
															Dollar_Amount_Saved__c, (SELECT Id, Rate_plan_name__c, Status__c, case__c, Sales_Rep__c, Price__c, Period__c, 
																	Subscription_Product_Charge__r.Zuora__Subscription__r.Sales_Rep__r.FirstName,
																	Subscription_Product_Charge__r.Zuora__Subscription__r.Sales_Rep__c,Term_End_Date__c,
														 			Subscription_Product_Charge__r.Zuora__Subscription__r.Sales_Rep__r.LastName FROM Feature_Requested_Cancelled__r 
														 		WHERE Status__c != 'Requested Cancelled')
																FROM Case 
																WHERE Id = :caseId limit 1];
			if (!caseList.isEmpty()) {
				currentCase = (Case)caseList[0];
			}
			return currentCase;
		} 
		set;
	}
	public String caseLink{
		get{
			return URL.getSalesforceBaseUrl().toExternalForm() + '/' + caseId;
		}
		set;
	} 
}