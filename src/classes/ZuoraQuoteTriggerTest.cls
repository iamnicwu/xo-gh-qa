/* 
<class>
  <name>ZuoraQuoteTriggerTest</name>
  <purpose>For testing save/delete/update events on a Zuora Quote</purpose>
  <created>
    <by>Jonathan Satterfield</by>
    <date>7/22/2015</date>
    <ticket>SF-598, SF-599, SF-601</ticket>
  </created>
</class>
*/
//@isTest//(SeeAllData=True)
@isTest
public class ZuoraQuoteTriggerTest {

    static testMethod void testMethodBeforeInsert() {
        List<User> srUserList = [SELECT Id, SalesRepID__c, ManagerID, Manager.IsActive, Email 
                                    FROM User 
                                    WHERE isActive = True 
                                        AND Manager.IsActive = True 
                                        AND Disallow_Sales_Rep_On_Quotes__c = false LIMIT 20];

        List<User> srUserDSROQList = [SELECT Id, SalesRepID__c, ManagerID, Manager.IsActive, Email 
                                    FROM User 
                                    WHERE isActive = True 
                                        AND Manager.IsActive = True 
                                        AND Disallow_Sales_Rep_On_Quotes__c = TRUE LIMIT 20];

        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        
        Map<String, SObject> testObjects = TestClassUtility.buildZQUTestObjects(false);

        zqu__Quote_Template__c testZquQuoteTemplate = TestClassUtility.createQuoteTemplate(false);
        testZquQuoteTemplate.Name = 'Quote Template for TRX';
        testZquQuoteTemplate.zqu__IsDefault__c = FALSE;
        insert testZquQuoteTemplate;

        Test.startTest();

        Opportunity testOpp = (Opportunity)testObjects.get('Opportunity');
        Contact testContact = (Contact)testObjects.get('Contact');
        Account testAccount = (Account)testObjects.get('Account');

        Contact testErrorContact = TestClassUtility.createContact(false,testAccount);
        testErrorContact.FirstName = '';
        testErrorContact.LastName = 'testLaseName' + TestClassUtility.randomNumber(9);
        testErrorContact.Email = 'test_contact_email2_' + TestClassUtility.randomNumber(99) + '@faketesting' + TestClassUtility.randomNumber(99) + '.com';
        testErrorContact.MailingStreet = TestClassUtility.generateRandomStreet();
        testErrorContact.MailingCity = 'Austin';
        testErrorContact.MailingState = 'Texas';
        testErrorContact.MailingCountry = 'United States';
        testErrorContact.MailingPostalCode = TestClassUtility.generateRandomUSPostalCode();
        testErrorContact.Phone = TestClassUtility.randomNumber(9) + '98765432' + TestClassUtility.randomNumber(9);
        insert testErrorContact;
        // insert Internet New Sub Quote
        zqu__Quote__c testZquQuote = TestClassUtility.createQuote(false,testOpp,testAccount,testContact);
        testZquQuote.zqu__SoldToContact__c = testErrorContact.Id;
        testZquQuote.zqu__BillToContact__c = testErrorContact.Id;
        testZquQuote.zqu__TermStartDate__c = Date.today().adddays(-1);
        testZquQuote.SalesRepLookup__c = srUserDSROQList[0].id;
        testZquQuote.Reporting_Rep__c = srUserDSROQList[0].id;
        testZquQuote.RenewalRepLookup__c = srUserDSROQList[0].id;
        testZquQuote.AutoRenewal__c = 'YES';
        testZquQuote.Product_Line__c = 'Print';
        try{
            insert testZquQuote;
        }catch(Exception e){}

        testZquQuote.zqu__SoldToContact__c = testContact.Id;
        testZquQuote.zqu__BillToContact__c = testContact.Id;
        testZquQuote.zqu__TermStartDate__c = Date.today().adddays(1);
        testZquQuote.SalesRepLookup__c = srUserList[0].id;
        testZquQuote.Reporting_Rep__c = srUserList[0].id;
        testZquQuote.RenewalRepLookup__c = srUserList[0].id;
        testZquQuote.Product_Line__c = 'Internet';
        try{
            insert testZquQuote;
        }catch(Exception e){}

        // insert Print Amend sub Quote
        Zuora__Subscription__c testSub = TestClassUtility.createSubscription(false,testAccount);
        testSub.Zuora__Zuora_Id__c = 'subfortestquotetriggerhandler';
        insert testSub;

        zqu__Quote__c testZquQuote1 = TestClassUtility.createQuote(false,testOpp,testAccount,testContact);
        testZquQuote1.zqu__SoldToContact__c = testContact.Id;
        testZquQuote1.zqu__TermStartDate__c = Date.today().adddays(1);
        testZquQuote1.SalesRepLookup__c = srUserList[0].id;
        testZquQuote1.Reporting_Rep__c = srUserList[0].id;
        testZquQuote1.RenewalRepLookup__c = srUserList[0].id;
        testZquQuote1.Product_Line__c = 'Print';
        testZquQuote1.zqu__SubscriptionType__c = 'Amend Subscription';
        testZquQuote1.zqu__ExistSubscriptionID__c = 'subfortestquotetriggerhandler';
        testZquQuote1.zqu__PaymentMethod__c = 'ACH';
        insert testZquQuote1;

        // insert transactions cancel sub quote
        zqu__Quote__c testZquQuote2 = TestClassUtility.createQuote(false,testOpp,testAccount,testContact);
        testZquQuote2.zqu__SoldToContact__c = testContact.Id;
        testZquQuote2.zqu__TermStartDate__c = Date.today().adddays(1);
        testZquQuote2.SalesRepLookup__c = srUserList[0].id;
        testZquQuote2.Reporting_Rep__c = srUserList[0].id;
        testZquQuote2.RenewalRepLookup__c = srUserList[0].id;
        testZquQuote2.Product_Line__c = 'transactions';
        testZquQuote2.zqu__SubscriptionType__c = 'Cancel Subscription';
        testZquQuote2.zqu__ExistSubscriptionID__c = 'subfortestquotetriggerhandler';
        insert testZquQuote2;

        // insert transactions new sub quote
        zqu__Quote__c testZquQuote3 = TestClassUtility.createQuote(false,testOpp,testAccount,testContact);
        testZquQuote3.zqu__SoldToContact__c = testContact.Id;
        testZquQuote3.zqu__TermStartDate__c = Date.today().adddays(1);
        testZquQuote3.SalesRepLookup__c = srUserList[0].id;
        testZquQuote3.Reporting_Rep__c = srUserList[0].id;
        testZquQuote3.RenewalRepLookup__c = srUserList[0].id;
        testZquQuote3.Product_Line__c = 'transactions';
        testZquQuote3.zqu__SubscriptionType__c = 'New Subscription';
        testZquQuote3.zqu__ExistSubscriptionID__c = 'subfortestquotetriggerhandler';
        insert testZquQuote3;

        Test.stopTest();
    }

