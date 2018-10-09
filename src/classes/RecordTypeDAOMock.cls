public abstract with sharing class RecordTypeDAOMock extends AbstractMock {
  private List<Object> listOfArgs;

  protected override Object callMockedMethod(String stubbedMethodName, List<Object> listOfArgs) {
    this.listOfArgs = listOfArgs;

    if (stubbedMethodName == 'getLocalRecordTypeForOpportunity') {
      System.assertEquals(0, listOfArgs.size());
      return getLocalRecordTypeForOpportunity();
    } else if (stubbedMethodName == 'getRecordTypeByName') {
      System.assertEquals(1, listOfArgs.size());
      return getRecordTypeByName((String) listOfArgs.get(0));
    }

    throw new Exceptions.MockException('Failed to find method for ' + stubbedMethodName);

  }

  public virtual RecordType getRecordTypeByName(String name) {
    throw newUnsupportedMethodException('getRecordTypeByName');
  }

  public virtual RecordType getLocalRecordTypeForOpportunity() {
    throw newUnsupportedMethodException('getLocalRecordTypeForOpportunity');
  }
}