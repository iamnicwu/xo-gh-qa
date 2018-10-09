/* 
<class>
  <name>BatchCreateTaskFromInventoryScheduledJob</name>
  <purpose>Used to schedule the BatchCreateTaskFromInventory class</purpose>
  <created>
    <by>Steve O'Neal</by>
    <date>9/18/2015</date>
    <ticket>SF-1223</ticket>
  </created>
</class>
*/
global class BatchCreateTaskFromInventoryScheduledJob implements Schedulable{
  global void execute(SchedulableContext sc) {
      BatchCreateTaskFromInventory bct = new BatchCreateTaskFromInventory();
      ID batchprocessid = Database.executeBatch(bct);
  }
}