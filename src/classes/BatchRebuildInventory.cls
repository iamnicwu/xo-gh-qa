/* 
<Class>
  <name>BatchRebuildInventory</name>
  <purpose>Removes any subscription based inventory.  Based on configuration settings, conditionally calls batch to rebuild inventory from Subscription Rate Plan data
  </purpose>
  <created>
    <by>Steve O'Neal</by>
    <date>03/07/2016</date>
    <ticket>CSP-576</ticket>
  </created>
</Class>
*/
global class BatchRebuildInventory implements Database.Batchable<sObject> {
	public string query = '';
	private string BatchDelAvailInvName = 'BatchDeleteAvailableInventory';
	Map<String, ChainBatchJob__c> chainBatchJob = ChainBatchJob__c.getAll();
	
	global BatchRebuildInventory() {
		query = ' SELECT ID FROM Inventory__c WHERE Held_By_Type__c = \'Subscription\' or Available__c = true';
		System.Debug('Query (this query is static, FYI): ' + query);
		
		ChainBatchJob__c bdaiChainBatchJob = new ChainBatchJob__c();
		if (chainBatchJob.containsKey(BatchDelAvailInvName)) {
			bdaiChainBatchJob = chainBatchJob.get(BatchDelAvailInvName);
		} else {
			bdaiChainBatchJob.Name = BatchDelAvailInvName;
		}
		
		bdaiChainBatchJob.Chain_Next_Batch_Job__c = false;
		upsert bdaiChainBatchJob;
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		Database.QueryLocator retVal = Database.getQueryLocator(query);
		return retVal;
	}

 	global void execute(Database.BatchableContext BC, List<Inventory__c> scope) {
 		Database.DeleteResult[] dbDeleteResult = Database.delete(scope, false);
    List<XO_Exception__c> xoExceptionList = ExceptionUtility.consumeException(dbDeleteResult);
    if(xoExceptionList.size() > 0){
    	insert xoExceptionList;
    }	    
 	}
   	
  global void finish(Database.BatchableContext BC) {
		Boolean runNextBatchJob = true;
		if (chainBatchJob.containsKey('BatchRebuildInventory')) {
			runNextBatchJob = chainBatchJob.get('BatchRebuildInventory').Chain_Next_Batch_Job__c;
		}
		
		if (runNextBatchJob) {
	    BatchRebuildInventoryFromSubscriptions batch1 = new BatchRebuildInventoryFromSubscriptions();
	    Database.ExecuteBatch(batch1,200);
		}
  }
}