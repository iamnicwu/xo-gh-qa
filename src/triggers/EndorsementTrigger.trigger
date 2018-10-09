trigger EndorsementTrigger on Endorsement__c (before insert, after insert) {
	XOTriggerFactory.createAndExecuteHandler(EndorsementTriggerHandler.class);
}