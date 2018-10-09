global class BatchUpdateAcctMarketSaleability implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return null;
    }
    global void execute(Database.BatchableContext BC, list<lead> scope) {}

    global void finish(Database.BatchableContext BC) {}


    
    //Comment by CSP-2712 Decommission Marketplace Health code

    /*
    private String query;
    public String filter;

    //CSP-2618 This batch used to update marketplace saleability of the account
    global Database.QueryLocator start(Database.BatchableContext bc) {

        query = 'SELECT Id, Marketplace_Health__c,Category_Code__c, Primary_Category__r.Category_Code__c, BillingPostalCode, Disqualification_Reason__c ' 
                + ' FROM Account WHERE Disqualification_Reason__c != \'Out of Business\' '
                + ' AND Disqualification_Reason__c != \'Do Not Contact\' AND RecordType.Name = \'Local\' ' ;

        if(filter != NULL ){
            query += filter; 
        }
        System.debug(LoggingLevel.INFO, '*** query: ' + query);
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, list<Account> scope) {
        
        List<Account> updateAcctList = new List<Account>();
        //Used utility to modify lead Market Saleability
        updateAcctList = UpdateMarketplaceSaleabilityUtility.updateAcctMarketSaleability(scope);

        //Update account  
        if(!updateAcctList.isEmpty()){
            List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();
            List<Database.SaveResult> resultList = Database.update(updateAcctList, false);
            xoExceptionList.addAll(ExceptionUtility.consumeException(resultList));

            if (!xoExceptionList.isEmpty()) {
                insert xoExceptionList;
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
    
    }
    */
}