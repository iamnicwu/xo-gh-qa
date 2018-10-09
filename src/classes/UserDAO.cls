/**
 * User object data access object
 */
public with sharing class UserDAO {
  private static UserDAO instance;

  @TestVisible
  private static void setMock(UserDAO mock) {
    if (instance != null) {
      throw new Exceptions.ServiceException('The dao was already mocked or accessed.');
    }
    instance = mock;
  }

  public static UserDAO getInstance() {
    if (instance == null) {
      instance = new UserDAO();
    }
    return instance;
  }

  /*
   * Method to get user by Id
   *
   * @param String userId The user id.
   * @return User object or null
   */
  public User getUserById(String userId) {
    List<User> users = [
        SELECT Name
        FROM User
        WHERE Id = :userId
        LIMIT 1
    ];
    User user = (users.size() == 1) ? users.get(0) : null;
    return user;
  }

  /*
   * Method to search list of Users by search string
   *
   * @param String searchText The search text.
   * @return List<User> The list of Users.
   */
  public List<User> searchUsers(String searchText) {
    List<List<SObject>> results = [FIND :searchText IN ALL FIELDS RETURNING User(Id, Name)];
    List<User> users = results.size() == 1 ? results.get(0) : null;
    return users;
  }

  /*
   * Method to search list of Users on account
   *
   * @param String accountId The account id.
   * @return List<User> The list of Users.
   */
  public List<User> getUsersOnAccount(String accountId) {
    List<User> users = [SELECT Id, Name FROM User WHERE AccountId = :accountId];
    return users;
  }
}