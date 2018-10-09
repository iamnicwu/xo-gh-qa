// CSP-824
/*
    * Modified by Tony Liu for ticket CSP-1634. The Quote should not be deleted when the Opp had been closed lost.
*/

global class BatchCloseExpiredLocalOpps implements Database.Batchable<sObject> {
    private Date dateToday;
    private Set<String> oppStagesToIgnore;   
    private String query;
    private Date oldDate;

    global BatchCloseExpiredLocalOpps() {
    	dateToday = Date.today();
        
        // csp-1480
        // getting the #days value from the custom settings. This value determines how far back we need to go to 
        // update the opportunities 
        OppUpdateLastModifiedNumberOfDays__c numberOfDays = OppUpdateLastModifiedNumberOfDays__c.getInstance('StandardDaysCount');
        if(numberOfDays != null) {
            Integer days = Integer.valueOf(numberOfDays.Number_of_Days__c);
            system.debug('11111111 ' + days);
            oldDate = dateToday.addDays(-days);
        } else {
            oldDate = dateToday.addDays(-90);
        }
        
        oppStagesToIgnore = new Set<String>{'Closed Won', 'Closed Lost', 'Client Approved'};
        
        query = 'SELECT Id,StageName, Lost_Reason__c FROM Opportunity '
                +' WHERE (Opportunity_Expiration_Date__c < :dateToday OR LastModifiedDate < :oldDate) '
                +' AND StageName NOT IN :oppStagesToIgnore AND RecordType.Name = \'Local\'';

        system.debug('99999999 query: ' + query);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        Database.QueryLocator retVal = Database.getQueryLocator(query);
        system.debug('7777777: ' + retVal);
        return retVal;
    }

    global void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        system.debug('222222222 ' + scope);
        //List<zqu__Quote__c> quoteToBeDeletedLst = new List<zqu__Quote__c>();
        //Set<Id> OppIdSet = new Set<Id>();

    	// CSP-824 | close the expired Opportunity records
    	for (Opportunity opp : scope) {
            system.debug('222222222opp ' + opp);
    		opp.StageName = 'Closed Lost';
            opp.CloseDate = Date.Today();
    		opp.Lost_Reason__c = 'Opportunity Expired';
    	}

        List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();
        Database.SaveResult[] dbSaveResult = Database.update(scope, false);
        xoExceptionList.addAll(ExceptionUtility.consumeException(dbSaveResult));
        
        //csp-1480
        // related quotes are deleted
        ////Modified by Tony, for ticket csp-1634
        // quoteToBeDeletedLst = [SELECT Id, zqu__Opportunity__c,zqu__Opportunity__r.Contract_Signer__c  FROM zqu__Quote__c WHERE zqu__Opportunity__c IN :scope];
        // system.debug('333333333 ' + quoteToBeDeletedLst);
                        
        // if(!quoteToBeDeletedLst.isEmpty()){
        //     Database.DeleteResult[] dbDeleteResult = Database.delete(quoteToBeDeletedLst, false);
        //     system.debug('444444444' + dbDeleteResult);
        //     xoExceptionList.addAll(ExceptionUtility.consumeException(dbDeleteResult));
        // }

        if(xoExceptionList.size() >0){
            system.debug('5555555' + xoExceptionList);
            insert xoExceptionList;
        }
    }

    global void finish(Database.BatchableContext BC) {
    	// don't do anything
    }
}