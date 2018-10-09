@isTest
private class WaitlistModalControllerTest {

    //static testMethod void myUnitTest() {
        
    //    System.debug('setup products to make sure we have at least some data for testing');
    //    //testDataFactory dataFactory = new testDataFactory();
    //    //dataFactory.CreateLocalTestObjects();
    //    SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
    //                                             'Complete',
    //                                             '{"companyName": "Test Account"}',
    //                                             null);
    //    Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        
    //    Test.startTest();
    //        Map<String, SObject> testObjects = TestClassUtility.buildZQUTestObjects(false);
    //    Test.stopTest();
        
    //    Account testAccount = (Account)testObjects.get('Account');
        
    //    zqu__ZProduct__c testProduct = TestClassUtility.createProduct(true);
    //    zqu__ProductRatePlan__c testZquProductRatePlan = TestClassUtility.createProductRatePlan(true, testProduct);
        
    //    List<zqu__ProductRatePlan__c> ratePlans = new List<zqu__ProductRatePlan__c>();
        
    //    WaitlistModalController wm = new WaitlistModalController();
        
    //    // set the product rate plan
    //    wm.OpenModal(testZquProductRatePlan.Id);
    //    // read the value we just inserted
    //    string val = wm.ProductRatePlanId;
        
    //    // add a few waitlist items
    //    wm.SaveNewWaitlist(testZquProductRatePlan.Id, testAccount.Id);
    //    wm.SaveNewWaitlist(testZquProductRatePlan.Id, testAccount.Id);
    //    wm.SaveNewWaitlist(testZquProductRatePlan.Id, testAccount.Id);
    //    wm.SaveNewWaitlist(testZquProductRatePlan.Id, testAccount.Id);
        
    //    // add some inventory
    //    Inventory__c inv = new Inventory__c();
    //    inv.Waitlist_Account__c = testAccount.Id;
    //    inv.Product_Rate_Plan__c = testZquProductRatePlan.Id;
    //    inv.Inventory_Hold_Expiry_Date__c = Date.Today().addDays(3);
    //    insert inv;
        
    //    // retrieve the waitlists
    //    List<Waitlist__c> waitlists = wm.getWaitlists();
        
    //    // reorder the list
    //    wm.SelectedWaitlistId = waitlists[2].Id;
    //    wm.MoveUp();
    //    wm.MoveDown();
    //    wm.MoveToBottom();
    //    wm.DeleteWaitlist();
        
    //    // retrieve the inventory
    //    List<Inventory__c> invList = wm.getAccountsOnDeck();
    //    wm.SelectedInventoryId = invList[0].id;
        
    //    // change inventory
    //    wm.HoldInventory();
    //    wm.DeleteInventory();
        
    //    // test page methods
    //    wm.getCanDeleteAnyWaitlist();
    //    wm.getCanReorderAnyWaitlist();
    //    wm.CloseModal();
    //    wm.getRatePlan();
    //    wm.AddAccount();

        
    //}
}