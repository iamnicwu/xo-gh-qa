@isTest
private class InventoryTriggerHandlerTest{   
    /* 
    <method>
        <name>inventoryTriggerHandler_UnitTest</name>
        <purpose>Test InventoryTriggerHandler class</purpose>
        <created>
            <by>Scott Yang</by>
            <date>Oct/31/2016</date>
        </created>
    </method>
    */
    private static List<User> userList;
    private static Map<String,Schema.RecordTypeInfo> rtMapByName;
    private static Map<String,Schema.RecordTypeInfo> rtLeadMapByName;
    // CSP-1999 private static Map<String,Schema.RecordTypeInfo> rtBrandMapByName;
    private static Map<String,Schema.RecordTypeInfo> rtOppMapByName;
    private static Deactivate_Trigger__c dtatt;
    private static Generate_Quote_Pdf_Config__c GQPF;
    private static Promise_to_Pay_reminder_config__c PTP;
    // CSP-1999 private static Brand__c testBrand;
    private static Region__c testRegion;
    private static Market__c testMarket;
    private static Category__c testCategory;
    private static MetroArea__c ma;
    private static Zip__c zip;
    private static Account testAccount;
    private static Zuora__Subscription__c testZquSubscription;
    private static Zuora__Product__c testZuoraProduct;
    private static Zuora__SubscriptionProductCharge__c testZquSubscriptionProductCharge;
    private static zqu__ProductRatePlan__c testZquProductRatePlan; 

    private static zqu__QuoteRatePlan__c testZquQuoteRatePlan;


    @isTest static void inventoryTriggerHandler_UnitTest(){
        createtestData();
        Test.startTest();
        
        //Test insert trigger
        Inventory__c testInventory = TestClassUtility.createInventory(false, testZquProductRatePlan);     
        testInventory.Subscription_RatePlan_Id__c = 'asdasdasdasdas';
        testInventory.Quote_Rate_Plan__c = testZquQuoteRatePlan.Id;
        testInventory.Subscription_Product_Charge__c= testZquSubscriptionProductCharge.Id;
        insert testInventory;

        //Test update trigger
        Zuora__SubscriptionProductCharge__c testZquSubscriptionProductCharge2 = TestClassUtility.createSubscriptionProductCharge(false, testZquSubscription, testZuoraProduct);
        testZquSubscriptionProductCharge2.Zuora__Account__c = testaccount.id;
        testZquSubscriptionProductCharge2.Zuora_Id_of_Migrated_Charge__c = '8675309abcdefghi';
        insert testZquSubscriptionProductCharge2;
        testInventory.Subscription_Product_Charge__c = testZquSubscriptionProductCharge2.Id;
        update testInventory;

        //Test delete trigger
        delete testInventory;


        //Test removeExcessRenewalSubscriptionInventory() Start
        Inventory__c testInventory2 = TestClassUtility.createInventory(false, testZquProductRatePlan);     
        testInventory2.Subscription_RatePlan_Id__c = 'asdasdasdasdas';
        testInventory2.Quote_Rate_Plan__c = testZquQuoteRatePlan.Id;
        testInventory2.Subscription_Name__c = 'Test Subscription' ;
        testInventory2.Subscription_Version__c = 1 ;
        insert testInventory2;  // testInventory2's Subscription_Product_Charge__c == null
        
        Inventory__c testInventory3 = TestClassUtility.createInventory(false, testZquProductRatePlan);     
        testInventory3.Subscription_RatePlan_Id__c = 'asdasdasdasdas';
        testInventory3.Quote_Rate_Plan__c = testZquQuoteRatePlan.Id;
        testInventory3.Subscription_Product_Charge__c = testZquSubscriptionProductCharge2.Id; 
        testInventory3.Subscription_Name__c = 'Test Subscription' ; 
        insert testInventory3;
        //Test removeExcessRenewalSubscriptionInventory() End

        Test.stopTest();

     }

