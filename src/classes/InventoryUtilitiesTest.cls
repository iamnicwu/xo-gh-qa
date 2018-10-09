/* 
<class>
	<name>InventoryUtilitiesTest</name>
	<purpose>Test methods for the InventoryUtilities class</purpose>
	<created>
	<by>Jonathan Satterfield</by>
	<date>9/15/2015</date>
	<ticket>SF-1211</ticket>
	</created>
</class>

	Nick CSP-1584 Refactor InventoryUtilitiesTest
*/
@isTest
public class InventoryUtilitiesTest {

	/* 
    <method>
        <name>inventoryUtilities_UnitTest*</name>
        <purpose>Test InventoryUtilities class</purpose>
        <created>
            <by>Scott Yang</by>
            <date>Nov/1/2016</date>
        </created>
    </method>
    */
	private static List<User> userList;
	private static Map<String,Schema.RecordTypeInfo> rtMapByName;
	private static Map<String,Schema.RecordTypeInfo> rtLeadMapByName;
	// CSP-1999 private static Map<String,Schema.RecordTypeInfo> rtBrandMapByName;
	private static Map<String,Schema.RecordTypeInfo> rtOppMapByName;
	private static Deactivate_Trigger__c dtatt;
	private static Generate_Quote_Pdf_Config__c GQPF;
	private static Promise_to_Pay_reminder_config__c PTP;
	// CSP-1999 private static Brand__c testBrand;
	private static Region__c testRegion;
	private static Market__c testMarket;
	private static Category__c testCategory;
	private static MetroArea__c ma;
	private static Zip__c zip;
	private static Account testAccount;
	private static zqu__Quote__c testZquQuote;
	private static Waitlist__c wl; 
	private static Zuora__Subscription__c testZquSubscription;
	private static Zuora__Product__c testZuoraProduct;
	private static Zuora__SubscriptionProductCharge__c testZquSubscriptionProductCharge;
	private static zqu__ProductRatePlan__c testZquProductRatePlan; 
	private static zqu__QuoteRatePlan__c testZquQuoteRatePlan;
	private static zqu__QuoteRatePlanCharge__c testZquQuoteRatePlanCharge;
	private static Inventory__c testInventory;
	private static List<zqu__QuoteRatePlan__c> qrpList =  new List<zqu__QuoteRatePlan__c>();
	private static List<zqu__QuoteRatePlanCharge__c> qrpcList = new List<zqu__QuoteRatePlanCharge__c>();
	private static Map<Id,Boolean> testMap;
	private static Opportunity testOpportunity;

	@isTest static void inventoryUtilities_UnitTest1(){
		createtestData();
		createtestdata2();
		Test.startTest();
		
		//Test IsInventoryAvailable(List<zqu__QuoteRatePlan__c> qrpList) 
		qrpList.add(testZquQuoteRatePlan);
		testMap = InventoryUtilities.IsInventoryAvailable(qrpList, testOpportunity.Id);

		Test.stopTest();
	}


