/* 
<class>
  <name>BatchSendQuotesToZuoraHourlyScheduledJob</name>
  <purpose>Used to schedule the BatchSendQuotesToZuoraHourly class</purpose>
  <created>
    <by>Scott Yang</by>
    <date>Dec/06/2016</date>
    <ticket>CSP-1553</ticket>
  </created>
</class>
*/
global class BatchSendQuotesToZuoraHourlyScheduledJob implements Schedulable{
  global void execute(SchedulableContext sc) {
      Integer size = Integer.valueOf(Label.BatchSendQuoteToZuora_Size);
      BatchSendQuotesToZuoraHourly bat = new BatchSendQuotesToZuoraHourly();
      bat.sendQuotesToBilling = false;
      ID batchprocessid = Database.executeBatch(bat,size);
  }
}