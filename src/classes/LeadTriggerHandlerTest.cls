@isTest
private class LeadTriggerHandlerTest {
    
    static testMethod void testLeadAssignment() {    
        // Implement test code
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Lead.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtCategoryMapByName = Schema.SObjectType.Category__c.getRecordTypeInfosByName();

        Lead_and_Account_Scoring__c scoring = new Lead_and_Account_Scoring__c();
        scoring.Name ='test';
        scoring.Apply_to_Lead_Score__c = true;
        scoring.Comparison_Type__c = 'Equals';
        scoring.Comparison_Value__c = 'no@email.com';
        scoring.Field_API_Name__c = 'Email';
        scoring.Points__c = 10;
        insert scoring;
        
        MetroArea__c ma = TestClassUtility.createMetroArea(true);
        
        List<Zip__c> zipList = new List<Zip__c>();

        Zip__c zip = TestClassUtility.createZip(false);
        zip.MetroArea__c = ma.id;
        zip.ZipCode__c = '12121';
        Zip.name = '12121';
        zipList.add(zip);
        
        Zip__c zip1 = TestClassUtility.createZip(false);
        zip1.MetroArea__c = ma.id;
        zip1.ZipCode__c = '12123';
        Zip1.name = '12123';
        zipList.add(zip1);

        insert zipList;
                
        Market__c testMarket = TestClassUtility.createMarket(false);
        testMarket.Market_ID__c = '222'; //Shashish: Market Id 222 is hardcoded in LeadLocalTriggerhandler
        testMarket.Active__c = true;
        //testMarket.Country__c = 'CA';
        insert testMarket;

        Category__c testCategory = TestClassUtility.createCategory(false);
        testCategory.RecordTypeId = rtCategoryMapByName.get('Local').getRecordTypeId();
        testCategory.Category_Group__c = 'Primary';
        testCategory.Active__c = true;
        testCategory.Name = 'Reception Venues - REC';

        insert testCategory;
            
        Test.startTest();
        
        List<Local_Sales_Rep_Assignment__c> localSalesRepAssignmentList = new List<Local_Sales_Rep_Assignment__c>();
        
        Local_Sales_Rep_Assignment__c lsra = TestClassUtility.createLocalSalesRepAssignment(false, testCategory, testMarket, null);
        Local_Sales_Rep_Assignment__c lsra1 = TestClassUtility.createLocalSalesRepAssignment(false, testCategory, null, zipList[0]);
        Local_Sales_Rep_Assignment__c lsra2 = TestClassUtility.createLocalSalesRepAssignment(false, testCategory, testMarket, null);
        Local_Sales_Rep_Assignment__c lsra3 = TestClassUtility.createLocalSalesRepAssignment(false, null, testMarket, null);
        Local_Sales_Rep_Assignment__c lsra4 = TestClassUtility.createLocalSalesRepAssignment(false, null, null, zipList[1]);
        Local_Sales_Rep_Assignment__c lsra5 = TestClassUtility.createLocalSalesRepAssignment(false, testCategory, null, null);

        localSalesRepAssignmentList.add(lsra);
        localSalesRepAssignmentList.add(lsra1);
        lsra2.Sales_Rep__c = null;
        lsra2.Lead_Distribution_Queue_Id__c = UserInfo.getUserId();
        localSalesRepAssignmentList.add(lsra2);
        localSalesRepAssignmentList.add(lsra3);

        lsra4.Sales_Rep__c = null;
        lsra4.Lead_Distribution_Queue_Id__c = UserInfo.getUserId();
        localSalesRepAssignmentList.add(lsra4);
        lsra5.Sales_Rep__c = null;
        lsra5.Lead_Distribution_Queue_Id__c = UserInfo.getUserId();
        localSalesRepAssignmentList.add(lsra5);
        insert localSalesRepAssignmentList;

        list<Lead> leadList = New list<Lead>();
        Lead testLead = TestClassUtility.createLead(false, testMarket, testCategory);
        testLead.recordtypeId = rtMapByName.get('Local').getRecordTypeId();
        testLead.PostalCode = '90034';
        testLead.LeadSource = 'Inbound Phone';
        testLead.State = 'California';
        testLead.City = 'los angeles';
        testLead.Street = 'ssdfgsf';
        testLead.Country = 'United States';
        testLead.Status = 'New';
        testLead.Email = 'abc@xyz.com';
        testLead.Website = 'sdfsd.com';
        testLead.Phone = '1234567890';
        testLead.Company = 'sfsdf';
        testLead.FirstName = 'Inbound';
        testLead.LastName = 'Phone';
        testLead.Primary_Category__c = testCategory.Id;
        testLead.Local_Sales_Market__c = testMarket.Id;
        leadList.add(testlead);

        Lead testLead2 = TestClassUtility.createLead(false, testMarket, testCategory);
        testLead2.recordtypeId = rtMapByName.get('Local').getRecordTypeId();
        testLead2.PostalCode = '90034';
        testLead2.LeadSource = 'Inbound Phone';
        testLead2.State = 'California';
        testLead2.City = 'los angeles1';
        testLead2.Street = 'ssdfgsf1';
        testLead2.Country = 'United States';
        testLead2.Status = 'New';
        testLead2.Email = 'abc@xyz1.com';
        testLead2.Website = 'sdfsd1.com';
        testLead2.Phone = '1234567891';
        testLead2.Company = 'sfsdf1';
        testLead2.FirstName = 'Inbound1';
        testLead2.LastName = 'Phone1';
        testLead2.Primary_Category__c = testCategory.Id;
        testLead2.Local_Sales_Market__c = testMarket.Id;
        testLead2.Local_Partners_Claiming__c = false;
        leadList.add(testlead2);

        insert leadList;

        System.assert(testLead.OwnerId != userinfo.getUserId());
        System.assert(testLead2.OwnerId != userinfo.getUserId());

        testLead2.Email = 'abc@xyz2.com';
        update testLead2;

        delete testLead;

        Test.stopTest();
    }
    
