@isTest     
private class AccountContactRoleSyncTest {
  @isTest static void checkPrimarySync() {
      DefaulCBSSValues__c defCBSScustomSetting = new DefaulCBSSValues__c();
      defCBSScustomSetting.Name = 'InvoiceTemplate';
      defCBSScustomSetting.Phone__c = '(800)843-4983';
      defCBSScustomSetting.Email__c = 'theknotaccounting@xogrp.com';
      insert defCBSScustomSetting;

      Deactivate_Trigger__c dtTrigger = TestClassUtility.createNotesDeactivateTriggerSetting(true);
      Generate_Quote_Pdf_Config__c gcr = TestClassUtility.generateQuotePdfConfig(true);
      
      Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();

      // CSP-1999
      // Map<String,Schema.RecordTypeInfo> rtBrandMapByName = Schema.SObjectType.Brand__c.getRecordTypeInfosByName();
      // Brand__c brand = TestClassUtility.createBrand(false);
      // brand.RecordTypeId = rtBrandMapByName.get('Local').getRecordTypeId();
      // insert brand;
      // Category__c category = TestClassUtility.createCategory(true,brand);
      Category__c category = TestClassUtility.createCategory(true);
      
      Market__c market = TestClassUtility.createMarket(false);
      market.Market_ID__c ='222';
      insert market;
      
      Zip__c zipCode = TestClassUtility.createZip(true);
      
      // CSP-1999
      // Account testAccount = TestClassUtility.createAccount(false,brand,category,market);
      Account testAccount = TestClassUtility.createAccount(false,category,market);
      testAccount.Type = 'Advertiser';
      testAccount.DynamicsAccID__c = 'testDynamicsLeadID';
      testAccount.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
      testAccount.BU__c = 'Local';
      insert testAccount; 

      Contact testContact = TestClassUtility.createContact(true, testAccount);
      
      AccountContactRole acr = TestClassUtility.createAccountContactRole(true,testAccount,testContact);  
      
      Opportunity opp = TestClassUtility.createOpportunity(true,testAccount);
      
      Test.startTest();
        AccountContactRoleSync roleSync = new AccountContactRoleSync(System.Today().addDays(-1),'Primary');
        Database.executeBatch(roleSync);        
      Test.stopTest();        

      Contact testCon = [SELECT id,name,Primary__c FROM Contact WHERE id =: testContact.id];
      System.assertEquals(testCon.Primary__c,true);
  }
}