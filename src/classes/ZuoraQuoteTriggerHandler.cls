public without sharing class ZuoraQuoteTriggerHandler implements XOTrigger{
	// Cannot be deleted due to Opportunity trigger is using this flag
	public static Boolean validUntilDateUpdatedFromOpportunityTrigger = false;

	// used for storing the exist subscription zuora id and subscription
	private Map<String,Zuora__Subscription__c> subZuoraIdMap  = new Map<String,Zuora__Subscription__c>();

	// Used for storing quote template Name => Id map
	private Map<String,Id> quoteTempNameIdMap = new Map<String,Id>();

	// Used for storing the Opp Id and Opp CSP-1610
	private Map<Id, Opportunity> oppIdMap = new Map<Id, Opportunity>();

	// CSP-SF-598, SF-599, SF-601, storing the id map between userId and User Object
	private Map<Id,User> userIdAndUserMap = new Map<Id,User>();

	// storing the quote which need update the child QuoteRatePlanCharge
	private Map<Id,zqu__Quote__c> quoteIdMap = new Map<Id,zqu__Quote__c>();
	
	// CSP-1414 - Enforce First Name and Last Name on contacts added to Bill To/Sold To
	private Map<Id, Contact> contactMap = new Map<Id, Contact>();

	// quoteToSumEffectivePriceMap
	// CSP-1598 - Getting all quotes being processed which have a non null True TCV value. This set
	// will be used to aggregate all Effective Prices from related Quote Rate Plan Charge Detail child records.
	// NOTE: Not checking to see if True_TCV__c field value is different from the old value because there
	// could be a scenario where modifications were made to the quote but the TCV somehow came out to be
	// exactly the same but the term price changed. Should be VERY rare but still possible?
	private Map<Id, Double> quoteToSumEffectivePriceMap = new Map<Id, Double>();

	// the flag indicate the currnt user has access to set the AutoRenewal__c to YES for the quote whose zqu__InitialTerm__c<12 
	private Boolean haveAccessForUser = false;

	// SF-1597 Code for Local Opportunity Approval Process; updates expiration dates on child Inventory records
	private Map<Id,Date> quoteIDAndExpirationDateMap = new Map<Id,Date>();

	// the Id Set of Opps which need udpated when the child quote's electronic payment method is changed from empty
	private Map<Id,Opportunity> updateOppIDMap = new Map<Id,Opportunity>();


	// set the Map: the original Subscription Name ==> the renewal Quote, used for sending notification
	// For CSP-2341, added a new lookup field Subscription_Being_Renewed__c to associate autoRenewal quote to original subscription
	private Set<Id> subscriptionIdSet = new Set<Id>();
	private Set<Id> renewQuoteIdSet = new Set<Id>();
	private Set<Id> renewAccountIdSet = new Set<Id>();
	
	// we need to query for all Quote records belonging to the parent Opportunity record(s) SF-1336 
	private Set<Id> parentOppIdSet = new Set<Id>();


	//CSP-2880 Make Invoice Owner field available to certain users
	private user currentUserInfo; 


	/**
	 * Method used to bulkify all data needed in any "before" action of a trigger.
	 */
	public void bulkBefore() {
		// SF-602, SF-1957 When Quote records are created or updated, note who the Salesforce
		// User is so that it can be tracked in Zuora later on (SOX compliance reasons)
		// old method: PopulateOriginalSalesforceQuoteIDField
		Set<String> existSubIdSet = new Set<String>();
		Set<Id> oppIdSet = new Set<Id>();

		// Populate User Id Set with SalesRep, RenewalRep, and ReportingRep
		Set<Id> srUserIdSet = new Set<Id>();

		// CSP-1414 - Enforce First Name and Last Name on contacts added to Bill To/Sold To
		Set<String> contactIdSet = new Set<String>();
		
		Set<Id> effectPriceQuoteSet = new Set<Id>();

		// bulk before Update and before Insert Logic//////////////////////////
		if (trigger.isInsert || trigger.isUpdate) {
			for (Integer i = 0; i< trigger.new.size(); i++) {
				zqu__Quote__c currentQuote = (zqu__Quote__c)trigger.new[i];

				// CSP-1610 On non-Cancellation Quote record update always set zqu__ValidUntil__c to the parent Opportunity_Expiration_Date__c field value
				// When a creating a quote, set the electronic payment method based on the opportunity
				if (currentQuote.zqu__Opportunity__c != null) {
					oppIdSet.add(currentQuote.zqu__Opportunity__c);
				}

				if(currentQuote.zqu__SubscriptionType__c != 'New Subscription') {
					existSubIdSet.add(currentQuote.zqu__ExistSubscriptionID__c);
				}


				// SalesRep 
				if (currentQuote.SalesRepLookup__c != NULL) {
						srUserIdSet.add(currentQuote.SalesRepLookup__c);
				}

				// ReportingRep
				if(currentQuote.Reporting_Rep__c != NULL){
					srUserIdSet.add(currentQuote.Reporting_Rep__c);
				}

				// RenewalRep 
				if (currentQuote.RenewalRepLookup__c != NULL) {
					srUserIdSet.add(currentQuote.RenewalRepLookup__c);
				}


				// CSP-1414 - Enforce First Name and Last Name on contacts added to Bill To/Sold To
				if(String.isNotBlank(currentQuote.zqu__SoldToContact__c)) {
					contactIdSet.add(currentQuote.zqu__SoldToContact__c);
				}

				// CSP-1414 - Enforce First Name and Last Name on contacts added to Bill To/Sold To
				if(String.isNotBlank(currentQuote.zqu__BillToContact__c)) {
					contactIdSet.add(currentQuote.zqu__BillToContact__c);
				}
			}
		}
		

		// bulk before Update Logic//////////////////////////
		if (Trigger.isUpdate) {
			for (Integer i = 0; i < trigger.new.size(); i++) {
				zqu__Quote__c currentQuote = (zqu__Quote__c)trigger.new[i];
				zqu__Quote__c oldQuote = (zqu__Quote__c)trigger.oldMap.get(currentQuote.id);

				if(currentQuote.True_TCV__c != null && 
					String.isNotBlank(currentQuote.Product_Line__c) && 
					// ????
					('Direct Mail,Print').indexOf(currentQuote.Product_Line__c) < 0) {

					effectPriceQuoteSet.add(currentQuote.Id);
				}
			}
		}

		// bulk before Delete Logic//////////////////////////
		if (Trigger.isDelete) {
			for (Integer i = 0; i < trigger.old.size(); i++) {
				zqu__Quote__c oldQuote = (zqu__Quote__c)trigger.old[i];

				if (oldQuote.zqu__Opportunity__c != null) {
					oppIdSet.add(oldQuote.zqu__Opportunity__c);
				}
			}
		}


		if (!existSubIdSet.isEmpty()) {
			// CSP-2735 Zuora Amendments and Cancels fail
			// replace Zuora Id (Deprecated) Zuora__Zuora_Id__c to Zuora__External_Id__c, cause Zuora__Zuora_Id__c is deprecated and non index field
			for (Zuora__Subscription__c currentSubscription : [SELECT Id, Name, Zuora__Zuora_Id__c, OriginalSalesforceQuoteID__c, 
																															Zuora__TCV__c, Product_Line__c, Zuora__InvoiceOwner__r.Name, 
																															Zuora__InvoiceOwner__r.Zuora__Zuora_Id__c 
																												 FROM Zuora__Subscription__c 
																												 WHERE Zuora__External_Id__c IN : existSubIdSet]) {

				subZuoraIdMap.put(currentSubscription.Zuora__Zuora_Id__c, currentSubscription);
			}
		}
		
		// get quote template name => Id map for LDE 
		for (zqu__Quote_Template__c currentZQT : [SELECT zqu__Template_Id__c, Name FROM zqu__Quote_Template__c WHERE 
																							Name = 'LDE Quote Template']) {

			quoteTempNameIdMap.put(currentZQT.Name, currentZQT.Id);

		}

		// set the Map oppIdMap for CSP-1610
		if (!oppIdSet.isEmpty()) {
			for (Opportunity currentOpp : [SELECT Id, Opportunity_Expiration_Date__c,Electronic_Payment_Method_Id_ACH__c, Electronic_Payment_Method_Id_Credit__c,
																		StageName, IsClosed FROM Opportunity 
																		WHERE Id IN :oppIdSet]) {

				oppIdMap.put(currentOpp.id,currentOpp);
			}
		}

		// if Id Set has values, run User query and populate User List
		//CSP-2880 Make Invoice Owner field available to certain users 
		//Add current user for select 
		for (User currentUser : [SELECT Id, SalesRepID__c, ManagerId, Manager.SalesRepID__c, Disallow_Sales_Rep_On_Quotes__c, 
																 Profile.Name, UserRole.Name FROM User 
																 WHERE Id IN :srUserIdSet OR Id =: userInfo.getUserId()]) {

			if(srUserIdSet.contains(currentUser.Id)) {
				userIdAndUserMap.put(currentUser.Id, currentUser);
			}
			//CSP-2880 Make Invoice Owner field available to certain users 
			//Get cerrent user role and profile
			if(currentUser.id == userInfo.getUserId()) {
				currentUserInfo = currentUser;
			}
		}

		if (!contactIdSet.isEmpty()) {
			contactMap = new Map<Id, Contact>([SELECT Id, FirstName, LastName FROM Contact WHERE Id IN :contactIdSet]);
		}

		if (!effectPriceQuoteSet.isEmpty()) {
			List<zqu__QuoteRatePlanCharge__c> quoteRPCList = [SELECT Id, zqu__EffectivePrice__c, zqu__QuoteRatePlan__r.zqu__Quote__c FROM zqu__QuoteRatePlanCharge__c 
																												WHERE zqu__QuoteRatePlan__r.zqu__Quote__c IN: effectPriceQuoteSet];

			for(Integer i = 0, len = quoteRPCList.size(); i < len; i++) {
				zqu__QuoteRatePlanCharge__c quoteRPC = quoteRPCList[i];
				// If the effective price is null or zero then just skip this quote rate plan charge. No reason to
				// access the hash map to try and add a null value(error) or add nothing.
				if(quoteRPC.zqu__EffectivePrice__c == null || quoteRPC.zqu__EffectivePrice__c == 0) {
					continue;
				}

				// If a map value exists for the quote then just add to double value
				if(quoteToSumEffectivePriceMap.containsKey(quoteRPC.zqu__QuoteRatePlan__r.zqu__Quote__c)) {
					Double currentSum = quoteToSumEffectivePriceMap.get(quoteRPC.zqu__QuoteRatePlan__r.zqu__Quote__c);
					quoteToSumEffectivePriceMap.put(quoteRPC.zqu__QuoteRatePlan__r.zqu__Quote__c, currentSum + quoteRPC.zqu__EffectivePrice__c);
					continue;
				}

				// If no map value exists then create a new key and being the double with the current effective price
				quoteToSumEffectivePriceMap.put(quoteRPC.zqu__QuoteRatePlan__r.zqu__Quote__c, quoteRPC.zqu__EffectivePrice__c);
			}
		}


		// For CSP-2048, use a public group to store the user or role who have the access to check the autorenewal flag of the quote with initial term less than 12
		Set<id> accessIdSet = new Set<Id>();
		for (GroupMember currentGroupMember: [Select id,UserOrGroupId,GroupId from GroupMember where Group.DeveloperName = 'UserCanCheckAutoRenewalQuoteLess12']) {
				accessIdSet.add(currentGroupMember.UserOrGroupId);
		}

		for (Group currentGroup : [Select Id, RelatedId from Group where Id in: accessIdSet]) {
				accessIdSet.add(currentGroup.RelatedId);
		}
		if (accessIdSet.contains(userInfo.getUserId())) {
				haveAccessForUser = TRUE;
		}
		else if(accessIdSet.contains(userInfo.getUserRoleId())){
				haveAccessForUser = TRUE;
		}
		
	}

	/**
	 *   Method used to bulkify all data needed in any "after" action of a trigger.
	 */
	public void bulkAfter() {
	}


	/**
	 *   All before insert logic should be done here. This method is called iteratively and as such
	 *   should contain no actions which could potentially hit limits or is considered bad practice 
	 *   in the Salesforce environment.
	 *   
	 *   @param  {SObject}   so Single SObject representation of the object being acted upon.
	 */
	public void beforeInsert(SObject so) {
		zqu__Quote__c zquQuoteObj = (zqu__Quote__c)so;
		System.debug(LoggingLevel.INFO, '*** zquQuoteObj: ' + zquQuoteObj);
		// Set deault value for some fields
		// SF-2101 old method: SetServiceActivationDateToTermStartDate
		zquQuoteObj.zqu__Service_Activation_Date__c = zquQuoteObj.zqu__TermStartDate__c;
		// CSP-2423 - If this is a new Billing Account - set the Bill Cycle Day to the same as the Service Activation Day
		if(String.isBlank(zquQuoteObj.zqu__ZuoraAccountID__c) && zquQuoteObj.zqu__Service_Activation_Date__c != null) {
			zquQuoteObj.zqu__BillCycleDay__c = String.valueOf(zquQuoteObj.zqu__Service_Activation_Date__c.day());
		}
		// CSP-1786 - ALWAYS set Zuora auto renew flag to False. Using a custom flag moving forward.
		zquQuoteObj.zqu__AutoRenew__c = false;

		zquQuoteObj.zqu__QuoteTemplate__c = null;

		if (zquQuoteObj.zqu__SubscriptionType__c == 'New Subscription') {
			zquQuoteObj.OriginalSalesforceQuoteID__c = zquQuoteObj.Id;

			//CSP-2880 Make Invoice Owner field available to certain users
			//Add error when Invoice Owner has value, exception renewal subscription. 
			if(currentUserInfo.UserRole.Name != 'SOSS Managers' && currentUserInfo.UserRole.Name != 'SOSS' 
				&& currentUserInfo.Profile.Name != 'Local Core Finance - ARR' && currentUserInfo.Profile.Name != 'System Administrator'
				&& currentUserInfo.Profile.Name != 'Service Accounts' 
				&& String.isNotBlank(zquQuoteObj.zqu__InvoiceOwnerName__c)
				&& String.isBlank(zquQuoteObj.Subscription_Being_Renewed__c)) {

				//Add error when Invoice Owner has value 
				zquQuoteObj.addError(Label.Change_Invoice_Owner_Error);
			}

		}else{
			if (subZuoraIdMap.containsKey(zquQuoteObj.zqu__ExistSubscriptionID__c)) {
				Zuora__Subscription__c currentSubscription = subZuoraIdMap.get(zquQuoteObj.zqu__ExistSubscriptionID__c);

				if (zquQuoteObj.zqu__SubscriptionType__c == 'Amend Subscription') {
					zquQuoteObj.OriginalSalesforceQuoteID__c = currentSubscription.OriginalSalesforceQuoteID__c;

					//CSP-2880 Make Invoice Owner field available to certain users
					//Add error when Invoice Owner not equal original Subscription Invoice Owner
					if(currentUserInfo.UserRole.Name != 'SOSS Managers' && currentUserInfo.UserRole.Name != 'SOSS' 
						&& currentUserInfo.Profile.Name != 'Local Core Finance - ARR' && currentUserInfo.Profile.Name != 'System Administrator'
						&& currentUserInfo.Profile.Name != 'Service Accounts' 
						&& currentSubscription.Zuora__InvoiceOwner__r.Zuora__Zuora_Id__c != zquQuoteObj.zqu__InvoiceOwnerId__c) {

						zquQuoteObj.addError(Label.Change_Invoice_Owner_Error);
					}
				}
			}
		}
		if (String.isNotBlank(zquQuoteObj.Product_Line__c) && 
					(zquQuoteObj.Product_Line__c.containsIgnoreCase('Direct Mail') || zquQuoteObj.Product_Line__c.containsIgnoreCase('Print'))) {

			zquQuoteObj.zqu__QuoteTemplate__c = quoteTempNameIdMap.get('LDE Quote Template');
		}

		// CSP-1610 On non-Cancellation Quote record update always set zqu__Quote__c.zqu__ValidUntil__c to the parent Opportunity.Opportunity_Expiration_Date__c field value
		// old method: setValidUntilDateToOppExpirationDate
		if (zquQuoteObj.zqu__SubscriptionType__c != 'Cancel Subscription' && 
					zquQuoteObj.zqu__Opportunity__c != null && 
					oppIdMap.containsKey(zquQuoteObj.zqu__Opportunity__c)) {
			
			zquQuoteObj.zqu__ValidUntil__c = oppIdMap.get(zquQuoteObj.zqu__Opportunity__c).Opportunity_Expiration_Date__c;  
		}

		// On non-Cancellation Quote record insert sure the Term Start Date is greater than or equal to today, otherwise throw an error message
		// old method: validateQuoteTermStartDates
		// comment for release 4.06
		// csp-2727: allow backdating of subs for certain
			if (zquQuoteObj.zqu__SubscriptionType__c != 'Cancel Subscription' && zquQuoteObj.zqu__TermStartDate__c < Date.today() && !LocalProductRules.backdateUserSet.contains(System.UserInfo.getUserId())) {
			zquQuoteObj.addError(Label.Quote_Term_Start_Date_Less_Than_Today);
		}

		// When Quote records are created, query and record the appropriate SalesRepId, RenewalRepId, and the RSD_Ids by querying the User records
		// SF-598, SF-599, SF-601
		// old method: PopulateIDsForCommissionTracking
		if (String.isNotBlank(zquQuoteObj.SalesRepLookup__c)) {
			User salesRep = userIdAndUserMap.get(zquQuoteObj.SalesRepLookup__c);
			//for CSP-999
			//the Disallow_Sales_Rep_On_Quotes__c field in Sales Rep or Renewal Rep must be false.
			if (salesRep.Disallow_Sales_Rep_On_Quotes__c) {
				zquQuoteObj.addError(system.Label.DisallowSalesRepOnQuotesErrorMessage);
			}

			zquQuoteObj.SalesRepId__c = salesRep.SalesRepId__c;
			zquQuoteObj.RenewalRepLookup__c = zquQuoteObj.SalesRepLookup__c;
			zquQuoteObj.RenewalRepId__c = salesRep.SalesRepId__c;
		}

		if (String.isNotBlank(zquQuoteObj.RenewalRepLookup__c)) {
			User renewalRep = userIdAndUserMap.get(zquQuoteObj.RenewalRepLookup__c);
			zquQuoteObj.RenewalRepId__c = renewalRep.SalesRepId__c;
			if (renewalRep.ManagerId != null) {
				zquQuoteObj.RSDLookup__c = renewalRep.ManagerId;
				zquQuoteObj.RSD_Id__c = renewalRep.Manager.SalesRepId__c;
			}
		}
		

		// if the quote is amend, cancel, renew subscription, assign the Product_Line__c of Previous Subscription to the quote Product_Line__c
		if (String.isNotBlank(zquQuoteObj.zqu__ExistSubscriptionID__c) && subZuoraIdMap.containsKey(zquQuoteObj.zqu__ExistSubscriptionID__c)) {
			zquQuoteObj.Product_Line__c = subZuoraIdMap.get(zquQuoteObj.zqu__ExistSubscriptionID__c).Product_Line__c;

			if (zquQuoteObj.zqu__SubscriptionType__c == 'Amend Subscription' || zquQuoteObj.zqu__SubscriptionType__c == 'Renew Subscription') {
				zquQuoteObj.Previous_Subscription_TCV__c = subZuoraIdMap.get(zquQuoteObj.zqu__ExistSubscriptionID__c).Zuora__TCV__c;
			}
		}

		// When a creating a quote, set the electronic payment method based on the opportunity
		if ((zquQuoteObj.zqu__ElectronicPaymentMethodId__c == null || zquQuoteObj.zqu__ElectronicPaymentMethodId__c == '') && oppIdMap.containsKey(zquQuoteObj.zqu__Opportunity__c)) {
			if (zquQuoteObj.zqu__PaymentMethod__c == zqu.PaymentPageController.PAYMENT_METHOD_TYPE_CREDIT_CARD){
				zquQuoteObj.zqu__ElectronicPaymentMethodId__c = oppIdMap.get(zquQuoteObj.zqu__Opportunity__c).Electronic_Payment_Method_Id_Credit__c;
			}
			else if (zquQuoteObj.zqu__PaymentMethod__c == zqu.PaymentPageController.PAYMENT_METHOD_TYPE_ACH)
			{
				zquQuoteObj.zqu__ElectronicPaymentMethodId__c = oppIdMap.get(zquQuoteObj.zqu__Opportunity__c).Electronic_Payment_Method_Id_ACH__c;
			}
		}

		// CSP-1414, CSP-2048
		// validate the quote's bill to contact, sold to contact and Auto Renewal Flag
		validateQuote(zquQuoteObj);

		// Copy the payment method into custom field
		if(zquQuoteObj.zqu__PaymentMethod__c != NUll && zquQuoteObj.zqu__PaymentMethod__c != ''){
				zquQuoteObj.Payment_Method__c = zquQuoteObj.zqu__PaymentMethod__c;
		}

		

		if(zquQuoteObj.zqu__SubscriptionType__c == 'Amend Subscription') {
				// CSP-1821 Remove Generate Invoice Option for Amendments
				// only for amendment
				zquQuoteObj.zqu__GenerateInvoice__c = false;
				zquQuoteObj.zqu__ProcessPayment__c = false; 
		}

		// CSP - 1470
		// Note: 12-09-2016 - Moved this to the processing loop AFTER validations occuring above
		// comment by ticket CSP-2414,  Local user cannot generate invoice when send the cancelled quote to zuora except Tonia and Shannon
		// if(zquQuoteObj.zqu__SubscriptionType__c != null && zquQuoteObj.zqu__SubscriptionType__c == 'Cancel Subscription'){
				// zquQuoteObj.zqu__GenerateInvoice__c = true;
				// zquQuoteObj.zqu__ProcessPayment__c = true;
		// }

		// CSP-2423
		if(String.isNotBlank(zquQuoteObj.zqu__BillCycleDay__c)) {
			Integer billCycleDay = Integer.valueOf(zquQuoteObj.zqu__BillCycleDay__c);
			if(billCycleDay > 27) {
				zquQuoteObj.zqu__BillCycleDay__c = '27';
			}
		}
	}


	/**
	*   All before update logic should be done here. This method is called iteratively and as such
	*   should contain no actions which could potentially hit limits or is considered bad practice
	*   in the Salesforce environment.
	*
	*   @param  {SObject}   oldSo Single SObject representation of the "old" copy of the current 
	*                             object being acted upon.
	*   @param  {SObject}   so    Single SObject representation of the object being acted upon.
	*/
	public void beforeUpdate(SObject oldSo, SObject so) {
		zqu__Quote__c zquQuoteObj = (zqu__Quote__c)so;
		zqu__Quote__c oldZQUQuote = (zqu__Quote__c)oldSo;

		// set default value for some fields
		// CSP-1786 - ALWAYS set Zuora auto renew flag to False. Using a custom flag moving forward.
		zquQuoteObj.zqu__AutoRenew__c = false;
		zquQuoteObj.zqu__Service_Activation_Date__c = zquQuoteObj.zqu__TermStartDate__c;
		// CSP-2423 - If this is a new Billing Account - set the Bill Cycle Day to the same as the Service Activation Day
		if(String.isBlank(zquQuoteObj.zqu__ZuoraAccountID__c) && zquQuoteObj.zqu__Service_Activation_Date__c != null) {
			zquQuoteObj.zqu__BillCycleDay__c = String.valueOf(zquQuoteObj.zqu__Service_Activation_Date__c.day());
		}
		zquQuoteObj.zqu__QuoteTemplate__c = null;

		if (zquQuoteObj.zqu__SubscriptionType__c == 'New Subscription') {
			zquQuoteObj.OriginalSalesforceQuoteID__c = zquQuoteObj.Id;

			//CSP-2880 Make Invoice Owner field available to certain users
			//Add error when update invoice owner if not corrent role or Profile
			if(currentUserInfo.UserRole.Name != 'SOSS Managers' && currentUserInfo.UserRole.Name != 'SOSS' 
				&& currentUserInfo.Profile.Name != 'Local Core Finance - ARR' && currentUserInfo.Profile.Name != 'System Administrator'
				&& currentUserInfo.Profile.Name != 'Service Accounts' 
				&& zquQuoteObj.zqu__InvoiceOwnerId__c != oldZQUQuote.zqu__InvoiceOwnerId__c) {

				//Add error when Invoice Owner has value 
				zquQuoteObj.addError(Label.Change_Invoice_Owner_Error);
			}
		}
		else{
			if (subZuoraIdMap.containsKey(zquQuoteObj.zqu__ExistSubscriptionID__c)) {
				Zuora__Subscription__c currentSubscription = subZuoraIdMap.get(zquQuoteObj.zqu__ExistSubscriptionID__c);

				if (zquQuoteObj.zqu__SubscriptionType__c == 'Amend Subscription') {
					zquQuoteObj.OriginalSalesforceQuoteID__c = currentSubscription.OriginalSalesforceQuoteID__c;

					//CSP-2880 Make Invoice Owner field available to certain users
					//Add error when update invoice owner if not corrent role or Profile
					if(currentUserInfo.UserRole.Name != 'SOSS Managers' && currentUserInfo.UserRole.Name != 'SOSS' 
						&& currentUserInfo.Profile.Name != 'Local Core Finance - ARR' && currentUserInfo.Profile.Name != 'System Administrator'
						&& currentUserInfo.Profile.Name != 'Service Accounts' 
						&& zquQuoteObj.zqu__InvoiceOwnerId__c != oldZQUQuote.zqu__InvoiceOwnerId__c) {

						//Add error
						zquQuoteObj.addError(Label.Change_Invoice_Owner_Error);
					}
				}
			}
		}

		if (String.isNotBlank(zquQuoteObj.Product_Line__c) && 
					(zquQuoteObj.Product_Line__c.containsIgnoreCase('Direct Mail') || zquQuoteObj.Product_Line__c.containsIgnoreCase('Print'))) {

			zquQuoteObj.zqu__QuoteTemplate__c = quoteTempNameIdMap.get('LDE Quote Template');
		}

		// CSP-1610 On non-Cancellation Quote record update always set zqu__Quote__c.zqu__ValidUntil__c to the parent Opportunity.Opportunity_Expiration_Date__c field value
		// old method: setValidUntilDateToOppExpirationDate
		if (zquQuoteObj.zqu__SubscriptionType__c != 'Cancel Subscription' && 
					zquQuoteObj.zqu__ValidUntil__c != oldZQUQuote.zqu__ValidUntil__c && 
					zquQuoteObj.zqu__Opportunity__c != null && 
					oppIdMap.containsKey(zquQuoteObj.zqu__Opportunity__c)) {
			
			zquQuoteObj.zqu__ValidUntil__c = oppIdMap.get(zquQuoteObj.zqu__Opportunity__c).Opportunity_Expiration_Date__c;  
		}

		if (String.isNotBlank(zquQuoteObj.SalesRepLookup__c) && userIdAndUserMap.containsKey(zquQuoteObj.SalesRepLookup__c)) {
			User salesRep = userIdAndUserMap.get(zquQuoteObj.SalesRepLookup__c);
			// SalesRep changed, update the SalesRepId__c, and if the RenewalRepLookup__c has not changed, assign the SalesRep to RenewalRepLookup__c
			if (zquQuoteObj.SalesRepLookup__c != oldZQUQuote.SalesRepLookup__c) {

				zquQuoteObj.SalesRepId__c = salesRep.SalesRepId__c;

				if (oldZQUQuote.RenewalRepLookup__c == zquQuoteObj.RenewalRepLookup__c) {
					zquQuoteObj.RenewalRepLookup__c = zquQuoteObj.SalesRepLookup__c;
					zquQuoteObj.RenewalRepId__c = salesRep.SalesRepId__c;
				}
			}

			//for CSP-999
			//the Disallow_Sales_Rep_On_Quotes__c field in SalesRep or RenewalRep must be false.
			if (salesRep.Disallow_Sales_Rep_On_Quotes__c) {
				zquQuoteObj.addError(system.Label.DisallowSalesRepOnQuotesErrorMessage);
			}
		}
		
		if (String.isNotBlank(zquQuoteObj.RenewalRepLookup__c)  && userIdAndUserMap.containsKey(zquQuoteObj.RenewalRepLookup__c)) {

			User renewalRep = userIdAndUserMap.get(zquQuoteObj.RenewalRepLookup__c);
			// RenewalRep changed
			if (oldZQUQuote.RenewalRepLookup__c != zquQuoteObj.RenewalRepLookup__c) {
				
				zquQuoteObj.RenewalRepId__c = renewalRep.SalesRepId__c;
				zquQuoteObj.RSDLookup__c = renewalRep.ManagerId;
				zquQuoteObj.RSD_Id__c = (String.isNotBlank(renewalRep.ManagerId)) ? renewalRep.Manager.SalesRepId__c : null;
			}

			//for CSP-999
			//the Disallow_Sales_Rep_On_Quotes__c field in SalesRep or RenewalRep must be false.
			if (renewalRep.Disallow_Sales_Rep_On_Quotes__c) {
				zquQuoteObj.addError(system.Label.DisallowSalesRepOnQuotesErrorMessage);
			}
		}

		// Assign paymennt method expiration date after the sales rep enters payment method 
		//detail and hits next to navigate to the next page in the Q2C process
		if (oldZQUQuote.zqu__ElectronicPaymentMethodId__c != zquQuoteObj.zqu__ElectronicPaymentMethodId__c) {
			if(zquQuoteObj.zqu__ElectronicPaymentMethodId__c != null && 
					zquQuoteObj.zqu__ZuoraAccountID__c == null && 
					zquQuoteObj.zqu__ZuoraPaymentID__c == null && 
					(zquQuoteObj.zqu__PaymentMethod__c == 'ACH' || zquQuoteObj.zqu__PaymentMethod__c == 'Credit Card')) {

				zquQuoteObj.Payment_Method_Expiration_Date__c = System.today().addDays(10);
			}
		}

		// CSP-1414, CSP-2048,
		// Add an error if the Bill To Contact and Sold To Contact does not have a FirstName AND LastName
		validateQuote(zquQuoteObj);

		// CSP-1598 - Populate the term total field with the summed effective prices
		if(quoteToSumEffectivePriceMap.containsKey(zquQuoteObj.Id)) {
				zquQuoteObj.Term_Total__c = quoteToSumEffectivePriceMap.get(zquQuoteObj.Id);
		}
		else {
				zquQuoteObj.Term_Total__c = 0;
		}

		// Copy the payment method into custom field
		if(String.isNotBlank(zquQuoteObj.zqu__PaymentMethod__c)){
				zquQuoteObj.Payment_Method__c = zquQuoteObj.zqu__PaymentMethod__c;
		}

		if(zquQuoteObj.zqu__SubscriptionType__c == 'Amend Subscription') {
				// CSP-1821 Remove Generate Invoice Option for Amendments
				// only for amendment
				zquQuoteObj.zqu__GenerateInvoice__c = false;
				zquQuoteObj.zqu__ProcessPayment__c = false; 
		}

		// CSP - 1470
		// Note: 12-09-2016 - Moved this to the processing loop AFTER validations occuring above
		// comment by ticket CSP-2414,  Local user cannot generate invoice when send the cancelled quote to zuora except Tonia and Shannon
		// if(zquQuoteObj.zqu__SubscriptionType__c != null && zquQuoteObj.zqu__SubscriptionType__c == 'Cancel Subscription'){
				// zquQuoteObj.zqu__GenerateInvoice__c = true;
				// zquQuoteObj.zqu__ProcessPayment__c = true;
		// }

		// CSP-2423
		if(String.isNotBlank(zquQuoteObj.zqu__BillCycleDay__c)) {
			Integer billCycleDay = Integer.valueOf(zquQuoteObj.zqu__BillCycleDay__c);
			if(billCycleDay > 27) {
				zquQuoteObj.zqu__BillCycleDay__c = '27';
			}
		}
	}

	/**
	*   All before delete logic should be done here. This method is called iteratively and as such
	*   should contain no actions which could potentilly hit limits or is considered bad practice
	*   in the Salesforce environment.
	*
	*   @param  {SObject}   so Single SObject representation of the object being acted upon.
	*/
	public void beforeDelete(SObject so) {
		zqu__Quote__c zquQuoteObj = (zqu__Quote__c)so;

		//  A Quote associated to an opportunity should NOT be able to be deleted once the opportunity stage has advanced passed Quoting except the user in permissionSet Manage_Quotes. 
		//  CSP-1634
		//  // comment for release 4.06
		// if(oppIdMap.containsKey(zquQuoteObj.zqu__Opportunity__c)) {
			Opportunity currentOpp = oppIdMap.get(zquQuoteObj.zqu__Opportunity__c);

			// if(currentOpp != null) {
				if (currentOpp.isClosed) {
					zquQuoteObj.addError(System.Label.ErrorMessageForPreventToDeleteQuoteClosedLost);
				}
				else if (!System.Label.OppStageForDeleteQuote.containsIgnoreCase(currentOpp.StageName)) {
					zquQuoteObj.addError(System.Label.ErrorMessageForPreventToDeleteQuote);
				}
			// }
		// }
	}

	/**
	*   All after insert logic should be done here. This method is called iteratively and as such
	*   should contain no actions which could potentilly hit limits or is considered bad practice
	*   in the Salesforce environment. 
	*
	*   @param  {SObject}   so Single SObject representation of the object being acted upon.
	*/
	public void afterInsert(SObject so) {}

	/**
	*   All after update logic should be done here. This method is called iteratively and as such
	*   should contain no actions which could potentilly hit limits or is considered bad practice
	*   in the Salesforce environment.
	*   
	*   @param  {SObject}   oldSo Single SObject representation of the "old" copy of the current 
	*                             object being acted upon.
	*   @param  {SObject}   so    Single SObject representation of the object being acted upon.
	*/
	public void afterUpdate(SObject oldSo, SObject so) {
		zqu__Quote__c zquQuoteObj = (zqu__Quote__c)so;
		zqu__Quote__c oldZQUQuote = (zqu__Quote__c)oldSo;

		// SalesRep,ReportingRep or RenewalRep changed, child QuoteRatePlanCharge records need update
		if (zquQuoteObj.SalesRepLookup__c != oldZQUQuote.SalesRepLookup__c ||
				zquQuoteObj.Reporting_Rep__c != oldZQUQuote.Reporting_Rep__c ||
				zquQuoteObj.RenewalRepLookup__c != oldZQUQuote.RenewalRepLookup__c) {

			quoteIdMap.put(zquQuoteObj.Id, zquQuoteObj);
		}

		if (zquQuoteObj.zqu__ValidUntil__c != oldZQUQuote.zqu__ValidUntil__c) {
			quoteIDAndExpirationDateMap.put(zquQuoteObj.Id,zquQuoteObj.zqu__ValidUntil__c);
		}

		// if the zqu__ElectronicPaymentMethodId__c of quote has been change from null, update the parent Opp's Electronic_Payment_Method_Id_Credit__c
		// and Electronic_Payment_Method_Id_Credit__c
		if (String.isNotBlank(zquQuoteObj.zqu__ElectronicPaymentMethodId__c) &&
			String.isEmpty(oldZQUQuote.zqu__ElectronicPaymentMethodId__c)){

			Opportunity newOpp = new Opportunity();
			if (updateOppIDMap.containsKey(zquQuoteObj.zqu__Opportunity__c)) {
				newOpp = updateOppIDMap.get(zquQuoteObj.zqu__Opportunity__c);
			}
			else{
				newOpp.Id = zquQuoteObj.zqu__Opportunity__c;
			}
			
			if (zquQuoteObj.zqu__PaymentMethod__c == zqu.PaymentPageController.PAYMENT_METHOD_TYPE_CREDIT_CARD) {
				newOpp.Electronic_Payment_Method_Id_Credit__c = zquQuoteObj.zqu__ElectronicPaymentMethodId__c;
				updateOppIDMap.put(newOpp.Id, newOpp);
			}
			else if(zquQuoteObj.zqu__PaymentMethod__c == zqu.PaymentPageController.PAYMENT_METHOD_TYPE_ACH){
				newOpp.Electronic_Payment_Method_Id_ACH__c = zquQuoteObj.zqu__ElectronicPaymentMethodId__c;
				updateOppIDMap.put(newOpp.Id, newOpp);
			}
		}

		// used to run the product rules when certain Quote fields are modified via the Edit Quote Details page
		if (zquQuoteObj.zqu__InitialTerm__c != oldZQUQuote.zqu__InitialTerm__c ||
			zquQuoteObj.zqu__StartDate__c != oldZQUQuote.zqu__StartDate__c ||
			zquQuoteObj.zqu__TermStartDate__c != oldZQUQuote.zqu__TermStartDate__c ||
			zquQuoteObj.zqu__Service_Activation_Date__c != oldZQUQuote.zqu__Service_Activation_Date__c) {

			LocalProductRules.evaluateOpportunity(zquQuoteObj.zqu__Opportunity__c);
		}


		if (zquQuoteObj.zqu__Status__c == 'Sent to Z-Billing' && 
				oldZQUQuote.zqu__Status__c != 'Sent to Z-Billing' && 
				String.isNotBlank(zquQuoteObj.Subscription_Being_Renewed__c)) {

			subscriptionIdSet.add(zquQuoteObj.Subscription_Being_Renewed__c);
			renewQuoteIdSet.add(zquQuoteObj.Id);
			renewAccountIdSet.add(zquQuoteObj.zqu__Account__c);
		}
	}

	/**
	*   All after delete logic should be done here. This method is called iteratively and as such
	*   should contain no actions which could potentilly hit limits or is considered bad practice
	*   in the Salesforce environment. 
	*
	*   @param  {SObject}   so Single SObject representation of the object being acted upon.
	*/
	public void afterDelete(SObject so) {
		zqu__Quote__c zquQuoteObj = (zqu__Quote__c)so;

		// we need to query for all Quote records belonging to the parent Opportunity record(s) SF-1336 
		parentOppIdSet.add(zquQuoteObj.zqu__Opportunity__c);
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
	public void afterAndFinally() {
		List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();


		// SalesRep,ReportingRep or RenewalRep changed, child QuoteRatePlanCharge records need update
		if (!quoteIdMap.isEmpty()) {
			List<zqu__QuoteRatePlanCharge__c> updateQRPCList = [SELECT Id, RenewalRepID__c, RSD_Id__c, SalesRepID__c, zqu__QuoteRatePlan__r.zqu__Quote__c 
																													FROM zqu__QuoteRatePlanCharge__c 
																													WHERE zqu__QuoteRatePlan__r.zqu__Quote__c IN :quoteIdMap.keySet()];
			
			if (!updateQRPCList.isEmpty()) {
				for (zqu__QuoteRatePlanCharge__c qrpc : updateQRPCList) {
					zqu__Quote__c tempQuoteObject = quoteIdMap.get(qrpc.zqu__QuoteRatePlan__r.zqu__Quote__c);

					qrpc.SalesRepID__c = tempQuoteObject.SalesRepID__c;
					qrpc.RenewalRepId__c = tempQuoteObject.RenewalRepId__c;
					qrpc.RSD_Id__c = tempQuoteObject.RSD_Id__c;
				}
				List<Database.SaveResult> resultList = Database.update(updateQRPCList);
				xoExceptionList.addAll(ExceptionUtility.consumeException(resultList));
			}
		}

		// UpdateInventoryExpirationDates SF-1597 Code for Local Opportunity Approval Process; updates expiration dates on child Inventory records
		if (!quoteIDAndExpirationDateMap.isEmpty()) {

			// Update all Inventory record's "Hold Until" dates to match the grandparent Quote's "Valid Until" date
			List<Inventory__c> inventoryUpdateList = new List<Inventory__c>();
			List<zqu__QuoteRatePlan__c> qrpList = [SELECT Id, zqu__Quote__c, (SELECT Id, Inventory_Hold_Expiry_Date__c FROM Inventory__r) FROM zqu__QuoteRatePlan__c 
																							WHERE zqu__Quote__c IN :quoteIDAndExpirationDateMap.keySet()];

			for (zqu__QuoteRatePlan__c qrp : qrpList) {
				Date newHoldDate = quoteIDAndExpirationDateMap.get(qrp.zqu__Quote__c);
				
				for (Inventory__c inv : qrp.Inventory__r) {
					inv.Inventory_Hold_Expiry_Date__c = newHoldDate;
					inventoryUpdateList.add(inv);
				}
			}

			List<Database.SaveResult> resultList = Database.update(inventoryUpdateList);
			xoExceptionList.addAll(ExceptionUtility.consumeException(resultList));
		}

		// When a Quote record's electronic payment method is changed from empty, set it on the opportunity
		if (!updateOppIDMap.isEmpty()) {
			List<Database.SaveResult> resultList = Database.update(updateOppIDMap.values());
			xoExceptionList.addAll(ExceptionUtility.consumeException(resultList));
		}
		
		// if the renewal quote has send to z-Billing, send a notification to the billingcontact
		if (!subscriptionIdSet.isEmpty()) {
			sendAutoRenewalNotification(subscriptionIdSet,renewQuoteIdSet,renewAccountIdSet);
		}

		// we need to query for all Quote records belonging to the parent Opportunity record(s) SF-1336 
		if (!parentOppIdSet.isEmpty()) {
			xoExceptionList.addAll(updateParentOpportunity(parentOppIdSet));
		}

		if (!xoExceptionList.isEmpty()) {
			insert xoExceptionList;
		}
	}




	/* 
	<method>
		<name>UpdatePotentialValueOfOpportunity</name>
		<purpose>When a Quote record is created, updated, or deleted, the Potential Value of the parent Opportunity is recalculated</purpose>
		<created>
			<by>Jonathan Satterfield</by>
			<date>10/2/2015</date>
			<ticket>SF-1499</ticket>
		</created>
		this method be called by class ZuoraQuoteChooseNextActionController
	</method>
	*/
	public static void UpdatePotentialValueOfOpportunity(Id oppId) {

		// CSP-1858 | don't update Opportunities that are Closed Won or Closed Lost
		Set<String> closedOppTypeSet = new Set<String>{'Closed Won', 'Closed Lost'};
		
		List<Opportunity> oppList = [SELECT Id, Potential_Value_Print__c, Potential_Value_Internet__c, Potential_Value_Direct_Marketing__c, 
																(SELECT Id, Product_Line__c, Quote_Template_TCV__c FROM zqu__Quotes__r) FROM Opportunity 
																WHERE Id = :oppID AND Type NOT IN :closedOppTypeSet];

		List<Opportunity> oppUpdateList = new List<Opportunity>();
		for (Opportunity opp : oppList) {
			// Product line values to assess: Print, Internet, and Direct Mail
			Decimal tempPrintPotentialValue = 0.00;
			Decimal tempInternetPotentialValue = 0.00;
			Decimal tempDirectMailPotentialValue = 0.00;

			for (zqu__Quote__c q : opp.zqu__Quotes__r) {
				if (q.Quote_Template_TCV__c != null){

					if (q.Product_Line__c == 'Print') {
						tempPrintPotentialValue += q.Quote_Template_TCV__c;
					}
					else if (q.Product_Line__c == 'Internet') {
						tempInternetPotentialValue += q.Quote_Template_TCV__c;
					}
					else if (q.Product_Line__c == 'Direct Mail') {
						tempDirectMailPotentialValue += q.Quote_Template_TCV__c;
					}
				}
			}

			// if any value changed, assign values to the Opportunity and add the Opportunity to the oppUpdateList
			if (opp.Potential_Value_Print__c != tempPrintPotentialValue || 
				opp.Potential_Value_Internet__c != tempInternetPotentialValue || 
				opp.Potential_Value_Direct_Marketing__c != tempDirectMailPotentialValue) {

				opp.Potential_Value_Print__c = tempPrintPotentialValue.setScale(2);
				opp.Potential_Value_Internet__c = tempInternetPotentialValue.setScale(2);
				opp.Potential_Value_Direct_Marketing__c = tempDirectMailPotentialValue.setScale(2);

				oppUpdateList.add(opp);
			}
		}

		if (!oppUpdateList.isEmpty()) {
			update oppUpdateList;
		}
	}


	/**
	 *   CSP-1746 | Refact quote trigger
	 *   When a Quote record is created, updated, validate the bill to contact and sold to contact and Auto Renewal Flag
	 *   @author Tony Liu
	 *   @date   2017-07-21
	 *   @param  Object Quote
	 */
	private void validateQuote(zqu__Quote__c zquQuoteObj) {
		// CSP-1414:
		// Add an error if the Bill To contact does not have a FirstName AND LastName
		if(String.isNotBlank(zquQuoteObj.zqu__BillToContact__c) && contactMap.containsKey(zquQuoteObj.zqu__BillToContact__c)) {
				
				Contact currentContact = contactMap.get(zquQuoteObj.zqu__BillToContact__c);
				
				if(String.isBlank(currentContact.FirstName)) {
						zquQuoteObj.zqu__BillToContact__c.addError('Bill To Contact must have a First Name');
				}

				if(String.isBlank(currentContact.LastName)) {
						zquQuoteObj.zqu__BillToContact__c.addError('Bill To Contact must have a Last Name');
				}
		}

		// CSP-1414:
		// Add an error if the Sold To contact does not have a FirstName AND LastName
		if(String.isNotBlank(zquQuoteObj.zqu__SoldToContact__c) && contactMap.containsKey(zquQuoteObj.zqu__SoldToContact__c)) {
				
				Contact currentContact = contactMap.get(zquQuoteObj.zqu__SoldToContact__c);
				
				if(String.isBlank(currentContact.FirstName)) {
						zquQuoteObj.zqu__SoldToContact__c.addError('Sold To Contact must have a First Name');
				}

				if(String.isBlank(currentContact.LastName)) {
						zquQuoteObj.zqu__SoldToContact__c.addError('Sold To Contact must have a Last Name');
				}
		}

		//  CSP-2048,
		if (String.isNotBlank(zquQuoteObj.Product_Line__c) && 
					String.valueOf(system.Label.TheProductLineNotAllowAutoRenwal).contains(zquQuoteObj.Product_Line__c) && 
					zquQuoteObj.AutoRenewal__c == 'YES') {

			zquQuoteObj.addError(system.Label.DisallowAutoRenewalErrorMessage);
		}
		
		if (!haveAccessForUser && zquQuoteObj.zqu__InitialTerm__c<12 && zquQuoteObj.AutoRenewal__c == 'YES') {
				zquQuoteObj.addError(system.Label.DisallowAutoRenewalErrorMessageTerms);
		}
	}



	/**
	*   Send a notification email to customer when the renewal quote had been sent to Z-Billing
	*   @author Tony Liu
	*   @date   2017-04-20
	*   
	*/
	private void sendAutoRenewalNotification(Set<Id> subscriptionIdSet, Set<Id> renewQuoteIdSet, Set<Id> renewAccountIdSet) {

		List<Messaging.SingleEmailMessage> emailsToSendList= new List<Messaging.SingleEmailMessage>();
		List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();

		// get the email template Id
		Id autoRenewalEmailTemplateId;
		try {
			autoRenewalEmailTemplateId = [SELECT Id, Name FROM EmailTemplate WHERE Name = 'Automating Auto Renewal Notification Emails'].id;
		}
		catch (Exception e) {
			XO_Exception__c xoException = ExceptionUtility.consumeException(e, true);
		}

		// Query all the original Subscriptions and check the flag AutoRenewal__c, if True, created an email and added to the emaillist
		List<OrgWideEmailAddress> oweaList = [SELECT id, Address FROM OrgWideEmailAddress WHERE Address = 'noreply@xogrp.com' limit 1];


		// get the primary contact role for accounts
		Map<Id, Id> primaryACRIdMap = retrievePrimaryContactRole(renewAccountIdSet);


		List<Zuora__SubscriptionProductCharge__c> subChargeList  = [SELECT Zuora__Subscription__r.Id, Zuora__Subscription__r.Name, Zuora__Subscription__r.AutoRenewal__c,
																																	Id, Name, Zuora__Price__c, LocationVendorDynamicsAccountID__c, Zuora__RatePlanName__c 
																																FROM Zuora__SubscriptionProductCharge__c 
																																WHERE Zuora__Subscription__c IN : subscriptionIdSet AND Zuora__Subscription__r.AutoRenewal__c = 'YES'];

		
		// CSP-3174 !!! renewal letters going to custoemrs with no change in rate
		// adding a field zqu__QuoteRatePlan__r.zqu__ProductRatePlan__r.zqu__ProductRatePlanFullName__c for querying the full name
		List<zqu__QuoteRatePlanCharge__c> renewalQuoteChargeList = [SELECT zqu__EffectivePrice__c, LocationVendorDynamicsAccountID__c, zqu__QuoteRatePlan__r.Name, zqu__QuoteRatePlan__r.zqu__ProductRatePlan__r.zqu__ProductRatePlanFullName__c,
																																zqu__QuoteRatePlan__r.zqu__Quote__r.Subscription_Being_Renewed__c, zqu__QuoteRatePlan__r.zqu__Quote__r.zqu__BillToContact__c, 
																																zqu__QuoteRatePlan__r.zqu__Quote__c,  zqu__QuoteRatePlan__r.zqu__Quote__r.zqu__Account__c, AccountSSEmail__c
																													FROM zqu__QuoteRatePlanCharge__c Where zqu__QuoteRatePlan__r.zqu__Quote__c in: renewQuoteIdSet];
		
		Map<String,Decimal> chargePriceMap = new Map<String,Decimal>();
		Set<Id> autoRenewalSubscriptionSet = new Set<Id>();
		if (!subChargeList.isEmpty()) {
			for(Integer i=0; i < subChargeList.size(); i++){
				Zuora__SubscriptionProductCharge__c currentSubCharge = subChargeList[i];

				// CSP-3174 !!! renewal letters going to custoemrs with no change in rate
				// Fixed location id will be lower case issue
				String keyString = '';
				if(String.isNotBlank(currentSubCharge.LocationVendorDynamicsAccountID__c)){
					keyString = currentSubCharge.LocationVendorDynamicsAccountID__c.toUpperCase() + currentSubCharge.Zuora__RatePlanName__c;
				}
				else{
					keyString = currentSubCharge.Zuora__RatePlanName__c;
				}
				chargePriceMap.put(keyString, currentSubCharge.Zuora__Price__c);

				autoRenewalSubscriptionSet.add(currentSubCharge.Zuora__Subscription__r.Id);

			}
		}

		Map<Id,zqu__QuoteRatePlanCharge__c> emailQuoteMap = new Map<Id,zqu__QuoteRatePlanCharge__c>();
		
		if (!renewalQuoteChargeList.isEmpty()) {
			
			for (Integer i=0; i < renewalQuoteChargeList.size(); i++) {
				zqu__QuoteRatePlanCharge__c currentQuoteCharge = renewalQuoteChargeList[i];
				
				if (autoRenewalSubscriptionSet.contains(currentQuoteCharge.zqu__QuoteRatePlan__r.zqu__Quote__r.Subscription_Being_Renewed__c)) {
					
					// CSP-3174 !!! renewal letters going to custoemrs with no change in rate
					// Using product rate plan full name instead of quote rate plan name
					// Fixed location id will be lower case issue
					String keyString = '';
					if(String.isNotBlank(currentQuoteCharge.LocationVendorDynamicsAccountID__c)){
						keyString = currentQuoteCharge.LocationVendorDynamicsAccountID__c.toUpperCase() + currentQuoteCharge.zqu__QuoteRatePlan__r.zqu__ProductRatePlan__r.zqu__ProductRatePlanFullName__c;
					}
					else{
						keyString = currentQuoteCharge.zqu__QuoteRatePlan__r.zqu__ProductRatePlan__r.zqu__ProductRatePlanFullName__c;
					}
					
					if (chargePriceMap.containsKey(keyString)) {
						if (currentQuoteCharge.zqu__EffectivePrice__c > chargePriceMap.get(keyString)){
							emailQuoteMap.put(currentQuoteCharge.zqu__QuoteRatePlan__r.zqu__Quote__c, currentQuoteCharge);
						}
					}else{
						emailQuoteMap.put(currentQuoteCharge.zqu__QuoteRatePlan__r.zqu__Quote__c, currentQuoteCharge);
					}
				}
				
			} 
		}
		if (!emailQuoteMap.isEmpty()) {
			for (Id quoteId : emailQuoteMap.keySet()) {
				zqu__QuoteRatePlanCharge__c currentQuoteCharge = emailQuoteMap.get(quoteId);

				Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

				// Set the email information
				email.setWhatId(quoteId);
				// Send the renewal notification to the primary contact
				if (primaryACRIdMap.containsKey(currentQuoteCharge.zqu__QuoteRatePlan__r.zqu__Quote__r.zqu__Account__c)) {

					email.setTargetObjectId(primaryACRIdMap.get(currentQuoteCharge.zqu__QuoteRatePlan__r.zqu__Quote__r.zqu__Account__c));
				}else{
					email.setTargetObjectId(currentQuoteCharge.zqu__QuoteRatePlan__r.zqu__Quote__r.zqu__BillToContact__c);
				}
				email.setTemplateId(autoRenewalEmailTemplateId);
				// CSP-2260 - Save the activity to the associate Contact, currently set to the BillToContact on Quote
				email.setSaveAsActivity(true);
				email.orgWideEmailAddressId = oweaList[0].id;
				email.setReplyTo(currentQuoteCharge.AccountSSEmail__c);
				emailsToSendList.add(email);
			}
		}

		// Send the email, and catch the exception if failure.
		if (emailsToSendList.size()>0) {
			List<Messaging.SendEmailResult> sendEmailResults = Messaging.sendEmail(emailsToSendList, false);
			xoExceptionList.addAll(ExceptionUtility.consumeException(sendEmailResults));
		}

		if(xoExceptionList.size() > 0){
			insert xoExceptionList;
		}
	}

	/**
	 *   Method used to get the Primary Contact Role associated with the Accounts provided. If 
	 *   no results are found a new AccountContactRole Map is generated to provide a blank value for code to work with.
	 *   find Primary contact role first, if no primary contact role, find billing, if more than 1 primary use the most recently created
	 *   
	 *   @author Tony 
	 *   @date   2017-10-12
	 *   @param  {Set<Id>}     Account Id Set The Account Id sets that will be used to retrieve the AccountContactRole
	 *   @return {Map<Id,Id>}           The retrieved Account ID primary contact Id Map or the empty Account ID primary contact Id Map
	 */
	public static Map<Id,Id> retrievePrimaryContactRole(Set<Id> accountIdSet) {
		try {
			// Query the accounts and the newest primary contact role or newest billing contact role
			List<Account> accList = [SELECT Id, 
																	(SELECT Id, ContactId, CreatedDate, AccountId, Role 
																		FROM AccountContactRoles  
																		WHERE Role in ('Primary','Billing') 
																			ORDER BY Role ASC, CreatedDate DESC limit 1) 
															FROM Account 
															WHERE Id in: accountIdSet];

			Map<Id,Id> primaryACRMap = new Map<Id,Id>();

			for (Account currentAccount : accList) {
				if (!currentAccount.AccountContactRoles.isEmpty()) {
					primaryACRMap.put(currentAccount.Id, currentAccount.AccountContactRoles[0].ContactId);
				}
			}
			return primaryACRMap;
		} catch(Exception e) {
			ExceptionUtility.consumeException(e, true);
			return new Map<Id,Id>();
		}
	}

	//  udpate the parent Opportunity for Potential Value and Approval_Process_Flag_Discount_Amount__c
	private static List<XO_Exception__c> updateParentOpportunity(Set<Id> parentOppIdSet) {
		List<XO_Exception__c> exceptionList = new List<XO_Exception__c>();
		// CSP-1858 | don't update Opportunities that are Closed Won or Closed Lost
		// comment the code for the type has no picklist value of 'Closed Won' and 'Closed Lost'
		// Set<String> closedOppTypeSet = new Set<String>{'Closed Won', 'Closed Lost'};       
		// List<Opportunity> oppList = [SELECT Id, Potential_Value_Print__c, Potential_Value_Internet__c, Potential_Value_Direct_Marketing__c, 
		//                                (SELECT Id, Product_Line__c, Quote_Template_TCV__c FROM zqu__Quotes__r) 
		//                              FROM Opportunity WHERE Id = :oppIdSet AND Type NOT IN :closedOppTypeSet];
		List<Opportunity> oppList = [SELECT Id, Potential_Value_Print__c, Potential_Value_Internet__c, Potential_Value_Direct_Marketing__c, Approval_Process_Flag_Discount_Amount__c,
																				(SELECT Id, Product_Line__c, Quote_Template_TCV__c, Approval_Process_Flag_Discount_Amount__c FROM zqu__Quotes__r) 
																	FROM Opportunity WHERE Id = :parentOppIdSet];

		List<Opportunity> oppUpdateList = new List<Opportunity>();
		
		for (Opportunity opp : oppList) {
			boolean approvalProcessFlagDiscountAmount = FALSE;
			// Product line values to assess: Print, Internet, and Direct Mail
			Decimal tempPrintPotentialValue = 0.00;
			Decimal tempInternetPotentialValue = 0.00;
			Decimal tempDirectMailPotentialValue = 0.00;

			for (zqu__Quote__c q : opp.zqu__Quotes__r) {
				// update the Potential
				if (q.Product_Line__c == 'Print') {
					tempPrintPotentialValue += q.Quote_Template_TCV__c;
				}
				else if (q.Product_Line__c == 'Internet') {
					tempInternetPotentialValue += q.Quote_Template_TCV__c;
				}
				else if (q.Product_Line__c == 'Direct Mail') {
					tempDirectMailPotentialValue += q.Quote_Template_TCV__c;
				}

				//update the Approval_Process_Flag_Discount_Amount__c for Opp
				// for the boolean, if Approval_Process_Flag_Discount_Amount__c is True put True,
				if (q.Approval_Process_Flag_Discount_Amount__c) {
					approvalProcessFlagDiscountAmount = TRUE;
				}
			}

			// if any value changed, assign values to the Opportunity and add the Opportunity to the oppUpdateList
			if (opp.Potential_Value_Print__c != tempPrintPotentialValue || 
					opp.Potential_Value_Internet__c != tempInternetPotentialValue || 
					opp.Potential_Value_Direct_Marketing__c != tempDirectMailPotentialValue ||
					opp.Approval_Process_Flag_Discount_Amount__c != approvalProcessFlagDiscountAmount) {

				opp.Potential_Value_Print__c = tempPrintPotentialValue.setScale(2);
				opp.Potential_Value_Internet__c = tempInternetPotentialValue.setScale(2);
				opp.Potential_Value_Direct_Marketing__c = tempDirectMailPotentialValue.setScale(2);
				opp.Approval_Process_Flag_Discount_Amount__c = approvalProcessFlagDiscountAmount;

				oppUpdateList.add(opp);
			}
		}

		if (!oppUpdateList.isEmpty()) {
			List<Database.SaveResult> resultList = Database.update(oppUpdateList);
			exceptionList.addAll(ExceptionUtility.consumeException(resultList));
		}
		return exceptionList;
	}


}