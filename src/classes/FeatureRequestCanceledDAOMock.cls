public abstract with sharing class FeatureRequestCanceledDAOMock extends AbstractMock {
  private List<Object> listOfArgs;

  protected override Object callMockedMethod(String stubbedMethodName, List<Object> listOfArgs) {
    this.listOfArgs = listOfArgs;

    if (stubbedMethodName == 'upsertFRCs') {
      System.assertEquals(1, listOfArgs.size());
      upsertFRCs((List<Feature_Requested_Cancelled__c>) listOfArgs[0]);
      return null;
    } else if (stubbedMethodName == 'deleteFRCs') {
      System.assertEquals(1, listOfArgs.size());
      deleteFRCs((List<Feature_Requested_Cancelled__c>) listOfArgs[0]);
      return null;
    }

    throw new Exceptions.MockException('Failed to find method for ' + stubbedMethodName);

  }

  public virtual void upsertFRCs(List<Feature_Requested_Cancelled__c> frcs) {
    throw newUnsupportedMethodException('upsertFRCs');
  }

  public virtual void deleteFRCs(List<Feature_Requested_Cancelled__c> frcs) {
    throw newUnsupportedMethodException('deleteFRCs');
  }
}