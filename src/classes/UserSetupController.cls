public without sharing class UserSetupController {
  //////////////////////
  // STATIC VARIABLES //
  //////////////////////
  
  //START - CSP-2866 | Outdated Information: Locals Sales Admin
  private static final String DELIMITER = '\r\n';                                               
  private static final Map<String, Local_Sales_Admin_Role_Mapping__c> LOCAL_SALES_ADMIN_ROLE_MAPPING = Local_Sales_Admin_Role_Mapping__c.getAll(); 
  //END - CSP-2866 | Outdated Information: Locals Sales Admin
  
  private static final String USER_QUERY = 'SELECT '
                                            + 'Id, '
                                            + 'Name, '
                                            + 'ManagerId, '
                                            + 'Manager.Name, '
                                            + 'ARR__c, '
                                            + 'ARR__r.Name, '
                                            + 'RSR__c, '
                                            + 'RSR__r.Name, '
                                            + 'Strategy_Specialist__c, '
                                            + 'Strategy_Specialist__r.Name, '
                                            + 'Print_Specialist__c, '
                                            + 'Print_Specialist__r.Name, '
                                            + 'SOR__c, '
                                            + 'SOR__r.Name '
                                          + ' FROM '
                                            + ' User '
                                          + ' WHERE '
                                            + '{WHERCLAUSE}';

  private static final String USER_ROLE_QUERY = 'SELECT '
                                              + 'Id, '
                                              + 'Name, '
                                              + 'UserRole.Name '
                                            + ' FROM '
                                              + ' User '
                                            + ' WHERE '
                                              + 'IsActive = true '
                                              + ' AND  '
                                              + '{WHERCLAUSE}'                                           
                                            +  ' ORDER BY '
                                              + 'UserRole.Name';                                         
  @AuraEnabled
  public static Map<String, List<RepresentativeAssignmentRulesController.PicklistOption>> getUserPicklists() {
    //START - CSP-2866 | Outdated Information: Locals Sales Admin
    Map<String,List<String>> roleKeyRoleNameMap = new Map<String,List<String>>();
    List<String> supportRoleNamesList = new List<String>();

    for(String roleKey: LOCAL_SALES_ADMIN_ROLE_MAPPING.keySet()){
      List<String> roleNameList = new List<String>();
      if(String.isNotBlank(LOCAL_SALES_ADMIN_ROLE_MAPPING.get(roleKey).Role_Name__c)){       
        for(String roleName : LOCAL_SALES_ADMIN_ROLE_MAPPING.get(roleKey).Role_Name__c.split(DELIMITER)){
            roleNameList.add(roleName.trim());
        }
        supportRoleNamesList.addAll(roleNameList);
      }  
      roleKeyRoleNameMap.put(roleKey, roleNameList);
    }
    
    String userRoleQuery = USER_ROLE_QUERY.replace('{WHERCLAUSE}', ' UserRole.Name IN :supportRoleNamesList ');
    List<User> managingUserList = Database.query(userRoleQuery);
    
    Map<String, List<RepresentativeAssignmentRulesController.PicklistOption>> userRoleOptionMap = new Map<String, List<RepresentativeAssignmentRulesController.PicklistOption>>();  
    for(String roleKey: roleKeyRoleNameMap.keySet()){
      Set<String> roleNameSet = new Set<String>(roleKeyRoleNameMap.get(roleKey));
      if(!userRoleOptionMap.containsKey(roleKey)){
        userRoleOptionMap.put(roleKey, new List<RepresentativeAssignmentRulesController.PicklistOption>());
      } 
      for(User currentUser : managingUserList){
        if(roleNameSet.contains(currentUser.UserRole.Name)){
          userRoleOptionMap.get(roleKey).add(new RepresentativeAssignmentRulesController.PicklistOption(currentUser.Name, currentUser.Id));
        }
      } 
    }
    return userRoleOptionMap;
    //END - CSP-2866 | Outdated Information: Locals Sales Admin
  }

  @AuraEnabled
  public static List<RecordAssignmentController.UpdateFailure> updateUser(User userParam) {
    if(userParam == null || String.isBlank(userParam.Id)) {
      return null;
    }

    RecordAssignmentController.UpdateFailure updateFailure = new RecordAssignmentController.UpdateFailure();
    Database.SaveResult updateResult = Database.update(userParam, false); //update userParam;
    if(updateResult.isSuccess()) {
      return new List<RecordAssignmentController.UpdateFailure>();
    }

    List<Database.Error> databaseErrorList = updateResult.getErrors();
    updateFailure.failedObject = userParam;
    for(Integer i = 0; i < databaseErrorList.size(); i++) {
      Database.Error currentError = databaseErrorList[i];
      updateFailure.errorMessageList.add(currentError.getMessage());
    }

    return new List<RecordAssignmentController.UpdateFailure>{updateFailure};
  }

  @AuraEnabled
  public static List<User> getUsers(List<String> whereClauseList) {
    if(whereClauseList == null || whereClauseList.size() < 1) {
      whereClauseList = new List<String>{'IsActive = true'};
    }

    String userQuery = USER_QUERY.replace('{WHERCLAUSE}', String.join(whereClauseList, ' AND '));

    return Database.query(userQuery);
  }
}