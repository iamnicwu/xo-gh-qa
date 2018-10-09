@isTest
public class DefaultValues_test_class  {
 
    static testmethod void test_trigger(){

        Test.startTest();
            Map<String, SObject> testObjects = TestClassUtility.buildZQUTestObjects(false);
        Test.stopTest();
      
        // retireve data that is needed for this test class
        Account testAccount = (Account)testObjects.get('Account');

        Zuora__CustomerAccount__c testCustomerAccount = (Zuora__CustomerAccount__c)testObjects.get('Zuora__CustomerAccount__c');
        testCustomerAccount.Zuora__DefaultPaymentMethod__c = 'CreditCard';
        testCustomerAccount.Zuora__Zuora_Id__c = 'abc123';
        update testCustomerAccount;

        // data needed for existing billing account used in the class defaultValues
        Account testAcc = TestClassUtility.createAccount(true);
        Zuora__CustomerAccount__c testCustomerAcc = TestClassUtility.createCustomerAccount(false, testAcc);
        testCustomerAcc.Zuora__Zuora_Id__c = 'abc1234';
        insert testCustomerAcc;
        
        Contact testContact = (Contact)testObjects.get('Contact');
        Opportunity testOpportunity = (Opportunity)testObjects.get('Opportunity');
        zqu__Quote__c quote = TestClassUtility.createQuote(true, testOpportunity, testAcc, testContact);

        // passing page parameters
        apexpages.currentpage().getparameters().put('subscriptionId' , 'abc123');
        apexpages.currentpage().getparameters().put('billingAccountId' , 'abc1234');
           
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse); 
        
        DefaultValues dV = new DefaultValues();
        zqu.PropertyComponentController.ParentController pc = new zqu.PropertyComponentController.ParentController();
     
        dV.populateDefaultFieldValue(quote,pc);
        
        quote.zqu__SubscriptionType__c = 'Renew Subscription';
        dV.populateDefaultFieldValue(quote,pc);
        
        quote.zqu__SubscriptionType__c = 'New Subscription';
        dV.populateDefaultFieldValue(quote,pc);

        quote.zqu__SubscriptionType__c = 'Amend Subscription';
        delete testCustomerAccount;
        dV.populateDefaultFieldValue(quote,pc);
    }    
}