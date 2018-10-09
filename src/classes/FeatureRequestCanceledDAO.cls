/**
 * FeatureRequestCanceled object data access object.
 */
public with sharing class FeatureRequestCanceledDAO {

  private static FeatureRequestCanceledDAO instance;

  @TestVisible
  private static void setMock(FeatureRequestCanceledDAO mock) {
    if (instance != null) {
      throw new Exceptions.ServiceException('The service was already mocked or accessed.');
    }
    instance = mock;
  }

  public static FeatureRequestCanceledDAO getInstance() {
    if (instance == null) {
      instance = new FeatureRequestCanceledDAO();
    }
    return instance;
  }

  /**
   * Upsert a list of Feature_Requested_Cancelled__c objects.
   *
   * @param frcs The List of Feature_Requested_Cancelled__c.
   */
  public void upsertFRCs(List<Feature_Requested_Cancelled__c> frcs) {
    upsert frcs UniqueId__c;
  }

  /**
   * Delete a list of Feature_Requested_Cancelled__c objects.
   *
   * @param frcs The List of Feature_Requested_Cancelled__c.
   */
  public void deleteFRCs(List<Feature_Requested_Cancelled__c> frcs) {
    delete frcs;
  }
}