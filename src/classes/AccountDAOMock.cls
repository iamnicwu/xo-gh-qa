public abstract with sharing class AccountDAOMock extends AbstractMock {
  private List<Object> listOfArgs;

  protected override Object callMockedMethod(String stubbedMethodName, List<Object> listOfArgs) {
    this.listOfArgs = listOfArgs;

    if (stubbedMethodName == 'getAccountById') {
      System.assertEquals(1, listOfArgs.size());
      return getAccountById((String) listOfArgs[0]);
    } else if (stubbedMethodName == 'searchAccounts') {
      System.assertEquals(1, listOfArgs.size());
      return searchAccounts((String) listOfArgs[0]);
    }

    throw new Exceptions.MockException('Failed to find method for ' + stubbedMethodName);

  }

  public List<Object> getListOfArgs() {
    return this.listOfArgs;
  }

  public virtual Account getAccountById(String accId) {
    throw newUnsupportedMethodException('getAccountById');
  }

  public virtual List<Account> searchAccounts(String searchString) {
    throw newUnsupportedMethodException('searchAccounts');
  }
}