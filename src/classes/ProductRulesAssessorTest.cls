@isTest
private class ProductRulesAssessorTest{

  /**
     *   Used to evaluate opportunity
     *
     *   @author Nick
     *   @date   2017-02-04
     *   @return test method
     */
  static testMethod void test_evaluateOpportunity() {
      
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

    zqu__Quote__c testZquQuote =TestClassUtility.createQuote(true, 
                                                testOpportunity, 
                                                testAccount, 
                                                testContact);


    MetroArea__c testMetroArea = new MetroArea__c();
    testMetroArea.name = 'test';
    insert testMetroArea;

    Product2 testProduct = TestClassUtility.createLocalProduct2(true);
    
    zqu__ProductRatePlan__c testZquProductRatePlan = new zqu__ProductRatePlan__c(); 
    testZquProductRatePlan.Name = 'Test Product Rate Plan'; 
    testZquProductRatePlan.zqu__Product__c = testProduct.id; 
    testZquProductRatePlan.Capacity__c = '10';
    testZquProductRatePlan.Market__c = 'Test Market';
    testZquProductRatePlan.Category__c = 'Test Category';
    testZquProductRatePlan.zqu__ZuoraId__c = '2c92c0f94e4d3a3d014e655c28c50f5f';  
    insert testZquProductRatePlan;
    
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
    testZquQuoteRatePlan.zqu__AmendmentType__c = 'New Product'; 
    testZquQuoteRatePlan.zqu__ProductRatePlanZuoraId__c = '2c92c0f94e4d3a3d014e655c28c50f5f'; 
    testZquQuoteRatePlan.zqu__QuoteProductName__c = 'Featured Vendor'; 
    testZquQuoteRatePlan.zqu__Quote__c = testZquQuote.id; 
    testZquQuoteRatePlan.zqu__ProductRatePlan__c = testZquProductRatePlan.id; 
    //testZquQuoteRatePlan.Print_Issue__c = pi.id;
    insert testZquQuoteRatePlan;
    
    
    ProductRulesAssessor.evaluateOpportunity(testOpportunity.id);
    
    testZquQuote.Product_Line__c  = 'Print'; 
    update testZquQuote;
    ProductRulesAssessor.evaluateOpportunity(testOpportunity.id);
    
    testZquQuote.Product_Line__c  = 'Direct Mail'; 
    update testZquQuote;
    ProductRulesAssessor.evaluateOpportunity(testOpportunity.id);
      
  }
    
