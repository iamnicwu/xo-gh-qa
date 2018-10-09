/*******************************************************************************
 *  Summary      : Test class for BatchRepairQuotesSentToZuora
 *  Refer Object : 
 *  Author       : Scott
 *  RefactorDate : 12 Dec 2016
 *  Change Log   : Refactoring by SF-2.6 release
 ******************************************************************************/
@isTest
public with sharing class BatchRepairQuotesSentToZuoraTest {
	static testMethod void testScheduledJob() {
		Test.startTest();
		BatchRepairQuotesSentToZuoraScheduledJob job = new BatchRepairQuotesSentToZuoraScheduledJob();
		String sch = '0 1 0 * * ?';
		System.schedule('Test BatchRepairQuotesSentToZuoraScheduledJob', sch, job);
		Test.stopTest();
	}

	static testMethod void testBatch() {
		Map<String, SObject> testObjects = TestClassUtility.buildZQUTestObjects(false);
		Test.startTest();

		Map<String, SObject> testsub =TestClassUtility.buildSubscriptionData((Account)testObjects.get('Account'), 
														 					(Contact)testObjects.get('Contact'), 
																			(Opportunity)testObjects.get('Opportunity') , 
																			(Zuora__CustomerAccount__c)testObjects.get('Zuora__CustomerAccount__c'));

		Opportunity testOpportunity = (Opportunity)testObjects.get('Opportunity');

		// set up test data to create a failure
		testOpportunity.StageName = 'Client Approved';
		update testOpportunity;

		BatchRepairQuotesSentToZuora batch = new BatchRepairQuotesSentToZuora();
		Database.executeBatch(batch);
		Test.stopTest();
	}

}