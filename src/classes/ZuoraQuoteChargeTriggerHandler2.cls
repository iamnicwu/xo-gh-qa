public without sharing class ZuoraQuoteChargeTriggerHandler2 implements ITrigger {
	
	private Set<Id> parentQuoteIdSet = new Set<Id>();
	private Map<Id,zqu__Quote__c> parentQuoteMap = new Map<Id, zqu__Quote__c>();

	// Constructor
	public ZuoraQuoteChargeTriggerHandler2() {	
	}

    /**
     * bulkBefore
     *
     * This method is called prior to execution of a BEFORE trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */	
	public void bulkBefore() {
		for (SObject zqcSObject : Trigger.new) {
			zqu__QuoteCharge__c zqcRecord = (zqu__QuoteCharge__c)zqcSObject;
			parentQuoteIdSet.add(zqcRecord.zqu__Quote__c);
		}

		parentQuoteMap = new Map<Id,zqu__Quote__c>([SELECT Id, SalesRepId__c, RenewalRepId__c, RSD_Id__c FROM zqu__Quote__c WHERE Id IN :parentQuoteIdSet]);
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
    	zqu__QuoteCharge__c record = (zqu__QuoteCharge__c)so;
		if (record.zqu__Quote__c != null) {
			zqu__Quote__c tempQuote = parentQuoteMap.get(record.zqu__Quote__c);
			record.SalesRepId__c = tempQuote.SalesRepId__c;
			record.RenewalRepId__c = tempQuote.RenewalRepId__c;
			record.RSD_Id__c = tempQuote.RSD_Id__c;
		}
    }
 
    public void beforeUpdate(SObject oldSo, SObject so) {
    	zqu__QuoteCharge__c record = (zqu__QuoteCharge__c)so;
    	zqu__QuoteCharge__c oldRecord = (zqu__QuoteCharge__c)oldSo;
    }
 
    public void beforeDelete(SObject so) {
    	zqu__QuoteCharge__c record = (zqu__QuoteCharge__c)so;
    }
 
    public void afterInsert(SObject so) {
    	zqu__QuoteCharge__c record = (zqu__QuoteCharge__c)so;
    }
 
    public void afterUpdate(SObject oldSo, SObject so) {
    	zqu__QuoteCharge__c record = (zqu__QuoteCharge__c)so;
    	zqu__QuoteCharge__c oldRecord = (zqu__QuoteCharge__c)oldSo;
    }
 
    public void afterDelete(SObject so) {
    	zqu__QuoteCharge__c record = (zqu__QuoteCharge__c)so;
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