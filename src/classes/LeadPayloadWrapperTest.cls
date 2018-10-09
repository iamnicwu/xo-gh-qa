@isTest
private class LeadPayloadWrapperTest{   
    @isTest static void test_method_one() {
        Test.startTest();
        LeadPayloadWrapper lpw = new LeadPayloadWrapper();
        boolean b = lpw.isClaiming;
        Test.stopTest();
    }
    
}