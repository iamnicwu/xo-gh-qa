public without sharing class LeadTriggerHandler implements XOTrigger{
    
    private Set<String> locationIdToFulfill = new Set<String>();
    private List<AccountContactRole> convertLeadAccountContactRoleList = new List<AccountContactRole>();
    private List<Id> leadsToConvertIdList = new List<Id>();
    private List<Opportunity> updateOppList = new List<Opportunity>();
    private static final String LEAD_SOURCE_TODISTRIBUTABLE_QUEUE = System.Label.Lead_Source_toDistributable_queue;
    private Map<Id, Id> salesRepStrategySpecialistMap = new Map<Id, Id>();
    private Map<String, String> zipMarketMap = new Map<String, String>();
    // CSP-2476, used for getting the State and city on the object Zip__c
    private Map<String, Zip__c> poastalCodeZipMap = new Map<String, Zip__c>();
    public static Boolean leadConvert = false;
    private static List<CountryZipREGEX__c> countryRegExList = [select Id, Name, Active__c, CountryCode__c, RegExPattern__c from CountryZipREGEX__c where Active__c = true];
    private Map<Id,Schema.RecordTypeInfo> rtMapById = Schema.SObjectType.Lead.getRecordTypeInfosById();
    private static Map<Id, List<Lead>> localSalesRepAssignmentToLeadListMap = new Map<Id, List<Lead>>();

    // CSP-1852 Assignment Tool Data Points
    private Map<String,String> leadOwnerNameMap = new Map<String,String>();

    // CSP-2061 | variables used for scoring Lead records
    private static final Set<String> SCORING_FIELDS_SET = LeadAndAccountScoringUtilities.getLeadScoringFieldsNameSet();
    private Set<Id> scoreLeadsIdSet = new Set<Id>();

    // csp-1940
    private static final Map<String, Group> QUEUE_NAME_MAP;
    private static final List<String> QUEUE_NAME_LIST;

    // CSP-2389
    private static final Set<Id> SKIP_ASSIGNMENT_RULES_MEMBERS = new Set<Id>();
    private static final Id bridalSalonCategoryId;
    private static final Id cassandraUserId;


    // CSP-1942 Hot Path for Leads - initialize the hot lead source set
    private static final Set<String> HOT_LEAD_SOURCE_VALUES = new Set<String>();

    // CSP-1941 Facilitate Lead Qualificiation - get field sets
    private static final List<Schema.FieldSetMember> qualifyFilters = Schema.SObjectType.Lead.fieldSets.Qualify_Lead_Fields.getFields();

    // CSP-1941 Facilitate Lead Qualificiation - get field sets
    private static final Set<String> LEAD_LASTNAME_FILTERS = new Set<String>();
    private static final Set<String> LEAD_FIRSTNAME_FILTERS = new Set<String>();

    // CSP-1941 Facilitate Lead Qualificiation - Data enrichment team member set
    private static final Set<Id> DATA_ENRICHMENT_MEMBERS = new Set<Id>();

    // CSP-2546 Clone feed from Lead to Account Upon Conversion
    private Map<Id, List<FeedItem>> feedItemMap = new Map<Id, List<FeedItem>>();

    // CSP-2552 get the converted account Id map when the lead converted
    private Map<Id, Id> leadConvertedAccIdMap = new Map<Id, Id>();
    private List<Endorsement__c> updateEndorsementList = new List<Endorsement__c>();

    // CSP-2621 Accounts Incorrectly Assigned to "Distributable Accounts" user
    private static final Id distactAccountId;

    //for CSP-2618 store lead data    
    //CSP-2453 DE for Sr. Sales Executive
    private static Map<String, String> zipCodePortfolioMap = new Map<String, String>();
    
    //csp-2559
    private static final Set<String> PROFILE_NAME_SET;

    //csp-2871 SIVA VANKADARU 08/12/2018 this list is to get profile names from custom label
    private static final Set<String> PROFILE_NAME_EXCEPTION_DISTRIBUTION_LIST;

    //This user list also used by CSP-2453 and CSP-2559, release with SF release 4.17
    private static  List<User> userObjList = [SELECT id, Profile.Name, UserRole.Name FROM User WHERE id = : UserInfo.getUserId()];

    //csp-2791
    private Map<String, Id> zipNameToIdMap = new Map<String, Id>();

    // CSP-3075 Update Automation on Lead to fill in Market based on Canadian Zip Codes
    private static Map<String, Market__c> marketIdObjMap = New Map<String, Market__c>();
    private Map<String, Canadian_Postal_Code_Market_Mapping__c> canadaMarketMap = new Map<String, Canadian_Postal_Code_Market_Mapping__c>();
    private Map<String, String> stateCodeMarketIdMap = new Map<String, String>(); 
    private static final Map<String, String> STATE_AND_STATECODE_MAP = new Map<String, String>(); 
    private static final Map<String, String> COUNTRY_AND_COUNTRYCODE_MAP = new Map<String, String>(); 

    static {
        List<XO_Exception__c> exceptionList = new List<XO_Exception__c>();

        if(QUEUE_NAME_LIST == null) {
            // CSP-1942 Hot Path for Leads - add data enrichment value to queue list
            QUEUE_NAME_LIST = new List<String>{'Distributable', 'Dead Queue', 'Data Enrichment'};
        }

        // csp-2559 - Custom label ProfileNamesRestrictedList contains list of all profiles which should be 
        // updating the lead status. Putting them into a custom label helps us to make futher changes directly 
        // to the config file without updating the code when adding new profiles to the list 
        if(PROFILE_NAME_SET == null) {

            List<String> profileNameRestrictedList = new List<String>(System.Label.ProfileNamesRestrictedList.split('\n'));
            PROFILE_NAME_SET = new Set<String>();

            for(String profileNameRec: profileNameRestrictedList) {
                PROFILE_NAME_SET.add(profileNameRec.trim());
            }
        }


        //csp-2871 SIVA VANKADARU 08/12/2018 this list is to get profile names from custom label begin
        if(PROFILE_NAME_EXCEPTION_DISTRIBUTION_LIST == null) {

            List<String> profilenameexceptiondistributionlist = new List<String>(System.Label.ProfileNamesExceptionDistubutionList.split('\n'));
            PROFILE_NAME_EXCEPTION_DISTRIBUTION_LIST = new Set<String>();

            for(String profileNameRec: profilenameexceptiondistributionlist) {
                PROFILE_NAME_EXCEPTION_DISTRIBUTION_LIST.add(profileNameRec.trim());
            }
        }
        //csp-2871 SIVA VANKADARU 08/12/2018 this list is to get profile names from custom label end


        if(QUEUE_NAME_MAP == null) {
            List<Group> queueGroupList = [SELECT Id, Name, (SELECT Id, UserOrGroupId FROM GroupMembers) FROM Group WHERE Type = 'Queue' AND Name IN :QUEUE_NAME_LIST];

            Map<String, Group> tempGroupMap = new Map<String, Group>();
            for(Integer i = 0; i < queueGroupList.size(); i++) {
                Group currentGroup = queueGroupList[i];
                tempGroupMap.put(currentGroup.Name, currentGroup);

                // CSP-1941 Facilitate Lead Qualificiation - adding group members of data enrichment team in a set
                if(currentGroup.Name.equalsIgnoreCase('Data Enrichment')){
                    for(GroupMember gm : currentGroup.GroupMembers){
                        DATA_ENRICHMENT_MEMBERS.add(gm.UserOrGroupId);
                    }
                }
            }

            QUEUE_NAME_MAP = tempGroupMap;
        }

        // csp-2389
        try {
            Group skipAssignmentRulesGrp = [SELECT Id, Name, (SELECT Id, UserOrGroupId FROM GroupMembers) FROM Group WHERE Type = 'Regular' AND Name = 'Skip Assignment Rules'];
            for(GroupMember currentGrpMember : skipAssignmentRulesGrp.GroupMembers) {
                SKIP_ASSIGNMENT_RULES_MEMBERS.add(currentGrpMember.UserOrGroupId);
            }
        } catch (Exception e) {
            XO_Exception__c xoException = ExceptionUtility.consumeException(e, false);
            xoException.Severity__c = 'Critical';
            xoException.Failure_Area__c = 'Lead Assignment Workflow Exception';
            exceptionList.add(xoException);
        }
 
        try {
            Category__c bridalSalonCatRec = [SELECT Id FROM Category__c WHERE Name = 'Bridal Salons - BWP'];
            if(bridalSalonCatRec != null) {
                bridalSalonCategoryId = bridalSalonCatRec.Id;
            }
        } catch (Exception e) {
            XO_Exception__c xoException = ExceptionUtility.consumeException(e, false);
            xoException.Severity__c = 'Critical';
            xoException.Failure_Area__c = 'Lead Assignment Workflow Exception';
            exceptionList.add(xoException);
        }

        try {
            // CSP-2621 Accounts Incorrectly Assigned to "Distributable Accounts" user

            for (User currentUser : [SELECT Id,Name,Alias FROM User WHERE 
                                    (Name =: Label.UserNameExceptionSkipAssigmentRule OR Alias = 'distacts') AND 
                                    IsActive = true]) {
                
                if (currentUser.Name == Label.UserNameExceptionSkipAssigmentRule) {
                    cassandraUserId = currentUser.id;
                }
                else if(currentUser.Alias == 'distacts'){
                    distactAccountId = currentUser.Id;
                }
            }

        } catch (Exception e) {
            XO_Exception__c xoException = ExceptionUtility.consumeException(e, false);
            xoException.Severity__c = 'Critical';
            xoException.Failure_Area__c = 'Lead Assignment Workflow Exception';
            exceptionList.add(xoException);
        }

        // CSP-3075 Update Automation on Lead to fill in Market based on Canadian Zip Codes
        // Get all Canada Market record for set default market when have no Zip code mapping
        for(Market__c canadaMarket : [SELECT Id, Name, Market_Id__c, Country__c FROM Market__c where Country__c = 'CA']) {
            marketIdObjMap.put(canadaMarket.Market_ID__c, canadaMarket);
        }

        // CSP-3075 Update Automation on Lead to fill in Market based on Canadian Zip Codes
        // Get system country and countryCode mapping, state and stateCode mapping  
        COUNTRY_AND_COUNTRYCODE_MAP.putAll(DataUtility.buildPicklistEntryMap('Lead','CountryCode'));
        STATE_AND_STATECODE_MAP.putAll(DataUtility.buildPicklistEntryMap('Lead','StateCode'));

        // CSP-1942 Hot Path for Leads - retrieve the hot path lead values from system label and put it to HOT_LEAD_SOURCE_VALUES
        HOT_LEAD_SOURCE_VALUES.addAll(System.label.Hot_Lead_Sources.split('\r\n'));

        // CSP-1941 Facilitate Lead Qualificiation - store filters in two sets
        LEAD_FIRSTNAME_FILTERS.addAll(system.label.Lead_First_Name_Filters.split('\r\n'));
        LEAD_LASTNAME_FILTERS.addAll(system.label.Lead_Last_Name_Filters.split('\r\n'));

        insert exceptionList;
    }

    public void bulkBefore() {

        Set<String> zipSet = new Set<String>();
        Set<Id> categoryIdSet = new Set<Id>();
        Set<Id> marketIdSet = new Set<Id>();
        Set<String> zipCodeSet = new Set<String>();
        Set<Id> salesRepIdSet = new Set<Id>(); // SIVA VANKADARU CSP - 2927 07-23-2018

        for(Lead record : (List<Lead>)Trigger.New) {
            if(rtMapById.get(record.RecordTypeId).getName().containsIgnoreCase('Local')){
                if(String.isNotBlank(record.Local_Sales_Market__c)){
                    marketIdSet.add(record.Local_Sales_Market__c);
                }
                if(String.isNotBlank(record.Primary_Category__c)){
                    categoryIdSet.add(record.Primary_Category__c);
                }
                if(String.isNotBlank(record.PostalCode)){
                    // CSP-3075 Update Automation on Lead to fill in Market based on Canadian Zip Codes
                    // Different bewteen US and Canada country 
                    // Get record Country Code
                    String tempCountryCode = String.isNotBlank(record.CountryCode) ? record.CountryCode : COUNTRY_AND_COUNTRYCODE_MAP.get(record.Country);

                    if(record.PostalCode.length() >= 5 
                        && tempCountryCode == 'US') {

                        zipSet.add(record.PostalCode.left(5));
                    }
                    // Add first three digits of Canadian Zipcod to set for query zipcode record
                    else if(record.PostalCode.length() >= 3 
                          && (tempCountryCode == 'CA')) {

                        zipSet.add(record.PostalCode.left(3).toUpperCase());
                    }
                    else {
                        zipSet.add(record.PostalCode);
                    }

                }
                
            }
            // BEGIN SIVA VANKADARU CSP - 2927 07-23-2018
            if(trigger.isUpdate) {

                leadOwnerNameMap.put(record.OwnerID, record.Owner.Name); // SIVA VANKADARU CSP - 3217 09-25-2018

                if(rtMapById.get(record.RecordTypeId).getName().containsIgnoreCase('Local')) {

                    Lead oldRecord = (Lead)trigger.oldMap.get(record.Id);

                    if(!record.isConverted && (record.OwnerId != oldRecord.OwnerId || String.isBlank(record.Strategy_Specialist__c))){
                        salesRepIdSet.add(record.OwnerId);
                    }
                }               
            }
        }

        if(trigger.isUpdate) {

            if(!salesRepIdSet.isEmpty()){
                for(User record : [select Id, Strategy_Specialist__c from User where Id IN : salesRepIdSet and Strategy_Specialist__c != null]){
                    salesRepStrategySpecialistMap.put(record.Id, record.Strategy_Specialist__c);
                }
            }
        }
        // END SIVA VANKADARU CSP - 2927 07-23-2018

        for (Zip__c zipObj : [SELECT Id, ZipCode__c, Local_Market__c, Local_Market__r.Market_ID__c, City__c, State__c, Portfolio__c  
                              FROM Zip__c
                              WHERE ZipCode__c IN :zipSet]) {
            
            marketIdSet.add(zipObj.Local_Market__c);

            zipMarketMap.put(zipObj.ZipCode__c, zipObj.Local_Market__c);
            poastalCodeZipMap.put(zipObj.ZipCode__c, zipObj);
            if(String.isNotBlank(zipObj.Portfolio__c)){
                zipCodePortfolioMap.put(zipObj.ZipCode__c, zipObj.Portfolio__c);
            }
            // CSP-3067 //csp-2791
            zipNameToIdMap.put(zipObj.ZipCode__c, zipObj.id);            
        }

        // CSP-3075 Update Automation on Lead to fill in Market based on Canadian Zip Codes
        // Get custom setting Postal Code market mapping
        for(Canadian_Postal_Code_Market_Mapping__c canadaMarket : Canadian_Postal_Code_Market_Mapping__c.getAll().values()) {
            canadaMarketMap.put(canadaMarket.Canadian_Postal_Code__c, canadaMarket);
            //Get default martket id
            if(String.isNotBlank(canadaMarket.Default_State_Code__c)) {
                stateCodeMarketIdMap.put(canadaMarket.Default_State_Code__c, canadaMarket.Market_Id__c);
            }
        }

        if(!zipSet.isEmpty() || !categoryIdSet.isEmpty() || !marketIdSet.isEmpty()) {
            AssignmentRulesUtility.buildAssignmentMap(marketIdSet, categoryIdSet, zipSet);
        }
    }

    ////////////////
    // BULK AFTER //
    ////////////////
    public void bulkAfter() {

        if(Trigger.isUpdate){
            // CSP-2546 Clone feed from Lead to Account Upon Conversion
            List<Lead> convertedLeadList = new List<Lead>();

            for(Lead record : (List<Lead>)Trigger.New) {
                if(rtMapById.get(record.RecordTypeId).getName().containsIgnoreCase('Local')){
                    if(record.IsConverted){
                        convertedLeadList.add(record);
                        // CSP-2552 added the converted lead to the map
                        leadConvertedAccIdMap.put(record.Id, record.ConvertedAccountId);
                    }
                }
            }
            
            // CSP-2546 Clone feed from Lead to Account Upon Conversion
            if(!convertedLeadList.isEmpty()){

                
                // Query all feed items from converted leads
                List<FeedItem> feedItemList = [SELECT Id, Body, LinkUrl, ParentId, HasContent, type, RelatedRecordId, IsRichText, Title
                                               FROM FeedItem WHERE ParentId IN: convertedLeadList];

                List<FeedItem> itemList = new List<FeedItem>();

                // Stored to a map for each lead with all its feed items
                for(FeedItem fi : feedItemList){
                    
                    if(!feedItemMap.containsKey(fi.ParentId)){
                        itemList = new List<FeedItem>();
                        itemList.add(fi);
                        feedItemMap.put(fi.ParentId, itemList);
                    }
                    else{
                        feedItemMap.get(fi.ParentId).add(fi);
                    }
                }
            }
            // CSP-2552 added the converted lead to the map
            if (!leadConvertedAccIdMap.isEmpty()) {
                updateEndorsementList = [Select Id, Account__c, Lead__c From Endorsement__c where Lead__c IN: leadConvertedAccIdMap.keySet()];

                if (!updateEndorsementList.isEmpty()) {
                    for (Endorsement__c currentEndorsement: updateEndorsementList) {
                        currentEndorsement.Account__c = leadConvertedAccIdMap.get(currentEndorsement.Lead__c);
                    }
                }
            }
        }
    }

    ///////////////////
    // BEFORE INSERT //
    ///////////////////
    public void beforeInsert(SObject so){
        Lead record = (Lead)so;

        //////////////////////////////////////////
        // LOCAL BEFORE INSERT PROCESSING LOGIC //
        //////////////////////////////////////////
        if(rtMapById.get(record.RecordTypeId).getName().containsIgnoreCase('Local')){

            // CSP-3075 Update Automation on Lead to fill in Market based on Canadian Zip Codes
            // Fill in CountryCode if it's blank 
            if(String.isNotBlank(record.Country) && String.isBlank(record.CountryCode) 
                && COUNTRY_AND_COUNTRYCODE_MAP.containsKey(record.Country)) {

                record.CountryCode = COUNTRY_AND_COUNTRYCODE_MAP.get(record.Country);
            }

            // CSP-3075 Update Automation on Lead to fill in Market based on Canadian Zip Codes
            // Fill in StateCode if it's blank 
            if(String.isNotBlank(record.State) && String.isBlank(record.StateCode) 
                && STATE_AND_STATECODE_MAP.containsKey(record.State)) {

                record.StateCode = STATE_AND_STATECODE_MAP.get(record.State);
            }

            // BEGIN SIVA VANKADARU CSP - 2927 07-23-2018
            LeadTriggerHandlerExtension.phoneValidation(record, null);
            LeadTriggerHandlerExtension.zipValidation(record, null);
            LeadTriggerHandlerExtension.assignDynamicsleadid(record);
            LeadTriggerHandlerExtension.assignCountry(record);
            LeadTriggerHandlerExtension.assignLocalsalesmarket(record, marketIdObjMap, zipMarketMap, null, canadaMarketMap, stateCodeMarketIdMap);
            LeadTriggerHandlerExtension.assignCitystate(record, poastalCodeZipMap, null);
            LeadTriggerHandlerExtension.assignFulfillstorefront(record);
            LeadTriggerHandlerExtension.assignStrategyspecialist(record, salesRepStrategySpecialistMap, null);
            // END SIVA VANKADARU CSP - 2927 07-23-2018
            
            //csp-2559
            if(PROFILE_NAME_SET.contains(userObjList[0].Profile.Name) && record.Status != 'New') {
                record.addError('User with ' + userObjList[0].Profile.Name + ' profile cannot update the lead status on creation');
            }

            // CSP-1852 Assignment Tool Data Points
            // Ownership changed date will assign in record insertion
            if(!record.IsConverted){
              record.Ownership_Changed_Date__c = System.today();
            }

            // csp-1940
            if(record.Status == 'New') {

                // CSP-1942 Hot Path for Leads
                // if current lead source is inside the set of hot path
                // system will set lead status to valid and owner set to distributable team
                // else if not hot path
                // system will set owner to data enrichment team   
                if(HOT_LEAD_SOURCE_VALUES.contains(record.LeadSource)){
 
                    // csp-2389: Even if the lead is created by users defined in csp-2389; a hot lead should alw ays be assigned 
                    // a valid status           
                    record.Status = 'Valid';
                    // CSP-1941 Facilitate Lead Qualificiation - mark down the time stamp when the status assigned to valid
                    record.Valid_Status_Time_Stamp__c = System.now();

                    // csp-2389: Skip assignment rules for users mentioned in the ticket
                    // else if(!SKIP_ASSIGNMENT_RULES_MEMBERS.contains(record.OwnerId)) {
                    if(!SKIP_ASSIGNMENT_RULES_MEMBERS.contains(record.OwnerId)) {
                        if(!(record.OwnerId == cassandraUserId && record.Primary_Category__c != bridalSalonCategoryId)) {

                            // CSP-2576 Default Owner to Data Enrichment when missing mapping
                            // For those valid Leads, if the existing Zipcode not mapping to current local sales market, 
                            // then set the owner to DE team
                            // status to Invalid
                            // Reason to Missing Required Information 
                            if(record.Local_Sales_Market__c == null 
                                && String.isNotBlank(record.PostalCode) 
                                && (!zipMarketMap.containsKey(record.PostalCode) 
                                && !zipMarketMap.containsKey(record.PostalCode.left(5)))){
                                
                                    if(QUEUE_NAME_MAP.containsKey('Data Enrichment')) {
                                        record.OwnerId = QUEUE_NAME_MAP.get('Data Enrichment').Id;
                                        record.Status = 'Invalid';
                                        record.Negative_Disposition_Reason__c = 'Missing Required Information';
                                    }
                            }
                            // if zipcode mapped to local sales market, then apply owner assignment rule
                            // CSP-2453 DE for Sr. Sales Executive 
                            // Add filter for SSE logic judge need skip assignment or not
                            else if(redirectToDELogic(record)) {
                                distributionEngine(record);
                            } else {
                                ownerAssignment(record);
                            }
                        }
                    }
                }
                else {
                    if(QUEUE_NAME_MAP.containsKey('Data Enrichment')) {
                        record.OwnerId = QUEUE_NAME_MAP.get('Data Enrichment').Id;
                    }
                }
            } 
            else if(record.Status == 'Valid') {

                if(!SKIP_ASSIGNMENT_RULES_MEMBERS.contains(record.OwnerId)) {
                    if(!(record.OwnerId == cassandraUserId && record.Primary_Category__c != bridalSalonCategoryId)) {

                        // CSP-2576 Default Owner to Data Enrichment when missing mapping
                        // For those valid Leads, if the existing Zipcode not mapping to current local sales market, 
                        // then set the owner to DE team
                        // status to Invalid
                        // Reason to Missing Required Information 
                        if(record.Local_Sales_Market__c == null 
                            && String.isNotBlank(record.PostalCode) 
                            && (!zipMarketMap.containsKey(record.PostalCode) 
                            && !zipMarketMap.containsKey(record.PostalCode.left(5)))){
                            
                                if(QUEUE_NAME_MAP.containsKey('Data Enrichment')) {
                                    record.OwnerId = QUEUE_NAME_MAP.get('Data Enrichment').Id;
                                    record.Status = 'Invalid';
                                    record.Negative_Disposition_Reason__c = 'Missing Required Information';
                                }
                        }
                        // if zipcode mapped to local sales market, then apply owner assignment rule
                        // CSP-2453 DE for Sr. Sales Executive 
                        // Add filter for SSE logic judge need skip assignment or not
                        
                        else if(redirectToDELogic(record)) {
                            distributionEngine(record);
                        } else {
                            ownerAssignment(record);
                        }
                    } 
                } 

                // csp-2791
                distributionEngine(record);
            }
            else if(record.Status == 'Qualified'){

                // CSP-2621 Accounts Incorrectly Assigned to "Distributable Accounts" user
                // for those lead owned by distributable queue, we need to assign them to distributable account as user
                // for those lead owned by data enrichment, we need to run through owner assignment rules
                // for those lead owned by individual AEs, keep it as is
                if(record.Local_Partners_Claiming__c){

                    if(!QUEUE_NAME_MAP.isEmpty()){
                        // check if the current lead owner is distributable queue
                        if(QUEUE_NAME_MAP.get('Distributable')!= null && record.OwnerId == QUEUE_NAME_MAP.get('Distributable').Id){
                            record.OwnerId = distactAccountId;
                        }
                        // check if the current lead owner is data enrichment
                        else if(QUEUE_NAME_MAP.get('Data Enrichment')!= null && record.OwnerId == QUEUE_NAME_MAP.get('Data Enrichment').Id){
                            ownerAssignment(record);
                            
                            // check if the assignment rule not mapped, then system will assign the lead to a specific user and run DE rules
                            if(record.OwnerId == QUEUE_NAME_MAP.get('Distributable').Id){
                                record.OwnerId = Label.LeadOwnerIDForNotMappedAssignmentRule;
                            }
                            
                        }
                        // just in case for the current lead owner is in a queue
                        else if(String.valueOf(record.OwnerId).startsWith('00G')) {
                            record.OwnerId = distactAccountId;
                        }
                    }
                }
            }
            
            if (record.Status != 'Invalid' && record.Status != 'New') {
                if(String.isNotBlank(record.Potential_Duplicates__c)) {
                    record.Potential_Duplicates__c = '';
                } 
                else if (record.Status != 'Unknown' && record.Status != 'Disqualified' && String.isNotBlank(record.Negative_Disposition_Reason__c)) {
                    record.Negative_Disposition_Reason__c = '';
                }
            }

            //ss-6634, CSP-2791
            LeadTriggerHandlerExtension.assignZip(record, zipNameToIdMap, null);// SIVA VANKADARU CSP - 2927 07-23-2018

        }
    }

    ///////////////////
    // BEFORE UPDATE //
    ///////////////////
    public void beforeUpdate(SObject oldSo, SObject so){
        Lead record = (Lead)so;
        Lead oldRecord = (Lead)oldSo;
        if(rtMapById.get(record.RecordTypeId).getName().containsIgnoreCase('Local') 
            && rtMapById.get(oldRecord.RecordTypeId).getName().containsIgnoreCase('Local')){

            // CSP-3075 Update Automation on Lead to fill in Market based on Canadian Zip Codes
            // Update CountryCode when change Country from call API
            if(String.isNotBlank(record.Country) && record.Country != oldRecord.Country
                && record.CountryCode == oldRecord.CountryCode
                && COUNTRY_AND_COUNTRYCODE_MAP.containsKey(record.Country)) {

                record.CountryCode = COUNTRY_AND_COUNTRYCODE_MAP.get(record.Country);
            }

            // CSP-3075 Update Automation on Lead to fill in Market based on Canadian Zip Codes
            // Update StateCode when change state from call API 
            if(String.isNotBlank(record.State) && record.State != oldRecord.Status
                && record.StateCode == oldRecord.StateCode
                && STATE_AND_STATECODE_MAP.containsKey(record.State)) {

                record.StateCode = STATE_AND_STATECODE_MAP.get(record.State);
            }

            if(record.DynamicsLeadID__c != oldRecord.DynamicsLeadID__c && record.DynamicsLeadID__c != null && oldRecord.DynamicsLeadID__c != null 
                && oldRecord.Salesforce_Generated_GUID__c){
                record.Salesforce_Generated_GUID__c = false;
            }

            // BEGIN SIVA VANKADARU CSP - 2927 07-23-2018
            LeadTriggerHandlerExtension.phoneValidation(record, oldRecord);
            LeadTriggerHandlerExtension.zipValidation(record, oldRecord);
            LeadTriggerHandlerExtension.assignDynamicsleadid(record);
            LeadTriggerHandlerExtension.assignCountry(record);
            LeadTriggerHandlerExtension.assignLocalsalesmarket(record, marketIdObjMap, zipMarketMap, oldRecord, canadaMarketMap, stateCodeMarketIdMap);
            LeadTriggerHandlerExtension.assignCitystate(record, poastalCodeZipMap, oldRecord);
            LeadTriggerHandlerExtension.assignFulfillstorefront(record);
            LeadTriggerHandlerExtension.assignStrategyspecialist(record, salesRepStrategySpecialistMap, oldRecord);
            LeadTriggerHandlerExtension.assignZip(record, zipNameToIdMap, oldRecord);

            // END SIVA VANKADARU CSP - 2927 07-23-2018

            // csp-1940
            // lead is no longer assigned directly to the sales rep; but it is first assigned to Data Enrichment queue from where 
            // its properly distributed after updating the lead status to 'Valid'
            if(record.Status == 'New') {

                // CSP-1942 Hot Path for Leads
                // if current lead source is inside the set of hot path
                // system will set lead status to valid and owner set to distributable team
                // else if not hot path
                // system will set owner to data enrichment team   
                if(HOT_LEAD_SOURCE_VALUES.contains(record.LeadSource)){  
                    // csp-2389: Even if the lead is created by users defined in csp-2389; a hot lead should always be assigned 
                    // a valid status           
                    record.Status = 'Valid';
                    // CSP-1941 Facilitate Lead Qualificiation - mark down the time stamp when the status assigned to valid
                    record.Valid_Status_Time_Stamp__c = System.now();

                    // csp-2389: Skip assignment rules for users mentioned in the ticket
                    if(!SKIP_ASSIGNMENT_RULES_MEMBERS.contains(record.CreatedById)) {
                        if(!(record.CreatedById == cassandraUserId && record.Primary_Category__c != bridalSalonCategoryId)) {
                            // CSP-2652 Hubspot leads missing marketing mapping
                            // For hubspot Leads, Some lead will updated lead source by hupspot
                            // if the existing Zipcode not mapping to current local sales market, 
                            // then set the owner to DE team
                            // status to Invalid
                            // Reason to Missing Required Information 
                            // 
                            if(record.Local_Sales_Market__c == null 
                                && String.isNotBlank(record.PostalCode) 
                                && (!zipMarketMap.containsKey(record.PostalCode) 
                                && !zipMarketMap.containsKey(record.PostalCode.left(5)))){

                                if(QUEUE_NAME_MAP.containsKey('Data Enrichment')) {
                                    record.OwnerId = QUEUE_NAME_MAP.get('Data Enrichment').Id;
                                    record.Status = 'Invalid';
                                    record.Negative_Disposition_Reason__c = 'Missing Required Information';
                                }
                            }
                            // if zipcode mapped to local sales market, then apply owner assignment rule
                            // CSP-2453 DE for Sr. Sales Executive 
                            // Add filter for SSE logic judge need skip assignment or not
                            if(redirectToDELogic(record)) {
                                distributionEngine(record);
                            } else {
                                ownerAssignment(record);
                            }
                        }
                    }
                } else {
                    if(oldRecord.Status != 'New'){
                        // update lead status back to New should clear out invalid reason
                        record.Negative_Disposition_Reason__c = '';

                        // csp-2389: Skip assignment rules for users mentioned in the ticket
                        if(!SKIP_ASSIGNMENT_RULES_MEMBERS.contains(record.CreatedById)) {
                            if(!(record.CreatedById == cassandraUserId && record.Primary_Category__c != bridalSalonCategoryId)) {

                                if(QUEUE_NAME_MAP.containsKey('Data Enrichment')) {
                                    //csp-1940
                                    // if the owner id is different it means the request for assigning the owner id is from the 'Accept' button
                                    // we check if the owner ids are different and the previous owner is indeed data enrichment queue
                                    if(oldRecord.OwnerId == record.OwnerId) {
                                        record.OwnerId = QUEUE_NAME_MAP.get('Data Enrichment').Id;
                                    }
                                }
                            }
                        }
                    }
                }
            // csp-1040
            // if the lead status of 'Invalid' and invalid reason is 'Out of Business'; it sets the lead to an end of life state 
            } else if(record.Status == 'Invalid') {
                if(record.Negative_Disposition_Reason__c == 'Out of Business') {
                    if(QUEUE_NAME_MAP.containsKey('Dead Queue')) {
                        Group deadQueue = QUEUE_NAME_MAP.get('Dead Queue');
                        record.OwnerId = deadQueue.Id;
                    }
                }
            // updating lead status from 'New' to 'Valid', updates the owner and assigns it to 'Distributable' queue
            } else if(record.Status == 'Valid') {

                string createdbyProfilename = record.CreatedBy.Profile.Name;
                createdbyProfilename = record.createdbyProfilename__c;
                //csp-2871 SIVA VANKADARU 08/12/2018 begin
                if( (!PROFILE_NAME_EXCEPTION_DISTRIBUTION_LIST.contains(createdbyProfilename)) && ((SKIP_ASSIGNMENT_RULES_MEMBERS.contains(record.CreatedById) 
                    || (cassandraUserId == record.CreatedById && record.Primary_Category__c != bridalSalonCategoryId)))) {
                    record.OwnerId = record.CreatedById;
                }
                //csp-2871 SIVA VANKADARU 08/12/2018 end

                else if(oldRecord.Status == 'New') {
                    // updating lead status to 'Valid' from 'New' assigns the lead to 'Distributable' queue
                    // As the MVP of Distribution Engine is not fulfill for all kinds of lead assigment as expected, so we need to trigger our own assignment instead.
                    if(!SKIP_ASSIGNMENT_RULES_MEMBERS.contains(record.CreatedById)) {
                        if(!(record.CreatedById == cassandraUserId && record.Primary_Category__c != bridalSalonCategoryId)) {
                            // CSP-2453 DE for Sr. Sales Executive 
                            // Add filter for SSE logic judge need skip assignment or not
                            
                            if(redirectToDELogic(record)) {
                                distributionEngine(record);
                            } else {
                                ownerAssignment(record);
                            }
                        } 
                    }
                }
                else if (oldRecord.Status != 'Valid') {
                    // CSP-2453 DE for Sr. Sales Executive 
                    // Add filter for SSE logic judge need skip assignment or not
                    if(redirectToDELogic(record)) {
                        distributionEngine(record);
                    } else { 
                        ownerAssignment(record);
                    }
                }
            }
            if(record.Status != 'Invalid' && record.Status != 'New') {
                if(String.isNotBlank(record.Potential_Duplicates__c)) {
                    record.Potential_Duplicates__c = '';
                } else if(record.Status != 'Unknown' && record.Status != 'Disqualified' && String.isNotBlank(record.Negative_Disposition_Reason__c)) {
                    record.Negative_Disposition_Reason__c = '';
                }
            } 

            // CSP-1941 Facilitate Lead Qualificiation - Not allow Data enrichment team to change lead status to Disqualified or Qualified
            if(record.Status == 'Qualified'){

                // CSP-2621 Accounts Incorrectly Assigned to "Distributable Accounts" user
                // for those lead owned by distributable queue, we need to assign them to distributable account as user
                // for those lead owned by data enrichment, we need to run through owner assignment rules
                // for those lead owned by individual AEs, keep it as is                
                if(record.Local_Partners_Claiming__c && oldRecord.Status != 'Qualified' && oldRecord.Status != 'Working'){
                    
                    if(!QUEUE_NAME_MAP.isEmpty()){

                        // check if the current lead owner is distributable queue
                        if(QUEUE_NAME_MAP.get('Distributable') != null && record.OwnerId == QUEUE_NAME_MAP.get('Distributable').Id){
                            record.OwnerId = distactAccountId;
                        }
                        // check if the current lead owner is data enrichment
                        else if(QUEUE_NAME_MAP.get('Data Enrichment') != null && record.OwnerId == QUEUE_NAME_MAP.get('Data Enrichment').Id){
                                ownerAssignment(record);

                            // check if the assignment rule not mapped, then system will assign the lead to a specific user and run DE rules
                            if(record.OwnerId == QUEUE_NAME_MAP.get('Distributable').Id){
                                record.OwnerId = Label.LeadOwnerIDForNotMappedAssignmentRule;
                            }
                        }
                        // just in case for the current lead owner is in a queue
                        else if(String.valueOf(record.OwnerId).startsWith('00G')) {
                            record.OwnerId = distactAccountId;
                        }
                    }
                    // SIVA VANKADARU CSP-2802 07/06/2018 BEGIN
                    // IF CLAIMED FROM WEBSITE AS PER LOGIC MENTIONED IN THE REQUIREMENT

                    if (record.Local_Partners_Claiming__c == True && record.Storefront_Status__c == 'Claimed'){

                        // CSP-2992 begin siva vankadaru begin
                        If ( ( SKIP_ASSIGNMENT_RULES_MEMBERS.contains(record.CreatedById) ) || 
                         ( record.LeadSource == 'Self Prospecting'&& record.Category_Group__c == 'Primary' && record.createdbyRoledevelopername__c == 'Inside_Sales_SSE' && record.Portfolio__c == 'Senior Sales Executive' ) ||
                        ( record.LeadSource == 'Self Prospecting' && record.Category_Group__c == 'Secondary' && record.createdbyRoledevelopername__c.contains ('Inside_Sales_OSE') ) ) {
                            record.OwnerId = record.CreatedById;
                        }
                        else if ( (record.LeadSource == 'Paid Media')  ||
                         ( record.LeadSource == 'Self Prospecting' &&  record.Category_Group__c == 'Secondary' && !(record.createdbyRoledevelopername__c.contains ('Inside_Sales_OSE')) ) || 
                          (record.Portfolio__c == 'Senior Sales Executive')
                           ){
                            record.OwnerId = distactAccountId;
                        }
                        else
                         {
                            ownerAssignment(record);
                        } 
                        // CSP-2992 begin siva vankadaru end

                    }
                    // SIVA VANKADARU CSP-2802 07/06/2018 END
                }
                else if(oldRecord.Status == 'Valid'){
                    // CSP-1941 Facilitate Lead Qualificiation - qualified the lead
                    qualifyLead(record);
                }
            }

            // csp-1957: Modify Disqualification Reasons & Routing
            if(record.Status == 'Disqualified') {
                
                if(record.Negative_Disposition_Reason__c != 'Other' && String.isNotBlank(record.Reason_Details__c)) {
                    record.Reason_Details__c = '';
                }
                // selection of Do Not Contact as the reason sets the Lead to an end of life state.
                if(record.Negative_Disposition_Reason__c == 'Do Not Contact' || record.Negative_Disposition_Reason__c == 'Out of Business') {
                    if(QUEUE_NAME_MAP.containsKey('Dead Queue')) {
                        Group deadQueue = QUEUE_NAME_MAP.get('Dead Queue');
                        Group dataEnrichmentQueue = QUEUE_NAME_MAP.get('Data Enrichment');
                        if(oldRecord.OwnerId == record.OwnerId) { // csp-1940
                            record.OwnerId = deadQueue.Id;
                        }
                    }
                }
                // selection of Bad Contact or Duplicate buckets the lead for the Data Enrichment team
                if(record.Negative_Disposition_Reason__c == 'Bad Contact' || record.Negative_Disposition_Reason__c == 'Duplicate') { 
                    if(QUEUE_NAME_MAP.containsKey('Data Enrichment')) {
                        Group dataEnrichmentQueue = QUEUE_NAME_MAP.get('Data Enrichment');
                        if(oldRecord.OwnerId == record.OwnerId) { // csp-1940
                            record.OwnerId = dataEnrichmentQueue.Id;
                        }
                    }
                }
            }

            // CSP-2645
            if (!oldRecord.Related_to_Paid_Media__c 
                && record.Related_to_Paid_Media__c 
                && record.Status != 'Invalid' 
                && record.Status != 'Disqualified'
                && record.Status != 'Unknown' 
                && QUEUE_NAME_MAP.containsKey('Distributable')) {
                
                Group distributableQueue = QUEUE_NAME_MAP.get('Distributable');
                    record.OwnerId = distributableQueue.Id;
                if (record.Status != 'Qualified' && record.Status != 'Working') {
                    record.Status = 'Valid';
                    record.Negative_Disposition_Reason__c = '';
                }
            }else if(record.Related_to_Paid_Media__c 
                    && record.Status == 'Invalid' 
                    && record.Negative_Disposition_Reason__c == 'Duplicate' 
                    && oldRecord.Status == 'Valid'){

                record.OwnerId = (ID)record.PreviousOwner__c;
            }
            // CSP-1852 Assignment Tool Data Points
            // Assign old record owner to previous owner field, calculate the ownership age and assign to ownershipAge field
            if(record.OwnerId != oldRecord.OwnerId && !record.IsConverted){
              record.PreviousOwner__c = leadOwnerNameMap.get(oldRecord.OwnerID);
              record.Ownership_Changed_Date__c = System.today();
            }

        }
    }

    public void beforeDelete(SObject so){
    }
 
    public void afterInsert(SObject so){
        Lead record = (Lead)so;

        if(rtMapById.get(record.RecordTypeId).getName().containsIgnoreCase('Local')){
            // NEED TO FIX THIS SECTION TO AUTOCONVERT A NEW INSERT LEAD IF IT IS QUALIFIED AND CLAIMED!!!
            if(String.isNotBlank(record.DynamicsLeadID__c) && record.Status == 'Qualified' && record.Storefront_Status__c == 'Unclaimed' 
                && XOGroupSettingUtility.getPartnerCalloutSetting()){
                locationIdToFulfill.add(record.DynamicsLeadID__c);
            }

            // CSP-2061 | add new Local Leads to the scoreLeadsIdSet to later score
            scoreLeadsIdSet.add(record.Id);
        }
    }
    
    public void afterUpdate(SObject oldSo, SObject so){
        Lead record = (Lead)so;
        Lead oldRecord = (Lead)oldSo;

        if(rtMapById.get(record.RecordTypeId).getName().containsIgnoreCase('Local') && rtMapById.get(oldRecord.RecordTypeId).getName().containsIgnoreCase('Local')){

            if(!LeadManualStorefrontFulfillmentContr.manualLeadFulfillment && String.isNotBlank(record.DynamicsLeadID__c) && record.Status 
                != oldRecord.Status && record.Status == 'Qualified' && record.Storefront_Status__c == 'Unclaimed' && !record.IsConverted 
                && XOGroupSettingUtility.getPartnerCalloutSetting()){
                locationIdToFulfill.add(record.DynamicsLeadID__c);
            }else if(record.Local_Partners_Claiming__c == false && String.isNotBlank(record.DynamicsLeadID__c) && record.IsConverted == false 
                && record.Status == 'Qualified' && record.Storefront_Status__c == 'Claimed' && (record.Status != oldRecord.Status || record.Storefront_Status__c 
                    != oldRecord.Storefront_Status__c)){
                leadsToConvertIdList.add(record.Id);
            }

            if(record.IsConverted  && !oldRecord.IsConverted){

                AccountContactRole newContactRole = new AccountContactRole();
                newContactRole.Role = 'Primary';
                newContactRole.AccountId = record.ConvertedAccountId;
                newContactRole.ContactId = record.ConvertedContactId;
                convertLeadAccountContactRoleList.add(newContactRole);

                /* may need to re-write this logic */
                if(String.isNotBlank(record.ConvertedOpportunityId)){
                    Opportunity opp = new Opportunity();
                    opp.Id = record.ConvertedOpportunityId;
                    
                    // CSP-1242 Enhancement Request - Opportunities: remove "new internet"
                    opp.Type = 'New';
                    updateOppList.add(opp);
                }

                // CSP-2546 Clone feed from Lead to Account Upon Conversion
                // clone feeds from lead to account or contact
                cloneFeeds(record);
            }

            // CSP-2061 | compare field values to see if any have been updated; if so, the Lead's score needs to be re-evaluated
            for (String scoringField : SCORING_FIELDS_SET) {
                // Note: as of 4-11-17 we are only doing comparisons against text fields
                String oldFieldValue = (String)oldRecord.get(scoringField);
                String newFieldValue = (String)record.get(scoringField);
                if (oldFieldValue != newFieldValue) {
                    scoreLeadsIdSet.add(record.Id);
                    break;
                }
            }
        }
    }

    public void afterDelete(SObject so){
    }   
    
    /**
    * andFinally
    *
    * This method is called once all records have been processed by the trigger. Use this
    * method to accomplish any final operations such as creation or updates of other records.
    */
    public void andFinally(){
    }

    public void beforeAndFinally(){

        // CSP-1851 | create Assignment_History__c records
        if (!localSalesRepAssignmentToLeadListMap.isEmpty()) {
            List<Assignment_History__c> assignmentHistoryInsertList = new List<Assignment_History__c>();
            for (Id localSalesRepAssignmentRecordId : localSalesRepAssignmentToLeadListMap.keySet()) {
                for (Lead newLeadRecord : localSalesRepAssignmentToLeadListMap.remove(localSalesRepAssignmentRecordId)) {
                    Assignment_History__c assignmentHistoryRecord = new Assignment_History__c();
                    assignmentHistoryRecord.Local_Sales_Rep_Assignment__c = localSalesRepAssignmentRecordId;
                    // CSP-2448 - If the Owner starts with 005 then this is a User assignment, else this is a Queue
                    if(String.valueOf(newLeadRecord.OwnerId).startsWith('005')) {
                        assignmentHistoryRecord.User__c = newLeadRecord.OwnerId;
                    } else {
                        assignmentHistoryRecord.Lead_Distribution_Queue_Id__c = newLeadRecord.OwnerId;
                    }
                    
                    assignmentHistoryRecord.Lead__c = newLeadRecord.Id;
                    assignmentHistoryInsertList.add(assignmentHistoryRecord);
                }
            }
            insert assignmentHistoryInsertList;
        }

    }

    public void afterAndFinally(){
        if(!locationIdToFulfill.isEmpty() && XOGroupSettingUtility.getPartnerCalloutSetting()){
            List<RESTLocalStorefrontAPI.ObjectWrapper> objWrapperList = new List<RESTLocalStorefrontAPI.ObjectWrapper>();
            for(String record : locationIdToFulfill){
                RESTLocalStorefrontAPI.ObjectWrapper objWrapper = new RESTLocalStorefrontAPI.ObjectWrapper();
                objWrapper.locationId = record;
                objWrapperList.add(objWrapper);
            }
            PartnerCallouts.partnerOrderCallout(JSON.serializePretty(objWrapperList));
        }

        if(!updateOppList.isEmpty()){
            update updateOppList;
        }

        if(!leadsToConvertIdList.isEmpty()){
            leadConvert = true;
            massConvertLeads();
            leadConvert = false;
        }

        if(!convertLeadAccountContactRoleList.isEmpty()){
            Database.insert(convertLeadAccountContactRoleList, false);
        }
        // CSP-2552 if there are endorsements should be update, updated the endorsements
        if (!updateEndorsementList.isEmpty()) {
            List<Database.SaveResult> saveResultList = Database.update(updateEndorsementList);
            List<XO_Exception__c> xoExceptionList = ExceptionUtility.consumeException(saveResultList);
            if (!xoExceptionList.isEmpty()) {
                insert xoExceptionList;
            }
        }

        // CSP-2061 | score Leads asynchronously since it's a long-running operation
        if (!scoreLeadsIdSet.isEmpty() && !System.isBatch() && !System.isFuture()) {
            LeadAndAccountScoringUtilities.scoreLeadsFutureJob(scoreLeadsIdSet);
        }

    }
     
    /**
     *   [massConvertLeads: This method is used for converting leads to Accounds and Contacts]
     *
     *   @date   2016-11-08
     */
    private void massConvertLeads(){
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true and MasterLabel = 'Qualified' LIMIT 1];
        List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
        for(Id record : leadsToConvertIdList){
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(record);
            lc.convertedStatus = convertStatus.MasterLabel;
            lc.setDoNotCreateOpportunity(true); // CSP-1937
            leadConverts.add(lc);
        }

        if(!leadConverts.isEmpty()){
            for(Integer i = 0; i <= leadConverts.size()/100; i++){
                List<Database.LeadConvert> tempList = new List<Database.LeadConvert>();
                Integer startIndex = i*100;
                Integer endIndex = ((startIndex + 100) < leadConverts.size()) ? startIndex+100 : leadConverts.size();
                for(Integer j = startIndex; j < endIndex; j++){
                    tempList.add(leadConverts[j]);
                }
                Database.LeadConvertResult[] lcrList = Database.convertLead(tempList, false);
                for(Database.LeadConvertResult lcr : lcrList){
                    if(!lcr.isSuccess()) {
                        List<SObject> duplicateRecords = new List<SObject>();
                        Map<String, String> objectToErrorMap = new Map<String, String>();
                        Lead errorLead = (Lead)trigger.newMap.get(lcr.leadId);
                        for(Database.Error error : lcr.getErrors()) {
                            if(error instanceof Database.DuplicateError) {
                                Database.DuplicateError duplicateError = 
                                (Database.DuplicateError)error;
                                Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();
                                
                                // Return only match results of matching rules that 
                                //  find duplicate records
                                Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();

                                // Just grab first match result (which contains the 
                                // duplicate record found and other match info)
                                Datacloud.MatchResult matchResult = matchResults[0];

                                Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();

                                // Add matched record to the duplicate records variable
                                for (Datacloud.MatchRecord matchRecord : matchRecords) {
                                    //this.duplicateRecords.add(matchRecord.getRecord());
                                    duplicateRecords.add(matchRecord.getRecord());
                                }

                                objectToErrorMap.put('Duplicate errors during conversion for Lead: ' + errorLead.Id, String.valueOf(duplicateRecords));
                            } else {
                                objectToErrorMap.put('Error during conversion for Lead: ' + errorLead.Id, String.valueOf(lcr.getErrors()));
                            }
                        }

                        errorLead.addError(String.valueOf(objectToErrorMap));
                    }
                }
            }
        }
    }

    /**
     *   This method is used to assign leads to sales representatives
     *
     *   @date   2016-11-08
     *   @param  {Lead}: Lead record to be updated with the owner id}
     *   @return {Lead} : Lead with Owner id populated
     */
    public static void ownerAssignment(Lead record){ // SIVA VANKADARU CSP - 2927 07-23-2018
        // Lead record assignment code here - The assignmentMap within AssignmentRulesUtility MUST be built prior.
        Local_Sales_Rep_Assignment__c localSalesRepAssignmentRecord = AssignmentRulesUtility.getRecordAssignment(record);

        If(localSalesRepAssignmentRecord != null && String.isNotBlank(localSalesRepAssignmentRecord.Lead_Distribution_Queue_Id__c)) {
            // CSP-2448 - Assign to Lead Queue unless partners is claiming then assign direct to a specified User
            if(record.Local_Partners_Claiming__c) {
                Local_Sales_Rep_Assignment__c directUserAssignment = AssignmentRulesUtility.getRecordAssignment('distacts');
                record.OwnerId = directUserAssignment.Sales_Rep__c;

                // CSP-2448 - Keep track of Queue Assignments
                List<Lead> assignmentHistoryLeadList = localSalesRepAssignmentToLeadListMap.containsKey(directUserAssignment.Id) 
                ? localSalesRepAssignmentToLeadListMap.get(directUserAssignment.Id) : new List<Lead>();
                assignmentHistoryLeadList.add(record);
                localSalesRepAssignmentToLeadListMap.put(directUserAssignment.Id, assignmentHistoryLeadList);
            } 
            else {
                record.OwnerId = localSalesRepAssignmentRecord.Lead_Distribution_Queue_Id__c;
                // CSP-2448 - Keep track of Queue Assignments
                List<Lead> assignmentHistoryLeadList = localSalesRepAssignmentToLeadListMap.containsKey(localSalesRepAssignmentRecord.Id) 
                ? localSalesRepAssignmentToLeadListMap.get(localSalesRepAssignmentRecord.Id) : new List<Lead>();
                assignmentHistoryLeadList.add(record);
                localSalesRepAssignmentToLeadListMap.put(localSalesRepAssignmentRecord.Id, assignmentHistoryLeadList);
            }
        } 
        else if (localSalesRepAssignmentRecord != null && localSalesRepAssignmentRecord.Sales_Rep__c != null) {
            record.OwnerId = localSalesRepAssignmentRecord.Sales_Rep__c;
            // CSP-1851 | populate map to later create Assignment_History__c records
            List<Lead> assignmentHistoryLeadList = localSalesRepAssignmentToLeadListMap.containsKey(localSalesRepAssignmentRecord.Id) ? 
            localSalesRepAssignmentToLeadListMap.get(localSalesRepAssignmentRecord.Id) : new List<Lead>();
            assignmentHistoryLeadList.add(record);
            localSalesRepAssignmentToLeadListMap.put(localSalesRepAssignmentRecord.Id, assignmentHistoryLeadList);
        } 
        else {
            // SIVA VANKADARU CSP-2802 07/06/2018 BEGIN
            // IF CLAIMED FROM WEBSITE AS PER LOGIC MENTIONED IN THE REQUIREMENT
            if (QUEUE_NAME_MAP.containsKey('Distributable') && record.Storefront_Status__c == 'Claimed') {
                if(record.Local_Partners_Claiming__c && QUEUE_NAME_MAP.containsKey('Data Enrichment') ) {
                    record.OwnerId = QUEUE_NAME_MAP.get('Data Enrichment').Id;
                    record.Status = 'Invalid';
                    record.Negative_Disposition_Reason__c = 'Missing Required Information';
                }
                else {
                    Group distributableQueue = QUEUE_NAME_MAP.get('Distributable');
                    record.OwnerId = distributableQueue.Id;
                }
            }
            // SIVA VANKADARU CSP-2802 07/06/2018 END
        }
    }

    /** 
     *   [assignCountry]: Assigning Country based on Zip Code   
     *   @date   2016-11-08
     *   @param  {[Lead record]: Lead record to be updated with the country code.}
     *   @return {Lead}: Updated lead record with the country code
     */
    private Lead assignCountry(Lead record){
        record = (Lead)XOCustomValidationUtility.assignCountryBasedOnZip(record, 'CountryCode', record.PostalCode);
        return record;
    }

    /**
     *    CSP-1941 Facilitate Lead Qualificiation
     *    check last name and first name does not contains "junk" values
     *    check the fields in field set has values
     *    if both of above true, than set the lead status to Qualified, otherwise, Disqualified
     * @param lead record
     * @return qualified or disqualified result
     */
    private void qualifyLead(Lead record){

        // step1: check fields has values
        for(Schema.FieldSetMember fsm : qualifyFilters){
            String val = String.valueOf(record.get(fsm.getFieldPath()));

            if(String.isBlank(val)){
                record.addError(fsm.getLabel() + ' is required');
            }
        }

        // after that, check the last name / first name is contains junk value
        // CSP-2772 Leads Bulk Data Loading bypassing trigger
        // Check the lastName and firstName whether they are null before check the junk value
        if(String.isNotBlank(record.LastName) && LEAD_LASTNAME_FILTERS.contains(String.valueOf(record.LastName).toLowerCase())){
            record.addError('LastName cannot be a junk value');
        }
        else if(String.isNotBlank(record.FirstName) && LEAD_FIRSTNAME_FILTERS.contains(String.valueOf(record.FirstName).toLowerCase())){
            record.addError('FirstName cannot be a junk value');
        }
    }

    /**
     * CSP-2546 Clone feed from Lead to Account Upon Conversion
     * Assign feed items to converted account and contact if they are not null
     * 
     * @Author Nick
     * @Date   2017-11-22
     * @param  record     Converted lead
     */
    private void cloneFeeds(Lead record){

        List<FeedItem> newFeeds = new List<FeedItem>();
        List<FeedItem> itemList = new List<FeedItem>();

        if(feedItemMap.containsKey(record.Id)){
            itemList = feedItemMap.get(record.Id);
        }
        
        if(!itemList.isEmpty()){
            for(FeedItem item : itemList){

                FeedItem feed = new FeedItem();

                // check if the converted lead has converted account id, yes, clone the feed to list
                if(String.isNotBlank(record.ConvertedAccountId)){
                    
                    feed.ParentId = record.ConvertedAccountId;
                    
                    if(String.isNotBlank(item.type)){
                        feed.type = item.type;
                    }

                    if(String.isNotBlank(item.Title)){
                        feed.Title = item.Title;
                    }

                    if(String.isNotBlank(item.Body)){
                        feed.IsRichText = item.IsRichText;
                        feed.Body = item.Body;
                    }

                    if(String.isNotBlank(item.LinkUrl)){
                        feed.LinkUrl = item.LinkUrl;
                    }

                    if(String.isNotBlank(item.RelatedRecordId)){
                        feed.RelatedRecordId = item.RelatedRecordId;
                    }

                    // will only insert those have comments or URLs or attachments feeds
                    if(String.isNotBlank(item.Body) || String.isNotBlank(feed.RelatedRecordId) || String.isNotBlank(feed.LinkUrl)){
                        newFeeds.add(feed);
                    }
                }

                // check if the converted lead has converted contact id, yes, clone the feed to list
                if(String.isNotBlank(record.ConvertedContactId)){
                    
                    feed = new FeedItem();
                    feed.ParentId = record.ConvertedContactId;

                    if(String.isNotBlank(item.type)){
                        feed.type = item.type;
                    }

                    if(String.isNotBlank(item.Title)){
                        feed.Title = item.Title;
                    }

                    if(String.isNotBlank(item.Body)){
                        feed.IsRichText = item.IsRichText;
                        feed.Body = item.Body;
                    }

                    if(String.isNotBlank(item.LinkUrl)){
                        feed.LinkUrl = item.LinkUrl;
                    }

                    if(String.isNotBlank(item.RelatedRecordId)){
                        feed.RelatedRecordId = item.RelatedRecordId;
                    }

                    // will only insert those have comments or URLs or attachments feeds
                    if(String.isNotBlank(item.Body) || String.isNotBlank(feed.RelatedRecordId) || String.isNotBlank(feed.LinkUrl)){
                        newFeeds.add(feed);
                    }
                }
            }
        }

        if(!newFeeds.isEmpty()){
            try {
                insert newFeeds;
            }
            catch (Exception ex) {
                XO_Exception__c xoException = ExceptionUtility.consumeException(ex, false);
                xoException.Severity__c = 'Critical';
                xoException.Failure_Area__c = 'Feed clone to Account and Contact failed during convertion';
            }
        }
    }

    /**
     * CSP-2453 DE for Sr. Sales Executive
     * Determine lead whether skip assignment rule or not
     * 
     * @Author Mason
     * @Date   2018-03-07
     * @param  currentLead lead
     * @return Boolean
     *
     */
    private Boolean redirectToDELogic(Lead currentLead){ // BEGIN SIVA VANKADARU CSP - 2927 07-23-2018
      
        String portfolioStr = ''; 
        // CSP-3075 Update Automation on Lead to fill in Market based on Canadian Zip Codes 
        // Get portfolio info form zip code record base on 5 digits or 3 digits postalCode
        if(String.isNotBlank(currentLead.PostalCode)) {
            String USPostCode = String.valueOf(currentLead.PostalCode.left(5)); 
            String CAPostCode = String.valueOf(currentLead.PostalCode.left(3).toUpperCase()); 

            if(zipCodePortfolioMap.containsKey(USPostCode)) {
                portfolioStr = zipCodePortfolioMap.get(USPostCode);
            }
            else if(zipCodePortfolioMap.containsKey(CAPostCode)) {
                portfolioStr = zipCodePortfolioMap.get(CAPostCode);
            }
        }  

        String currentUserRoleName = userObjList[0].UserRole.Name;
        
        //leadSource is paid media need to skip assignment rule 
        if(currentLead.LeadSource == LEAD_SOURCE_TODISTRIBUTABLE_QUEUE) {
            return true;
        }
        //leadSource is Self prospecting 
        else if(currentLead.LeadSource == 'Self Prospecting') {
            //Category Group is Secondary and role is equal to the Inside or SSE or core AE
            // CSP-2992 begin siva vankadaru begin
            if(currentLead.Category_Group__c == 'Secondary' 
                && (currentUserRoleName.containsIgnoreCase('Inside Sales SSE') 
                || ( currentUserRoleName.containsIgnoreCase('Inside Sales (RSM)') || currentUserRoleName.containsIgnoreCase('Inside Sales OSE') || currentUserRoleName.containsIgnoreCase('Inside Sales (RSD/RSR)') )// should not go to distributable
                || currentUserRoleName.containsIgnoreCase('Sales Representative' ) ) ) {
              return true;
            }
            //Else category group is primary and role is equal to the Inside and Core AE then run skip assignment
            else if(currentLead.Category_Group__c == 'Primary' 
                && ( ( currentUserRoleName.containsIgnoreCase('RSM') || currentUserRoleName.containsIgnoreCase('OSE') || currentUserRoleName.containsIgnoreCase('RSD') ) 
                || currentUserRoleName.containsIgnoreCase('Sales Representative'))) {
              return false;
            }
            //other when lead portfolio is equal to SSE 
            // only for primary categories
            else if(portfolioStr.containsIgnoreCase('Senior Sales Executive')) {
                return true;
            }
            // CSP-2992 begin siva vankadaru end
        }
        //other when lead portfolio is equal to SSE 
        else if(portfolioStr.equalsIgnoreCase('Senior Sales Executive')) {
            return true;
        } 
        return false;
    }

    /**
     * CSP-2453, CSP-2791: Logic for Dsitribution enginer owner assignement 
     * 
     * @Author Ruchit S
     * @Date   2018-04-08
     * @param  currentLead lead
     */
    private void distributionEngine(Lead currentLeadRec) { //  SIVA VANKADARU CSP - 2927 07-23-2018

        
        if(currentLeadRec.LeadSource == 'Self Prospecting' && currentLeadRec.CreatedById != currentLeadRec.OwnerId 
            && String.isEmpty(currentLeadRec.Category_Group__c)) {
                

            // CSP-2992 begin siva vankadaru begin
            if( ( currentLeadRec.CreatedBy.UserRole.Name.contains('Inside Sales (RSM)') || currentLeadRec.CreatedBy.UserRole.Name.contains('Inside Sales OSE')  || currentLeadRec.CreatedBy.UserRole.Name.contains('Inside Sales (RSD/RSR)')) 
                && currentLeadRec.CreatedBy.Profile.Name != System.Label.LocalCoreAccountExecutive
                    && currentLeadRec.Category_Group__c == 'Secondary') {
                currentLeadRec.OwnerId = currentLeadRec.CreatedById;
            } else if (currentLeadRec.CreatedBy.UserRole.Name.contains('Inside Sales SSE') 
                && currentLeadRec.Category_Group__c == 'Secondary') {
                currentLeadRec.OwnerId = currentLeadRec.CreatedById;
            } else if (currentLeadRec.CreatedBy.UserRole.Name.contains('Inside Sales ISE')){
                currentLeadRec.OwnerId = currentLeadRec.CreatedById;
            }
            // CSP-2992 begin siva vankadaru end
        } 
    }
}