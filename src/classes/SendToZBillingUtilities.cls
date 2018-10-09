public without sharing class SendToZBillingUtilities {
    
    // Opp Id future call
    @future(callout=true)
    public static void futureChaining(Id oppId) {
        System.enqueueJob(new SendToZBillingUtilities.QueueableOne(oppId));
    }
    
    
    // (serialized wrapper) String future call   
    // 
    @future(callout=true)
    public static void futureChaining(String serializedSTZBWrapper, set<Id> alreadyToSendId) {
        // deserialize then pass to queueable job
        SendToZBillingWrapper stzbWrapper = (SendToZBillingWrapper)JSON.deserialize(serializedSTZBWrapper, SendToZBillingWrapper.class);
        System.enqueueJob(new SendToZBillingUtilities.QueueableOne(stzbWrapper, alreadyToSendId));
    }
 
    public static Id getLocalOppRecordTypeId() {
        Id localOppRecordTypeId;
        for (Schema.RecordTypeInfo oppRTI : Schema.SObjectType.Opportunity.getRecordTypeInfosById().values()) {
            if (oppRTI.getName().containsIgnoreCase('Local')) {
                localOppRecordTypeId = oppRTI.getRecordTypeId();
                break;
            }
        }
        return localOppRecordTypeId;
    }
    
    
    // TODO: determine if this query criteria is good enough -- maybe sort by opp update time? https://developer.salesforce.com/forums/?id=906F000000092srIAA
    public static void startJobForNextClientApprovedOpp() {


        for (Opportunity clientApprovedOpp : [SELECT Id FROM Opportunity WHERE StageName = 'Client Approved' 
                                                AND NeedToSendToZBilling__c = true 
                                                AND RecordTypeId = :SendToZBillingUtilities.getLocalOppRecordTypeId() LIMIT 1]) {
            SendToZBillingUtilities.futureChaining(clientApprovedOpp.Id);
        }
    }
    
    
    // the possible values for the string parameter are "ReadyOnly" or "Editable"
    public static void updateQuoteRecordTypeToReadOnlyOrEditable(Id quoteId, String readOnlyOrEditable) {
        
        Map<String,Id> quoteRecordTypeNameToIdMap = new Map<String,Id>();
        Map<Id,String> quoteRecordTypeIdToNameMap = new Map<Id,String>();
        Map<String,String> quoteRecordTypeReadOnlyNameToEditableNameMap = new Map<String,String>();
        Map<String,String> quoteRecordTypeEditableNameToReadOnlyNameMap = new Map<String,String>();
        
        // populate Quote record type maps
        for (Schema.RecordTypeInfo rt : zqu__Quote__c.SObjectType.getDescribe().getRecordTypeInfos()) {
            quoteRecordTypeNameToIdMap.put(rt.getName(),rt.getRecordTypeId());
            quoteRecordTypeIdToNameMap.put(rt.getRecordTypeId(),rt.getName());
        }
        quoteRecordTypeReadOnlyNameToEditableNameMap.put('Amendment ReadOnly', 'Amendment');
        quoteRecordTypeReadOnlyNameToEditableNameMap.put('Cancellation ReadOnly', 'Cancellation');
        quoteRecordTypeReadOnlyNameToEditableNameMap.put('ReadOnly', 'Default');
        quoteRecordTypeReadOnlyNameToEditableNameMap.put('Renewal ReadOnly', 'Renewal');
        for (String readOnlyValue : quoteRecordTypeReadOnlyNameToEditableNameMap.keySet()) {
            quoteRecordTypeEditableNameToReadOnlyNameMap.put(quoteRecordTypeReadOnlyNameToEditableNameMap.get(readOnlyValue), readOnlyValue);
        }
        
        for (zqu__Quote__c q : [SELECT Id, RecordTypeId FROM zqu__Quote__c WHERE Id = :quoteId LIMIT 1]) {
            String currentRecordTypeName = quoteRecordTypeIdToNameMap.get(q.RecordTypeId);
            if (readOnlyOrEditable.containsIgnoreCase('ReadOnly') && quoteRecordTypeEditableNameToReadOnlyNameMap.containsKey(currentRecordTypeName)) {
                q.RecordTypeId = quoteRecordTypeNameToIdMap.get(quoteRecordTypeEditableNameToReadOnlyNameMap.get(currentRecordTypeName));
            }
            else if (readOnlyOrEditable.containsIgnoreCase('Editable') && quoteRecordTypeReadOnlyNameToEditableNameMap.containsKey(currentRecordTypeName)) {
                q.RecordTypeId = quoteRecordTypeNameToIdMap.get(quoteRecordTypeReadOnlyNameToEditableNameMap.get(currentRecordTypeName));
            }
            update q;
        }
    }
    
    public class QueueableOne implements Queueable, Database.AllowsCallouts {
        
        public SendToZBillingWrapper stzbWrapper {get; set;}
        //CSP-2563 store already to send quote id 
        public set<Id> alreadyToSendId  = new set<Id>();
        
        // Opp Id constructor
        public QueueableOne(Id oppId) {
            this.stzbWrapper = generateSendToZBillingWrapperObject(oppId);
        }
        
        // (deserialized) Wrapper constructor
        public QueueableOne(SendToZBillingWrapper stzbWrapper, set<Id> alreadyToSendId) {
            this.stzbWrapper = stzbWrapper;
            this.alreadyToSendId = alreadyToSendId;
        }  
        
        
        public void execute(QueueableContext context) {
            
            System.debug('stzbWrapper!!!!');
            System.debug(stzbWrapper);
            //Tickets CSP-937
            //check the Custom Settings Error_sending_a_quote_to_Zuora field. if field is true then create task.
            Task_Creation_Settings__c taskCreateSetting = Task_Creation_Settings__c.getValues('Error_sending_a_quote_to_Zuora');
            System.debug(LoggingLevel.INFO, '***alreadyToSendId: ' + alreadyToSendId);
            // first see if there are any Quotes ready to be sent to ZBilling
            if (!stzbWrapper.readyToSend.isEmpty()) { 
                //csp-2563 if frist quote send to ZBilling or not with check payment monthed. 
                if(alreadyToSendId.isEmpty() || !alreadyToSendId.contains(stzbWrapper.readyToSend[0].sfdcQuoteId)) {
                    SendToZBillingWrapper.QuoteWrapper qw = sendQuoteToZBilling(stzbWrapper.readyToSend.remove(0));
                    alreadyToSendId.addAll(qw.alreadyToSendId);
                    if (qw.zBillingResultSuccess) {
                        stzbWrapper.successfullySent.add(qw);
                    }
                    // CSP-1015 | attempt fix/resend if the initial send fails due to the payment already being tied to a billing account
                    else if (qw.zBillingResultMessage.containsIgnoreCase('payment method has already been associated with a billing account')) {
                        qw = attemptPaymentMethodAccountFixAndResendToZBilling(qw);
                        if (qw.zBillingResultSuccess) {
                            stzbWrapper.successfullySent.add(qw);
                        }
                        else {
                            stzbWrapper.failedToSend.add(qw);
                        }
                    }
                    else {
                        stzbWrapper.failedToSend.add(qw);
                    }
                }
                //csp-2563 quote already to sent ZBilling. and do't sent again
                else if(alreadyToSendId.contains(stzbWrapper.readyToSend[0].sfdcQuoteId)) {
                    stzbWrapper.readyToSend.remove(0);
                }
            }

            // if there are more Quotes to send, queue another run via the future method
            if (!stzbWrapper.readyToSend.isEmpty()) {
                SendToZBillingUtilities.futureChaining(JSON.serialize(stzbWrapper),alreadyToSendId);
            }
            // or, if all Quotes were successfully sent, perform that scenario's final logic
            else if (stzbWrapper.failedToSend.isEmpty()) {
                // calling a queuable job to update opoortunity
                sObject successOpp = Schema.getGlobalDescribe().get('Opportunity').newSObject(stzbWrapper.oppId);
                successOpp.put('StageName', 'Closed Won');
                successOpp.put('Actual_Close_Date__c', Date.Today());
                successOpp.put('NeedToSendToZBilling__c', false);
                
                List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();
                Database.SaveResult dbSaveResult = Database.Update(successOpp, false); // updating the opportunity
               
                // adding dbSaveResult inside a list as the method consumeException only accepts a list of type Database.SaveResult
                List<Database.SaveResult> dbSaveResultLst = new List<Database.SaveResult>();
                dbSaveResultLst.add(dbSaveResult);
                
                if(dbSaveResultLst.size() > 0) {
                    xoExceptionList.addAll(ExceptionUtility.consumeException(dbSaveResultLst));
                }
                
                if(xoExceptionList.size() > 0) {
                    insert xoExceptionList;
                }
                // 2. query for another client approved opp and start another job if needed
                SendToZBillingUtilities.startJobForNextClientApprovedOpp();
            }
            // otherwise, if there were some failures perform that scenario's final logic
            else {
                system.debug('111111111: ' + taskCreateSetting);
                //Tickets CSP-937
                //if Custom Settings Error_sending_a_quote_to_Zuora field is true
                if(taskCreateSetting != null && taskCreateSetting.Create_Task__c){
                    // 1. create error tasks
                    createErrorTasks(stzbWrapper.failedToSend);
                }
                // 2. set the new opp boolean flag to false and update the opportunity
                sObject failedOpp = Schema.getGlobalDescribe().get('Opportunity').newSObject(stzbWrapper.oppId);
                failedOpp.put('NeedToSendToZBilling__c', false);
                update failedOpp;
                // 3. query for another client approved opp and start another job if needed
                SendToZBillingUtilities.startJobForNextClientApprovedOpp();
                // TODO: should we reset all the failed-to-send Quote records to their Read-Only record type?
            }
        }
        
        private SendToZBillingWrapper generateSendToZBillingWrapperObject(Id oppId) {
            SendToZBillingWrapper stzbWrapper = new SendToZBillingWrapper();
            stzbWrapper.oppId = oppId;
            // TODO: remove unneeded fields from query
            // get the list of quotes tied to the opportunity that have not yet been sent to z-billing


            List<zqu__Quote__c> zQuotes = [SELECT Id, zqu__PaymentMethod__c, name, zqu__Opportunity__c,Old_Record_Type__c, recordtypeId, 
                                            zqu__ZuoraSubscriptionID__c, zqu__ZuoraAccountID__c, zqu__Account__c, zqu__ProcessPayment__c, 
                                            zqu__ElectronicPaymentMethodId__c, zqu__Opportunity__r.Electronic_Payment_Method_Id_Credit__c, 
                                            zqu__Opportunity__r.Electronic_Payment_Method_Id_ACH__c, zqu__Opportunity__r.OwnerId
                                           FROM zqu__Quote__c
                                           WHERE zqu__Opportunity__c = :oppId
                                           AND zqu__Status__c != 'Sent to Z-Billing'];
            
            for (zqu__Quote__c zQuote : zQuotes) {
                // build QuoteWrapper object
                SendToZBillingWrapper.QuoteWrapper qw = new SendToZBillingWrapper.QuoteWrapper();
                qw.sfdcAccountId = zQuote.zqu__Account__c;
                qw.zAccountId = zQuote.zqu__ZuoraAccountID__c == null ? 'new' : zQuote.zqu__ZuoraAccountID__c;
                qw.sfdcQuoteId = zQuote.Id;
                qw.electronicPaymentMethodId = zQuote.zqu__ElectronicPaymentMethodId__c;
                qw.processPayment = zQuote.zqu__ProcessPayment__c;
                qw.oppOwnerId = zQuote.zqu__Opportunity__r.OwnerId;
                qw.oppId = stzbWrapper.oppId;
                qw.paymentMethod = zQuote.zqu__PaymentMethod__c;
                qw.alreadyToSendId = new set<Id>();
                
                // add the QuoteWrapper object to the SendToZBillingWrapper object's "ready to send" list
                stzbWrapper.readyToSend.add(qw);
            }

            return stzbWrapper;
        }
        
        
        // CSP-1015 | attempt fix/resend if the initial send fails due to the payment already being tied to a billing account
        private SendToZBillingWrapper.QuoteWrapper attemptPaymentMethodAccountFixAndResendToZBilling(SendToZBillingWrapper.QuoteWrapper qw) {

            for (zqu__Quote__c qRec : [SELECT Id, zqu__Opportunity__c, zqu__ElectronicPaymentMethodId__c, zqu__ZuoraAccountID__c 
                                        FROM zqu__Quote__c WHERE zqu__Opportunity__c = :qw.oppId 
                                        AND zqu__ElectronicPaymentMethodId__c = :qw.electronicPaymentMethodId 
                                        AND zqu__ZuoraAccountID__c != null LIMIT 1]) {

                qw.zAccountId = qRec.zqu__ZuoraAccountID__c;
                qw.electronicPaymentMethodId = '';
            }
            return sendQuoteToZBilling(qw);
        }
        
        
        private SendToZBillingWrapper.QuoteWrapper sendQuoteToZBilling(SendToZBillingWrapper.QuoteWrapper qw) {
            
            try {
                
                // first update the Quote's record type so it isn't Read Only (if applicable)
                //SendToZBillingUtilities.updateQuoteRecordTypeToReadOnlyOrEditable(qw.sfdcQuoteId, 'Editable');
                
                // then build the ZBillingQuoteCollection
                List<zqu.zQuoteUtil.ZBillingQuoteCollection> zbqcList = new List<zqu.zQuoteUtil.ZBillingQuoteCollection>(); 
                zqu.zQuoteUtil.ZBillingQuoteCollection zbqc = new zqu.zQuoteUtil.ZBillingQuoteCollection();
                zbqc.quoteRequests = new List<zqu.zQuoteUtil.ZBillingQuoteRequest>();
                zbqc.sfdcAccountId = qw.sfdcAccountId;
                zbqc.zAccountId = qw.zAccountId;
                // then build the ZBillingQuoteRequest
                zqu.zQuoteUtil.ZBillingQuoteRequest zbqr = new zqu.zQuoteUtil.ZBillingQuoteRequest();
                zbqr.sfdcQuoteId = qw.sfdcQuoteId;
                
                // set these ZBillingQuoteRequest variables only if the quote is for a new billing account
                if (zbqc.zAccountId == 'new' && qw.electronicPaymentMethodId != null) {
                    zbqr.paymentMethodId = qw.electronicPaymentMethodId;
                    zbqr.processPayment = qw.processPayment;
                }
                else if (zbqc.zAccountId == 'new') {
                    zbqr.enableAccountAutoPay = false;
                    zbqr.processPayment = false;

                    if(qw.paymentMethod == 'Check'){
                        //CSP-2563 find all payment Method with check in same opportunity  
                        list<zqu__Quote__c> needSendzQuoteList = [SELECT Id, zqu__Opportunity__c, zqu__ZuoraAccountID__c, zqu__PaymentMethod__c FROM zqu__Quote__c 
                                                                            WHERE Id !=: qw.sfdcQuoteId 
                                                                            AND zqu__Opportunity__c =: qw.oppId 
                                                                            AND zqu__ZuoraAccountID__c = null 
                                                                            AND zqu__PaymentMethod__c = 'Check' ];

                        for(zqu__Quote__c checkQuote : needSendzQuoteList){
                            qw.alreadyToSendId.add(checkQuote.Id);
                            //New ZBillingQuoteRequest for every each quote 
                            zqu.zQuoteUtil.ZBillingQuoteRequest zbqRequest = new zqu.zQuoteUtil.ZBillingQuoteRequest();
                            zbqRequest.sfdcQuoteId = checkQuote.Id;
                            zbqRequest.enableAccountAutoPay = false;
                            zbqRequest.processPayment = false;
                            zbqc.quoteRequests.add(zbqRequest);
                        }
                    }
                }
                
                // add the ZBillingQuoteRequest to the ZBillingQuoteCollection's requests list,
                // and add the ZBillingQuoteCollection to the ZBillingQuoteCollection list
                zbqc.quoteRequests.add(zbqr);
                zbqcList.add(zbqc);
                
                // send to ZBilling, assign the result values to the QuoteWrapper object and return it
                // (if no results is returned at all, the quote will be handled as a failure)
                for (zqu.zQuoteUtil.zBillingResult result : zqu.zQuoteUtil.sendToZBilling(zbqcList)) {
                    qw.zBillingResultSuccess = result.success;
                    qw.zBillingResultMessage = result.message;
                    break;
                }
            }
            catch (Exception e) {
                qw.zBillingResultSuccess = false;
                qw.zBillingResultMessage = e.getMessage();
            }
            
            return qw;
        }
        
        
        // create tasks for quotes that failed to send to zbilling
        private void createErrorTasks(List<SendToZBillingWrapper.QuoteWrapper> failedToSend) {
            
            List<Task> quoteErrors = new List<Task>();
            for (SendToZBillingWrapper.QuoteWrapper qw : failedToSend) {
                Task errorTask = new Task();
                errorTask.OwnerID = qw.oppOwnerId;
                errorTask.Subject = 'Error sending a quote to Zuora - please resolve ASAP';
                errorTask.Description = 'When sending this quote to Zuora, we ran into the following error.  It must be resolved quickly in order to fulfill the customer\'s order!';
                errorTask.Description += '\n' + qw.zBillingResultMessage;
                errorTask.Description += '\n\nTo resend this quote, please do the following:';
                errorTask.Description += '\n1) Resolve the error above.  The most common error is do to expired payment methods.  This can be done by navigating to the Quote, clicking the button labelled "New Payment Method" and filling in the necessary information.';
                errorTask.Description += '\n2) Go to the Opportunity and click the Send To Z-Billing button.  You can then click the send button on the screen.  If any errors occur, a new task will be created for you.';
                errorTask.Description += '\n3) If the problem persists or the resolution is unclear, please contact your RSD for assistance.';
                errorTask.WhatId = qw.sfdcQuoteId;
                errorTask.Priority = 'High';
                errorTask.Status = 'Not Started';
                errorTask.Type = 'Other';
                errorTask.Purpose__c = 'Closing';
                errorTask.IsReminderSet = True;
                errorTask.ReminderDateTime = System.now();
                errorTask.ActivityDate = Date.Today();
                quoteErrors.add(errorTask);
            }
            
            if (!quoteErrors.isEmpty()) {
                insert quoteErrors;
            }
        }
    }
}