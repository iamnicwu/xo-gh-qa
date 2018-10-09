// This class was refactored and certain changes were made to accommodate updates required for csp-1861
/**
 *   CSP-2139
 *   
 *   Purpose: This Batch has been updated to also account for emails which are somehow missed by the PaymentMethodNewTriggerHandler
 *   - The entire class has been refactored and redundant code has been removed.
 *   - Newly created custom field 'Bill To Contact' on billing account is used instead of creating new contacts and deleting them 
 *     after sending the emails
 *   - Most of the variables have been renamed to make them more readable
 */
global class BatchCCDeclinedReminder implements Database.Batchable<sObject>, Database.Stateful {
	// Missing Billing Accont Contact Id Set - CSP-2139
	private Set<Id> missingContactSet;
	
	public String query;

	List<String> payType = new List<String>();
	List<Zuora__PaymentMethod__c> paymentMethodUpdateList = new List<Zuora__PaymentMethod__c>();
	Map<String, Credit_Card_Declined_Config__c> nameToCCDecConfigMap = new Map<String, Credit_Card_Declined_Config__c>();
	
	private static final OrgWideEmailAddress orgWideEmailAdd; 
	private static final OrgWideEmailAddress noReplyEmailAdd; 
	private static final Id achTemplateId; 
	private static final Id ccTemplateId; 

	static {
		try {
			noReplyEmailAdd = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address = 'noreply@xogrp.com' LIMIT 1];
		} catch (Exception e) {
			XO_Exception__c xoException = ExceptionUtility.consumeException(e, true);
		}
	} 

	static {
		try {
			orgWideEmailAdd = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address = 'theknotaccounting@xogrp.com' LIMIT 1];
		} catch (Exception e) {
			XO_Exception__c xoException = ExceptionUtility.consumeException(e, true);
		}
	} 

	static {
		try {
			achTemplateId = [SELECT Id, Name FROM EmailTemplate WHERE Name = 'ACH Declined Template'].id;
		} catch (Exception e) {
			XO_Exception__c xoException = ExceptionUtility.consumeException(e, true);
		}
	} 

	static {
		try {
			ccTemplateId = [SELECT Id, Name FROM EmailTemplate WHERE Name = 'CC Declined Template'].id;
		} catch (Exception e) {
			XO_Exception__c xoException = ExceptionUtility.consumeException(e, true);
		}
	} 

	global BatchCCDeclinedReminder() {
		// Initialize the Missing Contact Id set
		missingContactSet = new Set<Id>();
		
		payType.add('CreditCard');
		payType.add('ACH');
		nameToCCDecConfigMap = Credit_Card_Declined_Config__c.getAll();

		// Nick CSP-1542 removed some unused fields from Zuora__PaymentMethod__c
		query = 'SELECT '+
								'Id, '+
								'Zuora__BillingAccount__r.Zuora__BillToWorkEmail__c, ' +
								'Zuora__BillingAccount__r.Name, ' +
								'Zuora__BillingAccount__r.Zuora__BillToName__c, ' +
								'Zuora__BillingAccount__r.Bill_To_Contact__c, ' +
								'Zuora__BillingAccount__r.Bill_To_Contact__r.Email, ' +
								'Zuora__BillingAccount__r.Zuora__Account__c, ' + 
								'Zuora__BillingAccount__r.Zuora__Account__r.OwnerId, ' +
								'Zuora__BillingAccount__r.Zuora__Account__r.Owner.ARR__c, ' +
								'Zuora__NumConsecutiveFailures__c, ' +
								'CC_Failure_Notification_Sent__c,' +
								'Zuora__DefaultPaymentMethod__c, ' +
								'SF_Account_Id__c, ' +
								'Billing_Account_Name__c, ' +
								'Notify_customer_Days__c, ' +
								'Bill_To_Contact_Email__c, ' +
								'Zuora__Type__c ' +
						' FROM ' +
							' Zuora__PaymentMethod__c ' +
						' WHERE ' +
								'Zuora__BillingAccount__r.Zuora__Account__r.Past_Due_Balance__c > 0.00 AND ' +
								'Zuora__Type__c IN: payType AND ' +
								'Zuora__DefaultPaymentMethod__c = True'; 
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<Zuora__PaymentMethod__c> scope) {

		Set<Id> accountIdsResetCardStatusSet = new Set<Id>();
		Set<Id> accountIdsUpdateCardsStatusSet = new Set<Id>();
		List<Integer> notificationInterval = new List<Integer>();
		Map<Id,Account> idToAccountMap = new Map<Id, Account>(); 
		
		//START - CSP-2996: Stopping Payment Method Declined tasks in Prod
		//We may reuse it in the future, so we comment it currently 
		//List<Task> tasksToBeInsertedList = new List<Task>(); 
		//END - CSP-2996: Stopping Payment Method Declined tasks in Prod
		
		List<Messaging.SingleEmailMessage> emailsToSendList= new List<Messaging.SingleEmailMessage>();
		List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();
		List<Zuora__PaymentMethod__c> paymentMethodUpdateList = new List<Zuora__PaymentMethod__c>();

		for(Zuora__PaymentMethod__c currentPaymentMethodRec : scope) {
			// CSP-2294 - Skip records who end with .UAT to prevent hitting limits in test environment
			if(String.isNotBlank(currentPaymentMethodRec.Zuora__BillingAccount__r.Bill_To_Contact__r.Email) && 
				currentPaymentMethodRec.Zuora__BillingAccount__r.Bill_To_Contact__r.Email.endsWith('.uat')) {
				continue;
			}

			// if the contact is null, notify the administrator via email about the missing contact and then move on to the 
			// next record in the loop
			if(String.isBlank(currentPaymentMethodRec.Zuora__BillingAccount__r.Bill_To_Contact__c)) {
				missingContactSet.add(currentPaymentMethodRec.Zuora__BillingAccount__c);
				continue;
			}

			//Scenario 1: this is the case where the declined email has never been sent out before and the Zuora__NumConsecutiveFailures__c 
			// are 3 (unless this value is updated in the custom label 'NUMBER_OF_CONSECUTIVE_FAILUERS')
			if(currentPaymentMethodRec.CC_Failure_Notification_Sent__c == False 
				&& currentPaymentMethodRec.Zuora__NumConsecutiveFailures__c == Integer.ValueOf(Label.NUMBER_OF_CONSECUTIVE_FAILUERS)) {
				
				createEmail(currentPaymentMethodRec, emailsToSendList);
				
				//START - CSP-2996: Stopping Payment Method Declined tasks in Prod
				//We may reuse it in the future, so we comment it currently
				//createTask(currentPaymentMethodRec, tasksToBeInsertedList);
				//END - CSP-2996: Stopping Payment Method Declined tasks in Prod
				
				currentPaymentMethodRec.CC_Declined_Notification_First_Sent_On__c = Date.Today();
				currentPaymentMethodRec.CC_Failure_Notification_Sent__c = True;
				paymentMethodUpdateList.add(currentPaymentMethodRec);
				accountIdsUpdateCardsStatusSet.add(currentPaymentMethodRec.SF_Account_Id__c);

			//Scenario 2: this is the case where the declined email has been sent out before and Zuora__NumConsecutiveFailures__c should be 
			// greater than 3. We futher check if the notification interval is either 10 or 20 and the custom setting 'Credit_Card_Declined_Config__c'
			// has 'Send Email to Customer' and 'Create ARR Task' set to true before creating tasks and before sending out emails
			} else if(currentPaymentMethodRec.CC_Failure_Notification_Sent__c == True 
								&& currentPaymentMethodRec.Zuora__NumConsecutiveFailures__c > 0) {

				String notifyCustomerDaysStr = String.valueOf(currentPaymentMethodRec.Notify_customer_Days__c).substringBefore('.');
				if(nameToCCDecConfigMap.containsKey(notifyCustomerDaysStr)) { 

					if(nameToCCDecConfigMap.get(notifyCustomerDaysStr).Send_Email_To_Customer__c == True) {
						createEmail(currentPaymentMethodRec, emailsToSendList);
					}
					//START - CSP-2996: Stopping Payment Method Declined tasks in Prod
					//We may reuse it in the future, so we comment it currently
					/*if(nameToCCDecConfigMap.get(notifyCustomerDaysStr).Create_ARR_Task__c == True) {
						createTask(currentPaymentMethodRec, tasksToBeInsertedList);
					}*/
					//END - CSP-2996: Stopping Payment Method Declined tasks in Prod
				}
				accountIdsUpdateCardsStatusSet.add(currentPaymentMethodRec.SF_Account_Id__c);

			// Scenario 3: this is for populating the set with account Ids for which the Card_Declined__c status should be updated 
			// to false
			} else if(currentPaymentMethodRec.CC_Failure_Notification_Sent__c == False 
								&& currentPaymentMethodRec.Zuora__NumConsecutiveFailures__c == 0) {
					accountIdsResetCardStatusSet.add(currentPaymentMethodRec.SF_Account_Id__c);
			}
		}

		//Update Card Declined Status to False 
		for(Account currentAccount : [SELECT Id, Card_Declined__c FROM Account WHERE Id IN: accountIdsResetCardStatusSet]){
			currentAccount.Card_Declined__c = False;
			idToAccountMap.put(currentAccount.Id, currentAccount);
		}

		// Update Card Declined status to True
		for(Account currentAccount : [SELECT Id, Card_Declined__c FROM Account WHERE Id IN: accountIdsUpdateCardsStatusSet]){
			currentAccount.Card_Declined__c = True;
			idToAccountMap.put(currentAccount.Id, currentAccount);
		}
		//START - CSP-2996: Stopping Payment Method Declined tasks in Prod
		//We may reuse it in the future, so we comment it currently
		/*if(!tasksToBeInsertedList.isEmpty()){
			Database.SaveResult[] dbSaveResult = Database.Insert(tasksToBeInsertedList, False);
			xoExceptionList.addAll(ExceptionUtility.consumeException(dbSaveResult));
		}*/
		//END - CSP-2996: Stopping Payment Method Declined tasks in Prod
		
		if(!emailsToSendList.isEmpty()){
			List<Messaging.SendEmailResult> sendEmailResults = Messaging.sendEmail(emailsToSendList, False);
			xoExceptionList.addAll(ExceptionUtility.consumeException(sendEmailResults));
		}

		// CSP-2139 Payment Method Declined emails are not being sent for a subset of billing accounts
		// this part should be an update action
		if(!paymentMethodUpdateList.isEmpty()) {
			Database.SaveResult[] dbSaveResult = Database.Update(paymentMethodUpdateList, False);
			xoExceptionList.addAll(ExceptionUtility.consumeException(dbSaveResult));
		}

		if(idToAccountMap.values().size() > 0){
			Database.SaveResult[] srUpdList = Database.Update(idToAccountMap.values(), false);
			xoExceptionList.addAll(ExceptionUtility.consumeException(srUpdList));
		}

		if(xoExceptionList.size() > 0){
			insert xoExceptionList;
		}
	}

	/**
	 *   [createEmail: This method is used for creating email by using data from the current payment record and value from 
	 *   the new custom field 'Bill To Contact']
	 *
	 *   @author [Ruchit S]
	 *   @date   2017-07-21
	 *   @param  {[type]}   currentPaymentMethodRec [payment record]
	 *   @param  {[type]}   emailsToSendList        [list of emails to be send out]
	 */
	private void createEmail(Zuora__PaymentMethod__c currentPaymentMethodRec, List<Messaging.SingleEmailMessage> emailsToSendList) {
		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		email.setTargetObjectId(currentPaymentMethodRec.Zuora__BillingAccount__r.Bill_To_Contact__c);
		if(currentPaymentMethodRec.Zuora__Type__c == 'ACH'){
			email.setTemplateId(achTemplateId);
		}else{
			email.setTemplateId(ccTemplateId);
		}
		email.setWhatId(currentPaymentMethodRec.id);
		email.setSaveAsActivity(true); // save email as activity on the targetObjId (i.e. Contact)
		email.setOrgWideEmailAddressId(orgWideEmailAdd.Id);
		emailsToSendList.add(email);
	}

	/**
	 *   [createTask: This method is used to create a task by using date from the current payment record and value from the 
	 *   new custom field 'Bill To Contact']
	 *
	 *   @author [Ruchit S]
	 *   @date   2017-07-21
	 *   @param  {[type]}   currentPaymentMethodRec [payment record]
	 *   @param  {[type]}   emailsToSendList        [list of tasks to be inserted]
	 */
	//START - CSP-2996: Stopping Payment Method Declined tasks in Prod
	//We may reuse it in the future, so we comment it currently
	/*private void createTask(Zuora__PaymentMethod__c currentPaymentMethodRec, List<Task> tasksToBeInsertedList) {
		Id ownersARRId =  currentPaymentMethodRec.Zuora__BillingAccount__r.Zuora__Account__r.Owner.ARR__c; 
		Task tsk = new Task();
		tsk.ActivityDate = Date.Today();
		tsk.OwnerId = ownersARRId != null ? ownersARRId : currentPaymentMethodRec.Zuora__BillingAccount__r.Zuora__Account__r.OwnerId;
		tsk.WhoId = currentPaymentMethodRec.Zuora__BillingAccount__r.Bill_To_Contact__c;
		tsk.WhatId = currentPaymentMethodRec.Id;
		tsk.Type = 'Other';
		tsk.Purpose__c = 'Payment Method Declined'; 
		tsk.Status = 'Not Started';
		tsk.Delete_After_Due_Date__c = True;
		tsk.Subject = 'Payment Method Declined for Billing Account : '+currentPaymentMethodRec.Billing_Account_Name__c+' has been declined!';
		tsk.Description = 'Payment method associated with billing account : '+currentPaymentMethodRec.Billing_Account_Name__c+' has been declined!';
		tasksToBeInsertedList.add(tsk);
	}*/
	//END - CSP-2996: Stopping Payment Method Declined tasks in Prod
		
	/**
	 *   This method is used to notify the admin regarding the missing contact information for the billing accounts
	 *
	 *   @author Ruchit S
	 *   @date   2017-07-21
	 */
	public static void notifyAdminAboutMissingContact(List<Id> billingAccountIdList) {
		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		String title = 'Billing Accounts Missing "Bill To Contact" Information';
		String header = 'List Of Missing Contacts';

		email.setHtmlBody(EmailUtility.createEmailBody(header, 'Attached is a list of ' + billingAccountIdList.size() + ' Billing Account(s) which need their Bill To Contact populated.'));
		email.setSubject(title);
		email.setToAddresses(new String[] {'salessupport@xogrp.com'});
		email.setSaveAsActivity(false);
		email.setOrgWideEmailAddressId(noReplyEmailAdd.Id);

		// Build out the Excel File Blob String
		String stringBlob = 'Billing_Account_Id\r\n';
		for(Integer i = 0; i < billingAccountIdList.size(); i++) {
			Id billingAccountId = billingAccountIdList[i];
			stringBlob += billingAccountId + '\r\n';
		}

		Messaging.EmailFileAttachment excelFile = new Messaging.EmailFileAttachment();
		excelFile.setBody(Blob.valueOf(stringBlob));
		excelFile.setFilename('Missing_Billing_Account_Contacts.xls');
		excelFile.setContentType('application/vnd.ms-excel');

		email.setFileAttachments(new List<Messaging.EmailFileAttachment>{excelFile});

		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
	}
	
	//////////////////
	// FINISH BLOCK //
	//////////////////
	global void finish(Database.BatchableContext BC) {
		// If the contact set has values generate an email with an attachment to send to Sales Support
		if(!missingContactSet.isEmpty()) {
			notifyAdminAboutMissingContact(new List<Id>(missingContactSet));
		}

		//run the BatchNotifyPaymentMethodExpiration job
		Database.executebatch(new BatchNotifyPaymentMethodExpiration(), 50);
	}
}