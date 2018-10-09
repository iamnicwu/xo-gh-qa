/* 
<class>
  <name>BatchNotifyPaymentMethodExpiration</name>
  <purpose>The purpose of this batch class is to,
			1. Identify all those credit card payment methods which are about to expire in 15/20/29/60 days
			2. Send notification to the Bill To customer stating their payment method is about to expire and request them to update it.
			3. Create a reminder task regarding the payment method expiration and assign it the appropriate ARR assocaited with the customer.			
  </purpose>
  <created>
    <by>Hari Mohan</by>
    <date>10/2/2015</date>
    <ticket>SF-1125, SF-1126, SF-1127, SF-1128, SF-1040</ticket>
  </created>
</class>
*/
global class BatchNotifyPaymentMethodExpiration implements Database.Batchable<sObject> {
	
	private static final String PAYMENT_METHOD_QUERY = 'SELECT '+
			'Id, '+
			'Zuora__BillingAccount__r.Name, ' +
			'Zuora__BillingAccount__r.Zuora__BillToName__c, ' +
			'Zuora__BillingAccount__r.Bill_To_Contact__c, ' +
			'Zuora__BillingAccount__r.Bill_To_Contact__r.Email, ' +
			'Zuora__BillingAccount__r.Zuora__Account__c, ' + 
			'Zuora__BillingAccount__r.Zuora__Account__r.OwnerId, ' +
			'Zuora__BillingAccount__r.Zuora__Account__r.Owner.ARR__c, ' +					
			'Zuora__DefaultPaymentMethod__c, ' +
			'SF_Account_Id__c, ' +
			'Billing_Account_Name__c, ' +
			'Notify_customer_Days__c, ' +
			'Zuora__Type__c, ' +
			'Zuora__CreditCardExpirationMonth__c, '+
			'Zuora__CreditCardExpirationYear__c, '+
			'Bill_To_Contact_Email__c ' +
		' FROM ' +
	    	'Zuora__PaymentMethod__c ' +
		' WHERE Zuora__Type__c = \'CreditCard\' ' +
		    'AND Zuora__DefaultPaymentMethod__c = true ' +
		    'AND Zuora__BillingAccount__r.Zuora__Account__r.Local_Paid_Status__c IN (\'Paid\', \'Unpaid\') ' +
		    'AND (Zuora__BillingAccount__r.Zuora__Account__r.Customer_on_Payment_Arrangement__c = false OR Zuora__BillingAccount__r.Zuora__Account__r.Card_Declined__c = true)';

	private static final OrgWideEmailAddress ORG_WIDE_EMAIL_ADDRESS; 
	private static final Id TEMPLATE_ID;
	private Set<Id> missingContactSet;
	
	static {
		List<XO_Exception__c> exceptionList = new List<XO_Exception__c>();

		try {
			ORG_WIDE_EMAIL_ADDRESS = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address = 'theknotaccounting@xogrp.com' LIMIT 1];
		} catch (Exception e) {
			XO_Exception__c xoException = ExceptionUtility.consumeException(e, true);
			exceptionList.add(xoException);
		}	
	
		try {
			TEMPLATE_ID = [SELECT Id, Name FROM EmailTemplate WHERE Name = 'Credit Card Expiration Template'].id;
		} catch (Exception e) {
			XO_Exception__c xoException = ExceptionUtility.consumeException(e, true);
			exceptionList.add(xoException);
		}

		insert exceptionList;
	} 
	
	global BatchNotifyPaymentMethodExpiration() {    
	    missingContactSet = new Set<Id>();
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(PAYMENT_METHOD_QUERY);
	}

    global void execute(Database.BatchableContext BC, List<Zuora__PaymentMethod__c> scope) {
    //START - CSP-2996: Stopping Payment Method Declined tasks in Prod    
		//We may reuse it in the future, so we comment it currently
		//List<Task> tasksToBeInsertedList = new List<Task>();
		//END - CSP-2996: Stopping Payment Method Declined tasks in Prod
		List<Messaging.SingleEmailMessage> emailsToBeInsertedList = new List<Messaging.SingleEmailMessage>();
		List<Zuora__PaymentMethod__c> paymentMethodList = new List<Zuora__PaymentMethod__c>();
		Date expDate = null;
		
		//Retrieve and hold the credit card expiration reminder interval configured in the custom settings
		List<Credit_Card_Expiry_Config__c> creditCrdConfigList = Credit_Card_Expiry_Config__c.getAll().values();
		
		for(Zuora__PaymentMethod__c currentPaymentMethodRec: scope) {
		    
		  // if the contact is null, notify the administrator via email about the missing contact and then move on to the 
			// next record in the loop
			if(String.isBlank(currentPaymentMethodRec.Zuora__BillingAccount__r.Bill_To_Contact__c)) {
				missingContactSet.add(currentPaymentMethodRec.Zuora__BillingAccount__c);
				continue;
			}
			
			// CSP-2294 - Skip records who end with .UAT to prevent hitting limits in test environment
      if(String.isNotBlank(currentPaymentMethodRec.Zuora__BillingAccount__r.Bill_To_Contact__r.Email) && 
				currentPaymentMethodRec.Zuora__BillingAccount__r.Bill_To_Contact__r.Email.endsWith('.uat')) {
				continue;
			}
			
			//Generate the actual expiry date of the card based on the month and year of expiration
			if(Integer.ValueOf(currentPaymentMethodRec.Zuora__CreditCardExpirationMonth__c) != 12){
				expDate = Date.newInstance(Integer.ValueOf(currentPaymentMethodRec.Zuora__CreditCardExpirationYear__c), (Integer.ValueOf(currentPaymentMethodRec.Zuora__CreditCardExpirationMonth__c)+1), 1);
			}else{
				expDate = Date.newInstance((Integer.ValueOf(currentPaymentMethodRec.Zuora__CreditCardExpirationYear__c) + 1), 1, 1);
			}
	
			// look through custom settings and check if the expiry date matches any of the values specified in custom settings 
			for(Integer i = 0; i < creditCrdConfigList.size() ; i++) {						
		 													
              	//Create credit card/ Payment method expiration task and assign it to the ARR
              	//START - CSP-2996: Stopping Payment Method Declined tasks in Prod
								//We may reuse it in the future, so we comment it currently
                /*if((Date.Today().daysBetween(expDate) == Integer.valueOf(creditCrdConfigList[i].Days_Before_Expiry__c)   && creditCrdConfigList[i].Create_ARR_Task__c == True) || (Test.isRunningTest()) ){
                    createTask(currentPaymentMethodRec, tasksToBeInsertedList, Integer.valueOf(creditCrdConfigList[i].Days_Before_Expiry__c));
                }*/
                //END - CSP-2996: Stopping Payment Method Declined tasks in Prod
              
                if( (Date.Today().daysBetween(expDate) == Integer.valueOf(creditCrdConfigList[i].Days_Before_Expiry__c) && creditCrdConfigList[i].Send_Email_To_Customer__c == True) || (Test.isRunningTest())) {
                    createEmail(currentPaymentMethodRec, emailsToBeInsertedList);
                }
		    }
		}	

				//START - CSP-2996: Stopping Payment Method Declined tasks in Prod
				//We may reuse it in the future, so we comment it currently
        /*if(!tasksToBeInsertedList.isEmpty()) {
        	Database.Insert(tasksToBeInsertedList, false);
        }*/
        //END - CSP-2996: Stopping Payment Method Declined tasks in Prod
        
        if(!emailsToBeInsertedList.isEmpty()){
        	Messaging.sendEmail(emailsToBeInsertedList, false);
        }
    }

	/**
	 *   [createEmail: This method is used for creating email by using data from the current payment record and value from 
	 *   the new custom field 'Bill To Contact']
	 *
	 *   @author [Ruchit S]
	 *   @date   2017-08-12
	 *   @param  {[type]}   currentPaymentMethodRec [payment record]
	 *   @param  {[type]}   emailsToSendList        [list of emails to be send out]
	 */
	private void createEmail(Zuora__PaymentMethod__c currentPaymentMethodRec, List<Messaging.SingleEmailMessage> emailsToSendList) {
		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		email.setTargetObjectId(currentPaymentMethodRec.Zuora__BillingAccount__r.Bill_To_Contact__c);
		email.setTemplateId(TEMPLATE_ID);
		email.setWhatId(currentPaymentMethodRec.id);
		email.setSaveAsActivity(true); // save email as activity on the targetObjId (i.e. Contact)
		email.setOrgWideEmailAddressId(ORG_WIDE_EMAIL_ADDRESS.Id);
		emailsToSendList.add(email);
	}

	/**
	 *   [createTask: This method is used to create a task by using date from the current payment record and value from the 
	 *   new custom field 'Bill To Contact']
	 *
	 *   @author [Ruchit S]
	 *   @date   2017-08-12
	 *   @param  {[type]}   currentPaymentMethodRec [payment record]
	 *   @param  {[type]}   emailsToSendList        [list of tasks to be inserted]
	 */
	//START - CSP-2996: Stopping Payment Method Declined tasks in Prod
	//We may reuse it in the future, so we comment it currently 
	/*private void createTask(Zuora__PaymentMethod__c currentPaymentMethodRec, List<Task> tasksToBeInsertedList, Integer daysBeforeExpiry) {
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
	  tsk.Subject = 'The payment method associated with billing account: '+currentPaymentMethodRec.Zuora__BillingAccount__r.Name+' is about to expire in '+daysBeforeExpiry+' Days!';
    tsk.Description = 'The payment method associated with billing account: '+currentPaymentMethodRec.Zuora__BillingAccount__r.Name+' is about to expire in '+daysBeforeExpiry+' Days! Please follow up with the customer.';
		tasksToBeInsertedList.add(tsk);
	}*/
	//END - CSP-2996: Stopping Payment Method Declined tasks in Prod
	
	global void finish(Database.BatchableContext BC) {
		// If the contact set has values generate an email with an attachment to send to Sales Support
		if(!missingContactSet.isEmpty()) {
		    BatchCCDeclinedReminder.notifyAdminAboutMissingContact(new List<Id>(missingContactSet));
    	}
	}
}