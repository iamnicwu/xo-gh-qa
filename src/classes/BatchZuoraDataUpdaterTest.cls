@isTest
private class BatchZuoraDataUpdaterTest {
    @testSetup static void createTestData(){
      TestClassUtility.createCBSSCustomSettings();
    }
    
    static testMethod void testMethod1() {

      Test.startTest();

      Account testAcc = TestClassUtility.createAccount(true);
      Contact testCont = TestClassUtility.createContact(true);
      Zuora__CustomerAccount__c testCustomerAccount = TestClassUtility.createCustomerAccount(false,testAcc);
      testCustomerAccount.Zuora__SoldToId__c = testCont.Id;
      testCustomerAccount.ZDU_RetrieveSoldToContact__c = true;
      testCustomerAccount.ZDU_RetrieveSoldToContactFailureCount__c = 2;
      testCustomerAccount.ZDU_UpdateContacts__c = true;
      testCustomerAccount.ZDU_UpdateContactsFailureCount__c = 3;
      testCustomerAccount.NeedToUpdateAccountDetails__c = true;
      testCustomerAccount.ZDU_UpdateAccountFailureCount__c = 3;
      insert testCustomerAccount;

      
      BatchZuoraDataUpdater batch = new BatchZuoraDataUpdater();
      Database.executeBatch(batch,10);
      Test.stopTest();
    }
}