@isTest
private class ProductRatePlanChargeTriggerHandlerTest {
	
	@isTest
	static void test_setPrintUpToHowManyPeriodsDefaultValue() {
		Product2 printProduct = TestClassUtility.createLocalProduct2(false);
		printProduct.ProductType__c = 'Print';
		insert printProduct;
		zqu__ProductRatePlan__c printProductRatePlan = TestClassUtility.createProductRatePlan(true, printProduct);
		zqu__ProductRatePlanCharge__c printProductRatePlanCharge = TestClassUtility.createProductRatePlanCharge(false);
		printProductRatePlanCharge.zqu__ProductRatePlan__c = printProductRatePlan.Id;
		printProductRatePlanCharge.zqu__Upto_How_Many_Periods__c = null;
		insert printProductRatePlanCharge;
		printProductRatePlanCharge.zqu__Upto_How_Many_Periods__c = null;
		update printProductRatePlanCharge;
	}
}