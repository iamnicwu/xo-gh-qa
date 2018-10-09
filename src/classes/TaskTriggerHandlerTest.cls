/* 
<class>
  <name>TaskTriggerHandlerTest</name>
  <purpose>For testing save/delete events on a Task</purpose>
  <created>
	<by>Jonathan Satterfield</by>
	<date>6/4/2015</date>
	<ticket>SF-542</ticket>
  </created>
</class>
*/
@isTest
public class TaskTriggerHandlerTest {
	@testSetup static void createTestData(){
			TestClassUtility.generateQuotePdfConfig(true);
	}

	/* 
	<method>
	  <name>RecordOpportunityStageOnTask</name>
	  <purpose>Test the RecordOpportunityStageOnTask method</purpose>
	  <created>
		<by>Jonathan Satterfield</by>
		<date>6/4/2015</date>
		<ticket>SF-542</ticket>
	  </created>
	</method>
	*/
	private static testmethod void RecordOpportunityStageOnTask() {
		
		SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
												'Complete',
												'{"companyName": "Test Account"}',
												null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);
		
		
		Opportunity testOpportunity = TestClassUtility.createOpportunity(true);
		List<Task> opportunityTasks = new List<Task>();
		
		for (Integer i=0; i < 5; i++) {
			Task t = new Task();
			t.OwnerId = UserInfo.getUserId();
			t.WhatId = testOpportunity.Id;
			t.Subject = 'Call';
			t.CBSSResult__c = 'Payment Information Provided';
			t.Type = 'Call';
			t.Status = 'In Progress';
			t.Priority = 'Normal';
			t.Opportunity_Stage__c = '';
			t.ActivityDate = Date.today();
			opportunityTasks.add(t);
		}

		Out_Of_Office__c testOutOfOffice = new Out_Of_Office__c();
		testOutOfOffice.Assign_From__c = UserInfo.getUserId();
		testOutOfOffice.Start_Date__c = Date.today().addDays(-5);
		testOutOfOffice.End_Date__c = Date.today().addDays(5);
		testOutOfOffice.Assign_Task_To__c = [SELECT Id FROM User LIMIT 1].Id;
		insert testOutOfOffice;

		Test.startTest();
		insert opportunityTasks;

		Test.stopTest();

		Set<Id> opportunityTaskIds = new Set<Id>();
		
		for (Task insertedTask : opportunityTasks) {
			opportunityTaskIds.add(insertedTask.Id);
		}
		
		List<Task> insertedOpportunityTasks = [SELECT Id, Opportunity_Stage__c FROM Task WHERE Id in :opportunityTaskIds];
		
