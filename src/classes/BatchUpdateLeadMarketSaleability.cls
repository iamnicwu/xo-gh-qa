global class BatchUpdateLeadMarketSaleability implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return null;
    }
    global void execute(Database.BatchableContext BC, list<lead> scope) {}

    global void finish(Database.BatchableContext BC) {}

    

    //Comment by CSP-2712 Decommission Marketplace Health code


    /*
    private String query;
    //For filter some data to run batch 
    public String filter;
    //For contorl run update account batch job or not.default value is true
    public Boolean isUpdateAccount = true;

    //CSP-2618 This batch used to update marketplace saleability of the Lead
    global Database.QueryLocator start(Database.BatchableContext bc) {

        String deadQueueId = [SELECT Id, Name FROM Group WHERE Type = 'Queue' and name = 'Dead Queue' limit 1].Id;
        query = 'SELECT Id, Marketplace_Health__c, Category_Code__c, Primary_Category__r.Category_Code__c, PostalCode, isConverted, OwnerId FROM Lead ' 
                + ' WHERE OwnerId !=: deadQueueId AND isConverted = false '
                + ' AND Negative_Disposition_Reason__c != \'Out of Business\' ' 
                + ' AND Negative_Disposition_Reason__c != \'Do Not Contact\' AND RecordType.Name = \'Local\' ' ;

        if(filter != NULL ){
            query += filter; 
        }
        System.debug(LoggingLevel.INFO, '*** query: ' + query);
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, list<lead> scope) {
        
        List<lead> updateLeaList = new List<lead>();
        //used utility to modify lead Market Saleability
        updateLeaList = UpdateMarketplaceSaleabilityUtility.updateLeadMarketSaleability(scope);

        //Update Lead 
        if(!updateLeaList.isEmpty()){
            List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();
            List<Database.SaveResult> resultList = Database.update(updateLeaList, false);
            xoExceptionList.addAll(ExceptionUtility.consumeException(resultList));

            if (!xoExceptionList.isEmpty()) {
                insert xoExceptionList;
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        //Update marketplace saleability batch size 
        System.debug(LoggingLevel.INFO, '*** isUpdateAccount: ' + isUpdateAccount);
        if(isUpdateAccount) {
            Integer size = Integer.valueOf(Label.BatchUpdateMarketSaleability_Size);
            //Excute batch for update account market saleability 
            BatchUpdateAcctMarketSaleability cls = new BatchUpdateAcctMarketSaleability();
            Database.executeBatch(cls, size);
        }
    }*/
 }