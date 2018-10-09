/* 
<Class>
  <name>BatchResetPastDueBalanceOnCaseSchJob</name>
  <purpose>For scheduling BatchResetPastDueBalanceOnCase
  </purpose>
  <created>
    <by>Tony Liu</by>
    <date>02/01/2018</date>
    <ticket>CSP-2645</ticket>
  </created>
</Class>
*/

global class BatchResetPastDueBalanceOnCaseSchJob implements Schedulable {
  global void execute(SchedulableContext sc) {
    BatchResetPastDueBalanceOnCase b = new BatchResetPastDueBalanceOnCase();
		database.executebatch(b);
  }
}