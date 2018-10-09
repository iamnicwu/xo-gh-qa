@isTest
private class NVM_Embedded_Player_ControllerTest {
	@isTest static void visibilityTest() {
		User rsdUser = [SELECT Id, Manager.Id FROM User WHERE IsActive = TRUE AND Profile.Name = 'Local Core Strategy Specialist' AND Manager.Id != null AND Manager.IsActive = TRUE LIMIT 1];
		
		User nonOwnerRsd = [SELECT Id, Manager.Id FROM User WHERE IsActive = TRUE AND Profile.Name = 'Local Core Strategy Specialist' AND Id != :rsdUser.Id AND Manager.Id != :rsdUser.Manager.Id AND Manager.Id != null LIMIT 1];

		Task testTask = TestClassUtility.createTask(false);
		testTask.OwnerId = rsdUser.Id;

		insert testTask;

		// Task Owner Assertion
		System.runAs(rsdUser) {
			NVM_Embedded_Player_Controller testController = new NVM_Embedded_Player_Controller(new ApexPages.StandardController(testTask));

			//System.assert(testController.allowedToViewRecordings);
		}

		// Task Owner Manager Assertion
		System.runAs(rsdUser.Manager) {
			NVM_Embedded_Player_Controller testController = new NVM_Embedded_Player_Controller(new ApexPages.StandardController(testTask));

			//System.assert(testController.allowedToViewRecordings);
		}

		// Non-owner Manager Assertion
		System.runAs(nonOwnerRsd.Manager) {
			NVM_Embedded_Player_Controller testController = new NVM_Embedded_Player_Controller(new ApexPages.StandardController(testTask));

			//System.assert(!testController.allowedToViewRecordings);
		}

		// System Administrator Assertion
		NVM_Embedded_Player_Controller testController = new NVM_Embedded_Player_Controller(new ApexPages.StandardController(testTask));

		//System.assert(testController.allowedToViewRecordings);
		//System.assert(testController.systemAdmin);
	}

	@isTest
	static void negativeTests() {
		NVM_Embedded_Player_Controller.getUserRecord(null);
	}
}