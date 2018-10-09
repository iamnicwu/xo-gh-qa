@isTest
private class BatchConvertWaitlistToInventoryTest {
  
  @isTest static void batchTest() {
    // CREATE TEST DATA
    // zqu__ZProduct__c testProduct = TestClassUtility.createProduct(true);
    Product2 testProduct = TestClassUtility.createLocalProduct2(true);
    zqu__ProductRatePlan__c testProductRatePlan = TestClassUtility.createProductRatePlan(true, testProduct);
    Waitlist__c waitlist = TestClassUtility.createWaitlist(true,testProductRatePlan); 
    Inventory_Hold_Expiry_Date_Offsets__c invHoldExpDate = Inventory_Hold_Expiry_Date_Offsets__c.getOrgDefaults();
    invHoldExpDate.Account_Day_Offset__c = 2;
    upsert invHoldExpDate;

    // BEGIN TEST
    Test.startTest();
    BatchConvertWaitlistToInventory bct = new BatchConvertWaitlistToInventory();
    ID batchprocessid = Database.executeBatch(bct);
    Test.stopTest();
  } 
}