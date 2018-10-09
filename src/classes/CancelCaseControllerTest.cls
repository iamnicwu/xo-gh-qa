@IsTest
private class CancelCaseControllerTest {
  @IsTest
  static void testGetAllPicklistOptionsSuccess() {
    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceSuccessMock()));

    Test.startTest();
    Map<String, List<PicklistValueDTO>> options = CancelCaseController.getAllPicklistOptions();
    Test.stopTest();

    System.assert(options != null, 'Should have returned options');
    System.assertEquals(2, options.get('originOptions').size(), 'Should have 2 options.');
    System.assertEquals('test1', options.get('originOptions').get(0).label, 'Item 1 should be test1.');
    System.assertEquals('test2', options.get('originOptions').get(1).label, 'Item 2 should be test2.');

    System.assertEquals(2, options.get('typeOptions').size(), 'Should have 2 options.');
    System.assertEquals('type1', options.get('typeOptions').get(0).label, 'Item 1 should be test1.');
    System.assertEquals('type2', options.get('typeOptions').get(1).label, 'Item 2 should be test2.');

    System.assertEquals(2, options.get('reasonOptions').size(), 'Should have 2 options.');
    System.assertEquals('reason1', options.get('reasonOptions').get(0).label, 'Item 1 should be test1.');
    System.assertEquals('reason2', options.get('reasonOptions').get(1).label, 'Item 2 should be test2.');

    System.assertEquals(2, options.get('outcomeOptions').size(), 'Should have 2 options.');
    System.assertEquals('outcome1', options.get('outcomeOptions').get(0).label, 'Item 1 should be test1.');
    System.assertEquals('outcome2', options.get('outcomeOptions').get(1).label, 'Item 2 should be test2.');

    System.assertEquals(2, options.get('savedByOptions').size(), 'Should have 2 options.');
    System.assertEquals('saved1', options.get('savedByOptions').get(0).label, 'Item 1 should be test1.');
    System.assertEquals('saved2', options.get('savedByOptions').get(1).label, 'Item 2 should be test2.');
  }

  @IsTest
  static void testGetCaseForAccountSuccess() {
    String accountId = 'accountId';

    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceSuccessMock()));

    Test.startTest();
    CaseDTO caseDto = CancelCaseController.getCaseForAccount(accountId);
    Test.stopTest();

    System.assert(caseDto != null, 'Should have returned a case dto.');
    System.assertEquals('accountName', caseDto.accountName, 'Should have correct account name');
    System.assertEquals('caseOwnerName', caseDto.caseOwnerName, 'Should have correct caseOwnerName');
    System.assertEquals('caseOwnerId', caseDto.caseOwnerId, 'Should have correct caseOwnerId');
    System.assertEquals('contactId', caseDto.contactId, 'Should have correct contactId');
    System.assertEquals('contactName', caseDto.contactName, 'Should have correct contactName');
  }

  @IsTest
  static void testGetCaseForAccountException() {
    String accountId = 'accountId';
    String errorMessage;

    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceExceptionMock()));

    Test.startTest();
    try {
      CaseDTO caseDto = CancelCaseController.getCaseForAccount(accountId);
    } catch (AuraHandledException ahe) {
      errorMessage = ahe.getMessage();
    }
    Test.stopTest();

    System.assertEquals('Record Type 1 - Cancel not found.', errorMessage, 'Should have thrown exception');
  }

  @IsTest
  static void testSaveCaseSuccess() {
    List<User> u = [SELECT Id FROM User LIMIT 1];

    Account acc = new Account();
    acc.Name = 'Account Temp';
    insert acc;

    Contact cont = new Contact();
    cont.FirstName = 'Test';
    cont.LastName = 'Contact';
    cont.AccountId = acc.Id;
    insert cont;

    Map<String, Object> input = new Map<String, Object> {
        'caseOwnerId' => u.get(0).Id,
        'caseOwnerName' => 'somebody',
        'contactId' => cont.Id,
        'accountId' => acc.Id
    };

    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceSuccessMock()));

    Test.startTest();
    Map<String, Boolean> result = CancelCaseController.saveCase(input, false);
    Test.stopTest();

    System.assert(result != null, 'Should have returned a result map.');
    System.assertEquals(true, result.get('saved'), 'Should have saved');
  }

  @IsTest
  static void testSaveCaseException() {
    List<User> u = [SELECT Id FROM User LIMIT 1];

    Account acc = new Account();
    acc.Name = 'Account Temp';
    insert acc;

    Contact cont = new Contact();
    cont.FirstName = 'Test';
    cont.LastName = 'Contact';
    cont.AccountId = acc.Id;
    insert cont;

    Map<String, Object> input = new Map<String, Object> {
        'caseOwnerId' => u.get(0).Id,
        'caseOwnerName' => 'somebody',
        'contactId' => cont.Id,
        'accountId' => acc.Id
    };

    String errorMessage;

    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceExceptionMock()));

    Test.startTest();
    try {
      Map<String, Boolean> result = CancelCaseController.saveCase(input, false);
    } catch (AuraHandledException ahe) {
      errorMessage = ahe.getMessage();
    }
    Test.stopTest();

    System.assertEquals('Ahhhhhhh.', errorMessage, 'Should have thrown exception');
  }

  @IsTest
  static void testSaveFileChunkCreateNewFile() {
    String parentId = 'parentId';
    String fileName = 'filename.pdf';
    String base64Data = 'the data';
    String contentType = 'content';
    String attachmentId = null;

    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceSuccessMock()));

    Test.startTest();
    String result = CancelCaseController.saveFileChunk(parentId, fileName, base64Data, contentType, attachmentId);
    Test.stopTest();

    System.assertEquals('newAttachmentId', result, 'Should return new attachment id');
  }

  @IsTest
  static void testSaveFileChunkAppendToFile() {
    String parentId = 'parentId';
    String fileName = 'filename.pdf';
    String base64Data = 'the data';
    String contentType = 'content';
    String attachmentId = 'existingFile';

    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceSuccessMock()));

    Test.startTest();
    String result = CancelCaseController.saveFileChunk(parentId, fileName, base64Data, contentType, attachmentId);
    Test.stopTest();

    System.assertEquals('existingFile', result, 'Should return existing attachment id');
  }

  @IsTest
  static void testSaveFileException() {
    String parentId = 'parentId';
    String fileName = 'filename.pdf';
    String base64Data = 'the data';
    String contentType = 'content';
    String attachmentId = 'existingFile';
    String errorMessage;

    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceExceptionMock()));

    Test.startTest();
    try {
      String result = CancelCaseController.saveFileChunk(parentId, fileName, base64Data, contentType, attachmentId);
    } catch (AuraHandledException ahe) {
      errorMessage = ahe.getMessage();
    }
    Test.stopTest();

    System.assertEquals('Ahhhhhhh.', errorMessage, 'Should have thrown exception');
  }

  @IsTest
  static void testRemoveAttachmentSuccess() {
    String attachmentId = 'attachment';

    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceSuccessMock()));

    Test.startTest();
    Map<String, Boolean> result = CancelCaseController.removeAttachment(attachmentId);
    Test.stopTest();

    System.assert(result != null, 'Should have returned a result map.');
    System.assertEquals(true, result.get('saved'), 'Should have saved');
  }

  @IsTest
  static void testRemoveAttachmentException() {
    String attachmentId = 'attachment';
    String errorMessage;

    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceExceptionMock()));

    Test.startTest();
    try {
      Map<String, Boolean> result = CancelCaseController.removeAttachment(attachmentId);
    } catch (AuraHandledException ahe) {
      errorMessage = ahe.getMessage();
    }
    Test.stopTest();

    System.assertEquals('Ahhhhhhh.', errorMessage, 'Should have thrown exception');
  }

  class CaseServiceSuccessMock extends CaseServiceMock {

    public override List<PicklistValueDTO> getOriginOptions() {
      return new List<PicklistValueDTO> {
          new PicklistValueDTO('test1', 'test1'),
          new PicklistValueDTO('test2', 'test2')
      };
    }

    public override List<PicklistValueDTO> getTypeOptions() {
      return new List<PicklistValueDTO> {
          new PicklistValueDTO('type1', 'type1'),
          new PicklistValueDTO('type2', 'type2')
      };
    }

    public override List<PicklistValueDTO> getReasonOptions() {
      return new List<PicklistValueDTO> {
          new PicklistValueDTO('reason1', 'reason1'),
          new PicklistValueDTO('reason2', 'reason2')
      };
    }

    public override List<PicklistValueDTO> getOutcomeOptions() {
      return new List<PicklistValueDTO> {
          new PicklistValueDTO('outcome1', 'outcome1'),
          new PicklistValueDTO('outcome2', 'outcome2')
      };
    }

    public override List<PicklistValueDTO> getSavedByOptions() {
      return new List<PicklistValueDTO> {
          new PicklistValueDTO('saved1', 'saved1'),
          new PicklistValueDTO('saved2', 'saved2')
      };
    }

    public override String getCancelRecordTypeId() {
      List<RecordType> recordTypes = [SELECT Id FROM RecordType LIMIT 1];
      return (recordTypes.size() == 1) ? recordTypes.get(0).Id : null;
    }

    public override CaseDTO getOrCreateCaseForAccount(String accountId) {
      String accountName = 'accountName';
      String caseOwnerId = 'caseOwnerId';
      String caseOwnerName =  'caseOwnerName';
      String contactId = 'contactId';
      String contactName = 'contactName';
      Datetime requestDate = Datetime.now();

      CaseDTO ret = new CaseDTO(caseOwnerId, caseOwnerName, contactId, contactName, accountId, accountName, requestDate);
      return ret;
    }

    public override Case upsertCase(Case caseValues) {
      return caseValues;
    }

    public override String saveFile(String parentId, String fileName, String base64Data, String contentType) {
      return 'newAttachmentId';
    }

    public override void appendToFile(String attachmentId, String base64Data) {
      return;
    }

    public override Boolean deleteAttachment(String attachmentId) {
      return true;
    }
  }

  class CaseServiceExceptionMock extends CaseServiceMock {
    public override String getCancelRecordTypeId() {
      List<RecordType> recordTypes = [SELECT Id FROM RecordType LIMIT 1];
      return (recordTypes.size() == 1) ? recordTypes.get(0).Id : null;
    }

    public override CaseDTO getOrCreateCaseForAccount(String accountId) {
      throw new Exceptions.NotFoundException('Record Type 1 - Cancel not found.');
    }

    public override Case upsertCase(Case caseValues) {
      throw new Exceptions.ServiceException('Ahhhhhhh.');
    }

    public override void appendToFile(String attachmentId, String base64Data) {
      throw new Exceptions.ServiceException('Ahhhhhhh.');
    }

    public override Boolean deleteAttachment(String attachmentId) {
      throw new Exceptions.ServiceException('Ahhhhhhh.');
    }
  }
}