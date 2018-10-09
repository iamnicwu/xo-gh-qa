/* 
<class>
	<name>OutOfOfficeTriggerHandlerTest</name>
	<purpose>Tests the TaskTriggerNewHandler apex class</purpose>
	<created>
		<by>Harikrishnan Mohan</by>
		<date>9/14/2015</date>
		<ticket> </ticket>
	</created>
</class>
*/
@isTest
private class OutOfOfficeTriggerHandlerTest {
	
	@isTest 
	static void OutOfOfficeTest() {
	
		List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
		Out_Of_Office__c testOutOfOffice = new Out_Of_Office__c();
		testOutOfOffice.Assign_Task_To__c = userList[0].id;
		testOutOfOffice.Start_Date__c = Date.Today();
		testOutOfOffice.End_Date__c = Date.Today() + 15;
		insert testOutOfOffice;

		testOutOfOffice = new Out_Of_Office__c();
		testOutOfOffice.Assign_Task_To__c = userList[0].id;
		testOutOfOffice.Start_Date__c = Date.Today() + 16;
		testOutOfOffice.End_Date__c = Date.Today() + 20;
		insert testOutOfOffice;
		
		testOutOfOffice.Assign_From__c = userList[1].id;
		update testOutOfOffice;
		
		
		Out_Of_Office__c testOutOfOffice1 = new Out_Of_Office__c();
		testOutOfOffice1.Assign_Task_To__c = userList[0].id;
		testOutOfOffice1.Start_Date__c = Date.Today();
		testOutOfOffice1.End_Date__c = Date.Today() + 15;
		testOutOfOffice1.Assign_From__c = userList[1].id;
		
		try{
			insert testOutOfOffice1;
		}
		catch (Exception e) {
		}
	}
}