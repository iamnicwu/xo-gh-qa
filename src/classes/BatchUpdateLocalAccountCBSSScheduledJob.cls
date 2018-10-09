global class BatchUpdateLocalAccountCBSSScheduledJob implements Schedulable {
    global void execute(SchedulableContext sc) {
        Set<Id> userIdSet = new Set<Id>();
		BatchUpdateLocalAccountCBSS accountCBSSBatchJob = new BatchUpdateLocalAccountCBSS(userIdSet);
		Database.ExecuteBatch(accountCBSSBatchJob, 200);
    }
}