@isTest
private class ZuoraSubscriptionUtilityTest {
	@isTest 
	static void testGenerateRenewalQuoteFromSubcription_one() {
		/////////////////////
		// BUILD TEST DATA //
		/////////////////////
		Test.startTest();
		
		Generate_Quote_Pdf_Config__c gqpc = TestClassUtility.generateQuotePdfConfig(true);

    Account testAccount = TestClassUtility.createAccount(true);

    Contact testContact = TestClassUtility.createContact(true, testAccount);

    Zuora__CustomerAccount__c testCustomerAccount = TestClassUtility.createCustomerAccount(false);
    testCustomerAccount.Zuora__BillCycleDay__c = '10';
    insert testCustomerAccount;

    Opportunity testOpportunity = TestClassUtility.createOpportunity(false, testAccount, testContact);
    testOpportunity.Lost_Reason__c = 'Some Reason';
    testOpportunity.Lost_Reason_Details__c = 'Something';
    insert testOpportunity;

		TestClassUtility.generateInventoryExpireDateOffsets(true);
    
		TestClassUtility.createQuoteTemplate(true);

		Test.stopTest();

    zqu__Quote__c testQuote = TestClassUtility.createQuote(true, testOpportunity, testAccount, testContact);

    Zuora__ZInvoice__c testInvoice = TestClassUtility.createInvoice(true, testAccount, testCustomerAccount);

    Product2 testLocalProduct = TestClassUtility.createLocalProduct2(true);
		
    zqu__ProductRatePlan__c testProductRatePlan = TestClassUtility.createProductRatePlan(true, testLocalProduct);

    zqu__ProductRatePlanCharge__c testProductRatePlanCharge = TestClassUtility.createProductRatePlanCharge(true, testProductRatePlan);
    
    Zuora__Subscription__c testSubscription = TestClassUtility.createSubscription(true, testAccount);

    Zuora__Product__c testZuoraProduct = TestClassUtility.createZuoraProduct(true);

    Inventory__c testInventory = TestClassUtility.createInventory(true, testProductRatePlan);

    zqu__CommunicationProfile__c testzquCP =new zqu__CommunicationProfile__c();
    testzquCP.name = 'Default Profile';
    testzquCP.zqu__ZuoraId__c = '2c92c0f94e4d3a41014e655c389b63cp';
    insert testzquCP;

    Zuora__SubscriptionProductCharge__c testSubscriptionProductCharge1 = TestClassUtility.createSubscriptionProductCharge(true, testAccount, testSubscription, testZuoraProduct);

		zqu__Quote__c generatedQuote = ZuoraSubscriptionUtility.generateRenewalQuoteFromSubscription(testSubscription.Id, testOpportunity);
	}

	@isTest 
	static void testGenerateRenewalQuoteFromSubcription_two() {
		/////////////////////
		// BUILD TEST DATA //
		/////////////////////
		Test.startTest();
		
		Generate_Quote_Pdf_Config__c gqpc = TestClassUtility.generateQuotePdfConfig(true);

    Account testAccount = TestClassUtility.createAccount(true);

    Contact testContact = TestClassUtility.createContact(true, testAccount);

    Zuora__CustomerAccount__c testCustomerAccount = TestClassUtility.createCustomerAccount(false);
    testCustomerAccount.Zuora__BillCycleDay__c = '10';
    insert testCustomerAccount;

    Opportunity testOpportunity = TestClassUtility.createOpportunity(false, testAccount, testContact);
    testOpportunity.Lost_Reason__c = 'Some Reason';
    testOpportunity.Lost_Reason_Details__c = 'Something';
    insert testOpportunity;

		TestClassUtility.generateInventoryExpireDateOffsets(true);
    
		TestClassUtility.createQuoteTemplate(true);

		Test.stopTest();

    zqu__Quote__c testQuote = TestClassUtility.createQuote(true, testOpportunity, testAccount, testContact);

    Zuora__ZInvoice__c testInvoice = TestClassUtility.createInvoice(true, testAccount, testCustomerAccount);

    Product2 testLocalProduct = TestClassUtility.createLocalProduct2(true);
		
    zqu__ProductRatePlan__c testProductRatePlan = TestClassUtility.createProductRatePlan(true, testLocalProduct);

    zqu__ProductRatePlanCharge__c testProductRatePlanCharge = TestClassUtility.createProductRatePlanCharge(true, testProductRatePlan);
    
    Zuora__Subscription__c testSubscription = TestClassUtility.createSubscription(false, testAccount);
    testSubscription.Zuora__CustomerAccount__c = testCustomerAccount.Id;
    insert testSubscription;

    Zuora__Product__c testZuoraProduct = TestClassUtility.createZuoraProduct(true);

    Inventory__c testInventory = TestClassUtility.createInventory(true, testProductRatePlan);

    zqu__CommunicationProfile__c testzquCP =new zqu__CommunicationProfile__c();
    testzquCP.name = 'Default Profile';
    testzquCP.zqu__ZuoraId__c = '2c92c0f94e4d3a41014e655c389b63cp';
    insert testzquCP;

    List<Zuora__SubscriptionProductCharge__c> zspclist = new  List<Zuora__SubscriptionProductCharge__c> ();

    // Create Subscription Product Charge
    Zuora__SubscriptionProductCharge__c testSubscriptionProductCharge1 = TestClassUtility.createSubscriptionProductCharge(false, testAccount, testSubscription, testZuoraProduct);
		// Zuora__SubscriptionProductCharge__c testSubscriptionProductCharge2 = TestClassUtility.createSubscriptionProductCharge(false, testAccount, testSubscription, testZuoraProduct);
		// Zuora__SubscriptionProductCharge__c testSubscriptionProductCharge3 = TestClassUtility.createSubscriptionProductCharge(false, testAccount, testSubscription, testZuoraProduct);
		// Zuora__SubscriptionProductCharge__c testSubscriptionProductCharge4 = TestClassUtility.createSubscriptionProductCharge(false, testAccount, testSubscription, testZuoraProduct);

		zspclist.add(testSubscriptionProductCharge1);
		// zspclist.add(testSubscriptionProductCharge2);
		// zspclist.add(testSubscriptionProductCharge3);
		// zspclist.add(testSubscriptionProductCharge4);

		insert zspclist;


		zqu__Quote__c generatedQuote = ZuoraSubscriptionUtility.generateRenewalQuoteFromSubscription(testSubscription.Id, testOpportunity);
	}
	

	@isTest
	static void testGenerateRenewalQuoteFromSubscriptionBatch() {
		/////////////////////
		// BUILD TEST DATA //
		/////////////////////
		Test.startTest();
			Map<String, SObject> subData = TestClassUtility.buildZQUTestObjects(false);
		Test.stopTest();

		subData.putAll(TestClassUtility.buildSubscriptionData((Account)subData.get('Account'), (Contact)subData.get('Contact'), (Opportunity)subData.get('Opportunity'), (Zuora__CustomerAccount__c)subData.get('Zuora__CustomerAccount__c')));

		// Get Subscription to send Id
		Zuora__Subscription__c createdSubscription = (Zuora__Subscription__c)subData.get('Zuora__Subscription__c');

		// Get Opportunity to send Id
		Opportunity createdOpportunity = (Opportunity)subData.get('Opportunity');

		Database.executeBatch(new BatchGenerateQuoteRatePlans(createdSubscription.Id, createdOpportunity), 1);
	}
}