		for (Task insertedTask : insertedOpportunityTasks) {
			System.assert(insertedTask.Opportunity_Stage__c == testOpportunity.StageName);
		}
	}
	
	private static testmethod void RecordThoughtStarterRFPOnTask() {
		User u = [select id from user WHERE UserRole.Name = 'Sales Development' and IsActive = true limit 1];
		System.runAs(u){	
	    GroupMember testGroupMember = new GroupMember();
	    testGroupMember.UserOrGroupId = u.Id;
	    testGroupMember.GroupId = [SELECT Id FROM Group WHERE DeveloperName = 'Sales_Dev_Team'].Id;
	    insert testGroupMember;
		}
		
		SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
																																	'Complete',
																																	'{"companyName": "Test Account"}',
																																	null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);
		Account testAcc = TestClassUtility.createAccount(true);
		Opportunity testOpportunity = TestClassUtility.createOpportunity(false, testAcc);
		testOpportunity.AccStrategist__c = UserInfo.getUserId();
    insert testOpportunity;
    Id pricebookId = Test.getStandardPricebookId();
    Product2 testProduct2 = TestClassUtility.createProduct2(true);
    PricebookEntry testPBEntry = TestClassUtility.createPricebookEntry(true,pricebookId, testProduct2);
    Id thoughtStarterRecordTypeId = Schema.SObjectType.ThoughtStarter_RFP__c.getRecordTypeInfosByName().get('ThoughtStarter').getRecordTypeId();
    ThoughtStarter_RFP__c TRFP = TestClassUtility.createThoughtStarterRFP(false, testOpportunity, thoughtStarterRecordTypeId, u);
		TRFP.Sales_Developer__c = null;
		insert TRFP;
		/*
    TRFP.Opportunity__c = testOpportunity.id;
    TRFP.name = 'testTRFP';
    TRFP.RecordTypeId = RecordTypeId;
    TRFP.Clicks__c = true;
    TRFP.CTR__c  = 10;
    TRFP.End_Actions__c = false;
    TRFP.Leads__c = false;
    TRFP.Brand_Exposure__c = false;
    TRFP.Sales_Dev_Needed__c = true;
    TRFP.Sales_Developer__c = u.id;
		*/
		
		Task t = new Task();
		t.OwnerId = u.Id;
		t.WhatId = TRFP.Id;
		t.Subject = 'ThoughtStarter has been submitted';
		t.Purpose__c = 'Other';
		t.Type = 'Call';
		t.Status = 'In Progress';
		t.Priority = 'Normal';
		t.CallObject = 'test';
		Task t2 = new Task();
		t2.OwnerId = u.Id;
		t2.WhatId = TRFP.Id;
		t2.Subject = 'RFP has been approved and ready to be pitched to client!';
		t2.Purpose__c = 'Other';
		t2.Type = 'Call';
		t2.Status = 'In Progress';
		t2.Priority = 'Normal';
		insert new List<Task>{t, t2};

		Test.startTest();
		t.Status = 'Completed';
		t2.Status = 'Completed';
		t.CBSSResult__c = 'Payment Information Provided';
		t2.ServiceResult__c = 'Payment Information Provided';
		update new List<Task>{t, t2};

		Test.stopTest();

		t = [select id, CallObject, Task_Completion_Date__c FROM Task WHERE id =: t.Id];
		system.assert(String.isBlank(t.CallObject));
		System.assertEquals(t.Task_Completion_Date__c.date(), system.today());
		
	}

	private static testmethod void RecordAccountOnTask() {
		
		SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
												'Complete',
												'{"companyName": "Test Account"}',
												null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);
		
		Account testAcc = TestClassUtility.createAccount(false);
		testAcc.Past_Due_Balance__c = 1.1;
		insert testAcc;

		List<Task> accountTasks = new List<Task>();
		
		for (Integer i=0; i < 5; i++) {
			Task t = new Task();
			t.OwnerId = UserInfo.getUserId();
			t.WhatId = testAcc.Id;
			t.Subject = 'Call';
			t.ServiceResult__c = 'Payment Information Provided';
			t.Type = 'Call';
			t.Status = 'In Progress';
			t.Priority = 'Normal';
			t.Opportunity_Stage__c = '';
			accountTasks.add(t);
		}
		accountTasks[0].CallObject = 'test';
		Test.startTest();
		insert accountTasks;
		Test.stopTest();

		Set<Id> accountTaskIds = new Set<Id>();
		
		for (Task insertedTask : accountTasks) {
			accountTaskIds.add(insertedTask.Id);
		}
		
		List<Task> insertedAccountTasks = [SELECT Id, Account__c FROM Task WHERE Id in :accountTaskIds];
		
		for (Task insertedTask : insertedAccountTasks) {
			System.assert(insertedTask.Account__c == testAcc.Id);
		}
	}
	
	/* 
	<method>
	  <name>RecordLastResultOnLocalLead</name>
	  <purpose>Test the RecordLastResultOnLocalLead method</purpose>
	  <created>
		<by>Jonathan Satterfield</by>
		<date>6/22/2015</date>
		<ticket>SF-610</ticket>
	  </created>
	</method>
	*/
	static testMethod void RecordLastResultOnLocalLead() {
		
		// First, insert a Lead and a related Task
		SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
												 'Complete',
												 '{"companyName": "Test Account"}',
												 null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);
		
		Test.startTest();
		Map<String, SObject> testObjects = TestClassUtility.buildLocalData(false);
		
		Market__c testMarket = (Market__c)testObjects.get('Market__c');
		Category__c testCategory = (Category__c)testObjects.get('Category__c');
		Lead testLead = TestClassUtility.createLead(true, testMarket, testCategory);

		Task testTask = new Task(WhoId=testLead.Id,Subject='Call',Type='Call',Status='In Progress',Priority='Normal' );
		insert testTask;
		
		testLead = [SELECT Id, Last_Result__c, Last_Result_Date__c FROM Lead WHERE Id = :testLead.Id];
		
		// Because Task.Status is not 'Completed', Lead.Last_Result__c should not be equal to Task.Subject
		System.assertNotEquals(testLead.Last_Result__c, testTask.Subject);
		
		// Next, update the Task.Status to equal 'Completed'
		testTask.Status = 'Completed';
		// update testTask;
		// testLead = [SELECT Id, Last_Result__c, Last_Result_Date__c FROM Lead WHERE Id = :testLead.Id];
		
		// At this point the Trigger should fire, and Lead.Last_Result__c should equal Task.Subject,
		// and Lead.Last_Result_Date__c should be equal to Date.today()
		//System.assertEquals(testLead.Last_Result__c, testTask.Subject);
		//System.assertEquals(testLead.Last_Result_Date__c, Date.today());
		
		// Lastly, check to make sure that when a new Task is created with a Status of 'Completed',
		// the Lead.Last_Result__c field gets updated to the new Task's Subject
		testTask = new Task(WhoId=testLead.Id,Subject='Test Complete',Type='Call',Status='Completed',Priority='Normal');
		insert testTask;
		testLead = [SELECT Id, Last_Result__c, Last_Result_Date__c FROM Lead WHERE Id = :testLead.Id];
		//System.assertEquals(testLead.Last_Result__c, testTask.Subject);
		Test.stopTest();
	}


	static testMethod void testOnboardingCall(){

		Test.startTest();

		String content = 'Review Details:\r\n';
					 content += 'Review Id: 1356749,\r\n';
					 content += 'Storefront Id: 6fc9aed0-29c7-4cee-be59-a38f00f7a395,\r\n'; 
					 content += 'Display Id: 665527,\r\n';
					 content += 'Date: 10/3/2016 10:14 AM,\r\n';
					 content += 'Reviewer: 2840263e-d206-4551-bcc5-6818d76772c2.\r\n';


		Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Case.getRecordTypeInfosByName();
		Account acc = TestClassUtility.createAccount(true);
		acc.Strategy_Specialist__c = UserInfo.getUserId();
		update acc;
		Contact con = TestClassUtility.createContact(true, acc);

		List<Case> clist = createCases(content, rtMapByName.get('2 - Onboarding').getRecordTypeId(), con);

		insert clist;

		Task t1 = createTask(clist[0], 'Not Started', 'Onboarding Scheduling', 'Immediate Onboard');
		Task t2 = createTask(clist[1], 'Not Started', 'Onboarding Scheduling', 'Scheduled Onboard');
		Task t3 = createTask(clist[2], 'Not Started', 'Onboarding Scheduling', 'Declined Onboard');
		Task t4 = createTask(clist[3], 'Not Started', 'Onboarding Scheduling', 'No Answer');
		Task t5 = createTask(clist[4], 'Not Started', 'Onboarding Call', 'Rescheduled Onboard');
		Task t6 = createTask(clist[5], 'Not Started', 'Onboarding Call', 'Cancelled Onboard');
		Task t7 = createTask(clist[6], 'Not Started', 'Onboarding Call', 'Left Message');
		Task t8 = createTask(clist[7], 'Not Started', 'Onboarding Call', 'Completed Onboard');
		Task t9 = createTask(clist[8], 'Not Started', 'Onboarding Call', 'Declined Onboard');
		Task t10 = createTask(clist[9], 'Not Started', 'Onboarding Scheduling', 'Send Calendar Link');
		Task t11 = createTask(clist[10], 'Not Started', 'Onboarding Call', 'Send Calendar Link');
		Task t12 = createTask(clist[10], 'Completed', 'Onboarding Call', '');
		List<Task> tlist = new List<Task>();

		tlist.add(t1);
		tlist.add(t2);
		tlist.add(t3);
		tlist.add(t4);
		tlist.add(t5);
		tlist.add(t6);
		tlist.add(t7);
		tlist.add(t8);
		tlist.add(t9);
		tlist.add(t10);
		tlist.add(t11);
		tlist.add(t12);
		insert tlist;
	
		List<Task> tlist2 = new List<Task>();
		for(Integer i = 0; i < 11; i++){
			Task tempTask = tlist.get(i);
			tempTask.Status = 'Completed';
			if(String.isBlank(tempTask.Onboarding_Task_Outcome__c)){
				tempTask.Onboarding_Task_Outcome__c = 'Completed Onboard';
			}
			tlist2.add(tempTask);
		}
	
		update tlist2;

		Test.stopTest();

		system.assertEquals(t1.ActivityDate, t1.onboarding_date__c);
		List<Task> TaskList = [select id, Dispostition_Type__c FROM Task WHERE Dispostition_Type__c = 'SS Core'];
		system.assert(TaskList.size() > 10);

	}



	public static List<Case> createCases(String content, String recordtypeId, Contact con){

		List<Case> cases = new List<Case>();

		for(Integer i=0;i<11;i++){

			Case mockCase = new Case();
			mockCase.Description = content;
			mockCase.recordTypeId = recordtypeId; 
			mockCase.no_show_attempts__c = '0';
			mockCase.follow_up_attempts__c = '0';
			mockCase.attempts__c = '0';
			mockCase.SuppliedEmail = con.Email;
			cases.add(mockCase);
		}
		
		return cases;
	}

	public static Task createTask(Case mockCase, String status, String ssDispositionCode, String outcome){

		Task obTask = new Task();
		obTask.Type = 'Call';
		obTask.Purpose__c = 'Onboarding';
		obTask.Status = status;
		obTask.Dispostition_Type__c= 'SS Core';
		obTask.ServiceResult__c = ssDispositionCode;
		obTask.Onboarding_Task_Outcome__c = (String.isBlank(outcome))? null: outcome;
		obTask.Subject ='test Task 001';
		obTask.WhatId = mockCase.id;
		obTask.Onboard_Automation__c = true;
		obTask.ActivityDate = system.today();
		obTask.onboarding_date__c = system.today();
		return obTask;
	}
	
}