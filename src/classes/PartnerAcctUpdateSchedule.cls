global class PartnerAcctUpdateSchedule implements Schedulable {
	global void execute(SchedulableContext sc) {
		if(!XOGroupSettingUtility.getPartnerCalloutSetting()){
    		return;
    	}
		PartnerAccountUpdateBatch b = new PartnerAccountUpdateBatch();
		database.executebatch(b, 100);
	}
}