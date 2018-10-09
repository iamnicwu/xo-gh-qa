@isTest
private class BatchRetrieveSalesOrderStatusTest {

  	@testSetup static void testMethod1() {

		SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                         'Complete',
                                         '{"companyName": "Test Account"}',
                                         null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);


		// XO_Group_Settings__c xoSetting = XO_Group_Settings__c.getInstance();
		// xoSetting.Turn_on_Fulfillment_Callouts__c = true;
		// upsert xoSetting;

	  	RecordType rt = [select id FROM RecordType where DeveloperName ='RFP' and SobjectType = 'ThoughtStarter_RFP__c'  limit 1 ];
		user u = [select Id from User where UserRole.DeveloperName = 'Sales_Development' and isActive = true limit 1];

		OperativeOne__OperativeIntegrationSettings__c operativeOne = OperativeOne__OperativeIntegrationSettings__c.getOrgDefaults();
		operativeOne.OperativeOne__O1Credentials__c = 'supportops@mm.com:pwd123';
		upsert operativeOne;

		Account testAcc = TestClassUtility.createAccount(true);
 		Market__c testMarket = TestClassUtility.createMarket(true);
	    MetroArea__c testMetroArea = TestClassUtility.createMetroArea(true);
		Zip__c testZip = TestClassUtility.createZip(true, testMetroArea, testMarket);
		
		Contact testContact = TestClassUtility.createContact(false, testAcc);
	    testContact.MailingPostalCode = testZip.ZipCode__c;
        insert testContact;

		Generate_Quote_Pdf_Config__c testGQPdfC = TestClassUtility.generateQuotePdfConfig(true);
		Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();

		Opportunity oppy = TestClassUtility.createOpportunity(false);
		oppy.RecordTypeId = rtMapByName.get('National').getRecordTypeId();
		oppy.Description = 'test Description';
		oppy.OrderNumber__c = '1004125';
		oppy.StageName = 'Prospecting';
		oppy.AccStrategist__c = Userinfo.getUserId();
		insert oppy;

		Opportunity oppy2 = TestClassUtility.createOpportunity(false);
		oppy2.AccStrategist__c = UserInfo.getUserId();
		oppy2.OrderNumber__c = '1004125';
		oppy2.StageName = 'Prospecting';
		insert oppy2;


		list<Product2> productList = new list<Product2>();
		Id pricebookId = Test.getStandardPricebookId();
		Product2 prod = new Product2();
		prod.Name = 'Uncategorized Revenue';
		prod.ProductCode = 'Pro-X';
		prod.isActive = true;
		productList.add(prod);


		Product2 prod2 = new Product2();
		prod2.Name = 'Uncategorized Revenue';
		prod2.ProductCode = 'Pro-X';
		prod2.isActive = true;
		productList.add(prod2);
		List<Database.SaveResult> productSaveResults= database.insert(productList);

		list<PricebookEntry> PricebookEntryList = new list<PricebookEntry>();
		PricebookEntry pbEntry = new PricebookEntry();
		pbEntry.Pricebook2Id = pricebookId;
		pbEntry.Product2Id = prod.Id;
		pbEntry.UnitPrice = 100.00;
		pbEntry.IsActive = true;
		PricebookEntryList.add(pbEntry);

		PricebookEntry pbEntry2 = new PricebookEntry();
		pbEntry2.Pricebook2Id = pricebookId;
		pbEntry2.Product2Id = prod2.Id;
		pbEntry2.UnitPrice = 100.00;
		pbEntry2.IsActive = true;
		PricebookEntryList.add(pbEntry2);
		List<Database.SaveResult> peSaveResults= database.insert(PricebookEntryList);

