/**
 *   ZuoraSubscriptionUtility
 *
 *   This utility class is used specifically to generate a renewal quote given a Subscription Id and the Opportunity Id
 *   that the newly created Quote should be associated to. There is a lot of data generation and field mapping happening.
 *   Each method has been created to focus on the creation of a specific object record or multiple records. Unfortunately
 *   there are a two inserts within FOR loops below but this must be done because of the way Zuora needs its data to be
 *   formatted for creation. Normally this data is created slower through the QTC flow and not all at once like it is
 *   happening below.
 *
 *   Original ticket: CSP-1963
 */
public without sharing class ZuoraSubscriptionUtility {
	////////////////////////////
	// STATIC FINAL VARIABLES //
	////////////////////////////
	private static final zqu__CommunicationProfile__c DEFAULT_COMM_PROFILE;

	// Subscription and Subscription Product & Charges Query
	public static final String SUBSCRIPTION_QUERY = 'SELECT '
																										+ 'Id, '
																										+	'Name, '
																										+	'Sales_Rep__c, '
																										+	'Renewal_Rep__c, '
																										+	'AutoRenewal__c, '
																										+	'Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, '
																										+	'Zuora__CustomerAccount__r.Zuora__BillCycleDay__c, '
																										+	'Preferred_Payment_Schedule__c, '
																										+	'Product_Line__c, '
																										+	'Payment_Method__c, '
																										+	'Zuora__SubscriptionEndDate__c, '
																										+ 'Zuora__InvoiceOwner__r.Name,'
																										+ 'Zuora__InvoiceOwner__r.Zuora__Zuora_Id__c,'
																										+	'(SELECT '
																											+	'Id, '
																											+	'Name, '
																											+	'Zuora__Zuora_Id__c, '
																											+	'Zuora__RatePlanName__c, '
																											+	'Zuora__RatePlanId__c, '
																											+	'LocationVendorDynamicsAccountID__c, '
																											+	'Discount_Percentage__c '
																										+	' FROM '
																											+	'Zuora__Subscription_Product_Charges__r'
																										+ ')'
																									+	' FROM '
																										+	'Zuora__Subscription__c'
																									+	' WHERE '
																										+	'{WHERECLAUSE}';

	// Product Rate Plan with Child Product Rate Plan Charges
	private static final String PRODUCT_RATE_PLAN_QUERY = 	'SELECT '
																														+	'Id, '
																														+	'Name, '
																														+	'zqu__ZuoraId__c, '
																														+	'zqu__Product__r.Name, '
																														+	'(SELECT '
																															+	'Id, '
																															+	'Name, '
																															+	'zqu__Type__c, '
																															+ 'zqu__ProductRatePlan__c, '
																															+	'zqu__ProductRatePlan__r.Name, '
																															+	'zqu__ListPrice__c, '
																															+	'zqu__DefaultQuantity__c, '
																															+	'zqu__Model__c, '
																															+	'zqu__ListPriceBase__c, '
																															+	'zqu__ZuoraId__c, '
																															+	'zqu__RecurringPeriod__c'
																														+	' FROM '
																															+ 'R00N40000001mFVKEA2__r'
																														+ ')'
																													+ ' FROM '
																														+	' zqu__ProductRatePlan__c '
																													+	' WHERE '
																														+	' zqu__Deleted__c = false '
																													+	' AND '
																														+	'{WHERECLAUSE}';

  // Query used to get the Primary Contact that is Associated to the Opportunity Provided
	private static String PRIMARY_CONTACT_QUERY = 'SELECT '
																								+	'Id, '
																								+	'ContactId '
																							+	' FROM '
																								+ 'AccountContactRole'
																							+	' WHERE '
																								+	' AccountId IN '
																									+	'(SELECT '
																										+	' AccountId '
																									+	' FROM '
																										+ ' Opportunity '
																									+ ' WHERE '
																										+ ' Id = {OPPID}) '
																							+ ' AND '
																								+	' Role IN (\'Primary\', \'Billing\')'
																							+ ' LIMIT 1';

	//////////////////////
	// STATIC VARIABLES //
	//////////////////////
	/*
		Database SavePoint used to roll back ALL Renewal Quote records upon failure of ANY code/method being executed in the
		generateRenewalQuoteFromSubscription(Id subscriptionId, Opportunity opportunityId) method
	 */
	private static SavePoint RENEWAL_QUOTE_SAVE_POINT;

	static {
		try {
			DEFAULT_COMM_PROFILE = [SELECT Id, Name FROM zqu__CommunicationProfile__c WHERE Name = 'Default Profile' LIMIT 1];
		} catch(Exception e) {
			ExceptionUtility.consumeException(e, true);
		}
	}

	/**
	 *   Method used to get the Primary Contact Role associated with the Account of the current Opportunity provided. If 
	 *   no results are found a new AccountContactRole is generated to provide a blank value for code to work with.
	 *
	 *   @author Justin
	 *   @date   2017-07-10
	 *   @param  {Id}             opportunityId The opportunity Id that will be used to retrieve the AccountContactRole
	 *   @return {AccountContactRole}           The retrieved AccountContactRole or the empty AccountContactRole
	 */
	public static AccountContactRole retrievePrimaryContactRole(Id opportunityId) {
		try {
			return Database.query(PRIMARY_CONTACT_QUERY.replace('{OPPID}', ':opportunityId'));	
		} catch(Exception e) {
			ExceptionUtility.consumeException(e, true);
			return new AccountContactRole();
		}
	}

	public static zqu__Quote__c generateRenewalQuoteFromSubscription(Id subscriptionId, Opportunity currentOpp) {
		Id opportunityId = currentOpp.Id;
		RENEWAL_QUOTE_SAVE_POINT = Database.setSavepoint();
		Zuora__Subscription__c currentSubscription = Database.query(SUBSCRIPTION_QUERY.replace('{WHERECLAUSE}', 'Id = :subscriptionId'));
		
		List<Zuora__SubscriptionProductCharge__c> subProductChargeList = currentSubscription.Zuora__Subscription_Product_Charges__r;

		//////////////////////////////////////////////
		// DETERMINE IF ASYNCHRONOUS OR SYNCHRONOUS //
		//////////////////////////////////////////////
		// CSP-2323 - Only create quote for Print - No batching required no matter the size of Subscription
		if(subProductChargeList.size() > 3 && currentSubscription.Product_Line__c != 'Print') {
			currentOpp.StageName = 'Generating Quote';
			update currentOpp;

			Approval.LockResult lockResult = Approval.lock(currentOpp.Id);
			System.debug(lockResult);

			Database.executeBatch(new BatchGenerateQuoteRatePlans(subscriptionId, currentOpp), 1);
			return null;
		}

		/*
			Try to query the Primary Contact role associated to the Opportunity AccountId lookup for the Opportunity Id that
			was provided. If this query fails(no primary or billing exists) then log error and instantiate and blank AccountContactRole
			which will cause the code below to populate blank values in Contact lookups.
		 */
		AccountContactRole primaryContactRole = retrievePrimaryContactRole(opportunityId);

		//////////////////
		// CREATE QUOTE //
		//////////////////
		zqu__Quote__c newQuote; 
		try {
			newQuote = generateQuote(currentSubscription, opportunityId, primaryContactRole, true);
		} catch(Exception e) {
			// Nothing to really rollback at this point but better safe than sorry
			Database.rollback(RENEWAL_QUOTE_SAVE_POINT);
			ExceptionUtility.consumeException(e, true);
			throw e;
			return null;	
		}
		
		// CSP-2323 - Only create quote for Print
		if(newQuote.Product_Line__c == 'Print') {
			return newQuote;
		}

		/////////////////////////////////////////////////
		// CREATE QUOTE RATE PLANS && QUOTE AMENDMENTS //
		/////////////////////////////////////////////////
		List<zqu__QuoteRatePlan__c> newQuoteRatePlanList = new List<zqu__QuoteRatePlan__c>();
		Set<String> ratePlansProcessed = new Set<String>();

		Map<String, zqu__ProductRatePlan__c> nameToProductRateNameMap = buildProductRatePlanMap(subProductChargeList);

		for(Integer i = 0; i < subProductChargeList.size(); i++) {
			Zuora__SubscriptionProductCharge__c currentSubProductCharge = subProductChargeList[i];
			// CSP-2167 - Same product but different location
			String uniqueKey = currentSubProductCharge.Zuora__RatePlanName__c + '' + currentSubProductCharge.LocationVendorDynamicsAccountID__c;
			if(!nameToProductRateNameMap.containsKey(currentSubProductCharge.Zuora__RatePlanName__c) || ratePlansProcessed.contains(uniqueKey)) {
				continue;
			}

			zqu__ProductRatePlan__c currentProductRatePlan = nameToProductRateNameMap.get(currentSubProductCharge.Zuora__RatePlanName__c);
			List<zqu__ProductRatePlanCharge__c> productRatePlanChargesList = currentProductRatePlan.R00N40000001mFVKEA2__r;
			
			Map<String, zqu__QuoteAmendment__c> prodRPCIdToQuoteAmendmentMap = new Map<String, zqu__QuoteAmendment__c>();
			for(Integer j = 0; j < productRatePlanChargesList.size(); j++) {
				zqu__ProductRatePlanCharge__c currentProdRatePlanCharge = productRatePlanChargesList[j];

				////////////////////////////
				// CREATE QUOTE AMENDMENT //
				////////////////////////////
				zqu__QuoteAmendment__c newQuoteAmendment = generateQuoteAmendment(newQuote, currentProdRatePlanCharge, currentProductRatePlan, currentSubProductCharge);
				prodRPCIdToQuoteAmendmentMap.put(currentProdRatePlanCharge.Id, newQuoteAmendment);
			}

			// Insert in a FOR loop - Need the Quote Amendment Id's to create the Quote Rate Plan. Unfortunately can't get past
			// this and it is needed. This code will fail with large amounts of data being created - shouldn't be an issue for
			// 99% of the use cases.
			try {
				insert prodRPCIdToQuoteAmendmentMap.values();	
			} catch(Exception e) {
				Database.rollback(RENEWAL_QUOTE_SAVE_POINT);
				ExceptionUtility.consumeException(e, true);
				throw e;
				return null;
			}
			

			for(Integer j = 0; j < productRatePlanChargesList.size(); j++) {
				zqu__ProductRatePlanCharge__c currentProdRatePlanCharge = productRatePlanChargesList[j];
				// Shouldn't be possible - but just in case
				if(!prodRPCIdToQuoteAmendmentMap.containsKey(currentProdRatePlanCharge.Id)) {
					continue;
				}

				zqu__QuoteAmendment__c newQuoteAmendment = prodRPCIdToQuoteAmendmentMap.get(currentProdRatePlanCharge.Id);

				////////////////////////////
				// CREATE QUOTE RATE PLAN //
				////////////////////////////
				// Add Quote Rate Plan to list for insertion
				newQuoteRatePlanList.add(generateQuoteRatePlan(newQuote, newQuoteAmendment, currentProductRatePlan, currentSubProductCharge));
				ratePlansProcessed.add(uniqueKey);
			}
		}

		try {
			insert newQuoteRatePlanList;	
		} catch(Exception e) {
			Database.rollback(RENEWAL_QUOTE_SAVE_POINT);
			ExceptionUtility.consumeException(e, true);
			throw e;
			return null;
		}
		

		List<zqu__QuoteChargeSummary__c> newQuoteChargeSummaryList = new List<zqu__QuoteChargeSummary__c>();
		for(Integer i = 0; i < newQuoteRatePlanList.size(); i++) {
			zqu__QuoteRatePlan__c currentQuoteRatePlan = newQuoteRatePlanList[i];
			if(!nameToProductRateNameMap.containsKey(currentQuoteRatePlan.Name)) {
				continue;
			}

			zqu__ProductRatePlan__c currentProductRatePlan = nameToProductRateNameMap.get(currentQuoteRatePlan.Name);
			List<zqu__ProductRatePlanCharge__c> productRatePlanChargesList = currentProductRatePlan.R00N40000001mFVKEA2__r;
			Map<String, zqu__QuoteRatePlanCharge__c> prodRPCIdToQuoteRatePlanChargeMap = new Map<String, zqu__QuoteRatePlanCharge__c>();

			for(Integer j = 0; j < productRatePlanChargesList.size(); j++) {
				zqu__ProductRatePlanCharge__c currentProdRatePlanCharge = productRatePlanChargesList[j];

				///////////////////////////////////
				// CREATE QUOTE RATE PLAN CHARGE //
				///////////////////////////////////
				zqu__QuoteRatePlanCharge__c newQuoteRatePlanCharge = generateQuoteRatePlanCharge(currentQuoteRatePlan, currentProdRatePlanCharge);
				prodRPCIdToQuoteRatePlanChargeMap.put(currentProdRatePlanCharge.Id, newQuoteRatePlanCharge);				
			}

			// Insert in a FOR loop - Need the Quote Rate Plan Charge Id's to create the Quote Charge Summary. Unfortunately can't get past
			// this and it is needed. This code will fail with large amounts of data being created - shouldn't be an issue for
			// 99% of the use cases.
			try {
				insert prodRPCIdToQuoteRatePlanChargeMap.values();	
			} catch(Exception e) {
				Database.rollback(RENEWAL_QUOTE_SAVE_POINT);
				ExceptionUtility.consumeException(e, true);
				throw e;
				return null;
			}
			

			for(Integer j = 0; j < productRatePlanChargesList.size(); j++) {
				zqu__ProductRatePlanCharge__c currentProdRatePlanCharge = productRatePlanChargesList[j];
				if(!prodRPCIdToQuoteRatePlanChargeMap.containsKey(currentProdRatePlanCharge.Id)) {
					continue;
				}

				zqu__QuoteRatePlanCharge__c newQuoteRatePlanCharge = prodRPCIdToQuoteRatePlanChargeMap.get(currentProdRatePlanCharge.Id);

				/////////////////////////////////
				// CREATE QUOTE CHARGE SUMMARY //
				/////////////////////////////////
				newQuoteChargeSummaryList.add(generateQuoteChargeSummary(currentProdRatePlanCharge, opportunityId, newQuoteRatePlanCharge, currentQuoteRatePlan));
			}
		}

		// Insert the list of all new quote charge summaries
		try {
			insert newQuoteChargeSummaryList;
		} catch(Exception e) {
			Database.rollback(RENEWAL_QUOTE_SAVE_POINT);
			ExceptionUtility.consumeException(e, true);
			throw e;
			return null;
		}

		// CSP-2276 - Need to ensure all quote rate plans and charges align to the Preferred Payment Schedule on the Quote
		try {
			newQuote = ZuoraQuoteChooseNextActionController.RecalculateQuoteCharges(newQuote);	
		} catch(Exception e) {
			XO_Exception__c newException = ExceptionUtility.consumeException(e, false);
			newException.Related_Object_Id__c = newQuote.Id;
			newException.Failure_Area__c = 'Renewal Quote RecalculateQuoteCharges';
			newException.Severity__c = 'Minor';

			insert newException;
		}
		
		// Return the generated Quote to calling code
		return newQuote;
	}

	/**
	 *   Generate a quote given the correct parameters are passed as well as the correct data exists within the object
	 *   parameters.
	 *
	 *   Zuora__Subscription__c object required fields:
	 *   	Name, Sales_Rep__c, Renewal_Rep__c, Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, Preferred_Payment_Schedule__c, 
	 *    Product_Line__c, Payment_Method__c, Zuora__SubscriptionEndDate__c
	 *
	 *   AccountContactRole object required fields:
	 *   	ContactId
	 *
	 *   @author Justin
	 *   @date   2017-03-17
	 *   @param  {Zuora__Subscription__c}        currentSubscription 	The Zuora__Subscription__c object record used to generate a quote
	 *   @param  {Id}        										 opportunityId       	The Opportunity object record Id to be used for association/lookup
	 *   @param  {AccountContactRole}        		 primaryContactRole  	The AccountContactRole which is used to associate the
	 *                                                              	 SoldTo and BillTo Contact lookup fields
	 *   @param  {Boolean}        							 insertRecord        	The boolean flag used to indicate if the record should
	 *                                                        				 be inserted by this method
	 *   @return {zqu__Quote__c}                     								 	The zqu__Quote__c object record which was generated 
	 *                                                             		 by this method
	 */
	public static zqu__Quote__c generateQuote(Zuora__Subscription__c currentSubscription, Id opportunityId, AccountContactRole primaryContactRole, Boolean insertRecord) {
		zqu__Quote__c newQuote = new zqu__Quote__c();

		// Indicate that this quote is renewed from RenewalDashboard and associate this quote to the original subscription
		newQuote.Subscription_Being_Renewed__c = currentSubscription.Id;

		// Associate Quote to Opportunity
		newQuote.zqu__Opportunity__c = opportunityId;

		// Add SoldTo and BillTo Contacts
		newQuote.zqu__BillToContact__c = primaryContactRole.ContactId;
		newQuote.zqu__SoldToContact__c = primaryContactRole.ContactId;

		// Set Renewal Terms
		newQuote.zqu__RenewalTerm__c = 12;
		newQuote.zqu__RenewalSetting__c = 'RENEW_WITH_SPECIFIC_TERM';

		// Set reporting rep to the current running user
		newQuote.Reporting_Rep__c = UserInfo.getUserId();

		newQuote.Name = 'Renewal Quote for Subscription ' + currentSubscription.Name;

		// CSP-2157 - Set the renewal flag to be what the Subscription was
		newQuote.AutoRenewal__c = currentSubscription.AutoRenewal__c;

		// CSP-2171 - Set the Sales Rep as the renewal rep
		newQuote.SalesRepLookup__c = currentSubscription.Renewal_Rep__c;
		newQuote.RenewalRepLookup__c = currentSubscription.Renewal_Rep__c;
		//CSP-2880 Make Invoice Owner field available to certain users
		newquote.zqu__InvoiceOwnerName__c = currentSubscription.Zuora__InvoiceOwner__r.Name;
		newquote.zqu__InvoiceOwnerId__c = currentSubscription.Zuora__InvoiceOwner__r.Zuora__Zuora_Id__c;
		// Get Billing Account Id
		newQuote.zqu__ZuoraAccountID__c = currentSubscription.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c;

		// Hidden Required Fields
		// Hardcoding USD as we do not use any other currency currently
		// Thanks to Jonathan for finding this gem - causes everything to fail if not added
		newQuote.zqu__Currency__c = 'USD';
		newQuote.zqu__BillingMethod__c = 'Email'; 
		newQuote.zqu__InvoiceProcessingOption__c = 'Subscription';
		newQuote.zqu__PaymentTerm__c = 'Due Upon Receipt';
		if(DEFAULT_COMM_PROFILE != null) {
			newQuote.zqu__CommunicationProfile__c = DEFAULT_COMM_PROFILE.Id;	
		}
		newQuote.zqu__Calculate_Quote_Metrics_Through__c = 'EOT';

		newQuote.Preferred_Payment_Schedule__c = currentSubscription.Preferred_Payment_Schedule__c;
		newQuote.Product_Line__c = currentSubscription.Product_Line__c;
		newQuote.Payment_Method__c = currentSubscription.Payment_Method__c;
		newQuote.zqu__PaymentMethod__c = currentSubscription.Payment_Method__c;
		// Default Initial Term to a year(12 months)
		newQuote.zqu__InitialTerm__c = 12;

		/*
			Get the end date of the current subscription - this will be the new quotes start date UNLESS
			that date is somehow in the past(this Subscription has more than likely already ended or will end). In that case
			set the quote start date to today.
		 */
		Date quoteStartDate = currentSubscription.Zuora__SubscriptionEndDate__c;
		if(quoteStartDate < Date.today()) {
			quoteStartDate = Date.today();
		}
		newQuote.zqu__Service_Activation_Date__c = quoteStartDate;
		newQuote.zqu__TermStartDate__c = quoteStartDate;
		newQuote.zqu__StartDate__c = quoteStartDate;

		////////////////////
		// BILL CYCLE DAY //
		////////////////////
		if(String.isNotBlank(currentSubscription.Zuora__CustomerAccount__r.Zuora__BillCycleDay__c)) {
			// regEx to find digits
			Pattern digitRegexPattern = Pattern.compile('(\\d+)');
			// Use the Pattern to create a matcher against the Bill Cycle Day on Billing Account
			Matcher billCycleMatcher = digitRegexPattern.matcher(currentSubscription.Zuora__CustomerAccount__r.Zuora__BillCycleDay__c);
			
			// Determine if a digit was found
			if(billCycleMatcher.find()) {
				// Slap that digit in the Bill Cycle Day on the Quote
				newQuote.zqu__BillCycleDay__c = billCycleMatcher.group();
			} else {
				// Fail safe - set the bill cycle day to the quote start dates day
				newQuote.zqu__BillCycleDay__c = String.valueOf(quoteStartDate.day());
			}
		} else {
			// Fail safe - set the bill cycle day to the quote start dates day
			newQuote.zqu__BillCycleDay__c = String.valueOf(quoteStartDate.day());
		}

		if(insertRecord) {
			insert newQuote;
		}

		return newQuote;
	}

	/**
	 *   Generate a quote amendment given the correct parameters are passed as well as the correct data exists within the
	 *   object parameters.
	 *
	 *   zqu__ProductRatePlanCharge__c object required fields:
	 *   	zqu__ListPrice__c
	 *
	 *   zqu__ProductRatePlan__c object required fields:
	 *   	zqu__Product__r.Name
	 *
	 *   Zuora__SubscriptionProductCharge__c object required fields:
	 *   	Zuora__RatePlanName__c
	 *
	 *   @author Justin
	 *   @date   2017-03-17
	 *   @param  {zqu__Quote__c}                 				newQuote                  Quote used to associate Quote Amendment
	 *   @param  {zqu__ProductRatePlanCharge__c}  			currentProdRatePlanCharge Product Rate Plan Charge used to add the
	 *                                                                         		 List Price of the rate plan charge
	 *   @param  {zqu__ProductRatePlan}                 currentProductRatePlan    Product Rate Plan to get the associated
	 *                                                                             Products name.
	 *   @param  {Zuora__SubscriptionProductCharge__c}  currentSubProductCharge   Subscription Product Charge used to get
	 *                                                                             the Rate Plan Name.
	 *   @return {zqu__QuoteAmendment__c}                           							The Quote Amendment record which is generated
	 */
	public static zqu__QuoteAmendment__c generateQuoteAmendment(zqu__Quote__c newQuote, zqu__ProductRatePlanCharge__c currentProdRatePlanCharge, zqu__ProductRatePlan__c currentProductRatePlan, Zuora__SubscriptionProductCharge__c currentSubProductCharge) {

		zqu__QuoteAmendment__c newQuoteAmendment = new zqu__QuoteAmendment__c();
		newQuoteAmendment.zqu__Quote__c = newQuote.Id;
		newQuoteAmendment.zqu__TotalAmount__c = currentProdRatePlanCharge.zqu__ListPrice__c;
		newQuoteAmendment.zqu__DeltaTCV__c = newQuoteAmendment.zqu__TotalAmount__c * 12;
		newQuoteAmendment.zqu__DeltaMRR__c = newQuoteAmendment.zqu__TotalAmount__c;
		// Other Fields
		newQuoteAmendment.zqu__Type__c = 'NewProduct';
		newQuoteAmendment.zqu__Description__c = 'Added Product ' + currentProductRatePlan.zqu__Product__r.Name + ', RatePlan ' + currentSubProductCharge.Zuora__RatePlanName__c;

		return newQuoteAmendment;
	}

	/**
	 *   Generate a quote rate plan given the correct parameters are passed as well as the correct data exists within the
	 *   object parameters.
	 *
	 *   zqu__ProductRatePlan__c object required fields:
	 *   	zqu__ZuoraId__c, zqu__Product__r.Name
	 *
	 *   Zuora__SubscriptionProductCharge__c object required fields:
	 *   	LocationVendorDynamicsAccountID__c, Discount_Percentage__c
	 *
	 *   @author Justin
	 *   @date   2017-03-17
	 *   @param  {zqu__Quote__c}                				newQuote                The quote used to associate the quote rate plan
	 *   @param  {zqu__QuoteAmendment__c}               newQuoteAmendment       The quote amendment used to associate the quote rate plan
	 *   @param  {zqu__ProductRatePlan__c}              currentProductRatePlan  The product rate plan to associate to the quote rate plan
	 *   @param  {Zuora__SubscriptionProductCharge__c}	currentSubProductCharge The subscription product charge to get the
	 *                                                                         	 previous location id and discount percentage used.
	 *   @return {zqu__QuoteRatePlan__c}                         								The generated Quote Rate Plan
	 */
	public static zqu__QuoteRatePlan__c generateQuoteRatePlan(zqu__Quote__c newQuote, zqu__QuoteAmendment__c newQuoteAmendment, zqu__ProductRatePlan__c currentProductRatePlan, Zuora__SubscriptionProductCharge__c currentSubProductCharge) {
		zqu__QuoteRatePlan__c newQuoteRatePlan = new zqu__QuoteRatePlan__c();
		newQuoteRatePlan.Name = currentSubProductCharge.Zuora__RatePlanName__c;

		newQuoteRatePlan.Zuora_Id_of_Migrated_Charge__c = currentSubProductCharge.Zuora__Zuora_Id__c;

		// Associate Parent Quote
		newQuoteRatePlan.zqu__Quote__c = newQuote.Id;
		// Associate Parent Quote Amendment(Required)
		newQuoteRatePlan.zqu__QuoteAmendment__c = newQuoteAmendment.Id;
		// Set Product Rate Plan Id
		newQuoteRatePlan.zqu__ProductRatePlan__c = currentProductRatePlan.Id;
		newQuoteRatePlan.zqu__ProductRatePlanZuoraId__c = currentProductRatePlan.zqu__ZuoraId__c;
		// Other Fields
		newQuoteRatePlan.zqu__AmendmentType__c = 'NewProduct';
		newQuoteRatePlan.zqu__QuoteProductName__c = currentProductRatePlan.zqu__Product__r.Name;
		// Set Location Id
		newQuoteRatePlan.Location_Vendor__r = new Account(DynamicsAccID__c = currentSubProductCharge.LocationVendorDynamicsAccountID__c);
		// Set Discount - Old Logic
		//newQuoteRatePlan.Discount_Override__c = currentSubProductCharge.Discount_Percentage__c;
		//newQuoteRatePlan.DiscountOverrideModified__c = (newQuoteRatePlan.Discount_Override__c != null && newQuoteRatePlan.Discount_Override__c > 0);
		//
		/* 
			Set Discount Logic 
			CSP-1963 requested to blank of the discount percentage
		*/
		newQuoteRatePlan.Discount_Override__c = 0;
		newQuoteRatePlan.DiscountOverrideModified__c = false;
		return newQuoteRatePlan;
	}

	/**
	 *   Generate a quote rate plan charge given the correct parameters are passed as well as the correct data exists within
	 *   the object parameters.
	 *
	 *	 zqu__QuoteRatePlan__c object required fields:
	 *	 	Zuora_Id_of_Migrated_Charge__c, Discount_Override__c, Location_Vendor__r.DynamicsAccID__c
	 *
	 *   zqu__ProductRatePlanCharge__c object required fields:
	 *   	zqu__ZuoraId__c, zqu__RecurringPeriod__c, zqu__ListPrice__c, zqu__DefaultQuantity__c, zqu__Model__c, 
	 *   	zqu__ListPriceBase__c
	 *   
	 *   @author Justin
	 *   @date   2017-03-17
	 *   @param  {zqu__QuoteRatePlan__c}          currentQuoteRatePlan      The quote rate plan record needed
	 *   @param  {zqu__ProductRatePlanCharge__c}	currentProdRatePlanCharge The product rate plan charge needed
	 *   @return {zqu__QuoteRatePlanCharge__c}                           		The generated quote rate plan charge
	 */
	public static zqu__QuoteRatePlanCharge__c generateQuoteRatePlanCharge(zqu__QuoteRatePlan__c currentQuoteRatePlan, zqu__ProductRatePlanCharge__c currentProdRatePlanCharge) {
		zqu__QuoteRatePlanCharge__c newQuoteRatePlanCharge = new zqu__QuoteRatePlanCharge__c();
		newQuoteRatePlanCharge.Name = currentProdRatePlanCharge.Name;
		// Associate to Parent Quote
		newQuoteRatePlanCharge.zqu__QuoteRatePlan__c = currentQuoteRatePlan.Id;

		// Needs to be the Zuora Id of the Subscription Product and Charge
		newQuoteRatePlanCharge.Zuora_Id_of_Migrated_Charge__c = currentQuoteRatePlan.Zuora_Id_of_Migrated_Charge__c;

		// Set discount - Old Logic
		//newQuoteRatePlanCharge.zqu__Discount__c = currentQuoteRatePlan.Discount_Override__c;
		//newQuoteRatePlanCharge.Discount_Override__c = currentQuoteRatePlan.Discount_Override__c;
		
		/*
			Set Discount Logic
			CSP-1963 - Requested to default all discounts to 0%
		 */
		newQuoteRatePlanCharge.zqu__Discount__c = 0;
		newQuoteRatePlanCharge.Discount_Override__c = 0;

		// Set the Location Id
		newQuoteRatePlanCharge.LocationVendorDynamicsAccountID__c = currentQuoteRatePlan.Location_Vendor__r.DynamicsAccID__c;

		// Associate Product Rate Plan Charge
		newQuoteRatePlanCharge.zqu__ProductRatePlanCharge__c = currentProdRatePlanCharge.Id;
		newQuoteRatePlanCharge.zqu__ProductRatePlanChargeZuoraId__c = currentProdRatePlanCharge.zqu__ZuoraId__c;

		newQuoteRatePlanCharge.zqu__Period__c = currentProdRatePlanCharge.zqu__RecurringPeriod__c;
		newQuoteRatePlanCharge.zqu__Total__c = currentProdRatePlanCharge.zqu__ListPrice__c;
		newQuoteRatePlanCharge.zqu__ListTotal__c = currentProdRatePlanCharge.zqu__ListPrice__c;
		newQuoteRatePlanCharge.zqu__ListPrice__c = currentProdRatePlanCharge.zqu__ListPrice__c;
		newQuoteRatePlanCharge.zqu__Quantity__c = currentProdRatePlanCharge.zqu__DefaultQuantity__c;
		newQuoteRatePlanCharge.zqu__Model__c = currentProdRatePlanCharge.zqu__Model__c;
		newQuoteRatePlanCharge.zqu__ListPriceBase__c = currentProdRatePlanCharge.zqu__ListPriceBase__c;
		// Just setting the prices - the edit line items page will calculate discount
		newQuoteRatePlanCharge.zqu__EffectivePrice__c = currentProdRatePlanCharge.zqu__ListPrice__c;
		newQuoteRatePlanCharge.zqu__ListPrice__c = currentProdRatePlanCharge.zqu__ListPrice__c;
		newQuoteRatePlanCharge.zqu__EffectivePrice__c = currentProdRatePlanCharge.zqu__ListPrice__c;
		// Default to USD - no other currency currently
		newQuoteRatePlanCharge.zqu__Currency__c = 'USD';
		newQuoteRatePlanCharge.zqu__TCV__c = currentProdRatePlanCharge.zqu__ListPrice__c * 12;
		newQuoteRatePlanCharge.zqu__MRR__c = currentProdRatePlanCharge.zqu__ListPrice__c;
		newQuoteRatePlanCharge.zqu__PreviewedMRR__c = currentProdRatePlanCharge.zqu__ListPrice__c;

		// Add charge type
		newQuoteRatePlanCharge.zqu__ChargeType__c = currentProdRatePlanCharge.zqu__Type__c;

		return newQuoteRatePlanCharge;
	}

	/**
	 *   Generate a quote charge summary given the correct parameters are passed as well as the correct data exists within
	 *   the object parameters
	 *
	 *   zqu__ProductRatePlanCharge__c object required fields:
	 *   	zqu__ListPrice__c, zqu__DefaultQuantity__c, zqu__Model__c, zqu__EffectivePrice__c, zqu__RecurringPeriod__c
	 *   	zqu__Type__c
	 *
	 *   zqu__QuoteRatePlan__c object required fields:
	 *   	Discount_Override__c
	 *
	 *   @author Justin
	 *   @date   2017-03-17
	 *   @param  {zqu__ProductRatePlanCharge__c}	currentProdRatePlanCharge The product rate plan charge record needed
	 *   @param  {Id}                     				opportunityId             The opportunity id needed for association
	 *   @param  {zqu__QuoteRatePlanCharge__c}    newQuoteRatePlanCharge    The quote rate plan charge record needed
	 *   @param  {zqu__QuoteRatePlan__c}          currentQuoteRatePlan      The quote rate plan record needed
	 *   @return {zqu__QuoteChargeSummary__c}     		                      The generated quote charge summary
	 */
	public static zqu__QuoteChargeSummary__c generateQuoteChargeSummary(zqu__ProductRatePlanCharge__c currentProdRatePlanCharge, Id opportunityId, zqu__QuoteRatePlanCharge__c newQuoteRatePlanCharge, zqu__QuoteRatePlan__c currentQuoteRatePlan) {
		zqu__QuoteChargeSummary__c newQuoteChargeSummary = new zqu__QuoteChargeSummary__c();
		newQuoteChargeSummary.Name = currentProdRatePlanCharge.Name;
		newQuoteChargeSummary.zqu__EffectivePrice__c = currentProdRatePlanCharge.zqu__ListPrice__c;
		newQuoteChargeSummary.zqu__Quantity__c = currentProdRatePlanCharge.zqu__DefaultQuantity__c;
		newQuoteChargeSummary.zqu__Model__c = currentProdRatePlanCharge.zqu__Model__c;
		newQuoteChargeSummary.zqu__ListPrice__c = currentProdRatePlanCharge.zqu__ListPrice__c;
		newQuoteChargeSummary.zqu__MRR__c = currentProdRatePlanCharge.zqu__ListPrice__c;
		newQuoteChargeSummary.zqu__TCV__c = newQuoteChargeSummary.zqu__EffectivePrice__c * 12;
		newQuoteChargeSummary.zqu__TotalPrice__c = newQuoteChargeSummary.zqu__EffectivePrice__c;
		newQuoteChargeSummary.zqu__ListTotal__c = newQuoteChargeSummary.zqu__EffectivePrice__c;
		newQuoteChargeSummary.zqu__Period__c = currentProdRatePlanCharge.zqu__RecurringPeriod__c;
		newQuoteChargeSummary.zqu__Opportunity__c = opportunityId;
		newQuoteChargeSummary.zqu__QuoteRatePlanCharge__c = newQuoteRatePlanCharge.Id;
		newQuoteChargeSummary.zqu__Type__c = currentProdRatePlanCharge.zqu__Type__c;
		// Set Discount - Old Logic
		//newQuoteChargeSummary.zqu__Discount__c = currentQuoteRatePlan.Discount_Override__c;
		/*
			Set Discount Logic
			CSP-1963 - Requested to default to 0%
		 */
		newQuoteChargeSummary.zqu__Discount__c = 0;
		newQuoteChargeSummary.zqu__QuoteRatePlan__c = currentQuoteRatePlan.Id;

		return newQuoteChargeSummary;
	}

	/**
	 *   Method used to generate a Map which holds to Product Rate Name as the key and then zqu__ProductRatePlan__c record
	 *   as the value.
	 *
	 *   @author Justin
	 *   @date   2017-03-17
	 *   @param  {Zuora__SubscriptionProductCharge__c}    subProductChargeList  The subscription product charge record 
	 *                                                                           needed
	 *   @return {Map<String, zqu__ProductRatePlan__c>}               					The map that was generated
	 */
	public static Map<String, zqu__ProductRatePlan__c> buildProductRatePlanMap(List<Zuora__SubscriptionProductCharge__c> subProductChargeList) {
		Set<String> ratePlanNameSet = new Set<String>();

		for(Integer i = 0; i < subProductChargeList.size(); i++) {
			Zuora__SubscriptionProductCharge__c currentProductCharge = subProductChargeList[i];
			// Reduce rate plan name to 80 - which is the maximum allowed in the Name field for Product Rate Plan
			if(currentProductCharge.Zuora__RatePlanName__c.length() > 80) {
				currentProductCharge.Zuora__RatePlanName__c = currentProductCharge.Zuora__RatePlanName__c.substring(0, 80);
			}
			ratePlanNameSet.add(currentProductCharge.Zuora__RatePlanName__c);
		}

		List<zqu__ProductRatePlan__c> productRatePlanList = Database.query(PRODUCT_RATE_PLAN_QUERY.replace('{WHERECLAUSE}', 'Name IN :ratePlanNameSet'));

		// Create map to store values
		Map<String, zqu__ProductRatePlan__c> nameToProductRateNameMap = new Map<String, zqu__ProductRatePlan__c>();

		// Iterate through product rate plans and store in a map where Name => Object
		for(Integer i = 0; i < productRatePlanList.size(); i++) {
			zqu__ProductRatePlan__c currentProductRatePlan = productRatePlanList[i];
			nameToProductRateNameMap.put(currentProductRatePlan.Name, currentProductRatePlan);
		}

		return nameToProductRateNameMap;
	}
}