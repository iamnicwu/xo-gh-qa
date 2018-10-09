/**
 *@description: test class for InvoiceTrigger and InvoiceTriggerHandler
 */
@isTest
private class InvoiceTriggerHandlerTest{   
    private static List<User> userList;
    private static Map<String,Schema.RecordTypeInfo> rtMapByName;
    private static Map<String,Schema.RecordTypeInfo> rtLeadMapByName;
    // CSP-1999 private static Map<String,Schema.RecordTypeInfo> rtBrandMapByName;
    private static Deactivate_Trigger__c dtatt;
    private static Generate_Quote_Pdf_Config__c GQPF;
    // CSP-1999 private static Brand__c testBrand;
    private static Region__c testRegion;
    private static Market__c testMarket;
    private static Category__c testCategory;
    private static MetroArea__c ma;
    private static Zip__c zip;
    static testMethod void myUnitTest() {
        createtestData();
        TriggerHandlerAccess__c newTHA = TestClassUtility.createTriggerHandlerAccessSetting(true, 'Zuora__ZInvoice__c', 'InvoiceTriggerHandler');
        // CSP-1999 
        // Account testAccount = TestClassUtility.createAccount(false, testBrand, testCategory, testMarket);
        Account testAccount = TestClassUtility.createAccount(false, testCategory, testMarket);
        testAccount.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
        testAccount.Record_Type_Name__c = 'Local';
        testAccount.BU__c = 'Local';
        testAccount.Type = 'Agency';
        testAccount.Operative_Owner__c = userList[0].Name;
        testAccount.Fulfillment_Data__c = '{ "tier" : "Freemium", "reviewId" : "review Id", "parentGUID" : "37e0c6b9-6f4f-4dd4-a3f4-9707e9dc4bbc", "marketCode" : "228", "categoryId" : "8aa9a07b-fcd8-46ed-a98f-8f3e12689dd2" }';
        testAccount.ShippingPostalCode = zip.zipCode__c+'1';
	    testAccount.BillingPostalCode = zip.zipCode__c;    
        insert testAccount;
        
        Zuora__ZInvoice__c invObj = TestClassUtility.createInvoice(false);
        invObj.Zuora__Account__c = testAccount.id;
        invObj.Promise_to_Pay_Date__c = Date.Today()+1;
        invObj.Promise_To_Pay_Amount__c = 50;
        invObj.Zuora__Balance2__c = 50;
        insert invObj;
        
        invObj.Promise_to_Pay_Date__c = date.Today()+2;
        update invObj;
    }
    
    static testMethod void invoiceUpdateTest() {
        createtestData();
        TriggerHandlerAccess__c newTHA = TestClassUtility.createTriggerHandlerAccessSetting(true, 'Zuora__ZInvoice__c', 'InvoiceTriggerHandler');
        // CSP-1999 
        // Account testAccount = TestClassUtility.createAccount(false, testBrand, testCategory, testMarket);
        Account testAccount = TestClassUtility.createAccount(false, testCategory, testMarket);
        testAccount.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
        testAccount.Record_Type_Name__c = 'Local';
        testAccount.BU__c = 'Local';
        testAccount.Type = 'Agency';
        testAccount.Operative_Owner__c = userList[0].Name;
        testAccount.Fulfillment_Data__c = '{ "tier" : "Freemium", "reviewId" : "review Id", "parentGUID" : "37e0c6b9-6f4f-4dd4-a3f4-9707e9dc4bbc", "marketCode" : "228", "categoryId" : "8aa9a07b-fcd8-46ed-a98f-8f3e12689dd2" }';
        testAccount.ShippingPostalCode = zip.zipCode__c+'1';
	    testAccount.BillingPostalCode = zip.zipCode__c;    
        insert testAccount;
        
        Zuora__ZInvoice__c invObj = TestClassUtility.createInvoice(false);
        invObj.Zuora__Account__c = testAccount.id;
        invObj.Promise_to_Pay_Date__c = Date.Today()+1;
        invObj.Promise_To_Pay_Amount__c = 50;
        invObj.Zuora__Balance2__c = 50;
        insert invObj;
        
        invObj.Promise_to_Pay_Date__c = null;
        invObj.Promise_To_Pay_Amount__c = null;
        invObj.Zuora__Balance2__c = 0;
        update invObj;
    }
    private static void createtestData(){
    	userList = [select Id, Name, Alias, SalesRepID__c, Manager.SalesRepID__c from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        rtLeadMapByName = Schema.SObjectType.Lead.getRecordTypeInfosByName();
        // CSP-1999 rtBrandMapByName = Schema.SObjectType.Brand__c.getRecordTypeInfosByName();
        
        if(Deactivate_Trigger__c.getValues('Attachment') == null){
            dtatt = TestClassUtility.createAttachmentDeactivateTriggerSetting(true);
              
        }
        //createCBSSSetting = TestClassUtility.createCBSSSetting(true);

        TestClassUtility.createCBSSCustomSettings();
        
        GQPF = TestClassUtility.generateQuotePdfConfig(false);
        GQPF.URL__c = 'www.baidu.com';
        insert GQPF;
        // CSP-1999 
        // testBrand = TestClassUtility.createBrand(false);
        // testBrand.RecordTypeId = rtBrandMapByName.get('Local').getRecordTypeId();
        // insert testBrand;
        // testRegion = TestClassUtility.createRegion(true, testBrand);
        testRegion = TestClassUtility.createRegion(true);
        
        testMarket = TestClassUtility.createMarket(false);
        testMarket.Market_ID__c = '222';
        testMarket.Active__c = true;
        testMarket.Local_Sales_Region__c = testRegion.id;
        insert testMarket;
        // CSP-1999 
        // testCategory = TestClassUtility.createCategory(true, testBrand);
        testCategory = TestClassUtility.createCategory(true);
        
        ma = TestClassUtility.createMetroArea(true);
        
        zip = TestClassUtility.createZip(false);
        zip.MetroArea__c = ma.id;
        zip.ZipCode__c = '99999';
        zip.name = '12121';
        zip.Local_Market__c = testMarket.id;
        insert zip;	
    
    }
}