public without sharing class CallbackTriggerHandler implements XOTrigger{
	/**
	 * Method used to bulkify all data needed in any "before" action of a trigger.
	 */
	
	Set<Id> vipStrategySpecialistUserIdSet = new Set<Id>();
	Map<Id, Zuora__SubscriptionProductCharge__c> spcIdToSPCRecordMap = new Map<Id, Zuora__SubscriptionProductCharge__c>();
	Map<String, Id> marketIdToRecordIdMap = new Map<String, Id>();
	Map<String, Id> categoryTaxonomyIdToRecordIdMap = new Map<String, Id>();

	public void bulkBefore() {
		if (Trigger.isInsert) {
			Set<Id> spcIdSet = new Set<Id>();
			Set<String> marketIdSet = new Set<String>();
			Set<String> categoryIdSet = new Set<String>();

			// populate spcIdSet to use in query
			for (Integer i = 0; i < Trigger.new.size(); i++) {
				Callback__c callbackRecord = (Callback__c)Trigger.new[i];
				spcIdSet.add(callbackRecord.Subscription_Product_Charge__c);
			}

			// populate marketIdSet and categoryIdSet
			for (Zuora__SubscriptionProductCharge__c spcRecord : [SELECT Id, Market_ID__c, Category_Taxonomy_ID__c FROM Zuora__SubscriptionProductCharge__c WHERE Id IN :spcIdSet]) {
				spcIdToSPCRecordMap.put(spcRecord.Id, spcRecord);
				marketIdSet.add(spcRecord.Market_ID__c);
				categoryIdSet.add(spcRecord.Category_Taxonomy_ID__c);
			}

			// populate marketIdToRecordIdMap
			for (Market__c marketRecord : [SELECT Id, Market_ID__c FROM Market__c WHERE Market_ID__c IN :marketIdSet]) {
				marketIdToRecordIdMap.put(marketRecord.Market_ID__c, marketRecord.Id);
			}

			// populate categoryTaxonomyIdToRecordIdMap
			for (Category__c categoryRecord : [SELECT Id, Taxonomy_ID__c FROM Category__c WHERE Taxonomy_ID__c IN :categoryIdSet]) {
				categoryTaxonomyIdToRecordIdMap.put(categoryRecord.Taxonomy_ID__c, categoryRecord.Id);
			}
		}
		if (Trigger.isUpdate) {
			// CSP-1449 | if a Callback for a VIP Account is being reassigned, confirm the new owner is in the VIP Strategy Specialist permission set
			for (PermissionSetAssignment psa : [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = 'VIP_Strategy_Specialist']) {
				vipStrategySpecialistUserIdSet.add(psa.AssigneeId);
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
		Callback__c callbackRec = (Callback__c)so;

		// populate Market and Category lookups
		if (spcIdToSPCRecordMap.containsKey(callbackRec.Subscription_Product_Charge__c)) {
			Zuora__SubscriptionProductCharge__c spcRec = spcIdToSPCRecordMap.get(callbackRec.Subscription_Product_Charge__c);
			callbackRec.Market__c = marketIdToRecordIdMap.containsKey(spcRec.Market_ID__c) ? marketIdToRecordIdMap.get(spcRec.Market_ID__c) : null;
			callbackRec.Category__c = categoryTaxonomyIdToRecordIdMap.containsKey(spcRec.Category_Taxonomy_ID__c) ? categoryTaxonomyIdToRecordIdMap.get(spcRec.Category_Taxonomy_ID__c) : null;
		}

		// make sure the record's name max length is 80 characters
		if (callbackRec.Name.length() > 80) {
			callbackRec.Name = callbackRec.Name.left(80);
		}

		// CSP-1869 | if "Is_Possible_Renewal__c" is blank default to "No"
		callbackRec.Is_Possible_Renewal__c = String.isBlank(callbackRec.Is_Possible_Renewal__c) ? 'No' : callbackRec.Is_Possible_Renewal__c;
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
		Callback__c callbackRec = (Callback__c)so;
		Callback__c oldCallbackRec = (Callback__c)oldSo;

		// CSP-1449 | if a Callback for a VIP Account is being reassigned, confirm the new owner is in the VIP Strategy Specialist permission set
		if (callbackRec.VIP_Account__c && callbackRec.OwnerId != oldCallbackRec.OwnerId && !vipStrategySpecialistUserIdSet.contains(callbackRec.OwnerId)) {
			callbackRec.addError('Callbacks for VIP Accounts can only be reassigned to VIP Strategy Specialists');
		}

		// make sure the record's name max length is 80 characters
		if (callbackRec.Name.length() > 80) {
			callbackRec.Name = callbackRec.Name.left(80);
		}

		// CSP-1869 | if "Is_Possible_Renewal__c" is blank default to "No"
		callbackRec.Is_Possible_Renewal__c = String.isBlank(callbackRec.Is_Possible_Renewal__c) ? 'No' : callbackRec.Is_Possible_Renewal__c;
	}

	/**
	*   All before delete logic should be done here. This method is called iteratively and as such
	*   should contain no actions which could potentilly hit limits or is considered bad practice
	*   in the Salesforce environment.
	*
	*   @param  {SObject}   so Single SObject representation of the object being acted upon.
	*/
	public void beforeDelete(SObject so) {
		Callback__c callbackRec = (Callback__c)so;
		
		//CSP-1450 : Restrict user to delete callback record.
		callbackRec.addError('Callback Delete is not allowed');
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

}