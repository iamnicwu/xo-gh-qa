/* 
<Class>
  <name>BatchDeleteZeroDollarSubChrgScheduledJob</name>
  <purpose>For scheduling BatchDeleteZeroDollarSubscriptionCharges
  </purpose>
  <created>
    <by>Steve O'Neal</by>
    <date>03/01/2016</date>
    <ticket>CSP-291</ticket>
  </created>
</Class>
*/
global class BatchDeleteZeroDollarSubChrgScheduledJob implements Schedulable {
	global void execute(SchedulableContext sc) {
		BatchDeleteZeroDollarSubscriptionCharges b = new BatchDeleteZeroDollarSubscriptionCharges();
		database.executebatch(b);
	}
}