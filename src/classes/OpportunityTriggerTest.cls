/* 
<class>
  <name>OpportunityTriggerTest</name>
  <purpose>Used to test the OpportunityTrigger</purpose>
  <created>
    <by>Jonathan Satterfield</by>
    <date>10/7/2015</date>
    <ticket>SF-1597</ticket>
  </created>
</class>
*/
@isTest
public class OpportunityTriggerTest {
    @testSetup static void createTestData(){
        TestClassUtility.generateQuotePdfConfig(true);
    }

    @isTest static void NationalOpportunityTriggerTest() {
        
        List<user> userlist = [select id from user where Profile.name = 'National Users' and userRole.name = 'Account Strategist' and IsActive =: true];
        
        test.startTest();
        if(!userlist.isEmpty()){
            Account_Strategist_Assignment__c  ASA = TestClassUtility.createAccountStrategistAssignment(True,userlist[0]);
        }
        
        Map<String, SObject> testObjects = TestClassUtility.buildNationalData();
        
        Opportunity testOpportunity = (Opportunity)testObjects.get('Opportunity');

        List<Stage_Requires_Complete_TS_RFP__c> SRCTSRFP  = TestClassUtility.createStageRequiresCompleteTSRFP(True);
 
        
        testOpportunity.StageName = 'Pitched';
        try{
            update testOpportunity;
        }catch(exception e){}
        
        Id pricebookId = Test.getStandardPricebookId();
        Product2 prod = TestClassUtility.createProduct2(True);
        PricebookEntry pbEntry = TestClassUtility.createPricebookEntry(True, pricebookId, prod);
        
        Map<String,Schema.RecordTypeInfo> rtTRFPMapByName = Schema.SObjectType.ThoughtStarter_RFP__c.getRecordTypeInfosByName();
        user u = [select id from user where UserRole.name = 'Sales Development' limit 1];
        ThoughtStarter_RFP__c TRFP = TestClassUtility.createThoughtStarterRFP(True, testOpportunity, rtTRFPMapByName.get('ThoughtStarter').getRecordTypeId(), u);

        
        test.stopTest();
    }

    @isTest static void LocalOpportunityTriggerTest() {
    
        test.startTest();
        Map<String, SObject> testObjects = TestClassUtility.buildLocalData(FALSE);
        
        Opportunity testOpportunity = (Opportunity)testObjects.get('Opportunity');
        Account testAccount = (Account)testObjects.get('Account');
        Contact testContact = (Contact)testObjects.get('Contact');
        
        zqu__Quote__c testQuote = TestClassUtility.createQuote(true, testOpportunity, testAccount, testContact);

        String emailString = testContact.Email;
        testContact.Email = null;
        update testContact;
        test.stopTest();
        testOpportunity.StageName = 'Ready for Echo-Sign';
        try{
            update testOpportunity;
        }catch(exception e){}
        
        testContact.Email = emailString;
        update testContact;
        
        testQuote.zqu__SubscriptionType__c = 'New Subscription';
        update testQuote;
        
        testOpportunity.StageName = 'Ready for Echo-Sign';
        testOpportunity.Lock_Quotes__c = true;
        update testOpportunity;
        
        testOpportunity.Lock_Quotes__c = false;
        update testOpportunity;
        
        
        testOpportunity.NeedToSendToZBilling__c = true;
        testOpportunity.StageName = 'Closed Won';
        testOpportunity.Lock_Quotes__c = false;
        update testOpportunity;
        
        
        echosign_dev1__SIGN_Agreement__c testEDSA = TestClassUtility.createechosigndev1SIGNAgreement(true,testOpportunity);
        
        testOpportunity.StageName = 'Prospecting';
        testOpportunity.Lock_Quotes__c = true;
        testOpportunity.Opportunity_Expiration_Date__c = null;
        update testOpportunity;
    } 
    
