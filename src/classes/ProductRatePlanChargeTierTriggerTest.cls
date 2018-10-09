@isTest
private class ProductRatePlanChargeTierTriggerTest {
	
	@isTest
	static void priceUpdateValidation() {
		// Create Test Product
		Product2 testProduct = TestClassUtility.createLocalProduct2(true);
		// Create Test Product Rate Plan
		zqu__ProductRatePlan__c testProductRatePlan = TestClassUtility.createProductRatePlan(false);
		testProductRatePlan.zqu__Product__c = testProduct.Id;
		insert testProductRatePlan;
		// Create Test Product Rate Plan Charge
		zqu__ProductRatePlanCharge__c testProductRatePlanCharge = TestClassUtility.createProductRatePlanCharge(false);
		testProductRatePlanCharge.zqu__ProductRatePlan__c = testProductRatePlan.Id;
		insert testProductRatePlanCharge;
		// Create Test Product Rate Plan Charge Tier
		zqu__ProductRatePlanChargeTier__c testProductRatePlanChargeTier = new zqu__ProductRatePlanChargeTier__c();
		testProductRatePlanChargeTier.zqu__ProductRatePlanCharge__c = testProductRatePlanCharge.Id;
		testProductRatePlanChargeTier.zqu__Price__c = testProductRatePlanCharge.zqu__ListPrice__c;
		testProductRatePlanChargeTier.zqu__ZuoraId__c = 'someidforzuora';
		insert testProductRatePlanChargeTier;

		// Update Tier Price
		testProductRatePlanChargeTier.zqu__Price__c = 400000.00;
		update testProductRatePlanChargeTier;

		/*
			-- ASSERTION --
			The above price update should have auto flagged to "Zuora Update Pending" field to be true(checked)
		 */
		zqu__ProductRatePlanChargeTier__c assertFlagSet = [SELECT Id, Zuora_Update_Pending__c FROM zqu__ProductRatePlanChargeTier__c WHERE Id = :testProductRatePlanChargeTier.Id];
		System.assert(assertFlagSet.Zuora_Update_Pending__c);

		// This update should fail as no Zuora config is on during testing
		testProductRatePlanChargeTier.Update_Zuora_Immediately__c = true;
		// Force the batch job to run synchronously
		Test.startTest();
			update testProductRatePlanChargeTier;
		Test.stopTest();
		
		/*
			-- ASSERTION --
			The above update should have failed meaning that the "Last Update Attempted" field should now be populated with the latest
			attemp date time AND the "Zuora Update Pending" field should still be checked.
		 */
		assertFlagSet = [SELECT Id, Zuora_Update_Pending__c, Last_Update_Attempted__c FROM zqu__ProductRatePlanChargeTier__c WHERE Id = :testProductRatePlanChargeTier.Id];
		System.assert(assertFlagSet.Last_Update_Attempted__c != null);
		System.assert(assertFlagSet.Zuora_Update_Pending__c);
	}
}