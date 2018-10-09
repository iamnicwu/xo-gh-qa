@isTest 
public class DeleteFulfillmentResponseScheduleTest {
	static testMethod void testScheduledJob() {
		
		Test.startTest();
		SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
												 'Complete',
												 '{"companyName": "Test Account"}',
												 null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);
		Map<String, SObject> testObjects = TestClassUtility.buildZQUTestObjects(false);
		Test.stopTest();
		
		DeleteFulfillmentResponseSchedule binsj = new DeleteFulfillmentResponseSchedule();
		String sch = '0 1 0 * * ?';
		System.schedule('Test Inventory Job', sch, binsj);		
	}
}