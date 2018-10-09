@isTest
public class NotifyInternalCaseCancelsCaseTest {
    static testMethod void testMethod1() {
    	Case testCase = new Case();
    	insert testCase;

    	test.startTest();
        NotifyInternalCaseCancelsCaseController cls = new NotifyInternalCaseCancelsCaseController();
        cls.caseId = testCase.Id;
        String testId = cls.caseId;
        String testLink = cls.caseLink;
        case newCase = cls.currentCase;
      test.stopTest();
    }
}