/* 
<Class>
  <name>BatchDeleteNonsellableRatePlanCharge</name>
  <purpose>To remove any deleted Product Rate Plan Charges as they eat up disk space
  </purpose>
  <created>
    <by>Steve O'Neal</by>
    <date>03/01/2016</date>
    <ticket>CSP-291</ticket>
  </created>
</Class>
*/
global class BatchDeleteNonsellableRatePlanCharge implements Database.Batchable<sObject> {
	public string query = '';
	
	global BatchDeleteNonsellableRatePlanCharge()
	{
		query = ' SELECT ID, zqu__Deleted__c'
			  + ' FROM zqu__ProductRatePlanCharge__c'
			  + ' WHERE zqu__Deleted__c = TRUE or zqu__ProductRatePlan__c = null';
			  
		System.Debug(query);
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<zqu__ProductRatePlanCharge__c> scope) {
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