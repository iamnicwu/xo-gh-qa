@isTest
private class DeleteInvoiceItemsScheduledJobTest {
	@isTest
	static void test_method_one() {
		Test.startTest();
		System.schedule('DeleteInvoiceItemsScheduledJobtest', '0 0 4 ? * 1', new DeleteInvoiceItemsScheduledJob());
		Test.stopTest();
	}
}