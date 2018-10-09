global class BatchDelExpQuoAssWOpenOptyScheduleJob implements Schedulable {
	global void execute(SchedulableContext sc) {
		BatchDelExpiredQuotesAssociatedWOpenOpty b = new BatchDelExpiredQuotesAssociatedWOpenOpty();
		database.executebatch(b);
	}
}