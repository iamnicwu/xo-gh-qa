global class BatchAssignmentHistoryUpdate implements Database.Batchable<sObject> {
	
	String query;
	
	global BatchAssignmentHistoryUpdate() {
		this.query = 'SELECT Id, Account__c, Lead__c, Lead__r.ConvertedAccountId FROM Assignment_History__c WHERE Lead_Is_Converted__c = true';
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<Assignment_History__c> scope) {
		for (Integer i = 0; i < scope.size(); i++) {
			Assignment_History__c assignmentHistoryRecord = scope[i];
			assignmentHistoryRecord.Account__c = assignmentHistoryRecord.Lead__r.ConvertedAccountId;
			assignmentHistoryRecord.Lead__c = null;
		}
		List<Database.SaveResult> updateResultsList = Database.update(scope);
		List<XO_Exception__c> xoExceptionList = ExceptionUtility.consumeException(updateResultsList);
		if (!xoExceptionList.isEmpty()) {
			insert xoExceptionList;
		}
	}
	
	global void finish(Database.BatchableContext BC) {
		// nothing for now
	}
	
}