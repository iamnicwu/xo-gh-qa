@isTest
private class ReportRedirectControllerTest {
	
	@isTest(seeAllData=true) static void test_method_one() {
		PageReference pageRef = Page.ReportRedirect;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put('reportName', 'Renewal_Opportunity_Report');

        ReportRedirectController contr = new ReportRedirectController();
        contr.goToReport();
	}
	
	@isTest static void test_method_two() {
		PageReference pageRef = Page.ReportRedirect;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put('reportName', '');

        ReportRedirectController contr = new ReportRedirectController();
        contr.goToReport();
	}
	
}