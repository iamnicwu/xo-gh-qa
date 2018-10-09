@IsTest
private class CancelCaseModalControllerTest {
  @IsTest
  static void testInitialSearchAccountsSuccess() {
    String searchText = 'text';
    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceSuccessMock()));

    Test.startTest();
    List<SearchResultDTO> searchResults = CancelCaseModalController.initialSearchAccounts(searchText);
    Test.stopTest();

    System.assertEquals(2, searchResults.size(), 'Should have 2 results.');
    System.assertEquals('test1', searchResults.get(0).id, 'Item 1 should have id test1.');
    System.assertEquals('test1', searchResults.get(0).resultName, 'Item 1 should have name test1.');
    System.assertEquals('test2', searchResults.get(1).id, 'Item 2 should have id test2.');
    System.assertEquals('test2', searchResults.get(1).resultName, 'Item 2 should have Name test2.');
  }

  @IsTest
  static void testInitialSearchAccountsException() {
    String searchText = 'text';
    String errorMessage;
    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceExceptionMock()));

    Test.startTest();
    try {
      List<SearchResultDTO> searchResults = CancelCaseModalController.initialSearchAccounts(searchText);
    } catch (AuraHandledException ahe) {
      errorMessage = ahe.getMessage();
    }
    Test.stopTest();

    System.assertEquals('Ahhhhhhhh.', errorMessage, 'Should have thrown exception');
  }

  @IsTest
  static void testSearchAccountsSuccess() {
    String searchText = 'text';
    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceSuccessMock()));

    Test.startTest();
    List<SearchResultDTO> searchResults = CancelCaseModalController.searchAccounts(searchText);
    Test.stopTest();

    System.assertEquals(2, searchResults.size(), 'Should have 2 results.');
    System.assertEquals('test1', searchResults.get(0).id, 'Item 1 should have id test1.');
    System.assertEquals('test1', searchResults.get(0).resultName, 'Item 1 should have name test1.');
    System.assertEquals('test2', searchResults.get(1).id, 'Item 2 should have id test2.');
    System.assertEquals('test2', searchResults.get(1).resultName, 'Item 2 should have Name test2.');
  }

  @IsTest
  static void testSearchAccountsException() {
    String searchText = 'text';
    String errorMessage;
    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceExceptionMock()));

    Test.startTest();
    try {
      List<SearchResultDTO> searchResults = CancelCaseModalController.searchAccounts(searchText);
    } catch (AuraHandledException ahe) {
      errorMessage = ahe.getMessage();
    }
    Test.stopTest();

    System.assertEquals('Ahhhhhhhh.', errorMessage, 'Should have thrown exception');
  }

  @IsTest
  static void testInitialSearchContactsSuccess() {
    String accountId = 'accountId';
    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceSuccessMock()));

    Test.startTest();
    List<SearchResultDTO> searchResults = CancelCaseModalController.initialSearchContacts(accountId);
    Test.stopTest();

    System.assertEquals(2, searchResults.size(), 'Should have 2 results.');
    System.assertEquals('test1', searchResults.get(0).id, 'Item 1 should have id test1.');
    System.assertEquals('test1', searchResults.get(0).resultName, 'Item 1 should have name test1.');
    System.assertEquals('test2', searchResults.get(1).id, 'Item 2 should have id test2.');
    System.assertEquals('test2', searchResults.get(1).resultName, 'Item 2 should have Name test2.');
  }

  @IsTest
  static void testInitialSearchContactsException() {
    String accountId = 'accountId';
    String errorMessage;
    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceExceptionMock()));

    Test.startTest();
    try {
      List<SearchResultDTO> searchResults = CancelCaseModalController.initialSearchContacts(accountId);
    } catch (AuraHandledException ahe) {
      errorMessage = ahe.getMessage();
    }
    Test.stopTest();

    System.assertEquals('Ahhhhhhhh.', errorMessage, 'Should have thrown exception');
  }

  @IsTest
  static void testSearchContactsSuccess() {
    String searchText = 'text';
    String accountId = 'accountId';
    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceSuccessMock()));

    Test.startTest();
    List<SearchResultDTO> searchResults = CancelCaseModalController.searchContacts(searchText, accountId);
    Test.stopTest();

    System.assertEquals(2, searchResults.size(), 'Should have 2 results.');
    System.assertEquals('test1', searchResults.get(0).id, 'Item 1 should have id test1.');
    System.assertEquals('test1', searchResults.get(0).resultName, 'Item 1 should have name test1.');
    System.assertEquals('test2', searchResults.get(1).id, 'Item 2 should have id test2.');
    System.assertEquals('test2', searchResults.get(1).resultName, 'Item 2 should have Name test2.');
  }

  @IsTest
  static void testSearchContactsException() {
    String searchText = 'text';
    String accountId = 'accountId';
    String errorMessage;
    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceExceptionMock()));

    Test.startTest();
    try {
      List<SearchResultDTO> searchResults = CancelCaseModalController.searchContacts(searchText, accountId);
    } catch (AuraHandledException ahe) {
      errorMessage = ahe.getMessage();
    }
    Test.stopTest();

    System.assertEquals('Ahhhhhhhh.', errorMessage, 'Should have thrown exception');
  }

  @IsTest
  static void testInitialSearchUsersSuccess() {
    String searchText = 'text';
    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceSuccessMock()));

    Test.startTest();
    List<SearchResultDTO> searchResults = CancelCaseModalController.initialSearchUsers(searchText);
    Test.stopTest();

    System.assertEquals(2, searchResults.size(), 'Should have 2 results.');
    System.assertEquals('test1', searchResults.get(0).id, 'Item 1 should have id test1.');
    System.assertEquals('test1', searchResults.get(0).resultName, 'Item 1 should have name test1.');
    System.assertEquals('test2', searchResults.get(1).id, 'Item 2 should have id test2.');
    System.assertEquals('test2', searchResults.get(1).resultName, 'Item 2 should have Name test2.');
  }

  @IsTest
  static void testInitialSearchUsersException() {
    String searchText = 'text';
    String errorMessage;
    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceExceptionMock()));

    Test.startTest();
    try {
      List<SearchResultDTO> searchResults = CancelCaseModalController.initialSearchUsers(searchText);
    } catch (AuraHandledException ahe) {
      errorMessage = ahe.getMessage();
    }
    Test.stopTest();

    System.assertEquals('Ahhhhhhhh.', errorMessage, 'Should have thrown exception');
  }

  @IsTest
  static void testSearchUsersSuccess() {
    String searchText = 'text';
    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceSuccessMock()));

    Test.startTest();
    List<SearchResultDTO> searchResults = CancelCaseModalController.searchUsers(searchText);
    Test.stopTest();

    System.assertEquals(2, searchResults.size(), 'Should have 2 results.');
    System.assertEquals('test1', searchResults.get(0).id, 'Item 1 should have id test1.');
    System.assertEquals('test1', searchResults.get(0).resultName, 'Item 1 should have name test1.');
    System.assertEquals('test2', searchResults.get(1).id, 'Item 2 should have id test2.');
    System.assertEquals('test2', searchResults.get(1).resultName, 'Item 2 should have Name test2.');
  }

  @IsTest
  static void testSearchUsersException() {
    String searchText = 'text';
    String errorMessage;
    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceExceptionMock()));

    Test.startTest();
    try {
      List<SearchResultDTO> searchResults = CancelCaseModalController.searchUsers(searchText);
    } catch (AuraHandledException ahe) {
      errorMessage = ahe.getMessage();
    }
    Test.stopTest();

    System.assertEquals('Ahhhhhhhh.', errorMessage, 'Should have thrown exception');
  }

  @IsTest
  static void testInitialSearchTaskssSuccess() {
    String accountId = 'accountId';
    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceSuccessMock()));

    Test.startTest();
    List<SearchResultDTO> searchResults = CancelCaseModalController.initialSearchTasks(accountId);
    Test.stopTest();

    System.assertEquals(2, searchResults.size(), 'Should have 2 results.');
    System.assertEquals('task1', searchResults.get(0).id, 'Item 1 should have id test1.');
    System.assertEquals('task1', searchResults.get(0).resultName, 'Item 1 should have name test1.');
    System.assertEquals('task2', searchResults.get(1).id, 'Item 2 should have id test2.');
    System.assertEquals('task2', searchResults.get(1).resultName, 'Item 2 should have Name test2.');
  }

  @IsTest
  static void testInitialSearchTasksException() {
    String accountId = 'accountId';
    String errorMessage;
    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceExceptionMock()));

    Test.startTest();
    try {
      List<SearchResultDTO> searchResults = CancelCaseModalController.initialSearchTasks(accountId);
    } catch (AuraHandledException ahe) {
      errorMessage = ahe.getMessage();
    }
    Test.stopTest();

    System.assertEquals('Ahhhhhhhh.', errorMessage, 'Should have thrown exception');
  }

  @IsTest
  static void testSearchTasksSuccess() {
    String searchText = 'text';
    String accountId = 'accountId';
    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceSuccessMock()));

    Test.startTest();
    List<SearchResultDTO> searchResults = CancelCaseModalController.searchTasks(searchText, accountId);
    Test.stopTest();

    System.assertEquals(2, searchResults.size(), 'Should have 2 results.');
    System.assertEquals('task1', searchResults.get(0).id, 'Item 1 should have id test1.');
    System.assertEquals('task1', searchResults.get(0).resultName, 'Item 1 should have name test1.');
    System.assertEquals('task2', searchResults.get(1).id, 'Item 2 should have id test2.');
    System.assertEquals('task2', searchResults.get(1).resultName, 'Item 2 should have Name test2.');
  }

  @IsTest
  static void testSearchTasksException() {
    String searchText = 'text';
    String accountId = 'accountId';
    String errorMessage;
    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceExceptionMock()));

    Test.startTest();
    try {
      List<SearchResultDTO> searchResults = CancelCaseModalController.searchTasks(searchText, accountId);
    } catch (AuraHandledException ahe) {
      errorMessage = ahe.getMessage();
    }
    Test.stopTest();

    System.assertEquals('Ahhhhhhhh.', errorMessage, 'Should have thrown exception');
  }


  class CaseServiceSuccessMock extends CaseServiceMock {
    public override List<SearchResultDTO> getAccountsById(String searchText) {
      return new List<SearchResultDTO> {
          new SearchResultDTO('test1', 'test1'),
          new SearchResultDTO('test2', 'test2')
      };
    }

    public override List<SearchResultDTO> searchAccounts(String searchText) {
      return new List<SearchResultDTO> {
          new SearchResultDTO('test1', 'test1'),
          new SearchResultDTO('test2', 'test2')
      };
    }

    public override List<SearchResultDTO> getContactsForAccount(String searchText) {
      return new List<SearchResultDTO> {
          new SearchResultDTO('test1', 'test1'),
          new SearchResultDTO('test2', 'test2')
      };
    }

    public override List<SearchResultDTO> searchContacts(String searchText, String accountId) {
      return new List<SearchResultDTO> {
          new SearchResultDTO('test1', 'test1'),
          new SearchResultDTO('test2', 'test2')
      };
    }

    public override List<SearchResultDTO> getTasksForAccount(String searchText) {
      return new List<SearchResultDTO> {
          new SearchResultDTO('task1', 'task1'),
          new SearchResultDTO('task2', 'task2')
      };
    }

    public override List<SearchResultDTO> searchTasks(String searchText, String accountId) {
      return new List<SearchResultDTO> {
          new SearchResultDTO('task1', 'task1'),
          new SearchResultDTO('task2', 'task2')
      };
    }

    public override List<SearchResultDTO> getUsersOnAccount(String searchText) {
      return new List<SearchResultDTO> {
          new SearchResultDTO('test1', 'test1'),
          new SearchResultDTO('test2', 'test2')
      };
    }

    public override List<SearchResultDTO> searchUsers(String searchText) {
      return new List<SearchResultDTO> {
          new SearchResultDTO('test1', 'test1'),
          new SearchResultDTO('test2', 'test2')
      };
    }

  }

  class CaseServiceExceptionMock extends CaseServiceMock {
    public override List<SearchResultDTO> getAccountsById(String searchText) {
      throw new Exceptions.ServiceException('Ahhhhhhhh.');
    }

    public override List<SearchResultDTO> searchAccounts(String searchText) {
      throw new Exceptions.ServiceException('Ahhhhhhhh.');
    }

    public override List<SearchResultDTO> getContactsForAccount(String searchText) {
      throw new Exceptions.ServiceException('Ahhhhhhhh.');
    }

    public override List<SearchResultDTO> searchContacts(String searchText, String accountId) {
      throw new Exceptions.ServiceException('Ahhhhhhhh.');
    }

    public override List<SearchResultDTO> getTasksForAccount(String searchText) {
      throw new Exceptions.ServiceException('Ahhhhhhhh.');
    }

    public override List<SearchResultDTO> searchTasks(String searchText, String accountId) {
      throw new Exceptions.ServiceException('Ahhhhhhhh.');
    }

    public override List<SearchResultDTO> getUsersOnAccount(String searchText) {
      throw new Exceptions.ServiceException('Ahhhhhhhh.');
    }

    public override List<SearchResultDTO> searchUsers(String searchText) {
      throw new Exceptions.ServiceException('Ahhhhhhhh.');
    }
  }
}