    @isTest static void testUpdateZipCode() {
        // Implement test code 
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Map<String,Schema.RecordTypeInfo> rtLeadMapByName = Schema.SObjectType.Lead.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtCategoryMapByName = Schema.SObjectType.Category__c.getRecordTypeInfosByName();
        
        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        
        CountryZipREGEX__c czr = TestClassUtility.createContryZipREGEX(true, 'United States', 'US');         
        
        Generate_Quote_Pdf_Config__c GQPF = TestClassUtility.generateQuotePdfConfig(false);
        GQPF.URL__c = 'www.baidu.com';
        insert GQPF;

        Region__c testRegion = TestClassUtility.createRegion(true);

                
        Market__c testMarket = TestClassUtility.createMarket(false);
        testMarket.Active__c = true;
        testMarket.Local_Sales_Region__c = testRegion.id;
        insert testMarket;

        Market__c testMarket2 = New Market__c();
        testMarket2.Name = 'TX - Austin - 123';
        testMarket2.Short_Description__c = 'TX-Austin';
        testMarket2.Market_Id__c = '123';
        testMarket2.Active__c = true;
        testMarket2.Local_Sales_Region__c = testRegion.id;
        insert testMarket2;

        Category__c testCategory = TestClassUtility.createCategory(true);
        
        MetroArea__c ma = TestClassUtility.createMetroArea(true);
        
        Zip__c testZip = TestClassUtility.createZip(false);
        testZip.MetroArea__c = ma.id;
        testZip.ZipCode__c = '94230';
        testZip.name = '94230';
        testZip.Local_Market__c = testMarket.id;
        testZip.Portfolio__c = 'Senior Sales Executive';
        testZip.City__c = 'AUSTIN';
        testZip.State__c = 'Texas';
        insert testZip;

        Zip__c testZip2 = TestClassUtility.createZip(false);
        testZip2.MetroArea__c = ma.id;
        testZip2.ZipCode__c = '12580';
        testZip2.name = '12580';
        testZip2.Local_Market__c = testMarket2.id;
        testZip2.Portfolio__c = 'Senior Sales Executive';
        testZip2.City__c = 'AUSTIN';
        testZip2.State__c = 'Texas';
        insert testZip2;

        Account testAccount = TestClassUtility.createAccount(false, testCategory, testMarket);
        testAccount.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
        testAccount.BU__c = 'Local';
        testAccount.Type = 'Agency';
        testAccount.Operative_Owner__c = userList[0].Name;
        testAccount.Fulfillment_Data__c = '{ "tier" : "Freemium", "reviewId" : "review Id", "parentGUID" : "37e0c6b9-6f4f-4dd4-a3f4-9707e9dc4bbc", "marketCode" : "228", "categoryId" : "8aa9a07b-fcd8-46ed-a98f-8f3e12689dd2" }';  

        testAccount.ShippingCountry = 'United States';
        testAccount.ShippingState  = 'Alaska';
        testAccount.ShippingCity = 'US2';
        testAccount.ShippingStreet = 'US3';
        testAccount.ShippingPostalCode  = '99501';
        // testAccount.ShippingStateCode  = 'TX';
        testAccount.BillingCountry = 'United States';
        testAccount.BillingState  = 'Alaska';
        testAccount.BillingCity = 'US2';
        testAccount.BillingStreet = 'US3';
        testAccount.BillingPostalCode = '99501';
        // testAccount.BillingStateCode  = 'TX';
        testAccount.BillingCountryCode = 'US';
        // testAccount.ShippingPostalCode = 'US';

        insert testAccount;
        
        Contact testContact = TestClassUtility.createContact(true, testAccount);
                
        Campaign testCampaign = new Campaign();
        testCampaign.IsActive = true;
        testCampaign.Type = 'Bridal Show';
        testCampaign.Name = 'XO Group Internal - Hubspot_Paid Advertising-A';
        insert testCampaign;

        Lead testLead = TestClassUtility.createLead(false, testMarket, testCategory);
        testLead.recordtypeId = rtLeadMapByName.get('Local').getRecordTypeId();
        testLead.DynamicsLeadID__c = 'testDynamicsLeadID';
        testLead.Salesforce_Generated_GUID__c = true;
        testLead.Status = 'Qualified';
        testLead.Storefront_Status__c = 'Unclaimed';
        testLead.Country = 'United States';
        testLead.State  = 'Alaska';
        testLead.StateCode = 'AK';
        testLead.City = 'US2';
        testLead.Street = 'US3';
        testLead.Phone= '1234567895';
        testLead.Email='abc@abc.com';
        testLead.Website = 'www.abc.com';
        testLead.PostalCode = testZip.ZipCode__c;
        testLead.CountryCode = 'US';
        testLead.Salesforce_Generated_GUID__c = true;
        insert testLead;

        Test.startTest();

        testLead.LocalSalesMarket__c= 'AK - Alaska';
        testLead.Status = 'Qualified';
        testLead.Storefront_Status__c = 'Claimed';
        testLead.DynamicsLeadID__c = 'changeTestDynamicsLeadID';
        testLead.PostalCode = testZip2.ZipCode__c;
        testLead.Phone_Extension__c = '1234567';
        testLead.Website = 'www.123.com';
        update testLead;

        testLead.DynamicsLeadID__c = '';
        testLead.Fulfill_Storefront__c = false;
        testLead.PostalCode = '';
        update testLead;

        system.assert(testLead.PostalCode == '');
        system.assert(testLead.Zip__c == null);

        Test.stopTest();
        
    }
    
