trigger LocalSalesRepAssignmentTrigger on Local_Sales_Rep_Assignment__c (before insert, before update, after insert, after update) {
    XOTriggerFactory.createAndExecuteHandler(LocalSalesRepAssignmentTriggerHandler.class);
}