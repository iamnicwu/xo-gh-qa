public abstract with sharing class SubscriptionProductChargeServiceMock extends AbstractMock {
  private List<Object> listOfArgs;

  protected override Object callMockedMethod(String stubbedMethodName, List<Object> listOfArgs) {
    this.listOfArgs = listOfArgs;

    if (stubbedMethodName == 'getActiveForAccount') {
      System.assertEquals(1, listOfArgs.size());
      return getActiveForAccount((Id) listOfArgs[0]);
    }

    throw new Exceptions.MockException('Failed to find method for ' + stubbedMethodName);

  }

  public virtual List<Zuora__SubscriptionProductCharge__c> getActiveForAccount(Id accountId) {
    throw newUnsupportedMethodException('getActiveForAccount');
  }
}