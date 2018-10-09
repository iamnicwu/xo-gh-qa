/**
 * SubscriptionProductCharge object data access object.
 */
public with sharing class SubscriptionProductChargeDAO {

  private static SubscriptionProductChargeDAO instance;

  @TestVisible
  private static void setMock(SubscriptionProductChargeDAO mock) {
    if (instance != null) {
      throw new Exceptions.ServiceException('The service was already mocked or accessed.');
    }
    instance = mock;
  }

  public static SubscriptionProductChargeDAO getInstance() {
    if (instance == null) {
      instance = new SubscriptionProductChargeDAO();
    }
    return instance;
  }

  /**
   * Get all SubscriptionProductCharge object for an account that have an active subscription.
   *
   * @param accountId The account Id.
   *
   * @return A list of Zuora__SubscriptionProductCharge__c objects.
   */
  public List<Zuora__SubscriptionProductCharge__c> getActiveForAccount(Id accountId) {

    List<Zuora__SubscriptionProductCharge__c> subscriptionProductCharges = [
        SELECT Id, Name, Zuora__Account__c, Zuora__Account__r.Name, Zuora__ChargeNumber__c, Zuora__Subscription__r.Zuora__Version__c,
        Zuora__Subscription__c, Zuora__Subscription__r.Name, Zuora__Zuora_Id__c, Zuora__Subscription__r.Zuora__Zuora_Id__c,
        LDE_Email_Launch_Date__c, Zuora__SubscriptionChargeNumber__c, Zuora__Product__c,
        Zuora__Product__r.Name, Zuora__RatePlanName__c, LocationVendorDynamicsAccountID__c,
        List_Price__c,Zuora__Price__c, Zuora__BillingPeriod__c, Zuora__Subscription__r.Zuora__SubscriptionEndDate__c,
        Zuora__Subscription__r.Sales_Rep__r.FirstName, Zuora__Subscription__r.Sales_Rep__r.LastName,
        Zuora__Subscription__r.Sales_Rep__c, Zuora__Subscription__r.Zuora__TermEndDate__c, Zuora__Subscription__r.Zuora__TermStartDate__c
        FROM Zuora__SubscriptionProductCharge__c
        WHERE Zuora__Account__c = :accountId
//        AND Zuora__Subscription__r.True_Subscription_Status__c ='Active' //TODO: uncomment me, value can't be set in sandbox.
    ];

    return subscriptionProductCharges;
  }

}