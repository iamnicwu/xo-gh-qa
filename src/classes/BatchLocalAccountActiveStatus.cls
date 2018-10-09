global class BatchLocalAccountActiveStatus implements Database.Batchable<sObject> {
    
    private String query;
    private Date dateToQuery = Date.today().adddays(-7);
    global BatchLocalAccountActiveStatus() {
        // Date dateToQuery = Date.today().addmonths(-1);
        // CSP-2794 Expiring Account
        // added the code to query the open opportunity under the account
        query =     'SELECT '
                    +   'Longest_Past_Due_Date__c, '
                    +   'Account_Status__c, '
                    +   'Negative_Disposition_Reason__c, '
                    +   'ActiveSubscriptionTCVSummary__c, '
                    +   'Account_Anniversary_Status__c, '
                    +   'Past_Due_Invoice__c, '
                    +   'Past_Due_Balance__c, '
                    +   'Local_Paid_Status__c, '
                    +   'Local_Active__c, '
                    +   'Active_Status_Change_Date__c, '
                    +   'Inactive_Reason__c, '
                    +   'ProductType__c, '
                    +   '(SELECT id FROM Opportunities WHERE IsClosed = FALSE) '
                +   'FROM '
                    +   'Account '
                +   'WHERE '
                    +   'RecordType.Name = \'Local\' '
                +   'AND '
                    +   'Id IN (SELECT Zuora__Account__c FROM Zuora__Subscription__c WHERE LastModifiedDate > :dateToQuery OR Zuora__TermEndDate__c > :dateToQuery)';    
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Account> scope) {
        Integer numberOfExpiredLocalSubscriptionProductCharges;
        Integer numberOfNonExpiredLocalSubscriptionProductCharges;
        Set<String> productTypeStringSet;
        Map<Id,Account> accountMap = new Map<Id,Account>();
        Map<Id,List<Zuora__SubscriptionProductCharge__c>> accountIdToSPCListMap = new Map<Id,List<Zuora__SubscriptionProductCharge__c>>();       
        // add accounts to map 
        for (Account localAccount : scope) {
            // default account values
            localAccount.Local_Paid_Status__c = 'Unpaid';
            localAccount.Local_Active__c = False;
            localAccount.ProductType__c = '';
            localAccount.ActiveSubscriptionTCVSummary__c = 0.00;
            // CSP-2796 Account Anniversary Status
            localAccount.Account_Anniversary_Status__c = 'Prospect';
            accountMap.put(localAccount.Id, localAccount);
        }
        
        // CSP-2796 Account Anniversary Status
        Map<Id, List<Zuora__Subscription__c>> accountSubListMap = new Map<Id, List<Zuora__Subscription__c>>();
        // retrieve all subscription for the local accounts
        List<Zuora__Subscription__c> zuoraSubList = [SELECT id, Zuora__TermStartDate__c, Zuora__TermEndDate__c,Zuora__Account__c, Zuora__Status__c, 
                                                            True_Subscription_Status__c, Is_Valid_Subscription__c, Product_Line__c, 
                                                             (SELECT Id, Product_Type__c, Zuora__TotalContractValue__c 
                                                                FROM Zuora__Subscription_Product_Charges__r 
                                                                WHERE Zuora__Subscription__r.True_Subscription_Status__c = 'Active' 
                                                                    AND Zuora__Subscription__r.Product_Line__c != 'Concierge Venue') 
                                                        FROM Zuora__Subscription__c 
                                                        WHERE Zuora__Account__c IN : accountMap.keyset() ORDER BY Zuora__TermEndDate__c DESC];

        if (!zuoraSubList.isEmpty()) {
            // build the map accountSubListMap whose key is the account Id, value is the all subs list under the account
            Map<Id, Set<String>> accountIdProductTypeMap = new Map<Id, Set<String>>();
            for (Zuora__Subscription__c currentRecord : zuoraSubList) {
                // if the Subscription Term End Date is earlier than Term Start Date, the Sub is InValid, and this Sub will not used for 
                // calculate account Status and Anniversary Status.
                if (!currentRecord.Is_Valid_Subscription__c) {
                    continue;
                }
                List<Zuora__Subscription__c> accountZuoraSubList;
                if (accountSubListMap.containsKey(currentRecord.Zuora__Account__c)) {
                    accountZuoraSubList = accountSubListMap.get(currentRecord.Zuora__Account__c);
                }
                else{
                    accountZuoraSubList = new List<Zuora__Subscription__c>();
                }

                accountZuoraSubList.add(currentRecord);
                accountSubListMap.put(currentRecord.Zuora__Account__c, accountZuoraSubList);

                // move the local paid status logic to here
                Account acc = accountMap.get(currentRecord.Zuora__Account__c);
                // 
                if (currentRecord.True_Subscription_Status__c == 'Active' && currentRecord.Product_Line__c != 'Concierge Venue') {
                    if (String.isNotBlank(currentRecord.Product_Line__c) 
                        && !String.valueOf(acc.ProductType__c).containsIgnoreCase(currentRecord.Product_Line__c)){

                        if (String.isBlank(acc.ProductType__c)) {
                            acc.ProductType__c = currentRecord.Product_Line__c;
                        }
                        else{
                            acc.ProductType__c = acc.ProductType__c + '; ' + currentRecord.Product_Line__c;
                        }
                    }

                    for (Zuora__SubscriptionProductCharge__c zspc : currentRecord.Zuora__Subscription_Product_Charges__r) {
                        if (zspc.Zuora__TotalContractValue__c != null) {
                            acc.ActiveSubscriptionTCVSummary__c += zspc.Zuora__TotalContractValue__c;
                        }
                    }

                    if (acc.Local_Paid_Status__c != 'Paid') {
                        acc.Local_Paid_Status__c = 'Paid';
                        acc.Local_Active__c = True;
                    }
                }
                else if(currentRecord.True_Subscription_Status__c != 'Active' && currentRecord.Product_Line__c != 'Concierge Venue'){
                    if (acc.Local_Paid_Status__c != 'Paid' && acc.Local_Paid_Status__c != 'Expired') {
                        acc.Local_Paid_Status__c = 'Expired';
                        // JPS Note 9-28-15: populating additional "Expired" information for SF-1302
                        acc.Local_Active__c = False;
                        acc.Inactive_Reason__c = 'Expired';
                    }
                }
            }

            for (Id accId : accountSubListMap.keySet()) {
                Account acc = accountMap.get(accId);
                if (!accountSubListMap.get(accId).isEmpty()){
                    List<Zuora__Subscription__c> accountZuoraSubList = accountSubListMap.get(accId);

                    // The theEarlestStartDate stored the earlest Start date of the all no lapse Subs
                    Date theEarlestStartDate = Date.today();
                    for (integer i = 0; i < accountZuoraSubList.size(); i++) {

                        Zuora__Subscription__c currentSub = accountZuoraSubList[i];
                        // if the latest sub has been cancelled or expired, means the all subs have been cancelled or expired, 
                        // set the Anniversary status to 'Prior Vendor'
                        if (i == 0){
                             if(currentSub.Zuora__TermEndDate__c < Date.today()) {

                                acc.Account_Anniversary_Status__c = 'Prior Vendor';
                                
                                // CSP-2794 Expiring Account
                                // CSP-2793 Canceling Account
                                // if there is at least one open Opp under the account, set the Account_Status__c to 'In Opportunity';
                                if (acc.Opportunities.size()>0) {
                                    acc.Account_Status__c = 'In Opportunity';
                                }
                                // if the account has only one sub and the term end date is earlier than today, set the Account_Status__c to 'Dormant'
                                else if(acc.Account_Status__c == 'Active'){
                                    acc.Account_Status__c = 'Dormant';
                                    // if the sub true status is cancelled, set the Negative_Disposition_Reason__c to 'Canceled'
                                    if (currentSub.True_Subscription_Status__c == 'Cancelled') {
                                        acc.Negative_Disposition_Reason__c = 'Canceled';
                                    }
                                    // if the sub true status is Expired, set the Negative_Disposition_Reason__c to 'Expired'
                                    else{
                                        acc.Negative_Disposition_Reason__c = 'Expired';
                                    }
                                }

                                break;

                            }
                            // If the latest sub's Term End Date is greater than or equal Today, we set Anniversary Status to 'New' as a default Value
                            else if(currentSub.Zuora__TermEndDate__c >= Date.today()){

                                acc.Account_Anniversary_Status__c = 'New';

                                // CSP-2794 Expiring Account
                                // if the account has an active sub, set the Account_Status__c to active and clear Negative_Disposition_Reason__c
                                acc.Account_Status__c = 'Active';
                                acc.Negative_Disposition_Reason__c = '';

                                // for the latest sub, the tempSub storing the start date and end date
                                theEarlestStartDate = currentSub.Zuora__TermStartDate__c;
                            }
                        }
                        else{
                            // if there a sub's end date is greater than the tempSub's start date, we should check the sub's True status
                            if (currentSub.Zuora__TermEndDate__c >= theEarlestStartDate) {
                                // if the sub's True status is 'Expired', means the sub has been completed the full term,
                                // we set the Anniversary_Status to 'Renewed' and break the loop
                                if (currentSub.True_Subscription_Status__c == 'Expired') {
                                    acc.Account_Anniversary_Status__c = 'Renewed';

                                    break;

                                }
                                // if the sub is not completed with the full term(Cancelled, active), we should compare the cuurent with tempSub on Start Date
                                // and assign the earlier Start Date to the tempSub's Start Date
                                else if(currentSub.Zuora__TermStartDate__c < theEarlestStartDate){
                                    theEarlestStartDate = currentSub.Zuora__TermStartDate__c;
                                }

                            }
                            // if there a sub's end date is earlier than the tempSub's start date, we should check the sub's term End Date
                            else{

                                // If the sub's term End Date is greater than today, also assign the start date to the theEarlestStartDate
                                // and the anniversary status also set to Default 'New'
                                if (currentSub.Zuora__TermEndDate__c >= Date.today() ) {
                                    theEarlestStartDate = currentSub.Zuora__TermStartDate__c;
                                }
                                // If the sub's term End Date is earlier than today, we should check the lapse
                                else{
                                    // if the lapse less than 12 months, set the anniversary status also set to 'Winback' and break the loop
                                    if(currentSub.Zuora__TermEndDate__c.addmonths(12) > theEarlestStartDate){

                                        acc.Account_Anniversary_Status__c = 'Winback';
                                        break;

                                    }
                                    // if the lapse greater than 12 months, set the anniversary status also set to 'New' and break the loop
                                    else if(currentSub.Zuora__TermEndDate__c.addmonths(12) <= theEarlestStartDate){

                                        acc.Account_Anniversary_Status__c = 'New';
                                        break;
                                    }
                                }
                            } 
                        }
                    }
                }
            }
        }

        Database.SaveResult[] srListNew = Database.update(accountMap.values(), false);

        List<XO_Exception__c> xoExceptionList = ExceptionUtility.consumeException(srListNew);
        if(xoExceptionList.size() >0){
            insert xoExceptionList;
        }
    }
    
    //////////////////
    // FINISH BLOCK //
    //////////////////
    global void finish(Database.BatchableContext BC) {
        // 2906 Paid Status Across the Parent-Child Hierarchy
        BatchAccountAcitveHierarchy batchAccActiveHierarchyClass = new BatchAccountAcitveHierarchy();
        Database.ExecuteBatch(batchAccActiveHierarchyClass, 600);
    }
}