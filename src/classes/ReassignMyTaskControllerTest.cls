@isTest
private class ReassignMyTaskControllerTest {
    static testMethod void processSelectedTest() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);  
        
        Test.startTest();
            Map<String, SObject> testData =TestClassUtility.buildLocalData(false);
        Test.stopTest();

        Account testAccount = (Account)testData.get('Account'); 

        testAccount.Fulfillment_Data__c = '{ "tier" : "Freemium", "reviewId" : "review Id", "parentGUID" : "37e0c6b9-6f4f-4dd4-a3f4-9707e9dc4bbc", "marketCode" : "228", "categoryId" : "8aa9a07b-fcd8-46ed-a98f-8f3e12689dd2" }';
        update testAccount;
        
        Zuora__CustomerAccount__c testZuoraCustomerAccount = new Zuora__CustomerAccount__c(); 
        testZuoraCustomerAccount.Name = 'Test Billing Account'; 
        testZuoraCustomerAccount.Zuora__Account__c = testAccount.id;
        testZuoraCustomerAccount.Zuora__BillToAddress1__c = '123 ABC Dr';
        testZuoraCustomerAccount.Zuora__BillToCity__c = 'Austin'; 
        testZuoraCustomerAccount.Zuora__BillToCountry__c = 'United States';  
        testZuoraCustomerAccount.Zuora__BillToName__c = 'Test'; 
        testZuoraCustomerAccount.Zuora__BillToPostalCode__c = '77857'; 
        testZuoraCustomerAccount.Zuora__BillToState__c = 'Texas'; 
        testZuoraCustomerAccount.Zuora__BillToWorkEmail__c = 'abc@gmail.com';  
        testZuoraCustomerAccount.Zuora__Zuora_Id__c = '2c92c0f94ed8d0d7014ee476a6e419ee'; 
        testZuoraCustomerAccount.AccountStatus__c = 'Active';
        insert testZuoraCustomerAccount;
        
        Task testTask = new Task();
        testTask.Subject = 'Test';
        testTask.Type = 'Voicemail';
        testTask.ActivityDate = Date.Today();
        testTask.OwnerId = UserInfo.getUserId();
        testTask.Status = 'Not Started';
        testTask.Priority = 'Normal';
        testTask.WhatId = testZuoraCustomerAccount.id;
        insert testTask;
        
        ReassignMyTaskController newReassignTaskController = new ReassignMyTaskController();
        newReassignTaskController.tskRecord.ownerId = UserInfo.getUserId();
        ReassignMyTaskController.tTask rTst = new ReassignMyTaskController.tTask(testTask);
        newReassignTaskController.processSelected();    

        // scenario when tasks are empty 
        ReassignMyTaskController.tTask rTst1 = new ReassignMyTaskController.tTask(null);
        newReassignTaskController.processSelected();
    }    
}