@IsTest
private class SubscriptionProductChargeServiceTest {

  @IsTest
  static void testgetActiveForAccountNoResults() {
    Map<String, SObject> testObjects = TestClassUtility.buildLocalData(false);
    Account acc = (Account)testObjects.get('Account');

    Test.startTest();
    List<Zuora__SubscriptionProductCharge__c> spcs = SubscriptionProductChargeService.getInstance().getActiveForAccount(acc.Id);
    Test.stopTest();

    System.assertEquals(0, spcs.size());
  }

  @IsTest
  static void testgetActiveForAccount() {
    Zuora__Product__c zp = new Zuora__Product__c();
    zp.Name = 'Storefront';
    insert zp;

    Map<String, SObject> testObjects = TestClassUtility.buildLocalData(false);
    Account account = (Account)testObjects.get('Account');

    Zuora__SubscriptionRatePlan__c zsp = new Zuora__SubscriptionRatePlan__c();
    zsp.Name = 'Storefront | MI-Grand Rpds/Northern | Florists';
    insert zsp;

    Zuora__Subscription__c subscription = new Zuora__Subscription__c();
    subscription.Name = 'Recurring Charge';
    subscription.Zuora__SubscriptionEndDate__c  = Date.valueOf('2019-06-15');
    insert subscription;

    Zuora__SubscriptionProductCharge__c zspc = new Zuora__SubscriptionProductCharge__c();
    zspc.Name = '5';
    zspc.Zuora__ChargeNumber__c = '5';
    zspc.Zuora__SubscriptionRatePlan__c = zsp.Id;
    zspc.LDE_Email_Launch_Date__c = Date.valueOf('2017-05-15');
    zspc.LocationVendorDynamicsAccountID__c = 'abc123';
    zspc.List_Price__c = '45';
    zspc.Zuora__Price__c = 45.01;
    zspc.Zuora__BillingPeriod__c = 'Month';
    zspc.Zuora__Product__c = zp.Id;
    zspc.Zuora__Account__c = account.Id;
    zspc.Zuora__Subscription__c = subscription.Id;

    SubscriptionProductChargeDAOSuccessMock spcMock = new SubscriptionProductChargeDAOSuccessMock(new List<Zuora__SubscriptionProductCharge__c>{zspc});
    SubscriptionProductChargeDAO.setMock((SubscriptionProductChargeDAO) Test.createStub(SubscriptionProductChargeDAO.class, spcMock));

    Test.startTest();
    List<Zuora__SubscriptionProductCharge__c> spcs = SubscriptionProductChargeService.getInstance().getActiveForAccount(account.Id);
    Test.stopTest();

    System.assertEquals(1, spcs.size());
  }

  class SubscriptionProductChargeDAOSuccessMock extends SubscriptionProductChargeDAOMock {
    private List<Zuora__SubscriptionProductCharge__c> spcs;

    public SubscriptionProductChargeDAOSuccessMock(List<Zuora__SubscriptionProductCharge__c> spcs) {
      this.spcs = spcs;
    }

    public override List<Zuora__SubscriptionProductCharge__c> getActiveForAccount(Id accountId) {
      return this.spcs;
    }

  }

}