public with sharing class ExpiredOpenOpportunitiesController {
	private Set<Id> rfpIdSet;

	public List<Opportunity> opportunityRFPList {get; set;}
	public Boolean myOppOnly {get; set;}
	public String viewSelected {get; set;}

	public ExpiredOpenOpportunitiesController() {
		myOppOnly = true;
		viewSelected = 'RFP';

		fillAction();
	}

	public List<SelectOption> getViewList(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('RFP','Expired Opportunities with RFPs'));
        options.add(new SelectOption('ThoughtStarter','Expired Opportunites with ThoughtStarter'));
        return options;
    }

    public void fillAction(){
    	if(viewSelected == 'ThoughtStarter'){
			fillTSOppList();
		}else{
			fillRFPOppList();
		}
    }

	public void fillRFPOppList(){
		opportunityRFPList = new List<Opportunity>();
		rfpIdSet = new Set<Id>();

		if(myOppOnly){
			for(Opportunity record : [select Id, Name, StageName, Amount, Owner.Name, CampaignStartDate__c, CampaignEndDate__c, (select Name, Campaign_Start_Date__c, Campaign_End_Date__c from ThoughtStarters_RFPs__r where RecordType.Name = 'RFP' order by LastModifiedDate desc) from Opportunity where IsClosed = false and CampaignStartDate__c <: date.today() and OwnerId =: UserInfo.getUserId() order by StageName, Name]){
				opportunityRFPList.add(record);
				for(ThoughtStarter_RFP__c childRecord : record.ThoughtStarters_RFPs__r){
					rfpIdSet.add(childRecord.Id);
				}
			}
		}else{
			for(Opportunity record : [select Id, Name, StageName, Amount, Owner.Name, CampaignStartDate__c, CampaignEndDate__c, (select Name, Campaign_Start_Date__c, Campaign_End_Date__c from ThoughtStarters_RFPs__r where RecordType.Name = 'RFP' order by LastModifiedDate desc) from Opportunity where IsClosed = false and CampaignStartDate__c <: date.today() order by StageName, Name]){
				opportunityRFPList.add(record);
				for(ThoughtStarter_RFP__c childRecord : record.ThoughtStarters_RFPs__r){
					rfpIdSet.add(childRecord.Id);
				}
			}
		}
	}

	public void saveCampaignDates(){
		Map<Id, ThoughtStarter_RFP__c> idRFPMap = new Map<Id, ThoughtStarter_RFP__c>();
		for(ThoughtStarter_RFP__c record : [select Id, Campaign_Start_Date__c, Campaign_End_Date__c from ThoughtStarter_RFP__c where Id IN: rfpIdSet]){
			idRFPMap.put(record.Id, record);
		}

		List<ThoughtStarter_RFP__c> updateRFPDateList = new List<ThoughtStarter_RFP__c>();
		for(Opportunity record : opportunityRFPList){
			for(ThoughtStarter_RFP__c childRecord : record.ThoughtStarters_RFPs__r){
				if(idRFPMap.containsKey(childRecord.Id) && (childRecord.Campaign_Start_Date__c != idRFPMap.get(childRecord.Id).Campaign_Start_Date__c || childRecord.Campaign_End_Date__c != idRFPMap.get(childRecord.Id).Campaign_End_Date__c)){
					updateRFPDateList.add(childRecord);
				}
			}
		}
		if(!updateRFPDateList.isEmpty()){
			try{
				update updateRFPDateList;
				if(viewSelected == 'ThoughtStarter'){
					fillTSOppList();
				}else{
					fillRFPOppList();
				}
			}catch(Exception e){

			}
		}
	}

	public void fillTSOppList(){
		opportunityRFPList = new List<Opportunity>();
		rfpIdSet = new Set<Id>();

		if(myOppOnly){
			for(Opportunity record : [select Id, Name, StageName, Amount, Owner.Name, CampaignStartDate__c, CampaignEndDate__c, (select Name, Internal_Due_Date__c, Desired_Due_Date__c, RecordType.Name from ThoughtStarters_RFPs__r where RecordType.Name = 'ThoughtStarter' order by LastModifiedDate desc) from Opportunity where IsClosed = false and Id IN (select Opportunity__c from ThoughtStarter_RFP__c where (Internal_Due_Date__c <=: date.Today() or Desired_Due_Date__c <=: date.Today()) and RecordType.Name = 'ThoughtStarter' and Opportunity__r.RecordType.Name = 'National' and Opportunity__r.IsClosed = false) and OwnerId =: UserInfo.getUserId() order by StageName, Name]){
				opportunityRFPList.add(record);
				for(ThoughtStarter_RFP__c childRecord : record.ThoughtStarters_RFPs__r){
					rfpIdSet.add(childRecord.Id);
				}
			}
		}else{
			for(Opportunity record : [select Id, Name, StageName, Amount, Owner.Name, CampaignStartDate__c, CampaignEndDate__c, (select Name, Internal_Due_Date__c, Desired_Due_Date__c, RecordType.Name from ThoughtStarters_RFPs__r where RecordType.Name = 'ThoughtStarter' order by LastModifiedDate desc) from Opportunity where IsClosed = false and Id IN (select Opportunity__c from ThoughtStarter_RFP__c where (Internal_Due_Date__c <=: date.Today() or Desired_Due_Date__c <=: date.Today()) and RecordType.Name = 'ThoughtStarter' and Opportunity__r.RecordType.Name = 'National' and Opportunity__r.IsClosed = false) order by StageName, Name]){
				opportunityRFPList.add(record);
				for(ThoughtStarter_RFP__c childRecord : record.ThoughtStarters_RFPs__r){
					rfpIdSet.add(childRecord.Id);
				}
			}
		}
	}
}