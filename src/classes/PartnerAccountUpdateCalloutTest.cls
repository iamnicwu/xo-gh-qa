@isTest
private class PartnerAccountUpdateCalloutTest { 

    @isTest static void accountUpdateCalloutTestMethod() {

      List<RESTLocalStorefrontAPI.ObjectWrapper> accountUpdateList = new List<RESTLocalStorefrontAPI.ObjectWrapper>();
      createTestData(accountUpdateList);
      
      Test.startTest();
      PartnerAccountUpdateCallout.accountUpdateCallout(JSON.serializePretty(accountUpdateList));
      Test.stopTest();
    }
    
    @isTest static void accountUpdateCalloutNotFutureTestMethod() {  

      List<RESTLocalStorefrontAPI.ObjectWrapper> accountUpdateList = new List<RESTLocalStorefrontAPI.ObjectWrapper>();
      createTestData(accountUpdateList);
      
      Test.startTest();
      PartnerAccountUpdateCallout.accountUpdateCalloutNotFuture(JSON.serializePretty(accountUpdateList));
      Test.stopTest();
    } 

    private static void createTestData(List<RESTLocalStorefrontAPI.ObjectWrapper> accountUpdateList) {
      
      // insert custom settings XO_Group_Settings__c
      createXOGroupSettings(true);

      // Set mock callout class 
      Test.setMock(HttpCalloutMock.class, new PartnerAccountUpdateCalloutMock()); 
      Deactivate_Trigger__c dtatt = TestClassUtility.createNotesDeactivateTriggerSetting(true);
      Category__c category = TestClassUtility.createCategory(true);
      
      Market__c market = TestClassUtility.createMarket(false);
      market.Market_ID__c ='222';
      insert market;
      
      Account testAccount = TestClassUtility.createAccount(false,category,market);
      testAccount.DynamicsAccID__c = 'c8cafb16-e2a3-44cb-a609-15eba16d9d12';
      insert testAccount;

      Contact testContact = TestClassUtility.createContact(true, testAccount);
      AccountContactRole testAccountContactRole = TestClassUtility.createAccountContactRole(true, testAccount, testContact);
    
      //accountUpdateList = new List<RESTLocalStorefrontAPI.ObjectWrapper>();
      RESTLocalStorefrontAPI.ObjectWrapper objWrapper = new RESTLocalStorefrontAPI.ObjectWrapper();
      objWrapper.companyId = testAccount.DynamicsAccID__c;
      objWrapper.locationId = testAccount.DynamicsAccID__c;
      accountUpdateList.add(objWrapper);
    }  

    private static XO_Group_Settings__c createXOGroupSettings(Boolean insertRecord) {
      XO_Group_Settings__c xoGroupSettingsRecord = new XO_Group_Settings__c();
      xoGroupSettingsRecord.Always_Set_Credit_Hold_To_False__c = true;
      xoGroupSettingsRecord.Always_Set_Geocode_Override_To_True__c = true;
      xoGroupSettingsRecord.Turn_on_Fulfillment_Callouts__c = true;

      if (insertRecord) {
        insert xoGroupSettingsRecord;
      }
      return xoGroupSettingsRecord;
    }  
}