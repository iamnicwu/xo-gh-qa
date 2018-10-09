@isTest()
private class OrderPayloadWrapperTest{
    @isTest static void test_method_one() {
        OrderPayloadWrapper opw = new OrderPayloadWrapper();
        Boolean creditHold = opw.creditHold;
        //List<OrderPayloadWrapper.PhoneNumberWrapper> PhoneNumberWrapper = new List<OrderPayloadWrapper.PhoneNumberWrapper>();
        OrderPayloadWrapper.PhoneNumberWrapper PhoneNumberWrapper = new OrderPayloadWrapper.PhoneNumberWrapper();
        OrderPayloadWrapper.AddressWrapper AddressWrapper = new OrderPayloadWrapper.AddressWrapper();
        OrderPayloadWrapper.UserWrapper UserWrapper = new OrderPayloadWrapper.UserWrapper();
        OrderPayloadWrapper.ContactWrapper ContactWrapper = new OrderPayloadWrapper.ContactWrapper();
        OrderPayloadWrapper.LocationWrapper LocationWrapper = new OrderPayloadWrapper.LocationWrapper();
        OrderPayloadWrapper.ServiceWrapper ServiceWrapper = new OrderPayloadWrapper.ServiceWrapper();
        
    }
}