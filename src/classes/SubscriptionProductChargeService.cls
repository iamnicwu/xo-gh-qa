/**
 * Service class for Zuora__SubscriptionProductCharge__c objects.
 */
public with sharing class SubscriptionProductChargeService {

  private static SubscriptionProductChargeService instance;

  @TestVisible
  private static void setMock(SubscriptionProductChargeService mock) {
    if (instance != null) {
      throw new Exceptions.ServiceException('The service was already mocked or accessed.');
    }
    instance = mock;
  }

  public static SubscriptionProductChargeService getInstance() {
    if (instance == null) {
      instance = new SubscriptionProductChargeService();
    }
    return instance;
  }

  /**
   * Get all Zuora__SubscriptionProductCharge__c object for an account with an active subscription.
   *
   * @param accountId The account Id.
   *
   * @return A list of Zuora__SubscriptionProductCharge__c objects.
   */
  public List<Zuora__SubscriptionProductCharge__c> getActiveForAccount(Id accountId) {
    return SubscriptionProductChargeDAO.getInstance().getActiveForAccount(accountId);
  }

}