    private static void createtestData(){

        //Get 2 users
        userList = [select Id, Name, Alias from User where Id != :UserInfo.getUserId() and isActive = true  and ARR__c != null limit 2];
        rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        rtLeadMapByName = Schema.SObjectType.Lead.getRecordTypeInfosByName();
        // CSP-1999 rtBrandMapByName = Schema.SObjectType.Brand__c.getRecordTypeInfosByName();
        rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();

        if(Deactivate_Trigger__c.getValues('Attachment') == null){
            dtatt = TestClassUtility.createAttachmentDeactivateTriggerSetting(true);
              
        }
        if(Promise_to_Pay_reminder_config__c.getValues('P2P') == null){
            PTP = TestClassUtility.createPromiseToPayReminderConfig(true);
            
        }

        //Generate PDF(Custom settings)
        GQPF = TestClassUtility.generateQuotePdfConfig(false);
        GQPF.URL__c = 'www.google.com';
        insert GQPF;

        // CSP-1999 
        //Create Brand
        // testBrand = TestClassUtility.createBrand(false);
        // testBrand.RecordTypeId = rtBrandMapByName.get('Local').getRecordTypeId();
        // insert testBrand;
        //Create Region
        // testRegion = TestClassUtility.createRegion(true, testBrand);
        testRegion = TestClassUtility.createRegion(true);

        //Create Market
        testMarket = TestClassUtility.createMarket(false);
        testMarket.Market_ID__c = '222';
        testMarket.Active__c = true;
        testMarket.Local_Sales_Region__c = testRegion.id;
        insert testMarket;
        
        // CSP-1999 
        //Create Category
        // testCategory = TestClassUtility.createCategory(true, testBrand);
        testCategory = TestClassUtility.createCategory(true);
        
        //Create MetroArea
        ma = TestClassUtility.createMetroArea(true);
        
        //Create Zip Code 
        zip = TestClassUtility.createZip(false);
        zip.MetroArea__c = ma.id;
        zip.ZipCode__c = '99999';
        zip.name = '12121';
        zip.Local_Market__c = testMarket.id;
        insert zip; 

        // CSP-1999 
        //Create Account
        // testAccount = TestClassUtility.createAccount(false, testBrand, testCategory, testMarket);
        testAccount = TestClassUtility.createAccount(false, testCategory, testMarket);
        testAccount.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
        testAccount.Record_Type_Name__c = 'Local';
        testAccount.BU__c = 'Local';
        testAccount.Type = 'Agency';
        testAccount.Operative_Owner__c = userList[0].Name;
        testAccount.Fulfillment_Data__c = '{ "tier" : "Freemium", "reviewId" : "review Id", "parentGUID" : "37e0c6b9-6f4f-4dd4-a3f4-9707e9dc4bbc", "marketCode" : "228", "categoryId" : "8aa9a07b-fcd8-46ed-a98f-8f3e12689dd2" }';
        testAccount.OwnerId = userList[0].Id;
        testAccount.CBBS__c = userList[1].Id;
        testAccount.BillingPostalCode = zip.ZipCode__c;
        testAccount.Operative_Owner__c = userList[0].Name;
        insert testAccount;
        
        //Create Opportunity
        Opportunity testOpportunity = TestClassUtility.createOpportunity(false);
        testOpportunity.RecordTypeId = rtOppMapByName.get('Local').getRecordTypeId();
        testOpportunity.AccStrategist__c = UserInfo.getUserId();
        testOpportunity.Amount = 50000;
        testOpportunity.OwnerId = UserInfo.getUserId();
        testOpportunity.StageName = 'Prospecting';
        testOpportunity.AccountId = testAccount.Id;
        testOpportunity.CloseDate = Date.Today()-10;
        testOpportunity.Potential_Value_Print__c = 1.23;
        testOpportunity.Potential_Value_Internet__c = 1.23;
        testOpportunity.Potential_Value_Direct_Marketing__c = 1.23;
        testOpportunity.NeedToSendToZBilling__c = false;
        insert testOpportunity;
        
        //Create Contact
        Contact testContact = TestClassUtility.createContact(false, testAccount);
        testContact.Same_Address_as_Account__c = true;
        insert testContact;

        //Create Quote
        zqu__Quote__c testZquQuote = TestClassUtility.createQuote(false, testOpportunity, testAccount, testContact);
        testZquQuote.Preferred_Payment_Schedule__c = 'Quarter';   
        testZquQuote.zqu__InitialTerm__c = 3;  
        testZquQuote.zqu__StartDate__c = date.today().adddays(1);       
        testZquQuote.Product_Line__c = 'Print';
        testZquQuote.zqu__Previewed_TCV__c = 7.22;
        insert testZquQuote;
        
        //Create Product
        Product2 testProduct = TestClassUtility.createLocalProduct2(true);
        

        //Create Subscription
        testZquSubscription = TestClassUtility.createSubscription(false, testAccount);
        testZquSubscription.Zuora__Zuora_Id__c = 'abc123';
        testZquSubscription.OriginalSalesforceQuoteID__c = testZquQuote.Id;
        testZquSubscription.Zuora__Version__c =10 ; // Set Zuora__Version__c 
        insert testZquSubscription;
        
        //Create ZuoraProduct
        testZuoraProduct = TestClassUtility.createZuoraProduct(true);

        //Create SubScriptionProduct&Charge
        testZquSubscriptionProductCharge = TestClassUtility.createSubscriptionProductCharge(false, testZquSubscription, testZuoraProduct);
        testZquSubscriptionProductCharge.Zuora__Account__c = testaccount.id;
        testZquSubscriptionProductCharge.Zuora_Id_of_Migrated_Charge__c = '8675309abcdefghi';
        insert testZquSubscriptionProductCharge;
        
        //Create Product Rate Plan(not include price)
        testZquProductRatePlan = TestClassUtility.createProductRatePlan(false); 
        testZquProductRatePlan.Name = 'Rate Plan 1'; 
        testZquProductRatePlan.zqu__Product__c = testProduct.id; 
        testZquProductRatePlan.Capacity__c = '10';
        insert testZquProductRatePlan;
        
        //Create ProductRatePlanCharge(include price)
        zqu__ProductRatePlanCharge__c testZquProductRatePlanCharge = TestClassUtility.createProductRatePlanCharge(false);
        testZquProductRatePlanCharge.zqu__Upto_How_Many_Periods__c = 1;
        insert testZquProductRatePlanCharge; 
        
        //Create QuoteAmendment
        zqu__QuoteAmendment__c testZquQuoteAmendment = TestClassUtility.createQuoteAmendment(true, testZquQuote);
        
        //Create Quote Rate Plan
        testZquQuoteRatePlan = TestClassUtility.createQuoteRatePlan(true, testZquQuote, testZquProductRatePlan, testZquQuoteAmendment);  
        
        //Create Quote Rate Plan Charge
        zqu__QuoteRatePlanCharge__c testZquQuoteRatePlanCharge = TestClassUtility.createQuoteRatePlanCharge(false, testZquQuoteRatePlan, testZquProductRatePlanCharge);
        testZquQuoteRatePlanCharge.Location_Vendor__c = testaccount.id;
        insert testZquQuoteRatePlanCharge;
        
        //Create Waitlist(when Inventory run out, put current ProductRatePlan into Waitlist)
        Waitlist__c w = TestClassUtility.createWaitlist(true,testZquProductRatePlan);


    }

        // @isTest static void test_method_one() {
    //     // Implement test code
    //     Test.startTest();
        
    //     testDataFactoryT tdf = new testDataFactoryT();
    //     tdf.CreateNationalTestObjects();
        
    //     InventoryTriggerHandler  ith = new InventoryTriggerHandler();
    //     //ith.bulkBefore();
    //     ith.bulkAfter();
    //     ith.beforeInsert(tdf.testInventory);
    //     ith.beforeUpdate(tdf.testInventory,tdf.testInventory);
        
        
    //     ith.afterUpdate(tdf.testInventory,tdf.testInventory);
    //     ith.beforeDelete(tdf.testInventory);
    //     ith.afterDelete(tdf.testInventory);
    //     //ith.andFinally();
        
    //     tdf.testInventory.Waitlist_Account__c = tdf.testaccount.id;
    //     update tdf.testInventory;
    //     try{
    //         ith.afterInsert(tdf.testInventory);
    //     }catch(exception e){}
        
    //     Test.StopTest();
    // }

}