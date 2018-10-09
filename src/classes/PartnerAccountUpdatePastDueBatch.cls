global class PartnerAccountUpdatePastDueBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
	
	Set<String> acctIdSet = new Set<String>();

	global PartnerAccountUpdatePastDueBatch(Set<String> accountSet) {
		acctIdSet = accountSet;
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'select Id, DynamicsAccID__c from Account where Id IN : acctIdSet';
		if(!XOGroupSettingUtility.getPartnerCalloutSetting()){
    		query = 'select Id from Account where RecordType.Name = \'ReturnNothing\'';
    	}
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		system.debug(scope);
		List<RESTLocalStorefrontAPI.ObjectWrapper> accountUpdateList = new List<RESTLocalStorefrontAPI.ObjectWrapper>();

		for(sObject record : scope){
			Account acct = (Account)record;
			RESTLocalStorefrontAPI.ObjectWrapper objWrapper = new RESTLocalStorefrontAPI.ObjectWrapper();
			objWrapper.companyId = acct.DynamicsAccID__c;
			objWrapper.locationId = acct.DynamicsAccID__c;
			accountUpdateList.add(objWrapper);
		}

		if(!accountUpdateList.isEmpty()){
            PartnerAccountUpdateCallout.accountUpdateCalloutNotFuture(JSON.serializePretty(accountUpdateList));
        }
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}