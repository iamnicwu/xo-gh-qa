global class SchEchoSignNotification implements Schedulable {
	global void execute(SchedulableContext sc) {
		BatchEchoSignNotifications batchNotif = new BatchEchoSignNotifications();
    Database.executeBatch(batchNotif);
	}
}