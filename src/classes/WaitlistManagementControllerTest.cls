@isTest
private class WaitlistManagementControllerTest {

    static testMethod void myUnitTest() {
       SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                'Complete',
                                                '{"companyName": "Test Account"}',
                                                null);
       Test.setMock(HttpCalloutMock.class, fakeResponse);

       Map<String, SObject> testObjects = TestClassUtility.buildZQUTestObjects(false);
             
       List<zqu__ProductRatePlan__c> ratePlans = new List<zqu__ProductRatePlan__c>();
        
       Test.startTest();
       Map<String, SObject> testsub =TestClassUtility.buildSubscriptionData((Account)testObjects.get('Account'), 
                                                                           (Contact)testObjects.get('Contact'), 
                                                                           (Opportunity)testObjects.get('Opportunity') , 
                                                                           (Zuora__CustomerAccount__c)testObjects.get('Zuora__CustomerAccount__c'));
       Account testAccount = (Account)testObjects.get('Account');
       zqu__ProductRatePlan__c testZquProductRatePlan = (zqu__ProductRatePlan__c)testsub.get('zqu__ProductRatePlan__c');
       Product2 testProduct = TestClassUtility.createLocalProduct2(true);        

       WaitlistManagementController wmc = new WaitlistManagementController();
       wmc.myWaitlistModalController = new WaitlistModalController();

       // add a few inventory items until it is no longer available
       for (integer i = 0; i< 5; i++)
       {
           Inventory__c inv = new Inventory__c();
           inv.Waitlist_Account__c = testAccount.Id;
           inv.Product_Rate_Plan__c = testZquProductRatePlan.Id;
           inv.Inventory_Hold_Expiry_Date__c = Date.Today().addDays(3);
           try
           {
               insert inv;
           } catch (exception excDontCare) {}
       }
        
       // add a waitlist item
       wmc.myWaitlistModalController.SaveNewWaitlist(testZquProductRatePlan.Id, testAccount.Id);
        
       System.Debug('add filters to test the query');        
       wmc.FilterProduct = testProduct.Id;
       wmc.FilterCategory = 'test';
       wmc.FilterMarket = 'test';
       wmc.FilterAvailable = 'true';
       ratePlans = wmc.getProductRatePlans();
        
       System.Debug('remove all filters to ensure we get at least one rate plan');
       wmc.FilterProduct = '';
       wmc.FilterCategory = '';
       wmc.FilterMarket = '';
       wmc.FilterAvailable = '';
       ratePlans = wmc.getProductRatePlans();        
        
       System.Debug('test the modal window for displaying waitlists');
       System.Debug('launching modal for: ' + ratePlans[0].Id + ' (' + ratePlans[0].Name + ')');
       wmc.SelectedRatePlanIdForWaitlistModal = ratePlans[0].Id;
       wmc.ViewWaitlist();
        
       // code coverage on all of the pagination functions
       wmc.Beginning();
       wmc.End();
       wmc.Previous();
       wmc.Next();
       wmc.getDisablePrevious();
       wmc.getDisableNext();
       wmc.getPageNumber();
       wmc.getTotal_size();
       wmc.getTotalPages();
       wmc.total_size = 1;
       wmc.list_size = 1;
       wmc.getTotalPages();
       wmc.getOkToDisplayList();
        
       wmc.getMyComponentController();
        
       Test.stopTest();
    }
}