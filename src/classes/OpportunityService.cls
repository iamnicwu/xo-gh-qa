/**
 * Service class for Opportunity objects.
 */
public with sharing class OpportunityService {
  private static OpportunityService instance;

  @TestVisible
  private static void setMock(OpportunityService mock) {
    if (instance != null) {
      throw new Exceptions.ServiceException('The dao was already mocked or accessed.');
    }
    instance = mock;
  }

  public static OpportunityService getInstance() {
    if (instance == null) {
      instance = new OpportunityService();
    }
    return instance;
  }

  /**
   * Insert a list of Opportunities.
   *
   * @param opportunities The List of Opportunities.
   */
  public void insertOpportunities(List<Opportunity> opportunities) {
    OpportunityDAO.getInstance().insertOpportunities(opportunities);
  }

}