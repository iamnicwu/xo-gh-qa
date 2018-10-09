global class BatchCreateTaskForInvoiceScheduledJob implements Schedulable{
	
	global void execute(SchedulableContext sc) {
		BatchCreateTaskForInvoice b = new BatchCreateTaskForInvoice();
		database.executebatch(b);
	}
	
}