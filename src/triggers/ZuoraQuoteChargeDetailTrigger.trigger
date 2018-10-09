trigger ZuoraQuoteChargeDetailTrigger on zqu__QuoteChargeDetail__c (before insert, before update, before delete, after insert, after update, after delete) {
	XOTriggerFactory.createAndExecuteHandler(ZuoraQuoteChargeDetailTriggerHandler.class);
}