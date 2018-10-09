global class PartnerAccountUpdateBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
		
	global PartnerAccountUpdateBatch() {
		
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		DateTime d = DateTime.now().addMinutes(-30);
		String query = 'select Id, DynamicsAccID__c from Account where ParentId = null and DynamicsAccID__c != null and RecordType.Name LIKE \'%Local%\' and Id IN (select AccountId from AccountContactRole where SystemModstamp >= ' + d.format('yyyy-MM-dd')+'T'+d.format('HH:mm')+':00.000Z and Role IN (\'Primary\', \'Billing\'))';
		system.debug(query);
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