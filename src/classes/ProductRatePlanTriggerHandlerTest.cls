@isTest
private class ProductRatePlanTriggerHandlerTest {
	
	private static testmethod void test_method_one() {
		Product2 zp1 = TestClassUtility.createLocalProduct2(true);
		zqu__ProductRatePlan__c prp1 = TestClassUtility.createProductRatePlan(false, zp1);

		prp1.zqu__EffectiveStartDate__c = Date.today().addDays(-10);
		prp1.zqu__EffectiveEndDate__c = Date.today().addDays(-5);
		Database.insert(prp1, false);
	}

	private static testmethod void test_method_two() {
		Product2 zp1 = TestClassUtility.createLocalProduct2(true);
		zqu__ProductRatePlan__c prp1 = TestClassUtility.createProductRatePlan(false, zp1);

		prp1.zqu__EffectiveStartDate__c = Date.today().addDays(-10);
		prp1.zqu__EffectiveEndDate__c = Date.today().addDays(5);
		Database.insert(prp1, false);

		prp1.zqu__EffectiveEndDate__c = Date.today().addDays(6);
		Database.update(prp1, false);

		Database.delete(prp1, false);
	}	
}