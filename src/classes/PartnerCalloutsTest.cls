@isTest
private class PartnerCalloutsTest {
    @isTest static void test_method_One() {
        // Implement test code
        
        
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtLeadMapByName = Schema.SObjectType.Lead.getRecordTypeInfosByName();
        
        XO_Group_Settings__c xoSetting = XO_Group_Settings__c.getInstance();
        xoSetting.Turn_on_Fulfillment_Callouts__c = true;
        upsert xoSetting;
        
        Market__c testMarket = new Market__c();
        testMarket.Name = 'Test Market';
        testMarket.Short_Description__c = 'Test Market';
        testMarket.Market_ID__c = '222';
        testMarket.Active__c = true;
        insert testMarket;
        
        MetroArea__c ma = new MetroArea__c();
        ma.name = 'test';
        insert ma;
        
        Zip__c zip = new Zip__c();
        zip.MetroArea__c = ma.id;
        zip.ZipCode__c = '12121';
        Zip.name = '12121';
        insert zip;
        
        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        testAccount.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
        testAccount.BU__c = 'Local';
        testAccount.Website = 'www.google.com';
        testAccount.Phone = '12345678';
        testAccount.Type = 'Agency';
        testAccount.BillingCountry = 'United States';
        testAccount.BillingState = 'Alaska';
        testAccount.BillingCity = 'US2';
        testAccount.BillingStreet = 'US3';
        testAccount.BillingPostalCode = '12121';
        testAccount.Operative_Owner__c = userList[0].Name;
        testAccount.Website = 'www.google.com';
        testAccount.ConciergePrgQua__c = 'In Program';
        testAccount.Type = 'Advertiser';
        testAccount.DynamicsAccID__c = 'TestRestAPIDynamicsPartnerAcctUpdateScheduleTest';
        insert testAccount;
        
        Contact testContact = new Contact();
        testContact.Same_Address_as_Account__c = true;
        testContact.LastName = 'test';
        testContact.Email = 'abc@gmail.com';
        testContact.AccountId = testAccount.Id;
        testContact.MailingCountry = 'United States';
        insert testContact;
        
        AccountContactRole acr = new AccountContactRole();
        acr.AccountId = testAccount.id;
        acr.ContactId = testContact.id;
        acr.Role = 'Primary';
        insert acr;
        
        
        Account testAccount1 = new Account();
        testAccount1.Name = 'Test Agency Account Wait What';
        testAccount1.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
        testAccount1.BU__c = 'Local';
        testAccount1.Website = 'www.notgoogle.com';
        testAccount1.Phone = '8397111211';
        testAccount1.BillingCountry = 'United States';
        testAccount1.BillingState = 'Alaska';
        testAccount1.BillingCity = 'US2';
        testAccount1.BillingStreet = 'US3';
        testAccount1.BillingPostalCode = '12121';
        testAccount1.Operative_Owner__c = userList[0].Name;
        testAccount1.ConciergePrgQua__c = 'In Program';
        testAccount1.Type = 'Advertiser';
        testAccount1.DynamicsAccID__c = 'TestRestAPIDynamicsPartnerAcctUpdateScheduleTest1';
        insert testAccount1;
        
        Contact testContact1 = new Contact();
        testContact1.Same_Address_as_Account__c = true;
        testContact1.LastName = 't1estte1st';
        testContact1.Email = 'abc@gmail1.com';
        testContact1.AccountId = testAccount1.Id;
        testContact1.MailingCountry = 'United States';
        insert testContact1;
        
        AccountContactRole acr1 = new AccountContactRole();
        acr1.AccountId = testAccount1.id;
        acr1.ContactId = testContact1.id;
        acr1.Role = 'Primary';
        insert acr1;
        
        
        Deactivate_Trigger__c dt = new Deactivate_Trigger__c();
        dt.name = 'Note';
        dt.After_Delete__c = false;
        dt.After_Insert__c = false;
        dt.After_Update__c = false;
        dt.Before_Delete__c = false;
        dt.Before_Insert__c = false;
        dt.Before_Update__c = false;
        insert dt;
        
        
        Local_Sales_Rep_Assignment__c  lsra = new Local_Sales_Rep_Assignment__c();
        lsra.Name = 'test name';
        //lsra.Category__c = testCategory.id;
        //lsra.Market__c = testMarket.id;
        lsra.Sales_Rep__c = UserInfo.getUserId();
        lsra.Zip_Code__c = zip.id;
        //insert lsra;
        
        Lead testLead = new Lead();
        testLead.FirstName='9823urasdfndsaiofhasdf';
        testLead.LastName='awe5cgh7ijyrtersrceastgefearfsxd';
        testLead.Company='nd;5#$@#Q$WAERxddcfs5gaebai';
        //testLead.Local_Sales_Market__c = testMarket.id;
        //testLead.Primary_Category__c = testCategory.id;
        //testLead.Primary_Brand__c = testBrand.id;
        testLead.recordtypeId = rtLeadMapByName.get('Local').getRecordTypeId();
        testLead.PostalCode = '88541';
        testLead.DynamicsLeadID__c = testAccount.DynamicsAccID__c;
        testLead.Street = 'US3';
        testLead.Phone = '8547458124';
        insert testLead;
        
        Test.startTest();
        List<RESTLocalStorefrontAPI.ObjectWrapper> accountUpdateList = new List<RESTLocalStorefrontAPI.ObjectWrapper>();
        RESTLocalStorefrontAPI.ObjectWrapper objWrapper = new RESTLocalStorefrontAPI.ObjectWrapper();
        objWrapper.companyId = testAccount.DynamicsAccID__c;
        objWrapper.locationId = testAccount.DynamicsAccID__c;
        accountUpdateList.add(objWrapper);
        
        PartnerCallouts pc = new PartnerCallouts();
        PartnerCallouts.partnerOrderCallout(JSON.serializePretty(accountUpdateList));
        
        accountUpdateList[0].companyId  = '';
        PartnerCallouts.partnerOrderCallout(JSON.serializePretty(accountUpdateList));
        
        accountUpdateList[0].companyId  =  testAccount1.DynamicsAccID__c;
        accountUpdateList[0].locationId=  testAccount.DynamicsAccID__c;
        PartnerCallouts.partnerOrderCallout(JSON.serializePretty(accountUpdateList));
        
        PartnerCallouts.nonFuturePartnerOrderCallout(JSON.serializePretty(accountUpdateList));
        
        PartnerCallouts.FulfillmentLocationWrapper FulfillmentLocationWrapper = new PartnerCallouts.FulfillmentLocationWrapper();
        String locationId = FulfillmentLocationWrapper.locationId;
        List<PartnerCallouts.FulfilledStorefrontWrapper> FulfilledStorefrontWrappers = FulfillmentLocationWrapper.fulfilledStorefronts;
        List< PartnerCallouts.FulfillmentErrorWrapper> FulfillmentErrorWrappers = FulfillmentLocationWrapper.errors;
        
        
        PartnerCallouts.FulfilledStorefrontWrapper FulfilledStorefrontWrapper = new PartnerCallouts.FulfilledStorefrontWrapper();

        String storefrontId = FulfilledStorefrontWrapper.storefrontId;
        String storefrontDisplayId = FulfilledStorefrontWrapper.storefrontDisplayId ;
        String storefrontName = FulfilledStorefrontWrapper.storefrontName ;
        String storefrontTier = FulfilledStorefrontWrapper.storefrontTier ;
        String storefrontStatus = FulfilledStorefrontWrapper.storefrontStatus ;
        String marketCode = FulfilledStorefrontWrapper.marketCode ;
        String categoryId = FulfilledStorefrontWrapper.categoryId ;
        String subscriptionId = FulfilledStorefrontWrapper.subscriptionId ;
        String lineItemId = FulfilledStorefrontWrapper.lineItemId ;
        List<PartnerCallouts.FulfilledAddOnsWrapper> fulfilledAddOns = FulfilledStorefrontWrapper.fulfilledAddOns;

        PartnerCallouts.FulfillmentErrorWrapper FulfillmentErrorWrapper = new PartnerCallouts.FulfillmentErrorWrapper();
        String message = FulfillmentErrorWrapper.message;
        Test.stopTest();
    }
    
}