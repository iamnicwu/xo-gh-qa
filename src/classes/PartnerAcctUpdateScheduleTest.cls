@isTest
private class PartnerAcctUpdateScheduleTest {
    
    @isTest static void test_method_one() {
        // Implement test code
        
        
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        XO_Group_Settings__c xoSetting = XO_Group_Settings__c.getInstance();
        xoSetting.Turn_on_Fulfillment_Callouts__c = true;
        upsert xoSetting;
 

        Test.startTest();
        Map<String,SObject> testLocalData = TestClassUtility.buildLocalData(false);
        Account testAccount = (Account)testLocalData.get('Account');
        Test.stopTest();

        testAccount.DynamicsAccID__c = 'TestRestAPIDynamicsPartnerAcctUpdateScheduleTest';
        testAccount.Phone = '12345678';
        update testAccount;

        Deactivate_Trigger__c dtNote = TestClassUtility.createAttachmentDeactivateTriggerSetting(false);
        dtNote.After_Delete__c = false;
        dtNote.After_Insert__c = false;
        dtNote.After_Update__c = false;
        dtNote.Before_Delete__c = false;
        dtNote.Before_Insert__c = false;
        dtNote.Before_Update__c = false;
        insert dtNote; 

        //system.assert(false,[select id,SystemModstamp from AccountContactRole where id =: acr.id]);
        //Test.startTest();
           // PartnerAcctUpdateSchedule job = new PartnerAcctUpdateSchedule();
           // job.execute(null);
        //Test.stopTest();
    }
     @isTest static void test_method_two() {
        // Implement test code
        //Test.startTest();
        
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        XO_Group_Settings__c xoSetting = XO_Group_Settings__c.getInstance();
        xoSetting.Turn_on_Fulfillment_Callouts__c = true;
        upsert xoSetting;

        Test.startTest();
        Map<String,SObject> testLocalData = TestClassUtility.buildLocalData(false);
        Test.stopTest();

        Deactivate_Trigger__c dtNote = TestClassUtility.createNotesDeactivateTriggerSetting(false);
        dtNote.After_Delete__c = false;
        dtNote.After_Insert__c = false;
        dtNote.After_Update__c = false;
        dtNote.Before_Delete__c = false;
        dtNote.Before_Insert__c = false;
        dtNote.Before_Update__c = false;
        insert dtNote;

        Account testAccount = (Account)testLocalData.get('Account');
        testAccount.DynamicsAccID__c = 'TestRestAPIDynamicsPartnerAcctUpdateScheduleTest';
        update testAccount;

        RESTLocalStorefrontAPI.ObjectWrapper objWrapper = new RESTLocalStorefrontAPI.ObjectWrapper();
        objWrapper.companyId = testAccount.DynamicsAccID__c;
        objWrapper.locationId = testAccount.DynamicsAccID__c;

        List<RESTLocalStorefrontAPI.ObjectWrapper> accountUpdateList = new List<RESTLocalStorefrontAPI.ObjectWrapper>();
        accountUpdateList.add(objWrapper);

        PartnerAcctUpdateSchedule job = new PartnerAcctUpdateSchedule();
        String sch = '0 1 0 * * ?';
        System.schedule('Test BatchDelExpQuoAssWOpenOptyScheduleJob Job', sch, job);
        
        //PartnerAccountUpdateCallout testcase = new PartnerAccountUpdateCallout();
        //PartnerAccountUpdateCallout.accountUpdateCalloutNotFuture(JSON.serializePretty(accountUpdateList));
        //PartnerAccountUpdateCallout.accountUpdateCallout(JSON.serializePretty(accountUpdateList));
    }
    
    @isTest static void test_method_three() {
        // Implement test code
        Test.startTest();
        
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        PartnerAcctUpdateSchedule job = new PartnerAcctUpdateSchedule();
        String sch = '0 1 0 * * ?';
        System.schedule('Test BatchDelExpQuoAssWOpenOptyScheduleJob Job', sch, job);
        Test.stopTest();
     }
}