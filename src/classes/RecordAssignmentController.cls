public with sharing class RecordAssignmentController {
  //////////////////////
  // STATIC VARIABLES //
  //////////////////////

  // OBJECT FILTER MAP - Instantiated in the static method below
  private final static Map<String, List<FieldOptions>> OBJECT_FILTER_MAP;

  // CSP-1852 Assignment Tool Data Points adding Lead Source field
  private final static Map<String, String> FIELD_TO_OBJECT_MAP 
    = new Map<String, String>{'Local_Sales_Market__c' => 'Market__c',
                              'Primary_Category__c' => 'Category__c',
                              'OwnerId' => 'User',
                              'Lead_Source__c' => 'Lead_Source__c',
                              'PreviousOwner__c' => 'User'
                              };

  private final static Map<String, List<FieldResponse>> 
    OBJECT_DISPLAY_FIELD_MAP 
      = new Map<String, List<FieldResponse>>{'Account' => new List<FieldResponse>{new FieldResponse('Primary Category', 'Primary_Category__r.Name'), 
                                                                                  new FieldResponse('Locale Sales Market', 'Local_Sales_Market__r.Name'), 
                                                                                  new FieldResponse('Record Owner', 'Owner.Name')},
                                              'Lead' => new List<FieldResponse>{new FieldResponse('Company', 'Company'),
                                                                                new FieldResponse('Primary Category', 'Primary_Category__r.Name'),  
                                                                                new FieldResponse('Status', 'Status'),
                                                                                new FieldResponse('Locale Sales Market', 'Local_Sales_Market__r.Name'), 
                                                                                new FieldResponse('Record Owner', 'Owner.Name')}};

  private final static String USER_QUERY =  'SELECT '
                                              + 'Id, '
                                              + 'Name, '
                                              + 'FullPhotoUrl, '
                                              + 'SmallPhotoUrl, '
                                              + 'IsActive, '
                                              + 'LastLoginDate, '
                                              + 'Profile.Name, '
                                              + 'UserRole.Name '
                                            + ' FROM '
                                              + 'User'
                                            + ' WHERE '
                                              + 'Id = \'{USERID}\''
                                            + ' LIMIT 1';

  // ONLY get records which have the RecordType.Name = Local
  private final static String OBJECT_QUERY = 'SELECT '
                                              + 'Id, '
                                              + 'Name '
                                              + '{FIELDS} '
                                            + ' FROM '
                                              + '{OBJECT}'
                                            + ' WHERE '
                                              + ' RecordType.Name = \'Local\' '
                                              + ' {WHERECLAUSE} '
                                            + ' LIMIT 2000';

  // User PROFILE Query - Used to add all the profiles needed for Record Reassignment - Service Accounts and Admins were
  // added by CSP-1854
  private final static String USER_PROFILE_QUERY_ADDITION = '(Profile.Name = \'Local Core Account Executive\''
                                                          + ' OR '
                                                            + 'Profile.Name = \'Local Core Finance - ARR\''
                                                          + ' OR '
                                                            + 'Profile.Name = \'Local Core Marketing\''
                                                          + ' OR '
                                                            + 'Profile.Name = \'Local Core Regional Sales (RSR, RSD)\''
                                                          + ' OR '
                                                            + 'Profile.Name = \'Local Core Sales Operations\''
                                                          + ' OR '
                                                            + 'Profile.Name = \'Local Core Strategy Specialist\''
                                                          + ' OR '
                                                            + 'Profile.Name = \'Service Accounts Hubspot\''
                                                          + ' OR '
                                                            + 'Profile.Name = \'Service Accounts\''
                                                          + ' OR '
                                                            + 'Profile.Name = \'System Administrator\')';

  private final static Map<String, String> SYSTEM_MARKET_MAP;
  private final static Map<String, String> SYSTEM_CATEGORY_MAP;
  private final static Map<String, String> ACCOUNT_STATUS_MAP;
  
  ////////////////////////
  // STATIC INITIALIZER //
  ////////////////////////
  static {
    List<Market__c> systemMarketList = [SELECT Id, Name FROM Market__c];
    List<Category__c> systemCategoryList = [SELECT Id, Name FROM Category__c];

    ///////////////////////////////
    // BUILD MARKET PICKLIST MAP //
    ///////////////////////////////
    Map<String, String> tempMarketMap = new Map<String, String>();
    for(Integer i = 0, len = systemMarketList.size(); i < len; i++) {
      Market__c currentMarket = systemMarketList[i];

      tempMarketMap.put(currentMarket.Name, currentMarket.Id);
    }

    // Set SYSTEM_MARKET_MAP to be the tempMarketMap
    SYSTEM_MARKET_MAP = tempMarketMap;


    /////////////////////////////////
    // BUILD CATEGORY PICKLIST MAP //
    /////////////////////////////////
    Map<String, String> tempCategoryMap = new Map<String, String>();
    for(Integer i = 0, len = systemCategoryList.size(); i < len; i++) {
      Category__c currentCategory = systemCategoryList[i];

      tempCategoryMap.put(currentCategory.Name, currentCategory.Id);
    }

    // Set SYSTEM_CATEGORY_MAP to be the tempCategoryMap
    SYSTEM_CATEGORY_MAP = tempCategoryMap;

    OBJECT_FILTER_MAP = new Map<String, List<FieldOptions>>{'Lead' => buildLeadFieldOptions(),
                                                            'Account' => buildAccountFieldOptions()};
  }

  // CSP-1852 Assignment Tool Data Points adding private method to get picklist values from specific field
  private static Map<String, String> picklistValueMap(String objectName, String fieldName){

    Map<String, String> valueMap = new Map<String, String>();
    Schema.SObjectType sType = Schema.getGlobalDescribe().get(objectName);
    Schema.DescribeSObjectResult objSchema = sType.getDescribe();
    Map<String, Schema.SObjectField> fieldMap = objSchema.fields.getmap();
    // retrieve all picklist values from specific field
    List<Schema.Picklistentry> picklistEntryList = fieldMap.get(fieldName).getDescribe().getPicklistValues();
    
    for(Schema.PicklistEntry ple : picklistEntryList){
      valueMap.put(ple.getValue(), ple.getValue());
    }
    return valueMap;
  }

  // CSP-1852 Assignment Tool Data Points adding Lead Source field
  private static List<FieldOptions> buildLeadFieldOptions() {
    List<FieldOptions> leadOptions 
      = new List<FieldOptions>{ 
                                new FieldOptions('Last Activity', 'LastModifiedDate', 'datepicker'),
                                new FieldOptions('Lead Source', 'Lead_Source__c', 'textSearch'),
                                new FieldOptions('Market', 'Local_Sales_Market__c', 'picklist', SYSTEM_MARKET_MAP),
                                new FieldOptions('Owner', 'OwnerId', 'textSearch'),
                                new FieldOptions('Owner Status', 'Owner.IsActive', 'checkbox', new Map<String, String>{'Active' => 'true', 'Inactive' => 'false'}),
                                new FieldOptions('Ownership Age', 'Ownership_Age__c', 'text'),
                                new FieldOptions('Previous Owner', 'PreviousOwner__c', 'textSearch'),
                                new FieldOptions('Postal Code', 'PostalCode', 'text'),
                                new FieldOptions('Primary Category', 'Primary_Category__c', 'picklist', SYSTEM_CATEGORY_MAP),
                                new FieldOptions('State', 'State', 'text'),
                                new FieldOptions('State Code', 'StateCode', 'text')
                              };

    return leadOptions;
  }

  // CSP-1852 Assignment Tool Data Points adding Lead Source field
  private static List<FieldOptions> buildAccountFieldOptions() {
    List<FieldOptions> accountOptions 
      = new List<FieldOptions>{ 
                                new FieldOptions('Billing Postal Code', 'BillingPostalCode', 'text'),
                                new FieldOptions('Billing State', 'BillingState', 'text'),
                                new FieldOptions('Billing State Code', 'BillingStateCode', 'text'),
                                new FieldOptions('Days Since Expiration', 'Num_Of_Days_Since_Expiration__c', 'text'),
                                new FieldOptions('Last Activity', 'LastModifiedDate', 'datepicker'),
                                new FieldOptions('Lead Source', 'Lead_Source__c', 'textSearch'),
                                new FieldOptions('Market', 'Local_Sales_Market__c', 'picklist', SYSTEM_MARKET_MAP),
                                new FieldOptions('Owner', 'OwnerId', 'textSearch'),
                                new FieldOptions('Owner Status', 'Owner.IsActive', 'checkbox', new Map<String, String>{'Active' => 'true', 'Inactive' => 'false'}),
                                new FieldOptions('Ownership Age', 'Ownership_Age__c', 'text'),
                                new FieldOptions('Previous Owner', 'PreviousOwner__c', 'textSearch'),
                                new FieldOptions('Primary Category', 'Primary_Category__c', 'picklist', SYSTEM_CATEGORY_MAP)
                              };
    return accountOptions;
  }

  /**
   *   Method used to build all the needed object filters for the objects that can be reassigned in the front end.
   *   Currently this is just Lead and Account.
   *
   *   @author Justin
   *   @date   2017-01-31
   *   @param  {String}             objectName The object name which is selected in the front end.
   *   @return {List<FieldOptions>}            A list of FieldOption objects that is returned to the front end. This is
   *                                           used to dynamically populate picklist values.
   */
  @AuraEnabled
  public static List<FieldOptions> getObjectFilters(String objectName, Boolean firstPageLoad) {
    if(String.isBlank(objectName) || !OBJECT_FILTER_MAP.containsKey(objectName)) {
      return new List<FieldOptions>();
    }

    if(firstPageLoad) {
      // Create a Usage record for Page Load
      XOUsageUtility.createUsage('Record Assignment', 'init', 'Page Load', 'Object Selected by Default on Load: ' + objectName);
    } else {
      // Create a Usage record for Object Switched - send object that was chosen
      XOUsageUtility.createUsage('Record Assignment', 'getObjectFilters', 'Filter Selected/Changed', 'Object selected from UI: ' + objectName);
    }

    return OBJECT_FILTER_MAP.get(objectName);
  }

  /**
   *   Dynamic query method which receives an object name, field being used to query, query data, and an active user
   *   flag. This method returns 5 records to the front end primarily used for type search inputs. 
   *
   *   CSP-1872 Assignment Tool Data Points, add one more query for lead owner
   *   
   *   @author Justin
   *   @date   2017-01-31
   *   @param  {String}        objectName       The object name from the front end.
   *   @param  {String}        fieldQuery       The field that was used on the front end to query against - this value
   *                                            is used to check a map to transfer the field to an object reference in
   *                                            the system.
   *   @param  {String}        queryData        The input value which is used to find a record which has a Name LIKE
   *                                            what the User input.
   *   @param  {Boolean}       checkUserActive  A boolean variable which is used to determine if the query should only
   *                                            use "Active" users in the query.
   *   @return {List<SObject>}                  The SObject records which were dynamically retieved from the database.
   */
  @AuraEnabled
  public static List<SObject> getInputQueryData(String objectName, String fieldQuery, String queryData, Boolean checkUserActive) {
    
    if(String.isBlank(objectName) || String.isBlank(fieldQuery) || String.isBlank(queryData) || !FIELD_TO_OBJECT_MAP.containsKey(fieldQuery)) {
      return null;
    }

    List<SObject> resultList = new List<SObject>();

    // Use the FIELD_TO_OBJECT_MAP to turn the field which is being used for selection into an Object API Name.
    String objectAPIName = FIELD_TO_OBJECT_MAP.get(fieldQuery);

    String query = 'SELECT Id, Name FROM ';

    query += objectAPIName + ' WHERE Name LIKE \'%' + String.escapeSingleQuotes(queryData) + '%\'';
    // Special Logic for the User object
    if(objectAPIName == 'User') {
      if(checkUserActive) {
        query += ' AND IsActive = true ';
      }
      // Only return Users which have a "Local" profile name, System Admins, and Service Accounts
      query += ' AND ' + USER_PROFILE_QUERY_ADDITION;
    }
    query += ' LIMIT 5';

    // CSP-1852 Assignment Tool Data Points
    // Check if the field is OwnerId or PreviousOwner from Lead, if yes, query user and group
    if(objectName.equalsIgnoreCase('Lead') && 
      (fieldQuery.equalsIgnoreCase('OwnerId') || 
        fieldQuery.equalsIgnoreCase('PreviousOwner__c'))){
      
      String queryLog =query;

      resultList = Database.query(query);
      if(resultList.isEmpty()){
        queryLog += '\r\n';
        query = 'SELECT Id, Name FROM ';
        query += ' Group WHERE Name LIKE \'%' + String.escapeSingleQuotes(queryData) + '%\'';
        query += ' LIMIT 5';
        queryLog += query;
        resultList = Database.query(query);

      }
      XOUsageUtility.createUsage('Record Assignment', 'getInputQueryData', 'Input Field Query', 'Data returned by the following query: \r\n' + queryLog);
      return resultList;
    }
    else{
      XOUsageUtility.createUsage('Record Assignment', 'getInputQueryData', 'Input Field Query', 'Data returned by the following query: \r\n' + query);

      return Database.query(query);
    }
  }

  /**
   *   Method used to retrieve more detailed information about a user upon selection from the front. This method uses
   *   a static query which can be found in the variable definitions above. The only piece filled in is the User ID
   *   that is passed in from the front end.
   *
   *   @author Justin
   *   @date   2017-01-31
   *   @param  {String}   userId The User Id which was selected and sent from the front end.
   *   @return {User}            The User object from the database which was retrieved.
   */
  @AuraEnabled
  public static User getUserInformation(String userId) {
    if(String.isBlank(userId)) {
      return null;
    }

    String userQuery = USER_QUERY.replace('{USERID}', String.escapeSingleQuotes(userId));

    XOUsageUtility.createUsage('Record Assignment', 'getUserInformation', 'User Assignment Setup', 'Data returned by the following query: \r\n' + userQuery);

    return Database.query(userQuery);
  }

  @AuraEnabled
  public static Map<String, List<Object>> queryWithFilters(String filterJSON, String objectName) {
    if(String.isBlank(objectName) || !OBJECT_DISPLAY_FIELD_MAP.containsKey(objectName)) {
      return null;
    }

    // String used for dynamic generation of the WHERE clause in the dynamic query
    String whereClause = '';
    // The field list for the current object which is stored in a field response object
    List<FieldResponse> fieldList = OBJECT_DISPLAY_FIELD_MAP.get(objectName);
    // The dynamic query being retrieved
    String dynamicQuery = OBJECT_QUERY.replace('{FIELDS}', generateFieldString(fieldList));
    // Adding the object into the dynamic query
    dynamicQuery = dynamicQuery.replace('{OBJECT}', objectName);

    Map<String, Object> filterObject = (Map<String, Object>)JSON.deserializeUntyped(filterJSON);
    
    List<String> filterTypeList = new List<String>(filterObject.keySet());
    for(Integer i = 0; i < filterTypeList.size(); i++) {
      String currentFilterType = filterTypeList[i];

      whereClause += generateQueryString(currentFilterType, (Map<String, Object>)filterObject.get(currentFilterType));
    }

    // Special Lead Filter Logic to ignore converted
    if(objectName == 'Lead') {
      whereClause += ' AND IsConverted = false';
    }

    dynamicQuery = dynamicQuery.replace('{WHERECLAUSE}', whereClause);

    Map<String, List<Object>> genericMap = new Map<String, List<Object>>();

    System.debug(dynamicQuery);

    genericMap.put('values', (List<Object>)Database.query(dynamicQuery));
    genericMap.put('fields', (List<Object>)fieldList);

    XOUsageUtility.createUsage('Record Assignment', 'queryWithFilters', 
                                'User Filter Records', 'Data returned by the following query: \r\n' + dynamicQuery
                                + '\r\n\r\n'
                                + 'Data Returned to User: \r\n'
                                + String.valueOf(genericMap));

    return genericMap;
  }

  @AuraEnabled
  public static List<UpdateFailure> assignOwner(List<String> sobjectIds, String newOwnerId, String objectName) {
    if(sobjectIds == null || sobjectIds.isEmpty() || String.isBlank(objectName)) {
      return null;
    }

    List<SObject> objectsToUpdate = new List<SObject>();
    Type objectType = Type.forName(objectName);

    for(Integer i = 0; i < sobjectIds.size(); i++) {
      String currentId = sobjectIds[i];
      SObject objectInstance = (SObject)objectType.newInstance();
      objectInstance.put('Id', currentId);
      objectInstance.put('OwnerId', newOwnerId);

      objectsToUpdate.add(objectInstance);
    }

    XOUsageUtility.createUsage('Record Assignment', 'assignOwner', 
                                'Record Update(s)', 'User performed record update to reassign the following records: \r\n\r\n'
                                + String.valueOf(objectsToUpdate));

    List<Database.SaveResult> updateResults = Database.update(objectsToUpdate, false);
    List<UpdateFailure> updateFailureList = new List<UpdateFailure>();

    for(Integer i = 0; i < updateResults.size(); i++) {
      Database.SaveResult currentResult = updateResults[i];
      if(currentResult.isSuccess()) {
        continue;
      }

      List<Database.Error> databaseErrorList = currentResult.getErrors();
      UpdateFailure newFailure = new UpdateFailure();
      newFailure.failedObject = objectsToUpdate[i];
      for(Integer j = 0; j < databaseErrorList.size(); j++) {
        Database.Error currentError = databaseErrorList[j];
        newFailure.errorMessageList.add(currentError.getMessage());
      }
      updateFailureList.add(newFailure);
    }

    return updateFailureList;
  }

  private static String generateFieldString(List<FieldResponse> fieldResponseList) {
    String fieldQuery = '';
    for(Integer i = 0; i < fieldResponseList.size(); i++) {
      FieldResponse currentResponse = fieldResponseList[i];
      System.debug('RESPONSE ' + currentResponse);
      fieldQuery += ', ' + currentResponse.fieldName;
    }

    return fieldQuery;
  }

  private static String generateQueryString(String currentFilterType, Map<String, Object> fieldToFilterValuesMap) {
    
    String queryString = '';
    List<String> filterFieldList = new List<String>(fieldToFilterValuesMap.keySet());

    for(Integer i = 0; i < filterFieldList.size(); i++) {
      String currentFilterField = filterFieldList[i];
      
      List<String> includeValues = new List<String>();
      List<String> excludeValues = new List<String>();
      List<Object> filterValueList = (List<Object>)fieldToFilterValuesMap.get(currentFilterField);

      for(Integer j = 0; j < filterValueList.size(); j++) {
        
        Map<String, Object> currentFilterObject = (Map<String, Object>)filterValueList[j];
        String currentFilterValue = (String)currentFilterObject.get('userInput');
          
        
        if(currentFilterType == 'checkbox') {

          // CSP-1852 fixed owner status filter issue
          // String boolValue = currentFilterValue == 'Active' ? 'true' : 'false';
          String boolValue = currentFilterValue;
          
          if(Boolean.valueOf(currentFilterObject.get('include'))) {
            includeValues.add(currentFilterField + ' = ' + boolValue);
          } 
          else {
            excludeValues.add(currentFilterField + ' != ' + boolValue);
          }
          continue;
        }
        // CSP-1852 add datepicker filter type
        else if(currentFilterType == 'datepicker'){

          if(Boolean.valueOf(currentFilterObject.get('include'))){
            includeValues.add('DAY_ONLY(convertTimezone(' + currentFilterField + '))' + ' = ' + currentFilterValue);
          }
          else{
            excludeValues.add('DAY_ONLY(convertTimezone(' + currentFilterField + '))' + ' != ' + currentFilterValue);
          }
          continue;
        }
        
        if(Boolean.valueOf(currentFilterObject.get('include'))) {

          // CSP-1852 add specific field Num_Of_Days_Since_Expiration__c to set greater equal than input number of days
          if(currentFilterField == 'Num_Of_Days_Since_Expiration__c'){
            includeValues.add(currentFilterField + ' >= ' + String.escapeSingleQuotes(currentFilterValue));
          }
          // CSP-1852 add specific field Ownership_Age__c to set equal to input number of days
          else if(currentFilterField == 'Ownership_Age__c'){
            includeValues.add(currentFilterField + ' = ' + String.escapeSingleQuotes(currentFilterValue));
          }
          else{
            includeValues.add(currentFilterField + ' = \'' + String.escapeSingleQuotes(currentFilterValue) + '\'');
          }
        } 
        else {
          excludeValues.add(currentFilterField + ' != \'' + String.escapeSingleQuotes(currentFilterValue) + '\'');
        }
      }

      if(includeValues.size() > 0) {
        queryString += ' AND (' + String.join(includeValues, ' OR ') + ')';
      }

      if(excludeValues.size() > 0) {
        queryString += ' AND ' + String.join(excludeValues, ' AND ');
      }
    }

    return queryString;
  }

  public class UpdateFailure {
    @AuraEnabled
    public SObject failedObject;
    @AuraEnabled
    public List<String> errorMessageList;

    public UpdateFailure() {
      failedObject = null;
      errorMessageList = new List<String>();
    }

    public UpdateFailure(SObject pFailedObject, List<String> pErrorMessageList) {
      failedObject = pFailedObject;
      errorMessageList = pErrorMessageList;
    }

    public UpdateFailure(SObject pFailedObject, String errorMessage) {
      failedObject = pFailedObject;
      errorMessageList = new List<String>{errorMessage};
    }
  }

  public class FieldResponse {
    @AuraEnabled
    public String displayName;
    @AuraEnabled
    public String fieldName;

    public FieldResponse() {
      displayName = '';
      fieldName = '';
    }

    public FieldResponse(String pDispName, String pFieldName) {
      displayName = pDispName;
      fieldName = pFieldName;
    }
  }

  public class FieldOptions {
    @AuraEnabled
    public String value;
    @AuraEnabled
    public String objectFilter;
    @AuraEnabled
    public String filterType;
    @AuraEnabled
    public Map<String, String> additionalFilterOptions;

    public FieldOptions() {
      value = '';
      objectFilter = '';
      filterType = '';
      additionalFilterOptions = new Map<String, String>();
    }

    public FieldOptions(String pValue, String pObjFilter, String pFilterType) {
      value = pValue;
      objectFilter = pObjFilter;
      filterType = pFilterType;
    }

    public FieldOptions(String pValue, String pObjFilter, String pFilterType, Map<String, String> pFilterOptions) {
      value = pValue;
      objectFilter = pObjFilter;
      filterType = pFilterType;
      additionalFilterOptions = pFilterOptions;
    }
  }
}