	// Test for (Inventory__c inv : prp.Inventory__r
	@isTest static void inventoryUtilities_UnitTest2(){
		createtestData();
		Test.startTest();
		
		//Create Inventory inv.Quote_Rate_Plan__c != null
		testInventory= TestClassUtility.createInventory(false, testZquProductRatePlan);	 
		testInventory.Subscription_RatePlan_Id__c = 'asdasdasdasdas';
		testInventory.Quote_Rate_Plan__c = testZquQuoteRatePlan.Id;
		testInventory.Subscription_Product_Charge__c= testZquSubscriptionProductCharge.Id;
		insert testInventory;

		//Create Inventory inv.Quote_Rate_Plan__c == null
		Inventory__c testInventory2 = TestClassUtility.createInventory(false, testZquProductRatePlan);	 
		testInventory2.Subscription_RatePlan_Id__c = 'asdasdasdasdas';
		insert testInventory2;

		//Create Inventory inv.Quote_Rate_Plan__c == null, inv.Held_By_Migrated_Subscription__c == True
		Inventory__c testInventory3 = TestClassUtility.createInventory(false, testZquProductRatePlan);	 
		testInventory3.Subscription_RatePlan_Id__c = 'asdasdasdasdas';
		testInventory3.Held_By_Migrated_Subscription__c = true;
		insert testInventory3;

		//Create Inventory inv.Quote_Rate_Plan__c == null, inv.Held_By_Migrated_Subscription__c == True, countOfMigratedInventoryForAccountAndPRP.containsKey(tempMigratedInventoryMapKey)
		Inventory__c testInventory4 = TestClassUtility.createInventory(false, testZquProductRatePlan);	 
		testInventory4.Subscription_RatePlan_Id__c = 'asdasdasdasdas';
		testInventory4.Held_By_Migrated_Subscription__c = true;
		insert testInventory4;

		//Create Inventory inv.Quote_Rate_Plan__c == null, inv.Waitlist_Account__c != null
		Inventory__c testInventory5 = TestClassUtility.createInventory(false, testZquProductRatePlan);	 
		testInventory5.Subscription_RatePlan_Id__c = 'asdasdasdasdas';
		testInventory5.Waitlist_Account__c = testaccount.Id;
		insert testInventory5;

		//Create Inventory inv.Quote_Rate_Plan__c == null, inv.Waitlist_Account__c != null, waitlistInventoryMap.containsKey(tempKey) == true
		Inventory__c testInventory6 = TestClassUtility.createInventory(false, testZquProductRatePlan);	 
		testInventory6.Subscription_RatePlan_Id__c = 'asdasdasdasdas';
		testInventory6.Waitlist_Account__c = testaccount.Id;
		insert testInventory6;

		//Test IsInventoryAvailable(Set<Id> productRatePlanIdSet, Set<Id> quoteRatePlanIdSet)  for (Inventory__c inv : prp.Inventory__r)
		qrpList.add(testZquQuoteRatePlan);
		testMap = InventoryUtilities.IsInventoryAvailable(qrpList, testOpportunity.Id);


		Test.stopTest();

	}

	// SCENARIO 2: there's a "waitlist" Inventory record that the QuoteRatePlan can take control over
	// Test for (zqu__QuoteRatePlan__c qrp : prp.zqu__Quote_Rate_Plans__r)
	@isTest static void inventoryUtilities_UnitTest3(){
		createtestData();
		Test.startTest();
		Inventory__c testInventory7 = TestClassUtility.createInventory(false, testZquProductRatePlan);	 
		testInventory7.Subscription_RatePlan_Id__c = 'asdasdasdasdas';
		testInventory7.Waitlist_Account__c = testaccount.Id;
		insert testInventory7;

		//else if (waitlistInventoryMap.containsKey(tempKey2)), invList.size() == 1
		qrpList.add(testZquQuoteRatePlan);
		testMap = InventoryUtilities.IsInventoryAvailable(qrpList, testOpportunity.Id);

		

		Test.stopTest();
	}

	// SCENARIO 2: there's a "waitlist" Inventory record that the QuoteRatePlan can take control over
	// Test for (zqu__QuoteRatePlan__c qrp : prp.zqu__Quote_Rate_Plans__r)
	@isTest static void inventoryUtilities_UnitTest4(){
		createtestData();
		Test.startTest();
		Inventory__c testInventory8 = TestClassUtility.createInventory(false, testZquProductRatePlan);	 
		testInventory8.Subscription_RatePlan_Id__c = 'asdasdasdasdas';
		testInventory8.Waitlist_Account__c = testaccount.Id;
		insert testInventory8;

		Inventory__c testInventory9 = TestClassUtility.createInventory(false, testZquProductRatePlan);	 
		testInventory9.Subscription_RatePlan_Id__c = 'asdasdasdasdas';
		testInventory9.Waitlist_Account__c = testaccount.Id;
		insert testInventory9;

		//else if (waitlistInventoryMap.containsKey(tempKey2)), invList.size() > 1
		qrpList.add(testZquQuoteRatePlan);
		testMap = InventoryUtilities.IsInventoryAvailable(qrpList, testOpportunity.Id);


		Test.stopTest();

	}

