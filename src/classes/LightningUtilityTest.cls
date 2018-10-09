@IsTest
private class LightningUtilityTest {
  @IsTest
  static void testCreateException() {
    String message = 'An error';

    Test.startTest();
    AuraHandledException excep = LightningUtility.createException(message);
    Test.stopTest();

    System.assert(excep != null, 'Should have created exception.');
    System.assertEquals(message, excep.getMessage(), 'Should have correct message.');
  }
}