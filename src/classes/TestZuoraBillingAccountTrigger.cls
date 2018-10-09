@isTest
private class TestZuoraBillingAccountTrigger{

    static testMethod void test_method_one() {
        
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Test.startTest();
        Map<String, SObject> testData =TestClassUtility.buildLocalData(false);
        Test.stopTest();
        Account testAccount = (Account)testData.get('Account');
        
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
         
    }


    static testMethod void test_method_two() {   
        
        Zuora__CustomerAccount__c testZuoraCustomerAccount1 = new Zuora__CustomerAccount__c(); 
        testZuoraCustomerAccount1.Name = 'Test Billing Account'; 
        testZuoraCustomerAccount1.Zuora__BillToAddress1__c = '123 ABC Dr';
        testZuoraCustomerAccount1.Zuora__BillToCity__c = 'Austin'; 
        testZuoraCustomerAccount1.Zuora__BillToCountry__c = 'United States';  
        testZuoraCustomerAccount1.Zuora__BillToName__c = 'Test'; 
        testZuoraCustomerAccount1.Zuora__BillToPostalCode__c = '77857'; 
        testZuoraCustomerAccount1.Zuora__BillToState__c = 'Texas'; 
        testZuoraCustomerAccount1.Zuora__BillToWorkEmail__c = 'abc@gmail.com';  
        testZuoraCustomerAccount1.Zuora__Zuora_Id__c = '2c92c0f94ed8d0d7014ee476a6e419ee'; 
        testZuoraCustomerAccount1.AccountStatus__c = 'Active';
        testZuoraCustomerAccount1.SoldToCountry__c = 'USA';

        Zuora__CustomerAccount__c testZuoraCustomerAccount2 = new Zuora__CustomerAccount__c(); 
        testZuoraCustomerAccount2.Name = 'Test Billing Account'; 
        testZuoraCustomerAccount2.Zuora__BillToAddress1__c = '123 ABC Dr';
        testZuoraCustomerAccount2.Zuora__BillToCity__c = 'Austin'; 
        testZuoraCustomerAccount2.Zuora__BillToCountry__c = 'United States';  
        testZuoraCustomerAccount2.Zuora__BillToName__c = 'Test'; 
        testZuoraCustomerAccount2.Zuora__BillToPostalCode__c = '77857'; 
        testZuoraCustomerAccount2.Zuora__BillToState__c = 'Texas'; 
        testZuoraCustomerAccount2.Zuora__BillToWorkEmail__c = 'abc@gmail.com';  
        testZuoraCustomerAccount2.Zuora__Zuora_Id__c = '2c92c0f94ed8d0d7014ee476a6e419ee'; 
        testZuoraCustomerAccount2.AccountStatus__c = 'Active';
        testZuoraCustomerAccount1.SoldToCountry__c = 'Finland';
        

        ZuoraBillingAccountTriggerHandler.setUpdateContactsFlagOnContactUpdate(testZuoraCustomerAccount1, testZuoraCustomerAccount2);
    }
}