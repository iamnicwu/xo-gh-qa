@isTest
public class LeadManualStorefrontFulfillmentCTest {
    public static testMethod void test_method_one() {
        
        
        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtCategoryMapByName = Schema.SObjectType.Category__c.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtLeadMapByName = Schema.SObjectType.Lead.getRecordTypeInfosByName();
        
        Generate_Quote_Pdf_Config__c GQPF = new Generate_Quote_Pdf_Config__c();
        GQPF.name = 'Production';
        GQPF.URL__c = 'www.baidu.com';
        insert GQPF;

        Market__c testMarket = new Market__c();
        testMarket.Name = 'Test Market';
        testMarket.Short_Description__c = 'Test Market';
        testMarket.Market_ID__c = '222';
        testMarket.Active__c = true;
        insert testMarket;
        
        // CSP-1999 
        // Brand__c testBrand = new Brand__c();
        // testBrand.RecordTypeId = Schema.SObjectType.Brand__c.getRecordTypeInfosByName().get('Local').getRecordTypeId();
        // testBrand.Name = 'Test Knot Brand';
        // testBrand.Active__c = true;
        // insert testBrand;
        
        Category__c testCategory = new Category__c();
        testCategory.Active__c = true;
        testCategory.RecordTypeId = rtCategoryMapByName.get('Local').getRecordTypeId();
        testCategory.Name = 'Test Category';
        testCategory.Short_Description__c = 'Test Category';
        //CSP-1999 testCategory.Primary_Brand__c = testBrand.Id;
        testCategory.Category_Group__c = 'Primary';
        testCategory.Taxonomy_ID__c = 'testcategoryId';
        insert testCategory;
        
        MetroArea__c ma = new MetroArea__c();
        ma.name = 'test';
        insert ma;
        
        Zip__c zip = new Zip__c();
        zip.MetroArea__c = ma.id;
        zip.ZipCode__c = '12121';
        Zip.name = '12121';
        Zip.Local_Market__c = testMarket.id;
        insert zip;
        
        Local_Sales_Rep_Assignment__c  lsra = new Local_Sales_Rep_Assignment__c();
        lsra.Name = 'test name';
        lsra.Category__c = testCategory.id;
        lsra.Sales_Rep__c = UserInfo.getUserId();
        lsra.Zip_Code__c = zip.id;
        insert lsra;
        
        Lead testLead = new Lead();
        testLead.FirstName='Test';
        testLead.LastName='Lead';
        testLead.Phone='12345678';
        testLead.Email='test@test.com';
        testLead.Company='Test Company';
        testLead.Local_Sales_Market__c = testMarket.id;
        testLead.Primary_Category__c = testCategory.id;
        //CSP-1999  testLead.Primary_Brand__c = testBrand.id;
        testLead.recordtypeId = rtLeadMapByName.get('Local').getRecordTypeId();
        testLead.PostalCode = zip.ZipCode__c;
        testLead.DynamicsLeadID__c = 'testDynamicsLeadID';
        insert testLead;
        
        Test.startTest();
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"locations": null,"errors": [{"message":"error message"}]}',
                                                 null);
        Test.setMock(HttpCalloutMock.class,fakeResponse );
        test.setCurrentPageReference(Page.LeadManualStorefrontFulfillment);
        ApexPages.StandardController sc = new ApexPages.StandardController(testLead);
        LeadManualStorefrontFulfillmentContr testcase = new LeadManualStorefrontFulfillmentContr(sc); 

        testcase.fulfillStorefront();
        testcase.saveData();
        testcase.recordPageRedirect();
        
        Test.stopTest();
    }
    
    public static testMethod void test_method_two() {
        
        
        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtCategoryMapByName = Schema.SObjectType.Category__c.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtLeadMapByName = Schema.SObjectType.Lead.getRecordTypeInfosByName();
        
        Generate_Quote_Pdf_Config__c GQPF = new Generate_Quote_Pdf_Config__c();
        GQPF.name = 'Production';
        GQPF.URL__c = 'www.baidu.com';
        insert GQPF;
        
        

        Market__c testMarket = new Market__c();
        testMarket.Name = 'Test Market';
        testMarket.Short_Description__c = 'Test Market';
        testMarket.Market_ID__c = '222';
        testMarket.Active__c = true;
        insert testMarket;
        
        
        // Brand__c testBrand = new Brand__c();
        // testBrand.RecordTypeId = Schema.SObjectType.Brand__c.getRecordTypeInfosByName().get('Local').getRecordTypeId();
        // testBrand.Name = 'Test Knot Brand';
        // testBrand.Active__c = true;
        // insert testBrand;
        
        Category__c testCategory = new Category__c();
        testCategory.Active__c = true;
        testCategory.RecordTypeId = rtCategoryMapByName.get('Local').getRecordTypeId();
        testCategory.Name = 'Test Category';
        testCategory.Short_Description__c = 'Test Category';
        //CSP-1999  testCategory.Primary_Brand__c = testBrand.Id;
        testCategory.Category_Group__c = 'Primary';
        testCategory.Taxonomy_ID__c = 'testcategoryId';
        insert testCategory;
        
        MetroArea__c ma = new MetroArea__c();
        ma.name = 'test';
        insert ma;
        
        Zip__c zip = new Zip__c();
        zip.MetroArea__c = ma.id;
        zip.ZipCode__c = '12121';
        Zip.name = '12121';
        Zip.Local_Market__c = testMarket.id;
        insert zip;
        
        Local_Sales_Rep_Assignment__c  lsra = new Local_Sales_Rep_Assignment__c();
        lsra.Name = 'test name';
        lsra.Category__c = testCategory.id;
        lsra.Sales_Rep__c = UserInfo.getUserId();
        lsra.Zip_Code__c = zip.id;
        insert lsra;
        
        Lead testLead = new Lead();
        testLead.FirstName='Test';
        testLead.LastName='Lead';
        testLead.Phone='12345678';
        testLead.Email='test@test.com';
        testLead.Company='Test Company';
        testLead.Local_Sales_Market__c = testMarket.id;
        testLead.Primary_Category__c = testCategory.id;
        //CSP-1999  testLead.Primary_Brand__c = testBrand.id;
        testLead.recordtypeId = rtLeadMapByName.get('Local').getRecordTypeId();
        testLead.PostalCode = zip.ZipCode__c;
        testLead.DynamicsLeadID__c = 'testDynamicsLeadID';
        insert testLead;
        
        Deactivate_Trigger__c dt = new Deactivate_Trigger__c();
        dt.name = 'Note';
        dt.After_Delete__c = false;
        dt.After_Insert__c = false;
        dt.After_Update__c = false;
        dt.Before_Delete__c = false;
        dt.Before_Insert__c = false;
        dt.Before_Update__c = false;
        insert dt;
        
        XO_Group_Settings__c xoSetting = XO_Group_Settings__c.getInstance();
        xoSetting.Turn_on_Fulfillment_Callouts__c = true;
        upsert xoSetting;
        
        Test.startTest();
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"locations": [{"locationId":"locationId", "fulfilledStorefronts":null, "errors": [{"message":"error message"}]}],"errors": null}',
                                                 null);
        Test.setMock(HttpCalloutMock.class,fakeResponse );
        test.setCurrentPageReference(Page.LeadManualStorefrontFulfillment);
        ApexPages.StandardController sc = new ApexPages.StandardController(testLead);
        LeadManualStorefrontFulfillmentContr testcase = new LeadManualStorefrontFulfillmentContr(sc); 
        
        
        testcase.fulfillStorefront();
        
        Test.stopTest();
    }
    
    public static testMethod void test_method_three() {
        
        
        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtCategoryMapByName = Schema.SObjectType.Category__c.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtLeadMapByName = Schema.SObjectType.Lead.getRecordTypeInfosByName();
        
        Generate_Quote_Pdf_Config__c GQPF = new Generate_Quote_Pdf_Config__c();
        GQPF.name = 'Production';
        GQPF.URL__c = 'www.baidu.com';
        insert GQPF;
        
        XO_Group_Settings__c xoSetting = XO_Group_Settings__c.getInstance();
        xoSetting.Turn_on_Fulfillment_Callouts__c = true;
        upsert xoSetting;
        
        
        Market__c testMarket = new Market__c();
        testMarket.Name = 'Test Market';
        testMarket.Short_Description__c = 'Test Market';
        testMarket.Market_ID__c = '222';
        testMarket.Active__c = true;
        insert testMarket;
        
        // CSP-1999 
        // Brand__c testBrand = new Brand__c();
        // testBrand.RecordTypeId = Schema.SObjectType.Brand__c.getRecordTypeInfosByName().get('Local').getRecordTypeId();
        // testBrand.Name = 'Test Knot Brand';
        // testBrand.Active__c = true;
        // insert testBrand;
        
        Category__c testCategory = new Category__c();
        testCategory.Active__c = true;
        testCategory.RecordTypeId = rtCategoryMapByName.get('Local').getRecordTypeId();
        testCategory.Name = 'Test Category';
        testCategory.Short_Description__c = 'Test Category';
        //CSP-1999  testCategory.Primary_Brand__c = testBrand.Id;
        testCategory.Category_Group__c = 'Primary';
        testCategory.Taxonomy_ID__c = 'testcategoryId';
        insert testCategory;
        
        MetroArea__c ma = new MetroArea__c();
        ma.name = 'test';
        insert ma;
        
        Zip__c zip = new Zip__c();
        zip.MetroArea__c = ma.id;
        zip.ZipCode__c = '12121';
        Zip.name = '12121';
        Zip.Local_Market__c = testMarket.id;
        insert zip;
        
        Local_Sales_Rep_Assignment__c  lsra = new Local_Sales_Rep_Assignment__c();
        lsra.Name = 'test name';
        lsra.Category__c = testCategory.id;
        lsra.Sales_Rep__c = UserInfo.getUserId();
        lsra.Zip_Code__c = zip.id;
        insert lsra;
        
        Lead testLead = new Lead();
        testLead.FirstName='Test';
        testLead.LastName='Lead';
        testLead.Phone='12345678';
        testLead.Email='test@test.com';
        testLead.Company='Test Company';
        testLead.Local_Sales_Market__c = testMarket.id;
        testLead.Primary_Category__c = testCategory.id;
        //CSP-1999  testLead.Primary_Brand__c = testBrand.id;
        testLead.recordtypeId = rtLeadMapByName.get('Local').getRecordTypeId();
        testLead.PostalCode = zip.ZipCode__c;
        testLead.DynamicsLeadID__c = 'testDynamicsLeadID';
        insert testLead;
        
        Test.startTest();
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"locations": null,"errors": [{"message":"error message"}]}',
                                                 null);
        Test.setMock(HttpCalloutMock.class,fakeResponse );
        test.setCurrentPageReference(Page.LeadManualStorefrontFulfillment);
        ApexPages.StandardController sc = new ApexPages.StandardController(testLead);
        LeadManualStorefrontFulfillmentContr testcase = new LeadManualStorefrontFulfillmentContr(sc); 

        testcase.fulfillStorefront();
        Test.stopTest();
    }
    
}