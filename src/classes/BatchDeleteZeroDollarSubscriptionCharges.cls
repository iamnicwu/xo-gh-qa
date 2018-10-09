/* 
<Class>
  <name>BatchDeleteZeroDollarSubscriptionCharges</name>
  <purpose>To remove any Subscription Product and Charges (Zuora) that have no value to the system.  There are gb of migrated data that represent charges with $0 value.  The only exception are migrated charges that 
  	are labelled "Charge #00", by allowing those through we guarantee there is at least one charge associated with the product.  All non-migrated charges are let through.
  </purpose>
  <created>
    <by>Steve O'Neal</by>
    <date>03/01/2016</date>
    <ticket>CSP-291</ticket>
  </created>
</Class>
*/
global class BatchDeleteZeroDollarSubscriptionCharges implements Database.Batchable<sObject> {
	public string query = '';
	
	global BatchDeleteZeroDollarSubscriptionCharges()
	{
		query = ' SELECT ID, Name, Zuora__TotalContractValue__c, Zuora__Subscription__r.Product_Line__c '
			  + ' FROM Zuora__SubscriptionProductCharge__c'
			  + ' WHERE (Zuora__TotalContractValue__c = 0 AND Name <> \'Charge #00\')'
			  + '   AND (Zuora__Subscription__r.Product_Line__c = \'\' OR Zuora__Subscription__r.Product_Line__c = \'Migrated Contract\')';
			  
		System.Debug(query);
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<Zuora__SubscriptionProductCharge__c> scope) {
   		try
   		{
	   		Database.delete(scope, false);
   		}
   		catch (Exception e)
   		{
   			System.Debug(e);
   		}
   	}
   	
	global void finish(Database.BatchableContext BC) {
		
	}

}