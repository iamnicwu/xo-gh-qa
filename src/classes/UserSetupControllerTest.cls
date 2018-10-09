// UserSetupController test coverge - 100% on 08/30/2016
@isTest
private class UserSetupControllerTest {
	
	@isTest static void auraFunctionTests() {
		// Get picklist values function
    UserSetupController.getUserPicklists();

    // Get user list function
    List<User> userList = UserSetupController.getUsers(null);

    // Get a user from the previous user list - if userlist is empty for some reason query for any user
    User testUser;
    if(userList.size() < 1) {
      testUser = userList[0];
    } else {
      testUser = [SELECT Id, Name FROM User WHERE IsActive = true LIMIT 1];
    }

    // Fail clause hit
    UserSetupController.updateUser(null);

    // Normal success
    UserSetupController.updateUser(testUser);

    // Failure on Update
    testUser.Email = 'notanemail';
    UserSetupController.updateUser(testUser);
	}
}