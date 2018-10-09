/**
 * Task object data access object
 */
public with sharing class TaskDAO {
  private static TaskDAO instance;

  @TestVisible
  private static void setMock(TaskDAO mock) {
    if (instance != null) {
      throw new Exceptions.ServiceException('The dao was already mocked or accessed.');
    }
    instance = mock;
  }

  public static TaskDAO getInstance() {
    if (instance == null) {
      instance = new TaskDAO();
    }
    return instance;
  }

  /*
   * Method to task for case
   *
   * @param String caseId The case id.
   * @return List<Task>.
   */
  public List<Task> getTaskForCase(String caseId) {
    List<Task> tasks = [
        SELECT Id,
            Type,
            WhoId
        FROM Task
        WHERE WhatId = :caseId
    ];

    return tasks;
  }

  /**
   * Add case to a task
   *
   * @param String caseId The case id to add.
   * @param String taskId The task id to add to.
   * @return void.
   */
  public Boolean addCaseToTask(String caseId, String taskId) {
    Boolean ret = false;

    List<Task> tasks = [
        SELECT
            Id,
            WhatId
        FROM Task
        WHERE Id = :taskId
        LIMIT 1
    ];
    Task t = tasks.size() == 1 ? tasks.get(0) : null;

    if (t != null) {
      t.WhatId = caseId;
      update t;
      ret = true;
    }

    return ret;
  }

  /*
   * Method to search list of Tasks by search string
   *
   * @param String searchText The search text.
   * @param String accountId Search for tasks on this account it.
   * @return List<Task> The list of Tasks.
   */
  public List<Task> searchTasks(String searchText, String accountId) {
    List<List<SObject>> results = [FIND:searchText
      IN ALL FIELDS RETURNING Task(Id, WhoId, Subject, Type WHERE AccountId = :accountId ORDER BY LastModifiedDate DESC)];
    List<Task> tasks = results.size() == 1 ? results.get(0) : null;
    return tasks;
  }

  /*
   * Method to get all tasks for account
   *
   * @param String accountId Search for tasks on this account it.
   * @return List<Task> The list of Tasks.
   */
  public List<Task> getTasksForAccount(String accountId) {
    List<Task> tasks = [SELECT Id, WhoId, Subject, Type
      FROM Task
      WHERE AccountId = :accountId
      ORDER BY LastModifiedDate DESC
    ];
    return tasks;
  }
}