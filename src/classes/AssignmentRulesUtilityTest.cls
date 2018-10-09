@isTest
private class AssignmentRulesUtilityTest {
		@testSetup static void createTestData(){
			String className = 'LocalSalesRepAssignmentTriggerHandler';
			String objectName = 'Local_Sales_Rep_Assignment__c';
			TestClassUtility.createTriggerHandlerAccessSetting(true, objectName, className);
		}

		static testMethod void testLeadMethodNegative() {  
			Lead testNullLead = TestClassUtility.createLead(false);
  		testNullLead.Status = 'Invalid';
      testNullLead.Negative_Disposition_Reason__c = 'Other';
      testNullLead.Reason_Details__c = 'testReasonDetails';
  		insert testNullLead;
     	System.assert(AssignmentRulesUtility.getRecordAssignment(testNullLead) == null);

     	List<Lead> leadRecordList = null;
     	AssignmentRulesUtility.buildAssignmentMap(leadRecordList);
		}

		static testMethod void testAccountMethodNegative() { 
  		Account testAcc = TestClassUtility.createAccount(true);
      System.assert(AssignmentRulesUtility.getRecordAssignment(testAcc) == null);

      List<Account> accRecordList = null;
   		AssignmentRulesUtility.buildAssignmentMap(accRecordList);
    }

