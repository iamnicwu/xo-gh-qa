@IsTest
private class CaseDTOTest {
  @IsTest
  static void testGetCaseFromMap() {
    List<User> u = [SELECT Id FROM User LIMIT 1];

    Account acc = new Account();
    acc.Name = 'Account Temp';
    insert acc;

    Contact cont = new Contact();
    cont.FirstName = 'Test';
    cont.LastName = 'Contact';
    cont.AccountId = acc.Id;
    insert cont;

    Map<String, Object> caseValues = new Map<String, Object> {
        'caseOwnerId' => u.get(0).Id,
        'contactId' => cont.Id,
        'accountId' => acc.Id,
        'initialContact' => 'initialContact',
        'type' => 'type',
        'originalRequestDate' => '2018-03-07 10:10:10'
    };

    Test.startTest();
    Case c = CaseDTO.getCase(caseValues);
    Test.stopTest();

    System.assert(c != null, 'Should return case.');
    System.assertEquals(u.get(0).Id, c.OwnerId, 'Should have OwnerId.');
    System.assertEquals(cont.Id, c.ContactId, 'Should have ContactId.');
    System.assertEquals(acc.Id, c.AccountId, 'Should have AccountId.');
    System.assertEquals('initialContact', c.Origin, 'Should have Origin.');
    System.assertEquals('type', c.Type, 'Should have Type.');
    System.assertEquals(Datetime.valueOf('2018-03-07 10:10:10'), c.Date_and_Time_Request_Received__c, 'Should have Date_and_Time_Request_Received__c.');
  }
}