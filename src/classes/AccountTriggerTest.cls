@isTest
private class AccountTriggerTest { 
    private static List<User> userList;
    private static Map<String,Schema.RecordTypeInfo> rtAccountMapByName;
    private static Map<String,Schema.RecordTypeInfo> rtLeadMapByName;
    // CSP-1999 private static Map<String,Schema.RecordTypeInfo> rtBrandMapByName;
    private static Deactivate_Trigger__c dtatt;
    private static Generate_Quote_Pdf_Config__c GQPF;
    // CSP-1999 private static Brand__c testBrand;
    private static Region__c testRegion;
    private static Market__c testMarket;
    private static Market__c testCAMarket;
    private static Market__c testCAMarket2;
    private static Category__c testCategory;
    private static MetroArea__c ma;
    private static Zip__c zip;
    private static Zip__c zipUS;
    private static Zip__c zipCA;

    private static testmethod void test_accountinsertlogic() {
        create_TestData();

        Test.startTest();
        // CSP-1999 
        // Account parentAccount = TestClassUtility.createAccount(false, testBrand, testCategory, testMarket);
        Account parentAccount = TestClassUtility.createAccount(false, testCategory, testMarket);
        parentAccount.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        parentAccount.Record_Type_Name__c = 'Local';
        parentAccount.BU__c = 'Local';
        parentAccount.Type = 'Agency';
        parentAccount.Operative_Owner__c = userList[0].Name;
        parentAccount.Fulfillment_Data__c = '{ "tier" : "Freemium", "reviewId" : "review Id", "parentGUID" : "37e0c6b9-6f4f-4dd4-a3f4-9707e9dc4bbc", "marketCode" : "228", "categoryId" : "8aa9a07b-fcd8-46ed-a98f-8f3e12689dd2" }';
        parentAccount.Override_Account_CBSS__c = true;
        parentAccount.CBBS__c = userList[1].Id;
        insert parentAccount;
        List<Account> lstacc1 =[select id from Account where id=: parentAccount.id];
        system.assertEquals(1,lstacc1.size());

        
        // CSP-1999 
        // Account testAccount1 = TestClassUtility.createAccount(false, testBrand, testCategory, testMarket);
        Account testAccount1 = TestClassUtility.createAccount(false, testCategory, testMarket);
        testAccount1.BillingPostalCode = zip.zipCode__c+'1';
        testAccount1.Region__c = 'Austin/Central Texas/Texas Hill Country';
        testAccount1.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testAccount1.Fulfillment_Data__c = '{ "tier" : "Freemium", "reviewId" : "review Id", "parentGUID" : "", "marketCode" : "222", "categoryId" : "8aa9a07b-fcd8-46ed-a98f-8f3e12689dd2" }';
        testAccount1.OwnerId = userList[1].id;
        testAccount1.Fulfill_Storefront__c = true;
        testAccount1.Fulfilled__c = false;
        testAccount1.Override_Account_CBSS__c = true;

        testAccount1.parentId = parentAccount.id;
        try{
            insert testAccount1;
            List<Account> lstacc11 =[select id from Account where id=: testAccount1.id];
            system.assertEquals(1,lstacc11.size());
        }catch(exception e){}

        testAccount1.ShippingPostalCode = zip.zipCode__c+'1';
        try{
            insert testAccount1;
        }catch(exception e){}
        
        testAccount1.BillingPostalCode = zip.zipCode__c;
        try{
            insert testAccount1;
        }catch(exception e){}
        
        if(String.isNotBlank(testAccount1.Id)){
            return;
        }
        
        testAccount1.parentId = null;
        testAccount1.BillingPostalCode = zip.zipCode__c;
        testAccount1.Fulfilled__c = true;
        insert testAccount1;
        parentAccount.ShippingPostalCode = '';
        parentAccount.BillingPostalCode = zip.Zipcode__c + '1';
        parentAccount.Need_to_Create_CB_Case__c = true;
        try{
            update parentAccount;
        }catch(exception e){}
        
        parentAccount.ShippingPostalCode = zip.Zipcode__c + '1';
        try{
            update parentAccount;
        }catch(exception e){}
        Test.stopTest();
    }

    private static testmethod void test_parentaccountinsertlogic() {
        create_TestData();

        Test.startTest();

        Account testAccount1 = TestClassUtility.createAccount(false, testCategory, testMarket);
        testAccount1.BillingPostalCode = zip.zipCode__c+'1';
        testAccount1.Region__c = 'Austin/Central Texas/Texas Hill Country';
        testAccount1.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testAccount1.Fulfillment_Data__c = '{ "tier" : "Freemium", "reviewId" : "review Id", "parentGUID" : "", "marketCode" : "222", "categoryId" : "8aa9a07b-fcd8-46ed-a98f-8f3e12689dd2" }';
        testAccount1.OwnerId = userList[1].id;
        testAccount1.Fulfill_Storefront__c = true;
        testAccount1.Fulfilled__c = false;
        testAccount1.Override_Account_CBSS__c = true;        
        testAccount1.ShippingPostalCode = zip.zipCode__c+'1';
        testAccount1.BillingPostalCode = zip.zipCode__c;
        testAccount1.Fulfilled__c = true;
        testAccount1.Need_to_Create_CB_Case__c = false;
        testAccount1.Past_Due_Balance__c = 12.34;
        insert testAccount1;
        List<Account> lstacc1 =[select id from Account where id=: testAccount1.id];
        system.assertEquals(1,lstacc1.size());

        testAccount1.Need_to_Create_CB_Case__c = true;
        testAccount1.Past_Due_Balance__c = 123.4;
        update testAccount1;

        testAccount1.Need_to_Create_CB_Case__c = false;
        testAccount1.Past_Due_Balance__c = 288;
        update testAccount1;
        List<Account> lstacc2 =[select id from Account where id=: testAccount1.id];
        system.assertEquals(1,lstacc2.size());

        Test.stopTest();
    }

