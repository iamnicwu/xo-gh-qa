public with sharing class RecordTypeDAO {

  private static RecordTypeDAO instance;

  @TestVisible
  private static void setMock(RecordTypeDAO mock) {
    if (instance != null) {
      throw new Exceptions.ServiceException('The dao was already mocked or accessed.');
    }
    instance = mock;
  }

  public static RecordTypeDAO getInstance() {
    if (instance == null) {
      instance = new RecordTypeDAO();
    }
    return instance;
  }

  /*
   * Method to get record type by name
   *
   * @param String name - The name.
   * @return RecordType object or null
   */
  public RecordType getRecordTypeByName(String name) {
    List<RecordType> recordTypes = [SELECT Id FROM RecordType WHERE Name = :name LIMIT 1];
    return (recordTypes.size() == 1) ? recordTypes.get(0) : null;
  }

  /**
   * Get the local recordType object for Opportunities.
   *
   * @return The recordType if it exists, null otherwise.
   */
  public RecordType getLocalRecordTypeForOpportunity() {

    List<RecordType> recordTypes = [
        SELECT Id, Name
        FROM RecordType
        WHERE SobjectType = 'Opportunity' and RecordType.Name = 'Local'
        LIMIT 1
    ];
    RecordType recordType = (recordTypes.size() == 1) ? recordTypes.get(0) : null;

    return recordType;

  }
}