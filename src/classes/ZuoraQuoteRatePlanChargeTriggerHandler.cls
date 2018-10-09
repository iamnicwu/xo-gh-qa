public without sharing class ZuoraQuoteRatePlanChargeTriggerHandler implements ITrigger {
    

    // Constructor
    public ZuoraQuoteRatePlanChargeTriggerHandler() {   
    }

    /**
     * bulkBefore
     *
     * This method is called prior to execution of a BEFORE trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */ 
    public void bulkBefore() {


    }   
 
    /**
     * bulkAfter
     *
     * This method is called prior to execution of an AFTER trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public void bulkAfter() {
        // do nothing for now
    }

    public void beforeInsert(SObject so) {
        zqu__QuoteRatePlanCharge__c record = (zqu__QuoteRatePlanCharge__c)so;
    }
 
    public void beforeUpdate(SObject oldSo, SObject so) {
        zqu__QuoteRatePlanCharge__c record = (zqu__QuoteRatePlanCharge__c)so;
        zqu__QuoteRatePlanCharge__c oldRecord = (zqu__QuoteRatePlanCharge__c)oldSo;
    }
 
    public void beforeDelete(SObject so) {
        zqu__QuoteRatePlanCharge__c record = (zqu__QuoteRatePlanCharge__c)so;
    }
 
    public void afterInsert(SObject so) {
        zqu__QuoteRatePlanCharge__c record = (zqu__QuoteRatePlanCharge__c)so;
    }
 
    public void afterUpdate(SObject oldSo, SObject so) {
        zqu__QuoteRatePlanCharge__c record = (zqu__QuoteRatePlanCharge__c)so;
        zqu__QuoteRatePlanCharge__c oldRecord = (zqu__QuoteRatePlanCharge__c)oldSo;
    }
 
    public void afterDelete(SObject so) {
        zqu__QuoteRatePlanCharge__c record = (zqu__QuoteRatePlanCharge__c)so;
    }
 
    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public void andFinally() {
        // do nothing for now
    }
}