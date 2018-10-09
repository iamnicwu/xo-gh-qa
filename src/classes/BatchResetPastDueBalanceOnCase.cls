/* 
<Class>
  <name>BatchResetPastDueBalanceOnCase</name>
  <purpose> reset the past due balance on case every month
  </purpose>
  <created>
    <by>Tony Liu</by>
    <date>02/01/2018</date>
    <ticket>CSP-2645</ticket>
  </created>
</Class>
*/

global class BatchResetPastDueBalanceOnCase implements Database.Batchable<sObject> {
	public String query;

	global BatchResetPastDueBalanceOnCase() {
		this.query = 'SELECT ID, Past_Due_Potential__c, Account.Past_Due_Balance__c FROM CASE WHERE IsCLosed = FALSE AND RecordType.Name = \'Client Billing\'';
	}

	global Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, list<Case> scope) {
		List<Case> updateCaseList = new List<Case>();
		for (Case currentCase : scope) {
			if (currentCase.Past_Due_Potential__c != currentCase.Account.Past_Due_Balance__c) {
			    currentCase.Past_Due_Potential__c = currentCase.Account.Past_Due_Balance__c;
			    updateCaseList.add(currentCase);
			}
		}


		if (!updateCaseList.isEmpty()) {
			List<Database.SaveResult> updateResultsList = Database.update(updateCaseList, false);
	    List<XO_Exception__c> xoExceptionList = ExceptionUtility.consumeException(updateResultsList);
			if (!xoExceptionList.isEmpty()) {
				insert xoExceptionList;
			}
		}
	}

	global void finish(Database.BatchableContext BC) {

	}
}