@isTest
private class PartnerAccountUpdatePastDueScheduleTest {

	@isTest static void testrun() {
		// Implement test code
		SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
												 'Complete',
												 '{"companyName": "Test Account"}',
												 null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);
		
		Test.startTest();
		Map<String,SObject> testdataMap = TestClassUtility.buildLocalData(false);
		Test.stopTest();
		Account testAccount = (Account)testDataMap.get('Account');
		
		XO_Group_Settings__c xoSetting = XO_Group_Settings__c.getInstance();
		xoSetting.Turn_on_Fulfillment_Callouts__c = false;
		upsert xoSetting;

		TestClassUtility.createNotesDeactivateTriggerSetting(true);
		
		set<String> idlist = new set<String>();
		idlist.add(String.valueOf(testaccount.id));

		PartnerAccountUpdatePastDueSchedule job = new PartnerAccountUpdatePastDueSchedule(idlist);
		job.execute(null);
	}
	
}