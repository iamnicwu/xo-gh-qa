/* 
<class>
  <name>QuoteRatePlanChargeTriggerTest</name>
  <purpose>For testing save/delete events on a Zuora QuoteRatePlanCharge</purpose>
  <created>
    <by>Jonathan Satterfield</by>
    <date>7/22/2015</date>
    <ticket>SF-598, SF-599, SF-601</ticket>
  </created>
</class>
*/

/* 
<class>
  <name>QuoteRatePlanChargeTriggerTest</name>
  <purpose>For testing save/delete events on a Zuora QuoteRatePlanCharge and 
           record the Job Type & product Type from Zproducts on each QuoteRatePlanCharge record
  </purpose>
  <Modified>
    <by>Vijay Ram</by>
    <date>8/02/2015</date>
    <ticket>SF-583</ticket>
  </Modified>
</class>
*/

@isTest
public class QuoteRatePlanChargeTriggerTest {
    /* 
    <method>
      <name>TestUpdateIDsForCommissionTracking</name>
      <purpose>Test the QuoteRatePlanChargeTriggerHandler.UpdateIDsForCommissionTracking method</purpose>
      <created>
        <by>Jonathan Satterfield</by>
        <date>7/22/2015</date>
        <ticket>SF-598, SF-599, SF-601</ticket>
      </created>
    </method>
    */
    
     /* 
    <method>
      <name>TestUpdateIDsForCommissionTracking</name>
      <purpose>Test the QuoteRatePlanChargeTriggerHandler.RecordZProductJobType method</purpose>
      <created>
        <by>Vijay ram</by>
        <date>8/3/2015</date>
        <ticket>SF-583</ticket>
      </created>
    </method>
    */
    static testMethod void TestUpdateIDsForCommissionTracking() {
        
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Test.startTest();

        Map<String,SObject> testLocalData = TestClassUtility.buildLocalData(false);
        Account testAccount = (Account)testLocalData.get('Account');
        Opportunity testOpp = (Opportunity)testLocalData.get('Opportunity');
        Contact testContact = (Contact)testLocalData.get('Contact');
      
        testAccount.Fulfillment_Data__c = '{ "tier" : "Freemium", "reviewId" : "review Id", "parentGUID" : "37e0c6b9-6f4f-4dd4-a3f4-9707e9dc4bbc", "marketCode" : "228", "categoryId" : "8aa9a07b-fcd8-46ed-a98f-8f3e12689dd2" }';
        update testAccount;

        Test.stopTest();
        
        zqu__Quote__c testZQuote = TestClassUtility.createQuote(false, testOpp,testAccount,testContact);
        testZQuote.SalesRepId__c = '12345';
        testZQuote.RenewalRepId__c = '12345';
        testZQuote.RSD_Id__c = '11111';
        insert testZQuote;
        
        System.debug('Quote Created');

        zqu__QuoteAmendment__c testZQuoteAmendment = TestClassUtility.createQuoteAmendment(true,testZQuote);

        Product2 testProduct = TestClassUtility.createLocalProduct2(false);
        testProduct.Name = 'Test Product';
        testProduct.Job_Type__c = 'PRO'; 
        testProduct.zqu__SKU__c = 'test1234'; 
        testProduct.zqu__ZuoraId__c = 'test123456'; 
        insert testProduct;

        System.debug('Product Created');

        zqu__ProductRatePlan__c testProductRatePlan = TestClassUtility.createProductRatePlan(true,testProduct);

        System.debug('Product Rate Plan Created');

        zqu__ProductRatePlanCharge__c testProductRatePlanCharge = TestClassUtility.createProductRatePlanCharge(true,testProductRatePlan);

        System.debug('Product Rate Plan Charge Created');

        zqu__QuoteRatePlan__c testQuoteRatePlan = TestClassUtility.createQuoteRatePlan(false,testZQuote,testProductRatePlan);
        testQuoteRatePlan.zqu__QuoteAmendment__c = testZQuoteAmendment.Id;
        testQuoteRatePlan.zqu__SubscriptionRatePlanZuoraId__c = '';
        insert testQuoteRatePlan;

        System.debug('Quote Rate Plan for NewProduct Created');

        zqu__QuoteRatePlan__c testQuoteRatePlan2 = TestClassUtility.createQuoteRatePlan(false,testZQuote,testProductRatePlan);
        testQuoteRatePlan2.zqu__QuoteAmendment__c = testZQuoteAmendment.Id;
        testQuoteRatePlan2.zqu__SubscriptionRatePlanZuoraId__c = 'abc123';
        testQuoteRatePlan2.zqu__AmendmentType__c = 'UpdateProduct';
        insert testQuoteRatePlan2;

        System.debug('Quote Rate Plan for UpdateProduct Created');

        zqu__QuoteRatePlanCharge__c testQuoteRatePlanCharge = TestClassUtility.createQuoteRatePlanCharge(false,testQuoteRatePlan,testProductRatePlanCharge);
        testQuoteRatePlanCharge.zqu__ListPrice__c = 123;
        testQuoteRatePlanCharge.zqu__Total__c = 123;
        testQuoteRatePlanCharge.Quote_Rate_Plan_ID__c = '';
        testQuoteRatePlanCharge.zqu__ListPrice__c = 10.00;
        testQuoteRatePlanCharge.List_Price__c = '';
        testQuoteRatePlanCharge.Location_Vendor__c = testAccount.id;
        insert testQuoteRatePlanCharge;

        System.debug('Quote Rate Plan Charge Created');

        List<zqu__QuoteRatePlanCharge__c> qrpcList = new List<zqu__QuoteRatePlanCharge__c>();

        zqu__QuoteRatePlanCharge__c testQuoteRatePlanCharge2 = TestClassUtility.createQuoteRatePlanCharge(false,testQuoteRatePlan,testProductRatePlanCharge);
        testQuoteRatePlanCharge2.zqu__ListPrice__c = 123;
        testQuoteRatePlanCharge2.zqu__Total__c = 123;
        testQuoteRatePlanCharge2.Quote_Rate_Plan_ID__c = '';
        testQuoteRatePlanCharge2.zqu__ListPrice__c = 10.00;
        testQuoteRatePlanCharge2.List_Price__c = '';
        testQuoteRatePlanCharge2.Location_Vendor__c = testAccount.id;
        qrpcList.add(testQuoteRatePlanCharge2);

        zqu__QuoteRatePlanCharge__c testQuoteRatePlanCharge3 = TestClassUtility.createQuoteRatePlanCharge(false,testQuoteRatePlan,testProductRatePlanCharge);
        testQuoteRatePlanCharge3.zqu__ListPrice__c = 123;
        testQuoteRatePlanCharge3.zqu__Total__c = 123;
        testQuoteRatePlanCharge3.Quote_Rate_Plan_ID__c = '';
        testQuoteRatePlanCharge3.zqu__ListPrice__c = 10.00;
        testQuoteRatePlanCharge3.List_Price__c = '';
        qrpcList.add(testQuoteRatePlanCharge3);

        insert qrpcList;     
    }
    