		list<OpportunityLineItem> OpportunityLineItemList = new list<OpportunityLineItem>();
		OpportunityLineItem OLI = new OpportunityLineItem();
		OLI.End_Date__c = date.today().adddays(1);
		OLI.OpportunityId = oppy.id;
		OLI.Quantity = 12;
		OLI.TotalPrice = 22;
		OLI.PricebookEntryId = pbEntry.Id;
		OpportunityLineItemList.add(OLI);

	
		OpportunityLineItem OLI2 = new OpportunityLineItem();
		OLI2.End_Date__c = date.today().adddays(1);
		OLI2.OpportunityId = oppy2.id;
		OLI2.Quantity = 12;
		OLI2.TotalPrice = 22;
		OLI2.PricebookEntryId = pbEntry2.Id;
		OpportunityLineItemList.add(OLI2);
		List<Database.SaveResult> oliSaveResults= database.insert(OpportunityLineItemList);

		List<ThoughtStarter_RFP__c>  tsrlist= new List<ThoughtStarter_RFP__c>();
		ThoughtStarter_RFP__c TRFP = new ThoughtStarter_RFP__c();
		TRFP.Opportunity__c = oppy.id;
		TRFP.name = 'testTRFP';
		TRFP.RecordTypeId = rt.id;
		TRFP.Clicks__c = true;
		TRFP.CTR__c  = 10;
		TRFP.End_Actions__c = false;
		TRFP.Leads__c = false;
		TRFP.Brand_Exposure__c = false;
		TRFP.Sales_Dev_Needed__c = true;
		TRFP.Sales_Developer__c = u.id;
		TRFP.Campaign_Start_Date__c = date.today();
		TRFP.Internal_Due_Date__c = system.today();
		TRFP.Campaign_End_Date__c = date.today().adddays(1);
		// insert TRFP;
		tsrlist.add(TRFP);
		List<Database.SaveResult> taskSaveResults= database.insert(tsrlist);

		Task testTask = TestClassUtility.createTask(false);
		testTask.Subject = 'RFP has been approved and ready to be pitched to client!';
		testTask.WhatId = TRFP.id;
		insert testTask;

