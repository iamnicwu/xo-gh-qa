public without sharing class MassConvertLocalLeadsController {
	public String queryString {get;set;}
	public Boolean createOpportunity {get;set;}

	public MassConvertLocalLeadsController() {
		queryString = 'select Id from Lead where Storefront_Status__c = \'Claimed\' and Salesforce_Generated_GUID__c = false and IsConverted = false';
		createOpportunity = true;
	}

	public void executeBatchConvert(){
		String cleansedQueryString = String.escapeSingleQuotes(queryString);

		try{
			MassConvertLeadsBatch b = new MassConvertLeadsBatch(queryString, createOpportunity);
			database.executebatch(b, 10);
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Convert batch has been scheduled! Please go to Apex Jobs to view status!');
			ApexPages.addMessage(myMsg);
		}catch(Exception E){
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, E.getMessage());
    		ApexPages.addMessage(myMsg);
		}
	}
}