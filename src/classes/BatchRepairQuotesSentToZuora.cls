/* 
<Class>
<name>BatchRepairQuotesSentToZuora</name>
<purpose>On occassion, Zuora will fail to update Salesforce after successfully sending a quote to Zuora.  When this occurs, 
Salesforce is unaware that the update was successful and will attempt to try the update again.  This batch job will repair 
these quotes by checking to see if there are any subscriptions created for the quotes, and updating them appropriately. 
This will only work if the job runs frequently (every 5 minutes or so).

A batch job was chosen over triggers because of the overhead it creates during the zuora sync process.  This would exacerbate
the problem by creating row lock errors.
</purpose>
<created>
<by>Steve O'Neal</by>
<date>04/28/2016</date>
<ticket>SS-298</ticket>
</created>
</Class>
*/

global class BatchRepairQuotesSentToZuora implements Database.Batchable<sObject> {
    
    global final string query;
    
    global BatchRepairQuotesSentToZuora() {
        query = 'SELECT ID, Name, zqu__Status__c FROM zqu__Quote__c WHERE zqu__Status__c = \'New\' and zqu__Opportunity__r.StageName in (\'Client Approved\',\'Closed Won\')';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Database.QueryLocator retVal = Database.getQueryLocator(query);
        return retVal;
    }
    
    global void execute(Database.BatchableContext BC, List<zqu__Quote__c> scope) {

        List<zqu__Quote__c> quotesToUpdate = new List<zqu__Quote__c>();
        
        try {

            Map<Id, zqu__Quote__c> quoteMap = new Map<Id, zqu__Quote__c>();
            Map<Id, zqu__Quote__c> quoteToUpdateMap = new Map<Id, zqu__Quote__c>();

            
            for (zqu__Quote__c quote : scope) {
                quoteMap.put(quote.Id, quote);
            }
            
            List<zuora__Subscription__c> subscriptions = [Select Id, Name, CreatingSalesforceQuoteID__c
                                                          from zuora__Subscription__c 
                                                          where CreatingSalesforceQuoteID__c in :quoteMap.keySet()];
         
            for (zuora__Subscription__c subscription : subscriptions) {
                if(quoteMap.containsKey(subscription.CreatingSalesforceQuoteID__c)) {
                    zqu__Quote__c newQuoteRec = new zqu__Quote__c();
                    newQuoteRec = quoteMap.get(subscription.CreatingSalesforceQuoteID__c);                    
                    newQuoteRec.zqu__Status__c = 'Sent to Z-Billing';
                    quoteToUpdateMap.put(newQuoteRec.Id, newQuoteRec);
                }
            }

            if(quoteToUpdateMap != null) {
                update quoteToUpdateMap.values();
            }
        }
        catch (Exception e) {

            XO_Exception__c xoException = ExceptionUtility.consumeException(e, true);
            
        }
    }
    
    global void finish(Database.BatchableContext BC) {
    }
}