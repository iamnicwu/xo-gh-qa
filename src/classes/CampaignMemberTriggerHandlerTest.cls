@isTest
private class CampaignMemberTriggerHandlerTest {
    static testMethod void testMethod1() {
        test.startTest();
            lead testLead = TestClassUtility.createLead(false);
            testLead.DE_Backlog__c = true;
            testLead.Negative_Disposition_Reason__c = 'Duplicate';
            testLead.Status = 'Invalid';
            testLead.Website  = 'www.theknot.com';
            insert testLead;

            Campaign testCam = new Campaign();
            testCam.Notify_Sales_Team__c = true;
            testCam.Type = 'Paid Media';
            testCam.Name = 'Test Campaign';
            insert testCam;

            CampaignMember testCamMem = new CampaignMember();
            testCamMem.CampaignId = testCam.Id;
            testCamMem.LeadId = testLead.Id;
            // testCamMem.Name = 'test';
            insert testCamMem;

            update testCamMem;

            delete testCamMem;
        test.stopTest();
        
    }

    static testMethod void testMethod2() {
        test.startTest();
            Account testAcc = TestClassUtility.createAccount(false);
            testAcc.DE_Backlog__c = true;
            insert testAcc;

            Contact testCon = TestClassUtility.createContact(true, testAcc);

            Campaign testCam = new Campaign();
            testCam.Notify_Sales_Team__c = true;
            testCam.Name = 'Test Campaign';
            testCam.Type = 'Paid Media';
            insert testCam;

            CampaignMember testCamMem = new CampaignMember();
            testCamMem.CampaignId = testCam.Id;
            testCamMem.ContactId = testCon.Id;
            // testCamMem.Name = 'test';
            insert testCamMem;

            update testCamMem;

            delete testCamMem;
        test.stopTest();
        
    }

    static testMethod void testMethod3() {
        test.startTest();
            lead testLead = TestClassUtility.createLead(false);
            testLead.Negative_Disposition_Reason__c = 'Duplicate';
            testLead.Status = 'Invalid';
            testLead.Website  = 'www.theknot.com';
            insert testLead;

            Campaign testCam = new Campaign();
            testCam.Type = 'Paid Media';
            testCam.Name = 'Test Campaign';
            insert testCam;

            CampaignMember testCamMem = new CampaignMember();
            testCamMem.CampaignId = testCam.Id;
            testCamMem.LeadId = testLead.Id;
            // testCamMem.Name = 'test';
            insert testCamMem;

            update testCamMem;

            delete testCamMem;
        test.stopTest();
        
    }

    static testMethod void testMethod4() {
        test.startTest();
            lead testLead = TestClassUtility.createLead(false);
            testLead.DE_Backlog__c = true;
            testLead.Negative_Disposition_Reason__c = 'Duplicate';
            testLead.Status = 'Invalid';
            testLead.Website  = 'www.theknot.com';
            insert testLead;

            Campaign testCam = new Campaign();
            testCam.Notify_Sales_Team__c = true;
            testCam.Type = 'Other';
            testCam.Name = 'Test Campaign';
            insert testCam;

            CampaignMember testCamMem = new CampaignMember();
            testCamMem.CampaignId = testCam.Id;
            testCamMem.LeadId = testLead.Id;
            // testCamMem.Name = 'test';
            insert testCamMem;

            update testCamMem;

            delete testCamMem;
        test.stopTest();
        
    }

    static testMethod void testMethod5() {
        test.startTest();
            Account testAcc = TestClassUtility.createAccount(false);
            testAcc.Account_Status__c = 'Qualified';
            testAcc.DE_Backlog__c = true;
            insert testAcc;
            Contact testCon = TestClassUtility.createContact(false, testAcc);
            testCon.FirstName = 'Siva';
            testCon.LastName = 'Vankadaru';
            insert testCon;

            Campaign testCam = new Campaign();
            testCam.Notify_Sales_Team__c = true;
            testCam.Name = 'Test Campaign';
            testCam.Status = 'Responded';
            testCam.Type = 'Internal Referral';
            insert testCam;

            CampaignMember testCamMem = new CampaignMember();
            testCamMem.CampaignId = testCam.Id;
            testCamMem.ContactId = testCon.Id;
            testCamMem.Status = 'Responded';
            //testCamMem.HasResponded = true;
            // testCamMem.Name = 'test';
            insert testCamMem;

            update testCamMem;

            //Account camMemberAcc = testCamMem.Contact.Account;
            //camMemberAcc = CampaignMemberTriggerHandler.accOwnerAssignment(camMemberAcc);

            delete testCamMem;

        test.stopTest();
        
    }

    static testMethod void testMethod6() {
        test.startTest();
            Account testAcc = TestClassUtility.createAccount(false);
            testAcc.Account_Status__c = 'Qualified';
            testAcc.DE_Backlog__c = true;
            insert testAcc;

            Contact testCon = TestClassUtility.createContact(true, testAcc);

            Campaign testCam = new Campaign();
            testCam.Notify_Sales_Team__c = true;
            testCam.Name = 'Test Campaign';
            testCam.Type = 'Internal Referral';
            insert testCam;

            CampaignMember testCamMem = new CampaignMember();
            testCamMem.CampaignId = testCam.Id;
            testCamMem.ContactId = testCon.Id;
            // testCamMem.Name = 'test';
            insert testCamMem;

            testCamMem.Status = 'Responded';
            update testCamMem;

            delete testCamMem;
        test.stopTest();
        
    }


}