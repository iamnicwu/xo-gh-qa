@IsTest
private class UserDAOTest {
  @IsTest
  static void testGetUserById() {
    List<User> u = [SELECT Id FROM User LIMIT 1];

    Test.startTest();
    User usr = UserDAO.getInstance().getUserById(u.get(0).Id);
    Test.stopTest();

    System.assert(usr != null, 'Should return user.');
    System.assertEquals(u.get(0).Id, usr.Id, 'Should have correct id.');
  }

  @IsTest
  static void testSearchUsers() {
    List<User> u = [SELECT Id, Name FROM User LIMIT 1];

    // This is needed to test the SOSL query
    List<Id> fixedSearchResults= new List<Id>();
    fixedSearchResults.add(u.get(0).Id);
    Test.setFixedSearchResults(fixedSearchResults);

    Test.startTest();
    List<User> usrs = UserDAO.getInstance().searchUsers(u.get(0).Name);
    Test.stopTest();

    System.assertEquals(1, usrs.size(), 'Should return 1 item.');
    System.assertEquals(u.get(0).Name, usrs.get(0).Name, 'Should have correct name.');
  }

  @IsTest
  static void testSearchUsersNoResults() {
    Test.startTest();
    List<User> usrs = UserDAO.getInstance().searchUsers('Test');
    Test.stopTest();

    System.assertEquals(0, usrs.size(), 'Should return 0 items.');
  }

  @IsTest
  static void testGetUsersOnAccount() {
    Account acc = new Account();
    acc.Name = 'Temp Account';
    insert acc;

    List<User> u = [SELECT Id, Name FROM User LIMIT 1];

    Test.startTest();
    List<User> usrs = UserDAO.getInstance().getUsersOnAccount(acc.Id);
    Test.stopTest();

    System.assertEquals(0, usrs.size(), 'Should return 0 item.');
  }
}