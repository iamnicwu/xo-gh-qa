/*******************************************************************************
 *  Summary         : Test class for paymentmethod Controller
 *  Refer Object    : 
 *  Author          : Nick
 *  RefactorDate    : 12 Dec 2016
 *  Change Log      : Refactoring by SF-2.6 release
 ******************************************************************************/
@isTest
private class CreateNewPaymentMethodControllerTest{

    private static testmethod void test_method_one() {
        
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Map<String, SObject> zqDataMap = TestClassUtility.buildZQUTestObjects(false);

        Test.startTest();

        zqu__Quote__c testQuote = TestClassUtility.createQuote(true, 
            (Opportunity)zqDataMap.get('Opportunity'), 
            (Account)zqDataMap.get('Account'), 
            (Contact)zqDataMap.get('Contact'));

        zqu__HostedPageLiteSetting__c testzquHostedPageLiteSetting = new zqu__HostedPageLiteSetting__c ();
        testzquHostedPageLiteSetting.zqu__PaymentMethodType__c = 'Credit Card';
        testzquHostedPageLiteSetting.zqu__PageId__c = '8aa9a07b';
        testzquHostedPageLiteSetting.zqu__ComponentName__c = 'testComponentName';
        insert testzquHostedPageLiteSetting;
        
        test.setCurrentPageReference(Page.CreateNewPaymentMethod);
        ApexPages.StandardController sc = new ApexPages.StandardController(testQuote);
        CreateNewPaymentMethodController testcase = new CreateNewPaymentMethodController(sc); 
        string pageId = testcase.pageId;
        
        Test.stopTest();
    }
}