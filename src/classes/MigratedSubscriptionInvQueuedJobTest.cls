@isTest 
private class MigratedSubscriptionInvQueuedJobTest {
	private static testmethod void test_method_one() {
		Test.StartTest();
		//TestClassUtility.buildLocalData(false);
		Map<String, SObject> testLocalData = TestClassUtility.buildLocalData(false);
		Test.StopTest();
        
		
	    
        Account testAccount = (Account)testLocalData.get('Account');
        Zuora__Subscription__c testZSubcription = TestClassUtility.createSubscription(true,testAccount);
        Zuora__Product__c testProduct = TestClassUtility.createZuoraProduct(true);
        
        Zuora__SubscriptionProductCharge__c testZSubProductCharge = TestClassUtility.createSubscriptionProductCharge(false , testZSubcription,testProduct);
        testZSubProductCharge.Zuora_Id_of_Migrated_Charge__c = 'qweqweqwe';
        testZSubProductCharge.Do_not_create_inventory__c = 'Yes';
        testZSubProductCharge.Zuora__Zuora_Id__c = '21212122';
        insert testZSubProductCharge;


        Zuora__SubscriptionProductCharge__c testZSubProductCharge1 = TestClassUtility.createSubscriptionProductCharge(false ,testZSubcription,testProduct);
        testZSubProductCharge1.Zuora_Id_of_Migrated_Charge__c = 'asdasdasd';
        testZSubProductCharge1.Do_not_create_inventory__c = 'No';
        testZSubProductCharge1.Zuora__Zuora_Id__c = 'qweqweqwe';

        insert testZSubProductCharge1;

        Product2 testzquZProduct = TestClassUtility.createProduct2(true);
        //zqu__ProductRatePlan__c testProductRatePlan = TestClassUtility.createProductRatePlan(ture,testzquZProduct);
        zqu__ProductRatePlan__c testProductRatePlan = TestClassUtility.createProductRatePlan(true,testzquZProduct);
        //insert testProd
   



        MigratedSubscriptionInventoryQueuedJob uzjob = new MigratedSubscriptionInventoryQueuedJob();
		System.enqueueJob(new MigratedSubscriptionInventoryQueuedJob.QueueableOne());
        


        
 
	}
	
}