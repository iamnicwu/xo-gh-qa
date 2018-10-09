/* 
<Class>
  <name>BatchDeleteAvailableInventoryScheduled</name>
  <purpose>For scheduling BatchDeleteAvailableInventory
  </purpose>
  <created>
    <by>Steve O'Neal</by>
    <date>03/02/2016</date>
    <ticket>CSP-291</ticket>
  </created>
</Class>
*/
global class BatchDeleteAvailableInventoryScheduled implements Schedulable {
	global void execute(SchedulableContext sc) {
		BatchDeleteAvailableInventory b = new BatchDeleteAvailableInventory();
		database.executebatch(b);
	}
}