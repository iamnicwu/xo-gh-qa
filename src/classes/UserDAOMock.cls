public abstract with sharing class UserDAOMock extends AbstractMock {
  private List<Object> listOfArgs;

  protected override Object callMockedMethod(String stubbedMethodName, List<Object> listOfArgs) {
    this.listOfArgs = listOfArgs;

    if (stubbedMethodName == 'getUserById') {
      System.assertEquals(1, listOfArgs.size());
      return getUserById((String) listOfArgs[0]);
    } else if (stubbedMethodName == 'searchUsers') {
      System.assertEquals(1, listOfArgs.size());
      return searchUsers((String) listOfArgs[0]);
    } else if (stubbedMethodName == 'getUsersOnAccount') {
      System.assertEquals(1, listOfArgs.size());
      return getUsersOnAccount((String) listOfArgs[0]);
    }

    throw new Exceptions.MockException('Failed to find method for ' + stubbedMethodName);

  }

  public List<Object> getListOfArgs() {
    return this.listOfArgs;
  }

  public virtual User getUserById(String userId) {
    throw newUnsupportedMethodException('getUserById');
  }

  public virtual List<User> searchUsers(String searchString) {
    throw newUnsupportedMethodException('searchUsers');
  }

  public virtual List<User> getUsersOnAccount(String accountId) {
    throw newUnsupportedMethodException('getUsersOnAccount');
  }
}