public with sharing class NewThoughtStarterRFPController {

    private String parentAccountId;
    private String parentOpportunityId;

    @TestVisible private ThoughtStarter_RFP__c newThoughtStarterRFP = new ThoughtStarter_RFP__c();
    private Account relatedAccount;

    private String queryString = 'select {fieldMap} Id from Account where Id =: parentAccountId';

    private static final Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.ThoughtStarter_RFP__c.getRecordTypeInfosByName();
    private static final List<NationalTSRFPAccFieldMap__c> mappedAccountFieldsList = NationalTSRFPAccFieldMap__c.getAll().values();

    public String recordTypeSelected {get; set;}
    public Boolean showInfo {get; set;}

    public NewThoughtStarterRFPController() {
        recordTypeSelected = ApexPages.currentPage().getParameters().get('RecordType');
        parentAccountId = ApexPages.currentPage().getParameters().get('AccountId');
        parentOpportunityId = ApexPages.currentPage().getParameters().get('OpportunityId');

        showInfo = true;

        newThoughtStarterRFP.RecordTypeId = rtMapByName.get(recordTypeSelected).getRecordTypeId();
        newThoughtStarterRFP.Opportunity__c = parentOpportunityId;
        
        if(!mappedAccountFieldsList.isEmpty()){
            if(String.isBlank(parentAccountId)){
                parentAccountId = [select Id, AccountId from Opportunity where Id = : parentOpportunityId].AccountId;
            }
            populateWithAccountInfo();
        }
    }

    private void populateWithAccountInfo(){
        List<String> fieldList = new List<String>();

        for(NationalTSRFPAccFieldMap__c record : mappedAccountFieldsList){
            fieldList.add(record.Account_Field_API_Name__c);
        }

        queryString = queryString.replace('{fieldMap}', String.join(fieldList, ',') + ',');

        relatedAccount = Database.query(queryString);

        for(NationalTSRFPAccFieldMap__c record : mappedAccountFieldsList){
            newThoughtStarterRFP.put(record.TS_RFP_API_Name__c,relatedAccount.get(record.Account_Field_API_Name__c));
        }
    }

    public pageReference createThoughtStarterRFP(){

        try{
            insert newThoughtStarterRFP;
        }catch(Exception E){
            showInfo = false;
            return null;
        }

        PageReference editPage = new ApexPages.StandardController(newThoughtStarterRFP).edit();
        editPage.getParameters().put('retURL', '/' + newThoughtStarterRFP.Id);
        editPage.setRedirect(true);

        return editPage;
    }

}