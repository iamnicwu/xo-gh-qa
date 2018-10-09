@isTest
private class StringUtilsTest {
    
    @isTest static void test_method_one() {
        Test.startTest();
        StringUtils su = new StringUtils();
        String testStr = null;
        String testString = StringUtils.charAt(testStr,1);
        testStr = '';
        String testString1 = StringUtils.charAt(testStr,1);
        
        testStr = 'abc';
        String testString2 = StringUtils.charAt(testStr,5);
        
        testString2 = StringUtils.charAt(testStr,1);
        Test.stopTest();    
    }
}