		static testMethod void testLeadAssignmentRule() {  
			Category__c testCategory = TestClassUtility.createCategory(true);
      Market__c testMarket = TestClassUtility.createMarket(true);
			Zip__c testZip = TestClassUtility.createZip(true);

    	//if(String.isNotBlank(leadRecord.Primary_Category__c) && String.isNotBlank(leadRecord.PostalCode) 
	    Lead testLead1 = TestClassUtility.createLead(false, testMarket, testCategory);
	    testLead1.PostalCode = testZip.ZipCode__c.left(5);
	    testLead1.Local_Sales_Market__c = null;
	    testLead1.Status = 'Invalid';
	    testLead1.Country = 'China';
	    testLead1.State = 'Guangdong';
      testLead1.Negative_Disposition_Reason__c = 'Other';
      testLead1.Reason_Details__c = 'testReasonDetails';
	    
	    //if(String.isNotBlank(leadRecord.Primary_Category__c) && String.isNotBlank(leadRecord.PostalCode) && leadRecord.CountryCode == 'US' && leadRecord.PostalCode.length() > 5
	    Lead testLead2 = TestClassUtility.createLead(false, testMarket, testCategory);
	    testLead2.PostalCode = testZip.ZipCode__c;
	    testLead2.CountryCode = 'US';
	    testLead2.Local_Sales_Market__c = null;
	    testLead2.Status = 'Invalid';
      testLead2.Negative_Disposition_Reason__c = 'Other';
      testLead2.Reason_Details__c = 'testReasonDetails';
	    
	    //if(String.isNotBlank(leadRecord.Primary_Category__c) && String.isNotBlank(leadRecord.Local_Sales_Market__c)
	    Lead testLead3 = TestClassUtility.createLead(false, testMarket, testCategory);
	    testLead3.PostalCode = null;
	    testLead3.Country = 'China';
	    testLead3.State = 'Guangdong';
	    testLead3.Status = 'Invalid';
      testLead3.Negative_Disposition_Reason__c = 'Other';
      testLead3.Reason_Details__c = 'testReasonDetails';
	    
	    //if(String.isNotBlank(leadRecord.Primary_Category__c) 
	    Lead testLead4 = TestClassUtility.createLead(false, testMarket, testCategory);
	    testLead4.PostalCode = null;
	    testLead4.Local_Sales_Market__c = null;
	    testLead4.Status = 'Invalid';
	    testLead4.Country = 'China';
	    testLead4.State = 'Guangdong';
      testLead4.Negative_Disposition_Reason__c = 'Other';
      testLead4.Reason_Details__c = 'testReasonDetails';
	    
	    //if(String.isNotBlank(leadRecord.PostalCode) 
	    Lead testLead5 = TestClassUtility.createLead(false, testMarket, testCategory);
	    testLead5.PostalCode = testZip.ZipCode__c.left(5);
	    testLead5.Status = 'Invalid';
	    testLead5.Local_Sales_Market__c = null;
	    testLead5.Primary_Category__c = null;
	    testLead5.Country = 'China';
	    testLead5.State = 'Guangdong';
      testLead5.Negative_Disposition_Reason__c = 'Other';
      testLead5.Reason_Details__c = 'testReasonDetails';

      //if(String.isNotBlank(leadRecord.PostalCode) && leadRecord.CountryCode == 'US' && leadRecord.PostalCode.length() > 5 
      Lead testLead6 = TestClassUtility.createLead(false, testMarket, testCategory);
	    testLead6.PostalCode = testZip.ZipCode__c;
	    testLead6.CountryCode = 'US';
	    testLead6.Status = 'Invalid';
	    testLead6.Local_Sales_Market__c = null;
	    testLead6.Primary_Category__c = null;
      testLead6.Negative_Disposition_Reason__c = 'Other';
      testLead6.Reason_Details__c = 'testReasonDetails';

      //if(String.isNotBlank(leadRecord.Local_Sales_Market__c)
      Lead testLead7 = TestClassUtility.createLead(false, testMarket, testCategory);
	    testLead7.PostalCode = null;
	    testLead7.Primary_Category__c = null;
	    testLead7.Country = 'China';
	    testLead7.State = 'Guangdong';
	    testLead7.Status = 'Invalid';
      testLead7.Negative_Disposition_Reason__c = 'Other';
      testLead7.Reason_Details__c = 'testReasonDetails';
 			
	    List<Lead> testLeadList = new List<Lead> {
	    	testLead1,
	    	testLead2,
	    	testLead3,
	    	testLead4,
	    	testLead5,
	    	testLead6,
	    	testLead7
	    };
	    insert testLeadList;
	    
      Local_Sales_Rep_Assignment__c testLocalSalesRepAssignment1 = TestClassUtility.createLocalSalesRepAssignment(false, 
																                                                                                testCategory, 
																                                                                                null,
																                                                                                testZip);

      Local_Sales_Rep_Assignment__c testLocalSalesRepAssignment2 = TestClassUtility.createLocalSalesRepAssignment(false, 
																                                                                                testCategory, 
																                                                                                testMarket,
																                                                                                null);
      
      Local_Sales_Rep_Assignment__c testLocalSalesRepAssignment3 = TestClassUtility.createLocalSalesRepAssignment(false, 
																                                                                                testCategory, 
																                                                                                null,
																                                                                                null);
      
      Local_Sales_Rep_Assignment__c testLocalSalesRepAssignment4 = TestClassUtility.createLocalSalesRepAssignment(false, 
																                                                                                null, 
																                                                                                null,
																                                                                                testZip);
      
      Local_Sales_Rep_Assignment__c testLocalSalesRepAssignment5 = TestClassUtility.createLocalSalesRepAssignment(false, 
																                                                                                null, 
																                                                                                testMarket,
																                                                                                null);
      
      Profile profileRecord = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
      User testUser = TestClassUtility.createUser(false, profileRecord);
    	testUser.Alias = 'distacts';
      testUser.UserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
      System.runAs(testUser){
      	Local_Sales_Rep_Assignment__c testLocalSalesRepAssignment6 = TestClassUtility.createLocalSalesRepAssignment(true, null, null, null); 	
      }
      
      List<Local_Sales_Rep_Assignment__c> testLocalSalesRepAssignmentList = new List<Local_Sales_Rep_Assignment__c>{
      	testLocalSalesRepAssignment1,
      	testLocalSalesRepAssignment2,
      	testLocalSalesRepAssignment3,
      	testLocalSalesRepAssignment4,
      	testLocalSalesRepAssignment5
      };
      insert testLocalSalesRepAssignmentList;

      Test.startTest();

      AssignmentRulesUtility.buildAssignmentMap(testLeadList);

      AssignmentRulesUtility.assignmentMap.put(testLead1.PostalCode.left(5) + testLead1.Primary_Category__c, testLocalSalesRepAssignment5);
      AssignmentRulesUtility.assignmentMap.put(testLead3.Local_Sales_Market__c + '' + testLead3.Primary_Category__c, testLocalSalesRepAssignment5);
      AssignmentRulesUtility.assignmentMap.put(testLead4.Primary_Category__c, testLocalSalesRepAssignment5);
      AssignmentRulesUtility.assignmentMap.put(testLead5.PostalCode.left(5), testLocalSalesRepAssignment5);
      AssignmentRulesUtility.assignmentMap.put(testLead7.Local_Sales_Market__c, testLocalSalesRepAssignment5);
      
    	Test.stopTest();

    	for(Lead testLead : testLeadList){ 
    		system.assert(AssignmentRulesUtility.getRecordAssignment(testLead) != null);
    		if(String.isNotBlank(testLead.PostalCode)){
    			system.assert(AssignmentRulesUtility.getRecordAssignment(testLead.PostalCode.left(5)) != null);
    		}else{
    			system.assert(AssignmentRulesUtility.getRecordAssignment(testLead.PostalCode) == null);
    		}
    	}
		} 

