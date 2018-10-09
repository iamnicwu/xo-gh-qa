@isTest
private class LocalProductRulesTest{
    
    /**
     *   Used to evaluate internet, print, direct mail, migrate contract and transactions
     *   these five product line's opportunities
     *
     *   @author Nick
     *   @date   2017-02-04
     *   @return test method
     */
    @isTest static void test_evaluateOpportunity_one() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();  
        Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        // CSP-1999 Map<String,Schema.RecordTypeInfo> rtBrandMapByName = Schema.SObjectType.Brand__c.getRecordTypeInfosByName();
        
        Test.startTest();
            Map<String, SObject> testData =TestClassUtility.buildLocalData(false);
            TestClassUtility.generateQuotePdfConfig(true);


            Opportunity testOpportunity = (Opportunity)testData.get('Opportunity');
            Account testAccount = (Account)testData.get('Account');
            Contact testContact = (Contact)testData.get('Contact');

            zqu__Quote__c testQuote =TestClassUtility.createQuote(true, 
                                                        testOpportunity, 
                                                        testAccount, 
                                                        testContact);
            
            LocalProductRules.evaluateOpportunity(testOpportunity.id);
            
            testQuote.Product_Line__c  = 'Print';  
            update testQuote;
            LocalProductRules.evaluateOpportunity(testOpportunity.id);
        Test.stopTest();
        
        testQuote.Product_Line__c  = 'Direct Mail';  
        update testQuote;
        LocalProductRules.evaluateOpportunity(testOpportunity.id);

