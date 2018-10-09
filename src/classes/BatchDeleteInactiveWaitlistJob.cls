global class BatchDeleteInactiveWaitlistJob implements Schedulable {
    global void execute(SchedulableContext sc) {
        BatchDeleteInactiveWaitlist b = new BatchDeleteInactiveWaitlist();
        database.executebatch(b);
    }
}