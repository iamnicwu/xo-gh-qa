/**
 * Service class for RecordType Objects.
 */
public with sharing class RecordTypeService {
  private static RecordTypeService instance;

  @TestVisible
  private static void setMock(RecordTypeService mock) {
    if (instance != null) {
      throw new Exceptions.ServiceException('The dao was already mocked or accessed.');
    }
    instance = mock;
  }

  public static RecordTypeService getInstance() {
    if (instance == null) {
      instance = new RecordTypeService();
    }
    return instance;
  }

  /**
   * Get the RecordType for Opportunity objects.
   *
   * @return The RecordType.
   */
  public RecordType getLocalRecordTypeForOpportunity() {
    return RecordTypeDAO.getInstance().getLocalRecordTypeForOpportunity();
  }

}