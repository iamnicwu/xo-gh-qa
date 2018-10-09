@IsTest
private class AccountDAOTest {
  @IsTest
  static void testGetAccountById() {
    Account acc = new Account();
    acc.Name = 'Account Temp';
    insert acc;

    Test.startTest();
    Account acct = AccountDAO.getInstance().getAccountById(acc.Id);
    Test.stopTest();

    System.assert(acct != null, 'Should return item.');
    System.assertEquals('Account Temp', acct.Name, 'Should have correct name.');
  }

  @IsTest
  static void testSearchAccounts() {
    Account acc = new Account();
    acc.Name = 'Temp Account';
    insert acc;

    // This is needed to test the SOSL query
    List<Id> fixedSearchResults= new List<Id>();
    fixedSearchResults.add(acc.Id);
    Test.setFixedSearchResults(fixedSearchResults);

    Test.startTest();
    List<Account> accts = AccountDAO.getInstance().searchAccounts('Temp');
    Test.stopTest();

    System.assertEquals(1, accts.size(), 'Should return 1 item.');
    System.assertEquals('Temp Account', accts.get(0).Name, 'Should have correct name.');
  }

  @IsTest
  static void testSearchAccountsNoResults() {
    Test.startTest();
    List<Account> accts = AccountDAO.getInstance().searchAccounts('Temp');
    Test.stopTest();

    System.assertEquals(0, accts.size(), 'Should return 0 items.');
  }
}