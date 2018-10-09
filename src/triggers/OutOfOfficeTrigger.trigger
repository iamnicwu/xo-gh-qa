trigger OutOfOfficeTrigger on Out_Of_Office__c (before insert, before update, after insert, after update, before delete, after delete) {	
    XOTriggerFactory.createAndExecuteHandler(OutOfOfficeTriggerHandler.class);
}