global class testbach implements Database.Batchable<sObject> {
    public String query;

    global testbach() {
        // this.query = 'select id,External_Key__c from Marketplace_Health__c';
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
       return null;
    }

    global void execute(Database.BatchableContext BC, list<sObject> scope) {}
    
    // global Database.QueryLocator start(Database.BatchableContext bc) {
    //     return Database.getQueryLocator(query);
    // }

    // global void execute(Database.BatchableContext BC, list<Marketplace_Health__c> scope) {
    //     for (Marketplace_Health__c testmh : scope) {
    //         testmh.External_Key__c = testmh.External_Key__c.replace('-','');
    //     }
    //     update scope;
    // }

    global void finish(Database.BatchableContext BC) {

    }
}