global class ScheduledAccountContactRoleSync implements Schedulable {
       global void execute(SchedulableContext sc) {
		AccountContactRoleSync roleSync = new AccountContactRoleSync(System.Today().addDays(-1),'Primary');
        Database.executeBatch(roleSync);
   }
}