    private static testmethod void test_GenerateAccountVIPStatusTask() {
        create_TestData();

      Test.startTest();
        // CSP-1999 
        // Account testAccount1 = TestClassUtility.createAccount(false, testBrand, testCategory, testMarket);
        Account testAccount1 = TestClassUtility.createAccount(false, testCategory, testMarket);
        testAccount1.BillingPostalCode = zip.zipCode__c + '1';
        testAccount1.Region__c = 'Austin/Central Texas/Texas Hill Country';
        testAccount1.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testAccount1.OwnerId = userList[0].Id;
        testAccount1.Strategy_Specialist__c = userList[1].Id;
        testAccount1.Manual_VIP_Program_Status__c = 'VIP';
        insert testAccount1;
        List<Account> lstacc1 =[select id from Account where id=: testAccount1.id];
        system.assertEquals(1,lstacc1.size());
        
        testAccount1.Manual_VIP_Program_Status__c = 'Not VIP';
        update testAccount1;
        Test.stopTest();
    }

    private static testmethod void test_OverrideAccountCBSS() {
        create_TestData();

      Test.startTest();
        // CSP-1999 
        // Account testAccount1 = TestClassUtility.createAccount(false, testBrand, testCategory, testMarket);
        Account testAccount1 = TestClassUtility.createAccount(false, testCategory, testMarket);
        testAccount1.BillingPostalCode = zip.zipCode__c + '1';
        testAccount1.Region__c = 'Austin/Central Texas/Texas Hill Country';
        testAccount1.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testAccount1.OwnerId = userList[0].Id;
        testAccount1.Fulfill_Storefront__c = false;
        insert testAccount1;
        List<Account> lstacc1 =[select id from Account where id=: testAccount1.id];
        system.assertEquals(1,lstacc1.size());

        TestClassUtility.createCustomerAccount(true, testAccount1);

        testAccount1.Override_Account_CBSS__c = true;
        testAccount1.CBBS__c = userList[1].Id;
        //testAccount1.Fulfill_Storefront__c = true;
        update testAccount1;

        testAccount1.Override_Account_CBSS__c = false;
        testAccount1.Fulfill_Storefront__c = false;
        update testAccount1;

        //csp-2618
        Zip__c testZip = TestClassUtility.createzip(true);

        Category__c testCategory = TestClassUtility.createCategory(false);
        testCategory.Category_Code__c = 'ACC';
        insert testCategory;
        List<Category__c> lstcategory1 =[select id from Category__c where id=: testCategory.id];
        system.assertEquals(1,lstcategory1.size());        

        Account testAcct = TestClassUtility.createAccount(false);
        testAcct.BillingPostalCode = testZip.ZipCode__c;
        testAcct.Primary_Category__c = testCategory.id;
        insert testAcct;
        List<Account> lstacc2 =[select id from Account where id=: testAcct.id];
        system.assertEquals(1,lstacc2.size());

        /*Marketplace_Health__c  testMS = new Marketplace_Health__c();
        testMS.Category__c = testCategory.Id;
        testMS.Zip__c = testZip.Id;
        testMS.External_Key__c = testZip.ZipCode__c + testCategory.Category_Code__c;
        insert testMS;*/


        Test.stopTest();
    }

    private static testmethod void test_UpdateBillingAccountNames() {
        create_TestData();

        Test.startTest();
        // CSP-1999 
        // Account testAccount1 = TestClassUtility.createAccount(false, testBrand, testCategory, testMarket);
        Account testAccount1 = TestClassUtility.createAccount(false, testCategory, testMarket);
        testAccount1.BillingPostalCode = zip.zipCode__c;
        testAccount1.Region__c = 'Austin/Central Texas/Texas Hill Country';
        testAccount1.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testAccount1.OwnerId = userList[0].Id;
        testAccount1.Name = 'test name';
        insert testAccount1;
        List<Account> lstacc1 =[select id from Account where id=: testAccount1.id];
        system.assertEquals(1,lstacc1.size());
        
        Zuora__CustomerAccount__c customerAccount1 = TestClassUtility.createCustomerAccount(false, testAccount1);
        customerAccount1.Name = 'whatever';
        insert customerAccount1;

        testAccount1.Name = 'some other test name';
        update testAccount1;
        Test.stopTest();
    }

