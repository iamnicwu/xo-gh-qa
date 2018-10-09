/* 
<class>
    <name>AttachmentTriggerHandlerTest</name>
    <purpose>Tests the AttachmentTriggerHandler apex class</purpose>
    <created>
        <by>Harikrishnan Mohan</by>
        <date>8/10/2015</date>
        <ticket>SF-791</ticket>        
    </created>
</class>
*/
@isTest
private class AttachmentTriggerHandlerTest {
    
    @isTest static void test_method_one() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        /*
        testDataFactoryT tdf = new testDataFactoryT();
        tdf.CreateLocalTestObjects();
        */
        
        List<Attachment> attList = new List<Attachment>();
        
        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];        
        Profile p = [Select id,name from Profile where Name = 'Standard User'];
        user u = [select id from user where isactive = true limit 1];
        
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        // CSP-1999 Map<String,Schema.RecordTypeInfo> rtBrandMapByName = Schema.SObjectType.Brand__c.getRecordTypeInfosByName();
        
        // CSP-1999 
        // Brand__c brand = TestClassUtility.createBrand(false);
        // brand.RecordTypeId = rtBrandMapByName.get('Local').getRecordTypeId();
        // insert brand;
        // Category__c category = TestClassUtility.createCategory(true,brand);
        Category__c category = TestClassUtility.createCategory(true);
        Market__c market = TestClassUtility.createMarket(false);
        market.Market_ID__c ='222';
        insert market;
        Zip__c zipCode = TestClassUtility.createZip(true);
        // CSP-1999 
        // Account testAccount = TestClassUtility.createAccount(false,brand,category,market);
        Account testAccount = TestClassUtility.createAccount(false,category,market);
        //testAccount.Operative_Owner__c = userList[0].Name;
        testAccount.Type = 'Advertiser';
        testAccount.DynamicsAccID__c = 'testDynamicsLeadID';
        testAccount.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
        testAccount.BU__c = 'Local';
        insert testAccount;  
        
        Generate_Quote_Pdf_Config__c gqpf =  TestClassUtility.createGenerateQuotePdfConfig(true);
        Opportunity testOpportunity = TestClassUtility.createOpportunity(false, testAccount);    
        testOpportunity.RecordTypeId = rtOppMapByName.get('National').getRecordTypeId();
        testOpportunity.Opportunity_Expiration_Date__c = null;
        testOpportunity.CloseDate = Date.Today()-10;
        testOpportunity.Description = 'Test data for test class';
        insert testOpportunity;        
        // Create a custom setting named ProfilesExemptDeletingNotesNAttachment__c to hold the profiles exempt for deleting N&A
        ProfilesExemptDeletingNotesNAttachment__c pfl = new ProfilesExemptDeletingNotesNAttachment__c();
        pfl.Name = 'test System Administrator';
        insert pfl;
        
        Deactivate_Trigger__c dt = TestClassUtility.createAttachmentDeactivateTriggerSetting(true);
        
         for(integer i = 1; i < 5; i++){
            Attachment attach = TestClassUtility.createAttachment(false,'Test'+i, 'Text');            
            attach.ownerId = UserInfo.getUserId();
            attach.Body = Blob.valueOf('testString');            
            attach.ParentID = testOpportunity.id; 
            attList.add(attach);          
        }
        
        try
        {
            insert attList;
        } catch (exception eAttach) {}
        
        AttachmentTriggerHanlder.modifyAttachments(attList);
        
        /*
        Attachment attach = new Attachment();
        attach.ownerId = userList[0].id;
        attach.Body = Blob.valueOf('testString');
        attach.Name = 'Test';
        attach.ContentType = 'Text';
        attach.ParentID = tdf.testOpportunity.id; 
        insert attach;
        */
        Attachment attach = TestClassUtility.createAttachment(false,'Test', 'Text'); 
        attach.ownerId = UserInfo.getUserId();
        attach.ParentID = testOpportunity.id;
        insert attach;  
        
        attach.ContentType = 'Text1';
        try{
            update attach;
        }catch(exception e){}
        
        
        dt.After_Update__c = false;
        dt.Before_Update__c = false;
        update dt;
        attach.ContentType = 'Text2';
        try{
            update attach;
        }catch(exception e){}
        
        try{
            delete attach;
        }catch(exception e){}   
    }
    
    
    @isTest static void test_method_two() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        /*testDataFactoryT tdf = new testDataFactoryT();
        tdf.CreateLocalTestObjects();*/
        
        List<Attachment> attList = new List<Attachment>();
        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        
         Profile p = [Select id,name from Profile where Name = 'Standard User'];
        user u = [select id from user where isactive = true limit 1];
        
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        // CSP-1999 Map<String,Schema.RecordTypeInfo> rtBrandMapByName = Schema.SObjectType.Brand__c.getRecordTypeInfosByName();
        // CSP-1999
        // Brand__c brand = TestClassUtility.createBrand(false);
        // brand.RecordTypeId = rtBrandMapByName.get('Local').getRecordTypeId();
        // insert brand;
        // Category__c category = TestClassUtility.createCategory(true,brand);
        Category__c category = TestClassUtility.createCategory(true);
        Market__c market = TestClassUtility.createMarket(false);
        market.Market_ID__c ='222';
        insert market;
        Zip__c zipCode = TestClassUtility.createZip(true);
        // CSP-1999 
        // Account testAccount = TestClassUtility.createAccount(false,brand,category,market);
        Account testAccount = TestClassUtility.createAccount(false,category,market);
        //testAccount.Operative_Owner__c = userList[0].Name;
        testAccount.Type = 'Advertiser';
        testAccount.DynamicsAccID__c = 'testDynamicsLeadID';
        testAccount.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
        testAccount.BU__c = 'Local';
        insert testAccount;  
        
        Generate_Quote_Pdf_Config__c gqpf =  TestClassUtility.createGenerateQuotePdfConfig(true);
        Opportunity testOpportunity = TestClassUtility.createOpportunity(false, testAccount);    
        testOpportunity.RecordTypeId = rtOppMapByName.get('National').getRecordTypeId();
        testOpportunity.Opportunity_Expiration_Date__c = null;
        testOpportunity.CloseDate = Date.Today()-10;
        testOpportunity.Description = 'Test data for test class';
        insert testOpportunity;
        // Create a custom setting named ProfilesExemptDeletingNotesNAttachment__c to hold the profiles exempt for deleting N&A
        ProfilesExemptDeletingNotesNAttachment__c pfl = new ProfilesExemptDeletingNotesNAttachment__c();
        pfl.Name = 'test System Administrator';
        insert pfl;
        Deactivate_Trigger__c dt = TestClassUtility.createAttachmentDeactivateTriggerSetting(true);
        
         for(integer i = 1; i < 5; i++){
            Attachment attach = TestClassUtility.createAttachment(false,'Test'+i, 'Text');            
            attach.ownerId = UserInfo.getUserId();
            attach.Body = Blob.valueOf('testString');            
            attach.ParentID = testOpportunity.id; 
            attList.add(attach);          
        }
        
        try
        {
            insert attList;
        } catch (exception eAttach) {}
        
        AttachmentTriggerHanlder.modifyAttachments(attList);
        
       /* Attachment attach = new Attachment();
        attach.ownerId = userList[0].id;
        attach.Body = Blob.valueOf('testString');
        attach.Name = 'test111preview.pdf';
        attach.ContentType = 'Text';
        attach.ParentID = tdf.testOpportunity.id; 
        insert attach;
        */
        Attachment attach = TestClassUtility.createAttachment(false,'Test', 'Text'); 
        attach.ownerId = UserInfo.getUserId();
        attach.Name = 'test111preview.pdf';
        attach.ParentID = testOpportunity.id;
        insert attach;  
        List<Id> oppIds = new List<Id>();
        oppIds.add(testOpportunity.id);
        AttachmentTriggerHanlder.deleteZuoraQuotePDFAttachmentsFromOpportunities(oppIds);  
    }
    @isTest static void test_method_three() {
        
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        // Create test user
        Profile p = [Select id,name from Profile where Name = 'Standard User'];
        user u = [select id from user where isactive = true limit 1];
        
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        // CSP-1999 
        // Map<String,Schema.RecordTypeInfo> rtBrandMapByName = Schema.SObjectType.Brand__c.getRecordTypeInfosByName();
        
        // Brand__c brand = TestClassUtility.createBrand(false);
        // brand.RecordTypeId = rtBrandMapByName.get('Local').getRecordTypeId();
        // insert brand;
        // Category__c category = TestClassUtility.createCategory(true,brand);
        Category__c category = TestClassUtility.createCategory(true);
        Market__c market = TestClassUtility.createMarket(false);
        market.Market_ID__c ='222';
        insert market;
        Zip__c zipCode = TestClassUtility.createZip(true);
        // CSP-1999 
        // Account testAccount = TestClassUtility.createAccount(false,brand,category,market);
        Account testAccount = TestClassUtility.createAccount(false,category,market);
        //testAccount.Operative_Owner__c = userList[0].Name;
        testAccount.Type = 'Advertiser';
        testAccount.DynamicsAccID__c = 'testDynamicsLeadID';
        testAccount.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
        testAccount.BU__c = 'Local';
        insert testAccount;      

        // Create a custom setting named ProfilesExemptDeletingNotesNAttachment__c to hold the profiles exempt for deleting N&A
        ProfilesExemptDeletingNotesNAttachment__c pfl = new ProfilesExemptDeletingNotesNAttachment__c();
        pfl.Name = p.name;
        insert pfl;
        
        

        Id otherUserId = [select Id from User where isActive = true and Profile.Name = 'National Users' and UserRole.Name = 'Account Executive' limit 1].Id;

        /*
        testDataFactoryT tdf = new testDataFactoryT();
        tdf.CreateLocalTestObjects();
        */
        
        Deactivate_Trigger__c dt = TestClassUtility.createAttachmentDeactivateTriggerSetting(true);
        dt = TestClassUtility.updateAttachmentDeactivateTriggerSetting(true,dt,false);

        
        Attachment attach1 = TestClassUtility.createAttachment(false,'Test', 'Text');
        attach1.ownerId = UserInfo.getUserId();
        attach1.ParentID = testAccount.id;
        insert attach1 ;        
        
        delete attach1;
        delete dt;

        dt = TestClassUtility.createAttachmentDeactivateTriggerSetting(true);
        Attachment attach = TestClassUtility.createAttachment(false,'Test', 'Text');
        attach.ownerId = u.id;
        attach.ParentID = testAccount.id;
        insert attach ;
        
        attach.Name = 'Test1';
        try{
            update attach;
        }catch(exception e){}
        
        List<Attachment> attlist = new List<Attachment>();
        attlist.add(attach);
        AttachmentTriggerHanlder ath =  new AttachmentTriggerHanlder();
        try{
            AttachmentTriggerHanlder.modifyAttachments(attlist);
        }catch(exception e){}
        
        try{
            delete attach;
        }catch(exception e){}  
    }
    
}