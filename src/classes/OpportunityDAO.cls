/**
 * Opportunity object data access object.
 */
public with sharing class OpportunityDAO {

  private static OpportunityDAO instance;

  @TestVisible
  private static void setMock(OpportunityDAO mock) {
    if (instance != null) {
      throw new Exceptions.ServiceException('The dao was already mocked or accessed.');
    }
    instance = mock;
  }

  public static OpportunityDAO getInstance() {
    if (instance == null) {
      instance = new OpportunityDAO();
    }
    return instance;
  }

  /**
   * Insert a list of opportunities.
   *
   * @param opportunities The List of opportunities.
   */
  public void insertOpportunities(List<Opportunity> opportunities) {
    insert opportunities;
  }

}