	// SCENARIO 3: check for migrated inventory (CSP-608)
	// Test for (zqu__QuoteRatePlan__c qrp : prp.zqu__Quote_Rate_Plans__r)
	@isTest static void inventoryUtilities_UnitTest5(){
		createtestData();
		Test.startTest();
		//Create Inventory inv.Quote_Rate_Plan__c == null, inv.Held_By_Migrated_Subscription__c == True
		Inventory__c testInventory10 = TestClassUtility.createInventory(false, testZquProductRatePlan);	 
		testInventory10.Subscription_RatePlan_Id__c = 'asdasdasdasdas';
		testInventory10.Held_By_Migrated_Subscription__c = true;
		testInventory10.Subscription_Product_Charge__c = testZquSubscriptionProductCharge.Id;

		insert testInventory10;

		//else if (countOfMigratedInventoryForAccountAndPRP.containsKey(migratedInventoryMapKey)), currentCount.size() == 1
		qrpList.add(testZquQuoteRatePlan);
		testMap = InventoryUtilities.IsInventoryAvailable(qrpList, testOpportunity.Id);


		Test.stopTest();

	}

	// SCENARIO 3: check for migrated inventory (CSP-608)
	// Test for (zqu__QuoteRatePlan__c qrp : prp.zqu__Quote_Rate_Plans__r)
	@isTest static void inventoryUtilities_UnitTest6(){
		createtestData();
		Test.startTest();
		//Create Inventory inv.Quote_Rate_Plan__c == null, inv.Held_By_Migrated_Subscription__c == True
		Inventory__c testInventory10 = TestClassUtility.createInventory(false, testZquProductRatePlan);	 
		testInventory10.Subscription_RatePlan_Id__c = 'asdasdasdasdas';
		testInventory10.Held_By_Migrated_Subscription__c = true;
		testInventory10.Subscription_Product_Charge__c = testZquSubscriptionProductCharge.Id;

		insert testInventory10;

		Zuora__SubscriptionProductCharge__c testZquSubscriptionProductCharge2 = TestClassUtility.createSubscriptionProductCharge(false, testZquSubscription, testZuoraProduct);
		testZquSubscriptionProductCharge2.Zuora__Account__c = testAccount.id;
		testZquSubscriptionProductCharge2.Zuora_Id_of_Migrated_Charge__c = '8675309abcdefghi';
		// different testZquSubscriptionProductCharge Zuora__Zuora_Id__c
		testZquSubscriptionProductCharge2.Zuora__Zuora_Id__c = 'abc789'; 
		insert testZquSubscriptionProductCharge2;

		Inventory__c testInventory11 = TestClassUtility.createInventory(false, testZquProductRatePlan);	 
		testInventory11.Subscription_RatePlan_Id__c = 'asdasdasdasdas';
		testInventory11.Held_By_Migrated_Subscription__c = true;
		testInventory11.Subscription_Product_Charge__c = testZquSubscriptionProductCharge2.Id;
		insert testInventory11;

		//else if (countOfMigratedInventoryForAccountAndPRP.containsKey(migratedInventoryMapKey)), currentCount.size() <> 1
		qrpList.add(testZquQuoteRatePlan);
		testMap = InventoryUtilities.IsInventoryAvailable(qrpList, testOpportunity.Id);

		Test.stopTest();
	}

	// SCENARIO 4: no Inventory record at all; find out if any slots are available
	// Test for (zqu__QuoteRatePlan__c qrp : prp.zqu__Quote_Rate_Plans__r)
	@isTest static void inventoryUtilities_UnitTest7(){
		createtestData();
		Test.startTest();

		testZquProductRatePlan.Capacity__c = '100' ;
		testZquQuoteRatePlan.zqu__AmendmentType__c = 'NewProduct';
		update testZquProductRatePlan;
		update testZquQuoteRatePlan;

		qrpList.add(testZquQuoteRatePlan);
		testMap = InventoryUtilities.IsInventoryAvailable(qrpList, testOpportunity.Id);

		Test.stopTest();

	}

