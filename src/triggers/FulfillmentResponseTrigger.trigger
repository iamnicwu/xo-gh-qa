trigger FulfillmentResponseTrigger on Fulfillment_Response__c (before insert, after insert) {
    XOTriggerFactory.createAndExecuteHandler(FulfillmentResponseTriggerHandler.class);
}