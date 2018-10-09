@isTest
private class AutoGeneratePdfTest {
    
    @isTest static void test_method_one() {
        // Implement test code
        
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        // CREATE TEST DATA
        TestClassUtility.createCBSSCustomSettings();
        
        List<User> userList = [select Id, Name, Alias from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtLeadMapByName = Schema.SObjectType.Lead.getRecordTypeInfosByName();
        // CSP-1999 Map<String,Schema.RecordTypeInfo> rtBrandMapByName = Schema.SObjectType.Brand__c.getRecordTypeInfosByName();
        
        Test.startTest();
        if(Deactivate_Trigger__c.getValues('Attachment') == null){
            TestClassUtility.createAttachmentDeactivateTriggerSetting(true);  
        }
        
        Generate_Quote_Pdf_Config__c quotePdfConfig = TestClassUtility.generateQuotePdfConfig(false);
        quotePdfConfig.URL__c = 'www.baidu.com';
        insert quotePdfConfig;
        // CSP-1999 
        // Brand__c testBrand = TestClassUtility.createBrand(false);
        // testBrand.RecordTypeId = rtBrandMapByName.get('Local').getRecordTypeId();
        // insert testBrand;    
        // Region__c testRegion = TestClassUtility.createRegion(true, testBrand);
        Region__c testRegion = TestClassUtility.createRegion(true);
        Market__c testMarket = TestClassUtility.createMarket(false);
        testMarket.Market_ID__c = '222';
        testMarket.Active__c = true;
        testMarket.Local_Sales_Region__c = testRegion.id;
        insert testMarket;
        // CSP-1999 
        // Category__c testCategory = TestClassUtility.createCategory(true, testBrand);
        Category__c testCategory = TestClassUtility.createCategory(true);
        
        MetroArea__c ma = TestClassUtility.createMetroArea(true);
        
        Zip__c zip = TestClassUtility.createZip(false);
        zip.MetroArea__c = ma.id;
        zip.ZipCode__c = '99999';
        zip.name = '12121';
        zip.Local_Market__c = testMarket.id;
        insert zip;
        // CSP-1999 
        // Account account = TestClassUtility.createAccount(false, testBrand, testCategory, testMarket);
        Account account = TestClassUtility.createAccount(false, testCategory, testMarket);
        account.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
        account.Record_Type_Name__c = 'Local';
        account.BU__c = 'Local';
        account.Type = 'Agency';
        account.Operative_Owner__c = userList[0].Name;
        account.Fulfillment_Data__c = '{ "tier" : "Freemium", "reviewId" : "review Id", "parentGUID" : "37e0c6b9-6f4f-4dd4-a3f4-9707e9dc4bbc", "marketCode" : "228", "categoryId" : "8aa9a07b-fcd8-46ed-a98f-8f3e12689dd2" }';
        account.BillingPostalCode =zip.zipCode__c;
        insert account;
        
        Opportunity testOpportunity = TestClassUtility.createOpportunity(false, account);    
        testOpportunity.RecordTypeId = rtOppMapByName.get('Local').getRecordTypeId();
        testOpportunity.Opportunity_Expiration_Date__c = null;
        testOpportunity.CloseDate = Date.Today()-10;
        insert testOpportunity;

        Attachment att = new Attachment();
        att.Name = 'test file';
        att.Body = Blob.valueOf('abc');
        att.ContentType = 'txt';
        att.ParentId = testOpportunity.id;
        insert att;
        
        Contact contact = TestClassUtility.createContact(true,account);
        
        zqu__Quote__c testQuote = TestClassUtility.createQuote(true, testOpportunity, account, contact);
        
        // BEGIN TEST
        Map<Id, Id> quoOppIds = new Map<Id, Id>();
        quoOppIds.put(testQuote.Id, testOpportunity.Id);
        String tempId = '';
        String serverUrl = '';
        String sessionId = '';
        String endPoint = '';
        
        AutoGenerateQuotePdf.generatePdf(quoOppIds, tempId, serverUrl, sessionId, endPoint);

        System.enqueueJob(new AutoGenerateQuotePdf.QueueableOne(quoOppIds, tempId, serverUrl, sessionId, endPoint));
        Test.stopTest();
        
    }
}