/* 
<class>
	<name>PaymentMethodNewTriggerHandler</name>
	<purpose>The purpose of this trigger handler is to,
			1. Identify all those credit card payment methods which are about to expire in 15/20/29/60 days
			2. Send notification to the Bill To customer stating their payment method is about to expire and request them to update it.
			3. Create a reminder task regarding the payment method expiration and assign it the appropriate ARR assocaited with the customer.     
	</purpose>
	<created>
	<by>Hari Mohan</by>
	<date>10/2/2015</date>
	<ticket>SF-1182</ticket>
	</created>
	<modified>
		<by>Scott Yang</by>
	<date>23 Nov 2016</date>
	<ticket>CSP-1379</ticket>
	</modified>
	<modified>
		<by>Ruchit S</by>
	<date>15 July 2017</date>
	<ticket>CSP-2139</ticket>
	</modified>
</class>
*/

public without sharing class PaymentMethodNewTriggerHandler implements XOTrigger{
	/**
	* Class PaymentMethodNewTriggerHandler
	*
	* Trigger Handler for the Zuora__PaymentMethod__c SObject. This class implements the ITrigger
	* interface to help ensure the trigger code is bulkified and all in one place.
	*/ 

	Set<Id> accoundIdsSet = new Set<Id>();
	Set<Id> paymentMethodIdsSet = new Set<Id>();
	Set<Id> accountIdsResetCardStatusSet = new Set<Id>();

	// CSP-2139
	Set<Id> missingContactSet = new Set<Id>();

	Map<Id, List<Zuora__PaymentMethod__c>> accountIdToPaymentMethodListMap = new Map<Id, List<Zuora__PaymentMethod__c>>();
	Map<Id, Zuora__PaymentMethod__c> accountIdToPaymentMethodMap = new Map<Id, Zuora__PaymentMethod__c>();
	Map<Id, Zuora__PaymentMethod__c> idToPaymentMethodMap = new Map<Id, Zuora__PaymentMethod__c>();

	List<Account> accountUpdateList = new List<Account>();
	//START - CSP-2996: Stopping Payment Method Declined tasks in Prod
	//We may reuse it in the future, so we comment it currently 
	//List<Task> tskInsertList = new List<Task>();
	//END - CSP-2996: Stopping Payment Method Declined tasks in Prod
	List<Zuora__PaymentMethod__c> paymentMethodList = new List<Zuora__PaymentMethod__c>();
	List<Zuora__PaymentMethod__c> paymentMethodUpdateList = new List<Zuora__PaymentMethod__c>();
	List<Messaging.SingleEmailMessage> emailList= new List<Messaging.SingleEmailMessage>();
	List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();

	private static final OrgWideEmailAddress orgWideEmailAdd; 
	private static final OrgWideEmailAddress noReplyEmailAdd; 
	private static final Id achTemplateId; 
	private static final Id ccTemplateId; 
	private static Integer missingContactIndex;

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

	/**
	* bulkBefore
	*
	* This method is called prior to execution of a BEFORE trigger. Use this to cache
	* any data required into maps prior execution of the trigger.
	*/
	public void bulkBefore(){
	}

	public void bulkAfter(){
		if(trigger.isUpdate || trigger.isInsert){

			for(SObject so : trigger.new) {

				missingContactIndex = 1;
			
				Zuora__PaymentMethod__c paymentMethodRec = (Zuora__PaymentMethod__c)so;

				if(paymentMethodRec.Zuora__NumConsecutiveFailures__c == Integer.ValueOf(Label.NUMBER_OF_CONSECUTIVE_FAILUERS)
						&& paymentMethodRec.CC_Failure_Notification_Sent__c == False 
							&& paymentMethodRec.Zuora__DefaultPaymentMethod__c == True) {



					if(!accountIdToPaymentMethodListMap.containsKey(paymentMethodRec.SF_Account_Id__c)){
						paymentMethodList = new List<Zuora__PaymentMethod__c>();
						paymentMethodList.add(paymentMethodRec);
						accountIdToPaymentMethodListMap.put(paymentMethodRec.SF_Account_Id__c, paymentMethodList);
					} else {
						paymentMethodList = accountIdToPaymentMethodListMap.get(paymentMethodRec.SF_Account_Id__c) != null ? accountIdToPaymentMethodListMap.get(paymentMethodRec.SF_Account_Id__c) : new List<Zuora__PaymentMethod__c>();     
						paymentMethodList.add(paymentMethodRec);
						accountIdToPaymentMethodListMap.put(paymentMethodRec.SF_Account_Id__c, paymentMethodList);
					}

					accountIdToPaymentMethodMap.put(paymentMethodRec.SF_Account_Id__c, paymentMethodRec);
					accoundIdsSet.add(paymentMethodRec.SF_Account_Id__c);
				} else if(paymentMethodRec.Zuora__NumConsecutiveFailures__c == 0 && paymentMethodRec.Zuora__DefaultPaymentMethod__c == True){
					accountIdsResetCardStatusSet.add(paymentMethodRec.SF_Account_Id__c);
				}
			}

			for(Zuora__PaymentMethod__c paymentMethod: [SELECT Id, 
                                                          Zuora__BillingAccount__r.Bill_To_Contact__c,
                                                          Zuora__BillingAccount__r.Bill_To_Contact__r.Email,
                                                          Zuora__BillingAccount__r.Zuora__Account__c, 
                                                          Zuora__BillingAccount__r.Zuora__Account__r.OwnerId,
                                                          Zuora__BillingAccount__r.Zuora__Account__r.Owner.ARR__c,
                                                          Zuora__BillingAccount__r.Name,
                                                          Billing_Account_Name__c,
                                                          Zuora__Type__c 
																									FROM 
																												 Zuora__PaymentMethod__c 
																									WHERE 
																												 Id IN: accountIdToPaymentMethodMap.Values()]) {
				
				idToPaymentMethodMap.put(paymentMethod.Id, paymentMethod);
			}

			//Update Card Declined Status to True on the Account
			for(Account acc : [SELECT Id, Card_Declined__c FROM Account WHERE Id IN: accountIdToPaymentMethodMap.KeySet()]){
				acc.Card_Declined__c = True;
				accountUpdateList.add(acc);
			}

			//Update Card Declined Status to False on the customer Account
			for(Account acc : [SELECT Id, Card_Declined__c FROM Account WHERE Id IN: accountIdsResetCardStatusSet]){
				acc.Card_Declined__c = False;
				accountUpdateList.add(acc);
			}

			// Here we loop through all accounts and then through all the payment method inside each account
			if(accountIdToPaymentMethodListMap.keySet() != null) {
				for(Id accountId : accountIdToPaymentMethodListMap.keySet()) {
					for(Zuora__PaymentMethod__c zPaym : accountIdToPaymentMethodListMap.get(accountId)){ 

						if(idToPaymentMethodMap.containsKey(zPaym.Id)) {

							Zuora__PaymentMethod__c paymentMethodRec = idToPaymentMethodMap.get(zPaym.Id);

							// CSP-2294 - Skip records who end with .UAT to prevent hitting limits in test environment
							if(String.isNotBlank(paymentMethodRec.Zuora__BillingAccount__r.Bill_To_Contact__r.Email) && paymentMethodRec.Zuora__BillingAccount__r.Bill_To_Contact__r.Email.endsWith('.uat')) {
								continue;
							}

							// CSP-2139
							if(String.isBlank(paymentMethodRec.Zuora__BillingAccount__r.Bill_To_Contact__c)) {
								missingContactSet.add(paymentMethodRec.Zuora__BillingAccount__c);
								missingContactIndex ++;
							} 
							else {
								emailsAndTasksCreation(paymentMethodRec);
								paymentMethodIdsSet.add(paymentMethodRec.Id);
							} 
						}
					}
				}
			}

			for(Zuora__PaymentMethod__c currentPaymentMethod : [SELECT Id, CC_Declined_Notification_First_Sent_On__c, CC_Failure_Notification_Sent__c
																													FROM Zuora__PaymentMethod__c 
																													WHERE Id IN: paymentMethodIdsSet]){
				currentPaymentMethod.CC_Declined_Notification_First_Sent_On__c = Date.Today();
				currentPaymentMethod.CC_Failure_Notification_Sent__c = True;
				paymentMethodUpdateList.add(currentPaymentMethod);
			}
		}
	}

	/**
	 *   emailsAndTasksCreation: This method is for creating email to inform customers about declined payments and to inform ARR
	 *   about the same so that they can take appropriate actions
	 *
	 *   @author Ruchit S
	 *   @date   2017-07-18
	 *   @param  {Zuora__PaymentMethod__c}   zPaym Current Payment Record being processed by the trigger
	 */
	public void emailsAndTasksCreation(Zuora__PaymentMethod__c zPaym){
		//START - CSP-2996: Stopping Payment Method Declined tasks in Prod
		//We may reuse it in the future, so we comment it currently 
		// TASKS creation
		/*Task tsk = new Task();
		tsk.ActivityDate = Date.Today();
		tsk.OwnerId = zPaym.Zuora__BillingAccount__r.Zuora__Account__r.Owner.ARR__c != null ? zPaym.Zuora__BillingAccount__r.Zuora__Account__r.Owner.ARR__c : zPaym.Zuora__BillingAccount__r.Zuora__Account__r.OwnerId;
		tsk.WhoId = zPaym.Zuora__BillingAccount__r.Bill_To_Contact__c;
		tsk.WhatId = zPaym.Id;
		tsk.Type = 'Other';
		tsk.Purpose__c = 'Payment Method Declined';
		tsk.Status = 'Not Started';
		tsk.Subject = 'Payment method associated with billing account : '+zPaym.Billing_Account_Name__c+' has been declined!';
		tsk.Description = 'Payment method associated with billing account : '+zPaym.Billing_Account_Name__c+' has been declined!';
		tskInsertList.add(tsk);*/
		//END - CSP-2996: Stopping Payment Method Declined tasks in Prod
	
		// EMAILS creation
		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		email.setTargetObjectId(zPaym.Zuora__BillingAccount__r.Bill_To_Contact__c);
		if(zPaym.Zuora__Type__c == 'ACH'){
			email.setTemplateId(achTemplateId);
		}else{
			email.setTemplateId(ccTemplateId);
		}
		email.setWhatId(zPaym.id);
		email.setSaveAsActivity(true); // save email as activity on the targetObjId (i.e. Contact)
		email.setOrgWideEmailAddressId(orgWideEmailAdd.Id);
		emailList.add(email);
	}

	public void beforeInsert(SObject so){
	}

	public void beforeUpdate(SObject oldSo, SObject so){
	}
	
	/**
	* beforeDelete
	*
	* This method is called iteratively for each paymentMethodRec to be deleted during a BEFORE
	* trigger.
	*/  
	public void beforeDelete(SObject so){
	}
 
	public void afterInsert(SObject so){
	}
	
	public void afterUpdate(SObject oldSo, SObject so){
	}
 
	public void afterDelete(SObject so){
	}

	/**
		*   All final logic in the "before" context should be done at this point such as modification to objects outside of
		*   the current object. At this point all updates to the current trigger transaction should be
		*   complete and all validation done.
		*/
	public void beforeAndFinally() {
	}
	
	/**
		*   All final logic in the "after" context should be done at this point such as modification to objects outside of
		*   the current object. At this point all updates to the current trigger transaction should be
		*   complete and all validation done.
		*/
	public void afterAndFinally(){
		if(!accountUpdateList.isEmpty()){
			Database.SaveResult[] srUpdList = Database.Update(accountUpdateList, false);
			xoExceptionList.addAll(ExceptionUtility.consumeException(srUpdList));
		}
		//START - CSP-2996: Stopping Payment Method Declined tasks in Prod
		//We may reuse it in the future, so we comment it currently
		/*if(!tskInsertList.isEmpty()){
			Database.SaveResult[] srList = Database.Insert(tskInsertList, false);
			xoExceptionList.addAll(ExceptionUtility.consumeException(srList));
		}*/
		//END - CSP-2996: Stopping Payment Method Declined tasks in Prod
		if(!missingContactSet.isEmpty()) {
			BatchCCDeclinedReminder.notifyAdminAboutMissingContact(new List<Id>(missingContactSet));
		}

		if(!emailList.isEmpty()) {
			System.debug(emailList);
			List<Messaging.SendEmailResult> serList = Messaging.sendEmail(emailList);
			xoExceptionList.addAll(ExceptionUtility.consumeException(serList));
			
		}

		if(!paymentMethodUpdateList.isEmpty()) {
			Database.SaveResult[] urList = Database.Update(paymentMethodUpdateList, false);
			xoExceptionList.addAll(ExceptionUtility.consumeException(urList));
		}

		if(xoExceptionList.size() >0){
			insert xoExceptionList;
		}
	}
}