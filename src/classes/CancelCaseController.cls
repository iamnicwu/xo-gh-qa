/**
 * The controller for the cancel case lightning components.
 */
public with sharing class CancelCaseController {
  public static final String CANCEL = 'Cancel';
  public static final String DOWNGRADE = 'Downgrade';
  public static final String PROSPECTING = 'PROSPECTING';
  public static final String SAVED = 'saved';

  /**
   * Get all picklist values.
   *
   * @return Map<String, List<PicklistValueDTO>>.
   */
  @AuraEnabled
  public static Map<String, List<PicklistValueDTO>> getAllPicklistOptions() {
    List<PicklistValueDTO> originOptions = CaseService.getInstance().getOriginOptions();
    List<PicklistValueDTO> typeOptions = CaseService.getInstance().getTypeOptions();
    List<PicklistValueDTO> reasonOptions = CaseService.getInstance().getReasonOptions();
    List<PicklistValueDTO> outcomeOptions = CaseService.getInstance().getOutcomeOptions();
    List<PicklistValueDTO> savedByOptions = CaseService.getInstance().getSavedByOptions();

    return new Map<String, List<PicklistValueDTO>> {
        'originOptions' => originOptions,
        'typeOptions' => typeOptions,
        'reasonOptions' => reasonOptions,
        'outcomeOptions' => outcomeOptions,
        'savedByOptions' => savedByOptions
    };
  }

  /**
   * Get or create a case for the account id.
   *
   * @param accountId - The account id.
   * @return Case object.
   */
  @AuraEnabled
  public static CaseDTO getCaseForAccount(String accountId) {
    try {
      return CaseService.getInstance().getOrCreateCaseForAccount(accountId);
    } catch (Exception e) {
      throw LightningUtility.createException(e.getMessage());
    }
  }

  /**
   * Get or create a case for the account id.
   *
   * @param Map<String, Object> caseValues The case values to upsert.
   * @param Boolean insertOpportunity If true create a cancel case Opportunity.
   * @return Case object.
   */
  @AuraEnabled
  public static Map<String, Boolean> saveCase(Map<String, Object> caseValues, Boolean insertOpportunity) {
    try {
      Case upsertedCase = CaseService.getInstance().upsertCase(CaseDTO.getCase(caseValues));
      if (caseValues.get('associatedTaskOrEmail') != null) {
        String taskId = String.valueOf(caseValues.get('associatedTaskOrEmail'));
        TaskDAO.getInstance().addCaseToTask(upsertedCase.Id, taskId);
      }

      if(insertOpportunity) {
        generateCancelOpp(upsertedCase.Id);
      }
      return new Map<String, Boolean> {
          SAVED => true
      };
    } catch (Exception e) {
      throw LightningUtility.createException(e.getMessage());
    }
  }

  /**
   * Upload file as attachment
   *
   * @param String parentId The parent the attachment belongs to.
   * @param String fileName The name of the file.
   * @param String base64Data The file contents.
   * @param String contentType The file type.
   * @param String fileId The attachment id.
   * @return String Id of the attachment.
   */
  @AuraEnabled
  public static String saveFileChunk(String parentId, String fileName, String base64Data, String contentType, String attachmentId) {
    try {
      if (attachmentId == null || attachmentId.equals('')) {
        attachmentId = CaseService.getInstance().saveFile(parentId, fileName, base64Data, contentType);
      } else {
        CaseService.getInstance().appendToFile(attachmentId, base64Data);
      }
      return attachmentId;
    } catch (Exception e) {
      throw LightningUtility.createException(e.getMessage());
    }
  }

  /**
   * Delete an attachment
   *
   * @param String attachmentId The attachment id.
   * @return Map<String, Boolean>.
   */
  @AuraEnabled
  public static Map<String, Boolean> removeAttachment(String attachmentId) {
    try {
      Boolean result = CaseService.getInstance().deleteAttachment(attachmentId);
      return new Map<String, Boolean>{
          SAVED => result
      };
    } catch (Exception e) {
      throw LightningUtility.createException(e.getMessage());
    }
  }

  /**
   * Create the cancel opportunity for the cancel case.
   *
   * @param cancelCaseId The case Id.
   */
  public static void generateCancelOpp(Id cancelCaseId) {

    //TODO: CaseService
    Case CancelCase = [
        SELECT Id, CaseNumber, OwnerId, AccountId
        FROM Case
        WHERE Id = :cancelCaseId
    ];

    RecordType localOpportunityRecordType = RecordTypeService.getInstance().getLocalRecordTypeForOpportunity();

    Opportunity newOpp = new Opportunity();

    if (localOpportunityRecordType != null) {
      newOpp.RecordTypeId = localOpportunityRecordType.Id;
    }

    newOpp.OwnerId = cancelCase.OwnerId;
    newOpp.Name = String.format('Cancel Case {0} Cancel Request', new String[]{
        cancelCase.CaseNumber
    });
    //TODO: uncomment before merge...label does not exist in sandbox.
    // newOpp.Contract_Signer__c = Label.Contact_Signer_for_Cancel_Opp;
    newOpp.AccountId = cancelCase.AccountId;
    newOpp.CloseDate = Date.today().addDays(7);
    newOpp.Opportunity_Expiration_Date__c = Date.today().addDays(7);
    newOpp.StageName = PROSPECTING;
    newOpp.Type = CANCEL;
    newOpp.Approval_Process_Flag_Skip_EchoSign__c = true;
    newOpp.Skip_EchoSign_Reason_Code__c = DOWNGRADE;
    //TODO: uncomment before merge...field does not exist in sandbox.
    // newOpp.Cancel_Case__c = cancelCase.Id;

    OpportunityService.getInstance().insertOpportunities(new List<Opportunity>{newOpp});
  }
}