public without sharing class ZuoraQuoteChooseNextActionController {

	public Id quoteId {get;set;}
	public Id oppId {get;set;}
	public String nextAction = 'Submit for Internal Approvals'; // specify the default radio button here
	public zqu__Quote__c theQuote {get;set;}
	private Boolean getContactInfoFromCustomerAccount = True; // default to true


	public ZuoraQuoteChooseNextActionController(ApexPages.StandardController standardController) {

		this.quoteId = null;
		zqu__Quote__c quote = (zqu__Quote__c)standardController.getRecord();

		if (quote != null) {
			this.quoteId = quote.id;
			this.theQuote = [SELECT Id, zqu__BillingBatch__c, zqu__SubscriptionType__c, zqu__ZuoraAccountID__c, 
														zqu__Opportunity__c, zqu__Opportunity__r.Type, 
														zqu__Opportunity__r.OwnerId,
														zqu__PaymentMethod__c, 
														zqu__ElectronicPaymentMethodId__c, zqu__ExistSubscriptionID__c, zqu__Previewed_Delta_MRR__c, 
														zqu__Previewed_MRR__c, zqu__Previewed_SubTotal__c, zqu__Previewed_Tax__c, 
														zqu__Previewed_TCV__c, zqu__Previewed_Total__c, BillToContactQuoteTemplateMergeField__c, 
														SoldToContactQuoteTemplateMergeField__c, zqu__BillToContact__c, zqu__SoldToContact__c, 
														zqu__TermStartDate__c, zqu__SubscriptionTermEndDate__c, zqu__RenewalTerm__c, zqu__InitialTerm__c 
											FROM zqu__Quote__c WHERE Id = :quoteId LIMIT 1];
			this.oppId = this.theQuote.zqu__Opportunity__c;

			// if blank, will need to get contact info from the Quote's zqu__BillToContact__c and zqu__SoldToContact__c
			if (String.isBlank(this.theQuote.zqu__ZuoraAccountID__c)) {
				this.getContactInfoFromCustomerAccount = False;
			}

			// CSP-1818 | set default radio button to "View Quote Details" if Opportunity Type is "Renewal"
			if (this.theQuote.zqu__Opportunity__r.Type == 'Renewal') {
				this.nextAction = 'View Quote Details';
			}
		}
	}

	public void runLocalProductRulesAndUpdateTCV() {
		// CSP-1972  Resume Call Recording After filling all payment method info.
		// if(NewVoiceMediaUtility.getNVMCallRecordingPauseCookie() == 'Paused' && NewVoiceMediaUtility.resumeCallRecording()){
		// CSP-2096  Resume Call in CreateNewPaymentMethod.page instead of ZuoraQuoteChooseNextActionController.cls
		// NewVoiceMediaUtility.pauseOrResumeCallRecording('Started');

		zqu__Quote__c theQuote = RecalculateQuoteCharges(theQuote);
 
		// Code for CSP-430- OM
		List<zqu__CommunicationProfile__c> commProfileList = [Select Id,Name from zqu__CommunicationProfile__c];
		Map<String,Id> commProfileMap = new Map<String,Id>();
		
		for(zqu__CommunicationProfile__c commProfile : commProfileList)
		{
			commProfileMap.put(commProfile.Name,commProfile.Id);
		}
		
		system.debug('Map===>'+commProfileMap);
		 
		if(theQuote.zqu__PaymentMethod__c == 'Credit Card'|| theQuote.zqu__PaymentMethod__c == 'ACH')
		{
		 theQuote.zqu__CommunicationProfile__c = commProfileMap.get('Default Profile');
		 system.debug('Credit Card====>'+theQuote.zqu__CommunicationProfile__c+commProfileMap.get('Default Profile'));
		}
		else if (theQuote.zqu__PaymentMethod__c == 'Check')
		{
		 theQuote.zqu__CommunicationProfile__c = commProfileMap.get('Invoice Notifications');
		 system.debug('Check====>'+theQuote.zqu__CommunicationProfile__c+commProfileMap.get('Invoice Notifications'));
		}
		system.debug('Final value====>'+theQuote.zqu__CommunicationProfile__c);
		
		// set the billing batch for the quote
		if (theQuote.zqu__PaymentMethod__c == 'Credit Card')
		{
			theQuote.zqu__BillingBatch__c = 'Batch1';
		}
		else if (theQuote.zqu__PaymentMethod__c == 'ACH')
		{
			theQuote.zqu__BillingBatch__c = 'Batch2';
		}
		else if (theQuote.zqu__PaymentMethod__c == 'Check')
		{
			theQuote.zqu__BillingBatch__c = 'Batch3';
		}

		// SF-2177; populating the BillToContactQuoteTemplateMergeField__c and SoldToContactQuoteTemplateMergeField__c fields
		// (would have renamed the method, but don't want to mess up test classes on Feb 2)
		if (this.getContactInfoFromCustomerAccount) {
			// only queries one record
			for (Zuora__CustomerAccount__c zca : [SELECT Id, Zuora__Zuora_Id__c, Zuora__SoldToName__c, SoldToCity__c, SoldToCountry__c, 
														 SoldToAddress1__c, SoldToAddress2__c, SoldToState__c, 
														 SoldToPostalCode__c, Zuora__BillToName__c, Zuora__BillToCity__c, 
														 Zuora__BillToCountry__c, Zuora__BillToAddress1__c, Zuora__BillToAddress2__c, 
														 Zuora__BillToState__c, Zuora__BillToPostalCode__c 
												  FROM Zuora__CustomerAccount__c 
												  WHERE Zuora__Zuora_Id__c = :this.theQuote.zqu__ZuoraAccountID__c LIMIT 1]) {

					String soldToInfo = zca.Zuora__SoldToName__c;
					soldToInfo += ('\n' + zca.SoldToAddress1__c);
					if (!String.isBlank(zca.SoldToAddress2__c)) {
					soldToInfo += ('\n' + zca.SoldToAddress2__c);
				}
				soldToInfo += ('\n' + zca.SoldToCity__c + ', ' + zca.SoldToState__c);
				soldToInfo += ('\n' + zca.SoldToPostalCode__c);
				this.theQuote.SoldToContactQuoteTemplateMergeField__c = soldToInfo;


				String billToInfo = zca.Zuora__BillToName__c;
				billToInfo += ('\n' + zca.Zuora__BillToAddress1__c);
				if (!String.isBlank(zca.Zuora__BillToAddress2__c)) {
					billToInfo += ('\n' + zca.Zuora__BillToAddress2__c);
				}
				billToInfo += ('\n' + zca.Zuora__BillToCity__c + ', ' + zca.Zuora__BillToState__c);
				billToInfo += ('\n' + zca.Zuora__BillToPostalCode__c);
				this.theQuote.BillToContactQuoteTemplateMergeField__c = billToInfo;
			}		
		}
		else {
			Set<Id> conIdSet = new Set<Id>();
			conIdSet.add(this.theQuote.zqu__BillToContact__c);
			conIdSet.add(this.theQuote.zqu__SoldToContact__c);
			Map<Id, Contact> bsContactMap = new Map<Id, Contact>([SELECT Id, Name, MailingStreet, MailingCity, MailingState, MailingPostalCode FROM Contact WHERE Id IN :conIdSet]);
			if (!bsContactMap.isEmpty()) {
				if (bsContactMap.containsKey(this.theQuote.zqu__SoldToContact__c)) {
					Contact soldToContact = bsContactMap.get(this.theQuote.zqu__SoldToContact__c);
					String soldToInfo = soldToContact.Name;
					soldToInfo += ('\n' + soldToContact.MailingStreet);
					soldToInfo += ('\n' + soldToContact.MailingCity + ', ' + soldToContact.MailingState);
					soldToInfo += ('\n' + soldToContact.MailingPostalCode);
					this.theQuote.SoldToContactQuoteTemplateMergeField__c = soldToInfo;
				}
				if (bsContactMap.containsKey(this.theQuote.zqu__BillToContact__c)) {
					Contact billToContact = bsContactMap.get(this.theQuote.zqu__BillToContact__c);
					String billToInfo = billToContact.Name;
					billToInfo += ('\n' + billToContact.MailingStreet);
					billToInfo += ('\n' + billToContact.MailingCity + ', ' + billToContact.MailingState);
					billToInfo += ('\n' + billToContact.MailingPostalCode);
					this.theQuote.billToContactQuoteTemplateMergeField__c = billToInfo;
				}
			}
		}

		update this.theQuote;

		setServiceRunDatesTemplateMergeFieldOnCharges(this.theQuote);

		LocalProductRules.evaluateOpportunity(this.oppId);
	}


	public String getNextAction() {
		return nextAction;
	}
				 
	public void setNextAction(String nextAction) { this.nextAction = nextAction; }

	public String getImgUrl() {
		String imgDocId = '';

		try {
			Document imgDoc = [Select Id from Document d where d.DeveloperName = 'ZuoraTabImage' limit 1];
			imgDocId = imgDoc.Id;
		}
		catch(Exception e) {}
		
		return System.URL.getSalesforceBaseUrl().toExternalForm().replace('https','http')+'/servlet/servlet.ImageServer?id='+imgDocId+'&oid='+UserInfo.getOrganizationId();
	}

	public Boolean submitOpportunityForApproval() {
		Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
		app.setObjectId(this.oppId);
		system.debug('55555555' + app);
		Approval.ProcessResult result = Approval.process(app);
		system.debug('55555555...' + result.isSuccess());
		return result.isSuccess();
	}

	// NOTE: the "go back" URLs are hardcoded in, so if the steps in the Quote workflows ever change these will need to be updated
	public PageReference goNavigateBack() {
			
		PageReference pageRef;

		// return the regular "back" page
		if (ApexPages.currentPage().getParameters().get('quoteType') == 'Cancellation') {

			// if Cancellation, first query and delete the previously created Quote record
			String oldQuoteIdString = ApexPages.currentPage().getParameters().get('Id');
			zqu__Quote__c oldQuote = [SELECT Id FROM zqu__Quote__c WHERE Id = :oldQuoteIdString LIMIT 1];
			if (oldQuote != null) {
				delete oldQuote;
			}

			Map<String, String> customUrlParameters = new Map<String, String>{'billingAccountId' => this.theQuote.zqu__ZuoraAccountID__c, 'oppId' => (String)this.oppId, 'quoteType' => 'Cancellation', 'retUrl' => '%2F'+(String)this.oppId, 'stepNumber' => '2', 'subscriptionId' => this.theQuote.zqu__ExistSubscriptionID__c};
			pageRef = zqu.QuoteWizardManager.navigateBack(customUrlParameters);
		}
		// return to the Edit Line Items page
		else {
			pageRef = new PageReference('/apex/ZuoraQuoteEditLineItems?id='+(String)this.quoteId+'&quoteType=Subscription&stepNumber=4');
		}

		return pageRef;
	}


	public PageReference goNavigateNext() {
		zqu.zQuoteUtil.ZBillingResult result = zqu.QuoteRecalculateController.JR_recalculate(this.quoteId);

		if(result.success==TRUE){
			decimal deltaMrr=0,deltaTcv =0, mrr=0, tcv=0;
			if(result.chargeMetrics!=null){
				for(zqu.zQuoteUtil.ChargeMetrics deltaResults : result.chargeMetrics){
					System.debug('deltaResults : ' +deltaResults);
					if(deltaResults.deltaMrr!=null){
						deltaMrr += deltaResults.deltaMrr;
					}
					if(deltaResults.deltaTcv!=null){
						deltaTcv += deltaResults.deltaTcv;
					}
				}
			}

			//quote.Quote_Preview__c=FALSE;
			theQuote.zqu__Is_Charge_Expired__c=FALSE;
			if(result.totalMrr!=null){
				theQuote.zqu__Previewed_MRR__c=result.totalMrr;
			}
			if(result.totalTcv!=null){
				theQuote.zqu__Previewed_TCV__c=result.totalTcv;
			}
			if(result.totalInfo!=null){
				theQuote.zqu__Previewed_Tax__c=result.totalInfo.tax;
				theQuote.zqu__Previewed_SubTotal__c=result.totalInfo.subTotal;
				theQuote.zqu__Previewed_Total__c=result.totalInfo.total;
				theQuote.zqu__Previewed_Discount__c=result.totalInfo.discount;
			}
			theQuote.zqu__Previewed_Delta_MRR__c=deltaMrr;
			theQuote.zqu__Previewed_Delta_TCV__c=deltaTcv;
		}
		else
		{
			throw new ApplicationException(result.message);
		}

		PageReference pageRef;

		if (this.nextAction == 'Enter an Additional Quote') {
			pageRef = new PageReference('/apex/zqu__QuoteOption?scontrolCaching=1&id=' + (String)this.oppId);
		}
		else if (this.nextAction == 'Submit for Internal Approvals') {
			// submit Opportunity for approval
			Boolean successfullySubmittedForApproval = submitOpportunityForApproval();
			if (successfullySubmittedForApproval == false) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'A failure occurred when trying to submit the Opportunity for approval; please try again or notify a system admin.'));
			}
			else {
				pageRef = new PageReference('/' + (String)this.oppId);
			}
		}
		// default action is to return to the Quote record detail page
		else {
			pageRef = new PageReference('/' + (String)this.quoteId);
		}

		// update the Potential Value of the parent Opportunity
		ZuoraQuoteTriggerHandler.UpdatePotentialValueOfOpportunity(this.oppId);

		return pageRef;
	}
		
		
	public static void RecalculateQuoteChargesForOpportunities(List<string> oppIds)
	{
		List<zqu__Quote__c> quotesList = 
									 [Select Id, Total_Contract_Discount__c
										From zqu__Quote__c
										where zqu__Opportunity__c in :oppIds];
										
										
		List<zqu__Quote__c> quotesToUpdate = new List<zqu__Quote__c>();
		
		for (zqu__Quote__c q : quotesList)
		{
			quotesToUpdate.add(RecalculateQuoteCharges(q));
		}
		
		System.Debug('Updating ' + quotesToUpdate.size() + ' quotes');
		update quotesToUpdate;
			
	}
		
		
	// recalculates the payment period, tcv, and other financial information on the quote rate plan charge for a given quote  
	// quote must have the field Total_Contract_Discount__c or there will be a run-time error
	public static zqu__Quote__c RecalculateQuoteCharges(zqu__Quote__c q)
	{
		q.Total_Contract_Discount__c = 0;
		
		List<zqu__QuoteRatePlanCharge__c> zQuoteRatePlanCharges = [Select Id,  Name, zqu__QuoteRatePlan__c, zqu__QuoteRatePlan__r.zqu__Quote__c, 
																																		Period_equals_Preferred_Payment_Schedule__c, OpportunityId__c, Preferred_Payment_Schedule__c, 
																																		zqu__Period__c, zqu__Discount__c, DiscountPrice__c, Discount_Amount__c, zqu__EffectivePrice__c, 
																																		zqu__ListPrice__c, List_Price__c, zqu__ListPriceBase__c, zqu__TriggerDate__c, zqu__TriggerEvent__c,
																																		Print_Issue__c, Print_Issue__r.Step_2__c, Print_Issue__r.Previous_Issue__c, Quote_Start_Date__c, 
																																		Product_Type__c, LDE_Email_Launch_Date__c, zqu__MRR__c, zqu__ChargeType__c, zqu__Total__c, 
																																		Discount_Override__c, zqu__QuoteRatePlan__r.zqu__ProductRatePlan__c, zqu__TCV__c,
																																		zqu__ProductRatePlanCharge__r.zqu__Upto_How_Many_Periods__c, zqu__ProductRatePlanCharge__r.zqu__RecurringPeriod__c, 
																																		Number_of_Charges__c, Total_Contract_Discount__c,
																																		zqu__QuoteRatePlan__r.zqu__Quote__r.zqu__InitialTerm__c, Quote_Id__c, zqu__QuoteRatePlan__r.Name,
																																		zqu__QuoteRatePlan__r.zqu__ProductRatePlan__r.zqu__Product__c, zqu__QuoteRatePlan__r.zqu__Quote__r.zqu__TermStartDate__c,
																																		zqu__ProductRatePlanCharge__r.zqu__EndDateCondition__c, zqu__ProductRatePlanCharge__r.zqu__UpToPeriodsType__c,
																																		zqu__ProductRatePlanCharge__r.zqu__ListPrice__c
																																		
																															 from zqu__QuoteRatePlanCharge__c 
																															 where zqu__QuoteRatePlan__r.zqu__Quote__c = :q.Id 
																																		and zqu__QuoteRatePlan__r.zqu__Quote__r.zqu__Status__c != 'Sent to Z-Billing'
																															 order by OpportunityId__c,
																																	 Print_Issue__r.Step_2__c asc,
																																	 Name asc];


		Map<String, decimal> NumberOfMonthsInPayPeriod = new Map<string, decimal>();
		NumberOfMonthsInPayPeriod.put('Month', 1);
		NumberOfMonthsInPayPeriod.put('Quarter', 3);
		NumberOfMonthsInPayPeriod.put('Semi-Annual', 6);
		NumberOfMonthsInPayPeriod.put('Annual', 12);

		Map<String, decimal> NumberOfPaymentsInYearForPayPeriod = new Map<string, decimal>();
		for (String key : NumberOfMonthsInPayPeriod.KeySet())
		{
			NumberOfPaymentsInYearForPayPeriod.put(key, 12/NumberOfMonthsInPayPeriod.get(key));
		}


		if (zQuoteRatePlanCharges.size() > 0)
		{
			// there are two different payment types - recurring and one-time
			// each gets its own special handling
			Date mostRecentTriggerDate = null;
			
			Map<String, Date> MostRecentPrintTriggerDateMap = new Map<String, Date>();
				
			for (zqu__QuoteRatePlanCharge__c qrpc : zQuoteRatePlanCharges)
			{
				// print is special because we stagger the payments of consecutive print issues
				// if it turns out that the pay period is 12 months, we don't need to do anything at all, since that means they want to pay everything up front
				// print is special because we stagger the payments of consecutive print issues
				// if it turns out that the pay period is 12 months, we don't need to do anything at all, since that means they want to pay everything up front
				if (qrpc.Product_Type__c == 'Print' && NumberOfPaymentsInYearForPayPeriod.get(qrpc.Preferred_Payment_Schedule__c) > 1)
				{
					// we want to find print issues in succession, and charge them accordingly.  Therefore, if you've chosen two back-to-back issues, we want to have the first issue start payments immediately and the second to start 6 months after
					// The important distinction is that it's not JUST consecutive print issues - it's the combination of print issue plus product
					// For example, if you buy 1/2 page and full page ads for issue #1 and issue #2:
					//    The customer should be charged for the 1/2 page and full page ads for issue #1 for the first six months
					//    The customer should be charged for the 1/2 page and full page ads for issue #2 for the last six months
					
					// start by making a key out the current product/selected print issue
					String currentPrintKey = String.ValueOf(qrpc.zqu__QuoteRatePlan__r.zqu__ProductRatePlan__r.zqu__Product__c).Left(15) + '|' + String.ValueOf(qrpc.Print_Issue__c).Left(15);
					System.Debug('current print key: ' + currentPrintKey);
						
					// next, identify the key for the previous print issue
					String previousPrintKey = null;
					if (qrpc.Print_Issue__r.Previous_Issue__c != null)
					{
						previousPrintKey = String.ValueOf(qrpc.zqu__QuoteRatePlan__r.zqu__ProductRatePlan__r.zqu__Product__c).Left(15) + '|' + String.ValueOf(qrpc.Print_Issue__r.Previous_Issue__c).Left(15);
					}
						
					// determine what the trigger date should be for the print issue
					// if the previous print issue has not been set, assume we start charging immediately.
					// if the previous print issue was set, assume we start charging six months from the first charge
					
					if (previousPrintKey != null && MostRecentPrintTriggerDateMap.ContainsKey(previousPrintKey))
					{
						//mostRecentTriggerDate = MostRecentPrintTriggerDateMap.get(currentPrintKey);
						mostRecentTriggerDate = MostRecentPrintTriggerDateMap.get(previousPrintKey);
						System.Debug('The trigger date for the previous print/product combo of : ' + previousPrintKey + ' is ' + mostRecentTriggerDate);
						mostRecentTriggerDate = mostRecentTriggerDate.addMonths(6);
					}
					else
					{
						// the first print issue triggers on the Service Activation Date (AKA Term Start Date)
						mostRecentTriggerDate = qrpc.zqu__QuoteRatePlan__r.zqu__Quote__r.zqu__TermStartDate__c;
						System.Debug('A previous issue was found, setting default trigger date to ' + mostRecentTriggerDate);
					}
					
					System.Debug('Storing a new print issue date for: ' + currentPrintKey + ' of ' + mostRecentTriggerDate);
					MostRecentPrintTriggerDateMap.put(currentPrintKey, mostRecentTriggerDate);

					// assign the date to the product
					qrpc.zqu__TriggerDate__c = mostRecentTriggerDate;
					qrpc.zqu__TriggerEvent__c = 'SpecificDate';
				}
				else if (qrpc.Product_Type__c == 'Direct Mail')
				{
					System.Debug('Entering direct mail');
					// LDE is also special because it needs two different trigger dates
					// the first payment needs to be immediate, the second needs to be in the future
					System.Debug('Quote rate plan charge name: ' + qrpc.Name);
					if (qrpc.Name.Contains('Balance Due')) // as in "80% Balance Due"
					{
						System.Debug('Found balance due charge');
						// second charge
						// set the date to 1 week prior to email blast
						// unless they picked Annual, which means they want to pay all up front
						if (qrpc.Preferred_Payment_Schedule__c != 'Annual')
						{
							// CSP-2332 - Adjust Trigger Date to be 30 days rather than 7 days
							qrpc.zqu__TriggerDate__c = qrpc.LDE_Email_Launch_Date__c.addDays(-30);
							qrpc.zqu__TriggerEvent__c = 'SpecificDate';
						}
					}
					// first charge (or any other charge that we did not plan for)
					// no need to do anything, it will charge automatically according to the definition of the charge
				}
					
				// for all recurring charges, determine the payments based on the preferred payment method
				if (qrpc.zqu__ChargeType__c == 'Recurring')
				{
					// standard periodic charge adjustment
					// calculate what the rate would be manually
					
					String payPeriod = qrpc.Preferred_Payment_Schedule__c;
					// make sure that the list price matches the product definition, or refreshing the page will double the value
					
					qrpc.List_Price__c = String.Valueof(qrpc.zqu__ProductRatePlanCharge__r.zqu__ListPrice__c);
					
					decimal numberOfMonthsInPeriod = NumberOfMonthsInPayPeriod.get(payPeriod);
					decimal annualCharge = qrpc.List_Price__c == null ? 0 : decimal.ValueOf(qrpc.List_Price__c) * NumberOfPaymentsInYearForPayPeriod.get(qrpc.zqu__ProductRatePlanCharge__r.zqu__RecurringPeriod__c);
					decimal periodCharge = annualCharge / NumberOfPaymentsInYearForPayPeriod.get(payPeriod);


					// if the pay period is larger than the requested payment schedule, keep trying a smaller pay period until one fits
					if (qrpc.zqu__ProductRatePlanCharge__r.zqu__Upto_How_Many_Periods__c != null && qrpc.zqu__ProductRatePlanCharge__r.zqu__Upto_How_Many_Periods__c > 0)
					{
						while (NumberOfMonthsInPayPeriod.get(payPeriod) > qrpc.zqu__ProductRatePlanCharge__r.zqu__Upto_How_Many_Periods__c)
						{
							System.Debug('switching pay period from ' + payPeriod);
							
							if (payPeriod == 'Annual')
							{
								payPeriod = 'Semi-Annual';
							}
							else if (payPeriod == 'Semi-Annual')
							{
								payPeriod = 'Quarter';
							}
							else if (payPeriod == 'Quarter')
							{
								payPeriod = 'Month';
							}
							else
							{
								// we want an error thrown if there is anything smaller than a month
								payPeriod = null;
							}
							System.Debug('switching pay period to ' + payPeriod);
							
							numberOfMonthsInPeriod = NumberOfMonthsInPayPeriod.get(payPeriod);
							periodCharge = annualCharge / NumberOfPaymentsInYearForPayPeriod.get(payPeriod);
						}
					}
							
					qrpc.zqu__Period__c = payPeriod;
					decimal discountPercent = (qrpc.zqu__Discount__c / 100);
					qrpc.zqu__MRR__c = (annualCharge * (1 - discountPercent)) / 12;
					qrpc.zqu__ListPrice__c = periodCharge;
					qrpc.List_Price__c = String.ValueOf(periodCharge);
					qrpc.zqu__Total__c = (periodCharge * (1 - discountPercent));
					qrpc.zqu__EffectivePrice__c = qrpc.zqu__Total__c;
							
					// calculate the tcv
					if (qrpc.zqu__ProductRatePlanCharge__r.zqu__Upto_How_Many_Periods__c != null && qrpc.zqu__ProductRatePlanCharge__r.zqu__Upto_How_Many_Periods__c > 0)
					{
						qrpc.Number_of_Charges__c = qrpc.zqu__ProductRatePlanCharge__r.zqu__Upto_How_Many_Periods__c / NumberOfMonthsInPayPeriod.get(payPeriod);
						qrpc.zqu__Upto_How_Many_Periods__c = qrpc.Number_of_Charges__c;
						qrpc.zqu__EndDateCondition__c = qrpc.zqu__ProductRatePlanCharge__r.zqu__EndDateCondition__c;
						try
						{
							qrpc.zqu__Upto_How_Many_Periods_Type__c = qrpc.zqu__ProductRatePlanCharge__r.zqu__UpToPeriodsType__c.Replace('_',' ');
						}
						catch (Exception e)
						{
						}
						
						if (qrpc.zqu__EndDateCondition__c == '' || qrpc.zqu__EndDateCondition__c == null)
						{
							qrpc.zqu__EndDateCondition__c = 'Fixed Period';
						}
						
						if (qrpc.zqu__Upto_How_Many_Periods_Type__c == '' || qrpc.zqu__Upto_How_Many_Periods_Type__c == null)
						{
							qrpc.zqu__Upto_How_Many_Periods_Type__c = 'Billing Periods';
						}
					}
					else
					{
						qrpc.Number_of_Charges__c = qrpc.zqu__QuoteRatePlan__r.zqu__Quote__r.zqu__InitialTerm__c / NumberOfMonthsInPayPeriod.get(payPeriod);
					}
				}

				else
				{
						// one-time charges
					qrpc.Number_of_Charges__c = 1;
				}
					
				
				// calculate the TCV for the discounts for this item
				qrpc.Total_Contract_Discount__c = qrpc.Discount_Amount__c * qrpc.Number_of_Charges__c;
				
				// add the discount to the quote
				System.Debug('Quote discount total before charge: ' + q.Total_Contract_Discount__c);
				System.Debug('Charge discount total: ' + qrpc.Total_Contract_Discount__c);
				System.Debug('Number of Charges: ' + qrpc.Number_of_Charges__c);
				q.Total_Contract_Discount__c += qrpc.Total_Contract_Discount__c;
			}
			
			update zQuoteRatePlanCharges;
		}  
		return q;
	}


	public static List<zqu__Quote__c> updateQM1(List<ID> quoteIDs){
		List<ID> updatedQuoteIds = new List<ID>();
		List<zqu__Quote__c> quotesForUpdate = new List<zqu__Quote__c>();
		List<zqu.zQuoteUtil.ZBillingResult> matrixResults = new List<zqu.zQuoteUtil.ZBillingResult>();
		if(!Test.isRunningTest()){
			matrixResults =zqu.zQuoteUtil.previewQuotes(quoteIDs);
			System.debug('matrixResults : ' +matrixResults);
		}
		else{
			// add quoteMatrix results to first quote
			zqu.zQuoteUtil.ZBillingResult result = new zqu.zQuoteUtil.ZBillingResult();
			result.success=TRUE;
			result.sfdcQuoteId=quoteIDs.get(0);
			result.totalTcv=100;
			result.totalMrr=200;
			List <zqu.zQuoteUtil.ChargeMetrics> chM = new List <zqu.zQuoteUtil.ChargeMetrics>();
			zqu.zQuoteUtil.TotalInfo totalInfo = new zqu.zQuoteUtil.TotalInfo();
			totalInfo.tax=100;
			totalInfo.subTotal=1;   
			totalInfo.total=300;
			totalInfo.discount=0;
			result.totalInfo=(totalInfo);
			result.chargeMetrics=chM;
			matrixResults.add(result);
			 
			if(quoteIDs.size()>1){
				// add quoteMatrix results to second quote
				zqu.zQuoteUtil.ZBillingResult result2 = new zqu.zQuoteUtil.ZBillingResult();
				result2.success=FALSE;
				result2.sfdcQuoteId=quoteIDs.get(1);
				matrixResults.add(result2);
			}
			System.debug('matrixResults special : ' +matrixResults);
		}
			
		for(zqu.zQuoteUtil.ZBillingResult result :matrixResults){
			zqu__Quote__c quote = [SELECT id,zqu__Is_Charge_Expired__c,zqu__Previewed_MRR__c,zqu__Previewed_TCV__c,zqu__Previewed_Tax__c,
																	zqu__Previewed_SubTotal__c,zqu__Previewed_Total__c,zqu__Previewed_Discount__c,zqu__Previewed_Delta_MRR__c,
																	zqu__Previewed_Delta_TCV__c 
														FROM zqu__Quote__c WHERE Id =:result.sfdcQuoteId LIMIT 1];
			if(result.success==TRUE){
				decimal deltaMrr=0,deltaTcv =0, mrr=0, tcv=0;
				if(result.chargeMetrics!=null){
					for(zqu.zQuoteUtil.ChargeMetrics deltaResults : result.chargeMetrics){
						System.debug('deltaResults : ' +deltaResults);
						if(deltaResults.deltaMrr!=null){
							deltaMrr += deltaResults.deltaMrr;
						}
						if(deltaResults.deltaTcv!=null){
							deltaTcv += deltaResults.deltaTcv;
						}
					}
				}
				//quote.Quote_Preview__c=FALSE;
				quote.zqu__Is_Charge_Expired__c=FALSE;
				if(result.totalMrr!=null){
					quote.zqu__Previewed_MRR__c=result.totalMrr;
				}
				if(result.totalTcv!=null){
					quote.zqu__Previewed_TCV__c=result.totalTcv;
				}
				if(result.totalInfo!=null){
					quote.zqu__Previewed_Tax__c=result.totalInfo.tax;
					quote.zqu__Previewed_SubTotal__c=result.totalInfo.subTotal;
					quote.zqu__Previewed_Total__c=result.totalInfo.total;
					quote.zqu__Previewed_Discount__c=result.totalInfo.discount;
				}
				quote.zqu__Previewed_Delta_MRR__c=deltaMrr;
				quote.zqu__Previewed_Delta_TCV__c=deltaTcv;
				quotesForUpdate.add(quote);
			}
		}
		return quotesForUpdate;
	}

	/**
	 *   CSP-868 | sets the value for the ServiceRunDatesTemplateMergeField__c on child QuoteRatePlanCharge 
	 *   records for use in the Zuora Quote Template
	 *
	 *   @author Jonathan Satterfield
	 *   @date   2016-05-25
	 *   @param  {zqu__Quote__c}   quoteRecord
	 */
	private void setServiceRunDatesTemplateMergeFieldOnCharges(zqu__Quote__c quoteRecord) {
		List<zqu__QuoteRatePlanCharge__c> qrpcList = [SELECT Id, Product_Type__c, ServiceRunDatesTemplateMergeField__c, LDE_Email_Launch_Date__c, Print_Issue__r.Publish_1st_Cover_Ship__c,
																									 zqu__TriggerDate__c, zqu__TriggerEvent__c, zqu__SpecificEndDate__c, Discount_Reason__c
																								   FROM zqu__QuoteRatePlanCharge__c 
																								   WHERE zqu__QuoteRatePlan__r.zqu__Quote__c = :quoteRecord.Id];
		if (!qrpcList.isEmpty()) {
			for (Integer i = 0; i < qrpcList.size(); i++) {
				zqu__QuoteRatePlanCharge__c qrpcRec = qrpcList[i];
				if (qrpcRec.Product_Type__c.containsIgnoreCase('print')) {
					qrpcRec.ServiceRunDatesTemplateMergeField__c = qrpcRec.Print_Issue__r.Publish_1st_Cover_Ship__c.format();
				}
				else if (qrpcRec.Product_Type__c.containsIgnoreCase('direct mail')) {
					qrpcRec.ServiceRunDatesTemplateMergeField__c = qrpcRec.LDE_Email_Launch_Date__c.format();
				}
				// use the subscription date range as the default for non-print / direct mail subscriptions (CSP-1162)
				// resource: https://knowledgecenter.zuora.com/CA_Commerce/C_Zuora_Quotes/M_Working_with_Quotes/F_Quote_Metrics
				else {
					if (quoteRecord.zqu__SubscriptionType__c == 'New Subscription') {
						//CSP-2898 Enable Discounts for a Promotional Period (Switch Pitch)
						//update preview.pdf SERVICE RUN DATES for Promotional
						if(qrpcRec.Discount_Reason__c == 'Wedding Wire Switch Pitch' && 
							(qrpcRec.zqu__TriggerDate__c != null || qrpcRec.zqu__SpecificEndDate__c != null)) {
							//for 9 month not free
							if(qrpcRec.zqu__TriggerDate__c != null) {
								qrpcRec.ServiceRunDatesTemplateMergeField__c = qrpcRec.zqu__TriggerDate__c.format() + ' - ' + quoteRecord.zqu__TermStartDate__c.addMonths((Integer)quoteRecord.zqu__InitialTerm__c).format();
							}
							//for 3 month free 
							else if(qrpcRec.zqu__SpecificEndDate__c != null) {
								qrpcRec.ServiceRunDatesTemplateMergeField__c = quoteRecord.zqu__TermStartDate__c.format() + ' - ' + qrpcRec.zqu__SpecificEndDate__c.format();
							}
						}
						//for normal service run date 
						else {
							qrpcRec.ServiceRunDatesTemplateMergeField__c = quoteRecord.zqu__TermStartDate__c.format() + ' - ' + quoteRecord.zqu__TermStartDate__c.addMonths((Integer)quoteRecord.zqu__InitialTerm__c).format();
						}

					}
					else if (quoteRecord.zqu__SubscriptionType__c == 'Amend Subscription') {
						qrpcRec.ServiceRunDatesTemplateMergeField__c = quoteRecord.zqu__TermStartDate__c.format() + ' - ' + quoteRecord.zqu__SubscriptionTermEndDate__c.format();
					}
					// quoteRecord.zqu__SubscriptionType__c == 'Renew Subscription'
					else {
						qrpcRec.ServiceRunDatesTemplateMergeField__c = quoteRecord.zqu__TermStartDate__c.format() + ' - ' + quoteRecord.zqu__TermStartDate__c.addMonths((Integer)quoteRecord.zqu__RenewalTerm__c).format();
					}
				}
			}
			update qrpcList;
		}
	}
}