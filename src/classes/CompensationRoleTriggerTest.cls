@isTest
private class CompensationRoleTriggerTest {
    static testMethod void testMethod1() {
    	Test.startTest();
      Compensation_Role__c compRole1 = new Compensation_Role__c();
      compRole1.Sales_Rep__c = userInfo.getUserId();
      compRole1.Start_Date__c = system.today().addDays(-7);
      compRole1.End_Date__c = system.today().addDays(-5);
      compRole1.Compensation_Type__c = 'NSBB';
      insert compRole1;
      Test.stopTest();
    }
}