    @isTest static void OpportunityApprovalProcessARAssignmentTest() {
    
        test.startTest();
        Map<String, SObject> testObjects = TestClassUtility.buildLocalData(true);
        
        Opportunity testOpportunity = (Opportunity)testObjects.get('Opportunity');
        Account testAccount = (Account)testObjects.get('Account');
        Contact testContact = (Contact)testObjects.get('Contact');
        
        zqu__Quote__c testQuote = TestClassUtility.createQuote(true, testOpportunity, testAccount, testContact);
        echosign_dev1__SIGN_Agreement__c testEDSA = TestClassUtility.createechosigndev1SIGNAgreement(true,testOpportunity);
        LocalOppApprovalProcessARApprover__c LOAPARA = TestClassUtility.createLocalOppApprovalProcessARApprover(false);
        LOAPARA.Email__c = 'bobtester1@xogrp.com';
        insert LOAPARA;
        LocalOppApprovalProcessCancelApprover__c LOAPCA = TestClassUtility.createLocalOppApprovalProcessCancelApprover(false);
        LOAPCA.Email__c = 'bobtester1@xogrp.com';
        insert LOAPCA;
        Task_Creation_Settings__c taskCreateSetting = TestClassUtility.createTaskCreationSettings(true);
        
        //user mus = [select id,managerid from user where isActive = true limit 1];
        Profile rsrProfile = [SELECT Id FROM Profile WHERE Name = 'Local Core Regional Sales (RSR, RSD)'];
        User noManagerUser = TestClassUtility.createUser(false, rsrProfile);
        noManagerUser.Alias = 'btest1';
        noManagerUser.Email = 'bobtester1@xogrp.com';
        noManagerUser.UserName = 'bobtester1@xogrp.com';
        noManagerUser.SalesRepID__c = '54321';
        insert noManagerUser;
        
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User userObj = TestClassUtility.createUser(false, adminProfile);
        userObj.managerid = noManagerUser.id;
        insert userObj;
        
        test.stopTest();
        system.runAs(userObj){
            List<String> onboardingCaseProductNameList = System.Label.OnboardingCaseProductName.split('\n');
            zqu__QuoteRatePlan__c testQuoteRatePlan = (zqu__QuoteRatePlan__c)testObjects.get('zqu__QuoteRatePlan__c');
            testQuoteRatePlan.zqu__QuoteProductName__c = (onboardingCaseProductNameList.size() > 0)? onboardingCaseProductNameList.get(0): 'Bridal Salon Referral Program-Bridal Party - Storefront';
            update testQuoteRatePlan;
            testOpportunity.StageName = 'Client Approved';
            testOpportunity.NeedToSendToZBilling__c = true;
            update testOpportunity;
            Id onboardingCaseRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('2 - Onboarding').getRecordTypeId();
            Case onboardingCase = [SELECT Id FROM Case WHERE AccountId =: testAccount.Id AND RecordTypeId =: onboardingCaseRTId LIMIT 1];
            system.assert(onboardingCase != null);

            testOpportunity.Approval_Process_AR_Assignment__c = true;
            update testOpportunity;
            
            testOpportunity.Approval_Process_AR_Assignment__c = false;
            testOpportunity.StageName = 'Pending Client Approval';
            testOpportunity.Approval_Process_Manager_Assignment__c = true;
            update testOpportunity;
            
            testOpportunity.Approval_Process_AR_Assignment__c = false;
            testOpportunity.Approval_Process_Manager_Assignment__c = false;
            testOpportunity.Approval_Process_Cancel_Assignment__c = true;
            update testOpportunity;
        }
    }

