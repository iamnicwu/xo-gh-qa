/**
 * Service for FeatureRequestCanceled objects.
 */
public with sharing class FeatureRequestedCancelService {

  private static FeatureRequestedCancelService instance;

  @TestVisible
  private static void setMock(FeatureRequestedCancelService mock) {
    if (instance != null) {
      throw new Exceptions.ServiceException('The service was already mocked or accessed.');
    }
    instance = mock;
  }

  public static FeatureRequestedCancelService getInstance() {
    if (instance == null) {
      instance = new FeatureRequestedCancelService();
    }
    return instance;
  }

  /**
   * Get the potential values on the Status__c picklist.
   *
   * @return List<SelectOption> The List of <code>Schema.PicklistEntry</code> values for the Status__c field.
   */
  public List<SelectOption> getStatusOptions(){
    List<SelectOption> statusValues = new List<SelectOption>();
    Schema.DescribeFieldResult fieldResult = Feature_Requested_Cancelled__c.Status__c.getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    for (Schema.PicklistEntry f : ple){
      statusValues.add(new SelectOption(f.getLabel(), f.getValue()));
    }

    return statusValues;
  }

  /**
   * Upsert a list of Feature_Requested_Cancelled__c objects.
   *
   * @param frcs The List of Feature_Requested_Cancelled__c.
   */
  public void upsertFRCs(List<Feature_Requested_Cancelled__c> frcs) {
    FeatureRequestCanceledDAO.getInstance().upsertFRCs(frcs);
  }

  /**
   * Delete a list of Feature_Requested_Cancelled__c objects.
   *
   * @param frcs The List of Feature_Requested_Cancelled__c.
   */
  public void deleteFRCs(List<Feature_Requested_Cancelled__c> frcs) {
    FeatureRequestCanceledDAO.getInstance().deleteFRCs(frcs);
  }

}