		// Test.startTest();
		// BatchRetrieveSalesOrderStatus bt = new BatchRetrieveSalesOrderStatus();
		// Database.executeBatch(bt,200);
		// Test.stopTest(); 

	}
	 static testMethod void testMethod3() {
		SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                         'Complete',
                                         '{"companyName": "Test Account"}',
                                         null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);	

		Test.startTest();
		BatchRetrieveSalesOrderStatus bt = new BatchRetrieveSalesOrderStatus();
		Database.executeBatch(bt,200);
		Test.stopTest(); 	 	
	 }
	
	static testMethod void testMethod2() {
	  	RecordType rt = [select id FROM RecordType where DeveloperName ='RFP' and SobjectType = 'ThoughtStarter_RFP__c'  limit 1 ];
		user u = [select Id from User where UserRole.DeveloperName = 'Sales_Development' and isActive = true limit 1];

		OperativeOne__OperativeIntegrationSettings__c operativeOne = OperativeOne__OperativeIntegrationSettings__c.getOrgDefaults();
		operativeOne.OperativeOne__O1Credentials__c = 'supportops@mm.com:pwd123';
		upsert operativeOne;

		Account testAcc = TestClassUtility.createAccount(true);
 		Market__c testMarket = TestClassUtility.createMarket(true);
	    MetroArea__c testMetroArea = TestClassUtility.createMetroArea(true);
		Zip__c testZip = TestClassUtility.createZip(true, testMetroArea, testMarket);
		
		Contact testContact = TestClassUtility.createContact(false, testAcc);
	    testContact.MailingPostalCode = testZip.ZipCode__c;
        insert testContact;

		Generate_Quote_Pdf_Config__c testGQPdfC = TestClassUtility.generateQuotePdfConfig(true);
		Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();

		Opportunity oppy = TestClassUtility.createOpportunity(false);
		oppy.RecordTypeId = rtMapByName.get('National').getRecordTypeId();
		oppy.Description = 'test Description';
		oppy.OrderNumber__c = '1004125';
		oppy.StageName = 'Prospecting';
		oppy.AccStrategist__c = Userinfo.getUserId();
		insert oppy;

		Opportunity oppy2 = TestClassUtility.createOpportunity(false);
		oppy2.AccStrategist__c = UserInfo.getUserId();
		oppy2.OrderNumber__c = '1004125';
		oppy2.StageName = 'Prospecting';
		insert oppy2;


		list<Product2> productList = new list<Product2>();
		Id pricebookId = Test.getStandardPricebookId();
		Product2 prod = new Product2();
		prod.Name = 'Uncategorized Revenue';
		prod.ProductCode = 'Pro-X';
		prod.isActive = true;
		productList.add(prod);


		Product2 prod2 = new Product2();
		prod2.Name = 'Uncategorized Revenue';
		prod2.ProductCode = 'Pro-X';
		prod2.isActive = true;
		productList.add(prod2);
		List<Database.SaveResult> productSaveResults= database.insert(productList);

		list<PricebookEntry> PricebookEntryList = new list<PricebookEntry>();
		PricebookEntry pbEntry = new PricebookEntry();
		pbEntry.Pricebook2Id = pricebookId;
		pbEntry.Product2Id = prod.Id;
		pbEntry.UnitPrice = 100.00;
		pbEntry.IsActive = true;
		PricebookEntryList.add(pbEntry);

		PricebookEntry pbEntry2 = new PricebookEntry();
		pbEntry2.Pricebook2Id = pricebookId;
		pbEntry2.Product2Id = prod2.Id;
		pbEntry2.UnitPrice = 100.00;
		pbEntry2.IsActive = true;
		PricebookEntryList.add(pbEntry2);
		List<Database.SaveResult> peSaveResults= database.insert(PricebookEntryList);

		list<OpportunityLineItem> OpportunityLineItemList = new list<OpportunityLineItem>();
		OpportunityLineItem OLI = new OpportunityLineItem();
		OLI.End_Date__c = date.today().adddays(1);
		OLI.OpportunityId = oppy.id;
		OLI.Quantity = 12;
		OLI.TotalPrice = 22;
		OLI.PricebookEntryId = pbEntry.Id;
		OpportunityLineItemList.add(OLI);

		

		OpportunityLineItem OLI2 = new OpportunityLineItem();
		OLI2.End_Date__c = date.today().adddays(1);
		OLI2.OpportunityId = oppy2.id;
		OLI2.Quantity = 12;
		OLI2.TotalPrice = 22;
		OLI2.PricebookEntryId = pbEntry2.Id;
		OpportunityLineItemList.add(OLI2);
		List<Database.SaveResult> oliSaveResults= database.insert(OpportunityLineItemList);

		List<ThoughtStarter_RFP__c>  tsrlist= new List<ThoughtStarter_RFP__c>();
		ThoughtStarter_RFP__c TRFP = new ThoughtStarter_RFP__c();
		TRFP.Opportunity__c = oppy.id;
		TRFP.name = 'testTRFP';
		TRFP.RecordTypeId = rt.id;
		TRFP.Clicks__c = true;
		TRFP.CTR__c  = 10;
		TRFP.End_Actions__c = false;
		TRFP.Leads__c = false;
		TRFP.Brand_Exposure__c = false;
		TRFP.Sales_Dev_Needed__c = true;
		TRFP.Sales_Developer__c = u.id;
		TRFP.Campaign_Start_Date__c = date.today();
		TRFP.Internal_Due_Date__c = system.today();
		TRFP.Campaign_End_Date__c = date.today().adddays(1);
		// insert TRFP;
		tsrlist.add(TRFP);
		List<Database.SaveResult> taskSaveResults= database.insert(tsrlist);


		Task testTask = TestClassUtility.createTask(false);
		testTask.Subject = 'RFP has been approved and ready to be pitched to client!';
		testTask.WhatId = TRFP.id;
		insert testTask;

		Test.startTest();	
		SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
											 'Complete',
											 '{"test": "Final Order Creation"}',
											 null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);

		Test.stopTest();  
		
		BatchRetrieveSalesOrderStatusScheduleJob testjob = new BatchRetrieveSalesOrderStatusScheduleJob();
		String sch = '0 1 0 * * ?';
    	System.schedule('testjob', sch, testjob);
  	}
}