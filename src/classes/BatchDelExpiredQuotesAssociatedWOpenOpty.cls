global class BatchDelExpiredQuotesAssociatedWOpenOpty implements Database.Batchable<sObject> {
	
	String query;
	Date expDate;
	Id recType;
	global BatchDelExpiredQuotesAssociatedWOpenOpty() {
		// expDate = Date.Today();
		// recType = [Select Id, Name From RecordType  Where SobjectType = 'Opportunity' and DeveloperName = 'Local' LIMIT 1].Id;
		// query = 'Select Id, Opportunity_Expiration_Date__c, Account.Owner.ARR__c, (Select Id, zqu__ValidUntil__c From Zqu__Quotes__r where zqu__Status__c = \'New\' and Zqu__ValidUntil__c <: expDate) From Opportunity where RecordTypeId =: recType and IsClosed = False and Opportunity_Expiration_Date__c <: expDate';
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<Opportunity> scope) {
		// Set<Id> quoteIds = new Set<Id>();
		// List<Task> tskInsertList = new List<Task>();
		// List<Zqu__Quote__c> zquQuoteList = new List<Zqu__Quote__c>();
		// List<String> prdList = new List<String>();
		
		// //Tickets CSP-937
  //       //check the Custom Settings Quote_Deleted field. if field is true then create task.
		// Task_Creation_Settings__c taskCreateSetting=Task_Creation_Settings__c.getValues('Quote_Deleted');
		
		// for(Opportunity opp : scope){
		// 	for(Zqu__Quote__c zqu : opp.Zqu__Quotes__r){
		// 		quoteIds.add(zqu.Id);
		// 	}
		// }
		// system.debug('******************'+quoteIds);
		// for(Zqu__Quote__c zq : [Select Id, Name, Zqu__Opportunity__c, Zqu__Opportunity__r.Account.Owner.ARR__c, Zqu__ValidUntil__c,
		// 								(Select Id, Name, Zqu__ProductRatePlan__c, zqu__ProductRatePlan__r.Name, Product_Type__c, Quote_Expiration_Date__c, Zqu__QuoteProductName__c, ZProduct_Name__c  From Zqu__Quote_Rate_Plans__r) 
		// 							From Zqu__Quote__c where Id IN: quoteIds]){
		// 	Integer count =0;
		// 	String str = '';
		// 	prdList = new List<String>();
		// 	zquQuoteList.add(zq);
		// 	//Tickets CSP-937
		// 	//check the Custom Settings Quote_Deleted field. if field is true then create task.
		// 	if(taskCreateSetting != null && taskCreateSetting.Create_Task__c){				
		// 		Task tsk = new Task();
		// 		tsk.ActivityDate = Date.Today();
		//  		tsk.OwnerId = zq.Zqu__Opportunity__r.Account.Owner.ARR__c;
		//   		tsk.WhatId = zq.Zqu__Opportunity__c;
		//   		tsk.Type = 'Quote Deleted';
		//    		tsk.Purpose__c = 'Quote Deleted';
		//    		tsk.Status = 'Not Started';
		//    		tsk.Subject = 'Quote Deleted :'+ zq.Name;
		// 	   	str = 'The Quote "'+zq.Name+'" expired on '+zq.Zqu__ValidUntil__c+' and has been deleted. The products that were associated with the quotes are ';	
		// 		for(Zqu__QuoteRatePlan__c zPlan : zq.Zqu__Quote_Rate_Plans__r){
		// 			str+= '\n\n Quote Rate Plan Name :'+zPlan.Name+','
		// 	   				+'\n Product Rate Plan :'+zPlan.zqu__ProductRatePlan__r.Name+','
		// 	   				+'\n Product Type :'+zPlan.Product_Type__c+','
		// 	   				+'\n Product Name :'+zPlan.Zqu__QuoteProductName__c
		// 	   				+'\n -------------------------------------------------';		   				
		// 			prdList.add(str);
		// 			str = '';
		// 		}
		// 		tsk.Description = ''+prdList;
		// 		tskInsertList.add(tsk);
		// 	}

		// }
		// system.debug('XXXXXXXXXXXXXXXXXXXXX'+zquQuoteList);
		// if(!tskInsertList.isEmpty())
		// 	Database.insert(tskInsertList, false);

		// if(!zquQuoteList.isEmpty())
		// 	Database.delete(zquQuoteList, false);
	}

	global void finish(Database.BatchableContext BC) {
		
	}
	
}