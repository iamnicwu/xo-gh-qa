global class BatchDeleteSelectedTasks implements Database.Batchable<sObject>{

  global BatchDeleteSelectedTasks(){
  }

  global Database.QueryLocator start(Database.BatchableContext BC){
    
    //List<zqu__Quote__c> quoteList = [Select Id from zqu__Quote__c limit 45000];
    
    //String query = 'Select Id from Task where WhatId IN: quoteList limit 10000 ';
  
    String query = 'Select Id from Task where CreatedDate < 2017-12-01T00:00:00Z limit 48000';
  

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