@IsTest
private class CaseServiceTest {
  @IsTest
  static void testGetOriginOptionsSuccess() {
    Test.startTest();
    List<PicklistValueDTO> originOpts = CaseService.getInstance().getOriginOptions();
    Test.stopTest();

    System.assert(originOpts.size() > 0, 'Should have options.');
  }

  @IsTest
  static void testGetTypeOptionsSuccess() {
    Test.startTest();
    List<PicklistValueDTO> typeOpts = CaseService.getInstance().getTypeOptions();
    Test.stopTest();

    System.assert(typeOpts.size() > 0, 'Should have options.');
  }

  @IsTest
  static void testGetReasonOptionsSuccess() {
    Test.startTest();
    List<PicklistValueDTO> reasonOpts = CaseService.getInstance().getReasonOptions();
    Test.stopTest();

    System.assert(reasonOpts.size() > 0, 'Should have options.');
  }

  @IsTest
  static void testGetOutcomeOptionsSuccess() {
    Test.startTest();
    List<PicklistValueDTO> outcomeOpts = CaseService.getInstance().getOutcomeOptions();
    Test.stopTest();

    System.assert(outcomeOpts.size() > 0, 'Should have options.');
  }

  @IsTest
  static void testGetSavedByOptionsSuccess() {
    Test.startTest();
    List<PicklistValueDTO> savedbyOpts = CaseService.getInstance().getSavedByOptions();
    Test.stopTest();

    System.assert(savedbyOpts.size() > 0, 'Should have options.');
  }

  @IsTest
  static void testGetCancelRecordTypeIdSuccess() {
    AccountDAOSuccessMock accountMock = new AccountDAOSuccessMock();
    ContactDAOSuccessMock contactMock = new ContactDAOSuccessMock(accountMock.getAccount());
    CaseDAOSuccessMock caseMock = new CaseDAOSuccessMock(accountMock.getAccount(), contactMock.getContact());
    AttachmentDAOSuccessMock attachmentMock = new AttachmentDAOSuccessMock(caseMock.getCase());
    TaskDAOSuccessMock taskMock = new TaskDAOSuccessMock(contactMock.getContact());
    UserDAOSuccessMock userMock = new UserDAOSuccessMock();

    AccountDAO.setMock((AccountDAO) Test.createStub(AccountDAO.class, accountMock));
    ContactDAO.setMock((ContactDAO) Test.createStub(ContactDAO.class, contactMock));
    CaseDAO.setMock((CaseDAO) Test.createStub(CaseDAO.class, caseMock));
    AttachmentDAO.setMock((AttachmentDAO) Test.createStub(AttachmentDAO.class, attachmentMock));
    TaskDAO.setMock((TaskDAO) Test.createStub(TaskDAO.class, taskMock));
    UserDAO.setMock((UserDAO) Test.createStub(UserDAO.class, userMock));

    Test.startTest();
    String recordTypeId = CaseService.getInstance().getCancelRecordTypeId();
    Test.stopTest();

    System.assertEquals(caseMock.getCancelRecordTypeId(), recordTypeId, 'Should have correct id.');
  }

  @IsTest
  static void testGetCancelRecordTypeIdNull() {
    RecordTypeDAOSuccessMock mock = new RecordTypeDAOSuccessMock();
    RecordTypeDAO.setMock((RecordTypeDAO) Test.createStub(RecordTypeDAO.class, mock));

    Test.startTest();
    String recordTypeId = CaseService.getInstance().getCancelRecordTypeId();
    Test.stopTest();

    System.assertEquals(null, recordTypeId, 'Should have null id.');
  }

