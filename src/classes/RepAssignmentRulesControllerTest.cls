@isTest
private class RepAssignmentRulesControllerTest {
	
	@isTest static void controllerTest() {
		Market__c testMarket = TestClassUtility.createMarket(true);
        Category__c testCategory = TestClassUtility.createCategory(true);
        Zip__c testZipcode = TestClassUtility.createZip(true);
        User testUser = [SELECT Id FROM User WHERE IsActive = true AND Profile.Name LIKE '%local%' LIMIT 1];

        RepresentativeAssignmentRulesController.getPicklistValue();

        // Forced fail
        RepresentativeAssignmentRulesController.queryUsers(null);
        // Actual code test
        RepresentativeAssignmentRulesController.queryUsers('Test User');

        // No param query
        RepresentativeAssignmentRulesController.queryRules('', '', '', '');

        // Market, Cat, User Query
        RepresentativeAssignmentRulesController.queryRules(testMarket.Id, testCategory.Id, '', testUser.Id);

        // Zip, Cat, User Query
        RepresentativeAssignmentRulesController.queryRules('', testCategory.Id, '111111', testUser.Id);

        // Sample JSON string
        // {"Id":"a3m110000003QfhAAE","Market__c":"a3R11000000DxoCEAS","Category__c":"a3U110000009JYSEA2","Zip_Code__c":"","Sales_Rep__c":"005j000000DU2HsAAL"}

        String jsonMarketCatSave = '{"Id":"","Market__c":"' + testMarket.Id + '","Category__c":"' + testCategory.Id + '","Zip_Code__c":"","Sales_Rep__c":"' + testUser.Id + '"}';
        String jsonZipcodeSave = '{"Id":"","Market__c":"","Category__c":"","Zip_Code__c":"112331","Sales_Rep__c":"' + testUser.Id + '"}';
        String jsonZipcodeSaveValid = '{"Id":"","Market__c":"","Category__c":"","Zip_Code__c":"' + testZipcode.ZipCode__c + '","Sales_Rep__c":"' + testUser.Id + '"}';
        
        // Blank Rule
        RepresentativeAssignmentRulesController.saveAssignmentRule(null);
        // Rule save
        RepresentativeAssignmentRulesController.saveAssignmentRule(jsonMarketCatSave);
        // Invalid Zip Save - Exception Thrown
        RepresentativeAssignmentRulesController.saveAssignmentRule(jsonZipcodeSave);
        // Valid Zip save
        RepresentativeAssignmentRulesController.saveAssignmentRule(jsonZipcodeSaveValid);

        Local_Sales_Rep_Assignment__c testAssignment = [SELECT Id FROM Local_Sales_Rep_Assignment__c LIMIT 1];
        String jsonUpdateAssignId = '{"Id":"' + testAssignment.Id + '","Market__c":"' + testMarket.Id + '","Category__c":"' + testCategory.Id + '","Zip_Code__c":"","Sales_Rep__c":"' + testUser.Id + '"}';

        // Invalid Assignment Rule Id - Exception Thrown
        RepresentativeAssignmentRulesController.saveAssignmentRule(jsonUpdateAssignId);

        // Mass assignment rule update
        List<Local_Sales_Rep_Assignment__c> assignmentList = [SELECT Id, Sales_Rep__c FROM Local_Sales_Rep_Assignment__c LIMIT 20];
        RepresentativeAssignmentRulesController.massSaveAssignmentRules(assignmentList);

        // Mass assignment rule update - failure
        RepresentativeAssignmentRulesController.massSaveAssignmentRules(new List<Local_Sales_Rep_Assignment__c>{new Local_Sales_Rep_Assignment__c()});
	}
	
}