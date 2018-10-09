global class PartnerAccountUpdatePastDueSchedule implements Schedulable {

	global Set<String> accountSet = new Set<String>();

	global PartnerAccountUpdatePastDueSchedule(Set<String> acctIdSet){
		accountSet = acctIdSet;
	}

	global void execute(SchedulableContext sc) {
		if(!XOGroupSettingUtility.getPartnerCalloutSetting()){
    		return;
    	}
		PartnerAccountUpdatePastDueBatch b = new PartnerAccountUpdatePastDueBatch(accountSet);
		database.executebatch(b, 100);
	}
}