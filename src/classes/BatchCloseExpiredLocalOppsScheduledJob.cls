// CSP-824
global class BatchCloseExpiredLocalOppsScheduledJob implements Schedulable {    
    global void execute(SchedulableContext sc) {
        BatchCloseExpiredLocalOpps b = new BatchCloseExpiredLocalOpps();
        // Batch size being modified for CSP-1767. Previous batch size was 2000 which is far too large. Temporarily
        // changing the batch size to 80 to accomodate for an issue in the Opportunity Trigger where a query is in
        // a for loop. This is being addressed by another ticket - CSP-1610. Once this has been released the batch size
        // can be bumped up to 200(or the default value)
        Database.executeBatch(b, 80);
    }
}