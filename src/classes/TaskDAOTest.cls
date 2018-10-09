@IsTest
private class TaskDAOTest {
  @IsTest
  static void testGetTaskForCase() {
    Account acc = new Account();
    acc.Name = 'Temp Account';
    insert acc;

    Contact cont = new Contact();
    cont.FirstName = 'Test';
    cont.LastName = 'Contact';
    cont.AccountId = acc.Id;
    insert cont;

    Case c = new Case();
    c.Origin = 'Web';
    c.ContactId = cont.Id;
    insert c;

    Task tsk = new Task();
    tsk.Type = 'Call';
    tsk.WhoId = cont.Id;
    tsk.WhatId = c.Id;
    insert tsk;

    Test.startTest();
    List<Task> retTask = TaskDAO.getInstance().getTaskForCase(c.Id);
    Test.stopTest();

    System.assertEquals(1, retTask.size(), 'Should return task.');
    System.assertEquals('Call', retTask.get(0).Type, 'Should have correct type.');
    System.assertEquals(cont.Id, retTask.get(0).WhoId, 'Should have correct who id.');
  }

  @IsTest
  static void testAddCaseToTask() {
    Account acc = new Account();
    acc.Name = 'Temp Account';
    insert acc;

    Contact cont = new Contact();
    cont.FirstName = 'Test';
    cont.LastName = 'Contact';
    cont.AccountId = acc.Id;
    insert cont;

    Case c = new Case();
    c.Origin = 'Web';
    c.ContactId = cont.Id;
    insert c;

    Task tsk = new Task();
    tsk.Type = 'Call';
    tsk.WhoId = cont.Id;
    insert tsk;

    Test.startTest();
    Boolean added = TaskDAO.getInstance().addCaseToTask(c.Id, tsk.Id);
    List<Task> tasks = [SELECT WhatId FROM Task WHERE Id = :tsk.Id];
    Test.stopTest();

    System.assertEquals(true, added, 'Should have returned true.');
    System.assertEquals(1, tasks.size(), 'Should have task.');
    System.assertEquals(c.Id, tasks.get(0).WhatId, 'Should have case on task');
  }

  @IsTest
  static void testAddCaseToTaskNoUpdate() {
    Account acc = new Account();
    acc.Name = 'Temp Account';
    insert acc;

    Contact cont = new Contact();
    cont.FirstName = 'Test';
    cont.LastName = 'Contact';
    cont.AccountId = acc.Id;
    insert cont;

    Case c = new Case();
    c.Origin = 'Web';
    c.ContactId = cont.Id;
    insert c;

    Test.startTest();
    Boolean added = TaskDAO.getInstance().addCaseToTask(c.Id, cont.Id);
    Test.stopTest();

    System.assertEquals(false, added, 'Should have returned false.');
  }

  @IsTest
  static void testSearchTasks() {
    Account acc = new Account();
    acc.Name = 'Temp Account';
    insert acc;

    Task tsk = new Task();
    tsk.Type = 'Call';
    tsk.WhatId = acc.Id;
    insert tsk;

    // This is needed to test the SOSL query
    List<Id> fixedSearchResults= new List<Id>();
    fixedSearchResults.add(tsk.Id);
    Test.setFixedSearchResults(fixedSearchResults);

    Test.startTest();
    List<Task> tasks = TaskDAO.getInstance().searchTasks('call', acc.Id);
    Test.stopTest();

    System.assertEquals(1, tasks.size(), 'Should return 1 item.');
    System.assertEquals('Call', tasks.get(0).Type, 'Should have correct name.');
  }

  @IsTest
  static void testSearchTasksNoResults() {
    Account acc = new Account();
    acc.Name = 'Temp Account';
    insert acc;

    Test.startTest();
    List<Task> tasks = TaskDAO.getInstance().searchTasks('call', acc.Id);
    Test.stopTest();

    System.assertEquals(0, tasks.size(), 'Should return 0 items.');
  }

  @IsTest
  static void testGetTasksForAccount() {
    Account acc = new Account();
    acc.Name = 'Temp Account';
    insert acc;

    Task tsk = new Task();
    tsk.Type = 'Call';
    tsk.WhatId = acc.Id;
    insert tsk;

    Test.startTest();
    List<Task> tasks = TaskDAO.getInstance().getTasksForAccount(acc.Id);
    Test.stopTest();

    System.assertEquals(1, tasks.size(), 'Should return 1 item.');
    System.assertEquals('Call', tasks.get(0).Type, 'Should have correct name.');
  }
}