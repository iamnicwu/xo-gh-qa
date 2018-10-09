public without sharing class ZuoraQuoteEditLineItemsController extends PageControllerBase
{
	private class productRatePlanForPrintIssue
	{
		public string seasonName = '';
		public string marketName = '';
	}

	//Quote object
	public zqu__Quote__c thisQuote {get; set;}

	public Map<Id, integer> ProductRatePlansAddedToWaitlist = new Map<Id, integer>();
	private List<zqu__QuoteRatePlan__c> quoteRatePlans = new List<zqu__QuoteRatePlan__c>();
	private Map<Id,Boolean> inventoryAvailableForQuoteRatePlan;
	private Id parentAccountId;

	public Boolean loading {get;set;}
	public Boolean someInventoryUnavailable {get;set;}
	public Boolean newDiscountReasonNeeded {get;set;}

	public List<InvalidEmailmsgInner> invalidEmailList {get;set;}

	private String QRP_query;
	private Map<string, List<Schema.FieldSetMember>> productTypeFieldsMap = new Map<string, List<Schema.FieldSetMember>>();
	
	public List<String> suggestedDateReasons {get;set;}{suggestedDateReasons = new List<String>();}
	public boolean ShowSuggestedDateReasons
	{
		get
		{
			if (!someInventoryUnavailable && suggestedDateReasons.size() > 0)
			{
				return true;
			}
			else
			{
				return false;
			}
		}
	}
	
	public boolean QuoteModified = false;

	public Id getQuoteId
	{
		get
		{
			return thisQuote.Id;
		}
	}
	// CSP-1667 display the error message or not
	public boolean isValidLocationEmail{get;set;}
	public boolean hasInvalidLocationEmail{get;set;}
	// CSP-1667 inner class
	public class InvalidEmailmsgInner{
		public String invalidLocationName {get;set;}
		public String invalidLocationURL {get;set;}
	}

	public ZuoraQuoteEditLineItemsController(ApexPages.StandardController standardController) 
	{
		// get the quote from the db
		thisQuote = [Select Id, Name, zqu__TermStartDate__c, zqu__SubscriptionType__c, zqu__Account__c, 
						zqu__Opportunity__c, zqu__Opportunity__r.AccountId, Product_Line__c,zqu__Service_Activation_Date__c, Preferred_Payment_Schedule__c 
					from zqu__Quote__c where Id =:StandardController.getRecord().Id];
		
		// capture the Id of the Quote's parent Account
		parentAccountId = thisQuote.zqu__Account__c;
		
		// get the rate plans from the db.
		// create a list of fields that we ALWAYS need from the query, regardless of whether or not they are in included in the field set
		Map<String, String> fieldMap = new Map<String, String>();
		fieldMap.put('ID', null);
		fieldMap.put('Name', null);
		fieldMap.put('Product_Type__c', null);
		fieldMap.put('zqu__ProductRatePlan__c', null);
		fieldMap.put('zqu__ProductRatePlan__r.Name', null);
		fieldMap.put('zqu__QuoteAmendment__c', null);
		fieldMap.put('zqu__ProductRatePlanZuoraId__c', null);
		fieldMap.put('zqu__Quote__r.zqu__Account__r.Local_Paid_Status__c', null);
		fieldMap.put('zqu__Quote__r.zqu__Account__r.Promotional_Quote__c', null);
		fieldMap.put('Is_Split__c', null);
		fieldMap.put('zqu__Quote__r.Payment_Method__c', null);
		fieldMap.put('zqu__Quote__r.zqu__PaymentMethod__c', null);
		fieldMap.put('zqu__Quote__r.zqu__InitialTerm__c', null);
		fieldMap.put('Account_ID__c', null);
		fieldMap.put('zqu__AmendmentType__c', null);
		fieldMap.put('Steelbrick_Calculated_Discount__c', null);
		fieldMap.put('DiscountOverrideModified__c', null);
		fieldMap.put('Discount_Override__c', null);
		fieldMap.put('Per_Booking_Discount__c', null);
		fieldMap.put('Discount_Reason__c', null);
		fieldMap.put('zqu__Quote__c', null);
		fieldMap.put('zqu__QuoteProductName__c', null);
		fieldMap.put('Location_Vendor__c', null);
		fieldMap.put('zqu__Quote__r.zqu__Account__c', null);
		fieldMap.put('zqu__Quote__r.zqu__Account__r.Name', null);
		fieldMap.put('zqu__ProductRatePlan__r.zqu__Product__c', null);
		fieldMap.put('zqu__ProductRatePlan__r.zqu__Product__r.ProductType__c', null);
		fieldMap.put('zqu__ProductRatePlan__r.Category__c', null);
		fieldMap.put('zqu__ProductRatePlan__r.Market__c', null);
		fieldMap.put('zqu__ProductRatePlan__r.Name', null);
		fieldMap.put('Print_Issue__r.Previous_Issue__c', null);
		fieldMap.put('Print_Issue__r.Name', null);
		fieldMap.put('Print_Issue__r.Publish_1st_Cover_Ship__c', null);
		fieldMap.put('zqu__SubscriptionRatePlanZuoraId__c', null);
		fieldMap.put('zqu__Quote__r.zqu__ExistSubscriptionID__c', null);
		fieldMap.put('zqu__Quote__r.Product_Line__c', null); // Added by CSP-1667, to query the product line of the quote
		fieldMap.put('Zuora_Id_of_Migrated_Charge__c', null);
		
		for (Schema.FieldSetMember f : getAllFieldSetFields())
		{
			fieldMap.put(f.getFieldPath(), null);
		}
		
		string comma = '';
		QRP_query = 'SELECT ';
		for (String f : fieldMap.keyset())
		{
			QRP_query += comma + f;
			comma = ', ';
		}
		
		QRP_query += comma + ' (Select Id, Steelbrick_Calculated_Discount__c, Discount_Reason__c, DiscountOverrideModified__c, Discount_Override__c, zqu__Discount__c from zqu__Quote_Rate_Plan_Charges__r limit 1) ';
		QRP_query += ' from zqu__QuoteRatePlan__c where zqu__AmendmentType__c != \'RemoveProduct\' and zqu__Quote__c = \'' + String.ValueOf(getQuoteID).Left(15) + '\' order by Product_Type__c asc';
		
		quoteRatePlans = Database.Query(QRP_query);
		
		Set<String> subsRatePlanZuoraIdSet = new Set<String>();
		
		// some hackery to fill the discount information from the rate plan charge
		for (zqu__QuoteRatePlan__c qrp : quoteRatePlans)
		{
			if (!qrp.zqu__Quote_Rate_Plan_Charges__r.isEmpty()) {
				qrp.DiscountOverrideModified__c = qrp.zqu__Quote_Rate_Plan_Charges__r[0].DiscountOverrideModified__c;
				
				qrp.Steelbrick_Calculated_Discount__c = qrp.zqu__Quote_Rate_Plan_Charges__r[0].zqu__Discount__c;
				if (!qrp.DiscountOverrideModified__c)
				{
					qrp.Discount_Override__c = qrp.zqu__Quote_Rate_Plan_Charges__r[0].zqu__Discount__c;
				}
				else
				{
					qrp.Discount_Override__c = qrp.zqu__Quote_Rate_Plan_Charges__r[0].Discount_Override__c;
				}
				
				qrp.Discount_Reason__c = qrp.zqu__Quote_Rate_Plan_Charges__r[0].Discount_Reason__c;
			}
			
			if(qrp.zqu__Quote__r.zqu__ExistSubscriptionID__c != null && qrp.zqu__SubscriptionRatePlanZuoraId__c != null){
				subsRatePlanZuoraIdSet.add(qrp.zqu__SubscriptionRatePlanZuoraId__c);
			}

		}
		//CSP - 1476
		updateLocationId(subsRatePlanZuoraIdSet, quoteRatePlans);
			
		// Steve - ported from QuoteRatePlanChargeTrigger, since the code will no longer work there with this page
		/* Commented By Shashish on 27th july, 2017, CSP-1009
		if (fieldMap.ContainsKey('Location_Vendor__c'))
		{
			for (zqu__QuoteRatePlan__c qrp : quoteRatePlans)
			{
				if (qrp.Location_Vendor__c == null)
				{
					qrp.Location_Vendor__c = qrp.zqu__Quote__r.zqu__Account__c;
				}
			}
		}

		*/

		// SF-2014 - Steve
		// Added code here to automatically select the print issue if it's missing for all print products
		// Collect the markets and seasons of the products selected
		if (fieldMap.ContainsKey('Print_Issue__c'))
		{
			Map<id, productRatePlanForPrintIssue> productRatePlanPrintIssueMap = new Map<Id, productRatePlanForPrintIssue>();
			Set<String> marketSet = new Set<String>();
			Set<String> seasonSet = new Set<String>();

			for (zqu__QuoteRatePlan__c qrp : quoteRatePlans)
			{
				System.Debug(qrp.zqu__ProductRatePlan__r.Market__c);
				marketSet.add(qrp.zqu__ProductRatePlan__r.Market__c);
				// parse the rate plan name for the season
				String seasonName = qrp.Name;
				// all names have the format MARKET - SEASON | SIZE or MARKET - SEASON ^ SIZE
				if (seasonName.LastIndexOf(' ^ ') > 0)
				{
					seasonName = seasonName.Left(seasonName.LastIndexOf(' ^ '));
				}
				else if (seasonName.LastIndexOf(' | ') > 0)
				{
					seasonName = seasonName.Left(seasonName.LastIndexOf(' | '));
				}
				seasonName = seasonName.Right(seasonName.Length() - (seasonName.indexOf(' - ') + 3));
				System.Debug(seasonName);
				seasonSet.add(seasonName);
				
				productRatePlanForPrintIssue prppi = new productRatePlanForPrintIssue();
				prppi.seasonName = seasonName;
				prppi.marketName = qrp.zqu__ProductRatePlan__r.Market__c;
				productRatePlanPrintIssueMap.put(qrp.Id, prppi);
			}
			
			// get the print issues from the db that meet the criteria
			List<Print_Issue__c> printIssues = [Select Id, Name, Print_Market__c, Print_Market__r.Zuora_Description__c, Print_Issue__c.Edition__r.Name,
														Previous_Issue__c, Publish_1st_Cover_Ship__c
												from Print_Issue__c
												where Print_Market__r.Zuora_Description__c in :marketSet
												  and Edition__r.Name in : seasonSet];
			
			// loop through the trigger and update the affected records
			for (zqu__QuoteRatePlan__c qrp : quoteRatePlans)
			{
				System.Debug(productRatePlanPrintIssueMap.containsKey(qrp.Id));
				if (qrp.Print_Issue__c == null && productRatePlanPrintIssueMap.containsKey(qrp.Id))
				{
					for (Print_Issue__c pi : printIssues)
					{
						System.Debug('Checking print issue for ' + pi.Print_Market__r.Zuora_Description__c + ' - ' + pi.Edition__r.Name);
						if (pi.Print_Market__r.Zuora_Description__c == productRatePlanPrintIssueMap.get(qrp.id).marketName
						 && pi.Edition__r.Name == productRatePlanPrintIssueMap.get(qrp.Id).seasonName)
						{
							System.Debug('Adding print issue ' + pi.Name + ' to quote rate plan charge ' + qrp.id);
							qrp.Print_Issue__c = pi.Id;
							qrp.Print_Issue__r = pi;
							break;
						}
					}
				}
			}
		}
		
		
		// SF-2031 - Steve
		// Whenever there is a print ad being chosen, search to see if there is a previous print subscription.
		// If one can be found, use that old subscription end date as the suggested Term Start Date.
		// By doing this, a sales rep can automatically align the charges so that the customer continues paying on a monthly basis
			System.Debug('Entering print start date suggestion code');
		if (fieldMap.ContainsKey('Print_Issue__c') && thisQuote.zqu__SubscriptionType__c == 'New Subscription')
		{
			try
			{
				List<Id> previousPrintIssues = new List<Id>();
				for (zqu__QuoteRatePlan__c qrp : quoteRatePlans)
				{
					if (qrp.Print_Issue__c != null && qrp.Print_Issue__r != null && qrp.Print_Issue__r.Previous_Issue__c != null)
					{
						System.Debug('Looking up previous issue: ' + qrp.Print_Issue__r.Previous_Issue__c);
						previousPrintIssues.add(qrp.Print_Issue__r.Previous_Issue__c);
					}
				}
				
				
				Map<String, String> PreviousPrintIssueMap = new Map<String, String>();
				for (zqu__QuoteRatePlan__c qrp : quoteRatePlans)
				{
					if (qrp.Print_Issue__c != null)
					{
						String currentPrintKey = String.ValueOf(qrp.zqu__ProductRatePlan__r.zqu__Product__c).Left(15) + '|' + String.ValueOf(qrp.Print_Issue__c).Left(15);
						PreviousPrintIssueMap.put(currentPrintKey,null);
						
						System.Debug('currentPrintKey = ' + currentPrintKey);

						// next, identify the key for the previous print issue
						String previousPrintKey = null;
						if (qrp.Print_Issue__r.Previous_Issue__c != null)
						{
							previousPrintKey = String.ValueOf(qrp.zqu__ProductRatePlan__r.zqu__Product__c).Left(15) + '|' + String.ValueOf(qrp.Print_Issue__r.Previous_Issue__c).Left(15);
						}
						

						System.Debug('previousPrintKey = ' + previousPrintKey);

						if (!PreviousPrintIssueMap.ContainsKey(previousPrintKey))
						{
							if (thisQuote.zqu__TermStartDate__c.addMonths(6) < qrp.Print_Issue__r.Publish_1st_Cover_Ship__c)
							{
								suggestedDateReasons.add('The issue that you are selling (' + qrp.Print_Issue__r.Name + ') does not publish until ' + qrp.Print_Issue__r.Publish_1st_Cover_Ship__c.format() + '.  We recommend changing your Term Start Date to on or after ' + qrp.Print_Issue__r.Publish_1st_Cover_Ship__c.addmonths(-6).format() + ' so that the customer\'s payments end on the publication date.');
							}
						}
					}
				}
				
				if (previousPrintIssues.size() > 0)
				{
					List<Zuora__SubscriptionProductCharge__c> subscriptionProductChargeList = [select Id, Name, Zuora__Account__c, Print_Issue_Id__c, Zuora__Subscription__c, Zuora__Subscription__r.Name, Zuora__Subscription__r.Zuora__SubscriptionEndDate__c
																							   from Zuora__SubscriptionProductCharge__c
																							   where Print_Issue_Id__c in : previousPrintIssues
																								 and Zuora__Account__c = : thisQuote.zqu__Account__c
																							   order by Print_Issue_Id__c, Zuora__EffectiveEndDate__c desc];
					
					for (zqu__QuoteRatePlan__c qrp : quoteRatePlans)
					{
						
						if (qrp.Print_Issue__c != null && qrp.Print_Issue__r != null && qrp.Print_Issue__r.Previous_Issue__c != null)
						{
							for (Zuora__SubscriptionProductCharge__c spc : subscriptionProductChargeList)
							{
								if (spc.Print_Issue_Id__c == qrp.Print_Issue__r.Previous_Issue__c)
								{
									// If a previous issue was found, we make the assumption that they would not want to be invoiced immediately because this subscription is effectively
									// a "renewal of their old subscription.
									// Therefore, the customer would not need to make a down payment, and we should disable the Invoice Immediately checkbox.
									thisQuote.zqu__GenerateInvoice__c = false;
									QuoteModified = true;
									
									// only make a suggestion if the dates do not align
									if (thisQuote.zqu__TermStartDate__c != spc.Zuora__Subscription__r.Zuora__SubscriptionEndDate__c)
									{
										suggestedDateReasons.add('The previous issue to ' + qrp.Print_Issue__r.Name + ' was purchased by this customer, and that subscription ends on ' + spc.Zuora__Subscription__r.Zuora__SubscriptionEndDate__c.format() + '.  To align charges so that there is no billing overlap, choose a Term Start Date of ' + spc.Zuora__Subscription__r.Zuora__SubscriptionEndDate__c.format() + '.');
										break;
									}
								}
							}
						}
					}
				}
			}
			catch (Exception piExc)
			{
				// no sense blocking the sale if this gets an error.
				System.Debug(piExc);
			}
		}
				
		loading = True;
		someInventoryUnavailable = False;
		newDiscountReasonNeeded = False;

	}
	
	/**
	 *@description: CSP - 1476 , While Amendment populate the location Id on Quote Reat Plan from the existing Subscription.
	 *@param : 		set of rate plan id and List of Quote rate Plan where Location Id needs to be updated.
	 *
	 */
	private static void updateLocationId(Set<String> subsRatePlanZuoraIdSet, List<zqu__QuoteRatePlan__c> quoteRatePlans){
		Map<String, String> quoteRatePlanWithLocationIdMap = new Map<String, String>();
		Map<String, String> accountMap = new Map<String, String>();
		if(subsRatePlanZuoraIdSet.size() > 0){
			// find the subscriptionProductcharge based on the subscritpion Rate plan zuora id from Quote rate plan.
			List<Zuora__SubscriptionProductCharge__c> subsProductChargeList = [SELECT id, Zuora__RatePlanId__c, LocationVendorDynamicsAccountID__c 
																				FROM Zuora__SubscriptionProductCharge__c 
																				WHERE Zuora__RatePlanId__c IN : subsRatePlanZuoraIdSet];
																				
			
			Set<String> locationIdSet = new Set<String>();
			//prepare a map to get location id based on Rateplan id.
			for(Zuora__SubscriptionProductCharge__c subsProdChargeObj : subsProductChargeList){
				// CSP-1598
        // A bug was found where blank/null values were being included and used to find a Location to associate to a
        // Quote Rate Plan. This code will now skip null/blank locations so that they do not get queried.
        if(String.isBlank(subsProdChargeObj.LocationVendorDynamicsAccountID__c)) {
          continue;
        }
        quoteRatePlanWithLocationIdMap.put(subsProdChargeObj.Zuora__RatePlanId__c, subsProdChargeObj.LocationVendorDynamicsAccountID__c);
				locationIdSet.add(subsProdChargeObj.LocationVendorDynamicsAccountID__c);
			}
			
			//Based on Location id, search for an account and store in map to get related Account id.
			if(locationIdSet.size() > 0){
				List<Account> accountList = [SELECT id, DynamicsAccID__c FROM Account WHERE DynamicsAccID__c IN : locationIdSet];
				
				for(Account accObj : AccountList){
					accountMap.put(accObj.DynamicsAccID__c, accObj.id);
				}
				
			}
		}
		
		//use quoteRatePlanWithLocationIdMap and accountMap to find the correct Location id for the QuoteReateplan.
		for (zqu__QuoteRatePlan__c qrp : quoteRatePlans){
			if (qrp.Location_Vendor__c == null && qrp.zqu__Quote__r.zqu__ExistSubscriptionID__c != null 
						&& qrp.zqu__SubscriptionRatePlanZuoraId__c != null && accountMap.size() > 0 
						&& quoteRatePlanWithLocationIdMap.size() > 0){
				
				String locationId = quoteRatePlanWithLocationIdMap.containskey(qrp.zqu__SubscriptionRatePlanZuoraId__c)	 ? 	quoteRatePlanWithLocationIdMap.get(qrp.zqu__SubscriptionRatePlanZuoraId__c) : '';	
				qrp.Location_Vendor__c = locationId != '' && accountMap.containsKey(locationId) ? accountMap.get(locationId) : null;
			}
		}
	}
	

	// return a set of ALL the fields that could potentially be required for a product.
	// we use a set because there may be overlap of fields across product types, and sets automatically remove duplicates
	private Set<Schema.FieldSetMember> getAllFieldSetFields()
	{
		Set<Schema.FieldSetMember> retVal = new Set<Schema.FieldSetMember>();
		retVal.addAll(getPrintFields());
		retVal.addAll(getInternetFields());
		retVal.addAll(getDiscountFields());
		retVal.addAll(getDirectMailFields());
		return retVal;
	}
	
	private List<Schema.FieldSetMember> getPrintFields()
	{
		productTypeFieldsMap.put('Print', SObjectType.zqu__QuoteRatePlan__c.FieldSets.QRP_Edit_Line_Item_Print.getFields());
		return productTypeFieldsMap.get('Print');
	}
	
	private List<Schema.FieldSetMember> getInternetFields()
	{
		productTypeFieldsMap.put('Internet', SObjectType.zqu__QuoteRatePlan__c.FieldSets.QRP_Edit_Line_Item_Internet.getFields());
		return productTypeFieldsMap.get('Internet');
	}

	private List<Schema.FieldSetMember> getDiscountFields()
	{
		productTypeFieldsMap.put('Discount', SObjectType.zqu__QuoteRatePlan__c.FieldSets.QRP_Edit_Line_Item_Discount.getFields());
		return productTypeFieldsMap.get('Discount');
	}

	private List<Schema.FieldSetMember> getDirectMailFields()
	{
		productTypeFieldsMap.put('Direct Mail', SObjectType.zqu__QuoteRatePlan__c.FieldSets.QRP_Edit_Line_Item_Direct_Mail.getFields());
		return productTypeFieldsMap.get('Direct Mail');
	}


	public string getImgUrl()
	{
		string imgDocId = '';
		try
		{
			Document imgDoc = [Select Id from Document d where d.DeveloperName = 'ZuoraTabImage' limit 1];
			imgDocId = imgDoc.Id;
		}
		catch(Exception e) {}
		
		return System.URL.getSalesforceBaseUrl().toExternalForm().replace('https','http')+'/servlet/servlet.ImageServer?id='+imgDocId+'&oid='+UserInfo.getOrganizationId();
	}
	
	// if the page is in a wizard, change the buttons that are displayed
	public boolean getPageIsInWizard()
	{
		// if there's no "next" text, that implies that this page was launched to directly
		if (zqu.QuoteWizardManager.getNextButtonText() == null || zqu.QuoteWizardManager.getNextButtonText() == '')
		{
			return false;
		}
		else
		{
			return true;
		}
		
	}
	

	/* ZUORA NAVIGATION */
	//Global method to retrieve back button text
	public String BackButtonText {
		get {
			if(BackButtonText == null) BackButtonText = zqu.QuoteWizardManager.getBackButtonText();
			return BackButtonText;
		}
		private set;
	}

	//Global method to retrieve next button text
	public String NextButtonText {
		get {
			if(NextButtonText == null) NextButtonText = zqu.QuoteWizardManager.getNextButtonText();
			return NextButtonText;
		}
		private set;
	}

	//Navigation methods
	public PageReference navigateNext() {

		// CSP-1667 set save point at the beginning of the next button
		Savepoint sp = Database.setSavepoint();

		//CSP-2898 Enable Discounts for a Promotional Period (Switch Pitch)
		//add try catch code for catch exception error to page
		try{
			upsert quoteRatePlans;
		}catch (Exception e){
			ApexPages.addMessages(e);
			Database.rollback(sp);
			return null;
		}

		invalidEmailList = new List<InvalidEmailmsgInner>();
		Set<String> invalidIdSet = new Set<String>();
		//CSP-2898 Enable Discounts for a Promotional Period (Switch Pitch)
		//Need to split quote rate plan list when discount is Wedding Wire Switch Pitch
		list<zqu__QuoteRatePlan__c> quoteRatePlanList = new List<zqu__QuoteRatePlan__c>();
		Set<String> productNameLocationIdSet = new Set<String>();
		list<Account> updateAccountList = new List<Account>();
	  Set<Id> accountIdSet = new Set<Id>();
		Integer countStorefront = 0;         
		Integer countFeaturedVendor = 0;
		boolean isUpdateQuote = false;
		// Featured Vendor label
		List<String> featuredVendorList = label.Promotional_Featured_Vendor_Name.split('\r\n');
		// Storefront label
		List<String> storefrontList = label.Promotional_Storefront_Name.split('\r\n');

		for (zqu__QuoteRatePlan__c qrp : quoteRatePlans) {
			
			// CSP-1667 adding invalid location vendor id to set
			if(qrp.zqu__Quote__r.Product_Line__c == 'Internet') {
				invalidIdSet.add(qrp.Location_Vendor__c);

				//CSP-2898 Enable Discounts for a Promotional Period (Switch Pitch)
				//Get all quote rate plan need to spit 
				if(!String.isBlank(qrp.zqu__QuoteProductName__c) 
					&& qrp.Discount_Reason__c == 'Wedding Wire Switch Pitch') {

					  //Product Rate Plan Name and Location Vendor as key for avoid count again 
						String keyString = qrp.zqu__ProductRatePlan__r.Name + qrp.Location_Vendor__c;
					 	System.debug(LoggingLevel.INFO, '*** keyString: ' + keyString);

						//when product is Featured Vendor  
					  if(featuredVendorList.contains(qrp.zqu__QuoteProductName__c)) {
					  	
					  	//avoid count again when the same quote rate plan 
					  	if(!productNameLocationIdSet.contains(keyString)) {
					  		countStorefront += 1;
					  		productNameLocationIdSet.add(keyString);
					  	}
					  	
					  	//if quote rate plan has splited
					  	if(!qrp.Is_Split__c) { 
					  	  quoteRatePlanList.add(qrp);
					  	  isUpdateQuote = true;
					  	  //When new Account has promotional Quote, should update Account 
					  	  if(String.isBlank(qrp.zqu__Quote__r.zqu__Account__r.Promotional_Quote__c)) {
					  	  	accountIdSet.add(qrp.Account_ID__c);
					  	  }
					    }
					  }
					  //when product is Storefront    
					  else if(storefrontList.contains(qrp.zqu__QuoteProductName__c)) {

					  	//avoid count again when the same quote rate plan 
					  	if(!productNameLocationIdSet.contains(keyString)) {
					  		countFeaturedVendor += 1; 
					  		productNameLocationIdSet.add(keyString);
					  	}
					  	
					  	//if quote rate plan has splited
					  	if(!qrp.Is_Split__c) { 
					  	  quoteRatePlanList.add(qrp);
					  	  isUpdateQuote = true;

					  	  //When Account has frist promotional Quote, should update Account 
					  	  if(String.isBlank(qrp.zqu__Quote__r.zqu__Account__r.Promotional_Quote__c)) {
					  	  	accountIdSet.add(qrp.Account_ID__c);
					  	  }
					    }
					  }
				}
			}
		}
		//CSP-2898 Enable Discounts for a Promotional Period (Switch Pitch)
		//only apply the promotion to 1 standard storefront and 1 featured vendor
		if(countStorefront > 1 || countFeaturedVendor > 1) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, label.Promotion_Product_Limits));
			Database.rollback(sp);
			return null;
		}

		System.debug(LoggingLevel.INFO, '*** quoteRatePlanList: ' + quoteRatePlanList);
		// CSP-1667 get all the invalid email accounts
		//CSP-2898 Enable Discounts for a Promotional Period (Switch Pitch)
		//add Account to select for update Promotional Account
		Map<String,Account> invalidMap = new Map<String, Account>([SELECT Id, Name, Email__c, Promotional_Quote__c FROM Account 
																												WHERE RecordType.Name = 'Local' 
																												AND ((Id IN: invalidIdSet  
																												AND (Email__c = '' OR Email__c = null))  
																												OR  Id IN: accountIdSet)]);

		// CSP-1667 store the invalid email into list
		for(Account acc : invalidMap.values()){
			if(invalidIdSet.contains(acc.id) && string.isBlank(acc.Email__c)) {
				InvalidEmailmsgInner iem = new InvalidEmailmsgInner();
				iem.invalidLocationName = acc.Name;
				iem.invalidLocationURL = System.URL.getSalesforceBaseUrl().toExternalForm() + '/'+ acc.Id;
				invalidEmailList.add(iem);
			}
			//CSP-2898 Enable Discounts for a Promotional Period (Switch Pitch)
			//add Promotional Account flag to Account for avoid create two times Promotional quote before send to zuora 
			if(accountIdSet.contains(acc.id)) {
				acc.Promotional_Quote__c = thisQuote.id;
				updateAccountList.add(acc);
			}
		}
		//CSP-2898 Enable Discounts for a Promotional Period (Switch Pitch)
		//Update Account Promotional Account remark have Promotional 
		if(!updateAccountList.isEmpty()) {
    	update updateAccountList;
		}
		// CSP-1667 if there any invalid account emails then return to error messages
		if(!invalidEmailList.isEmpty()){
			hasInvalidLocationEmail = true;
			Database.rollback(sp);
			// return ApexPages.currentPage();
			return null;
		}
		updateDiscounts();
		if (ShowSuggestedDateReasons || QuoteModified || isUpdateQuote)
		{
			// make sure that the customer acceptance date is valid
			thisQuote.zqu__Customer_Acceptance_Date__c = thisQuote.zqu__TermStartDate__c;

			//CSP-2898 Enable Discounts for a Promotional Period (Switch Pitch)
			//add flag to Quote for Promotional
			if(isUpdateQuote){
				thisQuote.Promotional_Quote__c = true;
			}

			update thisQuote;
		}
		if (newDiscountReasonNeeded) {
			// return ApexPages.currentPage();
			return null;
		}
		else {
			setApprovalProcessFlagDiscountAmountOnQuote();
			//CSP-2898 Enable Discounts for a Promotional Period (Switch Pitch)
			//spilt quote rate plan, quote amendment and so on 
			if(!quoteRatePlanList.isEmpty()) {
				boolean hasDmlError = spiltPromotionalData(quoteRatePlanList, thisQuote, sp);
				// Stop next page if has DML exception
				if(hasDmlError){
					return null;
				}
			}
			Map<String, String> customUrlParameters = new Map<String, String>{'Id' => thisQuote.Id};
			return zqu.QuoteWizardManager.navigateNext(customUrlParameters);
		}
	}
 
	public PageReference navigateBack() {
		Map<String, String> customUrlParameters = new Map<String, String>{'Id' => thisQuote.Id,
																	 'oppId' => thisQuote.zqu__Opportunity__c};
		return zqu.QuoteWizardManager.navigateBack(customUrlParameters);
	}
 
	//If the user clicks cancel, use global method to delete all quote information and navigate back to the Opportunity page
	public PageReference cancel() {
		return zqu.QuoteWizardManager.cancel('/' + thisQuote.zqu__Opportunity__c);
	}
	
	public PageReference standaloneCancel()
	{
		return new PageReference('/' + getQuoteId);
	}
	
	public PageReference standaloneSave()
	{
		upsert quoteRatePlans;
		updateDiscounts();
		return standaloneCancel();
	}
	/* End ZUORA NAVIGATION */
	
	public void updateDiscounts() {
	
		// the DiscountOverrideModified__c boolean is set to true to maintain the new Discount_Override__c value between page loads
		// (otherwise the Discount_Override__c field is set to the value that Steelbrick calculated)
		// this boolean is reset to False after the page reloads

		Boolean returnNullFlag = False;
		for (zqu__QuoteRatePlan__c ratePlanRecord : quoteRatePlans) {
			if (ratePlanRecord.Steelbrick_Calculated_Discount__c != ratePlanRecord.Discount_Override__c) {
				ratePlanRecord.DiscountOverrideModified__c = True;

				// throw error prompting user to select a different Discount Reason, then return null
				if ((ratePlanRecord.Steelbrick_Calculated_Discount__c < ratePlanRecord.Discount_Override__c) && ratePlanRecord.Discount_Reason__c.containsIgnoreCase('autocalculated')) {
					returnNullFlag = True;
				}
			}
		}

		// TODO: is this necessary still?
		update quoteRatePlans;

		// problem with page reload, seems to be due to Zuora components
		// workaround is to requery/reset the quoteRatePlanCharges
		quoteRatePlans = Database.Query(QRP_query);
		if (returnNullFlag) {
			this.newDiscountReasonNeeded = True;
		}
		else {
			this.newDiscountReasonNeeded = False;
		}	
	}


	// SF-1336
	private void setApprovalProcessFlagDiscountAmountOnQuote() {
		Map<Id,Boolean> quoteIDToApprovalProcessFlagDiscountAmountBooleanMap = new Map<Id,Boolean>();
		for (zqu__QuoteRatePlan__c qrpRec : quoteRatePlans) {
			// if not in map, add Quote Id (key) and boolean to map
			// for the boolean, if Discount_Override__c > Steelbrick_Calculated_Discount__c put True, otherwise put False
			if (!quoteIDToApprovalProcessFlagDiscountAmountBooleanMap.containsKey(qrpRec.zqu__Quote__c)) {
				if (qrpRec.Discount_Override__c > qrpRec.Steelbrick_Calculated_Discount__c) {
					quoteIDToApprovalProcessFlagDiscountAmountBooleanMap.put(qrpRec.zqu__Quote__c,True);
				}
				else {
					quoteIDToApprovalProcessFlagDiscountAmountBooleanMap.put(qrpRec.zqu__Quote__c,False);
				}
			}
			// if it does contain the key and the value is True, don't do anything.
			// if it does contain the key and the value is False, and if Discount_Override__c > Steelbrick_Calculated_Discount__c, replace the value with True
			else if (quoteIDToApprovalProcessFlagDiscountAmountBooleanMap.get(qrpRec.zqu__Quote__c) == False){
				if (qrpRec.Discount_Override__c > qrpRec.Steelbrick_Calculated_Discount__c) {
					quoteIDToApprovalProcessFlagDiscountAmountBooleanMap.put(qrpRec.zqu__Quote__c,True);
				}
			}
		}

		// then, update the parent Quote records
		List<zqu__Quote__c> parentQuoteList = [SELECT Id, Approval_Process_Flag_Discount_Amount__c FROM zqu__Quote__c WHERE Id IN :quoteIDToApprovalProcessFlagDiscountAmountBooleanMap.keySet()];
		for (zqu__Quote__c parentQuote : parentQuoteList) {
			parentQuote.Approval_Process_Flag_Discount_Amount__c = quoteIDToApprovalProcessFlagDiscountAmountBooleanMap.get(parentQuote.Id);
		}

		update parentQuoteList;
	}

	/* 
	 * Begin MODAL WAITLIST CODE
	 * This section is needed in order to control the modal window.  Keep in mind this only works if you extend this class with PageControllerBase 
	 */
	
	public WaitlistModalController myWaitlistModalController {get;set;} 
	public String SelectedRatePlanIdForWaitlistModal {get;set;} {SelectedRatePlanIdForWaitlistModal = '';}
	//public String AccountIdForWaitlistModal {get;set;} {AccountIdForWaitlistModal = '';}

	public void ViewWaitlist() {
		myWaitlistModalController.OpenModal(SelectedRatePlanIdForWaitlistModal);
	}
	
	public override void setComponentController(ComponentControllerBase compController) {
		myWaitlistModalController = (WaitlistModalController)compController;
	}

	public override ComponentControllerBase getMyComponentController() {
		return myWaitlistModalController;
	}
	/* 
	 * End MODAL WAITLIST CODE 
	 */	

	public void addToWaitlist() {
		myWaitlistModalController.SaveNewWaitlist(SelectedRatePlanIdForWaitlistModal, parentAccountId);
		integer waitlistPosition = myWaitlistModalController.WaitlistSizeByProductRatePlanId.get(SelectedRatePlanIdForWaitlistModal.left(15));
		ProductRatePlansAddedToWaitlist.put(SelectedRatePlanIdForWaitlistModal, waitlistPosition);
	}


	public List<RatePlanWrapper> getRatePlanList() 
	{
		List<RatePlanWrapper> retVal = new List<RatePlanWrapper>();
		
		for (zqu__QuoteRatePlan__c qrp : quoteRatePlans)
		{
			RatePlanWrapper rpWrapper;
			boolean invAvailable = false;
			// CSP-1963
			if(String.isNotBlank(qrp.Zuora_Id_of_Migrated_Charge__c)) {
				invAvailable = true;
			} 

			if (loading != True && inventoryAvailableForQuoteRatePlan.containsKey(qrp.Id)) {
				invAvailable = inventoryAvailableForQuoteRatePlan.get(qrp.Id);
			}

			// create the wrapper
			rpWrapper = new RatePlanWrapper(qrp, null, invAvailable);
			if (ProductRatePlansAddedToWaitlist.ContainsKey(qrp.zqu__ProductRatePlan__c)) {
				rpWrapper.waitlistNumber = ProductRatePlansAddedToWaitlist.get(qrp.zqu__ProductRatePlan__c);
			}
			
			retVal.add(rpWrapper);
		}
	
		return retVal;
	}
	

	public class RatePlanWrapper {
		public zqu__QuoteRatePlan__c RatePlan {get;set;}
		public List<zqu__QuoteRatePlanCharge__c> RatePlanCharges {get;set;}
		public Boolean hasInventory {get;set;}
		public String productType {get;set;}
		public String accountId {get;set;}
		public Integer waitlistNumber {get;set;} {waitlistNumber = 0;}
		
		public RatePlanWrapper(zqu__QuoteRatePlan__c qrp, list<zqu__QuoteRatePlanCharge__c> qrpCharges, boolean inventoryAvailable) {
			this.RatePlan = qrp;
			this.RatePlanCharges = qrpCharges;
			this.hasInventory = inventoryAvailable;
			this.productType = qrp.Product_Type__c;
		}
	}


	public void checkInventory() {
		inventoryAvailableForQuoteRatePlan = InventoryUtilities.IsInventoryAvailable(quoteRatePlans, thisQuote.zqu__Opportunity__c);
		loading = False;
		// check to see if there's any Inventory that isn't available
		// if so, we need to set a flag to prevent the user from moving one until it's removed
		for (Boolean bool : inventoryAvailableForQuoteRatePlan.values()) {
			if (!bool) {
				someInventoryUnavailable = True;
				break;
			}
		}
		System.debug(LoggingLevel.INFO, '*** quoteRatePlans: ' + quoteRatePlans);
		update quoteRatePlans;
	}

  /**
   * CSP-2898 Enable Discounts for a Promotional Period (Switch Pitch)
   * spilt quote rate plan, quote amendment and so on 
   * 
   * @Author Mason
   * @Date   2018-07-05
   * @param  quoteRatePlanList, thisQuote, sp
   * @return boolean
   *
   */
  public static boolean spiltPromotionalData(list<zqu__QuoteRatePlan__c> quoteRatePlanList, zqu__Quote__c thisQuote, Savepoint sp) {
  	String soql;
		List<Id> quoteAmendmentIdList = new List<Id>();
		List<Id> quoteRatePlanIdList = new List<Id>();
		list<quoteRatePlanWrapper> quoteRatePlanWrapperList = new List<quoteRatePlanWrapper>();	

		//Get all Quote Amendment id and Quote Rate Plan id 
		for(zqu__QuoteRatePlan__c currentQRP : quoteRatePlanList) {
			currentQRP.Is_Split__c = true;
			quoteAmendmentIdList.add(currentQRP.zqu__QuoteAmendment__c);
			quoteRatePlanIdList.add(currentQRP.id);
			quoteRatePlanWrapper wrap = new quoteRatePlanWrapper();
			wrap.quoteRatePlan = currentQRP;
			quoteRatePlanWrapperList.add(wrap);
		}
		//update original Quote Rate Plan
		try {
			update quoteRatePlanList;
		} catch(Exception e) {
			ApexPages.addMessages(e);
			Database.rollback(sp);
			return true;
		}

		//Get Quote Amendment from Datebase
		soql = getCreatableFieldsSOQL('zqu__QuoteAmendment__c','id IN : quoteAmendmentIdList');
		List<zqu__QuoteAmendment__c> originalQuoteAmendment = Database.query(soql);

		// put in original Quote Amendment to Wrapper
		for(zqu__QuoteAmendment__c quoteAmendment : originalQuoteAmendment) {
			for(quoteRatePlanWrapper wrap : quoteRatePlanWrapperList) {
				if(wrap.quoteRatePlan.zqu__QuoteAmendment__c == quoteAmendment.id) {
					wrap.quoteAmendment = quoteAmendment;
				}
			}
		}

		//get Quote Rate Plan Charge from datebase
		soql = getCreatableFieldsSOQL('zqu__QuoteRatePlanCharge__c','zqu__QuoteRatePlan__c IN : quoteRatePlanIdList');
		List<zqu__QuoteRatePlanCharge__c> originalQRPC = Database.query(soql);

		// put in original Quote Rate Plan Charge to Wrapper
		for(zqu__QuoteRatePlanCharge__c QRPC : originalQRPC) {
			for(quoteRatePlanWrapper wrap : quoteRatePlanWrapperList){
				if(wrap.quoteRatePlan.id == QRPC.zqu__QuoteRatePlan__c) {
					wrap.quoteRatePlanCharge = QRPC;
				}
		  }
		}
		//Get Quote Charge Summary from Datebase
		soql = getCreatableFieldsSOQL('zqu__QuoteChargeSummary__c','zqu__QuoteRatePlan__c IN : quoteRatePlanIdList');
		List<zqu__QuoteChargeSummary__c> originalQCS = Database.query(soql);

		// put in original Quote Charge Summary to Wrapper
		for(zqu__QuoteChargeSummary__c QCSObj : originalQCS) {
			for(quoteRatePlanWrapper wrap : quoteRatePlanWrapperList){
				if(wrap.quoteRatePlan.id == QCSObj.zqu__QuoteRatePlan__c) {
					wrap.quoteChargeSummary = QCSObj;
				}
		  }
		}

		System.debug(LoggingLevel.INFO, '*** quoteRatePlanWrapperList: ' + quoteRatePlanWrapperList);
		List<zqu__QuoteRatePlan__c> cloneQuoteRatePlanList = new List<zqu__QuoteRatePlan__c>();
		List<zqu__QuoteAmendment__c> cloneQuoteAmendmentList = new List<zqu__QuoteAmendment__c>();
		List<zqu__QuoteRatePlanCharge__c> cloneQuoteRatePlanChargeList = new List<zqu__QuoteRatePlanCharge__c>();
		List<zqu__QuoteChargeSummary__c> cloneQuoteChargeSummaryList = new List<zqu__QuoteChargeSummary__c>();
		// clone new bundle object 
		list<quoteRatePlanWrapper> cloneQuoteRatePlanWrapperList = quoteRatePlanWrapperList.clone();

		//update original Quote Rate Plan Charge field Trigger Event and Trigger Date
		List<zqu__QuoteRatePlanCharge__c> updateQuoteRatePlanChargeList = new List<zqu__QuoteRatePlanCharge__c>();
	  for(quoteRatePlanWrapper originalwrap : quoteRatePlanWrapperList) {
	  	originalwrap.quoteRatePlanCharge.zqu__Discount__c = 0;
	  	originalwrap.quoteRatePlanCharge.zqu__TriggerEvent__c = 'SpecificDate';
		  originalwrap.quoteRatePlanCharge.zqu__TriggerDate__c = thisQuote.zqu__Service_Activation_Date__c.addMonths(integer.valueOf(label.Promotional_Month));
		  updateQuoteRatePlanChargeList.add(originalwrap.quoteRatePlanCharge);
	  }

	  try {
	  	//update original Quote Rate Plan Charge
			update updateQuoteRatePlanChargeList;
		} catch(Exception e) {
			ApexPages.addMessages(e);
			Database.rollback(sp);
			return true;
		}
	  
	  //clone quote Amendment
		for(quoteRatePlanWrapper wrap : cloneQuoteRatePlanWrapperList) {
			wrap.quoteAmendment.id = null;
			cloneQuoteAmendmentList.add(wrap.quoteAmendment);
		}

		try {
			//insert clone quote amendment 
			insert cloneQuoteAmendmentList;
		} catch(Exception e) {
			ApexPages.addMessages(e);
			Database.rollback(sp);
			return true;
		}

		//cloned quote Rate Plan
		for(quoteRatePlanWrapper wrap : cloneQuoteRatePlanWrapperList) {
			wrap.quoteRatePlan.id = null;
			wrap.quoteRatePlan.Is_Clone__c = true;
			wrap.quoteRatePlan.zqu__QuoteAmendment__c = wrap.quoteAmendment.id;
	  	cloneQuoteRatePlanList.add(wrap.quoteRatePlan);
		}

		try {
			//insert cloned quote Rate Plan
			insert cloneQuoteRatePlanList;
		} catch(Exception e) {
			ApexPages.addMessages(e);
			Database.rollback(sp);
			return true;
		}

		//cloned quote Rate Plan Charge
		for(quoteRatePlanWrapper wrap : cloneQuoteRatePlanWrapperList) {
			wrap.quoteRatePlanCharge.id = null;
			wrap.quoteRatePlanCharge.zqu__Discount__c = 100;
			wrap.quoteRatePlanCharge.zqu__ListPrice__c = 0;
			wrap.quoteRatePlanCharge.List_Price__c = '0';
			wrap.quoteRatePlanCharge.zqu__EndDateCondition__c = 'Specific End Date';	
			wrap.quoteRatePlanCharge.zqu__SpecificEndDate__c = thisQuote.zqu__Service_Activation_Date__c.addMonths(integer.valueOf(label.Promotional_Month));
			wrap.quoteRatePlanCharge.zqu__TriggerEvent__c = null;
		  wrap.quoteRatePlanCharge.zqu__TriggerDate__c = null;
			wrap.quoteRatePlanCharge.zqu__QuoteRatePlan__c = wrap.quoteRatePlan.id;
	  	cloneQuoteRatePlanChargeList.add(wrap.quoteRatePlanCharge);
		}
		try {
			//insert cloned quote Rate Plan Charge
			insert cloneQuoteRatePlanChargeList;
			System.debug(LoggingLevel.INFO, '*** cloneQuoteRatePlanChargeList: ' + cloneQuoteRatePlanChargeList);
		} catch(Exception e) {
			ApexPages.addMessages(e);
			Database.rollback(sp);
			return true;
		}

		//cloned Quote Charge Summary
		for(quoteRatePlanWrapper wrap : cloneQuoteRatePlanWrapperList) {
			wrap.quoteChargeSummary.id = null;
			wrap.quoteChargeSummary.zqu__QuoteRatePlan__c = wrap.quoteRatePlan.id;
			wrap.quoteChargeSummary.zqu__QuoteRatePlanCharge__c = wrap.quoteRatePlanCharge.id;
	  	cloneQuoteChargeSummaryList.add(wrap.quoteChargeSummary);
		}
		try {
			//insert cloned Quote Charge Summary
			insert cloneQuoteChargeSummaryList;
		} catch(Exception e) {
			ApexPages.addMessages(e);
			Database.rollback(sp);
			return true;
		}
		// retrun false if have no DML exception 
		return false;
  }


  /**
   * CSP-2898 Enable Discounts for a Promotional Period (Switch Pitch)
   * Returns a dynamic SOQL statement for the whole object, includes only creatable fields since we will be inserting a cloned result of this query
   * 
   * @Author Mason
   * @Date   2018-07-05
   * @param  objectName, whereClause
   * @return String
   *
   */
  public static string getCreatableFieldsSOQL(String objectName, String whereClause) {
         
      String selects = '';
       
      if (string.isBlank(whereClause)) { 
      	return null; 
      }
       
      // Get a map of field name and field token
      Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();
      list<string> selectFieldsList = new list<string>();
       
      if (fieldMap != null) {
          for (Schema.SObjectField ft : fieldMap.values()) {         // loop through all field tokens (ft)
              Schema.DescribeFieldResult fd = ft.getDescribe();      // describe each field (fd)
              if (fd.isCreateable()) {                               // field is creatable
                  selectFieldsList.add(fd.getName());
              }
          }
      }
       
      if (!selectFieldsList.isEmpty()) {
          for (string s : selectFieldsList) {
              selects += s + ',';
          }
          if (selects.endsWith(',')) {
          	selects = selects.substring(0, selects.lastIndexOf(','));
          }
      }
       
      return 'SELECT ' + selects + ' FROM ' + objectName + ' WHERE ' + whereClause;
  }

  //CSP-2898 Enable Discounts for a Promotional Period (Switch Pitch)
  //used to wrap promotional data 
  public class quoteRatePlanWrapper {
  	zqu__QuoteAmendment__c quoteAmendment;
  	zqu__QuoteRatePlan__c quoteRatePlan;
  	zqu__QuoteRatePlanCharge__c quoteRatePlanCharge;
  	zqu__QuoteChargeSummary__c quoteChargeSummary;
  }

}