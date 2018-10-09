trigger ProductRatePlanChargeTrigger on zqu__ProductRatePlanCharge__c (before insert, before update) {
	XOTriggerFactory.createAndExecuteHandler(ProductRatePlanChargeTriggerHandler.class);
}