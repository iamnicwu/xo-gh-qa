global class DeleteFulfillmentResponseBatch implements Database.Batchable<sObject> {
		
	global DeleteFulfillmentResponseBatch() {
		
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		DateTime d = DateTime.now().addDays(-30);
		String query = 'select Id from Partner_Fulfillment_Response__c where CreatedDate <: d';
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		delete scope;
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}