    private static testmethod void test_UpdateContactAddress() {
        create_TestData();

      Test.startTest();
      // CSP-1999 
        // Account testAccount1 = TestClassUtility.createAccount(false, testBrand, testCategory, testMarket);
        Profile localsalesdatateamProfile = [SELECT Id FROM Profile WHERE Name='Local Sales Data Team'];
        User userTorun = [SELECT Id FROM User WHERE ProfileId = :localsalesdatateamProfile.Id limit 1];


        System.runAs(userTorun) {

            Account testAccount1 = TestClassUtility.createAccount(false, testCategory, testMarket);
            testAccount1.BillingStreet = '100 Pennock Court';
            testAccount1.BillingCity = 'Folsom';
            testAccount1.BillingState = 'California';
            testAccount1.BillingPostalCode = zip.zipCode__c + '1';
            testAccount1.BillingCountry = 'United States';
            testAccount1.Region__c = 'Austin/Central Texas/Texas Hill Country';
            testAccount1.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
            testAccount1.OwnerId = userList[0].Id;
            testAccount1.Name = 'testing name';
            testAccount1.Fulfill_Storefront__c = false;
            testAccount1.Past_Due_Balance__c = 12.34;

            insert testAccount1;
            List<Account> lstacc1 =[select id from Account where id=: testAccount1.id];
            system.assertEquals(1,lstacc1.size());

            Contact testContact1 = TestClassUtility.createContact(false, testAccount1);
            testContact1.Same_Address_as_Account__c = true;
            testContact1.Email = 'test@test.com';
            testAccount1.Past_Due_Balance__c = 23.45;
            insert testContact1;
            List<Contact> testcon1 =[select id from Contact where id=: testContact1.id];
            system.assertEquals(1,testcon1.size());

            AccountContactRole accConrole = new AccountContactRole();
            accConrole.AccountId = testAccount1.Id;
            accConrole.ContactId = testContact1.Id;
            accConrole.Role = 'Primary';
            Insert accConrole;
            List<AccountContactRole> testaccconrole1 =[select id from AccountContactRole where id=: accConrole.id];
            system.assertEquals(1,testaccconrole1.size());

            testAccount1.BillingStreet = '666 Pennock Court';
            testAccount1.BillingPostalCode = zip.zipCode__c + '11';
            //testAccount1.Fulfill_Storefront__c = true;
            testAccount1.Account_Status__c = 'Qualified';
            testAccount1.Past_Due_Balance__c = 0;
            update testAccount1;
            List<Account> lstacc11 =[select id from Account where id=: testAccount1.id];
            system.assertEquals(1,lstacc11.size());

        }

        Test.stopTest();
    }     

    private static testmethod void test_UpdateContactAddress1() {
        create_TestData();

      Test.startTest();
      // CSP-1999 
        // Account testAccount1 = TestClassUtility.createAccount(false, testBrand, testCategory, testMarket);
        Profile localsalesdatateamProfile = [SELECT Id FROM Profile WHERE Name='Local Sales Data Team'];
        User userTorun = [SELECT Id FROM User WHERE ProfileId = :localsalesdatateamProfile.Id limit 1];

        Account testAccount1 = TestClassUtility.createAccount(false, testCategory, testMarket);
        testAccount1.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testAccount1.Name = 'testing ttesting name name';
        //testAccount1.Account_Status__c = 'New';
        insert testAccount1;
        List<Account> lstacc11 =[select id from Account where id=: testAccount1.id];
        system.assertEquals(1,lstacc11.size());

        System.runAs(userTorun) {

            testAccount1.Account_Status__c = 'Qualified';
            update testAccount1;
            List<Account> lstacc1 =[select id from Account where id=: testAccount1.id];
            system.assertEquals(1,lstacc1.size());

        }

        Test.stopTest();
    }     

