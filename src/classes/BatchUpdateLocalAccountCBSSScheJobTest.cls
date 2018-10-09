@isTest
private class BatchUpdateLocalAccountCBSSScheJobTest {
    static testMethod void testMethod1() {
        BatchUpdateLocalAccountCBSSScheduledJob bsj = new BatchUpdateLocalAccountCBSSScheduledJob();
	    String sch = '0 1 0 * * ?';
	    System.schedule('Test Inventory Job', sch, bsj);
    }
}