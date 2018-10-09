@isTest
private class ThoughtStarterRFPEditControllerTest {
    @isTest static void test_method_one() {
        NationalTSRFPAccFieldMap__c newTSRFPAcc = new NationalTSRFPAccFieldMap__c();
        newTSRFPAcc.Name = 'Test CS'; 
        newTSRFPAcc.Account_Field_API_Name__c = 'Name';
        newTSRFPAcc.TS_RFP_API_Name__c = 'Action_Explanation__c';
        insert newTSRFPAcc;
        
        Map<String, SObject> testObjects = TestClassUtility.buildNationalData();
        Opportunity testOpp = (Opportunity)testObjects.get('Opportunity');
    
        Test.startTest();
        PageReference pageRef = Page.ThoughtStarterRFPEdit;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put('Type', 'ThoughtStarter');
        ApexPages.currentPage().getParameters().put('OpportunityId', testOpp.Id);

        ThoughtStarterRFPEditController contr = new ThoughtStarterRFPEditController(new ApexPages.StandardController(new ThoughtStarter_RFP__c()));

        ApexPages.currentPage().getParameters().put('Type', 'RFP');
        ApexPages.currentPage().getParameters().put('OpportunityId', testOpp.Id);

        contr = new ThoughtStarterRFPEditController(new ApexPages.StandardController(new ThoughtStarter_RFP__c()));
        Test.stopTest();
    }   
}