    private static testmethod void test_callout() {
        create_TestData();

        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account", "companyId" : "testdynamicleadid"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        XO_Group_Settings__c xoSetting = XO_Group_Settings__c.getInstance();
        xoSetting.Turn_on_Fulfillment_Callouts__c = true;
        upsert xoSetting;
        System.debug(LoggingLevel.INFO, '*** limits.getQueries 1: ' + limits.getQueries());


        CountryZipREGEX__c testCzr = TestClassUtility.createContryZipREGEX(true,'United States','US');

        DefaulCBSSValues__c defCBSScustomSetting = new DefaulCBSSValues__c();
        defCBSScustomSetting.Name = 'testInvoiceTemplate';
        defCBSScustomSetting.Phone__c = '(800)843-4983';
        defCBSScustomSetting.Email__c = 'test@xogrp.com';
        insert defCBSScustomSetting;      

        Lead_and_Account_Scoring__c laas = new Lead_and_Account_Scoring__c();
        laas.Name = 'Name Not Blank';
        laas.Apply_to_Lead_Score__c = true;
        laas.Comparison_Type__c = 'Not Blank';
        laas.Points__c = 5;
        laas.Apply_to_Account_Score__c = true;
        laas.Field_API_Name__c = 'Name';
        insert laas; 

        Test.startTest();
        
        Account testAcc = TestClassUtility.createAccount(false, testCategory, testMarket);
        testAcc.BillingStreet = '100 Pennock Court';
        testAcc.BillingCity = 'Folsom';
        testAcc.BillingState = 'California';
        testAcc.BillingPostalCode = zip.zipCode__c;
        testAcc.ShippingPostalCode = zip.zipCode__c;
        testAcc.BillingCountry = 'United States';
        testAcc.Region__c = 'Austin/Central Texas/Texas Hill Country';
        testAcc.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testAcc.OwnerId = userList[0].Id;
        testAcc.Name = 'testing name';
        testAcc.Fulfill_Storefront__c = false;
        // testAcc.Past_Due_Balance__c = 12.34;
        insert testAcc;

        Contact testContact1 = TestClassUtility.createContact(false, testAcc);
        testContact1.Same_Address_as_Account__c = true;
        testContact1.Email = 'test@test.com';
        insert testContact1;

        AccountContactRole accConrole = new AccountContactRole();
        accConrole.AccountId = testAcc.Id;
        accConrole.ContactId = testContact1.Id;
        accConrole.Role = 'Primary';
        Insert accConrole;

        List<Account> lstacc1 =[select id from Account where id=: testAcc.id];
        system.assertEquals(1,lstacc1.size());
  
        Account testParentAcc = TestClassUtility.createAccount(false, testCategory, testMarket);
        testParentAcc.DynamicsAccID__c = 'tes7890AcccID1';
        testParentAcc.Fulfill_Storefront__c = true;
        testParentAcc.BillingPostalCode = zip.zipCode__c;
        testParentAcc.ShippingPostalCode = zip.zipCode__c;
        insert testParentAcc;
        List<Account> lstacc2 =[select id from Account where id=: testParentAcc.id];
        system.assertEquals(1,lstacc2.size());

        Account testParentAcc2 = TestClassUtility.createAccount(false, testCategory, testMarket);
        testParentAcc2.DynamicsAccID__c = 't1234567890AccID2';
        testParentAcc2.Name = 'testParentAcc2';
        testParentAcc2.Website = 'www.test.com';
        testParentAcc2.Phone = '1234567890';
        testParentAcc2.BillingStreet = 'test street';
        testParentAcc2.BillingCity = 'New York';
        testParentAcc2.BillingState = 'New York';
        testParentAcc2.BillingPostalCode = zip.zipCode__c;
        testParentAcc2.ShippingPostalCode = zip.zipCode__c;
        insert testParentAcc2;
        List<Account> lstacc3 =[select id from Account where id=: testParentAcc2.id];
        system.assertEquals(1,lstacc3.size());

        Test.stopTest();

        testAcc.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testAcc.ParentId = null;
        testAcc.DynamicsAccID__c = testParentAcc.Id;
        //testAcc.Fulfill_Storefront__c = true;
        testAcc.Ignore_Parent_Account__c = false;
        update testAcc;

        testAcc.Ignore_Parent_Account__c = true; 
        update testAcc;

        testAcc.Storefront_Status__c = 'Claimed';
        testAcc.Fulfilled__c = true;
        testAcc.BillingPostalCode = zip.zipCode__c;
        testAcc.ShippingPostalCode = zip.zipCode__c; 
        update testAcc;

        testAcc.BillingPostalCode = '12345';
        testAcc.Ignore_Parent_Account__c = false; 
        testAcc.ParentId =testParentAcc2.Id;
        User u =[SELECT id FROM User WHERE Profile.Name = 'Local Sales Data Team' Limit 1];
        testAcc.OwnerId = u.id;
        update testAcc;      

        System.debug(LoggingLevel.INFO, '*** limit.getQueries 4: ' + limits.getQueries());

        Category__C testCategory2 = TestClassUtility.createCategory(true);

        Market__c testMarket2 = new Market__c();
        testMarket.Name = 'TX - Austin - 111';
        testMarket.Short_Description__c = 'TX-Austin';
        testMarket.Market_Id__c = '191';
        // testMarket2.Market_ID__c = '222';
        testMarket2.Active__c = true;
        testMarket2.Local_Sales_Region__c = testRegion.id;
        testMarket2.Short_Description__c = 'abc';
        insert testMarket2;
        List<Market__c> lstmarket1 =[select id from Market__c where id=: testMarket2.id];
        system.assertEquals(1,lstmarket1.size());

        testAcc.Primary_Category__c = testCategory2.Id;
        testAcc.Name = 'test Account';
        testAcc.Local_Sales_Market__c = testMarket2.Id;
        update testAcc;
    }

    private static testmethod void test_cfullfillment() {
        create_TestData();

        Account testAccount2 = TestClassUtility.createAccount(false, testCategory, testMarket);
        testAccount2.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testAccount2.Fulfill_Storefront__c = true;
        testAccount2.DynamicsAccID__c = 'testDynamicsAccID';
        testAccount2.Ignore_Parent_Account__c = true;
        testAccount2.Strategy_Specialist__c = userlist[0].id;
        testAccount2.Manual_VIP_Program_Status__c = 'VIP';
        insert testAccount2;
        List<Account> lstacc111 =[select id from Account where id=: testAccount2.id];
        system.assertEquals(1,lstacc111.size());        


        Account testAccParent22 = TestClassUtility.createAccount(false, testCategory, testMarket);
        testAccParent22.DynamicsAccID__c = 'testParentAccID22';
        insert testAccParent22;

        Account testAcc3 = TestClassUtility.createAccount(false, testCategory, testMarket);
        testAcc3.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testAcc3.ParentId = testAccParent22.Id;
        testAcc3.DynamicsAccID__c = testAccParent22.Id;
        testAcc3.Fulfill_Storefront__c = true;
        testAcc3.Ignore_Parent_Account__c = false;
        insert testAcc3;
        List<Account> lstacc1111 =[select id from Account where id=: testAcc3.id];
        system.assertEquals(1,lstacc1111.size());
        
        System.debug(LoggingLevel.INFO, '*** limits.getQueries 4: ' + limits.getQueries());



    }

