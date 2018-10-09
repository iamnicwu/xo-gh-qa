/* 
<Class>
  <name>BatchDeleteNonsellableProducts</name>
  <purpose>To remove any deleted Products as they eat up disk space
  </purpose>
  <created>
    <by>Steve O'Neal</by>
    <date>03/01/2016</date>
    <ticket>CSP-291</ticket>
  </created>
</Class>
*/
global class BatchDeleteNonsellableProducts implements Database.Batchable<sObject> {
	public string query = '';
	
	global BatchDeleteNonsellableProducts() {
		query = ' SELECT ID, zqu__Deleted__c'
    			  + ' FROM Product2'
    			  + ' WHERE zqu__Deleted__c = TRUE';
    			  
		System.Debug(query);
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

 	global void execute(Database.BatchableContext BC, List<Product2> scope) {
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