trigger PartnersSalesProfileTrigger on Partners_SalesProfile__c (after insert, after update) {
	//TriggerFactory.createAndExecuteHandler(PartnersSalesProfileTriggerHandler.class, 'Partners_SalesProfile__c', null);
	XOTriggerFactory.createAndExecuteHandler(PartnersSalesProfileTriggerHandler.class);
}