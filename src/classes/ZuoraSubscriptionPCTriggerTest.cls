@isTest
private class ZuoraSubscriptionPCTriggerTest {
    static testMethod void testMethod1() {
     
        Map<String,SObject> loacalData = TestClassUtility.buildLocalData(true);

   			Test.startTest();
        Zuora__SubscriptionProductCharge__c TestSPC = (Zuora__SubscriptionProductCharge__c)loacalData.get('Zuora__SubscriptionProductCharge__c');
        Inventory__c TestInventory = (Inventory__c)loacalData.get('Inventory__c');
        TestInventory.Subscription_Product_Charge__c = TestSPC.id;
        update TestInventory;
        // Zuora__SubscriptionProductCharge__c TestSPC = loacalData.get('Zuora__SubscriptionProductCharge__c');

        Zuora__Subscription__c testSubscription = (Zuora__Subscription__c)loacalData.get('Zuora__Subscription__c');
        testSubscription.Zuora__Status__c = 'Cancelled';
        testSubscription.Zuora__Version__c = 2;
        update testSubscription;
     		update TestSPC;
     		delete TestSPC;
        Test.stopTest();
    }
    static testMethod void testMethod2() {

    	Inventory_Hold_Expiry_Date_Offsets__c settings = Inventory_Hold_Expiry_Date_Offsets__c.getOrgDefaults();
			settings.Subscription_Product_Charge_Day_Offset__c = 2;
			settings.Account_Day_Offset__c = 2;
			settings.Quote_Rate_Plan_Day_Offset__c =2;
			upsert settings;

 			Test.startTest();
	    List<RecordType> localRecordTypeList = [SELECT Id, Name, SObjectType FROM RecordType WHERE Name LIKE '%local%' AND IsActive = true];
	    Map<String, Id> localRecordTypeMap = new Map<String, Id>();
	    for(Integer i = 0; i < localRecordTypeList.size(); i++) {
	      RecordType currentRecordType = localRecordTypeList[i];
	      localRecordTypeMap.put(currentRecordType.SObjectType, currentRecordType.Id);
	    }

	    Map<String, SObject> objectMap = new Map<String, SObject>();
	    DefaulCBSSValues__c defCBSScustomSetting = new DefaulCBSSValues__c();
	       defCBSScustomSetting.Name = 'InvoiceTemplate';
	       defCBSScustomSetting.Phone__c = '(800)843-4983';
	       defCBSScustomSetting.Email__c = 'theknotaccounting@xogrp.com';
	       insert defCBSScustomSetting;

	    // Create Region
	    // Region__c testRegion = createRegion(true, testBrand);
	    Region__c testRegion = TestClassUtility.createRegion(true);


	    // Create Market
	    Market__c testMarket = TestClassUtility.createMarket(true, testRegion);

	    // Create Category
	    // CSP-1999 Category__c testCategory = createCategory(false, testBrand);
	    Category__c testCategory = TestClassUtility.createCategory(false);
	    if(localRecordTypeMap.containsKey('Category__c')) {
	      testCategory.RecordTypeId = localRecordTypeMap.get('Category__c');
	    }
	    insert testCategory;

	    // Create MetroArea - Not sure where this is used?
	    MetroArea__c testMetroArea = TestClassUtility.createMetroArea(true);
	    objectMap.put('MetroArea__c', testMetroArea);

	    // Create Zip
	    Zip__c testZip = TestClassUtility.createZip(true, testMetroArea, testMarket);

	    // Create Account
	    // CSP-1999
	    // Account testAccount = createAccount(false, testBrand, testCategory, testMarket);
	    Account testAccount = TestClassUtility.createAccount(false, testCategory, testMarket);
	    if(localRecordTypeMap.containsKey('Account')) {
	      testAccount.RecordTypeId = localRecordTypeMap.get('Account');
	    }
	    insert testAccount;

	    // Create Contact
	    Contact testContact = TestClassUtility.createContact(false, testAccount);
	    testContact.MailingPostalCode = testZip.ZipCode__c;
	    insert testContact;

	    // Create Opportunity
	    Opportunity testOpportunity = TestClassUtility.createOpportunity(false, testAccount, testContact);
	    testOpportunity.AccStrategist__c = UserInfo.getUserId();
	    if(localRecordTypeMap.containsKey('Opportunity')) {
	      testOpportunity.RecordTypeId = localRecordTypeMap.get('Opportunity');
	    }
	    insert testOpportunity;

	    Product2 testLocalProduct = TestClassUtility.createLocalProduct2(true);

	     // Create Subscription
	    Zuora__Subscription__c testSubscription = TestClassUtility.createSubscription(false, testAccount);
	    testSubscription.Zuora__Status__c = 'Cancelled';
    	testSubscription.Zuora__Version__c = 2;
    	insert testSubscription;

    	 // Create Quote
	    zqu__Quote__c testQuote = TestClassUtility.createQuote(false, testOpportunity, testAccount, testContact);
	    testQuote.Subscription_Being_Renewed__c = testSubscription.id;
	   	testQuote.zqu__Status__c = 'Sent to Z-Billing';

	    insert testQuote;

	    testSubscription.OriginalSalesforceQuoteID__c = testQuote.id;
	    testSubscription.Zuora__Version__c = 2;
	    update testSubscription;

	    // Create Product Rate Plan
	    zqu__ProductRatePlan__c testProductRatePlan = TestClassUtility.createProductRatePlan(true, testLocalProduct);

	    // Create Zuora Product
	    Zuora__Product__c testZuoraProduct = TestClassUtility.createZuoraProduct(true);

	    // Create Inventory
	    Inventory__c testInventory = TestClassUtility.createInventory(true, testProductRatePlan);

	    zqu__QuoteChargeDetail__c testQCD = new zqu__QuoteChargeDetail__c();
	    testQCD.zqu__ChargeNumber__c = 'test'; 
	    testQCD.Inventory_Freed_By_Cancellation__c = true;
	    // testQCD.Sent_to_ZBilling__c = true;
	    testQCD.zqu__Quote__c = testQuote.id;
	    testQCD.zqu__ProductRatePlan__c = testProductRatePlan.id;
	    insert testQCD;

	    // Create Subscription Product Charge
	    Zuora__SubscriptionProductCharge__c testSubscriptionProductCharge = TestClassUtility.createSubscriptionProductCharge(false, testAccount, testSubscription, testZuoraProduct);
	    testSubscriptionProductCharge.Product_Type__c = 'Transactions';		
	    testSubscriptionProductCharge.TermLessThan12__c = true;		
	    testSubscriptionProductCharge.Zuora__ChargeNumber__c = 'test';				 
	    insert testSubscriptionProductCharge;

    	Test.stopTest();
	}
}