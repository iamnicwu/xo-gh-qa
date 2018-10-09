/**
 * Contact object data access object
 */
public with sharing class ContactDAO {
  private static ContactDAO instance;

  @TestVisible
  private static void setMock(ContactDAO mock) {
    if (instance != null) {
      throw new Exceptions.ServiceException('The dao was already mocked or accessed.');
    }
    instance = mock;
  }

  public static ContactDAO getInstance() {
    if (instance == null) {
      instance = new ContactDAO();
    }
    return instance;
  }

  /*
   * Method to get Contact by account Id
   *
   * @param String accId The account id.
   * @return Contact object or null
   */
  public Contact getContactByAccountId(String accId) {
    List<Contact> contacts = [
        SELECT Id, Name
        FROM Contact
        WHERE AccountId = :accId
        LIMIT 1
    ];
    return (contacts.size() == 1) ? contacts.get(0) : null;
  }

  /*
   * Method to get Contacts by account Id
   *
   * @param String accId The account id.
   * @return Contact object or null
   */
  public List<Contact> getContactsOnAccount(String accId) {
    List<Contact> contacts = [
        SELECT Id, Name
        FROM Contact
        WHERE AccountId = :accId
    ];
    return contacts;
  }

  /*
   * Method to get Contact by Id
   *
   * @param String contactId The Contact id.
   * @return Contact object or null
   */
  public Contact getContactById(String contactId) {
    List<Contact> contacts = [
        SELECT Id, Name
        FROM Contact
        WHERE Id = :contactId
        LIMIT 1
    ];
    Contact contact = (contacts.size() == 1) ? contacts.get(0) : null;
    return contact;
  }

  /*
   * Method to search list of Contacts by search string
   *
   * @param String searchText The search text.
   * @param accountId The account id.
   * @return List<Contact> The list of Contacts.
   */
  public List<Contact> searchContacts(String searchText, String accountId) {
    List<List<SObject>> results = [FIND :searchText IN ALL FIELDS RETURNING Contact(Id, Name WHERE AccountId = :accountId)];
    List<Contact> contacts = results.size() == 1 ? results.get(0) : null;
    return contacts;
  }
}