  @IsTest
  static void testGetOrCreateCaseForAccountWhenCaseFoundSuccess() {
    AccountDAOSuccessMock accountMock = new AccountDAOSuccessMock();
    ContactDAOSuccessMock contactMock = new ContactDAOSuccessMock(accountMock.getAccount());
    CaseDAOSuccessMock caseMock = new CaseDAOSuccessMock(accountMock.getAccount(), contactMock.getContact());
    AttachmentDAOSuccessMock attachmentMock = new AttachmentDAOSuccessMock(caseMock.getCase());
    TaskDAOSuccessMock taskMock = new TaskDAOSuccessMock(contactMock.getContact());
    UserDAOSuccessMock userMock = new UserDAOSuccessMock();

    AccountDAO.setMock((AccountDAO) Test.createStub(AccountDAO.class, accountMock));
    ContactDAO.setMock((ContactDAO) Test.createStub(ContactDAO.class, contactMock));
    CaseDAO.setMock((CaseDAO) Test.createStub(CaseDAO.class, caseMock));
    AttachmentDAO.setMock((AttachmentDAO) Test.createStub(AttachmentDAO.class, attachmentMock));
    TaskDAO.setMock((TaskDAO) Test.createStub(TaskDAO.class, taskMock));
    UserDAO.setMock((UserDAO) Test.createStub(UserDAO.class, userMock));

    String accountId = accountMock.getAccount().Id;

    Test.startTest();
    CaseDTO dto = CaseService.getInstance().getOrCreateCaseForAccount(accountId);
    Test.stopTest();

    System.assert(dto != null, 'Should have returned dto.');
    System.assertEquals(caseMock.getCase().Id, dto.id, 'Should have correct id.');
    System.assertEquals(accountMock.getAccount().Id, dto.accountId, 'Should have Account id.');
    System.assertEquals(accountMock.getAccount().Name, dto.accountName, 'Should have Account name.');
    System.assertEquals(contactMock.getContact().Id, dto.contactId, 'Should have Account name.');
    System.assertEquals('Phone', dto.initialContact, 'Should have initialContact.');
    System.assertEquals(1, dto.attachments.size(), 'Should have attachment.');
    System.assertEquals(attachmentMock.getAttachment().Id, dto.attachments.get(0).id, 'Should have correct attachment id.');
    System.assertEquals(attachmentMock.getAttachment().Name, dto.attachments.get(0).attachmentName, 'Should have correct attachment name.');
    System.assertEquals(2, dto.tasks.size(), 'Should have task.');
    System.assertEquals(taskMock.getTasks().get(0).Id, dto.tasks.get(0).id, 'Should have correct task id.');
    System.assertEquals('Call', dto.tasks.get(0).taskName, 'Should have correct task name.');
  }

  @IsTest
  static void testGetOrCreateCaseForAccountWhenCaseNotFoundSuccess() {
    AccountDAOSuccessMock accountMock = new AccountDAOSuccessMock();
    ContactDAOSuccessMock contactMock = new ContactDAOSuccessMock(accountMock.getAccount());
    CaseDAONoCaseObjectMock caseMock = new CaseDAONoCaseObjectMock(accountMock.getAccount(), contactMock.getContact());
    AttachmentDAOSuccessMock attachmentMock = new AttachmentDAOSuccessMock(caseMock.getCase());
    TaskDAOSuccessMock taskMock = new TaskDAOSuccessMock(contactMock.getContact());
    UserDAOSuccessMock userMock = new UserDAOSuccessMock();

    AccountDAO.setMock((AccountDAO) Test.createStub(AccountDAO.class, accountMock));
    ContactDAO.setMock((ContactDAO) Test.createStub(ContactDAO.class, contactMock));
    CaseDAO.setMock((CaseDAO) Test.createStub(CaseDAO.class, caseMock));
    AttachmentDAO.setMock((AttachmentDAO) Test.createStub(AttachmentDAO.class, attachmentMock));
    TaskDAO.setMock((TaskDAO) Test.createStub(TaskDAO.class, taskMock));
    UserDAO.setMock((UserDAO) Test.createStub(UserDAO.class, userMock));

    String accountId = accountMock.getAccount().Id;

    Test.startTest();
    CaseDTO dto = CaseService.getInstance().getOrCreateCaseForAccount(accountId);
    Test.stopTest();

    System.assert(dto != null, 'Should have returned dto.');
    System.assert(dto.id == null, 'Should not have correct id.');
    System.assertEquals(accountMock.getAccount().Id, dto.accountId, 'Should have Account id.');
    System.assertEquals(accountMock.getAccount().Name, dto.accountName, 'Should have Account name.');
    System.assertEquals(contactMock.getContact().Id, dto.contactId, 'Should have Account name.');
    System.assert(dto.initialContact == null, 'Should not have initialContact.');
    System.assertEquals(0, dto.attachments.size(), 'Should not have attachments.');
    System.assertEquals(0, dto.tasks.size(), 'Should not have tasks.');
  }

