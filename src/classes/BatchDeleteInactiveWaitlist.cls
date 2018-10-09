/*
<Class>
  <name>BatchDeleteInactiveWaitlist</name>
  <purpose>Delete the Waitlist which has been inactived pass half year
  </purpose>
  <created>
    <by>Tony Liu</by>
    <date>08/07/2018</date>
    <ticket>CSP-3013</ticket>
  </created>    
*/
global class BatchDeleteInactiveWaitlist implements Database.Batchable<sObject> {
    private String query;
    private Date dateToQuery;
    global BatchDeleteInactiveWaitlist() {
        
        Integer monthsNum = Integer.valueOf(Label.Months_To_Delete_Inactive_Waitlist);
        dateToQuery = Date.today().addmonths(monthsNum);
        this.query = 'SELECT Id FROM Waitlist__c WHERE InActive_Date__c <: dateToQuery ';
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, list<Waitlist__c> scope) {
        
        Delete scope;
    }

    global void finish(Database.BatchableContext BC) {

    }
}