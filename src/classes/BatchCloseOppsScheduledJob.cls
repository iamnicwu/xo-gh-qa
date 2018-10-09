/* 
<class>
  <name>BatchCloseOppsScheduledJob </name>
  <purpose>Used to Schedule batch class BatchCloseOpps (Auto closed the open Opp which is not modified in last 90 days.)</purpose>
  <created>
    <by>Tony Liu</by>
    <date>07/07/2016</date>
    <ticket>CSP-1138</ticket>
  </created>
</class>
*/
global class BatchCloseOppsScheduledJob implements Schedulable {
    global void execute(SchedulableContext sc) {
        BatchCloseOpps batchNotif = new BatchCloseOpps();
    Database.executeBatch(batchNotif);
    }
}