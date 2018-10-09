trigger ZProductTrigger on zqu__ZProduct__c (before insert, before update, before delete, after insert, after update, after delete) {
	XOTriggerFactory.createAndExecuteHandler(ZProductTriggerHandler.class); 
}