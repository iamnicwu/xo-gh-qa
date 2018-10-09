/* 
<Class>
  <name>BatchDeleteAvailableInventory</name>
  <purpose>To remove any unecessary inventory, freeing up product rate plans to be deleted
  </purpose>
  <created>
	<by>Steve O'Neal</by>
	<date>03/02/2016</date>
	<ticket>CSP-576</ticket>
  </created>
</Class>
*/
global class BatchDeleteAvailableInventory implements Database.Batchable<sObject> {
	public string query = '';
	
	global BatchDeleteAvailableInventory() {
		System.Debug('Entering constructor for BatchDeleteAvailableInventory');
		query = ' SELECT ID, available__c'
			  + ' FROM Inventory__c'
			  + ' WHERE available__c = TRUE';
			  
		System.Debug('Query: ' + query);
		System.Debug('Exiting constructor for BatchDeleteAvailableInventory');
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		System.Debug('Entering BatchDeleteAvailableInventory.start');
		Database.QueryLocator retVal = Database.getQueryLocator(query);
		System.Debug('Exiting BatchDeleteAvailableInventory.start');
		return retVal;
	}

	global void execute(Database.BatchableContext BC, List<Inventory__c> scope) {
		Database.DeleteResult[] dbDeleteResult = Database.delete(scope, false);
		List<XO_Exception__c> xoExceptionList = ExceptionUtility.consumeException(dbDeleteResult);
		if (xoExceptionList.size() > 0) {
			insert xoExceptionList;
		}
	}
	
	global void finish(Database.BatchableContext BC) {
		System.Debug('Entering BatchDeleteAvailableInventory.finish');
		Boolean runNextBatchJob = true;
		Map<String, ChainBatchJob__c> chainBatchJob = ChainBatchJob__c.getAll();
		if (chainBatchJob.containsKey('BatchDeleteAvailableInventory')) {
			runNextBatchJob = chainBatchJob.get('BatchDeleteAvailableInventory').Chain_Next_Batch_Job__c;
		}
		
		System.Debug('Run next batch job:' + runNextBatchJob);
		if (runNextBatchJob && !Test.isRunningTest()) {
			System.Debug('Running BatchConvertWaitlistToInventory next');
			BatchConvertWaitlistToInventory batch1 = new BatchConvertWaitlistToInventory();
			Database.ExecuteBatch(batch1,200);
			
		}
		
		System.Debug('Exiting BatchDeleteAvailableInventory.finish');
	}
}