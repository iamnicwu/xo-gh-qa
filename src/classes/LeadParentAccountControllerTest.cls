@isTest
public class LeadParentAccountControllerTest{
	
	public static testMethod void test_method_one() {
		SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
												 'Complete',
												 '{"companyName": "Test Account"}',
												 null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);
		
		List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
		Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
		Map<String,Schema.RecordTypeInfo> rtCategoryMapByName = Schema.SObjectType.Category__c.getRecordTypeInfosByName();
		Map<String,Schema.RecordTypeInfo> rtLeadMapByName = Schema.SObjectType.Lead.getRecordTypeInfosByName();
	  
		
		Map<String, SObject> testLocalDate = TestClassUtility.buildLocalData(false);
		
		Test.startTest();
		

		Category__c testCategory = (Category__c)testLocalDate.get('Category__c');
		Market__c testMarket = (Market__c)testLocalDate.get('Market__c');
		// CSP-1999  Brand__c testBrand = (Brand__c)testLocalDate.get('Brand__c');
		Zip__c testzip = (Zip__c)testLocalDate.get('Zip__c');

		Local_Sales_Rep_Assignment__c testlsrp = TestClassUtility.createLocalSalesRepAssignment(false,
																								testCategory,
																								testMarket,
																								testzip);
		testlsrp.Market__c = null;
		insert testlsrp;
		// CSP-1999 
		// Lead testLead = TestClassUtility.createLead(false,testMarket,testCategory,testBrand); 
		Lead testLead = TestClassUtility.createLead(false,testMarket,testCategory); 
		testLead.recordtypeId = rtLeadMapByName.get('Local').getRecordTypeId();
		testLead.DynamicsLeadID__c = 'testDynamicsLeadID';
		testLead.Fulfillment_Data__c = '{"tier":"tier", "marketCode":"marketCode", "categoryId":"categoryId", "parentGUID":"TestRestAPIDynamicsPartnerAcctUpdateScheduleTest"}';
		testLead.Status = 'Valid';
		testLead.PostalCode  = '12345';
		testLead.Country = 'United States';
		testLead.CountryCode = 'US';
		testLead.LeadSource= 'Other';
		testLead.City = 'New York';
		testLead.State= 'New York';
		testLead.Phone = '1234567890';
		insert testLead;
		
	  
		
		test.setCurrentPageReference(Page.LeadParentAccount);

		System.currentPageReference().getParameters().put('id',testLead.id);

		LeadParentAccountController testcase = new LeadParentAccountController(); 

		testLead.Status = 'Qualified';
		update testLead;
		LeadParentAccountController testcase1 = new LeadParentAccountController(); 

		testLead.PostalCode = '';
		update testLead;

		Test.stopTest();
	}


	public static testMethod void test_method_two() {
		SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
												 'Complete',
												 '{"companyName": "Test Account"}',
												 null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);

		List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
		Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
		Map<String,Schema.RecordTypeInfo> rtCategoryMapByName = Schema.SObjectType.Category__c.getRecordTypeInfosByName();
		Map<String,Schema.RecordTypeInfo> rtLeadMapByName = Schema.SObjectType.Lead.getRecordTypeInfosByName();
		 
		
		Map<String, SObject> testLocalDate = TestClassUtility.buildLocalData(false);

		Test.startTest();

		Category__c testCategory = (Category__c)testLocalDate.get('Category__c');
		Market__c testMarket = (Market__c)testLocalDate.get('Market__c');
		// CSP-1999  Brand__c testBrand = (Brand__c)testLocalDate.get('Brand__c');
		Zip__c testzip = (Zip__c)testLocalDate.get('Zip__c');

		Local_Sales_Rep_Assignment__c testlsrp = TestClassUtility.createLocalSalesRepAssignment(false,
																								testCategory,
																								testMarket,
																								testzip);
		testlsrp.Market__c = null;
		insert testlsrp;

		Lead testLead = TestClassUtility.createLead(false,testMarket,testCategory); 
		testLead.recordtypeId = rtLeadMapByName.get('Local').getRecordTypeId();
		testLead.DynamicsLeadID__c = 'testDynamicsLeadID';
		testLead.Fulfillment_Data__c = '{"tier":"tier", "marketCode":"marketCode", "categoryId":"categoryId", "parentGUID":"TestRestAPIDynamicsPartnerAcctUpdateScheduleTest"}';
		testLead.Status = 'Valid';
		testLead.PostalCode  = '12345';
		testLead.Country = 'United States';
		testLead.CountryCode = 'US';
		testLead.LeadSource= 'Other';
		testLead.City = 'New York';
		testLead.State= 'New York';
		testLead.Phone = '1234567890';
		insert testLead;

		LeadParentAccountController testcase2 = new LeadParentAccountController(); 
		// testcase1.saveParent();
		// testcase1.cancelConvert();
		
		Account testAccount = (Account)testLocalDate.get('Account');
		testAccount.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
		testAccount.BU__c = 'Local';
		testAccount.Type = 'Agency';
		testAccount.Operative_Owner__c = userList[0].Name;
		testAccount.ConciergePrgQua__c = 'In Program';
		testAccount.Type = 'Advertiser';
		testAccount.DynamicsAccID__c = 'TestRestAPIDynamicsPartnerAcctUpdateScheduleTest';
		update testAccount;
		
		
		LeadParentAccountController testcase3 = new LeadParentAccountController(); 
		testcase3.saveParent();

		testLead.PostalCode = '12345';
		testLead.Email = 'Test@test.com';
		testLead.FirstName = 'testfortest';
		testLead.LastName = 'testfortest';
		update testLead;
		testcase3.saveParent();
		testcase3.cancelConvert();

   	boolean testresult;
    testresult = LeadParentAccountController.fulfillStorefront(testLead);

    Test.stopTest();
	}
}