public abstract with sharing class TaskDAOMock extends AbstractMock {
  private List<Object> listOfArgs;

  protected override Object callMockedMethod(String stubbedMethodName, List<Object> listOfArgs) {
    this.listOfArgs = listOfArgs;

    if (stubbedMethodName == 'searchTasks') {
      System.assertEquals(2, listOfArgs.size());
      return searchTasks((String) listOfArgs[0], (String) listOfArgs[1]);
    } else if (stubbedMethodName == 'getTaskForCase') {
      System.assertEquals(1, listOfArgs.size());
      return getTaskForCase((String) listOfArgs[0]);
    } else if (stubbedMethodName == 'getTasksForAccount') {
      System.assertEquals(1, listOfArgs.size());
      return getTasksForAccount((String) listOfArgs[0]);
    }

    throw new Exceptions.MockException('Failed to find method for ' + stubbedMethodName);

  }

  public List<Object> getListOfArgs() {
    return this.listOfArgs;
  }

  public virtual List<Task> searchTasks(String searchString, String accountId) {
    throw newUnsupportedMethodException('searchTasks');
  }

  public virtual List<Task> getTaskForCase(String caseId) {
    throw newUnsupportedMethodException('getTaskForCase');
  }

  public virtual List<Task> getTasksForAccount(String accountId) {
    throw newUnsupportedMethodException('getTasksForAccount');
  }
}