trigger InventoryTrigger on Inventory__c (before insert, before update, before delete, after insert, after update, after delete) {
	XOTriggerFactory.createAndExecuteHandler(InventoryTriggerHandler.class);
}