/* 
<class>
  <name>BatchNotifyPaymentMthdExpScheduledJob</name>
  <purpose>Scheduled class for "BatchNotifyPaymentMethodExpiration" batch class</purpose>
  <created>
    <by>Hari Mohan</by>
    <date>10/2/2015</date>
    <ticket>SF-1125, SF-1126, SF-1127, SF-1128, SF-1040</ticket>
  </created>
</class>
*/
global class BatchNotifyPaymentMthdExpScheduledJob implements Schedulable {
	global void execute(SchedulableContext sc) {
		BatchNotifyPaymentMethodExpiration b = new BatchNotifyPaymentMethodExpiration();
		database.executebatch(b);
	}
}