  @IsTest
  static void testGetAccountsByIdSuccess() {
    AccountDAOSuccessMock accountMock = new AccountDAOSuccessMock();
    ContactDAOSuccessMock contactMock = new ContactDAOSuccessMock(accountMock.getAccount());
    CaseDAOSuccessMock caseMock = new CaseDAOSuccessMock(accountMock.getAccount(), contactMock.getContact());
    AttachmentDAOSuccessMock attachmentMock = new AttachmentDAOSuccessMock(caseMock.getCase());
    TaskDAOSuccessMock taskMock = new TaskDAOSuccessMock(contactMock.getContact());
    UserDAOSuccessMock userMock = new UserDAOSuccessMock();

    AccountDAO.setMock((AccountDAO) Test.createStub(AccountDAO.class, accountMock));
    ContactDAO.setMock((ContactDAO) Test.createStub(ContactDAO.class, contactMock));
    CaseDAO.setMock((CaseDAO) Test.createStub(CaseDAO.class, caseMock));
    AttachmentDAO.setMock((AttachmentDAO) Test.createStub(AttachmentDAO.class, attachmentMock));
    TaskDAO.setMock((TaskDAO) Test.createStub(TaskDAO.class, taskMock));
    UserDAO.setMock((UserDAO) Test.createStub(UserDAO.class, userMock));

    String accountId = accountMock.getAccount().Id;

    Test.startTest();
    List<SearchResultDTO> dtos = CaseService.getInstance().getAccountsById(accountId);
    Test.stopTest();

    System.assertEquals(1, dtos.size(), 'Should have 1 item.');
    System.assertEquals(accountMock.getAccount().Name, dtos.get(0).resultName, 'Should have Account name.');
  }

  @IsTest
  static void testSearchAccountsSuccess() {
    AccountDAOSuccessMock accountMock = new AccountDAOSuccessMock();
    ContactDAOSuccessMock contactMock = new ContactDAOSuccessMock(accountMock.getAccount());
    CaseDAOSuccessMock caseMock = new CaseDAOSuccessMock(accountMock.getAccount(), contactMock.getContact());
    AttachmentDAOSuccessMock attachmentMock = new AttachmentDAOSuccessMock(caseMock.getCase());
    TaskDAOSuccessMock taskMock = new TaskDAOSuccessMock(contactMock.getContact());
    UserDAOSuccessMock userMock = new UserDAOSuccessMock();

    AccountDAO.setMock((AccountDAO) Test.createStub(AccountDAO.class, accountMock));
    ContactDAO.setMock((ContactDAO) Test.createStub(ContactDAO.class, contactMock));
    CaseDAO.setMock((CaseDAO) Test.createStub(CaseDAO.class, caseMock));
    AttachmentDAO.setMock((AttachmentDAO) Test.createStub(AttachmentDAO.class, attachmentMock));
    TaskDAO.setMock((TaskDAO) Test.createStub(TaskDAO.class, taskMock));
    UserDAO.setMock((UserDAO) Test.createStub(UserDAO.class, userMock));

    String accountName = accountMock.getAccount().Name;

    Test.startTest();
    List<SearchResultDTO> dtos = CaseService.getInstance().searchAccounts(accountName);
    Test.stopTest();

    System.assertEquals(1, dtos.size(), 'Should have 1 item.');
    System.assertEquals(accountMock.getAccount().Name, dtos.get(0).resultName, 'Should have Account name.');
  }

  @IsTest
  static void testSearchContactsSuccess() {
    AccountDAOSuccessMock accountMock = new AccountDAOSuccessMock();
    ContactDAOSuccessMock contactMock = new ContactDAOSuccessMock(accountMock.getAccount());
    CaseDAOSuccessMock caseMock = new CaseDAOSuccessMock(accountMock.getAccount(), contactMock.getContact());
    AttachmentDAOSuccessMock attachmentMock = new AttachmentDAOSuccessMock(caseMock.getCase());
    TaskDAOSuccessMock taskMock = new TaskDAOSuccessMock(contactMock.getContact());
    UserDAOSuccessMock userMock = new UserDAOSuccessMock();

    AccountDAO.setMock((AccountDAO) Test.createStub(AccountDAO.class, accountMock));
    ContactDAO.setMock((ContactDAO) Test.createStub(ContactDAO.class, contactMock));
    CaseDAO.setMock((CaseDAO) Test.createStub(CaseDAO.class, caseMock));
    AttachmentDAO.setMock((AttachmentDAO) Test.createStub(AttachmentDAO.class, attachmentMock));
    TaskDAO.setMock((TaskDAO) Test.createStub(TaskDAO.class, taskMock));
    UserDAO.setMock((UserDAO) Test.createStub(UserDAO.class, userMock));

    String contactName = contactMock.getContact().Name;
    String accountId = 'accountid';

    Test.startTest();
    List<SearchResultDTO> dtos = CaseService.getInstance().searchContacts(contactName, accountId);
    Test.stopTest();

    System.assertEquals(1, dtos.size(), 'Should have 1 item.');
    System.assertEquals(contactMock.getContact().Name, dtos.get(0).resultName, 'Should have Contact name.');
  }