	// Test for (zqu__QuoteRatePlan__c zQRP : finalQRPWithInventoryCheckList) 
	@isTest static void inventoryUtilities_UnitTest8(){
		createtestData();
		Test.startTest();
		// Set zqu__AmendmentType__c = 'NewProduct'
		testZquQuoteRatePlan.zqu__AmendmentType__c = 'NewProduct';
		// Set zQRP.Inventory__r.size() < 0
		testZquProductRatePlan.Capacity__c = '-1' ; 
		update testZquProductRatePlan;
		update testZquQuoteRatePlan;

		qrpList.add(testZquQuoteRatePlan);
		testMap = InventoryUtilities.IsInventoryAvailable(qrpList, testOpportunity.Id);
		Test.stopTest();
	}

	// Test for (zqu__QuoteRatePlan__c zQRP : finalQRPWithInventoryCheckList) 
	@isTest static void inventoryUtilities_UnitTest9(){
		createtestData();
		Test.startTest();
		// Set zqu__AmendmentType__c = 'NewProduct'
		testZquQuoteRatePlan.zqu__AmendmentType__c = 'NewProduct';
		// Set zQRP.Inventory__r.size() < 0
		testZquProductRatePlan.Capacity__c = '-1' ; 
		update testZquProductRatePlan;
		update testZquQuoteRatePlan;

		//Create Inventory inv.Quote_Rate_Plan__c == null, inv.Held_By_Migrated_Subscription__c == True
		Inventory__c testInventory12 = TestClassUtility.createInventory(false, testZquProductRatePlan);	 
		testInventory12.Subscription_RatePlan_Id__c = 'asdasdasdasdas';
		testInventory12.Held_By_Migrated_Subscription__c = true;
		testInventory12.Subscription_Product_Charge__c = testZquSubscriptionProductCharge.Id;

		insert testInventory12;

		qrpList.add(testZquQuoteRatePlan);
		testMap = InventoryUtilities.IsInventoryAvailable(qrpList, testOpportunity.Id);
		Test.stopTest();
	}

	// Test for (zqu__QuoteRatePlan__c zQRP : finalQRPWithInventoryCheckList) 
	@isTest static void inventoryUtilities_UnitTest10(){
		createtestData();
		Test.startTest();



		// Set zqu__AmendmentType__c = 'NewProduct'
		testZquQuoteRatePlan.zqu__AmendmentType__c = 'NewProduct';
		// Set zQRP.Inventory__r.size() < 0
		testZquProductRatePlan.Capacity__c = '-2' ; 
		update testZquProductRatePlan;
		update testZquQuoteRatePlan;


	

		//Create Inventory inv.Quote_Rate_Plan__c == null, inv.Held_By_Migrated_Subscription__c == True
		Inventory__c testInventory12 = TestClassUtility.createInventory(false, testZquProductRatePlan);	 
		testInventory12.Subscription_RatePlan_Id__c = 'asdasdasdasdas';
		testInventory12.Held_By_Migrated_Subscription__c = true;
		testInventory12.Subscription_Product_Charge__c = testZquSubscriptionProductCharge.Id;

		insert testInventory12;

		Zuora__SubscriptionProductCharge__c testZquSubscriptionProductCharge2 = TestClassUtility.createSubscriptionProductCharge(false, testZquSubscription, testZuoraProduct);
		testZquSubscriptionProductCharge2.Zuora__Account__c = testAccount.id;
		testZquSubscriptionProductCharge2.Zuora_Id_of_Migrated_Charge__c = '8675309abcdefghi';
		// different testZquSubscriptionProductCharge Zuora__Zuora_Id__c
		testZquSubscriptionProductCharge2.Zuora__Zuora_Id__c = 'abc111'; 
		insert testZquSubscriptionProductCharge2;

		Inventory__c testInventory13 = TestClassUtility.createInventory(false, testZquProductRatePlan);	 
		testInventory13.Subscription_RatePlan_Id__c = 'asdasdasdasdas';
		testInventory13.Held_By_Migrated_Subscription__c = true;
		testInventory13.Subscription_Product_Charge__c = testZquSubscriptionProductCharge2.Id;
		insert testInventory13;



		qrpList.add(testZquQuoteRatePlan);
		testMap = InventoryUtilities.IsInventoryAvailable(qrpList, testOpportunity.Id);
		Test.stopTest();
	}

