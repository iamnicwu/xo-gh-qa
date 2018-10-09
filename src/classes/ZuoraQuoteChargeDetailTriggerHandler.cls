public without sharing class ZuoraQuoteChargeDetailTriggerHandler implements XOTrigger {
	////////////////////////
	// Instance Variables //
	////////////////////////
	
	Set<String> cancellationIdSet = new Set<String>();
	Map<String, Inventory__c> cancellationInventoryMap = new Map<String, Inventory__c>();


	/**
	*   Method used to bulkify all data needed in any "before" action of a trigger.
	*/
	public void bulkBefore() {
		if (Trigger.isInsert || Trigger.isUpdate) {
			for (Integer i = 0; i < Trigger.new.size(); i++) {
				zqu__QuoteChargeDetail__c newRec = (zqu__QuoteChargeDetail__c)Trigger.new[i];
				// CSP-1543 | if Cancellation Quote populate set for query
				if (newRec.Subscription_Type__c == 'Cancel Subscription') {
					cancellationIdSet.add(newRec.Exist_Subscription_Id__c);
				}
			}
			if (cancellationIdSet.size() > 0) {
				for (Inventory__c invRec : [SELECT Id, Subscription_Product_Charge__r.Zuora__Zuora_Id__c FROM Inventory__c WHERE Subscription_Product_Charge__r.Zuora__Subscription__r.Zuora__Zuora_Id__c IN :cancellationIdSet] ){
					cancellationInventoryMap.put(invRec.Subscription_Product_Charge__r.Zuora__Zuora_Id__c, invRec);
				}
			}
		}
	}

	/**
	*   Method used to bulkify all data needed in any "after" action of a trigger.
	*/
	public void bulkAfter() {

	}

	/**
	*   All before insert logic should be done here. This method is called iteratively and as such
	*   should contain no actions which could potentially hit limits or is considered bad practice 
	*   in the Salesforce environment.
	*   
	*   @param  {SObject}   so Single SObject representation of the object being acted upon.
	*/
	public void beforeInsert(SObject so) {
		zqu__QuoteChargeDetail__c newRec = (zqu__QuoteChargeDetail__c)so;

		// use newRec.zqu__OriginalId__c to match in cancellationInventoryMap
		if (cancellationInventoryMap.containsKey(newRec.zqu__OriginalId__c)) {
			cancellationInventoryMap.remove(newRec.zqu__OriginalId__c);
			newRec.Inventory_Freed_By_Cancellation__c = true;
		}
	}

	/**
	*   All before update logic should be done here. This method is called iteratively and as such
	*   should contain no actions which could potentially hit limits or is considered bad practice
	*   in the Salesforce environment.
	*
	*   @param  {SObject}   oldSo Single SObject representation of the "old" copy of the current 
	*                             object being acted upon.
	*   @param  {SObject}   so    Single SObject representation of the object being acted upon.
	*/
	public void beforeUpdate(SObject oldSo, SObject so) {

	}

	/**
	*   All before delete logic should be done here. This method is called iteratively and as such
	*   should contain no actions which could potentilly hit limits or is considered bad practice
	*   in the Salesforce environment.
	*
	*   @param  {SObject}   so Single SObject representation of the object being acted upon.
	*/
	public void beforeDelete(SObject so) {

	}

	/**
	*   All after insert logic should be done here. This method is called iteratively and as such
	*   should contain no actions which could potentilly hit limits or is considered bad practice
	*   in the Salesforce environment. 
	*
	*   @param  {SObject}   so Single SObject representation of the object being acted upon.
	*/
	public void afterInsert(SObject so) {

	}

	/**
	*   All after update logic should be done here. This method is called iteratively and as such
	*   should contain no actions which could potentilly hit limits or is considered bad practice
	*   in the Salesforce environment.
	*   
	*   @param  {SObject}   oldSo Single SObject representation of the "old" copy of the current 
	*                             object being acted upon.
	*   @param  {SObject}   so    Single SObject representation of the object being acted upon.
	*/
	public void afterUpdate(SObject oldSo, SObject so) {

	}

	/**
	*   All after delete logic should be done here. This method is called iteratively and as such
	*   should contain no actions which could potentilly hit limits or is considered bad practice
	*   in the Salesforce environment. 
	*
	*   @param  {SObject}   so Single SObject representation of the object being acted upon.
	*/
	public void afterDelete(SObject so) {

	}

	/**
	*   All final logic in the "before" context should be done at this point such as modification to objects outside of
	*   the current object. At this point all updates to the current trigger transaction should be
	*   complete and all validation done.
	*/
	public void beforeAndFinally() {

	}

	/**
	*   All final logic in the "after" context should be done at this point such as modification to objects outside of
	*   the current object. At this point all updates to the current trigger transaction should be
	*   complete and all validation done.
	*/
	public void afterAndFinally() {

	}

	//////////////////////////
	// CUSTOM METHODS BELOW //
	//////////////////////////


}