/* 
<class>
  <name>SubscriptionBatchClassScheduledJob</name>
  <purpose>Used to schedule the SubscriptionBatchClass</purpose>
  <created>
    <by>Jonathan Satterfield</by>
    <date>8/17/2015</date>
    <ticket>SF-612</ticket>
  </created>
</class>
*/
global class SubscriptionBatchClassScheduledJob implements Schedulable{
	/* 
    <method>
      <name>execute</name>
      <purpose>"execute" is a standard method used in Scheduled classes; runs the SubscriptionBatchClass job</purpose>
      <created>
        <by>Jonathan Satterfield</by>
        <date>8/17/2015</date>
        <ticket>SF-612</ticket>
      </created>
    </method>
    */
	global void execute(SchedulableContext sc) {
	    SubscriptionBatchClass b1 = new SubscriptionBatchClass();
	    ID batchprocessid = Database.executeBatch(b1);
	}
}