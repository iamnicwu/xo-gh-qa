/**
 * Case Data Transfer object
 */
public with sharing class CaseDTO {
  @AuraEnabled public String id { get; set; }
  @AuraEnabled public String caseOwnerId { get; set; }
  @AuraEnabled public String caseOwnerName { get; set; }
  @AuraEnabled public String contactId { get; set; }
  @AuraEnabled public String contactName { get; set; }
  @AuraEnabled public String accountId { get; set; }
  @AuraEnabled public String accountName { get; set; }
  @AuraEnabled public String initialContact { get; set; }
  @AuraEnabled public String associatedTaskOrEmail { get; set; }
  @AuraEnabled public Datetime originalRequestDate { get; set; }
  @AuraEnabled public String type { get; set; }
  @AuraEnabled public String reason { get; set; }
  @AuraEnabled public String cancelReasonNotes { get; set; }
  @AuraEnabled public String outcome { get; set; }
  @AuraEnabled public String savedBy { get; set; }
  @AuraEnabled public List<AttachmentDTO> attachments { get; set; }
  @AuraEnabled public List<TaskDTO> tasks { get; set; }

  public CaseDTO(
      String caseOwnerId,
      String caseOwnerName,
      String contactId,
      String contactName,
      String accountId,
      String accountName,
      Datetime requestDate) {
    this.id = null;
    this.caseOwnerId = caseOwnerId;
    this.caseOwnerName = caseOwnerName;
    this.contactId = contactId;
    this.contactName = contactName;
    this.accountId = accountId;
    this.accountName = accountName;
    this.initialContact = null;
    this.associatedTaskOrEmail = null;
    this.originalRequestDate = requestDate;
    this.type = null;
    this.reason = null;
    this.cancelReasonNotes = null;
    this.outcome = null;
    this.savedBy = null;
    this.attachments = new List<AttachmentDTO>();
    this.tasks = new List<TaskDTO>();
  }

  public CaseDTO(Case caseObj, String caseOwnerName, String contactName, String accountName) {
    this.id = caseObj.Id;
    this.caseOwnerId = caseObj.OwnerId;
    this.caseOwnerName = caseOwnerName;
    this.contactId = caseObj.ContactId;
    this.contactName = contactName;
    this.accountId = caseObj.AccountId;
    this.accountName = accountName;
    this.initialContact = caseObj.Origin;
    this.associatedTaskOrEmail = null;
    this.originalRequestDate = caseObj.Date_and_Time_Request_Received__c;
    this.type = caseObj.Type;
    this.reason = caseObj.Reason;
    this.cancelReasonNotes = caseObj.Cancel_Reason_Notes__c;
    this.outcome = caseObj.Outcome__c;
    this.savedBy = caseObj.Saved_By__c;
    this.attachments = new List<AttachmentDTO>();
    this.tasks = new List<TaskDTO>();
  }

  /*
   * Method to return Case object from dto.
   *
   * @return Case.
   */
  public static Case getCase(Map<String, Object> caseValues) {
    Case newCase = new Case();

    if (caseValues.get('id') != null) {
      newCase.Id = String.valueOf(caseValues.get('id'));
    } else {
      // If we have an Id, we know this is an update, so this isn't required
      newCase.RecordTypeId = CaseService.getInstance().getCancelRecordTypeId();
    }

    if (caseValues.get('caseOwnerId') != null) {
      newCase.OwnerId = String.valueOf(caseValues.get('caseOwnerId'));
    }

    if (caseValues.get('contactId') != null) {
      newCase.ContactId = String.valueOf(caseValues.get('contactId'));
    }

    if (caseValues.get('accountId') != null) {
      newCase.AccountId = String.valueOf(caseValues.get('accountId'));
    }

    if (caseValues.get('initialContact') != null) {
      newCase.Origin = String.valueOf(caseValues.get('initialContact'));
    }

    if (caseValues.get('originalRequestDate') != null) {
      String dt = String.valueOf(caseValues.get('originalRequestDate'));
      newCase.Date_and_Time_Request_Received__c = Datetime.valueOf(dt);
    }

    if (caseValues.get('type') != null) {
      newCase.Type = String.valueOf(caseValues.get('type'));
    }

    if (caseValues.get('reason') != null) {
      newCase.Reason = String.valueOf(caseValues.get('reason'));
    }

    if (caseValues.get('cancelReasonNotes') != null) {
      newCase.Cancel_Reason_Notes__c = String.valueOf(caseValues.get('cancelReasonNotes'));
    }

    if (caseValues.get('outcome') != null) {
      newCase.Outcome__c = String.valueOf(caseValues.get('outcome'));
    }

    if (caseValues.get('savedBy') != null) {
      newCase.Saved_By__c = String.valueOf(caseValues.get('savedBy'));
    } else {
      newCase.Saved_By__c = null;
    }

    return newCase;
  }
}