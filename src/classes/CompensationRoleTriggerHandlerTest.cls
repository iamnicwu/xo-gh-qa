@isTest
private class CompensationRoleTriggerHandlerTest {
    static testMethod void testMethod1() {
      Test.startTest();
    	List<Compensation_Role__c> compRoleList = new List<Compensation_Role__c>();

      Compensation_Role__c compRole1 = new Compensation_Role__c();
      compRole1.Sales_Rep__c = userInfo.getUserId();
      compRole1.Start_Date__c = system.today().addDays(-7);
      compRole1.End_Date__c = system.today().addDays(-5);
      compRole1.Compensation_Type__c = 'NSBB';
      compRole1.Role__c = 'Senior Sales Execs';
      insert compRole1;

      Compensation_Role__c compRole2 = new Compensation_Role__c();
      compRole2.Sales_Rep__c = userInfo.getUserId();
      compRole2.Start_Date__c = system.today().addDays(-4);
      compRole2.End_Date__c = system.today().addDays(-2);
      compRole2.Compensation_Type__c = 'NSBB';
      compRole2.Role__c = 'Senior Sales Execs';
      compRoleList.add(compRole2);


      Compensation_Role__c compRole3 = new Compensation_Role__c();
      compRole3.Sales_Rep__c = userInfo.getUserId();
      compRole3.Start_Date__c = system.today().addDays(-1);
      compRole3.End_Date__c = system.today();
      compRole3.Compensation_Type__c = 'NSBB';
      compRole3.Role__c = 'Senior Sales Execs';
       compRoleList.add(compRole3);

      
      insert compRoleList;

      compRoleList[0].Start_Date__c = system.today().addDays(+5);
      compRoleList[0].End_Date__c = system.today().addDays(+7);
      update compRoleList[0];

      delete compRoleList[0];
      
      Test.stopTest();
    }
}