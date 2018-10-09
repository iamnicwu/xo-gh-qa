/* 
<Class>
  <name>BatchDeleteNonsellableRPCScheduledJob</name>
  <purpose>For scheduling BatchDeleteNonsellableRatePlanCharge
  </purpose>
  <created>
    <by>Steve O'Neal</by>
    <date>03/01/2016</date>
    <ticket>CSP-291</ticket>
  </created>
</Class>
*/
global class BatchDeleteNonsellableRPCScheduledJob implements Schedulable {
	global void execute(SchedulableContext sc) {
		BatchDeleteNonsellableRatePlanCharge b = new BatchDeleteNonsellableRatePlanCharge();
		database.executebatch(b);
	}
}