    @isTest static void testCancelForConvenience() {
        Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();

        Account testAcctInsert = TestClassUtility.createAccount(false);
        testAcctInsert.Name = 'testAcctInsertLengthGreaterThanFortyCharacters';
        Account testAcctUpdate = TestClassUtility.createAccount(false);
        testAcctUpdate.Name = 'testAcctUpdate';
        Account testAcctInsert2 = TestClassUtility.createAccount(false);
        testAcctInsert2.Name = 'testAcctInsert2';
        Account testAcctUpdate2 = TestClassUtility.createAccount(false);
        testAcctUpdate2.Name = 'testAcctUpdate2';
        insert new List<Account>{testAcctInsert, testAcctUpdate, testAcctInsert2, testAcctUpdate2};

        Opportunity testOppInsert = TestClassUtility.createOpportunity(false, testAcctInsert);
        testOppInsert.RecordTypeId = rtOppMapByName.get('Local').getRecordTypeId();
        testOppInsert.Name = null;
        testOppInsert.Cancel_For_Convenience__c = true;

        Opportunity testOppInsert2 = TestClassUtility.createOpportunity(false, testAcctInsert2);
        testOppInsert2.RecordTypeId = rtOppMapByName.get('Local').getRecordTypeId();
        testOppInsert2.Name = 'testOppInsert2';
        testOppInsert2.Cancel_For_Convenience__c = true;

        Opportunity testOppInsert3 = TestClassUtility.createOpportunity(false, testAcctInsert2);
        testOppInsert2.RecordTypeId = rtOppMapByName.get('Local').getRecordTypeId();
        testOppInsert3.Name = 'testOppInsert3';
        testOppInsert3.Cancel_For_Convenience__c = true;

        Opportunity testOppUpdate = TestClassUtility.createOpportunity(false, testAcctUpdate);
        testOppUpdate.RecordTypeId = rtOppMapByName.get('Local').getRecordTypeId();
        testOppUpdate.Name = 'testOppUpdate';
        testOppUpdate.Cancel_For_Convenience__c = false;

        Opportunity testOppUpdate2 = TestClassUtility.createOpportunity(false, testAcctUpdate2);
        testOppUpdate2.RecordTypeId = rtOppMapByName.get('Local').getRecordTypeId();
        testOppUpdate2.Name = 'testOppUpdate2';
        testOppUpdate2.Cancel_For_Convenience__c = false;

        Opportunity testOppUpdate3 = TestClassUtility.createOpportunity(false, testAcctUpdate2);
        testOppUpdate3.RecordTypeId = rtOppMapByName.get('Local').getRecordTypeId();
        testOppUpdate3.Name = 'testOppUpdate3';
        testOppUpdate3.Cancel_For_Convenience__c = false;

        Opportunity testOppUpdate4 = TestClassUtility.createOpportunity(false, testAcctUpdate2);
        testOppUpdate4.RecordTypeId = rtOppMapByName.get('Local').getRecordTypeId();
        testOppUpdate4.Name = 'testOppUpdate4';
        testOppUpdate4.Cancel_For_Convenience__c = false;


        insert new List<Opportunity>{testOppInsert, testOppInsert2, testOppInsert3, testOppUpdate, testOppUpdate2, testOppUpdate3, testOppUpdate4};
        
        Test.startTest();

        testOppUpdate.Cancel_For_Convenience__c = true;
        testOppUpdate2.Cancel_For_Convenience__c = true;
        testOppUpdate3.Cancel_For_Convenience__c = true;

        testOppUpdate4.Cancel_For_Convenience__c = true;
        testOppUpdate4.RecordTypeId = rtOppMapByName.get('National').getRecordTypeId();
        update new List<Opportunity>{testOppUpdate, testOppUpdate2, testOppUpdate3, testOppUpdate4};
        
        Test.stopTest();
        
        for(Account accAssert : [SELECT Cancel_For_Convenience__c FROM Account]){
            system.assert(accAssert.Cancel_For_Convenience__c == true);
        }
    }

