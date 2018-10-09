@isTest
private class zQuoteFlowAddPaymentMethodControllerTest{
    @isTest static void test_method_one() {
        
        
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Test.startTest();
            Map<String, SObject> localObjects = TestClassUtility.buildLocalData(false);
        Test.stopTest();

        Account testAccount = (Account)localObjects.get('Account');
        Opportunity testOpp = (Opportunity)localObjects.get('Opportunity');

        Map<String, SObject> subscriptionObjects = TestClassUtility.buildSubscriptionData(testAccount, (Contact)localObjects.get('Contact'), testOpp, (Zuora__CustomerAccount__c)localObjects.get('Zuora__CustomerAccount__c'));
        
        zqu__Quote__c testQuote = (zqu__Quote__c)subscriptionObjects.get('zqu__Quote__c');
        
        Test.setCurrentPageReference(Page.zQuoteFlowAddPaymentMethod);

        System.currentPageReference().getParameters().put('id', testQuote.id);
        ApexPages.StandardController sc = new ApexPages.StandardController(testQuote);
        zQuoteFlowAddPaymentMethodController testcase = new zQuoteFlowAddPaymentMethodController(sc);
        String pageId = testcase.pageId;
    }
}