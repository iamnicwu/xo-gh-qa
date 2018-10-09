@isTest
private class SendToZBillingUtilitiesTest {
	
	static testMethod void testOne() {
		
		Test.startTest();
		Map<String, SObject> testObjects = TestClassUtility.buildZQUTestObjects(false);
		Test.stopTest();

		Opportunity testOpp = (Opportunity)testObjects.get('Opportunity');

		Task_Creation_Settings__c taskCreationSetting = Task_Creation_Settings__c.getOrgDefaults();
		taskCreationSetting.Create_Task__c = true;
		taskCreationSetting.Name = 'Error_sending_a_quote_to_Zuora';
		upsert taskCreationSetting Task_Creation_Settings__c.Id;

		testOpp.NeedToSendToZBilling__c = true;
		testOpp.StageName = 'Client Approved';
		update testOpp;

		zqu__Quote__c zquQuote = new zqu__Quote__c();
		zquQuote.zqu__Opportunity__c = testOpp.id;
		zquQuote.zqu__Status__c = 'New'; 
		zquQuote.Name = 'Test Quote';
    zquQuote.Zqu__ValidUntil__c = Date.Today()-1;
    zquQuote.Product_Line__c = 'Internet';
    zquQuote.zqu__PaymentMethod__c = 'Check';
    zquQuote.Payment_Method__c = 'Check';
    zquQuote.Preferred_Payment_Schedule__c = 'Annual';
		insert zquQuote;

		Id opportunityId = testOpp.Id;
		SendToZBillingUtilities.futureChaining(opportunityId);
	}
	
	static testMethod void updateQuoteRecordTypeToReadOnlyOrEditableTest() {

		Test.startTest();
		Map<String, SObject> testObjects = TestClassUtility.buildZQUTestObjects(false);
		Test.stopTest();

		Opportunity testOpp = (Opportunity)testObjects.get('Opportunity');
		Account testAcc = (Account)testObjects.get('Account');
		Contact testCon = (Contact)testObjects.get('Contact');
		zqu__Quote__c testQuote = TestClassUtility.createQuote(true, testOpp, testAcc, testCon);


		List<zqu__Quote__c> QuoteList = new List<zqu__Quote__c>();
		Task_Creation_Settings__c taskCreationSetting = Task_Creation_Settings__c.getOrgDefaults();
		taskCreationSetting.Create_Task__c = true;
		taskCreationSetting.Name = 'Error_sending_a_quote_to_Zuora';
		upsert taskCreationSetting Task_Creation_Settings__c.Id;

		testOpp.NeedToSendToZBilling__c = true;
		testOpp.StageName = 'Client Approved';
		update testOpp;

		zqu__Quote__c zquQuote = new zqu__Quote__c();
		zquQuote.zqu__Opportunity__c = testOpp.id;
		zquQuote.zqu__Status__c = 'New'; 
		zquQuote.Name = 'Test Quote';
    zquQuote.Zqu__ValidUntil__c = Date.Today()-1;
    zquQuote.Product_Line__c = 'Internet';
    zquQuote.zqu__PaymentMethod__c = 'Check';
    zquQuote.Payment_Method__c = 'Check';
    zquQuote.Preferred_Payment_Schedule__c = 'Annual';
		// insert zquQuote;
		zqu__Quote__c zquQuote2 = new zqu__Quote__c();
		zquQuote2.zqu__Opportunity__c = testOpp.id;
		zquQuote2.zqu__Status__c = 'New'; 
		zquQuote2.Name = 'Test Quote';
    zquQuote2.Zqu__ValidUntil__c = Date.Today()-1;
    zquQuote2.Product_Line__c = 'Internet';
    zquQuote2.zqu__PaymentMethod__c = 'Check';
    zquQuote2.Payment_Method__c = 'Check';
    zquQuote2.Preferred_Payment_Schedule__c = 'Annual';
		//insert zquQuote2;


		QuoteList.add(zquQuote);
		QuoteList.add(zquQuote2);
		insert QuoteList;

		Id opportunityId = testOpp.Id;
		SendToZBillingUtilities.futureChaining(opportunityId);
		
		SendToZBillingUtilities.updateQuoteRecordTypeToReadOnlyOrEditable(testQuote.Id, 'readOnly');
		SendToZBillingUtilities.updateQuoteRecordTypeToReadOnlyOrEditable(testQuote.Id, 'Editable');
	}
}