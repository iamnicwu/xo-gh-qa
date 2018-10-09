public without sharing class AssignmentRulesUtility {
  //////////////////////
  // STATIC VARIABLES //
  //////////////////////
  public static Map<String, Local_Sales_Rep_Assignment__c> assignmentMap;
  public static Map<Id, Id> salesRepStrategySpecialistMap;

  public static Local_Sales_Rep_Assignment__c getRecordAssignment(Lead leadRecord) {

    if(assignmentMap == null) {
      return null;
    }

    if(String.isNotBlank(leadRecord.Primary_Category__c) && String.isNotBlank(leadRecord.PostalCode) && assignmentMap.containsKey(leadRecord.PostalCode + leadRecord.Primary_Category__c)){
      return assignmentMap.get(leadRecord.PostalCode + leadRecord.Primary_Category__c);
    }else if(String.isNotBlank(leadRecord.Primary_Category__c) && String.isNotBlank(leadRecord.PostalCode) && leadRecord.CountryCode == 'US' && leadRecord.PostalCode.length() > 5 && assignmentMap.containsKey(leadRecord.PostalCode.left(5) + leadRecord.Primary_Category__c)){
      return assignmentMap.get(leadRecord.PostalCode.left(5) + leadRecord.Primary_Category__c);
    }
    //CSP-3077 Update Automation on Account to fill in Market based on the first three digits of Canadian Zip Codes
    //Add Canadian billing postal code Id for Assignment Rules Map building logic
    else if(String.isNotBlank(leadRecord.Primary_Category__c) && String.isNotBlank(leadRecord.PostalCode) && leadRecord.CountryCode == 'CA' && leadRecord.PostalCode.length() > 3 && assignmentMap.containsKey(leadRecord.PostalCode.left(3).toUpperCase() + leadRecord.Primary_Category__c)){
      return assignmentMap.get(leadRecord.PostalCode.left(3).toUpperCase() + leadRecord.Primary_Category__c);
    }else  if(String.isNotBlank(leadRecord.Primary_Category__c) && String.isNotBlank(leadRecord.Local_Sales_Market__c) && assignmentMap.containsKey(leadRecord.Local_Sales_Market__c + '' + leadRecord.Primary_Category__c)){
      return assignmentMap.get(leadRecord.Local_Sales_Market__c + '' + leadRecord.Primary_Category__c);
    }else if(String.isNotBlank(leadRecord.Primary_Category__c) && assignmentMap.containsKey(leadRecord.Primary_Category__c)){
      return assignmentMap.get(leadRecord.Primary_Category__c);
    }else if(String.isNotBlank(leadRecord.PostalCode) && assignmentMap.containsKey(leadRecord.PostalCode)){
      return assignmentMap.get(leadRecord.PostalCode);
    }else if(String.isNotBlank(leadRecord.PostalCode) && leadRecord.CountryCode == 'US' && leadRecord.PostalCode.length() > 5 && assignmentMap.containsKey(leadRecord.PostalCode.left(5))){
      return assignmentMap.get(leadRecord.PostalCode.left(5));
    //CSP-3077 Update Automation on Account to fill in Market based on the first three digits of Canadian Zip Codes
    //Add Canadian billing postal code Id for Assignment Rules Map building logic
    }else if(String.isNotBlank(leadRecord.PostalCode) && leadRecord.CountryCode == 'CA' && leadRecord.PostalCode.length() > 3 && assignmentMap.containsKey(leadRecord.PostalCode.left(3).toUpperCase())){
      return assignmentMap.get(leadRecord.PostalCode.left(3).toUpperCase());
    }else if(String.isNotBlank(leadRecord.Local_Sales_Market__c) && assignmentMap.containsKey(leadRecord.Local_Sales_Market__c)){
      return assignmentMap.get(leadRecord.Local_Sales_Market__c);
    }

    return null;
  }

  // CSP-2697 Run Assignment Rules on Accounts
  // overload the getRecordAssignment method to apply the account assignment
  public static Local_Sales_Rep_Assignment__c getRecordAssignment(Account accountRecord) {
    if(assignmentMap == null){
      return null;
    }

    if(String.isNotBlank(accountRecord.Primary_Category__c) && 
      String.isNotBlank(accountRecord.BillingPostalCode) && 
      assignmentMap.containsKey(accountRecord.BillingPostalCode + accountRecord.Primary_Category__c)){

      return assignmentMap.get(accountRecord.BillingPostalCode + accountRecord.Primary_Category__c);
    }
    else if(String.isNotBlank(accountRecord.Primary_Category__c) && 
      String.isNotBlank(accountRecord.BillingPostalCode) && 
      accountRecord.BillingCountryCode == 'US' && 
      accountRecord.BillingPostalCode.length() > 5 && 
      assignmentMap.containsKey(accountRecord.BillingPostalCode.left(5) + accountRecord.Primary_Category__c)){

      return assignmentMap.get(accountRecord.BillingPostalCode.left(5) + accountRecord.Primary_Category__c);
    }
    //CSP-3077 Update Automation on Account to fill in Market based on the first three digits of Canadian Zip Codes
    //Add Canadian billing postal code Id for Assignment Rules Map building logic
    else if(String.isNotBlank(accountRecord.Primary_Category__c) && 
      String.isNotBlank(accountRecord.BillingPostalCode) && 
      accountRecord.BillingCountryCode == 'CA' && 
      accountRecord.BillingPostalCode.length() > 3 && 
      assignmentMap.containsKey(accountRecord.BillingPostalCode.left(3).toUpperCase() + accountRecord.Primary_Category__c)){

      return assignmentMap.get(accountRecord.BillingPostalCode.left(3).toUpperCase() + accountRecord.Primary_Category__c);
    }
    else  if(String.isNotBlank(accountRecord.Primary_Category__c) && 
      String.isNotBlank(accountRecord.Local_Sales_Market__c) && 
      assignmentMap.containsKey(accountRecord.Local_Sales_Market__c + '' + accountRecord.Primary_Category__c)){

      return assignmentMap.get(accountRecord.Local_Sales_Market__c + '' + accountRecord.Primary_Category__c);
    }
    else if(String.isNotBlank(accountRecord.Primary_Category__c) && 
      assignmentMap.containsKey(accountRecord.Primary_Category__c)){

      return assignmentMap.get(accountRecord.Primary_Category__c);
    }
    else if(String.isNotBlank(accountRecord.BillingPostalCode) && 
      assignmentMap.containsKey(accountRecord.BillingPostalCode)){
      return assignmentMap.get(accountRecord.BillingPostalCode);
    }
    else if(String.isNotBlank(accountRecord.BillingPostalCode) && 
      accountRecord.BillingCountryCode == 'US' && 
      accountRecord.BillingPostalCode.length() > 5 && 
      assignmentMap.containsKey(accountRecord.BillingPostalCode.left(5))){

      return assignmentMap.get(accountRecord.BillingPostalCode.left(5));
    }
    //CSP-3077 Update Automation on Account to fill in Market based on the first three digits of Canadian Zip Codes
    //Add Canadian billing postal code Id for Assignment Rules Map building logic
    else if(String.isNotBlank(accountRecord.BillingPostalCode) && 
      accountRecord.BillingCountryCode == 'CA' && 
      accountRecord.BillingPostalCode.length() > 3 && 
      assignmentMap.containsKey(accountRecord.BillingPostalCode.left(3).toUpperCase())){

      return assignmentMap.get(accountRecord.BillingPostalCode.left(3).toUpperCase());
    }
    else if(String.isNotBlank(accountRecord.Local_Sales_Market__c) && 
      assignmentMap.containsKey(accountRecord.Local_Sales_Market__c)){
      
      return assignmentMap.get(accountRecord.Local_Sales_Market__c);
    }

    return null;
  }

  public static Local_Sales_Rep_Assignment__c getRecordAssignment(String mapKey) {
    if(String.isBlank(mapKey) || !assignmentMap.containsKey(mapKey)) {
      return null;
    }

    return assignmentMap.get(mapKey);
  }

  public static void buildAssignmentMap(List<Lead> leadRecordList) {
    if(leadRecordList == null || leadRecordList.size() < 1) {
      return;
    }

    assignmentMap = new Map<String, Local_Sales_Rep_Assignment__c>();

    Set<Id> marketIdSet = new Set<Id>();
    Set<Id> categoryIdSet = new Set<Id>();
    Set<String> zipSet = new Set<String>();

    for(Integer i = 0, length = leadRecordList.size(); i < length; i++) {
      Lead currentLead = leadRecordList[i];

      if(String.isNotBlank(currentLead.Local_Sales_Market__c)){
        marketIdSet.add(currentLead.Local_Sales_Market__c);
      }
      if(String.isNotBlank(currentLead.Primary_Category__c)){
        categoryIdSet.add(currentLead.Primary_Category__c);
      }
      if(String.isNotBlank(currentLead.PostalCode)){
        zipSet.add(currentLead.PostalCode);
        if(currentLead.PostalCode.length() > 5 && currentLead.CountryCode == 'US'){
          zipSet.add(currentLead.PostalCode.left(5));
        //CSP-3077 Update Automation on Account to fill in Market based on the first three digits of Canadian Zip Codes
        //Add Canadian billing postal code Id for Assignment Rules Map building logic
        }else if(currentLead.PostalCode.length() > 3 && currentLead.CountryCode == 'CA'){
          zipSet.add(currentLead.PostalCode.left(3).toUpperCase());
        }
      }
    }

    buildAssignmentMap(marketIdSet, categoryIdSet, zipSet);
  }

  // CSP-2697 Run Assignment Rules on Accounts
  // overload the buildAssignmentMap to enable build assignmentMap for account records
  public static void buildAssignmentMap(List<Account> accountRecordList){
    
    if(accountRecordList == null || accountRecordList.size() < 1) {
      return;
    }

    assignmentMap = new Map<String, Local_Sales_Rep_Assignment__c>();

    Set<Id> marketIdSet = new Set<Id>();
    Set<Id> categoryIdSet = new Set<Id>();
    Set<String> zipSet = new Set<String>();

    for(Integer i = 0, length = accountRecordList.size(); i < length; i++) {
      
      Account currentAccount = (Account)accountRecordList[i];

      if(String.isNotBlank(currentAccount.Local_Sales_Market__c)){
        marketIdSet.add(currentAccount.Local_Sales_Market__c);
      }
      if(String.isNotBlank(currentAccount.Primary_Category__c)){
        categoryIdSet.add(currentAccount.Primary_Category__c);
      }

      if(String.isNotBlank(currentAccount.BillingPostalCode)){
        zipSet.add(currentAccount.BillingPostalCode);

        if(currentAccount.BillingPostalCode.length() > 5 && currentAccount.BillingCountryCode == 'US'){
          zipSet.add(currentAccount.BillingPostalCode.left(5));
        //CSP-3077 Update Automation on Account to fill in Market based on the first three digits of Canadian Zip Codes
        //Add Canadian billing postal code Id for Assignment Rules Map building logic
        }else if(currentAccount.BillingPostalCode.length() > 3 && currentAccount.BillingCountryCode == 'CA'){
          zipSet.add(currentAccount.BillingPostalCode.left(3).toUpperCase());
        } 
      }
    }

    buildAssignmentMap(marketIdSet, categoryIdSet, zipSet);
  }

  public static void buildAssignmentMap(Set<Id> marketIdSet, Set<Id> categoryIdSet, Set<String> zipSet) {
    if(assignmentMap == nulL) {
      assignmentMap = new Map<String, Local_Sales_Rep_Assignment__c>();
    }

    if(salesRepStrategySpecialistMap == null) {
      salesRepStrategySpecialistMap = new Map<Id, Id>();
    }

    List<Local_Sales_Rep_Assignment__c> localAssignmentRulesList = [SELECT Id, Zip_Code__r.ZipCode__c, Sales_Rep__c, Lead_Distribution_Queue_Id__c, Sales_Rep__r.Strategy_Specialist__c, 
                                                                    Category__c, Market__c, Sales_Rep__r.Alias FROM Local_Sales_Rep_Assignment__c 
                                                                    WHERE (Sales_Rep__c != NULL OR Lead_Distribution_Queue_Id__c != NULL)
                                                                    AND ((Zip_Code__r.ZipCode__c IN: zipSet AND Category__c IN: categoryIdSet AND Market__c = null)
                                                                        OR (Market__c IN: marketIdSet AND Category__c IN: categoryIdSet AND Zip_Code__c = null)
                                                                        OR (Category__c IN: categoryIdSet AND Market__c = null and Zip_Code__c = null)
                                                                        OR (Zip_Code__r.ZipCode__c IN: zipSet AND Category__c = null and Market__c = null)
                                                                        OR (Market__c IN: marketIdSet AND Category__c = null and Zip_Code__c = null)
                                                                        OR (Sales_Rep__r.Alias = 'distacts')
                                                                        )];

    for(Integer i = 0, length = localAssignmentRulesList.size(); i < length; i++) {
      Local_Sales_Rep_Assignment__c currentAssignmentRule = localAssignmentRulesList[i];

      // CSP-2448 - Add specific user into map
      if(currentAssignmentRule.Sales_Rep__r.Alias == 'distacts') {
        assignmentMap.put(currentAssignmentRule.Sales_Rep__r.Alias, currentAssignmentRule);
        continue;
      }

      if(currentAssignmentRule.Zip_Code__c != null && currentAssignmentRule.Category__c != null && currentAssignmentRule.Market__c == null){
        assignmentMap.put(currentAssignmentRule.Zip_Code__r.ZipCode__c + currentAssignmentRule.Category__c, currentAssignmentRule);
      }else if(currentAssignmentRule.Zip_Code__c == null && currentAssignmentRule.Category__c != null && currentAssignmentRule.Market__c != null){
        assignmentMap.put(currentAssignmentRule.Market__c + '' + currentAssignmentRule.Category__c, currentAssignmentRule);
      }else if(currentAssignmentRule.Zip_Code__c == null && currentAssignmentRule.Category__c != null && currentAssignmentRule.Market__c == null){
        assignmentMap.put(currentAssignmentRule.Category__c, currentAssignmentRule);
      }else if(currentAssignmentRule.Zip_Code__c != null && currentAssignmentRule.Category__c == null && currentAssignmentRule.Market__c == null){
        assignmentMap.put(currentAssignmentRule.Zip_Code__r.ZipCode__c, currentAssignmentRule);
      }else if(currentAssignmentRule.Zip_Code__c == null && currentAssignmentRule.Category__c == null && currentAssignmentRule.Market__c != null){
        assignmentMap.put(currentAssignmentRule.Market__c, currentAssignmentRule);
      }

      if(String.isNotBlank(currentAssignmentRule.Sales_Rep__r.Strategy_Specialist__c)){
        salesRepStrategySpecialistMap.put(currentAssignmentRule.Sales_Rep__c, currentAssignmentRule.Sales_Rep__r.Strategy_Specialist__c);
      }
    }
  }
}