/* 
<Class>
  <name>BatchRepairQuotesSentToZuoraScheduledJob</name>
  <purpose>For scheduling BatchRepairQuotesSentToZuora
  </purpose>
  <created>
    <by>Steve O'Neal</by>
    <date>04/28/2016</date>
    <ticket></ticket>
  </created>
</Class>
*/
global class BatchRepairQuotesSentToZuoraScheduledJob implements Schedulable {
	global void execute(SchedulableContext sc) {
		BatchRepairQuotesSentToZuora b = new BatchRepairQuotesSentToZuora();
		database.executebatch(b);
	}
}