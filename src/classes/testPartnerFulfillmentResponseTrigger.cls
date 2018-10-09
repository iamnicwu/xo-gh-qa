@isTest
private class testPartnerFulfillmentResponseTrigger{
    @isTest static void test_method_one() {
        // Implement test code
        Test.startTest();
        
        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        
        Deactivate_Trigger__c dt = TestClassUtility.createNotesDeactivateTriggerSetting(true);
        
        List<Partner_Fulfillment_Response__c> testPFRList = new List<Partner_Fulfillment_Response__c>();
        Partner_Fulfillment_Response__c testPFR = TestClassUtility.createPartnerFulfillmentResponse(false);
        testPFRList.add(testPFR);
                
        String ResponseJSON = '{"locations":[{"locationId":"855f225f-ef9f-43f2-88b4-f6f13bfc8778","fulfilledStorefronts":null,';
        ResponseJSON += '"errors":[{"message":"Test"},{"message":"test"}]}],';
        ResponseJSON += '"companyId":null}';
        
        Partner_Fulfillment_Response__c testPFR1 = TestClassUtility.createPartnerFulfillmentResponse(false);
        testPFR1.Response_JSON__c = ResponseJSON ;
        testPFR1.Type__c = 'Storefront Fulfillment';
        testPFRList.add(testPFR1);
        
        Partner_Fulfillment_Response__c testPFR2 = TestClassUtility.createPartnerFulfillmentResponse(false);
        testPFR2.Object_Type__c = 'Lead';
        testPFR2.Response_JSON__c = ResponseJSON ;
        testPFR2.Type__c = 'Storefront Fulfillment';
        testPFRList.add(testPFR2);
        
        ResponseJSON = '{"locations":[{"locationId":"855f225f-ef9f-43f2-88b4-f6f13bfc8778","fulfilledStorefronts":null,';
        ResponseJSON += '"errors":null}],';
        ResponseJSON += '"companyId":null}';
        
        Partner_Fulfillment_Response__c testPFR3 = TestClassUtility.createPartnerFulfillmentResponse(false);
        testPFR3.Object_Type__c = 'Account';
        testPFR3.Response_JSON__c = ResponseJSON ;
        testPFR3.Type__c = 'Storefront Fulfillment';
        testPFRList.add(testPFR3);
        
        Partner_Fulfillment_Response__c testPFR4 = TestClassUtility.createPartnerFulfillmentResponse(false);
        testPFR4.Object_Type__c = 'Lead';
        testPFR4.Response_JSON__c = ResponseJSON ;
        testPFR4.Type__c = 'Storefront Fulfillment';
        testPFRList.add(testPFR4);
        insert testPFRList;
        
        PartnerFulfillmentResponseTriggerHandler testpfrth = new PartnerFulfillmentResponseTriggerHandler();
        testpfrth.bulkBefore();
        testpfrth.beforeInsert(testPFRList[4]);
        testpfrth.beforeUpdate(testPFRList[4],testPFRList[4]);
        testpfrth.beforeDelete(testPFRList[4]);
        testpfrth.afterUpdate(testPFRList[4],testPFRList[4]);
        testpfrth.afterDelete(testPFRList[4]);
        Test.stopTest();    
    }
}