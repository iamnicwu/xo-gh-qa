trigger PotentialDuplicateTrigger on CRMfusionDBR101__Potential_Duplicate__c (before insert, before update, after insert, after update) {
    XOTriggerFactory.createAndExecuteHandler(PotentialDuplicateTriggerHandler.class);
}