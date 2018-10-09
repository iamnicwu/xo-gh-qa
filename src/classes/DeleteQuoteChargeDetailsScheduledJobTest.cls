@isTest
private class DeleteQuoteChargeDetailsScheduledJobTest {
	@isTest
	static void test_method_one() {
		Test.startTest();
		System.schedule('DeleteQuoteChargeDetailsScheduledJobtest', '0 0 4 ? * 1', new DeleteQuoteChargeDetailsScheduledJob());
		Test.stopTest();
	}
}