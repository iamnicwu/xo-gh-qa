/* 
<Class>
  <name>BatchCreateTaskFromInventory</name>
  <purpose>To handle time-based task creation where the owner cannot be determined using workflow</purpose>
  <created>
    <by>Steve O'Neal</by>
    <date>09/16/2015</date>
    <ticket>SF-1223</ticket>
  </created>
</Class>
*/
global class BatchCreateTaskFromInventory implements Database.Batchable<sObject> {

    String query;

    global Database.QueryLocator start(Database.BatchableContext BC){
    	// get account-owned inventory and create notifications for them
      query = 'SELECT '+
                    'Id,' +
                    'Held_By_Type__c,' +
                    'Inventory_Hold_Expiry_Date__c,' +
                    'Product_Rate_Plan__c,' +
                    'Product_Rate_Plan__r.Name,' +
                    'Product_Rate_Plan__r.zqu__Product__r.Name,' + 
                    'Waitlist_Account__c,' +
                    'Waitlist_Account__r.Name,' + 
                    'Waitlist_Account__r.OwnerId,' + 
                    'Waitlist_Account__r.Owner.ManagerId,' +
                    'Held_Until_Extended__c '+
              'FROM '+
                    'Inventory__c '+ 
              'WHERE '+
                    'Held_By_Type__c = \'Account\' and CreatedDate <= TODAY';

      if(Test.isRunningTest()) {
        query = 'SELECT '+
                      'Id,' +
                      'Held_By_Type__c,' +
                      'Inventory_Hold_Expiry_Date__c,' +
                      'Product_Rate_Plan__c,' +
                      'Product_Rate_Plan__r.Name,' +
                      'Product_Rate_Plan__r.zqu__Product__r.Name,' + 
                      'Waitlist_Account__c,' +
                      'Waitlist_Account__r.Name,' + 
                      'Waitlist_Account__r.OwnerId,' + 
                      'Waitlist_Account__r.Owner.ManagerId,' +
                      'Held_Until_Extended__c '+
                'FROM '+
                      'Inventory__c '+ 
                'WHERE '+
                      'Held_By_Type__c = \'Account\'';
      }
      return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Inventory__c> scope){

      List<Task> tasksForInventoryList = new List<Task>();
    	List<Messaging.SingleEmailMessage> notifEmailList = new List<Messaging.SingleEmailMessage>();
    	
      for (Inventory__c inv : scope) {
    		
        // sales rep always gets a task
    		Task invSalesRepTask = createTaskFromInventory(inv);
    		tasksForInventoryList.add(invSalesRepTask);
    		
    		// for held accounts, the sales rep's manager also gets notified on the last day
    		if (inv.Held_Until_Extended__c && inv.Inventory_Hold_Expiry_Date__c == Date.Today() && inv.Waitlist_Account__r.Owner.ManagerId != null) {
	    		Task invManagerTask = createTaskFromInventory(inv);
	    		invManagerTask.OwnerId = String.ValueOf(inv.Waitlist_Account__r.Owner.ManagerId).left(15);
    		}

        //For CSP-1497 Enhancement Request: Waitlist notifications. 
        /// Account Onwer should receive an email notification when one of his vendors moves to the 'on deck' spot on a waitlist.
        Messaging.SingleEmailMessage notifEmail;
        notifEmail = EmailUtility.createWaitListOnDeckEmail(inv);
        notifEmailList.add(notifEmail);
        ///end of CSP-1497
     	}

      List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();

      if(!tasksForInventoryList.isEmpty()) {
          Database.SaveResult[] srList = Database.Insert(tasksForInventoryList, false);
          xoExceptionList.addAll(ExceptionUtility.consumeException(srList));
      }

      if(!notifEmailList.isEmpty()) {
          List<Messaging.SendEmailResult> results = Messaging.sendEmail(notifEmailList, false);
          xoExceptionList.addAll(ExceptionUtility.consumeException(results));
      }

      if(xoExceptionList.size() >0){
          insert xoExceptionList;
      }
    }
    
    global void finish(Database.BatchableContext BC){
    }

    global static Task createTaskFromInventory(Inventory__c inv) {
    
      String formattedDate = inv.Inventory_Hold_Expiry_Date__c.Month() + '/' + inv.Inventory_Hold_Expiry_Date__c.Day() + '/' + inv.Inventory_Hold_Expiry_Date__c.Year();

      Task newTask = new Task();
      newTask.ActivityDate = Date.Today();
      newTask.OwnerId = String.ValueOf(inv.Waitlist_Account__r.OwnerId).left(15);
      newTask.WhatId = inv.Waitlist_Account__c;
      newTask.Type = 'Other';
      newTask.Purpose__c = 'Pitching';
      newTask.Status = 'Not Started';
      newTask.Delete_After_Due_Date__c = FALSE;
      newTask.Subject = 'Waitlisted Account ' + inv.Waitlist_Account__r.Name + ' is on deck until ' + formattedDate;
      newTask.Description = inv.Waitlist_Account__r.Name + ' has moved to the top of the list for ' + inv.Product_Rate_Plan__r.zqu__Product__r.Name + ' - ' + inv.Product_Rate_Plan__r.Name + '.'
                 + '\n\nThey will be available to sell until ' + formattedDate + ' to create a quote, after which the next Account on the waitlist will be notified.';
      
      if (inv.Held_Until_Extended__c) {
        newTask.Description += '\\nThis inventory slot has already been extended once and cannot be extended a second time.';
      }

      return newTask;
    }
}