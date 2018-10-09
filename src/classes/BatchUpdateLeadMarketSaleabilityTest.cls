@isTest
private class BatchUpdateLeadMarketSaleabilityTest {
  //Comment by CSP-2712 Decommission Marketplace Health code
  // static testMethod void testMethod1() {
  //   Test.startTest();

  //   Market__c testMarket = TestClassUtility.createMarket(false);
  //   testMarket.Market_ID__c = '222';
  //   testMarket.Active__c = true;
  //   insert testMarket;

  //   Zip__c testZip = TestClassUtility.createzip(false);
  //   testZip.Local_Market__c = testMarket.Id;
  //   insert testZip;

  //   Category__c testCategory = TestClassUtility.createCategory(false);
  //   testCategory.Category_Code__c = 'ACC';
  //   insert testCategory;

  //   Account testAcct = TestClassUtility.createAccount(false);
  //   testAcct.BillingPostalCode = testZip.ZipCode__c;
  //   testAcct.Primary_Category__c = testCategory.id;
  //   insert testAcct;

  //   Lead testlead = TestClassUtility.createLead(false,testMarket,testCategory);
  //   testlead.PostalCode = testZip.ZipCode__c;
  //   insert testlead;

  //   Marketplace_Health__c  testMS = new Marketplace_Health__c();
  //   testMS.Category__c = testCategory.Id;
  //   testMS.Zip__c = testZip.Id;
  //   testMS.External_Key__c = testZip.ZipCode__c + testCategory.Category_Code__c;
  //   insert testMS;

  //   //Excute batch for update account market saleability 
  //   BatchUpdateLeadMarketSaleability cls = new BatchUpdateLeadMarketSaleability();
  //   Database.executeBatch(cls,2000);


  //   Test.stopTest();
  // }
}