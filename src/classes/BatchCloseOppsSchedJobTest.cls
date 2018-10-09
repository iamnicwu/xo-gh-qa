/* 
<class>
  <name>BatchCloseOppsSchedJobTest</name>
  <purpose>Used to test the class BatchCloseOppsSchedJob and BatchCloseOpps </purpose>
  <created>
    <by>Tony Liu</by>
    <date>07/07/2016</date>
    <ticket>CSP-1138</ticket>
  </created>
</class>
*/
@isTest
public class BatchCloseOppsSchedJobTest{
    @isTest static void BatchCloseOppsSchedJobTest() {
        test.startTest();
        Map<String, SObject> testObjects = TestClassUtility.buildNationalData();
        
        Opportunity testOpportunity = (Opportunity)testObjects.get('Opportunity');
        test.stopTest();
        
        BatchCloseOppsScheduledJob binsj = new BatchCloseOppsScheduledJob();
        String sch = '0 1 0 * * ?';
        System.schedule('Test Opp close Job', sch, binsj);
    }
    
    @isTest static void BatchCloseOppsTest() {
        test.startTest();
        Map<String, SObject> testObjects = TestClassUtility.buildNationalData();
        
        Opportunity testOpportunity = (Opportunity)testObjects.get('Opportunity');
        
        test.stopTest();
        
        BatchCloseOpps bb = new BatchCloseOpps();
        Database.executeBatch(bb);
    }
}