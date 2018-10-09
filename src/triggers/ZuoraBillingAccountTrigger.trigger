trigger ZuoraBillingAccountTrigger on Zuora__CustomerAccount__c (before insert, before update, after update) {
	XOTriggerFactory.createAndExecuteHandler(ZuoraBillingAccountTriggerHandler.class);
}