    static testMethod void TestUpdateIDsForCommissionTracking_two() {
        
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Test.startTest();

        Map<String,SObject> testLocalData = TestClassUtility.buildLocalData(false);
        Account testAccount = (Account)testLocalData.get('Account');
        Opportunity testOpp = (Opportunity)testLocalData.get('Opportunity');
        Contact testContact = (Contact)testLocalData.get('Contact');
        
        testAccount.Fulfillment_Data__c = '{ "tier" : "Freemium", "reviewId" : "review Id", "parentGUID" : "37e0c6b9-6f4f-4dd4-a3f4-9707e9dc4bbc", "marketCode" : "228", "categoryId" : "8aa9a07b-fcd8-46ed-a98f-8f3e12689dd2" }';
        update testAccount;
        
        Test.stopTest();

        zqu__Quote__c testZQuote = TestClassUtility.createQuote(false, testOpp,testAccount,testContact);
        testZQuote.SalesRepId__c = '12345';
        testZQuote.RenewalRepId__c = '12345';
        testZQuote.RSD_Id__c = '11111';
        insert testZQuote;

        System.debug('Quote Created');

        zqu__QuoteAmendment__c testZQuoteAmendment = TestClassUtility.createQuoteAmendment(true,testZQuote);

        Product2 testProduct = TestClassUtility.createLocalProduct2(false);
        testProduct.Name = 'Test Product';
        testProduct.Job_Type__c = 'PRO'; 
        testProduct.zqu__SKU__c = 'test1234'; 
        testProduct.zqu__ZuoraId__c = 'test123456'; 
        insert testProduct;

        System.debug('Product Created');

        zqu__ProductRatePlan__c testProductRatePlan = TestClassUtility.createProductRatePlan(true,testProduct);

        System.debug('Product Rate Plan Created');

        zqu__ProductRatePlanCharge__c testProductRatePlanCharge = TestClassUtility.createProductRatePlanCharge(true,testProductRatePlan);

        System.debug('Product Rate Plan Charge Created');

        zqu__QuoteRatePlan__c testQuoteRatePlan = TestClassUtility.createQuoteRatePlan(false,testZQuote,testProductRatePlan);
        testQuoteRatePlan.zqu__QuoteAmendment__c = testZQuoteAmendment.Id;
        testQuoteRatePlan.zqu__SubscriptionRatePlanZuoraId__c = '';
        insert testQuoteRatePlan;

        System.debug('Quote Rate Plan for NewProduct Created');

        zqu__QuoteRatePlan__c testQuoteRatePlan2 = TestClassUtility.createQuoteRatePlan(false,testZQuote,testProductRatePlan);
        testQuoteRatePlan2.zqu__QuoteAmendment__c = testZQuoteAmendment.Id;
        testQuoteRatePlan2.zqu__SubscriptionRatePlanZuoraId__c = 'abc123';
        testQuoteRatePlan2.zqu__AmendmentType__c = 'UpdateProduct';
        insert testQuoteRatePlan2;

        System.debug('Quote Rate Plan for UpdateProduct Created');

        zqu__QuoteRatePlanCharge__c testQuoteRatePlanCharge = TestClassUtility.createQuoteRatePlanCharge(false,testQuoteRatePlan,testProductRatePlanCharge);
        testQuoteRatePlanCharge.zqu__ListPrice__c = 123;
        testQuoteRatePlanCharge.zqu__Total__c = 123;
        testQuoteRatePlanCharge.Quote_Rate_Plan_ID__c = '';
        testQuoteRatePlanCharge.zqu__ListPrice__c = 10.00;
        testQuoteRatePlanCharge.List_Price__c = '';
        testQuoteRatePlanCharge.Location_Vendor__c = testAccount.id;
        insert testQuoteRatePlanCharge;

        System.debug('Quote Rate Plan Charge Created');

        List<zqu__QuoteRatePlanCharge__c> qrpcList = new List<zqu__QuoteRatePlanCharge__c>();

        zqu__QuoteRatePlanCharge__c testQuoteRatePlanCharge2 = TestClassUtility.createQuoteRatePlanCharge(false,testQuoteRatePlan,testProductRatePlanCharge);
        testQuoteRatePlanCharge2.zqu__ListPrice__c = 123;
        testQuoteRatePlanCharge2.zqu__Total__c = 123;
        testQuoteRatePlanCharge2.Quote_Rate_Plan_ID__c = '';
        testQuoteRatePlanCharge2.zqu__ListPrice__c = 10.00;
        testQuoteRatePlanCharge2.List_Price__c = '';
        testQuoteRatePlanCharge2.Location_Vendor__c = testAccount.id;
        qrpcList.add(testQuoteRatePlanCharge2);

 
        zqu__QuoteRatePlanCharge__c testQuoteRatePlanCharge3 = TestClassUtility.createQuoteRatePlanCharge(false,testQuoteRatePlan,testProductRatePlanCharge);
        testQuoteRatePlanCharge3.zqu__ListPrice__c = 123;
        testQuoteRatePlanCharge3.zqu__Total__c = 123;
        testQuoteRatePlanCharge3.Quote_Rate_Plan_ID__c = '';
        testQuoteRatePlanCharge3.zqu__ListPrice__c = 10.00;
        testQuoteRatePlanCharge3.List_Price__c = ''; 
        qrpcList.add(testQuoteRatePlanCharge3);
        
        insert qrpcList;
       
        Zuora__Subscription__c testSubscription = TestClassUtility.createSubscription(false,testAccount);
        testSubscription.Zuora__Zuora_Id__c = 'abc123';
        insert testSubscription;

        Zuora__Product__c testZuoraProduct = TestClassUtility.createZuoraProduct(true);
      
        Zuora__Subscription__c testSub = TestClassUtility.createSubscription(true,testAccount);
        
        Zuora__SubscriptionProductCharge__c testZSubProductCharge = TestClassUtility.createSubscriptionProductCharge(true,testSub,testZuoraProduct);
        
        QuoteRatePlanChargeTriggerHandler.UpdateIDsForCommissionTracking(qrpcList);    
    }

}