public with sharing class OpportunitySendToZBillingController {
	public static string readOnlyRecordType = Schema.SObjectType.zqu__Quote__c.getRecordTypeInfosByName().get('ReadOnly').getRecordTypeId();
	// quote list
	private List<zqu__Quote__c> quotes = new List<zqu__Quote__c>();
	// quote rate plan list
	private List<zqu__QuoteRatePlan__c> quoteRatePlans {get;set;}

	private List<QuoteWrapper> quoteWrappers = new List<QuoteWrapper>(); 
	private Opportunity opp;
	private string clientApprovedStageName = 'Client Approved';
	private string closedStageName = 'Closed Won';

	// CSP-634 | used to determine whether or not the SendToZBillingMethod is getting called from a trigger
	public static Boolean sendToZBillingMethodCalledFromTrigger = false;
	
	public static boolean AsyncCalloutComplete {get;set;}
 
	public boolean getShowSendButton()
	{
		return (ApexPages.getMessages().size() == 0);
	}
	
	public pageReference Cancel()
	{
		return new PageReference('/' + opp.Id);
	}
	
	public List<QuoteWrapper> getQuotes()
	{
		return quoteWrappers;
	}
	
	// call for a list of opportunities
	public static ApexPages.Message SendToZBilling(List<Id> oppIds)
	{
		ApexPages.Message retVal = new ApexPages.Message(ApexPages.Severity.Info,'Your request has been queued.  You will be notified via task if there are any issues while processing your request.');
	  
		Map<String,Id> quoteRecordTypeNameToIdMap = new Map<String,Id>();
		Map<Id,String> quoteRecordTypeIdToNameMap = new Map<Id,String>();
		Map<String,String> quoteRecordTypeReadOnlyNameToRegularNameMap = new Map<String,String>();

		// populate Quote record type maps
		for (Schema.RecordTypeInfo rt : zqu__Quote__c.SObjectType.getDescribe().getRecordTypeInfos()) {
			quoteRecordTypeNameToIdMap.put(rt.getName(),rt.getRecordTypeId());
			quoteRecordTypeIdToNameMap.put(rt.getRecordTypeId(),rt.getName());
		}
		quoteRecordTypeReadOnlyNameToRegularNameMap.put('Amendment ReadOnly', 'Amendment');
		quoteRecordTypeReadOnlyNameToRegularNameMap.put('Cancellation ReadOnly', 'Cancellation');
		quoteRecordTypeReadOnlyNameToRegularNameMap.put('ReadOnly', 'Default');
		quoteRecordTypeReadOnlyNameToRegularNameMap.put('Renewal ReadOnly', 'Renewal');

		// try
		// {
			// get the list of quotes tied to the opportunity that have not yet been sent to z-billing
			List<zqu__Quote__c> zQuotes = [select Id, Product_Line__c, zqu__PaymentMethod__c, name, zqu__Opportunity__c,Old_Record_Type__c, recordtypeId, zqu__ZuoraSubscriptionID__c, zqu__ZuoraAccountID__c, zqu__Account__c, zqu__ElectronicPaymentMethodId__c,
							  zqu__Opportunity__r.Electronic_Payment_Method_Id_Credit__c, zqu__Opportunity__r.Electronic_Payment_Method_Id_ACH__c, zqu__Opportunity__r.Date_Client_Approved__c,
							  zqu__Customer_Acceptance_Date__c, zqu__TermStartDate__c, zqu__SubscriptionTermStartDate__c, zqu__StartDate__c, zqu__SubscriptionType__c, zqu__Service_Activation_Date__c, zqu__InvoiceDate__c, zqu__InvoiceTargetDate__c, zqu__BillCycleDay__c
							 from zqu__Quote__c 
							 where zqu__Opportunity__c in :oppIds
							 and zqu__Status__c != 'Sent to Z-Billing'];
							 
			// set those quotes' record type ids to their original value
			for (zqu__Quote__c q : zQuotes)
			{
				q.RecordTypeId = q.Old_Record_Type__c;

				// CSP-634 | if Record Type value is the Read Only version, set it to the regular version
				if (quoteRecordTypeReadOnlyNameToRegularNameMap.containsKey(quoteRecordTypeIdToNameMap.get(q.RecordTypeId))) {
					String regularRecordTypeName = quoteRecordTypeReadOnlyNameToRegularNameMap.get(quoteRecordTypeIdToNameMap.get(q.RecordTypeId));
					q.RecordTypeId = quoteRecordTypeNameToIdMap.get(regularRecordTypeName);
				}
	  
	  
				// set the electronic payment method for each quote based on the opportunity
				if (q.zqu__PaymentMethod__c == zqu.PaymentPageController.PAYMENT_METHOD_TYPE_ACH)
				{
					q.zqu__ElectronicPaymentMethodId__c = q.zqu__Opportunity__r.Electronic_Payment_Method_Id_ACH__c;
				}
				if (q.zqu__PaymentMethod__c == zqu.PaymentPageController.PAYMENT_METHOD_TYPE_CREDIT_CARD)
				{
					q.zqu__ElectronicPaymentMethodId__c = q.zqu__Opportunity__r.Electronic_Payment_Method_Id_Credit__c;
				}
			}
			
			SetQuoteDates(zQuotes);
			
			// update the quotes with the new record type ids
			update zQuotes;
	  
			// no need to update the opportunity so the Opportunity.NeedToSendToZBilling__c field is checked since it's getting called directly
			// if another job is already queued don't do anything, otherwise queue another job
			Set<String> asyncJobStatusSet = new Set<String>{'Holding', 'Queued', 'Preparing', 'Processing'};
			List<AsyncApexJob> jobList = [SELECT Id, Status, ApexClass.Name FROM AsyncApexJob WHERE ApexClass.Name = 'SendToZBillingUtilities' AND Status IN :asyncJobStatusSet LIMIT 1];
			if (jobList.isEmpty()) {
				System.enqueueJob(new SendToZBillingUtilities.QueueableOne(oppIds[0]));
			}
			// if it can't be queued up at this time, and it wasn't called from a trigger method,
			// set the Opportunity.NeedToSendToZBilling__c field to true
			else if (!OpportunitySendToZBillingController.sendToZBillingMethodCalledFromTrigger) {
				List<Opportunity> oppZBillingBoolUpdateList = [SELECT Id FROM Opportunity WHERE Id IN :oppIds AND NeedToSendToZBilling__c = false];
				if (!oppZBillingBoolUpdateList.isEmpty()) {
					for (Opportunity oppRec : oppZBillingBoolUpdateList) {
						oppRec.NeedToSendToZBilling__c = true;
					}
					update oppZBillingBoolUpdateList;
				}
			}
		// }
		// catch (Exception e)
		// {
		// 	retVal = new ApexPages.Message(ApexPages.Severity.Error,'An error occurred while processing your request:' + e.getMessage());
		// }
	
		 return retVal;
	}
	
	
	// sets the appropriate dates for a quote for sending to Zuora
	public static void SetQuoteDates(List<zqu__Quote__c> zQuotes)
	{
		for (zqu__Quote__c q : zQuotes)
		{
			// for ticket SF-2018, set the contract effective date for new subscriptions
			// for ticket SF-2019, set the contract effective date for ammendments
		  
			// store the start date (Customer Acceptance Date) based on the day the contract was signed
			// if the contract has not been signed, use today so that we at least have a value
			if (q.zqu__Opportunity__r.Date_Client_Approved__c == null)
			{
				q.zqu__StartDate__c = Date.Today();
			}
			else
			{
				q.zqu__StartDate__c = q.zqu__Opportunity__r.Date_Client_Approved__c;
			}
		  
			// SF-2101 | for all Quotes, set the Invoice Date to the Start Date, which was set above to equal the date the Opp was Client Approved
			q.zqu__InvoiceDate__c = q.zqu__StartDate__c;
	
			// CSP-1649 | if this is a Cancellation Quote, set the Invoice Target Date to January 1, 2099 and then skip the rest of the logic below
			if (q.zqu__SubscriptionType__c == 'Cancel Subscription') {
				q.zqu__InvoiceTargetDate__c = Date.newInstance(2099, 1, 1);
				continue;
			}
		  
			// set the service activation date to the date the user selected
			q.zqu__Customer_Acceptance_Date__c = q.zqu__TermStartDate__c;
		  
			// for Quotes with a new Billing Account,
			// first set the Bill Cycle Day on the Quote/Account to equal the day value of the Service Activation Date
			if (String.isBlank(q.zqu__ZuoraAccountID__c)) 
			{
				q.zqu__BillCycleDay__c = String.valueOf(q.zqu__Service_Activation_Date__c.day());
				
				// CSP-2423 - If Bill Cycle Day is set to a day after the 27th, change it to the 27th instead
				if (q.zqu__BillCycleDay__c == '28' || q.zqu__BillCycleDay__c == '29' || q.zqu__BillCycleDay__c == '30' || q.zqu__BillCycleDay__c == '31') {
					q.zqu__BillCycleDay__c = '27';
				}
			}
		  

			// CSP-1799 | for internet services, set the Invoice Target Date to the Service Activation Date
			if (q.Product_Line__c == 'Internet') {
        q.zqu__InvoiceTargetDate__c = q.zqu__Service_Activation_Date__c;
      }
			// otherwise, set the Invoice Target Date to the day before the next Bill Cycle Date after the Service Activation Date;
			// however, if the Bill Cycle Date is one day after the Service Activation Date, the Invoice Target Date is extended out
			// to the day before the following Bill Cycle Date the next month in order to pick up one-time charges.
			else {
				Date serviceActivationDate = q.zqu__Service_Activation_Date__c;
				Integer sadDay = serviceActivationDate.day();
				Integer sadMonth = serviceActivationDate.month();
				Integer sadYear = serviceActivationDate.year();
				Integer bcdMOD = 0;

				// JPS Note 1-18-17: i think this try/catch block is supposed to catch "EOM" values
				try
				{
					bcdMOD = Integer.valueOf(q.zqu__BillCycleDay__c) - 1;
				}
				catch (Exception e)
				{
					// if it fails, set it to the last possible day of the month
					bcdMOD = 31;
				}

				if (bcdMOD == 0) 
				{
					bcdMOD = 31; // using 31 because that's the max day of any month
				}
		
				Integer daysInMonth;
				// same month as Service Activation Date
				if (sadDay < bcdMOD) 
				{
					daysInMonth = Date.daysInMonth(sadYear, sadMonth);
					if (bcdMOD > daysInMonth) 
					{
						q.zqu__InvoiceTargetDate__c = Date.newInstance(sadYear, sadMonth, daysInMonth);
					}
					else 
					{
						q.zqu__InvoiceTargetDate__c = Date.newInstance(sadYear, sadMonth, bcdMOD);
					}
				}
				// the following month of Service Activation Date
				else 
				{
					if (sadMonth == 12) 
					{
						daysInMonth = Date.daysInMonth(sadYear + 1, 1);
						if (bcdMOD > daysInMonth) 
						{
							q.zqu__InvoiceTargetDate__c = Date.newInstance(sadYear + 1, 1, daysInMonth);
						}
						else 
						{
							q.zqu__InvoiceTargetDate__c = Date.newInstance(sadYear + 1, 1, bcdMOD);
						}
					}
					else 
					{
						daysInMonth = Date.daysInMonth(sadYear, sadMonth + 1);
						if (bcdMOD > daysInMonth) 
						{
							q.zqu__InvoiceTargetDate__c = Date.newInstance(sadYear, sadMonth + 1, daysInMonth);
						}
						else 
						{
							q.zqu__InvoiceTargetDate__c = Date.newInstance(sadYear, sadMonth + 1, bcdMOD);
						}
					}
				}
			}
		}
	}
	
	
	@future(callout=true)
	public static void AsyncSendToZBilling(List<Id> oppIds)
	{
		AsyncCalloutComplete = false;
		boolean AllQuotesSuccessful = true;
 
		// get the list of quotes tied to the opportunity that have not yet been sent to z-billing
		List<zqu__Quote__c> zQuotes = [select Id, zqu__PaymentMethod__c, name, zqu__Opportunity__c,Old_Record_Type__c, recordtypeId, zqu__ZuoraSubscriptionID__c, zqu__ZuoraAccountID__c, zqu__Account__c, zqu__ProcessPayment__c, zqu__ElectronicPaymentMethodId__c,
												   zqu__Opportunity__r.Electronic_Payment_Method_Id_Credit__c, zqu__Opportunity__r.Electronic_Payment_Method_Id_ACH__c
										from zqu__Quote__c
										where zqu__Opportunity__c in :oppIds
										  and zqu__Status__c != 'Sent to Z-Billing'];
				   
		List<String> retVal = new List<String>();
		List<Task> quoteErrors = new List<Task>();
		List<zqu__Quote__c> quotesThatDidNotSend = new List<zqu__Quote__c>();
  
		// Attempt to send all of the quotes to z-billing.  Create tasks for any failures.
		// create the map of billing accounts for new/ammendment quotes
		Map<String,zqu.zQuoteUtil.ZBillingQuoteCollection> billQuoteCollectionMap = new Map<String, zqu.zQuoteUtil.ZBillingQuoteCollection>();

		//Tickets CSP-937
		//check the Custom Settings Error_sending_a_quote_to_Zuora field. if field is true then create task.
		Task_Creation_Settings__c taskCreateSetting=Task_Creation_Settings__c.getValues('Error_sending_a_quote_to_Zuora');

		for (zqu__Quote__c q : zQuotes)
		{
	  
			zqu.zQuoteUtil.ZBillingQuoteRequest quoteRequest = new zqu.zQuoteUtil.ZBillingQuoteRequest();
			quoteRequest.sfdcQuoteId = q.Id;

			zqu.zQuoteUtil.ZBillingQuoteCollection quoteCollection = null;
			// test if we have hit this billing account before for this opportunity, only send quotes that have not been sent to z-billing
			if (q.zqu__ZuoraAccountID__c != null && billQuoteCollectionMap.containsKey(q.zqu__ZuoraAccountID__c))
			{
				System.Debug('Found a billing account: ' + q.zqu__ZuoraAccountID__c);
				quoteCollection = billQuoteCollectionMap.get(q.zqu__ZuoraAccountID__c);
			}
			else if (billQuoteCollectionMap.containsKey(q.zqu__ElectronicPaymentMethodId__c))
			{
				System.Debug('Found an electronic payment method: ' + q.zqu__ElectronicPaymentMethodId__c);
				quoteCollection = billQuoteCollectionMap.get(q.zqu__ElectronicPaymentMethodId__c);
			}
			else if (billQuoteCollectionMap.containsKey(q.zqu__PaymentMethod__c))
			{
				System.Debug('Found a payment method: ' + q.zqu__PaymentMethod__c);
				quoteCollection = billQuoteCollectionMap.get(q.zqu__PaymentMethod__c);
			}
			else
			{
				System.Debug('create a new quote collection for the billing account');
				quoteCollection = new zqu.zQuoteUtil.ZBillingQuoteCollection();
				quoteCollection.sfdcAccountId = q.zqu__Account__c;
				quoteCollection.quoteRequests = new List<zqu.zQuoteUtil.ZBillingQuoteRequest>();

				if (q.zqu__ZuoraAccountID__c == null)
				{
					quoteCollection.zAccountId = 'new';
				}
				else
				{
					quoteCollection.zAccountId = q.zqu__ZuoraAccountID__c;
				}
		
				// neither is part of the collection.  Figure out which one we have a value for
				// billing account is best to use
				if (q.zqu__ZuoraAccountID__c != null)
				{
					System.Debug('using billing account ' + q.zqu__ZuoraAccountID__c);
					billQuoteCollectionMap.put(q.zqu__ZuoraAccountID__c, quoteCollection);
				}
				// electronic payment method is second best - this only applies for a new electronic payment method
				else if (q.zqu__ElectronicPaymentMethodId__c != null)
				{
					System.Debug('using electronic payment id ' + q.zqu__ElectronicPaymentMethodId__c);
					quoteRequest.paymentMethodId = q.zqu__ElectronicPaymentMethodId__c;
					quoteRequest.processPayment = q.zqu__ProcessPayment__c;
					billQuoteCollectionMap.put(q.zqu__ElectronicPaymentMethodId__c, quoteCollection);
				}
				// payment method is least best - this only applies for a new non-electronic payment method
				else // some other new payment method
				{
					System.Debug('using payment method ' + q.zqu__PaymentMethod__c);
					quoteRequest.enableAccountAutoPay = false;
					quoteRequest.processPayment = false;
					billQuoteCollectionMap.put(q.zqu__PaymentMethod__c, quoteCollection);
				}
			}

			quoteCollection.quoteRequests.add(quoteRequest);
		}

		try
		{
			for (String billingAccount : billQuoteCollectionMap.keyset())
			{
				/*
				zqu.zQuoteUtil.ZBillingQuoteCollection quote = billQuoteCollectionMap.get(billingAccount);
				List<zqu.zQuoteUtil.ZBillingQuoteCollection> billQuotes = new List<zqu.zQuoteUtil.ZBillingQuoteCollection>();
				billQuotes.add(quote);
				*/

				// CSP-648 | send each Quote by itself to avoid record type conflicts
				zqu.zQuoteUtil.ZBillingQuoteCollection mainZBQC = billQuoteCollectionMap.get(billingAccount); 
				for (zqu.zQuoteUtil.ZBillingQuoteRequest singleZBQR : mainZBQC.quoteRequests)
				{
					// populate temporary zQuoteUtil objects and send them up to Zuora
					List<zqu.zQuoteUtil.ZBillingQuoteCollection> billQuotes = new List<zqu.zQuoteUtil.ZBillingQuoteCollection>();
					zqu.zQuoteUtil.ZBillingQuoteCollection tempZBQC = new zqu.zQuoteUtil.ZBillingQuoteCollection();
					List<zqu.zQuoteUtil.ZBillingQuoteRequest> tempZBQRList = new List<zqu.zQuoteUtil.ZBillingQuoteRequest>();
					tempZBQRList.add(singleZBQR);
					tempZBQC.quoteRequests = tempZBQRList;
					tempZBQC.sfdcAccountId = mainZBQC.sfdcAccountId;
					tempZBQC.zAccountId = mainZBQC.zAccountId;

					billQuotes.add(tempZBQC);

					List<zqu.zQuoteUtil.zBillingResult> results = zqu.zQuoteUtil.sendToZBilling(billQuotes);
					boolean quoteFailed = false;
					List<Id> successfullyCreateQuoteIds = new List<Id>();
				
					for ( zqu.zQuoteUtil.zBillingResult result : results ) 
					{
						if (!result.success)
						{
							AllQuotesSuccessful = false;
							quoteFailed = true;
							//Tickets CSP-937
							//check the Custom Settings Quote_Deleted field. if field is true then create task.
							if(taskCreateSetting != null && taskCreateSetting.Create_Task__c){
								Task errorTask = new Task();
								errorTask.OwnerID = UserInfo.GetUserID();
								errorTask.Subject = 'Error sending a quote to Zuora - please resolve ASAP';
								errorTask.Description = 'When sending this quote to Zuora, we ran into the following error.  It must be resolved quickly in order to fulfill the customer\'s order!';
								errorTask.Description += '\n' + result.message;
								errorTask.Description += '\n\nTo resend this quote, please do the following:';
								errorTask.Description += '\n1) Resolve the error above.  The most common error is do to expired payment methods.  This can be done by navigating to the Quote, clicking the button labelled "New Payment Method" and filling in the necessary information.';
								errorTask.Description += '\n2) Go to the Opportunity and click the Send To Z-Billing button.  You can then click the send button on the screen.  If any errors occur, a new task will be created for you.';
								errorTask.Description += '\n3) If the problem persists or the resolution is unclear, please contact your RSD for assistance.';
								errorTask.WhatId = result.sfdcQuoteId;
								errorTask.Priority = 'High';
								errorTask.Status = 'Not Started';
								errorTask.Type = 'Other';
								errorTask.Purpose__c = 'Closing';
								errorTask.IsReminderSet = True;
								errorTask.ReminderDateTime = System.now();
								errorTask.ActivityDate = Date.Today();
								quoteErrors.add(errorTask);
							}
							for (zqu__Quote__c q : zQuotes)
							{
								if (String.ValueOf(q.Id).Left(15) == String.ValueOf(result.sfdcQuoteId).Left(15))
								{
									q.RecordTypeId = readOnlyRecordType;
									quotesThatDidNotSend.add(q);
								}
							}
		
						}
						System.debug( 'Result: QuoteId = ' + result.sfdcQuoteId + ', Success = ' + result.success + ', message = ' + result.message );
					}
				}
			}
		}
		catch(Exception e)
		{
			AllQuotesSuccessful = false;
			System.Debug(e);
			//Tickets CSP-937
			//check the Custom Settings Quote_Deleted field. if field is true then create task.
			if(taskCreateSetting != null && taskCreateSetting.Create_Task__c){
				Task errorTask = new Task();
				errorTask.OwnerID = UserInfo.GetUserID();
				errorTask.Subject = 'Error sending a quote to Zuora - please resolve ASAP';
				errorTask.Description = 'When sending a quote to Zuora, we ran into the following error.  It must be resolved quickly in order to fulfill the customer\'s order!';
				errorTask.Description += '\n' + e.getMessage();
				errorTask.Priority = 'High';
				errorTask.Status = 'Not Started';
				errorTask.Type = 'Other';
				errorTask.Purpose__c = 'Closing';
				errorTask.IsReminderSet = True;
				errorTask.ReminderDateTime = System.now();
				errorTask.ActivityDate = Date.Today();
				quoteErrors.add(errorTask);
			}
		}
		finally
		{
			if (quoteErrors.size() > 0)
			{
				// create the tasks
				insert quoteErrors;
			}
		  
			if (quotesThatDidNotSend.size() > 0)
			{
				// roll back the quotes to their read-only record type
				update quotesThatDidNotSend;
			}
		  
			// update the opportunity
			if (AllQuotesSuccessful)
			{
				List<Opportunity> opps = [select id, stagename from Opportunity where Id in :oppIds];
				for (Opportunity opp : opps)
				{
					opp.stagename = 'Closed Won';
					opp.Actual_Close_Date__c = Date.Today();
				}
				update opps;        
			}
		  
			AsyncCalloutComplete = true;
		}
	}
	
	public OpportunitySendToZBillingController(Apexpages.StandardController controller)
	{
		opp = [select id, stagename from Opportunity where Id = :controller.getRecord().Id];
		if (opp.StageName != clientApprovedStageName && opp.StageName != closedStageName)
		{
			ApexPages.Message msgBadStageName = new ApexPages.Message(ApexPages.Severity.Error,'This Opportunity must be in stage ' + clientApprovedStageName + ' or ' + closedStageName + ' in order to send to Z-Billing.');
			ApexPages.addMessage(msgBadStageName);
		}
		
		// get the quotes from the DB before sending them to z-billing
		quotes = [select Id, name, zqu__Opportunity__c,Old_Record_Type__c, recordtypeId, zqu__ZuoraSubscriptionID__c, zqu__ZuoraAccountID__c, zqu__Account__c from zqu__Quote__c where zqu__Opportunity__c = :opp.Id and zqu__Status__c != 'Sent to Z-Billing'];
		
		if (quotes.size() == 0)
		{
			ApexPages.Message noQuotesFound = new ApexPages.Message(ApexPages.Severity.Error,'No quotes were found for this Opportunity');
			ApexPages.addMessage(noQuotesFound);
		}

		// csp-2485 Disallow Sending Internet Quotes to Zuora without LocationId
		//Check below in the Quote Rate Plan if missing location id and LocationVendorDynamicsAccountID 
		List<zqu__QuoteRatePlanCharge__c> QuoteRatePlanChargeList = [SELECT Id, zqu__QuoteRatePlan__r.zqu__Quote__r.Product_Line__c,Location_Vendor__c
                                                                 FROM zqu__QuoteRatePlanCharge__c 
                                                                 WHERE zqu__QuoteRatePlan__r.zqu__Quote__r.zqu__Opportunity__c = :opp.Id  
                                                                  AND zqu__QuoteRatePlan__r.zqu__Quote__r.Product_Line__c = 'Internet' 
                                                                  AND (Location_Vendor__c = null 
                                                                    or LocationVendorDynamicsAccountID__c = null 
                                                                    or LocationVendorDynamicsAccountID__c = ''
                                                                    OR zqu__QuoteRatePlan__r.Location_Vendor__c = null)];		
		if(!QuoteRatePlanChargeList.isEmpty()){
			ApexPages.Message withoutLocationId = new ApexPages.Message(ApexPages.Severity.Error,System.Label.MessageWithoutLocationId);
			ApexPages.addMessage(withoutLocationId);
		}
		
		else
		{
			// get the rate plans for display
			quoteRatePlans = [Select Id, Name, zqu__Quote__c, zqu__QuoteProductName__c, Account_ID__c, zqu__ProductRatePlan__c, Product_Type__c from zqu__QuoteRatePlan__c where zqu__Quote__r.zqu__Opportunity__c = :opp.Id];
	
			for (zqu__Quote__c quote : quotes)
			{
				QuoteWrapper qw = new QuoteWrapper(quote);
				quoteWrappers.add(qw);
			
				// add the rate plans
				for (zqu__QuoteRatePlan__c qrp : quoteRatePlans)
				{
					if (qrp.zqu__Quote__c == quote.Id)
					{
						qw.RatePlans.add(qrp);
					}
				}
			}
		}
	}
  
  
	// call for this opportunity
	public void SendToZBilling()
	{
		Apexpages.AddMessage(SendToZBilling(new List<Id> {opp.Id}));
	}
  
  
  
	public class QuoteWrapper
	{
		public List<zqu__QuoteRatePlan__c> RatePlans {get;set;}
		public zqu__Quote__c Quote {get;set;}
		public string errorMessage {get;set;}
		
		public QuoteWrapper(zqu__Quote__c quote)
		{
			this.Quote = quote;
			errorMessage = '';
			RatePlans = new List<zqu__QuoteRatePlan__c>();
		  
		}
	}
}