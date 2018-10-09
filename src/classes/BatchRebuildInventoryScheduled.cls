/* 
<Class>
  <name>BatchRebuildInventoryScheduled</name>
  <purpose>For scheduling BatchRebuildInventory
  </purpose>
  <created>
    <by>Steve O'Neal</by>
    <date>03/09/2016</date>
    <ticket>CSP-376</ticket>
  </created>
</Class>
*/
global class BatchRebuildInventoryScheduled implements Schedulable {
	global void execute(SchedulableContext sc) {
		BatchRebuildInventory b = new BatchRebuildInventory();
		database.executebatch(b);
	}
}