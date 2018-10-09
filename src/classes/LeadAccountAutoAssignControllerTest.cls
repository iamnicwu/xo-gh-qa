@isTest
private class LeadAccountAutoAssignControllerTest {
  @isTest static void testMethod_one() {
    ////////////////////////////
    // Create Local Test Data //
    ////////////////////////////
    Test.startTest();
      Map<String, Object> localObjectMap = TestClassUtility.buildLocalData(FALSE);
    Test.stopTest();
    
    //////////////////////////////
    // Begin Testing Controller //
    //////////////////////////////
    LeadAccountAutoAssignController ldaac = new LeadAccountAutoAssignController();
    ldaac.getActiveType();
    ldaac.getAssignType();
    ldaac.getProfileList();
    ldaac.getUserList();

    ldaac.aType = 'accountMetro';
    ldaac.reRenderPanel();

    ldaac.executeBatchAssign();
    
    ldaac.selectedProfile = 'admin';
    ldaac.getUserList();
    
    ldaac.query = '';
    
    ldaac.aType = 'accountOwner';
    ldaac.executeBatchAssign();
    
    ldaac.selectedRecordOwner = UserInfo.getUserId();
    ldaac.executeBatchAssign();
    
    ldaac.aType = 'leadOwner';
    ldaac.executeBatchAssign();
  }
    
  @isTest static void testMethod_Two() {
    ////////////////////////////
    // Create Local Test Data //
    ////////////////////////////
    Test.startTest();
      Map<String, Object> localObjectMap = TestClassUtility.buildLocalData(FALSE);
    Test.stopTest();

    //////////////////////////////////////
    // Grab Needed Object Data from Map //
    //////////////////////////////////////
    Market__c testMarket = (Market__c)localObjectMap.get('Market__c');
    Category__c testCategory = (Category__c)localObjectMap.get('Category__c');
    Zip__c testZip = (Zip__c)localObjectMap.get('Zip__c');
    // CSP-1999 Brand__c testBrand = (Brand__c)localObjectMap.get('Brand__c');
    
    Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
    List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
    
    //////////////////////////////////////////
    // Create Sales Rep Assignment Records  //
    //////////////////////////////////////////
    Local_Sales_Rep_Assignment__c lsra = new Local_Sales_Rep_Assignment__c();
    lsra.Sales_Rep__c = UserInfo.getUserId();
    lsra.Category__c = testCategory.Id;
    lsra.Market__c = testMarket.Id;
    insert lsra;
    
    Local_Sales_Rep_Assignment__c lsra1 = new Local_Sales_Rep_Assignment__c();
    lsra1.Sales_Rep__c = UserInfo.getUserId();
    lsra1.Zip_Code__c = testZip.id;
    lsra1.Category__c = testCategory.Id;
    insert lsra1;
    
    Local_Sales_Rep_Assignment__c lsra2 = new Local_Sales_Rep_Assignment__c();
    lsra2.Sales_Rep__c = UserInfo.getUserId();
    lsra2.Category__c = testCategory.Id;
    insert lsra2;
    
    Local_Sales_Rep_Assignment__c lsra3 = new Local_Sales_Rep_Assignment__c();
    lsra3.Sales_Rep__c = UserInfo.getUserId();
    lsra3.Zip_Code__c = testZip.id;
    insert lsra3;
    
    Local_Sales_Rep_Assignment__c lsra4 = new Local_Sales_Rep_Assignment__c();
    lsra4.Sales_Rep__c = UserInfo.getUserId();
    lsra4.Market__c = testMarket.Id;
    insert lsra4;
    
    /////////////////////////
    // Create New Account  //
    /////////////////////////
    Account testAccount1 = new Account();
    testAccount1.Name = 'second Test A';
    testAccount1.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
    testAccount1.BU__c = 'Local';
    testAccount1.Website = 'www.google.com';
    testAccount1.BillingCountry = 'United States';
    testAccount1.BillingState = 'Alaska';
    testAccount1.BillingCity = 'US2';
    testAccount1.BillingStreet = 'US3';
    testAccount1.BillingPostalCode = testZip.ZipCode__c;
    
    testAccount1.ShippingCountry = 'United States';
    testAccount1.shippingPostalCode = testZip.ZipCode__c;
    testAccount1.Type = 'Advertiser';
    testAccount1.DynamicsAccID__c = 'testDynamicsLeadID1';
    testAccount1.Operative_Owner__c = userList[0].Name;
    testAccount1.Phone = '12345678';
    //CSP-1999  testAccount1.Primary_Brand__c = testBrand.id;
    testAccount1.Primary_Category__c = testCategory.id;
    testAccount1.Local_Sales_Market__c = testMarket.id;
    insert testAccount1;
    
    /////////////////////////////////
    // Begin Auto Assignment Logic //
    /////////////////////////////////
    LeadAccountAutoAssignController ldaac = new LeadAccountAutoAssignController();
    ldaac.selectedRecordOwner = UserInfo.getUserId();
    ldaac.aType = 'accountOwner';
    ldaac.executeBatchAssign();
  } 
}