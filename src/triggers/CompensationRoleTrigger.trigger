trigger CompensationRoleTrigger on Compensation_Role__c (before insert, before update, after insert, after update, before delete, after delete) {
    XOTriggerFactory.createAndExecuteHandler(CompensationRoleTriggerHandler.class);
}