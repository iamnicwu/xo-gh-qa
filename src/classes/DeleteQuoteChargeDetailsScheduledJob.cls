// CSP-1834
global class DeleteQuoteChargeDetailsScheduledJob implements Schedulable {
	global void execute(SchedulableContext sc) {
		String queryString = 'SELECT Id FROM zqu__QuoteChargeDetail__c '
								+ 'WHERE Sent_To_ZBilling__c = true '
								+ 'AND SystemModstamp < ' + String.valueOf(DateTime.now().addMonths(-1).format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\''));

		Database.executeBatch(new GenericBatchQueryDeletion(queryString));
	}
}