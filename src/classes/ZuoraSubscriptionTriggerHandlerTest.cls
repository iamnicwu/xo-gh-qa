@isTest()
private class ZuoraSubscriptionTriggerHandlerTest {
    private static List<User> userList;
    private static Map<String,Schema.RecordTypeInfo> rtMapByName;
    private static Map<String,Schema.RecordTypeInfo> rtLeadMapByName;
    // CSP-1999 private static Map<String,Schema.RecordTypeInfo> rtBrandMapByName;
    private static Deactivate_Trigger__c dtatt;
    private static Generate_Quote_Pdf_Config__c GQPF;
    // CSP-1999 private static Brand__c testBrand;
    private static Region__c testRegion;
    private static Market__c testMarket;
    private static Category__c testCategory;
    private static MetroArea__c ma;
    private static Zip__c zip;
    //private static DefaulCBSSValues__c createCBSSSetting;
    static testMethod void TestUpdateLocalActiveStatus() {
        
        createtestData();
        // CSP-1999 
        // Account parentAccount = TestClassUtility.createAccount(false, testBrand, testCategory, testMarket);
        Account parentAccount = TestClassUtility.createAccount(false, testCategory, testMarket);
        parentAccount.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
        parentAccount.Record_Type_Name__c = 'Local';
        parentAccount.BU__c = 'Local';
        parentAccount.Type = 'Agency';
        parentAccount.Operative_Owner__c = userList[0].Name;
        parentAccount.Fulfillment_Data__c = '{ "tier" : "Freemium", "reviewId" : "review Id", "parentGUID" : "37e0c6b9-6f4f-4dd4-a3f4-9707e9dc4bbc", "marketCode" : "228", "categoryId" : "8aa9a07b-fcd8-46ed-a98f-8f3e12689dd2" }';
        parentAccount.ShippingPostalCode = zip.zipCode__c;
        parentAccount.BillingPostalCode = zip.zipCode__c;
        insert parentAccount;
        
        List<User> NoManagerSRuList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true and Manager.SalesRepID__c = null limit 2];
        List<User> InactiveuserList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = false limit 2];
        
        List<Zuora__Subscription__c> zuoraSubscriptionList = new List<Zuora__Subscription__c>();
        for(integer i =0;i<5;i++){
            Zuora__Subscription__c testZquSubscription = TestClassUtility.createSubscription(false, parentAccount);
            testZquSubscription.Zuora__Status__c = 'Cancelled';
            testZquSubscription.Renewal_Rep__c = userlist[0].id;
            testZquSubscription.RenewalRepId__c = userlist[0].SalesRepID__c;
            testZquSubscription.ReportingRepId__c = userlist[0].SalesRepID__c;
            testZquSubscription.SalesRepID__c =userlist[0].SalesRepID__c;
            zuoraSubscriptionList.add(testZquSubscription);
        }
        zuoraSubscriptionList[0].Zuora__Status__c = 'Active';
        insert zuoraSubscriptionList;
        
        zuoraSubscriptionList[0].Renewal_Rep__c = InactiveuserList[1].id;   
        zuoraSubscriptionList[0].Reporting_Rep__c = InactiveuserList[1].id; 
        try{
            update zuoraSubscriptionList;
        }catch(exception e){}
        //system.assert(false,testZquSubscription.Renewal_Rep__c+'::'+userlist[1].id);
        zuoraSubscriptionList[0].Renewal_Rep__c = userlist[1].id;
        //testZquSubscription.Reporting_Rep__c = NoManageruList[1].id;
        try{
            update zuoraSubscriptionList;
        }catch(exception e){}
        
        zuoraSubscriptionList[0].Reporting_Rep__c = NoManagerSRuList[1].id;
        try{
            update zuoraSubscriptionList;
        }catch(exception e){}
        
        zuoraSubscriptionList[0].Reporting_Rep__c = userlist[1].id;
        try{
            update zuoraSubscriptionList;
        }catch(exception e){}
        
        zuoraSubscriptionList[0].Name = 'Test Subscription2';
        try{
            update zuoraSubscriptionList;
        }catch(exception e){}
        
        ZuoraSubscriptionTriggerHandler testcase = new ZuoraSubscriptionTriggerHandler();
        testcase.afterUpdate(zuoraSubscriptionList[0],zuoraSubscriptionList[0]);
        testcase.afterDelete(zuoraSubscriptionList[0]);
        
        delete zuoraSubscriptionList;
    }
    
    static testMethod void TestUpdateLocalActiveStatus2() {
        
        createtestData();
        // CSP-1999 
        // Account parentAccount = TestClassUtility.createAccount(false, testBrand, testCategory, testMarket);
        Account parentAccount = TestClassUtility.createAccount(false, testCategory, testMarket);
        parentAccount.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
        parentAccount.Record_Type_Name__c = 'Local';
        parentAccount.BU__c = 'Local';
        parentAccount.Type = 'Agency';
        parentAccount.Operative_Owner__c = userList[0].Name;
        parentAccount.Fulfillment_Data__c = '{ "tier" : "Freemium", "reviewId" : "review Id", "parentGUID" : "37e0c6b9-6f4f-4dd4-a3f4-9707e9dc4bbc", "marketCode" : "228", "categoryId" : "8aa9a07b-fcd8-46ed-a98f-8f3e12689dd2" }';
        parentAccount.ShippingPostalCode = zip.zipCode__c;
        parentAccount.BillingPostalCode = zip.zipCode__c;
        insert parentAccount;
        // CSP-1999 
        // Account testAccount = TestClassUtility.createAccount(false, testBrand, testCategory, testMarket);
        Account testAccount = TestClassUtility.createAccount(false, testCategory, testMarket);
        testAccount.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
        testAccount.Record_Type_Name__c = 'Local';
        testAccount.BU__c = 'Local';
        testAccount.Type = 'Agency';
        testAccount.Operative_Owner__c = userList[0].Name;
        testAccount.Fulfillment_Data__c = '{ "tier" : "Freemium", "reviewId" : "review Id", "parentGUID" : "37e0c6b9-6f4f-4dd4-a3f4-9707e9dc4bbc", "marketCode" : "228", "categoryId" : "8aa9a07b-fcd8-46ed-a98f-8f3e12689dd2" }';
        testAccount.ShippingPostalCode = zip.zipCode__c+'1';
        testAccount.BillingPostalCode = zip.zipCode__c;    
        insert testAccount;
        
        parentAccount.Local_Active__c = false;
        update parentAccount;
        
        List<Zuora__Subscription__c> zslist = new List<Zuora__Subscription__c>();
        for(integer i =0;i<55;i++){
            Zuora__Subscription__c testZquSubscription1 = TestClassUtility.createSubscription(false, testAccount);
            testZquSubscription1.Zuora__Status__c = 'Cancelled';
            testZquSubscription1.Renewal_Rep__c = userlist[0].id;
            testZquSubscription1.RenewalRepId__c = userlist[0].SalesRepID__c;
            testZquSubscription1.ReportingRepId__c = userlist[0].SalesRepID__c;
            testZquSubscription1.SalesRepID__c =userlist[0].SalesRepID__c;
            testZquSubscription1.Zuora__Zuora_Id__c = 'testZuoraId'+ string.valueOf(i);
            zslist.add(testZquSubscription1);
        }
        zslist[0].Zuora__Status__c = 'Active';
        insert zslist;
        
        zslist[2].Renewal_Rep__c = userlist[1].id;
        zslist[2].Reporting_Rep__c = userlist[1].id;
        zslist[2].Sales_Rep__c = userlist[1].id;
        zslist[3].RenewalRepId__c = userlist[1].SalesRepID__c;
        zslist[4].ReportingRepId__c = userlist[1].SalesRepID__c;
        zslist[5].SalesRepID__c = userlist[1].SalesRepID__c;
        try{
            update zslist;
        }catch(exception e){}
        
    }
    
    private static void createtestData(){
        userList = [select Id, Name, Alias, SalesRepID__c, Manager.SalesRepID__c from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        rtLeadMapByName = Schema.SObjectType.Lead.getRecordTypeInfosByName();
        // CSP-1999 rtBrandMapByName = Schema.SObjectType.Brand__c.getRecordTypeInfosByName();
        
        if(Deactivate_Trigger__c.getValues('Attachment') == null){
            dtatt = TestClassUtility.createAttachmentDeactivateTriggerSetting(true);
              
        }
        //createCBSSSetting = TestClassUtility.createCBSSSetting(true);
        
        GQPF = TestClassUtility.generateQuotePdfConfig(false);
        GQPF.URL__c = 'www.baidu.com';
        insert GQPF;
        // CSP-1999 
        // testBrand = TestClassUtility.createBrand(false);
        // testBrand.RecordTypeId = rtBrandMapByName.get('Local').getRecordTypeId();
        // insert testBrand;
        // testRegion = TestClassUtility.createRegion(true, testBrand);
        testRegion = TestClassUtility.createRegion(true);
        testMarket = TestClassUtility.createMarket(false);
        testMarket.Market_ID__c = '222';
        testMarket.Active__c = true;
        testMarket.Local_Sales_Region__c = testRegion.id;
        insert testMarket;
        // CSP-1999 
        // testCategory = TestClassUtility.createCategory(true, testBrand);
        testCategory = TestClassUtility.createCategory(true);
        ma = TestClassUtility.createMetroArea(true);
        
        zip = TestClassUtility.createZip(false);
        zip.MetroArea__c = ma.id;
        zip.ZipCode__c = '99999';
        zip.name = '12121';
        zip.Local_Market__c = testMarket.id;
        insert zip; 
    
    }

    static testMethod void testReleaseCancelledReplaceInventoryMethod() {
        Test.startTest();

        Map<String, SObject> testObjects = TestClassUtility.buildZQUTestObjects(false);

        // Create Quote
        zqu__Quote__c testQuote = TestClassUtility.createQuote(false, (Opportunity)testObjects.get('Opportunity'), (Account)testObjects.get('Account'), (Contact)testObjects.get('Contact'));
        testQuote.zqu__Status__c = 'Sent to Z-Billing';
        insert testQuote;
        testObjects.put('zqu__Quote__c', testQuote);

        // Create local product
        Product2 testProduct = TestClassUtility.createLocalProduct2(true);
        testObjects.put('Product2', testProduct);

        // Create Product Rate Plan
        zqu__ProductRatePlan__c testProductRatePlan = TestClassUtility.createProductRatePlan(true, testProduct);
        testObjects.put('zqu__ProductRatePlan__c', testProductRatePlan);

        // Create Subscription
        Zuora__Subscription__c testSubscription = TestClassUtility.createSubscription(false, (Account)testObjects.get('Account'));
        testSubscription.Zuora__Status__c = 'Cancelled';
        insert testSubscription;
        testObjects.put('Zuora__Subscription__c', testSubscription);

        // Create Zuora Product
        Zuora__Product__c testZuoraProduct = TestClassUtility.createZuoraProduct(true);
        testObjects.put('Zuora__Product__c', testZuoraProduct);

        // Create Quote Charge Detail
        zqu__QuoteChargeDetail__c testQuoteChargeDetail = TestClassUtility.createQuoteChargeDetail(false, testQuote);
        testQuoteChargeDetail.zqu__ChargeNumber__c = 'C-666';
        testQuoteChargeDetail.Inventory_Freed_By_Cancellation__c = true;
        insert testQuoteChargeDetail;
        testObjects.put('zqu__QuoteChargeDetail__c', testQuoteChargeDetail); 
        
        Test.stopTest();

        // Create Subscription Product Charge
        // (inserting this record is what causes the ZuoraSubscriptionPCTriggerHandler.releaseCancelledReplaceInventory to be called)
        Zuora__SubscriptionProductCharge__c testSubscriptionProductCharge = TestClassUtility.createSubscriptionProductCharge(false, testSubscription, testZuoraProduct);
        testSubscriptionProductCharge.Zuora__ChargeNumber__c = 'C-666';
        insert testSubscriptionProductCharge;
        testObjects.put('Zuora__SubscriptionProductCharge__c', testSubscriptionProductCharge);
    }
}