    @isTest static void testLeadConvert(){

        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Map<String,Schema.RecordTypeInfo> rtLeadMapByName = Schema.SObjectType.Lead.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtCategoryMapByName = Schema.SObjectType.Category__c.getRecordTypeInfosByName();
        
        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();

        Region__c testRegion = TestClassUtility.createRegion(true);        

        Market__c testMarket = TestClassUtility.createMarket(false);
        testMarket.Market_ID__c = '222';
        testMarket.Active__c = true;
        testMarket.Local_Sales_Region__c = testRegion.id;
        insert testMarket;

        Category__c testCategory = TestClassUtility.createCategory(true);
        
        MetroArea__c ma = TestClassUtility.createMetroArea(true);
        
        Zip__c zip = TestClassUtility.createZip(false);
        zip.MetroArea__c = ma.id;
        zip.ZipCode__c = '12121';
        Zip.name = '12121';
        Zip.Local_Market__c = testMarket.id;
        insert zip;

        Account testAccount = TestClassUtility.createAccount(false, testCategory, testMarket);
        testAccount.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
        testAccount.BU__c = 'Local';
        testAccount.Type = 'Agency';
        testAccount.Operative_Owner__c = userList[0].Name;
        testAccount.Fulfillment_Data__c = '{ "tier" : "Freemium", "reviewId" : "review Id", "parentGUID" : "37e0c6b9-6f4f-4dd4-a3f4-9707e9dc4bbc", "marketCode" : "228", "categoryId" : "8aa9a07b-fcd8-46ed-a98f-8f3e12689dd2" }';   
        insert testAccount;
        
        Contact testContact = TestClassUtility.createContact(true, testAccount);
            
        Test.startTest();
       
        Lead testLead = TestClassUtility.createLead(false, testMarket, testCategory);
        testLead.recordtypeId = rtLeadMapByName.get('Local').getRecordTypeId();
        testLead.DynamicsLeadID__c = 'testDynamicsLeadID';
        testLead.Status = 'Valid';
        testLead.Salesforce_Generated_GUID__c = true;
        testLead.IsConverted = false;
        testLead.Storefront_Status__c = 'Claimed';
        testLead.LeadSource  = 'Internal Referral';
        testLead.PostalCode = '12121';
        testLead.Primary_Category__c = testCategory.Id;
        testLead.Local_Sales_Market__c = testMarket.Id;
        testLead.CountryCode = 'US';
        testLead.Country = 'United States';
        testLead.State  = 'Alaska';
        testLead.City = 'US2';
        testLead.Street = 'US3';
        testLead.Phone = '1234537895';
        testLead.Website  = 'ttt222.com';
        insert testLead;

        Generate_Quote_Pdf_Config__c GQPF = TestClassUtility.generateQuotePdfConfig(false);
        GQPF.URL__c = 'www.baidu.com';
        insert GQPF;

        FeedItem testFeed = New FeedItem();
        testFeed.ParentId = testlead.id;
        testFeed.Title = 'test title';
        testFeed.Body = 'Hello';
        testFeed.LinkUrl = 'www.abc123.com';
        insert testFeed;
        
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(testLead.id);
        lc.setDoNotCreateOpportunity(false);
        lc.setConvertedStatus('Qualified');
        lc.setOwnerId(UserInfo.getUserId());
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess());

        Endorsement__c testEndorsementObj = new Endorsement__c();
        testEndorsementObj.Name = 'TestEndorsement';
        testEndorsementObj.Account__c = lcr.getAccountId();
        testEndorsementObj.Type__c = 'Internet Endorsement';
        testEndorsementObj.Lead__c = testLead.Id;
        insert testEndorsementObj;