    private static testmethod void test_accOwnerAssignment() {
        create_TestData();
   
        Account testParentAcc = TestClassUtility.createAccount(false, testCategory, testMarket);
        testParentAcc.DynamicsAccID__c = 'testParentAccID';
        testParentAcc.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        insert testParentAcc;
        List<Account> lstacc1 =[select id from Account where id=: testParentAcc.id];
        system.assertEquals(1,lstacc1.size());

        Account testAcc = TestClassUtility.createAccount(false, testCategory, testMarket);
        testAcc.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testAcc.ParentId = testParentAcc.Id;
        User u1 =[SELECT id FROM User WHERE Profile.Name = 'Local Sales Data Team' Limit 1];
        testAcc.OwnerId = u1.id;
        insert testAcc;
        List<Account> lstacc2 =[select id from Account where id=: testAcc.id];
        system.assertEquals(1,lstacc2.size());

        Test.startTest();

        Account testAcc2 = TestClassUtility.createAccount(false, testCategory, testMarket);
        testAcc2.OwnerId = userList[0].id;
        insert testAcc2;
        List<Account> lstacc3 =[select id from Account where id=: testAcc2.id];
        system.assertEquals(1,lstacc3.size());

        testAcc2.OwnerId = userList[1].Id;
        testAcc2.ParentId = null;
        update testAcc2;

        User u =[SELECT id FROM User WHERE Profile.Name = 'Local Sales Data Team' Limit 1];

        System.runAs(u){
            testAcc2.Account_Status__c = 'Disqualified';
            testAcc2.Negative_Disposition_Reason__c = 'Do Not Contact';
            update testAcc2;

            testAcc2.Account_Status__c = 'Qualified';
            update testAcc2;

            testAcc2.Account_Status__c = 'Disqualified';
            testAcc2.Negative_Disposition_Reason__c = 'Do Not Contact';
            update testAcc2;
            testAcc2.Related_to_Paid_Media__c = true;
            testAcc2.Account_Status__c = 'Qualified';
            update testAcc2;
        }

        Test.stopTest();

        AccountTriggerHandler ath = new AccountTriggerHandler();
        ath.beforeDelete(testParentAcc);
        ath.afterDelete(testParentAcc);
        Set<ID> deleteAccountIdSet = New Set<ID>();
        deleteAccountIdSet.add(testParentAcc.Id);
        ath.beforeAndFinally();
    }

    private static testmethod void test_beforeupdate() {
        create_TestData();
    
        userList[1].Strategy_Specialist__c = userlist[0].Id;
        userList[1].SOR__c = userlist[0].Id;
        userList[1].ARR__c = userlist[0].Id;
        //update userList[1];

        Account testParentAcc = TestClassUtility.createAccount(false, testCategory, testMarket);
        testParentAcc.DynamicsAccID__c = 'testParentAccID';
        testParentAcc.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testParentAcc.OwnerId = userList[0].Id;
        insert testParentAcc;
        List<Account> lstacc3 =[select id from Account where id=: testParentAcc.id];
        system.assertEquals(1,lstacc3.size());

        Account testAcc = TestClassUtility.createAccount(false, testCategory, testMarket);
        testAcc.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testAcc.OwnerId = userList[1].Id;
        testAcc.CBBS__c = userList[0].Id;
        insert testAcc;
        List<Account> lstacc2 =[select id from Account where id=: testAcc.id];
        system.assertEquals(1,lstacc2.size());

        Test.startTest();

        Account testParentAcc2 = TestClassUtility.createAccount(false, testCategory, testMarket);
        testParentAcc2.DynamicsAccID__c = 'testParentId abc';
        testParentAcc2.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        User u2 =[SELECT id FROM User WHERE Profile.Name = 'Local Sales Data Team' Limit 1];
        testParentAcc2.OwnerId = u2.id;
        insert testParentAcc2;
        List<Account> lstacc1 =[select id from Account where id=: testParentAcc2.id];
        system.assertEquals(1,lstacc1.size());

        testAcc.ParentId = testParentAcc.Id;
        update testAcc;

        testAcc.ParentId = testParentAcc2.Id;
        update testAcc;

        Test.stopTest();

    }

    private static testmethod void test_InsertUSAccPostalCode() {
        create_TestData();
        List<Account> list_AccountsInsert = new List<Account>();

        Account testUSAccFullShipping = TestClassUtility.createAccount(false);
        testUSAccFullShipping.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testUSAccFullShipping.ShippingCountryCode = 'US';
        testUSAccFullShipping.ShippingPostalCode = '100051001';
        testUSAccFullShipping.BillingCountryCode = 'US';
        testUSAccFullShipping.BillingPostalCode = '100051001';
        list_AccountsInsert.add(testUSAccFullShipping);

        Account testUSAccNormalShipping = TestClassUtility.createAccount(false);
        testUSAccNormalShipping.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testUSAccNormalShipping.ShippingCountryCode = 'US';
        testUSAccNormalShipping.ShippingPostalCode = '10005';
        list_AccountsInsert.add(testUSAccNormalShipping);

        Account testUSAccFullBilling = TestClassUtility.createAccount(false);
        testUSAccFullBilling.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testUSAccFullBilling.BillingCountryCode = 'US';
        testUSAccFullBilling.ShippingCountryCode = null;
        testUSAccFullBilling.BillingPostalCode = '100051001';
        testUSAccFullBilling.ShippingPostalCode = null;
        list_AccountsInsert.add(testUSAccFullBilling);

        Account testUSAccNormalBilling = TestClassUtility.createAccount(false);
        testUSAccNormalBilling.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testUSAccNormalBilling.BillingCountryCode = 'US';
        testUSAccNormalBilling.ShippingCountryCode = null;
        testUSAccNormalBilling.BillingPostalCode = '10005';
        testUSAccNormalBilling.ShippingPostalCode = null;
        list_AccountsInsert.add(testUSAccNormalBilling);

        Account testUSAccBlank = TestClassUtility.createAccount(false);
        testUSAccBlank.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testUSAccBlank.BillingCountryCode = null;
        testUSAccBlank.ShippingCountryCode = null;
        testUSAccBlank.BillingPostalCode = null;
        testUSAccBlank.ShippingPostalCode = null;
        testUSAccBlank.Local_Sales_Market__c = null;
        list_AccountsInsert.add(testUSAccBlank);

        Test.startTest();
        
        insert list_AccountsInsert;
       
        Test.stopTest();

        for(Account assertAccount : [SELECT Local_Sales_Market__c, Zip__c 
                                        FROM Account 
                                        WHERE Id IN: list_AccountsInsert]){
            if(assertAccount.Id == testUSAccFullShipping.Id){
                System.assert(assertAccount.Local_Sales_Market__c == testMarket.Id);
                System.assert(assertAccount.Zip__c == zipUS.Id);
            }else if(assertAccount.Id == testUSAccBlank.Id){
                System.assert(assertAccount.Local_Sales_Market__c == null);
                System.assert(assertAccount.Zip__c == null);
            }
        }
    }

