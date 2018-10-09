@isTest
private class testPartnersSalesProfileTrigger{
    @isTest static void test_method_one() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        
        Test.startTest();
        Map<String, SObject> testData =TestClassUtility.buildLocalData(false);
        Test.stopTest();
        Deactivate_Trigger__c dtNote =  TestClassUtility.createNotesDeactivateTriggerSetting(true);

        Account testAccount = (Account)testData.get('Account');
        Zip__c testZip = (Zip__c)testData.get('Zip__c');
        Market__c testMarket = (Market__c)testData.get('Market__c');
        Category__c testCategory = (Category__c)testData.get('Category__c');
        // CSP-1999 Brand__c testBrand = (Brand__c)testData.get('Brand__c');

        dtNote.After_Delete__c = false;
        dtNote.After_Insert__c = false;
        dtNote.After_Update__c = false;
        dtNote.Before_Delete__c = false;
        dtNote.Before_Insert__c = false;
        dtNote.Before_Update__c = false;
        Update dtNote; 
        
        // Implement test code
        
            Account testAccount1 = new Account();
            testAccount1.Name = 'wakeinthemorningandistepoutside';
            testAccount1.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
            testAccount1.BU__c = 'Local';
            testAccount1.Website = 'www.asdfdgoosadfadsfgladfadfe.com';
            testAccount1.Type = 'Agency';
            testAccount1.BillingCountry = 'United States';
            testAccount1.BillingState = 'Alaska';
            testAccount1.BillingCity = 'US2';
            testAccount1.BillingStreet = 'US3';
            testAccount1.BillingPostalCode = testZip.zipcode__c;
            testAccount1.Operative_Owner__c = userList[0].Name;
            testAccount1.parentId = testAccount.id;
            // CSP-1999 testAccount1.Primary_Brand__c = testBrand.id;
            testAccount1.Primary_Category__c = testCategory.id;
            testAccount1.Local_Sales_Market__c = testMarket.id;
            insert testAccount1;
            
            Partners_SalesProfile__c testpsp = new Partners_SalesProfile__c();
            testpsp.Name = 'test name';
            testpsp.Tier__c = 'Freemium';
            testpsp.Location__c = testAccount1.id;
            testpsp.Partners_SalesProfile_GUID__c ='testPartners_SalesProfile_GUID1';
            insert testpsp;
            
            
            PartnersSalesProfileTriggerHandler testPSPTH = new PartnersSalesProfileTriggerHandler();
            testPSPTH.bulkBefore();
            testPSPTH.beforeInsert(testpsp);
            testPSPTH.beforeUpdate(testpsp,testpsp);
            testPSPTH.beforeDelete(testpsp);
            testPSPTH.afterDelete(testpsp);
        
    }
    
    @isTest static void test_method_Two() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        
        Test.startTest();
        Map<String, SObject> testData =TestClassUtility.buildLocalData(false);
        Test.stopTest();
        Deactivate_Trigger__c dtNote =  TestClassUtility.createNotesDeactivateTriggerSetting(true);
        Account testAccount = (Account)testData.get('Account');
        Zip__c testZip = (Zip__c)testData.get('Zip__c');
        Market__c testMarket = (Market__c)testData.get('Market__c');
        Category__c testCategory = (Category__c)testData.get('Category__c');
        // CSP-1999 Brand__c testBrand = (Brand__c)testData.get('Brand__c');

        dtNote.After_Delete__c = false;
        dtNote.After_Insert__c = false;
        dtNote.After_Update__c = false;
        dtNote.Before_Delete__c = false;
        dtNote.Before_Insert__c = false;
        dtNote.Before_Update__c = false;
        Update dtNote; 
        
        // Implement test code
        
            Account testAccount1 = new Account();
            testAccount1.Name = 'anditakeadeepbreathWHATSGOINGON';
            testAccount1.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
            testAccount1.BU__c = 'Local';
            testAccount1.Website = 'www.sadfadsfadsfdsafgadsfdasfoogle.com';
            testAccount1.Type = 'Agency';
            testAccount1.BillingCountry = 'United States';
            testAccount1.BillingState = 'Alaska';
            testAccount1.BillingCity = 'US2';
            testAccount1.BillingStreet = 'US3';
            testAccount1.BillingPostalCode = testZip.zipcode__c;
            testAccount1.Operative_Owner__c = userList[0].Name;
            testAccount1.parentId = testAccount.id;
            testAccount1.ProductType__c = 'Internet';
            // CSP-1999 testAccount1.Primary_Brand__c = testBrand.id;
            testAccount1.Primary_Category__c = testCategory.id;
            testAccount1.Local_Sales_Market__c = testMarket.id;
            insert testAccount1;
            
            Partners_SalesProfile__c testpsp = new Partners_SalesProfile__c();
            testpsp.Name = 'test name';
            testpsp.Tier__c = 'Freemium';
            testpsp.Location__c = testAccount1.id;
            testpsp.Partners_SalesProfile_GUID__c ='testPartners_SalesProfile_GUID1';
            insert testpsp;
            
            
            
            testpsp.Tier__c = 'Standard';
            update testpsp;
            
            
            Partners_SalesProfile__c testpsp1 = new Partners_SalesProfile__c();
            testpsp1.Name = 'test name1';
            testpsp1.Tier__c = 'Freemium';
            testpsp1.Location__c = testAccount1.id;
            testpsp1.Partners_SalesProfile_GUID__c ='testPartners_SalesProfile_GUID';
            insert testpsp1;
            
            testAccount1.ProductType__c = 'Internet';
            update testAccount1;
            testpsp.Tier__c = 'Standard1';
            update testpsp;
            
            testAccount1.ProductType__c = '';
            update testAccount1;
            testpsp.Tier__c = 'Standard';
            update testpsp;
        
         
    }
    
    
}