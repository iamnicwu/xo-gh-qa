@isTest
public class ZuoraQuoteChargeDetailTriggerHandlerTest {

	@isTest static void test_one() {
		// set up test data
		Test.startTest();
		Map<String, SObject> testObjects = TestClassUtility.buildZQUTestObjects(false);

		Opportunity testOpportunity = (Opportunity)testObjects.get('Opportunity');
		Account testAccount = (Account)testObjects.get('Account');
		Contact testContact = (Contact)testObjects.get('Contact');

		zqu__Quote__c testQuote = TestClassUtility.createQuote(false, testOpportunity, testAccount, testContact);
		testQuote.zqu__SubscriptionType__c = 'Cancel Subscription';
		insert testQuote;

		Product2 testProduct = TestClassUtility.createLocalProduct2(true);
		zqu__ProductRatePlan__c testProductRatePlan = TestClassUtility.createProductRatePlan(true, testProduct);
		Inventory__c testInventory = TestClassUtility.createInventory(true, testProductRatePlan);

		Zuora__Subscription__c testSubscription = TestClassUtility.createSubscription(false, testAccount);
		testSubscription.CreatingSalesforceQuoteID__c = testQuote.Id;
		testSubscription.Zuora__Zuora_Id__c = 'abc123';
		insert testSubscription;
		
		zqu__QuoteChargeDetail__c quoteChargeDetailRecord = TestClassUtility.createQuoteChargeDetail(false, testQuote);
		quoteChargeDetailRecord.zqu__ProductRatePlan__c = testProductRatePlan.Id;
		insert quoteChargeDetailRecord;
		Test.stopTest();

		// perform zqu__QuoteChargeDetail__c DML to test the ZuoraQuoteChargeDetailTriggerHandler
		quoteChargeDetailRecord.Name = 'Update Test';
		update quoteChargeDetailRecord;
	}


	@isTest static void test_two() {
		// set up test data
		Test.startTest();
		Map<String, SObject> testObjects = TestClassUtility.buildZQUTestObjects(false);

		Opportunity testOpportunity = (Opportunity)testObjects.get('Opportunity');
		Account testAccount = (Account)testObjects.get('Account');
		Contact testContact = (Contact)testObjects.get('Contact');

		zqu__Quote__c testQuote = TestClassUtility.createQuote(false, testOpportunity, testAccount, testContact);
		testQuote.zqu__SubscriptionType__c = 'Cancel Subscription';
		insert testQuote;

		Product2 testProduct = TestClassUtility.createLocalProduct2(true);
		zqu__ProductRatePlan__c testProductRatePlan = TestClassUtility.createProductRatePlan(true, testProduct);
		Inventory__c testInventory = TestClassUtility.createInventory(true, testProductRatePlan);

		Zuora__Subscription__c testSubscription = TestClassUtility.createSubscription(false, testAccount);
		testSubscription.CreatingSalesforceQuoteID__c = testQuote.Id;
		testSubscription.Zuora__Zuora_Id__c = 'abc123';
		insert testSubscription;
		
		zqu__QuoteChargeDetail__c quoteChargeDetailRecord = TestClassUtility.createQuoteChargeDetail(false, testQuote);
		quoteChargeDetailRecord.zqu__ProductRatePlan__c = testProductRatePlan.Id;
		insert quoteChargeDetailRecord;
		Test.stopTest();

		// perform zqu__QuoteChargeDetail__c DML to test the ZuoraQuoteChargeDetailTriggerHandler
		delete quoteChargeDetailRecord;
	}

}