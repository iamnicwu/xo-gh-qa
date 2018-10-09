public with sharing class ThoughtStarterRFPEditController {

	public Map<Id, String> rtMapById {get; set;}
	public ThoughtStarter_RFP__c tsRFPRecord {get; set;}
	public Opportunity oppRecord {get; set;}
	public String requiredFields {get; set;}

	private static final List<NationalTSRFPAccFieldMap__c> mappedAccountFieldsList = NationalTSRFPAccFieldMap__c.getAll().values();
	private String queryString = 'select {fieldMap} Id from Account where Id =: parentAccountId';
	private String parentAccountId;
	private Account relatedAccount;

	public ThoughtStarterRFPEditController(ApexPages.StandardController stdController) {
		requiredFields = '';
		Map<String,Schema.RecordTypeInfo> rtMapInfo = Schema.SObjectType.ThoughtStarter_RFP__c.getRecordTypeInfosByName();
		rtMapById = new Map<Id, String>();
		for(Schema.RecordTypeInfo record : rtMapInfo.values()){
			rtMapById.put(record.getRecordTypeId(), record.getName());
		}

		tsRFPRecord = (ThoughtStarter_RFP__c) stdController.getRecord();
		tsRFPRecord.RecordTypeId = rtMapInfo.get(ApexPages.currentPage().getParameters().get('Type')).getRecordTypeId();
		tsRFPRecord.Opportunity__c = ApexPages.currentPage().getParameters().get('OpportunityId');
		oppRecord = [select Id, Name, Amount, AccountId, Account.AccountCategory__c, AccStrategist__c from Opportunity where Id =: tsRFPRecord.Opportunity__c];

		tsRFPRecord.Name = (rtMapById.get(tsRFPRecord.RecordTypeId).contains('ThoughtStarter')) ? 'TS' + '-' + oppRecord.Name : rtMapById.get(tsRFPRecord.RecordTypeId) + '-' + oppRecord.Name;
		tsRFPRecord.Account_Strategist__c = oppRecord.AccStrategist__c;

		if(rtMapById.get(tsRFPRecord.RecordTypeId).contains('ThoughtStarter')){
			tsRFPRecord.Sales_Dev_Needed__c = true;
			tsRFPRecord.Budget__c = oppRecord.Amount;

			List<Schema.FieldSetMember> tsFieldList = SObjectType.ThoughtStarter_RFP__c.FieldSets.Required_ThoughtStarter_Fields.getFields();
			for(Integer i = 0; i < tsFieldList.size(); i++) {
				Schema.FieldSetMember currentField = tsFieldList[i];
				requiredFields += currentField.getFieldPath() + ',';
			}
		}

		if(rtMapById.get(tsRFPRecord.RecordTypeId).contains('RFP')){
			tsRFPRecord.Maximum_Budget__c = oppRecord.Amount;

			List<Schema.FieldSetMember> rfpFieldList = SObjectType.ThoughtStarter_RFP__c.FieldSets.Required_RFP_Fields.getFields();
			for(Integer i = 0; i < rfpFieldList.size(); i++) {
				Schema.FieldSetMember currentField = rfpFieldList[i];
				requiredFields += currentField.getFieldPath() + ',';
			}
		}

		if(!mappedAccountFieldsList.isEmpty()){
            if(String.isBlank(parentAccountId)){
                parentAccountId = oppRecord.AccountId;
            }
            populateWithAccountInfo();
        }
	}

	private void populateWithAccountInfo(){
        List<String> fieldList = new List<String>();

        for(Integer i = 0; i < mappedAccountFieldsList.size(); i++) {
        	NationalTSRFPAccFieldMap__c currentMappedField = mappedAccountFieldsList[i];

        	fieldList.add(currentMappedField.Account_Field_API_Name__c);
        }

        queryString = queryString.replace('{fieldMap}', String.join(fieldList, ',') + ',');

        relatedAccount = Database.query(queryString);

        for(Integer i = 0; i < mappedAccountFieldsList.size(); i++) {
        	NationalTSRFPAccFieldMap__c currentMappedField = mappedAccountFieldsList[i];

        	tsRFPRecord.put(currentMappedField.TS_RFP_API_Name__c, relatedAccount.get(currentMappedField.Account_Field_API_Name__c));
        }
    }

}