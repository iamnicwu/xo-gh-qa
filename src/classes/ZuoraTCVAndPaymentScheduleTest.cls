/*******************************************************************************
 *  Summary      : Test class for ZuoraTCVAndPaymentSchedule
 *  Refer Object : 
 *  Author       : Nick
 *  RefactorDate : 12 Dec 2016
 *  Change Log   : Refactoring by SF-2.6 release
 ******************************************************************************/
@isTest
private class ZuoraTCVAndPaymentScheduleTest {
    
    
    @isTest static void test_method_one() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        // Zuora test data
        Product2 testProduct = TestClassUtility.createLocalProduct2(true);
        zqu__ProductRatePlan__c testProductRatePlan = TestClassUtility.createProductRatePlan(true, testProduct);
        zqu__ProductRatePlanCharge__c testProductRatePlanCharge = TestClassUtility.createProductRatePlanCharge(true, testProductRatePlan);

        // Quote test data
        Market__c testMarket = TestClassUtility.createMarket(false);
        testMarket.Market_Id__c = '222';
        insert testMarket;

        TestClassUtility.generateQuotePdfConfig(true);
        generateZuoraEnvironmentURLList(true);
        
        Account testAccount = TestClassUtility.createAccount(false);
        testAccount.shippingPostalCode = '78741';
        testAccount.billingPostalCode = '78741';
        insert testAccount;

        Opportunity testOpportunity = TestClassUtility.createOpportunity(true, testAccount);
        Contact testContact = TestClassUtility.createContact(true, testAccount);
        TestClassUtility.createAccountContactRole(true, testAccount, testContact);
        Zuora__CustomerAccount__c testCustomerAccount = TestClassUtility.createCustomerAccount(true, testAccount);
        zqu__Quote__c testQuote = TestClassUtility.createQuote(false, testOpportunity, testAccount, testContact);
        testQuote.zqu__ZuoraAccountId__c = '';
        testQuote.zqu__SubscriptionType__c = 'New Subscription';
        testQuote.zqu__BillCycleDay__c = '12';
        insert testQuote;
        zqu__Quote__c zquote = [SELECT zqu__StartDate__c, zqu__BillingCycleDay__c FROM zqu__Quote__c WHERE id = : testQuote.Id];
        System.debug(LoggingLevel.INFO, '*** zquote: ' + zquote);

        zqu__QuoteAmendment__c testQuoteAmendment = TestClassUtility.createQuoteAmendment(true, testQuote);
        zqu__QuoteRatePlan__c testQuoteRatePlan = TestClassUtility.createQuoteRatePlan(true, testQuote, testProductRatePlan, testQuoteAmendment);
        
