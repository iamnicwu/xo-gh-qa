trigger ProductRatePlanChargeTierTrigger on zqu__ProductRatePlanChargeTier__c (Before Insert, Before Update, Before Delete, After Insert, After Update, After Delete) {
    XOTriggerFactory.createAndExecuteHandler(ProductRatePlanChargeTierTriggerHandler.class);
}