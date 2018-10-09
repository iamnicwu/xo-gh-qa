public abstract with sharing class CaseServiceMock extends AbstractMock {

  protected override Object callMockedMethod(String stubbedMethodName, List<Object> listOfArgs) {

    if (stubbedMethodName == 'getOriginOptions') {
      System.assertEquals(0, listOfArgs.size());
      return getOriginOptions();
    } else if (stubbedMethodName == 'getTypeOptions') {
      System.assertEquals(0, listOfArgs.size());
      return getTypeOptions();
    } else if (stubbedMethodName == 'getReasonOptions') {
      System.assertEquals(0, listOfArgs.size());
      return getReasonOptions();
    } else if (stubbedMethodName == 'getOutcomeOptions') {
      System.assertEquals(0, listOfArgs.size());
      return getOutcomeOptions();
    } else if (stubbedMethodName == 'getSavedByOptions') {
      System.assertEquals(0, listOfArgs.size());
      return getSavedByOptions();
    } else if (stubbedMethodName == 'getCancelRecordTypeId') {
      System.assertEquals(0, listOfArgs.size());
      return getCancelRecordTypeId();
    } else if (stubbedMethodName == 'getOrCreateCaseForAccount') {
      System.assertEquals(1, listOfArgs.size());
      return getOrCreateCaseForAccount((String)listOfArgs[0]);
    } else if (stubbedMethodName == 'searchAccounts') {
      System.assertEquals(1, listOfArgs.size());
      return searchAccounts((String)listOfArgs[0]);
    } else if (stubbedMethodName == 'searchContacts') {
      System.assertEquals(2, listOfArgs.size());
      return searchContacts((String)listOfArgs[0], (String)listOfArgs[1]);
    } else if (stubbedMethodName == 'searchTasks') {
      System.assertEquals(2, listOfArgs.size());
      return searchTasks((String)listOfArgs[0], (String)listOfArgs[1]);
    } else if (stubbedMethodName == 'searchUsers') {
      System.assertEquals(1, listOfArgs.size());
      return searchUsers((String)listOfArgs[0]);
    } else if (stubbedMethodName == 'upsertCase') {
      System.assertEquals(1, listOfArgs.size());
      return upsertCase((Case)listOfArgs[0]);
    } else if (stubbedMethodName == 'saveFile') {
      System.assertEquals(4, listOfArgs.size());
      return saveFile((String)listOfArgs[0], (String)listOfArgs[1], (String)listOfArgs[2], (String)listOfArgs[3]);
    } else if (stubbedMethodName == 'appendToFile') {
      System.assertEquals(2, listOfArgs.size());
      appendToFile((String)listOfArgs[0], (String)listOfArgs[1]);
      return null;
    } else if (stubbedMethodName == 'deleteAttachment') {
      System.assertEquals(1, listOfArgs.size());
      return deleteAttachment((String)listOfArgs[0]);
    } else if (stubbedMethodName == 'getAccountsById') {
      System.assertEquals(1, listOfArgs.size());
      return getAccountsById((String)listOfArgs[0]);
    } else if (stubbedMethodName == 'getContactsForAccount') {
      System.assertEquals(1, listOfArgs.size());
      return getContactsForAccount((String)listOfArgs[0]);
    } else if (stubbedMethodName == 'getTasksForAccount') {
      System.assertEquals(1, listOfArgs.size());
      return getTasksForAccount((String)listOfArgs[0]);
    } else if (stubbedMethodName == 'getUsersOnAccount') {
      System.assertEquals(1, listOfArgs.size());
      return getUsersOnAccount((String)listOfArgs[0]);
    } else if (stubbedMethodName == 'getCaseWithFeatureRequestCancelled') {
      System.assertEquals(1, listOfArgs.size());
      return getCaseWithFeatureRequestCancelled((Id)listOfArgs[0]);
    }

    throw new Exceptions.MockException('Failed to find method for ' + stubbedMethodName);

  }

  public virtual List<PicklistValueDTO> getOriginOptions() {
    throw newUnsupportedMethodException('getOriginOptions');
  }

  public virtual List<PicklistValueDTO> getTypeOptions() {
    throw newUnsupportedMethodException('getTypeOptions');
  }

  public virtual List<PicklistValueDTO> getReasonOptions() {
    throw newUnsupportedMethodException('getReasonOptions');
  }

  public virtual List<PicklistValueDTO> getOutcomeOptions() {
    throw newUnsupportedMethodException('getOutcomeOptions');
  }

  public virtual List<PicklistValueDTO> getSavedByOptions() {
    throw newUnsupportedMethodException('getSavedByOptions');
  }

  public virtual String getCancelRecordTypeId() {
    throw newUnsupportedMethodException('getCancelRecordTypeId');
  }

  public virtual CaseDTO getOrCreateCaseForAccount(String accountId) {
    throw newUnsupportedMethodException('getOrCreateCaseForAccount');
  }

  public virtual List<SearchResultDTO> searchAccounts(String searchVal) {
    throw newUnsupportedMethodException('searchAccounts');
  }

  public virtual List<SearchResultDTO> searchContacts(String searchVal, String accountId) {
    throw newUnsupportedMethodException('searchContacts');
  }

  public virtual List<SearchResultDTO> searchTasks(String searchVal, String accountId) {
    throw newUnsupportedMethodException('searchTasks');
  }

  public virtual List<SearchResultDTO> searchUsers(String searchVal) {
    throw newUnsupportedMethodException('searchUsers');
  }

  public virtual Case upsertCase(Case caseValues) {
    throw newUnsupportedMethodException('upsertCase');
  }

  public virtual String saveFile(String parentId, String fileName, String base64Data, String contentType) {
    throw newUnsupportedMethodException('saveFile');
  }

  public virtual void appendToFile(String attachmentId, String base64Data) {
    throw newUnsupportedMethodException('appendToFile');
  }

  public virtual Boolean deleteAttachment(String attachmentId) {
    throw newUnsupportedMethodException('deleteAttachment');
  }

  public virtual List<SearchResultDTO> getAccountsById(String accountId) {
    throw newUnsupportedMethodException('getAccountsById');
  }

  public virtual List<SearchResultDTO> getContactsForAccount(String accountId) {
    throw newUnsupportedMethodException('getContactsForAccount');
  }

  public virtual List<SearchResultDTO> getTasksForAccount(String accountId) {
    throw newUnsupportedMethodException('getTasksForAccount');
  }

  public virtual List<SearchResultDTO> getUsersOnAccount(String accountId) {
    throw newUnsupportedMethodException('getUsersOnAccount');
  }

  public virtual Case getCaseWithFeatureRequestCancelled(Id caseId) {
    throw newUnsupportedMethodException('getCaseWithFeatureRequestCancelled');
  }
}