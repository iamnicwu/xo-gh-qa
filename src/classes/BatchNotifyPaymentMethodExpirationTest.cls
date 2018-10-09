/*
  Class(es) Tested:
    BatchNotifyPaymentMethodExpiration
 */
@isTest
private class BatchNotifyPaymentMethodExpirationTest {
    
  @isTest static void test_method_one() {
    // Implement test code
    Test.startTest();
    
      Map<String, Object> nationTestData = TestClassUtility.buildNationalData();
      
      BatchNotifyPaymentMthdExpScheduledJob job = new BatchNotifyPaymentMthdExpScheduledJob();
      String sch = '0 1 0 * * ?';
      System.schedule('Test BatchNotifyPaymentMethodExpirationTest Job', sch, job);
    
    Test.stopTest();
  }
 
  @isTest static void test_method_two() {

    // Region__c testRegion = TestClassUtility.createRegion(true);
    // Category__c testCategory = TestClassUtility.createCategory(true);
    // Market__c testMarket = TestClassUtility.createMarket(true, testRegion);
    // Account testAcc = TestClassUtility.createAccount(true, testCategory, testMarket);
    // Zuora__CustomerAccount__c testCustomerAcc = TestClassUtility.createCustomerAccount(true, testAcc);
    // Zuora__PaymentMethod__c testPaymentMethod = TestClassUtility.createPaymentMethod(true, testCustomerAcc);    
    
    Test.startTest();
    Map<String,SObject> testLocalData = TestClassUtility.buildLocalData(false);
    Test.stopTest();

    Account testAccount = (Account)testLocalData.get('Account');
    testAccount.Local_Paid_Status__c = 'Paid';
    testAccount.Card_Declined__c = true;
    testAccount.Customer_on_Payment_Arrangement__c = false;
    update testAccount;


    // Deactivate_Trigger__c dtNote = TestClassUtility.createNotesDeactivateTriggerSetting(false);
    // dtNote.After_Delete__c = false;
    // dtNote.After_Insert__c = false;
    // dtNote.After_Update__c = false;
    // dtNote.Before_Delete__c = false;
    // dtNote.Before_Insert__c = false;
    // dtNote.Before_Update__c = false;
    // insert dtNote; 

    // testAccount.Fulfillment_Data__c = '{ "tier" : "Freemium", "reviewId" : "review Id", "parentGUID" : "37e0c6b9-6f4f-4dd4-a3f4-9707e9dc4bbc", "marketCode" : "228", "categoryId" : "8aa9a07b-fcd8-46ed-a98f-8f3e12689dd2" }';
    // update testAccount;
    
    Zuora__CustomerAccount__c testZuoraCustomerAccount = (Zuora__CustomerAccount__c)testLocalData.get('Zuora__CustomerAccount__c');

    Zuora__PaymentMethod__c testPaymentMthd = TestClassUtility.createPaymentMethod(false,testZuoraCustomerAccount);
    testPaymentMthd.CC_Failure_Notification_Sent__c = false;
    testPaymentMthd.Zuora__NumConsecutiveFailures__c = 3;
    testPaymentMthd.Zuora__DefaultPaymentMethod__c = true;
    insert testPaymentMthd;

    // List<Zuora__PaymentMethod__c> updatezpmlist = new List<Zuora__PaymentMethod__c>();
    // updatezpmlist.add(testPaymentMthd);

    // insert updatezpmlist;

    BatchNotifyPaymentMethodExpiration bt = new BatchNotifyPaymentMethodExpiration();
    Database.executeBatch(bt, 1);
    
    
  }

  @isTest static void test_method_three() {
  
    Test.startTest();
    Map<String,SObject> testLocalData = TestClassUtility.buildLocalData(false);
    Test.stopTest();

    Account testAccount = (Account)testLocalData.get('Account');
    testAccount.Local_Paid_Status__c = 'Paid';
    testAccount.Card_Declined__c = true;
    testAccount.Customer_on_Payment_Arrangement__c = false;
    update testAccount;

    Contact testContact = (Contact)testLocalData.get('Contact');

    Zuora__CustomerAccount__c testZuoraCustomerAccount = (Zuora__CustomerAccount__c)testLocalData.get('Zuora__CustomerAccount__c');
    testZuoraCustomerAccount.Bill_To_Contact__c = testContact.Id;
    update testZuoraCustomerAccount;

    Zuora__PaymentMethod__c testPaymentMthd = TestClassUtility.createPaymentMethod(false,testZuoraCustomerAccount);
    testPaymentMthd.CC_Failure_Notification_Sent__c = false;
    testPaymentMthd.Zuora__NumConsecutiveFailures__c = 3;
    testPaymentMthd.Zuora__DefaultPaymentMethod__c = true;
    insert testPaymentMthd;


    BatchNotifyPaymentMethodExpiration bt = new BatchNotifyPaymentMethodExpiration();
    Database.executeBatch(bt, 1);
    
    
  }

  // @isTest static void test_method_three() {

  //   List<Account> accountList = new List<Account>();
  //   List<Zuora__CustomerAccount__c> zuoraCustomerAccountList = new List<Zuora__CustomerAccount__c>();
  //   List<Zuora__PaymentMethod__c> zpmlist = new List<Zuora__PaymentMethod__c>();

  //   Region__c testRegion = TestClassUtility.createRegion(true);
  //   Category__c testCategory = TestClassUtility.createCategory(true);
  //   Market__c testMarket = TestClassUtility.createMarket(true, testRegion);

  //   Test.startTest();

  //   for(Integer i=0; i<7; i++){
  //     Account testAccount = TestClassUtility.createAccount(false, testCategory, testMarket); 
  //     testAccount.Local_Paid_Status__c = 'Paid';
  //     testAccount.Card_Declined__c = true;
  //     testAccount.Customer_on_Payment_Arrangement__c = false;
  //     System.debug(LoggingLevel.INFO, '*** testAccount: ' + testAccount);

  //     accountList.add(testAccount);
  //   }
  //   insert accountList;


  //   for(Integer j=0; j<7; j++){
  //     Zuora__CustomerAccount__c testZuoraCustomerAccount = TestClassUtility.createCustomerAccount(false, accountList[j]);
      
  //     zuoraCustomerAccountList.add(testZuoraCustomerAccount);
  //   }
  //   insert zuoraCustomerAccountList;

    
  //   for(Integer k=0; k<7; k++){
  //     Zuora__PaymentMethod__c testPaymentMthd = TestClassUtility.createPaymentMethod(false, zuoraCustomerAccountList[k]); 
  //     testPaymentMthd.CC_Failure_Notification_Sent__c = false;
  //     testPaymentMthd.Zuora__NumConsecutiveFailures__c = 3;
  //     testPaymentMthd.Zuora__DefaultPaymentMethod__c = true;

  //     zpmlist.add(testPaymentMthd);
  //   }
  //   insert zpmlist;       
    
  //   Test.stopTest();


  //   BatchNotifyPaymentMethodExpiration bt = new BatchNotifyPaymentMethodExpiration();
  //   Database.executeBatch(bt, 10);
    

    
  // }  
}