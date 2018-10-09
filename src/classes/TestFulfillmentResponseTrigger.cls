@isTest
private class TestFulfillmentResponseTrigger{
    
    @isTest static void test_method_one() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                                       'Complete',
                                                                       '{"companyName": "Test Account"}',
                                                                       null);
        Test.setMock(HttpCalloutMock.class, fakeResponse); 
        Map<String,Schema.RecordTypeInfo> rtLeadMapByName = Schema.SObjectType.Lead.getRecordTypeInfosByName();
        
        /*testDataFactoryT tdf = new testDataFactoryT();
		tdf.CreateLocalTestObjects();*/
        
        /* Date: 6th July: Local Data creation required for test class */
        Deactivate_Trigger__c dtTrigger = TestClassUtility.createNotesDeactivateTriggerSetting(true);
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        // CSP-1999 Map<String,Schema.RecordTypeInfo> rtBrandMapByName = Schema.SObjectType.Brand__c.getRecordTypeInfosByName();
	    // Brand__c brand = TestClassUtility.createBrand(false);
	    // brand.RecordTypeId = rtBrandMapByName.get('Local').getRecordTypeId();
	    // insert brand;
        // Category__c category = TestClassUtility.createCategory(true,brand);
        Category__c category = TestClassUtility.createCategory(true);
        Market__c market = TestClassUtility.createMarket(false);
        market.Market_ID__c ='222';
        insert market;
        Zip__c zipCode = TestClassUtility.createZip(true);
        // CSP-1999 
        // Account testAccount = TestClassUtility.createAccount(false,brand,category,market);
        Account testAccount = TestClassUtility.createAccount(false,category,market);
        //testAccount.Operative_Owner__c = userList[0].Name;
        testAccount.Type = 'Advertiser';
        testAccount.DynamicsAccID__c = 'testDynamicsLeadID';
        testAccount.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
        testAccount.BU__c = 'Local';
        insert testAccount;      
        
        //Commented creation of old Partner Fulfillment response and created data using TestClassUtilty
        /*Partner_Fulfillment_Response__c testPFR = new Partner_Fulfillment_Response__c();
        testPFR.Object_Type__c = 'Account';
        testPFR.Response_JSON__c = '{"accountId":"2192345c-d0db-4bec-8bc1-a56e0173e0de","companyId":"08cf5c27-d577-4e1f-85a5-6c673032208d","errors":"testerrors"}';
        testPFR.Type__c = 'Account Update';
        insert testPFR;
        */
        Partner_Fulfillment_Response__c testPFR = TestClassUtility.createPartnerFulfillmentResponse(true); 
                
        /*Fulfillment_Response__c testFR = new Fulfillment_Response__c();
        testFR.Partner_Fulfillment_Response__c = testPFR.id;
        testFR.Account__c = tdf.testaccount.id;
        insert testFR;*/
        Fulfillment_Response__c testFR = TestClassUtility.createFulfillmentResponse(true,testAccount,testPFR); 
        
        /*Local_Sales_Rep_Assignment__c  lsra = new Local_Sales_Rep_Assignment__c();
        lsra.Name = 'test name';
        lsra.Category__c = tdf.testCategory.id;
        //lsra.Market__c = tdf.testMarket.id;
        lsra.Sales_Rep__c = UserInfo.getUserId();
        lsra.Zip_Code__c = tdf.testzip.id;
        insert lsra;*/
        Local_Sales_Rep_Assignment__c lsra = TestClassUtility.createLocalSalesRepAssignment(true, category, null, zipCode);
                
        /*Lead testLead = new Lead();
        testLead.FirstName='ad8s9ufvmcfa89r73';
        testLead.LastName='34v5c6gd7jbzcad';
        testLead.Phone='98745678987';
        testLead.Email='adsfadsfvac3rfxsxd33333@test.com';
        testLead.Company='TesadsfvadsfZSDeraxsd4AWZsdxsze';
        testLead.Local_Sales_Market__c = tdf.testMarket.id;
        testLead.Primary_Category__c = tdf.testCategory.id;
        testLead.Primary_Brand__c = tdf.testBrand.id;
        testLead.recordtypeId = rtLeadMapByName.get('Local').getRecordTypeId();
        testLead.PostalCode = tdf.testzip.Zipcode__c;
        testLead.DynamicsLeadID__c = 'testDynamicsLeadID';
		*/
        // CSP-1999
        // Lead testLead = TestClassUtility.createLead(false, market, category, brand);
        Lead testLead = TestClassUtility.createLead(false, market, category);
        testLead.Phone='98745678987';
		testLead.recordtypeId = rtLeadMapByName.get('Local').getRecordTypeId();        
        testLead.DynamicsLeadID__c = 'testDynamicsLeadID';        
        insert testLead;
                
        /*Fulfillment_Response__c testFR1 = new Fulfillment_Response__c();
        testFR1.Partner_Fulfillment_Response__c = testPFR.id;
        testFR1.Lead__c = testLead.id;
        insert testFR1;
		*/     
        
        Fulfillment_Response__c testFR1 = TestClassUtility.createFulfillmentResponse(false,null,null);
        testFR1.Partner_Fulfillment_Response__c = testPFR.id;
		testFR1.Lead__c = testLead.id;
        insert testFR1;
    }
}