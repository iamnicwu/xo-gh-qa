@isTest
private class ExpiredOpenOpportunitiesControllerTest {


     @isTest static void test_method_one() {
        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        // CSP-1999 Map<String,Schema.RecordTypeInfo> rtBrandMapByName = Schema.SObjectType.Brand__c.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtTSRMapByName = Schema.SObjectType.ThoughtStarter_RFP__c.getRecordTypeInfosByName();
        Id otherUserId = [select Id from User where isActive = true and UserRole.Name = 'Account Strategist' limit 1].Id;
        user u = [select Id from User where UserRole.DeveloperName = 'Sales_Development' limit 1];
        recordtype rt = [select id,name,developername from RecordType where DeveloperName = 'OppConcierge' and SobjectType = 'Opportunity' limit 1];
        
        XO_Group_Settings__c xoSetting = XO_Group_Settings__c.getInstance();
        xoSetting.Turn_on_Fulfillment_Callouts__c = true;
        upsert xoSetting;

        Test.startTest();
        Map<String, SObject> testLocalData = TestClassUtility.buildLocalData(false);
        Test.stopTest();
  
        System.AssertEquals(true,true);

        Account testAccount = (Account)testLocalData.get('Account');
        
        Contact testContact = (Contact)testLocalData.get('Contact');
       
        Opportunity testOpportunity = (Opportunity)testLocalData.get('Opportunity');
        
        Id pricebookId = Test.getStandardPricebookId();

        Product2 testProduct2 = TestClassUtility.createProduct2(true);

        PricebookEntry testPBEntry = TestClassUtility.createPricebookEntry(true,pricebookId, testProduct2);
        
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = testOpportunity.Id,
            Quantity = 5,
            PricebookEntryId = testPBEntry.Id,
            TotalPrice = 5 * testPBEntry.UnitPrice,
            Start_Date__c = date.today().adddays(-1)
        );
        insert oli;
        
        ThoughtStarter_RFP__c TRFP = new ThoughtStarter_RFP__c();
        TRFP.Opportunity__c = testOpportunity.id;
        TRFP.name = 'testTRFP';
        TRFP.RecordTypeId = rtTSRMapByName.get('RFP').getRecordTypeId();
        TRFP.Clicks__c = true;
        TRFP.CTR__c  = 10;
        TRFP.End_Actions__c = false;
        TRFP.Leads__c = false;
        TRFP.Brand_Exposure__c = false;
        TRFP.Sales_Dev_Needed__c = true;
        TRFP.Sales_Developer__c = u.id;
        TRFP.Campaign_Start_Date__c = date.today();
        TRFP.Campaign_End_Date__c = date.today().adddays(1);
        insert TRFP;
        
        test.setCurrentPageReference(Page.ExpiredOpenOpportunities);
        ExpiredOpenOpportunitiesController contr = new ExpiredOpenOpportunitiesController();
        contr.getViewList();
        
        contr.myOppOnly = false;
        contr.fillAction();
        
        // TRFP.Campaign_Start_Date__c = date.today().adddays(-1);
        // TRFP.Campaign_End_Date__c = date.today().adddays(2);
        // TRFP.Deliverable__c = 'Word (.doc)';
        // TRFP.Target_Audience__c = 'test';
        // TRFP.Description__c = 'test';
        // TRFP.Request_Type__c = 'Formal RFP';
        // TRFP.Campaign_Category__c = 'Agency > Agency > Agency';
        // TRFP.Internal_Due_Date__c = date.today().adddays(+2);
        // TRFP.Due_to_Client__c = date.today().adddays(-1);
        // TRFP.Spend_Type__c = 'Incremental';
        // TRFP.Multiple_Spends__c = 'Yes';
        // TRFP.Budget__c = 10;
        // update TRFP;
        
        // contr.saveCampaignDates();
        
        // contr.viewSelected = 'ThoughtStarter';
        // contr.fillAction();
        
        // contr.myOppOnly = true;
        // contr.fillAction();
     }
     
     @isTest static void test_method_two() {
       
       
        Map<String, SObject> testNationalData = TestClassUtility.buildNationalData();
        Opportunity testOpportunity = (Opportunity)testNationalData.get('Opportunity');
        testOpportunity.Amount = 50000;
        testOpportunity.OwnerId = UserInfo.getUserId();
        update testOpportunity;

        test.startTest();
        Map<String,Schema.RecordTypeInfo> rtTRFPMapByName = Schema.SObjectType.ThoughtStarter_RFP__c.getRecordTypeInfosByName();
        user u = [select id from user where UserRole.name = 'Sales Development' limit 1];
        
        Id pricebookId = Test.getStandardPricebookId();
     
        Product2 testProduct2 = TestClassUtility.createProduct2(true);

        PricebookEntry testPBEntry = TestClassUtility.createPricebookEntry(true,pricebookId, testProduct2);
        
        ThoughtStarter_RFP__c TRFP = new ThoughtStarter_RFP__c();
        TRFP.Opportunity__c = testOpportunity.Id;
        TRFP.name = 'testTRFP';
        TRFP.RecordTypeId = rtTRFPMapByName.get('ThoughtStarter').getRecordTypeId();
        TRFP.Clicks__c = true;
        TRFP.CTR__c  = 10;
        TRFP.End_Actions__c = false;
        TRFP.Leads__c = false;
        TRFP.Brand_Exposure__c = false;
        TRFP.Sales_Dev_Needed__c = true;
        TRFP.Sales_Developer__c = u.id;
        TRFP.Internal_Due_Date__c = date.today().adddays(-1);
        TRFP.Desired_Due_Date__c = date.today().adddays(-1); 
        TRFP.Campaign_Start_Date__c = date.today();
        TRFP.Campaign_End_Date__c = date.today().adddays(1);
        insert TRFP;
           // original start here
        test.setCurrentPageReference(Page.ExpiredOpenOpportunities);
        ExpiredOpenOpportunitiesController contr = new ExpiredOpenOpportunitiesController();

        contr.viewSelected = 'ThoughtStarter';
        contr.fillAction();
        
        contr.myOppOnly = false;
        contr.fillAction();
        
        test.stopTest();
     }
    
}