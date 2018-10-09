global with sharing class BatchCalculateLiveChargeTCVSchJob implements Schedulable{
   global void execute(SchedulableContext sc) {
		database.executebatch(new BatchCalculateLiveChargeTCVMonthly());
	}
}