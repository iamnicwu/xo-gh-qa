/*******************************************************************************
 *  Summary		 : Test class for BatchMoveCustomerToCreditHold
 *  Refer Object : 
 *  Author		 : Scott
 *  RefactorDate : 12 Dec 2016
 *  Change Log	 : Refactoring by SF-2.6 release
 ******************************************************************************/
@isTest
private class BatchMoveCustomerToCreditHoldTest {
	@isTest static void test_method_one() {
		Map<String, SObject> testObjects = TestClassUtility.buildZQUTestObjects(false);

		Test.startTest();

		Map<String, SObject> testsub =TestClassUtility.buildSubscriptionData((Account)testObjects.get('Account'), 
														 					(Contact)testObjects.get('Contact'), 
																			(Opportunity)testObjects.get('Opportunity') , 
																			(Zuora__CustomerAccount__c)testObjects.get('Zuora__CustomerAccount__c'));

			SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
													'Complete',
													'{"companyName": "Test Account"}',
													null);
			Test.setMock(HttpCalloutMock.class, fakeResponse);
			
			BatchMoveCustToCreditHoldScheduledJob job = new BatchMoveCustToCreditHoldScheduledJob();
			String sch = '0 1 0 * * ?';
			System.schedule('Test BatchMoveCustToCreditHoldTest Job', sch, job);
		Test.stopTest();
	}
	
	@isTest static void test_method_two() {
		Map<String, SObject> testObjects = TestClassUtility.buildZQUTestObjects(false);

		Test.startTest();

		Map<String, SObject> testsub =TestClassUtility.buildSubscriptionData((Account)testObjects.get('Account'), 
																			(Contact)testObjects.get('Contact'), 
																			(Opportunity)testObjects.get('Opportunity') , 
																			(Zuora__CustomerAccount__c)testObjects.get('Zuora__CustomerAccount__c'));

		SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
												'Complete',
												'{"companyName": "Test Account"}',
												null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);
		BatchMoveCustomerToCreditHold b = new BatchMoveCustomerToCreditHold();
		database.executebatch(b);

		Test.stopTest();
	}
}