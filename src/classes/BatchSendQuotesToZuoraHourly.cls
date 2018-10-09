/* 
<class>
  <name>BatchSendQuotesToZuoraHourly</name>
  <purpose>
    Send quotes to Zuora hourly, and only send one notification Task daily to users.
  </purpose>
  <created>
    <by>Scott Yang</by>
    <date>Dec/1/2016</date>
    <ticket>CSP-1553</ticket>
  </created>
</class>
*/
global class BatchSendQuotesToZuoraHourly implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful{
    public String query;
    
    public List<XO_Exception__C> xoExceptionList = new List<XO_Exception__C>();
    public Set<Id> successOppIdSet = new Set<Id>();
    public Set<Id> failedOppIdSet = new Set<Id>();
    public Set<Id> successQuoteIdSet = new Set<Id>();
    public Set<Id> failedQuoteIdSet = new Set<Id>();
    public Map<Id, string> quoteIdToErrorMessageMap = new Map<Id, String>();
    public Map<Id, Id> quoteOwnerIdMap = new Map<Id, Id>();
    public Map<Id, Id> needTaskOppyIdOwnerIdMap = new Map<Id,Id>();

    public Set<Id> notSendToZBilingSet = new set<Id>();
    //public List<Schema.RecordTypeInfo> sriList = zqu__Quote__c.SObjectType.getDescribe().getRecordTypeInfos();
    global Boolean sendQuotesToBilling {get;set;}


    global BatchSendQuotesToZuoraHourly() {
        //query = 'Select Id, Name from Opportunity Where StageName = \'Client Approved\' and RecordType.Name like \'%Local%\'';
        query = 'Select Id, Product_Line__c, zqu__PaymentMethod__c, name, zqu__Opportunity__c,Old_Record_Type__c, recordtypeId, zqu__ZuoraSubscriptionID__c, zqu__ZuoraAccountID__c, zqu__Account__c, zqu__ElectronicPaymentMethodId__c, ';
        query += ' zqu__Opportunity__r.Electronic_Payment_Method_Id_Credit__c, zqu__Opportunity__r.Electronic_Payment_Method_Id_ACH__c, zqu__Opportunity__r.Date_Client_Approved__c, zqu__Opportunity__r.OwnerId, zqu__ProcessPayment__c, zqu__Opportunity__r.StageName, ';
        query += ' zqu__Customer_Acceptance_Date__c, zqu__TermStartDate__c, zqu__SubscriptionTermStartDate__c, zqu__StartDate__c, zqu__SubscriptionType__c, zqu__Service_Activation_Date__c, zqu__InvoiceDate__c, zqu__InvoiceTargetDate__c, zqu__BillCycleDay__c ';
        query += ' from zqu__Quote__c where zqu__Opportunity__r.StageName IN (\'Client Approved\', \'Closed Won\') AND zqu__Opportunity__r.RecordType.Name LIKE \'%Local%\' AND zqu__Status__c != \'Sent to Z-Billing\'';
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO, 'BatchSendQuotesToZuoraHourly query:' + query);
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, list<zqu__Quote__c> scope) {
        //get the list of opportunity Ids
        xoExceptionList = new List<XO_Exception__C>();
        Map<Id,Id> oppyIdOwnerIdMap = new Map<Id,Id>();
        Set<Id> allQuoteIdSet = new Set<Id>();

        //List<Id> oppIdList = new List<Id>();
        //csp-2485 Disallow Sending Internet Quotes to Zuora without LocationId
        for (zqu__Quote__c currentQuote : scope) {
            allQuoteIdSet.add(currentQuote.Id);
        }
        System.debug('***allQuoteIdSet:'+allQuoteIdSet);
        
        //Query missing locatin id and LocationVendorDynamicsAccountID And quote product line is internet.  
        //And stroe opportunity id and opportunity owner id .
        List<zqu__QuoteRatePlanCharge__c> QuoteRatePlanChargeList = [SELECT Id, zqu__QuoteRatePlan__r.zqu__Quote__r.Product_Line__c, LocationVendorDynamicsAccountID__c, 
                                                                                                                                    Location_Vendor__c, zqu__QuoteRatePlan__r.zqu__Quote__r.zqu__Opportunity__c,zqu__QuoteRatePlan__r.Location_Vendor__c,
                                                                                                                                    zqu__QuoteRatePlan__r.zqu__Quote__r.zqu__Opportunity__r.OwnerId,zqu__QuoteRatePlan__c, 
                                                                                                                                    zqu__QuoteRatePlan__r.zqu__Quote__c, zqu__QuoteRatePlan__r.zqu__Quote__r.zqu__Opportunity__r.accountId
                                                                                                                                FROM zqu__QuoteRatePlanCharge__c 
                                                                                                                                WHERE zqu__QuoteRatePlan__r.zqu__Quote__c IN: allQuoteIdSet
                                                                                                                                    AND zqu__QuoteRatePlan__r.zqu__Quote__r.Product_Line__c = 'Internet'
                                                                                                                                    AND (Location_Vendor__c = null 
                                                                                                                                        OR LocationVendorDynamicsAccountID__c = null 
                                                                                                                                        OR LocationVendorDynamicsAccountID__c = ''
                                                                                                                                        OR zqu__QuoteRatePlan__r.Location_Vendor__c = null)];

        for(zqu__QuoteRatePlanCharge__c qrpc : QuoteRatePlanChargeList){
            if(!oppyIdOwnerIdMap.containsKey(qrpc.zqu__QuoteRatePlan__r.zqu__Quote__r.zqu__Opportunity__c)){
                oppyIdOwnerIdMap.put(qrpc.zqu__QuoteRatePlan__r.zqu__Quote__r.zqu__Opportunity__c, qrpc.zqu__QuoteRatePlan__r.zqu__Quote__r.zqu__Opportunity__r.OwnerId);
            }
        } 
        // update quotes firstly and then run BatchSendQuotesToZuoraHourly again in finish(). Because Database DML not allow in execute() when there is any callout method
        if(!sendQuotesToBilling){
            resetQuotes(scope); 
        }
        // send quotes to zbilling
        else{
            for (zqu__Quote__c currentQuote : scope){
                //if quote which has Quote Rate Plans in any opportunity that are missing a LocationId should not be allowed to be sent to Zuora.
                if(oppyIdOwnerIdMap.containsKey(currentQuote.zqu__Opportunity__c)) {
                    //creat task below in the opportunity 
                    needTaskOppyIdOwnerIdMap.put(currentQuote.zqu__Opportunity__c, oppyIdOwnerIdMap.get(currentQuote.zqu__Opportunity__c));
                }else{
                      //csp-2563 Skip already sent to ZBiling quote. 
                    if(!notSendToZBilingSet.contains(currentQuote.Id)){
                        sendQuote(currentQuote, true);
                    }
                }
            }
        }

        if(xoExceptionList.size()>0){
            insert xoExceptionList;
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug(LoggingLevel.INFO, '*** successOppIdSet: ' + successOppIdSet);
        System.debug(LoggingLevel.INFO, '*** QuoteIdToErrorMessageMap :' + quoteIdToErrorMessageMap);
        System.debug(LoggingLevel.INFO, '*** finish sendQuotesToBilling : ' + sendQuotesToBilling);

        if(sendQuotesToBilling){
            // Send to ZBilling successfully
            xoExceptionList = new List<XO_Exception__C>();
            if (successOppIdSet.size()>0){
                List<Id> currentOppIdList = new List<Id>();
                for (Id oppId : successOppIdSet){
                    if(!failedOppIdSet.contains(oppId)){
                        currentOppIdList.add(oppId);
                    }
                }

                if(currentOppIdList.size()>0){
                    List<Opportunity> successOppList = new List<Opportunity>();
                    for(Id oppId : currentOppIdList){
                        Opportunity successOpp = new Opportunity(Id = oppId);
                        successOpp.StageName= 'Closed Won';
                        successOpp.Actual_Close_Date__c = Date.today();
                        successOpp.NeedToSendToZBilling__c = false;
                        successOppList.add(successOpp);
                        System.debug(LoggingLevel.INFO, '*** successOpp: ' + successOpp);
                    }

                    if(successOppList.size()>0){
                        List<Database.SaveResult> dbSaveResultList = Database.update(successOppList,false);
                        xoExceptionList.addAll(ExceptionUtility.consumeException(successOppList, dbSaveResultList, 'Critical', 'Zuora Sync', false));
                    }
                }
            }

            // Send to ZBilling failed
            if(quoteIdToErrorMessageMap.size()>0){
                Task_Creation_Settings__c taskCreateSetting=Task_Creation_Settings__c.getValues('Error_sending_a_quote_to_Zuora');
                if(taskCreateSetting != null && taskCreateSetting.Create_Task__c){
                    // 1. create error tasks
                    createErrorTasks(quoteIdToErrorMessageMap);
                }

                List<Opportunity> failedOppList = new List<Opportunity>();
                for(Id oppId : failedOppIdSet){
                    // Opportunity failedOpp = (Opportunity)Schema.getGlobalDescribe().get('Opportunity').newSObject(oppId);
                    // failedOpp.put('NeedToSendToZBilling__c', false);
                    Opportunity failedOpp = new Opportunity(Id = oppId);
                    failedOpp.NeedToSendToZBilling__c = false;
                    failedOppList.add(failedOpp);
                    System.debug(LoggingLevel.INFO, '*** : failedOpp' + failedOpp);
                }

                if(failedOppList.size() > 0){
                    List<Database.SaveResult> dbSaveResultList = Database.update(failedOppList,false);
                    xoExceptionList.addAll(ExceptionUtility.consumeException(failedOppList, dbSaveResultList, 'Critical', 'Zuora Sync', false));
                }

            }

            // csp-2485 without location ID and LocationVendorDynamicsAccountID
            if(!needTaskOppyIdOwnerIdMap.isEmpty()){
                createTaskForOppy(needTaskOppyIdOwnerIdMap);
            }

            if(xoExceptionList.size()>0){
                insert xoExceptionList;
            }
        }
        else{
            try{
                // run BatchSendQuotesToZuoraHourly again to send quotes to Zuora 
                Integer size = Integer.valueOf(Label.BatchSendQuoteToZuora_Size);
                BatchSendQuotesToZuoraHourly bat = new BatchSendQuotesToZuoraHourly();
                bat.sendQuotesToBilling = true;
                ID batchprocessid = Database.executeBatch(bat,size);
            }
            catch (Exception ex) {
                ExceptionUtility.consumeException(ex, true);
            }
        }
    }

    /**
     *   CSP-1827 | "sendQuote" sends the Quote records to Zuora. If the "isFirstSendAttempt" parameter is set to true,
     *   in the event sending a Quote fails due to a payment method already being associated to a Billing Account the logic
     *   in this method will attempt to "fix" the data on the Quote and resend to Zuora by recursively calling this method.
     *
     *   @author Jonathan Satterfield
     *   @date   2017-01-18
     *   @param  {zqu__Quote__c}
     *   @param  {Boolean}
     */
    public void sendQuote(zqu__Quote__c quote, Boolean isFirstSendAttempt) {
        System.debug(LoggingLevel.INFO, '*** currentquote.RecordTypeId: ' + quote.RecordTypeId);
        
        List<zqu.zQuoteUtil.ZBillingQuoteCollection> zbqcList = new List<zqu.zQuoteUtil.ZBillingQuoteCollection>(); 
        zqu.zQuoteUtil.ZBillingQuoteCollection zbqc = new zqu.zQuoteUtil.ZBillingQuoteCollection();
        zbqc.quoteRequests = new List<zqu.zQuoteUtil.ZBillingQuoteRequest>();
        zbqc.sfdcAccountId = quote.zqu__Account__c;
        zbqc.zAccountId = quote.zqu__ZuoraAccountID__c == null ? 'new' : quote.zqu__ZuoraAccountID__c;
        // then build the ZBillingQuoteRequest
        zqu.zQuoteUtil.ZBillingQuoteRequest zbqr = new zqu.zQuoteUtil.ZBillingQuoteRequest();
        zbqr.sfdcQuoteId = quote.Id;
        
        // set these ZBillingQuoteRequest variables only if the quote is for a new billing account
        if (zbqc.zAccountId == 'new' && quote.zqu__ElectronicPaymentMethodId__c != null) {
            zbqr.paymentMethodId = quote.zqu__ElectronicPaymentMethodId__c;
            zbqr.processPayment = quote.zqu__ProcessPayment__c;
        }
        else if (zbqc.zAccountId == 'new') {
            zbqr.enableAccountAutoPay = false;
            zbqr.processPayment = false;
            
            //CSP-2563 find all payment Method with check in same opportunity  
            if(quote.zqu__PaymentMethod__c == 'Check') {
                list<zqu__Quote__c> needSendzQuoteList = [SELECT Id, zqu__Opportunity__c, zqu__ZuoraAccountID__c, zqu__PaymentMethod__c FROM zqu__Quote__c 
                                                                        WHERE Id !=: quote.Id 
                                                                        AND zqu__Opportunity__c =: quote.zqu__Opportunity__c 
                                                                        AND zqu__ZuoraAccountID__c = null 
                                                                        AND zqu__PaymentMethod__c = 'Check' ];

                for(zqu__Quote__c checkQuote : needSendzQuoteList){
                      //For skip these quote next into batch job
                    notSendToZBilingSet.add(checkQuote.Id);
                    System.debug(LoggingLevel.INFO, '*** checkQuote.Id: ' + checkQuote.Id);
                    
                    //New ZBillingQuoteRequest for every each quote 
                    zqu.zQuoteUtil.ZBillingQuoteRequest zbqRequest = new zqu.zQuoteUtil.ZBillingQuoteRequest();
                    zbqRequest.sfdcQuoteId = checkQuote.Id;
                    zbqRequest.enableAccountAutoPay = false;
                    zbqRequest.processPayment = false;
                    //All payment menthod with check into one ZBillingQuoteCollection to send
                    zbqc.quoteRequests.add(zbqRequest);
                }
            }
        }
        
        // add the ZBillingQuoteRequest to the ZBillingQuoteCollection's requests list,
        // and add the ZBillingQuoteCollection to the ZBillingQuoteCollection list
        zbqc.quoteRequests.add(zbqr);
        zbqcList.add(zbqc);
        
        try{
            // send to ZBilling, assign the result values to the QuoteWrapper object and return it
            // (if no results is returned at all, the quote will be handled as a failure)
            System.debug(LoggingLevel.INFO, '*** zqu.zQuoteUtil.sendToZBilling: start' );
            System.debug(LoggingLevel.INFO, '*** zbqcList: ' + zbqcList);

            list<zqu.zQuoteUtil.zBillingResult> resultList = new list<zqu.zQuoteUtil.zBillingResult>();
            if (Test.isRunningTest()) {
                // test Sucess
                zqu.zQuoteUtil.zBillingResult testSuccessSalesResult = new zqu.zQuoteUtil.zBillingResult();
                testSuccessSalesResult.Success = true;
                resultList.add(testSuccessSalesResult);
                // test Failure
                zqu.zQuoteUtil.zBillingResult testFailSalesResult = new zqu.zQuoteUtil.zBillingResult();
                testFailSalesResult.Success = false;
                resultList.add(testFailSalesResult);

                zqu.zQuoteUtil.zBillingResult testFailSalesResult2 = new zqu.zQuoteUtil.zBillingResult();
                testFailSalesResult2.Success = false;
                testFailSalesResult2.message = 'payment method has already been associated with a billing account';
                resultList.add(testFailSalesResult2);
            }else{
                resultList = zqu.zQuoteUtil.sendToZBilling(zbqcList);
            }

            for (zqu.zQuoteUtil.zBillingResult result : resultList) {
                if (result.success) {
                    // sent successfully
                    System.debug(LoggingLevel.INFO, '*** zqu.zQuoteUtil.sendToZBilling: success ' );
                    // CSP-2306 Only add success opp to non-closed won Opportunities
                    if(!quote.zqu__Opportunity__r.StageName.equals('Closed Won')) {
                        successOppIdSet.add(quote.zqu__Opportunity__c);    
                    }
                    successQuoteIdSet.add(quote.Id);
                }
                // CSP-1827 / CSP-1015 | attempt fix/resend if the initial send fails due to the payment already being tied to a billing account
                else if (result.message.containsIgnoreCase('payment method has already been associated with a billing account') && isFirstSendAttempt) {
                    Boolean relatedQuoteRecordFound = false;
                    // this query is restricted to returning 1 record
                    for (zqu__Quote__c qRec : [SELECT Id, zqu__Opportunity__c, zqu__ElectronicPaymentMethodId__c, zqu__ZuoraAccountID__c 
                                                                            FROM zqu__Quote__c WHERE zqu__Opportunity__c = :quote.zqu__Opportunity__c 
                                                                            AND zqu__ElectronicPaymentMethodId__c = :quote.zqu__ElectronicPaymentMethodId__c 
                                                                            AND zqu__ZuoraAccountID__c != null LIMIT 1]) {

                        System.debug(LoggingLevel.INFO, '*** zqu.zQuoteUtil.sendToZBilling: attempting payment method repair/resend' );
                        relatedQuoteRecordFound = true;
                        quote.zqu__ZuoraAccountID__c = qRec.zqu__ZuoraAccountID__c;
                        quote.zqu__ElectronicPaymentMethodId__c = '';
                        sendQuote(quote, false); // MUST set the "isFirstSendAttempt" parameter to false, or else we'll have endless recursion
                    }
                    // if no related Quote records found, should add to failure list
                    if (relatedQuoteRecordFound == false) {
                        System.debug(LoggingLevel.INFO, '*** zqu.zQuoteUtil.sendToZBilling: fail ' );
                        quoteIdToErrorMessageMap.put(result.sfdcQuoteId, result.message);
                        quoteOwnerIdMap.put(result.sfdcQuoteId, quote.zqu__Opportunity__r.OwnerId);
                        failedOppIdSet.add(quote.zqu__Opportunity__c);              
                    }
                }
                else {
                    // sent failed
                    System.debug(LoggingLevel.INFO, '*** zqu.zQuoteUtil.sendToZBilling: fail ' );
                    quoteIdToErrorMessageMap.put(result.sfdcQuoteId, result.message);
                    quoteOwnerIdMap.put(result.sfdcQuoteId, quote.zqu__Opportunity__r.OwnerId);
                    failedOppIdSet.add(quote.zqu__Opportunity__c);
                }
            }
            System.debug(LoggingLevel.INFO, '*** zqu.zQuoteUtil.sendToZBilling: end' );
        }catch(Exception e){
            xoExceptionList.add(ExceptionUtility.consumeException(e, false));
        }
    }

    public void resetQuotes(List<zqu__Quote__c> zQuoteList){
        Map<String,Id> quoteRecordTypeNameToIdMap = new Map<String,Id>();
        Map<Id,String> quoteRecordTypeIdToNameMap = new Map<Id,String>();
        Map<String,String> quoteRecordTypeReadOnlyNameToRegularNameMap = new Map<String,String>();
        List<Schema.RecordTypeInfo> sriList = zqu__Quote__c.SObjectType.getDescribe().getRecordTypeInfos();
        for (Schema.RecordTypeInfo rt : sriList) {
            quoteRecordTypeNameToIdMap.put(rt.getName(),rt.getRecordTypeId());
            quoteRecordTypeIdToNameMap.put(rt.getRecordTypeId(),rt.getName());
        }
        quoteRecordTypeReadOnlyNameToRegularNameMap.put('Amendment ReadOnly', 'Amendment');
        quoteRecordTypeReadOnlyNameToRegularNameMap.put('Cancellation ReadOnly', 'Cancellation');
        quoteRecordTypeReadOnlyNameToRegularNameMap.put('ReadOnly', 'Default');
        quoteRecordTypeReadOnlyNameToRegularNameMap.put('Renewal ReadOnly', 'Renewal');
       
        // set those quotes' record type ids to their original value
        for (zqu__Quote__c q : zQuoteList){
            q.RecordTypeId = q.Old_Record_Type__c;
            // CSP-634 | if Record Type value is the Read Only version, set it to the regular version
            if (quoteRecordTypeReadOnlyNameToRegularNameMap.containsKey(quoteRecordTypeIdToNameMap.get(q.RecordTypeId))) {
                String regularRecordTypeName = quoteRecordTypeReadOnlyNameToRegularNameMap.get(quoteRecordTypeIdToNameMap.get(q.RecordTypeId));
                q.RecordTypeId = quoteRecordTypeNameToIdMap.get(regularRecordTypeName);
                System.debug(LoggingLevel.INFO, '*** quote new recordtype: ' + regularRecordTypeName);
            }

            // set the electronic payment method for each quote based on the opportunity
            if (q.zqu__PaymentMethod__c == zqu.PaymentPageController.PAYMENT_METHOD_TYPE_ACH){
                q.zqu__ElectronicPaymentMethodId__c = q.zqu__Opportunity__r.Electronic_Payment_Method_Id_ACH__c;
            }

            if (q.zqu__PaymentMethod__c == zqu.PaymentPageController.PAYMENT_METHOD_TYPE_CREDIT_CARD){
                q.zqu__ElectronicPaymentMethodId__c = q.zqu__Opportunity__r.Electronic_Payment_Method_Id_Credit__c;
            }
        }
        SetQuoteDates(zQuoteList);
        if(zQuoteList.size() > 0){
            Database.SaveResult[] updateResults = Database.update(zQuoteList, false);
            xoExceptionList.addAll(ExceptionUtility.consumeException(updateResults));
        }
    }

    public void SetQuoteDates(List<zqu__Quote__c> zQuoteList){
        for (zqu__Quote__c q : zQuoteList){
            // for ticket SF-2018, set the contract effective date for new subscriptions
            // for ticket SF-2019, set the contract effective date for ammendments
          
            // store the start date (Customer Acceptance Date) based on the day the contract was signed
            // if the contract has not been signed, use today so that we at least have a value
            if (q.zqu__Opportunity__r.Date_Client_Approved__c == null){
                q.zqu__StartDate__c = Date.Today();
            }
            else{
                q.zqu__StartDate__c = q.zqu__Opportunity__r.Date_Client_Approved__c;
            }
          
            // SF-2101 | for all Quotes, set the Invoice Date to the Start Date, which was set above to equal the date the Opp was Client Approved
            q.zqu__InvoiceDate__c = q.zqu__StartDate__c;
    
            // CSP-1649 | if this is a Cancellation Quote, set the Invoice Target Date to January 1, 2099 and then skip the rest of the logic below
            if (q.zqu__SubscriptionType__c == 'Cancel Subscription') {
                q.zqu__InvoiceTargetDate__c = Date.newInstance(2099, 1, 1);
                continue;
            }
          
            // set the service activation date to the date the user selected
            q.zqu__Customer_Acceptance_Date__c = q.zqu__TermStartDate__c;
          
            // for Quotes with a new Billing Account,
            // first set the Bill Cycle Day on the Quote/Account to equal the day value of the Service Activation Date
            if (String.isBlank(q.zqu__ZuoraAccountID__c)) {
                q.zqu__BillCycleDay__c = String.valueOf(q.zqu__Service_Activation_Date__c.day());
                // CSP-2423 - If Bill Cycle Day is set to a day after the 27th, change it to the 27th instead
                if (q.zqu__BillCycleDay__c == '28' || q.zqu__BillCycleDay__c == '29' || q.zqu__BillCycleDay__c == '30' || q.zqu__BillCycleDay__c == '31') {
                    q.zqu__BillCycleDay__c = '27';
                }
            }
          
            // CSP-1799 | for internet services, set the Invoice Target Date to the Service Activation Date
            if (q.Product_Line__c == 'Internet') {
                q.zqu__InvoiceTargetDate__c = q.zqu__Service_Activation_Date__c;
            }
            // otherwise, set the Invoice Target Date to the day before the next Bill Cycle Date after the Service Activation Date;
            // however, if the Bill Cycle Date is one day after the Service Activation Date, the Invoice Target Date is extended out
            // to the day before the following Bill Cycle Date the next month in order to pick up one-time charges.
            else {
                Date serviceActivationDate = q.zqu__Service_Activation_Date__c;
                Integer sadDay = serviceActivationDate.day();
                Integer sadMonth = serviceActivationDate.month();
                Integer sadYear = serviceActivationDate.year();
                Integer bcdMOD = 0;

                // JPS Note 1-18-17: i think this try/catch block is supposed to catch "EOM" values
                try {
                    bcdMOD = Integer.valueOf(q.zqu__BillCycleDay__c) - 1;
                }
                catch (Exception e) {
                    // if it fails, set it to the last possible day of the month
                    bcdMOD = 31;
                }
              
                if (bcdMOD == 0) {
                    bcdMOD = 31; // using 31 because that's the max day of any month
                }
        
                Integer daysInMonth;
                // same month as Service Activation Date
                if (sadDay < bcdMOD) {
                    daysInMonth = Date.daysInMonth(sadYear, sadMonth);
                    if (bcdMOD > daysInMonth) {
                        q.zqu__InvoiceTargetDate__c = Date.newInstance(sadYear, sadMonth, daysInMonth);
                    }
                    else {
                        q.zqu__InvoiceTargetDate__c = Date.newInstance(sadYear, sadMonth, bcdMOD);
                    }
                }
                // the following month of Service Activation Date
                else {
                    if (sadMonth == 12) {
                        daysInMonth = Date.daysInMonth(sadYear + 1, 1);
                        if (bcdMOD > daysInMonth) {
                            q.zqu__InvoiceTargetDate__c = Date.newInstance(sadYear + 1, 1, daysInMonth);
                        }
                        else {
                            q.zqu__InvoiceTargetDate__c = Date.newInstance(sadYear + 1, 1, bcdMOD);
                        }
                    }
                    else {
                        daysInMonth = Date.daysInMonth(sadYear, sadMonth + 1);
                        if (bcdMOD > daysInMonth) {
                            q.zqu__InvoiceTargetDate__c = Date.newInstance(sadYear, sadMonth + 1, daysInMonth);
                        }
                        else {
                            q.zqu__InvoiceTargetDate__c = Date.newInstance(sadYear, sadMonth + 1, bcdMOD);
                        }
                    }
                }
            }
        }
    }//end SetQuoteDates


    public void createErrorTasks(Map<Id, String> quoteIdToErrorMessageMap){
        System.debug(LoggingLevel.INFO, '*** createErrorTasks: ' );
        List<Task> quoteErrors = new List<Task>();
        Set<Id> quoteIdSet = checkTodayTask(quoteIdToErrorMessageMap);
        System.debug(LoggingLevel.INFO, '*** quoteIdSet: ' + quoteIdSet);
        for(Id keyQuoteId : quoteIdToErrorMessageMap.keySet()){
            // check today tasks
            if(!quoteIdSet.contains(keyQuoteId)){
                Task errorTask = new Task();
                String errorMsg = quoteIdToErrorMessageMap.get(keyQuoteId);
                errorTask.OwnerID = quoteOwnerIdMap.get(keyQuoteId);
                errorTask.Subject = 'Error sending a quote to Zuora - please resolve ASAP';
                errorTask.Description = 'When sending this quote to Zuora, we ran into the following error.  It must be resolved quickly in order to fulfill the customer\'s order!';
                errorTask.Description += '\n' + errorMsg;
                errorTask.Description += '\n\nTo resend this quote, please do the following:';
                errorTask.Description += '\n1) Resolve the error above.  The most common error is do to expired payment methods.  This can be done by navigating to the Quote, clicking the button labelled "New Payment Method" and filling in the necessary information.';
                errorTask.Description += '\n2) Go to the Opportunity and click the Send To Z-Billing button.  You can then click the send button on the screen.  If any errors occur, a new task will be created for you.';
                errorTask.Description += '\n3) If the problem persists or the resolution is unclear, please contact your RSD for assistance.';
                errorTask.WhatId = keyQuoteId;
                errorTask.Priority = 'High';
                errorTask.Status = 'Not Started';
                errorTask.Type = 'Other';
                errorTask.Purpose__c = 'Closing';
                errorTask.IsReminderSet = True;
                errorTask.ReminderDateTime = System.now();
                errorTask.ActivityDate = Date.Today();
                quoteErrors.add(errorTask);
                xoExceptionList.add(ExceptionUtility.consumeException('BatchSendQuotesToZuoraHourly',errorMsg,false,keyQuoteId));
            }
        }

        if (!quoteErrors.isEmpty()) {
            insert quoteErrors;
        }
    }

    public void createTaskForOppy(Map<Id,Id> oppyIdOwnerIdMap){
        System.debug(LoggingLevel.INFO, '*** createTaskForOppy: ' + oppyIdOwnerIdMap);
        List<Task> quoteTips = new List<Task>();
        List<Task> taskList = [Select Id, WhatId From Task where WhatId  in: oppyIdOwnerIdMap.keySet() 
                                                            and Subject='Error sending a quote to Zuora - Please filling in require field'];
        //if task already exit , do't create task in the opportunity
        if(!taskList.isEmpty()){
            for(task currentTask : taskList) {
                oppyIdOwnerIdMap.remove(currentTask.WhatId);
            }
        }
        
        for(Id oppyId : oppyIdOwnerIdMap.keySet()){
            //create task in the opportunity
            Task tipTask = new Task();
            tipTask.OwnerID = oppyIdOwnerIdMap.get(oppyId);
            tipTask.Subject = 'Error sending a quote to Zuora - Please filling in require field';
            tipTask.Description = System.Label.MessageWithoutLocationId;
            tipTask.WhatId = oppyId;
            tipTask.Priority = 'High';
            tipTask.Status = 'Not Started';
            tipTask.Type = 'Other';
            tipTask.Purpose__c = 'Closing';
            tipTask.IsReminderSet = True;
            tipTask.ReminderDateTime = System.now();
            tipTask.ActivityDate = Date.Today();
            quoteTips.add(tipTask);
        }
        if (!quoteTips.isEmpty()) {
             insert quoteTips;
        }
    }
    
    

    public Set<Id> checkTodayTask(Map<Id, String> quoteIdToErrorMessageMap){
        Set<Id> quoteIdSet = new Set<Id>();
        Set<Id> taskWhatIdSet = new Set<Id>();
        for(Id keyQuoteId : quoteIdToErrorMessageMap.keySet()){
            taskWhatIdSet.add(keyQuoteId);
        }

        List<Task> taskList = [Select Id, WhatId From Task where WhatId  in :taskWhatIdSet and ActivityDate = :Date.Today() and Subject='Error sending a quote to Zuora - please resolve ASAP'];
        if(taskList.size()>0){
            for(Task tk : taskList){
                quoteIdSet.add(tk.WhatId);
            }
        }
        return quoteIdSet;
    }
}