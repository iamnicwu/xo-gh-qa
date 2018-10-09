trigger ProductRatePlanTrigger on zqu__ProductRatePlan__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
    XOTriggerFactory.createAndExecuteHandler(ProductRatePlanTriggerHandler.class); 
}