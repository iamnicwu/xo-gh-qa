public without sharing class ZuoraQuoteCreateCancellationController {

	public Opportunity theOpp {get;set;}
	public zqu__Quote__c theQuote {get;set;}
	public Zuora__CustomerAccount__c theCustomerAccount {get;set;}
	public Zuora__Subscription__c theSubscription {get;set;}
	public String oppLink {get;set;}
	public String accountLink {get;set;}
	public Date endOfLastInvoicePeriod {get;set;}
	public String cancellationEffectiveDate {get;set;}
	public List<SelectOption> cancellationEffectiveDateOptions {get;set;}
	// for ticket CSP-2514, the boolean param used for determine the user can check the Generate Invoice flag for cancel quote
	public Boolean isGenerateInvoice {get;set;}
	// constructor doesn't do anything because we need to perform a DML statement upon page load
	// therefore, all "initilization" code takes place below in the initializeQuote method
	public ZuoraQuoteCreateCancellationController(ApexPages.StandardController standardController) {
	}	


	public void initializeQuote() {
		// for ticket CSP-2514, only the special user can check the Generate Invoice flag for cancel quote
		Set<Id> generateCancelInvoiceUserIdSet = new Set<Id>();
		Group generateInvoiceGroup = [SELECT Id, Name, Type, (SELECT Id, UserOrGroupId FROM GroupMembers) FROM Group WHERE Name = 'GenerateCancelInvoiceUser'];
		for (GroupMember currntGM : generateInvoiceGroup.GroupMembers) {
			generateCancelInvoiceUserIdSet.add(currntGM.UserOrGroupId);
		}
		if (generateCancelInvoiceUserIdSet.contains(UserInfo.getUserId())) {
	    isGenerateInvoice = true;
		}else{
			isGenerateInvoice = false;
		}

		Id oppId = (Id)ApexPages.currentPage().getParameters().get('oppId');
		this.theOpp = [SELECT Id, Name, AccountId, Account.Name FROM Opportunity WHERE Id = :oppId LIMIT 1];

		String billingAccountId = ApexPages.currentPage().getParameters().get('billingAccountId');
		this.theCustomerAccount = [SELECT Id, Zuora__Account__c, Zuora__Zuora_Id__c, Zuora__BillCycleDay__c, Zuora__BillToName__c, Zuora__SoldToName__c FROM Zuora__CustomerAccount__c WHERE Zuora__Zuora_Id__c = :billingAccountId LIMIT 1];

		String subscriptionId = ApexPages.currentPage().getParameters().get('subscriptionId');
		this.theSubscription = [SELECT Id, Zuora__TermEndDate__c, Zuora__Version__c FROM Zuora__Subscription__c WHERE Zuora__Zuora_Id__c = :subscriptionId];

		this.endOfLastInvoicePeriod = returnEndOfLastInvoicePeriod(this.theCustomerAccount);

		this.cancellationEffectiveDateOptions = new List<SelectOption>();
		this.cancellationEffectiveDateOptions.add(new SelectOption('Enter a Date','Enter a Date'));
		this.cancellationEffectiveDateOptions.add(new SelectOption('End of Current Term','End of Current Term -- ' + this.theSubscription.Zuora__TermEndDate__c.format()));
		this.cancellationEffectiveDateOptions.add(new SelectOption('End of Last Invoice Period','End of Last Invoice Period -- ' + this.endOfLastInvoicePeriod.format()));

		this.oppLink = '<a href="' + System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + (String)this.theOpp.Id + '">' + this.theOpp.Name + '</a>';
		this.accountLink = '<a href="' + System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + (String)this.theOpp.AccountId + '">' + this.theOpp.Account.Name + '</a>';

		this.theQuote = new zqu__Quote__c();
		this.theQuote.Name = 'Quote for ' + theOpp.Name;
		this.theQuote.zqu__Opportunity__c = theOpp.Id;
		this.theQuote.zqu__Account__c = theOpp.AccountId;
		this.theQuote.zqu__ValidUntil__c = Date.today();
		this.theQuote.zqu__StartDate__c = Date.today();
		this.theQuote.zqu__CancellationDate__c = Date.today();
		this.theQuote.zqu__CancellationEffectiveDate__c = 'Enter a Date';
		this.theQuote.zqu__ExistSubscriptionID__c = ApexPages.currentPage().getParameters().get('subscriptionId');
		this.theQuote.zqu__SubscriptionType__c = 'Cancel Subscription';
		this.theQuote.RecordTypeId = Schema.SObjectType.zqu__Quote__c.RecordTypeInfosByName.get('Cancellation').RecordTypeId;
		this.theQuote.zqu__ZuoraAccountID__c = ApexPages.currentPage().getParameters().get('billingAccountId');
		this.theQuote.zqu__Currency__c = 'USD';
		this.theQuote.zqu__Amendment_Name__c = this.theQuote.Name;
		this.theQuote.zqu__SubscriptionVersion__c = this.theSubscription.Zuora__Version__c;
		// (SF-2036) this boolean needs to be set in order to run the zqu.zQuoteUtil.previewQuotes method on the ChooseNextAction page
		this.theQuote.zqu__Is_Charge_Expired__c = True;

		// these two values I hardcoded in, but not 100% sure they couldn't change
		this.theQuote.zqu__Calculate_Quote_Metrics_Through__c = 'EOT';
		this.theQuote.zqu__InvoiceProcessingOption__c = 'Subscription';

		insert this.theQuote;
	}


	public Date returnEndOfLastInvoicePeriod(Zuora__CustomerAccount__c customerAccount) {

		Date endOfLastInvoicePeriod;

		String bcdFirstThreeChars = customerAccount.Zuora__BillCycleDay__c.left(3);
		String bcdFirstTwoChars = customerAccount.Zuora__BillCycleDay__c.left(2);
		String bcdFirstChar = customerAccount.Zuora__BillCycleDay__c.left(1);

		// end of month
		if (bcdFirstThreeChars == 'EOM') {
			// current month
			if (Date.today().day() < Date.daysInMonth(Date.today().year(), Date.today().month())) {
				endOfLastInvoicePeriod = Date.newInstance(Date.today().year(), Date.today().month(), Date.daysInMonth(Date.today().year(), Date.today().month()));
			}
			// next month
			else {
				// if the month is December...
				if (Date.today().month() == 12) {
					endOfLastInvoicePeriod = Date.newInstance(Date.today().year() + 1, 1, Date.daysInMonth(Date.today().year() + 1, 1));
				}
				// and if the month is not December...
				else {
					endOfLastInvoicePeriod = Date.newInstance(Date.today().year(), Date.today().month() + 1, Date.daysInMonth(Date.today().year(), Date.today().month() + 1));
				}
			}
		}
		// any other day
		else {
			// first find if day is double digits, e.g. the 10th, the 22nd, etc., or single digits
			Integer billingDay;
			
			if (bcdFirstTwoChars.right(1) == '0' || bcdFirstTwoChars.right(1) == '1' || 
				bcdFirstTwoChars.right(1) == '2' || bcdFirstTwoChars.right(1) == '3' || 
				bcdFirstTwoChars.right(1) == '4' || bcdFirstTwoChars.right(1) == '5' || 
				bcdFirstTwoChars.right(1) == '6' || bcdFirstTwoChars.right(1) == '7' || 
				bcdFirstTwoChars.right(1) == '8' || bcdFirstTwoChars.right(1) == '9') {

				billingDay = Integer.valueOf(bcdFirstTwoChars);
			}
			else {
				billingDay = Integer.valueOf(bcdFirstChar);
			}
			// current month
			if (Date.today().day() < billingDay) {
				endOfLastInvoicePeriod = Date.newInstance(Date.today().year(), Date.today().month(), billingDay);
			}
			// next month
			else {
				// if the month is December...
				if (Date.today().month() == 12) {
					endOfLastInvoicePeriod = Date.newInstance(Date.today().year() + 1, 1, billingDay);
				}
				// and if the month is not December...
				else {
					endOfLastInvoicePeriod = Date.newInstance(Date.today().year(), Date.today().month() + 1, billingDay);
				}
			}
		}

		return endOfLastInvoicePeriod;
	}


	public void updateCancellationEffectiveDate() {

		if (cancellationEffectiveDate == 'Enter a Date') {
			this.theQuote.zqu__CancellationDate__c = Date.today();
		}
		else if (cancellationEffectiveDate == 'End of Current Term') {
			this.theQuote.zqu__CancellationDate__c = this.theSubscription.Zuora__TermEndDate__c;
		}
		// a.k.a. End of Last Invoice Period
		else {
			this.theQuote.zqu__CancellationDate__c = this.endOfLastInvoicePeriod;
		}
	}


	// TODO: add try-catch blocks in this method
	public void createCancellationAmendment(Id quoteId) {
		zqu.zQuoteUtil.createCancellationAmendment(quoteId);
	}


	public String getImgUrl() {
		String imgDocId = '';

		try {
			Document imgDoc = [Select Id from Document d where d.DeveloperName = 'ZuoraTabImage' limit 1];
			imgDocId = imgDoc.Id;
		}
		catch(Exception e) {}
		
		return System.URL.getSalesforceBaseUrl().toExternalForm().replace('https','http')+'/servlet/servlet.ImageServer?id='+imgDocId+'&oid='+UserInfo.getOrganizationId();
	}


	public PageReference goNavigateBack() {
		Map<String, String> customUrlParameters = new Map<String, String>{'oppId' => this.theOpp.Id};
		return zqu.QuoteWizardManager.navigateBack(customUrlParameters);
	}


	public PageReference goNavigateNext() {
		// CSP-506 | set Start Date to equal the Cancellation Date
		this.theQuote.zqu__StartDate__c = this.theQuote.zqu__CancellationDate__c;
		
		update this.theQuote;
		createCancellationAmendment(this.theQuote.Id);
		Map<String, String> customUrlParameters = new Map<String, String>{'Id' => this.theQuote.Id, 'oppId' => this.theOpp.Id, 'quoteType' => 'Cancellation'};
		return zqu.QuoteWizardManager.navigateNext(customUrlParameters);
	}

}