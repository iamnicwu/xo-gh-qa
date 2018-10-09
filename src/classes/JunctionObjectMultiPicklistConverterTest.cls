@isTest
private class JunctionObjectMultiPicklistConverterTest{
    private static testmethod void test_method_one() {
        Test.startTest();
        Schema.DescribeFieldResult dfr = Account.Description.getDescribe();
        JunctionObjectMultiPicklistConverter testcase = new JunctionObjectMultiPicklistConverter (dfr ,dfr );
        Test.stopTest();
    }
}