@IsTest
private class FeatureRequestedCancelServiceTest {

  @IsTest
  static void testGetStatusOptions() {
    List<SelectOption> statusValues;

    Test.startTest();
    statusValues = FeatureRequestedCancelService.getInstance().getStatusOptions();
    Test.stopTest();

    System.assertNotEquals(0, statusValues.size());
  }

  @IsTest
  static void testUpsertFRCs() {

    FeatureRequestCanceledDAOSuccessMock FRCDaoMock = new FeatureRequestCanceledDAOSuccessMock();
    FeatureRequestCanceledDAO.setMock((FeatureRequestCanceledDAO) Test.createStub(FeatureRequestCanceledDAO.class, FRCDaoMock));

    Feature_Requested_Cancelled__c frc = new Feature_Requested_Cancelled__c();
    List<Feature_Requested_Cancelled__c> frcs = new List<Feature_Requested_Cancelled__c>{frc};

    Test.startTest();
    FeatureRequestedCancelService.getInstance().upsertFRCs(frcs);
    Test.stopTest();

    List<Feature_Requested_Cancelled__c> mockedFRCs = FRCDaoMock.getFRCs();
    System.assertEquals(1, mockedFRCs.size());
  }

  @IsTest
  static void testDeleteFRCs() {
    FeatureRequestCanceledDAOSuccessMock FRCDaoMock = new FeatureRequestCanceledDAOSuccessMock();
    FeatureRequestCanceledDAO.setMock((FeatureRequestCanceledDAO) Test.createStub(FeatureRequestCanceledDAO.class, FRCDaoMock));

    Feature_Requested_Cancelled__c frc = new Feature_Requested_Cancelled__c();
    List<Feature_Requested_Cancelled__c> frcs = new List<Feature_Requested_Cancelled__c>{frc};

    Test.startTest();
    FeatureRequestedCancelService.getInstance().deleteFRCs(frcs);
    Test.stopTest();

    List<Feature_Requested_Cancelled__c> mockedFRCs = FRCDaoMock.getFRCs();
    System.assertEquals(1, mockedFRCs.size());
  }

  class FeatureRequestCanceledDAOSuccessMock extends FeatureRequestCanceledDAOMock {

    private List<Feature_Requested_Cancelled__c> frcs;

    public List<Feature_Requested_Cancelled__c> getFRCs() {
      return this.frcs;
    }

    public override void upsertFRCs(List<Feature_Requested_Cancelled__c> frcs) {
      System.assertNotEquals(0, frcs.size());
      this.frcs = frcs;
    }

    public override void deleteFRCs(List<Feature_Requested_Cancelled__c> frcs) {
      System.assertNotEquals(0, frcs.size());
      this.frcs = frcs;
    }
  }
}