    @isTest static void testClosedLost() {
        Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();

        Account testAcctWithActiveSubs = TestClassUtility.createAccount(false);
        testAcctWithActiveSubs.Name = 'testAcctWithActiveSubs';
        Account testAcctOutOfBusiness = TestClassUtility.createAccount(false);
        testAcctOutOfBusiness.Name = 'testAcctOutOfBusiness';
        Account testAcctDoNotContact = TestClassUtility.createAccount(false);
        testAcctDoNotContact.Name = 'testAcctDoNotContact';
        Account testAcctNoBudget = TestClassUtility.createAccount(false);
        testAcctNoBudget.Name = 'testAcctNoBudget';
        insert new List<Account>{testAcctWithActiveSubs, testAcctOutOfBusiness, testAcctDoNotContact, testAcctNoBudget};

        TestClassUtility.createSubscription(true, testAcctWithActiveSubs);

        Opportunity testOppOfAccWithSubs = TestClassUtility.createOpportunity(false, testAcctWithActiveSubs);
        testOppOfAccWithSubs.RecordTypeId = rtOppMapByName.get('Local').getRecordTypeId();
        testOppOfAccWithSubs.Name = 'testOppOfAccWithSubs';

        Opportunity testOppOutOfBusiness = TestClassUtility.createOpportunity(false, testAcctOutOfBusiness);
        testOppOutOfBusiness.RecordTypeId = rtOppMapByName.get('Local').getRecordTypeId();
        testOppOutOfBusiness.Name = 'testOppOutOfBusiness';

        Opportunity testOppOutOfBusiness2 = TestClassUtility.createOpportunity(false, testAcctOutOfBusiness);
        testOppOutOfBusiness2.RecordTypeId = rtOppMapByName.get('Local').getRecordTypeId();
        testOppOutOfBusiness2.Name = 'testOppOutOfBusiness2';

        Opportunity testOppDoNotContact = TestClassUtility.createOpportunity(false, testAcctDoNotContact);
        testOppDoNotContact.RecordTypeId = rtOppMapByName.get('Local').getRecordTypeId();
        testOppDoNotContact.Name = 'testOppDoNotContact';

        Opportunity testOppNoBudget = TestClassUtility.createOpportunity(false, testAcctNoBudget);
        testOppNoBudget.RecordTypeId = rtOppMapByName.get('Local').getRecordTypeId();
        testOppNoBudget.Name = 'testOppNoBudget';

        insert new List<Opportunity>{testOppOfAccWithSubs, testOppOutOfBusiness, testOppOutOfBusiness2, testOppDoNotContact, testOppNoBudget};
        
        Test.startTest();
        AccountTriggerHandler.openedOppSet = new Set<Id>();

        testOppOfAccWithSubs.StageName = 'Closed Lost';
        testOppOfAccWithSubs.Lost_Reason__c = 'Out of Business';
        
        testOppOutOfBusiness.StageName = 'Closed Lost';
        testOppOutOfBusiness.Lost_Reason__c = 'Out of Business';

        testOppOutOfBusiness2.StageName = 'Closed Lost';
        testOppOutOfBusiness2.Lost_Reason__c = 'Out of Business';

        testOppDoNotContact.StageName = 'Closed Lost';
        testOppDoNotContact.Lost_Reason__c = 'Do not contact again';

        testOppNoBudget.StageName = 'Closed Lost';
        testOppNoBudget.Lost_Reason__c = 'No Budget';

        update new List<Opportunity>{testOppOfAccWithSubs, testOppOutOfBusiness, testOppOutOfBusiness2, testOppDoNotContact, testOppNoBudget};
        
        Test.stopTest();
        
        for(Account accAssert : [SELECT Negative_Disposition_Reason__c, account_status__c 
                                    FROM Account]){
            if(accAssert.Id == testAcctWithActiveSubs.Id){
                system.assert(accAssert.Negative_Disposition_Reason__c != 'Out of Business');
                system.assert(accAssert.account_status__c != 'Disqualified');
            }else if(accAssert.Id == testAcctOutOfBusiness.Id){
                system.assert(accAssert.Negative_Disposition_Reason__c == 'Out of Business');
                system.assert(accAssert.account_status__c == 'Disqualified');
            }else if(accAssert.Id == testAcctDoNotContact.Id){
                system.assert(accAssert.Negative_Disposition_Reason__c == 'Do Not Contact');
                system.assert(accAssert.account_status__c == 'Disqualified');
            }else if(accAssert.Id == testAcctNoBudget.Id){
                system.assert(accAssert.Negative_Disposition_Reason__c == 'No Need');
                system.assert(accAssert.account_status__c == 'Dormant');
            }
        }
    } 

