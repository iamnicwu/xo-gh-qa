/**
 *@description: Create a task for an invoice where promise to pay date expired. 
 *				functionality should not exeucte on Weekend and on monday it should look for invoice which expired overweek and task needs to be created.
 *				Note: make sure batch executes on Week days only.
 *				CSP-1302
 *
 */
public class BatchCreateTaskForInvoice implements Database.Batchable<sObject>{
	
	private String query;
	private date expirationDate;
	private Date todayDate;
	private String dayOfWeek;
	private String defaultUserName = Label.Default_CBSS_Name; //default user name to assign task if there is not a CBSS assigned to the associated account.
	private OrgWideEmailAddress orgEmail;
	private String url;

	public BatchCreateTaskForInvoice(){
		todayDate = date.today();
		Datetime dt = DateTime.newInstance(todayDate, Time.newInstance(0, 0, 0, 0));
		String dayOfWeek = dt.format('EEEE');
		Integer noOfDay = dayOfWeek == 'Monday'? 3 : 1;// Need to skip functionality on weekend, so on Monday create task for Friday, Saturday and sunday.
		
		expirationDate = test.isRunningTest()? todayDate.addDays(1) : todayDate.adddays(-noOfDay);
		todayDate = test.isRunningTest()? todayDate.addDays(3) : todayDate;
		
		query = 'SELECT Id, Name, Zuora__Account__r.OwnerId, Zuora__Balance2__c, Promise_to_Pay_Date__c, Promise_To_Pay_Amount__c, Zuora__Account__c, Zuora__Account__r.Name FROM Zuora__ZInvoice__c '
    			+' WHERE Zuora__Balance2__c > 0 AND Promise_to_Pay_Date__c >=: expirationDate AND Promise_to_Pay_Date__c <: todayDate AND Zuora__Account__c != null';
	
		// get Organization Wide Email to use for sending out EchoSign Notifications
		try {
			orgEmail = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@xogrp.com' LIMIT 1];
		}
		catch(Exception e) {
			ExceptionUtility.consumeException(e, true);
			// we want to record the exception (which we do directly above), but we also don't want 
			// the batch job to proceed, so re-throw the exception here to prevent batch job execution
			throw e;
		}
		
		url = System.URL.getSalesforceBaseUrl().toExternalForm();
	}
	
	public Database.QueryLocator start(Database.BatchableContext BC) {
        Database.QueryLocator retVal = Database.getQueryLocator(query);
        return retVal;
    }
    
    public void execute(Database.BatchableContext BC, List<Zuora__ZInvoice__c> scope) {
    	if(dayOfWeek == 'Saturday' || dayOfWeek == 'Sunday'){
    		return;
    	}

        // For ticket CSP-1835, if the Promise_to_Pay_Date__c had past, blank out the field Promise_to_Pay_Date__c and Promise_To_Pay_Amount__c
        List<Zuora__ZInvoice__c>  updateZInvoiceList= new List<Zuora__ZInvoice__c>();
    	
    	List<Task> taskInsertList = new List<Task>();
    	// CSP-1594 | also send an email notification regarding the expired Promise to Pay
    	List<Messaging.SingleEmailMessage> p2pEmailList = new List<Messaging.SingleEmailMessage>();
    	
    	Set<String> userIdSet = new Set<String>();
    	for(Zuora__ZInvoice__c invObj : scope){
    		userIdSet.add(invObj.Zuora__Account__r.OwnerId);

            invObj.Promise_To_Pay_Amount__c = null;
            invObj.Promise_to_Pay_Date__c = null;
            updateZInvoiceList.add(invObj);
    	}
    	
    	Map<String, User> userMap = new Map<String, User>();
    	List<User> userList = [SELECT Id, Name, ARR__c FROM User WHERE (Id IN : userIdSet AND IsActive = true)or Name =: defaultUserName];
    	for(User userObj : userList){
    		if(userObj.Name == defaultUserName){
    			userMap.put(defaultUserName,userObj);
    		}else{
    			userMap.put(userObj.id, userObj);
    		}
    		
    	}
    	for(Zuora__ZInvoice__c invObj : scope){
    		String ownerId = '';
    		if(userMap.containsKey(invObj.Zuora__Account__r.OwnerId) && userMap.get(invObj.Zuora__Account__r.OwnerId).ARR__c != null){
    			ownerId = userMap.get(invObj.Zuora__Account__r.OwnerId).ARR__c;
    		}else{
    			ownerId = userMap.containsKey(defaultUserName) ? userMap.get(defaultUserName).id : ownerId;
    		}
    		
    		// create task and add to list
    		Task taskObj = new Task();
            taskObj.OwnerId = ownerId;
            taskObj.WhatId = invObj.Zuora__Account__c;
            taskObj.Subject = 'Promise To Pay';
            taskObj.Status = 'Not Started';
            taskObj.Priority = 'Normal';
            taskObj.Purpose__c = 'Other';
            taskObj.Description = 'The associated customer\'s promise to pay date has expired. \n'
            				+url+'/'+ invObj.id +' '+invObj.Name;
            taskObj.Type =  'Call';
            taskInsertList.add(taskObj);

            // CSP-1594 | create email and add to list
			Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
			String title = 'Promise to Pay Expiration';
			String body = '<h3>The associated customer\'s promise to pay date has expired:</h3>'
            				+ '<b>Invoice "' + invObj.Name + '":</b> ' + url + '/' + invObj.id
            				+ '<br/><b>Account "' + invObj.Zuora__Account__r.Name + '":</b> ' + url + '/' + invObj.Zuora__Account__c;
			email.setHtmlBody(EmailUtility.createEmailBody(title, body));
			email.setSubject(title);
			email.setTargetObjectId(ownerId);
			email.setSaveAsActivity(false);
			email.setOrgWideEmailAddressId(orgEmail.Id);
			p2pEmailList.add(email);            
    	}
    	
    	//Try inserting all the task in the tskInsertList.. Ignore those records which cannot be inserted due to certain error
    	List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();
        if(!taskInsertList.isEmpty()){
            Database.SaveResult[] dbSaveResult = Database.Insert(taskInsertList, false);
            xoExceptionList.addAll(ExceptionUtility.consumeException(dbSaveResult));
        }

        if (!updateZInvoiceList.isEmpty()) {
            Database.SaveResult[] invoiceSaveResults = Database.update(updateZInvoiceList, false);
            xoExceptionList.addAll(ExceptionUtility.consumeException(invoiceSaveResults));
        }
        
        if(xoExceptionList.size() > 0){
        	insert xoExceptionList;
        }

        // CSP-1594 | attempt to send emails
        if (p2pEmailList.size() > 0) {
        	try {
        		Messaging.sendEmail(p2pEmailList);
        	}
        	catch(Exception e) {
				ExceptionUtility.consumeException(e, true);
			}
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        
    }
}