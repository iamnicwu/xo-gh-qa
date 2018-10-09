/* 
<class>
  <name>BatchTaskTest</name>
  <purpose>For testing the BatchTask class</purpose>
  <created>
    <by>Steve O'Neal</by>
    <date>9/18/2015</date>
    <ticket>SF-1223</ticket>
  </created>
</class>
*/
@isTest
private class BatchTaskScheduledJobTest{

  /* 
    <method>
      <name>testScheduledJob</name>
      <purpose>Test the scheduled job</purpose>
      <created>
        <by>Steve O'Neal</by>
        <date>9/18/2015</date>
        <ticket>SF-1223</ticket>
      </created>
    </method>
    */
    static testMethod void testScheduledJob() {
        
        Task newTask = new Task();
        newTask.Subject = 'testing task';
        newTask.Status = 'Not Started';
        newTask.ActivityDate = Date.Today().addDays(-1);
        newTask.Delete_After_Due_Date__c = true;
        insert newTask;
        
        Test.startTest();
        
        BatchTaskScheduledJob job = new BatchTaskScheduledJob();
        String sch = '0 2 0 * * ?';
        // System.schedule('Test BatchTask Job 1', sch, job);
        
        Test.stopTest();
    }
}