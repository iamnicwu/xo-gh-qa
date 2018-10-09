/* 
<Class>
  <name>BatchDeleteNonsellableRatePlans</name>
  <purpose>To remove any deleted or migrated Product Rate Plans as they eat up disk space
  </purpose>
  <created>
    <by>Steve O'Neal</by>
    <date>03/01/2016</date>
    <ticket>CSP-291</ticket>
  </created>
</Class>
*/
global class BatchDeleteNonsellableRatePlans implements Database.Batchable<sObject> {
	public string query = '';
	
	global BatchDeleteNonsellableRatePlans()
	{
		// Note the date - all migrated plans had an effective end date of 1/31/2016.  Using this date is the most reliable way to remove migrated plans as the only other alternative is to look for the "^" symbol
		// Delete any rate plans that were marked deleted in Zuora or were a migration plan
		query = ' SELECT ID, zqu__Deleted__c,  zqu__EffectiveEndDate__c'
			  + ' FROM zqu__ProductRatePlan__c'
			  + ' WHERE zqu__Deleted__c = TRUE OR zqu__EffectiveEndDate__c < 2016-02-01';
			  
		System.Debug(query);
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<zqu__ProductRatePlan__c> scope) {
   		try
   		{
	   		Database.delete(scope, false);
   		}
   		catch (Exception e)
   		{
   			System.Debug(e);
   		}
   	}
   	
	global void finish(Database.BatchableContext BC) {
		
	}

}