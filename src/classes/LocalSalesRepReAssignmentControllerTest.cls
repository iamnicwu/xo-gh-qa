/*******************************************************************************
 *  Summary         : Test class for LocalSalesRepReAssignment Controller
 *  Refer Object    : 
 *  Author          : Tony
 *  RefactorDate    : 12 Dec 2016
 *  Change Log      : refactoring by SF-2.6 release
 ******************************************************************************/
@isTest
private class LocalSalesRepReAssignmentControllerTest{
    @isTest static void test_method_one() {
        
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        
        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        // Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        // Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        test.startTest();
        Map<String,SObject> sObjectMap  = TestClassUtility.buildLocalData(FALSE);
        Account testAccount = (Account)sObjectMap.get('Account');
        // CSP-1999 Brand__c testBrand = (Brand__c)sObjectMap.get('Brand__c');
        Market__c testMarket = (Market__c)sObjectMap.get('Market__c');
        Category__c testCategory = (Category__c)sObjectMap.get('Category__c');
        Zip__c testZip = (Zip__c)sObjectMap.get('Zip__c');

        Product2 testProduct = TestClassUtility.createLocalProduct2(TRUE);
        Zuora__Subscription__c testZquSubscription = TestClassUtility.createSubscription(TRUE,testAccount);
        test.stopTest();
        
        // insert testZquSubscription;
        testZquSubscription.Zuora__Zuora_Id__c =testZquSubscription.id;
        update testZquSubscription;
        
        test.setCurrentPageReference(Page.LocalSalesRepReAssignment);
        ApexPages.StandardController sc = new ApexPages.StandardController(testZquSubscription);
        LocalSalesRepReAssignmentController testcase = new LocalSalesRepReAssignmentController(); 
        
        testcase.objectFilter.leadFilter.Status = 'test';
        testcase.selectedRecordOwner = UserInfo.getUserId();
        testcase.selectedObjectType  = 'Lead';
        testcase.filterResults();
        
        testcase.selectedObjectType  = 'Account';
        testcase.filterResults();
        
        testcase.selectedObjectType  = 'Opportunity';
        testcase.filterResults();
        
        
        testcase.selectedObjectType  = 'Local_Sales_Rep_Assignment__c';
        testcase.filterResults();
        
        
        testcase.selectedObjectType  = 'Account';
        testcase.filterResults();
        testcase.selectedRecordMap.put(testAccount.id,true);
        testcase.populateSObject();
        
        testcase.saveNewOwner();
        
        testcase.reRenderPanel();
        List<SelectOption> getObjectTypes = testcase.getObjectTypes();
        List<SelectOption> getUserList = testcase.getUserList();
        List<SelectOption> getLocalSalesRepActive = testcase.getLocalSalesRepActive();
        List<SelectOption> getActiveType = testcase.getActiveType();
        List<SelectOption> getLocalAEOnly = testcase.getLocalAEOnly();
        List<SelectOption> getResultSizeOptions = testcase.getResultSizeOptions();
        List<SelectOption> getLeadStatusValues = testcase.getLeadStatusValues();
        Boolean hasNext = testcase.hasNext;
        Boolean hasPrevious = testcase.hasPrevious;
        Integer pageNumber = testcase.pageNumber;
        
        
        testcase.first();
        testcase.last();
        testcase.previous();
        testcase.next();
    }
}