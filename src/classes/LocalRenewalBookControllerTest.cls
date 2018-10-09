/*******************************************************************************
 *  Summary         : Test class for LocalRenewalBook Controller
 *  Refer Object    : 
 *  Author          : Tony
 *  RefactorDate    : 12 Dec 2016
 *  Change Log      : refactoring by SF-2.6 release
 ******************************************************************************/
@isTest
private class LocalRenewalBookControllerTest{
    @isTest static void test_method_one() {
        
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        test.startTest();
        Map<String,SObject> sObjectMap  = TestClassUtility.buildLocalData(FALSE);
        test.stopTest();

        Account testAccount = (Account)sObjectMap.get('Account');
        Market__c testMarket = (Market__c)sObjectMap.get('Market__c');
        Category__c testCategory = (Category__c)sObjectMap.get('Category__c');
        Product2 testLocalProduct = TestClassUtility.createLocalProduct2(TRUE);
        Zuora__Subscription__c testZquSubscription = TestClassUtility.createSubscription(TRUE,testAccount);
        
        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];

        test.setCurrentPageReference(Page.LocalRenewalBook);
        ApexPages.StandardController sc = new ApexPages.StandardController(testZquSubscription);
        LocalRenewalBookController testcase = new LocalRenewalBookController(sc); 
        string ownerActiveFilter = testcase.ownerActiveFilter;
        
        testcase.filterObject.brandFilter = testAccount.id;
        
        testcase.filterObject.marketFilter.add(new SelectOption('testMarket', string.valueOf(testMarket.Id)));
        
        testcase.filterObject.categoryFilter.add(new SelectOption('testCategory', string.valueOf(testCategory.Id)));
        testcase.filterObject.postalCodeSelected = '12121';
        testcase.filterObject.subscriptionFilter.Sales_Rep__c = userList[0].id;
        testcase.filterObject.subscriptionFilter.Renewal_Rep__c = userList[0].id;
        testcase.filterObject.productLineFilter.Product_Line__c = 'test';
        testcase.filterResults();
        
        testcase.brandFilterFunction();
        testcase.subSelectedMap.put(testZquSubscription.id,false);
        testcase.populateSubscriptions();
        
        testcase.refresh();
        
        testcase.saveRenewalRep();
        testcase.saveFloaterRep();
        
        testcase.salesRepToAssign = userList[1].id;
        testcase.subSelectedMap.clear();
        testcase.saveRenewalRep();
        testcase.saveFloaterRep();
        
        testcase.subSelectedMap.put(testZquSubscription.id,true);
        testcase.saveRenewalRep();
        testcase.saveFloaterRep();
        
        boolean hasNext = testcase.hasNext;
        boolean hasPrevious = testcase.hasPrevious;
        Integer pageNumber = testcase.pageNumber;
        
        testcase.first();
        testcase.last();
        testcase.previous();
        testcase.next();
        
        List<SelectOption> ResultSizeOptions = testcase.getResultSizeOptions();
        List<SelectOption> BrandOptions = testcase.getBrandOptions();
        List<SelectOption> CategoryOptions = testcase.getCategoryOptions();
        List<SelectOption> MarketOptions = testcase.getMarketOptions();
        List<SelectOption> SortByList = testcase.getSortByList();
        List<SelectOption> getUserList = testcase.getUserList();
        List<SelectOption> getUserRenewalList = testcase.getUserRenewalList();
        List<SelectOption> getLocalSalesRepActive = testcase.getLocalSalesRepActive();
        List<SelectOption> getActiveType = testcase.getActiveType();
        List<SelectOption> getLocalAEOnly = testcase.getLocalAEOnly();
        
        testcase.reRenderPanel();
        
    }
}