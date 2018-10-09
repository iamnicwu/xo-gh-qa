trigger InvoiceTrigger on Zuora__ZInvoice__c (before insert, before update, after insert, after update, before delete, after delete) {
    
    XOTriggerFactory.createAndExecuteHandler(InvoiceTriggerHandler.class);
}