global class MassConvertLeadsBatch implements Database.Batchable<sObject> {
	
	String query;
	Boolean createOpportunity;
	
	global MassConvertLeadsBatch(String queryString, Boolean createOpp) {
		query = queryString;
		createOpportunity = createOpp;
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
		for(Lead myLead : (List<Lead>)scope){
			Database.LeadConvert lc = new database.LeadConvert();
			lc.setLeadId(myLead.Id);
			lc.convertedStatus = 'Qualified';
			lc.setDoNotCreateOpportunity(!createOpportunity);
			leadConverts.add(lc);
		}

		if(!leadConverts.isEmpty()){
			for(Integer i = 0; i <= leadConverts.size()/100 ; i++){
				List<Database.LeadConvert> tempList = new List<Database.LeadConvert>();
				Integer startIndex = i*100;
				Integer endIndex = ((startIndex+100) < leadConverts.size()) ? startIndex+100: leadConverts.size();
				for(Integer j=startIndex;j<endIndex;j++){
					tempList.add(leadConverts[j]);
				}
				Database.LeadConvertResult[] lcrList = Database.convertLead(tempList, false);
				for(Database.LeadConvertResult lcr : lcrList){
					System.debug(lcr.isSuccess());
					System.debug(lcr);
				}
			}
		}
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}