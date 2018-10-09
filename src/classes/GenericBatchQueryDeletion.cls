global class GenericBatchQueryDeletion implements Database.Batchable<sObject> {
	
	String query;
	
	global GenericBatchQueryDeletion(String deletionQuery) {
		query = deletionQuery;
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		Database.DeleteResult[] dbDeleteResult = Database.delete(scope, false);
		List<XO_Exception__c> xoExceptionList = ExceptionUtility.consumeException(dbDeleteResult);
		if (xoExceptionList.size() > 0) {
			insert xoExceptionList;
		}		
	}
	
	global void finish(Database.BatchableContext BC) {
		// nothing for now
	}
	
}