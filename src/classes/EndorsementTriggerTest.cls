/**
 * Test Class for : EndorsementTrigger and EndorsementTriggerHandler.
 */
@isTest
private class EndorsementTriggerTest {

    static testMethod void myUnitTest() {
    	List<User> userList = [select Id, Name, Alias from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
    	Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
    	// CSP-1999 Map<String,Schema.RecordTypeInfo> rtBrandMapByName = Schema.SObjectType.Brand__c.getRecordTypeInfosByName();
    	
    	//TestClassUtility.createCBSSCustomSettings();
    	TestClassUtility.createGenerateQuotePdfConfig(true);
    	// CSP-1999 
    	// Brand__c testBrand = TestClassUtility.createBrand(false);
        // testBrand.RecordTypeId = rtBrandMapByName.get('Local').getRecordTypeId();
        // insert testBrand;
        // Region__c testRegion = TestClassUtility.createRegion(true, testBrand);
        Region__c testRegion = TestClassUtility.createRegion(true);
    	 
    	Market__c testMarket = TestClassUtility.createMarket(false);
        testMarket.Market_ID__c = '222';
        testMarket.Active__c = true;
        testMarket.Local_Sales_Region__c = testRegion.id;
        insert testMarket;
    	
        Account testAccount = TestClassUtility.createAccount(false);
        testAccount.BillingPostalCode = '787878';
        testAccount.ShippingPostalCode = '787878';
        testAccount.Region__c = 'Austin/Central Texas/Texas Hill Country';
        testAccount.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
        testAccount.Fulfillment_Data__c = '{ "tier" : "Freemium", "reviewId" : "review Id", "parentGUID" : "", "marketCode" : "222", "categoryId" : "8aa9a07b-fcd8-46ed-a98f-8f3e12689dd2" }';
        testAccount.OwnerId = userList[1].id;
        //testAccount.Fulfill_Storefront__c = true; 
        testAccount.Fulfilled__c = false;
        insert testAccount;
        
        Endorsement__c endObj = TestClassUtility.createEndorsement(true, testAccount);
    }
}