// CSP-1863
global class DeleteInvoiceItemsScheduledJob implements Schedulable {
	global void execute(SchedulableContext sc) {
		String queryString = 'SELECT Id FROM InvoiceItem__c '
								+ 'WHERE CreatedDate < ' + String.valueOf(DateTime.now().addDays(-1).format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\''));

		Database.executeBatch(new GenericBatchQueryDeletion(queryString));
	}
}