  @IsTest
  static void testGetContactsForAccountSuccess() {
    AccountDAOSuccessMock accountMock = new AccountDAOSuccessMock();
    ContactDAOSuccessMock contactMock = new ContactDAOSuccessMock(accountMock.getAccount());
    CaseDAOSuccessMock caseMock = new CaseDAOSuccessMock(accountMock.getAccount(), contactMock.getContact());
    AttachmentDAOSuccessMock attachmentMock = new AttachmentDAOSuccessMock(caseMock.getCase());
    TaskDAOSuccessMock taskMock = new TaskDAOSuccessMock(contactMock.getContact());
    UserDAOSuccessMock userMock = new UserDAOSuccessMock();

    AccountDAO.setMock((AccountDAO) Test.createStub(AccountDAO.class, accountMock));
    ContactDAO.setMock((ContactDAO) Test.createStub(ContactDAO.class, contactMock));
    CaseDAO.setMock((CaseDAO) Test.createStub(CaseDAO.class, caseMock));
    AttachmentDAO.setMock((AttachmentDAO) Test.createStub(AttachmentDAO.class, attachmentMock));
    TaskDAO.setMock((TaskDAO) Test.createStub(TaskDAO.class, taskMock));
    UserDAO.setMock((UserDAO) Test.createStub(UserDAO.class, userMock));

    String contactName = contactMock.getContact().Name;
    String accountId = 'accountid';

    Test.startTest();
    List<SearchResultDTO> dtos = CaseService.getInstance().getContactsForAccount(accountId);
    Test.stopTest();

    System.assertEquals(1, dtos.size(), 'Should have 1 item.');
    System.assertEquals(contactMock.getContact().Name, dtos.get(0).resultName, 'Should have Contact name.');
  }

  @IsTest
  static void testSearchTasksSuccess() {
    AccountDAOSuccessMock accountMock = new AccountDAOSuccessMock();
    ContactDAOSuccessMock contactMock = new ContactDAOSuccessMock(accountMock.getAccount());
    CaseDAOSuccessMock caseMock = new CaseDAOSuccessMock(accountMock.getAccount(), contactMock.getContact());
    AttachmentDAOSuccessMock attachmentMock = new AttachmentDAOSuccessMock(caseMock.getCase());
    TaskDAOSuccessMock taskMock = new TaskDAOSuccessMock(contactMock.getContact());
    UserDAOSuccessMock userMock = new UserDAOSuccessMock();

    AccountDAO.setMock((AccountDAO) Test.createStub(AccountDAO.class, accountMock));
    ContactDAO.setMock((ContactDAO) Test.createStub(ContactDAO.class, contactMock));
    CaseDAO.setMock((CaseDAO) Test.createStub(CaseDAO.class, caseMock));
    AttachmentDAO.setMock((AttachmentDAO) Test.createStub(AttachmentDAO.class, attachmentMock));
    TaskDAO.setMock((TaskDAO) Test.createStub(TaskDAO.class, taskMock));
    UserDAO.setMock((UserDAO) Test.createStub(UserDAO.class, userMock));

    String searchVal = 'call';
    String accountId = 'accountid';

    Test.startTest();
    List<SearchResultDTO> dtos = CaseService.getInstance().searchTasks(searchVal, accountId);
    Test.stopTest();

    System.assertEquals(2, dtos.size(), 'Should have 1 item.');
    System.assertEquals('Call', dtos.get(0).resultName, 'Should have correct name for item 1.');
    System.assertEquals('Call - Test Contact', dtos.get(1).resultName, 'Should have correct name for item 2 when contact present on task.');
  }