	@testSetup
	private static void createtestdata2(){
		//Create Contact
		Contact testContact = TestClassUtility.createContact(false, testAccount);
		testContact.Same_Address_as_Account__c = true;
		insert testContact;

		System.debug(LoggingLevel.INFO, '*** Limits.getQueries():3 ' + Limits.getQueries());

		//Create Quote
		testZquQuote = TestClassUtility.createQuote(false, testOpportunity, testAccount, testContact);
		testZquQuote.Preferred_Payment_Schedule__c = 'Quarter';   
		testZquQuote.zqu__InitialTerm__c = 3;  
		testZquQuote.zqu__StartDate__c = date.today().adddays(1);	   
		testZquQuote.Product_Line__c = 'Print';
		testZquQuote.zqu__Previewed_TCV__c = 7.22;
		insert testZquQuote;
		
		//Create Product
		Product2 testProduct = TestClassUtility.createLocalProduct2(true);
		

		//Create Subscription
		testZquSubscription = TestClassUtility.createSubscription(false, testAccount);
		testZquSubscription.Zuora__Zuora_Id__c = 'abc123';
		testZquSubscription.OriginalSalesforceQuoteID__c = testZquQuote.Id;
		testZquSubscription.Zuora__Version__c =10 ; // Set Zuora__Version__c 
		insert testZquSubscription;
		
		//Create ZuoraProduct
		testZuoraProduct = TestClassUtility.createZuoraProduct(true);

		//Create SubScriptionProduct&Charge
		testZquSubscriptionProductCharge = TestClassUtility.createSubscriptionProductCharge(false, testZquSubscription, testZuoraProduct);
		testZquSubscriptionProductCharge.Zuora__Account__c = testaccount.id;
		testZquSubscriptionProductCharge.Zuora_Id_of_Migrated_Charge__c = '8675309abcdefghi';
		insert testZquSubscriptionProductCharge;
		
		//Create Product Rate Plan(not include price)
		testZquProductRatePlan = TestClassUtility.createProductRatePlan(false); 
		testZquProductRatePlan.Name = 'Rate Plan 1'; 
		testZquProductRatePlan.zqu__Product__c = testProduct.id; 
		testZquProductRatePlan.Capacity__c = '10';
		insert testZquProductRatePlan;
		
		//Create ProductRatePlanCharge(include price)
		zqu__ProductRatePlanCharge__c testZquProductRatePlanCharge = TestClassUtility.createProductRatePlanCharge(false);
		testZquProductRatePlanCharge.zqu__Upto_How_Many_Periods__c = 1;
		insert testZquProductRatePlanCharge; 
		
		//Create QuoteAmendment
		zqu__QuoteAmendment__c testZquQuoteAmendment = TestClassUtility.createQuoteAmendment(true, testZquQuote);
		
		//Create Quote Rate Plan
		testZquQuoteRatePlan = TestClassUtility.createQuoteRatePlan(false, testZquQuote, testZquProductRatePlan, testZquQuoteAmendment);  
		testZquQuoteRatePlan.zqu__Quote__c = testZquQuote.Id;
		insert testZquQuoteRatePlan;

		//Create Quote Rate Plan Charge
		testZquQuoteRatePlanCharge = TestClassUtility.createQuoteRatePlanCharge(false, testZquQuoteRatePlan, testZquProductRatePlanCharge);
		testZquQuoteRatePlanCharge.Location_Vendor__c = testaccount.id;
		insert testZquQuoteRatePlanCharge;
		
		//Create Waitlist(when Inventory run out, put current ProductRatePlan into Waitlist)
		wl = TestClassUtility.createWaitlist(true,testZquProductRatePlan);
	}