    private static testmethod void test_UpdateUSAccPostalCode() {
        create_TestData();
        List<Account> list_AccountsInsert = new List<Account>();

        Account testUSAccFull = TestClassUtility.createAccount(false);
        testUSAccFull.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testUSAccFull.ShippingCountryCode = 'US';
        testUSAccFull.BillingCountryCode = 'US';
        testUSAccFull.ShippingPostalCode = '10003';

        Account testUSAccBilling = TestClassUtility.createAccount(false);
        testUSAccBilling.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testUSAccBilling.ShippingCountryCode = 'US';
        testUSAccBilling.BillingCountryCode = 'US';
        testUSAccBilling.ShippingPostalCode = '10005';

        insert new List<Account>{testUSAccFull, testUSAccBilling};
        Test.startTest();

        testUSAccFull.ShippingPostalCode = '10005';
        
        testUSAccBilling.ShippingPostalCode = null;
        testUSAccBilling.ShippingCountryCode = null;
        testUSAccBilling.ShippingCountry = null;
        testUSAccBilling.ShippingStateCode = null;
        testUSAccBilling.ShippingState = null;
        testUSAccBilling.ShippingStreet = null;
        testUSAccBilling.ShippingCity = null;

        update new List<Account>{testUSAccFull, testUSAccBilling};
        Test.stopTest();

        Account accAssertFull = [SELECT Local_Sales_Market__c, Zip__c FROM Account WHERE Id =: testUSAccFull.Id LIMIT 1];
        System.assert(accAssertFull.Local_Sales_Market__c == testMarket.Id);
        System.assert(accAssertFull.Zip__c == null);
    }

    private static testmethod void test_InsertCAAccPostalCode() {
        create_TestData();
        List<Account> list_AccountsInsert = new List<Account>();

        Account testCAAccFull = TestClassUtility.createAccount(false);
        testCAAccFull.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testCAAccFull = generateCAAddress(testCAAccFull);
        list_AccountsInsert.add(testCAAccFull);

        Account testCAAccBilling = TestClassUtility.createAccount(false);
        testCAAccBilling.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testCAAccBilling = generateCAAddress(testCAAccBilling);       
        testCAAccBilling.ShippingPostalCode = null;
        testCAAccBilling.ShippingCountryCode = null;
        testCAAccBilling.ShippingCountry = null;
        testCAAccBilling.ShippingStateCode = null;
        testCAAccBilling.ShippingState = null;
        testCAAccBilling.ShippingStreet = null;
        testCAAccBilling.ShippingCity = null;
        testCAAccBilling.BillingPostalCode = 'B1A 1A1';
        list_AccountsInsert.add(testCAAccBilling);

        Account testCAAccState = TestClassUtility.createAccount(false);
        testCAAccState.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testCAAccState = generateCAAddress(testCAAccState);       
        testCAAccState.ShippingPostalCode = null;
        testCAAccState.ShippingState = 'Ontario';
        testCAAccState.ShippingStateCode = 'ON';
        list_AccountsInsert.add(testCAAccState);

        Test.startTest();
        
        insert list_AccountsInsert;
       
        Test.stopTest();

        for(Account assertAccount : [SELECT Local_Sales_Market__c, Zip__c
                                        FROM Account 
                                        WHERE Id IN: list_AccountsInsert]){
            if(assertAccount.Id == testCAAccFull.Id){
                System.assert(assertAccount.Local_Sales_Market__c == testCAMarket.Id);
                System.assert(assertAccount.Zip__c == zipCA.Id);
            }else if(assertAccount.Id == testCAAccBilling.Id){
                System.assert(assertAccount.Local_Sales_Market__c == testCAMarket2.Id);
                System.assert(assertAccount.Zip__c == null);
            }else if(assertAccount.Id == testCAAccState.Id){  
                // Commented by CAN market splits go live          
                // System.assert(assertAccount.Local_Sales_Market__c == testCAMarket.Id);
                // System.assert(assertAccount.Zip__c == zipCA.Id);
            }
        }
    }

    private static testmethod void test_InsertGZAccPostalCode() {
        create_TestData();

        Account testGZAcc = TestClassUtility.createAccount(false);
        testGZAcc.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();          
        testGZAcc = generateGZAddress(testGZAcc); 

        Test.startTest();
        
        insert testGZAcc;
       
        Test.stopTest();

        Account assertAccount = [SELECT Local_Sales_Market__c, Zip__c
                                        FROM Account 
                                        WHERE Id =: testGZAcc.Id LIMIT 1];
        System.assert(assertAccount.Local_Sales_Market__c == null);
        System.assert(assertAccount.Zip__c == null);
    }

