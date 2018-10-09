trigger ZuoraSubscriptionTrigger on Zuora__Subscription__c (before insert, before update, after update, before delete, after insert) {
    TriggerFactory.createAndExecuteHandler(ZuoraSubscriptionTriggerHandler.class, 'Zuora__Subscription__c', null);
}