    static testMethod void testUpdateMethodOne() {
        TestClassUtility.DISABLE_TRIGGERS = TRUE;
        List<User> srUserList = [SELECT Id, SalesRepID__c, ManagerID, Manager.IsActive, Email 
                                    FROM User 
                                    WHERE isActive = True 
                                        AND Manager.IsActive = True 
                                        AND Disallow_Sales_Rep_On_Quotes__c = false LIMIT 20];

        List<User> srUserDSROQList = [SELECT Id, SalesRepID__c, ManagerID, Manager.IsActive, Email 
                                    FROM User 
                                    WHERE isActive = True 
                                        AND Manager.IsActive = True 
                                        AND Disallow_Sales_Rep_On_Quotes__c = TRUE LIMIT 20];

        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        
        Map<String, SObject> testObjects = TestClassUtility.buildZQUTestObjects(false);

        zqu__Quote_Template__c testZquQuoteTemplate = TestClassUtility.createQuoteTemplate(false);
        testZquQuoteTemplate.Name = 'Quote Template for TRX';
        testZquQuoteTemplate.zqu__IsDefault__c = FALSE;
        insert testZquQuoteTemplate;
        

        

        Opportunity testOpp = (Opportunity)testObjects.get('Opportunity');
        Contact testContact = (Contact)testObjects.get('Contact');
        Account testAccount = (Account)testObjects.get('Account');

        Contact testErrorContact = TestClassUtility.createContact(false,testAccount);
        testErrorContact.FirstName = '';
        testErrorContact.LastName = 'testLaseName' + TestClassUtility.randomNumber(9);
        testErrorContact.Email = 'test_contact_email2_' + TestClassUtility.randomNumber(99) + '@faketesting' + TestClassUtility.randomNumber(99) + '.com';
        testErrorContact.MailingStreet = TestClassUtility.generateRandomStreet();
        testErrorContact.MailingCity = 'Austin';
        testErrorContact.MailingState = 'Texas';
        testErrorContact.MailingCountry = 'United States';
        testErrorContact.MailingPostalCode = TestClassUtility.generateRandomUSPostalCode();
        testErrorContact.Phone = TestClassUtility.randomNumber(9) + '98765432' + TestClassUtility.randomNumber(9);
        insert testErrorContact;
        // insert Internet New Sub Quote
        TestClassUtility.DISABLE_TRIGGERS = FALSE;
        Test.startTest();
        zqu__Quote__c testZquQuote = TestClassUtility.createQuote(false,testOpp,testAccount,testContact);

        testZquQuote.zqu__SoldToContact__c = testContact.Id;
        testZquQuote.zqu__BillToContact__c = testContact.Id;
        testZquQuote.zqu__TermStartDate__c = Date.today().adddays(1);
        testZquQuote.SalesRepLookup__c = srUserList[0].id;
        testZquQuote.Reporting_Rep__c = srUserList[0].id;
        testZquQuote.RenewalRepLookup__c = srUserList[0].id;
        testZquQuote.Product_Line__c = 'Internet';
        testZquQuote.zqu__ElectronicPaymentMethodId__c = 'testElectronicPaymentMethodId';
        insert testZquQuote;
        TestClassUtility.DISABLE_TRIGGERS = TRUE;
        // zqu__ProductRatePlan__c testPRP = TestClassUtility.
        zqu__QuoteAmendment__c testQAmendment = TestClassUtility.createQuoteAmendment(true,testZquQuote);

        zqu__QuoteRatePlan__c testQRP = TestClassUtility.createQuoteRatePlan(false);
        testQRP.zqu__QuoteAmendment__c = testQAmendment.id;
        testQRP.zqu__Quote__c = testZquQuote.Id;
        insert testQRP;

        zqu__ProductRatePlanCharge__c testPRPC = TestClassUtility.createProductRatePlanCharge(true);

        list<zqu__QuoteRatePlanCharge__c> testQRPCList = new list<zqu__QuoteRatePlanCharge__c>();
        zqu__QuoteRatePlanCharge__c  testQRPC = TestClassUtility.createQuoteRatePlanCharge(false,testQRP,testPRPC);
        testQRPCList.add(testQRPC);
        zqu__QuoteRatePlanCharge__c testQRPC1 = TestClassUtility.createQuoteRatePlanCharge(false,testQRP,testPRPC);
        testQRPC1.zqu__EffectivePrice__c = 10;
        testQRPCList.add(testQRPC1);
        zqu__QuoteRatePlanCharge__c testQRPC2 = TestClassUtility.createQuoteRatePlanCharge(false,testQRP,testPRPC);
        testQRPC2.zqu__EffectivePrice__c = 10;
        testQRPCList.add(testQRPC2);
        insert testQRPCList;
        TestClassUtility.DISABLE_TRIGGERS = FALSE;

        testZquQuote.True_TCV__c = 10;
        testZquQuote.SalesRepLookup__c = srUserDSROQList[1].id;
        testZquQuote.Reporting_Rep__c = srUserDSROQList[1].id;
        testZquQuote.RenewalRepLookup__c = srUserDSROQList[1].id;
        testZquQuote.zqu__ValidUntil__c = Date.Today().addDays(10);
        testZquQuote.zqu__ElectronicPaymentMethodId__c = 'testElectronicPaymentMethodId1';
        testZquQuote.zqu__PaymentMethod__c = 'ACH';
        try{
          update testZquQuote;
        }catch(Exception e){}
        
        TestClassUtility.DISABLE_TRIGGERS = TRUE;
        Zuora__Subscription__c testSub = TestClassUtility.createSubscription(false,testAccount);
        testSub.Zuora__Zuora_Id__c = 'subfortestquotetriggerhandler';
        testSub.AutoRenewal__c = 'YES';
        insert testSub;

        Zuora__Product__c testProduct = TestClassUtility.createZuoraProduct(True);
        Zuora__SubscriptionProductCharge__c testSubProductCharge = TestClassUtility.createSubscriptionProductCharge(false,testAccount,testSub,testProduct);
        insert testSubProductCharge;
        TestClassUtility.DISABLE_TRIGGERS = FALSE;
        testZquQuote.zqu__ExistSubscriptionID__c = 'subfortestquotetriggerhandler';
        testZquQuote.zqu__SubscriptionType__c = 'Amend Subscription';
        testZquQuote.Product_Line__c = 'transactions';
        testZquQuote.SalesRepLookup__c = srUserList[1].id;
        testZquQuote.Reporting_Rep__c = srUserList[1].id;
        testZquQuote.RenewalRepLookup__c = srUserList[0].id;
        testZquQuote.zqu__ValidUntil__c = Date.Today().addDays(10);
        testZquQuote.zqu__Status__c = 'Sent to Z-Billing';
        testZquQuote.Subscription_Being_Renewed__c = testSub.id;
        update testZquQuote;

        ZuoraQuoteTriggerHandler.UpdatePotentialValueOfOpportunity(testOpp.id);
        delete testZquQuote;
        Test.stopTest();
    }
    
}