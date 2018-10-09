@IsTest
private class RecordTypeDAOTest {

  @IsTest
  static void testGetRecordTypeByNameNoRecordType() {

    Test.startTest();
    RecordType rt = RecordTypeDAO.getInstance().getRecordTypeByName('notaname');
    Test.stopTest();

    System.assertEquals(null, rt);
  }

  @IsTest
  static void testGetRecordTypeByNameExists() {

    Test.startTest();
    RecordType rt = RecordTypeDAO.getInstance().getRecordTypeByName('Local');
    Test.stopTest();

    System.assertNotEquals(null, rt);
  }

  @IsTest
  static void testGetLocalRecordTypeForOpportunity() {

    Test.startTest();
    RecordType localOppRecordType = RecordTypeDAO.getInstance().getLocalRecordTypeForOpportunity();
    Test.stopTest();

    System.assertNotEquals(null, localOppRecordType);
  }

}