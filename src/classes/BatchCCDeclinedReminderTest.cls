/*******************************************************************************
 *  Summary      : Test class for BatchCCDeclinedReminder
 *  Refer Object : 
 *  Author       : Nick
 *  RefactorDate : 12 Dec 2016 
 *  Change Log   : Refactoring by SF-2.6 release
 ******************************************************************************/
@isTest
private class BatchCCDeclinedReminderTest {

    private static Zuora__PaymentMethod__c testPaymentMthd;
    private static Zuora__PaymentMethod__c testPaymentMthd1;

    @isTest 
    static void test_method_one() {
        
        Map<String,SObject> testMap = TestClassUtility.buildNationalData();
        Test.startTest();
        Contact con = (Contact)testMap.get('Contact');

        Credit_Card_Declined_Config__c cdc = TestClassUtility.generateCardDeclinedConfig(true);
        Zuora__CustomerAccount__c testZuoraCustomerAccount = TestClassUtility.createCustomerAccount(false, (Account)testMap.get('Account'));
        testZuoraCustomerAccount.Customer_Type__c='ACTIVE';
        testZuoraCustomerAccount.CreditHold__c = 'Yes';
        testZuoraCustomerAccount.Bill_To_Contact__c =con.id;
        testZuoraCustomerAccount.Sold_To_Contact__c =con.id;
        insert testZuoraCustomerAccount;

        testPaymentMthd = TestClassUtility.createPaymentMethod(false, testZuoraCustomerAccount);
        testPaymentMthd.Zuora__External_Id__c = '2c92c0f94fd7f22b014ff62286425cdc';
        testPaymentMthd.Zuora__NumConsecutiveFailures__c = 0;
        testPaymentMthd.CC_Failure_Notification_Sent__c = false;
        testPaymentMthd.Zuora__Type__c = 'CreditCard';
        testPaymentMthd.Zuora__DefaultPaymentMethod__c=true;
        insert testPaymentMthd;
        
        testPaymentMthd1 = TestClassUtility.createPaymentMethod(false, testZuoraCustomerAccount);
        testPaymentMthd1.Zuora__External_Id__c = '2c92c0f94fd7f22b014ff62286425cdf';
        testPaymentMthd1.Zuora__NumConsecutiveFailures__c = 3;
        testPaymentMthd1.CC_Failure_Notification_Sent__c = false;
        testPaymentMthd.Zuora__Type__c = 'CreditCard';
        testPaymentMthd.Zuora__DefaultPaymentMethod__c=true;
        insert testPaymentMthd1;


        // Nick CSP-1542 removed some unused fields from Zuora__PaymentMethod__c
        String query = 'SELECT '+
                        'Id, '+
                        'Zuora__BillingAccount__r.Zuora__BillToWorkEmail__c,'+
                        'Zuora__BillingAccount__r.Name,'+
                        'Zuora__BillingAccount__r.Zuora__BillToName__c, ' +
                        'Zuora__BillingAccount__r.Bill_To_Contact__c, ' +
                        'Zuora__BillingAccount__r.Bill_To_Contact__r.Email, ' +
                        'Zuora__BillingAccount__r.Zuora__Account__c, ' + 
                        'Zuora__BillingAccount__r.Zuora__Account__r.OwnerId, ' +
                        'Zuora__BillingAccount__r.Zuora__Account__r.Owner.ARR__c, ' +
                        'Zuora__NumConsecutiveFailures__c, ' +
                        'CC_Failure_Notification_Sent__c,'+
                        'Zuora__DefaultPaymentMethod__c, '+
                        'SF_Account_Id__c, '+
                        'Billing_Account_Name__c, '+
                        'Notify_customer_Days__c, '+
                        'Bill_To_Contact_Email__c, '+
                        'Zuora__Type__c '+
                        'FROM Zuora__PaymentMethod__c WHERE '+
                        'id =\''+testPaymentMthd.id+'\' OR id = \'' +testPaymentMthd1.id+ '\'';

        BatchCCDeclinedReminder bb = new BatchCCDeclinedReminder();
        bb.query = query;
        Database.executeBatch(bb);
        
        Test.stopTest();
    }

