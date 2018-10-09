trigger Product2Trigger on Product2 (before insert, before update, before delete, after insert, after update, after delete) {
	XOTriggerFactory.createAndExecuteHandler(Product2TriggerHandler.class); 
}