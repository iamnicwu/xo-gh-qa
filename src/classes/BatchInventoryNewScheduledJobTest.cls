/*******************************************************************************
 *  Summary         : Test class for BatchInventoryNewScheduledJob
 *  Refer Object    : 
 *  Author          : Scott
 *  RefactorDate    : 12 Dec 2016
 *  Change Log      : Refactoring by SF-2.6 release
 ******************************************************************************/
@isTest
public class BatchInventoryNewScheduledJobTest {
	static testMethod void testScheduledJob() {
		
		Map<String, SObject> testObjects = TestClassUtility.buildZQUTestObjects(false);
		
		Test.startTest();

		Map<String, SObject> testsub =TestClassUtility.buildSubscriptionData((Account)testObjects.get('Account'), 
														 					(Contact)testObjects.get('Contact'), 
																			(Opportunity)testObjects.get('Opportunity') , 
																			(Zuora__CustomerAccount__c)testObjects.get('Zuora__CustomerAccount__c'));

		Account testAccount = (Account)testObjects.get('Account');
		Inventory__c testInventory = (Inventory__c)testsub.get('Inventory__c');
		testInventory.Waitlist_Account__c = testAccount.Id;
		testInventory.Last_Expiry_Date_for_Account__c = NULL;
		testInventory.Subscription_RatePlan_Id__c = 'New Rate Plan';
		update testInventory;
		

		Zuora__SubscriptionProductCharge__c testProductCharge = (Zuora__SubscriptionProductCharge__c)testsub.get('Zuora__SubscriptionProductCharge__c');
		testProductCharge.Zuora__RatePlanEffectiveEndDate__c = System.today() + 11;
		testProductCharge.Zuora__ChargeNumber__c = 'New Rate Plan';
		update testProductCharge;

		SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
												 'Complete',
												 '{"companyName": "Test Account"}',
												 null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);

		BatchInventoryNewScheduledJob binsj = new BatchInventoryNewScheduledJob();
		String sch = '0 1 0 * * ?';
		System.schedule('Test Inventory Job', sch, binsj);

		Test.stopTest();
	}
}