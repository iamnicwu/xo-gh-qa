public abstract with sharing class ContactDAOMock extends AbstractMock {
  private List<Object> listOfArgs;

  protected override Object callMockedMethod(String stubbedMethodName, List<Object> listOfArgs) {
    this.listOfArgs = listOfArgs;

    if (stubbedMethodName == 'getContactByAccountId') {
      System.assertEquals(1, listOfArgs.size());
      return getContactByAccountId((String) listOfArgs[0]);
    } else if (stubbedMethodName == 'getContactById') {
      System.assertEquals(1, listOfArgs.size());
      return getContactById((String) listOfArgs[0]);
    } else if (stubbedMethodName == 'searchContacts') {
      System.assertEquals(2, listOfArgs.size());
      return searchContacts((String) listOfArgs[0], (String) listOfArgs[1]);
    } else if (stubbedMethodName == 'getContactsOnAccount') {
      System.assertEquals(1, listOfArgs.size());
      return getContactsOnAccount((String) listOfArgs[0]);
    }

    throw new Exceptions.MockException('Failed to find method for ' + stubbedMethodName);

  }

  public List<Object> getListOfArgs() {
    return this.listOfArgs;
  }

  public virtual Contact getContactByAccountId(String accId) {
    throw newUnsupportedMethodException('getContactByAccountId');
  }

  public virtual Contact getContactById(String contactId) {
    throw newUnsupportedMethodException('getContactById');
  }

  public virtual List<Contact> searchContacts(String searchString, String accountId) {
    throw newUnsupportedMethodException('searchContacts');
  }

  public virtual List<Contact> getContactsOnAccount(String accId) {
    throw newUnsupportedMethodException('getContactsOnAccount');
  }
}