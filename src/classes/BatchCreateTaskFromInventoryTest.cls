/*******************************************************************************
 *  Summary         : Test class for BatchCreateTaskFromInventory
 *  Refer Object    : 
 *  Author          : Nick
 *  RefactorDate    : 12 Dec 2016
 *  Change Log      : Refactoring by SF-2.6 release
 ******************************************************************************/
@isTest
private class BatchCreateTaskFromInventoryTest {
	@isTest 
	static void test_method_one(){
		// Implement test code
		Test.startTest();

		BatchCreateTaskFromInventory bb = new BatchCreateTaskFromInventory();
		Database.executeBatch(bb);

		Test.stopTest();
	}
	
	@isTest 
	static void test_method_two(){
		Test.startTest();

		BatchCreateTaskFromInventoryScheduledJob job = new BatchCreateTaskFromInventoryScheduledJob();
		String sch = '0 0 0 3 9 ? 2022';
		System.schedule('Test BatchCreateTaskFromInventoryTest Job', sch, job);

		Test.stopTest();
	}

	@isTest
	static void test_method_three() {

		TestClassUtility.buildZQUTestObjects(false);
		
		Test.startTest();

		BatchCreateTaskFromInventory bb = new BatchCreateTaskFromInventory();
		Database.executeBatch(bb);

		Test.stopTest();
	}
}