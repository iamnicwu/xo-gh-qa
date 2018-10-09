/*******************************************************************************
 *  Summary         : Test class for Account Summary Controller
 *  Refer Object    : 
 *  Author          : Nick
 *  RefactorDate    : 12 Dec 2016
 *  Change Log      : Refactoring by SF-2.6 release
 ******************************************************************************/
@isTest
private class AccountSummaryControllerTest {

    @isTest static void summaryTest() {
        // Use TestClassUtility to build local data WITH subscription data

        Map<String, SObject> testObjects = TestClassUtility.buildLocalData(false);
        Test.startTest();

        Map<String, SObject> testsub =TestClassUtility.buildSubscriptionData((Account)testObjects.get('Account'), 
                                                                            (Contact)testObjects.get('Contact'), 
                                                                            (Opportunity)testObjects.get('Opportunity') , 
                                                                            (Zuora__CustomerAccount__c)testObjects.get('Zuora__CustomerAccount__c'));

        Account testAccount = (Account)testObjects.get('Account');
        
        
        // Test base functionality
        AccountSummaryController.getSummaryData(testAccount.Id, 'all');
        AccountSummaryController.getSummaryData(null, 'active');
        AccountSummaryController.getSummaryData(testAccount.Id, 'completedlast90');

        // Test credit hold display logic
        testAccount.CreditHold__c = 'Yes';
        update testAccount;
        Test.stopTest();
        AccountSummaryController.getSummaryData(testAccount.Id, 'all');

        testAccount.CreditHold__c = 'No';
        testAccount.Customer_on_Payment_Arrangement__c = true;
        update testAccount;
        AccountSummaryController.getSummaryData(testAccount.Id, 'all');
        
        // Test Market and Category logic
        Category__c testCategory = (Category__c)testObjects.get('Category__c');

        Zuora__SubscriptionProductCharge__c testSubscriptionProductCharge = (Zuora__SubscriptionProductCharge__c)testsub.get('Zuora__SubscriptionProductCharge__c');

        zqu__QuoteRatePlan__c testQuoteRatePlan = (zqu__QuoteRatePlan__c)testsub.get('zqu__QuoteRatePlan__c');

        testCategory.Taxonomy_ID__c = 'testcategoryId';
        update testCategory;

        // Extra Subscription Product Charge Logic
        testSubscriptionProductCharge.Market_ID__c = '222';
        testSubscriptionProductCharge.Category_Taxonomy_ID__c = 'testcategoryId';
        testSubscriptionProductCharge.Quote_Rate_Plan_ID__c = testQuoteRatePlan.Id;
        update testSubscriptionProductCharge;

        AccountSummaryController.getSummaryData(testAccount.Id, 'all');

        // Instantiate wrapper class
        AccountSummaryController.AccountData testAccountData = new AccountSummaryController.AccountData();

    }
}