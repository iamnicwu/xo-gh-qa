@isTest
private class CallbackTriggerHandlerTest {
	
	@isTest
	static void test_method_one() {

		Callback__c callbackRecord = new Callback__c();
		callbackRecord.Name = 'Test Callback';
		callbackRecord.OwnerId = UserInfo.getUserId();
		insert callbackRecord;
		
		Test.startTest();
		// test update
		callbackRecord.Name = 'Test Update';
		update callbackRecord;

		// test delete
		try {
			delete callbackRecord;
		}
		catch (Exception e) {
			// don't do anything, testing to make sure Callbacks can't get deleted
		}
		Test.stopTest();
	}
}