/* 
<class>
  <name>BatchInventoryNewScheduledJob</name>
  <purpose>Used to schedule the BatchInventoryNew class</purpose>
  <created>
    <by>Om Vankayalapati</by>
    <date>9/11/2015</date>
    <ticket>SF-1211_Generic_Inventory_Management</ticket>
  </created>
</class>
*/
global class BatchInventoryNewScheduledJob implements Schedulable{
 
  
    /*Integer intervalMinutes = 1;
    
    public void execute(SchedulableContext sc) {
        // Re-schedule ourself to run again in "intervalMinutes" time
        DateTime now  = DateTime.now();
        DateTime nextRunTime = now.addMinutes(intervalMinutes);
        String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + 
            nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + 
            nextRunTime.month() + ' ? ' + nextRunTime.year(); 
        System.schedule(BatchInventoryNewScheduledJob.class.getName() + '-' + now.format(), cronString, new BatchInventoryNewScheduledJob());
        // Abort the current job
        Id jobId = sc.getTriggerId();
        System.abortJob(jobId);     
        // Launch a batch job or call a future method to do the actual work
        BatchInventoryNew b1 = new BatchInventoryNew();
      ID batchprocessid = Database.executeBatch(b1);
    }

  
  */
  global void execute(SchedulableContext sc) {
      BatchInventoryNew b1 = new BatchInventoryNew();
      ID batchprocessid = Database.executeBatch(b1);
  }
}