/* 
<class>
  <name>SubscriptionCreatorQueuedJobTest</name>
  <purpose>For testing the SubscriptionCreatorQueuedJob class</purpose>
  <created>
	<by>Jonathan Satterfield</by>
	<date>7/27/2015</date>
	<ticket>SF-602</ticket>
  </created>
</class>
*/ 
@isTest
public class SubscriptionCreatorQueuedJobTest {
	/* 
	<method>
	  <name>RunTest</name>
	  <purpose>Test the SubscriptionCreatorQueuedJob class</purpose>
	  <created>
		<by>Jonathan Satterfield</by>
		<date>7/27/2015</date>
		<ticket>SF-602</ticket>
	  </created>
	</method>
	*/
	@isTest static void TestSubscriptionCreatorQueuedJob_one() {

		Test.startTest();
		Map<String, SObject> testObjects = TestClassUtility.buildZQUTestObjects(false);
		Test.stopTest();
		
		Contact testContact = (Contact)testObjects.get('Contact');

		// first, create a "new" Quote to later tie to a Subscription
		zqu__Quote__c newQuote = new zqu__Quote__c();
		newQuote.OwnerId = UserInfo.getUserId();
		newQuote.zqu__BillToContact__c = testContact.Id;
		insert newQuote;

		// then, create an "amendment" Quote to later tie to a Subscription
		zqu__Quote__c amendmentQuote = new zqu__Quote__c();
		amendmentQuote.OwnerId = UserInfo.getUserId();
		amendmentQuote.zqu__SubscriptionVersion__c = 1;
		amendmentQuote.zqu__Hidden_Subscription_Name__c = 'AmendmentSubFromSalesforce';
		amendmentQuote.zqu__BillToContact__c = testContact.Id;
		insert amendmentQuote;

		// create new Subscription that originated in Zuora
		Zuora__Subscription__c newSubFromZuora = new Zuora__Subscription__c();
		newSubFromZuora.Name = 'NewSubFromZuora';
		newSubFromZuora.Zuora__Zuora_Id__c = '2c92c0f84e713779014e73b9dfba42e1';
		newSubFromZuora.NeedToUpdateSubscriptionCreator__c = True;
		newSubFromZuora.Zuora__Version__c = 1;
		newSubFromZuora.OwnerId = UserInfo.getUserId();
		newSubFromZuora.Product_Line__c = 'test';
		insert newSubFromZuora;

		// next, create "new" Subscription that originated in Salesforce
		Zuora__Subscription__c newSubFromSalesforce = new Zuora__Subscription__c();
		newSubFromSalesforce.Name = 'NewSubFromSalesforce';
		newSubFromSalesforce.Zuora__Zuora_Id__c = '2c92c0f84e713779014e73b9dfba42e1';
		newSubFromSalesforce.NeedToUpdateSubscriptionCreator__c = True;
		newSubFromSalesforce.Zuora__Version__c = 1;
		newSubFromSalesforce.OwnerId = UserInfo.getUserId();
		newSubFromSalesforce.OriginalSalesforceQuoteID__c = (String)newQuote.Id;
		newSubFromSalesforce.CreatingSalesforceQuoteID__c = (String)newQuote.Id;
		newSubFromSalesforce.Product_Line__c = 'test';
		insert newSubFromSalesforce;

		// then, create an "amendment" Subscription that originated in Salesforce
		Zuora__Subscription__c amendmentSubFromSalesforce = new Zuora__Subscription__c();
		amendmentSubFromSalesforce.Name = 'AmendmentSubFromSalesforce';
		amendmentSubFromSalesforce.Zuora__Zuora_Id__c = '2c92c0f84e713779014e73b9dfba42e1';
		amendmentSubFromSalesforce.NeedToUpdateSubscriptionCreator__c = True;
		amendmentSubFromSalesforce.Zuora__Version__c = 2;
		amendmentSubFromSalesforce.OwnerId = UserInfo.getUserId();
		amendmentSubFromSalesforce.OriginalSalesforceQuoteID__c = (String)amendmentQuote.Id;
		amendmentSubFromSalesforce.CreatingSalesforceQuoteID__c = (String)amendmentQuote.Id;
		amendmentSubFromSalesforce.Product_Line__c = 'test';
		insert amendmentSubFromSalesforce;

		// then, create an "amendment" Subscription that originated in Salesforce
		Zuora__Subscription__c amendmentSubFromZuora = new Zuora__Subscription__c();
		amendmentSubFromZuora.Name = 'AmendmentSubFromZuora';
		amendmentSubFromZuora.Zuora__Zuora_Id__c = '2c92c0f84e713779014e73b9dfba42e1';
		amendmentSubFromZuora.NeedToUpdateSubscriptionCreator__c = True;
		amendmentSubFromZuora.Zuora__Version__c = 3;
		amendmentSubFromZuora.OwnerId = UserInfo.getUserId();
		amendmentSubFromZuora.Product_Line__c = 'test';
		insert amendmentSubFromZuora;

		// Then, run the test
		ID jobID = System.enqueueJob(new SubscriptionCreatorQueuedJob());

	}
	
