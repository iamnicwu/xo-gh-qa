@IsTest
private class CaseDAOTest {
  @IsTest
  static void testGetRecordTypeByNameSuccess() {
    String name = '1 - Cancels';

    Test.startTest();
    RecordType rts = RecordTypeDAO.getInstance().getRecordTypeByName(name);
    Test.stopTest();

    System.assert(rts != null, 'Should return item.');
  }

  @IsTest
  static void testGetCaseByAccountAndRecordType() {
    List<RecordType> cancelRecordTypes = [SELECT
        Id
      FROM RecordType
      WHERE Name = '1 - Cancels'
    ];

    Account acc = new Account();
    acc.Name = 'Account Temp';
    insert acc;

    Contact cont = new Contact();
    cont.FirstName = 'Test';
    cont.LastName = 'Contact';
    cont.AccountId = acc.Id;
    insert cont;

    Case cancelledCase = new Case();
    cancelledCase.AccountId = acc.Id;
    cancelledCase.RecordTypeId = cancelRecordTypes.get(0).Id;
    cancelledCase.Origin = 'Phone';
    cancelledCase.ContactId = cont.Id;
    insert cancelledCase;

    Test.startTest();
    Case c = CaseDAO.getInstance().getCaseByAccountAndRecordType(acc.Id, cancelRecordTypes.get(0).Id);
    Test.stopTest();

    System.assert(c != null, 'Should return contact.');
    System.assertEquals('Phone', c.Origin, 'Should have correct origin.');
    System.assertEquals(cont.Id, c.ContactId, 'Should have contact id.');
    System.assertEquals(acc.Id, c.AccountId, 'Should have account id.');
  }

  @IsTest
  static void testUpsertCase() {
    Account acc = new Account();
    acc.Name = 'Temp Account';
    insert acc;

    Contact cont = new Contact();
    cont.FirstName = 'Test';
    cont.LastName = 'Contact';
    cont.AccountId = acc.Id;
    insert cont;

    Case c = new Case();
    insert c;
    c.Origin = 'Web';
    c.ContactId = cont.Id;

    Test.startTest();
    Case newCase = CaseDAO.getInstance().upsertCase(c);
    Test.stopTest();

    System.assert(newCase != null, 'Should return case');
    System.assertEquals('Web', newCase.Origin, 'Should have correct origin.');
    System.assertEquals(cont.Id, newCase.ContactId, 'Should have correct contact id.');
  }

  @IsTest
  static void testgetWithFeatureRequestCanceled() {

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

    Feature_Requested_Cancelled__c frc = new Feature_Requested_Cancelled__c();
    frc.Case__c = c.Id;
    frc.Status__c = 'Cancelled';
    frc.UniqueId__c = 'abc123';
    frc.Sub_Product_Charge_Number__c = 'a1b2c3';
    insert frc;

    Test.startTest();
    Case testCase = CaseDAO.getInstance().getWithFeatureRequestCancelled(c.Id);
    Test.stopTest();

    System.assertNotEquals(testCase, null);
    System.assertEquals(1, testCase.Feature_Requested_Cancelled__r.size());
    Feature_Requested_Cancelled__c testFRC = testCase.Feature_Requested_Cancelled__r[0];
    System.assertEquals(frc.Id, testFRC.Id);
  }
}