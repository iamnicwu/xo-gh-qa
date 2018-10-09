@isTest
private class TestThoughtStarterRFPTrigger {
    static testMethod void test_method_one() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        Test.startTest();
        Map<String, SObject> testData =TestClassUtility.buildLocalData(false);
        Test.stopTest();
        Opportunity testOpportunity = (Opportunity)testData.get('Opportunity');
        
        Map<String,Schema.RecordTypeInfo> rtTSRFPMapByName = Schema.SObjectType.ThoughtStarter_RFP__c.getRecordTypeInfosByName();
        
        Id pricebookId = Test.getStandardPricebookId();

        //Create your product
        Product2 prod = new Product2(
            Name = 'Uncategorized Revenue',
            ProductCode = 'Pro-X',
            isActive = true
        );
        insert prod;
        
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry;
        
        ThoughtStarter_RFP__c testThoughtStarter = new ThoughtStarter_RFP__c();
        testThoughtStarter.Opportunity__c = testOpportunity.Id;
        testThoughtStarter.RecordTypeId = rtTSRFPMapByName.get('ThoughtStarter').getRecordTypeId();
        testThoughtStarter.Account_Strategist__c = UserInfo.getUserId();
        testThoughtStarter.Clicks__c = true;
        testThoughtStarter.CTR__c = 2;
        testThoughtStarter.Desired_Due_Date__c = date.today();
        testThoughtStarter.Internal_Due_Date__c = date.today();
        testThoughtStarter.Deliverable__c = 'Word (.doc)';
        testThoughtStarter.Target_Audience__c = 'test';
        testThoughtStarter.Campaign_Start_Date__c = date.today();
        testThoughtStarter.Campaign_End_Date__c = date.today();
        testThoughtStarter.Budget__c = 10;
        testThoughtStarter.Submitted_for_Production__c = true;
        
        insert testThoughtStarter;
        
        testThoughtStarter.Budget__c = 11;
        testThoughtStarter.Sales_Dev_Needed__c = false;
        update testThoughtStarter;
        
        Task newTask = new Task();
        newTask.OwnerId = [select id from user where UserRole.DeveloperName = 'Sales_Development' limit 1].id;
        newTask.WhatId = testThoughtStarter.Id;
        newTask.Type = 'Other';
        newTask.Purpose__c = 'Produce ';
        newTask.ActivityDate = testThoughtStarter.Internal_Due_Date__c;
        newTask.Subject = ' has been submitted';
        insert newTask;
        
        Task newTask1 = new Task();
        newTask1.OwnerId = [select id from user where UserRole.DeveloperName = 'Sales_Development' limit 1].id;
        newTask1.WhatId = testThoughtStarter.Id;
        newTask1.Type = 'Other';
        newTask1.Purpose__c = 'Produce ';
        newTask1.ActivityDate = testThoughtStarter.Internal_Due_Date__c;
        newTask1.Subject = ' has been submitted';
        insert newTask1;
        
        testThoughtStarter.Sales_Dev_Needed__c = True;
        testThoughtStarter.Sales_Developer__c = [select id from user where userrole.name = 'Sales Development' limit 1].id;
        update testThoughtStarter;
        
    }
    
    
    static testMethod void test_method_two() {
        
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        Test.startTest();
        Map<String, SObject> testData =TestClassUtility.buildLocalData(false);
        Test.stopTest();
        Opportunity testOpportunity = (Opportunity)testData.get('Opportunity');
        
        Map<String,Schema.RecordTypeInfo> rtTSRFPMapByName = Schema.SObjectType.ThoughtStarter_RFP__c.getRecordTypeInfosByName();
        
        Id pricebookId = Test.getStandardPricebookId();

        //Create your product
        Product2 prod = new Product2(
            Name = 'Uncategorized Revenue',
            ProductCode = 'Pro-X',
            isActive = true
        );
        insert prod;
        
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry;
        
        testOpportunity.Pricebook2Id = pricebookId;
        update testOpportunity;
        
        ThoughtStarter_RFP__c testThoughtStarter = new ThoughtStarter_RFP__c();
        testThoughtStarter.Opportunity__c = testOpportunity.Id;
        testThoughtStarter.RecordTypeId = rtTSRFPMapByName.get('RFP').getRecordTypeId();
        testThoughtStarter.Account_Strategist__c = UserInfo.getUserId();
        testThoughtStarter.Clicks__c = true;
        testThoughtStarter.CTR__c = 2;
        testThoughtStarter.Desired_Due_Date__c = date.today();
        testThoughtStarter.Internal_Due_Date__c = date.today();
        testThoughtStarter.Deliverable__c = 'Word (.doc)';
        testThoughtStarter.Target_Audience__c = 'test';
        testThoughtStarter.Campaign_Start_Date__c = date.today();
        testThoughtStarter.Campaign_End_Date__c = date.today();
        testThoughtStarter.Budget__c = 10;
        testThoughtStarter.Submitted_for_Production__c = true;
        testThoughtStarter.Description__c = 'test';
        testThoughtStarter.Request_Type__c = 'Formal RFP';
        testThoughtStarter.Campaign_Category__c = 'Agency > Agency > Agency';
        testThoughtStarter.Due_to_Client__c = date.today();
        testThoughtStarter.Maximum_Budget__c= 20;
        testThoughtStarter.Spend_Type__c = 'New';
        testThoughtStarter.Multiple_Spends__c = 'Yes';
        insert testThoughtStarter;
        
        testThoughtStarter.Budget__c = 11;
        update testThoughtStarter;
        
    }
}