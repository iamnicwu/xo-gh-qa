public with sharing class ZuoraSubscriptionTriggerHandlerUtilities {
// SCO - commented this out as it creates a compile error and is not referenced anywhere
/*
	public static void AddSubscriptionProductChargesToPreviousSubscriptionVersions(List<Previous_Subscription_Version__c> psvList, Set<Id> oldListIdSet) {

		// this Map is also populated for use below when assignming products to Previous Subscription Version
		Map<String,Id> deletedSubscriptionToNewPreviousSubscriptionMap = new Map<String,Id>();
		for (Previous_Subscription_Version__c psv : psvList) {
			deletedSubscriptionToNewPreviousSubscriptionMap.put(psv.Zuora_Id__c, psv.Id);
		}

		String queryString = 'SELECT Id, Zuora__Zuora_Id__c, (SELECT';
		Set<String> subscriptionProductChargeFields = Schema.SObjectType.Zuora__SubscriptionProductCharge__c.fields.getMap().keySet();
		for (String fieldName : subscriptionProductChargeFields) {
			// can't insert records with duplicate values in Zuora__External_Id__c field
			if (fieldName.toLowerCase() != 'zuora__external_id__c') {
				queryString = queryString + ' ' + fieldName + ',';
			}
		}
		queryString = queryString.removeEnd(',');
		queryString = queryString + ' FROM Zuora__Subscription_Product_Charges__r) FROM Zuora__Subscription__c WHERE Id IN :oldListIdSet';
		List<Zuora__Subscription__c> productList = Database.query(queryString);

		// used for inserting new Subscription Product Charge records (clones of existing records)
		List<Zuora__SubscriptionProductCharge__c> zspcList = new List<Zuora__SubscriptionProductCharge__c>();

		for (Zuora__Subscription__c zs : productList) {
		    for (Zuora__SubscriptionProductCharge__c zspc : zs.Zuora__Subscription_Product_Charges__r) {
		        Zuora__SubscriptionProductCharge__c zspcClone = zspc.clone(False, True);
		        zspcClone.PreviousSubscriptionVersion__c = deletedSubscriptionToNewPreviousSubscriptionMap.get(zs.Zuora__Zuora_Id__c);
		        zspcClone.Zuora__Subscription__c = null;
		        zspcList.add(zspcClone);
		    }
		}

		insert zspcList;
	}



/*	// TODO: handle situation where subscription is being deleted, not amended
	@future
	public static void LinkPreviousSubscriptionsToCurrentSubscriptions() {
		Set<String> subscriptionNameSet = new Set<String>();

		List<Previous_Subscription_Version__c> previousSubList = [SELECT Id, Name, CurrentSubscription__c FROM Previous_Subscription_Version__c WHERE CurrentSubscription__c = null];
		
		if (!previousSubList.isEmpty()) {
			for (Previous_Subscription_Version__c psv : previousSubList) {
				subscriptionNameSet.add(psv.Name);
			}

			List<Zuora__Subscription__c> zsList = [SELECT Id, Name FROM Zuora__Subscription__c WHERE Name IN :subscriptionNameSet]; 
		
			Map<String,Id> zsMap = new Map<String,Id>();
			for (Zuora__Subscription__c zs : zsList) {
				zsMap.put(zs.Name, zs.Id);
			}

			for (Previous_Subscription_Version__c psv : previousSubList) {
				if (zsMap.containsKey(psv.Name)) {
					psv.CurrentSubscription__c = zsMap.get(psv.Name);
				}
			}

			update previousSubList;
		}
	}


	public class AsyncExecutionExample implements Queueable, Database.AllowsCallouts {
		String accountName;

		public AsyncExecutionExample(String accountName) {
			this.accountName = accountName;
		}

	    public void execute(QueueableContext context) {
	        Account a = new Account(Name=accountName,Phone='(415) 555-1212');
	        insert a;        
	    }
	}
*/
	/*
	global class scheduledTest implements Schedulable {

		global void execute(SchedulableContext sc) {

		}


	}
	*/

}