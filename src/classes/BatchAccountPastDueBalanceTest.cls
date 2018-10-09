@isTest
private class BatchAccountPastDueBalanceTest {
		
	static testMethod void testMethod1() {
		Invoice_Past_Due_Config__c ipdc = TestClassUtility.createInvoicePastDueConfig(true);
		Map<String,SObject> testMap = TestClassUtility.buildLocalData(false);

		Map<Integer, Date> daysLateDateMap = new Map<Integer, Date>();
		user currentUser  = [Select id, name, email from User where id=: UserInfo.getUserId()];
		
		Test.startTest();
		Integer daysPastDue = (Integer)ipdc.Number_Of_Days_Past_Due__c;
		Date pastDueDate = Date.today().addDays(daysPastDue * -1);

		Account acc = (Account)testMap.get('Account');
		Zuora__CustomerAccount__c ca = (Zuora__CustomerAccount__c)testMap.get('Zuora__CustomerAccount__c');
		Contact con = (Contact)testMap.get('Contact');

		// ca.Bill_To_Contact__c = con.id;
		// update ca;

		acc.Past_Due_Balance__c = 100.0;
		acc.Customer_on_Payment_Arrangement__c = false;
		acc.Longest_Past_Due_Date__c = pastDueDate;
		acc.CBBS__c = currentUser.ID;
		acc.Override_Account_CBSS__c = true;

		update acc;

		BatchAccountPastDueBalanceEmailsAndTasks bb = new BatchAccountPastDueBalanceEmailsAndTasks();
		Database.executeBatch(bb);
		
		Test.stopTest();
	}

	static testMethod void testMethod2() {
		Invoice_Past_Due_Config__c ipdc = TestClassUtility.createInvoicePastDueConfig(true);
		ipdc.Send_Email_To_Account_Owner__c = true;
		ipdc.Number_Of_Days_Past_Due__c = 75;
		ipdc.Send_Email_To_Customer__c = false;
		update ipdc;

		user currentUser  = [Select id, name, email from User where id=: UserInfo.getUserId()];

		Map<String,SObject> testMap = TestClassUtility.buildLocalData(false);

		Map<Integer, Date> daysLateDateMap = new Map<Integer, Date>();

		Test.startTest();
		Integer daysPastDue = (Integer)ipdc.Number_Of_Days_Past_Due__c;
		Date pastDueDate = Date.today().addDays(daysPastDue * -1);

		Account acc = (Account)testMap.get('Account');
		Zuora__CustomerAccount__c ca = (Zuora__CustomerAccount__c)testMap.get('Zuora__CustomerAccount__c');
		Contact con = (Contact)testMap.get('Contact');

		// ca.Bill_To_Contact__c = con.id;
		// update ca;

		acc.Past_Due_Balance__c = 100.0;
		acc.Customer_on_Payment_Arrangement__c = false;
		acc.Longest_Past_Due_Date__c = pastDueDate;
		acc.CBBS__c = currentUser.ID;
		acc.Override_Account_CBSS__c = true;

		update acc;

		BatchAccountPastDueBalanceEmailsAndTasks bb = new BatchAccountPastDueBalanceEmailsAndTasks();
		Database.executeBatch(bb);
		
		Test.stopTest();
	}
}