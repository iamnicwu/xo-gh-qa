public without sharing class OppLocalPendingApprovalTriggerHandler implements ITrigger 
{
	Map<String,List<zqu__QuoteRatePlanCharge__c>> OppIdToQuoteRatePlanChargesMap;
	Map<Id,zqu__QuoteRatePlanCharge__c> quoteRatePlanChargesToUpdate;
	List<zqu__Quote__c> quotesList;
	
	private static string internalApprovalStage = 'Client Approved';
	
	public static boolean ObjectMeetsCriteriaForTrigger(sObject obj, sObject oldObj)
	{
		Opportunity oppObj = (Opportunity)obj;
		Opportunity oppOldObj = null;
		if (oldObj != null)
		{
			oppOldObj = (Opportunity)oldObj;
		}
		
		boolean retval = false;
		
		if (oppObj.Lock_Quotes__c == true)
		{
			if (oppOldObj == null || (oppObj.Lock_Quotes__c != oppOldObj.Lock_Quotes__c))
			{
				retVal = true;
			}
		}
		return retVal;
	}
	
	public OppLocalPendingApprovalTriggerHandler()
	{
		OppIdToQuoteRatePlanChargesMap = new Map<String,List<zqu__QuoteRatePlanCharge__c>>();
		quoteRatePlanChargesToUpdate = new Map<Id, zqu__QuoteRatePlanCharge__c>();
		quotesList = new List<zqu__Quote__c>();
	}
	
    /**
     * bulkBefore
     *
     * This method is called prior to execution of a BEFORE trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public void bulkBefore()
    {

    }
    
    /**
     * bulkAfter
     *
     * This method is called prior to execution of an AFTER trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public void bulkAfter()
    {
    }
 
    /**
     * beforeInsert
     *
     * This method is called iteratively for each record to be inserted during a BEFORE
     * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
     */
    public void beforeInsert(SObject so)
    {
    	
    }
 
    /**
     * beforeUpdate
     *
     * This method is called iteratively for each record to be updated during a BEFORE
     * trigger.
     */
    public void beforeUpdate(SObject oldSo, SObject so)
    {
    }
   
   
    /**
     * beforeDelete
     *
     * This method is called iteratively for each record to be deleted during a BEFORE
     * trigger.
     */
    public void beforeDelete(SObject so)
    {
    	
    }
 
    /**
     * afterInsert
     *
     * This method is called iteratively for each record inserted during an AFTER
     * trigger. Always put field validation in the 'After' methods in case another trigger
     * has modified any values. The record is 'read only' by this point.
     */
    public void afterInsert(SObject so)
    {
    	
    }
    
    /**
     * afterUpdate
     *
     * This method is called iteratively for each record updated during an AFTER
     * trigger.
     */
    public void afterUpdate(SObject oldSo, SObject so)
    {
    }
 
    /**
     * afterDelete
     *
     * This method is called iteratively for each record deleted during an AFTER
     * trigger.
     */
    public void afterDelete(SObject so)
    {
    	
    }
 
    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public void andFinally()
    {
    	if (quoteRatePlanChargesToUpdate.size() > 0)
    	{
    		// convert a set to a list to send to the db
    		List<zqu__QuoteRatePlanCharge__c> quoteRatePlanChargesToUpdateList = quoteRatePlanChargesToUpdate.values();
    		update quoteRatePlanChargesToUpdateList;

	    	// calculate the total discounts on the quote
	    	for (zqu__Quote__c q : quotesList)
	    	{
	    		System.Debug('Updating quote: ' + q.Name);
	    		q.Total_Contract_Discount__c = 0;
	    		for (zqu__QuoteRatePlanCharge__c qrpc : quoteRatePlanChargesToUpdateList)
	    		{
	    			if (qrpc.Quote_Id__c == q.Id)
	    			{
	    				q.Total_Contract_Discount__c += qrpc.Total_Contract_Discount__c;
	    			}
	    		}
	    	}
	    	
	    	// calculate the dates on the quotes
	    	OpportunitySendToZBillingController.SetQuoteDates(quotesList);
	    	
	    	update quotesList;

    	}
    	
    }
}