/**
 * Case Service
 */
public with sharing class CaseService {
  private final static String CANCEL_RECORD_TYPE = '1 - Cancels';

  private static CaseService instance;

  @TestVisible
  private static void setMock(CaseService mock) {
    if (instance != null) {
      throw new Exceptions.ServiceException('The service was already mocked or accessed.');
    }
    instance = mock;
  }

  public static CaseService getInstance() {
    if (instance == null) {
      instance = new CaseService();
    }
    return instance;
  }

  /**
   * Get list of active picklist values for origin.
   *
   * @return List<SelectOption>.
   */
  public List<PicklistValueDTO> getOriginOptions() {
    List<PicklistValueDTO> options = new List<PicklistValueDTO>{
        new PicklistValueDTO('', '')
    };
    Schema.DescribeFieldResult fieldResult = Case.Origin.getDescribe();
    List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
    for(Schema.PicklistEntry entry : values) {
      if (entry.isActive()) {
        options.add(new PicklistValueDTO(entry.getLabel(), entry.getValue()));
      }
    }

    return options;
  }

  /**
   * Get list of active picklist values for type.
   *
   * @return List<SelectOption>.
   */
  public List<PicklistValueDTO> getTypeOptions() {
    List<PicklistValueDTO> options = new List<PicklistValueDTO>{
        new PicklistValueDTO('', '')
    };
    Schema.DescribeFieldResult fieldResult = Case.Type.getDescribe();
    List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
    for(Schema.PicklistEntry entry : values) {
      if (entry.isActive()) {
        options.add(new PicklistValueDTO(entry.getLabel(), entry.getValue()));
      }
    }

    return options;
  }

  /**
   * Get list of active picklist values for type.
   *
   * @return List<SelectOption>.
   */
  public List<PicklistValueDTO> getReasonOptions() {
    List<PicklistValueDTO> options = new List<PicklistValueDTO>{
        new PicklistValueDTO('', '')
    };
    Schema.DescribeFieldResult fieldResult = Case.Reason.getDescribe();
    List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
    for(Schema.PicklistEntry entry : values) {
      if (entry.isActive()) {
        options.add(new PicklistValueDTO(entry.getLabel(), entry.getValue()));
      }
    }

    return options;
  }

  /**
   * Get list of active picklist values for outcome.
   *
   * @return List<SelectOption>.
   */
  public List<PicklistValueDTO> getOutcomeOptions() {
    List<PicklistValueDTO> options = new List<PicklistValueDTO>{
        new PicklistValueDTO('', '')
    };
    Schema.DescribeFieldResult fieldResult = Case.Outcome__c.getDescribe();
    List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
    for(Schema.PicklistEntry entry : values) {
      if (entry.isActive()) {
        options.add(new PicklistValueDTO(entry.getLabel(), entry.getValue()));
      }
    }

    return options;
  }

  /**
   * Get list of active picklist values for outcome.
   *
   * @return List<SelectOption>.
   */
  public List<PicklistValueDTO> getSavedByOptions() {
    List<PicklistValueDTO> options = new List<PicklistValueDTO>{
        new PicklistValueDTO('', '')
    };
    Schema.DescribeFieldResult fieldResult = Case.Saved_By__c.getDescribe();
    List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
    for(Schema.PicklistEntry entry : values) {
      if (entry.isActive()) {
        options.add(new PicklistValueDTO(entry.getLabel(), entry.getValue()));
      }
    }

    return options;
  }

  /**
   * Initial search accounts.
   *
   * @param accountId The search string.
   * @return List<SearchResultDTO>.
   */
  public List<SearchResultDTO> getAccountsById(String accountId) {
    List<SearchResultDTO> results = new List<SearchResultDTO>();
    Account acc = AccountDAO.getInstance().getAccountById(accountId);

    if (acc != null) {
      results.add(new SearchResultDTO(acc.Id, acc.Name));
    }

    return results;
  }

  /**
   * Search accounts.
   *
   * @param searchVal The search string.
   * @return List<SearchResultDTO>.
   */
  public List<SearchResultDTO> searchAccounts(String searchVal) {
    List<SearchResultDTO> results = new List<SearchResultDTO>();
    List<Account> accounts = AccountDAO.getInstance().searchAccounts(searchVal);

    for (Account acc : accounts) {
      results.add(new SearchResultDTO(acc.Id, acc.Name));
    }

    return results;
  }

  /**
   * Search contacts on account.
   *
   * @param accountId The account id.
   * @return List<SearchResultDTO>.
   */
  public List<SearchResultDTO> getContactsForAccount(String accountId) {
    List<SearchResultDTO> results = new List<SearchResultDTO>();
    List<Contact> contacts = ContactDAO.getInstance().getContactsOnAccount(accountId);

    for (Contact con : contacts) {
      results.add(new SearchResultDTO(con.Id, con.Name));
    }

    return results;
  }

  /**
   * Search contacts.
   *
   * @param searchVal The search string.
   * @param accountId The account id.
   * @return List<SearchResultDTO>.
   */
  public List<SearchResultDTO> searchContacts(String searchVal, String accountId) {
    List<SearchResultDTO> results = new List<SearchResultDTO>();
    List<Contact> contacts = ContactDAO.getInstance().searchContacts(searchVal, accountId);

    for (Contact con : contacts) {
      results.add(new SearchResultDTO(con.Id, con.Name));
    }

    return results;
  }

  /**
   * Search tasks on account.
   *
   * @param accountId The account id.
   * @return List<SearchResultDTO>.
   */
  public List<SearchResultDTO> getTasksForAccount(String accountId) {
    List<SearchResultDTO> results = new List<SearchResultDTO>();
    List<Task> tasks = TaskDAO.getInstance().getTasksForAccount(accountId);

    for (Task t : tasks) {
      Contact contact = null;
      if (t.WhoId != null) {
        contact = ContactDAO.getInstance().getContactById(t.WhoId);
      }
      String tempName = (contact != null) ? t.Type + ' - ' + contact.Name : t.Type;
      results.add(new SearchResultDTO(t.Id, tempName));
    }

    return results;
  }

  /**
   * Search task.
   *
   * @param searchVal The search string.
   * @param accountId The account id.
   * @return List<SearchResultDTO>.
   */
  public List<SearchResultDTO> searchTasks(String searchVal, String accountId) {
    List<SearchResultDTO> results = new List<SearchResultDTO>();
    List<Task> tasks = TaskDAO.getInstance().searchTasks(searchVal, accountId);

    for (Task t : tasks) {
      Contact contact = null;
      if (t.WhoId != null) {
        contact = ContactDAO.getInstance().getContactById(t.WhoId);
      }
      String tempName = (contact != null) ? t.Type + ' - ' + contact.Name : t.Type;
      results.add(new SearchResultDTO(t.Id, tempName));
    }

    return results;
  }

  /**
   * Search Users on account.
   *
   * @param accountId The account id.
   * @return List<SearchResultDTO>.
   */
  public List<SearchResultDTO> getUsersOnAccount(String accountId) {
    List<SearchResultDTO> results = new List<SearchResultDTO>();
    List<User> users = UserDAO.getInstance().getUsersOnAccount(accountId);

    for (User usr : users) {
      results.add(new SearchResultDTO(usr.Id, usr.Name));
    }

    return results;
  }

  /**
   * Search Users.
   *
   * @param searchVal The search string.
   * @return List<SearchResultDTO>.
   */
  public List<SearchResultDTO> searchUsers(String searchVal) {
    List<SearchResultDTO> results = new List<SearchResultDTO>();
    List<User> users = UserDAO.getInstance().searchUsers(searchVal);

    for (User usr : users) {
      results.add(new SearchResultDTO(usr.Id, usr.Name));
    }

    return results;
  }

  /**
   * Get the Id of the cancel record type.
   *
   * @return String.
   */
  public String getCancelRecordTypeId() {
    RecordType recordType = RecordTypeDAO.getInstance().getRecordTypeByName(CANCEL_RECORD_TYPE);
    return (recordType != null) ? recordType.Id : null;
  }

  /**
   * Get or create a case for the account id.
   *
   * @param accountId The account id.
   * @return Case object.
   */
  public CaseDTO getOrCreateCaseForAccount(String accountId) {
    CaseDTO ret;
    String caseOwnerId;
    User caseOwner;
    String caseOwnerName;
    User contact;
    Contact contactOnAccount;
    String contactId;
    String contactName;
    Datetime requestDate;
    String cancelRecordTypeId = this.getCancelRecordTypeId();

    if (cancelRecordTypeId == null) {
      throw new Exceptions.NotFoundException('Record Type ' + CANCEL_RECORD_TYPE + ' not found.');
    }

    Account acc = AccountDAO.getInstance().getAccountById(accountId);
    String accountName = (acc != null) ? acc.Name : '';
    Case foundCase = CaseDAO.getInstance().getCaseByAccountAndRecordType(accountId, cancelRecordTypeId);

    if (foundCase == null) {
      caseOwnerId = UserInfo.getUserId();
      caseOwner = UserDAO.getInstance().getUserById(caseOwnerId);
      caseOwnerName =  (caseOwner != null) ? caseOwner.Name : '';
      contactOnAccount = ContactDAO.getInstance().getContactByAccountId(accountId);
      contactId = (contactOnAccount != null) ? contactOnAccount.Id : null;
      contactName = (contactOnAccount != null) ? contactOnAccount.Name : '';
      requestDate = null;

      ret = new CaseDTO(caseOwnerId, caseOwnerName, contactId, contactName, accountId, accountName, requestDate);
    } else {
      caseOwner = UserDAO.getInstance().getUserById(foundCase.OwnerId);
      caseOwnerName =  (caseOwner != null ) ? caseOwner.Name : '';
      contactOnAccount = ContactDAO.getInstance().getContactById(foundCase.ContactId);
      contactName = (contactOnAccount != null) ? contactOnAccount.Name : '';
      ret = new CaseDTO(foundCase, caseOwnerName, contactName, accountName);

      List<Attachment> caseAttachments = AttachmentDAO.getInstance().getAttachmentOnCase(foundCase.Id);
      List<AttachmentDTO> attachmentDtos = new List<AttachmentDTO>();
      for (Attachment att : caseAttachments) {
        attachmentDtos.add(new AttachmentDTO(att.Id, att.Name));
      }
      ret.attachments = attachmentDtos;

      List<Task> caseTasks = TaskDAO.getInstance().getTaskForCase(foundCase.Id);
      List<TaskDTO> taskDtos = new List<TaskDTO>();
      for (Task t : caseTasks) {
        Contact taskContact = null;
        String tempName = null;

        if (t.WhoId != null) {
          taskContact = ContactDAO.getInstance().getContactById(t.WhoId);
          tempName = (taskContact != null) ? t.Type + ' - ' + taskContact.Name : t.Type;
        } else {
          tempName = t.Type;
        }

        taskDtos.add(new TaskDTO(t.Id, tempName));
      }
      ret.tasks = taskDtos;
    }

    return ret;
  }

  /**
   * Upsert case object.
   *
   * @param Case caseToUpsert The case.
   * @return Case - The upserted case.
   */
  public Case upsertCase(Case caseToUpsert) {
    Case upsertedCase = CaseDAO.getInstance().upsertCase(caseToUpsert);
    return upsertedCase;
  }

  /**
   * Save file as attachment
   *
   * @param String parentId The parent the attachment belongs to.
   * @param String fileName The name of the file.
   * @param String base64Data The file contents.
   * @param String contentType The file type.
   * @return String Id of the attachment.
   */
  public String saveFile(String parentId, String fileName, String base64Data, String contentType) {
    base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
    return AttachmentDAO.getInstance().createAttachment(parentId, fileName, base64Data, contentType);
  }

  /**
   * Append content to file
   *
   * @param String attachmentId The attachment id.
   * @param String base64Data The file contents.
   * @return void.
   */
  public void appendToFile(String attachmentId, String base64Data) {
    base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
    AttachmentDAO.getInstance().appendToFile(attachmentId, base64Data);
    return;
  }

  /**
   * Delete attachment
   *
   * @param String attachmentId The attachment id.
   * @return Map<String, Boolean>.
   */
  public Boolean deleteAttachment(String attachmentId) {
    Boolean result = false;

    try {
      AttachmentDAO.getInstance().deleteAttachment(attachmentId);
      result = true;
    } catch (Exception e) {
      throw e;
    }

    return result;
  }

  /**
   * Get a Case with related Feature_Request_Canceled data.
   *
   * @param caseId The case Id.
   *
   * @return A Case with Feature_Requested_Cancelled__r data.
   */
  public Case getCaseWithFeatureRequestCancelled(Id caseId) {
    return CaseDAO.getInstance().getWithFeatureRequestCancelled(caseId);
  }

}