/*
 *   CSP-3159 Last AM Transfer Date 
 *   This batch used to Calculate total TCV for all items marked "Live" for the Account  
 *   @Author  Mason
 *   @Date    2018-09-10
 *   @period  Monthly  
 */
global class BatchCalculateLiveChargeTCVMonthly implements Database.Batchable<sObject> {
    private String query;
    public String filter;

  
    global Database.QueryLocator start(Database.BatchableContext bc) {
        query = 'SELECT Id, Last_AM_Transfer__c, Live_at_Last_Month_Start__c, Live_at_Every_Month__c, Live_at_Month_Start__c '
                + 'FROM Account WHERE RecordType.Name = \'Local\' '
                + 'AND Account_Status__c = \'Active\' '
                + 'AND Last_AM_Transfer__c != null ';
        
        if(String.isNotBlank(filter)) {
            query += filter;
        }

        System.debug(LoggingLevel.INFO, '*** query: ' + query);
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, list<Account> scope) {
        Decimal tempTCV;
        //Store all Account Id for query Sub charge
        Set<Id> accIdSet = new Set<Id>();
        //Store Account and Total TCV mapping
        Map<Id, Decimal> accIdTotalTCVMap = new Map<Id, Decimal>();
     
        //Collect all Account Id for query Sub charge
        for(Account acc : scope) {
            accIdSet.add(acc.Id);
            // Put field Live at Last Month Start value to field Live at Every Month
            if(acc.Live_at_Last_Month_Start__c != null) {
               if(acc.Live_at_Every_Month__c == null) {
                  acc.Live_at_Every_Month__c = acc.Live_at_Last_Month_Start__c + ' |';
               }
               else {
                  acc.Live_at_Every_Month__c += ' ' + acc.Live_at_Last_Month_Start__c + ' |';
               }
            }
            
            // Put field Live at Month Start value to field Live at Last Month Start
            acc.Live_at_Last_Month_Start__c = acc.Live_at_Month_Start__c != null? acc.Live_at_Month_Start__c: null;

            // Initial Live at Month start 
            acc.Live_at_Month_Start__c = 0;
        }

        //Calculate total TCV for all items marked "Live" for the Account
        for(Zuora__SubscriptionProductCharge__c charge : [SELECT Id, Zuora__Account__c, Zuora__TotalContractValue__c 
                                                            FROM Zuora__SubscriptionProductCharge__c 
                                                            WHERE CommissionLineItemStatus__c = 'Live' AND Zuora__Account__c IN: accIdSet]) {
            //Initial tempTCV
            tempTCV = 0;
            //Get every Account and total Live charge TCV value
            if(String.isNotBlank(charge.Zuora__Account__c) && charge.Zuora__TotalContractValue__c != null ) {
                if(!accIdTotalTCVMap.containsKey(charge.Zuora__Account__c)) {
                    accIdTotalTCVMap.put(charge.Zuora__Account__c, charge.Zuora__TotalContractValue__c);
                } 
                else {
                    tempTCV = accIdTotalTCVMap.get(charge.Zuora__Account__c) + charge.Zuora__TotalContractValue__c;
                    accIdTotalTCVMap.put(charge.Zuora__Account__c, tempTCV);
                }
            }
        }

        // Get current total TCV value to fill in Live At Month Start
        for(Account acc : scope) {
            if(accIdTotalTCVMap.containsKey(acc.Id)) {
                acc.Live_at_Month_Start__c = accIdTotalTCVMap.get(acc.Id);
            }
        }

        // Update Account Live at Mont Start
        if(!scope.isEmpty()) {
            List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();
            List<Database.SaveResult> resultList = Database.update(scope, false);
            xoExceptionList.addAll(ExceptionUtility.consumeException(resultList));

            if (!xoExceptionList.isEmpty()) {
                insert xoExceptionList;
            }
        }
    }

    global void finish(Database.BatchableContext BC) {

    }
}