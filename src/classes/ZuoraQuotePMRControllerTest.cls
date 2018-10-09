@isTest
public class ZuoraQuotePMRControllerTest {
    public static testMethod void testTheController1(){
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Test.startTest();
        Map<String, SObject> testData =TestClassUtility.buildLocalData(false);
        Test.stopTest();
        Account testAccount = (Account)testData.get('Account');
        Opportunity testOpportunity = (Opportunity)testData.get('Opportunity');
        Contact testContact = (Contact)testData.get('Contact');
        Market__c testMarket = (Market__c)testData.get('Market__c');
        Category__c testCategory = (Category__c)testData.get('Category__c');
        // CSP-1999 Brand__c testBrand = (Brand__c)testData.get('Brand__c');
        Zip__c testZip = (Zip__c)testData.get('Zip__c');

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
        
        zqu__Quote__c testZquQuote = new zqu__Quote__c();
        testZquQuote.Name = 'Test Quote';
        testZquQuote.zqu__Status__c = 'New';
        testZquQuote.zqu__Account__c = testAccount.id;
        testZquQuote.zqu__BillToContact__c = testContact.Id;
        testZquQuote.zqu__Opportunity__c = testOpportunity.Id;
        testZquQuote.Zqu__ValidUntil__c = Date.Today()-1;  
        testZquQuote.Preferred_Payment_Schedule__c = 'Quarter';   
        testZquQuote.zqu__InitialTerm__c = 3;  
        testZquQuote.zqu__StartDate__c = date.today().adddays(1);
        insert testZquQuote;
        
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
        
        Product2 testProduct = TestClassUtility.createLocalProduct2(true);
        
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
        testZquProductRatePlanCharge.zqu__Upto_How_Many_Periods__c = 1;
        insert testZquProductRatePlanCharge; 
        
        zqu__QuoteRatePlan__c testZquQuoteRatePlan = new zqu__QuoteRatePlan__c();  
        testZquQuoteRatePlan.Name = 'Test Rate Plan';  
        testZquQuoteRatePlan.zqu__QuoteAmendment__c = testZquQuoteAmendment.id; 
        testZquQuoteRatePlan.zqu__AmendmentType__c = 'New Product'; 
        testZquQuoteRatePlan.zqu__ProductRatePlanZuoraId__c = '2c92c0f94e4d3a3d014e655c28c50f5f'; 
        testZquQuoteRatePlan.zqu__QuoteProductName__c = 'Featured Vendor'; 
        testZquQuoteRatePlan.zqu__Quote__c = testZquQuote.id; 
        testZquQuoteRatePlan.zqu__ProductRatePlan__c = testZquProductRatePlan.id; 
        insert testZquQuoteRatePlan;
        
        zqu__QuoteRatePlanCharge__c testZquQuoteRatePlanCharge = new zqu__QuoteRatePlanCharge__c();
        testZquQuoteRatePlanCharge.Name = 'Test Quote Rate Plan Charge';  
        testZquQuoteRatePlanCharge.zqu__QuoteRatePlan__c = testZquQuoteRatePlan.id; 
        testZquQuoteRatePlanCharge.zqu__ProductRatePlanCharge__c = testZquProductRatePlanCharge.id;
        testZquQuoteRatePlanCharge.zqu__Total__c = 1;
        testZquQuoteRatePlanCharge.zqu__EffectivePrice__c = 20;
        testZquQuoteRatePlanCharge.zqu__EffectivePrice__c = 15;
        testZquQuoteRatePlanCharge.Product_Type__c = 'Print';
        testZquQuoteRatePlanCharge.Print_Issue__c = pi.id;
        testZquQuoteRatePlanCharge.zqu__ChargeType__c = 'Recurring';
        testZquQuoteRatePlanCharge.List_Price__c = '12';
        testZquQuoteRatePlanCharge.zqu__Period__c = 'Quarter';
        testZquQuoteRatePlanCharge.zqu__Discount__c = 31;
        testZquQuoteRatePlanCharge.Number_of_Charges__c = 3;
        testZquQuoteRatePlanCharge.Discount_Override__c = 1;
        insert testZquQuoteRatePlanCharge;
        
        zqu__QuoteRatePlanCharge__c testZquQuoteRatePlanCharge1 = new zqu__QuoteRatePlanCharge__c();
        testZquQuoteRatePlanCharge1.Name = 'Test Quote Rate Plan Charge1';  
        testZquQuoteRatePlanCharge1.zqu__QuoteRatePlan__c = testZquQuoteRatePlan.id; 
        testZquQuoteRatePlanCharge1.zqu__ProductRatePlanCharge__c = testZquProductRatePlanCharge.id;
        testZquQuoteRatePlanCharge1.zqu__Total__c = 1;
        testZquQuoteRatePlanCharge1.zqu__EffectivePrice__c = 20;
        testZquQuoteRatePlanCharge1.zqu__EffectivePrice__c = 15;
        testZquQuoteRatePlanCharge1.Product_Type__c = 'Print';
        testZquQuoteRatePlanCharge1.Print_Issue__c = pi.id;
        testZquQuoteRatePlanCharge1.zqu__ChargeType__c = 'Recurring';
        testZquQuoteRatePlanCharge1.List_Price__c = '12';
        testZquQuoteRatePlanCharge1.zqu__Period__c = 'Quarter';
        testZquQuoteRatePlanCharge1.zqu__Discount__c = 31;
        testZquQuoteRatePlanCharge1.Number_of_Charges__c = 3;
        testZquQuoteRatePlanCharge1.LDE_Email_Launch_Date__c = date.today();
        testZquQuoteRatePlanCharge1.Discount_Override__c = 1;
        insert testZquQuoteRatePlanCharge1;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testZquQuote);
        ZuoraQuotePMRController testZQ = new ZuoraQuotePMRController(sc);
        testZQ.redirect();
        