    @isTest static void testOppTrigger() {
        User tempManagerUser = [Select Id, FirstName, LastName, UserName, Email, Phone, ManagerID from User where id != :UserInfo.getUserId() AND isActive = true limit 1];
        User currentUser = [Select Id, FirstName, LastName, UserName, Email, Phone, ManagerID from User where id = :UserInfo.getUserId() limit 1];
        currentUser.ManagerId = tempManagerUser.Id;
        update currentUser;


        List<RecordType> recordTypes = [select Id, Name, sObjectType from RecordType where name like '%local%' and IsActive = true];

        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        testAccount.Region__c = 'Test Region';
        testAccount.OwnerId = currentUser.Id;
        for (RecordType rt : recordTypes)
        {
            if (rt.SObjectType == 'Account')
            {
                testAccount.RecordTypeId = rt.Id;
            }
            break;
        }
        insert testAccount;
            

        Opportunity testOpportunity = new Opportunity();
        testOpportunity.Name = 'Test Opportunity';
        testOpportunity.AccountId = testAccount.Id;
        testOpportunity.CloseDate = Date.Today()-10;
        testOpportunity.StageName = 'Prospecting';
        testOpportunity.Opportunity_Expiration_Date__c = Date.today();
        testOpportunity.Approval_Process_AR_Assignment__c = False;
        testOpportunity.Approval_Process_Manager_Assignment__c = False;
        testOpportunity.EchoSign_Contract_Due_Date__c = Date.today();
        testOpportunity.Lock_Quotes__c = False;
        for (RecordType rt : recordTypes)
        {
            if (rt.SObjectType == 'Opportunity')
            {
                testOpportunity.RecordTypeId = rt.Id;
            }
            break;
        }
        insert testOpportunity;
        

        Contact testContact = new Contact();
        testContact.Same_Address_as_Account__c = true;
        testContact.LastName = 'test';
        testContact.Email = 'abc@gmail.com';
        testContact.AccountId = testAccount.Id;
        insert testContact;


        Opportunity testOpportunity2 = testOpportunity.clone();
        insert testOpportunity2;
        
        zqu__Quote__c qut = new zqu__Quote__c();
        qut.Name = 'Test Quote';
        qut.zqu__Opportunity__c = testOpportunity.Id;
        insert qut;

        zqu__Quote__c qut1 = new zqu__Quote__c();
        qut1.Name = 'Test Quote';
        qut1.zqu__Opportunity__c = testOpportunity.Id;
        insert qut1;

        testOpportunity.Approval_Process_AR_Assignment__c = True;
        testOpportunity2.Approval_Process_AR_Assignment__c = True;
        testOpportunity2.StageName = 'Pending Client Approval';
        //testOpportunity2.Lock_Quotes__c = True;
        List<Opportunity> oppUpdateList = new List<Opportunity>();
        oppUpdateList.add(testOpportunity);
        oppUpdateList.add(testOpportunity2);
        update oppUpdateList;

        Test.startTest();
        testOpportunity.Approval_Process_AR_Assignment__c = True;
        testOpportunity.Approval_Process_AR_Assignment__c = True;
        testOpportunity.StageName = 'Pending Client Approval';
        testOpportunity.Lock_Quotes__c = True;
        update testOpportunity;
        
        testOpportunity.Approval_Process_AR_Assignment__c = True;
        testOpportunity.Approval_Process_AR_Assignment__c = True;
        testOpportunity.StageName = 'Pending Client Approval';
        testOpportunity.Lock_Quotes__c = False;
        update testOpportunity;

        testOpportunity2.Approval_Process_AR_Assignment__c = False;
        testOpportunity2.Approval_Process_Manager_Assignment__c = True;
        testOpportunity2.Opportunity_Expiration_Date__c = null;
        testOpportunity2.Lock_Quotes__c = True;
        update testOpportunity2;
        Test.stopTest();
    }
}