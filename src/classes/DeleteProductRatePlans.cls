global class DeleteProductRatePlans implements Database.Batchable<sObject>{

  global DeleteProductRatePlans(){
  }

  global Database.QueryLocator start(Database.BatchableContext BC){
    String tempInput ='\'%' + '^'  + '%\'';
    String query = 'Select Id, Name from zqu__productRatePlan__c where Name like '+tempInput + 'Limit 30000';
    system.debug('1111111 query  ' + query);
    return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext BC, List<sObject> scope){
    system.debug('111111 ' + scope.size());
    delete scope;
  }

  global void finish(Database.BatchableContext BC){
  }
}