@istest 
public class SubscriptionBatchClas_test{

	public static testmethod void TestSubscriptionBatchClas(){

		Subscription_Batch_Process_Run_History__c subLastRun = new Subscription_Batch_Process_Run_History__c();
		subLastRun.name = 'test';
		subLastRun.Last_Successfully_Completed__c = Date.today() - 1;
		insert subLastRun;
		
		Test.startTest();
		Map<String, SObject> testObjects = TestClassUtility.buildLocalData(false);
		Test.stopTest();

		Account testAccount = (Account)testObjects.get('Account');

		Zuora__Subscription__c zs = new Zuora__Subscription__c(name='testjs',
																Zuora__status__c='Active',
																Zuora__account__c=testAccount.id,
																Zuora__SubscriptionEndDate__c = Date.today() - 1
																);
		insert zs;
		Zuora__SubscriptionProductCharge__c zsc = new Zuora__SubscriptionProductCharge__c(Product_Type__c ='Print', 
																							name='testzsc',
																							Zuora__ProductSKU__c ='test123',
																							Zuora__Subscription__c=zs.id
																							);
		insert zsc;
		zqu__ZProduct__c zp=new zqu__ZProduct__c(name='testzp', 
												zqu__SKU__c='test123',
												ProductType__c='testgroup',
												zqu__ZuoraId__c='123'
												);
		insert zp;

		SubscriptionBatchClass b = new SubscriptionBatchClass();
		database.executebatch(b);
	}

	public static testmethod void TestSubscriptionBatchClas1(){
		
		Subscription_Batch_Process_Run_History__c subLastRun = new Subscription_Batch_Process_Run_History__c();
		subLastRun.name = 'test';
		subLastRun.Last_Successfully_Completed__c = Date.today() - 1;
		insert subLastRun;

		Test.startTest();
		Map<String, SObject> testObjects = TestClassUtility.buildLocalData(false);
		Test.stopTest();

		Account testAccount = (Account)testObjects.get('Account');


		Zuora__Subscription__c zs = new Zuora__Subscription__c(name='testjs',
																Zuora__status__c='Active',
																Zuora__account__c=testAccount.id,
																Zuora__SubscriptionEndDate__c = Date.today() + 1
																);
		insert zs;
		Zuora__SubscriptionProductCharge__c zsc = new Zuora__SubscriptionProductCharge__c(Product_Type__c ='print',
																							name='testzsc',
																							Zuora__ProductSKU__c ='test123',
																							Zuora__Subscription__c=zs.id
																							);
		insert zsc;
		zqu__ZProduct__c zp=new zqu__ZProduct__c(name='testzp', 
												zqu__SKU__c='test123',
												ProductType__c='testgroup',
												zqu__ZuoraId__c='123'
												);
		insert zp;

		SubscriptionBatchClass b = new SubscriptionBatchClass();
		database.executebatch(b);

	}

	public static testmethod void TestSubscriptionBatchClas2(){

		Subscription_Batch_Process_Run_History__c subLastRun = new Subscription_Batch_Process_Run_History__c();
		subLastRun.name = 'test';
		subLastRun.Last_Successfully_Completed__c = Date.today() - 1;
		insert subLastRun;

		Test.startTest();
		Map<String, SObject> testObjects = TestClassUtility.buildLocalData(false);
		Test.stopTest();

		Account testAccount = (Account)testObjects.get('Account');

		Zuora__Subscription__c zs=new Zuora__Subscription__c(name='testjs',
															Zuora__status__c='Active',
															Zuora__account__c=testAccount.id,
															Zuora__SubscriptionEndDate__c = Date.today() + 1
															);
		insert zs;

		Zuora__SubscriptionProductCharge__c zsc = new Zuora__SubscriptionProductCharge__c(Product_Type__c ='Concierge Venue',
																						name='testzsc',
																						Zuora__ProductSKU__c ='test123',
																						Zuora__Subscription__c=zs.id);
		insert zsc;

		zqu__ZProduct__c zp=new zqu__ZProduct__c(name='testzp', 
												zqu__SKU__c='test123',
												ProductType__c='testgroup',
												zqu__ZuoraId__c='123'
												);
		insert zp;

		SubscriptionBatchClass b = new SubscriptionBatchClass();
		database.executebatch(b);
	}
}