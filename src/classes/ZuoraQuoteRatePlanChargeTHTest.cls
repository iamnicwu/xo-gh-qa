@isTest
public class ZuoraQuoteRatePlanChargeTHTest {

	public static testMethod void testTheController1(){
		
		SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
												 'Complete',
												 '{"companyName": "Test Account"}',
												 null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);
		
		Test.startTest();
		Map<String, SObject> testObjects = TestClassUtility.buildZQUTestObjects(false);
		Test.stopTest();

		Market__c testMkt = TestClassUtility.createMarket(true);

		Map<String, SObject> testsub =TestClassUtility.buildSubscriptionData((Account)testObjects.get('Account'), 
																			(Contact)testObjects.get('Contact'), 
																			(Opportunity)testObjects.get('Opportunity') , 
																			(Zuora__CustomerAccount__c)testObjects.get('Zuora__CustomerAccount__c'));
		

		zqu__QuoteRatePlanCharge__c testQRP = (zqu__QuoteRatePlanCharge__c)testsub.get('zqu__QuoteRatePlanCharge__c');

		Publication__c testPublication = new Publication__c();
		testPublication.name = 'testPublication';
		testPublication.Short_Name__c = 'test';
		insert testPublication;

		Edition__c testEdition = new Edition__c();
		testEdition.name = 'testEdition';
		testEdition.Publication__c = testPublication.id;
		insert testEdition;


		Print_Issue__c pi1 =new Print_Issue__c();
		pi1.name = 'test name';
		pi1.Edition__c = testEdition.id;
		pi1.Print_Market__c = testMkt.id;
		pi1.Selling_Start_Date__c = date.today();
		pi1.Publish_1st_Cover_Ship__c = date.today();
		insert pi1;
		
		Print_Issue__c pi2 =new Print_Issue__c();
		pi2.name = 'test name';
		pi2.Edition__c = testEdition.id;
		pi2.Print_Market__c = testMkt.id;
		pi2.Selling_Start_Date__c = date.today();
		pi2.Publish_1st_Cover_Ship__c = date.today();
		insert pi2;
		
		Print_Issue__c pi =new Print_Issue__c();
		pi.name = 'test name';
		pi.Previous_Issue__c = pi1.id;
		pi.Next_Issue__c = pi2.id;
		pi.Edition__c = testEdition.id;
		pi.Print_Market__c = testMkt.id;
		pi.Selling_Start_Date__c = date.today();
		pi.Publish_1st_Cover_Ship__c = date.today();
		pi.Step_2__c = date.today().adddays(-1);
		pi.Step_3__c = date.today().adddays(-1);
		insert pi;
		
		//zqu__QuoteRatePlanCharge__c testZquQuoteRatePlanCharge = new zqu__QuoteRatePlanCharge__c();
		//testZquQuoteRatePlanCharge.Name = 'Test Quote Rate Plan Charge';  
		//testZquQuoteRatePlanCharge.zqu__QuoteRatePlan__c = testZquQuoteRatePlan.id; 
		//testZquQuoteRatePlanCharge.zqu__ProductRatePlanCharge__c = testZquProductRatePlanCharge.id;
		testQRP.zqu__Total__c = 1;
		testQRP.zqu__EffectivePrice__c = 20;
		testQRP.zqu__EffectivePrice__c = 15;
		testQRP.Product_Type__c = 'Print';
		testQRP.Print_Issue__c = pi.id;
		testQRP.zqu__ChargeType__c = 'Recurring';
		testQRP.List_Price__c = '12';
		testQRP.zqu__Period__c = 'Quarter';
		testQRP.zqu__Discount__c = 31;
		testQRP.Number_of_Charges__c = 3;
		testQRP.Discount_Override__c = 1;
		update testQRP;
		

		
		ZuoraQuoteRatePlanChargeTriggerHandler testcase = new ZuoraQuoteRatePlanChargeTriggerHandler();
		testcase.bulkBefore();
		testcase.bulkAfter();
		testcase.beforeInsert(testQRP);
		testcase.beforeUpdate(testQRP,testQRP);
		testcase.beforeDelete(testQRP);
		testcase.afterInsert(testQRP);
		testcase.afterUpdate(testQRP,testQRP);
		testcase.afterDelete(testQRP);
		testcase.andFinally();
		
		
		delete testQRP;
	}
}