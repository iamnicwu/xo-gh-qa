trigger DuplicateRecordSetTrigger on DuplicateRecordSet (before insert, before update, after insert, after update) {		
	XOTriggerFactory.createAndExecuteHandler(DuplicateRecordSetTriggerHandler.class);	
}