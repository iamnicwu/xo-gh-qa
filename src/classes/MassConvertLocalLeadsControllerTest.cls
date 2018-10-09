@isTest
private class MassConvertLocalLeadsControllerTest {
    @isTest static void test_method_one() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Map<String,Schema.RecordTypeInfo> rtLeadMapByName = Schema.SObjectType.Lead.getRecordTypeInfosByName();
        
        Test.startTest();
        Map<String, SObject> testData =TestClassUtility.buildLocalData(false);
        Test.stopTest();

        Market__c testMarket = (Market__c)testData.get('Market__c');
        Category__c testCategory = (Category__c)testData.get('Category__c');

        Lead testLead = TestClassUtility.createLead(false, testMarket, testCategory);
        testLead.FirstName='Test';
        testLead.LastName='Lead';
        testLead.Company='Test Company';
        testLead.Phone = '1231231234';
        testLead.recordtypeId = rtLeadMapByName.get('Local').getRecordTypeId();
        testLead.DynamicsLeadID__c = 'testDynamicsLeadID';
        testLead.Status = 'Valid';
        testLead.Salesforce_Generated_GUID__c = false;
        testLead.IsConverted = false;
        testLead.Storefront_Status__c = 'Claimed';
        insert testLead;
        
        
        MassConvertLocalLeadsController testcase = new MassConvertLocalLeadsController();
        testcase.executeBatchConvert();
        
        
    }
}