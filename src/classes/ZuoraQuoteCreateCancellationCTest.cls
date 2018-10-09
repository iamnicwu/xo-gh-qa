@isTest
public class ZuoraQuoteCreateCancellationCTest{
    public static testMethod void test_method_one() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        
        Test.startTest(); 
            // Map<String, SObject> localObjects = TestClassUtility.buildLocalData(false);
        
            // Account testAccount = (Account)localObjects.get('Account');
            // Opportunity testOpp = (Opportunity)localObjects.get('Opportunity');
            // Zuora__CustomerAccount__c testBillingAccount = (Zuora__CustomerAccount__c)localObjects.get('Zuora__CustomerAccount__c');

            // Map<String, SObject> subscriptionObjects = TestClassUtility.buildSubscriptionData(testAccount, (Contact)localObjects.get('Contact'), testOpp, (Zuora__CustomerAccount__c)localObjects.get('Zuora__CustomerAccount__c'));
            
            // Zuora__Subscription__c testSub = (Zuora__Subscription__c)subscriptionObjects.get('Zuora__Subscription__c');
            // zqu__Quote__c testQuote = (zqu__Quote__c)subscriptionObjects.get('zqu__Quote__c');
            
            // testBillingAccount.Zuora__SoldToName__c = 'Bob Test';
            // testBillingAccount.Zuora__BillCycleDay__c = 'EOM';
            // update testBillingAccount;
        Test.stopTest();
        
        // testSub.Zuora__Zuora_Id__c = '2c92c0f94ed8d0d7014ee476a6e419ef'; 
        // testSub.Zuora__TermEndDate__c = date.today();
        // update testSub;
        
        
        
        // test.setCurrentPageReference(Page.ZuoraQuoteCreateCancellation);
        // System.currentPageReference().getParameters().put('oppId', testQuote.zqu__Opportunity__c );
        // // System.currentPageReference().getParameters().put('billingAccountId', testBillingAccount.Zuora__Zuora_Id__c );
        // // System.currentPageReference().getParameters().put('subscriptionId', testSub.Zuora__Zuora_Id__c );
        // ApexPages.StandardController sc = new ApexPages.StandardController(testQuote);
        
        // ZuoraQuoteCreateCancellationController testcase = new ZuoraQuoteCreateCancellationController(sc); 
        
        // testcase.initializeQuote();
        
        //testBillingAccount.Zuora__BillCycleDay__c = '552';
        //update testBillingAccount;
        //testcase.initializeQuote();
        
        //testBillingAccount.Zuora__BillCycleDay__c = '5a2';
        //update testBillingAccount;
        //testcase.initializeQuote();
        
        // testcase.updateCancellationEffectiveDate();
        
        // String getImgUrl =  testcase.getImgUrl();
        
        // testcase.goNavigateBack();
        
        // testcase.goNavigateNext();
    }
    
}