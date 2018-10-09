@isTest
private class FeatureRequestedCancelledControllerTest {
    static testMethod void testMethod1() {
        Test.startTest();
        Map<String, SObject> testObjects = TestClassUtility.buildLocalData(false);
        Account acc = (Account)testObjects.get('Account');
        Test.stopTest();
        
        Case ca = new Case();
        ca.AccountId = acc.Id;
        insert ca;

        Feature_Requested_Cancelled__c frc1 = new Feature_Requested_Cancelled__c();
        frc1.Case__c = ca.Id;
        frc1.Sub_Product_Charge_Number__c = 'testnum';
        frc1.UniqueId__c = 'abcdefge';
        insert frc1;

        PageReference pageRef = Page.FeatureRequestedCancelledDetail;
        Test.setCurrentPageReference(pageRef);
        ApexPages.StandardController sc = new ApexPages.StandardController(new Feature_Requested_Cancelled__c());
        ApexPages.currentPage().getParameters().put('caseId', ca.Id);
        FeatureRequestedCancelledController newFRCController = new FeatureRequestedCancelledController(sc);

        List<FeatureRequestedCancelledController.SubsPCWrapper> wrapperList = new List<FeatureRequestedCancelledController.SubsPCWrapper>();
        FeatureRequestedCancelledController.SubsPCWrapper wrapper = new FeatureRequestedCancelledController.SubsPCWrapper();
        wrapper.isAdded = true;
        wrapperList.add(wrapper);
        newFRCController.subsPCWrappers = wrapperList;
        
        newFRCController.caseId = ca.Id;
        newFRCController.haveSubsPC = true;

        newFRCController.getFRCStatus();
        newFRCController.Save();
    }
}