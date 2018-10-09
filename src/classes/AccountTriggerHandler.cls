public without sharing class AccountTriggerHandler implements XOTrigger{
    ////////////////////////////
    // STATIC FINAL VARIABLES // 
    ////////////////////////////
    //  CSP-1288
    //  Get email and phone from custom settings DefaultCBSSValues - If no values are present for that instance then
    //  a null value is returned.
    private static final DefaulCBSSValues__c CBSS_DEFAULT_VALUES = DefaulCBSSValues__c.getInstance('InvoiceTemplate'); 

    private Map<Id,Schema.RecordTypeInfo> rtMapById = Schema.SObjectType.Account.getRecordTypeInfosById();
    // Code used for leap mapping to ensure the correct record type is being assigned from Lead to Account
    private Map<String, Schema.RecordTypeInfo> rtAccountMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
    
    // NEW VALUE - Used to hold User data and mapping
    private static Map<Id, User> userMap; // CSP-3114 SIVA VANKADARU 08/23/2018

    private Boolean updateZuoraAccountCBSS = false;
    private Boolean updateZuoraAccountCreditHoldAndCustomerTypes = false;

    private Map<String,Zuora__SubscriptionProductCharge__c> subscriptionProductChargeMap  = new Map<String,Zuora__SubscriptionProductCharge__c>();//CSP-1454
    
    private List<RESTLocalStorefrontAPI.ObjectWrapper> orderFulfillmentList = new List<RESTLocalStorefrontAPI.ObjectWrapper>();
    private List<RESTLocalStorefrontAPI.ObjectWrapper> accountUpdateList = new List<RESTLocalStorefrontAPI.ObjectWrapper>();
    
    private Map<String, String> parentIdGUIDMap = new Map<String, String>();        
    private Set<Id> accountWithPrimaryContactRole = new Set<Id>();
    private static Map<Id,String> categoryMap = new Map<Id,String>();
    private static Map<Id,String> marketMap = new Map<Id,String>();
    // CSP-3077 Update Automation on Account to fill in Market based on the first three digits of Canadian Zip Codes
    // Commented this code because CANADA_MARKET_ID_STRING is deprecated
    //private static final String CANADA_MARKET_ID_STRING = System.Label.CanadaMarketId;
    //private Id canadaMarketRecordId;

    private Map<String, Lead> leadMap = new Map<String, Lead>();// CSP-965
    
    private static User userObj = [SELECT id, profile.Name FROM User WHERE id = : UserInfo.getUserId()];
    private static List<CountryZipREGEX__c> countryRegExList = [SELECT Id, Name, Active__c, CountryCode__c, RegExPattern__c FROM CountryZipREGEX__c WHERE Active__c = true];

    private Map<Id, Id> accountParentOwnerMap = new Map<Id, Id>(); // <ParentId, Parent.OwnerId> used to set the current Account's Owner field if it has a parent account and it was created or changed
    private Map<Id, Id> accountParentMap = new Map<Id, Id>(); // Used for Lead convert setting of parent
            
    // Map<Id, Opportunity> oppMap;// = new Map<Id,String>();
    private Map<String, Zip__c> zipMap = new Map<String, Zip__c>();// Key is ZipCode
    private Set<String> updatedAccountAddressIdSet = new Set<String>();
    
    
    // Set<String> userAliasSet = new Set<String>(); //commented by CSP-1110,removed all code of concierge 
    // Map<String, String> accIdWithAliasMap = new Map<String, String>();//commented by CSP-1110,removed all code of concierge
    private Set<String> accIdSet = new Set<String>();// Account Id set where account Name got updated.
    private static final OrgWideEmailAddress orgWideEmailAdd = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address = 'theknotaccounting@xogrp.com' LIMIT 1];
    private List<Messaging.SingleEmailMessage> emailsToSendList = new List<Messaging.SingleEmailMessage>();
    private Set<Id> billingAccountsToUpdateSet = new Set<Id>();// CSP-1603
    private Set<Id> ownerIdsSet = new Set<Id>();// CSP-1603
    private List<Task> taskInsertList = new List<Task>(); // CSP-1885, could potentially be used for other tasks though

    // CSP-1852 Assignment Tool Data Points
    private Map<String,String> AccountOwnerNameMap = new Map<String,String>();
    // CSP-2040 | used to update child Contact Owners when an Account Owner is updated
    private Map<Id, Id> accountIdToOwnerIdMap = new Map<Id, Id>();

    // CSP-2061 | variables used for scoring Account records
    private static final Set<String> SCORING_FIELDS_SET = LeadAndAccountScoringUtilities.getAccountScoringFieldsNameSet();
    private Set<Id> scoreAccountsIdSet = new Set<Id>();

    // CSP-2648 | used for creating/updating client billing case
    private List<Case> newCaseList = new List<Case>();
    private List<Case> updateCaseList = new List<Case>();

    // CSP-2736 ACH Returns did not create cases
    // using a list to store the client billing queue
    public static List<Group> queueList = new List<Group>();

    // CSP-2821 Selling to a Prospect
    // store all the accounts while the account status changes
    public List<Account> statusChangeAccList = new List<Account>();
    public List<Zuora__Subscription__c> activeSubsList = new List<Zuora__Subscription__c>();
    public List<Opportunity> openedOppList = new List<Opportunity>();
    public Map<Id, Boolean> accStatusValidateMap = new Map<Id, Boolean>();
    public static Set<Id> activeSubAccSet = new Set<Id>();
    public static Set<Id> openedOppSet = new Set<Id>();
    private static String deadUserId = Label.DeadUserId;
    private static String dataEnrichmentUserId = Label.DataEnrichmentUserId;
    
    // CSP-3077 Update Automation on Account to fill in Market based on the first three digits of Canadian Zip Codes
    //country label and country code map
    private static Map<String, String> countryCodeMap = new Map<String, String>();
    //state label and state code map
    private static Map<String, String> stateCodeMap = new Map<String, String>();
    //key is Market_Id__c, value is Market__c record
    private static Map<String, Market__c> canadianMarketMap = new Map<String, Market__c>();
    //key is canadian state code, value is corresponding Market Id
    private static Map<String, String> stateCodeMarketIdMap = new Map<String, String>();
    //key is canadian postal code letters, value is Canadian_Postal_Code_Market_Mapping__c record
    private static Map<String, Canadian_Postal_Code_Market_Mapping__c> canadianMarketSettingMap = new Map<String, Canadian_Postal_Code_Market_Mapping__c>();
    

    //CSP-2912 Siva 06/08/2018 BEGIN
    private static final Id distactAccountId;
    private String profileName = userObj.profile.Name;
    private String localsalesdaateamProfileid = Label.Local_Sales_Data_Team;
    
    //CSP-2906 Paid Status Across the Parent-Child Hierarchy
    // To store the account id which should be updated the flag "Need to recalculate active hierarchu"
    private Set<Id> oldParentIdSet = new Set<Id>();
    // to store the account Id whose child accounts should be updated the flag "Need to recalculate active hierarchu"
    private Set<Id> deleteAccountIdSet = new Set<Id>();
    
    // CSP-3011 Client Billing Cases exclusion for particular CBSS
    // The account ownerId set store the ownerId of the accounts which should not create client billing case
    private static Set<Id> regionNationalOwnerIdSet = new Set<Id>();

    public static boolean hasrun_bulkBefore = false; // CSP-3114 SIVA VANKADARU 08/23/2018

    static {
    List<XO_Exception__c> exceptionList = new List<XO_Exception__c>();

    try {
      for (User currentUser : [SELECT Id,Name,Alias FROM User WHERE Alias = 'distacts' AND IsActive = true]) {
        distactAccountId = currentUser.Id;
      }
      } catch (Exception e) {
          XO_Exception__c xoException = ExceptionUtility.consumeException(e, false);
          xoException.Severity__c = 'Critical';
          xoException.Failure_Area__c = 'Account Assignment Workflow Exception';
          exceptionList.add(xoException);
      }
    
    insert exceptionList;
    }
    //CSP-2912 Siva 06/08/2018 END
    
    static{
      // CSP-2736 ACH Returns did not create cases
      // retrieve client billing queue
      // queueList = [SELECT Id FROM Group WHERE DeveloperName = 'Client_Billing_Queue' AND Type = 'Queue' limit 1];

      // CSP-3011 Client Billing Cases exclusion for particular CBSS
        // query the public group and the queue, and added to the different list/set base on the developer name
      for (Group currentGroup : [SELECT Id,Type,DeveloperName,(select UserOrGroupId from GroupMembers) FROM Group WHERE DeveloperName = 'Client_Billing_Queue' OR DeveloperName = 'Regional_National_Account_Owner'] ) {
          if (currentGroup.DeveloperName == 'Client_Billing_Queue') {
              queueList.add(currentGroup);
          }
          else if (currentGroup.DeveloperName == 'Regional_National_Account_Owner' && !currentGroup.GroupMembers.isEmpty()) {
              
                for (GroupMember currentGM : currentGroup.GroupMembers) {
                    regionNationalOwnerIdSet.add(currentGM.UserOrGroupId);
                }
              
          }
      }

      // CSP-3077 Update Automation on Account to fill in Market based on the first three digits of Canadian Zip Codes
      //build country code map
      countryCodeMap.putAll(DataUtility.buildPicklistEntryMap('Account','ShippingCountryCode'));
      //build state code map
      stateCodeMap.putAll(DataUtility.buildPicklistEntryMap('Account','ShippingStateCode'));
    
    }
    /**
     * Method used to bulkify all data needed in any "before" action of a trigger.
     */
    public void bulkBefore() {
        
        // Set<Id> conciergeOppIdSet = new Set<Id>();// comment by ticket csp-1110, removed all code of the concierge
        Set<String> zipCodeSet = new Set<String>();
        Set<Id> accMarketparentIdSet = new Set<Id>();
        Set<Id> accCategoryparentIdSet = new Set<id>();
        Set<Id> accountParentIdSet = new Set<Id>();
        Set<String> dynamicsIdSet = new Set<String>();//for CSP-965
        Set<Id> userIdSet = new Set<Id>();
        Set<Id> checkAccountForPrimaryContactRoleIdSet = new Set<Id>();
        //CSP-2912 Siva 06/14/2018 BEGIN
        Set<String> zipSet = new Set<String>();
        Set<Id> categoryIdSet = new Set<Id>();
        Set<Id> marketIdSet = new Set<Id>();
        //CSP-2912 Siva 06/14/2018 END

        // CSP-3114 SIVA VANKADARU BEGIN 08/23/2018
        if (hasrun_bulkBefore == false){

            for(Account record : (List<Account>)Trigger.New) {
                ///////////////////////////////////////
                // LOCAL BEFORE INSERT BULKING LOGIC //
                ///////////////////////////////////////
                // csp-1133 this is done to make sure that we only pass records which are local
                if(rtMapById.get(record.RecordTypeId).getName().containsIgnoreCase('Local')){
                    if(String.isNotBlank(record.Local_Sales_Market__c)){
                        marketIdSet.add(record.Local_Sales_Market__c);
                    }
                    if(String.isNotBlank(record.Primary_Category__c)){
                        categoryIdSet.add(record.Primary_Category__c);
                    }
                    if(String.isNotBlank(record.BillingPostalCode)){
                        //CSP-3077 Update Automation on Account to fill in Market based on the first three digits of Canadian Zip Codes
                        //countryCode may be blank from API insert, so we need to get country code from countryCodeMap  
                        String tempBillingCountryCode = String.isNotBlank(record.BillingCountryCode)? record.BillingCountryCode : countryCodeMap.get(record.BillingCountry);

                        if(record.BillingPostalCode.length() > 5 && tempBillingCountryCode == 'US'){
                            zipSet.add(record.BillingPostalCode.left(5));
                        //CSP-3077 Update Automation on Account to fill in Market based on the first three digits of Canadian Zip Codes
                        //Add Canadian billing postal code Id for Assignment Rules Map building logic
                        }else if(record.BillingPostalCode.length() > 3 && tempBillingCountryCode == 'CA'){
                            zipSet.add(record.BillingPostalCode.left(3).toUpperCase());
                        }else{
                            //Other countries
                            zipSet.add(record.BillingPostalCode);
                        }
                    }
                }
            }
    
            //CSP-2912 Siva 06/14/2018 BEGIN
            for (Zip__c zipObj : [SELECT Id, ZipCode__c, Local_Market__c, Local_Market__r.Market_ID__c, City__c, State__c, Portfolio__c  
                                  FROM Zip__c
                                  WHERE ZipCode__c IN :zipSet ]){
                //CSP-3077 Update Automation on Account to fill in Market based on the first three digits of Canadian Zip Codes
                //Commented this code because CANADA_MARKET_ID_STRING is deprecated
                                  //OR Local_Market__r.Market_ID__c = :CANADA_MARKET_ID_STRING]) {
                
                // Add Market Id to marketSet for Assignment Rules Map building logic
                marketIdSet.add(zipObj.Local_Market__c);
                //CSP-3077 Update Automation on Account to fill in Market based on the first three digits of Canadian Zip Codes
                //Commented this code because CANADA_MARKET_ID_STRING is deprecated    
                // Set the value of the single "Canada" Market__c record Id
                /*if (zipObj.Local_Market__r.Market_ID__c == CANADA_MARKET_ID_STRING) {
                    canadaMarketRecordId = zipObj.Local_Market__c;
                    continue;
                }*/
            }
    
            if(!zipSet.isEmpty() || !categoryIdSet.isEmpty() || !marketIdSet.isEmpty()) {
                //CSP-3077 Update Automation on Account to fill in Market based on the first three digits of Canadian Zip Codes
                //Commented this code because CANADA_MARKET_ID_STRING is deprecated
                //marketIdSet.add(canadaMarketRecordId);
                AssignmentRulesUtility.buildAssignmentMap(marketIdSet, categoryIdSet, zipSet);
            }
            //CSP-2912 Siva 06/14/2018 END
        }

        hasrun_bulkBefore = true;
        // CSP-3114 SIVA VANKADARU END 08/23/2018   
        
        /////////////////////////////////
        // BEFORE INSERT BULKING LOGIC //
        /////////////////////////////////
        if(trigger.isInsert){
            Map<String, String> parentGUIDChildIdMap = new Map<String, String>(); //functionality can't be executed on before insert.
            
            for(Account accObj : (List<Account>)trigger.new){
                assignRecordType(accObj);

                //CSP-3077 Update Automation on Account to fill in Market based on the first three digits of Canadian Zip Codes
                /**
                 *  query corresponding zip records based on the first three digits of Canadian Zip Codes
                 *  Postal code allows lowercase, so we need to uppercase the first three digits to match Zip__c record
                 */  
                //countryCode may be blank from API insert, so we need to get country code from countryCodeMap  
                String tempBillingCountryCode = String.isNotBlank(accObj.BillingCountryCode)? accObj.BillingCountryCode : countryCodeMap.get(accObj.BillingCountry);
                String tempShippingCountryCode = String.isNotBlank(accObj.ShippingCountryCode)? accObj.ShippingCountryCode : countryCodeMap.get(accObj.ShippingCountry);

                if(String.isNotBlank(accObj.ShippingPostalCode)){
                    if(tempShippingCountryCode == 'US'){

                        zipCodeSet.add(accObj.ShippingPostalCode.left(5));
                    }else if(tempShippingCountryCode == 'CA'){

                        zipCodeSet.add(accObj.ShippingPostalCode.left(3).toUpperCase());
                    }else{

                        zipCodeSet.add(accObj.ShippingPostalCode);
                    }
                } 
                if(String.isNotBlank(accObj.BillingPostalCode)){
                    if(tempBillingCountryCode == 'US'){

                        zipCodeSet.add(accObj.BillingPostalCode.left(5));
                    }else if(tempBillingCountryCode == 'CA'){

                        zipCodeSet.add(accObj.BillingPostalCode.left(3).toUpperCase());
                    }else{

                        zipCodeSet.add(accObj.BillingPostalCode);
                    }
                }
                System.debug(LoggingLevel.INFO, '*** zipCodeSet: ' + zipCodeSet);
                ///////////////////////////////////////
                // LOCAL BEFORE INSERT BULKING LOGIC //
                ///////////////////////////////////////
                if(rtMapById.get(accObj.RecordTypeId).getName().containsIgnoreCase('Local')){
                    userIdSet.add(accObj.OwnerId);
                    
                    // csp-2099 assign account source hidden value to account source
                    accObj.AccountSource = accObj.AccountSourceHidden__c;

                    // CSP-1659 | adding logic for CSP-1128
                    if (accObj.Override_Account_CBSS__c) {
                        if (accObj.CBBS__c != null) {
                            userIdSet.add(accObj.CBBS__c);
                        } else {
                            accObj.Override_Account_CBSS__c = false;
                        }
                    }

                    /* functionality can't be executed on before insert.*/
                    if(String.isNotBlank(accObj.Fulfillment_Data__c)){
                        LeadPayloadWrapper.FulfillData fulfillment = (LeadPayloadWrapper.FulfillData) JSON.deserialize(accObj.Fulfillment_Data__c, LeadPayloadWrapper.FulfillData.class);
                        if(String.isNotBlank(fulfillment.parentGUID)){
                            parentGUIDChildIdMap.put(fulfillment.parentGUID, accObj.Id);
                        }
                    }

                    // Bulk Parent Account Id's
                    if(String.isNotBlank(accObj.ParentId)) {
                        accountParentIdSet.add(accObj.ParentId);
                    }

                    // Bulk Primary Category Id's
                    if(String.isNotBlank(accObj.Primary_Category__c)) {
                        accCategoryparentIdSet.add(accObj.Primary_Category__c);
                    }

                    // Bulk Local Sales Martker Id's
                    if(String.isNotBlank(accObj.Local_Sales_Market__c)) {
                        accMarketparentIdSet.add(accObj.Local_Sales_Market__c);
                    }
                    
                    // for CSP-965
                    if(String.isNotBlank(accObj.DynamicsAccID__c)) {
                        dynamicsIdSet.add(accObj.DynamicsAccID__c);
                    }
                }
            }
            if(parentGUIDChildIdMap.size() > 0){
                for(Account record : [select Id, DynamicsAccID__c from Account where DynamicsAccID__c IN : parentGUIDChildIdMap.keySet()]){
                    accountParentMap.put(parentGUIDChildIdMap.get(record.DynamicsAccID__c), record.Id);
                    accountParentIdSet.add(record.Id);
                }
            }
        }
        

        /////////////////////////////////
        // BEFORE UPDATE BULKING LOGIC //
        /////////////////////////////////
        if(trigger.isUpdate){
            system.debug(' trigger.New : ' + trigger.New );
            for(Account newAccObj : (List<Account>)trigger.New){
                Account oldAccObj = (Account)trigger.oldMap.get(newAccObj.Id);
                
                assignRecordType(newAccObj);

                // CSP-2912 BEGIN 08/07/2018 SIVA VANKADARU
                If ( newAccObj.Account_Status__c == 'Qualified' && oldAccObj.Account_Status__c != 'Qualified' && profileName == localsalesdaateamProfileid ){
                    newAccObj = accOwnerAssignment(newAccObj);
                }

                // CSP-2912 END 08/07/2018 SIVA VANKADARU
                if(newAccObj.ShippingPostalCode  != oldAccObj.ShippingPostalCode 
                || newAccObj.BillingPostalCode != oldAccObj.BillingPostalCode

                || newAccObj.ShippingCountryCode  != oldAccObj.ShippingCountryCode 
                || newAccObj.BillingCountryCode != oldAccObj.BillingCountryCode
                || newAccObj.ShippingStateCode  != oldAccObj.ShippingStateCode
                || newAccObj.BillingStateCode != oldAccObj.BillingStateCode

                || newAccObj.ShippingCountry  != oldAccObj.ShippingCountry
                || newAccObj.BillingCountry != oldAccObj.BillingCountry
                || newAccObj.ShippingState  != oldAccObj.ShippingState
                || newAccObj.BillingState != oldAccObj.BillingState){
                    // CSP-3077 Update Automation on Account to fill in Market based on the first three digits of Canadian Zip Codes
                    // country code may be not the same as country name from API update(new country name, old country code)
                    // country code may be not the same as country name from UI update(new country code, old country name)
                    String tempBillingCountryCode = newAccObj.BillingCountryCode;
                    String tempShippingCountryCode = newAccObj.ShippingCountryCode;
                    
                    if(oldAccObj.BillingCountry != newAccObj.BillingCountry){
                        tempBillingCountryCode = countryCodeMap.get(newAccObj.BillingCountry);
                    }

                    if(oldAccObj.ShippingCountry != newAccObj.ShippingCountry){
                        tempShippingCountryCode = countryCodeMap.get(newAccObj.ShippingCountry);
                    }
                    //CSP-3077 Update Automation on Account to fill in Market based on the first three digits of Canadian Zip Codes
                    //query corresponding zip records based on the first three digits of Canadian Zip Codes
                    if(String.isNotBlank(newAccObj.ShippingPostalCode)){
                        if(tempShippingCountryCode == 'US'){

                            zipCodeSet.add(newAccObj.ShippingPostalCode.left(5));
                        }else if(tempShippingCountryCode == 'CA'){

                            zipCodeSet.add(newAccObj.ShippingPostalCode.left(3).toUpperCase());
                        }else{

                            zipCodeSet.add(newAccObj.ShippingPostalCode);
                        }
                    } 

                    if(String.isNotBlank(newAccObj.BillingPostalCode)){
                        if(tempBillingCountryCode == 'US'){

                            zipCodeSet.add(newAccObj.BillingPostalCode.left(5));
                        }else if(tempBillingCountryCode == 'CA'){

                            zipCodeSet.add(newAccObj.BillingPostalCode.left(3).toUpperCase());
                        }else{
                            
                            zipCodeSet.add(newAccObj.BillingPostalCode);
                        }
                    }
                }
                ///////////////////////////////////////
                // LOCAL BEFORE UPDATE BULKING LOGIC //
                ///////////////////////////////////////
                if(rtMapById.get(newAccObj.RecordTypeId).getName().containsIgnoreCase('Local')){
                    userIdSet.add(newAccObj.OwnerId);
                    
                    // CSP-1659 | also include record.CBBS__c for CBSS overrides
                    userIdSet.add(newAccObj.CBBS__c);
                    
                    if(newAccObj.Fulfill_Storefront__c && !oldAccObj.Fulfill_Storefront__c){
                        if(String.isBlank(newAccObj.ParentId)){
                            checkAccountForPrimaryContactRoleIdSet.add(newAccObj.Id);
                        }else{
                            checkAccountForPrimaryContactRoleIdSet.add(newAccObj.ParentId);
                        }
                    }
                    
                    if(String.isNotBlank(newAccObj.ParentId) && newAccObj.ParentId != oldAccObj.ParentId){
                        accountParentIdSet.add(newAccObj.ParentId);
                    }
                    if(String.isNotBlank(newAccObj.Primary_Category__c) && newAccObj.Primary_Category__c != oldAccObj.Primary_Category__c){
                        accCategoryparentIdSet.add(newAccObj.Primary_Category__c);
                    }
                    if(String.isNotBlank(newAccObj.Local_Sales_Market__c) && newAccObj.Local_Sales_Market__c != oldAccObj.Local_Sales_Market__c){
                        accMarketparentIdSet.add(newAccObj.Local_Sales_Market__c);
                    }

                    // CSP-2821 Selling to a Prospect
                    // check if account status changes
                    if(newAccObj.account_status__c != oldAccObj.account_status__c){
                        statusChangeAccList.add(newAccObj);
                    }
                }
            }
            
            // CSP-2821 Selling to a Prospect
            // Retrieve all active subs and opened opp from this account
            if(!statusChangeAccList.isEmpty()){

                // query all active subs
                activeSubsList = [SELECT Id, Zuora__TermEndDate__c, Zuora__Account__c FROM Zuora__Subscription__c WHERE Zuora__Account__c IN: statusChangeAccList
                                    AND Zuora__TermEndDate__c >=: System.today()];

                for(Zuora__Subscription__c sub : activeSubsList){
                    // store all having active subs' account ids in a set
                    activeSubAccSet.add(sub.Zuora__Account__c);
                }

                // query all opened opps
                openedOppList = [SELECT Id, AccountId FROM Opportunity WHERE AccountId IN: statusChangeAccList AND IsClosed = FALSE];

                for(Opportunity opp : openedOppList){
                    // store all having opened opp ids in a set
                    openedOppSet.add(opp.AccountId);
                }
            }

            // CSP-1852 Assignment Tool Data Points
            // stored changed Account's owner in a map, modified it to move from for loop
            List<Account> accountChangedList = [SELECT Id, OwnerId, Owner.Name FROM Account WHERE ID IN: (List<Account>)Trigger.New];
            for(Account acc : accountChangedList){
                accountOwnerNameMap.put(acc.OwnerID, acc.Owner.Name);
            }
        }
        //CSP-3077 Update Automation on Account to fill in Market based on the first three digits of Canadian Zip Codes
        /**
         *  we need to get all canadian markets if canadian acocunt does not have a postal code or canadian postal code does not have a corresponding Zip__c record
         *  if canadian acocunt does not have a postal code, we set market based on the state code
         *  if canadian postal code does not have a corresponding Zip__c record, we set market based on the first letter of the postal code
         */   
        for(Market__c marketObj : [SELECT Id, Name, Market_ID__c FROM Market__c WHERE Country__c = 'CA']){
            canadianMarketMap.put(marketObj.Market_ID__c, marketObj);
        }
        for(Canadian_Postal_Code_Market_Mapping__c canadaMarket : Canadian_Postal_Code_Market_Mapping__c.getAll().values()) {
           canadianMarketSettingMap.put(canadaMarket.Canadian_Postal_Code__c, canadaMarket);
           //Get default market id
           if(String.isNotBlank(canadaMarket.Default_State_Code__c)) {
               stateCodeMarketIdMap.put(canadaMarket.Default_State_Code__c, canadaMarket.Market_Id__c);
           }
        }
        // CSP-1820 | combined populating the zipMap and setting the canadaMarketRecordId into a single query
        for (Zip__c zipObj : [SELECT Id, ZipCode__c, MetroArea__c, Local_Market__c, Local_Market__r.Market_ID__c
                                FROM Zip__c 
                                WHERE ZipCode__c IN :zipCodeSet ]){
            // CSP-3077 Update Automation on Account to fill in Market based on the first three digits of Canadian Zip Codes
            // Commented this code because CANADA_MARKET_ID_STRING is deprecated
                                //OR Local_Market__r.Market_ID__c = :CANADA_MARKET_ID_STRING]) {
            // Set the value of the single "Canada" Market__c record Id
            /*if (zipObj.Local_Market__r.Market_ID__c == CANADA_MARKET_ID_STRING) {
                canadaMarketRecordId = zipObj.Local_Market__c;
                continue;
            }*/
            // Otherwise populate the zipMap
            zipMap.put(zipObj.ZipCode__c, zipObj);
        }

        // For CSP-965  if account is converted from a Claimed lead, set the field "Fulfill_Storefront__c" to true, so the account can sync to Partners.
        if(dynamicsIdSet.size() > 0){
            for(Lead leadObj : [SELECT Id, Fulfill_Storefront__c, Storefront_Status__c, DynamicsLeadID__c 
                                FROM Lead 
                                WHERE DynamicsLeadID__c IN: dynamicsIdSet AND Storefront_Status__c =: 'Claimed']){
                leadMap.put(leadObj.DynamicsLeadID__c,leadObj);
            }
        }
        
        if(checkAccountForPrimaryContactRoleIdSet.size() > 0){
            for(Account accObj : [SELECT Id, 
                                    (SELECT Id, Role FROM AccountContactRoles WHERE Role = 'Primary' AND Contact.Email != null) 
                                    FROM Account WHERE Id IN: checkAccountForPrimaryContactRoleIdSet]){
                
                if(!accObj.AccountContactRoles.isEmpty()){
                    accountWithPrimaryContactRole.add(accObj.Id);
                }
            }
        }
        
        if(!accCategoryparentIdSet.isEmpty()){
            for(Category__c categoryObj : [SELECT Id, Name FROM Category__c WHERE Id IN : accCategoryparentIdSet]){
                categoryMap.put(categoryObj.Id,categoryObj.Name);
            }
        }
        
        if(!accMarketparentIdSet.isEmpty()){
            for(Market__c marketObj : [SELECT Id, Name FROM Market__c WHERE Id IN : accMarketparentIdSet]){
                marketMap.put(marketObj.Id,marketObj.name);
            }
        }
        
        if(!accountParentIdSet.isEmpty()){
            for(Account record : [select id, OwnerId from Account where Id IN : accountParentIdSet]){
                accountParentOwnerMap.put(record.Id, record.OwnerId);
                userIdSet.add(record.OwnerId);
            }
        }

        // CSP-1128, CSP-1975
        // Code refactor to use a generic userMap to store all User data for recall later
        if(userIdSet.size() > 0){
            userMap = new Map<Id, User>([SELECT Id, Name, Title, Email, Phone, ARR__c, ARR__r.Phone, ARR__r.Email, SOR__C, Strategy_Specialist__c FROM User WHERE Id IN :userIdSet]);
        } else {
            userMap = new Map<Id, User>();
        }
    }
    
    /**
     *   Method used to bulkify all data needed in any "after" action of a trigger.
     */
    public void bulkAfter() {

        if(trigger.isInsert || trigger.isUpdate){
            Set<String> accountParentIdSet = new Set<String>();
            for(SObject record : trigger.New){
                Account accObj = (Account)record;
                if(String.isNotBlank(accObj.ParentId)){
                    accountParentIdSet.add(accObj.ParentId);
                }
            }

            if(accountParentIdSet.size() > 0){
                for(Account accObj : [SELECT Id, DynamicsAccID__c FROM Account WHERE Id IN : accountParentIdSet]){
                    parentIdGUIDMap.put(accObj.Id, accObj.DynamicsAccID__c);
                }
            }
        }

        if(trigger.isUpdate){

            // For CSP-2648 client billing Case, if the account past due balance has been changed to not 0 from 0, the client billing Case will be created
            // if the account past due balance has been changed to 0 from Not 0, the client billing Case will be closed
            // if the account past due balance has been increased, the Past Due potential should be increased.
            // stored the Id of the accounts which should create a new client billing case
            Set<Id> pdbAccountIdSet = new Set<Id>();
            // stored the Id of the accounts which should close the related client billing case
            Set<Id> nonePDBAccountIdSet = new Set<Id>();
            // stored the Id and pdb increase of the accounts which should updated the related client billing case
            Map<Id, Decimal> pdbUpdateMap = new Map<Id,Decimal>();
            // CSP-2736 ACH Returns did not create cases
            // new a total Id Set for the all accounts which need to new/update/close case, so we can query the all data with one SOQL
            Set<Id> needUpdateCaseAccIdSet = new Set<Id>();
            Map<String, Schema.RecordTypeInfo> caseRecTypeNameMap = Schema.SObjectType.Case.getRecordTypeInfosByName();

            // CSP-2704 Calculating Potential for In House Collections and Past Due Retention Cases
            // Stored the Id and pdb increase of the accounts which should updated the related Cancels case
            Map<Id, Decimal> pdbIncreaseMap = new Map<Id,Decimal>();


            for(SObject record : trigger.New){
                Account newAccObj = (Account)record;
                Account oldAccObj = (Account)trigger.oldMap.get(newAccObj.Id);

                // CSP-2725 Past Due Potential Error?
                // creating two decimal value to convert all brand new past due balance to 0
                Decimal oldAccPDB = oldAccObj.Past_Due_Balance__c== null ? 0 : oldAccObj.Past_Due_Balance__c;
                Decimal newAccPDB = newAccObj.Past_Due_Balance__c== null ? 0 : newAccObj.Past_Due_Balance__c;

                
                // get the account id set which need to create a new client billing case
                // CSP-2782 Client Billing Case Open Logic
                // if the field Need_to_Create_CB_Case__c checked, created a client billing case for the account
                if (!oldAccObj.Need_to_Create_CB_Case__c && newAccObj.Need_to_Create_CB_Case__c ) {
                    // CSP-2736 ACH Returns did not create cases
                    // added the account id to the total Id set
                    needUpdateCaseAccIdSet.add(newAccObj.Id);

                    pdbAccountIdSet.add(newAccObj.Id);
                }
                // get the account id set which the exist client billing case need to close
                else if (newAccPDB == 0 && oldAccPDB > 0) {
                    // CSP-CSP-2736 ACH Returns did not create cases
                    // added the account id to the total Id set
                    needUpdateCaseAccIdSet.add(newAccObj.Id);                 

                    nonePDBAccountIdSet.add(newAccObj.Id);
                }
                // get the account id,Increased balance map, so the exist client billing case need to increased the past due potential.
                // CSP-2725 Past Due Potential Error?
                // added the filter, the past due potential increased only once the old account's past due balance is not 0, and past due balance increased.
                else if (newAccPDB > oldAccPDB && oldAccPDB != 0 ) {
                    // CSP-2736 ACH Returns did not create cases
                    // added the account id to the total Id set
                    needUpdateCaseAccIdSet.add(newAccObj.Id);

                    Decimal pdbIncreased = newAccObj.Past_Due_Balance__c - oldAccObj.Past_Due_Balance__c;
                    pdbUpdateMap.put(newAccObj.Id,pdbIncreased);
                }

                // CSP-2704 Calculating Potential for In House Collections and Past Due Retention Cases
                // Stored the Id and pdb increase of the accounts which should updated the related Cancels case
                if (newAccPDB > oldAccPDB) {
                    Decimal pdbIncreased = newAccPDB - oldAccPDB;
                    pdbIncreaseMap.put(newAccObj.Id,pdbIncreased);
                }

            }

            if (!needUpdateCaseAccIdSet.isEmpty()) {
                // CSP-2736 ACH Returns did not create cases
                // query all account which need to new/update/close case
                // CSP-2781 | Close In House Collections Cases when Past Due Balance Reaches $0
                // In House Collections cases automatically close when Account Past Due Balance goes from >$0 to =$0
                List<Account> accountList = [SELECT Id,CBBS__c, CBBS__r.Email, OwnerId, 
                                                CBBS__r.Name, Past_Due_Balance__c, 
                                                ( SELECT ContactId, AccountId 
                                                FROM AccountContactRoles 
                                                WHERE Role in ('Primary','Billing') 
                                                    AND Contact.Status__c = 'Active' 
                                                ORDER BY Role ASC, CreatedDate DESC limit 1), 
                                                (SELECT Id, Status, Outcome__c, Past_Due_Potential__c, AccountId, RecordTypeId  
                                                FROM Cases 
                                                WHERE IsClosed = FALSE 
                                                AND (RecordTypeID = :caseRecTypeNameMap.get('Client Billing').getRecordTypeId()
                                                OR RecordTypeID = :caseRecTypeNameMap.get('In House Collections').getRecordTypeId()))
                                            FROM Account 
                                            WHERE Id IN: needUpdateCaseAccIdSet AND RecordType.Name = 'Local'];

                for (Account currentAccount : accountList) {
                    // CSP-2736 ACH Returns did not create cases
                    // created new case for the account whose id is in the set pdbAccountIdSet
                    if (pdbAccountIdSet.contains(currentAccount.Id)) {
                        // CSP-3011 Client Billing Cases exclusion for particular CBSS
                        // if ( currentAccount.Cases.isEmpty()) {
                        // if there is one opened client billling case under the account, we should not create a new client billing case for the account
                        Boolean createCBCase = TRUE;
                        if (!currentAccount.Cases.isEmpty()) {
                            for (Case caseRecord : currentAccount.Cases) {
                                if (caseRecord.RecordTypeId == caseRecTypeNameMap.get('Client Billing').getRecordTypeId()) {
                                    createCBCase = FALSE;
                                }
                            }
                        }
                        // CSP-3011 Client Billing Cases exclusion for particular CBSS
                        // if the account onwerId is in the group Regional National Account Owner, we should not create client billing case for the account
                        if (!regionNationalOwnerIdSet.contains(currentAccount.OwnerId) && createCBCase) {
                            Case caseRecord = new Case();
                            caseRecord.AccountId = currentAccount.Id;
                            // if the account have primary contact, assigned the newest contact role's contact to case contact
                            if (currentAccount.AccountContactRoles.size()>0) {
                                caseRecord.ContactId = currentAccount.AccountContactRoles[0].ContactId;
                            }
                            caseRecord.RecordTypeId = caseRecTypeNameMap.get('Client Billing').getRecordTypeId();
                            caseRecord.Origin = 'Auto Generated';

                            // CSP-2736 ACH Returns did not create cases
                            // need to check if the CBSS is null, yes assign to client billing queue
                            if(currentAccount.CBBS__c != null){
                              caseRecord.OwnerId = currentAccount.CBBS__c;
                            }
                            else{
                              caseRecord.OwnerId = queueList[0].id;
                            }

                            caseRecord.Reason = 'Client Billing';
                            caseRecord.Subject = 'Client Billing';
                            caseRecord.Past_Due_Potential__c = currentAccount.Past_Due_Balance__c;
                            caseRecord.Past_Due_on_Case_Open__c = currentAccount.Past_Due_Balance__c;
                            newCaseList.add(caseRecord);
                        }
                    }
                    // CSP-2736 ACH Returns did not create cases
                    // closed the case for the account whose id is in the set nonePDBAccountIdSet        
                    else if(nonePDBAccountIdSet.contains(currentAccount.Id)){
                        if (!currentAccount.Cases.isEmpty()) {
                            for (Case currentCase : currentAccount.Cases) {
                                // CSP-2781 | Close In House Collections Cases when Past Due Balance Reaches $0
                                // In House Collections cases automatically close when Account Past Due Balance goes from >$0 to =$0
                                currentCase.Status = 'Closed';                                
                                if(currentCase.RecordTypeId == caseRecTypeNameMap.get('Client Billing').getRecordTypeId()){
                                    currentCase.Outcome__c = 'Paid';
                                }                                
                                updateCaseList.add(currentCase);
                            }
                        }
                    }
                    // CSP-2736 ACH Returns did not create cases
                    // updated the Past_Due_Potential__c of the case for the account whose id is in the set nonePDBAccountIdSet
                    else if(pdbUpdateMap.containsKey(currentAccount.Id)){
                        if (!currentAccount.Cases.isEmpty()) {
                            for (Case currentCase : currentAccount.Cases) {
                                Decimal pastDueVal = currentCase.Past_Due_Potential__c == NULL ? 0: currentCase.Past_Due_Potential__c;
                                currentCase.Past_Due_Potential__c = pastDueVal + pdbUpdateMap.get(currentAccount.Id);
                                updateCaseList.add(currentCase);
                            }
                        }
                    }
                }
            }

            // CSP-2704 Calculating Potential for In House Collections and Past Due Retention Cases
            // if the PDB of the account is increased, we should update the all opened cancel case
            if (!pdbIncreaseMap.isEmpty()) {
                String timeStamp = System.Label.Time_Stamp_For_Cancel_Case;

                List<Case> caseList = [SELECT id,Past_Due_Potential_Collections__c,AccountId,PDPC_Date_Time_Stamp__c 
                                        FROM Case 
                                        WHERE AccountId IN : pdbIncreaseMap.keySet() 
                                            AND IsClosed = FALSE 
                                            AND RecordTypeID = :caseRecTypeNameMap.get('1 - Cancels').getRecordTypeId()];
                
                for (Case currentCase : caseList) {
                    // prevent the work flow refire the logic.
                    if (currentCase.PDPC_Date_Time_Stamp__c != null && currentCase.PDPC_Date_Time_Stamp__c > system.now().addMinutes(Integer.valueOf(timeStamp))) {
                        continue;
                    }
                    Decimal pastDueVal = currentCase.Past_Due_Potential_Collections__c == NULL ? 0: currentCase.Past_Due_Potential_Collections__c;
                    currentCase.Past_Due_Potential_Collections__c = pastDueVal + pdbIncreaseMap.get(currentCase.AccountId);
                    currentCase.PDPC_Date_Time_Stamp__c = system.now();
                    updateCaseList.add(currentCase);
                }
            }
            
        }
    }
    
    /**
     *   All before insert logic should be done here. This method is called iteratively and as such
     *   should contain no actions which could potentially hit limits or is considered bad practice 
     *   in the Salesforce environment.
     *   
     *   @param  {SObject}   so Single SObject representation of the object being acted upon.
     */
    public void beforeInsert(SObject so) {
        Account accObj = (Account)so;
        assignRecordType(accObj);
        /////////////////////////
        // LOCAL ACCOUNT LOGIC //
        /////////////////////////
        if(rtMapById.get(accObj.RecordTypeId).getName().containsIgnoreCase('Local')){
            // Commented by CAN market splits go live
            // CSP-2657 Unable to Convert Canadian Leads
            // fixing the bug when lead address is CA, and unable to convert to acconut
            if(accObj.BillingCountryCode == 'CA'){

                // means shipping country code is non-CA
                if(accObj.BillingCountryCode != accObj.ShippingCountryCode){

                    // If below address fields are all empty, it should be converted
                    if(String.isBlank(accObj.ShippingStreet) && String.isBlank(accObj.ShippingCity) &&
                       String.isBlank(accObj.ShippingStateCode) && String.isBlank(accObj.ShippingPostalCode)){

                        accObj.ShippingCountryCode = accObj.BillingCountryCode;
                        accObj.ShippingStreet = accObj.BillingStreet;
                        accObj.ShippingCity = accObj.BillingCity;
                        accObj.ShippingStateCode = accObj.BillingStateCode;
                        accObj.ShippingPostalCode = accObj.BillingPostalCode;
                    }

                }
                // for handling both country code are the same
                else{
                    accObj.ShippingCountryCode = String.isBlank(accObj.Fulfillment_Data__c) && (String.isNotBlank(accObj.ShippingCountryCode)) ? accObj.ShippingCountryCode : accObj.BillingCountryCode;
                    accObj.ShippingStreet = (String.isNotBlank(accObj.ShippingStreet)) ? accObj.ShippingStreet : accObj.BillingStreet;
                    accObj.ShippingCity = (String.isNotBlank(accObj.ShippingCity)) ? accObj.ShippingCity : accObj.BillingCity;
                    accObj.ShippingStateCode = (String.isNotBlank(accObj.ShippingStateCode)) ? accObj.ShippingStateCode : accObj.BillingStateCode;
                    accObj.ShippingPostalCode = (String.isNotBlank(accObj.ShippingPostalCode)) ? accObj.ShippingPostalCode : accObj.BillingPostalCode;
                }
            }
            // for those BillingCountryCode is US, keep the logic
            else{
                accObj.ShippingCountryCode = String.isBlank(accObj.Fulfillment_Data__c) && (String.isNotBlank(accObj.ShippingCountryCode)) ? accObj.ShippingCountryCode : accObj.BillingCountryCode;
                accObj.ShippingStreet = (String.isNotBlank(accObj.ShippingStreet)) ? accObj.ShippingStreet : accObj.BillingStreet;
                accObj.ShippingCity = (String.isNotBlank(accObj.ShippingCity)) ? accObj.ShippingCity : accObj.BillingCity;
                accObj.ShippingStateCode = (String.isNotBlank(accObj.ShippingStateCode)) ? accObj.ShippingStateCode : accObj.BillingStateCode;
                accObj.ShippingPostalCode = (String.isNotBlank(accObj.ShippingPostalCode)) ? accObj.ShippingPostalCode : accObj.BillingPostalCode;
            }
           
            //CSP-3077 Update Automation on Account to fill in Market based on the first three digits of Canadian Zip Codes
            //populate country code if country code is blank but country is not blank(insert from API)
            if(String.isNotBlank(accObj.ShippingCountry) && String.isBlank(accObj.ShippingCountryCode)){
                accObj.ShippingCountryCode = countryCodeMap.get(accObj.ShippingCountry);
            }
            if(String.isNotBlank(accObj.BillingCountry) && String.isBlank(accObj.BillingCountryCode)){
                accObj.BillingCountryCode = countryCodeMap.get(accObj.BillingCountry);
            }
            //populate state code if state code is blank but state is not blank(insert from API)
            if(String.isNotBlank(accObj.ShippingState) && String.isBlank(accObj.ShippingStateCode)){
                accObj.ShippingStateCode = stateCodeMap.get(accObj.ShippingState);
            }
            if(String.isNotBlank(accObj.BillingState) && String.isBlank(accObj.BillingStateCode)){
                accObj.BillingStateCode = stateCodeMap.get(accObj.BillingState);
            }
           
            //CSP-2954: Allow Leads with incomplete (3-digit) Canadian postal codes
            validateAccountZipcode(accObj);

            // only Local need to auto assign market
            assignAccountZip(accObj);

            if(String.isNotBlank(accObj.DynamicsAccID__c) && leadMap.containsKey(accObj.DynamicsAccID__c)){
                accObj.Fulfill_Storefront__c = true;
            }

            // CSP-2544 - Phone Validation
            if(String.isNotBlank(accObj.Phone)) {
                DataUtility.ValidationResult phoneValidation = DataUtility.formatPhoneNumber(accObj.Phone);
                // If the Phone is valid then put the formatted value into the Phone field
                if(phoneValidation.valid) {
                    accObj.Phone = phoneValidation.formattedValue;
                } else {
                    accObj.Phone.addError(System.Label.Phone_Validation_Error);
                }
            }

            // CSP-2544 - extension Validation
            if(String.isNotBlank(accObj.Phone_Extension__c)){
                DataUtility.ValidationResult extValidation = DataUtility.formatExt(accObj.Phone_Extension__c);
                // If the extension is valid then put the formatted value into the Phone field
                if(extValidation.valid) {
                    accObj.Phone_Extension__c = extValidation.formattedValue;
                } 
                else {
                    accObj.Phone_Extension__c.addError(System.Label.Ext_Validation_Error);
                }
            }

            // CSP-2544 - Website Validation
            if(String.isNotBlank(accObj.Website)) {
                DataUtility.ValidationResult websiteValidation = DataUtility.validateWebsite(accObj.Website);
                // If the Website is valid put the formatted value into the Website field
                if(websiteValidation.valid) {
                    accObj.Website = websiteValidation.formattedValue;
                } else {
                    accObj.Website.addError(System.Label.Website_Validation_Error);
                }
            }

            if(String.isNotBlank(accObj.Primary_Category__c)){
                accObj.Primary_Category_Hubspot_Formula__c = categoryMap.get(accObj.Primary_Category__c);
            }
            
            if(String.isNotBlank(accObj.Local_Sales_Market__c)){
                accObj.Local_Sales_Market_Hubspot_Formula__c = marketMap.get(accObj.Local_Sales_Market__c);
            }
            
            if(!accObj.Fulfilled__c && accObj.Fulfill_Storefront__c && !LeadTriggerHandler.leadConvert && String.isBlank(accObj.DynamicsAccID__c)){
                accObj.Fulfill_Storefront__c.addError('Please add a Contact and a Primary Contact Role before you can Fulfill Storefront!');
            }
    
            if(String.isBlank(accObj.DynamicsAccID__c)){
                accObj.DynamicsAccID__c = RandomStringUtils.randomUUID();
                accObj.Salesforce_Generated_GUID__c = true;
            }
    
            if(!countryRegExList.isEmpty() && ((String.isBlank(accObj.ShippingCountryCode) && String.isNotBlank(accObj.ShippingPostalCode)) 
                    || (String.isBlank(accObj.BillingCountryCode) && String.isNotBlank(accObj.BillingPostalCode)))){
                        
                assignCountry(accObj);
            }

            // for release 3.8, added back these codes.
            if(accountParentMap.containsKey(accObj.Id)){
                accObj.ParentId = accountParentMap.get(accObj.Id);
            }

            if(String.isNotBlank(accObj.ParentId)){
                accObj.OwnerId = accountParentOwnerMap.get(accObj.ParentId);

                // CSP-2906 Paid Status Across the Parent-Child Hierarchy
                // if the account has parent, set the flag to "Yes", and then the batch will recalculated the active hierarchy
                accObj.Active_Hierarchy_Date__c = Date.today();
                accObj.Need_to_Recalculate_Active_Hierarchy__c = 'Yes';
            }else{
                // CSP-2906 Paid Status Across the Parent-Child Hierarchy
                //  if the account have no parent, set the Active_Hierarchy__c to 'Not Applicable' and the flag to "No"
                accObj.Active_Hierarchy__c = 'Not Applicable';
                accObj.Need_to_Recalculate_Active_Hierarchy__c = 'No';
                accObj.Active_Hierarchy_Date__c = Date.today();
            }
            
            ////////////////////////////////////////
            // BEGIN OWNER FIELD POPULATION LOGIC //
            ////////////////////////////////////////
            User currentOwner;
            if(userMap.containsKey(accObj.OwnerId)) {
                currentOwner = userMap.get(accObj.OwnerId);
            }

            if(currentOwner != null) {
                if(String.isBlank(accObj.Strategy_Specialist__c) && String.isNotBlank(currentOwner.Strategy_Specialist__c)){
                    accObj.Strategy_Specialist__c = currentOwner.Strategy_Specialist__c;
                }
                
                if(String.isBlank(accObj.SOR__c) && String.isNotBlank(currentOwner.SOR__c)){
                    accObj.SOR__c = currentOwner.SOR__c;
                }
                
                if(!accObj.Override_Account_CBSS__c && String.isNotBlank(currentOwner.ARR__c)){
                    accObj.CBBS__c = currentOwner.ARR__c;
                }

                // CSP-1128
                if(userMap.containsKey(accObj.CBBS__c)) {
                    User currentCBSS = userMap.get(accObj.CBBS__c);
                    if(String.isNotBlank(currentCBSS.Email) && currentCBSS.Email != accObj.CBSS_Email__c){
                        accObj.CBSS_Email__c = currentCBSS.Email;
                    } else if(CBSS_DEFAULT_VALUES != null) {
                        accObj.CBSS_Email__c = CBSS_DEFAULT_VALUES.Email__c;
                    }

                    if(String.isNotBlank(currentCBSS.Phone) && currentCBSS.Phone != accObj.CBSS_Phone__c) {
                        accObj.CBSS_Phone__c = currentCBSS.Phone;
                    } else if(CBSS_DEFAULT_VALUES != null) {
                        accObj.CBSS_Phone__c = CBSS_DEFAULT_VALUES.Phone__c;
                    }
                } else if(String.isNotBlank(currentOwner.ARR__c)) {
                    User currentCBSS = currentOwner.ARR__r;

                    if(String.isNotBlank(currentCBSS.Email) && currentCBSS.Email != accObj.CBSS_Email__c){
                        accObj.CBSS_Email__c = currentCBSS.Email;
                    } else if(CBSS_DEFAULT_VALUES != null) {
                        accObj.CBSS_Email__c = CBSS_DEFAULT_VALUES.Email__c;
                    }

                    if(String.isNotBlank(currentCBSS.Phone) && currentCBSS.Phone != accObj.CBSS_Phone__c) {
                        accObj.CBSS_Phone__c = currentCBSS.Phone;
                    } else if(CBSS_DEFAULT_VALUES != null) {
                        accObj.CBSS_Phone__c = CBSS_DEFAULT_VALUES.Phone__c;
                    }
                } else if(CBSS_DEFAULT_VALUES != null) {
                    accObj.CBSS_Email__c = CBSS_DEFAULT_VALUES.Email__c;
                    accObj.CBSS_Phone__c = CBSS_DEFAULT_VALUES.Phone__c;
                }

                // Commented by CAN market splits go live
                //CSP-3159 Last AM Transfer Date
                //Stamp date to Last AM Transfer when Account owner title is Account Manage
                if(currentOwner.Title == Label.Account_Manager) {
                    accObj.Last_AM_Transfer__c = system.today();
                }
            }
            
            // CSP-1486 | when a new record is being inserted, default the "VIP_Program_Last_Modified_Date__c" to today if the "VIP_Program__c" checkbox is checked
            if (accObj.VIP_Program__c) {
                accObj.VIP_Program_Last_Modified_Date__c = Date.today();
            }

            // CSP-1852 Assignment Tool Data Points
            // Ownership changed date will assign in record insertion
            accObj.Ownership_Changed_Date__c = System.today();
            
        }
    }
    
    /**
    *   All before update logic should be done here. This method is called iteratively and as such
    *   should contain no actions which could potentially hit limits or is considered bad practice
    *   in the Salesforce environment.
    *
    *   @param  {SObject}   oldSo Single SObject representation of the "old" copy of the current 
    *                             object being acted upon.
    *   @param  {SObject}   so    Single SObject representation of the object being acted upon.
    */
    public void beforeUpdate(SObject oldSo, SObject so) {
        Account newAccObj = (Account)so;
        Account oldAccObj = (Account)oldSo;
        
        assignRecordType(newAccObj);
        
        /////////////////////////
        // LOCAL ACCOUNT LOGIC //
        /////////////////////////
        if(rtMapById.get(newAccObj.RecordTypeId).getName().containsIgnoreCase('Local')){
            //CSP-3077 Update Automation on Account to fill in Market based on the first three digits of Canadian Zip Codes
            //populate country code if only country is changed(update from API)
            if(oldAccObj.ShippingCountryCode == newAccObj.ShippingCountryCode
            && oldAccObj.ShippingCountry != newAccObj.ShippingCountry){
                newAccObj.ShippingCountryCode = countryCodeMap.get(newAccObj.ShippingCountry);
            }
            if(oldAccObj.BillingCountryCode == newAccObj.BillingCountryCode
            && oldAccObj.BillingCountry != newAccObj.BillingCountry){
                newAccObj.BillingCountryCode = countryCodeMap.get(newAccObj.BillingCountry);
            }
            //populate state code if only state is changed(update from API)
            if(oldAccObj.ShippingStateCode == newAccObj.ShippingStateCode
            && oldAccObj.ShippingState != newAccObj.ShippingState){
                newAccObj.ShippingStateCode = stateCodeMap.get(newAccObj.ShippingState);
            }
            if(oldAccObj.BillingStateCode == newAccObj.BillingStateCode
            && oldAccObj.BillingState != newAccObj.BillingState){
                newAccObj.BillingStateCode = countryCodeMap.get(newAccObj.BillingState);
            }
        
            if(newAccObj.ShippingPostalCode  != oldAccObj.ShippingPostalCode 
            || newAccObj.BillingPostalCode != oldAccObj.BillingPostalCode 

            || newAccObj.ShippingCountryCode  != oldAccObj.ShippingCountryCode 
            || newAccObj.BillingCountryCode != oldAccObj.BillingCountryCode
            || newAccObj.BillingStateCode != oldAccObj.BillingStateCode
            || newAccObj.ShippingStateCode  != oldAccObj.ShippingStateCode

            || newAccObj.ShippingCountry  != oldAccObj.ShippingCountry
            || newAccObj.BillingCountry != oldAccObj.BillingCountry
            || newAccObj.BillingState != oldAccObj.BillingState
            || newAccObj.ShippingState  != oldAccObj.ShippingState){
                    
                //CSP-2954: Allow Leads with incomplete (3-digit) Canadian postal codes
                validateAccountZipcode(newAccObj);
                // only Local need to auto assign market
                assignAccountZip(newAccObj);
            }
            
            if(newAccObj.DynamicsAccID__c != oldAccObj.DynamicsAccID__c && newAccObj.DynamicsAccID__c != null 
                && oldAccObj.DynamicsAccID__c != null && oldAccObj.Salesforce_Generated_GUID__c){
                        
                newAccObj.Salesforce_Generated_GUID__c = false;
            }
    
            if(String.isBlank(newAccObj.DynamicsAccID__c)){
                newAccObj.DynamicsAccID__c = RandomStringUtils.randomUUID();
                newAccObj.Salesforce_Generated_GUID__c = true;
            }

            // CSP-2544 - Phone Validation
            if(String.isNotBlank(newAccObj.Phone) && !newAccObj.Phone.equalsIgnoreCase(oldAccObj.Phone)) {
                DataUtility.ValidationResult phoneValidation = DataUtility.formatPhoneNumber(newAccObj.Phone);
                // If the Phone is valid then put the formatted value into the Phone field
                if(phoneValidation.valid) {
                    newAccObj.Phone = phoneValidation.formattedValue;
                } else {
                    newAccObj.Phone.addError(System.Label.Phone_Validation_Error);
                }
            }

            // CSP-2544 - extension Validation
            if(String.isNotBlank(newAccObj.Phone_Extension__c) && !newAccObj.Phone_Extension__c.equalsIgnoreCase(oldAccObj.Phone_Extension__c)){
                DataUtility.ValidationResult extValidation = DataUtility.formatExt(newAccObj.Phone_Extension__c);
                // If the extension is valid then put the formatted value into the Phone field
                if(extValidation.valid) {
                    newAccObj.Phone_Extension__c = extValidation.formattedValue;
                } 
                else {
                    newAccObj.Phone_Extension__c.addError(System.Label.Ext_Validation_Error);
                }
            }
            
            // CSP-2544 - Website Validation
            if(String.isNotBlank(newAccObj.Website) && !newAccObj.Website.equalsIgnoreCase(oldAccObj.Website)) {
                DataUtility.ValidationResult websiteValidation = DataUtility.validateWebsite(newAccObj.Website);
                // If the Website is valid put the formatted value into the Website field
                if(websiteValidation.valid) {
                    newAccObj.Website = websiteValidation.formattedValue;
                } else {
                    newAccObj.Website.addError(System.Label.Website_Validation_Error);
                }
            }
    
            if(!countryRegExList.isEmpty() && ((String.isBlank(newAccObj.ShippingCountryCode) && String.isNotBlank(newAccObj.ShippingPostalCode)) 
                        || (String.isBlank(newAccObj.BillingCountryCode) && String.isNotBlank(newAccObj.BillingPostalCode)))){
                            
                assignCountry(newAccObj);
            }
            
            if(((newAccObj.Customer_Type__c != oldAccObj.Customer_Type__c)||(newAccObj.Credit_Hold__c != oldAccObj.Credit_Hold__c))
                    && updateZuoraAccountCreditHoldAndCustomerTypes == False) {
                        
                updateZuoraAccountCreditHoldAndCustomerTypes = True;
            }

            // Add missing code from AccountLocalTriggerHandler.cls
            if(newAccObj.Fulfill_Storefront__c && !oldAccObj.Fulfill_Storefront__c && !accountWithPrimaryContactRole.contains(newAccObj.Id) && String.isBlank(newAccObj.ParentId)){
                newAccObj.Fulfill_Storefront__c.addError('This Account needs a Primary Contact with an Email!');
            } else if(newAccObj.Fulfill_Storefront__c && !oldAccObj.Fulfill_Storefront__c && !accountWithPrimaryContactRole.contains(newAccObj.ParentId) && String.isNotBlank(newAccObj.ParentId)){
                newAccObj.Fulfill_Storefront__c.addError('This Account\'s Parent Account needs a Primary Contact with an Email!');
            }

            // CSP-953 If the parent had been changed, assigning FALSE to field Ignore_Parent_Account__c
            if(String.isNotBlank(newAccObj.ParentId) && newAccObj.ParentId != oldAccObj.ParentId){
                newAccObj.Ignore_Parent_Account__c = false;
                newAccObj.OwnerId = accountParentOwnerMap.get(newAccObj.ParentId);
            }

            //CSP-1454
            if (String.isNotBlank(newAccObj.DynamicsAccID__c) && subscriptionProductChargeMap.containsKey(newAccObj.DynamicsAccID__c)) {
                newAccObj.addError('You may not manually adjust this location\'s enrollment in the Pay Per Booking program because a Transactional subscription exists.');
            }
            
            if(String.isNotBlank(newAccObj.Primary_Category__c) && categoryMap.containsKey(newAccObj.Primary_Category__c)){
                newAccObj.Primary_Category_Hubspot_Formula__c = categoryMap.get(newAccObj.Primary_Category__c);
            }
            
            if(String.isNotBlank(newAccObj.Local_Sales_Market__c) && marketMap.containsKey(newAccObj.Local_Sales_Market__c)){
                newAccObj.Local_Sales_Market_Hubspot_Formula__c = marketMap.get(newAccObj.Local_Sales_Market__c);
            }

            ////////////////////////////////////////
            // BEGIN OWNER FIELD POPULATION LOGIC //
            ////////////////////////////////////////
            User currentOwner;
            if(userMap.containsKey(newAccObj.OwnerId)) {
                currentOwner = userMap.get(newAccObj.OwnerId);
            }

            // CSP-596 | if override isn't checked, set CBBS__c to record.Owner.ARR__c
            if(!newAccObj.Override_Account_CBSS__c && currentOwner != null) {
                // If the field Override_Account_CBSS__c had been set to FALSE from TRUE, update the CBBS__c
                if(newAccObj.Override_Account_CBSS__c != oldAccObj.Override_Account_CBSS__c) {
                    // Set the CBSS Zuora Update flag to true as the values have changed
                    updateZuoraAccountCBSS = true;
                    if(String.isNotBlank(currentOwner.ARR__c)) {
                        newAccObj.CBBS__c = currentOwner.ARR__c;
                    } else {
                        newAccObj.CBBS__c = null;
                    }
                } 
                // If account's Owner had been changed and the owner's ARR is not blank, update the CBBS__c to the Owner's ARR
                else if(String.isNotBlank(currentOwner.ARR__c) && newAccObj.CBBS__c != currentOwner.ARR__c) {
                    // Set the CBSS Zuora Update flag to true as the values have changed
                    updateZuoraAccountCBSS = true;
                    newAccObj.CBBS__c = currentOwner.ARR__c;
                }
                // If account's Owner ARR is blank null the CBSS value
                else if(String.isBlank(currentOwner.ARR__c)) {
                    // Set the CBSS Zuora Update flag to true as the values have changed
                    updateZuoraAccountCBSS = true;
                    newAccObj.CBBS__c = null;
                }
            }
    
            // CSP-1128
            if(newAccObj.CBBS__c != oldAccObj.CBBS__c) {
                // Set the CBSS Zuora Update flag to true as the values have changed
                updateZuoraAccountCBSS = true;

                if(userMap.containsKey(newAccObj.CBBS__c)) {
                    User currentCBSS = userMap.get(newAccObj.CBBS__c);
                    if(String.isNotBlank(currentCBSS.Email) && currentCBSS.Email != newAccObj.CBSS_Email__c){
                        newAccObj.CBSS_Email__c = currentCBSS.Email;
                    } else if(CBSS_DEFAULT_VALUES != null) {
                        newAccObj.CBSS_Email__c = CBSS_DEFAULT_VALUES.Email__c;
                    }

                    if(String.isNotBlank(currentCBSS.Phone) && currentCBSS.Phone != newAccObj.CBSS_Phone__c) {
                        newAccObj.CBSS_Phone__c = currentCBSS.Phone;
                    } else if(CBSS_DEFAULT_VALUES != null) {
                        newAccObj.CBSS_Phone__c = CBSS_DEFAULT_VALUES.Phone__c;
                    }
                } else if(String.isNotBlank(newAccObj.CBBS__c) && newAccObj.CBBS__c == currentOwner.ARR__c) {
                    User currentCBSS = currentOwner.ARR__r;
                    if(String.isNotBlank(currentCBSS.Email) && currentCBSS.Email != newAccObj.CBSS_Email__c){
                        newAccObj.CBSS_Email__c = currentCBSS.Email;
                    } else if(CBSS_DEFAULT_VALUES != null) {
                        newAccObj.CBSS_Email__c = CBSS_DEFAULT_VALUES.Email__c;
                    }

                    if(String.isNotBlank(currentCBSS.Phone) && currentCBSS.Phone != newAccObj.CBSS_Phone__c) {
                        newAccObj.CBSS_Phone__c = currentCBSS.Phone;
                    } else if(CBSS_DEFAULT_VALUES != null) {
                        newAccObj.CBSS_Phone__c = CBSS_DEFAULT_VALUES.Phone__c;
                    }
                } else if(CBSS_DEFAULT_VALUES != null) {
                    newAccObj.CBSS_Email__c = CBSS_DEFAULT_VALUES.Email__c;
                    newAccObj.CBSS_Phone__c = CBSS_DEFAULT_VALUES.Phone__c;
                }
            } else if(String.isBlank(newAccObj.CBBS__c) && CBSS_DEFAULT_VALUES != null) {
                /*
                    This conditional statement is just put in place to rectify any "bad" data that has gotten into a bad state
                    where the CBBS__c lookup field got blanked out somehow but never fixed.
                */

                // Set the CBSS Zuora Update flag to true as the values have changed
                updateZuoraAccountCBSS = true;

                newAccObj.CBSS_Email__c = CBSS_DEFAULT_VALUES.Email__c;
                newAccObj.CBSS_Phone__c = CBSS_DEFAULT_VALUES.Phone__c;
            }
            
            if((newAccObj.OwnerId != oldAccObj.OwnerId || String.isBlank(newAccObj.SOR__c)) && currentOwner != null
                    && String.isNotBlank(currentOwner.SOR__c)){
                        
                newAccObj.SOR__c = currentOwner.SOR__c;
            }

            if((newAccObj.OwnerId != oldAccObj.OwnerId || String.isBlank(newAccObj.Strategy_Specialist__c)) && currentOwner != null
                    && String.isNotBlank(currentOwner.Strategy_Specialist__c)) {
                        
                newAccObj.Strategy_Specialist__c = currentOwner.Strategy_Specialist__c;
            }

            // CSP-1232 update the Active_Status_Change_Date__c anytime when Local_Active__c had been changed to true from false. 
            if (newAccObj.Local_Active__c && !oldAccObj.Local_Active__c) {
                newAccObj.Active_Status_Change_Date__c = Datetime.now();
            }
            
            // CSP-1486 | if the VIP_Program__c field is being updated, update the "VIP_Program_Last_Modified_Date__c" to today
            if (newAccObj.VIP_Program__c != oldAccObj.VIP_Program__c) {
                newAccObj.VIP_Program_Last_Modified_Date__c = Date.today();
            }

            // CSP-1852 Assignment Tool Data Points
            // Assign old record owner to previous owner field, calculate the ownership age and assign to ownershipAge field
            if(newAccObj.OwnerId != oldAccObj.OwnerId){
                newAccObj.PreviousOwner__c = AccountOwnerNameMap.get(oldAccObj.OwnerID);
                newAccObj.Ownership_Changed_Date__c = System.today();
            }
            // CSP-1852 Assignment Tool Data Points
            // check if Local_Paid_Status__c is changed to Expired, if yes, then recorded the ExpirationChangedDate
            if(newAccObj.Local_Paid_Status__c != oldAccObj.Local_Paid_Status__c && 
                newAccObj.Local_Paid_Status__c == 'Expired'){
                newAccObj.Expiration_Changed_Date__c = System.today();
            }

            // CSP-2821 Selling to a Prospect
            // account status change logic
            accountStatusChangeValidation(newAccObj, oldAccObj);

            // CSP-2906 Paid Status Across the Parent-Child Hierarchy
            // if the parent has been changed, set the flag to "Yes"
            if (newAccObj.ParentId != oldAccObj.ParentId) {

                newAccObj.Active_Hierarchy_Date__c = Date.today();
                newAccObj.Need_to_Recalculate_Active_Hierarchy__c = 'Yes';
            }
            
            // if the account status has been changed to 'Active' or changed from 'Active', set the flag to "Yes"
            if (newAccObj.Account_Status__c != oldAccObj.Account_Status__c 
                && (newAccObj.Account_Status__c == 'Active' || oldAccObj.Account_Status__c == 'Active')) {
                
                newAccObj.Active_Hierarchy_Date__c = Date.today();
                newAccObj.Need_to_Recalculate_Active_Hierarchy__c = 'Yes';
            }

            // Commented by CAN market splits go live
            //CSP-3159 Last AM Transfer Date
            //Stamp date to Last AM Transfer when Account owner title is Account Manage
            if(newAccObj.OwnerId != oldAccObj.OwnerId && userMap.containsKey(newAccObj.OwnerId)) {
                currentOwner = userMap.get(newAccObj.OwnerId);
               
                if(currentOwner != null && currentOwner.Title == Label.Account_Manager) {
                    newAccObj.Last_AM_Transfer__c = system.today();
                }
            }
        }
    }
    
    /**
    *   All before delete logic should be done here. This method is called iteratively and as such
    *   should contain no actions which could potentilly hit limits or is considered bad practice
    *   in the Salesforce environment.
    *
    *   @param  {SObject}   so Single SObject representation of the object being acted upon.
    */
    public void beforeDelete(SObject so) {
        // CSP-2906 Paid Status Across the Parent-Child Hierarchy
        // if the account has been deleted, we should set the all child account's flag "Need to recalculate active hierarchy" to Yes
        Account accObj = (Account)so;
        deleteAccountIdSet.add(accObj.Id);
    }

    /**
    *   All after insert logic should be done here. This method is called iteratively and as such
    *   should contain no actions which could potentilly hit limits or is considered bad practice
    *   in the Salesforce environment. 
    *
    *   @param  {SObject}   so Single SObject representation of the object being acted upon.
    */
    public void afterInsert(SObject so) {
        Account accountObj = (Account)so;
        if(String.isNotBlank(accountObj.DynamicsAccID__c) && accountObj.Fulfill_Storefront__c && XOGroupSettingUtility.getPartnerCalloutSetting()){
            RESTLocalStorefrontAPI.ObjectWrapper objWrapper = new RESTLocalStorefrontAPI.ObjectWrapper();
            objWrapper.locationId = accountObj.DynamicsAccID__c;
            if(String.isBlank(accountObj.ParentId) || accountObj.Ignore_Parent_Account__c == true){
                objWrapper.companyId = accountObj.DynamicsAccID__c;
            }else if(String.isNotBlank(accountObj.ParentId) && parentIdGUIDMap.containsKey(accountObj.ParentId)){
                objWrapper.companyId = parentIdGUIDMap.get(accountObj.ParentId);
            }else if(String.isNotBlank(accountObj.ParentId) && !parentIdGUIDMap.containsKey(accountObj.ParentId)){
                accountObj.ParentId.addError('Please generate a GUID for the parent Account');
            }
            orderFulfillmentList.add(objWrapper);
        }
        // CSP-1885 | if the Account's "VIP Program" formula checkbox is set to true and the Account's
        // "Strategy Specialist" lookup is populated, assign a notification Task to the Strategy Specialist
        if (accountObj.VIP_Program__c && accountObj.Strategy_Specialist__c != null) {
         taskInsertList.add(generateAccountVIPStatusTask(accountObj, true));
        }

        if (rtMapById.get(accountObj.RecordTypeId).getName().containsIgnoreCase('Local')) {
            // CSP-2061 | add new Local Accounts to the scoreAccountsIdSet to later score
            scoreAccountsIdSet.add(accountObj.Id);
        }
    }
    
    /**
    *   All after update logic should be done here. This method is called iteratively and as such
    *   should contain no actions which could potentilly hit limits or is considered bad practice
    *   in the Salesforce environment.
    *   
    *   @param  {SObject}   oldSo Single SObject representation of the "old" copy of the current 
    *                             object being acted upon.
    *   @param  {SObject}   so    Single SObject representation of the object being acted upon.
    */
    public void afterUpdate(SObject oldSo, SObject so) {
        Account newAccObj = (Account)so;
        Account oldAccObj = (Account)oldSo;
        
        if (newAccObj.BillingStreet != oldAccObj.BillingStreet
            || newAccObj.BillingCity != oldAccObj.BillingCity
            || newAccObj.BillingState != oldAccObj.BillingState
            || newAccObj.BillingPostalCode != oldAccObj.BillingPostalCode
            || newAccObj.BillingCountry != oldAccObj.BillingCountry)
        {
            updatedAccountAddressIdSet.add(newAccObj.Id);
        }
        
        if(rtMapById.get(newAccObj.RecordTypeId).getName().containsIgnoreCase('Local')){
            if(String.isBlank(newAccObj.ParentId) && newAccObj.OwnerId != oldAccObj.OwnerId){
                accountParentOwnerMap.put(newAccObj.Id, newAccObj.OwnerId);
            }
    
            if(newAccObj != oldAccObj && !RequestStorefrontRepublishController.requestFulfillRunning && XOGroupSettingUtility.getPartnerCalloutSetting()){
                if(newAccObj.Ignore_Parent_Account__c && !oldAccObj.Ignore_Parent_Account__c && newAccObj.Fulfill_Storefront__c){
                    RESTLocalStorefrontAPI.ObjectWrapper objWrapper = new RESTLocalStorefrontAPI.ObjectWrapper();
                    objWrapper.locationId = newAccObj.DynamicsAccID__c;
                    objWrapper.companyId = newAccObj.DynamicsAccID__c;
                    orderFulfillmentList.add(objWrapper);
                //}else if(newAccObj.Fulfill_Storefront__c && !oldAccObj.Fulfill_Storefront__c && !newAccObj.Fulfilled__c){
                }else if(newAccObj.Fulfill_Storefront__c && !oldAccObj.Fulfill_Storefront__c && newAccObj.Storefront_Status__c != 'Claimed'){
                    RESTLocalStorefrontAPI.ObjectWrapper objWrapper = new RESTLocalStorefrontAPI.ObjectWrapper();
                    objWrapper.locationId = newAccObj.DynamicsAccID__c;
                    if(String.isBlank(newAccObj.ParentId) || newAccObj.Ignore_Parent_Account__c == true){
                        objWrapper.companyId = newAccObj.DynamicsAccID__c;
                    }else if(String.isNotBlank(newAccObj.ParentId) && parentIdGUIDMap.containsKey(newAccObj.ParentId)){
                        objWrapper.companyId = parentIdGUIDMap.get(newAccObj.ParentId);
                    }else if(String.isNotBlank(newAccObj.ParentId) && !parentIdGUIDMap.containsKey(newAccObj.ParentId)){
                        newAccObj.ParentId.addError('Please generate a GUID for the parent Account');
                    }
                    orderFulfillmentList.add(objWrapper);
                } else if(newAccObj.Fulfilled__c && newAccObj.Storefront_Status__c == 'Claimed' && String.isBlank(newAccObj.ParentId)){
                    // CSP-1997 Modify Account Partner Update Fields to be Fieldset
                    List<String> fulfillmentFieldAcctChangeValidateList = new List<String>();
                    Map<String, Schema.FieldSet> accountFieldSets = Schema.SObjectType.Account.fieldSets.getMap();
                    if (accountFieldSets.containsKey('Fulfillment_Field_Validation')) {
                        List<Schema.FieldSetMember> fsmList = accountFieldSets.get('Fulfillment_Field_Validation').getfields();
                        for(Schema.FieldSetMember fs : fsmList ){
                            fulfillmentFieldAcctChangeValidateList.add(fs.getFieldPath());
                        }
                        for(String field : fulfillmentFieldAcctChangeValidateList){
                            if(newAccObj.get(field) != oldAccObj.get(field)){
                                if(String.isNotBlank(newAccObj.DynamicsAccID__c)){
                                    RESTLocalStorefrontAPI.ObjectWrapper objWrapper = new RESTLocalStorefrontAPI.ObjectWrapper();
                                    objWrapper.locationId = newAccObj.DynamicsAccID__c;
                                    
                                    if(String.isBlank(newAccObj.ParentId) || newAccObj.Ignore_Parent_Account__c == true){
                                        objWrapper.companyId = newAccObj.DynamicsAccID__c;
                                    }else if(String.isNotBlank(newAccObj.ParentId) && parentIdGUIDMap.containsKey(newAccObj.ParentId)){
                                        objWrapper.companyId = parentIdGUIDMap.get(newAccObj.ParentId);
                                    }else if(String.isNotBlank(newAccObj.ParentId) && !parentIdGUIDMap.containsKey(newAccObj.ParentId)){
                                        newAccObj.ParentId.addError('Please generate a GUID for the parent Account');
                                    }
                                    accountUpdateList.add(objWrapper);
                                }
                                break;
                            }
                        }
                    }
                }
            }

            // CSP-1400 use equals() instead of "!=" in Account Name Comparison 
            if(!newAccObj.Name.equals(oldAccObj.Name)){
                accIdSet.add(newAccObj.id);
            }

            // csp-1603
            // CSP-1400 use equals() instead of "!=" in Account Name Comparison 
            if(newAccObj.OwnerId != oldAccObj.ownerId || !newAccObj.Name.equals(oldAccObj.Name)) {
                billingAccountsToUpdateSet.add(newAccObj.Id);
                ownerIdsSet.add(newAccObj.OwnerId);
            }

            // CSP-1885 | if the Account's "VIP Program" formula checkbox is updated and the Account's
            // "Strategy Specialist" lookup is populated, assign a notification Task to the Strategy Specialist
            if (newAccObj.VIP_Program__c != oldAccObj.VIP_Program__c && newAccObj.Strategy_Specialist__c != null) {
             taskInsertList.add(generateAccountVIPStatusTask(newAccObj, newAccObj.VIP_Program__c));
            }

            // CSP-2040 | used to update child Contact Owners when an Account Owner is updated
            if (newAccObj.OwnerId != oldAccObj.OwnerId) {
                accountIdToOwnerIdMap.put(newAccObj.Id, newAccObj.OwnerId);
            }

            // CSP-2061 | compare field values to see if any have been updated; if so, the Account's score needs to be re-evaluated
            for (String scoringField : SCORING_FIELDS_SET) {
                // Note: as of 4-11-17 we are only doing comparisons against text fields
                String oldFieldValue = (String)oldAccObj.get(scoringField);
                String newFieldValue = (String)newAccObj.get(scoringField);
                if (oldFieldValue != newFieldValue) {
                    scoreAccountsIdSet.add(newAccObj.Id);
                    break;
                }
            }
            // Csp-2906 Paid Status Across the Parent-Child Hierarchy
            // the ole parent account should be update the flag "Need to recalculate active hierarchy" to Yes
            if (newAccObj.ParentId != oldAccObj.ParentId && String.isNotBlank(oldAccObj.ParentId)) {
                oldParentIdSet.add(oldAccObj.ParentId);
            }
        }
    }

    /**
    *   All after delete logic should be done here. This method is called iteratively and as such
    *   should contain no actions which could potentilly hit limits or is considered bad practice
    *   in the Salesforce environment. 
    *
    *   @param  {SObject}   so Single SObject representation of the object being acted upon.
    */
    public void afterDelete(SObject so) {
        // CSP-2906 Paid Status Across the Parent-Child Hierarchy
        // if the account has been deleted, we should set the parent's flag "Need to recalculate active hierarchy" to Yes
        Account oldAccObj = (Account)so;
        if (String.isNotBlank(oldAccObj.ParentId)) {
            oldParentIdSet.add(oldAccObj.ParentId);
        }
    }

    /**
    *   All final logic in the "before" context should be done at this point such as modification to objects outside of
    *   the current object. At this point all updates to the current trigger transaction should be
    *   complete and all validation done.
    */
    public void beforeAndFinally() {
        // CSP-2906 Paid Status Across the Parent-Child Hierarchy
        // if the account has been deleted, we should set the parent's flag "Need to recalculate active hierarchy" to Yes
        if (!deleteAccountIdSet.isEmpty()) {
            List<Account> childAccList = [SELECT Id,Active_Hierarchy_Date__c,Need_to_Recalculate_Active_Hierarchy__c FROM Account WHERE ParentId IN: deleteAccountIdSet];
            for (Account childAcc : childAccList) {
                childAcc.Active_Hierarchy_Date__c = Date.today();
                childAcc.Need_to_Recalculate_Active_Hierarchy__c = 'Yes';
            }

            if (!childAccList.isEmpty()) {
                List<Database.SaveResult> updateResults = Database.update(childAccList,false);
                List<XO_Exception__C> exceptionList = ExceptionUtility.consumeException(updateResults);
                if(!exceptionList.isEmpty()){
                    insert exceptionList;
                }
            }
        }


        // CSP-1659 | run BatchZuoraDataUpdater job if needed
        if (!System.isBatch() && !System.isFuture() && !Test.isRunningTest() && (updateZuoraAccountCreditHoldAndCustomerTypes || updateZuoraAccountCBSS)) {
            Set<String> asyncJobInProgressStatusSet = new Set<String>{'Holding', 'Queued', 'Preparing', 'Processing'};
            Integer runningBatchZuoraDataUpdaterJobCount = [SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = 'BatchZuoraDataUpdater' AND Status IN :asyncJobInProgressStatusSet LIMIT 1];
            if (runningBatchZuoraDataUpdaterJobCount == 0) {
                Database.executebatch(new BatchZuoraDataUpdater());
            }
        }
    }
    
    /**
    *   All final logic in the "after" context should be done at this point such as modification to objects outside of
    *   the current object. At this point all updates to the current trigger transaction should be
    *   complete and all validation done.
    */
    public void afterAndFinally() {
        List<XO_Exception__C> xoExceptionList = new List<XO_Exception__C>();

        // CSP-2040 | update child Contact Owners when an Account Owner is updated
        // NOTE: queueable execution context causes both System.isBatch() and System.isQueueable() to return true,
        // but future jobs can be called from a queueable, hence the complicated IF statement below
        if (accountIdToOwnerIdMap.size() > 0 && !System.isFuture() && (!System.isBatch() || System.isQueueable())) {
            updateAccountContactsOwner(accountIdToOwnerIdMap);
        }
        
        //csp-1603 getting the owners name so that it can be assigned to Sales rep name
        Map<Id, String> idToOwnerMap = new Map<Id, String>();
        for(User userRecord: [Select Id,Name from User where Id IN: ownerIdsSet]) {
            idToOwnerMap.put(userRecord.id, userRecord.Name);
        }
        List<Zuora__CustomerAccount__c> customerAccountsToBeUpdated = new List<Zuora__CustomerAccount__c>();
        // looping through the billing accounts and update the sales rep name based on the changes made to owners account
        for(Zuora__CustomerAccount__c customerAccountRecord : [SELECT id,name, Zuora__Account__r.ownerId, Zuora__Account__c,Zuora__Account__r.Name from Zuora__CustomerAccount__c where Zuora__Account__c in : billingAccountsToUpdateSet]) {
            customerAccountRecord.Name = customerAccountRecord.Zuora__Account__r.Name;
            customerAccountRecord.Zuora__SalesRepName__c = idToOwnerMap.get(customerAccountRecord.Zuora__Account__r.ownerId);
            customerAccountRecord.NeedToUpdateAccountDetails__c = true;
            customerAccountsToBeUpdated.add(customerAccountRecord);
        }

        if(trigger.isUpdate) {
            if(customerAccountsToBeUpdated.size() > 0) {
                // update customerAccountsToBeUpdated;
                Database.SaveResult[] updateResults = Database.update(customerAccountsToBeUpdated, false);
                List<XO_Exception__C> exceptionList = ExceptionUtility.consumeException(updateResults);
                if(exceptionList != null && exceptionList.Size() > 0){
                    xoExceptionList.addAll(exceptionList);
                }
            }
        }

        if(updatedAccountAddressIdSet.size() > 0){
            List<Contact> contactUpdateList = updateContactAddress(updatedAccountAddressIdSet);
            
            if(contactUpdateList != null && contactUpdateList.size() > 0){
                Database.SaveResult[] updateResults = Database.update(contactUpdateList, false);
                List<XO_Exception__C> exceptionList = ExceptionUtility.consumeException(updateResults);
                if(exceptionList != null && exceptionList.Size() > 0){
                    xoExceptionList.addAll(exceptionList);
                }
            }
        }
        
        System.debug(LoggingLevel.INFO, '*** orderFulfillmentList: ' + orderFulfillmentList);
        if(!orderFulfillmentList.isEmpty() && !system.isBatch() && !system.isFuture() && XOGroupSettingUtility.getPartnerCalloutSetting()){
            PartnerCallouts.partnerOrderCallout(JSON.serializePretty(orderFulfillmentList));
        }
        
        System.debug(LoggingLevel.INFO, '*** accountUpdateList: ' + accountUpdateList);
        if(!accountUpdateList.isEmpty() && !system.isBatch() && !system.isFuture() && XOGroupSettingUtility.getPartnerCalloutSetting()){
            PartnerAccountUpdateCallout.accountUpdateCallout(JSON.serializePretty(accountUpdateList));
        }
        
        if(trigger.isAfter && trigger.isUpdate && !accountParentOwnerMap.isEmpty()){
            List<Account> childAccountToUpdate = updateChildAccountOwners();
            
            if(childAccountToUpdate != null && childAccountToUpdate.size() > 0){
                Database.SaveResult[] updateResults = Database.update(childAccountToUpdate, false);
                List<XO_Exception__C> exceptionList = ExceptionUtility.consumeException(updateResults);
                if(exceptionList != null && exceptionList.Size() > 0){
                    xoExceptionList.addAll(exceptionList);
                }
            }
        }
        
        if(accIdSet.size() > 0 && !System.isQueueable()){
            List<Zuora__CustomerAccount__c> billingAccountsTobeUpdateList = updateBillingAccountNames(accIdSet);
            
            if(billingAccountsTobeUpdateList != null && billingAccountsTobeUpdateList.size() > 0){
                Database.SaveResult[] updateResults = Database.update(billingAccountsTobeUpdateList, false);
                List<XO_Exception__C> exceptionList = ExceptionUtility.consumeException(updateResults);
                if(exceptionList != null && exceptionList.Size() > 0){
                    xoExceptionList.addAll(exceptionList);
                }
            }
        }

        if (taskInsertList.size() > 0) {
            Database.insert(taskInsertList, false);
        }

        // CSP-2648, insert/update/close the client billing case
        if (!newCaseList.isEmpty()) {
            Database.SaveResult[] insertResults = Database.insert(newCaseList, false);
            List<XO_Exception__C> exceptionList = ExceptionUtility.consumeException(insertResults);
            if(exceptionList != null && exceptionList.Size() > 0){
                xoExceptionList.addAll(exceptionList);
            }
        }
        if (!updateCaseList.isEmpty()) {
            Database.SaveResult[] saveResults = Database.update(updateCaseList, false);
            List<XO_Exception__C> exceptionList = ExceptionUtility.consumeException(saveResults);
            if(exceptionList != null && exceptionList.Size() > 0){
                xoExceptionList.addAll(exceptionList);
            }
        }

        // CSP-2906 Paid Status Across the Parent-Child Hierarchy
        // if oldParentIdSet is not empty, we should set the all parent account's flag to 'Yes' 
        if (!oldParentIdSet.isEmpty()) {
            List<Account> parentAccList = new List<Account>();
            for (Id accId : oldParentIdSet) {
                Account parentAcc = new Account();
                parentAcc.Id = accId;
                parentAcc.Active_Hierarchy_Date__c = Date.today();
                parentAcc.Need_to_Recalculate_Active_Hierarchy__c = 'Yes';
                parentAccList.add(parentAcc);
            }

            if (!parentAccList.isEmpty()) {
                Database.SaveResult[] saveResults = Database.update(parentAccList, false);
                List<XO_Exception__C> exceptionList = ExceptionUtility.consumeException(saveResults);
                if(exceptionList != null && exceptionList.Size() > 0){
                    xoExceptionList.addAll(exceptionList);
                }
            }
        }

        if(xoExceptionList.size() > 0){
            insert xoExceptionList;
        }

        // CSP-2061 | score Accounts asynchronously since it's a long-running operation
        if (!scoreAccountsIdSet.isEmpty() && !System.isBatch() && !System.isFuture()) {
            LeadAndAccountScoringUtilities.scoreAccountsFutureJob(scoreAccountsIdSet);
        }
    }
    
    /**
     *@description: update RecordType for the account.
     *
     *
     */
    private void assignRecordType(Account accObj){
        if(String.isNotBlank(accObj.Record_Type_Name__c) && rtAccountMapByName.containsKey(accObj.Record_Type_Name__c)) {
            Schema.RecordTypeInfo currentRecordTypeSchema = rtAccountMapByName.get(accObj.Record_Type_Name__c);
            accObj.RecordTypeId = currentRecordTypeSchema.getRecordTypeId();
        }
    }
    /**
     *@description: update contact Mailing Address with related Account Billling address.
     *
     *
     */
    private List<Contact> updateContactAddress(Set<String> accountIdSet){
        List<Contact> contactUpdateList = new List<Contact>();
        if (accountIdSet.size() > 0){
            contactUpdateList = [SELECT Id, MailingStreet, MailingCity,  MailingState, MailingPostalCode, MailingCountry, AccountId,
                                        Account.BillingCity, Account.BillingStreet, Account.BillingState, Account.BillingPostalCode, Account.BillingCountry 
                                 FROM Contact 
                                 WHERE AccountId IN :accountIdSet AND Same_Address_as_Account__c = true];
        
            if(contactUpdateList != null && contactUpdateList.size() > 0){
                for (Contact conObj : contactUpdateList){
                    conObj.MailingStreet = conObj.Account.BillingStreet;
                    conObj.MailingCity = conObj.Account.BillingCity;
                    conObj.MailingState = conObj.Account.BillingState;
                    conObj.MailingPostalCode = conObj.Account.BillingPostalCode;
                    conObj.MailingCountry = conObj.Account.BillingCountry;
                }
            }           
        }
        return contactUpdateList;
    }
    
    
    /**
     *@description: update zip, Local Sales Market on Account based on zip code.
     *
     *
     */
    private void assignAccountZip(Account acc){
        /**
         * CPS-3077 Update Automation on Account to fill in Market based on the first three digits of Canadian Zip Codes
         * Account postal code allows lowercase and the zipcode of Zip__c record is uppercase
         * CA Local_Sales_Market__c value assignments
         * so we need to uppercase the first three digits to match Zip__c record because canadian postal code contains alphabet
         * US Local_Sales_Market__c value assignments
         * we do not need to uppercase the first five digits of US postal code because US postal code is numeric
         */
        String billingPostalCodeCA = (String.isNotBlank(acc.BillingPostalCode))? acc.BillingPostalCode.left(3).toUpperCase() : acc.BillingPostalCode;
        String shippingPostalCodeCA = (String.isNotBlank(acc.ShippingPostalCode))? acc.ShippingPostalCode.left(3).toUpperCase() : acc.ShippingPostalCode;
        //Shipping is preferred
        //If shipping postal code has a corresponding Zip__c record directly regardless of the shipping country
        if(String.isNotBlank(acc.ShippingPostalCode) && zipMap != null && zipMap.containsKey(acc.ShippingPostalCode)){
            
            acc.Local_Sales_Market__c = zipMap.get(acc.ShippingPostalCode).Local_Market__c;
        //If shipping country is United States,  we use the first five digits of shipping postal code to match Zip__c record
        }else if(acc.ShippingCountryCode == 'US' && String.isNotBlank(acc.ShippingPostalCode) 
            && zipMap != null && zipMap.containsKey(acc.ShippingPostalCode.left(5))){
              
            acc.Local_Sales_Market__c = zipMap.get(acc.ShippingPostalCode.left(5)).Local_Market__c;
        //If shipping country is Canada, we use the first three uppercase digits of shipping postal code to match Zip__c record
        }else if(acc.ShippingCountryCode == 'CA' && String.isNotBlank(shippingPostalCodeCA) 
            && zipMap != null && zipMap.containsKey(shippingPostalCodeCA)){
            
            acc.Local_Sales_Market__c = zipMap.get(shippingPostalCodeCA).Local_Market__c;
        //If shipping country is Canada, shipping postal code does not have a corresponding Zip__c record or shipping postal code is blank
        }else if(acc.ShippingCountryCode == 'CA'){
            
            //If shipping postal code does not have a corresponding Zip__c record, we use the first letter to get a corresponding market__c record
            //If we do not have a shipping postal code, we use shipping state to get a corresponding market__c record
            Market__c canadianMarket = DataUtility.getDefaultCanadaMarket(shippingPostalCodeCA, acc.ShippingStateCode, canadianMarketMap, canadianMarketSettingMap, stateCodeMarketIdMap);
            if(canadianMarket != null){ 
                acc.Local_Sales_Market__c = canadianMarket.Id;
            }
        }
        //If shipping postal code is blank, we use billing postal code
        //If billing postal code has a corresponding Zip__c record directly regardless of the billing country
        else if(String.isBlank(acc.ShippingPostalCode) && String.isNotBlank(acc.BillingPostalCode) 
               && zipMap != null && zipMap.containsKey(acc.BillingPostalCode)){
                   
            acc.Local_Sales_Market__c = zipMap.get(acc.BillingPostalCode).Local_Market__c;
        //If billing country is United States,  we use the first five digits of billing postal code to match Zip__c record
        }else if(String.isBlank(acc.ShippingPostalCode) && acc.BillingCountryCode == 'US' && String.isNotBlank(acc.BillingPostalCode) 
                && zipMap != null && zipMap.containsKey(acc.BillingPostalCode.left(5))){
                    
            acc.Local_Sales_Market__c = zipMap.get(acc.BillingPostalCode.left(5)).Local_Market__c;
        //If billing country is Canada, we use the first three uppercase digits of billing postal code to match Zip__c record
        }else if(String.isBlank(acc.ShippingPostalCode) && acc.BillingCountryCode == 'CA' && String.isNotBlank(billingPostalCodeCA) 
                && zipMap != null && zipMap.containsKey(billingPostalCodeCA)){
                
            acc.Local_Sales_Market__c = zipMap.get(billingPostalCodeCA).Local_Market__c;
        //If billing country is Canada, billing postal code does not have a corresponding Zip__c record or billing postal code is blank
        }else if(String.isBlank(acc.ShippingPostalCode) && acc.BillingCountryCode == 'CA'){
            
            //If billing postal code does not have a corresponding Zip__c record, we use the first letter to get a corresponding market__c record
            //If we do not have a billing postal code, we use billing state to get a corresponding market__c record
            Market__c canadianMarket = DataUtility.getDefaultCanadaMarket(billingPostalCodeCA, acc.BillingStateCode, canadianMarketMap, canadianMarketSettingMap, stateCodeMarketIdMap);
            if(canadianMarket != null){
                acc.Local_Sales_Market__c = canadianMarket.Id;
            }
        }

        // Zip__c value assignment
        // CSP-2838 Base Portfolio & Marketplace Health on Billing Zip
        // Zip__c value assign by Billing Postal Code
        if(String.isNotBlank(acc.BillingPostalCode)){
            
            if(acc.BillingCountryCode == 'US' &&  zipMap != null && zipMap.containsKey(acc.BillingPostalCode.left(5))){

                acc.Zip__c = zipMap.get(acc.BillingPostalCode.left(5)).Id;
            //CPS-3077 Update Automation on Account to fill in Market based on the first three digits of Canadian Zip Codes
            //Follow the same business logic as US Zip__c assignment， we set Zip__c value based on billing postal code
            }else if(acc.BillingCountryCode == 'CA' && zipMap != null && zipMap.containsKey(billingPostalCodeCA)){

                acc.Zip__c = zipMap.get(billingPostalCodeCA).Id;
            }
        }else{
            acc.Zip__c = null;
        }
    }
    
  /**
   * Check if record has valid and complete postal codes
   * @Author Steven Shen
   * @Date   2018-08-27
   * @param  record the account record
   */
    private void validateAccountZipcode(Account record){        
        if(String.isNotBlank(record.ShippingCountryCode) && String.isNotBlank(record.ShippingPostalCode)){
            //CSP-2954: Allow Leads with incomplete (3-digit) Canadian postal codes
            //Account must have complete zip for Canada            
            if(!XOCustomValidationUtility.hasCompleteCanadianZip(record.ShippingCountryCode, record.ShippingPostalCode) ){
                record.ShippingPostalCode.addError('6-digit postal code is required for the selected Country');
            }
            
            if(!XOCustomValidationUtility.validZip(record.ShippingCountryCode, record.ShippingPostalCode)){
                record.ShippingPostalCode.addError('Not a valid zip code for the selected Country');
            }
        }

        if(String.isNotBlank(record.BillingCountryCode) && String.isNotBlank(record.BillingPostalCode)){
            //CSP-2954: Allow Leads with incomplete (3-digit) Canadian postal codes
            //Account must have complete zip for Canada 
            if(!XOCustomValidationUtility.hasCompleteCanadianZip(record.BillingCountryCode, record.BillingPostalCode) ){
                record.BillingPostalCode.addError('6-digit postal code is required for the selected Country');
            }
            
            if(!XOCustomValidationUtility.validZip(record.BillingCountryCode, record.BillingPostalCode)){
                record.BillingPostalCode.addError('Not a valid zip code for the selected Country');
            }
        }
    }

    /**
     *@description: 
     *
     */
    private Account assignCountry(Account record){        
        if(String.isBlank(record.ShippingCountryCode) && String.isNotBlank(record.ShippingPostalCode)){
            record = (Account)XOCustomValidationUtility.assignCountryBasedOnZip(record, 'ShippingCountryCode', record.ShippingPostalCode);            
        }

        if(String.isBlank(record.BillingCountryCode) && String.isNotBlank(record.BillingPostalCode)){
            record = (Account)XOCustomValidationUtility.assignCountryBasedOnZip(record, 'BillingCountryCode', record.BillingPostalCode);            
        }
        return record;
    }
    
    /**
     *@description:
     *
     */
    private List<Account> updateChildAccountOwners(){
        List<Account> childAccountToUpdate = new List<Account>();
        for(Account record : [SELECT Id, OwnerId, ParentId, Parent.OwnerId FROM Account WHERE ParentId IN : accountParentOwnerMap.keySet()]){
            //Account oldParentValue = (Account)trigger.oldMap.get(record.ParentId);
        //if(record.OwnerId == oldParentValue.OwnerId){
            if(record.OwnerId != record.Parent.OwnerId){
                //record.OwnerId = accountParentOwnerMap.get(record.ParentId);
                record.OwnerId = record.Parent.OwnerId;
                childAccountToUpdate.add(record);
            }
        }
        return childAccountToUpdate;
    }

    /**
     *@description: Update All Billing Account Name(s) when there is change in Account name
     *
     */
    private List<Zuora__CustomerAccount__c> updateBillingAccountNames(Set<String> accountIdSet){
        List<Zuora__CustomerAccount__c> billingAccountsTobeUpdateList = new List<Zuora__CustomerAccount__c>();
        for(Zuora__CustomerAccount__c customerAccount : [SELECT id, Name, Zuora__Account__c, Zuora__Account__r.Name 
                                                         FROM Zuora__CustomerAccount__c WHERE Zuora__Account__c IN: accountIdSet]){
                                                            
            // CSP -1400 use equals() instead of "!=" in Account Name Comparison                                             
            if(!customerAccount.Name.equals(customerAccount.Zuora__Account__r.Name) && customerAccount.Zuora__Account__r.Name.length() <= 80){
                customerAccount.Name = customerAccount.Zuora__Account__r.Name;
                billingAccountsTobeUpdateList.add(customerAccount);
            }
        }  
        return billingAccountsTobeUpdateList;
    }

    /**
     *   CSP-1885 | "generateAccountVIPStatusTask" generates a Task whenever a local Account's "VIP Program"
     *   formula checkbox changes and assigns it to the Account's "Strategy Specialist" lookup user
     *
     *   @author Jonathan Satterfield
     *   @date   2017-02-16
     *   @param  {Account}   accountObj
     *   @param  {Boolean}   isVIP
     *   @return {Task}
     */
    private static Task generateAccountVIPStatusTask(Account accountObj, Boolean isVIP) {
     Task vipStatusTask = new Task();
     vipStatusTask.ActivityDate = Date.Today();
     vipStatusTask.OwnerId = accountObj.Strategy_Specialist__c; // before calling this method check to make sure this lookup != null
     vipStatusTask.WhatId = accountObj.Id;
     vipStatusTask.Type = 'Other';
     vipStatusTask.Purpose__c = 'VIP Status Change';
     vipStatusTask.Status = 'Not Started';
     vipStatusTask.Subject = isVIP ? accountObj.Name + ' has been upgraded to a VIP status' : accountObj.Name + ' has been downgraded to a non-VIP status';
     vipStatusTask.Description = isVIP ? 'The following account has been upgraded to a VIP status:' : 'The following account has been downgraded to a non-VIP status:';
     vipStatusTask.Description += '\nAccount Name: ' + accountObj.Name + '\nTotal Spend: ' + accountObj.ActiveSubscriptionTCVSummary__c;
     return vipStatusTask;
    }

    /**
     *   CSP-2040 | "updateAccountContactsOwner" will update the Owner of all child Contact
     *   records to be the same as the parent Account's Owner when the Account's Owner changes.
     *
     *   @author Jonathan Satterfield
     *   @date   2017-04-04
     *   @param  {Map<Id, Id>}  
     */
    @future
    private static void updateAccountContactsOwner(Map<Id, Id> accountIdToOwnerIdMap) {
        List<Contact> childContactList = [SELECT Id, AccountId, OwnerId FROM Contact WHERE AccountId IN :accountIdToOwnerIdMap.keySet()];
        // if no child Contacts found return immediately
        if (childContactList.isEmpty()) {
            return;
        }
        // if records found, set this static boolean flag to skip ContactTriggerHandler record owner assignment logic
        ContactTriggerHandler.accountTriggerUpdatingContactOwners = true;
        for (Integer i = 0; i < childContactList.size(); i++) {
            Contact childContact = childContactList[i];
            // due to the query's WHERE clause there's no need to check to see if the map contains the key
            childContact.OwnerId = accountIdToOwnerIdMap.get(childContact.AccountId);
        }
        List<Database.SaveResult> updateResultsList = Database.update(childContactList, false);
        List<XO_Exception__c> xoExceptionList = ExceptionUtility.consumeException(updateResultsList);
        if (!xoExceptionList.isEmpty()) {
            insert xoExceptionList;
        }
    }

    // CSP-2821 Selling to a Prospect
    // put all the account status changing logic and validation in the method
    private static void accountStatusChangeValidation(Account newAccObj, Account oldAccObj){

        String newStatus = newAccObj.account_status__c != NULL? newAccObj.account_status__c:'';
        String oldStatus = oldAccObj.account_status__c != NULL? oldAccObj.account_status__c:'';
        String newReason = newAccObj.Negative_Disposition_Reason__c != NULL? newAccObj.Negative_Disposition_Reason__c:'';
        String oldReason = oldAccObj.Negative_Disposition_Reason__c != NULL? oldAccObj.Negative_Disposition_Reason__c:'';

        // CSP-2821 Selling to a Prospect
        // validate the status from non Active to Active
        if(!activeSubAccSet.contains(newAccObj.Id) && 
            !oldStatus.equalsIgnoreCase('Active') &&
            newStatus.equalsIgnoreCase('Active')){
            newAccObj.addError(Label.NonActiveErrMsg);
            return;
        }

        // CSP-2821 Selling to a Prospect
        // validate the status from non In opportunity to In Opportunity
        if(!openedOppSet.contains(newAccObj.Id) &&
            !oldStatus.equalsIgnoreCase('In Opportunity') && 
            newStatus.equalsIgnoreCase('In Opportunity')){
            newAccObj.addError(Label.NonInOpportunityErrMsg);
            return;
        }

        // CSP-2821 Selling to a Prospect
        // validate the status from Active to non Active
        if(activeSubAccSet.contains(newAccObj.Id) && 
            !newStatus.equalsIgnoreCase('Active')){

            newAccObj.addError(Label.ActiveErrorMsg);
            return;
        }

        // CSP-2821 Selling to a Prospect
        // validate the status from In opportunity to non In Opportunity, 
        else if(openedOppSet.contains(newAccObj.Id) && 
                !newStatus.equalsIgnoreCase('In Opportunity') && 
                !newStatus.equalsIgnoreCase('Active')){

            newAccObj.addError(Label.InOpportunityErrorMsg);
            return;
        }

        // CSP-2821 Selling to a Prospect
        // Clean up the negative disposition reason when status changing from Disqualified or Dormant
        if(newStatus != 'Dormant' && newStatus != 'Disqualified'){
            newAccObj.Negative_Disposition_Reason__c = '';
            newAccObj.Reason_Details__c = '';
        }
        if(oldReason == 'Other' && newReason != 'Other'){
            newAccObj.Reason_Details__c = '';
        }

        // CSP-2821 Selling to a Prospect
        // Assign owner logic
        // If reason changed, and changed to the following vlaues then assign to data enrichment team
        // Bad contact
        // Duplicate
        // Missing Required Information
        // Not My Territory
        // Not Wedding Related
        if(newReason.equalsIgnoreCase('Bad Contact') && !oldReason.equalsIgnoreCase('Bad Contact') || 
            newReason.equalsIgnoreCase('Duplicate') && !oldReason.equalsIgnoreCase('Duplicate') ||
            newReason.equalsIgnoreCase('Missing Required Information') && !oldReason.equalsIgnoreCase('Missing Required Information') ||
            newReason.equalsIgnoreCase('Not My Territory') && !oldReason.equalsIgnoreCase('Not My Territory') ||
            newReason.equalsIgnoreCase('Not Wedding Related') && !oldReason.equalsIgnoreCase('Not Wedding Related')){

            newAccObj.OwnerId = dataEnrichmentUserId;
        }
        // If reason changed, and changed to the following vlaues then assign to data enrichment team
        // Out of Business
        // Do Not Contact
        else if(newReason.equalsIgnoreCase('Out of Business') && !oldReason.equalsIgnoreCase('Out of Business') || 
            newReason.equalsIgnoreCase('Do Not Contact') && !oldReason.equalsIgnoreCase('Do Not Contact')){
            
            newAccObj.OwnerId = deadUserId;
        }

        
    }

    private static Id localSalesRepAssignmentlogic (Account accountTocheck){
        Id returnId;
        return returnId;
    }

    /**
     * CSP-2912 Re-engage an Account
     * Account owner Assignment
     *
     * * @Author Siva
     *   @Date   2018-05-21
     *   @param  acc
     *   @return Account
    */
    private Account accOwnerAssignment(Account acc) {
 
        // Account related to paid media or SSE Portfolio 
        if(acc.Related_to_Paid_Media__c || acc.Portfolio__c == 'Senior Sales Executive') {
            acc.OwnerId = distactAccountId;
        }
        // Execute assignment rule for Account
        else {
            Local_Sales_Rep_Assignment__c localSalesRepAssignmentRecord = AssignmentRulesUtility.getRecordAssignment(acc);
            if(localSalesRepAssignmentRecord != null) {
                if (localSalesRepAssignmentRecord.Sales_Rep__c != null ){
                    acc.OwnerId = localSalesRepAssignmentRecord.Sales_Rep__c;
                }
                else{
                    acc.OwnerId = distactAccountId;
                }
            }
            else {
                // If not find local user to do 
                acc.OwnerId = dataEnrichmentUserId; 
                acc.Account_Status__c = 'Dormant';
                acc.Negative_Disposition_Reason__c = 'Missing Required Information';
            }
        }
        return acc; 
    }

}