  /**
     *   Used to evaluate print logic
     *
     *   @author Nick
     *   @date   2017-02-04
     *   @return test method
     */ 
  static testMethod void test_runPrintEvaluation() {
      
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


    MetroArea__c testMetroArea = new MetroArea__c();
    testMetroArea.name = 'test';
    insert testMetroArea;
    
    Product2 testProduct = TestClassUtility.createLocalProduct2(true);
    
    zqu__ProductRatePlan__c testZquProductRatePlan = new zqu__ProductRatePlan__c(); 
    testZquProductRatePlan.Name = 'Test Product Rate Plan'; 
    testZquProductRatePlan.zqu__Product__c = testProduct.id; 
    testZquProductRatePlan.Capacity__c = '10';
    testZquProductRatePlan.Market__c = 'Test Market';
    testZquProductRatePlan.Category__c = 'Test Category';
    testZquProductRatePlan.zqu__ZuoraId__c = '2c92c0f94e4d3a3d014e655c28c50f5f';  
    insert testZquProductRatePlan;
    
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
    testZquQuoteRatePlan.zqu__QuoteProductName__c = 'Featured Vendor'; 
    testZquQuoteRatePlan.zqu__Quote__c = testZquQuote.id; 
    testZquQuoteRatePlan.zqu__ProductRatePlan__c = testZquProductRatePlan.id; 
    testZquQuoteRatePlan.Print_Issue__c = pi.id;
    insert testZquQuoteRatePlan;
    
    zqu__QuoteRatePlan__c testZquQuoteRatePlan1 = new zqu__QuoteRatePlan__c();  
    testZquQuoteRatePlan1.Name = 'Test Rate Plan1';  
    testZquQuoteRatePlan1.zqu__QuoteAmendment__c = testZquQuoteAmendment.id; 
    testZquQuoteRatePlan1.zqu__AmendmentType__c = 'New Product'; 
    testZquQuoteRatePlan1.zqu__ProductRatePlanZuoraId__c = '2c92c0f94e4d3a3d014e655c28c50f5c'; 
    testZquQuoteRatePlan1.zqu__QuoteProductName__c = 'Featured Vendor'; 
    testZquQuoteRatePlan1.zqu__Quote__c = testZquQuote.id; 
    testZquQuoteRatePlan1.zqu__ProductRatePlan__c = testZquProductRatePlan.id; 
    testZquQuoteRatePlan1.Print_Issue__c = pi.id;
    insert testZquQuoteRatePlan1;        

    ProductRulesAssessor.QuotesWrapper QuotesWrapper = new ProductRulesAssessor.QuotesWrapper();
    ProductRulesAssessor.OpportunityQuotesWrapper  OpportunityQuotesWrapper = new ProductRulesAssessor.OpportunityQuotesWrapper();
    
    QuotesWrapper.quote = testZquQuote;
    QuotesWrapper.quoteSubscriptionType = 'Cancel Subscription';
    QuotesWrapper.quoteProductLine = 'Print';
    OpportunityQuotesWrapper.quotesWrapperList.add(QuotesWrapper);
    
    ProductRulesAssessor.runPrintEvaluation(OpportunityQuotesWrapper);
    ///////////////////
    
    QuotesWrapper = new ProductRulesAssessor.QuotesWrapper();
    OpportunityQuotesWrapper = new ProductRulesAssessor.OpportunityQuotesWrapper();
    
    QuotesWrapper.quote = testZquQuote;
    QuotesWrapper.quoteSubscriptionType = '';
    QuotesWrapper.quoteProductLine = 'Print';
    QuotesWrapper.quoteRatePlanMap.put(testZquQuoteRatePlan.id,testZquQuoteRatePlan);
    OpportunityQuotesWrapper.quotesWrapperList.add(QuotesWrapper);
    
    ProductRulesAssessor.runPrintEvaluation(OpportunityQuotesWrapper);
    ////////////////////////////////////////////////
    
    testZquQuoteRatePlan.zqu__AmendmentType__c = 'New Product';
    update testZquQuoteRatePlan;
    
    List<zqu__QuoteRatePlan__c> qrpList = [SELECT Id, zqu__QuoteProductName__c, Name, zqu__AmendmentType__c, 
                                                zqu__Quote__c, zqu__Quote__r.zqu__Opportunity__c, Location_Vendor__c, CannotBeSoldPast__c, NoAutomatedDiscount__c, RequiresApproval__c, 
                                                RequiresPaidStorefront__c, MaximumSubscriptionTerm__c, MinimumSubscriptionTerm__c, Requires2X__c, 
                                                Print_Issue__c, Print_Issue_Next_Issue_ID__c, Print_Issue_Previous_Issue_ID__c, Print_Issue_Step_2_Date__c, Print_Issue_Step_3_Date__c, 
                                                (SELECT Id, Name, Product_Name__c, Print_Issue__c, Location_Vendor__c, Steelbrick_Calculated_Discount__c, zqu__Discount__c, Discount_Override__c FROM zqu__Quote_Rate_Plan_Charges__r) 
                                                FROM zqu__QuoteRatePlan__c WHERE zqu__Quote__r.zqu__Opportunity__c = :testopportunity.Id];
    
    QuotesWrapper = new ProductRulesAssessor.QuotesWrapper();
    OpportunityQuotesWrapper = new ProductRulesAssessor.OpportunityQuotesWrapper();
    
    QuotesWrapper.quote = testZquQuote;
    QuotesWrapper.quoteSubscriptionType = '';
    QuotesWrapper.quoteProductLine = 'Print';
    QuotesWrapper.quoteRatePlanMap.put(qrpList[0].id,qrpList[0]);
    QuotesWrapper.quoteRatePlanMap.put(qrpList[1].id,qrpList[1]);
    OpportunityQuotesWrapper.quotesWrapperList.add(QuotesWrapper);
    
    ProductRulesAssessor.runPrintEvaluation(OpportunityQuotesWrapper);
    ////////////////////////////////////////////////
    
    testProduct.CannotBeSoldPast__c = '3 Weeks Before Step 2 Date';
    update testProduct;
    
    qrpList = [SELECT Id, zqu__QuoteProductName__c, Name, zqu__AmendmentType__c, 
                                                zqu__Quote__c, zqu__Quote__r.zqu__Opportunity__c, Location_Vendor__c, CannotBeSoldPast__c, NoAutomatedDiscount__c, RequiresApproval__c, 
                                                RequiresPaidStorefront__c, MaximumSubscriptionTerm__c, MinimumSubscriptionTerm__c, Requires2X__c, 
                                                Print_Issue__c, Print_Issue_Next_Issue_ID__c, Print_Issue_Previous_Issue_ID__c, Print_Issue_Step_2_Date__c, Print_Issue_Step_3_Date__c, 
                                                (SELECT Id, Name, Product_Name__c, Print_Issue__c, Location_Vendor__c, Steelbrick_Calculated_Discount__c, zqu__Discount__c, Discount_Override__c FROM zqu__Quote_Rate_Plan_Charges__r) 
                                                FROM zqu__QuoteRatePlan__c WHERE zqu__Quote__r.zqu__Opportunity__c = :testopportunity.Id];
    
    QuotesWrapper = new ProductRulesAssessor.QuotesWrapper();
    OpportunityQuotesWrapper = new ProductRulesAssessor.OpportunityQuotesWrapper();
    
    QuotesWrapper.quote = testZquQuote;
    QuotesWrapper.quoteSubscriptionType = '';
    QuotesWrapper.quoteProductLine = 'Print';
    QuotesWrapper.quoteRatePlanMap.put(qrpList[0].id,qrpList[0]);
    OpportunityQuotesWrapper.quotesWrapperList.add(QuotesWrapper);
    
    ProductRulesAssessor.runPrintEvaluation(OpportunityQuotesWrapper);
    ////////////////////////////////////////////////
    
    testProduct.CannotBeSoldPast__c = 'Step 3 Date';
    update testProduct;
    
    qrpList = [SELECT Id, zqu__QuoteProductName__c, Name, zqu__AmendmentType__c, 
                                                zqu__Quote__c, zqu__Quote__r.zqu__Opportunity__c, Location_Vendor__c, CannotBeSoldPast__c, NoAutomatedDiscount__c, RequiresApproval__c, 
                                                RequiresPaidStorefront__c, MaximumSubscriptionTerm__c, MinimumSubscriptionTerm__c, Requires2X__c, 
                                                Print_Issue__c, Print_Issue_Next_Issue_ID__c, Print_Issue_Previous_Issue_ID__c, Print_Issue_Step_2_Date__c, Print_Issue_Step_3_Date__c, 
                                                (SELECT Id, Name, Product_Name__c, Print_Issue__c, Location_Vendor__c, Steelbrick_Calculated_Discount__c, zqu__Discount__c, Discount_Override__c FROM zqu__Quote_Rate_Plan_Charges__r) 
                                                FROM zqu__QuoteRatePlan__c WHERE zqu__Quote__r.zqu__Opportunity__c = :testopportunity.Id];
    
    QuotesWrapper = new ProductRulesAssessor.QuotesWrapper();
    OpportunityQuotesWrapper = new ProductRulesAssessor.OpportunityQuotesWrapper();
    
    QuotesWrapper.quote = testZquQuote;
    QuotesWrapper.quoteSubscriptionType = '';
    QuotesWrapper.quoteProductLine = 'Print';
    QuotesWrapper.quoteRatePlanMap.put(qrpList[0].id,qrpList[0]);
    OpportunityQuotesWrapper.quotesWrapperList.add(QuotesWrapper);
    
    ProductRulesAssessor.runPrintEvaluation(OpportunityQuotesWrapper);
      
  }
  
