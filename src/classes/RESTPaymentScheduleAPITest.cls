@isTest
private class RESTPaymentScheduleAPITest {
	
	@isTest
	static void testGeneratePaymentSchedulePDF() {

		TestClassUtility.DISABLE_TRIGGERS = true;

		// Zuora test data
		Product2 testProduct = TestClassUtility.createProduct2(true);
		zqu__ProductRatePlan__c testProductRatePlan = TestClassUtility.createProductRatePlan(true, testProduct);
		zqu__ProductRatePlanCharge__c testProductRatePlanCharge = TestClassUtility.createProductRatePlanCharge(true, testProductRatePlan);

		// Quote test data
		Market__c testMarket = TestClassUtility.createMarket(false);
		testMarket.Market_Id__c = '222';
		insert testMarket;

		TestClassUtility.generateQuotePdfConfig(true); 
		
		Account testAccount = TestClassUtility.createAccount(false);
		testAccount.shippingPostalCode = '78741';
		insert testAccount;

		Opportunity testOpportunity = TestClassUtility.createOpportunity(true, testAccount);
		Contact testContact = TestClassUtility.createContact(true, testAccount);
		TestClassUtility.createAccountContactRole(true, testAccount, testContact);
		Zuora__CustomerAccount__c testCustomerAccount = TestClassUtility.createCustomerAccount(true, testAccount);
		zqu__Quote__c testQuote = TestClassUtility.createQuote(false, testOpportunity, testAccount, testContact);
		testQuote.zqu__BillCycleDay__c = '11';
		testQuote.zqu__StartDate__c = Date.today();
		testQuote.zqu__Customer_Acceptance_Date__c = Date.today();
		testQuote.zqu__InitialTerm__c = 12.00;
		testQuote.zqu__Service_Activation_Date__c = Date.today();
		testQuote.zqu__Subscription_Term_Type__c = 'Termed';
		insert testQuote;

		zqu__QuoteAmendment__c testQuoteAmendment = TestClassUtility.createQuoteAmendment(true, testQuote);
		zqu__QuoteRatePlan__c testQuoteRatePlan = TestClassUtility.createQuoteRatePlan(true, testQuote, testProductRatePlan, testQuoteAmendment);
		
		zqu__QuoteRatePlanCharge__c testQuoteRatePlanCharge = TestClassUtility.createQuoteRatePlanCharge(false, testQuoteRatePlan, testProductRatePlanCharge);
		testQuoteRatePlanCharge.zqu__Period__c = 'Semi-Annual';
		testQuoteRatePlanCharge.zqu__SubscriptionRatePlanChargeZuoraId__c = 'adkfadsjfdasfsadf32424';
		testQuoteRatePlanCharge.zqu__Total__c = 19.89;
		testQuoteRatePlanCharge.zqu__BillingPeriodAlignment__c = 'AlignToSubscriptionStart';
		insert testQuoteRatePlanCharge;

		RESTPaymentScheduleAPI.generatePaymentSchedulePDF(testQuote.Id, testOpportunity.Id, 'Test Quote');
	}
}