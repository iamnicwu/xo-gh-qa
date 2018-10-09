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
global class BatchDeleteNonsellableProductsScheduled implements Schedulable {
	global void execute(SchedulableContext sc) {
		BatchDeleteNonsellableProducts b = new BatchDeleteNonsellableProducts();
		database.executebatch(b);
	}
}