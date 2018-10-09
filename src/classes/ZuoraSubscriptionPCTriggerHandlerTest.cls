@isTest
private class ZuoraSubscriptionPCTriggerHandlerTest {
	
    @testSetup 
    static void createTestData(){

		Group g1 = new Group(Name = 'Asset Collection Queue', type = 'Queue');
        insert g1;
        QueuesObject q1 = new QueueSObject(QueueID = g1.id, SobjectType = 'Case');
        insert q1;   
	}

    static testMethod void testMethod1() {

        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = TestClassUtility.createUser(true, standardProfile);
        
        Account testAccount = TestClassUtility.createAccount(false);
        testAccount.Strategy_Specialist__c = testUser.Id;
        insert testAccount;

        Contact testContact = TestClassUtility.createContact(true, testAccount);

        AccountContactRole testPrimaryAccContRole = TestClassUtility.createAccountContactRole(true,testAccount,testContact);
        AccountContactRole testNonPrimaryAccContRole = TestClassUtility.createAccountContactRole(false,testAccount,testContact);
        testNonPrimaryAccContRole.IsPrimary = false;
        testNonPrimaryAccContRole.Role = 'Employee';
        insert testNonPrimaryAccContRole;

        Zuora__Subscription__c testZuoraSubscriptionCancelled = TestClassUtility.createSubscription(false, testAccount);
        testZuoraSubscriptionCancelled.Zuora__Status__c = 'Cancelled';
        testZuoraSubscriptionCancelled.Zuora__Version__c = 2;
        
        Zuora__Subscription__c testZuoraSubscriptionV2 = TestClassUtility.createSubscription(false, testAccount);
        testZuoraSubscriptionV2.Zuora__Version__c = 2;
        
        Zuora__Subscription__c testZuoraSubscriptionV1 = TestClassUtility.createSubscription(false, testAccount);
        testZuoraSubscriptionV1.Zuora__Version__c = 1;

        List<Zuora__Subscription__c> zuoraSubList = new List<Zuora__Subscription__c>{testZuoraSubscriptionCancelled,
																					testZuoraSubscriptionV2,
																					testZuoraSubscriptionV1};
        insert zuoraSubList;

        Zuora__Product__c testZuoraProduct = TestClassUtility.createZuoraProduct(true);
        // Zuora__SubscriptionProductCharge__c(Sub_True_Status__c = 'Cancelled')
        Zuora__SubscriptionProductCharge__c testZuoraSubPCCancelled = TestClassUtility.createSubscriptionProductCharge(false, 
																													   testAccount, 
																								        	           testZuoraSubscriptionCancelled, 
																										               testZuoraProduct);
        testZuoraSubPCCancelled.Zuora__EffectiveStartDate__c = Date.today().addMonths(-5);
        testZuoraSubPCCancelled.Zuora__EffectiveEndDate__c = Date.today().addMonths(5);
        testZuoraSubPCCancelled.Product_Type__c = 'Transactions';
        // Zuora__SubscriptionProductCharge__c(Sub_True_Status__c = 'Active') 
        Zuora__SubscriptionProductCharge__c testZuoraSubPCActiveV1 = TestClassUtility.createSubscriptionProductCharge(false, 
																			 										  testAccount, 
																											          testZuoraSubscriptionV1, 
																    										          testZuoraProduct);
        testZuoraSubPCActiveV1.Zuora__EffectiveStartDate__c = Date.today().addMonths(-5);
        testZuoraSubPCActiveV1.Zuora__EffectiveEndDate__c = Date.today().addMonths(5);
        testZuoraSubPCActiveV1.Product_Type__c = 'Transactions';
        testZuoraSubPCActiveV1.Zuora__ProductSKU__c = 'test01';
        testZuoraSubPCActiveV1.Zuora__Account__c = testAccount.Id;
        Zuora__SubscriptionProductCharge__c testZuoraSubPCActiveV2 = TestClassUtility.createSubscriptionProductCharge(false, 
																													testAccount, 
																										        	testZuoraSubscriptionV2, 
																										        	testZuoraProduct);
        testZuoraSubPCActiveV2.Zuora__EffectiveStartDate__c = Date.today().addMonths(-5);
        testZuoraSubPCActiveV2.Zuora__EffectiveEndDate__c = Date.today().addMonths(5);
        testZuoraSubPCActiveV2.Product_Type__c = 'Transactions';
        testZuoraSubPCActiveV2.Zuora__SubscriptionChargeNumber__c = 'Test001';
        // Zuora__SubscriptionProductCharge__c(Sub_True_Status__c = 'Active', Name.containsIgnoreCase('20% Down')) 
        Zuora__SubscriptionProductCharge__c testZuoraSubPCActiveDown = TestClassUtility.createSubscriptionProductCharge(false, 
																														testAccount, 
																												        testZuoraSubscriptionV2, 
																											        	testZuoraProduct);
        testZuoraSubPCActiveDown.Zuora__EffectiveStartDate__c = Date.today().addMonths(-5);
        testZuoraSubPCActiveDown.Zuora__EffectiveEndDate__c = Date.today().addMonths(5);
        testZuoraSubPCActiveDown.Product_Type__c = 'Transactions';
        testZuoraSubPCActiveDown.Name = 'Test Subscription Product Charge - 20% Down';

        List<Zuora__SubscriptionProductCharge__c> subPCList = new List<Zuora__SubscriptionProductCharge__c>{testZuoraSubPCCancelled, 
																											testZuoraSubPCActiveV2,
																											testZuoraSubPCActiveV1,
																											testZuoraSubPCActiveDown};
        
        Callback__c testCallBack = TestClassUtility.createCallback(false);
        testCallBack.Subscription_Name__c = testZuoraSubscriptionV2.Name;
        testCallBack.Subscription_Charge_Number__c = testZuoraSubPCActiveV2.Zuora__SubscriptionChargeNumber__c;
        insert testCallBack;


	    Test.startTest();
        insert subPCList;
        Test.stopTest();
    }

    static testMethod void testUpdateDataToZuora() {
    	Map<String, String> zspcZuoraIdMap = new Map<String, String>();
        zspcZuoraIdMap.put('123', 'abc');
        Test.startTest();
        ZuoraSubscriptionPCTriggerHandler.updateDataToZuora(zspcZuoraIdMap);
        Test.stopTest();
    }

    
        
}