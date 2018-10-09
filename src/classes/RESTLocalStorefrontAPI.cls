@RestResource(urlMapping='/LocalStorefront/*')
global with sharing class RESTLocalStorefrontAPI {
    private static Map<String,Schema.RecordTypeInfo> rtLeadMapByName = Schema.SObjectType.Lead.getRecordTypeInfosByName();
    private static Map<String,Schema.RecordTypeInfo> rtAccountMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
    private static Map<String,Schema.RecordTypeInfo> rtOpportunityMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();

    private static List<SObject> duplicateRecords = new List<SObject>();

    ////////////////////////////
    // STATIC FINAL VARIABLES //
    ////////////////////////////
    // Formatting for Error Task Subject
    private static final String errorTaskSubject = '{VENDOR} Claim Issue: {REASON}';
    // User that will be set when claiming - this is in place to protect against assigning Queues to Accounts(Failure)
    // private static final User CLAIMING_USER;

    private static final Group DATA_ENRICHMENT_QUEUE;

    static {
        try {
            // User claimingUser = [SELECT Id FROM User WHERE Alias = 'distacts' LIMIT 1];
            // CLAIMING_USER = claimingUser;

            Group que = [SELECT Id FROM Group WHERE Type='Queue' AND developerName = 'Data_Enrichment' LIMIT 1];
            DATA_ENRICHMENT_QUEUE = que;

        } catch(Exception e) {
            XO_Exception__c newException = ExceptionUtility.consumeException(e, false);
            newException.Severity__c = 'Critical';
            newException.Failure_Area__c = 'Parters Claiming';

            insert newException;
        }
    }

    @HttpPost
    global static LeadSubmissionResponse storefrontFromPartner() {
        
        LeadSubmissionResponse leadResponse = new LeadSubmissionResponse();

        RestRequest sfw = RestContext.request;
        leadResponse.request = sfw.requestBody.toString();

        RestResponse res = RestContext.response;
        System.debug(LoggingLevel.INFO, '*** res: ' + res);

        if (res == null) {
            res = new RestResponse();
            RestContext.response = res;
        }

        try{
            ObjectWrapper thisLead = partnerLocationRequest(sfw.requestBody.toString());
            System.debug(LoggingLevel.INFO, '*** thisLead: ' + thisLead);
            SObject leadRecord;

            // CSP-2107 Remove the existing Lead Source object
            for(Lead record : [SELECT Id, Status, DynamicsLeadID__c, Company, Website, Email, Phone, Street, City, State, PostalCode, Country, 
                                FirstName, LastName, Primary_Category__r.Name, Local_Sales_Market__r.Name,
                                Owner.FirstName, Owner.LastName, Strategy_Specialist__r.FirstName, IsConverted, Partners_Metadata__c,
                                Strategy_Specialist__r.LastName FROM Lead WHERE DynamicsLeadID__c =: thisLead.locationId]){
                leadRecord = record;
            }


            for(Account record : [select Id, Parent.DynamicsAccID__c, DynamicsAccID__c, Name, Website, Email__c, Phone, ShippingStreet, ShippingCity, 
                                    ShippingState, ShippingPostalCode, ShippingCountry, Owner.FirstName, Owner.LastName, Strategy_Specialist__r.FirstName, 
                                    Strategy_Specialist__r.LastName, Partners_Metadata__c, (SELECT Role, Contact.Name FROM AccountContactRoles)
                                 FROM Account WHERE DynamicsAccID__c =: thisLead.locationId]){
                leadRecord = record;
            }

            res.statusCode = 200;
            leadResponse.status = 'success';
            leadResponse.statusCode = 200;
            leadResponse.message = 'SUCCESS: Lead Created!';

            if(leadRecord != null && leadRecord.id != null){
                leadResponse.data = leadRecord;
            }
        }
        catch(Exception e){

            res.statusCode = 400;
            leadResponse.status = 'error';
            leadResponse.statusCode = 400;
            leadResponse.message = 'Failed: Lead Not Created!';

            leadResponse.errors = new ErrorWrapper();
            leadResponse.errors.exceptions.add(e.getMessage());

            if(!duplicateRecords.isEmpty()){
                leadResponse.errors.duplicates = duplicateRecords;
            }
        }

        Map<String, Object> partnerJSON = (Map<String,Object>)JSON.deserializeUntyped(sfw.requestBody.toString());
        
        Object metaObj = partnerJSON.get('metadata');

        leadResponse.metadata = JSON.serialize(metaObj);

        return leadResponse;
    }

    // maybe convert this to a list of sObjects for Leads and Created Account data?
    private static ObjectWrapper partnerLocationRequest(String reqString){
        Map<String, Object> partnerJSON = (Map<String,Object>)JSON.deserializeUntyped(reqString);
        
        Object metaObj = partnerJSON.get('metadata');
        partnerJSON.remove('metadata');
        System.debug(LoggingLevel.INFO, '*** partnerJSON: ' + partnerJSON);

        LeadPayloadWrapper sfw = (LeadPayloadWrapper)JSON.deserialize(JSON.serialize(partnerJSON), LeadPayloadWrapper.class);
        system.debug(sfw);

        sfw.metadata = metaObj;

        ObjectWrapper objWrapper = new ObjectWrapper();

        system.debug( ' sfw.companyId : ' + sfw.companyId);
        system.debug( ' sfw.locationId : ' + sfw.locationId);
        
        if(String.isBlank(sfw.companyId) && String.isBlank(sfw.locationId)){
            // Completely new unclaimed Lead. i.e. Bride enters Storefront info
            objWrapper = newLocationNoClaimingAccount(sfw);
            system.debug( ' newLocationNoClaimingAccount ' );
        }

        else if(String.isBlank(sfw.companyId) && String.isNotBlank(sfw.locationId)){
            // Existing Lead but no existing account is claiming it. Can be a new account wanting to claim their storefront
            objWrapper = existingLocationNewClaimingAccount(sfw);
            system.debug( ' existingLocationNewClaimingAccount ' );
        }

        else if(String.isNotBlank(sfw.companyId) && String.isBlank(sfw.locationId)){
            // An existing Vendor enterring a new Storefront they want to claim.
            objWrapper = newLocationWithClaimingAccount(sfw);
            system.debug( ' newLocationWithClaimingAccount ' );
        }

        else if(String.isNotBlank(sfw.companyId) && String.isNotBlank(sfw.locationId)){
            // An existing Vendor claiming an unclaimed Storefront.
            objWrapper = existingLocationWithClaimingAccount(sfw);
            system.debug( ' existingLocationWithClaimingAccount ' );
        }

        return objWrapper;
    }

    public class ObjectWrapper{
        public String companyId;
        public String locationId;
    }

    // For completely new unclaimed Lead. i.e. Bride enters Storefront info
    private static ObjectWrapper newLocationNoClaimingAccount(LeadPayloadWrapper sfw){
        ObjectWrapper objWrapper = new ObjectWrapper();

        // Create new Lead
        Lead newLead = leadMapping(sfw);
        System.debug(LoggingLevel.INFO, '*** step1 newLead: ' + newLead);

        //Contact Info
        newLead.FirstName = sfw.contact.firstName;
        newLead.LastName = sfw.contact.lastName;
        newLead.Fulfill_Storefront__c = true;

        sfw.fulfillmentData.tier = (String.isNotBlank(sfw.fulfillmentData.tier) && sfw.fulfillmentData.tier != null) ? sfw.fulfillmentData.tier : 'Freemium';

        newLead.Fulfillment_Data__c = JSON.serializePretty(sfw.fulfillmentData); //USING DESCRIPTION FIELD FOR TESTING PURPOSES
        newLead.Partners_Metadata__c = (sfw.metadata != null) ? JSON.serializePretty(sfw.metadata) : '';

        Database.SaveResult saveResult = Database.insert(newLead, false);

        if (!saveResult.isSuccess()) {

            // CSP-1937
            Boolean isDuplicateError = checkDupe(saveResult);

            System.debug(LoggingLevel.INFO, '*** isDuplicateError: ' + isDuplicateError);

            // CSP-1937 | if it's a duplicate error push it through anyway, but set the Lead Status as "Duplicate"
            if (isDuplicateError) {
                Database.DMLOptions dml = new Database.DMLOptions();
                dml.DuplicateRuleHeader.allowSave = true;
                newLead.Status = 'Invalid';
                newLead.Invalid_Reason__c = 'Duplicate';
                newLead.Negative_Disposition_Reason__c = 'Duplicate';
                newLead.Reason_Details__c = '';
                Database.SaveResult sr = Database.insert(newLead, dml);

                if (!sr.isSuccess()) {

                    System.debug(LoggingLevel.INFO, '*** sr: ' + sr);

                    throw new ApplicationException('Failed to create new Lead record in Salesforce.');
                }
            }
            else {
                insert newLead;
            }
        }

        String guid = [select DynamicsLeadID__c from Lead where Id =: newLead.Id].DynamicsLeadID__c;
        objWrapper.locationId = guid;

        return objWrapper;
    }

    // Existing Lead but no existing account is claiming it. Can be a new account wanting to claim their storefront
    private static ObjectWrapper existingLocationNewClaimingAccount(LeadPayloadWrapper sfw){
        ObjectWrapper objWrapper = new ObjectWrapper();

        // Allow ability for Accounts to be claimed - CSP-274
        // CSP-2558 Duplicate Handling for Claim Requests - query lead record if it is same dynamic id
        List<Lead> existingLeadList = [SELECT Status, IsConverted FROM Lead WHERE DynamicsLeadID__c = :sfw.locationId LIMIT 1];

        List<Account> existingAccountList = [SELECT Id, DynamicsAccID__c, ParentId, Parent.Name, Parent.DynamicsAccID__c FROM Account
                                            WHERE DynamicsAccID__c = :sfw.locationId LIMIT 1];

        Lead newLead = new Lead();

        System.debug(LoggingLevel.INFO, '*** existingLeadList: ' + existingLeadList);

        if(existingAccountList != null && existingAccountList.size() > 0) {

            Account existingAccount = existingAccountList[0];

            // CSP-1783 - Modify the "Fulfilled" field to be false. There are instances where this field is being 
            // set to true but is not a true state for the Account.
            existingAccount.Fulfilled__c = false;

            // Need to reset this flag so that the logic to Fulfill will fire
            if(existingAccount.Fulfill_Storefront__c){

                try {
                    existingAccount.Fulfill_Storefront__c = false;
                    update existingAccount;
                }
                catch (Exception ex){

                    ExceptionUtility.consumeException(ex, true);
                    // ERROR - Why is there a converted Lead but the Account is not in the system?!
                    throw new ApplicationException('Account update error.');
                }
            }

            // set the fulfill storefront to true and make this account sync back/update back to partners again
            try {
                existingAccount.Fulfill_Storefront__c = true;
                update existingAccount;
            }
            catch (Exception ex){
                ExceptionUtility.consumeException(ex, true);
                // ERROR - Why is there a converted Lead but the Account is not in the system?!
                throw new ApplicationException('Account sync back to partners failed.');
            }

            System.debug(LoggingLevel.INFO, '*** existingLeadList: ' + existingAccount);

            objWrapper.companyId = existingAccount.DynamicsAccID__c;
            objWrapper.locationId = existingAccount.DynamicsAccID__c;
            return objWrapper;
        }

        // CSP-2558 Duplicate Handling for Claim Requests
        // No change yet, but need epm decide how to be good for this case
        else if(existingLeadList != null && existingLeadList.size() > 0 && existingLeadList[0].IsConverted) {
            newLead = existingLeadList[0];
            // ERROR - Why is there a converted Lead but the Account is not in the system?!
            throw new ApplicationException('Converted Lead exists in the system but no associated Account.');
        }

        // CSP-2558 Duplicate Handling for Claim Requests
        // If the existing lead is unconverted, will assign leads
        else if(existingLeadList != null && existingLeadList.size() > 0 && !existingLeadList[0].IsConverted){
            newLead = existingLeadList[0];
        }

        // lead mapping to this lead
        newLead = leadMapping(sfw);

        //Contact Info
        newLead.FirstName = sfw.contact.firstName;
        newLead.LastName = sfw.contact.lastName;
        newLead.Fulfill_Storefront__c = true;

        newLead.Fulfillment_Data__c = JSON.serializePretty(sfw.fulfillmentData);
        newLead.Partners_Metadata__c = (sfw.metadata != null) ? JSON.serializePretty(sfw.metadata) :'';JSON.serializePretty(sfw.metadata);


        // Creates a new lead, or updates it, depending if it finds the GUID in the system
        Schema.SObjectField dynamicsLeadIdSchema = Lead.Fields.DynamicsLeadID__c;
        Database.UpsertResult upsertResult = Database.upsert(newLead, dynamicsLeadIdSchema, false);
        
        List<XO_Exception__c> exceptionList = new List<XO_Exception__c>();

        if(!upsertResult.isSuccess()) {
            System.debug(LoggingLevel.INFO, '*** upsertResult: ' + upsertResult);
            // CSP-1937
            Boolean isDuplicateError = checkDupe(upsertResult);

            // CSP-1937 | if it's a duplicate error push it through anyway, but set the Lead Status as "Duplicate"
            if (isDuplicateError) {

                Database.DMLOptions dml = new Database.DMLOptions();
                dml.DuplicateRuleHeader.allowSave = true;
                newLead.Status = 'Invalid';
                newLead.Invalid_Reason__c = 'Duplicate';
                newLead.Negative_Disposition_Reason__c = 'Duplicate';
                newLead.Reason_Details__c = '';
                Database.SaveResult sr;
                
                // CSP-2558 Duplicate Handling for Claim Requests
                // check the lead has Id or not, if it's brand new lead, insert it, otherwise, update it
                if(String.isBlank(newLead.Id)){

                    sr = Database.insert(newLead, dml);

                    // if insert failed, have to throw out exceptions
                    if (!sr.isSuccess()){
                        Database.SaveResult[] saveResult = new Database.SaveResult[]{sr};
                        exceptionList = ExceptionUtility.consumeException(saveResult);
                        if (!exceptionList.isEmpty()) {
                            insert exceptionList;
                        }
                        throw new ApplicationException('Failed to create new Lead record in Salesforce.');
                    }
                }
                else{

                    sr = Database.update(newLead, dml);

                    // if update failed, have to throw out exceptions
                    if (!sr.isSuccess()){
                        Database.SaveResult[] saveResult = new Database.SaveResult[]{sr};
                        exceptionList = ExceptionUtility.consumeException(saveResult);
                        if (!exceptionList.isEmpty()) {
                            insert exceptionList;
                        }
                        throw new ApplicationException('Failed to update Lead record in Salesforce.');
                    }
                }
            }

            else {
                Database.UpsertResult[] upsertResults = new Database.UpsertResult[]{upsertResult};
                exceptionList = ExceptionUtility.consumeException(upsertResults);
                if (!exceptionList.isEmpty()) {
                    insert exceptionList;
                }
                throw new ApplicationException('Failed to create Lead record in Salesforce with failed claim request.');
            }
        }

        // executing lead convertion
        if(sfw.isClaiming != null && sfw.isClaiming){
            
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(newLead.Id);
            lc.setDoNotCreateOpportunity(true);

            LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true and MasterLabel = 'Qualified' LIMIT 1];
            lc.setConvertedStatus(convertStatus.MasterLabel);
            Database.LeadConvertResult lcr;

            // CSP-1937 | the reason we have this try/catch block here, instead of solely relying on the Database.LeadConvertResult.isSuccess()
            // value, is that during the conversion a DMLException for DUPLICATES_DETECTED is being thrown that isn't captured in the 
            // Database.LeadConvertResult object. We still have the Database.LeadConvertResult.isSuccess() check after this try/catch block in 
            // case something changes, but as of March 8, 2017 the execution flow never reaches that logic block.
            try {
                lcr = Database.convertlead(lc);
            }
            catch(Exception e){

                System.debug(LoggingLevel.INFO, '*** e: ' + e);
                System.debug(LoggingLevel.INFO, '*** newLead beginning: ' + newLead);
                // if duplicated, we will need to convert again and skip the duplication rules, assign error task to Data team or admin
                if(e.getMessage().containsIgnoreCase('DUPLICATES_DETECTED')){

                    Database.DMLOptions dml = new Database.DMLOptions();
                    dml.DuplicateRuleHeader.AllowSave = true;

                    lc = new Database.LeadConvert();
                    lc.setLeadId(newLead.Id);
                    lc.setDoNotCreateOpportunity(true);
                    lc.setConvertedStatus(convertStatus.MasterLabel);

                    Database.LeadConvertResult convertResult = Database.convertlead(lc, dml);

                    if(convertResult.isSuccess()){
                        
                        User taskOwner = retrieveClaimErrorUser();
                        // CSP-2558 Duplicate Handling for Claim Requests
                        // generate error task to Account owner
                        List<Lead> tempLead = [SELECT Id, ConvertedAccountId FROM Lead WHERE Id =: newLead.Id LIMIT 1];
                        Task errorTask = generateClaimErrorTask(sfw, tempLead[0].ConvertedAccountId, taskOwner.id, Label.Claiming_error_duplicated);
                        Database.SaveResult insertResult = Database.insert(errorTask, false);
                        
                    }
                    // if with unknown reason
                    else{
                        XO_Exception__c ex = ExceptionUtility.consumeException('Lead convert failed','Failed Claim Request',false,'');
                        insert ex;

                        // CSP-2558 Duplicate Handling for Claim Requests
                        // If non-duplicate exception, we would like to update back the lead to invalid and disposition reason to Failed Claim Request
                        System.debug(LoggingLevel.INFO, '*** newLead121: ' + newLead);

                        newLead.Status = 'Invalid';
                        newLead.Invalid_Reason__c = 'Other';
                        newLead.Negative_Disposition_Reason__c = 'Failed Claim Request';
                        newLead.Reason_Details__c = '';
                        newlead.Storefront_Status__c= 'Unclaimed';
                        newLead.OwnerId = DATA_ENRICHMENT_QUEUE.Id;
                        Database.SaveResult sr = Database.update(newLead, false);
                        throw new ApplicationException('Convert lead in Salesforce is failed by claim request.');
                    }
                }

                // if with unknown reason
                else{
                    XO_Exception__c ex = ExceptionUtility.consumeException('Lead convert failed','Failed Claim Request',false,'');
                    insert ex;
                    
                    System.debug(LoggingLevel.INFO, '*** newLead122: ' + newLead);
                    // CSP-2558 Duplicate Handling for Claim Requests
                    // If non-duplicate exception, we would like to update back the lead to invalid and disposition reason to Failed Claim Request
                    newLead.Status = 'Invalid';
                    newLead.Invalid_Reason__c = 'Other';
                    newLead.Negative_Disposition_Reason__c = 'Failed Claim Request';
                    newLead.Reason_Details__c = '';
                    newLead.OwnerId = DATA_ENRICHMENT_QUEUE.Id;
                    newlead.Storefront_Status__c= 'Unclaimed';
                    Database.SaveResult sr = Database.update(newLead, false);
                    throw new ApplicationException('Convert lead in Salesforce is failed by claim request.');
                }
            }
        }

        objWrapper.companyId = newLead.DynamicsLeadID__c;
        if (String.isBlank(objWrapper.locationId)) {
            objWrapper.locationId = newLead.DynamicsLeadID__c;
        }
        return objWrapper;
    }

    // An existing Vendor enterring a new Storefront they want to claim.
    private static ObjectWrapper newLocationWithClaimingAccount(LeadPayloadWrapper sfw){
        ObjectWrapper objWrapper = new ObjectWrapper();

        Account acct = [select Id, DynamicsAccID__c from Account where DynamicsAccID__c =: sfw.companyId];
        objWrapper.companyId = acct.DynamicsAccID__c; 

        // Create new Lead
        Lead newLead = leadMapping(sfw);

        //Contact Info
        newLead.FirstName = sfw.contact.firstName;
        newLead.LastName = sfw.contact.lastName;
        newLead.Fulfill_Storefront__c = true;
        // CSP-1783
        newLead.Claim_Upon_Conversion__c = sfw.isClaiming;

        sfw.fulfillmentData.parentGUID = sfw.companyId;
        sfw.fulfillmentData.tier = (String.isNotBlank(sfw.fulfillmentData.tier) && sfw.fulfillmentData.tier != null) ? sfw.fulfillmentData.tier : 'Freemium';

        newLead.Fulfillment_Data__c = JSON.serializePretty(sfw.fulfillmentData);
        newLead.Partners_Metadata__c = (sfw.metadata != null) ? JSON.serializePretty(sfw.metadata) : '';

        Database.SaveResult saveResult = Database.insert(newLead, false);
        System.debug(LoggingLevel.INFO, '*** step 3 saveResult: ' + saveResult);
        if (!saveResult.isSuccess()) {

            // csp-1937
            Boolean isDuplicateError = checkDupe(saveResult);

            System.debug(LoggingLevel.INFO, '*** step 3 isDuplicateError: ' + isDuplicateError);

            // CSP-1937 | if it's a duplicate error push it through anyway, but set the Lead Status as "Duplicate"
            if (isDuplicateError) {
                Database.DMLOptions dml = new Database.DMLOptions();
                dml.DuplicateRuleHeader.allowSave = true;
                newLead.Status = 'Invalid';
                newLead.Invalid_Reason__c = 'Duplicate';
                newLead.Negative_Disposition_Reason__c = 'Duplicate';
                newLead.Reason_Details__c = '';
                Database.SaveResult sr = Database.insert(newLead, dml);
                System.debug(LoggingLevel.INFO, '*** sr: ' + sr);
                if (!sr.isSuccess()) {
                    throw new ApplicationException('Failed to create new Lead record in Salesforce.');
                }
            }
            else {
                // CSP-2769 Claiming a lead from Partners not converting correctly
                // added try catch to return a exception
                // insert newLead;
                try {
                  insert newLead;
                }
                catch (Exception ex) {
                  
                  ExceptionUtility.consumeException(ex, true);

                  throw new ApplicationException('Failed to create new Lead record in Salesforce.');
                  return objWrapper;
                }
            }
        }

        if(sfw.isClaiming != null && sfw.isClaiming){
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(newLead.Id);
            lc.setDoNotCreateOpportunity(true);

            LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true and MasterLabel = 'Qualified' LIMIT 1];
            lc.setConvertedStatus(convertStatus.MasterLabel);
            Database.LeadConvertResult lcr;

            // CSP-2769 Claiming a lead from Partners not converting correctly
            // added try-catch to catch the duplicates error and then create the error task or create a xoexception.

            try{
                lcr = Database.convertlead(lc);
            } 
            catch(Exception e){
                if(e.getMessage().containsIgnoreCase('DUPLICATES_DETECTED')){

                    Database.DMLOptions dml = new Database.DMLOptions();
                    dml.DuplicateRuleHeader.allowSave = true;

                    lc = new Database.LeadConvert();
                    lc.setLeadId(newLead.Id);
                    lc.setDoNotCreateOpportunity(true);
                    lc.setConvertedStatus(convertStatus.MasterLabel);
                    
                    lcr = Database.convertlead(lc, dml);

                    if(lcr.isSuccess()){
                        
                        // CSP-2769 Claiming a lead from Partners not converting correctly
                        // if the lead convert to a duplicate account, created a task related to the duplicate account
                        User taskOwner = retrieveClaimErrorUser();
                        // CSP-2558 Duplicate Handling for Claim Requests
                        // generate error task to Account owner
                        List<Lead> tempLead = [SELECT Id, ConvertedAccountId FROM Lead WHERE Id =: newLead.Id LIMIT 1];
                        Task errorTask = generateClaimErrorTask(sfw, tempLead[0].ConvertedAccountId, taskOwner.id, Label.Claiming_error_duplicated);
                        Database.SaveResult insertResult = Database.insert(errorTask, false);
                        
                        Account location = new Account();
                        location.Id = lcr.getAccountId();
                        location.ParentId = acct.Id;
                        //update location;

                        String guid = [select DynamicsAccID__c from Account where Id =: location.Id].DynamicsAccID__c;
                        objWrapper.locationId = guid;
                    }
                    // CSP-2769 Claiming a lead from Partners not converting correctly
                    // if with unknown reason, create a XOexception and update the lead back to invalid
                    else{
                        XO_Exception__c ex = ExceptionUtility.consumeException('Lead convert failed','Failed Claim Request',false,'');
                        insert ex;

                        // CSP-2558 Duplicate Handling for Claim Requests
                        // If non-duplicate exception, we would like to update back the lead to invalid and disposition reason to Failed Claim Request
                        System.debug(LoggingLevel.INFO, '*** newLead121: ' + newLead);

                        newLead.Status = 'Invalid';
                        newLead.Invalid_Reason__c = 'Other';
                        newLead.Negative_Disposition_Reason__c = 'Failed Claim Request';
                        newLead.Reason_Details__c = '';
                        newlead.Storefront_Status__c= 'Unclaimed';
                        newLead.OwnerId = DATA_ENRICHMENT_QUEUE.Id;
                        Database.SaveResult sr = Database.update(newLead, false);
                        throw new ApplicationException('Convert lead in Salesforce is failed by claim request.');
                    }
                }
                // CSP-2769 Claiming a lead from Partners not converting correctly
                // if with unknown reason to convert failed, create a XOexception and update the lead back to invalid
                else{

                    XO_Exception__c ex = ExceptionUtility.consumeException('Lead convert failed','Failed Claim Request',false,'');
                    insert ex;
                    
                    System.debug(LoggingLevel.INFO, '*** newLead122: ' + newLead);
                    // CSP-2558 Duplicate Handling for Claim Requests
                    // If non-duplicate exception, we would like to update back the lead to invalid and disposition reason to Failed Claim Request
                    newLead.Status = 'Invalid';
                    newLead.Invalid_Reason__c = 'Other';
                    newLead.Negative_Disposition_Reason__c = 'Failed Claim Request';
                    newLead.Reason_Details__c = '';
                    newLead.OwnerId = DATA_ENRICHMENT_QUEUE.Id;
                    newlead.Storefront_Status__c= 'Unclaimed';
                    Database.SaveResult sr = Database.update(newLead, false);
                    throw new ApplicationException('Convert lead in Salesforce is failed by claim request.');
                }   
            }
        }
        System.debug(LoggingLevel.INFO, '*** : objWrapper' + objWrapper);
        return objWrapper;
    }

    private static ObjectWrapper existingLocationWithClaimingAccount(LeadPayloadWrapper sfw){
        ObjectWrapper objWrapper = new ObjectWrapper();

        // CSP-2737 Claiming a lead from Partners to an existing account throws a Salesforce Duplication Error
        // Modify the claiming logic for specific account
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        
        // Allow ability for Accounts to be claimed - CSP-274
        List<Lead> existingLeadList = [SELECT Status FROM Lead WHERE DynamicsLeadID__c = :sfw.locationId AND IsConverted = true LIMIT 1];
        List<Account> existingAccountList = [SELECT Id, DynamicsAccID__c, Fulfill_Storefront__c, ParentId, Parent.Name, Parent.DynamicsAccID__c FROM Account WHERE DynamicsAccID__c = :sfw.locationId LIMIT 1];
        

        if(existingAccountList != null && existingAccountList.size() > 0) {
            
            Account existingAccount = existingAccountList[0];
            // CSP-1783 - Modify the "Fulfilled" field to be false. There are instances where this field is being 
            // set to true but is not a true state for the Account.
            // if fufill the account failed, created a xoexception and return a error message to partners
            existingAccount.Fulfilled__c = false;

            if(sfw.companyId == sfw.locationId) {
                if(existingAccount.Fulfill_Storefront__c) {
                    existingAccount.Fulfill_Storefront__c = false;

                    try {
                      update existingAccount;
                    }
                    catch (Exception ex) {
                      
                      ExceptionUtility.consumeException(ex, true);

                      throw new ApplicationException('Account update error before fulfill to partners.');
                    }
                }

                existingAccount.Fulfill_Storefront__c = true;

                try {
                  update existingAccount;
                }
                catch (Exception ex) {
                  
                  ExceptionUtility.consumeException(ex, true);

                  throw new ApplicationException('Account update error after fulfill to partners.');
                }

                objWrapper.locationId = existingAccount.DynamicsAccID__c;
                objWrapper.companyId = existingAccount.DynamicsAccID__c;
                return objWrapper;
            }

            if(String.isNotBlank(existingAccount.ParentId) && sfw.companyId != existingAccount.Parent.DynamicsAccID__c) {
                // ERROR - Existing Account has the wrong parent account!
                User taskOwner = retrieveClaimErrorUser();
                
                // If taskOwner exists then generate the claim error task
                if(taskOwner != null) {
                    Task errorTask = generateClaimErrorTask(sfw, existingAccount.Id, taskOwner.Id, Label.Different_Existing_Parent);

                    Database.SaveResult insertResult = Database.insert(errorTask, false);
                    ExceptionUtility.consumeException(insertResult, true);
                }
                
                throw new ApplicationException('Account trying to be claimed has a different parent in Salesforce.');
                return objWrapper;
            }

            Account parentAccount;

            try {
                parentAccount = [SELECT Id, DynamicsAccID__c FROM Account WHERE DynamicsAccID__c = :sfw.companyId];
            } 
            catch(Exception e) {
                // ERROR - Parent Account does not exist in our system!
                User taskOwner = retrieveClaimErrorUser();

                if(taskOwner != null) {
                    Task errorTask = generateClaimErrorTask(sfw, existingAccount.Id, taskOwner.id, Label.Parent_Account_Does_Not_Exist);

                    Database.SaveResult insertResult = Database.insert(errorTask, false);
                    ExceptionUtility.consumeException(insertResult, true);
                }

                throw new ApplicationException('Parent Account with Location Id: ' + sfw.companyId + ' does not exist in Salesforce.');
                return objWrapper;
            }


            if(existingAccount.Fulfill_Storefront__c) {
                existingAccount.Fulfill_Storefront__c = false;

                try {
                  update existingAccount;
                }
                catch (Exception ex) {
                  
                  ExceptionUtility.consumeException(ex, true);

                  throw new ApplicationException('Account update error before fulfill to partners.');
                }
            }

            existingAccount.ParentId = parentAccount.Id;
            existingAccount.Fulfill_Storefront__c = true;

            try {
              update existingAccount;
            }
            catch (Exception ex) {
              
              ExceptionUtility.consumeException(ex, true);

              throw new ApplicationException('Account update error after fulfill to partners.');
            }
            
            objWrapper.locationId = existingAccount.DynamicsAccID__c;
            objWrapper.companyId = parentAccount.DynamicsAccID__c; 
            return objWrapper;
        } 
        else if(existingLeadList != null && existingLeadList.size() > 0) {
            Lead existingLead = existingLeadList[0];
            // ERROR - Why is there a converted Lead but the Account is not in the system?!
            throw new ApplicationException('Converted Lead exists in the system but no associated Account.');
        }

        Account acct = new Account();
        for(Account record : [select Id, DynamicsAccID__c from Account where DynamicsAccID__c =: sfw.companyId]){
            acct = record;
        }

        if(String.isBlank(acct.Id)){
            system.debug('No Account Found');
            return objWrapper;
        }
        objWrapper.companyId = acct.DynamicsAccID__c;

        Lead newLead = leadMapping(sfw);

        //Contact Info
        newLead.FirstName = sfw.contact.firstName;
        newLead.LastName = sfw.contact.lastName;
        newLead.Fulfill_Storefront__c = true;
        // CSP-1783
        newLead.Claim_Upon_Conversion__c = sfw.isClaiming;

        sfw.fulfillmentData.parentGUID = sfw.companyId;
        sfw.fulfillmentData.tier = (String.isNotBlank(sfw.fulfillmentData.tier) && sfw.fulfillmentData.tier != null) ? sfw.fulfillmentData.tier : 'Freemium';

        newLead.Fulfillment_Data__c = JSON.serializePretty(sfw.fulfillmentData);
        newLead.Partners_Metadata__c = (sfw.metadata != null) ? JSON.serializePretty(sfw.metadata) : '';

        // Creates a new lead, or updates it, depending if it finds the GUID in the system
        Schema.SObjectField dynamicsLeadIdSchema = Lead.Fields.DynamicsLeadID__c;
        Database.UpsertResult upsertResult = Database.upsert(newLead, dynamicsLeadIdSchema, false);
        
        List<XO_Exception__c> exceptionList = new List<XO_Exception__c>();

        if(!upsertResult.isSuccess()) {

            // csp-1937
            Boolean isDuplicateError = checkDupe(upsertResult);

            // for(Database.Error currentError : upsResult.getErrors()) {
            //     if(currentError instanceof Database.DuplicateError) {

            //         Database.DuplicateError currentDuplicate = (Database.DuplicateError)currentError;

            //         Datacloud.DuplicateResult duplicateResult = currentDuplicate.getDuplicateResult();

            //         List<Datacloud.MatchResult> matchResults = duplicateResult.getMatchResults();

            //         // Documentation has to just grab the first match result record - no documentation as to why..
            //         List<Datacloud.MatchRecord> matchRecords = matchResults[0].getMatchRecords();

            //         for(Datacloud.MatchRecord matchRecord : matchRecords) {
            //             duplicateRecords.add(matchRecord.getRecord());
            //         }
            //         isDuplicateError = true;
            //     } else {
            //         throw new ApplicationException(JSON.serialize(currentError));//.replace('\\', ''));
            //     }
            // }
            
            // CSP-1937 | if it's a duplicate error push it through anyway, but set the Lead Status as "Duplicate"
            if (isDuplicateError) {

                newLead.Status = 'Invalid';
                newLead.Invalid_Reason__c = 'Duplicate';
                newLead.Negative_Disposition_Reason__c = 'Duplicate';
                newLead.Reason_Details__c = '';
                Database.SaveResult sr;
                
                // CSP-2558 Duplicate Handling for Claim Requests
                // check the lead has Id or not, if it's brand new lead, insert it, otherwise, update it
                if(String.isBlank(newLead.Id)){

                    sr = Database.insert(newLead, dml);

                    // if insert failed, have to throw out exceptions
                    if (!sr.isSuccess()){
                        Database.SaveResult[] saveResult = new Database.SaveResult[]{sr};
                        exceptionList = ExceptionUtility.consumeException(saveResult);
                        if (!exceptionList.isEmpty()) {
                            insert exceptionList;
                        }
                        throw new ApplicationException('Failed to create new Lead record in Salesforce.');
                    }
                }
                else{

                    sr = Database.update(newLead, dml);

                    // if update failed, have to throw out exceptions
                    if (!sr.isSuccess()){
                        Database.SaveResult[] saveResult = new Database.SaveResult[]{sr};
                        exceptionList = ExceptionUtility.consumeException(saveResult);
                        if (!exceptionList.isEmpty()) {
                            insert exceptionList;
                        }
                        throw new ApplicationException('Failed to update Lead record in Salesforce.');
                    }
                }
            }

            else {
                Database.UpsertResult[] upsertResults = new Database.UpsertResult[]{upsertResult};
                exceptionList = ExceptionUtility.consumeException(upsertResults);
                if (!exceptionList.isEmpty()) {
                    insert exceptionList;
                }
                throw new ApplicationException('Failed to create Lead record in Salesforce with failed claim request.');
            }

            // if(duplicateRecords.size() > 0) {
            //     throw new ApplicationException('Duplicates Found');
            // }

            // // CSP-1937 | if it's a duplicate error push it through anyway, but set the Lead Status as "Duplicate"
            // if (isDuplicateError) {
            //     newLead.Status = 'Invalid';
            //     newLead.Invalid_Reason__c = 'Duplicate';
            //     newLead.Negative_Disposition_Reason__c = 'Duplicate';
            //     newLead.Reason_Details__c = '';
            //     Database.SaveResult sr = Database.insert(newLead, dml);
            //     if (!sr.isSuccess()) {
            //         throw new ApplicationException('Failed to create new Lead record in Salesforce.');
            //     }
            // }
        }

        Lead leadRecord = [select Id, IsConverted, ConvertedAccountId from Lead where DynamicsLeadID__c =: sfw.locationId];
        
        if(leadRecord != null && !leadRecord.IsConverted && sfw.isClaiming != null && sfw.isClaiming){
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(leadRecord.Id);
            lc.setDoNotCreateOpportunity(true);

            LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true and MasterLabel = 'Qualified' LIMIT 1];
            lc.setConvertedStatus(convertStatus.MasterLabel);
            Database.LeadConvertResult lcr;

            try {
                lcr = Database.convertlead(lc);
            }
            catch(Exception e){

                System.debug(LoggingLevel.INFO, '*** e: ' + e);
                System.debug(LoggingLevel.INFO, '*** newLead beginning: ' + newLead);
                // if duplicated, we will need to convert again and skip the duplication rules, assign error task to Data team or admin
                if(e.getMessage().containsIgnoreCase('DUPLICATES_DETECTED')){

                    lc = new Database.LeadConvert();
                    lc.setLeadId(newLead.Id);
                    lc.setDoNotCreateOpportunity(true);
                    lc.setConvertedStatus(convertStatus.MasterLabel);

                    lcr = Database.convertlead(lc, dml);
                    
                    if(lcr.isSuccess()){
                        
                        User taskOwner = retrieveClaimErrorUser();
                        // CSP-2558 Duplicate Handling for Claim Requests
                        // generate error task to Account owner
                        List<Lead> tempLead = [SELECT Id, ConvertedAccountId FROM Lead WHERE Id =: newLead.Id LIMIT 1];
                        Task errorTask = generateClaimErrorTask(sfw, tempLead[0].ConvertedAccountId, taskOwner.id, Label.Claiming_error_duplicated);
                        Database.SaveResult insertResult = Database.insert(errorTask, false);
                        
                        Account location = new Account();
                        location.Id = lcr.getAccountId();
                        location.ParentId = acct.Id;
                        //update location;

                        String guid = [select DynamicsAccID__c from Account where Id =: location.Id].DynamicsAccID__c;
                        objWrapper.locationId = guid;
                    }
                    // if with unknown reason
                    else{
                        XO_Exception__c ex = ExceptionUtility.consumeException('Lead convert failed','Failed Claim Request',false,'');
                        insert ex;

                        // CSP-2558 Duplicate Handling for Claim Requests
                        // If non-duplicate exception, we would like to update back the lead to invalid and disposition reason to Failed Claim Request
                        System.debug(LoggingLevel.INFO, '*** newLead121: ' + newLead);

                        newLead.Status = 'Invalid';
                        newLead.Invalid_Reason__c = 'Other';
                        newLead.Negative_Disposition_Reason__c = 'Failed Claim Request';
                        newLead.Reason_Details__c = '';
                        newlead.Storefront_Status__c= 'Unclaimed';
                        newLead.OwnerId = DATA_ENRICHMENT_QUEUE.Id;
                        Database.SaveResult sr = Database.update(newLead, false);
                        throw new ApplicationException('Convert lead in Salesforce is failed by claim request.');
                    }
                }

                // if with unknown reason
                else{
                    XO_Exception__c ex = ExceptionUtility.consumeException('Lead convert failed','Failed Claim Request',false,'');
                    insert ex;
                    
                    System.debug(LoggingLevel.INFO, '*** newLead122: ' + newLead);
                    // CSP-2558 Duplicate Handling for Claim Requests
                    // If non-duplicate exception, we would like to update back the lead to invalid and disposition reason to Failed Claim Request
                    newLead.Status = 'Invalid';
                    newLead.Invalid_Reason__c = 'Other';
                    newLead.Negative_Disposition_Reason__c = 'Failed Claim Request';
                    newLead.Reason_Details__c = '';
                    newLead.OwnerId = DATA_ENRICHMENT_QUEUE.Id;
                    newlead.Storefront_Status__c= 'Unclaimed';
                    Database.SaveResult sr = Database.update(newLead, false);
                    throw new ApplicationException('Convert lead in Salesforce is failed by claim request.');
                }
            }

        }
        else if(leadRecord != null && leadRecord.IsConverted){
            // NEED TO THROW ERROR HERE SINCE IT'S BEEN CLAIMED!!!
            system.debug('THIS STOREFRONT HAS BEEN CLAIMED');
            throw new ApplicationException('The claiming lead has been converted in Salesforce.');
        }

        return objWrapper;
    }


    private static Lead leadMapping(LeadPayloadWrapper sfw){
        Lead newLead = new Lead();

        newLead.RecordTypeId = rtLeadMapByName.get('Local').getRecordTypeId();
        newLead.DynamicsLeadID__c = sfw.locationId;
        newLead.Company = sfw.companyName;
        newLead.Website = sfw.website;
        newLead.Email = sfw.email;
        newLead.Phone = sfw.phone;
        newLead.Street = (String.isNotBlank(sfw.address[0].street1)) ? sfw.address[0].street1 : '';
        newLead.Street += (String.isNotBlank(sfw.address[0].street2)) ? '\r\n' + sfw.address[0].street2 : '';
        newLead.City = sfw.address[0].city;

        System.debug(LoggingLevel.INFO, '*** newlead 1: ' + newlead);
        if(String.isNotBlank(sfw.address[0].stateOrProvince) && 
            sfw.address[0].stateOrProvince.length() == 2){
            newLead.StateCode = sfw.address[0].stateOrProvince;
        }
        else if(String.isNotBlank(sfw.address[0].stateOrProvince) && 
            sfw.address[0].stateOrProvince.length() != 2){
            newLead.State = sfw.address[0].stateOrProvince;
        }

        newLead.PostalCode = sfw.address[0].postalCode;

        if(String.isNotBlank(sfw.address[0].country) && 
            sfw.address[0].country.length() != 2){
            newLead.Country = sfw.address[0].country;
        }
        else if(String.isNotBlank(sfw.address[0].country) && 
            sfw.address[0].country.length() == 2){
            newLead.CountryCode = sfw.address[0].country;
        }

        if(String.isBlank(newLead.CountryCode) && 
            String.isNotBlank(newLead.PostalCode)){

            newLead = (Lead)XOCustomValidationUtility.assignCountryBasedOnZip(newLead, 'CountryCode', newLead.PostalCode);
        }

        // CSP-1940 - Assignment/Queue Logic addition
        if(sfw.isClaiming != null && sfw.isClaiming) {
            newLead.Status = 'Qualified';
            newLead.Local_Partners_Claiming__c = true;
            newLead.Storefront_Status__c = 'Claimed';
            
            // CSP-2621 Accounts Incorrectly Assigned to "Distributable Accounts" user
            // List<Lead> existingLeadList = [SELECT Id, OwnerId FROM Lead WHERE DynamicsLeadID__c = :newLead.DynamicsLeadID__c LIMIT 1];
            
            // if(!existingLeadList.isEmpty()) {
            //     Lead checkLead = existingLeadList[0];
            //     // If the current Owner is a Queue(essentially a group) then set it to the Account Distribution user
            //     if(String.valueOf(checkLead.OwnerId).startsWith('00G')) {
            //         newLead.OwnerId = CLAIMING_USER.Id;
            //     }
            // } 
            // // No Lead exists meaning this is a brand new Lead - set the owner as the Account Distribution user
            // else {
            //     newLead.OwnerId = CLAIMING_USER.Id;
            // }
        } 
        else {
            newLead.Status = 'New';
            newLead.Storefront_Status__c = 'Unclaimed';
        }
        newLead.Interest_in_Adv_in_Multiple_Categories__c = sfw.fulfillmentData.multipleCategoryInterest;

        newLead.Tier__c = sfw.fulfillmentData.tier; // csp-2070

        Market__c mkt = new Market__c();
        String mktCode = (XOGroupSettingUtility.lpSFMarketCodeMap().containsKey(sfw.fulfillmentData.marketCode)) ? XOGroupSettingUtility.lpSFMarketCodeMap().get(sfw.fulfillmentData.marketCode) : sfw.fulfillmentData.marketCode;

        for(Market__c record : [select Id from Market__c where Market_ID__c =: mktCode AND Market_ID__c != null]){
            mkt = record;
        }

        if(String.isBlank(mkt.Id) && String.isNotBlank(sfw.fulfillmentData.marketCode) && sfw.fulfillmentData.marketCode != null){
            throw new ApplicationException('Incorrect Market Code');
        }

        Category__c cat = new Category__c();
        for(Category__c record : [select Id from Category__c where Taxonomy_ID__c =: sfw.fulfillmentData.categoryId]){
            cat = record;
        }

        if(String.isBlank(cat.Id) && String.isNotBlank(sfw.fulfillmentData.categoryId) && sfw.fulfillmentData.categoryId != null){
            throw new ApplicationException('Incorrect Category Id');
        }

        // CSP-2107 Remove the existing Lead Source object
        // newLead.Lead_Source__c = leadSource.Id;//[select Id from Lead_Source__c where Dynamics_Lead_Source_ID__c =: sfw.leadSourceCode limit 1].Id;
        newLead.Local_Sales_Market__c = mkt.Id; //[select Id from Market__c where Market_ID__c =: sfw.fulfillmentData.marketCode limit 1].Id;
        newLead.Primary_Category__c = cat.Id;//[select Id from Category__c where Taxonomy_ID__c =: sfw.fulfillmentData.categoryId limit 1].Id;
        
        newLead.LeadBU__c = 'Local';

        // CSP-1937 Lead Creation with Duplicate Tracking (from TK Pro) - assign lead source to TK Pro
        newLead.LeadSource = 'Website';
        
        if(String.isNotBlank(sfw.fulfillmentData.tier)){
            if(sfw.fulfillmentData.tier.equalsIgnoreCase('Limited')){
                newLead.Lead_Sub_Source__c= 'Freemium';
            }
            else if(sfw.fulfillmentData.tier.equalsIgnoreCase('Standard')){
                newLead.Lead_Sub_Source__c= 'Standard';
            }
            else if(sfw.fulfillmentData.tier.equalsIgnoreCase('Featured')){
                newLead.Lead_Sub_Source__c= 'Featured';
            }
            else{
                newLead.Lead_Sub_Source__c= 'Contact Us';
            }
        }

        return newLead;
    }



    private static Task generateClaimErrorTask(LeadPayloadWrapper sfw, String accountId, String ownerId, String reasonString) {
        String contactName = '';
        if(String.isNotBlank(sfw.contact.firstName)) {
            contactName += sfw.contact.firstName;
        }

        if(String.isNotBlank(sfw.contact.lastName)) {
            // Trim will remove the leading space if the first name failed to exist and append above
            contactName += ' ' + sfw.contact.lastName;
        }

        contactName = contactName.trim();

        Task errorTask = new Task();
        errorTask.Claiming_Task_Type__c = 'Claiming';
        errorTask.WhatId = accountId;
        errorTask.OwnerId = ownerId;
        errorTask.Subject = errorTaskSubject.replace('{VENDOR}', contactName);
        errorTask.Subject = errorTask.Subject.replace('{REASON}', reasonString);
        errorTask.Description = 'Contact Information: \r\n'
                                 + 'Firstname: ' + (String.isNotBlank(sfw.contact.firstName) ? sfw.contact.firstName : '') + '\r\n'
                                 + 'Lastname: ' + (String.isNotBlank(sfw.contact.lastName) ? sfw.contact.lastName : '') + '\r\n'
                                 + 'Email: ' + (String.isNotBlank(sfw.email) ? sfw.email : '') + '\r\n'
                                 + 'Phone: ' + (String.isNotBlank(sfw.phone) ? sfw.phone : '') + '\r\n \r\n'
                                + 'Company Information: \r\n'
                                 + 'Company name: ' + (String.isNotBlank(sfw.companyName) ? sfw.companyName : '') + '\r\n'
                                 + 'Location Id: ' + (String.isNotBlank(sfw.locationId) ? sfw.locationId : '') + '\r\n'
                                 + 'Parent Account Location Id: ' + (String.isNotBlank(sfw.companyId) ? sfw.companyId : '') + '\r\n';
        return errorTask;
    }

    /**
     *   Method used to retrieve a claim error user. Currently this defaults to Callie Thomas as per CSP-274 on 10-19-2016.
     *   If Callie Thomas is not found for some reason then ANY active System Administrator is retrieved.
     *
     *   @author Justin
     *   @date   2016-10-19
     *   @return {User}     The retrieved user that will be used to assign to claim error tasks.
     */
    private static User retrieveClaimErrorUser() {
        for(User currentUser : [SELECT Id FROM User WHERE Id =: Label.ClaimingTaskOwner AND IsActive = true LIMIT 1]) {
            return currentUser;
        }

        // Default to any ACTIVE System Administrator if Callie Thomas cannot be found
        for(User currentUser : [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1]) {
            return currentUser;
        }

        return null;
    }

    private static void createInquiryTasks(LeadPayloadWrapper sfw){
        try{
            Account inquiredAccount = [select Id, OwnerId, Name from Account where DynamicsAccID__c = :sfw.locationId limit 1];

            Task inquiryTask = new Task();
            inquiryTask.WhatId = inquiredAccount.Id;
            inquiryTask.OwnerId = inquiredAccount.OwnerId;
            inquiryTask.Subject = (String.isNotBlank(sfw.contact.firstName)) ? sfw.contact.firstName + ' ' : ''; 
            inquiryTask.Subject += (String.isNotBlank(sfw.contact.lastName)) ? sfw.contact.lastName + ' ' : ''; 
            inquiryTask.Subject += 'Inquired to Upgrade the Storefront for this Location';
            inquiryTask.Description = inquiryTask.Subject;
            inquiryTask.Description += (String.isNotBlank(sfw.phone) ? '\r\n Phone: ' + sfw.phone : '') + ((String.isNotBlank(sfw.email) ? '\r\n Email: ' + sfw.email : ''));
            
            insert inquiryTask;
        }catch(Exception e){
            system.debug(e.getMessage());
            ExceptionUtility.consumeException(e, true);
        }
    }

    global class LeadSubmissionResponse{
        global String status {get; set;}
        global Integer statusCode {get; set;}
        global String message {get; set;}
        global SObject data {get; set;}
        global String request {get; set;}
        global ErrorWrapper errors {get; set;}
        global String metadata {get; set;}
    }

    global class ErrorWrapper{
        global List<String> validations {get; set;}
        global List<String> exceptions {get; set;}
        global List<SObject> duplicates {get; set;}

        global ErrorWrapper(){
            validations = new List<String>();
            exceptions = new List<String>();
            duplicates = new List<SObject>();
        }
    }

    /**
     * CSP-1937 Lead Creation with Duplicate Tracking (from TK Pro)
     * Use to check if has duplicate reocrds when doing upsertion.
     *
     * @author Nick
     * @date   2017-09-22 
     * @return [has duplicated records]
     */
    public static Boolean checkDupe(Database.UpsertResult upsertResult){
        // CSP-1937
        Boolean isDuplicateError = false;

        for(Database.Error currentError : upsertResult.getErrors()) {
            System.debug(LoggingLevel.INFO, '*** currentError: ' + currentError);
            if(currentError instanceof Database.DuplicateError) {
                Database.DuplicateError currentDuplicate = (Database.DuplicateError)currentError;

                Datacloud.DuplicateResult duplicateResult = currentDuplicate.getDuplicateResult();
                System.debug(LoggingLevel.INFO, '*** upsert duplicateResult: ' + duplicateResult);
                List<Datacloud.MatchResult> matchResults = duplicateResult.getMatchResults();

                // Documentation has to just grab the first match result record - no documentation as to why..
                List<Datacloud.MatchRecord> matchRecords = matchResults[0].getMatchRecords();

                for(Datacloud.MatchRecord matchRecord : matchRecords) {
                    duplicateRecords.add(matchRecord.getRecord());
                    isDuplicateError = true;
                }
            }
        }

        // if(duplicateRecords.size() > 0) {
        //     throw new ApplicationException('Duplicates Found');
        // }
        return isDuplicateError;
    }

    /**
     * CSP-1937 Lead Creation with Duplicate Tracking (from TK Pro)
     * Use to check if has duplicate reocrds when doing insertion.
     *
     * @author Nick
     * @date   2017-09-22 
     * @return [has duplicated records]
     * 
     */
    public static Boolean checkDupe(Database.SaveResult saveResult){
        // CSP-1937
        Boolean isDuplicateError = false;

        for (Database.Error error : saveResult.getErrors()) {
            if (error instanceof Database.DuplicateError) {
                Database.DuplicateError duplicateError = (Database.DuplicateError)error;
                Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();
                System.debug(LoggingLevel.INFO, '*** insert duplicateResult: ' + duplicateResult);
                // Return only match results of matching rules that find duplicate records
                Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();

                // Just grab first match result (which contains the 
                //   duplicate record found and other match info)
                Datacloud.MatchResult matchResult = matchResults[0];
                Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();

                // Add matched record to the duplicate records variable
                for (Datacloud.MatchRecord matchRecord : matchRecords) {
                    System.debug('MatchRecord: ' + matchRecord.getRecord());
                    //this.duplicateRecords.add(matchRecord.getRecord());
                    duplicateRecords.add(matchRecord.getRecord());
                    isDuplicateError = true;
                }
                
            }
        }
        return isDuplicateError;
    }

}