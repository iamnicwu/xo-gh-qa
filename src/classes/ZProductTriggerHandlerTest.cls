@isTest
private class ZProductTriggerHandlerTest {

	private static testmethod void test_method_one() {
		// non-deleted ZProduct insertion
		zqu__ZProduct__c zp1 = TestClassUtility.createProduct(false);
		Database.insert(zp1, false);

		// non-deleted ZProduct updated so zqu__Deleted__c == true
		zp1.zqu__Deleted__c = true;
		Database.update(zp1, false);

		// deleted ZProduct insertion
		zqu__ZProduct__c zp2 = TestClassUtility.createProduct(false);
		zp2.zqu__Deleted__c = true;
		Database.insert(zp2, false);
	}
}