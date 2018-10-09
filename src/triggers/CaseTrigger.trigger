trigger CaseTrigger on Case(before insert, before update, before delete, after insert, after update, after delete) {
    XOTriggerFactory.createAndExecuteHandler(CaseTriggerHandler.class);
}