  @IsTest
  static void testGetTasksForAccountSuccess() {
    AccountDAOSuccessMock accountMock = new AccountDAOSuccessMock();
    ContactDAOSuccessMock contactMock = new ContactDAOSuccessMock(accountMock.getAccount());
    CaseDAOSuccessMock caseMock = new CaseDAOSuccessMock(accountMock.getAccount(), contactMock.getContact());
    AttachmentDAOSuccessMock attachmentMock = new AttachmentDAOSuccessMock(caseMock.getCase());
    TaskDAOSuccessMock taskMock = new TaskDAOSuccessMock(contactMock.getContact());
    UserDAOSuccessMock userMock = new UserDAOSuccessMock();

    AccountDAO.setMock((AccountDAO) Test.createStub(AccountDAO.class, accountMock));
    ContactDAO.setMock((ContactDAO) Test.createStub(ContactDAO.class, contactMock));
    CaseDAO.setMock((CaseDAO) Test.createStub(CaseDAO.class, caseMock));
    AttachmentDAO.setMock((AttachmentDAO) Test.createStub(AttachmentDAO.class, attachmentMock));
    TaskDAO.setMock((TaskDAO) Test.createStub(TaskDAO.class, taskMock));
    UserDAO.setMock((UserDAO) Test.createStub(UserDAO.class, userMock));

    String searchVal = 'call';
    String accountId = 'accountid';

    Test.startTest();
    List<SearchResultDTO> dtos = CaseService.getInstance().getTasksForAccount(accountId);
    Test.stopTest();

    System.assertEquals(2, dtos.size(), 'Should have 1 item.');
    System.assertEquals('Call', dtos.get(0).resultName, 'Should have correct name for item 1.');
    System.assertEquals('Call - Test Contact', dtos.get(1).resultName, 'Should have correct name for item 2 when contact present on task.');
  }

  @IsTest
  static void testSearchUsersSuccess() {
    AccountDAOSuccessMock accountMock = new AccountDAOSuccessMock();
    ContactDAOSuccessMock contactMock = new ContactDAOSuccessMock(accountMock.getAccount());
    CaseDAOSuccessMock caseMock = new CaseDAOSuccessMock(accountMock.getAccount(), contactMock.getContact());
    AttachmentDAOSuccessMock attachmentMock = new AttachmentDAOSuccessMock(caseMock.getCase());
    TaskDAOSuccessMock taskMock = new TaskDAOSuccessMock(contactMock.getContact());
    UserDAOSuccessMock userMock = new UserDAOSuccessMock();

    AccountDAO.setMock((AccountDAO) Test.createStub(AccountDAO.class, accountMock));
    ContactDAO.setMock((ContactDAO) Test.createStub(ContactDAO.class, contactMock));
    CaseDAO.setMock((CaseDAO) Test.createStub(CaseDAO.class, caseMock));
    AttachmentDAO.setMock((AttachmentDAO) Test.createStub(AttachmentDAO.class, attachmentMock));
    TaskDAO.setMock((TaskDAO) Test.createStub(TaskDAO.class, taskMock));
    UserDAO.setMock((UserDAO) Test.createStub(UserDAO.class, userMock));

    String userName = userMock.getUser().Name;

    Test.startTest();
    List<SearchResultDTO> dtos = CaseService.getInstance().searchUsers(userName);
    Test.stopTest();

    System.assertEquals(1, dtos.size(), 'Should have 1 item.');
    System.assertEquals(userMock.getUser().Name, dtos.get(0).resultName, 'Should have User name.');
  }

  @IsTest
  static void testGetUsersOnAccountSuccess() {
    AccountDAOSuccessMock accountMock = new AccountDAOSuccessMock();
    ContactDAOSuccessMock contactMock = new ContactDAOSuccessMock(accountMock.getAccount());
    CaseDAOSuccessMock caseMock = new CaseDAOSuccessMock(accountMock.getAccount(), contactMock.getContact());
    AttachmentDAOSuccessMock attachmentMock = new AttachmentDAOSuccessMock(caseMock.getCase());
    TaskDAOSuccessMock taskMock = new TaskDAOSuccessMock(contactMock.getContact());
    UserDAOSuccessMock userMock = new UserDAOSuccessMock();

    AccountDAO.setMock((AccountDAO) Test.createStub(AccountDAO.class, accountMock));
    ContactDAO.setMock((ContactDAO) Test.createStub(ContactDAO.class, contactMock));
    CaseDAO.setMock((CaseDAO) Test.createStub(CaseDAO.class, caseMock));
    AttachmentDAO.setMock((AttachmentDAO) Test.createStub(AttachmentDAO.class, attachmentMock));
    TaskDAO.setMock((TaskDAO) Test.createStub(TaskDAO.class, taskMock));
    UserDAO.setMock((UserDAO) Test.createStub(UserDAO.class, userMock));

    String accountId = 'accountid';

    Test.startTest();
    List<SearchResultDTO> dtos = CaseService.getInstance().getUsersOnAccount(accountId);
    Test.stopTest();

    System.assertEquals(1, dtos.size(), 'Should have 1 item.');
    System.assertEquals(userMock.getUser().Name, dtos.get(0).resultName, 'Should have User name.');
  }

