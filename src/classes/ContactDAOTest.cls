@IsTest
private class ContactDAOTest {
  @IsTest
  static void testGetContactByAccountId() {
    Account acc = new Account();
    acc.Name = 'Account Temp';
    insert acc;

    Contact cont = new Contact();
    cont.FirstName = 'Test';
    cont.LastName = 'Contact';
    cont.AccountId = acc.Id;
    insert cont;

    Test.startTest();
    Contact c = ContactDAO.getInstance().getContactByAccountId(acc.Id);
    Test.stopTest();

    System.assert(c != null, 'Should return contact.');
    System.assertEquals('Test Contact', c.Name, 'Should have name.');
  }

  @IsTest
  static void testGetContactById() {
    Account acc = new Account();
    acc.Name = 'Account Temp';
    insert acc;

    Contact cont = new Contact();
    cont.FirstName = 'Test';
    cont.LastName = 'Contact';
    cont.AccountId = acc.Id;
    insert cont;

    Test.startTest();
    Contact c = ContactDAO.getInstance().getContactById(cont.Id);
    Test.stopTest();

    System.assert(c != null, 'Should return contact.');
    System.assertEquals('Test Contact', c.Name, 'Should have name.');
  }

  @IsTest
  static void testSearchContacts() {
    Account acc = new Account();
    acc.Name = 'Temp Account';
    insert acc;

    Contact cont = new Contact();
    cont.FirstName = 'Test';
    cont.LastName = 'Contact';
    cont.AccountId = acc.Id;
    insert cont;

    // This is needed to test the SOSL query
    List<Id> fixedSearchResults= new List<Id>();
    fixedSearchResults.add(cont.Id);
    Test.setFixedSearchResults(fixedSearchResults);

    Test.startTest();
    List<Contact> contacts = ContactDAO.getInstance().searchContacts('Test', acc.Id);
    Test.stopTest();

    System.assertEquals(1, contacts.size(), 'Should return 1 item.');
    System.assertEquals('Test Contact', contacts.get(0).Name, 'Should have correct name.');
  }

  @IsTest
  static void testSearchContactsNoResults() {
    Account acc = new Account();
    acc.Name = 'Temp Account';
    insert acc;

    Test.startTest();
    List<Contact> contacts = ContactDAO.getInstance().searchContacts('Test', acc.Id);
    Test.stopTest();

    System.assertEquals(0, contacts.size(), 'Should return 0 items.');
  }

  @IsTest
  static void testGetContactsOnAccount() {
    Account acc = new Account();
    acc.Name = 'Temp Account';
    insert acc;

    Contact cont = new Contact();
    cont.FirstName = 'Test';
    cont.LastName = 'Contact';
    cont.AccountId = acc.Id;
    insert cont;

    Test.startTest();
    List<Contact> contacts = ContactDAO.getInstance().getContactsOnAccount(acc.Id);
    Test.stopTest();

    System.assertEquals(1, contacts.size(), 'Should return 1 item.');
    System.assertEquals('Test Contact', contacts.get(0).Name, 'Should have correct name.');
  }
}