        Test.stopTest();
    }
    
    @isTest static void testUpdateLead() {
        // Implement test code
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Map<String,Schema.RecordTypeInfo> rtLeadMapByName = Schema.SObjectType.Lead.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtCategoryMapByName = Schema.SObjectType.Category__c.getRecordTypeInfosByName();
        
        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        
        if(CountryZipREGEX__c.getValues('United States') == null){
            CountryZipREGEX__c czr = TestClassUtility.createContryZipREGEX(true, 'United States', 'US');
        }
        
        XO_Group_Settings__c xoSetting = XO_Group_Settings__c.getInstance();
        xoSetting.Turn_on_Fulfillment_Callouts__c = true;
        upsert xoSetting;
        
        Generate_Quote_Pdf_Config__c GQPF = TestClassUtility.generateQuotePdfConfig(false);
        GQPF.URL__c = 'www.baidu.com';
        insert GQPF;

        Region__c testRegion = TestClassUtility.createRegion(true);       
        Market__c testMarket = TestClassUtility.createMarket(false);
        testMarket.Market_ID__c = '222';
        testMarket.Active__c = true;
        testMarket.Local_Sales_Region__c = testRegion.id;
        insert testMarket;
        
        Category__c testCategory = TestClassUtility.createCategory(false);
        testCategory.Name = 'Bridal Salons - BWP';
        insert testCategory;
        MetroArea__c ma = TestClassUtility.createMetroArea(true);
        
        List<Zip__c> zipList = new List<Zip__c>();
        List<Lead> LeadList = new List<Lead>();
        
        Zip__c zip = TestClassUtility.createZip(false);
        zip.MetroArea__c = ma.id;
        zip.ZipCode__c = '12121';
        Zip.name = '12121';
        Zip.Local_Market__c = testMarket.id;
        zipList.add(zip);
        
        Zip__c zip1 = TestClassUtility.createZip(false);
        zip1.MetroArea__c = ma.id;
        zip1.ZipCode__c = '12122';
        Zip1.name = '12122';
        Zip1.Local_Market__c = testMarket.id;
        zipList.add(zip1);

        Zip__c zip2 = TestClassUtility.createzip(false);
        zip2.MetroArea__c = ma.id;
        zip2.ZipCode__c = '12123';
        Zip2.name = '12123';
        Zip2.Local_Market__c = testMarket.id;
        zip2.Portfolio__c = 'Senior Sales Executive';
        zipList.add(zip2);
        
        insert zipList;
        
        Campaign testCampaign = new Campaign();
        testCampaign.IsActive = true;
        testCampaign.Type = 'Bridal Show';
        testCampaign.Name = 'XO Group Internal - Hubspot_Paid Advertising-A';
        insert testCampaign;

        Lead testLead = TestClassUtility.createLead(false, testMarket, testCategory);
        testLead.recordtypeId = rtLeadMapByName.get('Local').getRecordTypeId();
        testLead.DynamicsLeadID__c = 'testDynamicsLeadID';
        testLead.Salesforce_Generated_GUID__c = true;
        testLead.IsConverted = false;
        testLead.Status = 'Qualified';
        testLead.Storefront_Status__c = 'Unclaimed';
        testLead.PostalCode = '12121';
        testLead.Country = null;
        testLead.CountryCode = 'US';
        testLead.State  = null;
        testLead.City = null;
        testLead.Street = null;
        testLead.Website  = 'ttt.com';
        insert testLead;


        Category__c masonCategory = TestClassUtility.createCategory(false);
        masonCategory.Category_Code__c = 'ACC';
        masonCategory.RecordTypeId = rtCategoryMapByName.get('Local').getRecordTypeId();
        masonCategory.Category_Group__c = 'Primary';
        masonCategory.Active__c = true;
        masonCategory.Name = 'Reception Venues - REC';
        insert masonCategory;

        Test.startTest();

        Lead testlead2 = TestClassUtility.createLead(false);
        testlead2.Country = 'United States';
        testlead2.CountryCode = 'US';
        testlead2.PostalCode = '12345';
        testlead2.Primary_Category__c = masonCategory.id;
        testlead2.LeadSource = 'Inbound Phone';
        testlead2.State = 'California';
        testlead2.City = 'los angeles';
        testlead2.Street = 'ssdfgsf';
        testlead2.Status = 'New';
        testlead2.Email = 'abc@xyz.com';
        testlead2.Website = 'sdfsd.com';
        testlead2.Phone = '1234567890';
        testlead2.Company = 'sfsdf';
        testlead2.FirstName = 'Inbound';
        testlead2.LastName = 'Phone';
        testlead2.Local_Sales_Market__c = testMarket.Id;
        testlead2.Invalid_Reason__c = 'No contact information';
        testlead2.Negative_Disposition_Reason__c = 'No contact information';
        testlead2.Related_to_Paid_Media__c = false;
        insert testLead2;
        
        testlead2.PostalCode = zip1.ZipCode__c;
        update testlead2;

        testlead2.Local_Sales_Market__c = null;
        testlead2.PostalCode = '90034';
        update testlead2;

        testlead2.Status = 'New';
        testlead2.LeadSource = 'Other';
        update testlead2;

        testlead2.Status = 'Invalid';
        testlead2.Negative_Disposition_Reason__c = 'Out of Business';
        update testlead2;

        testlead2.Status = 'New';
        update testlead2;

        testlead2.Status = 'Qualified';
        testlead2.Local_Sales_Market__c = testMarket.Id;
        testlead2.Local_Partners_Claiming__c = true;
        testlead2.Storefront_Status__c = 'Claimed';
        update testlead2; 

        testlead2.Related_to_Paid_Media__c = true;
        update testlead2; 

        testlead2.Status = 'Disqualified';
        testlead2.Negative_Disposition_Reason__c = 'Do Not Contact';
        testlead2.Reason_Details__c = 'test reason tedails';
        testlead2.Related_to_Paid_Media__c = false;
        update testlead2; 

        System.assert(testlead2.OwnerId != userinfo.getUserId());

        testlead2.Negative_Disposition_Reason__c = 'Bad Contact';
        update testlead2; 

        testlead2.Status  = 'Valid';
        testlead2.Negative_Disposition_Reason__c = null;
        testLead2.Reason_Details__c = null;
        testLead2.Related_to_Paid_Media__c = true;
        update testlead2;

        testlead2.Status  = 'Invalid';
        testlead2.Negative_Disposition_Reason__c = 'Duplicate';
        testlead2.PreviousOwner__c = UserInfo.getUserId();
        update testlead2;

        System.assert(testlead2.OwnerId != userinfo.getUserId());

        Test.stopTest();
    }

    @isTest static void testDeleteLead(){

        Map<String,Schema.RecordTypeInfo> rtLeadMapByName = Schema.SObjectType.Lead.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtCategoryMapByName = Schema.SObjectType.Category__c.getRecordTypeInfosByName();

        Category__c testCategory = TestClassUtility.createCategory(false);
        testCategory.Category_Code__c = 'ACC';
        testCategory.RecordTypeId = rtCategoryMapByName.get('Local').getRecordTypeId();
        testCategory.Category_Group__c = 'Primary';
        testCategory.Active__c = true;
        testCategory.Name = 'Reception Venues - REC';
        insert testCategory;

        Region__c testRegion = TestClassUtility.createRegion(true); 
        Market__c testMarket = TestClassUtility.createMarket(false);
        testMarket.Active__c = true;
        testMarket.Local_Sales_Region__c = testRegion.id;
        insert testMarket;

        Lead testLead = TestClassUtility.createLead(false, testMarket, testCategory);
        testLead.Country = 'Canada';
        testLead.State = 'Alberta';
        testLead.Phone_Extension__c = '1234567';
        testLead.Invalid_Reason__c = 'No Contact Information';
        testLead.Status = 'New';
        testLead.City = 'los angeles';
        testLead.Street = 'ssdfgsf';
        testLead.RecordTypeId = rtLeadMapByName.get('Local').getRecordTypeId();
        testLead.Website  = 'ttt.com';
        insert testLead; 


        Test.startTest();

        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        Lead testLead2 = TestClassUtility.createLead(false, testMarket, testCategory);
        testLead2.recordtypeId = rtLeadMapByName.get('Local').getRecordTypeId();
        testLead2.DynamicsLeadID__c = '';
        testLead2.Salesforce_Generated_GUID__c = true;
        testLead2.IsConverted = false;
        testLead2.Status = 'Qualified';
        testLead2.Storefront_Status__c = 'Unclaimed';
        testLead2.PostalCode = '12321';
        testLead2.Country = null;
        testLead2.CountryCode = 'US';
        testLead2.State  = null;
        testLead2.City = null;
        testLead2.Street = null;
        testlead2.Local_Partners_Claiming__c = true;
        testlead2.Potential_Duplicates__c = 'test Potential Duplicates';
        testLead2.Website  = 'ttt.com';
        insert testLead2;

        Lead testlead3 = TestClassUtility.createLead(false, testMarket, testCategory);
        testLead3.Status = 'Qualified';  
        testLead3.PostalCode = '12322'; 
        testlead3.Negative_Disposition_Reason__c = 'Duplicate';
        testLead3.Website  = 'ttt.com';
        insert testLead3;

        Test.stopTest();  

        LeadTriggerHandler lth = new LeadTriggerHandler();
        lth.afterDelete(testlead3);
        lth.andFinally();
    }

    @isTest static void testAssigmentByCreateRole() {
        // Implement test code
                
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Map<String,Schema.RecordTypeInfo> rtLeadMapByName = Schema.SObjectType.Lead.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtCategoryMapByName = Schema.SObjectType.Category__c.getRecordTypeInfosByName();
        
        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        
        if(CountryZipREGEX__c.getValues('United States') == null){
            CountryZipREGEX__c czr = TestClassUtility.createContryZipREGEX(true, 'United States', 'US');         
        }
        
        Generate_Quote_Pdf_Config__c GQPF = TestClassUtility.generateQuotePdfConfig(false);
        GQPF.URL__c = 'www.baidu.com';
        insert GQPF;

        Region__c testRegion = TestClassUtility.createRegion(true);
                
        Market__c testMarket = TestClassUtility.createMarket(false);
        testMarket.Active__c = true;
        testMarket.Local_Sales_Region__c = testRegion.id;
        insert testMarket;

        Category__c testCategory = TestClassUtility.createCategory(false);
        testCategory.Category_Group__c = 'Secondary';
        insert testCategory;


        MetroArea__c ma = TestClassUtility.createMetroArea(true);
        
        Zip__c testzip = TestClassUtility.createZip(false);
        testzip.MetroArea__c = ma.id;
        testzip.ZipCode__c = '94230';
        testzip.name = '94230';
        testzip.Local_Market__c = testMarket.id;
        testzip.Portfolio__c = 'Senior Sales Executive';
        insert testzip;

        Account testAccount = TestClassUtility.createAccount(false, testCategory, testMarket);
        testAccount.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
        testAccount.BU__c = 'Local';
        testAccount.Type = 'Agency';
        testAccount.Operative_Owner__c = userList[0].Name;
        testAccount.Fulfillment_Data__c = '{ "tier" : "Freemium", "reviewId" : "review Id", "parentGUID" : "37e0c6b9-6f4f-4dd4-a3f4-9707e9dc4bbc", "marketCode" : "228", "categoryId" : "8aa9a07b-fcd8-46ed-a98f-8f3e12689dd2" }';  
        testAccount.ShippingCountry = 'United States';
        testAccount.ShippingState  = 'California';
        testAccount.ShippingCity = 'Sacramento';
        testAccount.ShippingStreet = 'US3';
        testAccount.ShippingPostalCode  = testZip.ZipCode__c;
        testAccount.ShippingStateCode  = 'CA';
        testAccount.BillingCountry = 'United States';
        testAccount.BillingState  = 'California';
        testAccount.BillingCity = 'Sacramento';
        testAccount.BillingStreet = 'US3';
        testAccount.BillingPostalCode = testZip.ZipCode__c;
        testAccount.BillingStateCode  = 'CA';
        testAccount.BillingCountryCode = 'US';
        // testAccount.ShippingPostalCode = 'US';
        insert testAccount;
        
        Contact testContact = TestClassUtility.createContact(true, testAccount);
                
        Campaign testCampaign = new Campaign();
        testCampaign.IsActive = true;
        testCampaign.Type = 'Bridal Show';
        testCampaign.Name = 'XO Group Internal - Hubspot_Paid Advertising-A';
        insert testCampaign;
 
        Test.startTest();

        TriggerHandlerAccess__c tha = TestClassUtility.createTriggerHandlerAccessSetting(true, 'Lead', 'LeadTriggerHandler');

        User u = [SELECT id FROM user WHERE UserRole.Name LIKE '%Sales Representative%' and isActive = true Limit 1];
        System.runAs(u){
            Lead testLead = TestClassUtility.createLead(false, testMarket, testCategory);
            testLead.recordtypeId = rtLeadMapByName.get('Local').getRecordTypeId();
            testLead.Status = 'New';
            testLead.LeadSource = 'Self Prospecting';
            testLead.Website  = 'ttt2.com';
            // testLead.OwnerId = groupMenberIDList[0];
            insert testLead;
            system.assert(testLead.Status == 'New');
        }

        testCategory.Category_Group__c = 'Primary';
        update testCategory;
        User u2 = [SELECT id FROM user WHERE UserRole.Name LIKE '%Sales Representative%' and isActive = true Limit 1];
        System.runAs(u2){
            Lead testLead2 = TestClassUtility.createLead(false, testMarket, testCategory);
            testLead2.recordtypeId = rtLeadMapByName.get('Local').getRecordTypeId();
            testLead2.Status = 'New';
            testLead2.LeadSource = 'Self Prospecting';

            testLead2.PostalCode = '12123';

            testLead2.City = 'test City';
            testLead2.State = 'Texas';
            testLead2.Phone = '1234569999';
            testLead2.Website  = 'ttt3.com';
            insert testLead2;
        }
       Test.stopTest();

    }

    @isTest static void testInsertNotHotLead() {
        // Implement test code
                
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Map<String,Schema.RecordTypeInfo> rtLeadMapByName = Schema.SObjectType.Lead.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtCategoryMapByName = Schema.SObjectType.Category__c.getRecordTypeInfosByName();
        
        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        
        if(CountryZipREGEX__c.getValues('United States') == null){
            CountryZipREGEX__c czr = TestClassUtility.createContryZipREGEX(true, 'United States', 'US');         
        }
        
        Generate_Quote_Pdf_Config__c GQPF = TestClassUtility.generateQuotePdfConfig(false);
        GQPF.URL__c = 'www.baidu.com';
        insert GQPF;

        Region__c testRegion = TestClassUtility.createRegion(true);
                
        Market__c testMarket = TestClassUtility.createMarket(false);
        testMarket.Active__c = true;
        testMarket.Local_Sales_Region__c = testRegion.id;
        insert testMarket;

        Category__c testCategory = TestClassUtility.createCategory(false);
        testCategory.Category_Group__c = 'Secondary';
        // testCategory.Name = 'Bridal Salons - BWP';
        testCategory.Name = 'Beauty - BEA';
        insert testCategory;

        MetroArea__c ma = TestClassUtility.createMetroArea(true);
        
        Zip__c testzip = TestClassUtility.createZip(false);
        testzip.MetroArea__c = ma.id;
        testzip.ZipCode__c = '94230';
        testzip.name = '94230';
        testzip.Local_Market__c = testMarket.id;
        testzip.Portfolio__c = 'Senior Sales Executive';
        insert testzip;

        Account testAccount = TestClassUtility.createAccount(false, testCategory, testMarket);
        testAccount.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
        testAccount.BU__c = 'Local';
        testAccount.Type = 'Agency';
        testAccount.Operative_Owner__c = userList[0].Name;
        testAccount.Fulfillment_Data__c = '{ "tier" : "Freemium", "reviewId" : "review Id", "parentGUID" : "37e0c6b9-6f4f-4dd4-a3f4-9707e9dc4bbc", "marketCode" : "228", "categoryId" : "8aa9a07b-fcd8-46ed-a98f-8f3e12689dd2" }';  
        testAccount.ShippingCountry = 'United States';
        testAccount.ShippingState  = 'California';
        testAccount.ShippingCity = 'Sacramento';
        testAccount.ShippingStreet = 'US3';
        testAccount.ShippingPostalCode = '94230';
        testAccount.ShippingStateCode  = 'CA';
        testAccount.BillingCountry = 'United States';
        testAccount.BillingState  = 'California';
        testAccount.BillingCity = 'Sacramento';
        testAccount.BillingStreet = 'US3';
        testAccount.BillingPostalCode = '94230';
        testAccount.BillingStateCode  = 'CA';
        testAccount.BillingCountryCode = 'US';
        // testAccount.ShippingPostalCode = 'US';
        insert testAccount;
        
        Contact testContact = TestClassUtility.createContact(true, testAccount);
                
        Campaign testCampaign = new Campaign();
        testCampaign.IsActive = true;
        testCampaign.Type = 'Bridal Show';
        testCampaign.Name = 'XO Group Internal - Hubspot_Paid Advertising-A';
        insert testCampaign;

        Test.startTest();

        Lead testLead = TestClassUtility.createLead(false, testMarket, testCategory);
        testLead.recordtypeId = rtLeadMapByName.get('Local').getRecordTypeId();
        testLead.Status = 'New';
        testLead.LeadSource = 'Other';
        testLead.PostalCode = testZip.ZipCode__c;
        testLead.Website  = 'ttt.com';
        insert testLead;

        Lead testLead2 = TestClassUtility.createLead(false, testMarket, testCategory);
        testLead2.recordtypeId = rtLeadMapByName.get('Local').getRecordTypeId();
        testLead2.Status = 'New';
        testLead2.LeadSource = 'Other';
        testLead2.Website  = 'ttt.com';
        insert testLead2;

        system.assert(testLead2.Status == 'New');

        testlead2.Status = 'Valid';
        update testlead2;

        Lead testLead3 = TestClassUtility.createLead(false);
        testLead3.recordtypeId = rtLeadMapByName.get('Local').getRecordTypeId();
        testLead3.Status = 'Valid';
        testLead3.LeadSource = 'Other';
        testLead3.Primary_Category__c = testCategory.Id;
        testLead3.PostalCode = '12451';
        testLead3.Phone = '1239876541';
        testLead3.Website  = 'ttt23.com';
        insert testLead3;
        system.assert(testLead3.Zip__c == null);  

        Lead testLead4 = TestClassUtility.createLead(false, testMarket, testCategory);
        testLead4.recordtypeId = rtLeadMapByName.get('Local').getRecordTypeId();
        testLead4.Status = 'Valid';
        testLead4.LeadSource = 'Reviews';
        testLead4.PostalCode = '12452   ';
        testLead4.Phone = '5232111345';
        testLead4.Website  = 'sdkjfsdkd.com';
        testLead4.FirstName = 'kdjfsdkjfs1';
        testLead4.LastName = 'sdfsfgs1';
        insert testLead4;

        

        Lead testLead5 = TestClassUtility.createLead(false, testMarket, testCategory);
        testLead5.recordtypeId = rtLeadMapByName.get('Local').getRecordTypeId();
        testLead5.Status = 'Valid';
        testLead5.LeadSource = 'Other';
        testLead5.Phone = '6129873541';
        testLead5.PostalCode = '13651';
        testLead5.Website  = 'ttt32.com';
        insert testLead5;

        Test.stopTest();

    }

    @isTest static void testInsertBridalSalonsLead() {
        // Implement test code
                
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Map<String,Schema.RecordTypeInfo> rtLeadMapByName = Schema.SObjectType.Lead.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtCategoryMapByName = Schema.SObjectType.Category__c.getRecordTypeInfosByName();
        
        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        
        if(CountryZipREGEX__c.getValues('United States') == null){
            CountryZipREGEX__c czr = TestClassUtility.createContryZipREGEX(true, 'United States', 'US');         
        }
        
        Generate_Quote_Pdf_Config__c GQPF = TestClassUtility.generateQuotePdfConfig(false);
        GQPF.URL__c = 'www.baidu.com';
        insert GQPF;

        Region__c testRegion = TestClassUtility.createRegion(true);
                
        Market__c testMarket = TestClassUtility.createMarket(false);
        testMarket.Active__c = true;
        testMarket.Local_Sales_Region__c = testRegion.id;
        insert testMarket;

        Category__c testCategory = TestClassUtility.createCategory(false);
        testCategory.Category_Group__c = 'Secondary';
        testCategory.Name = 'Bridal Salons - BWP';
        insert testCategory;

        MetroArea__c ma = TestClassUtility.createMetroArea(true);
        
        Zip__c testzip = TestClassUtility.createZip(false);
        testzip.MetroArea__c = ma.id;
        testzip.ZipCode__c = '94230';
        testzip.name = '94230';
        testzip.Local_Market__c = testMarket.id;
        testzip.Portfolio__c = 'Senior Sales Executive';
        insert testzip;

        Account testAccount = TestClassUtility.createAccount(false, testCategory, testMarket);
        testAccount.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
        testAccount.BU__c = 'Local';
        testAccount.Type = 'Agency';
        testAccount.Operative_Owner__c = userList[0].Name;
        testAccount.Fulfillment_Data__c = '{ "tier" : "Freemium", "reviewId" : "review Id", "parentGUID" : "37e0c6b9-6f4f-4dd4-a3f4-9707e9dc4bbc", "marketCode" : "228", "categoryId" : "8aa9a07b-fcd8-46ed-a98f-8f3e12689dd2" }';  
        testAccount.ShippingCountry = 'United States';
        testAccount.ShippingState  = 'California';
        testAccount.ShippingCity = 'Sacramento';
        testAccount.ShippingStreet = 'US3';
        testAccount.ShippingPostalCode = '94230';
        testAccount.ShippingStateCode  = 'CA';
        testAccount.BillingCountry = 'United States';
        testAccount.BillingState  = 'California';
        testAccount.BillingCity = 'Sacramento';
        testAccount.BillingStreet = 'US3';
        testAccount.BillingPostalCode = '94230';
        testAccount.BillingStateCode  = 'CA';
        testAccount.BillingCountryCode = 'US';
        // testAccount.ShippingPostalCode = 'US';
        insert testAccount;
        
        Contact testContact = TestClassUtility.createContact(true, testAccount);
                
        Campaign testCampaign = new Campaign();
        testCampaign.IsActive = true;
        testCampaign.Type = 'Bridal Show';
        testCampaign.Name = 'XO Group Internal - Hubspot_Paid Advertising-A';
        insert testCampaign;

        Test.startTest();

        Lead testLead = TestClassUtility.createLead(false, testMarket, testCategory);
        testLead.recordtypeId = rtLeadMapByName.get('Local').getRecordTypeId();
        testLead.Status = 'New';
        testLead.LeadSource = 'Other';
        testLead.PostalCode = testZip.ZipCode__c;
        testLead.Website  = 'ttt.com';
        insert testLead;

        system.assert(testLead.Local_Sales_Market__c == testMarket.id);

        Lead testLead2 = TestClassUtility.createLead(false, testMarket, testCategory);
        testLead2.recordtypeId = rtLeadMapByName.get('Local').getRecordTypeId();
        testLead2.Status = 'New';
        testLead2.LeadSource = 'Other';
        testLead2.Website  = 'ttt.com';
        insert testLead2;

        system.assert(testLead.Status == 'New');

        Test.stopTest();

    }

    @isTest static void testOtherCase() {
       // Implement test code
       List<XO_Exception__c> exceptionList = new List<XO_Exception__c>();
       SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Map<String,Schema.RecordTypeInfo> rtLeadMapByName = Schema.SObjectType.Lead.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtCategoryMapByName = Schema.SObjectType.Category__c.getRecordTypeInfosByName();
        
        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        
        if(CountryZipREGEX__c.getValues('United States') == null){
            CountryZipREGEX__c czr = TestClassUtility.createContryZipREGEX(true, 'United States', 'US');         
        }

        /*Canadian_Postal_Code_Market_Mapping__c customSetting = new Canadian_Postal_Code_Market_Mapping__c();
        customSetting.Name='A';
        customSetting.Canadian_Postal_Code__c = 'ON';
        customSetting.Default_State_Code__c = 'ON';
        customSetting.Market_Id__c = '222'; 
        insert customSetting;*/

        
        Generate_Quote_Pdf_Config__c GQPF = TestClassUtility.generateQuotePdfConfig(false);
        GQPF.URL__c = 'www.baidu.com';
        insert GQPF;

        Region__c testRegion = TestClassUtility.createRegion(true);
                
        Market__c testMarket = TestClassUtility.createMarket(false);
        testMarket.Active__c = true;
        testMarket.Local_Sales_Region__c = testRegion.id;
        insert testMarket;

        Category__c testCategory = TestClassUtility.createCategory(false);
        testCategory.Category_Group__c = 'Secondary';
        testCategory.Name = 'Bridal Salons - BWP';
        insert testCategory;

        MetroArea__c ma = TestClassUtility.createMetroArea(true);
        
        Zip__c testzip = TestClassUtility.createZip(false);
        testzip.MetroArea__c = ma.id;
        testzip.ZipCode__c = 'ABCDEF';
        testzip.name = 'ABCDEF';
        testzip.Local_Market__c = testMarket.id;
        testzip.Portfolio__c = 'Senior Sales Executive';
        insert testzip;

        Zip__c testzip1 = TestClassUtility.createZip(false);
        testzip1.MetroArea__c = ma.id;
        testzip1.ZipCode__c = '78757';
        testzip1.name = '78757';
        testzip1.Local_Market__c = testMarket.id;
        testzip1.Portfolio__c = 'Senior Sales Executive';
        insert testzip1;

        Account testAccount = TestClassUtility.createAccount(false, testCategory, testMarket);
        testAccount.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
        testAccount.BU__c = 'Local';
        testAccount.Type = 'Agency';
        testAccount.Operative_Owner__c = userList[0].Name;
        testAccount.Fulfillment_Data__c = '{ "tier" : "Freemium", "reviewId" : "review Id", "parentGUID" : "37e0c6b9-6f4f-4dd4-a3f4-9707e9dc4bbc", "marketCode" : "228", "categoryId" : "8aa9a07b-fcd8-46ed-a98f-8f3e12689dd2" }';  
        testAccount.ShippingCountry = 'United States';
        testAccount.ShippingState  = 'Texas';
        testAccount.ShippingCity = 'Austin';
        testAccount.ShippingStreet = 'US3';
        testAccount.ShippingPostalCode = '94230';
        testAccount.ShippingStateCode  = 'TX';
        testAccount.BillingCountry = 'United States';
        testAccount.BillingState  = 'Texas';
        testAccount.BillingCity = 'Austin';
        testAccount.BillingStreet = 'US3';
        testAccount.BillingPostalCode = '94230';
        testAccount.BillingStateCode  = 'TX';
        testAccount.BillingCountryCode = 'US';
        // testAccount.ShippingPostalCode = 'US';

        insert testAccount;
        
        Contact testContact = TestClassUtility.createContact(true, testAccount);
                
        Campaign testCampaign = new Campaign();
        testCampaign.IsActive = true;
        testCampaign.Type = 'Bridal Show';
        testCampaign.Name = 'XO Group Internal - Hubspot_Paid Advertising-A';
        insert testCampaign;

        Test.startTest();

        Lead testLead = TestClassUtility.createLead(false, testMarket, testCategory);
        testLead.recordtypeId = rtLeadMapByName.get('Local').getRecordTypeId();
        testLead.Status = 'New';
        testLead.LeadSource = 'Other';
        testLead.Website  = 'ttt.com';
        testLead.Country = 'United States';
        testLead.State  = 'Alaska';
        testLead.City = 'US2';
        testLead.Street = 'US3';
        testLead.Phone= '1234567895';
        testLead.Email='abc@abc.com';
        testLead.Website = 'www.abc.com';
        testLead.PostalCode = testZip.ZipCode__c;
        testLead.CountryCode = 'US';
        try {
            insert testLead;
            system.assert(testLead.Zip__c == testZip.id);
        } catch (Exception e) {
            XO_Exception__c xoException = ExceptionUtility.consumeException(e, false);
            xoException.Severity__c = 'Critical';
            xoException.Failure_Area__c = 'Lead Assignment Workflow Exception';
            exceptionList.add(xoException);
        }

        Lead testLead1 = TestClassUtility.createLead(false, testMarket, testCategory);
        testLead1.recordtypeId = rtLeadMapByName.get('Local').getRecordTypeId();
        testLead1.Status = 'New';
        testLead1.LeadSource = 'Other';
        testLead1.Website  = 'ttt.com';
        testLead1.State  = 'Alaska';
        testLead1.City = 'US2';
        testLead1.Street = 'US3';
        testLead1.Phone= '1234567895';
        testLead1.Email='abc@abc.com';
        testLead1.Website = 'www.abc.com';
        testLead1.PostalCode = testZip1.ZipCode__c;
        insert testLead1;
        system.assert(testLead1.Status == 'New');

        List<CountryZipREGEX__c> countryRegExList11 = [select Id, Name, Active__c, CountryCode__c, RegExPattern__c from CountryZipREGEX__c where Active__c = true];
        Test.stopTest();
    }

    static testmethod void testExistingLocationNewClaimingAccount_sseportfolio(){

        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);


            Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();

            Region__c testRegion = TestClassUtility.createRegion(true);
            Category__c testCategory = TestClassUtility.createCategory(true);

            Market__c testMkt = TestClassUtility.createMarket(false, testRegion);
            testMkt.Market_ID__c = '222';
            insert testMkt;

            MetroArea__c ma = TestClassUtility.createMetroArea(true);
            
            Zip__c zip = TestClassUtility.createZip(false);
            zip.MetroArea__c = ma.id;
            zip.ZipCode__c = '78757';
            Zip.name = '78757';
            zip.Portfolio__c = 'Senior Sales Executive';
            zip.Local_Market__c = testMkt.Id;
            zip.City__c = 'Austin';
            zip.State__c = 'Texas';
            insert zip;


            Lead testLead = TestClassUtility.createLead(false, testMkt, testCategory);
            testLead.DynamicsLeadID__c = 'testDynamicsID 01';
            testLead.LeadSource = 'Paid Media';
            testlead.PostalCode = '78757';
            //insert testLead;

            Lead testLead2 = TestClassUtility.createLead(false, testMkt, testCategory);
            testLead2.DynamicsLeadID__c = 'testDynamicsID 02';
            testlead2.Street = '59dgfsfgfg547';
            testlead2.City = 'Austin';
            testlead2.State = 'Texas';
            testlead2.PostalCode = '78757';
            testlead2.Country = 'United States  ';
            testLead2.LeadSource = 'Paid Media';
            insert testLead2;

            Test.startTest();

            Generate_Quote_Pdf_Config__c GQPF = TestClassUtility.generateQuotePdfConfig(false);
            GQPF.URL__c = 'www.baidu.com';
            insert GQPF;

            Test.stopTest();
            
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            
            LeadPayloadWrapper reqst = new LeadPayloadWrapper();
            reqst.companyId = '';//testLead.DynamicsLeadID__c;
            reqst.locationId = testLead.DynamicsLeadID__c;
            reqst.fulfillmentData.multipleCategoryInterest = false;
            reqst.fulfillmentData.tier = null;
            reqst.isClaiming = true;
            reqst.phone = '(123)456-7890';
            reqst.email = 'test@test.com';
            reqst.contact.lastName = 'test';
            reqst.contact.firstName = 'Lead';
            reqst.companyName = 'testcompanyName';
            reqst.fulfillmentData.marketCode = '222';
            reqst.fulfillmentData.categoryId = testCategory.Taxonomy_Id__c;

            System.debug(LoggingLevel.INFO, '*** reqst: ' + reqst);

            LeadPayloadWrapper.AddressWrapper addressWrapper = new LeadPayloadWrapper.AddressWrapper();
            addressWrapper.street1 = 'teststreet1';
            addressWrapper.street2 = 'teststreet2';
            addressWrapper.postalCode = '59547';
            addressWrapper.stateOrProvince = 'MT';
            addressWrapper.country = 'United States';
            addressWrapper.city = 'Zurich';
            addressWrapper.addressType = 'Shipping';

            reqst.address.add(AddressWrapper);
            String JsonMsg=JSON.serialize(reqst);

            req.requestURI = '/services/apexrest/LocalStorefront';  //Request URL
            req.httpMethod = 'Post';//HTTP Request Type
            req.requestBody = Blob.valueOf(JsonMsg);
            RestContext.request = req;
            //RESTLocalStorefrontAPI.LeadSubmissionResponse responseMessage = RESTLocalStorefrontAPI.storefrontFromPartner();
     
            reqst = new LeadPayloadWrapper();
            reqst.companyId = '';//testLead.DynamicsLeadID__c;
            reqst.locationId = testLead2.DynamicsLeadID__c;
            reqst.fulfillmentData.multipleCategoryInterest = false;
            reqst.fulfillmentData.tier = null;
            reqst.isClaiming = true;
            reqst.phone = '(123)456-7890';
            reqst.email = 'test@test.com';
            reqst.contact.lastName = 'test';
            reqst.contact.firstName = 'Lead';
            reqst.companyName = 'testcompanyName';
            reqst.fulfillmentData.marketCode = '222';
            reqst.fulfillmentData.categoryId = testCategory.Taxonomy_Id__c;

            System.debug(LoggingLevel.INFO, '*** reqst 2: ' + reqst);

            addressWrapper = new LeadPayloadWrapper.AddressWrapper();
            addressWrapper.street1 = 'teststreet1';
            addressWrapper.street2 = 'teststreet2';
            addressWrapper.postalCode = '78757';
            addressWrapper.stateOrProvince = 'TX';
            addressWrapper.country = 'United States';
            addressWrapper.city = 'Austin';
            addressWrapper.addressType = 'Shipping';

            reqst.address.add(AddressWrapper);
            String JsonMsg2=JSON.serialize(reqst);

            req.requestBody = Blob.valueOf(JsonMsg2);
            RestContext.request = req;
            RESTLocalStorefrontAPI.LeadSubmissionResponse responseMessage = RESTLocalStorefrontAPI.storefrontFromPartner();
            system.debug (' responseMessage  : ' + responseMessage );
    }

}