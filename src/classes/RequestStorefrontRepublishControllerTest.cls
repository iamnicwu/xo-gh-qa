@isTest 
private class RequestStorefrontRepublishControllerTest {
    
    @isTest static void test_method_one() {
        // testDataFactoryT tdf = new testDataFactoryT();
        // tdf.CreateLocalTestObjects();
        test.startTest();
        Map<String,SObject> testLocalData = TestClassUtility.buildLocalData(false);
        test.stopTest();

        Account testAccount = (Account)testLocalData.get('Account');
        testAccount.Fulfill_Storefront__c = false;
        update testAccount;
        
        // Zuora__Subscription__c testZquSubscription = new Zuora__Subscription__c();
        // testZquSubscription.Name = 'Test Subscription';
        // testZquSubscription.Zuora__SubscriptionStartDate__c = Date.Today();
        // testZquSubscription.Zuora__SubscriptionEndDate__c = Date.Today() + 365;
        // testZquSubscription.Zuora__Status__c = 'Active';
        // testZquSubscription.Zuora__Account__c = tdf.testAccount.Id;
        // testZquSubscription.Zuora__Zuora_Id__c = 'abc123';
        // insert testZquSubscription;
        Zuora__Subscription__c testZSub = TestClassUtility.createSubscription(false,testAccount);
        testZSub.Zuora__Zuora_Id__c = 'abc123';
        insert testZSub;
        
        //Test.startTest();
        PageReference pageRef = Page.RequestStorefrontRepublish;
        Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('acctId', testAccount.Id);

        RequestStorefrontRepublishController rsfrc = new RequestStorefrontRepublishController();
        rsfrc.updateAccount();
        rsfrc.fulfillStorefront();
        
        //Test.stopTest();
    }
   
    @isTest static void test_method_Four() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account", "errors" : [{"message": "errors message"}]}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        XO_Group_Settings__c xoSetting = new XO_Group_Settings__c();
        xoSetting.Turn_on_Fulfillment_Callouts__c = true;
        insert xoSetting;


        Test.startTest();
        Map<String ,SObject> testLocalData = TestClassUtility.buildLocalData(false);
        Test.stopTest();
        
        Account testAccount = (Account)testLocalData.get('Account');
        testAccount.Fulfill_Storefront__c = false;
        update testAccount;

        PageReference pageRef = Page.RequestStorefrontRepublish;
        Test.setCurrentPage(pageRef);

        //ApexPages.currentPage().getParameters().put('acctId', tdf.testAccount.Id);
        ApexPages.currentPage().getParameters().put('acctId', testAccount.Id);

        RequestStorefrontRepublishController rsfrc = new RequestStorefrontRepublishController();
        rsfrc.initiateProcess();
        rsfrc.cancelProcess();
    }
    
    @isTest static void test_method_Five() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account", "locations" : [{"locationId": "errors message" , "errors": [{"message": "errors message"}]}]}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        XO_Group_Settings__c xoSetting = new XO_Group_Settings__c();
        xoSetting.Turn_on_Fulfillment_Callouts__c = true;
        insert xoSetting;

        // testDataFactoryT tdf = new testDataFactoryT();
        // tdf.CreateLocalTestObjects();

        // tdf.testAccount.Fulfill_Storefront__c = false;
        // update tdf.testAccount;

        Test.startTest();
        Map<String ,SObject> testLocalData = TestClassUtility.buildLocalData(false);
        Test.stopTest();
        
        Account testAccount = (Account)testLocalData.get('Account');
        testAccount.Fulfill_Storefront__c = false;
        update testAccount;


        PageReference pageRef = Page.RequestStorefrontRepublish;
        Test.setCurrentPage(pageRef);

        //ApexPages.currentPage().getParameters().put('acctId', tdf.testAccount.Id);
        ApexPages.currentPage().getParameters().put('acctId', testAccount.Id);

        RequestStorefrontRepublishController rsfrc = new RequestStorefrontRepublishController();
        
    }
    
     @isTest static void test_method_Six() {
        // testDataFactoryT tdf = new testDataFactoryT();
        // tdf.CreateLocalTestObjects();

        // tdf.testAccount.Fulfill_Storefront__c = false;
        // update tdf.testAccount;
        
        Test.startTest();
        Map<String ,SObject> testLocalData = TestClassUtility.buildLocalData(false);
        Test.stopTest();
        
        Account testAccount = (Account)testLocalData.get('Account');
     
        testAccount.Fulfill_Storefront__c = false;
        update testAccount;
        // Account testAccount = new Account();
        // testAccount.Name = 'six Test child Account';
        // testAccount.Type = 'Agency';
        // testAccount.BillingCountry = 'United States';
        // testAccount.BillingState = 'Alaska';
        // testAccount.BillingCity = 'US2';
        // testAccount.BillingStreet = 'US3';
        // testAccount.BillingPostalCode = tdf.testZip.ZipCode__c;
        // testAccount.Website = 'www.google1.com';
        // testAccount.Primary_Brand__c = tdf.testBrand.id;
        // testAccount.Primary_Category__c = tdf.testCategory.id;
        // testAccount.Local_Sales_Market__c = tdf.testMarket.id;
        // insert testAccount;
        

        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        
     
        testAccount.ConciergePrgQua__c = '';
        testAccount.Operative_Owner__c = userinfo.getuserID();
        //testAccount.ParentId =testAccount.id;
        testAccount.RecordTypeId = rtMapByName.get('National').getRecordTypeId();
        testAccount.BU__c = 'National';
        update testAccount;
        //Test.startTest();
        PageReference pageRef = Page.RequestStorefrontRepublish;
        //Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('acctId', testAccount.Id);

        RequestStorefrontRepublishController rsfrc = new RequestStorefrontRepublishController();
        rsfrc.fulfillStorefront();
        
    }
}