trigger OpportunityTrigger on Opportunity (before insert, before update, after insert, after update) {

    Map<Id,Schema.RecordTypeInfo> rtMapById = Schema.SObjectType.Opportunity.getRecordTypeInfosById();
  
    Set<Id> setAccountIds = new Set<Id>();
    Map<Id, Account> mapAccounts;

    // CSP-2821 Selling to a Prospect
    private Set<Id> sellingAccountSet = new Set<Id>();
    private List<Account> needUpdateAccList = new List<account>();
    private List<Account> sellingAccountList = new List<Account>();
    private Set<Id> activeSubAccSet = new Set<Id>();

    // CSP-2821/CSP-2831 Using to store the account set for filtering
    private Map<Id, Account> needUpdateAccMap = new Map<Id, Account>();

    // 05/31/2017 - Change by Justin - Commenting this out as CSP-2114 is being held.
    //List<Task> taskList = new List<Task>();

    if(Trigger.isInsert && Trigger.isBefore) {
        for(Opportunity o: Trigger.new){           
            setAccountIds.add(o.AccountId);
        }
        mapAccounts = new Map<Id,Account>([select id,name from Account where id in : setAccountIds]);       

        // Code that works to populate the Opp name if it is blank befort insert.
        for(Integer i = 0; i < Trigger.new.size(); i++) {
            Opportunity currentOpp = Trigger.new[i];
            String oppRecordTypeName = rtMapById.get(currentOpp.RecordTypeId).getName();
             String oppAccountName = '';
             if(mapAccounts.containsKey(currentOpp.AccountId)) {
                oppAccountName = mapAccounts.get(currentOpp.AccountId).Name;
            }
            if(oppAccountName.length() > 40)
                oppAccountName = oppAccountName.left(40);
            if(String.isBlank(currentOpp.Name) && oppRecordTypeName == 'Local') {
                currentOpp.Name = oppRecordTypeName +' - '+oppAccountName+' - '+Datetime.now().format('MM/YYYY');    
            }    
        }
    }

    //Om's Code starts here
    /* 
    <trigger> 
       <purpose>For Locking and Unlocking the quotes on an opportunity</purpose>
      <created>
        <by>Om Vankayalapati</by>
        <date>10/08/2015</date>
        <ticket>SF- 1498 - Generic Quote To Cash Stories</ticket>
      </created>
    </trigger>
    */
    // CSP-1553 use batch instead of workflow to send quotes to ZBilling 
    // List<Integer> localClientApprovedIndexList = new List<Integer>(); 
    List<Integer> localPendingInteralApprovalIndexList = new List<Integer>(); 
    List<Integer> localIndexList = new List<Integer>(); 
    String internalApprovalStage = 'Pending Internal Approval';
    Map<Id, Opportunity> oppsThatSkippedCalculatingTCVStage = new Map<Id, Opportunity>();
    List<Id> oppsThatNeedTCVCalculationIdList = new List<Id>();
    
    // for ticket CSP-2114, store the CLient Approved Opportunity Id  
    Set<Id> clientApprovedOppIdSet = new Set<Id>();

    if(trigger.isUpdate) {
        //CSP-986 | Prevent a Closed Opportunity from being Re-opened
        Set<String> allowUpdateFieldSet = new Set<String>();
        List<Schema.FieldSetMember> fsmList = Schema.SObjectType.Opportunity.fieldSets.getMap().get('Close_Fields_AllowToUpdate').getfields();
        for(Schema.FieldSetMember fs : fsmList ){
            allowUpdateFieldSet.add(fs.getFieldPath().toLowerCase());
        }
        RecordType rtClosedLost = new RecordType();
        RecordType rtClosedWon = new RecordType();
        List<RecordType> rtList= [Select Id, Name from RecordType Where SObjectType = 'Opportunity' and Name like '%Local%'];
        for(RecordType rt : rtList){
            if(rt.Name == 'Local - Closed Lost'){
                rtClosedLost = rt;
            }
            if(rt.Name == 'Local - Closed Won'){
                rtClosedWon = rt;
            }
        }
        // CSP-986 end
        
        // CSP-1610 | if Opportunity_Expiration_Date__c changed, update the zqu__ValidUntil__c field on child Quote records
        Map<Id, Date> oppIDAndExpirationDateMap = new Map<Id,Date>();
        // CSP-1869 | if Local Opportunity.Type changed update all related zqu__QuoteRatePlanCharge__c.Is_Possible_Renewal__c values to the correct value
        Map<Id, String> oppIdToOppTypeMap = new Map<Id, String>();
        List<User> userList = [Select Id, Profile.Name From User Where Id = :UserInfo.getUserId()];
        for(Integer i = 0; i < trigger.new.size(); i++){
            Opportunity record = trigger.new[i];
            Opportunity oldRecord = Trigger.oldMap.get(record.Id);
            if(rtMapById.get(record.RecordTypeId).getName().containsIgnoreCase('Local')){               
                if (trigger.isBefore){
                    // CSP-986 | Prevent a Closed Opportunity from being Re-opened 
                    if(oldRecord.StageName == 'Closed Won' || oldRecord.StageName == 'Closed Lost'){
                        // CSP-2272 Handling Production QA Test orders - Add TestData Record Type to Opportunities
                        // System Admins should be allowed to change the opportunity record type at any time
                        
                        if(userList.size() > 0 && userList[0].Profile.Name != 'System Administrator'){
                            Map<String, Schema.SObjectField> oppFieldsMap  = Schema.SObjectType.Opportunity.fields.getMap(); 
                            for(String field: oppFieldsMap.Keyset()) {
                                if(record.get(field)!=oldRecord.get(field) && !allowUpdateFieldSet.contains(field.toLowerCase())){

                                    String errmsg = '';
                                    if(oldRecord.StageName == 'Closed Won'){
                                        errmsg = System.Label.Opportunity_Closed_Won_Reopen_Error;
                                    }else{
                                        errmsg = System.Label.Opportunity_Closed_Lost_Reopen_Error;
                                    }
                                    errmsg = errmsg + '(error updating field: ' + oppFieldsMap.get(field).getDescribe().getLabel() + ')';
                                    record.addError(errmsg);
                                }
                            }
                        }
                    }
                    // CSP-2272 Handling Production QA Test orders - Add TestData Record Type to Opportunities
                    Boolean isLocalTestRecordType = rtMapById.get(record.RecordTypeId).getName().containsIgnoreCase('Test');
                    if(record.StageName == 'Closed Won' && !isLocalTestRecordType){
                        record.RecordTypeId = rtClosedWon.Id;
                    }
                    if(record.StageName == 'Closed Lost' && !isLocalTestRecordType){
                        record.RecordTypeId = rtClosedLost.Id;
                    }
                    // CSP-986 end
                    
                    // CSP-550 | if Opp stage skips from Quoting or Pending Internal Approval to Client Approved, this indicates that the Opp has a Cancellation Quote
                    // however, prior to this fix it didn't take into consideration whether there was also a New or Amendment Quote as well, skipping Echosign
                    // this code checks to see if there is a New or Amendment Quote and if so, sets the Opp stage to Calculating TCV
                    // CSP-1787 | added logic in the IF statement to exclude records that have the Opportunity.Approval_Process_Flag_Skip_EchoSign__c flag set to true
                    if ((oldRecord.StageName == 'Quoting' || oldRecord.StageName == 'Pending Internal Approval') && record.StageName == 'Client Approved' && record.Approval_Process_Flag_Skip_EchoSign__c == false) {
                        oppsThatSkippedCalculatingTCVStage.put(record.Id, record);
                    }

                    // CSP-634 | uncheck this box if StageName != 'Client Approved'
                    if (record.NeedToSendToZBilling__c && record.StageName != 'Client Approved' && (record.NeedToSendToZBilling__c != trigger.OldMap.Get(record.Id).NeedToSendToZBilling__c)) {
                        record.NeedToSendToZBilling__c = false;
                    }

                    // CSP-635 | don't allow Echosign (or anyone) to move the stage from Client Approved or Closed Won if there are Signed Echosign Agreements for that Opportunity
                    // for ticket CSP-1634, when local user click the button "Unlock the Quote", the Stage move to "Quoting" from "Client Approved"
                    //if ((oldRecord.StageName == 'Client Approved' || oldRecord.StageName == 'Closed Won') && record.Stagename != 'Closed Won') {
                    if (oldRecord.StageName == 'Closed Won' && record.Stagename != 'Closed Won') {
                        Integer signedAgreementCount = [SELECT COUNT() FROM echosign_dev1__SIGN_Agreement__c WHERE echosign_dev1__Opportunity__c = :record.Id AND echosign_dev1__StatusVisible__c = 'Signed'];
                        if (signedAgreementCount > 0) {
                            record.StageName = oldRecord.StageName;
                        }
                    }
                    
                    if (oldRecord.StageName != 'Calculating TCV' && record.StageName == 'Calculating TCV') {
                        // CSP-1181 | retrieve the "true TCV" values for the Opportunity and all child Quote records
                        record.Zuora_Quote_PDF_Session_Id__c = UserInfo.getSessionId();
                        oppsThatNeedTCVCalculationIdList.add(record.Id);
                    } 
                    // CSP-2078 - Modifying the "Skip EchoSign" logic to happen AFTER Calculating TCV happens to ensure
                    // that the PDF documents get generated.
                    else if(oldRecord.StageName != 'Ready for Echo-Sign' && record.StageName == 'Ready for Echo-Sign' && record.Approval_Process_Flag_Skip_EchoSign__c) {
                        record.StageName = 'Client Approved';
                    }

                    // CSP-1818 / CSP-1787 | if the "skip echosign" checkbox is deselected, automatically clear out the "Skip_EchoSign_Reason_Code__c" field
                    if (record.Approval_Process_Flag_Skip_EchoSign__c == false && oldRecord.Approval_Process_Flag_Skip_EchoSign__c == true) {
                        record.Skip_EchoSign_Reason_Code__c = '';
                    }     
                }              
                if (trigger.isAfter){
                    if (OppLocalPendingApprovalTriggerHandler.ObjectMeetsCriteriaForTrigger(record, trigger.oldMap.get(record.Id))){
                        System.Debug('Record found awaiting internal approval:' + record.Id);
                        localPendingInteralApprovalIndexList.add(i);
                    }
                    // CSP-1553 use batch instead of workflow to send quotes to ZBilling 
                    // if (record.NeedToSendToZBilling__c && record.NeedToSendToZBilling__c != trigger.OldMap.Get(record.Id).NeedToSendToZBilling__c){
                    //  localClientApprovedIndexList.add(i);
                    // }
                    if (oldRecord.Opportunity_Expiration_Date__c != record.Opportunity_Expiration_Date__c) {
                        oppIDAndExpirationDateMap.put(record.Id, record.Opportunity_Expiration_Date__c);
                    }

                    // CSP-1869 | if Opportunity.Type changed add to map for later processing
                    if (record.Type != oldRecord.Type) {
                        oppIdToOppTypeMap.put(record.Id, record.Type);
                    }   

                    // for ticket CSP-2114, if Opportunity has been set to 'Client Approved', we maybe created a new case base on the account info and quote info
                    if (oldRecord.StageName != 'Client Approved' && record.StageName == 'Client Approved' && record.Date_Client_Approved__c == null) {
                        clientApprovedOppIdSet.add(record.Id);
                    }                  
                }
            }
        }               

        // CSP-1869 | if Local Opportunity.Type changed update all related zqu__QuoteRatePlanCharge__c.Is_Possible_Renewal__c values to the correct value
        if (!oppIdToOppTypeMap.isEmpty()) {
            List<zqu__QuoteRatePlanCharge__c> qrpcUpdateList = [SELECT Is_Possible_Renewal__c, zqu__QuoteRatePlan__r.zqu__Quote__r.zqu__Opportunity__c FROM zqu__QuoteRatePlanCharge__c WHERE zqu__QuoteRatePlan__r.zqu__Quote__r.zqu__Opportunity__c IN :oppIdToOppTypeMap.keySet()];
            for (Integer i = 0; i < qrpcUpdateList.size(); i++) {
                zqu__QuoteRatePlanCharge__c qrpcRecord = qrpcUpdateList[i];
                String oppType = oppIdToOppTypeMap.get(qrpcRecord.zqu__QuoteRatePlan__r.zqu__Quote__r.zqu__Opportunity__c);
                qrpcRecord.Is_Possible_Renewal__c = oppType == 'Renewal' ? 'Yes' : 'No';
            }
            if (qrpcUpdateList.size() > 0) {
                Database.SaveResult[] srListNew = Database.update(qrpcUpdateList, false);
                List<XO_Exception__c> xoExceptionList = ExceptionUtility.consumeException(srListNew);
                if (xoExceptionList.size() > 0) {
                    insert xoExceptionList;
                }               
            }
        }


        if (!oppIDAndExpirationDateMap.isEmpty()) {
            List<zqu__Quote__c> quoteUpdateList = [SELECT Id, zqu__Opportunity__c, zqu__ValidUntil__c FROM zqu__Quote__c WHERE zqu__Opportunity__c IN :oppIDAndExpirationDateMap.keySet()];
            for (zqu__Quote__c quoteRecord : quoteUpdateList) {
                quoteRecord.zqu__ValidUntil__c = oppIDAndExpirationDateMap.get(quoteRecord.zqu__Opportunity__c);
            }

            // set this static variable to true so the ZuoraQuoteTriggerHandler doesn't unnecessarily perform the same update (more efficient and saves SOQL queries)
            ZuoraQuoteTriggerHandler.validUntilDateUpdatedFromOpportunityTrigger = true;

            update quoteUpdateList;
        }

        // for the ticket CSP-2114, if an Opporutniy has been client approved, we should create an Onboarding Case when the opporunity fixed the following condition:
        // 1 the Opp contains the following Services:
                                            // "Storefront", 
                                            //"Bridal Salon Referral Program-Gown - Storefront", 
                                            //"Bridal Salon Referral Program-Bridal Party - Storefront", 
                                            // "Jewelry Store Referral Program-Jewelry Search - Storefront"
        // 2 the Account has not had services with us for > 1year
        if (!clientApprovedOppIdSet.isEmpty()) {

            Map<String, Schema.RecordTypeInfo> caseRecTypeNameMap = Schema.SObjectType.Case.getRecordTypeInfosByName();
            List<Group> queueList = [SELECT Id FROM Group WHERE DeveloperName = 'Onboarding_case_queue' AND Type = 'Queue' limit 1];

            // get the accountID of the Opp which contains the products up
            Set<Id>  accountIdSet = new Set<Id>();

            // get all the products name in the condition to created a case.
            List<String> onboardingCaseProductNameList = System.Label.OnboardingCaseProductName.split('\n');
            Set<String> onboardingCaseProductNameSet = new Set<String>();

            // use the query String for added product into the custom label 
            String qrpQueryString = 'SELECT id,name,zqu__Quote__r.zqu__Opportunity__c,zqu__Quote__r.zqu__Opportunity__r.AccountId ';
            qrpQueryString += 'FROM zqu__QuoteRatePlan__c ';
            qrpQueryString += 'WHERE zqu__Quote__r.zqu__Opportunity__c IN: clientApprovedOppIdSet ';
            // CSP-2694 Update Onboarding Case Generation Logic
            // Added a query filter string to store the product name filter
            String queryFilterString = '';
            if (onboardingCaseProductNameList.size() > 1) {
                for (String productName :  onboardingCaseProductNameList) {
                    onboardingCaseProductNameSet.add(productName.trim());
                }  
                qrpQueryString += 'AND zqu__QuoteProductName__c IN: onboardingCaseProductNameSet';
                queryFilterString += 'AND Product_Name_Text__c IN: onboardingCaseProductNameSet';
            }else{
                qrpQueryString += 'AND zqu__QuoteProductName__c = \'' + onboardingCaseProductNameList[0] +'\'';
                queryFilterString += 'AND Product_Name_Text__c = \'' + onboardingCaseProductNameList[0] +'\'';
            }


            List<zqu__QuoteRatePlan__c> onboardingCaseQRPList = Database.query(qrpQueryString);
            
            for (zqu__QuoteRatePlan__c zquQRP : onboardingCaseQRPList) {
                accountIdSet.add(zquQRP.zqu__Quote__r.zqu__Opportunity__r.AccountId);
            }
            // CSP-2694 Update Onboarding Case Generation Logic
            // query the subscription product charge for the Storefront product
            String spcQueryString = 'SELECT Id,Zuora__Subscription__c, Zuora__Subscription__r.Zuora__TermStartDate__c, ';
            spcQueryString += 'Zuora__Subscription__r.Zuora__TermEndDate__c, Zuora__Subscription__r.Zuora__Status__c, ';
            spcQueryString += 'Zuora__Subscription__r.Zuora__Account__c FROM Zuora__SubscriptionProductCharge__c ';
            spcQueryString += 'WHERE Zuora__Subscription__r.Zuora__Account__c IN: accountIdSet AND Zuora__Subscription__r.Zuora__TermEndDate__c > N_DAYS_AGO:365 ';
            spcQueryString += queryFilterString;

            List<Zuora__SubscriptionProductCharge__c> subscriptionPCList = Database.query(spcQueryString);


            for (Zuora__SubscriptionProductCharge__c currentSPC : subscriptionPCList) {
                Zuora__Subscription__c  currentSub = currentSPC.Zuora__Subscription__r;
                if (currentSub.Zuora__TermStartDate__c < currentSub.Zuora__TermEndDate__c && accountIdSet.contains(currentSub.Zuora__Account__c)) {
                    accountIdSet.remove(currentSub.Zuora__Account__c);
                }
            }

            //Get all the accounts that a case need created for it. 
            List<Account> accountList = [SELECT Id,Strategy_Specialist__c, Strategy_Specialist__r.Email,
                                                                                    Strategy_Specialist__r.Name, 
                                                                                    ( SELECT ContactId, AccountId 
                                                                                            FROM AccountContactRoles 
                                                                                            WHERE Role in ('Primary','Billing') 
                                                                                                AND Contact.Status__c = 'Active' 
                                                                                            ORDER BY Role ASC, CreatedDate DESC limit 1) 
                                                                        FROM Account 
                                                                        WHERE Id IN: accountIdSet];

            List<Case> newCaseList = new List<Case>();

            for (Account currentAccount : accountList) {
                Case caseRecord = new Case();
                caseRecord.AccountId = currentAccount.Id;
                // if the account have primary contact, assigned the newest contact role's contact to case contact
                if (currentAccount.AccountContactRoles.size()>0) {
                    caseRecord.ContactId = currentAccount.AccountContactRoles[0].ContactId;
                }
                caseRecord.RecordTypeId = caseRecTypeNameMap.get('2 - Onboarding').getRecordTypeId();
                caseRecord.Origin = 'Auto Generated';
                // CSP-3195 Route All Onboarding Cases to Queue
                // 100% of onboarding cases that are created should be routed to the "Onboarding" queue
                caseRecord.OwnerId = queueList[0].Id;
                caseRecord.Priority = 'High';
                caseRecord.Reason = 'Onboarding';
                caseRecord.Subject = 'Onboarding';
                caseRecord.Attempts__c = '0';
                caseRecord.Follow_Up_Attempts__c = '0';
                caseRecord.No_Show_Attempts__c = '0';
                newCaseList.add(caseRecord);
            }

            if (!newCaseList.isEmpty()) {

                List<Database.SaveResult> saveResultsList = Database.insert(newCaseList);
                List<XO_Exception__c> xoExceptionList = ExceptionUtility.consumeException(saveResultsList);

                if (!xoExceptionList.isEmpty()) {
                    insert xoExceptionList;
                } 
            }
        }
    }
    
    // CSP-550 | determine if Opp contains a New or Amendment Quote, and if so update the Opp stage to 'Calculating TCV'
    // and add the record Id to the oppsThatNeedTCVCalculationIdList
    if (!oppsThatSkippedCalculatingTCVStage.isEmpty()) {
        for (Opportunity opp : [SELECT Id, (SELECT zqu__SubscriptionType__c FROM zqu__Quotes__r WHERE zqu__SubscriptionType__c != 'Cancel Subscription' LIMIT 1) FROM Opportunity WHERE Id IN :oppsThatSkippedCalculatingTCVStage.keySet()]) {
            // only need to check if a single record was found
            if (!opp.zqu__Quotes__r.isEmpty()) {
                Opportunity oppRec = oppsThatSkippedCalculatingTCVStage.get(opp.Id);
                oppRec.StageName = 'Calculating TCV';
                oppRec.Zuora_Quote_PDF_Session_Id__c = UserInfo.getSessionId();
                oppsThatNeedTCVCalculationIdList.add(oppRec.Id);
            }
        }
    }
    
    if (!oppsThatNeedTCVCalculationIdList.isEmpty()) {
        AttachmentTriggerHanlder.deleteZuoraQuotePDFAttachmentsFromOpportunities(oppsThatNeedTCVCalculationIdList);

        List<zqu__Quote__c> quoList = [Select Id, Name, server_Url__c, session_Id__c, zqu__Opportunity__c From zqu__Quote__c Where zqu__Status__c = 'New' and zqu__SubscriptionType__c <> 'Cancel Subscription' and zqu__Opportunity__c IN :oppsThatNeedTCVCalculationIdList];
        
        // JPS addition for renaming Quote records
        Map<Id, List<zqu__Quote__c>> quoteRenameListMap = new Map<Id, List<zqu__Quote__c>>();

        for(zqu__Quote__c zQuote : quoList){
            // JPS addition for renaming Quote records
            List<zqu__Quote__c> quoteRenameList = quoteRenameListMap.containsKey(zQuote.zqu__Opportunity__c) ? quoteRenameListMap.get(zQuote.zqu__Opportunity__c) : new List<zqu__Quote__c>();
            quoteRenameList.add(zQuote);
            quoteRenameListMap.put(zQuote.zqu__Opportunity__c, quoteRenameList);
        }
        
        // JPS addition for renaming Quote records
        List<zqu__Quote__c> quoteRenameUpdateList = new List<zqu__Quote__c>();
        for (List<zqu__Quote__c> quoteRenameListRec : quoteRenameListMap.values()) {
            Integer quoteRecordNumber = 1;
            for (zqu__Quote__c quoteRenameRecord : quoteRenameListRec) {
                if (quoteRenameRecord.Name.left(4).containsIgnoreCase(' - ')) {
                    quoteRenameRecord.Name = quoteRenameRecord.Name.substringAfter(' - ');
                }
                quoteRenameRecord.Name = String.valueOf(quoteRecordNumber) + ' - ' + quoteRenameRecord.Name;
                quoteRenameRecord.Name = quoteRenameRecord.Name.left(80); // CSP-1868 | make sure max length of the Quote record is 80 chars
                quoteRenameUpdateList.add(quoteRenameRecord);
                quoteRecordNumber++;
            }
        }
        if (!quoteRenameUpdateList.isEmpty()) {
            update quoteRenameUpdateList;
        }

        //if (!System.isBatch() && !oppsThatNeedTCVCalculationIdList.isEmpty()) {
        if (!System.isBatch()) {
            Database.executeBatch(new BatchCalculateZuoraTCV(oppsThatNeedTCVCalculationIdList), 1); // batch size needs to be set to 1 because of callout limits and queued job limits
        }
    }

    TriggerFactory.createAndExecuteHandler(OppLocalPendingApprovalTriggerHandler.class, 'Opportunity', localPendingInteralApprovalIndexList);
    // CSP-1553 use batch instead of workflow to send quotes to ZBilling 
    if(Trigger.isAfter && Trigger.isUpdate){
        
        /*Start of Changes added by Hari*/

        //List that holds the IDs of all those Opportunities which are Pending Internal Approval
        List<Id> opptyIds = new List<Id>();

        //List to hold the closed won opportunity ID
        List<Id> cwOppIds = new List<Id>();

        //String to hold the Zuora end point
        String endPoint = '';
        
        Integer counter = 0;

        //custom settings that holds the zuora endpoint url
        Generate_Quote_Pdf_Config__c config = Generate_Quote_Pdf_Config__c.getValues('Production');
        endPoint = config.URL__c;

        List<zqu__Quote_Template__c> quoteTemp = [Select zqu__Template_Id__c From zqu__Quote_Template__c Where zqu__IsDefault__c = True and zqu__Quote_Type__c = 'New Subscription' Limit 1];
        /*End of Change added by Hari*/

        Map<Id, List<zqu__Quote__c>> quoteMap = new Map<Id, List<zqu__Quote__c>>();
        List<Id> oppId =  new List<Id>();

        // CSP-2821 Selling to a Prospect
        Set<Id> statusChangeAccSet = new Set<Id>();

        for(Opportunity opp : trigger.new){

            Opportunity oldOpp = Trigger.oldMap.get(opp.id);
            
            oppId.add(opp.id);
            //If statement added by Hari
            if((Trigger.newMap.get(opp.Id).StageName == 'Ready for Echo-Sign') && (Trigger.oldMap.get(opp.Id).StageName != 'Ready for Echo-Sign')){
                opptyIds.add(opp.Id);
            }
            if((Trigger.newMap.get(opp.Id).StageName == 'Closed Won') && (Trigger.oldMap.get(opp.Id).StageName != 'Closed Won')){
                cwOppIds.add(opp.Id);
            }

            // CSP-2821 Selling to a Prospect
            if(!oldOpp.StageName.equalsIgnoreCase('Closed Lost') && opp.StageName.equalsIgnoreCase('Closed Lost')){
                if(!statusChangeAccSet.contains(opp.AccountId)){
                    statusChangeAccSet.add(opp.AccountId);
                }
            }
        }

        // CSP-2821 Selling to a Prospect
        // query all active Subs under the accounts
        List<Zuora__Subscription__c> activeSubsList = [SELECT Id, Zuora__TermEndDate__c, Zuora__Account__c FROM Zuora__Subscription__c WHERE Zuora__Account__c IN: statusChangeAccSet
                                              AND Zuora__TermEndDate__c >=: System.today()];

        for(Zuora__Subscription__c sub : activeSubsList){
            // store all having active subs' account ids in a set
            activeSubAccSet.add(sub.Zuora__Account__c);
        }

        for(zqu__Quote__c record : [select Id, Name, zqu__Opportunity__c,Old_Record_Type__c, zqu__SubscriptionType__c, recordtypeId from zqu__Quote__c where zqu__Opportunity__c IN : oppId]){
            if(quoteMap.containsKey(record.zqu__Opportunity__c)){
                quoteMap.get(record.zqu__Opportunity__c).add(record);
            }
            else{
                List<zqu__Quote__c> qlst = new List<zqu__Quote__c>();
                qlst.add(record);
                quoteMap.put(record.zqu__Opportunity__c, qlst);
            }
        }

        RecordType RecType = [Select Id From RecordType  Where SobjectType = 'zqu__Quote__c' and DeveloperName = 'ReadOnly' LIMIT 1];
        //Map<ID,RecordType> rt_Map = New Map<ID,RecordType>([Select ID, Name From RecordType Where sObjectType = 'Opportunity']);
        List<zqu__Quote__c> updateQuoteList = new List<zqu__Quote__c>();
        
        for(Opportunity opp : trigger.new){
            if(Trigger.newMap.get(opp.Id).Lock_Quotes__c != Trigger.oldMap.get(opp.Id).Lock_Quotes__c && opp.Lock_Quotes__c == true){
                List<zqu__Quote__c> QuoteList = new List<zqu__Quote__c>();
                QuoteList = quoteMap.get(opp.Id);
                if(QuoteList != NULL && QuoteList.size() > 0)
                {
                    for(zqu__Quote__c q : QuoteList){
                        if((q.Old_Record_Type__c == '' || q.Old_Record_Type__c == NULL) && q.zqu__SubscriptionType__c != 'Cancel Subscription')
                        {
                            q.Old_Record_Type__c = q.recordtypeId;
                            q.RecordTypeID = RecType.Id;
                            updateQuoteList.add(q);
                        }    
                    }
                 }   
            }
            if(Trigger.newMap.get(opp.Id).Lock_Quotes__c != Trigger.oldMap.get(opp.Id).Lock_Quotes__c && opp.Lock_Quotes__c != true){
                List<zqu__Quote__c> QuoteList = new List<zqu__Quote__c>();
                QuoteList = quoteMap.get(opp.Id);
                if(QuoteList != NULL && QuoteList.size() > 0)
                {
                    for(zqu__Quote__c q : QuoteList){
                      if (q.zqu__SubscriptionType__c != 'Cancel Subscription') {
                          q.RecordTypeId = (Id)q.Old_Record_Type__c;
                          q.Old_Record_Type__c = '';
                          updateQuoteList.add(q);
                      }
                    }
                }
            }
            // CSP-2831 Flag Month-To-Month Contracts
            // update flag 'Cancel For Convenience' and sync Account flag  
            if(Trigger.newMap.get(opp.Id).Cancel_For_Convenience__c != Trigger.oldMap.get(opp.Id).Cancel_For_Convenience__c 
                && opp.Cancel_For_Convenience__c
                && rtMapById.get(opp.RecordTypeId).getName().containsIgnoreCase('Local')) {

                Account acc = new Account();

                // CSP-3082 OpportunityTrigger update error
                // Since duplicate account records added into the list, we use map to avoid the list exception
                if(needUpdateAccMap.containsKey(opp.AccountId)){
                    acc = needUpdateAccMap.get(opp.AccountId);
                }
                else{
                    acc.Id = opp.AccountId;
                }

                acc.Cancel_For_Convenience__c = true;

                needUpdateAccMap.put(opp.AccountId, acc);
            }

            // CSP-2821 Selling to a Prospect
            // oldOpp for other usage
            Opportunity oldOpp = Trigger.oldMap.get(opp.id);
            // store the if the opp stage from non-closed lost change to closed lost
            if(!oldOpp.StageName.equalsIgnoreCase('Closed Lost') && opp.StageName.equalsIgnoreCase('Closed Lost')){
                // check if there are any active subs under the account, if yes, do not change the account status
                // Only work for no any active subs account
                if(!activeSubAccSet.contains(opp.AccountId)){

                    Account acc = new Account();
                    // CSP-3082 OpportunityTrigger update error
                    // Since duplicate account records added into the list, we use map to avoid the list exception
                    if(needUpdateAccMap.containsKey(opp.AccountId)){
                        acc = needUpdateAccMap.get(opp.AccountId);
                    }
                    else{
                        acc.Id = opp.AccountId;
                    }
                    
                    // If lost reason is OOB or Do not contact, then make the account to dead, otherwise, account is Dormant
                    if(opp.Lost_Reason__c.equalsIgnoreCase('Out of Business') || opp.Lost_Reason__c.equalsIgnoreCase('Do not contact again')){
                        acc.account_status__c = 'Disqualified';

                        if(opp.Lost_Reason__c.equalsIgnoreCase('Out of Business')){
                            acc.Negative_Disposition_Reason__c = opp.Lost_Reason__c;
                        }
                        else{
                            acc.Negative_Disposition_Reason__c = 'Do Not Contact';
                        }
                        
                    }
                    else{
                        System.debug(LoggingLevel.INFO, '*** opp.Lost_Reason__c: ' + opp.Lost_Reason__c);
                        acc.account_status__c = 'Dormant';
                        acc.Negative_Disposition_Reason__c = 'No Need';
                    }
                    // CSP-3082 OpportunityTrigger update error
                    // Since duplicate account records added into the list, we use map to avoid the list exception
                    needUpdateAccMap.put(opp.AccountId, acc);
                }
                
            }
        }
        //CSP-2831 Flag Month-To-Month Contracts
        //Call method to update account flag
        if(!needUpdateAccMap.isEmpty()){
            List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();
            List<Database.SaveResult> resultList = Database.update(needUpdateAccMap.values(), false);
            xoExceptionList.addAll(ExceptionUtility.consumeException(resultList));
            System.debug(LoggingLevel.INFO, '*** xoExceptionList: ' + xoExceptionList);
            // insert xoException
            if(!xoExceptionList.isEmpty()){
                Insert xoExceptionList;
            }
        }

        if (!updateQuoteList.isEmpty()) {
            update updateQuoteList;
        }

        if(cwOppIds.size() > 0) {
            // CSP-1347 | no longer create callback tasks, instead create Callback__c records for the new Callback Queue system
            //CreateCallBackTask.callbackTask(cwOppIds);
        }

    }
    // Om' code End here.
   
    if(Trigger.isAfter && (test.isRunningTest() || ConnectApi.Organization.getSettings().features.chatter)){
        List<EntitySubscription> followOpportunityList = new List<EntitySubscription>();

        if(trigger.isInsert){
            for(Opportunity record : trigger.New){
                if(String.isNotBlank(record.AccStrategist__c)){
                    EntitySubscription acFollow = new EntitySubscription();
                    acFollow.parentId = record.Id;
                    acFollow.subscriberId = record.AccStrategist__c;
                    followOpportunityList.add(acFollow);
                }
            }
        }else if(trigger.isUpdate){

            Map<Id, Id> closedOppAccStratMap = new Map<Id, Id>();
            Map<Id, Set<Id>> oppFollowersMap = new Map<Id, Set<Id>>();
            Set<Id> oppNameChangeSet = new Set<Id>();

            for(EntitySubscription record : [select Id, parentId, subscriberId from EntitySubscription where parentId IN : trigger.New limit 1000]){
                if(oppFollowersMap.containsKey(record.parentId)){
                    oppFollowersMap.get(record.parentId).add(record.subscriberId);
                }else{
                    Set<Id> idSet = new Set<Id>();
                    idSet.add(record.subscriberId);
                    oppFollowersMap.put(record.parentId, idSet);
                }
            }

            for(Opportunity record : trigger.New){
                Opportunity oldRecord = trigger.oldMap.get(record.Id);

                if(rtMapById.get(record.RecordTypeId).getName().contains('National') && record.Name != oldRecord.Name){
                    oppNameChangeSet.add(record.Id);
                }

                if(String.isNotBlank(record.AccStrategist__c) && oldRecord.AccStrategist__c != record.AccStrategist__c && !record.isClosed && (!oppFollowersMap.containsKey(record.Id) || !oppFollowersMap.get(record.Id).contains(record.AccStrategist__c))){
                    EntitySubscription acFollow = new EntitySubscription();
                    acFollow.parentId = record.Id;
                    acFollow.subscriberId = record.AccStrategist__c;
                    if(String.isNotBlank(oldRecord.AccStrategist__c)){
                        closedOppAccStratMap.put(record.Id, oldRecord.AccStrategist__c);
                    }
                    followOpportunityList.add(acFollow);
                }else if(record.isClosed && !oldRecord.isClosed && String.isNotBlank(record.AccStrategist__c)){
                    closedOppAccStratMap.put(record.Id, record.AccStrategist__c);
                }
            }

            if(!oppNameChangeSet.isEmpty()){
                update [select Id, (Select Id from ThoughtStarters_RFPs__r) from Opportunity where Id IN : oppNameChangeSet].ThoughtStarters_RFPs__r;
            }

            List<EntitySubscription> unfollowOpportunityList = new List<EntitySubscription>();

            for(EntitySubscription record : [select Id, parentId, subscriberId from EntitySubscription where parentId IN : closedOppAccStratMap.keySet() and subscriberId IN : closedOppAccStratMap.values() limit 1000]){
                if(closedOppAccStratMap.get(record.parentId) == record.subscriberId){
                    unfollowOpportunityList.add(record);
                }
            }

            if(!unfollowOpportunityList.isEmpty()){
                delete unfollowOpportunityList;
            }
        }

        if(!followOpportunityList.isEmpty()){
            insert followOpportunityList;
        }
    }

    if(Trigger.isBefore){
        Map<Id, Id> salesRepAccStratMap = new Map<Id, Id>();
        for(Account_Strategist_Assignment__c record : [select Account_Strategist__c, Sales_Rep__c from Account_Strategist_Assignment__c]){
            salesRepAccStratMap.put(record.Sales_Rep__c, record.Account_Strategist__c);
        }

        if(trigger.isInsert){
            Id pbId;
            if(Test.isRunningTest()){
                pbId = Test.getStandardPricebookId();
            }else{
                pbId = [select Id from Pricebook2 where isActive = true and isStandard = true limit 1].id;
            }

            for(Opportunity record : trigger.New){
                if(salesRepAccStratMap.containsKey(record.OwnerId)){
                    record.AccStrategist__c = salesRepAccStratMap.get(record.OwnerId);
                }
                if(rtMapById.get(record.RecordTypeId).getName().contains('National')){
                    record.Pricebook2Id = pbId;
                }
            }
        }else if(Trigger.isUpdate){

            //Map with Opportunity and Created ThoughtStarter and RFP IDs for validation
            Map<Id, Set<String>> oppIdTsRfpMap = new Map<Id, Set<String>>();

            //Map with Opportunity and Created ThoughtStarter and RFP IDs for validation
            Map<Id, Set<String>> oppIdTsRfpCompletedMap = new Map<Id, Set<String>>();

            //Map of Stagae requiring full RFP or TS
            Map<String, Stage_Requires_Complete_TS_RFP__c> stageRequireMap = Stage_Requires_Complete_TS_RFP__c.getAll();

            for(Opportunity record : trigger.New){
                Opportunity oldRecord = trigger.oldMap.get(record.Id);

                //CSP-1104 and CSP-923 | Close Date update for Closed Lost stage.
                if(record.StageName != oldRecord.StageName && record.StageName == 'Closed Lost'){
                  record.CloseDate = date.today();
                }  

                if(record.OwnerId != oldRecord.OwnerId && salesRepAccStratMap.containsKey(record.OwnerId)){
                    record.AccStrategist__c = salesRepAccStratMap.get(record.OwnerId);
                }
            }
        }
    }
    
    if (Trigger.isBefore) {

        // SF-2268; Opportunity Contract Signer must have an email address
        Map<Id, List<Opportunity>> contactIdToOpenOppsWhereContractSigner = new Map<Id, List<Opportunity>>();

        // CSP-2884 Bulk Load Error for National workflow
        // userId set & national UserMap
        Set<Id> natUserSet = new Set<Id>();
        Map<Id, User> natUserMap = new Map<Id, User>();

        // CSP-2884 Bulk Load Error for National workflow
        // put all the user id into set
        for(Opportunity csOpp : Trigger.new){
            if(rtMapById.get(csOpp.RecordTypeId).getName().containsIgnoreCase('National')){
                if(!natUserSet.contains(csOpp.OwnerId)){
                    natUserSet.add(csOpp.OwnerId);
                }
            }
        }
        
        // CSP-2884 Bulk Load Error for National workflow
        // query the Sales planner and Strategy specialist
        if(Trigger.isInsert || Trigger.isUpdate){
            if(!natUserSet.isEmpty()){
                natUserMap = new Map<Id, User>([SELECT Id, Sales_Planner__c, Strategy_Specialist__c FROM User WHERE Id IN: natUserSet]);
            }
        }
        

        for (Opportunity csOpp : Trigger.new) {
            if(rtMapById.get(csOpp.RecordTypeId).getName().containsIgnoreCase('Local')) {
                // CSP-1610 | for Local Opps, set default value if null
                if (csOpp.Opportunity_Expiration_Date__c == null) {
                    csOpp.Opportunity_Expiration_Date__c = Date.today() + 60;
                }
            }

            if (csOpp.StageName != 'Closed Won' && csOpp.StageName != 'Closed Lost') {
                List<Opportunity> openOppList;
                if (contactIdToOpenOppsWhereContractSigner.containsKey(csOpp.Contract_Signer__c)) {
                    openOppList = contactIdToOpenOppsWhereContractSigner.get(csOpp.Contract_Signer__c);
                }
                else {
                    openOppList = new List<Opportunity>();
                }

                openOppList.add(csOpp);
                contactIdToOpenOppsWhereContractSigner.put(csOpp.Contract_Signer__c, openOppList);
            }

            // CSP-2884 Bulk Load Error for National workflow
            // Assign the Account manager & Sales Planner when the owner of national opp changed
            // Used to replace the CSP-2817 process builder logic
            if(rtMapById.get(csOpp.RecordTypeId).getName().containsIgnoreCase('National')){

                if(!natUserMap.isEmpty()){

                    User oppUser = natUserMap.get(csOpp.OwnerId);

                    if(Trigger.isInsert){
                        csOpp.Sales_Planner__c =  oppUser.Sales_Planner__c;
                        csOpp.Account_Manager__c = oppUser.Strategy_Specialist__c;
                    }
                    else if(Trigger.isUpdate){
                        Opportunity oldOpp = Trigger.oldMap.get(csOpp.Id);

                        if(oldOpp.OwnerId != csOpp.OwnerId){
                            csOpp.Sales_Planner__c = oppUser.Sales_Planner__c;
                            csOpp.Account_Manager__c = oppUser.Strategy_Specialist__c;
                        }
                    }

                }
            }

        }

        if (!contactIdToOpenOppsWhereContractSigner.isEmpty()) {
            for (Contact contractSigner : [SELECT Id, Email FROM Contact WHERE Id IN :contactIdToOpenOppsWhereContractSigner.keySet() AND Email = null]) {
                for (Opportunity openCSOpp : contactIdToOpenOppsWhereContractSigner.get(contractSigner.Id)) {
                    openCSOpp.Contract_Signer__c.addError('Cannot select a Contact without an email address to be the Contract Signer for an open Opportunity');
                }
            }
        }

        if (Trigger.isUpdate) {

            // Code that supports Local Opportunity Quote-to-Cash Process; updates expiration dates on child Quote records
            
            // Ticket: SF-1597
            Map<Id,RecordType> rtMap = New Map<ID,RecordType>([SELECT ID, Name FROM RecordType WHERE sObjectType = 'Opportunity' AND (Name = 'Local')]);

            // CSP-1610 | when Opp Stage gets updated to Closed Lost, delete all held Inventory
            Set<Id> oppIdOfInventoryToDeleteSet = new Set<Id>();

            // Tickets SF-1506, SF-1511, and SF-1781
            Map<Id,Opportunity> oppsThatNeedARApprovalMap = new Map<Id,Opportunity>();
            Map<Id,Opportunity> oppsThatNeedManagerApprovalMap = new Map<Id,Opportunity>();
            Map<Id,Opportunity> oppsThatNeedCancelApprovalMap = new Map<Id,Opportunity>();


            for (Opportunity newOpp : Trigger.new) {
                Opportunity oldOpp = Trigger.oldMap.get(newOpp.Id);

                // CSP-1610
                if (oldOpp.StageName != 'Closed Lost' && newOpp.StageName == 'Closed Lost') {
                    newOpp.Opportunity_Expiration_Date__c = Date.today();
                    oppIdOfInventoryToDeleteSet.add(newOpp.Id);
                }

                if (rtMap.keySet().contains(newOpp.RecordTypeID)) {
                    
                    // Ticket SF-1498
                    // set the Opportunity Expiration Date to 10 calendar days from the first time the Opportunity enters an Approval Process
                    if (oldOpp.Lock_Quotes__c == False && newOpp.Lock_Quotes__c == True && newOpp.Opportunity_Expiration_Date__c == null) {
                        newOpp.Opportunity_Expiration_Date__c = Date.today() + 10;
                    }

                    // check to see if the expiration date has changed
                    if (oldOpp.Opportunity_Expiration_Date__c != newOpp.Opportunity_Expiration_Date__c) {
                        // Negate 5 business days from the opp. exp date and update ESign Date
                        if(newOpp.Opportunity_Expiration_Date__c != null){
                            newOpp.EchoSign_Contract_Due_Date__c = DateUtility.addBusinessDays(newOpp.Opportunity_Expiration_Date__c, -5);
                        }
                    }

                    // Tickets SF-1506, SF-1511, and SF-1781
                    // populate list of Opp records to process down below
                    if (newOpp.Approval_Process_AR_Assignment__c || newOpp.Approval_Process_Manager_Assignment__c || newOpp.Approval_Process_Cancel_Assignment__c) {
                        if (newOpp.Approval_Process_AR_Assignment__c) {
                            newOpp.Approval_Process_AR_Assignment__c = False;
                            oppsThatNeedARApprovalMap.put(newOpp.Id,newOpp);
                        }
                        else if (newOpp.Approval_Process_Manager_Assignment__c) {
                            newOpp.Approval_Process_Manager_Assignment__c = False;
                            oppsThatNeedManagerApprovalMap.put(newOpp.Id,newOpp);
                        }
                        else {
                          newOpp.Approval_Process_Cancel_Assignment__c = False;
                          oppsThatNeedCancelApprovalMap.put(newOpp.Id,newOpp);
                        }
                    }
                    
                }
            }

            // CSP-1610 | immediately release all Inventory for Opportunities with a StageName of Closed Lost
            if (oppIdOfInventoryToDeleteSet.size() > 0) {
                List<Inventory__c> inventoryDeleteList = [SELECT Id FROM Inventory__c WHERE Quote_Rate_Plan__r.zqu__Quote__r.zqu__Opportunity__c IN :oppIdOfInventoryToDeleteSet];

                // if there was a delete exception, insert an XO_Exception__c record
                List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();
                Database.DeleteResult[] dbDeleteResult = Database.delete(inventoryDeleteList, false);
                xoExceptionList.addAll(ExceptionUtility.consumeException(dbDeleteResult));
                if (xoExceptionList.size() > 0) {
                    insert xoExceptionList;
                }
            }

            // Tickets SF-1506, SF-1511, and SF-1781
            // For each Opportunity, populate the "Approval_Process_AR_Lookup__c" lookup field or the "Approval_Process_Manager_Lookup__c" lookup field or the "Approval_Process_Cancel_Lookup__c" lookup field,
            // then create and assign a Task for said Opportunity notifying the User that they have an Approval Request waiting for their review
            if (!oppsThatNeedARApprovalMap.isEmpty() || !oppsThatNeedManagerApprovalMap.isEmpty() || !oppsThatNeedCancelApprovalMap.isEmpty()) {
                
                //Tickets CSP-937
                //check the Custom Settings Approval_Requested field. if field is true then create task.
                Task_Creation_Settings__c taskCreateSetting=Task_Creation_Settings__c.getValues('Approval_Requested');
                
                List<Task> approvalProcessTaskList = new List<Task>();
                String sfdcURL = URL.getSalesforceBaseUrl().toExternalForm();

                if (!oppsThatNeedARApprovalMap.isEmpty()) {
                    Map<String,List<Opportunity>> approverEmailToOppListMap = new Map<String,List<Opportunity>>();
                    for (Opportunity arOpp : oppsThatNeedARApprovalMap.values()) {
                        // using a custom hierarchy setting to designate each user's AR approver
                        // as of 10-10-2015 the only AR approver is Shannon Davis, but the functionality for more complex assignments exists
                        String arUserEmail = LocalOppApprovalProcessARApprover__c.getInstance(arOpp.OwnerId).Email__c;
                        if (approverEmailToOppListMap.containsKey(arUserEmail)) {
                            List<Opportunity> oppList = approverEmailToOppListMap.get(arUserEmail);
                            oppList.add(arOpp);
                            approverEmailToOppListMap.put(arUserEmail,oppList);
                        }
                        else {
                            List<Opportunity> newOppList = new List<Opportunity>();
                            newOppList.add(arOpp);
                            approverEmailToOppListMap.put(arUserEmail,newOppList);
                        }
                    }

                    // create the Task and populate the "Approval_Process_AR_Lookup__c" lookup field on the Opportunity
                    // the "Approval_Process_AR_Lookup__c" lookup field is used to help assign Approval Requests to the Opportunity Owner's AR approver
                    List<User> arApproverUserList = [SELECT Id, Email FROM User WHERE Email IN :approverEmailToOppListMap.keySet()];
                    for (User arUser : arApproverUserList) {
                        for (Opportunity arApprovalOpp : approverEmailToOppListMap.get(arUser.Email)) {
                          //Tickets CSP-937
                          //add the condition before create tasks.
                          if(taskCreateSetting != null && taskCreateSetting.Create_Task__c){
                              Task arTask = new Task();
                              arTask.OwnerId = arUser.Id;
                              arTask.Subject = 'Approval Requested: ' + arApprovalOpp.Name;
                              arTask.Description = 'An Opportunity ('+sfdcURL+'/'+arApprovalOpp.Id+') for a credit-hold Account ('+sfdcURL+'/'+arApprovalOpp.AccountId+') has been submitted for approval.'; 
                              arTask.Type = 'Opportunity Approval';
                              arTask.Purpose__c = 'Quote Approval';
                              arTask.Status = 'Not Started';
                              arTask.Priority = 'High';
                              arTask.WhatId = arApprovalOpp.Id;
                              arTask.IsReminderSet = True;
                              arTask.ReminderDateTime = System.now();
                              arTask.ActivityDate = DateUtility.addBusinessDays(Date.today(),1);
                              approvalProcessTaskList.add(arTask);
                          }
                            arApprovalOpp.Approval_Process_AR_Lookup__c = arUser.Id;
                        }
                    }
                }


                if (!oppsThatNeedManagerApprovalMap.isEmpty()) {
                    Set<Id> ownerIDSet = new Set<Id>();
                    for (Opportunity mo : oppsThatNeedManagerApprovalMap.values()) {
                        ownerIDSet.add(mo.OwnerId);
                    }

                    Map<Id,User> oppOwnerRecordMap = new Map<Id,User>([SELECT Id, ManagerId FROM User WHERE Id IN :ownerIDSet]);
                    
                    for (Opportunity maptOpp : oppsThatNeedManagerApprovalMap.values()) {
                        
                        // if the User has a Manager, create the Task and populate the "Opportunity_Owner_Manager__c" lookup field on the Opportunity
                        // the "Opportunity_Owner_Manager__c" lookup field is used to help assign Approval Requests to the Opportunity Owner's Manager
                        User tempUser = oppOwnerRecordMap.get(maptOpp.OwnerId);
                        if (tempUser.ManagerId != null) {
                          //Tickets CSP-937
                          //add the condition before create tasks.
                          if(taskCreateSetting != null && taskCreateSetting.Create_Task__c){
                              Task managerTask = new Task();
                              managerTask.OwnerId = tempUser.ManagerId;
                              managerTask.Subject = 'Approval Requested: ' + maptOpp.Name;
                              managerTask.Description = 'An Opportunity ('+sfdcURL+'/'+maptOpp.Id+') has been submitted for approval.';
                              managerTask.Type = 'Opportunity Approval';
                              managerTask.Purpose__c = 'Quote Approval';
                              managerTask.Status = 'Not Started';
                              managerTask.Priority = 'High';
                              managerTask.WhatId = maptOpp.Id;
                              managerTask.IsReminderSet = True;
                              managerTask.ReminderDateTime = System.now();
                              managerTask.ActivityDate = DateUtility.addBusinessDays(Date.today(),1);
                              approvalProcessTaskList.add(managerTask);
                          }
                            maptOpp.Approval_Process_Manager_Lookup__c = tempUser.ManagerId;
                        }
                    }
                }


                if (!oppsThatNeedCancelApprovalMap.isEmpty()) {
                    Map<String,List<Opportunity>> cancelApproverEmailTocancelOppListMap = new Map<String,List<Opportunity>>();
                    for (Opportunity cancelOpp : oppsThatNeedCancelApprovalMap.values()) {
                        // using a custom hierarchy setting to designate each user's AR approver
                        // as of 12-21-2015 the main Cancel approver is Naomi Carlson, but the functionality for more complex assignments exists
                        String cancelUserEmail = LocalOppApprovalProcessCancelApprover__c.getInstance(cancelOpp.OwnerId).Email__c;
                        if (cancelApproverEmailTocancelOppListMap.containsKey(cancelUserEmail)) {
                            List<Opportunity> cancelOppList = cancelApproverEmailTocancelOppListMap.get(cancelUserEmail);
                            cancelOppList.add(cancelOpp);
                            cancelApproverEmailTocancelOppListMap.put(cancelUserEmail,cancelOppList);
                        }
                        else {
                            List<Opportunity> newCancelOppList = new List<Opportunity>();
                            newCancelOppList.add(cancelOpp);
                            cancelApproverEmailTocancelOppListMap.put(cancelUserEmail,newCancelOppList);
                        }
                    }

                    // create the Task and populate the "Approval_Process_Cancel_Lookup__c" lookup field on the Opportunity
                    // the "Approval_Process_Cancel_Lookup__c" lookup field is used to help assign Approval Requests to the Opportunity Owner's Cancel approver
                    List<User> cancelApproverUserList = [SELECT Id, Email FROM User WHERE Email IN :cancelApproverEmailTocancelOppListMap.keySet()];
                    for (User cancelUser : cancelApproverUserList) {
                        for (Opportunity cancelApprovalOpp : cancelApproverEmailTocancelOppListMap.get(cancelUser.Email)) {
                          //Tickets CSP-937
                          //add the condition before create tasks.
                          if(taskCreateSetting != null && taskCreateSetting.Create_Task__c){
                              Task cancelTask = new Task();
                              cancelTask.OwnerId = cancelUser.Id;
                              cancelTask.Subject = 'Approval Requested: ' + cancelApprovalOpp.Name;
                              cancelTask.Description = 'An Opportunity ('+sfdcURL+'/'+cancelApprovalOpp.Id+') with a Cancellation ('+sfdcURL+'/'+cancelApprovalOpp.AccountId+') has been submitted for approval.'; 
                              cancelTask.Type = 'Opportunity Approval';
                              cancelTask.Purpose__c = 'Quote Approval';
                              cancelTask.Status = 'Not Started';
                              cancelTask.Priority = 'High';
                              cancelTask.WhatId = cancelApprovalOpp.Id;
                              cancelTask.IsReminderSet = True;
                              cancelTask.ReminderDateTime = System.now();
                              cancelTask.ActivityDate = DateUtility.addBusinessDays(Date.today(),1);
                              approvalProcessTaskList.add(cancelTask);
                          }
                            cancelApprovalOpp.Approval_Process_Cancel_Lookup__c = cancelUser.Id;
                        }
                    }
                }
                //Tickets CSP-937
                if(!approvalProcessTaskList.isEmpty()){
                    insert approvalProcessTaskList;
                }
            }   

        }
    }

    // for ticket csp-1137, when an Opportunity be created, a primary will be added to the Opportunity from the account
    if(Trigger.isAfter && Trigger.isInsert){
        Set<id> accIdList = new Set<id>();
        Set<id> oppIdList = new Set<id>(); 
        
        for(Opportunity newOpp: Trigger.new){
            if(rtMapById.get(newOpp.RecordTypeId).getName().containsIgnoreCase('Local')){
                accIdList.add(newOpp.AccountId);
                oppIdList.add(newOpp.id);

                // CSP-2831 Flag Month-To-Month Contracts
                // Get all Account id when falg Cancel For Convenience is true
                if(newOpp.Cancel_For_Convenience__c) {
                    
                    Account acc = new Account();

                    if(needUpdateAccMap.containsKey(newOpp.accountId)){
                        acc = needUpdateAccMap.get(newOpp.accountId);
                        acc.Cancel_For_Convenience__c = true;
                    }
                    else{
                        acc.id = newOpp.AccountId;
                        acc.Cancel_For_Convenience__c = true;
                    }
                    needUpdateAccMap.put(newOpp.accountId, acc);
                }

                // CSP-2821 Selling to a Prospect
                // store all accountId to a set
                if(!sellingAccountSet.contains(newOpp.AccountId)){
                    sellingAccountSet.add(newOpp.AccountId);
                }
                
            }
        }

        // CSP-2821 Selling to a Prospect
        // query all non-active and non-In Opportunity accounts
        List<Account> activeAccountList = [SELECT Id, Account_Status__c FROM Account WHERE Id IN: sellingAccountSet 
                                                                                AND Account_status__c!='Active' AND Account_status__c!='In Opportunity'];

        if(!activeAccountList.isEmpty()){
            for(Account acc : activeAccountList){
                
                if(needUpdateAccMap.containsKey(acc.id)){
                    acc = needUpdateAccMap.get(acc.id);
                    acc.Account_status__c = 'In Opportunity';
                }
                else{
                    acc.Account_status__c = 'In Opportunity';
                    needUpdateAccMap.put(acc.id, acc);
                }

            }
        }

        if(!oppIdList.isEmpty()){
            List<OpportunityContactRole> OCRList = [select id,contactid,opportunityid,role,isprimary from OpportunityContactRole where (/*isprimary = true or*/ role = 'Primary') and opportunityid in: oppIdList];
            List<AccountContactRole> ACRList = [select id,contactId,accountId,role,isPrimary from AccountContactRole where (role = 'Primary' /*or isPrimary = True*/ )and accountId in: accIdList];
            Map<id,OpportunityContactRole> OCRmap = new Map<id,OpportunityContactRole>();
            Map<id,id> ACRmap = new Map<id,id>();
            Map<id,Set<AccountContactRole>> acountContactSetMap = new Map<id,Set<AccountContactRole>>();
            if(!OCRList.isEmpty()){
                for(OpportunityContactRole OCR : OCRList){
                    OCRmap.put(OCR.opportunityid,OCR);
                }
            }
            if(!ACRList.isEmpty()){
                for(AccountContactRole ACR : ACRList){
                    if(ACRmap.containsKey(ACR.AccountId)){
                        acountContactSetMap.get(ACR.AccountId).add(ACR);
                        if (ACR.Role == 'Primary') {
                            ACRmap.put(ACR.accountId,ACR.contactid);
                        }
                    }else{
                        Set<AccountContactRole> tempSet = new Set<AccountContactRole>();
                        tempSet.add(ACR);
                        acountContactSetMap.put(ACR.accountId,tempSet);
                        ACRmap.put(ACR.accountId,ACR.contactid);
                    }
                }
            }
            System.debug(acountContactSetMap);
            List<OpportunityContactRole> newOCRList = new List<OpportunityContactRole>();
            for(Opportunity newOpp: Trigger.new){
                if(!OCRmap.containsKey(newOpp.id) && ACRmap.containsKey(newOpp.accountId)){
                    for(AccountContactRole tempACR : acountContactSetMap.get(newOpp.accountId)){
                        OpportunityContactRole newOCR = new OpportunityContactRole();
                        newOCR.contactid = tempACR.contactId;
                        newOCR.opportunityid = newOpp.id;
                        newOCR.IsPrimary = tempACR.isPrimary;
                        newOCR.role = 'Primary';
                        newOCRList.add(newOCR);
                    }
                }
            }
            system.debug(newOCRList);
            if(!newOCRList.isEmpty()){
                try{
                    upsert newOCRList;
                }catch(exception e){
                    ExceptionUtility.consumeException(e, true);
                }
            }
        }

        // CSP-2821 Selling to a Prospect & CSP-2831 Flag Month-To-Month Contracts
        // update the account status to In Opportunity
        if(!needUpdateAccMap.isEmpty()){
            List<Database.SaveResult> resultList = Database.update(needUpdateAccMap.values(), false);
            List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();
            xoExceptionList.addAll(ExceptionUtility.consumeException(resultList));

            // insert xoException
            if(!xoExceptionList.isEmpty()){
                Insert xoExceptionList;
            }
        }
    }

}