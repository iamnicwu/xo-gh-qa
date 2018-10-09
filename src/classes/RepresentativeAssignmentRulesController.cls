public with sharing class RepresentativeAssignmentRulesController {
	private static final String MARKET_QUERY = 'SELECT '
                                              + 'Id, '
                                              + 'Name '
                                            + ' FROM '
                                              + 'Market__c'
                                            + ' ORDER BY '
                                              + ' Name ';

  private static final String CATEGORY_QUERY = 'SELECT '
                                                + 'Id, '
                                                + 'Name '
                                              + ' FROM '
                                                + 'Category__c'
                                              + ' ORDER BY '
                                                + ' Name ';

  private static final String USER_QUERY = 'SELECT '
                                            + 'Id, '
                                            + 'Name '
                                          + ' FROM '
                                            + 'User'
                                          + ' WHERE '
                                            + 'IsActive = true'
                                          + ' AND '
                                            + 'Profile.Name LIKE \'%local%\''
                                          + ' AND '
                                            + ' {WHERECLAUSE}'
                                          + ' LIMIT 5';

  private static final String REP_ASSIGNMENT_QUERY = 'SELECT '
                                                      + 'Id, '
                                                      + 'Name, '
                                                      + 'Market__r.Name, '
                                                      + 'Category__r.Name, '
                                                      + 'Zip_Code__r.Name, '
                                                      + 'Sales_Rep__r.Name, '
                                                      + 'Sales_Rep__r.IsActive '
                                                    + ' FROM '
                                                      + 'Local_Sales_Rep_Assignment__c'
                                                    + ' WHERE '
                                                      + ' {WHERECLAUSE}'
                                                    + ' LIMIT 2000 ';

  private static final String ZIP_QUERY = 'SELECT '
                                              + 'Id '
                                            + ' FROM '
                                              +' Zip__c '
                                            + ' WHERE '
                                              + '{WHERECLAUSE}';

  /**
   *   Retrieve all available options for Market and Category to be displayed on the front end.
   *
   *   @author Justin
   *   @date   2016-08-08
   *   @return {Map<String, List<PicklistOption>>} A map of picklist values to be displayed on the front end.
   */
  @AuraEnabled
  public static Map<String, List<PicklistOption>> getPicklistValue() {
    Map<String, List<PicklistOption>> picklistMap = new Map<String, List<PicklistOption>>();

    picklistMap.put('Market', retrieveMarketValues());
    picklistMap.put('Category', retrieveCategoryValues());

    // Create Usage record
    XOUsageUtility.createUsage('Assignment Rules', 'init', 'Page Load', 'Picklist Map Generated: ' + picklistMap);

    return picklistMap;
  }

  /**
   *   Method used to query available users from the system that meet specific criteria as well as the input value
   *   provided from the front end. See USER_QUERY variable above for specific criteria.
   *
   *   @author Justin
   *   @date   2016-08-08
   *   @param  {String}     inputValue Input value from the user being sent from the front end.
   *   @return {List<User>}            List of users meeting the criteria - limited to 5
   */
  @AuraEnabled
  public static List<User> queryUsers(String inputValue) {
    if(String.isBlank(inputValue)) {
      return null;
    }

    // Build dynamic query
    String userQuery = USER_QUERY.replace('{WHERECLAUSE}', 'Name LIKE \'%' + String.escapeSingleQuotes(inputValue) + '%\'');

    // Store database query into a list
    List<User> userList = Database.query(userQuery);

    // Create Usage record
    XOUsageUtility.createUsage('Assignment Rules', 'queryUsers', 'User Query', 
                                'Data returned by the following query: \r\n' 
                                + userQuery
                                + '\r\n\r\nRecords returned by query: \r\n'
                                + userList);

    return userList;
  }

  /**
   *   Method used to query current assignment rules in the system given specific criteria provided by the front end
   *   user input.
   *
   *   @author Justin
   *   @date   2016-08-08
   *   @param  {String}                              market     The market id of a selected market on the front end.
   *   @param  {String}                              category   The category id of a selected category on the front end.
   *   @param  {String}                              postalCode The zipcode name of a selected zipcode on the front end.
   *   @param  {String}                              rep        The user id of a selected user on the front end.
   *   @return {List<Local_Sales_Rep_Assignment__c>}            A list of all Local Sales Rep Assignment record which
   *                                                            matched the criteria specified limited to 2000.
   */
  @AuraEnabled
  public static List<Local_Sales_Rep_Assignment__c> queryRules(String market, String category, String postalCode, String rep) {
    String assignmentQuery = REP_ASSIGNMENT_QUERY;

    List<String> whereClauseList = new List<String>();

    if(String.isNotBlank(market) && market != 'none' && market != '-- None --') {
      whereClauseList.add(' Market__c = :market ');
    }

    if(String.isNotBlank(category) && category != 'none' && category != '-- None --') {
      whereClauseList.add(' Category__c = :category ');
    }

    if(String.isNotBlank(postalCode)) {
      whereClauseList.add(' Zip_Code__r.ZipCode__c = :postalCode ');
    }

    if(String.isNotBlank(rep)) {
      whereClauseList.add(' Sales_Rep__c = :rep ');
    }

    if(whereClauseList.size() > 0) {
      assignmentQuery = assignmentQuery.replace('{WHERECLAUSE}', String.join(whereClauseList, ' AND '));  
    } else {
      assignmentQuery = assignmentQuery.replace('{WHERECLAUSE}', '').replace('WHERE', '');
    }

    // Store records from query
    List<Local_Sales_Rep_Assignment__c> assignmentRuleList = Database.query(assignmentQuery);

    // Create Usage record
    XOUsageUtility.createUsage('Assignment Rules', 'queryRules', 'Rule Query', 
                                'Data returned by the following query: \r\n' 
                                + assignmentQuery
                                + '\r\n\r\nRecords returned by query: \r\n'
                                + assignmentRuleList);

    return assignmentRuleList;
  }

  /**
   *   Method used to update or insert an assignment rule which has been created or updated from the front end given
   *   specified criteria through a JSON string representation of an object. This object is parsed dynamically without
   *   casting into a structured object.
   *
   *   @author Justin
   *   @date   2016-08-08
   *   @param  {String}   saveObject JSON representation of an object being passed from the front end. 
   *                                 EG: {"Id":"a3m110000003QfhAAE","Market__c":"a3R11000000DxoCEAS","Category__c":"a3U110000009JYSEA2","Zip_Code__c":"","Sales_Rep__c":"005j000000DU2HsAAL"}
   *   @return {String}              Error message, if available, which is passed back to the front end for display.
   */
  @AuraEnabled
  public static String saveAssignmentRule(String saveObject) {
    if(String.isBlank(saveObject)) {
      return null;
    }

    Map<String, Object> assignmentObject = (Map<String, Object>)JSON.deserializeUntyped(saveObject);

    String catId = (String)assignmentObject.get('Category__c');
    String assignmentRuleId = (String)assignmentObject.get('Id');
    String marketId = (String)assignmentObject.get('Market__c');
    String zipCodeName = (String)assignmentObject.get('Zip_Code__c');
    String salesRepId = (String)assignmentObject.get('Sales_Rep__c');

    Local_Sales_Rep_Assignment__c assignRule = new Local_Sales_Rep_Assignment__c();

    if(String.isNotBlank(marketId)) {
      assignRule.Market__c = marketId == 'none' ? null : marketId;
    }

    if(String.isNotBlank(catId)) {
      assignRule.Category__c = catId == 'none' ? null : catId;
    }

    if(String.isNotBlank(zipCodeName)) {
      String zipQuery = ZIP_QUERY.replace('{WHERECLAUSE}', 'Name = :zipCodeName');
      Zip__c currentZipCode;

      try {
        currentZipCode = Database.query(zipQuery);
      } catch(Exception e) {
        return zipCodeName + ' Zipcode does not exist in this sytem.';
      }
      
      assignRule.Zip_Code__c = currentZipCode.Id;  
    } else {
      assignRule.Zip_Code__c = null;
    }

    if(String.isNotBlank(salesRepId)) {
      assignRule.Sales_Rep__c = salesRepId;
    }

    if(String.isNotBlank(assignmentRuleId)) {
      assignRule.Id = assignmentRuleId;
    }
    
    try {
      upsert assignRule;
    } catch(Exception e) {
      return e.getMessage();
    }

    // Create Usage record
    XOUsageUtility.createUsage('Assignment Rules', 'saveAssignmentRule', 'Assignment Rule Save', 
                                'The following data was created/updated: \r\n' 
                                + assignRule);

    return 'SUCCESS';
  }

  /**
   *   Method used to mass update many assignment rules - this is currently being used to just reassign the owner of
   *   many assignment rules all at once.
   *
   *   @author Justin
   *   @date   2017-02-16
   *   @param  {List<Local_Sales_Rep_Assignment__c>}   assignmentRuleList List which is being sent from the front end
   *                                                                      code that contains > 2 assignment rules for
   *                                                                      update.
   *   @return {String}                                                   The success or error message which is sent
   *                                                                      back to the front end for presentation.
   */
  @AuraEnabled
  public static String massSaveAssignmentRules(List<Local_Sales_Rep_Assignment__c> assignmentRuleList) {
    if(assignmentRuleList == null || assignmentRuleList.size() < 1) {
      return null;
    }

    try {
      update assignmentRuleList;
    } catch(Exception e) {
      System.debug('exception ' + e);
      return e.getMessage();
    }

    // Create Usage record
    XOUsageUtility.createUsage('Assignment Rules', 'massSaveAssignmentRules', 'Mass Assignment Rule Save', 
                                'The following ' + assignmentRuleList.size() + ' records were updated: \r\n' 
                                + assignmentRuleList);

    return 'SUCCESS';
  }

  /**
   *   Method used to retrieve all market values
   *
   *   @author Justin
   *   @date   2016-08-08
   *   @return {List<PicklistOption>} List of all values in PicklistOption format
   */
  private static List<PicklistOption> retrieveMarketValues() {
    List<PicklistOption> marketPicklistOptionList = new List<PicklistOption>();

    List<Market__c> marketList = Database.query(MARKET_QUERY);

    for(Integer i = 0; i < marketList.size(); i++) {
      Market__c currentMarket = marketList[i];
      marketPicklistOptionList.add(new PicklistOption(currentMarket.Name, currentMarket.Id));
    }

    return marketPicklistOptionList;
  }

  /**
   *   Method used to retrieve all category values
   *
   *   @author Justin
   *   @date   2016-08-08
   *   @return {List<PicklistOption>} List of all values in PicklistOption format
   */
  private static List<PicklistOption> retrieveCategoryValues() {
    List<PicklistOption> categoryPicklistOptionList = new List<PicklistOption>();

    List<Category__c> categoryList = Database.query(CATEGORY_QUERY);

    for(Integer i = 0; i < categoryList.size(); i++) {
      Category__c currentCategory = categoryList[i];
      categoryPicklistOptionList.add(new PicklistOption(currentCategory.Name, currentCategory.Id));
    }

    return categoryPicklistOptionList;
  }

  /**
   *   PicklistOption wrapper class for storing picklist options that will be utilized on the front end
   */
  public class PicklistOption {
    @AuraEnabled
    public String label;
    @AuraEnabled
    public String value;

    public PicklistOption(String paramLabel, String paramValue) {
      label = paramLabel;
      value = paramValue;
    }
  }
}