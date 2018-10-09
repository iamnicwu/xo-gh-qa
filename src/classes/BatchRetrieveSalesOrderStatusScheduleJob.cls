/* 
  @Purpose: Used to Schedule batch class BatchRetrieveSalesOrderStatus
  @Created By: Tony Liu
  @Created Date: 09/27/2017
  @Ticket: CSP-1700
*/
global class BatchRetrieveSalesOrderStatusScheduleJob implements Schedulable {
    global void execute(SchedulableContext sc) {
      BatchRetrieveSalesOrderStatus batchBRSOS = new BatchRetrieveSalesOrderStatus();
  		Database.executeBatch(batchBRSOS,5);
    }
}