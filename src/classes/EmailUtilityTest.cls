@isTest
private class EmailUtilityTest {
	@testSetup static void testSetupData(){
		TestClassUtility.generateQuotePdfConfig(true);
	}

    static testMethod void testCreateTwoDayContractEmail() {
        Opportunity testOpp = TestClassUtility.createOpportunity(true);

        Test.startTest();
		Messaging.SingleEmailMessage emailResponse = EmailUtility.createTwoDayContractEmail(testOpp);
		Test.stopTest();

        System.assert(emailResponse != null);
    }

    static testMethod void testCreateExpiredContractEmail() {
        Opportunity testOpp = TestClassUtility.createOpportunity(true);

        Test.startTest();
        Messaging.SingleEmailMessage emailResponse = EmailUtility.createExpiredContractEmail(testOpp);
        Test.stopTest();

        System.assert(emailResponse != null);
    }

    static testMethod void testCreateWaitListOnDeckEmail() {
		Product2 testProduct = TestClassUtility.createLocalProduct2(true);
    	zqu__ProductRatePlan__c testProductRatePlan = TestClassUtility.createProductRatePlan(true, testProduct);

    	Inventory__c testInventory = TestClassUtility.createInventory(false,testProductRatePlan);
    	testInventory.Inventory_Hold_Expiry_Date__c = Date.today();
    	testInventory.Waitlist_Account__c = TestClassUtility.createAccount(true).Id;
    	Database.insert(testInventory,false);

		Test.startTest();
        Messaging.SingleEmailMessage emailResponse = EmailUtility.createWaitListOnDeckEmail(testInventory);
        Test.stopTest();

        System.assert(emailResponse != null);
    }

    static testMethod void testCreateEmailBody() {
		String title = 'testTitle';
		String bodyText = 'testBodyText';

		Test.startTest();
        String responseString = EmailUtility.createEmailBody(title,bodyText);
        Test.stopTest();

        System.assert(String.isNotBlank(responseString));
    }
}