        try{
            ApexPages.PageReference apprf = testZQ.updateDiscountsRunLocalProductRulesAndRedirect();
        }catch(exception e){}
        
        testZQ.quoteId = testZquQuoteRatePlanCharge1.id;
        try{
            ApexPages.PageReference apprf = testZQ.updateDiscountsRunLocalProductRulesAndRedirect();
        }catch(exception e){}
    }

    public static testMethod void testTheController2() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Test.startTest();
        Map<String, SObject> testData =TestClassUtility.buildLocalData(false);
        Test.stopTest();
        Account testAccount = (Account)testData.get('Account');
        Opportunity testOpportunity = (Opportunity)testData.get('Opportunity');
        Contact testContact = (Contact)testData.get('Contact');
        Market__c testMarket = (Market__c)testData.get('Market__c');
        Category__c testCategory = (Category__c)testData.get('Category__c');
        // CSP-1999 Brand__c testBrand = (Brand__c)testData.get('Brand__c');
        Zip__c testZip = (Zip__c)testData.get('Zip__c');
        
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
        
        zqu__Quote__c testZquQuote = new zqu__Quote__c();
        testZquQuote.Name = 'Test Quote';
        testZquQuote.zqu__Status__c = 'New';
        testZquQuote.zqu__Account__c = testAccount.id;
        testZquQuote.zqu__BillToContact__c = testContact.Id;
        testZquQuote.zqu__Opportunity__c = testOpportunity.Id;
        testZquQuote.Zqu__ValidUntil__c = Date.Today()-1;  
        testZquQuote.Preferred_Payment_Schedule__c = 'Quarter';   
        testZquQuote.zqu__InitialTerm__c = 3;  
        testZquQuote.zqu__StartDate__c = date.today().adddays(1);
        testZquQuote.zqu__ZuoraAccountID__c = '';
        testZquQuote.zqu__PaymentMethod__c = 'Credit Card';
        insert testZquQuote;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testZquQuote);
        ZuoraQuotePMRController testZQ = new ZuoraQuotePMRController(sc);
        testZQ.billingAccountID = 'test';
        testZQ.subscriptionType= 'Cancel Subscription';
        testZQ.redirect();
        testZQ.updateDiscountsRunLocalProductRulesAndRedirect();
    }
}