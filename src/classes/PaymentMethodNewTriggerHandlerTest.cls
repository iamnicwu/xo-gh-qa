/* 
<class>
  <name>PaymentMethodNewTriggerHandler</name>
  <purpose>For testing the PaymentMethodNewTriggerHandler class</purpose>
  <created>
    <by>Hari Mohan</by>
    <date>10/2/2015</date>
    <ticket>SF-1182</ticket>
  </created>
</class>
*/
@isTest
private class PaymentMethodNewTriggerHandlerTest {
    
    @isTest static void test_method_one() {
        
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
       
        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        
        
        Test.startTest();
        Map<String,SObject> testLocalData = TestClassUtility.buildLocalData(false);
        List<Consecutive_Credit_Card_Failure_Config__c> consecFailureList = Consecutive_Credit_Card_Failure_Config__c.getAll().Values();
        

        Account testAccount = (Account)testLocalData.get('Account');
        testAccount.Card_Declined__c = false;
        update testAccount;

        Deactivate_Trigger__c dtNote = TestClassUtility.createNotesDeactivateTriggerSetting(false);
        dtNote.After_Delete__c = false;
        dtNote.After_Insert__c = false;
        dtNote.After_Update__c = false;
        dtNote.Before_Delete__c = false;
        dtNote.Before_Insert__c = false;
        dtNote.Before_Update__c = false;
        insert dtNote;
        
        testAccount.Fulfillment_Data__c = '{ "tier" : "Freemium", "reviewId" : "review Id", "parentGUID" : "37e0c6b9-6f4f-4dd4-a3f4-9707e9dc4bbc", "marketCode" : "228", "categoryId" : "8aa9a07b-fcd8-46ed-a98f-8f3e12689dd2" }';
        update testAccount;

        Contact con = (Contact)testLocalData.get('Contact');

        Zuora__CustomerAccount__c testZuoraCustomerAccount = (Zuora__CustomerAccount__c)testLocalData.get('Zuora__CustomerAccount__c');
        testZuoraCustomerAccount.Sold_To_Contact__c = con.id;
        List<Zuora__PaymentMethod__c> testPaymentMethods = new List<Zuora__PaymentMethod__c>();

        Zuora__PaymentMethod__c testPaymentMthd = TestClassUtility.createPaymentMethod(FALSE,testZuoraCustomerAccount);
        testPaymentMthd.Zuora__External_Id__c ='PaymentMethodNewTriggerHandler01';
        testPaymentMthd.CC_Failure_Notification_Sent__c = false;
        testPaymentMthd.Zuora__NumConsecutiveFailures__c = 3;
        testPaymentMthd.Zuora__DefaultPaymentMethod__c = true;
        insert testPaymentMthd;
 
        Zuora__PaymentMethod__c testPaymentMthd1 = TestClassUtility.createPaymentMethod(FALSE,testZuoraCustomerAccount);
        testPaymentMthd1.Zuora__External_Id__c ='PaymentMethodNewTriggerHandler02';
        testPaymentMthd1.CC_Failure_Notification_Sent__c = false;
        testPaymentMthd1.Zuora__NumConsecutiveFailures__c = 0;
        testPaymentMthd1.Zuora__BankIdentificationNumber__c = '411112';
        testPaymentMthd1.Zuora__DefaultPaymentMethod__c = true;
        insert testPaymentMthd1;

        PaymentMethodNewTriggerHandler pmnt = new PaymentMethodNewTriggerHandler();
        pmnt.emailsAndTasksCreation(testPaymentMthd);

        Test.stopTest();

    } 
    
    
    @isTest static void test_method_two() {
        
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        
        Test.startTest();
        Map<String,SObject> testLocalData = TestClassUtility.buildLocalData(false);
       
        Test.stopTest();
        Account testAccount = (Account)testLocalData.get('Account');
      
        testAccount.Card_Declined__c = true;
        update testAccount;


        Deactivate_Trigger__c dtNote = TestClassUtility.createNotesDeactivateTriggerSetting(false);
        dtNote.After_Delete__c = false;
        dtNote.After_Insert__c = false;
        dtNote.After_Update__c = false;
        dtNote.Before_Delete__c = false;
        dtNote.Before_Insert__c = false;
        dtNote.Before_Update__c = false;
        insert dtNote; 

        testAccount.Fulfillment_Data__c = '{ "tier" : "Freemium", "reviewId" : "review Id", "parentGUID" : "37e0c6b9-6f4f-4dd4-a3f4-9707e9dc4bbc", "marketCode" : "228", "categoryId" : "8aa9a07b-fcd8-46ed-a98f-8f3e12689dd2" }';
        update testAccount;
        
        Zuora__CustomerAccount__c testZuoraCustomerAccount = (Zuora__CustomerAccount__c)testLocalData.get('Zuora__CustomerAccount__c');

        Zuora__PaymentMethod__c testPaymentMthd = TestClassUtility.createPaymentMethod(false,testZuoraCustomerAccount);
        testPaymentMthd.CC_Failure_Notification_Sent__c = false;
        testPaymentMthd.Zuora__NumConsecutiveFailures__c = 3;
        testPaymentMthd.Zuora__DefaultPaymentMethod__c = true;

        Zuora__PaymentMethod__c testPaymentMthd1 = TestClassUtility.createPaymentMethod(false,testZuoraCustomerAccount);
        testPaymentMthd1.Zuora__External_Id__c = '2c92c0f94fd7f22b014ff62286456cdf';
        testPaymentMthd1.CC_Failure_Notification_Sent__c = false;
        testPaymentMthd1.Zuora__NumConsecutiveFailures__c = 0;   
        testPaymentMthd1.Zuora__BankIdentificationNumber__c = '411112';
        testPaymentMthd1.Zuora__DefaultPaymentMethod__c = true;
        List<Zuora__PaymentMethod__c> updatezpmlist = new List<Zuora__PaymentMethod__c>();
        updatezpmlist.add(testPaymentMthd);

        insert updatezpmlist;

        List<Consecutive_Credit_Card_Failure_Config__c> consecFailureList = Consecutive_Credit_Card_Failure_Config__c.getAll().Values();          

    }      
}