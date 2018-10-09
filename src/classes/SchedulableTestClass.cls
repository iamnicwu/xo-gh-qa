@isTest
private class SchedulableTestClass {
	
	@isTest static void schFulfillmentResponseDeletion() {
	  /*Partner_Fulfillment_Response__c testPartnerFulfillment = new Partner_Fulfillment_Response__c();
    testPartnerFulfillment.CreatedDate = DateTime.newInstance(Date.today().addMonths(-2), Time.newInstance(0, 0, 0, 0));
    insert testPartnerFulfillment;*/
    
    SchFulfillmentResponseDeletion fulSch = new SchFulfillmentResponseDeletion();
    fulSch.execute(null);
	}

  @isTest static void schEchoSignNotification() {
    List<RecordType> recordTypes = [select Id, Name, sObjectType from RecordType where name like '%local%' and IsActive = true];
    Map<String, RecordType> objectTypeToRecordTypeMap = new Map<String, RecordType>();
    for(Integer i = 0; i < recordTypes.size(); i++) {
      RecordType currentRT = recordTypes[i];
      objectTypeToRecordTypeMap.put(currentRT.sObjectType, currentRT);
    }

    User currentUser = [Select Id, FirstName, LastName, UserName, Email, Phone, ManagerID from User where id != :UserInfo.getUserId() AND isActive = true AND ManagerID != null limit 1];

    Generate_Quote_Pdf_Config__c newGQP = new Generate_Quote_Pdf_Config__c();
    newGQP.Name = 'Production';
    newGQP.URL__c = 'http://www.xogrpinc.com';
    insert newGQP;

    // AccountLocalTriggerHandler Line 17 dependancy. Wtf?
    Market__c testMarket = new Market__c();
    testMarket.Market_ID__c = '222';
    testMarket.Short_Description__c = 'Blah';
    insert testMarket;

    Account testAccount = new Account();
    testAccount.Name = 'Test Account';
    testAccount.Region__c = 'Test Region';
    testAccount.OwnerId = currentUser.Id;
    if(objectTypeToRecordTypeMap.containsKey('Account')) {
      RecordType accRT = objectTypeToRecordTypeMap.get('Account');
      testAccount.RecordTypeId = accRT.Id;
    }
    insert testAccount;

    Opportunity testOpp = new Opportunity();
    testOpp.Name = 'Test Opportunity';
    testOpp.AccountId = testAccount.Id;
    testOpp.CloseDate = Date.Today()-10;
    testOpp.StageName = 'Prospecting';
    testOpp.Opportunity_Expiration_Date__c = Date.today();
    testOpp.Approval_Process_AR_Assignment__c = False;
    testOpp.Approval_Process_Manager_Assignment__c = False;
    testOpp.Three_Business_Days_From_Today__c = DateUtility.addBusinessDays(Date.today(), -1);
    testOpp.Lock_Quotes__c = False;
    if(objectTypeToRecordTypeMap.containsKey('Opportunity')) {
      RecordType oppRT = objectTypeToRecordTypeMap.get('Opportunity');
      testOpp.RecordTypeId = oppRT.Id;
    }
    insert testOpp;

    Contact testContact = new Contact();
    testContact.Same_Address_as_Account__c = true;
    testContact.LastName = 'test';
    testContact.Email = 'abc@invalid1gmail.com';
    testContact.AccountId = testAccount.Id;
    insert testContact;

    testOpp.StageName = 'Pending Client Approval';
    testOpp.Contract_Signer__c = testContact.Id;
    update testOpp;
    // Expired notification email
    Test.startTest();
      SchEchoSignNotification echoSch = new SchEchoSignNotification();
      echoSch.execute(null);
    Test.stopTest();

    // Two Day notification email
    testOpp.Three_Business_Days_From_Today__c = DateUtility.addBusinessDays(Date.today(), 2);
    update testOpp;
    SchEchoSignNotification echoSch2 = new SchEchoSignNotification();
    echoSch2.execute(null);
  }
}