	@testSetup
	private static void createtestData(){
		 //Get 2 users
		userList = [select Id, Name, Alias from User where Id != :UserInfo.getUserId() and isActive = true  and ARR__c != null limit 2];
		rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
		rtLeadMapByName = Schema.SObjectType.Lead.getRecordTypeInfosByName();
		// CSP-1999 rtBrandMapByName = Schema.SObjectType.Brand__c.getRecordTypeInfosByName();
		rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();

		if(Deactivate_Trigger__c.getValues('Attachment') == null){
			dtatt = TestClassUtility.createAttachmentDeactivateTriggerSetting(true);
			  
		}
		if(Promise_to_Pay_reminder_config__c.getValues('P2P') == null){
			PTP = TestClassUtility.createPromiseToPayReminderConfig(true);
			
		}

		//Generate PDF(Custom settings)
		GQPF = TestClassUtility.generateQuotePdfConfig(false);
		GQPF.URL__c = 'www.google.com';
		insert GQPF;
		
		// CSP-1999 
		//Create Brand
		// testBrand = TestClassUtility.createBrand(false);
		// testBrand.RecordTypeId = rtBrandMapByName.get('Local').getRecordTypeId();
		// insert testBrand;
		//Create Region
		// testRegion = TestClassUtility.createRegion(true, testBrand);
		testRegion = TestClassUtility.createRegion(true);

		//Create Market
		testMarket = TestClassUtility.createMarket(false);
		testMarket.Market_ID__c = '222';
		testMarket.Active__c = true;
		testMarket.Local_Sales_Region__c = testRegion.id;
		insert testMarket;
		
		// CSP-1999 
		//Create Category
		// testCategory = TestClassUtility.createCategory(true, testBrand);
		testCategory = TestClassUtility.createCategory(true);
		
		//Create MetroArea
		ma = TestClassUtility.createMetroArea(true);
		
		//Create Zip Code 
		zip = TestClassUtility.createZip(false);
		zip.MetroArea__c = ma.id;
		zip.ZipCode__c = '99999';
		zip.name = '12121';
		zip.Local_Market__c = testMarket.id;
		insert zip; 

		System.debug(LoggingLevel.INFO, '*** Limits.getLimitQueries(): ' + Limits.getQueries());

		// CSP-1999 
		//Create Account
		// testAccount = TestClassUtility.createAccount(false, testBrand, testCategory, testMarket);
		testAccount = TestClassUtility.createAccount(false, testCategory, testMarket);
		testAccount.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
		testAccount.Record_Type_Name__c = 'Local';
		testAccount.BU__c = 'Local';
		testAccount.Type = 'Agency';
		testAccount.Operative_Owner__c = userList[0].Name;
		testAccount.Fulfillment_Data__c = '{ "tier" : "Freemium", "reviewId" : "review Id", "parentGUID" : "37e0c6b9-6f4f-4dd4-a3f4-9707e9dc4bbc", "marketCode" : "228", "categoryId" : "8aa9a07b-fcd8-46ed-a98f-8f3e12689dd2" }';
		testAccount.OwnerId = userList[0].Id;
		testAccount.CBBS__c = userList[1].Id;
		testAccount.BillingPostalCode = zip.ZipCode__c;
		testAccount.Operative_Owner__c = userList[0].Name;
		insert testAccount;
		
		System.debug(LoggingLevel.INFO, '*** Limits.getQueries():1 ' + Limits.getQueries());

		//Create Opportunity
		testOpportunity = TestClassUtility.createOpportunity(false);
		testOpportunity.RecordTypeId = rtOppMapByName.get('Local').getRecordTypeId();
		testOpportunity.AccStrategist__c = UserInfo.getUserId();
		testOpportunity.Amount = 50000;
		testOpportunity.OwnerId = UserInfo.getUserId();
		testOpportunity.StageName = 'Prospecting';
		testOpportunity.AccountId = testAccount.Id;
		testOpportunity.CloseDate = Date.Today()-10;
		testOpportunity.Potential_Value_Print__c = 1.23;
		testOpportunity.Potential_Value_Internet__c = 1.23;
		testOpportunity.Potential_Value_Direct_Marketing__c = 1.23;
		testOpportunity.NeedToSendToZBilling__c = false;
		insert testOpportunity;
		
		System.debug(LoggingLevel.INFO, '*** Limits.getQueries():2 ' + Limits.getQueries());

		

	}
}