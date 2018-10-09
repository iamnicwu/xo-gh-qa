trigger ContactTrigger on Contact (before insert, before update, after update) {
    XOTriggerFactory.createAndExecuteHandler(ContactTriggerHandler.class);
}