        zqu__QuoteRatePlanCharge__c testQuoteRatePlanCharge = TestClassUtility.createQuoteRatePlanCharge(true, testQuoteRatePlan, testProductRatePlanCharge);
        testQuoteRatePlanCharge.zqu__Period__c = 'Semi-Annual';
        Update testQuoteRatePlanCharge;
        // run test
        ZuoraTCVAndPaymentSchedule.setTrueTCV(testOpportunity.Id);
    }
    
    // @isTest static void test_InternetMonthly() {
        
    //     Test.startTest();

    //     // Zuora test data
    //     Product2 testProduct = TestClassUtility.createLocalProduct2(true);
    //     zqu__ProductRatePlan__c testProductRatePlan = TestClassUtility.createProductRatePlan(true, testProduct);
    //     zqu__ProductRatePlanCharge__c testProductRatePlanCharge = TestClassUtility.createProductRatePlanCharge(true, testProductRatePlan);

    //     // Quote test data
    //     Market__c testMarket = TestClassUtility.createMarket(false);
    //     testMarket.Market_Id__c = '222';
    //     insert testMarket;

    //     TestClassUtility.generateQuotePdfConfig(true); 
        
    //     Account testAccount = TestClassUtility.createAccount(false);
    //     testAccount.shippingPostalCode = '78741';
    //     insert testAccount;

    //     Test.stopTest();

    //     Opportunity testOpportunity = TestClassUtility.createOpportunity(true, testAccount);
    //     Contact testContact = TestClassUtility.createContact(true, testAccount);
    //     TestClassUtility.createAccountContactRole(true, testAccount, testContact);
    //     Zuora__CustomerAccount__c testCustomerAccount = TestClassUtility.createCustomerAccount(true, testAccount);
    //     zqu__Quote__c testQuote = TestClassUtility.createQuote(false, testOpportunity, testAccount, testContact);
    //     testQuote.zqu__BillCycleDay__c = '11';
    //     testQuote.zqu__StartDate__c = Date.today();
    //     testQuote.zqu__Customer_Acceptance_Date__c = Date.today();
    //     testQuote.zqu__InitialTerm__c = 12.00;
    //     testQuote.zqu__Service_Activation_Date__c = Date.today();
    //     testQuote.zqu__Subscription_Term_Type__c = 'Termed';
    //     insert testQuote;

    //     zqu__QuoteAmendment__c testQuoteAmendment = TestClassUtility.createQuoteAmendment(true, testQuote);
    //     zqu__QuoteRatePlan__c testQuoteRatePlan = TestClassUtility.createQuoteRatePlan(true, testQuote, testProductRatePlan, testQuoteAmendment);
    //     zqu__QuoteRatePlanCharge__c testQuoteRatePlanCharge = TestClassUtility.createQuoteRatePlanCharge(false, testQuoteRatePlan, testProductRatePlanCharge);
    //     testQuoteRatePlanCharge.zqu__Period__c = 'Semi-Annual';
    //     testQuoteRatePlanCharge.zqu__SubscriptionRatePlanChargeZuoraId__c = 'adkfadsjfdasfsadf32424';
    //     testQuoteRatePlanCharge.zqu__Total__c = 19.89;
    //     insert testQuoteRatePlanCharge;

    //     // run test
    //     //ZuoraTCVAndPaymentSchedule.setTrueTCV(testOpportunity.Id);
    //     ZuoraTCVAndPaymentSchedule.OpportunityQuotesWrapper oqw = ZuoraTCVAndPaymentSchedule.generateOpportunityQuotesWrapper(testOpportunity.Id);
    //     //ZuoraTCVAndPaymentSchedule.buildSTRPListForNewInternetSubs(oqw.quotesWrapperList[0]);
    //     ZuoraTCVAndPaymentSchedule.buildPreviewAccountInfo(oqw.quotesWrapperList[0]);
    //     ZuoraTCVAndPaymentSchedule.populateBaseClassFields(oqw.quotesWrapperList[0]);
    //     ZuoraTCVAndPaymentSchedule.buildNewAccountNewSubWrapper(oqw.quotesWrapperList[0]);
    //     ZuoraTCVAndPaymentSchedule.populateAmendmentBaseClassFields(oqw.quotesWrapperList[0]);
    //     ZuoraTCVAndPaymentSchedule.buildExistingAccountNewSubWrapper(oqw.quotesWrapperList[0]);
    //     ZuoraTCVAndPaymentSchedule.buildAmendmentSubWrapper(oqw.quotesWrapperList[0]);
    //     ZuoraTCVAndPaymentSchedule.buildUpdateWrapper(oqw.quotesWrapperList[0], testQuoteRatePlan);
    //     ZuoraTCVAndPaymentSchedule.buildRemoveWrapper(oqw.quotesWrapperList[0], testQuoteRatePlan);
    //     ZuoraTCVAndPaymentSchedule.getSubscriptionCurrentTerm('subZuoraId');
    // }

    // @isTest static void test_InternetNonMonthly() {
        
    //     Test.startTest();
    //     // Zuora test data
    //     Product2 testProduct = TestClassUtility.createLocalProduct2(true);
    //     zqu__ProductRatePlan__c testProductRatePlan = TestClassUtility.createProductRatePlan(true, testProduct);
    //     zqu__ProductRatePlanCharge__c testProductRatePlanCharge = TestClassUtility.createProductRatePlanCharge(true, testProductRatePlan);

    //     // Quote test data
    //     Market__c testMarket = TestClassUtility.createMarket(false);
    //     testMarket.Market_Id__c = '222';
    //     insert testMarket;

    //     TestClassUtility.generateQuotePdfConfig(true); 
        
    //     Account testAccount = TestClassUtility.createAccount(false);
    //     testAccount.shippingPostalCode = '78741';
    //     insert testAccount;

    //     Test.stopTest();

    //     Opportunity testOpportunity = TestClassUtility.createOpportunity(true, testAccount);
    //     Contact testContact = TestClassUtility.createContact(true, testAccount);
    //     TestClassUtility.createAccountContactRole(true, testAccount, testContact);
    //     Zuora__CustomerAccount__c testCustomerAccount = TestClassUtility.createCustomerAccount(true, testAccount);
    //     zqu__Quote__c testQuote = TestClassUtility.createQuote(false, testOpportunity, testAccount, testContact);
    //     testQuote.zqu__BillCycleDay__c = '11';
    //     testQuote.zqu__StartDate__c = Date.today();
    //     testQuote.zqu__Customer_Acceptance_Date__c = Date.today();
    //     testQuote.zqu__InitialTerm__c = 12.00;
    //     testQuote.zqu__Service_Activation_Date__c = Date.today();
    //     testQuote.zqu__Subscription_Term_Type__c = 'Termed';
    //     insert testQuote;

    //     zqu__QuoteAmendment__c testQuoteAmendment = TestClassUtility.createQuoteAmendment(true, testQuote);
    //     zqu__QuoteRatePlan__c testQuoteRatePlan = TestClassUtility.createQuoteRatePlan(true, testQuote, testProductRatePlan, testQuoteAmendment);
    //     zqu__QuoteRatePlanCharge__c testQuoteRatePlanCharge = TestClassUtility.createQuoteRatePlanCharge(false, testQuoteRatePlan, testProductRatePlanCharge);
    //     testQuoteRatePlanCharge.zqu__Period__c = 'Semi-Annual';
    //     testQuoteRatePlanCharge.zqu__SubscriptionRatePlanChargeZuoraId__c = 'adkfadsjfdasfsadf32424';
    //     testQuoteRatePlanCharge.zqu__Total__c = 19.89;
    //     testQuoteRatePlanCharge.zqu__BillingPeriodAlignment__c = 'AlignToSubscriptionStart';
    //     insert testQuoteRatePlanCharge;

    //     // run test
    //     ZuoraTCVAndPaymentSchedule.OpportunityQuotesWrapper oqw = ZuoraTCVAndPaymentSchedule.generateOpportunityQuotesWrapper(testOpportunity.Id);
    //     ZuoraTCVAndPaymentSchedule.buildSTRPListForNewInternetSubs(oqw.quotesWrapperList[0]);
    //     ZuoraTCVAndPaymentSchedule.buildAddWrapper(oqw.quotesWrapperList[0], testQuoteRatePlan);
    // }


    // @isTest static void test_PrintMonthly() {
        
    //     Test.startTest();

    //     // Zuora test data
    //     Product2 testProduct = TestClassUtility.createLocalProduct2(true);
    //     zqu__ProductRatePlan__c testProductRatePlan = TestClassUtility.createProductRatePlan(true, testProduct);
    //     zqu__ProductRatePlanCharge__c testProductRatePlanCharge = TestClassUtility.createProductRatePlanCharge(true, testProductRatePlan);

    //     // Quote test data
    //     Market__c testMarket = TestClassUtility.createMarket(false);
    //     testMarket.Market_Id__c = '222';
    //     insert testMarket;

    //     TestClassUtility.generateQuotePdfConfig(true); 
        
    //     Account testAccount = TestClassUtility.createAccount(false);
    //     testAccount.shippingPostalCode = '78741';
    //     insert testAccount;

    //     Test.stopTest();

    //     Opportunity testOpportunity = TestClassUtility.createOpportunity(true, testAccount);
    //     Contact testContact = TestClassUtility.createContact(true, testAccount);
    //     TestClassUtility.createAccountContactRole(true, testAccount, testContact);
    //     Zuora__CustomerAccount__c testCustomerAccount = TestClassUtility.createCustomerAccount(true, testAccount);
    //     zqu__Quote__c testQuote = TestClassUtility.createQuote(false, testOpportunity, testAccount, testContact);
    //     testQuote.zqu__BillCycleDay__c = '11';
    //     testQuote.zqu__StartDate__c = Date.today();
    //     testQuote.zqu__Customer_Acceptance_Date__c = Date.today();
    //     testQuote.zqu__InitialTerm__c = 12.00;
    //     testQuote.zqu__Service_Activation_Date__c = Date.today();
    //     testQuote.zqu__Subscription_Term_Type__c = 'Termed';
    //     insert testQuote;

    //     zqu__QuoteAmendment__c testQuoteAmendment = TestClassUtility.createQuoteAmendment(true, testQuote);
    //     zqu__QuoteRatePlan__c testQuoteRatePlan = TestClassUtility.createQuoteRatePlan(true, testQuote, testProductRatePlan, testQuoteAmendment);
        
    //     zqu__QuoteRatePlanCharge__c testQuoteRatePlanCharge = TestClassUtility.createQuoteRatePlanCharge(false, testQuoteRatePlan, testProductRatePlanCharge);
    //     testQuoteRatePlanCharge.zqu__Period__c = 'Semi-Annual';
    //     testQuoteRatePlanCharge.zqu__SubscriptionRatePlanChargeZuoraId__c = 'adkfadsjfdasfsadf32424';
    //     testQuoteRatePlanCharge.zqu__Total__c = 19.89;
    //     testQuoteRatePlanCharge.zqu__BillingPeriodAlignment__c = 'AlignToSubscriptionStart';
    //     insert testQuoteRatePlanCharge;

    //     // run test
    //     ZuoraTCVAndPaymentSchedule.OpportunityQuotesWrapper oqw = ZuoraTCVAndPaymentSchedule.generateOpportunityQuotesWrapper(testOpportunity.Id);
    //     ZuoraTCVAndPaymentSchedule.buildSTRPListForNewPrintSubs(oqw.quotesWrapperList[0]);
    // }


    // @isTest static void test_PrintNonMonthly() {
        
    //     Test.startTest();
    //     // Zuora test data
    //     Product2 testProduct = TestClassUtility.createLocalProduct2(true);
    //     zqu__ProductRatePlan__c testProductRatePlan = TestClassUtility.createProductRatePlan(true, testProduct);
    //     zqu__ProductRatePlanCharge__c testProductRatePlanCharge = TestClassUtility.createProductRatePlanCharge(true, testProductRatePlan);

    //     // Quote test data
    //     Market__c testMarket = TestClassUtility.createMarket(false);
    //     testMarket.Market_Id__c = '222';
    //     insert testMarket;

    //     TestClassUtility.generateQuotePdfConfig(true); 
        
    //     Account testAccount = TestClassUtility.createAccount(false);
    //     testAccount.shippingPostalCode = '78741';
    //     insert testAccount;

    //     Test.stopTest();

    //     Opportunity testOpportunity = TestClassUtility.createOpportunity(true, testAccount);
    //     Contact testContact = TestClassUtility.createContact(true, testAccount);
    //     TestClassUtility.createAccountContactRole(true, testAccount, testContact);
    //     Zuora__CustomerAccount__c testCustomerAccount = TestClassUtility.createCustomerAccount(true, testAccount);
    //     zqu__Quote__c testQuote = TestClassUtility.createQuote(false, testOpportunity, testAccount, testContact);
    //     testQuote.zqu__BillCycleDay__c = '11';
    //     testQuote.zqu__StartDate__c = Date.today();
    //     testQuote.zqu__Customer_Acceptance_Date__c = Date.today();
    //     testQuote.zqu__InitialTerm__c = 12.00;
    //     testQuote.zqu__Service_Activation_Date__c = Date.today();
    //     testQuote.zqu__Subscription_Term_Type__c = 'Termed';
    //     testQuote.zqu__ZuoraAccountID__c = '';
    //     insert testQuote;

    //     zqu__QuoteAmendment__c testQuoteAmendment = TestClassUtility.createQuoteAmendment(true, testQuote);
    //     zqu__QuoteRatePlan__c testQuoteRatePlan = TestClassUtility.createQuoteRatePlan(true, testQuote, testProductRatePlan, testQuoteAmendment);
        
    //     zqu__QuoteRatePlanCharge__c testQuoteRatePlanCharge = TestClassUtility.createQuoteRatePlanCharge(false, testQuoteRatePlan, testProductRatePlanCharge);
    //     testQuoteRatePlanCharge.zqu__Period__c = 'Month';
    //     testQuoteRatePlanCharge.zqu__SubscriptionRatePlanChargeZuoraId__c = 'adkfadsjfdasfsadf32424';
    //     testQuoteRatePlanCharge.zqu__Total__c = 19.89;
    //     testQuoteRatePlanCharge.zqu__BillingPeriodAlignment__c = 'AlignToSubscriptionStart';
    //     insert testQuoteRatePlanCharge;

    //     // run test for new account
    //     ZuoraTCVAndPaymentSchedule.OpportunityQuotesWrapper oqw = ZuoraTCVAndPaymentSchedule.generateOpportunityQuotesWrapper(testOpportunity.Id);
    //     ZuoraTCVAndPaymentSchedule.buildSTRPListForNewPrintSubs(oqw.quotesWrapperList[0]);

    //     // run test for existing account
    //     testQuote.zqu__ZuoraAccountID__c = 'adfsaudfdsf';
    //     update testQuote;
    //     oqw = ZuoraTCVAndPaymentSchedule.generateOpportunityQuotesWrapper(testOpportunity.Id);
    //     ZuoraTCVAndPaymentSchedule.buildSTRPListForNewPrintSubs(oqw.quotesWrapperList[0]);
    // }


    // @isTest static void test_DirectMail() {
        
    //     Test.startTest();

    //     // Zuora test data
    //     Product2 testProduct = TestClassUtility.createLocalProduct2(true);
    //     zqu__ProductRatePlan__c testProductRatePlan = TestClassUtility.createProductRatePlan(true, testProduct);
    //     zqu__ProductRatePlanCharge__c testProductRatePlanCharge = TestClassUtility.createProductRatePlanCharge(true, testProductRatePlan);

    //     // Quote test data
    //     Market__c testMarket = TestClassUtility.createMarket(false);
    //     testMarket.Market_Id__c = '222';
    //     insert testMarket;

    //     TestClassUtility.generateQuotePdfConfig(true); 
        
    //     Account testAccount = TestClassUtility.createAccount(false);
    //     testAccount.shippingPostalCode = '78741';
    //     insert testAccount;

    //     Test.stopTest();

    //     Opportunity testOpportunity = TestClassUtility.createOpportunity(true, testAccount);
    //     Contact testContact = TestClassUtility.createContact(true, testAccount);
    //     TestClassUtility.createAccountContactRole(true, testAccount, testContact);
    //     Zuora__CustomerAccount__c testCustomerAccount = TestClassUtility.createCustomerAccount(true, testAccount);
    //     zqu__Quote__c testQuote = TestClassUtility.createQuote(false, testOpportunity, testAccount, testContact);
    //     testQuote.zqu__BillCycleDay__c = '11';
    //     testQuote.zqu__StartDate__c = Date.today();
    //     testQuote.zqu__Customer_Acceptance_Date__c = Date.today();
    //     testQuote.zqu__InitialTerm__c = 12.00;
    //     testQuote.zqu__Service_Activation_Date__c = Date.today();
    //     testQuote.zqu__Subscription_Term_Type__c = 'Termed';
    //     testQuote.zqu__ZuoraAccountID__c = '';
    //     insert testQuote;

    //     zqu__QuoteAmendment__c testQuoteAmendment = TestClassUtility.createQuoteAmendment(true, testQuote);
    //     zqu__QuoteRatePlan__c testQuoteRatePlan = TestClassUtility.createQuoteRatePlan(true, testQuote, testProductRatePlan, testQuoteAmendment);
        
    //     zqu__QuoteRatePlanCharge__c testQuoteRatePlanCharge = TestClassUtility.createQuoteRatePlanCharge(false, testQuoteRatePlan, testProductRatePlanCharge);
    //     testQuoteRatePlanCharge.zqu__Period__c = 'Month';
    //     testQuoteRatePlanCharge.zqu__SubscriptionRatePlanChargeZuoraId__c = 'adkfadsjfdasfsadf32424';
    //     testQuoteRatePlanCharge.zqu__Total__c = 19.89;
    //     testQuoteRatePlanCharge.zqu__BillingPeriodAlignment__c = 'AlignToSubscriptionStart';
    //     insert testQuoteRatePlanCharge;

    //     zqu__QuoteRatePlanCharge__c testQuoteRatePlanCharge2 = TestClassUtility.createQuoteRatePlanCharge(false, testQuoteRatePlan, testProductRatePlanCharge);
    //     testQuoteRatePlanCharge2.zqu__Period__c = 'Month';
    //     testQuoteRatePlanCharge2.zqu__SubscriptionRatePlanChargeZuoraId__c = 'adkfadsjfdasfsadf32424';
    //     testQuoteRatePlanCharge2.zqu__Total__c = 19.89;
    //     testQuoteRatePlanCharge2.zqu__BillingPeriodAlignment__c = 'AlignToSubscriptionStart';
    //     testQuoteRatePlanCharge2.zqu__TriggerEvent__c = 'AlignToSubscriptionStart';
    //     testQuoteRatePlanCharge2.zqu__TriggerDate__c = Date.today();
    //     insert testQuoteRatePlanCharge2;

    //     // run test for new account
    //     ZuoraTCVAndPaymentSchedule.OpportunityQuotesWrapper oqw = ZuoraTCVAndPaymentSchedule.generateOpportunityQuotesWrapper(testOpportunity.Id);
    //     ZuoraTCVAndPaymentSchedule.buildSTRPListForNewDirectMailSubs(oqw.quotesWrapperList[0]);
    // }

    // @isTest static void test_AmendmentSubWrapperAddUpdateRemove() {
        
    //     // Zuora test data
    //     Product2 testProduct = TestClassUtility.createLocalProduct2(true);
    //     zqu__ProductRatePlan__c testProductRatePlan = TestClassUtility.createProductRatePlan(true, testProduct);
    //     zqu__ProductRatePlanCharge__c testProductRatePlanCharge = TestClassUtility.createProductRatePlanCharge(true, testProductRatePlan);

    //     // Quote test data
    //     Market__c testMarket = TestClassUtility.createMarket(false);
    //     testMarket.Market_Id__c = '222';
    //     insert testMarket;

    //     TestClassUtility.generateQuotePdfConfig(true); 
        
    //     Account testAccount = TestClassUtility.createAccount(false);
    //     testAccount.shippingPostalCode = '78741';
    //     insert testAccount;


    //     Opportunity testOpportunity = TestClassUtility.createOpportunity(true, testAccount);
    //     Contact testContact = TestClassUtility.createContact(true, testAccount);
    //     TestClassUtility.createAccountContactRole(true, testAccount, testContact);
    //     Zuora__CustomerAccount__c testCustomerAccount = TestClassUtility.createCustomerAccount(true, testAccount);
    //     zqu__Quote__c testQuote = TestClassUtility.createQuote(false, testOpportunity, testAccount, testContact);
    //     testQuote.zqu__BillCycleDay__c = '11';
    //     testQuote.zqu__StartDate__c = Date.today();
    //     testQuote.zqu__Customer_Acceptance_Date__c = Date.today();
    //     testQuote.zqu__InitialTerm__c = 12.00;
    //     testQuote.zqu__Service_Activation_Date__c = Date.today();
    //     testQuote.zqu__Subscription_Term_Type__c = 'Termed';
    //     testQuote.zqu__ZuoraAccountID__c = '';
    //     insert testQuote;

    //     // update amendment data
    //     zqu__QuoteAmendment__c testQuoteAmendment = TestClassUtility.createQuoteAmendment(true, testQuote);
    //     zqu__QuoteRatePlan__c testQuoteRatePlan = TestClassUtility.createQuoteRatePlan(false, testQuote, testProductRatePlan, testQuoteAmendment);
    //     testQuoteRatePlan.zqu__SubscriptionRatePlanZuoraId__c = 'aodsifujadslfkadsjfsadf';
    //     testQuoteRatePlan.zqu__AmendmentType__c = 'Update';
    //     insert testQuoteRatePlan;
        
    //     zqu__QuoteRatePlanCharge__c testQuoteRatePlanCharge = TestClassUtility.createQuoteRatePlanCharge(false, testQuoteRatePlan, testProductRatePlanCharge);
    //     testQuoteRatePlanCharge.zqu__Period__c = 'Month';
    //     testQuoteRatePlanCharge.zqu__SubscriptionRatePlanChargeZuoraId__c = 'adkfadsjfdasfsadf32424';
    //     testQuoteRatePlanCharge.zqu__Total__c = 19.89;
    //     testQuoteRatePlanCharge.zqu__BillingPeriodAlignment__c = 'AlignToSubscriptionStart';
    //     insert testQuoteRatePlanCharge;

    //     // remove amendment data
    //     zqu__QuoteAmendment__c testQuoteAmendment2 = TestClassUtility.createQuoteAmendment(true, testQuote);
    //     zqu__QuoteRatePlan__c testQuoteRatePlan2 = TestClassUtility.createQuoteRatePlan(false, testQuote, testProductRatePlan, testQuoteAmendment2);
    //     testQuoteRatePlan2.zqu__AmendmentType__c = 'Remove';
    //     insert testQuoteRatePlan2;
        
    //     Test.startTest();

    //     zqu__QuoteRatePlanCharge__c testQuoteRatePlanCharge2 = TestClassUtility.createQuoteRatePlanCharge(false, testQuoteRatePlan2, testProductRatePlanCharge);
    //     testQuoteRatePlanCharge2.zqu__Period__c = 'Month';
    //     testQuoteRatePlanCharge2.zqu__SubscriptionRatePlanChargeZuoraId__c = 'adkfadsjfdasfsadf32424';
    //     testQuoteRatePlanCharge2.zqu__Total__c = 19.89;
    //     testQuoteRatePlanCharge2.zqu__BillingPeriodAlignment__c = 'AlignToSubscriptionStart';
    //     insert testQuoteRatePlanCharge2;

    //     // add amendment data
    //     zqu__QuoteAmendment__c testQuoteAmendment3 = TestClassUtility.createQuoteAmendment(true, testQuote);
    //     zqu__QuoteRatePlan__c testQuoteRatePlan3 = TestClassUtility.createQuoteRatePlan(false, testQuote, testProductRatePlan, testQuoteAmendment3);
    //     testQuoteRatePlan3.zqu__AmendmentType__c = 'new';
    //     insert testQuoteRatePlan3;
        
    //     zqu__QuoteRatePlanCharge__c testQuoteRatePlanCharge3 = TestClassUtility.createQuoteRatePlanCharge(false, testQuoteRatePlan3, testProductRatePlanCharge);
    //     testQuoteRatePlanCharge3.zqu__Period__c = 'Month';
    //     testQuoteRatePlanCharge3.zqu__SubscriptionRatePlanChargeZuoraId__c = 'adkfadsjfdasfsadf32424';
    //     testQuoteRatePlanCharge3.zqu__Total__c = 19.89;
    //     testQuoteRatePlanCharge3.zqu__BillingPeriodAlignment__c = 'AlignToSubscriptionStart';
    //     insert testQuoteRatePlanCharge3;

        

    //     ZuoraTCVAndPaymentSchedule.OpportunityQuotesWrapper oqw = ZuoraTCVAndPaymentSchedule.generateOpportunityQuotesWrapper(testOpportunity.Id);
    //     ZuoraTCVAndPaymentSchedule.buildAmendmentSubWrapper(oqw.quotesWrapperList[0]);

    //     Test.stopTest();
    // }

    // @isTest static void test_AmendmentSubWrapperUpdateRemove() {
        
    //     Test.startTest();
    //     // Zuora test data
    //     Product2 testProduct = TestClassUtility.createLocalProduct2(true);
    //     zqu__ProductRatePlan__c testProductRatePlan = TestClassUtility.createProductRatePlan(true, testProduct);
    //     zqu__ProductRatePlanCharge__c testProductRatePlanCharge = TestClassUtility.createProductRatePlanCharge(true, testProductRatePlan);

    //     // Quote test data
    //     Market__c testMarket = TestClassUtility.createMarket(false);
    //     testMarket.Market_Id__c = '222';
    //     insert testMarket;

    //     TestClassUtility.generateQuotePdfConfig(true); 
        
    //     Account testAccount = TestClassUtility.createAccount(false);
    //     testAccount.shippingPostalCode = '78741';
    //     insert testAccount;
        
    //     Test.stopTest();

    //     Opportunity testOpportunity = TestClassUtility.createOpportunity(true, testAccount);
    //     Contact testContact = TestClassUtility.createContact(true, testAccount);
    //     TestClassUtility.createAccountContactRole(true, testAccount, testContact);
    //     Zuora__CustomerAccount__c testCustomerAccount = TestClassUtility.createCustomerAccount(true, testAccount);
    //     zqu__Quote__c testQuote = TestClassUtility.createQuote(false, testOpportunity, testAccount, testContact);
    //     testQuote.zqu__BillCycleDay__c = '11';
    //     testQuote.zqu__StartDate__c = Date.today();
    //     testQuote.zqu__Customer_Acceptance_Date__c = Date.today();
    //     testQuote.zqu__InitialTerm__c = 12.00;
    //     testQuote.zqu__Service_Activation_Date__c = Date.today();
    //     testQuote.zqu__Subscription_Term_Type__c = 'Termed';
    //     testQuote.zqu__ZuoraAccountID__c = '';
    //     insert testQuote;

    //     // update amendment data
    //     zqu__QuoteAmendment__c testQuoteAmendment = TestClassUtility.createQuoteAmendment(true, testQuote);
    //     zqu__QuoteRatePlan__c testQuoteRatePlan = TestClassUtility.createQuoteRatePlan(false, testQuote, testProductRatePlan, testQuoteAmendment);
    //     testQuoteRatePlan.zqu__SubscriptionRatePlanZuoraId__c = 'aodsifujadslfkadsjfsadf';
    //     testQuoteRatePlan.zqu__AmendmentType__c = 'Update';
    //     insert testQuoteRatePlan;
        
    //     zqu__QuoteRatePlanCharge__c testQuoteRatePlanCharge = TestClassUtility.createQuoteRatePlanCharge(false, testQuoteRatePlan, testProductRatePlanCharge);
    //     testQuoteRatePlanCharge.zqu__Period__c = 'Month';
    //     testQuoteRatePlanCharge.zqu__SubscriptionRatePlanChargeZuoraId__c = 'adkfadsjfdasfsadf32424';
    //     testQuoteRatePlanCharge.zqu__Total__c = 19.89;
    //     testQuoteRatePlanCharge.zqu__BillingPeriodAlignment__c = 'AlignToSubscriptionStart';
    //     insert testQuoteRatePlanCharge;

    //     // remove amendment data
    //     zqu__QuoteAmendment__c testQuoteAmendment2 = TestClassUtility.createQuoteAmendment(true, testQuote);
    //     zqu__QuoteRatePlan__c testQuoteRatePlan2 = TestClassUtility.createQuoteRatePlan(false, testQuote, testProductRatePlan, testQuoteAmendment2);
    //     testQuoteRatePlan2.zqu__AmendmentType__c = 'Remove';
    //     insert testQuoteRatePlan2;
        
    //     zqu__QuoteRatePlanCharge__c testQuoteRatePlanCharge2 = TestClassUtility.createQuoteRatePlanCharge(false, testQuoteRatePlan2, testProductRatePlanCharge);
    //     testQuoteRatePlanCharge2.zqu__Period__c = 'Month';
    //     testQuoteRatePlanCharge2.zqu__SubscriptionRatePlanChargeZuoraId__c = 'adkfadsjfdasfsadf32424';
    //     testQuoteRatePlanCharge2.zqu__Total__c = 19.89;
    //     testQuoteRatePlanCharge2.zqu__BillingPeriodAlignment__c = 'AlignToSubscriptionStart';
    //     insert testQuoteRatePlanCharge2;

    //     ZuoraTCVAndPaymentSchedule.OpportunityQuotesWrapper oqw = ZuoraTCVAndPaymentSchedule.generateOpportunityQuotesWrapper(testOpportunity.Id);
    //     ZuoraTCVAndPaymentSchedule.buildAmendmentSubWrapper(oqw.quotesWrapperList[0]);
    // }


    // @isTest static void test_AmendmentSubWrapperAddUpdate() {
    //     Test.startTest();
    //         // Zuora test data
    //         Product2 testProduct = TestClassUtility.createLocalProduct2(true);
    //         zqu__ProductRatePlan__c testProductRatePlan = TestClassUtility.createProductRatePlan(true, testProduct);
    //         zqu__ProductRatePlanCharge__c testProductRatePlanCharge = TestClassUtility.createProductRatePlanCharge(true, testProductRatePlan);

    //         // Quote test data
    //         Market__c testMarket = TestClassUtility.createMarket(false);
    //         testMarket.Market_Id__c = '222';
    //         insert testMarket;

    //         TestClassUtility.generateQuotePdfConfig(true); 
            
    //         Account testAccount = TestClassUtility.createAccount(false);
    //         testAccount.shippingPostalCode = '78741';
    //         insert testAccount;

    //         Opportunity testOpportunity = TestClassUtility.createOpportunity(true, testAccount);
    //         Contact testContact = TestClassUtility.createContact(true, testAccount);
    //         TestClassUtility.createAccountContactRole(true, testAccount, testContact);
    //         Zuora__CustomerAccount__c testCustomerAccount = TestClassUtility.createCustomerAccount(true, testAccount);
    //         zqu__Quote__c testQuote = TestClassUtility.createQuote(false, testOpportunity, testAccount, testContact);
    //         testQuote.zqu__BillCycleDay__c = '11';
    //         testQuote.zqu__StartDate__c = Date.today();
    //         testQuote.zqu__Customer_Acceptance_Date__c = Date.today();
    //         testQuote.zqu__InitialTerm__c = 12.00;
    //         testQuote.zqu__Service_Activation_Date__c = Date.today();
    //         testQuote.zqu__Subscription_Term_Type__c = 'Termed';
    //         testQuote.zqu__ZuoraAccountID__c = '';
    //         insert testQuote;
    //     Test.stopTest();

    //     // update amendment data
    //     zqu__QuoteAmendment__c testQuoteAmendment = TestClassUtility.createQuoteAmendment(true, testQuote);
    //     zqu__QuoteRatePlan__c testQuoteRatePlan = TestClassUtility.createQuoteRatePlan(false, testQuote, testProductRatePlan, testQuoteAmendment);
    //     testQuoteRatePlan.zqu__SubscriptionRatePlanZuoraId__c = 'aodsifujadslfkadsjfsadf';
    //     testQuoteRatePlan.zqu__AmendmentType__c = 'Update';
    //     insert testQuoteRatePlan;
        
    //     zqu__QuoteRatePlanCharge__c testQuoteRatePlanCharge = TestClassUtility.createQuoteRatePlanCharge(false, testQuoteRatePlan, testProductRatePlanCharge);
    //     testQuoteRatePlanCharge.zqu__Period__c = 'Month';
    //     testQuoteRatePlanCharge.zqu__SubscriptionRatePlanChargeZuoraId__c = 'adkfadsjfdasfsadf32424';
    //     testQuoteRatePlanCharge.zqu__Total__c = 19.89;
    //     testQuoteRatePlanCharge.zqu__BillingPeriodAlignment__c = 'AlignToSubscriptionStart';
    //     insert testQuoteRatePlanCharge;

    //     // add amendment data
    //     zqu__QuoteAmendment__c testQuoteAmendment3 = TestClassUtility.createQuoteAmendment(true, testQuote);
    //     zqu__QuoteRatePlan__c testQuoteRatePlan3 = TestClassUtility.createQuoteRatePlan(false, testQuote, testProductRatePlan, testQuoteAmendment3);
    //     testQuoteRatePlan3.zqu__AmendmentType__c = 'new';
    //     insert testQuoteRatePlan3;
        
    //     zqu__QuoteRatePlanCharge__c testQuoteRatePlanCharge3 = TestClassUtility.createQuoteRatePlanCharge(false, testQuoteRatePlan3, testProductRatePlanCharge);
    //     testQuoteRatePlanCharge3.zqu__Period__c = 'Month';
    //     testQuoteRatePlanCharge3.zqu__SubscriptionRatePlanChargeZuoraId__c = 'adkfadsjfdasfsadf32424';
    //     testQuoteRatePlanCharge3.zqu__Total__c = 19.89;
    //     testQuoteRatePlanCharge3.zqu__BillingPeriodAlignment__c = 'AlignToSubscriptionStart';
    //     insert testQuoteRatePlanCharge3;

    //     ZuoraTCVAndPaymentSchedule.OpportunityQuotesWrapper oqw = ZuoraTCVAndPaymentSchedule.generateOpportunityQuotesWrapper(testOpportunity.Id);
    //     ZuoraTCVAndPaymentSchedule.buildAmendmentSubWrapper(oqw.quotesWrapperList[0]);

    //     // lastly, get coverage for remove amendment only
    //     delete testQuoteRatePlanCharge3;
    //     delete testQuoteRatePlan3;
    //     oqw = ZuoraTCVAndPaymentSchedule.generateOpportunityQuotesWrapper(testOpportunity.Id);
    //     ZuoraTCVAndPaymentSchedule.buildAmendmentSubWrapper(oqw.quotesWrapperList[0]);
    // }


    // @isTest static void test_AmendmentSubWrapperAddRemove() {
        
    //     Test.startTest();
    //         // Zuora test data
    //         Product2 testProduct = TestClassUtility.createLocalProduct2(true);
    //         zqu__ProductRatePlan__c testProductRatePlan = TestClassUtility.createProductRatePlan(true, testProduct);
    //         zqu__ProductRatePlanCharge__c testProductRatePlanCharge = TestClassUtility.createProductRatePlanCharge(true, testProductRatePlan);

    //         // Quote test data
    //         Market__c testMarket = TestClassUtility.createMarket(false);
    //         testMarket.Market_Id__c = '222';
    //         insert testMarket;

    //         TestClassUtility.generateQuotePdfConfig(true); 
            
    //         Account testAccount = TestClassUtility.createAccount(false);
    //         testAccount.shippingPostalCode = '78741';
    //         insert testAccount;

    //         Opportunity testOpportunity = TestClassUtility.createOpportunity(true, testAccount);
    //         Contact testContact = TestClassUtility.createContact(true, testAccount);
    //         TestClassUtility.createAccountContactRole(true, testAccount, testContact);
    //         Zuora__CustomerAccount__c testCustomerAccount = TestClassUtility.createCustomerAccount(true, testAccount);
    //         zqu__Quote__c testQuote = TestClassUtility.createQuote(false, testOpportunity, testAccount, testContact);
    //         testQuote.zqu__BillCycleDay__c = '11';
    //         testQuote.zqu__StartDate__c = Date.today();
    //         testQuote.zqu__Customer_Acceptance_Date__c = Date.today();
    //         testQuote.zqu__InitialTerm__c = 12.00;
    //         testQuote.zqu__Service_Activation_Date__c = Date.today();
    //         testQuote.zqu__Subscription_Term_Type__c = 'Termed';
    //         testQuote.zqu__ZuoraAccountID__c = '';
    //         insert testQuote;
    //     Test.stopTest();

    //     // remove amendment data
    //     zqu__QuoteAmendment__c testQuoteAmendment2 = TestClassUtility.createQuoteAmendment(true, testQuote);
    //     zqu__QuoteRatePlan__c testQuoteRatePlan2 = TestClassUtility.createQuoteRatePlan(false, testQuote, testProductRatePlan, testQuoteAmendment2);
    //     testQuoteRatePlan2.zqu__AmendmentType__c = 'Remove';
    //     insert testQuoteRatePlan2;
        
    //     zqu__QuoteRatePlanCharge__c testQuoteRatePlanCharge2 = TestClassUtility.createQuoteRatePlanCharge(false, testQuoteRatePlan2, testProductRatePlanCharge);
    //     testQuoteRatePlanCharge2.zqu__Period__c = 'Month';
    //     testQuoteRatePlanCharge2.zqu__SubscriptionRatePlanChargeZuoraId__c = 'adkfadsjfdasfsadf32424';
    //     testQuoteRatePlanCharge2.zqu__Total__c = 19.89;
    //     testQuoteRatePlanCharge2.zqu__BillingPeriodAlignment__c = 'AlignToSubscriptionStart';
    //     insert testQuoteRatePlanCharge2;

    //     // add amendment data
    //     zqu__QuoteAmendment__c testQuoteAmendment3 = TestClassUtility.createQuoteAmendment(true, testQuote);
    //     zqu__QuoteRatePlan__c testQuoteRatePlan3 = TestClassUtility.createQuoteRatePlan(false, testQuote, testProductRatePlan, testQuoteAmendment3);
    //     testQuoteRatePlan3.zqu__AmendmentType__c = 'new';
    //     insert testQuoteRatePlan3;
        
    //     zqu__QuoteRatePlanCharge__c testQuoteRatePlanCharge3 = TestClassUtility.createQuoteRatePlanCharge(false, testQuoteRatePlan3, testProductRatePlanCharge);
    //     testQuoteRatePlanCharge3.zqu__Period__c = 'Month';
    //     testQuoteRatePlanCharge3.zqu__SubscriptionRatePlanChargeZuoraId__c = 'adkfadsjfdasfsadf32424';
    //     testQuoteRatePlanCharge3.zqu__Total__c = 19.89;
    //     testQuoteRatePlanCharge3.zqu__BillingPeriodAlignment__c = 'AlignToSubscriptionStart';
    //     insert testQuoteRatePlanCharge3;

    //     ZuoraTCVAndPaymentSchedule.OpportunityQuotesWrapper oqw = ZuoraTCVAndPaymentSchedule.generateOpportunityQuotesWrapper(testOpportunity.Id);
    //     ZuoraTCVAndPaymentSchedule.buildAmendmentSubWrapper(oqw.quotesWrapperList[0]);

    //     // lastly, get coverage for remove amendment only
    //     delete testQuoteRatePlanCharge3;
    //     delete testQuoteRatePlan3;
    //     oqw = ZuoraTCVAndPaymentSchedule.generateOpportunityQuotesWrapper(testOpportunity.Id);
    //     ZuoraTCVAndPaymentSchedule.buildAmendmentSubWrapper(oqw.quotesWrapperList[0]);
    // }

    // @isTest static void test_BuildWrappers() {
        
    //     Test.startTest();
    //     // Zuora test data
    //     Product2 testProduct = TestClassUtility.createLocalProduct2(true);
    //     zqu__ProductRatePlan__c testProductRatePlan = TestClassUtility.createProductRatePlan(true, testProduct);
    //     zqu__ProductRatePlanCharge__c testProductRatePlanCharge = TestClassUtility.createProductRatePlanCharge(true, testProductRatePlan);

    //     // Quote test data
    //     Market__c testMarket = TestClassUtility.createMarket(false);
    //     testMarket.Market_Id__c = '222';
    //     insert testMarket;

    //     TestClassUtility.generateQuotePdfConfig(true); 
        
    //     Account testAccount = TestClassUtility.createAccount(false);
    //     testAccount.shippingPostalCode = '78741';
    //     insert testAccount;

    //     Test.stopTest();

    //     Opportunity testOpportunity = TestClassUtility.createOpportunity(true, testAccount);
    //     Contact testContact = TestClassUtility.createContact(true, testAccount);
    //     TestClassUtility.createAccountContactRole(true, testAccount, testContact);
    //     Zuora__CustomerAccount__c testCustomerAccount = TestClassUtility.createCustomerAccount(true, testAccount);
    //     zqu__Quote__c testQuote = TestClassUtility.createQuote(false, testOpportunity, testAccount, testContact);
    //     testQuote.zqu__BillCycleDay__c = '11';
    //     testQuote.zqu__StartDate__c = Date.today();
    //     testQuote.zqu__Customer_Acceptance_Date__c = Date.today();
    //     testQuote.zqu__InitialTerm__c = 12.00;
    //     testQuote.zqu__Service_Activation_Date__c = Date.today();
    //     testQuote.zqu__Subscription_Term_Type__c = 'Termed';
    //     testQuote.zqu__ZuoraAccountID__c = '';
    //     insert testQuote;

    //     // remove amendment data
    //     zqu__QuoteAmendment__c testQuoteAmendment2 = TestClassUtility.createQuoteAmendment(true, testQuote);
    //     zqu__QuoteRatePlan__c testQuoteRatePlan2 = TestClassUtility.createQuoteRatePlan(false, testQuote, testProductRatePlan, testQuoteAmendment2);
    //     testQuoteRatePlan2.zqu__AmendmentType__c = 'Remove';
    //     insert testQuoteRatePlan2;
        
    //     zqu__QuoteRatePlanCharge__c testQuoteRatePlanCharge2 = TestClassUtility.createQuoteRatePlanCharge(false, testQuoteRatePlan2, testProductRatePlanCharge);
    //     testQuoteRatePlanCharge2.zqu__Period__c = 'Month';
    //     testQuoteRatePlanCharge2.zqu__SubscriptionRatePlanChargeZuoraId__c = 'adkfadsjfdasfsadf32424';
    //     testQuoteRatePlanCharge2.zqu__Total__c = 19.89;
    //     testQuoteRatePlanCharge2.zqu__BillingPeriodAlignment__c = 'AlignToSubscriptionStart';
    //     insert testQuoteRatePlanCharge2;

    //     // add amendment data
    //     zqu__QuoteAmendment__c testQuoteAmendment3 = TestClassUtility.createQuoteAmendment(true, testQuote);
    //     zqu__QuoteRatePlan__c testQuoteRatePlan3 = TestClassUtility.createQuoteRatePlan(false, testQuote, testProductRatePlan, testQuoteAmendment3);
    //     testQuoteRatePlan3.zqu__AmendmentType__c = 'new';
    //     insert testQuoteRatePlan3;
        
    //     zqu__QuoteRatePlanCharge__c testQuoteRatePlanCharge3 = TestClassUtility.createQuoteRatePlanCharge(false, testQuoteRatePlan3, testProductRatePlanCharge);
    //     testQuoteRatePlanCharge3.zqu__Period__c = 'Month';
    //     testQuoteRatePlanCharge3.zqu__SubscriptionRatePlanChargeZuoraId__c = 'adkfadsjfdasfsadf32424';
    //     testQuoteRatePlanCharge3.zqu__Total__c = 19.89;
    //     testQuoteRatePlanCharge3.zqu__BillingPeriodAlignment__c = 'AlignToSubscriptionStart';
    //     insert testQuoteRatePlanCharge3;

    //     ZuoraTCVAndPaymentSchedule.OpportunityQuotesWrapper oqw = ZuoraTCVAndPaymentSchedule.generateOpportunityQuotesWrapper(testOpportunity.Id);
    //     oqw.quotesWrapperList[0].quoteProductLine = 'Print';
    //     ZuoraTCVAndPaymentSchedule.buildNewAccountNewSubWrapper(oqw.quotesWrapperList[0]);
    //     ZuoraTCVAndPaymentSchedule.buildExistingAccountNewSubWrapper(oqw.quotesWrapperList[0]);
    //     oqw.quotesWrapperList[0].quoteProductLine = 'Direct Mail';
    //     ZuoraTCVAndPaymentSchedule.buildNewAccountNewSubWrapper(oqw.quotesWrapperList[0]);
    //     ZuoraTCVAndPaymentSchedule.buildExistingAccountNewSubWrapper(oqw.quotesWrapperList[0]);
    // }

    // @isTest static void test_getZuoraEndpointBaseURL() {
    //     generateZuoraEnvironmentURLList(true);
    //     ZuoraTCVAndPaymentSchedule.getZuoraRESTAPIPath();
    //     List<Zuora_Environment_URL__c> nonSandboxDefaultList = new List<Zuora_Environment_URL__c>();
    //     Map<String, Zuora_Environment_URL__c> zuoraEnvMap = Zuora_Environment_URL__c.getAll();
    //     for (String key : zuoraEnvMap.keySet()) {
    //         if (key != 'SandboxDefault') {
    //             nonSandboxDefaultList.add(zuoraEnvMap.get(key));
    //         }
    //     }
    //     delete nonSandboxDefaultList;
    //     ZuoraTCVAndPaymentSchedule.getZuoraRESTAPIPath();
    // }

    // @isTest static void test_ZuoraSubscriptionPreview() {
    //     ZuoraSubscriptionPreview zsp = new ZuoraSubscriptionPreview();
    //     zsp.success = true;
    //     System.assertNotEquals(null, zsp);
    // }

    private static List<Zuora_Environment_URL__c> generateZuoraEnvironmentURLList(Boolean insertList) {
        List<Zuora_Environment_URL__c> zuoraEnvURLList = new List<Zuora_Environment_URL__c>();
        // SandboxDefault
        Zuora_Environment_URL__c sandboxDefault = new Zuora_Environment_URL__c();
        sandboxDefault.Name = 'SandboxDefault';
        sandboxDefault.Zuora_Base_URL__c = 'https://apisandbox-api.zuora.com';
        sandboxDefault.Zuora_REST_API_Path__c = '/rest';
        zuoraEnvURLList.add(sandboxDefault);
        // BeCreative
        Zuora_Environment_URL__c beCreative = new Zuora_Environment_URL__c();
        beCreative.Name = 'BeCreative';
        beCreative.Zuora_Base_URL__c = 'https://apisandbox-api.zuora.com';
        beCreative.Zuora_REST_API_Path__c = '/rest';
        zuoraEnvURLList.add(beCreative);
        // UAT
        Zuora_Environment_URL__c uat = new Zuora_Environment_URL__c();
        uat.Name = 'UAT';
        uat.Zuora_Base_URL__c = 'https://services421.zuora.com';
        uat.Zuora_REST_API_Path__c = '/apps';
        zuoraEnvURLList.add(uat);
        // Production
        Zuora_Environment_URL__c production = new Zuora_Environment_URL__c();
        production.Name = 'Production';
        production.Zuora_Base_URL__c = 'https://api.zuora.com';
        production.Zuora_REST_API_Path__c = '/rest';
        zuoraEnvURLList.add(production);
        if (insertList) {
            insert zuoraEnvURLList;
        }
        return zuoraEnvURLList;         
    }   
}