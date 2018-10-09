@isTest
private class RandomStringUtilsTest{
    
    @isTest static void test_method_one() {
        Test.startTest();
        
        RandomStringUtils rsu = new RandomStringUtils();
        String testString = RandomStringUtils.randomUUID();
        
        Test.stopTest();
    }
}