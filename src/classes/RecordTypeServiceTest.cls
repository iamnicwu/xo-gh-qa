@IsTest
private with sharing class RecordTypeServiceTest {

  @IsTest
  static void testGetLocalRecordTypeForOpportunity() {

    Test.startTest();
    RecordType rt = RecordTypeService.getInstance().getLocalRecordTypeForOpportunity();
    Test.stopTest();

    System.assertNotEquals(null, rt);
  }
}