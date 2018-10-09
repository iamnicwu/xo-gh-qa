@isTest()
private class OpportunitySendToZBillingControllerTest{
    @isTest static void test_method_one() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Test.startTest();
        Map<String ,SObject> testLocalData = TestClassUtility.buildLocalData(false); 
        Opportunity testOpp = (Opportunity)testLocalData.get('Opportunity');
        Account testAccount = (Account)testLocalData.get('Account');
        Contact testContact = (Contact)testLocalData.get('Contact'); 
        Test.stopTest(); 

        test.setCurrentPageReference(Page.OpportunitySendToZBilling);
        ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
        OpportunitySendToZBillingController testcase = new OpportunitySendToZBillingController(sc);
        
        zqu__Quote__c testZquQuote = TestClassUtility.createQuote(false,testOpp,testAccount,testContact);
        testZquQuote.zqu__Service_Activation_Date__c = Date.newinstance(2016, 12, 31);    
        testZquQuote.zqu__TermStartDate__c = Date.today();
        testZquQuote.zqu__InitialTerm__c= 2;  
        testZquQuote.zqu__PaymentMethod__c = zqu.PaymentPageController.PAYMENT_METHOD_TYPE_ACH;
        insert testZquQuote;
       
        Product2 testProduct = TestClassUtility.createLocalProduct2(true);
        
        zqu__ProductRatePlan__c testZquProductRatePlan = TestClassUtility.createProductRatePlan(true,testProduct);
        
        zqu__QuoteAmendment__c testZquQuoteAmendment = TestClassUtility.createQuoteAmendment(true,testZquQuote);

        zqu__QuoteRatePlan__c testZquQuoteRatePlan = TestClassUtility.createQuoteRatePlan(false,testZquQuote,testZquProductRatePlan);
        testZquQuoteRatePlan.zqu__QuoteAmendment__c = testZquQuoteAmendment.id; 
        insert testZquQuoteRatePlan;
        
        OpportunitySendToZBillingController testcase1 = new OpportunitySendToZBillingController(sc);
        testcase1.SendToZBilling();
        
        testZquQuote.zqu__PaymentMethod__c = zqu.PaymentPageController.PAYMENT_METHOD_TYPE_CREDIT_CARD;
        update testZquQuote;
        testcase1.SendToZBilling();
        
        boolean getShowSendButton = testcase1.getShowSendButton();
        testcase1.Cancel();
        List<OpportunitySendToZBillingController.QuoteWrapper> QuoteWrappers = new list<OpportunitySendToZBillingController.QuoteWrapper>();
        QuoteWrappers = testcase1.getQuotes();
        
        zqu__Quote__c testZquQuote1 = TestClassUtility.createQuote(false,testOpp,testAccount,testContact);
        testZquQuote1.zqu__Service_Activation_Date__c = Date.newinstance(2016, 12, 31);     
        testZquQuote1.zqu__TermStartDate__c = Date.today();
        testZquQuote1.zqu__InitialTerm__c= 2;  
        testZquQuote1.zqu__PaymentMethod__c = zqu.PaymentPageController.PAYMENT_METHOD_TYPE_CREDIT_CARD;
        insert testZquQuote1;
        
