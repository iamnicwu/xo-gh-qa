@IsTest
private class FeatureRequestCanceledDAOTest {

  @IsTest
  static void testUpsertFRCs() {
    Map<String, SObject> testObjects = TestClassUtility.buildLocalData(false);
    Account acc = (Account)testObjects.get('Account');

    Case ca = new Case();
    ca.AccountId = acc.Id;
    insert ca;

    Feature_Requested_Cancelled__c frc1 = new Feature_Requested_Cancelled__c();
    frc1.Case__c = ca.Id;
    frc1.Sub_Product_Charge_Number__c = 'testnum';
    frc1.UniqueId__c = 'abcdefge';
    insert frc1;
    frc1.Sub_Product_Charge_Number__c = 'testnum2';

    List<Feature_Requested_Cancelled__c> frcs = new List<Feature_Requested_Cancelled__c>{frc1};

    Test.startTest();
    FeatureRequestCanceledDAO.getInstance().upsertFRCs(frcs);
    Test.stopTest();

    List<Feature_Requested_Cancelled__c> queryFRCs = [
        SELECT Id, Sub_Product_Charge_Number__c
        FROM Feature_Requested_Cancelled__c
    ];

    System.assertEquals(1, queryFRCs.size());
    System.assertEquals('testnum2', queryFRCs[0].Sub_Product_Charge_Number__c);
  }

  @IsTest
  static void testDeleteFRCs() {
    Map<String, SObject> testObjects = TestClassUtility.buildLocalData(false);
    Account acc = (Account)testObjects.get('Account');

    Case ca = new Case();
    ca.AccountId = acc.Id;
    insert ca;

    Feature_Requested_Cancelled__c frc1 = new Feature_Requested_Cancelled__c();
    frc1.Case__c = ca.Id;
    frc1.Sub_Product_Charge_Number__c = 'testnum';
    frc1.UniqueId__c = 'abcdefge';
    insert frc1;

    Test.startTest();
    FeatureRequestCanceledDAO.getInstance().deleteFRCs(new List<Feature_Requested_Cancelled__c>{frc1});
    Test.stopTest();


    List<Feature_Requested_Cancelled__c> queryFRCs = [
        SELECT Id, Sub_Product_Charge_Number__c
        FROM Feature_Requested_Cancelled__c
    ];

    System.assertEquals(0, queryFRCs.size());
  }
}