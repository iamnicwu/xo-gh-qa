/* 
<Class>
  <name>BatchDeleteNonsellableRatePlansScheduled</name>
  <purpose>For scheduling BatchDeleteNonsellableRatePlans
  </purpose>
  <created>
    <by>Steve O'Neal</by>
    <date>03/01/2016</date>
    <ticket>CSP-291</ticket>
  </created>
</Class>
*/
global class BatchDeleteNonsellableRatePlansScheduled implements Schedulable {
	global void execute(SchedulableContext sc) {
		BatchDeleteNonsellableRatePlans b = new BatchDeleteNonsellableRatePlans();
		database.executebatch(b);
	}
}