    private static testmethod void test_UpdateGZAccPostalCode() {
        create_TestData();
        CountryZipREGEX__c testCzr = TestClassUtility.createContryZipREGEX(true,'United States','US');

        Account testGZAcc = TestClassUtility.createAccount(false);
        testGZAcc.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();   
        testGZAcc.ShippingPostalCode = '10006';
        testGZAcc.BillingPostalCode = '10006';
        Account testGZAcc2 = TestClassUtility.createAccount(false);
        testGZAcc2.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testGZAcc2.ShippingPostalCode = '10006';
        testGZAcc2.BillingPostalCode = '10006';
        Account testUSAcc = TestClassUtility.createAccount(false);
        testUSAcc.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testUSAcc.ShippingPostalCode = '10006';
        testUSAcc.BillingPostalCode = '10006';
        insert new List<Account>{testGZAcc, testGZAcc2, testUSAcc};

        Test.startTest();

        testGZAcc = generateGZAddress(testGZAcc);

        testGZAcc2 = generateGZAddress(testGZAcc2);
        testGZAcc2.BillingCountryCode = 'US';
        testGZAcc2.ShippingCountryCode = 'US';

        testUSAcc.BillingCountry = null;
        testUSAcc.BillingCountryCode = null;
        testUSAcc.ShippingCountryCode = null;
        testUSAcc.ShippingCountry = null;

        update new List<Account>{testGZAcc, testGZAcc2, testUSAcc};

        Test.stopTest();

        for(Account assertAccount : [SELECT Local_Sales_Market__c, Zip__c 
                                        FROM Account
                                        WHERE Id =: testGZAcc.Id 
                                        OR Id =: testGZAcc2.Id
                                        OR Id =: testUSAcc.Id]){
            System.assert(assertAccount.Local_Sales_Market__c == null);
            System.assert(assertAccount.Zip__c == null);
        }
    }

    private static testmethod void test_UpdateCAAccPostalCode() {
        create_TestData();

        Account testCAAccFull = TestClassUtility.createAccount(false);
        testCAAccFull.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testCAAccFull = generateCAAddress(testCAAccFull);
        testCAAccFull.Phone_Extension__c = '123456';

        Account testCAAccOnlyBilling = TestClassUtility.createAccount(false);
        testCAAccOnlyBilling.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testCAAccOnlyBilling = generateCAAddress(testCAAccOnlyBilling);        

        Account testCAAccState = TestClassUtility.createAccount(false);
        testCAAccState.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testCAAccState = generateCAAddress(testCAAccState);        

        insert new List<Account>{testCAAccFull, testCAAccOnlyBilling, testCAAccState};

        Test.startTest();

        testCAAccFull.ShippingPostalCode = 'A1A 1B1';
        testCAAccFull.BillingPostalCode = 'A1A 1B1';
    
        testCAAccOnlyBilling.ShippingCountryCode = null;
        testCAAccOnlyBilling.ShippingCountry = null;
        testCAAccOnlyBilling.ShippingState = null;
        testCAAccOnlyBilling.ShippingStateCode = null;
        testCAAccOnlyBilling.ShippingCity = null;
        testCAAccOnlyBilling.ShippingPostalCode = null;

        testCAAccState.ShippingPostalCode = null;
        testCAAccState.ShippingState = 'Ontario';
        testCAAccState.ShippingStateCode = 'ON';
        testCAAccState.Phone_Extension__c = '123456';

        update new List<Account>{testCAAccFull, testCAAccOnlyBilling, testCAAccState};

        Test.stopTest();
        for(Account assertAccount : [SELECT Local_Sales_Market__c, Zip__c 
                            FROM Account 
                            WHERE Id =: testCAAccFull.Id 
                            OR Id =: testCAAccOnlyBilling.Id 
                            OR Id =: testCAAccState.Id]){
            if(assertAccount.Id == testCAAccFull.Id){
                System.assert(assertAccount.Local_Sales_Market__c == testCAMarket.Id);
                System.assert(assertAccount.Zip__c == zipCA.Id);
            }else if(assertAccount.Id == testCAAccOnlyBilling.Id){
                System.assert(assertAccount.Local_Sales_Market__c == testCAMarket.Id);
                System.assert(assertAccount.Zip__c == zipCA.Id);
            }else if(assertAccount.Id == testCAAccState.Id){
                // Commented by CAN market splits go live 
                // System.assert(assertAccount.Local_Sales_Market__c == testCAMarket2.Id);
                // System.assert(assertAccount.Zip__c == zipCA.Id);
            }
        }
    }