  @IsTest
  static void testUpsertCaseSuccess() {
    AccountDAOSuccessMock accountMock = new AccountDAOSuccessMock();
    ContactDAOSuccessMock contactMock = new ContactDAOSuccessMock(accountMock.getAccount());
    CaseDAOSuccessMock caseMock = new CaseDAOSuccessMock(accountMock.getAccount(), contactMock.getContact());
    AttachmentDAOSuccessMock attachmentMock = new AttachmentDAOSuccessMock(caseMock.getCase());
    TaskDAOSuccessMock taskMock = new TaskDAOSuccessMock(contactMock.getContact());
    UserDAOSuccessMock userMock = new UserDAOSuccessMock();

    AccountDAO.setMock((AccountDAO) Test.createStub(AccountDAO.class, accountMock));
    ContactDAO.setMock((ContactDAO) Test.createStub(ContactDAO.class, contactMock));
    CaseDAO.setMock((CaseDAO) Test.createStub(CaseDAO.class, caseMock));
    AttachmentDAO.setMock((AttachmentDAO) Test.createStub(AttachmentDAO.class, attachmentMock));
    TaskDAO.setMock((TaskDAO) Test.createStub(TaskDAO.class, taskMock));
    UserDAO.setMock((UserDAO) Test.createStub(UserDAO.class, userMock));

    Case newCase = new Case();
    newCase.Origin = 'Web';

    Test.startTest();
    Case result = CaseService.getInstance().upsertCase(newCase);
    Test.stopTest();

    System.assert(result != null, 'Should have returned a case object');
    System.assertEquals('Web', result.Origin, 'Should have origin');
  }

  @IsTest
  static void testSaveFile() {
    String parentId = 'parentId';
    String fileName = 'filename.pdf';
    String base64Data = 'the data';
    String contentType = 'content';

    AccountDAOSuccessMock accountMock = new AccountDAOSuccessMock();
    ContactDAOSuccessMock contactMock = new ContactDAOSuccessMock(accountMock.getAccount());
    CaseDAOSuccessMock caseMock = new CaseDAOSuccessMock(accountMock.getAccount(), contactMock.getContact());
    AttachmentDAOSuccessMock attachmentMock = new AttachmentDAOSuccessMock(caseMock.getCase());
    TaskDAOSuccessMock taskMock = new TaskDAOSuccessMock(contactMock.getContact());
    UserDAOSuccessMock userMock = new UserDAOSuccessMock();

    AccountDAO.setMock((AccountDAO) Test.createStub(AccountDAO.class, accountMock));
    ContactDAO.setMock((ContactDAO) Test.createStub(ContactDAO.class, contactMock));
    CaseDAO.setMock((CaseDAO) Test.createStub(CaseDAO.class, caseMock));
    AttachmentDAO.setMock((AttachmentDAO) Test.createStub(AttachmentDAO.class, attachmentMock));
    TaskDAO.setMock((TaskDAO) Test.createStub(TaskDAO.class, taskMock));
    UserDAO.setMock((UserDAO) Test.createStub(UserDAO.class, userMock));

    Test.startTest();
    String result = CaseService.getInstance().saveFile(parentId, fileName, base64Data, contentType);
    Test.stopTest();

    System.assertEquals('newAttachmentId', result, 'Should return new attachment id');
  }

  @IsTest
  static void testAppendToFile() {
    String attachmentId = 'attachmentId';
    String base64Data = 'the data';

    AccountDAOSuccessMock accountMock = new AccountDAOSuccessMock();
    ContactDAOSuccessMock contactMock = new ContactDAOSuccessMock(accountMock.getAccount());
    CaseDAOSuccessMock caseMock = new CaseDAOSuccessMock(accountMock.getAccount(), contactMock.getContact());
    AttachmentDAOSuccessMock attachmentMock = new AttachmentDAOSuccessMock(caseMock.getCase());
    TaskDAOSuccessMock taskMock = new TaskDAOSuccessMock(contactMock.getContact());
    UserDAOSuccessMock userMock = new UserDAOSuccessMock();

    AccountDAO.setMock((AccountDAO) Test.createStub(AccountDAO.class, accountMock));
    ContactDAO.setMock((ContactDAO) Test.createStub(ContactDAO.class, contactMock));
    CaseDAO.setMock((CaseDAO) Test.createStub(CaseDAO.class, caseMock));
    AttachmentDAO.setMock((AttachmentDAO) Test.createStub(AttachmentDAO.class, attachmentMock));
    TaskDAO.setMock((TaskDAO) Test.createStub(TaskDAO.class, taskMock));
    UserDAO.setMock((UserDAO) Test.createStub(UserDAO.class, userMock));

    Test.startTest();
    CaseService.getInstance().appendToFile(attachmentId, base64Data);
    List<Object> listOfArgs = attachmentMock.getListOfArgs();
    Test.stopTest();

    System.assertEquals('attachmentId', (String) listOfArgs[0], 'Should have been called with correct attachment id');
    System.assertEquals('the data', (String) listOfArgs[1], 'Should have been called with correct data');
  }