    @isTest 
    static void test_method_two() {
        Map<String,SObject> testMap = TestClassUtility.buildNationalData();
        Test.startTest();
        Contact con = (Contact)testMap.get('Contact');

        Credit_Card_Declined_Config__c cdc = TestClassUtility.generateCardDeclinedConfig(true);
        Zuora__CustomerAccount__c testZuoraCustomerAccount = TestClassUtility.createCustomerAccount(false, (Account)testMap.get('Account'));
        testZuoraCustomerAccount.Customer_Type__c='ACTIVE';
        testZuoraCustomerAccount.CreditHold__c = 'Yes';
        testZuoraCustomerAccount.Sold_To_Contact__c =con.id;
        insert testZuoraCustomerAccount;

        testPaymentMthd = TestClassUtility.createPaymentMethod(false, testZuoraCustomerAccount);
        testPaymentMthd.Zuora__External_Id__c = '2c92c0f94fd7f22b014ff62286425cdc';
        testPaymentMthd.Zuora__NumConsecutiveFailures__c = 2;
        testPaymentMthd.CC_Failure_Notification_Sent__c = true;
        testPaymentMthd.Zuora__Type__c = 'CreditCard';
        testPaymentMthd.Zuora__DefaultPaymentMethod__c=true;
        insert testPaymentMthd;
        
        testPaymentMthd1 = TestClassUtility.createPaymentMethod(false, testZuoraCustomerAccount);
        testPaymentMthd1.Zuora__External_Id__c = '2c92c0f94fd7f22b014ff62286425cdf';
        testPaymentMthd1.Zuora__NumConsecutiveFailures__c = 3;
        testPaymentMthd1.CC_Failure_Notification_Sent__c = false;
        testPaymentMthd.Zuora__Type__c = 'CreditCard';
        testPaymentMthd.Zuora__DefaultPaymentMethod__c=true;
        insert testPaymentMthd1;


        // Nick CSP-1542 removed some unused fields from Zuora__PaymentMethod__c
        String query = 'SELECT '+
                        'Id, '+
                        'Zuora__BillingAccount__r.Zuora__BillToWorkEmail__c,'+
                        'Zuora__BillingAccount__r.Name,'+
                        'Zuora__BillingAccount__r.Zuora__BillToName__c, ' +
                        'Zuora__BillingAccount__r.Bill_To_Contact__c, ' +
                        'Zuora__BillingAccount__r.Bill_To_Contact__r.Email, ' +
                        'Zuora__BillingAccount__r.Zuora__Account__c, ' + 
                        'Zuora__BillingAccount__r.Zuora__Account__r.OwnerId, ' +
                        'Zuora__BillingAccount__r.Zuora__Account__r.Owner.ARR__c, ' +
                        'Zuora__NumConsecutiveFailures__c, ' +
                        'CC_Failure_Notification_Sent__c,'+
                        'Zuora__DefaultPaymentMethod__c, '+
                        'SF_Account_Id__c, '+
                        'Billing_Account_Name__c, '+
                        'Notify_customer_Days__c, '+
                        'Bill_To_Contact_Email__c, '+
                        'Zuora__Type__c '+
                        'FROM Zuora__PaymentMethod__c WHERE '+
                        'id =\''+testPaymentMthd.id+'\' OR id = \'' +testPaymentMthd1.id+ '\'';

        BatchCCDeclinedReminder bb = new BatchCCDeclinedReminder();
        bb.query = query;
        Database.executeBatch(bb);

        BatchCCDeclinedReminder.notifyAdminAboutMissingContact(new List<Id>{testZuoraCustomerAccount.id});
        
        Test.stopTest();
    }
    
    @isTest static void test_method_three() {
        BatchCCDeclinedReminderScheduledJob testScheduled = new BatchCCDeclinedReminderScheduledJob();
        String schedule = '0 0 23 * * ?';
        system.schedule('Nightly Update', schedule, testScheduled);
    }
    
}