    private static testmethod void test_ValidateAccPostalCode() {
        create_TestData();
        CountryZipREGEX__c testCzr = TestClassUtility.createContryZipREGEX(true,'United States','US');

        List<Account> list_AccountsInsert = new List<Account>();

        Account testCAAccIncomplete = TestClassUtility.createAccount(false);
        testCAAccIncomplete.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testCAAccIncomplete = generateCAAddress(testCAAccIncomplete);
        testCAAccIncomplete.ShippingPostalCode = 'A1A';
        testCAAccIncomplete.BillingPostalCode = 'A1A';
        list_AccountsInsert.add(testCAAccIncomplete);

        Account testUSAccInvalid = TestClassUtility.createAccount(false);
        testUSAccInvalid.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testUSAccInvalid.BillingCountryCode = 'US';
        testUSAccInvalid.ShippingCountryCode = 'US';
        testUSAccInvalid.BillingPostalCode = '1abcdefgh';
        testUSAccInvalid.ShippingPostalCode = '1abcdefgh';
        list_AccountsInsert.add(testUSAccInvalid);

        Account testCAAccValid = TestClassUtility.createAccount(false);
        testCAAccValid.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
        testCAAccValid = generateCAAddress(testCAAccValid);
        list_AccountsInsert.add(testCAAccValid);

        Test.startTest();

        Database.insert(list_AccountsInsert,false);
        
        Test.stopTest();

        System.assert(testCAAccIncomplete.Id == null);
        System.assert(testUSAccInvalid.Id == null);
        System.assert(testCAAccValid.Id != null);
    }

    private static Account generateCAAddress(Account acc) {
        if(acc != null){
            acc.BillingCountryCode = 'CA';
            acc.ShippingCountryCode = 'CA';
            acc.BillingCity = 'ST. JOHN\'S';
            acc.BillingState = 'Newfoundland and Labrador';
            acc.BillingCountry = 'Canada';
            acc.BillingPostalCode = 'A1A 1A1';
            acc.ShippingCountry = 'Canada';
            acc.ShippingState = 'Newfoundland and Labrador';
            acc.ShippingCity = 'ST. JOHN\'S';
            acc.ShippingPostalCode = 'A1A 1A1';
        }
        return acc;
    }
    
    private static Account generateGZAddress(Account acc) {
        if(acc != null){
            acc.BillingCountryCode = 'CN';
            acc.ShippingCountryCode = 'CN';
            acc.BillingCity = 'Guangzhou';
            acc.BillingState = 'Guangdong';
            acc.BillingCountry = 'China';
            acc.BillingPostalCode = '510000';
            acc.ShippingCountry = 'China';
            acc.ShippingState = 'Guangdong';
            acc.ShippingCity = 'Guangzhou';
            acc.ShippingPostalCode = '510000';
        }
        return acc;
    }

    private static Canadian_Postal_Code_Market_Mapping__c generateCanadianPostalCodeMapping(Boolean insertRecord) {
        Canadian_Postal_Code_Market_Mapping__c testCanadianPostalCodeMapping = new Canadian_Postal_Code_Market_Mapping__c();
        testCanadianPostalCodeMapping.Canadian_Postal_Code__c = 'B';
        testCanadianPostalCodeMapping.Name = 'B-308';
        testCanadianPostalCodeMapping.Market_Id__c = '308';
        testCanadianPostalCodeMapping.Default_State_Code__c = 'ON';
        
        if(insertRecord) {
          insert testCanadianPostalCodeMapping;
        }

        return testCanadianPostalCodeMapping;
    }

    private static void create_TestData(){
        generateCanadianPostalCodeMapping(true);
        
        userList = [select Id, Name, Alias from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        rtAccountMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        rtLeadMapByName = Schema.SObjectType.Lead.getRecordTypeInfosByName();
        
        if(Deactivate_Trigger__c.getValues('Attachment') == null){
            dtatt = TestClassUtility.createAttachmentDeactivateTriggerSetting(true);
        }
        
        GQPF = TestClassUtility.generateQuotePdfConfig(false);
        GQPF.URL__c = 'www.baidu.com';
        insert GQPF;

        testRegion = TestClassUtility.createRegion(true);
        testMarket = TestClassUtility.createMarket(false);
        testMarket.Name = 'TestMarket - US - 222';
        testMarket.Market_ID__c = '222';
        testMarket.Active__c = true;
        testMarket.Local_Sales_Region__c = testRegion.id;

        testCAMarket = TestClassUtility.createMarket(false);
        testCAMarket.Name = 'TestMarket - CA - 306';
        testCAMarket.Market_ID__c = '306';
        testCAMarket.Active__c = true;
        testCAMarket.Country__c = 'CA';

        testCAMarket2 = TestClassUtility.createMarket(false);
        testCAMarket2.Name = 'TestMarket - CA - 308';
        testCAMarket2.Market_ID__c = '308';
        testCAMarket2.Active__c = true;
        testCAMarket2.Country__c = 'CA';
        insert new List<Market__c>{testMarket, testCAMarket, testCAMarket2};

        testCategory = TestClassUtility.createCategory(true);
        
        ma = TestClassUtility.createMetroArea(true);
        
        zip = TestClassUtility.createZip(false);
        zip.MetroArea__c = ma.id;
        zip.ZipCode__c = '99999';
        zip.Portfolio__c = 'Senior Sales Executive';
        zip.Name = '99999';
        zip.Local_Market__c = testMarket.id;

        zipUS = TestClassUtility.createZip(false);
        zipUS.MetroArea__c = ma.id;
        zipUS.ZipCode__c = '10005';
        zipUS.Portfolio__c = 'Senior Sales Executive';
        zipUS.Name = '10005';
        zipUS.Local_Market__c = testMarket.id;

        zipCA = TestClassUtility.createZip(false);
        zipCA.MetroArea__c = ma.id;
        zipCA.ZipCode__c = 'A1A';
        zipCA.Portfolio__c = 'Senior Sales Executive';
        zipCA.Name = 'A1A';
        zipCA.Local_Market__c = testCAMarket.Id;
        insert new list<Zip__c>{zip, zipCA, zipUS};
    }
}