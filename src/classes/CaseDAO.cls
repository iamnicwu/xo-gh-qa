/**
 * Case object data access object
 */
public with sharing class CaseDAO {
  private static CaseDAO instance;

  @TestVisible
  private static void setMock(CaseDAO mock) {
    if (instance != null) {
      throw new Exceptions.ServiceException('The dao was already mocked or accessed.');
    }
    instance = mock;
  }

  public static CaseDAO getInstance() {
    if (instance == null) {
      instance = new CaseDAO();
    }
    return instance;
  }



  /*
   * Method to get single case by account and record type
   *
   * @param String accountId The account id the case belongs to.
   * @param String recordTypeId The id of the record type
   * @return Case The Case or null.
   */
  public Case getCaseByAccountAndRecordType(String accountId, String recordTypeId) {

    List<Case> cases = [
        SELECT Id,
            AccountId,
            Account_Owner__c,
            CaseNumber,
            ContactId,
            Origin,
            OwnerId,
            RecordTypeId,
            Date_and_Time_Request_Received__c,
            Type,
            Reason,
            Cancel_Reason_Notes__c,
            Outcome__c,
            Saved_By__c
        FROM Case
        WHERE AccountId = :accountId
        AND RecordTypeId = :recordTypeId
        AND IsClosed = FALSE
        LIMIT 1
    ];

    return (cases.size() == 1) ? cases.get(0) : null;
  }

  /*
   * Method to upsert case object
   *
   * @param Case c The case to upsert.
   * @return Case.
   */
  public Case upsertCase(Case c) {
    try {
      upsert c;
      return c;
    } catch (DmlException e) {
      System.debug('Error upsertCase ' + e.getMessage());
      throw e;
    }
  }

  /**
   * Get a Case with related Feature_Request_Canceled data.
   *
   * @param caseId The case Id.
   *
   * @return A Case with Feature_Requested_Cancelled__r data.
   */
  public Case getWithFeatureRequestCancelled(Id caseId) {
    List<Case> cases = [
        SELECT
            Id, AccountId,
        (SELECT Id, Case__c, Status__c, Subscription_Product_Charge__c, UniqueId__c, Sub_Product_Charge_Number__c
        FROM Feature_Requested_Cancelled__r)
        FROM Case
        WHERE Id =: caseId
        LIMIT 1
    ];
    Case aCase = (cases.size() == 1) ? cases.get(0) : null;
    return aCase;
  }
}