/**
Date: 12/7/2015
Author: Tony Liu
Purpose: test AccountUpdatePayloadWrapper class
 */
@isTest
private class AccountUpdatePayloadWrappertest{

    private static testMethod void myUnitTest() {
        AccountUpdatePayloadWrapper.PhoneNumberWrapper pnw = new AccountUpdatePayloadWrapper.PhoneNumberWrapper(); 
        AccountUpdatePayloadWrapper.AddressWrapper AW= new AccountUpdatePayloadWrapper.AddressWrapper();
        AccountUpdatePayloadWrapper.UserWrapper uw = new AccountUpdatePayloadWrapper.UserWrapper();
        AccountUpdatePayloadWrapper.ContactWrapper cw = new AccountUpdatePayloadWrapper.ContactWrapper();
        AccountUpdatePayloadWrapper.LocationWrapper lw = new AccountUpdatePayloadWrapper.LocationWrapper();
        AccountUpdatePayloadWrapper aupw = new AccountUpdatePayloadWrapper();
        aupw.creditHold = false;
    }
}