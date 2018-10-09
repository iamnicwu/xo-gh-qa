@isTest
private class BatchResetPastDueBalanceOnCaseSchJobTest {
    static testMethod void testMethod1() {
    	SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        Map<String, Schema.RecordTypeInfo> caseRecTypeNameMap = Schema.SObjectType.Case.getRecordTypeInfosByName();

        Test.startTest();
        Map<String, SObject> testData =TestClassUtility.buildLocalData(false);
        Test.stopTest();

        Account testAccount = (Account)testData.get('Account');
        testAccount.Past_Due_Balance__c = 100;
        update testAccount;

        Case testCase = new Case();
        testCase.AccountId = testAccount.Id;
        testCase.RecordTypeId = caseRecTypeNameMap.get('Client Billing').getRecordTypeId();
        testCase.Past_Due_Potential__c = 700;
        insert testCase;

        list<Case> caselist = [select id,RecordType.name, IsClosed from Case where id =: testCase.id];
        // system.assert(false,caselist[0].IsClosed);
        BatchResetPastDueBalanceOnCaseSchJob bct = new BatchResetPastDueBalanceOnCaseSchJob();
	    String schedule = '0 0 23 * * ?';
	    system.schedule('Nightly Update', schedule, bct );


	    BatchResetPastDueBalanceOnCase b = new BatchResetPastDueBalanceOnCase();
		database.executebatch(b);
    }
}