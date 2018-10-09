@isTest
private class BatchAssignmentHistoryUpdateSchJobTest {
	@isTest
	static void test_method_one() {
		System.schedule('BatchAssignmentHistoryUpdateSchJobTEST', '0 50 7 ? * *', new BatchAssignmentHistoryUpdateSchJob());
	}
}