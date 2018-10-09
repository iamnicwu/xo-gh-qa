@isTest
private class AccountStrategySpecialisTest{
    private static testmethod void test_method_one() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        Test.startTest();
        Map<String, SObject> testData =TestClassUtility.buildLocalData(false);
        Test.stopTest();

        Set<Id> AccIds = new Set<Id>();
        Account testAccount = (Account)testData.get('Account');
        AccIds.add(testaccount.id);
        
        AccountStrategySpecialis.createAccountStrategySpecialis(AccIds);
        
    }
}