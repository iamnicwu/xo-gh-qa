public with sharing class ReportRedirectController {
	public ReportRedirectController() {
		
	}

	public PageReference goToReport(){
		try{
			Id reportId = [select Id from Report where DeveloperName =: ApexPages.currentPage().getParameters().get('reportName')].Id;

			PageReference pageRef = new PageReference('/'+reportId);
			pageRef.setRedirect(true);
			return pageRef;
		}catch(Exception E){
			return null;
		}
	}
}