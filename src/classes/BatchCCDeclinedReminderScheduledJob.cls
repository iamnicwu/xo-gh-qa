global class BatchCCDeclinedReminderScheduledJob implements Schedulable {
	global void execute(SchedulableContext sc) {
		BatchCCDeclinedReminder b = new BatchCCDeclinedReminder();
		database.executebatch(b);
	}
}