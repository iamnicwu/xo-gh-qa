// CSP-1851
global class BatchAssignmentHistoryUpdateSchJob implements Schedulable {
	global void execute(SchedulableContext sc) {
		database.executebatch(new BatchAssignmentHistoryUpdate());
	}
}