	@isTest
	static void TestSubscriptionCreatorQueuedJob_two() {

		Test.startTest();
		Map<String, SObject> testObjects = TestClassUtility.buildZQUTestObjects(false);
		Test.stopTest();
		
		Contact testContact = (Contact)testObjects.get('Contact');

		// first, create a "new" Quote to later tie to a Subscription
		zqu__Quote__c newQuote = new zqu__Quote__c();
		newQuote.OwnerId = UserInfo.getUserId();
		newQuote.zqu__BillToContact__c = testContact.Id;
		insert newQuote;

		// then, create an "amendment" Quote to later tie to a Subscription
		zqu__Quote__c amendmentQuote = new zqu__Quote__c();
		amendmentQuote.OwnerId = UserInfo.getUserId();
		amendmentQuote.zqu__SubscriptionVersion__c = 1;
		amendmentQuote.zqu__Hidden_Subscription_Name__c = 'AmendmentSubFromSalesforce';
		amendmentQuote.zqu__BillToContact__c = testContact.Id;
		insert amendmentQuote;

		// create new Subscription that originated in Zuora
		Zuora__Subscription__c newSubFromZuora = new Zuora__Subscription__c();
		newSubFromZuora.Name = 'NewSubFromZuora';
		newSubFromZuora.Zuora__Zuora_Id__c = '2c92c0f84e713779014e73b9dfba42e1';
		newSubFromZuora.NeedToUpdateSubscriptionCreator__c = True;
		newSubFromZuora.Zuora__Version__c = 1;
		newSubFromZuora.OwnerId = UserInfo.getUserId();
		newSubFromZuora.Product_Line__c = 'test';
		insert newSubFromZuora;

		// next, create "new" Subscription that originated in Salesforce
		Zuora__Subscription__c newSubFromSalesforce = new Zuora__Subscription__c();
		newSubFromSalesforce.Name = 'NewSubFromSalesforce';
		newSubFromSalesforce.Zuora__Zuora_Id__c = '2c92c0f84e713779014e73b9dfba42e1';
		newSubFromSalesforce.NeedToUpdateSubscriptionCreator__c = True;
		newSubFromSalesforce.Zuora__Version__c = 1;
		newSubFromSalesforce.OwnerId = UserInfo.getUserId();
		newSubFromSalesforce.OriginalSalesforceQuoteID__c = null;
		newSubFromSalesforce.CreatingSalesforceQuoteID__c = (String)newQuote.Id;
		newSubFromSalesforce.Product_Line__c = 'test';
		insert newSubFromSalesforce;

		// then, create an "amendment" Subscription that originated in Salesforce
		Zuora__Subscription__c amendmentSubFromSalesforce = new Zuora__Subscription__c();
		amendmentSubFromSalesforce.Name = 'AmendmentSubFromSalesforce';
		amendmentSubFromSalesforce.Zuora__Zuora_Id__c = '2c92c0f84e713779014e73b9dfba42e1';
		amendmentSubFromSalesforce.NeedToUpdateSubscriptionCreator__c = True;
		amendmentSubFromSalesforce.Zuora__Version__c = 2;
		amendmentSubFromSalesforce.OwnerId = UserInfo.getUserId();
		amendmentSubFromSalesforce.OriginalSalesforceQuoteID__c = (String)amendmentQuote.Id;
		amendmentSubFromSalesforce.CreatingSalesforceQuoteID__c = (String)amendmentQuote.Id;
		amendmentSubFromSalesforce.Product_Line__c = 'test';
		insert amendmentSubFromSalesforce;

		// then, create an "amendment" Subscription that originated in Salesforce
		Zuora__Subscription__c amendmentSubFromZuora = new Zuora__Subscription__c();
		amendmentSubFromZuora.Name = 'AmendmentSubFromZuora';
		amendmentSubFromZuora.Zuora__Zuora_Id__c = '2c92c0f84e713779014e73b9dfba42e1';
		amendmentSubFromZuora.NeedToUpdateSubscriptionCreator__c = True;
		amendmentSubFromZuora.Zuora__Version__c = 3;
		amendmentSubFromZuora.OwnerId = UserInfo.getUserId();
		amendmentSubFromZuora.Product_Line__c = 'test';
		insert amendmentSubFromZuora;

		// Then, run the test
		ID jobID = System.enqueueJob(new SubscriptionCreatorQueuedJob());
	}
}