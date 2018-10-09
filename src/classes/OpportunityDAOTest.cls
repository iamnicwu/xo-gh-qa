@IsTest
private class OpportunityDAOTest {

  @IsTest
  static void testInsertOpportunities() {

    Opportunity one = new Opportunity();
    one.StageName = 'Closed';
    one.CloseDate = Date.today();
    Opportunity two = new Opportunity();
    two.StageName = 'Closed';
    two.CloseDate = Date.today();

    List<Opportunity> opportunities = new List<Opportunity>{one, two};

    Test.startTest();
    OpportunityDAO.getInstance().insertOpportunities(opportunities);
    Test.stopTest();

    System.assertNotEquals(null, one.Id);
    System.assertNotEquals(null, two.Id);
  }

}