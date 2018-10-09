// 94% - 08/22/2016
@isTest
private class RecordAssignmentControllerTest {
	
	@isTest static void controllerTest() {
    // Get object filters for known objects
  	RecordAssignmentController.getObjectFilters('Lead', true);
    RecordAssignmentController.getObjectFilters('Account', false);

    // Get object filters for fake object(failure)
    RecordAssignmentController.getObjectFilters('Not_Real_Object__c', false);

    // Correct format
    RecordAssignmentController.getInputQueryData('Lead', 'Local_Sales_Market__c', 'Something', false);

    // Correct format - OwnerId field AND only active users
    RecordAssignmentController.getInputQueryData('Lead', 'OwnerId', 'Something', true);

    // Sending a null value
    RecordAssignmentController.getInputQueryData(null, 'Local_Sales_Market__c', 'Something', false);

    // Get user information - use current running user
    RecordAssignmentController.getUserInformation(UserInfo.getUserId());

    // Get user information sending a null value
    RecordAssignmentController.getUserInformation(null);

    // Query with filter and object - filter is JSON representation of javascript object
    RecordAssignmentController.queryWithFilters('{"checkbox":{"Owner.IsActive":[{"userInput":"true","include":true}]},"picklist":{"Primary_Category__c":[{"userInput":"a3Uj0000000fy8qEAA","include":true}]}}', 'Lead');

    // Query with filter and object both being null
    RecordAssignmentController.queryWithFilters(null, null);

    Market__c testMarket = new Market__c();
    testMarket.Name = 'Test Market';
    testMarket.Market_ID__c = '222';
    testMarket.Short_Description__c = 'Nothing';
    insert testMarket;

    Map<String,Schema.RecordTypeInfo> rtCategoryMapByName = Schema.SObjectType.Category__c.getRecordTypeInfosByName();
    Category__c testCategory = TestClassUtility.createCategory(false);
    testCategory.RecordTypeId = rtCategoryMapByName.get('Local').getRecordTypeId();
    testCategory.Category_Group__c = 'Primary';
    insert testCategory;

    Lead testLead = TestClassUtility.createLead(false,testMarket,testCategory);
    insert testLead;

    // Assign Records
    RecordAssignmentController.assignOwner(new List<String>{testLead.Id}, UserInfo.getUserId(), 'Lead');

    // Fail Assignment
    RecordAssignmentController.assignOwner(new List<String>{testLead.Id}, 'sfafasfaf', 'Lead');

    // Assign Records - null values
    RecordAssignmentController.assignOwner(null, null, null);
 
    // Instantiate Objects
    new RecordAssignmentController.FieldResponse();
    new RecordAssignmentController.FieldOptions();
    new RecordAssignmentController.UpdateFailure();
	}
}