  @IsTest
  static void testDeleteAttachmentSuccess() {
    AccountDAOSuccessMock accountMock = new AccountDAOSuccessMock();
    ContactDAOSuccessMock contactMock = new ContactDAOSuccessMock(accountMock.getAccount());
    CaseDAOSuccessMock caseMock = new CaseDAOSuccessMock(accountMock.getAccount(), contactMock.getContact());
    AttachmentDAOSuccessMock attachmentMock = new AttachmentDAOSuccessMock(caseMock.getCase());
    TaskDAOSuccessMock taskMock = new TaskDAOSuccessMock(contactMock.getContact());
    UserDAOSuccessMock userMock = new UserDAOSuccessMock();

    AccountDAO.setMock((AccountDAO) Test.createStub(AccountDAO.class, accountMock));
    ContactDAO.setMock((ContactDAO) Test.createStub(ContactDAO.class, contactMock));
    CaseDAO.setMock((CaseDAO) Test.createStub(CaseDAO.class, caseMock));
    AttachmentDAO.setMock((AttachmentDAO) Test.createStub(AttachmentDAO.class, attachmentMock));
    TaskDAO.setMock((TaskDAO) Test.createStub(TaskDAO.class, taskMock));
    UserDAO.setMock((UserDAO) Test.createStub(UserDAO.class, userMock));

    String attachmentId = 'attachment';

    Test.startTest();
    Boolean result = CaseService.getInstance().deleteAttachment(attachmentId);
    Test.stopTest();

    System.assertEquals(true, result, 'Should have saved');
  }

  @IsTest
  static void testGetCaseWithFeatureRequestCanceled() {
    Map<String, SObject> testObjects = TestClassUtility.buildLocalData(false);
    Account acc = (Account)testObjects.get('Account');
    Contact cont = (Contact)testObjects.get('Contact');
    CaseDAOSuccessMock caseMock = new CaseDAOSuccessMock(acc, cont);
    CaseDAO.setMock((CaseDAO) Test.createStub(CaseDAO.class, caseMock));

    Test.startTest();
    Case c = CaseService.getInstance().getCaseWithFeatureRequestCancelled(caseMock.getCase().Id);
    Test.stopTest();

    System.assertNotEquals(null, c, 'Should have returned the case.');
  }

  class CaseDAOSuccessMock extends CaseDAOMock {
    private List<RecordType> cancelRecordTypes;
    private Case cancelledCase;

    public CaseDAOSuccessMock(Account acc, Contact cont) {
      cancelRecordTypes = [SELECT
          Id
        FROM RecordType
        WHERE Name = '1 - Cancels'
      ];

      cancelledCase = new Case();
      cancelledCase.AccountId = acc.Id;
      cancelledCase.RecordTypeId = cancelRecordTypes.get(0).Id;
      cancelledCase.Origin = 'Phone';
      cancelledCase.ContactId = cont.Id;
      insert cancelledCase;
    }

    public String getCancelRecordTypeId() {
      return cancelRecordTypes.size() > 0 ? cancelRecordTypes.get(0).Id : null;
    }

    public Case getCase() {
      return cancelledCase;
    }

    public override Case getCaseByAccountAndRecordType(String accountId, String recordTypeId) {
      return cancelledCase;
    }

    public override Case upsertCase(Case c) {
      return c;
    }

    public override Case getWithFeatureRequestCancelled(Id caseId) {
      return cancelledCase;
    }
  }

  class AccountDAOSuccessMock extends AccountDAOMock {
    private Account acc;

    public AccountDAOSuccessMock() {
      acc = new Account();
      acc.Name = 'Account Temp';
      insert acc;
    }

    public Account getAccount() {
      return acc;
    }

    public override Account getAccountById(String accId) {
      return acc;
    }

    public override List<Account> searchAccounts(String searchString) {
      return new List<Account> { acc };
    }
  }

  class AttachmentDAOSuccessMock extends AttachmentDAOMock {
    private Attachment attch;