  /**
     *   Used to evaluate LDE logic
     *
     *   @author Nick
     *   @date   2017-02-04
     *   @return test method
     */ 
  static testMethod void test_runLDEEvaluation() {
      
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

    
    MetroArea__c testMetroArea = new MetroArea__c();
    testMetroArea.name = 'test';
    insert testMetroArea;
    
    Product2 testProduct = TestClassUtility.createLocalProduct2(true);
    
    zqu__ProductRatePlan__c testZquProductRatePlan = new zqu__ProductRatePlan__c(); 
    testZquProductRatePlan.Name = 'Test Product Rate Plan'; 
    testZquProductRatePlan.zqu__Product__c = testProduct.id; 
    testZquProductRatePlan.Capacity__c = '10';
    testZquProductRatePlan.Market__c = 'Test Market';
    testZquProductRatePlan.Category__c = 'Test Category';
    testZquProductRatePlan.zqu__ZuoraId__c = '2c92c0f94e4d3a3d014e655c28c50f5f';  
    insert testZquProductRatePlan;
    
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
    //testZquQuoteRatePlan.Print_Issue__c = pi.id;
    insert testZquQuoteRatePlan;   
    
    zqu__QuoteRatePlan__c testZquQuoteRatePlan1 = new zqu__QuoteRatePlan__c();  
    testZquQuoteRatePlan1.Name = 'Test Rate Plan1';  
    testZquQuoteRatePlan1.zqu__QuoteAmendment__c = testZquQuoteAmendment.id; 
    testZquQuoteRatePlan1.zqu__AmendmentType__c = 'New Product'; 
    testZquQuoteRatePlan1.zqu__ProductRatePlanZuoraId__c = '2c92c0f94e4d3a3d014e655c28c50f5c'; 
    testZquQuoteRatePlan1.zqu__QuoteProductName__c = 'Featured Vendor'; 
    testZquQuoteRatePlan1.zqu__Quote__c = testZquQuote.id; 
    testZquQuoteRatePlan1.zqu__ProductRatePlan__c = testZquProductRatePlan.id; 
    //testZquQuoteRatePlan1.Print_Issue__c = pi.id;
    insert testZquQuoteRatePlan1;      
    
    ProductRulesAssessor.QuotesWrapper QuotesWrapper = new ProductRulesAssessor.QuotesWrapper();
    ProductRulesAssessor.OpportunityQuotesWrapper  OpportunityQuotesWrapper = new ProductRulesAssessor.OpportunityQuotesWrapper();
    
    QuotesWrapper.quote = testZquQuote;
    QuotesWrapper.quoteSubscriptionType = 'Cancel Subscription';
    QuotesWrapper.quoteProductLine = 'Direct Mail';
    OpportunityQuotesWrapper.quotesWrapperList.add(QuotesWrapper);
    
    ProductRulesAssessor.runLDEEvaluation(OpportunityQuotesWrapper);
    ///////////////////
     List<zqu__QuoteRatePlan__c> qrpList = [SELECT Id, zqu__QuoteProductName__c, Name, zqu__AmendmentType__c, 
                                                zqu__Quote__c, zqu__Quote__r.zqu__Opportunity__c, Location_Vendor__c, CannotBeSoldPast__c, NoAutomatedDiscount__c, RequiresApproval__c, 
                                                RequiresPaidStorefront__c, MaximumSubscriptionTerm__c, MinimumSubscriptionTerm__c, Requires2X__c, 
                                                Print_Issue__c, Print_Issue_Next_Issue_ID__c, Print_Issue_Previous_Issue_ID__c, Print_Issue_Step_2_Date__c, Print_Issue_Step_3_Date__c, 
                                                (SELECT Id, Name, Product_Name__c, Print_Issue__c, Location_Vendor__c, Steelbrick_Calculated_Discount__c, zqu__Discount__c, Discount_Override__c FROM zqu__Quote_Rate_Plan_Charges__r) 
                                                FROM zqu__QuoteRatePlan__c WHERE zqu__Quote__r.zqu__Opportunity__c = :testopportunity.Id];
    
    
    QuotesWrapper = new ProductRulesAssessor.QuotesWrapper();
    OpportunityQuotesWrapper = new ProductRulesAssessor.OpportunityQuotesWrapper();
    
    QuotesWrapper.quote = testZquQuote;
    QuotesWrapper.quoteSubscriptionType = '';
    QuotesWrapper.quoteProductLine = 'Direct Mail';
    QuotesWrapper.quoteRatePlanMap.put(qrpList[0].id,qrpList[0]);
    QuotesWrapper.quoteRatePlanMap.put(qrpList[1].id,qrpList[1]);
    OpportunityQuotesWrapper.quotesWrapperList.add(QuotesWrapper);
    
    ProductRulesAssessor.runLDEEvaluation(OpportunityQuotesWrapper);

  }
}