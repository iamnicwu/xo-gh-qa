/*******************************************************************************
 *  Summary         : Test class for call back manager controller
 *  Refer Object    : 
 *  Author          : Nick
 *  RefactorDate    : 12 Dec 2016
 *  Change Log      : Refactoring by SF-2.6 release
 ******************************************************************************/
@isTest
private class CallbackManagerControllerTest {

	@isTest static void testCallbackManager() {
		
		Map<String, SObject> testObjects = TestClassUtility.buildLocalData(false);
		
		Test.startTest();
		Map<String, SObject> testsub =TestClassUtility.buildSubscriptionData((Account)testObjects.get('Account'), 
														 					(Contact)testObjects.get('Contact'), 
																			(Opportunity)testObjects.get('Opportunity') , 
																			(Zuora__CustomerAccount__c)testObjects.get('Zuora__CustomerAccount__c'));


		Zuora__Subscription__c testSubscription = (Zuora__Subscription__c)testsub.get('Zuora__Subscription__c');
		Zuora__SubscriptionProductCharge__c testSubscriptionProductCharge = (Zuora__SubscriptionProductCharge__c)testsub.get('Zuora__SubscriptionProductCharge__c');
		testSubscriptionProductCharge.Zuora__SubscriptionChargeNumber__c = 'TEST-001';
		update testSubscriptionProductCharge;

		Callback__c testCallback = new Callback__c();
		testCallback.Name = testSubscription.Name;
		testCallback.Subscription_Name__c = testSubscription.Name;
		testCallback.Status__c = 'New';
		insert testCallback;

		
		CallbackManagerController.getCallbacks(2, 'all', 'all', 
												'all', 'all', 'all', 
												'all', 'Account__r.Name ASC ', '',
												'', '', '',
												'all');
		CallbackManagerController.getCallbacks(2, 'mine', 'internet', 
												'open', 'AK-Alaska', 'Accessories - ACC', 
												'VIP', 'Account__r.Name ASC ', 'AccountName', 
												'SubName', String.valueOf(Date.today() - 1), String.valueOf(Date.today() + 1),
												'all');
		CallbackManagerController.getStatusPicklistValues();
		CallbackManagerController.updateCallbackStatus(testCallback.Id, 'Proof Out');
		CallbackManagerController.getOwnerPicklistValues();
		CallbackManagerController.getMarketPicklistValues();
		CallbackManagerController.getCategoryPicklistValues();
		CallbackManagerController.updateCallbackDate(testCallback.Id, String.valueOf(Date.today()), new Map<String, String>());
		CallbackManagerController.getSubscriptionDetails(testCallback.Id);
		CallbackManagerController.updatecallbackOwner(testCallback.Id, UserInfo.getUserId());
		CallbackManagerController.getStrategySpecialistPicklistValues();

		// testing CallbackManagerController methods with an invalid Callback record Id
		Id invalidCallbackId = 'a4J11000000D7klEAC';
		CallbackManagerController.updateCallbackStatus(invalidCallbackId, 'Proof Out');
		CallbackManagerController.updateCallbackDate(invalidCallbackId, String.valueOf(Date.today()), new Map<String, String>());
		CallbackManagerController.getSubscriptionDetails(invalidCallbackId);
		CallbackManagerController.updatecallbackOwner(invalidCallbackId, UserInfo.getUserId());
		CallbackManagerController.getCallbackNotes(invalidCallbackId);
		CallbackManagerController.createCallbackNote(invalidCallbackId, 'test');

		Test.stopTest();
	}

	@isTest static void testZuoraSubscriptionTriggerHandler() {
		
		Map<String, SObject> testObjects = TestClassUtility.buildLocalData(false);
		
		Test.startTest();
		Map<String, SObject> testsub =TestClassUtility.buildSubscriptionData((Account)testObjects.get('Account'), 
														 					(Contact)testObjects.get('Contact'), 
																			(Opportunity)testObjects.get('Opportunity') , 
																			(Zuora__CustomerAccount__c)testObjects.get('Zuora__CustomerAccount__c'));

		Zuora__Subscription__c testSubscription = (Zuora__Subscription__c)testsub.get('Zuora__Subscription__c');
		Callback__c testCallback = new Callback__c();
		testCallback.Name = testSubscription.Name;
		testCallback.Subscription_Name__c = testSubscription.Name;
		testCallback.Status__c = 'New';
		insert testCallback;

		ZuoraSubscriptionTriggerHandler.closeOpenCallbacksForCancelledSubs(new Set<String>{testSubscription.Name});
		Test.stopTest();
	}

	@isTest static void testZuoraSubscriptionPCTriggerHandler() {
		
		Map<String, SObject> testObjects = TestClassUtility.buildLocalData(false);
		Test.startTest();
		Map<String, SObject> testsub =TestClassUtility.buildSubscriptionData((Account)testObjects.get('Account'), 
														 					(Contact)testObjects.get('Contact'), 
																			(Opportunity)testObjects.get('Opportunity') , 
																			(Zuora__CustomerAccount__c)testObjects.get('Zuora__CustomerAccount__c'));


		Zuora__Subscription__c testSubscription = (Zuora__Subscription__c)testsub.get('Zuora__Subscription__c');
		Zuora__SubscriptionProductCharge__c testSubscriptionProductCharge = (Zuora__SubscriptionProductCharge__c)testsub.get('Zuora__SubscriptionProductCharge__c');
		testSubscriptionProductCharge.Zuora__SubscriptionChargeNumber__c = 'TEST-001';
		update testSubscriptionProductCharge;

		Callback__c testCallback = new Callback__c();
		testCallback.Name = testSubscription.Name;
		testCallback.Subscription_Name__c = testSubscription.Name;
		testCallback.Status__c = 'New';
		insert testCallback;

		Map<String, Zuora__SubscriptionProductCharge__c> amendedSubCallbackMap = new Map<String, Zuora__SubscriptionProductCharge__c>();
		amendedSubCallbackMap.put(testSubscriptionProductCharge.Zuora__SubscriptionChargeNumber__c, testSubscriptionProductCharge);

		ZuoraSubscriptionPCTriggerHandler.createAndUpdateCallbacks(amendedSubCallbackMap, new Map<String, List<Zuora__SubscriptionProductCharge__c>>());

		Test.stopTest();
	}

	@isTest static void testCallbackTrigger() {
		
		Map<String, SObject> testObjects = TestClassUtility.buildLocalData(false);
		Test.startTest();
		Map<String, SObject> testsub =TestClassUtility.buildSubscriptionData((Account)testObjects.get('Account'), 
														 					(Contact)testObjects.get('Contact'), 
																			(Opportunity)testObjects.get('Opportunity') , 
																			(Zuora__CustomerAccount__c)testObjects.get('Zuora__CustomerAccount__c'));
		

		Zuora__Subscription__c testSubscription = (Zuora__Subscription__c)testsub.get('Zuora__Subscription__c');

		Callback__c testCallback = new Callback__c();
		testCallback.Name = testSubscription.Name;
		testCallback.Subscription_Name__c = testSubscription.Name;
		testCallback.Status__c = 'New';
		insert testCallback;

		try {
			delete testCallback;
		}
		catch (Exception e) {
			// don't do anything, this is testing the CallbackTrigger code to prevent deletions
		}
		Test.stopTest();
	}
}