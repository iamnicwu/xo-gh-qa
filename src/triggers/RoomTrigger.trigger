trigger RoomTrigger on Room__c (before insert, before update, before delete, after insert, after update, after delete) {
    XOTriggerFactory.createAndExecuteHandler(RoomTriggerHandler.class);
}