/* 
<class>
	<name>TaskTriggerNewHandlerTest</name>
	<purpose>Tests the TaskTriggerNewHandler apex class</purpose>
	<created>
		<by>Harikrishnan Mohan</by>
		<date>9/14/2015</date>
		<ticket> </ticket>        
	</created>
</class>
*/
@isTest
private class TaskTriggerNewHandlerTest {
	@isTest static void myUnitTest() {
		Test.startTest();
    		Map<String, SObject> testObjects = TestClassUtility.buildZQUTestObjects(false);
    		Account testAccount = (Account)testObjects.get('Account');
    		Task testTask = TestClassUtility.createTask(false);
    		testTask.WhatId = testAccount.Id;
    		insert testTask;
		Test.stopTest();

		TaskTriggerNewHandler tskTrgrNewHndlr = new TaskTriggerNewHandler();
		tskTrgrNewHndlr.beforeInsert(testTask);
		tskTrgrNewHndlr.beforeUpdate(testTask, testTask);
		tskTrgrNewHndlr.beforeDelete(testTask);
		tskTrgrNewHndlr.afterInsert(testTask);
		tskTrgrNewHndlr.afterUpdate(testTask, testTask);
		tskTrgrNewHndlr.afterDelete(testTask);
	}
}