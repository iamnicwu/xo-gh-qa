/* 
<class>
  <name>SubscriptionBatchClassScheduledJobTest</name>
  <purpose>For testing the SubscriptionBatchClassScheduledJob class</purpose>
  <created>
	<by>Jonathan Satterfield</by>
	<date>8/17/2015</date>
	<ticket>SF-612</ticket>
  </created>
</class>
*/
@isTest
public class SubscriptionBatchClassScheduledJobTest {
	/* 
	<method>
		<name>testScheduledJob</name>
		<purpose>Test the scheduled job</purpose>
		<created>
		<by>Jonathan Satterfield</by>
		<date>8/17/2015</date>
		<ticket>SF-612</ticket>
	  </created>
	</method>
	*/
	@isTest
	static void testScheduledJob() {
		Test.startTest();
		SubscriptionBatchClassScheduledJob sj = new SubscriptionBatchClassScheduledJob();
		String sch = '0 0 23 * * ?';
		System.schedule('Test Territory Check', sch, sj);
		Test.stopTest();
	}
	
	@isTest
	static void testSubscriptionBatchClass2() {
		
		Test.startTest();
		Map<String, SObject> testObjects = TestClassUtility.buildLocalData(false);
		Test.stopTest();
		
		Account testAccount = (Account)testObjects.get('Account');

		Subscription_Batch_Process_Run_History__c sbprh = new Subscription_Batch_Process_Run_History__c();
		sbprh.Name = 'test';
		sbprh.Last_Successfully_Completed__c = dateTime.now().adddays(-1);
		insert sbprh;
		
		Zuora__Product__c testZuoraProduct = new Zuora__Product__c();
		testZuoraProduct.Zuora__Description__c = 'Test Product';
		testZuoraProduct.Zuora__EffectiveEndDate__c = Date.Today();
		testZuoraProduct.Zuora__External_Id__c = '123ed';
		testZuoraProduct.ProductType__c = 'Concierge Venue';
		testZuoraProduct.Zuora__SKU__c = 'SKU-00000044';
		insert testZuoraProduct;
		
		Zuora__Subscription__c testZquSubscription = new Zuora__Subscription__c();
		testZquSubscription.Name = 'Test Subscription';
		testZquSubscription.Zuora__SubscriptionStartDate__c = Date.Today();
		testZquSubscription.Zuora__SubscriptionEndDate__c = Date.Today() + 365;
		testZquSubscription.Zuora__Status__c = 'Active';
		testZquSubscription.Zuora__Account__c = testAccount.Id;
		testZquSubscription.Zuora__Zuora_Id__c = 'abc123';
		insert testZquSubscription;
		
		Zuora__SubscriptionProductCharge__c testZquSubscriptionProductCharge = new Zuora__SubscriptionProductCharge__c();
		testZquSubscriptionProductCharge.Name = 'Test Subscription Product Charge';
		testZquSubscriptionProductCharge.Zuora__EffectiveEndDate__c = Date.newinstance(2015, 9, 10);
		testZquSubscriptionProductCharge.Zuora__Zuora_Id__c = 'zinrid12nd45oidl';
		testZquSubscriptionProductCharge.Quote_Rate_Plan_ID__c = 'qweqweqwe';
		testZquSubscriptionProductCharge.Zuora__RatePlanId__c = 'asdasdasdasdas';
		testZquSubscriptionProductCharge.Zuora__Subscription__c = testZquSubscription.id;
		testZquSubscriptionProductCharge.Zuora__ProductName__c = 'Test Product';
		testZquSubscriptionProductCharge.Zuora__RatePlanName__c = 'Test Product Rate Plan';
		testZquSubscriptionProductCharge.Zuora__Product__c = testZuoraProduct.id;
		testZquSubscriptionProductCharge.Zuora__Account__c = testAccount.id;
		testZquSubscriptionProductCharge.Product_Type__c = 'Concierge Venu';
		insert testZquSubscriptionProductCharge;
		
		Zuora__Subscription__c testZquSubscription1 = new Zuora__Subscription__c();
		testZquSubscription1.Name = 'Test Subscription1';
		testZquSubscription1.Zuora__SubscriptionStartDate__c = Date.Today();
		testZquSubscription1.Zuora__SubscriptionEndDate__c = Date.Today().adddays(-1);
		testZquSubscription1.Zuora__Status__c = 'Active';
		testZquSubscription1.Zuora__Account__c = testAccount.Id;
		testZquSubscription1.Zuora__Zuora_Id__c = 'abc1231';
		insert testZquSubscription1;
		
		Zuora__SubscriptionProductCharge__c testZquSubscriptionProductCharge1 = new Zuora__SubscriptionProductCharge__c();
		testZquSubscriptionProductCharge1.Name = 'Test Subscription Product Charge1';
		testZquSubscriptionProductCharge1.Zuora__EffectiveEndDate__c = Date.newinstance(2015, 9, 10);
		testZquSubscriptionProductCharge1.Zuora__Zuora_Id__c = 'zinrid12nd45oidl';
		testZquSubscriptionProductCharge1.Quote_Rate_Plan_ID__c = 'qweqweqwe';
		testZquSubscriptionProductCharge1.Zuora__RatePlanId__c = 'asdasdasdasdas';
		testZquSubscriptionProductCharge1.Zuora__Subscription__c = testZquSubscription1.id;
		testZquSubscriptionProductCharge1.Zuora__ProductName__c = 'Test Product';
		testZquSubscriptionProductCharge1.Zuora__RatePlanName__c = 'Test Product Rate Plan';
		testZquSubscriptionProductCharge1.Zuora__Product__c = testZuoraProduct.id;
		testZquSubscriptionProductCharge1.Zuora__Account__c = testAccount.id;
		insert testZquSubscriptionProductCharge1;
		
		SubscriptionBatchClass2 bb = new SubscriptionBatchClass2();
		Database.executeBatch(bb);
	}
}