    public AttachmentDAOSuccessMock(Case cancelledCase) {
      // This is needed to get the test to pass since the Attachment trigger fires
      Deactivate_Trigger__c deactivateTrigger = new Deactivate_Trigger__c();
      deactivateTrigger.After_Delete__c = true;
      deactivateTrigger.After_Insert__c = true;
      deactivateTrigger.After_Update__c = true;
      deactivateTrigger.Before_Delete__c = true;
      deactivateTrigger.Before_Insert__c = true;
      deactivateTrigger.Before_Update__c = true;
      deactivateTrigger.Name = 'Attachment';
      insert deactivateTrigger;

      attch = new Attachment();
      attch.Name = 'test.txt';
      attch.Body = EncodingUtil.base64Decode('stuff');
      attch.ContentType = 'text/plain';
      attch.ParentId = cancelledCase.Id;
      insert attch;
    }

    public Attachment getAttachment() {
      return attch;
    }

    public override String createAttachment(String parentId, String fileName, String base64Data, String contentType) {
      return 'newAttachmentId';
    }

    public override void appendToFile(String attachmentId, String base64Data) {
      return;
    }

    public override void deleteAttachment(String attachmentId) {}

    public override List<Attachment> getAttachmentOnCase(String parentId) {
      return new List<Attachment> { attch };
    }
  }

  class ContactDAOSuccessMock extends ContactDAOMock {
    private Contact cont;

    public ContactDAOSuccessMock(Account acc) {
      cont = new Contact();
      cont.FirstName = 'Test';
      cont.LastName = 'Contact';
      cont.AccountId = acc.Id;
      insert cont;
    }

    public Contact getContact() {
      return cont;
    }

    public override Contact getContactById(String contactId) {
      List<Contact> contacts = [SELECT
          Id, Name, FirstName, LastName, AccountId
      FROM Contact
      WHERE Id = :cont.Id
      LIMIT 1
      ];
      return contacts.size() == 1 ? contacts.get(0) : null;
    }

    public override Contact getContactByAccountId(String accId) {
      return cont;
    }

    public override List<Contact> searchContacts(String searchString, String accountId) {
      return new List<Contact> { cont };
    }

    public override List<Contact> getContactsOnAccount(String accountId) {
      return new List<Contact> { cont };
    }
  }

  class TaskDAOSuccessMock extends TaskDAOMock {
    private List<Task> tasks;

    public TaskDAOSuccessMock(Contact cont) {
      tasks = new List<Task>();
      Task tsk = new Task();
      tsk.Type = 'Call';
      insert tsk;
      tasks.add(tsk);

      tsk = new Task();
      tsk.Type = 'Call';
      tsk.WhoId = cont.Id;
      insert tsk;
      tasks.add(tsk);
    }

    public List<Task> getTasks() {
      return tasks;
    }

    public override List<Task> searchTasks(String searchString, String accountId) {
      return tasks;
    }

    public override List<Task> getTaskForCase(String caseId) {
      return tasks;
    }

    public override List<Task> getTasksForAccount(String accountId) {
      return tasks;
    }
  }

  class UserDAOSuccessMock extends UserDAOMock {
    private List<User> usr;

    public UserDAOSuccessMock() {
      usr = [SELECT Id, Name FROM User LIMIT 1];
    }

    public User getUser() {
      return usr.get(0);
    }

    public override User getUserById(String userId) {
      User usr = new User();
      usr.FirstName = 'User';
      usr.LastName = 'Name';
      return usr;
    }

    public override List<User> searchUsers(String searchString) {
      return new List<User> { usr.get(0) };
    }

    public override List<User> getUsersOnAccount(String accountId) {
      return new List<User> { usr.get(0) };
    }
  }

  class CaseDAONoCaseObjectMock extends CaseDAOMock {
    private List<RecordType> cancelRecordTypes;
    private Case cancelledCase;

    public CaseDAONoCaseObjectMock(Account acc, Contact cont) {
      cancelRecordTypes = [SELECT
          Id
      FROM RecordType
      WHERE Name = '1 - Cancels'
      ];

      cancelledCase = new Case();
      cancelledCase.AccountId = acc.Id;
      cancelledCase.RecordTypeId = cancelRecordTypes.get(0).Id;
      cancelledCase.Origin = 'Phone';
      cancelledCase.ContactId = cont.Id;
      insert cancelledCase;
    }

    public String getCancelRecordTypeId() {
      return cancelRecordTypes.size() > 0 ? cancelRecordTypes.get(0).Id : null;
    }

    public Case getCase() {
      return cancelledCase;
    }

    public override Case getCaseByAccountAndRecordType(String accountId, String recordTypeId) {
      return null;
    }
  }

  class RecordTypeDAOSuccessMock extends RecordTypeDAOMock {

    public override RecordType getRecordTypeByName(String name) {
      return null;
    }
  }
}