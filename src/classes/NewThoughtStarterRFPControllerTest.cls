@isTest
private class NewThoughtStarterRFPControllerTest {
    
    @isTest static void createSuccessful() {      
        user u = [select id from user where userrole.name = 'Account Strategist' limit 1];
        
        NationalTSRFPAccFieldMap__c newTSRFPAcc = new NationalTSRFPAccFieldMap__c();
        newTSRFPAcc.Name = 'Test CS';
        newTSRFPAcc.Account_Field_API_Name__c = 'Name';
        newTSRFPAcc.TS_RFP_API_Name__c = 'Action_Explanation__c';
        insert newTSRFPAcc;
        
        NationalTSRFPAccFieldMap__c newTSRFPAcc1 = new NationalTSRFPAccFieldMap__c();
        newTSRFPAcc1.Name = 'Test CS1';
        newTSRFPAcc1.Account_Field_API_Name__c = 'Strategy_Specialist__c';
        newTSRFPAcc1.TS_RFP_API_Name__c = 'Account_Strategist__c';
        insert newTSRFPAcc1;
        
        NationalTSRFPAccFieldMap__c newTSRFPAcc2 = new NationalTSRFPAccFieldMap__c();
        newTSRFPAcc2.Name = 'Test CS2';
        newTSRFPAcc2.Account_Field_API_Name__c = 'Anniversary_Date__c';
        newTSRFPAcc2.TS_RFP_API_Name__c = 'Internal_Due_Date__c';
        insert newTSRFPAcc2;
        
        NationalTSRFPAccFieldMap__c newTSRFPAcc3 = new NationalTSRFPAccFieldMap__c();
        newTSRFPAcc3.Name = 'Test CS3';
        newTSRFPAcc3.Account_Field_API_Name__c = 'Longest_Past_Due_Date__c';
        newTSRFPAcc3.TS_RFP_API_Name__c = 'Desired_Due_Date__c';
        insert newTSRFPAcc3;
        
        NationalTSRFPAccFieldMap__c newTSRFPAcc4 = new NationalTSRFPAccFieldMap__c();
        newTSRFPAcc4.Name = 'Test CS4';
        newTSRFPAcc4.Account_Field_API_Name__c = 'Last_Contracted_Service_Date__c';
        newTSRFPAcc4.TS_RFP_API_Name__c = 'Campaign_Start_Date__c';
        insert newTSRFPAcc4;
        
        NationalTSRFPAccFieldMap__c newTSRFPAcc5 = new NationalTSRFPAccFieldMap__c();
        newTSRFPAcc5.Name = 'Test CS5';
        newTSRFPAcc5.Account_Field_API_Name__c = 'CancellationDate__c';
        newTSRFPAcc5.TS_RFP_API_Name__c = 'Campaign_End_Date__c';
        insert newTSRFPAcc5;
        
        NationalTSRFPAccFieldMap__c newTSRFPAcc6 = new NationalTSRFPAccFieldMap__c();
        newTSRFPAcc6.Name = 'Test CS6';
        newTSRFPAcc6.Account_Field_API_Name__c = 'ProductType__c';
        newTSRFPAcc6.TS_RFP_API_Name__c = 'Deliverable__c';
        insert newTSRFPAcc6;
        
        NationalTSRFPAccFieldMap__c newTSRFPAcc7 = new NationalTSRFPAccFieldMap__c();
        newTSRFPAcc7.Name = 'Test CS7';
        newTSRFPAcc7.Account_Field_API_Name__c = 'Desc__c';
        newTSRFPAcc7.TS_RFP_API_Name__c = 'Target_Audience__c';
        insert newTSRFPAcc7;
        
        NationalTSRFPAccFieldMap__c newTSRFPAcc8 = new NationalTSRFPAccFieldMap__c();
        newTSRFPAcc8.Name = 'Test CS8';
        newTSRFPAcc8.Account_Field_API_Name__c = 'DoNotBulkEmail__c';
        newTSRFPAcc8.TS_RFP_API_Name__c = 'Clicks__c';
        insert newTSRFPAcc8;
        
        NationalTSRFPAccFieldMap__c newTSRFPAcc9 = new NationalTSRFPAccFieldMap__c();
        newTSRFPAcc9.Name = 'Test CS9';
        newTSRFPAcc9.Account_Field_API_Name__c = 'Past_Due_Balance__c';
        newTSRFPAcc9.TS_RFP_API_Name__c = 'Cost_Per_Click__c';
        insert newTSRFPAcc9;
        
        Id pricebookId = Test.getStandardPricebookId();
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
        
        Map<String, SObject> testObjects = TestClassUtility.buildNationalData();
        
        Account testacc = (Account)testObjects.get('Account');
        Opportunity testOpp = (Opportunity)testObjects.get('Opportunity');
        
        testacc.Anniversary_Date__c = date.today().adddays(2);
        testacc.Last_Contracted_Service_Date__c = date.today().adddays(3);
        testacc.CancellationDate__c = date.today().adddays(4);
        testacc.Longest_Past_Due_Date__c = date.today().adddays(3);
        testacc.Desc__c = 'Desctest';
        testacc.ProductType__c = 'test';
        testacc.Strategy_Specialist__c = u.id;
        testacc.DoNotBulkEmail__c = true;
        testacc.Past_Due_Balance__c = 12;
        update testacc;
        Test.startTest();
        PageReference pageRef = Page.NewThoughtStarterRFP;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put('RecordType', 'ThoughtStarter');
        ApexPages.currentPage().getParameters().put('AccountId', testacc.Id);
        ApexPages.currentPage().getParameters().put('OpportunityId', testOpp.Id);

        NewThoughtStarterRFPController controller = new NewThoughtStarterRFPController();
        controller.createThoughtStarterRFP();
        test.stopTest();
    }

    @isTest static void createFailed() {

        NationalTSRFPAccFieldMap__c newTSRFPAcc = new NationalTSRFPAccFieldMap__c();
        newTSRFPAcc.Name = 'Test CS';
        newTSRFPAcc.Account_Field_API_Name__c = 'Name';
        newTSRFPAcc.TS_RFP_API_Name__c = 'Action_Explanation__c';
        insert newTSRFPAcc;

        Map<String, SObject> testObjects = TestClassUtility.buildNationalData();
        
        Opportunity testOpp = (Opportunity)testObjects.get('Opportunity');

        PageReference pageRef = Page.NewThoughtStarterRFP;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put('RecordType', 'ThoughtStarter');
        ApexPages.currentPage().getParameters().put('OpportunityId', testOpp.Id);

        NewThoughtStarterRFPController controller = new NewThoughtStarterRFPController();
        controller.newThoughtStarterRFP.Submitted_for_Production__c = true;
        controller.createThoughtStarterRFP();
    }    
}