/**
 * Account object data access object
 */
public with sharing class AccountDAO {
  private static AccountDAO instance;

  @TestVisible
  private static void setMock(AccountDAO mock) {
    if (instance != null) {
      throw new Exceptions.ServiceException('The dao was already mocked or accessed.');
    }
    instance = mock;
  }

  public static AccountDAO getInstance() {
    if (instance == null) {
      instance = new AccountDAO();
    }
    return instance;
  }

  /*
   * Method to get Account by Id
   *
   * @param String accId - The account id.
   * @return Account object or null
   */
  public Account getAccountById(String accId) {
    List<Account> acct = [SELECT Id, Name FROM Account WHERE Id = :accId LIMIT 1];
    return (acct.size() == 1) ? acct.get(0) : null;
  }

  /*
   * Method to list of Accounts by search string
   *
   * @param String searchText The search text.
   * @return List<Account> The list of Accounts.
   */
  public List<Account> searchAccounts(String searchText) {
    List<List<SObject>> results = [FIND :searchText IN ALL FIELDS RETURNING Account(Id, Name)];
    List<Account> accounts = results.size() == 1 ? results.get(0) : null;
    return accounts;
  }
}