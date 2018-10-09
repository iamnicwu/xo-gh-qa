public abstract with sharing class CaseDAOMock extends AbstractMock {
  private List<Object> listOfArgs;

  protected override Object callMockedMethod(String stubbedMethodName, List<Object> listOfArgs) {
    this.listOfArgs = listOfArgs;

    if (stubbedMethodName == 'getRecordTypeByName') {
      System.assertEquals(1, listOfArgs.size());
      return getRecordTypeByName((String) listOfArgs[0]);
    } else if (stubbedMethodName == 'getCaseByAccountAndRecordType') {
      System.assertEquals(2, listOfArgs.size());
      return getCaseByAccountAndRecordType((String) listOfArgs[0], (String) listOfArgs[1]);
    } else if (stubbedMethodName == 'upsertCase') {
      System.assertEquals(1, listOfArgs.size());
      return upsertCase((Case) listOfArgs[0]);
    } else if (stubbedMethodName == 'getWithFeatureRequestCancelled') {
      System.assertEquals(1, listOfArgs.size());
      return getWithFeatureRequestCancelled((Id) listOfArgs[0]);
    }

    throw new Exceptions.MockException('Failed to find method for ' + stubbedMethodName);

  }

  public List<Object> getListOfArgs() {
    return this.listOfArgs;
  }

  public virtual RecordType getRecordTypeByName(String name) {
    throw newUnsupportedMethodException('getRecordTypeByName');
  }

  public virtual Case getCaseByAccountAndRecordType(String accountId, String recordTypeId) {
    throw newUnsupportedMethodException('getCaseByAccountAndRecordType');
  }

  public virtual Case upsertCase(Case c) {
    throw newUnsupportedMethodException('upsertCase');
  }

  public virtual Case getWithFeatureRequestCancelled(Id caseId) {
    throw newUnsupportedMethodException('getCaseWithFeatureRequestCancelled');
  }
}