        list<id> oppIds = new list<id>();
        oppIds.add(testOpp.id);
        OpportunitySendToZBillingController.AsyncSendToZBilling(oppIds);

    }
    
    @isTest static void test_method_two() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Test.startTest();
        Map<String ,SObject> testLocalData = TestClassUtility.buildLocalData(false); 
        Opportunity testOpp = (Opportunity)testLocalData.get('Opportunity');
        Account testAccount = (Account)testLocalData.get('Account');
        Contact testContact = (Contact)testLocalData.get('Contact'); 
        Test.stopTest(); 

        test.setCurrentPageReference(Page.OpportunitySendToZBilling);
        ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
        OpportunitySendToZBillingController testcase = new OpportunitySendToZBillingController(sc);
        
        zqu__Quote__c testZquQuote = TestClassUtility.createQuote(false,testOpp,testAccount,testContact);
        testZquQuote.zqu__InitialTerm__c= 2;  
        testZquQuote.zqu__PaymentMethod__c = zqu.PaymentPageController.PAYMENT_METHOD_TYPE_ACH;
        testZquQuote.zqu__ElectronicPaymentMethodId__c = 'test';
        insert testZquQuote;
        
        zqu__Quote__c testZquQuote1 = TestClassUtility.createQuote(false,testOpp,testAccount,testContact);
        testZquQuote1.zqu__InitialTerm__c= 2;  
        testZquQuote1.zqu__PaymentMethod__c = zqu.PaymentPageController.PAYMENT_METHOD_TYPE_ACH;
        testZquQuote1.zqu__ElectronicPaymentMethodId__c = 'test';
        insert testZquQuote1;

        list<id> oppIds = new list<id>();
        oppIds.add(testOpp.id);
        OpportunitySendToZBillingController.AsyncSendToZBilling(oppIds);
    }
    
    @isTest static void test_method_Three() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        Test.startTest();
        Map<String ,SObject> testLocalData = TestClassUtility.buildLocalData(false); 
        Opportunity testOpp = (Opportunity)testLocalData.get('Opportunity');
        Account testAccount = (Account)testLocalData.get('Account');
        Contact testContact = (Contact)testLocalData.get('Contact'); 
        Test.stopTest(); 

        zqu__Quote__c testZquQuote = TestClassUtility.createQuote(false,testOpp,testAccount,testContact);
        testZquQuote.zqu__TermStartDate__c = Date.today();  
        testZquQuote.zqu__InitialTerm__c= 2;  
        testZquQuote.zqu__PaymentMethod__c = zqu.PaymentPageController.PAYMENT_METHOD_TYPE_ACH;
        testZquQuote.zqu__ZuoraAccountID__c = 'test';
        testZquQuote.zqu__Service_Activation_Date__c = Date.newinstance(2015, 12, 31);
        testZquQuote.zqu__BillCycleDay__c = '1';
        insert testZquQuote;

        zqu__Quote__c testZquQuote1 = TestClassUtility.createQuote(false,testOpp,testAccount,testContact);   
        testZquQuote1.zqu__TermStartDate__c = Date.today();
        testZquQuote1.zqu__InitialTerm__c= 2;  
        testZquQuote1.zqu__PaymentMethod__c = zqu.PaymentPageController.PAYMENT_METHOD_TYPE_ACH;
        testZquQuote1.zqu__ZuoraAccountID__c = '';
        testZquQuote1.zqu__Service_Activation_Date__c = Date.newinstance(2015, 12, 31);
        insert testZquQuote1;

        zqu__Quote__c testZquQuote2 = TestClassUtility.createQuote(false,testOpp,testAccount,testContact);
        testZquQuote2.zqu__InitialTerm__c= 2;     
        testZquQuote2.zqu__TermStartDate__c = Date.today(); 
        testZquQuote2.zqu__PaymentMethod__c = zqu.PaymentPageController.PAYMENT_METHOD_TYPE_ACH;
        testZquQuote2.zqu__ZuoraAccountID__c = '';
        testZquQuote2.zqu__Service_Activation_Date__c = Date.newinstance(2015, 12, 31);
        insert testZquQuote2;

        Task_Creation_Settings__c testTaskCreSet = TestClassUtility.createTaskCreationSettingsWithQuoteDeleted(false);
        testTaskCreSet.name = 'Error_sending_a_quote_to_Zuora';
        insert testTaskCreSet;
        ApexPages.Message testm = OpportunitySendToZBillingController.SendToZBilling(new List<Id> {testOpp.Id});
        
        list<id> oppIds = new list<id>();
        oppIds.add(testOpp.id);
        OpportunitySendToZBillingController.AsyncSendToZBilling(oppIds);
         
        list<zqu__Quote__c> ZquoteList = new list<zqu__Quote__c>();
        ZquoteList.add(testZquQuote);
        ZquoteList.add(testZquQuote1);
        ZquoteList.add(testZquQuote2);
        OpportunitySendToZBillingController.SetQuoteDates(ZquoteList);
    }
    
   
    @isTest static void test_method_Four() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Test.startTest();
        Map<String ,SObject> testLocalData = TestClassUtility.buildLocalData(false); 
        Opportunity testOpp = (Opportunity)testLocalData.get('Opportunity');
        Account testAccount = (Account)testLocalData.get('Account');
        Contact testContact = (Contact)testLocalData.get('Contact'); 
        Test.stopTest(); 

        testOpp.Date_Client_Approved__c =  date.today();
        update testOpp;

        zqu__Quote__c testZquQuote = TestClassUtility.createQuote(false,testOpp,testAccount,testContact);
        testZquQuote.zqu__InitialTerm__c= 2; 
        testZquQuote.zqu__TermStartDate__c = Date.today();  
        testZquQuote.zqu__PaymentMethod__c = zqu.PaymentPageController.PAYMENT_METHOD_TYPE_ACH;
        testZquQuote.zqu__ZuoraAccountID__c = 'test';
        testZquQuote.zqu__Service_Activation_Date__c = Date.newinstance(2015, 12, 31);
        testZquQuote.zqu__BillCycleDay__c = '2';
        insert testZquQuote;
        
        Task_Creation_Settings__c testTaskCreSet = TestClassUtility.createTaskCreationSettingsWithQuoteDeleted(false);
        testTaskCreSet.name = 'Error_sending_a_quote_to_Zuora';
        insert testTaskCreSet;

        ApexPages.Message testm = OpportunitySendToZBillingController.SendToZBilling(new List<Id> {testOpp.Id});

        list<zqu__Quote__c> ZquoteList = new list<zqu__Quote__c>();
        ZquoteList.add(testZquQuote);
        OpportunitySendToZBillingController.SetQuoteDates(ZquoteList);
        
        ZquoteList[0].zqu__BillCycleDay__c = '32';
        ZquoteList[0].zqu__Service_Activation_Date__c = Date.newinstance(2015, 1, 31);
        OpportunitySendToZBillingController.SetQuoteDates(ZquoteList);
    }
}