public with sharing class TradeshowCreationController {
    
    public Contact newContact {get;set;}
    public Account acc {get;set;}
    public String accId {get;set;}
    public Opportunity newOpp {get;set;}
    private static final Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();

    public TradeshowCreationController() {
      
      accId = System.currentPageReference().getParameters().get('id');

      initialize(accId);
    }

    // initalize the contact data
    private void initialize(String accId){

      newContact = new Contact();
      newOpp = new Opportunity();
      acc = new Account();

      if(String.isNotBlank(accId)){

        List<Account> acclist = [SELECT Id, Name, OwnerId, Phone, Email__c, BillingCountry, BillingState, BillingCity, BillingStreet, BillingPostalCode, AccountSource, 
                                 (SELECT Id, Role FROM AccountContactRoles WHERE Role = 'Primary')
                                 FROM Account WHERE id =: accId limit 1];

        if(!acclist.isEmpty()){
          acc = acclist[0];
          newContact.AccountId = acc.Id;
          newContact.Email = acc.Email__c;
          newContact.Phone = acc.Phone;
          newContact.LeadSource = 'Field Event';
          newContact.MailingCountry = acc.BillingCountry;
          newContact.MailingState = acc.BillingState;
          newContact.MailingCity = acc.BillingCity;
          newContact.MailingStreet = acc.BillingStreet;
          newContact.MailingPostalCode = acc.BillingPostalCode;
        }
      }

      List<Campaign> camplist = [SELECT Id FROM Campaign WHERE Name =:Label.TradeShow_Campaign_Name limit 1];

      if(!camplist.isEmpty()){
        newOpp.CampaignId = camplist[0].Id;
      }

      newOpp.OwnerId = acc.OwnerId;
      newOpp.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
    }

    // retrieve the trade show contact fields
    public List<Schema.FieldSetMember> getContactFields(){

      List<Schema.FieldSetMember> fieldmembers = sObjectType.Contact.FieldSets.TradeShow_Fields.getFields();
      return fieldmembers;
    }

    public List<Schema.FieldSetMember> getOppFields(){

      List<Schema.FieldSetMember> fieldmembers = sObjectType.Opportunity.FieldSets.Tradeshow_fields.getFields();
      return fieldmembers;
    }

    // for saving the contact
    public PageReference save(){

      try {
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        Database.SaveResult saveResult = Database.insert(newContact, dml);
        System.debug(LoggingLevel.INFO, '*** saveResult: ' + saveResult);

        if(saveResult.isSuccess()){
          String contactId = saveResult.getId();
          createCampaignMember(contactId);
          updateContactRole(acc, contactId);
          createOpp(acc, contactId);
        }
        else{
          String err = '';
          for(Database.Error de : saveResult.errors){
            err+= de.getMessage()+'\r\n';
          }
          ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING,err));
          return null;
        }

      }
      catch (Exception ex) {

        XO_Exception__c xoException = ExceptionUtility.consumeException(ex, true);
        ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING,
                        'Auto create Opportunity failed! Please contact Administrator!'));
        return null;
      }

      PageReference pr = new PageReference('/' + accId);
      pr.setRedirect(false);
      return pr;
    }

    // for cancel the action
    public PageReference cancel(){
      newContact = new Contact();
      PageReference pr = new PageReference('/' + accId);
      pr.setRedirect(true);
      return pr;
    }

    public void createOpp(Account acc, String conId){
      newOpp.AccountId = acc.id;
      newOpp.Contract_Signer__c = conId;
      newOpp.Name = 'Local - ' + acc.Name + ' - '+ Date.today().month() +'/'+ Date.today().year();
      newOpp.Type = 'New';
      newOpp.CloseDate = Date.today();
      newOpp.StageName= 'Prospecting';
      newOpp.LeadSource= 'Field Event';
      newOpp.Lead_Sub_Source__c = 'Tradeshow';

      try {
          insert newOpp;
      }
      catch (Exception ex) {
        XO_Exception__c xoException = ExceptionUtility.consumeException(ex, true);
      }

    }


    public void createCampaignMember(String conId){

      CampaignMember cm = new CampaignMember();
      cm.CampaignId = newOpp.CampaignId;
      cm.ContactId = conId;

      System.debug(LoggingLevel.INFO, '*** newContact: ' + conId);
      cm.Status= 'Sent';

      try {
        insert cm;
      }
      catch (Exception ex){
        XO_Exception__c xoException = ExceptionUtility.consumeException(ex, true);
      }
    }


    public void updateContactRole(Account acc, String conId){

      list<AccountContactRole> acrList = new List<AccountContactRole>();

      for(AccountContactRole acr : acc.AccountContactRoles){

        if(acr.Role == 'Primary'){
          acr.IsPrimary = false;
          // acr.Role = 'Billing';
          acrList.add(acr);
        }
        else{
          if(acr.IsPrimary){
            acr.IsPrimary = false;
            acrList.add(acr);
          }
        }
      }

      AccountContactRole cr = new AccountContactRole();
      cr.AccountId = accId;
      cr.ContactId = conId;
      cr.Role = 'Primary';
      cr.IsPrimary = true;
      acrList.add(cr);

      try {
        upsert acrList;
      }
      catch (Exception ex){
        XO_Exception__c xoException = ExceptionUtility.consumeException(ex, true);
      }
    }

}