/*******************************************************************************
 *  Summary    : Test class for BatchCloseExpiredLocalOppsSchedJob
 *  Refer Object : 
 *  Author     : Nick
 *  RefactorDate : 12 Dec 2016
 *  Change Log   : Refactoring by SF-2.6 release
 ******************************************************************************/
@isTest
private class BatchCloseExpiredLocalOppsSchedJobTest {
  
  @isTest static void test_method_one() {
    
    TestClassUtility.buildZQUTestObjects(false);
    
    Test.startTest();
    List<Opportunity> oppUpdateList = [SELECT Id, Opportunity_Expiration_Date__c, StageName, Lost_Reason__c FROM Opportunity WHERE RecordType.Name = 'Local'];
    for (Opportunity opp: oppUpdateList) {
      opp.StageName = 'Quoting';
      opp.Opportunity_Expiration_Date__c = Date.today() - 5;
    }
    Database.update(oppUpdateList, false);
    
    BatchCloseExpiredLocalOppsScheduledJob bct = new BatchCloseExpiredLocalOppsScheduledJob();
    String schedule = '0 0 23 * * ?';
    system.schedule('Nightly Update', schedule, bct );
    
    Test.stopTest();
  }

  @isTest static void test_method_two() {
    
    TestClassUtility.buildZQUTestObjects(false);
    OppUpdateLastModifiedNumberOfDays__c testOULMNOD = TestClassUtility.createOppUpdateLastModifiedNOD(TRUE);
    system.assertNotEquals(null,OppUpdateLastModifiedNumberOfDays__c.getInstance('StandardDaysCount'),'false');
    Test.startTest();
    List<Opportunity> oppUpdateList = [SELECT Id, Opportunity_Expiration_Date__c, StageName, Lost_Reason__c FROM Opportunity WHERE RecordType.Name = 'Local'];
    for (Opportunity opp: oppUpdateList) {
      opp.StageName = 'Quoting';
      opp.Opportunity_Expiration_Date__c = Date.today() - 5;
    }
    Database.update(oppUpdateList, false);
    
    BatchCloseExpiredLocalOppsScheduledJob bct = new BatchCloseExpiredLocalOppsScheduledJob();
    String schedule = '0 0 23 * * ?';
    system.schedule('Nightly Update', schedule, bct );
    
    Test.stopTest();
  }
}