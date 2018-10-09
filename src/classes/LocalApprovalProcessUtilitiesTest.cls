@isTest
private class LocalApprovalProcessUtilitiesTest {
	@isTest static void test_method_one() {
		Test.startTest();
		Map<String, SObject> testObjects = TestClassUtility.buildZQUTestObjects(false);
		Test.stopTest();

		Opportunity testOpp = (Opportunity)testObjects.get('Opportunity');
		LocalApprovalProcessUtilities.submitLocalOppForApproval(testOpp.Id);
		LocalApprovalProcessUtilities.checkSubmitForApproval(testOpp.Id);
	}

	@isTest static void test_method_two() {
		Test.startTest();
		Map<String, SObject> testObjects = TestClassUtility.buildZQUTestObjects(false);
		Opportunity testOpp = (Opportunity)testObjects.get('Opportunity');
		testOpp.Type = 'Renewal';
		update testOpp;
		List<Profile> profileList = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];
		// should normally make sure the list isn't empty before trying to access an array directly, but this query will always return a result in this case
		String userProfileName = profileList[0].Name;
		LocalApprovalProcessUtilities.setOppSkipEchoSignFlagIfApplicableWebservice(testOpp.Id, testOpp.Type, userProfileName);
		Test.stopTest();
		// comment for release SF 3.1
	}
}