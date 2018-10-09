/* 
<Class>
  <name>BatchDeleteNonsellableZproductsScheduled</name>
  <purpose>For scheduling BatchDeleteNonsellableZproducts
  </purpose>
  <created>
    <by>Steve O'Neal</by>
    <date>03/01/2016</date>
    <ticket>CSP-291</ticket>
  </created>
</Class>
*/
global class BatchDeleteNonsellableZproductsScheduled implements Schedulable {
	global void execute(SchedulableContext sc) {
		BatchDeleteNonsellableZproducts b = new BatchDeleteNonsellableZproducts();
		database.executebatch(b);
	}
}