@isTest
private class EmailMessageTriggerTest {
  static testMethod void testMethod1() {
    Test.startTest();
    Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Case.getRecordTypeInfosByName();
		Case mockCase = new Case();
		mockCase.Description = 'testCase';
		mockCase.recordTypeId = rtMapByName.get('3 - Reviews').getRecordTypeId();
		mockCase.SuppliedEmail = 'testemail@test.com';
		insert mockCase;

		mockCase.Status = 'Closed';
		mockCase.Outcome__c = 'Review Removed';
		update mockCase;

		EmailMessage emaiMeassageObj = new EmailMessage();
		emaiMeassageObj.RelatedToId = mockCase.id;
		// emaiMeassageObj.Status = 'Draft';
		emaiMeassageObj.Subject = 'test for email message trigger';

		insert emaiMeassageObj;

		emaiMeassageObj.Subject = 'test for email message trigger update';
		update emaiMeassageObj;

		delete emaiMeassageObj;
		Test.stopTest();
  }
}