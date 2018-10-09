@isTest
private class BatchCreateInventoryForRenewalQuoteTest {
  static testMethod void testMethod1() {
  	Inventory_Hold_Expiry_Date_Offsets__c invHoldExpDate = Inventory_Hold_Expiry_Date_Offsets__c.getOrgDefaults();
  	Map<String,SObject> testMap = TestClassUtility.buildLocalData(TRUE);
  	
  	Test.startTest();
  	
  	Account testAccount = (Account)testMap.get('Account');
	    
  	Zuora__Subscription__c testSub = TestClassUtility.createSubscription(false, testAccount);
	testSub.Zuora__TermEndDate__c = Date.today().adddays(1);
	insert testSub;
	
	zqu__Quote__c testQuote = (zqu__Quote__c)testMap.get('zqu__Quote__c');
	testQuote.Subscription_Being_Renewed__c = testSub.Id;
	testQuote.zqu__ValidUntil__c = Date.today().adddays(10);
	update testQuote;
	
	
	BatchCreateInventoryForRenewalQuote b = new BatchCreateInventoryForRenewalQuote();
	database.executebatch(b);
	Test.stopTest();
  }
}