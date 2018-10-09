/**
 * Test Class for : VendorLookupController
 */
@isTest
private class VendorLookupControllerTest {

    static testMethod void testVendorLookupController() {
        //DefaulCBSSValues__c createCBSSSetting = TestClassUtility.createCBSSSetting(true);
        
        Market__c testMarket = TestClassUtility.createMarket(false);
        testMarket.Market_ID__c = '222';
        testMarket.Active__c = true;
        //testMarket.Local_Sales_Region__c = testRegion.id;
        insert testMarket;
        
        RecordType accLocalRecordType = [SELECT Id, Name, SObjectType FROM RecordType WHERE SObjectType = 'Account' AND Name LIKE '%local%' AND IsActive = true LIMIT 1];

        Account parentObj = TestClassUtility.createAccount(false);
        parentObj.shippingPostalCode = '12345';
        parentObj.BillingPostalCode = '12345';
        parentObj.Phone = '1910101381';
        parentObj.Email__c = 'asd1312@asdas21213.com';
        parentObj.RecordTypeId = accLocalRecordType.Id;
        insert parentObj;

        Account accObj = TestClassUtility.createAccount(false);
        accObj.ParentId = parentObj.id;
        accObj.shippingPostalCode = '54321';
        accObj.BillingPostalCode = '54321';
        accObj.RecordTypeId = accLocalRecordType.Id;
        accObj.Email__c = '21s1212@AJKDHN132.com';
        insert accObj;
        
        System.currentPageReference().getParameters().put('accId', accObj.id);
        System.currentPageReference().getParameters().put('lksrch', 'Test');
        VendorLookupController controllerObj = new VendorLookupController();
        controllerObj.getFormTag();
        controllerObj.getTextBox();
    }
}