@isTest
private class AccountDetailPayloadWrapperTest{
    private static testmethod void test_method_one() {
        Test.StartTest(); 
        //
        //AccountDetailPayloadWrapper.AccountDetailPayloadWrapper adpw = new AccountDetailPayloadWrapper.AccountDetailPayloadWrapper();
        AccountDetailPayloadWrapper.PhoneNumberWrapper pnw = new AccountDetailPayloadWrapper.PhoneNumberWrapper();
        AccountDetailPayloadWrapper.AddressWrapper aw = new AccountDetailPayloadWrapper.AddressWrapper();
        AccountDetailPayloadWrapper.UserWrapper uw = new AccountDetailPayloadWrapper.UserWrapper();
        AccountDetailPayloadWrapper.ContactWrapper cw = new AccountDetailPayloadWrapper.ContactWrapper();
        AccountDetailPayloadWrapper adpw1 = new AccountDetailPayloadWrapper();
        adpw1.creditHold = false;
        Test.StopTest();
        
    }
}