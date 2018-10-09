/* 
<Class>
  <name>BatchDeleteZuoraObjectTest</name>
  <purpose>For testing the following classes: 
            BatchDeleteZeroDollarSubscriptionCharges
            BatchDeleteZeroDollarSubChrgScheduledJob
            BatchDeleteNonsellableProducts
            BatchDeleteNonsellableProductsScheduled
            BatchDeleteNonsellableRatePlans
            BatchDeleteNonsellableRatePlansScheduled
            BatchDeleteNonsellableRatePlanCharge
            BatchDeleteNonsellableRPCScheduledJob
            BatchDeleteAvailableInventory
            BatchDeleteAvailableInventoryScheduled
  </purpose>
  <created>
    <by>Steve O'Neal</by>
    <date>03/01/2016</date>
    <ticket>CSP-291</ticket>
  </created>
</Class>
*/
@isTest
public with sharing class BatchDeleteZuoraObjectTest {
    static testMethod void testBatchDeleteZeroDollarSubscriptionCharges() {
        Test.startTest();
        // Implement test code
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Inventory_Hold_Expiry_Date_Offsets__c invHoldExpDateOffsets = Inventory_Hold_Expiry_Date_Offsets__c.getOrgDefaults();
        invHoldExpDateOffsets.Account_Day_Offset__c = 3;
        upsert invHoldExpDateOffsets;

        TestClassUtility.createCBSSCustomSettings();
        
        List<User> userList = [select Id, Name, Alias from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        // CSP-1999 Map<String,Schema.RecordTypeInfo> rtBrandMapByName = Schema.SObjectType.Brand__c.getRecordTypeInfosByName();
        
        if(Deactivate_Trigger__c.getValues('Attachment') == null){
            TestClassUtility.createAttachmentDeactivateTriggerSetting(true); 
        }
        
        Generate_Quote_Pdf_Config__c quotePdfConfig = TestClassUtility.generateQuotePdfConfig(false);
        quotePdfConfig.URL__c = 'www.baidu.com';
        insert quotePdfConfig;
        // CSP-1999 
        // Brand__c testBrand = TestClassUtility.createBrand(false);
        // testBrand.RecordTypeId = rtBrandMapByName.get('Local').getRecordTypeId();
        // insert testBrand;
        // Region__c testRegion = TestClassUtility.createRegion(true, testBrand);
        Region__c testRegion = TestClassUtility.createRegion(true);
        Market__c testMarket = TestClassUtility.createMarket(false);
        testMarket.Market_ID__c = '222';
        testMarket.Active__c = true;
        testMarket.Local_Sales_Region__c = testRegion.id;
        insert testMarket;
        // CSP-1999 
        // Category__c testCategory = TestClassUtility.createCategory(true, testBrand);
        Category__c testCategory = TestClassUtility.createCategory(true);
        MetroArea__c ma = TestClassUtility.createMetroArea(true);
        
        Zip__c zip = TestClassUtility.createZip(false);
        zip.MetroArea__c = ma.id;
        zip.ZipCode__c = '99999';
        zip.name = '12121';
        zip.Local_Market__c = testMarket.id;
        insert zip; 
        // CSP-1999 
        // Account account = TestClassUtility.createAccount(false, testBrand, testCategory, testMarket);
        Account account = TestClassUtility.createAccount(false, testCategory, testMarket);
        account.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
        account.Record_Type_Name__c = 'Local';
        account.BU__c = 'Local';
        account.Type = 'Agency';
        account.Operative_Owner__c = userList[0].Name;
        account.Fulfillment_Data__c = '{ "tier" : "Freemium", "reviewId" : "review Id", "parentGUID" : "37e0c6b9-6f4f-4dd4-a3f4-9707e9dc4bbc", "marketCode" : "228", "categoryId" : "8aa9a07b-fcd8-46ed-a98f-8f3e12689dd2" }';
        account.BillingPostalCode =zip.zipCode__c;
        insert account;

        Zuora__Subscription__c testSubscription = TestClassUtility.createSubscription(false,account);
        testSubscription.Product_Line__c = 'Migrated Contract';
        insert testSubscription;
        
        Zuora__Product__c testZuoraProduct = TestClassUtility.createZuoraProduct(true);
        // create a $0 subscription charge #00
        Zuora__SubscriptionProductCharge__c testCharge00 = new Zuora__SubscriptionProductCharge__c();
        testCharge00.Name = 'Charge #00';
        testCharge00.Zuora__EffectiveEndDate__c = Date.newinstance(2015, 9, 10);
        testCharge00.Zuora__Zuora_Id__c = 'zinrid12nd45oidla';
        testCharge00.Quote_Rate_Plan_ID__c = 'qweqweqwe';
        testCharge00.Zuora__RatePlanId__c = 'asdasdasdasdas';
        testCharge00.Zuora__Subscription__c = testSubscription.id;
        testCharge00.Zuora__ProductName__c = 'Test Product';
        testCharge00.Zuora__RatePlanName__c = 'Test Product Rate Plan';
        testCharge00.Zuora__Product__c = testZuoraProduct.id;
        testCharge00.Zuora__Account__c = account.id;
        testCharge00.Zuora__TotalContractValue__c = 0;
        insert testCharge00;
        
        // create a $0 subscription charge #01
        Zuora__SubscriptionProductCharge__c testCharge01 = new Zuora__SubscriptionProductCharge__c();
        testCharge01.Name = 'Charge #01';
        testCharge01.Zuora__EffectiveEndDate__c = Date.newinstance(2015, 9, 10);
        testCharge01.Zuora__Zuora_Id__c = 'zinrid12nd45oidlb';
        testCharge01.Quote_Rate_Plan_ID__c = 'qweqweqwe';
        testCharge01.Zuora__RatePlanId__c = 'asdasdasdasdas';
        testCharge01.Zuora__Subscription__c = testSubscription.id;
        testCharge01.Zuora__ProductName__c = 'Test Product';
        testCharge01.Zuora__RatePlanName__c = 'Test Product Rate Plan';
        testCharge01.Zuora__Product__c = testZuoraProduct.id;
        testCharge01.Zuora__Account__c = account.id;
        testCharge01.Zuora__TotalContractValue__c = 0;
        insert testCharge01;
        
        // run the batch
        BatchDeleteZeroDollarSubscriptionCharges batch = new BatchDeleteZeroDollarSubscriptionCharges();
        Database.executeBatch(batch);
        
        Test.stopTest();
        
    }

    static testMethod void testBatchDeleteZeroDollarSubChrgScheduledJob() {
        Test.startTest();
            // Implement test code
            SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                     'Complete',
                                                     '{"companyName": "Test Account"}',
                                                     null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            
            BatchDeleteZeroDollarSubChrgScheduledJob sj = new BatchDeleteZeroDollarSubChrgScheduledJob();
            String sch = '0 1 0 * * ?';
            System.schedule('testBatchDeleteZeroDollarSubChrgScheduledJob', sch, sj);
        Test.stopTest();
    }

    static testMethod void testBatchDeleteNonsellableProductsScheduled() {

        Test.startTest();
            // Implement test code
            SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                     'Complete',
                                                     '{"companyName": "Test Account"}',
                                                     null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            
            BatchDeleteNonsellableProductsScheduled sj = new BatchDeleteNonsellableProductsScheduled();
            String sch = '0 1 0 * * ?';
            System.schedule('testBatchDeleteNonsellableProductsScheduled', sch, sj);
        Test.stopTest();
    }
    
    static testMethod void testBatchDeleteNonsellableRatePlans() {    
        Test.startTest();
            // Implement test code
            SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                     'Complete',
                                                     '{"companyName": "Test Account"}',
                                                     null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);

            // Create Product Data
            Product2 testProduct = TestClassUtility.createLocalProduct2(true);
            zqu__ProductRatePlan__c testProductRatePlan2 = TestClassUtility.createProductRatePlan(true, testProduct);
            testProductRatePlan2.zqu__EffectiveEndDate__c = Date.newInstance(2016,1,31);
            update testProductRatePlan2;

            // run the batch
            BatchDeleteNonsellableRatePlans batch = new BatchDeleteNonsellableRatePlans();
            Database.executeBatch(batch);
        Test.stopTest();
    }

    static testMethod void testBatchDeleteNonsellableRatePlansScheduled() {
        Test.startTest();
            // Implement test code
            SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                     'Complete',
                                                     '{"companyName": "Test Account"}',
                                                     null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            
            BatchDeleteNonsellableRatePlansScheduled sj = new BatchDeleteNonsellableRatePlansScheduled();
            String sch = '0 1 0 * * ?';
            System.schedule('testBatchDeleteNonsellableRatePlansScheduled', sch, sj);
        Test.stopTest();
    }
    
    static testMethod void testBatchDeleteNonsellableRatePlanCharge() {
        Test.startTest();
            // Implement test code
            SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                     'Complete',
                                                     '{"companyName": "Test Account"}',
                                                     null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);

            // Create Product Data
            zqu__ProductRatePlanCharge__c testZquProductRatePlanCharge = TestClassUtility.createProductRatePlanCharge(true);
            testZquProductRatePlanCharge.zqu__Deleted__c = true;
            update testZquProductRatePlanCharge;  

            // run the batch
            BatchDeleteNonsellableRatePlanCharge batch = new BatchDeleteNonsellableRatePlanCharge();
            Database.executeBatch(batch);
        Test.stopTest();
    }

    static testMethod void testBatchDeleteNonsellableRPCScheduledJob() {
        Test.startTest();
            // Implement test code
            SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                     'Complete',
                                                     '{"companyName": "Test Account"}',
                                                     null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            
            BatchDeleteNonsellableRPCScheduledJob sj = new BatchDeleteNonsellableRPCScheduledJob();
            String sch = '0 1 0 * * ?';
            System.schedule('testBatchDeleteNonsellableRPCScheduledJob', sch, sj);
        Test.stopTest();
    }

    static testMethod void testBatchDeleteAvailableInventory() {
        Test.startTest();
            // Implement test code
            SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                     'Complete',
                                                     '{"companyName": "Test Account"}',
                                                     null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);

            ChainBatchJob__c CBJ = new ChainBatchJob__c();
            CBJ.name = 'BatchDeleteAvailableInventory';
            CBJ.Chain_Next_Batch_Job__c = true;
            insert CBJ;
            
            Product2 testProduct = TestClassUtility.createLocalProduct2(true);
            zqu__ProductRatePlan__c testZquProductRatePlan = TestClassUtility.createProductRatePlan(true,testProduct);
            
            Inventory__c inv = TestClassUtility.createInventory(true, testZquProductRatePlan);
            
            // run the batch
            BatchDeleteAvailableInventory batch = new BatchDeleteAvailableInventory();
            Database.executeBatch(batch);
        Test.stopTest();
    }

    static testMethod void testBatchDeleteAvailableInventoryScheduled() {
        Test.startTest();
            // Implement test code
            SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                     'Complete',
                                                     '{"companyName": "Test Account"}',
                                                     null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            
            BatchDeleteAvailableInventoryScheduled sj = new BatchDeleteAvailableInventoryScheduled();
            String sch = '0 1 0 * * ?';
            System.schedule('testBatchDeleteNonsellableRPCScheduledJob', sch, sj);
        Test.stopTest();
    }
}