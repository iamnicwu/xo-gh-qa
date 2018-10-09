global class SchFulfillmentResponseDeletion implements Schedulable {

  global void execute(SchedulableContext sc) {
    String filterDate = DateTime.newInstance(Date.today().addMonths(-1), Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd') + 'T00:00:01.000Z';

		String deleteQuery =  'SELECT '
                            + 'Id '
                          + ' FROM '
                            + 'Partner_Fulfillment_Response__c'
                          + ' WHERE '
                            + 'CreatedDate < ' + filterDate;
    
    GenericBatchQueryDeletion genericBatchDelete = new GenericBatchQueryDeletion(deleteQuery);
    Database.executeBatch(genericBatchDelete);
	}
}