        testQuote.Product_Line__c  = 'Migrated Contract'; 
        testQuote.zqu__SubscriptionType__c = 'Amend Subscription'; 
        update testQuote;
        LocalProductRules.evaluateOpportunity(testOpportunity.id);

        
    }
    
    /**
     *   Used to evaluate the opportunity with Cancel Subscription
     *
     *   @author Nick
     *   @date   2017-02-04
     *   @return test method
     */
    @isTest static void test_evaluateOpportunity_two() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        // CSP-1999 Map<String,Schema.RecordTypeInfo> rtBrandMapByName = Schema.SObjectType.Brand__c.getRecordTypeInfosByName();
        
        Test.startTest();
        Map<String, SObject> testData =TestClassUtility.buildLocalData(false);
        Test.stopTest();
        TestClassUtility.generateQuotePdfConfig(true);


        Opportunity testOpportunity = (Opportunity)testData.get('Opportunity');
        Account testAccount = (Account)testData.get('Account');
        Contact testContact = (Contact)testData.get('Contact');
        Market__c testMarket = (Market__c)testData.get('Market__c');

        zqu__Quote__c testQuote =TestClassUtility.createQuote(false, 
                                                    testOpportunity, 
                                                    testAccount, 
                                                    testContact);
        testQuote.zqu__TermStartDate__c  = date.today().adddays(14);
        testQuote.zqu__InitialTerm__c = 12;
        insert testQuote;
        
        Publication__c testPublication = new Publication__c();
        testPublication.name = 'testPublication';
        testPublication.Short_Name__c = 'test';
        insert testPublication;
        
        Edition__c testEdition = new Edition__c();
        testEdition.name = 'testEdition';
        testEdition.Publication__c = testPublication.id;
        insert testEdition;
        

        Print_Issue__c pi1 =new Print_Issue__c();
        pi1.name = 'test name';
        pi1.Edition__c = testEdition.id;
        pi1.Print_Market__c = testMarket.id;
        pi1.Selling_Start_Date__c = date.today();
        pi1.Publish_1st_Cover_Ship__c = date.today();
        insert pi1;
        
        Print_Issue__c pi2 =new Print_Issue__c();
        pi2.name = 'test name';
        pi2.Edition__c = testEdition.id;
        pi2.Print_Market__c = testMarket.id;
        pi2.Selling_Start_Date__c = date.today();
        pi2.Publish_1st_Cover_Ship__c = date.today();
        insert pi2;
        
        Print_Issue__c pi =new Print_Issue__c();
        pi.name = 'test name';
        pi.Previous_Issue__c = pi1.id;
        pi.Next_Issue__c = pi2.id;
        pi.Edition__c = testEdition.id;
        pi.Print_Market__c = testMarket.id;
        pi.Selling_Start_Date__c = date.today();
        pi.Publish_1st_Cover_Ship__c = date.today();
        pi.Step_2__c = date.today().adddays(-1);
        pi.Step_3__c = date.today().adddays(-1);
        insert pi;
        
        //Create Product
        // Product2 testProduct = TestClassUtility.createLocalProduct2(true);
        Product2 testProduct = TestClassUtility.createLocalProduct2(false);
        testProduct.Requires_2X__c = 'Yes';  
        testProduct.RequiresPaidStorefront__c = 'In Any Market/Category';
        insert testProduct;
        
        zqu__ProductRatePlan__c testZquProductRatePlan = new zqu__ProductRatePlan__c(); 
        testZquProductRatePlan.Name = 'Test Product Rate Plan'; 
        testZquProductRatePlan.zqu__Product__c = testProduct.id; 
        testZquProductRatePlan.Capacity__c = '10';
        testZquProductRatePlan.Market__c = 'Test Market';
        testZquProductRatePlan.Category__c = 'Test Category';
        testZquProductRatePlan.zqu__ZuoraId__c = '2c92c0f94e4d3a3d014e655c28c50f5f';  
        insert testZquProductRatePlan;
        
        zqu__ProductRatePlanCharge__c testZquProductRatePlanCharge = new zqu__ProductRatePlanCharge__c();
        testZquProductRatePlanCharge.Name = 'Test Prodcut Rate Plan Charge'; 
        testZquProductRatePlanCharge.zqu__DefaultQuantity__c = 0; 
        testZquProductRatePlanCharge.zqu__ListPrice__c = 200;
        testZquProductRatePlanCharge.zqu__Model__c = 'Flat Fee Pricing';
        testZquProductRatePlanCharge.zqu__ProductRatePlan__c = testZquProductRatePlan.id; 
        testZquProductRatePlanCharge.zqu__RecurringPeriod__c = 'Month'; 
        testZquProductRatePlanCharge.zqu__ZuoraId__c = '2c92c0f94e4d3a41014e655c389b63f7';
        insert testZquProductRatePlanCharge; 
        
        zqu__QuoteAmendment__c testZquQuoteAmendment = new zqu__QuoteAmendment__c();
        testZquQuoteAmendment.Name = 'Test Amendment'; 
        testZquQuoteAmendment.zqu__Quote__c = testQuote.id; 
        testZquQuoteAmendment.zqu__DeltaMRR__c = 0; 
        testZquQuoteAmendment.zqu__DeltaTCV__c = 200; 
        testZquQuoteAmendment.zqu__Description__c = 'Testing the amendment';  
        testZquQuoteAmendment.zqu__Status__c = 'Draft'; 
        testZquQuoteAmendment.zqu__TotalAmount__c = 200; 
        testZquQuoteAmendment.zqu__Type__c = 'NewProduct';
        insert testZquQuoteAmendment;
        
        zqu__QuoteRatePlan__c testZquQuoteRatePlan = new zqu__QuoteRatePlan__c();  
        testZquQuoteRatePlan.Name = 'Test Rate Plan';  
        testZquQuoteRatePlan.zqu__QuoteAmendment__c = testZquQuoteAmendment.id; 
        testZquQuoteRatePlan.zqu__AmendmentType__c = 'RemoveProduct';
        testZquQuoteRatePlan.zqu__ProductRatePlanZuoraId__c = '2c92c0f94e4d3a3d014e655c28c50f5f'; 
        testZquQuoteRatePlan.zqu__QuoteProductName__c = 'Featured Vendor'; 
        testZquQuoteRatePlan.zqu__Quote__c = testQuote.id; 
        testZquQuoteRatePlan.zqu__ProductRatePlan__c = testZquProductRatePlan.id; 
        testZquQuoteRatePlan.Print_Issue__c = pi.id;
        // testZquQuoteRatePlan.Requires2X__c = 'Yes';
        insert testZquQuoteRatePlan;
        
        zqu__QuoteRatePlanCharge__c testZquQuoteRatePlanCharge = new zqu__QuoteRatePlanCharge__c();
        testZquQuoteRatePlanCharge.Name = 'Test Quote Rate Plan Charge';  
        testZquQuoteRatePlanCharge.zqu__QuoteRatePlan__c = testZquQuoteRatePlan.id; 
        testZquQuoteRatePlanCharge.zqu__ProductRatePlanCharge__c = testZquProductRatePlanCharge.id;
        testZquQuoteRatePlanCharge.Location_Vendor__c = testaccount.id;
        testZquQuoteRatePlanCharge.Discount_Override__c = 10;
        testZquQuoteRatePlanCharge.Steelbrick_Calculated_Discount__c = 5;
        insert testZquQuoteRatePlanCharge;

        LocalProductRules.evaluateOpportunity(testOpportunity.id); 
        
        
        testZquQuoteRatePlanCharge.Discount_Override__c = 5;
        testZquQuoteRatePlanCharge.Steelbrick_Calculated_Discount__c = 10;
        update testZquQuoteRatePlanCharge;
        
        testQuote.zqu__SubscriptionType__c = 'Cancel Subscription';
        update testQuote;
        
        LocalProductRules.evaluateOpportunity(testOpportunity.id); 
        
        LocalProductRules.QuotesWrapper QuotesWrapper = new LocalProductRules.QuotesWrapper();
        LocalProductRules.OpportunityQuotesWrapper OpportunityQuotesWrapper = new LocalProductRules.OpportunityQuotesWrapper();
        
        QuotesWrapper.quote = testQuote;
        QuotesWrapper.quoteProductLine = 'Print';
        QuotesWrapper.quoteSubscriptionType = 'Cancel Subscription';
        OpportunityQuotesWrapper.quotesWrapperList.add(QuotesWrapper);
        OpportunityQuotesWrapper = LocalProductRules.runPrintEvaluation(OpportunityQuotesWrapper);
        
        OpportunityQuotesWrapper = new LocalProductRules.OpportunityQuotesWrapper();
        QuotesWrapper.quote = testQuote;
        QuotesWrapper.quoteProductLine = 'Print';
        QuotesWrapper.quoteSubscriptionType = '';
        QuotesWrapper.quoteRatePlanMap.put(testZquQuoteRatePlan.id,testZquQuoteRatePlan);
        OpportunityQuotesWrapper.quotesWrapperList.add(QuotesWrapper);
        OpportunityQuotesWrapper = LocalProductRules.runPrintEvaluation(OpportunityQuotesWrapper);
        
        testZquQuoteRatePlan.zqu__AmendmentType__c = 'New Product'; 
        update testZquQuoteRatePlan;
        
        List<zqu__QuoteRatePlan__c> qrpList = [SELECT Id, zqu__QuoteProductName__c, ZProduct_Name__c, zqu__ProductRatePlan__r.zqu__Product__r.zqu__SKU__c, zqu__Quote__r.zqu__InitialTerm__c, Name, zqu__AmendmentType__c, zqu__Quote__c, zqu__Quote__r.zqu__Opportunity__c, Location_Vendor__c, CannotBeSoldPast__c, NoAutomatedDiscount__c, RequiresApproval__c, RequiresPaidStorefront__c, MaximumSubscriptionTerm__c, MinimumSubscriptionTerm__c, Requires2X__c, Print_Issue__c, Print_Issue_Next_Issue_ID__c, Print_Issue_Previous_Issue_ID__c, Print_Issue_Step_2_Date__c, Print_Issue_Step_3_Date__c, AvoidDuplicates__c, 
                                                    (SELECT Id, Name, Product_Name__c, Print_Issue__c, Location_Vendor__c, Location_Vendor__r.Name, Market_ID__c, Category_Taxonomy_ID__c, zqu__QuoteRatePlan__c, zqu__QuoteRatePlan__r.zqu__AmendmentType__c, zqu__QuoteRatePlan__r.ZProduct_Name__c, Steelbrick_Calculated_Discount__c, zqu__Discount__c, Discount_Override__c FROM zqu__Quote_Rate_Plan_Charges__r) 
                                                FROM zqu__QuoteRatePlan__c WHERE zqu__Quote__r.zqu__Opportunity__c = :testopportunity.Id];
        
        
        OpportunityQuotesWrapper = new LocalProductRules.OpportunityQuotesWrapper();
        QuotesWrapper = new LocalProductRules.QuotesWrapper();
        QuotesWrapper.quote = testQuote;
        QuotesWrapper.quoteProductLine = 'Print';
        QuotesWrapper.quoteSubscriptionType = '';
        
        for(zqu__QuoteRatePlan__c qrp: qrpList ){
            QuotesWrapper.quoteRatePlanMap.put(qrp.id,qrp);
        }
        OpportunityQuotesWrapper.quotesWrapperList.add(QuotesWrapper);
        
        OpportunityQuotesWrapper = LocalProductRules.runPrintEvaluation(OpportunityQuotesWrapper);
        
        testProduct.CannotBeSoldPast__c = '3 Weeks Before Step 2 Date';
        update testProduct;
        
        qrpList = [SELECT Id, zqu__QuoteProductName__c, ZProduct_Name__c, zqu__ProductRatePlan__r.zqu__Product__r.zqu__SKU__c, zqu__Quote__r.zqu__InitialTerm__c, Name, zqu__AmendmentType__c, zqu__Quote__c, zqu__Quote__r.zqu__Opportunity__c, Location_Vendor__c, CannotBeSoldPast__c, NoAutomatedDiscount__c, RequiresApproval__c, RequiresPaidStorefront__c, MaximumSubscriptionTerm__c, MinimumSubscriptionTerm__c, Requires2X__c, Print_Issue__c, Print_Issue_Next_Issue_ID__c, Print_Issue_Previous_Issue_ID__c, Print_Issue_Step_2_Date__c, Print_Issue_Step_3_Date__c, AvoidDuplicates__c, 
                                                    (SELECT Id, Name, Product_Name__c, Print_Issue__c, Location_Vendor__c, Location_Vendor__r.Name, Market_ID__c, Category_Taxonomy_ID__c, zqu__QuoteRatePlan__c, zqu__QuoteRatePlan__r.zqu__AmendmentType__c, zqu__QuoteRatePlan__r.ZProduct_Name__c, Steelbrick_Calculated_Discount__c, zqu__Discount__c, Discount_Override__c FROM zqu__Quote_Rate_Plan_Charges__r) 
                                                FROM zqu__QuoteRatePlan__c WHERE zqu__Quote__r.zqu__Opportunity__c = :testopportunity.Id];
        
        
        OpportunityQuotesWrapper = new LocalProductRules.OpportunityQuotesWrapper();
        QuotesWrapper = new LocalProductRules.QuotesWrapper();
        QuotesWrapper.quote = testQuote;
        QuotesWrapper.quoteProductLine = 'Print';
        QuotesWrapper.quoteSubscriptionType = '';
        
        for(zqu__QuoteRatePlan__c qrp: qrpList ){
            QuotesWrapper.quoteRatePlanMap.put(qrp.id,qrp);
        }
        OpportunityQuotesWrapper.quotesWrapperList.add(QuotesWrapper);
        
        OpportunityQuotesWrapper = LocalProductRules.runPrintEvaluation(OpportunityQuotesWrapper);

    }

    /**
     *   Used to evaluate Internet
     *
     *   @author Nick
     *   @date   2017-02-04
     *   @return test method
     */
    @isTest static void test_runInternetEvaluation() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        // CSP-1999 Map<String,Schema.RecordTypeInfo> rtBrandMapByName = Schema.SObjectType.Brand__c.getRecordTypeInfosByName();
        
        Test.startTest();
        Map<String, SObject> testData =TestClassUtility.buildLocalData(false);
        Test.stopTest();
        TestClassUtility.generateQuotePdfConfig(true);


        Opportunity testOpportunity = (Opportunity)testData.get('Opportunity');
        Account testAccount = (Account)testData.get('Account');
        Contact testContact = (Contact)testData.get('Contact');
        Market__c testMarket = (Market__c)testData.get('Market__c');

        zqu__Quote__c testZquQuote =TestClassUtility.createQuote(true, 
                                                    testOpportunity, 
                                                    testAccount, 
                                                    testContact);

        
        
        Publication__c testPublication = new Publication__c();
        testPublication.name = 'testPublication';
        testPublication.Short_Name__c = 'test';
        insert testPublication;
        
        Edition__c testEdition = new Edition__c();
        testEdition.name = 'testEdition';
        testEdition.Publication__c = testPublication.id;
        insert testEdition;
        

        Print_Issue__c pi1 =new Print_Issue__c();
        pi1.name = 'test name';
        pi1.Edition__c = testEdition.id;
        pi1.Print_Market__c = testMarket.id;
        pi1.Selling_Start_Date__c = date.today();
        pi1.Publish_1st_Cover_Ship__c = date.today();
        insert pi1;
        
        Print_Issue__c pi2 =new Print_Issue__c();
        pi2.name = 'test name';
        pi2.Edition__c = testEdition.id;
        pi2.Print_Market__c = testMarket.id;
        pi2.Selling_Start_Date__c = date.today();
        pi2.Publish_1st_Cover_Ship__c = date.today();
        insert pi2;
        
        Print_Issue__c pi =new Print_Issue__c();
        pi.name = 'test name';
        pi.Previous_Issue__c = pi1.id;
        pi.Next_Issue__c = pi2.id;
        pi.Edition__c = testEdition.id;
        pi.Print_Market__c = testMarket.id;
        pi.Selling_Start_Date__c = date.today();
        pi.Publish_1st_Cover_Ship__c = date.today();
        pi.Step_2__c = date.today().adddays(-1);
        pi.Step_3__c = date.today().adddays(-1);
        insert pi;

         //Create Product
        Product2 testProduct = TestClassUtility.createLocalProduct2(false);
        testProduct.Requires_2X__c = 'Yes'; 
        testProduct.RequiresPaidStorefront__c = 'In Any Market/Category'; 
        insert testProduct;

        
        zqu__ProductRatePlan__c testZquProductRatePlan = new zqu__ProductRatePlan__c(); 
        testZquProductRatePlan.Name = 'Test Product Rate Plan'; 
        testZquProductRatePlan.zqu__Product__c = testProduct.id; 
        testZquProductRatePlan.Capacity__c = '10';
        testZquProductRatePlan.Market__c = 'Test Market';
        testZquProductRatePlan.Category__c = 'Test Category';
        testZquProductRatePlan.zqu__ZuoraId__c = '2c92c0f94e4d3a3d014e655c28c50f5f';  
        insert testZquProductRatePlan;
        
        zqu__ProductRatePlanCharge__c testZquProductRatePlanCharge = new zqu__ProductRatePlanCharge__c();
        testZquProductRatePlanCharge.Name = 'Test Prodcut Rate Plan Charge'; 
        testZquProductRatePlanCharge.zqu__DefaultQuantity__c = 0; 
        testZquProductRatePlanCharge.zqu__ListPrice__c = 200;
        testZquProductRatePlanCharge.zqu__Model__c = 'Flat Fee Pricing';
        testZquProductRatePlanCharge.zqu__ProductRatePlan__c = testZquProductRatePlan.id; 
        testZquProductRatePlanCharge.zqu__RecurringPeriod__c = 'Month'; 
        testZquProductRatePlanCharge.zqu__ZuoraId__c = '2c92c0f94e4d3a41014e655c389b63f7';
        insert testZquProductRatePlanCharge; 
        
        zqu__QuoteAmendment__c testZquQuoteAmendment = new zqu__QuoteAmendment__c();
        testZquQuoteAmendment.Name = 'Test Amendment'; 
        testZquQuoteAmendment.zqu__Quote__c = testZquQuote.id; 
        testZquQuoteAmendment.zqu__DeltaMRR__c = 0; 
        testZquQuoteAmendment.zqu__DeltaTCV__c = 200; 
        testZquQuoteAmendment.zqu__Description__c = 'Testing the amendment';  
        testZquQuoteAmendment.zqu__Status__c = 'Draft'; 
        testZquQuoteAmendment.zqu__TotalAmount__c = 200; 
        testZquQuoteAmendment.zqu__Type__c = 'NewProduct';
        insert testZquQuoteAmendment;
        
        zqu__QuoteRatePlan__c testZquQuoteRatePlan = new zqu__QuoteRatePlan__c();  
        testZquQuoteRatePlan.Name = 'Test Rate Plan';  
        testZquQuoteRatePlan.zqu__QuoteAmendment__c = testZquQuoteAmendment.id; 
        testZquQuoteRatePlan.zqu__AmendmentType__c = 'RemoveProduct';
        testZquQuoteRatePlan.zqu__ProductRatePlanZuoraId__c = '2c92c0f94e4d3a3d014e655c28c50f5f'; 
        testZquQuoteRatePlan.zqu__QuoteProductName__c = 'Featured Vendor'; 
        testZquQuoteRatePlan.zqu__Quote__c = testZquQuote.id; 
        testZquQuoteRatePlan.zqu__ProductRatePlan__c = testZquProductRatePlan.id; 
        testZquQuoteRatePlan.Print_Issue__c = pi.id;
        testZquQuoteRatePlan.Location_Vendor__c = testaccount.id;
        insert testZquQuoteRatePlan;
        
        zqu__QuoteRatePlanCharge__c testZquQuoteRatePlanCharge = new zqu__QuoteRatePlanCharge__c();
        testZquQuoteRatePlanCharge.Name = 'Test Quote Rate Plan Charge';  
        testZquQuoteRatePlanCharge.zqu__QuoteRatePlan__c = testZquQuoteRatePlan.id; 
        testZquQuoteRatePlanCharge.zqu__ProductRatePlanCharge__c = testZquProductRatePlanCharge.id;
        testZquQuoteRatePlanCharge.Location_Vendor__c = testaccount.id;
        testZquQuoteRatePlanCharge.Discount_Override__c = 10;
        testZquQuoteRatePlanCharge.Steelbrick_Calculated_Discount__c = 5;
        testZquQuoteRatePlanCharge.LocationVendorDynamicsAccountID__c = 'testAccount';
        insert testZquQuoteRatePlanCharge;
        
        RestrictedCategories__c testRestrictedCategories = new RestrictedCategories__c();
        testRestrictedCategories.name = 'SKU-00000044';
        testRestrictedCategories.Category_Taxonomy_Id__c = testZquQuoteRatePlanCharge.Category_Taxonomy_ID__c ;
        insert testRestrictedCategories;
        
        LocalProductRules.QuotesWrapper QuotesWrapper = new LocalProductRules.QuotesWrapper();
        LocalProductRules.OpportunityQuotesWrapper OpportunityQuotesWrapper = new LocalProductRules.OpportunityQuotesWrapper();
        
        QuotesWrapper.quote = testZquQuote;
        QuotesWrapper.quoteProductLine = 'Internet';
        QuotesWrapper.quoteSubscriptionType = 'Cancel Subscription';
        OpportunityQuotesWrapper.quotesWrapperList.add(QuotesWrapper);
        OpportunityQuotesWrapper = LocalProductRules.runInternetEvaluation(OpportunityQuotesWrapper);
        
        // Comment by CSP-2947 Salesforce 4.28
        // List<zqu__QuoteRatePlan__c> qrpList = [SELECT Id, zqu__QuoteProductName__c, ZProduct_Name__c, zqu__ProductRatePlan__r.zqu__Product__r.zqu__SKU__c, zqu__Quote__r.zqu__InitialTerm__c, Name, zqu__AmendmentType__c, zqu__Quote__c, zqu__Quote__r.zqu__Opportunity__c, Location_Vendor__c, CannotBeSoldPast__c, NoAutomatedDiscount__c, RequiresApproval__c, RequiresPaidStorefront__c, MaximumSubscriptionTerm__c, MinimumSubscriptionTerm__c, Requires2X__c, Print_Issue__c, Print_Issue_Next_Issue_ID__c, Print_Issue_Previous_Issue_ID__c, Print_Issue_Step_2_Date__c, Print_Issue_Step_3_Date__c, AvoidDuplicates__c, 
        //                                             (SELECT Id, Name, Product_Name__c, Print_Issue__c, Location_Vendor__c, Location_Vendor__r.Name, Market_ID__c, Category_Taxonomy_ID__c, zqu__QuoteRatePlan__c, zqu__QuoteRatePlan__r.zqu__AmendmentType__c, zqu__QuoteRatePlan__r.ZProduct_Name__c, Steelbrick_Calculated_Discount__c, zqu__Discount__c, Discount_Override__c, LocationVendorDynamicsAccountID__c FROM zqu__Quote_Rate_Plan_Charges__r) 
        //                                         FROM zqu__QuoteRatePlan__c WHERE zqu__Quote__r.zqu__Opportunity__c = :testopportunity.Id];
        
        
        // OpportunityQuotesWrapper = new LocalProductRules.OpportunityQuotesWrapper();
        // QuotesWrapper = new LocalProductRules.QuotesWrapper();
        // QuotesWrapper.quote = testZquQuote;
        // QuotesWrapper.quoteProductLine = 'Internet';
        // QuotesWrapper.quoteSubscriptionType = '';
        
        // for(zqu__QuoteRatePlan__c qrp: qrpList ){
        //     QuotesWrapper.quoteRatePlanMap.put(qrp.id,qrp);
        //     QuotesWrapper.quoteRatePlanChargeListMap.put(qrp.Id, qrp.zqu__Quote_Rate_Plan_Charges__r);
        // }
        
        // OpportunityQuotesWrapper.quotesWrapperList.add(QuotesWrapper);
        // OpportunityQuotesWrapper.opp = testopportunity;
        // OpportunityQuotesWrapper = LocalProductRules.runInternetEvaluation(OpportunityQuotesWrapper);
        
        // ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Inventory_Hold_Expiry_Date_Offsets__c invHoldExpDate = Inventory_Hold_Expiry_Date_Offsets__c.getOrgDefaults();
        // invHoldExpDate.Account_Day_Offset__c = 2;
        // upsert invHoldExpDate;
        
        // Zuora__Subscription__c testZquSubscription = new Zuora__Subscription__c();
        // testZquSubscription.Name = 'Test Subscription';
        // testZquSubscription.Zuora__SubscriptionStartDate__c = Date.Today();
        // testZquSubscription.Zuora__SubscriptionEndDate__c = Date.Today() + 365;
        // testZquSubscription.Zuora__TermEndDate__c = Date.Today() + 365;
        // testZquSubscription.Zuora__Status__c = 'Active';
        // testZquSubscription.Zuora__Account__c = testAccount.Id;
        // insert testZquSubscription;
        
        // Zuora__Product__c testZuoraProduct = new Zuora__Product__c();
        // testZuoraProduct.Zuora__Description__c = 'Test Product';
        // testZuoraProduct.Zuora__EffectiveEndDate__c = Date.Today();
        // testZuoraProduct.Zuora__External_Id__c = '123ed';
        // testZuoraProduct.ProductType__c = 'Internet';
        // testZuoraProduct.Zuora__SKU__c = 'SKU-00000044';
        // insert testZuoraProduct;
        
        // Zuora__SubscriptionProductCharge__c testZquSubscriptionProductCharge = new Zuora__SubscriptionProductCharge__c();
        // testZquSubscriptionProductCharge.Name = 'Test Subscription Product Charge';
        // testZquSubscriptionProductCharge.Zuora__EffectiveEndDate__c = Date.newinstance(2016, 1, 10);
        // testZquSubscriptionProductCharge.Zuora__Zuora_Id__c = 'zinrid12nd45oidl';
        // testZquSubscriptionProductCharge.Quote_Rate_Plan_ID__c = 'qweqweqwe';
        // testZquSubscriptionProductCharge.Zuora__RatePlanId__c = 'asdasdasdasdas';
        // testZquSubscriptionProductCharge.Zuora__Subscription__c = testZquSubscription.id;
        // testZquSubscriptionProductCharge.Zuora__ProductName__c = 'Test Product';
        // testZquSubscriptionProductCharge.Zuora__RatePlanName__c = 'Test Product Rate Plan';
        // testZquSubscriptionProductCharge.Zuora__Product__c = testZuoraProduct.id;
        // testZquSubscriptionProductCharge.Zuora__Account__c = testaccount.id;
        // insert testZquSubscriptionProductCharge;
        
        // Zuora__SubscriptionProductCharge__c testZquSubscriptionProductCharge1 = new Zuora__SubscriptionProductCharge__c();
        // testZquSubscriptionProductCharge1.Name = 'Test Subscription Product Charge';
        // testZquSubscriptionProductCharge1.Zuora__EffectiveEndDate__c = Date.newinstance(2016, 1, 10);
        // testZquSubscriptionProductCharge1.Zuora__Zuora_Id__c = 'zinrid12nd45oidl';
        // testZquSubscriptionProductCharge1.Quote_Rate_Plan_ID__c = 'qweqweqwe';
        // testZquSubscriptionProductCharge1.Zuora__RatePlanId__c = 'asdasdasdasdas';
        // testZquSubscriptionProductCharge1.Zuora__Subscription__c = testZquSubscription.id;
        // testZquSubscriptionProductCharge1.Zuora__ProductName__c = 'Test Product';
        // testZquSubscriptionProductCharge1.Zuora__RatePlanName__c = 'Test Product Rate Plan';
        // testZquSubscriptionProductCharge1.Zuora__Product__c = testZuoraProduct.id;
        // testZquSubscriptionProductCharge1.Zuora__Account__c = testaccount.id;
        // insert testZquSubscriptionProductCharge1;
        
        // testZquQuoteRatePlan.zqu__AmendmentType__c = 'New Product'; 
        // update testZquQuoteRatePlan;
        
        // qrpList = [SELECT Id, zqu__QuoteProductName__c, ZProduct_Name__c, zqu__ProductRatePlan__r.zqu__Product__r.zqu__SKU__c, zqu__Quote__r.zqu__InitialTerm__c, Name, zqu__AmendmentType__c, zqu__Quote__c, zqu__Quote__r.zqu__Opportunity__c, Location_Vendor__c, CannotBeSoldPast__c, NoAutomatedDiscount__c, RequiresApproval__c, RequiresPaidStorefront__c, MaximumSubscriptionTerm__c, MinimumSubscriptionTerm__c, Requires2X__c, Print_Issue__c, Print_Issue_Next_Issue_ID__c, Print_Issue_Previous_Issue_ID__c, Print_Issue_Step_2_Date__c, Print_Issue_Step_3_Date__c, AvoidDuplicates__c, 
        //                                             (SELECT Id, Name, Product_Name__c, Print_Issue__c, Location_Vendor__c, Location_Vendor__r.Name, Market_ID__c, Category_Taxonomy_ID__c, zqu__QuoteRatePlan__c, zqu__QuoteRatePlan__r.zqu__AmendmentType__c, zqu__QuoteRatePlan__r.ZProduct_Name__c, Steelbrick_Calculated_Discount__c, zqu__Discount__c, Discount_Override__c, LocationVendorDynamicsAccountID__c FROM zqu__Quote_Rate_Plan_Charges__r) 
        //                                         FROM zqu__QuoteRatePlan__c WHERE zqu__Quote__r.zqu__Opportunity__c = :testopportunity.Id];
        
        
        // OpportunityQuotesWrapper = new LocalProductRules.OpportunityQuotesWrapper();
        // QuotesWrapper = new LocalProductRules.QuotesWrapper();
        // QuotesWrapper.quote = testZquQuote;
        // QuotesWrapper.quoteProductLine = 'Internet';
        // QuotesWrapper.quoteSubscriptionType = 'New Subscription';
        
        // for(zqu__QuoteRatePlan__c qrp: qrpList ){
        //     QuotesWrapper.quoteRatePlanMap.put(qrp.id,qrp);
        //     QuotesWrapper.quoteRatePlanChargeListMap.put(qrp.Id, qrp.zqu__Quote_Rate_Plan_Charges__r);
        // }
        
        // OpportunityQuotesWrapper.quotesWrapperList.add(QuotesWrapper);
        // OpportunityQuotesWrapper.opp = testopportunity;        
        // OpportunityQuotesWrapper = LocalProductRules.runInternetEvaluation(OpportunityQuotesWrapper);
    }

    /**
     *   Used to evaluate the opporunity with internet quote and new subscription
     *
     *   @author Nick
     *   @date   2017-02-04
     *   @return test method
     */
    @isTest static void test_method_one() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        
        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        // CSP-1999 Map<String,Schema.RecordTypeInfo> rtBrandMapByName = Schema.SObjectType.Brand__c.getRecordTypeInfosByName();
        
        Test.startTest();
        Map<String, SObject> testData =TestClassUtility.buildLocalData(false);
        Test.stopTest();

        TestClassUtility.DISABLE_TRIGGERS = TRUE;
        TestClassUtility.generateQuotePdfConfig(true);


        Opportunity testOpportunity = (Opportunity)testData.get('Opportunity');
        Account testAccount = (Account)testData.get('Account');
        Contact testContact = (Contact)testData.get('Contact');
        Market__c testMarket = (Market__c)testData.get('Market__c');

        
        MetroArea__c ma = new MetroArea__c();
        ma.name = 'test';
        insert ma;

        //Create Product
        Product2 testProduct = TestClassUtility.createLocalProduct2(true);
        
        Zuora__Subscription__c testZquSubscription = new Zuora__Subscription__c();
        testZquSubscription.Name = 'Test Subscription';
        testZquSubscription.Zuora__SubscriptionStartDate__c = Date.Today();
        testZquSubscription.Zuora__SubscriptionEndDate__c = Date.Today() + 365;
        testZquSubscription.Zuora__Status__c = 'Active';
        testZquSubscription.Zuora__Account__c = testAccount.Id;
        insert testZquSubscription;
        
        Zuora__Product__c testZuoraProduct = new Zuora__Product__c();
        testZuoraProduct.Zuora__Description__c = 'Test Product';
        testZuoraProduct.Zuora__EffectiveEndDate__c = Date.Today();
        testZuoraProduct.Zuora__External_Id__c = '123ed';
        testZuoraProduct.ProductType__c = 'Internet';
        testZuoraProduct.Zuora__SKU__c = 'SKU-00000044';
        insert testZuoraProduct;
        
        
        Zuora__SubscriptionProductCharge__c testZquSubscriptionProductCharge = new Zuora__SubscriptionProductCharge__c();
        testZquSubscriptionProductCharge.Name = 'Test Subscription Product Charge';
        testZquSubscriptionProductCharge.Zuora__EffectiveEndDate__c = Date.newinstance(2015, 9, 10);
        testZquSubscriptionProductCharge.Zuora__Zuora_Id__c = 'zinrid12nd45oidl';
        testZquSubscriptionProductCharge.Quote_Rate_Plan_ID__c = 'qweqweqwe';
        testZquSubscriptionProductCharge.Zuora__RatePlanId__c = 'asdasdasdasdas';
        testZquSubscriptionProductCharge.Zuora__Subscription__c = testZquSubscription.id;
        testZquSubscriptionProductCharge.Zuora__ProductName__c = 'Test Product';
        testZquSubscriptionProductCharge.Zuora__RatePlanName__c = 'Test Product Rate Plan';
        testZquSubscriptionProductCharge.Zuora__Product__c = testZuoraProduct.id;
        testZquSubscriptionProductCharge.Zuora__Account__c = testaccount.id;
        insert testZquSubscriptionProductCharge;
        
        
        
        zqu__Quote__c testZquQuote = new zqu__Quote__c();
        testZquQuote.Name = 'Test Quote';
        testZquQuote.zqu__Status__c = 'New';
        testZquQuote.zqu__Account__c = testAccount.id;
        testZquQuote.zqu__BillToContact__c = testContact.Id;
        testZquQuote.zqu__Opportunity__c = testOpportunity.Id;
        testZquQuote.Zqu__ValidUntil__c = Date.Today()-1;    
        testZquQuote.zqu__InitialTerm__c= 2;  
        testZquQuote.zqu__SubscriptionType__c = 'Cancel Subscription';
        testZquQuote.Product_Line__c  = 'Print';  
        insert testZquQuote;
        
        zqu__ProductRatePlan__c testZquProductRatePlan = new zqu__ProductRatePlan__c(); 
        testZquProductRatePlan.Name = 'Test Product Rate Plan'; 
        testZquProductRatePlan.zqu__Product__c = testProduct.id; 
        testZquProductRatePlan.Capacity__c = '10';
        testZquProductRatePlan.Market__c = 'Test Market';
        testZquProductRatePlan.Category__c = 'Test Category';
        testZquProductRatePlan.zqu__ZuoraId__c = '2c92c0f94e4d3a3d014e655c28c50f5f';  
        insert testZquProductRatePlan;
        
        zqu__ProductRatePlanCharge__c testZquProductRatePlanCharge = new zqu__ProductRatePlanCharge__c();
        testZquProductRatePlanCharge.Name = 'Test Prodcut Rate Plan Charge'; 
        testZquProductRatePlanCharge.zqu__DefaultQuantity__c = 0; 
        testZquProductRatePlanCharge.zqu__ListPrice__c = 200;
        testZquProductRatePlanCharge.zqu__Model__c = 'Flat Fee Pricing';
        testZquProductRatePlanCharge.zqu__ProductRatePlan__c = testZquProductRatePlan.id; 
        testZquProductRatePlanCharge.zqu__RecurringPeriod__c = 'Month'; 
        testZquProductRatePlanCharge.zqu__ZuoraId__c = '2c92c0f94e4d3a41014e655c389b63f7';
        insert testZquProductRatePlanCharge; 
        
        zqu__QuoteAmendment__c testZquQuoteAmendment = new zqu__QuoteAmendment__c();
        testZquQuoteAmendment.Name = 'Test Amendment'; 
        testZquQuoteAmendment.zqu__Quote__c = testZquQuote.id; 
        testZquQuoteAmendment.zqu__DeltaMRR__c = 0; 
        testZquQuoteAmendment.zqu__DeltaTCV__c = 200; 
        testZquQuoteAmendment.zqu__Description__c = 'Testing the amendment';  
        testZquQuoteAmendment.zqu__Status__c = 'Draft'; 
        testZquQuoteAmendment.zqu__TotalAmount__c = 200; 
        testZquQuoteAmendment.zqu__Type__c = 'NewProduct';
        insert testZquQuoteAmendment;
        
        Publication__c testPublication = new Publication__c();
        testPublication.name = 'testPublication';
        testPublication.Short_Name__c = 'test';
        insert testPublication;
        
        
        Edition__c testEdition = new Edition__c();
        testEdition.name = 'testEdition';
        testEdition.Publication__c = testPublication.id;
        insert testEdition;
        

        Print_Issue__c pi1 =new Print_Issue__c();
        pi1.name = 'test name';
        pi1.Edition__c = testEdition.id;
        pi1.Print_Market__c = testMarket.id;
        pi1.Selling_Start_Date__c = date.today();
        pi1.Publish_1st_Cover_Ship__c = date.today();
        insert pi1;
        
        Print_Issue__c pi2 =new Print_Issue__c();
        pi2.name = 'test name';
        pi2.Edition__c = testEdition.id;
        pi2.Print_Market__c = testMarket.id;
        pi2.Selling_Start_Date__c = date.today();
        pi2.Publish_1st_Cover_Ship__c = date.today();
        insert pi2;
        
        Print_Issue__c pi =new Print_Issue__c();
        pi.name = 'test name';
        pi.Previous_Issue__c = pi1.id;
        pi.Next_Issue__c = pi2.id;
        pi.Edition__c = testEdition.id;
        pi.Print_Market__c = testMarket.id;
        pi.Selling_Start_Date__c = date.today();
        pi.Publish_1st_Cover_Ship__c = date.today();
        pi.Step_2__c = date.today().adddays(-1);
        pi.Step_3__c = date.today().adddays(-1);
        insert pi;
        
        zqu__QuoteRatePlan__c testZquQuoteRatePlan = new zqu__QuoteRatePlan__c();  
        testZquQuoteRatePlan.Name = 'Test Rate Plan';  
        testZquQuoteRatePlan.zqu__QuoteAmendment__c = testZquQuoteAmendment.id; 
        testZquQuoteRatePlan.zqu__AmendmentType__c = 'RemoveProduct'; 
        testZquQuoteRatePlan.zqu__ProductRatePlanZuoraId__c = '2c92c0f94e4d3a3d014e655c28c50f5f'; 
        testZquQuoteRatePlan.zqu__QuoteProductName__c = 'Storefront Vendor'; 
        testZquQuoteRatePlan.zqu__Quote__c = testZquQuote.id; 
        testZquQuoteRatePlan.zqu__ProductRatePlan__c = testZquProductRatePlan.id; 
        testZquQuoteRatePlan.Print_Issue__c = pi.id;
        testZquQuoteRatePlan.Location_Vendor__c = testaccount.id;
        insert testZquQuoteRatePlan;
        
        zqu__QuoteRatePlanCharge__c testZquQuoteRatePlanCharge = new zqu__QuoteRatePlanCharge__c();
        testZquQuoteRatePlanCharge.Name = 'Test Quote Rate Plan Charge';  
        testZquQuoteRatePlanCharge.zqu__QuoteRatePlan__c = testZquQuoteRatePlan.id; 
        testZquQuoteRatePlanCharge.zqu__ProductRatePlanCharge__c = testZquProductRatePlanCharge.id;
        testZquQuoteRatePlanCharge.Location_Vendor__c = testaccount.id;
        testZquQuoteRatePlanCharge.Category_Taxonomy_ID__c = 'testCategoryTaxonomyID';
        testZquQuoteRatePlanCharge.LocationVendorDynamicsAccountID__c = 'testAccount';
        insert testZquQuoteRatePlanCharge;
        
        zqu__QuoteRatePlan__c testZquQuoteRatePlan1 = new zqu__QuoteRatePlan__c();  
        testZquQuoteRatePlan1.Name = 'Test Rate Plan';  
        testZquQuoteRatePlan1.zqu__QuoteAmendment__c = testZquQuoteAmendment.id; 
        testZquQuoteRatePlan1.zqu__AmendmentType__c = 'RemoveProduct'; 
        testZquQuoteRatePlan1.zqu__ProductRatePlanZuoraId__c = '2c92c0f94e4d3a3d014e655c28c50f5c'; 
        testZquQuoteRatePlan1.zqu__QuoteProductName__c = 'Storefront Vendor'; 
        testZquQuoteRatePlan1.zqu__Quote__c = testZquQuote.id; 
        testZquQuoteRatePlan1.zqu__ProductRatePlan__c = testZquProductRatePlan.id; 
        testZquQuoteRatePlan1.Print_Issue__c = pi.id;
        testZquQuoteRatePlan1.Location_Vendor__c = testaccount.id;
        insert testZquQuoteRatePlan1;
        
        zqu__QuoteRatePlanCharge__c testZquQuoteRatePlanCharge1 = new zqu__QuoteRatePlanCharge__c();
        testZquQuoteRatePlanCharge1.Name = 'Test Quote Rate Plan Charge';  
        testZquQuoteRatePlanCharge1.zqu__QuoteRatePlan__c = testZquQuoteRatePlan1.id; 
        testZquQuoteRatePlanCharge1.zqu__ProductRatePlanCharge__c = testZquProductRatePlanCharge.id;
        testZquQuoteRatePlanCharge1.Location_Vendor__c = testaccount.id;
        testZquQuoteRatePlanCharge1.Category_Taxonomy_ID__c = 'testCategoryTaxonomyID';
        testZquQuoteRatePlanCharge1.LocationVendorDynamicsAccountID__c = 'testAccount';
        insert testZquQuoteRatePlanCharge1;
        
        testZquQuoteRatePlan.zqu__AmendmentType__c = 'New Product'; 
        update testZquQuoteRatePlan;

        testZquQuote.Product_Line__c = 'Internet';  
        testZquQuote.zqu__SubscriptionType__c = 'New Subscription';
        update testZquQuote;

        testProduct.CannotBeSoldPast__c = 'Step 3 Date';
        testProduct.AvoidDuplicates__c = 'In Same Market/Category';
        testProduct.RequiresPaidStorefront__c = 'In Same Market/Category';
        update testProduct;

        Opportunity opp = [SELECT Id, AccountId, Account.DynamicsAccID__c, Approval_Process_Flag_Manager_Approval__c, Approval_Process_Flag_Autoreject__c, 
                                Approval_Process_Info_For_Approver__c, (SELECT Id, zqu__SubscriptionType__c, zqu__InitialTerm__c, Product_Line__c, Approval_Process_Flag_Discount_Amount__c FROM zqu__Quotes__r) 
                                FROM Opportunity WHERE Id = :testOpportunity.id LIMIT 1];
        List<zqu__QuoteRatePlan__c> qrpList = [SELECT Id, zqu__QuoteProductName__c, ZProduct_Name__c, zqu__Quote__r.zqu__InitialTerm__c, Name, zqu__AmendmentType__c, 
                                                    zqu__Quote__c, zqu__Quote__r.zqu__Opportunity__c, Location_Vendor__c, CannotBeSoldPast__c, NoAutomatedDiscount__c, RequiresApproval__c, 
                                                    RequiresPaidStorefront__c, MaximumSubscriptionTerm__c, MinimumSubscriptionTerm__c, Requires2X__c, Print_Issue__c, Print_Issue_Next_Issue_ID__c, 
                                                    Print_Issue_Previous_Issue_ID__c, Print_Issue_Step_2_Date__c, Print_Issue_Step_3_Date__c, AvoidDuplicates__c, zqu__ProductRatePlan__r.zqu__Product__r.zqu__SKU__c,
                                                    (SELECT Id, Name, Product_Name__c, Print_Issue__c, Location_Vendor__c, Location_Vendor__r.Name, Market_ID__c, Category_Taxonomy_ID__c, 
                                                                zqu__QuoteRatePlan__c, zqu__QuoteRatePlan__r.zqu__AmendmentType__c, zqu__QuoteRatePlan__r.ZProduct_Name__c, 
                                                                Steelbrick_Calculated_Discount__c, zqu__Discount__c, Discount_Override__c, LocationVendorDynamicsAccountID__c FROM zqu__Quote_Rate_Plan_Charges__r) 
                                                    FROM zqu__QuoteRatePlan__c WHERE zqu__Quote__r.zqu__Opportunity__c = :testOpportunity.Id];

        RestrictedCategories__c testRestrictedCategories = new RestrictedCategories__c();
        testRestrictedCategories.name = 'SKU-00000044';
        testRestrictedCategories.Category_Taxonomy_Id__c = testZquQuoteRatePlanCharge.Category_Taxonomy_ID__c ;
        insert testRestrictedCategories;
        
        
        LocalProductRules.OpportunityQuotesWrapper OpportunityQuotesWrapper = new LocalProductRules.OpportunityQuotesWrapper();
        OpportunityQuotesWrapper = LocalProductRules.generateOpportunityQuotesWrapper(opp, qrpList);
        OpportunityQuotesWrapper = LocalProductRules.runInternetEvaluation(OpportunityQuotesWrapper);
        
        
        testProduct.AvoidDuplicates__c = 'In Same Market/Category';
        testProduct.RequiresPaidStorefront__c = 'In Same Market/Category';
        update testProduct;
        qrpList = [SELECT Id, zqu__QuoteProductName__c, ZProduct_Name__c, zqu__Quote__r.zqu__InitialTerm__c, Name, zqu__AmendmentType__c, 
                                                    zqu__Quote__c, zqu__Quote__r.zqu__Opportunity__c, Location_Vendor__c, CannotBeSoldPast__c, NoAutomatedDiscount__c, RequiresApproval__c, 
                                                    RequiresPaidStorefront__c, MaximumSubscriptionTerm__c, MinimumSubscriptionTerm__c, Requires2X__c, Print_Issue__c, Print_Issue_Next_Issue_ID__c, 
                                                    Print_Issue_Previous_Issue_ID__c, Print_Issue_Step_2_Date__c, Print_Issue_Step_3_Date__c, AvoidDuplicates__c, zqu__ProductRatePlan__r.zqu__Product__r.zqu__SKU__c,
                                                    (SELECT Id, Name, Product_Name__c, Print_Issue__c, Location_Vendor__c, Location_Vendor__r.Name, Market_ID__c, Category_Taxonomy_ID__c, 
                                                                zqu__QuoteRatePlan__c, zqu__QuoteRatePlan__r.zqu__AmendmentType__c, zqu__QuoteRatePlan__r.ZProduct_Name__c, 
                                                                Steelbrick_Calculated_Discount__c, zqu__Discount__c, Discount_Override__c, LocationVendorDynamicsAccountID__c FROM zqu__Quote_Rate_Plan_Charges__r) 
                                                    FROM zqu__QuoteRatePlan__c WHERE zqu__Quote__r.zqu__Opportunity__c = :testOpportunity.Id];
        OpportunityQuotesWrapper = LocalProductRules.generateOpportunityQuotesWrapper(opp, qrpList);
        OpportunityQuotesWrapper = LocalProductRules.runInternetEvaluation(OpportunityQuotesWrapper);
        TestClassUtility.DISABLE_TRIGGERS = FALSE;
        
        List<zqu__QuoteRatePlan__c> quoteSpecificQRPList = new List<zqu__QuoteRatePlan__c>();
        LocalProductRules.TwoXWrapper TwoXWrapper = new LocalProductRules.TwoXWrapper(testZquQuoteRatePlan);
        LocalProductRules.TwoXWrapper TwoXWrapper1 = new LocalProductRules.TwoXWrapper(testZquQuoteRatePlan);
        list<LocalProductRules.TwoXWrapper> TwoXWrapperlist = new list<LocalProductRules.TwoXWrapper>();
        Map<String, List<LocalProductRules.TwoXWrapper>> mainMap = new Map<String, List<LocalProductRules.TwoXWrapper>>();

    
        TwoXWrapperlist.clear();
        mainMap.clear();
        TwoXWrapperlist.add(TwoXWrapper);
        mainMap.put('test',TwoXWrapperlist);
        quoteSpecificQRPList = LocalProductRules.evaluateTwoXProductsAndReturnQRPWarningList(mainMap );
        
        TwoXWrapperlist.clear();
        mainMap.clear();
        TwoXWrapper.previousWrapperKey = 'test1';
        TwoXWrapperlist.add(TwoXWrapper);
        mainMap.put('test',TwoXWrapperlist);
        mainMap.put('test1',TwoXWrapperlist);
        quoteSpecificQRPList = LocalProductRules.evaluateTwoXProductsAndReturnQRPWarningList(mainMap );
        
        TwoXWrapperlist.clear();
        mainMap.clear();
        TwoXWrapper.nextWrapperKey = 'test1';
        TwoXWrapper.previousWrapperKey = 'test2';
        TwoXWrapperlist.add(TwoXWrapper);
        mainMap.put('test',TwoXWrapperlist);
        mainMap.put('test1',TwoXWrapperlist);
        quoteSpecificQRPList = LocalProductRules.evaluateTwoXProductsAndReturnQRPWarningList(mainMap );
        
        TwoXWrapperlist.clear();
        mainMap.clear();
        TwoXWrapper.nextWrapperKey = 'test1';
        TwoXWrapper.previousWrapperKey = 'test1';
        TwoXWrapperlist.add(TwoXWrapper);
        mainMap.put('test',TwoXWrapperlist);
        mainMap.put('test1',TwoXWrapperlist);
        quoteSpecificQRPList = LocalProductRules.evaluateTwoXProductsAndReturnQRPWarningList(mainMap );
        
        TwoXWrapperlist.clear();
        mainMap.clear();
        TwoXWrapper.nextWrapperKey = 'test1';
        TwoXWrapper.previousWrapperKey = 'test1';
        
        TwoXWrapper1.nextWrapperKey = 'test1';
        TwoXWrapper1.previousWrapperKey = 'test1';
        TwoXWrapperlist.add(TwoXWrapper);
        mainMap.put('test',TwoXWrapperlist);
        TwoXWrapperlist.add(TwoXWrapper1);
        mainMap.put('test1',TwoXWrapperlist);
        quoteSpecificQRPList = LocalProductRules.evaluateTwoXProductsAndReturnQRPWarningList(mainMap );
        
    }
    
    ////////////////////////////////////////////////////////////////////////////////////
    @isTest static void test_method_two() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        
        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        // CSP-1999 Map<String,Schema.RecordTypeInfo> rtBrandMapByName = Schema.SObjectType.Brand__c.getRecordTypeInfosByName();
        
        Test.startTest();
        Map<String, SObject> testData =TestClassUtility.buildLocalData(false);
        Test.stopTest();

        TestClassUtility.DISABLE_TRIGGERS = TRUE;
        TestClassUtility.generateQuotePdfConfig(true);


        Opportunity testOpportunity = (Opportunity)testData.get('Opportunity');
        Account testAccount = (Account)testData.get('Account');
        Contact testContact = (Contact)testData.get('Contact');
        Market__c testMarket = (Market__c)testData.get('Market__c');

        
        
        MetroArea__c ma = new MetroArea__c();
        ma.name = 'test';
        insert ma;
        
        //Create Product
        Product2 testProduct = TestClassUtility.createLocalProduct2(true);
        
        Zuora__Subscription__c testZquSubscription = new Zuora__Subscription__c();
        testZquSubscription.Name = 'Test Subscription';
        testZquSubscription.Zuora__SubscriptionStartDate__c = Date.Today();
        testZquSubscription.Zuora__SubscriptionEndDate__c = Date.Today() + 365;
        testZquSubscription.Zuora__Status__c = 'Active';
        testZquSubscription.Zuora__Account__c = testAccount.Id;
        insert testZquSubscription;
        
        Zuora__Product__c testZuoraProduct = new Zuora__Product__c();
        testZuoraProduct.Zuora__Description__c = 'Test Product';
        testZuoraProduct.Zuora__EffectiveEndDate__c = Date.Today();
        testZuoraProduct.Zuora__External_Id__c = '123ed';
        testZuoraProduct.ProductType__c = 'Internet';
        testZuoraProduct.Zuora__SKU__c = 'SKU-00000044';
        insert testZuoraProduct;
        
        
        Zuora__SubscriptionProductCharge__c testZquSubscriptionProductCharge = new Zuora__SubscriptionProductCharge__c();
        testZquSubscriptionProductCharge.Name = 'Test Subscription Product Charge';
        testZquSubscriptionProductCharge.Zuora__EffectiveEndDate__c = Date.newinstance(2015, 9, 10);
        testZquSubscriptionProductCharge.Zuora__Zuora_Id__c = 'zinrid12nd45oidl';
        testZquSubscriptionProductCharge.Quote_Rate_Plan_ID__c = 'qweqweqwe';
        testZquSubscriptionProductCharge.Zuora__RatePlanId__c = 'asdasdasdasdas';
        testZquSubscriptionProductCharge.Zuora__Subscription__c = testZquSubscription.id;
        testZquSubscriptionProductCharge.Zuora__ProductName__c = 'Test Product';
        testZquSubscriptionProductCharge.Zuora__RatePlanName__c = 'Test Product Rate Plan';
        testZquSubscriptionProductCharge.Zuora__Product__c = testZuoraProduct.id;
        testZquSubscriptionProductCharge.Zuora__Account__c = testaccount.id;
        insert testZquSubscriptionProductCharge;
        
        zqu__Quote__c testZquQuote = new zqu__Quote__c();
        testZquQuote.Name = 'Test Quote';
        testZquQuote.zqu__Status__c = 'New';
        testZquQuote.zqu__Account__c = testAccount.id;
        testZquQuote.zqu__BillToContact__c = testContact.Id;
        testZquQuote.zqu__Opportunity__c = testOpportunity.Id;
        testZquQuote.Zqu__ValidUntil__c = Date.Today()-1;    
        testZquQuote.zqu__InitialTerm__c= 2;  
        testZquQuote.zqu__SubscriptionType__c = 'Cancel Subscription';
        testZquQuote.Product_Line__c  = 'Print';  
        insert testZquQuote;
        
        zqu__ProductRatePlan__c testZquProductRatePlan = new zqu__ProductRatePlan__c(); 
        testZquProductRatePlan.Name = 'Test Product Rate Plan'; 
        testZquProductRatePlan.zqu__Product__c = testProduct.id; 
        testZquProductRatePlan.Capacity__c = '10';
        testZquProductRatePlan.Market__c = 'Test Market';
        testZquProductRatePlan.Category__c = 'Test Category';
        testZquProductRatePlan.zqu__ZuoraId__c = '2c92c0f94e4d3a3d014e655c28c50f5f';  
        insert testZquProductRatePlan;
        
        zqu__ProductRatePlanCharge__c testZquProductRatePlanCharge = new zqu__ProductRatePlanCharge__c();
        testZquProductRatePlanCharge.Name = 'Test Prodcut Rate Plan Charge'; 
        testZquProductRatePlanCharge.zqu__DefaultQuantity__c = 0; 
        testZquProductRatePlanCharge.zqu__ListPrice__c = 200;
        testZquProductRatePlanCharge.zqu__Model__c = 'Flat Fee Pricing';
        testZquProductRatePlanCharge.zqu__ProductRatePlan__c = testZquProductRatePlan.id; 
        testZquProductRatePlanCharge.zqu__RecurringPeriod__c = 'Month'; 
        testZquProductRatePlanCharge.zqu__ZuoraId__c = '2c92c0f94e4d3a41014e655c389b63f7';
        insert testZquProductRatePlanCharge; 
        
        zqu__QuoteAmendment__c testZquQuoteAmendment = new zqu__QuoteAmendment__c();
        testZquQuoteAmendment.Name = 'Test Amendment'; 
        testZquQuoteAmendment.zqu__Quote__c = testZquQuote.id; 
        testZquQuoteAmendment.zqu__DeltaMRR__c = 0; 
        testZquQuoteAmendment.zqu__DeltaTCV__c = 200; 
        testZquQuoteAmendment.zqu__Description__c = 'Testing the amendment';  
        testZquQuoteAmendment.zqu__Status__c = 'Draft'; 
        testZquQuoteAmendment.zqu__TotalAmount__c = 200; 
        testZquQuoteAmendment.zqu__Type__c = 'NewProduct';
        insert testZquQuoteAmendment;
        
        Publication__c testPublication = new Publication__c();
        testPublication.name = 'testPublication';
        testPublication.Short_Name__c = 'test';
        insert testPublication;
        
        
        Edition__c testEdition = new Edition__c();
        testEdition.name = 'testEdition';
        testEdition.Publication__c = testPublication.id;
        insert testEdition;
        

        Print_Issue__c pi1 =new Print_Issue__c();
        pi1.name = 'test name';
        pi1.Edition__c = testEdition.id;
        pi1.Print_Market__c = testMarket.id;
        pi1.Selling_Start_Date__c = date.today();
        pi1.Publish_1st_Cover_Ship__c = date.today();
        insert pi1;
        
        Print_Issue__c pi2 =new Print_Issue__c();
        pi2.name = 'test name';
        pi2.Edition__c = testEdition.id;
        pi2.Print_Market__c = testMarket.id;
        pi2.Selling_Start_Date__c = date.today();
        pi2.Publish_1st_Cover_Ship__c = date.today();
        insert pi2;
        
        Print_Issue__c pi =new Print_Issue__c();
        pi.name = 'test name';
        pi.Previous_Issue__c = pi1.id;
        pi.Next_Issue__c = pi2.id;
        pi.Edition__c = testEdition.id;
        pi.Print_Market__c = testMarket.id;
        pi.Selling_Start_Date__c = date.today();
        pi.Publish_1st_Cover_Ship__c = date.today();
        pi.Step_2__c = date.today().adddays(-1);
        pi.Step_3__c = date.today().adddays(-1);
        insert pi;
        
        zqu__QuoteRatePlan__c testZquQuoteRatePlan = new zqu__QuoteRatePlan__c();  
        testZquQuoteRatePlan.Name = 'Test Rate Plan';  
        testZquQuoteRatePlan.zqu__QuoteAmendment__c = testZquQuoteAmendment.id; 
        testZquQuoteRatePlan.zqu__AmendmentType__c = 'RemoveProduct'; 
        testZquQuoteRatePlan.zqu__ProductRatePlanZuoraId__c = '2c92c0f94e4d3a3d014e655c28c50f5f'; 
        testZquQuoteRatePlan.zqu__QuoteProductName__c = 'Storefront Vendor'; 
        testZquQuoteRatePlan.zqu__Quote__c = testZquQuote.id; 
        testZquQuoteRatePlan.zqu__ProductRatePlan__c = testZquProductRatePlan.id; 
        testZquQuoteRatePlan.Print_Issue__c = pi.id;
        testZquQuoteRatePlan.Location_Vendor__c = testaccount.id;
        insert testZquQuoteRatePlan;
        
        zqu__QuoteRatePlanCharge__c testZquQuoteRatePlanCharge = new zqu__QuoteRatePlanCharge__c();
        testZquQuoteRatePlanCharge.Name = 'Test Quote Rate Plan Charge';  
        testZquQuoteRatePlanCharge.zqu__QuoteRatePlan__c = testZquQuoteRatePlan.id; 
        testZquQuoteRatePlanCharge.zqu__ProductRatePlanCharge__c = testZquProductRatePlanCharge.id;
        testZquQuoteRatePlanCharge.Location_Vendor__c = testaccount.id;
        testZquQuoteRatePlanCharge.Category_Taxonomy_ID__c = 'testCategoryTaxonomyID';
        testZquQuoteRatePlanCharge.LocationVendorDynamicsAccountID__c = 'testAccount';
        insert testZquQuoteRatePlanCharge;
        
        zqu__QuoteRatePlan__c testZquQuoteRatePlan1 = new zqu__QuoteRatePlan__c();  
        testZquQuoteRatePlan1.Name = 'Test Rate Plan';  
        testZquQuoteRatePlan1.zqu__QuoteAmendment__c = testZquQuoteAmendment.id; 
        testZquQuoteRatePlan1.zqu__AmendmentType__c = 'RemoveProduct'; 
        testZquQuoteRatePlan1.zqu__ProductRatePlanZuoraId__c = '2c92c0f94e4d3a3d014e655c28c50f5c'; 
        testZquQuoteRatePlan1.zqu__QuoteProductName__c = 'Storefront Vendor'; 
        testZquQuoteRatePlan1.zqu__Quote__c = testZquQuote.id; 
        testZquQuoteRatePlan1.zqu__ProductRatePlan__c = testZquProductRatePlan.id; 
        testZquQuoteRatePlan1.Print_Issue__c = pi.id;
        testZquQuoteRatePlan1.Location_Vendor__c = testaccount.id;
        insert testZquQuoteRatePlan1;
        
        zqu__QuoteRatePlanCharge__c testZquQuoteRatePlanCharge1 = new zqu__QuoteRatePlanCharge__c();
        testZquQuoteRatePlanCharge1.Name = 'Test Quote Rate Plan Charge';  
        testZquQuoteRatePlanCharge1.zqu__QuoteRatePlan__c = testZquQuoteRatePlan1.id; 
        testZquQuoteRatePlanCharge1.zqu__ProductRatePlanCharge__c = testZquProductRatePlanCharge.id;
        testZquQuoteRatePlanCharge1.Location_Vendor__c = testaccount.id;
        testZquQuoteRatePlanCharge1.Category_Taxonomy_ID__c = 'testCategoryTaxonomyID';
        testZquQuoteRatePlanCharge1.LocationVendorDynamicsAccountID__c = 'testAccount';
        insert testZquQuoteRatePlanCharge1;
        
        testProduct.CannotBeSoldPast__c = 'Step 3 Date';
        update testProduct;

        testZquQuote.Product_Line__c = 'Direct Mail';  
        testZquQuote.zqu__SubscriptionType__c = 'New Subscription';
        update testZquQuote;
        
        testZquQuoteRatePlan.zqu__AmendmentType__c = 'RemoveProduct'; 
        update testZquQuoteRatePlan;
        TestClassUtility.DISABLE_TRIGGERS = FALSE;
        
        opportunity opp = [SELECT Id, AccountId, Account.DynamicsAccID__c, Approval_Process_Flag_Manager_Approval__c, Approval_Process_Flag_Autoreject__c, 
                                Approval_Process_Info_For_Approver__c, (SELECT Id, zqu__SubscriptionType__c, zqu__InitialTerm__c, Product_Line__c, Approval_Process_Flag_Discount_Amount__c FROM zqu__Quotes__r) 
                                FROM Opportunity WHERE Id = :testOpportunity.id LIMIT 1];
        List<zqu__QuoteRatePlan__c> qrpList = [SELECT Id, zqu__QuoteProductName__c, ZProduct_Name__c, zqu__Quote__r.zqu__InitialTerm__c, Name, zqu__AmendmentType__c, 
                                                    zqu__Quote__c, zqu__Quote__r.zqu__Opportunity__c, Location_Vendor__c, CannotBeSoldPast__c, NoAutomatedDiscount__c, RequiresApproval__c, 
                                                    RequiresPaidStorefront__c, MaximumSubscriptionTerm__c, MinimumSubscriptionTerm__c, Requires2X__c, Print_Issue__c, Print_Issue_Next_Issue_ID__c, 
                                                    Print_Issue_Previous_Issue_ID__c, Print_Issue_Step_2_Date__c, Print_Issue_Step_3_Date__c, AvoidDuplicates__c, 
                                                    (SELECT Id, Name, Product_Name__c, Print_Issue__c, Location_Vendor__c, Location_Vendor__r.Name, Market_ID__c, Category_Taxonomy_ID__c, 
                                                                zqu__QuoteRatePlan__c, zqu__QuoteRatePlan__r.zqu__AmendmentType__c, zqu__QuoteRatePlan__r.ZProduct_Name__c, 
                                                                Steelbrick_Calculated_Discount__c, zqu__Discount__c, Discount_Override__c, LocationVendorDynamicsAccountID__c FROM zqu__Quote_Rate_Plan_Charges__r) 
                                                    FROM zqu__QuoteRatePlan__c WHERE zqu__Quote__r.zqu__Opportunity__c = :testOpportunity.Id];
        LocalProductRules.OpportunityQuotesWrapper OpportunityQuotesWrapper = new LocalProductRules.OpportunityQuotesWrapper();
        OpportunityQuotesWrapper = LocalProductRules.generateOpportunityQuotesWrapper(opp, qrpList);
        OpportunityQuotesWrapper = LocalProductRules.runLDEEvaluation(OpportunityQuotesWrapper);
        
        testZquQuoteRatePlan.zqu__AmendmentType__c = 'New Product'; 
        update testZquQuoteRatePlan;
        qrpList = [SELECT Id, zqu__QuoteProductName__c, ZProduct_Name__c, zqu__Quote__r.zqu__InitialTerm__c, Name, zqu__AmendmentType__c, 
                                                    zqu__Quote__c, zqu__Quote__r.zqu__Opportunity__c, Location_Vendor__c, CannotBeSoldPast__c, NoAutomatedDiscount__c, RequiresApproval__c, 
                                                    RequiresPaidStorefront__c, MaximumSubscriptionTerm__c, MinimumSubscriptionTerm__c, Requires2X__c, Print_Issue__c, Print_Issue_Next_Issue_ID__c, 
                                                    Print_Issue_Previous_Issue_ID__c, Print_Issue_Step_2_Date__c, Print_Issue_Step_3_Date__c, AvoidDuplicates__c, zqu__ProductRatePlan__r.zqu__Product__r.zqu__SKU__c,
                                                    (SELECT Id, Name, Product_Name__c, Print_Issue__c, Location_Vendor__c, Location_Vendor__r.Name, Market_ID__c, Category_Taxonomy_ID__c, 
                                                                zqu__QuoteRatePlan__c, zqu__QuoteRatePlan__r.zqu__AmendmentType__c, zqu__QuoteRatePlan__r.ZProduct_Name__c, 
                                                                Steelbrick_Calculated_Discount__c, zqu__Discount__c, Discount_Override__c, LocationVendorDynamicsAccountID__c FROM zqu__Quote_Rate_Plan_Charges__r) 
                                                    FROM zqu__QuoteRatePlan__c WHERE zqu__Quote__r.zqu__Opportunity__c = :testOpportunity.Id];

        OpportunityQuotesWrapper = LocalProductRules.generateOpportunityQuotesWrapper(opp, qrpList);
        OpportunityQuotesWrapper = LocalProductRules.runLDEEvaluation(OpportunityQuotesWrapper);
        
    }
}