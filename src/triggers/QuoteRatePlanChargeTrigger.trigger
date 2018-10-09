/* 
<trigger>
  <name>QuoteRatePlanChargeTrigger</name>
  <purpose>TO capture List price and Discount Price from a quote and display them in Zuora Subscription</purpose>
  <Modified>
    <by>Om Vankayalapati</by>
    <date>7/17/2015</date>
    <ticket>SF-600</ticket>
  </Modified>
</trigger>
*/
//Before Insert and Before Update
trigger QuoteRatePlanChargeTrigger on zqu__QuoteRatePlanCharge__c (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
			
            // Om's Code
            // JPS NOTE: also added additional logic to record the ID of the parent Quote Rate Plan
            for(zqu__QuoteRatePlanCharge__c qc: Trigger.new) {
                qc.Quote_Rate_Plan_ID__c = qc.zqu__QuoteRatePlan__c;
                if(qc.zqu__ListPrice__c != Null && qc.zqu__Total__c != Null) {
                    qc.List_Price__c = String.valueOf(qc.zqu__ListPrice__c);
                }
                // CSP-996 | if Billing Period isn't equal to Month, set the Billing Period Alignment to Align to Subscription Start
                QuoteRatePlanChargeTriggerHandler.SetBillingPeriodAlignment(qc);
            }
            
            // Steve's code to copy down the location id
            List<Id> accountIdsForLocations = new List<id>();
            for(zqu__QuoteRatePlanCharge__c qc: Trigger.new) {
            	if (qc.Location_Vendor__c != null)
            	{
            		if (trigger.isInsert || (trigger.isUpdate && qc.Location_Vendor__c != trigger.oldMap.get(qc.Id).Location_Vendor__c))
            		{
            			accountIdsForLocations.add(qc.Location_Vendor__c);
            		}
            	}
            }
            
            if (accountIdsForLocations.size() > 0)
            {
            	List<Account> accountsWithLocationIds = [Select Id, DynamicsAccID__c,Name from Account where id in : accountIdsForLocations];
	            for(zqu__QuoteRatePlanCharge__c qc: Trigger.new) {
	            	if (qc.Location_Vendor__c != null)
	            	{
	            		for (Account a : accountsWithLocationIds)
	            		{
	            			if (a.Id == qc.Location_Vendor__c)
	            			{
	            				System.Debug('Adding location id ' + a.DynamicsAccID__c + ' to QRPC ' + qc.Id);
	            				qc.LocationVendorDynamicsAccountID__c = a.DynamicsAccID__c;
                                qc.Venue_Name__c = a.Name;
	            				break;
	            			}
	            		}
	            	}
	            }
            	
            }
            
            // Vijay's code (SF-583)
            QuoteRatePlanChargeTriggerHandler.RecordZProductJobType(Trigger.new);
            
            // SF-587 - copy over the print issue Id
	        QuoteRatePlanChargeTriggerHandler.UpdatePrintIssueIds(Trigger.new);

            if (Trigger.isInsert) {
                // JPS Code
                QuoteRatePlanChargeTriggerHandler.UpdateIDsForCommissionTracking(Trigger.new);
                QuoteRatePlanChargeTriggerHandler.RecordMarketIdAndCategoryTaxonomyId(Trigger.new);
                QuoteRatePlanChargeTriggerHandler.setIsPossibleRenewalPicklistValue(Trigger.new);
            }
            
        }
    }
}