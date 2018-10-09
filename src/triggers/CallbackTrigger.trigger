trigger CallbackTrigger on Callback__c (before delete, before update, before insert) {
	XOTriggerFactory.createAndExecuteHandler(CallbackTriggerHandler.class);
}