    static testMethod void testAccountAssignmentRule() {   
    		Category__c testCategory = TestClassUtility.createCategory(true);
      	Market__c testMarket = TestClassUtility.createMarket(true);
      	Zip__c testZip = TestClassUtility.createZip(true);
	    		
	    	// if(String.isNotBlank(accountRecord.Primary_Category__c) && String.isNotBlank(accountRecord.BillingPostalCode) 
	  		Account testAcc1 = TestClassUtility.createAccount(false, testCategory, testMarket);
	  		testAcc1.Name = 'testAcc1';
	  		testAcc1.BillingPostalCode = testZip.ZipCode__c.left(5);
	  		testAcc1.BillingCountry = 'China';
	  		testAcc1.BillingCity = 'Guangzhou';
    		testAcc1.BillingState = 'Guangdong';
    		testAcc1.Local_Sales_Market__c = null;

		    // if(String.isNotBlank(accountRecord.Primary_Category__c) && String.isNotBlank(accountRecord.BillingPostalCode) && 
		    // accountRecord.BillingCountryCode == 'US' && accountRecord.BillingPostalCode.length() > 5  
		    Account testAcc2 = TestClassUtility.createAccount(false, testCategory, testMarket);
		    testAcc2.Name = 'testAcc2';
		    testAcc2.BillingCountryCode = 'US';
		    testAcc2.BillingPostalCode = testZip.ZipCode__c;

		    // if(String.isNotBlank(accountRecord.Primary_Category__c) && 
		    // String.isNotBlank(accountRecord.Local_Sales_Market__c) &&   		    
		    Account testAcc3 = TestClassUtility.createAccount(false, testCategory, testMarket);
		    testAcc3.Name = 'testAcc3';
		    testAcc3.BillingPostalCode = null;
		    testAcc3.BillingCountry = 'China';
	  		testAcc3.BillingCity = 'Guangzhou';
    		testAcc3.BillingState = 'Guangdong';
		     		
		    // else if(String.isNotBlank(accountRecord.Primary_Category__c) 
		    Account testAcc4 = TestClassUtility.createAccount(false, testCategory, testMarket);
		    testAcc4.Name = 'testAcc4';
   			testAcc4.Local_Sales_Market__c = null;
   			testAcc4.BillingPostalCode = null;
   			testAcc4.BillingCountry = 'China';
	  		testAcc4.BillingCity = 'Guangzhou';
    		testAcc4.BillingState = 'Guangdong';
    		
		    // if(String.isNotBlank(accountRecord.BillingPostalCode) 		    
		    Account testAcc5 = TestClassUtility.createAccount(false, testCategory, testMarket);
		    testAcc5.Name = 'testAcc5';
   			testAcc5.BillingPostalCode = testZip.ZipCode__c.left(5);
   			testAcc5.BillingCountry = 'China';
	  		testAcc5.BillingCity = 'Guangzhou';
    		testAcc5.BillingState = 'Guangdong';
    		testAcc5.Local_Sales_Market__c = null;
    		testAcc5.Primary_Category__c = null;

		    // if(String.isNotBlank(accountRecord.BillingPostalCode) && accountRecord.BillingCountryCode == 'US' && accountRecord.BillingPostalCode.length() > 5     
		    Account testAcc6 = TestClassUtility.createAccount(false, testCategory, testMarket);
		    testAcc6.Name = 'testAcc6';	   
		    testAcc6.BillingCountryCode = 'US';
   			testAcc6.BillingPostalCode = testZip.ZipCode__c;
   			testAcc6.Local_Sales_Market__c = null;
    		testAcc6.Primary_Category__c = null;

		    // if(String.isNotBlank(accountRecord.Local_Sales_Market__c) 	    
		    Account testAcc7 = TestClassUtility.createAccount(false, testCategory, testMarket);
		    testAcc7.Name = 'testAcc7';
		    testAcc7.Primary_Category__c = null;
   			testAcc7.BillingCountry = 'China';
	  		testAcc7.BillingCity = 'Guangzhou';
    		testAcc7.BillingState = 'Guangdong';
   			testAcc7.BillingPostalCode = null;

	      List<Account> testAccList = new List<Account>{
	      	testAcc1,
	      	testAcc2,
	      	testAcc3,
	      	testAcc4,
	      	testAcc5,
	      	testAcc6,
	      	testAcc7
	      };

	      Local_Sales_Rep_Assignment__c testLocalSalesRepAssignment;
	      Profile profileRecord = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
	      User testUser = TestClassUtility.createUser(false, profileRecord);
	      testUser.UserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
	      testUser.Strategy_Specialist__c = [SELECT Id FROM User LIMIT 1].Id;
	      System.runAs(testUser){
	      	testLocalSalesRepAssignment = TestClassUtility.createLocalSalesRepAssignment(true, null, testMarket, null); 	
	      }

	      Test.startTest();

	      AssignmentRulesUtility.buildAssignmentMap(testAccList);
	    
	  		AssignmentRulesUtility.assignmentMap.put(testAcc1.BillingPostalCode.left(5) + testAcc1.Primary_Category__c, testLocalSalesRepAssignment);
	      AssignmentRulesUtility.assignmentMap.put(testAcc3.Local_Sales_Market__c + '' + testAcc3.Primary_Category__c, testLocalSalesRepAssignment);
	      AssignmentRulesUtility.assignmentMap.put(testAcc4.Primary_Category__c, testLocalSalesRepAssignment);
	      AssignmentRulesUtility.assignmentMap.put(testAcc5.BillingPostalCode.left(5), testLocalSalesRepAssignment);
	      AssignmentRulesUtility.assignmentMap.put(testAcc7.Local_Sales_Market__c, testLocalSalesRepAssignment);

	      Test.stopTest();   

	      for(Account testAccount : testAccList){
      		system.assert(AssignmentRulesUtility.getRecordAssignment(testAccount) != null);
      		if(String.isNotBlank(testAccount.BillingPostalCode)){
    				system.assert(AssignmentRulesUtility.getRecordAssignment(testAccount.BillingPostalCode.left(5)) != null);
	    		}else{
	    			system.assert(AssignmentRulesUtility.getRecordAssignment(testAccount.BillingPostalCode) == null);
	    		}
	      }
    }
}