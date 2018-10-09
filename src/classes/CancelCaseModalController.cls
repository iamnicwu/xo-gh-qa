/**
 * The controller for the cancel case modal lightning components.
 */
public with sharing class CancelCaseModalController {
  /**
   * Initial search for accounts.
   *
   * @param searchVal The search string.
   * @return List<SearchResultDTO> List of search result dtos.
   */
  @AuraEnabled
  public static List<SearchResultDTO> initialSearchAccounts(String searchVal) {
    try {
      return CaseService.getInstance().getAccountsById(searchVal);
    } catch (Exception e) {
      throw LightningUtility.createException(e.getMessage());
    }
  }

  /**
   * Search accounts.
   *
   * @param searchVal The search string.
   * @return List<SearchResultDTO> List of search result dtos.
   */
  @AuraEnabled
  public static List<SearchResultDTO> searchAccounts(String searchVal) {
    try {
      return CaseService.getInstance().searchAccounts(searchVal);
    } catch (Exception e) {
      throw LightningUtility.createException(e.getMessage());
    }
  }

  /**
  * Initial search contacts.
  *
  * @param searchVal The search string.
  * @return List<SearchResultDTO> List of search result dtos.
  */
  @AuraEnabled
  public static List<SearchResultDTO> initialSearchContacts(String searchVal) {
    try {
      return CaseService.getInstance().getContactsForAccount(searchVal);
    } catch (Exception e) {
      throw LightningUtility.createException(e.getMessage());
    }
  }

  /**
   * Search contacts.
   *
   * @param searchVal The search string.
   * @param accountId The account id.
   * @return List<SearchResultDTO> List of search result dtos.
   */
  @AuraEnabled
  public static List<SearchResultDTO> searchContacts(String searchVal, String accountId) {
    try {
      return CaseService.getInstance().searchContacts(searchVal, accountId);
    } catch (Exception e) {
      throw LightningUtility.createException(e.getMessage());
    }
  }

  /**
   * Search tasks on account.
   *
   * @param searchVal The search string.
   * @return List<SearchResultDTO> List of search result dtos.
   */
  @AuraEnabled
  public static List<SearchResultDTO> initialSearchTasks(String searchVal) {
    try {
      return CaseService.getInstance().getTasksForAccount(searchVal);
    } catch (Exception e) {
      throw LightningUtility.createException(e.getMessage());
    }
  }

  /**
   * Search tasks.
   *
   * @param searchVal The search string.
   * @param accountId The account id.
   * @return List<SearchResultDTO> List of search result dtos.
   */
  @AuraEnabled
  public static List<SearchResultDTO> searchTasks(String searchVal, String accountId) {
    try {
      return CaseService.getInstance().searchTasks(searchVal, accountId);
    } catch (Exception e) {
      throw LightningUtility.createException(e.getMessage());
    }
  }

  /**
   * Search users on account.
   *
   * @param searchVal The search string.
   * @return List<SearchResultDTO> List of search result dtos.
   */
  @AuraEnabled
  public static List<SearchResultDTO> initialSearchUsers(String searchVal) {
    try {
      return CaseService.getInstance().getUsersOnAccount(searchVal);
    } catch (Exception e) {
      throw LightningUtility.createException(e.getMessage());
    }
  }

  /**
   * Search users.
   *
   * @param searchVal The search string.
   * @return List<SearchResultDTO> List of search result dtos.
   */
  @AuraEnabled
  public static List<SearchResultDTO> searchUsers(String searchVal) {
    try {
      return CaseService.getInstance().searchUsers(searchVal);
    } catch (Exception e) {
      throw LightningUtility.createException(e.getMessage());
    }
  }
}