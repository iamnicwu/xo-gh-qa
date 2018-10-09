@isTest
private class JavascriptButtonServiceTest {
    
  static testMethod void validateSignature1() {

    Map<String, SObject> testObjects =TestClassUtility.buildLocalData(false);

    test.startTest();

    Account testAcc = (Account)testObjects.get('Account');
    Opportunity testOpp = (Opportunity)testObjects.get('Opportunity');
    Contact testContact = (Contact)testObjects.get('Contact');
    Zuora__CustomerAccount__c testBillingAccount = (Zuora__CustomerAccount__c)testObjects.get('Zuora__CustomerAccount__c');

    Map<String, SObject> testSubObjects = TestClassUtility.buildSubscriptionData(testAcc, testContact, testOpp, testBillingAccount);

    String eStdTemplateName = 'Local Amendment Agreement Template 20160127';
    echosign_dev1__Agreement_Template__c eStdTemplate = new echosign_dev1__Agreement_Template__c();
    eStdTemplate.Name = eStdTemplateName;
    eStdTemplate.echosign_dev1__Name__c = eStdTemplateName;
    eStdTemplate.echosign_dev1__Active__c = true;
    insert eStdTemplate;
    
    zqu__Quote__c testQuote = (zqu__Quote__c)testSubObjects.get('zqu__Quote__c');
    testQuote.zqu__SubscriptionType__c= 'Amend Subscription';
    testQuote.zqu__TermStartDate__c = DateUtility.AddBusinessDays(Date.today(), 4);
    update testQuote;
    
    testOpp.Contract_Signer__c = testContact.id;
    update testOpp;

    JavascriptButtonService.validateSignatureProceed(testOpp.Id);
    test.stopTest();

  }

  static testMethod void validateSignature2() {

    Map<String, SObject> testObjects =TestClassUtility.buildLocalData(true);

    test.startTest();
    String eStdTemplateName = 'Local Standard Agreement Template 20170524';
    echosign_dev1__Agreement_Template__c eStdTemplate = new echosign_dev1__Agreement_Template__c();
    eStdTemplate.Name = eStdTemplateName;
    eStdTemplate.echosign_dev1__Name__c = eStdTemplateName;
    eStdTemplate.echosign_dev1__Active__c = true;
    insert eStdTemplate;
    
    zqu__Quote__c testQuote = (zqu__Quote__c)testObjects.get('zqu__Quote__c');
    testQuote.zqu__SubscriptionType__c= 'New Subscription';
    testQuote.zqu__TermStartDate__c = DateUtility.AddBusinessDays(Date.today(), 4);
    update testQuote;

    Opportunity testOpp = (Opportunity)testObjects.get('Opportunity');
    Contact testContact = (Contact)testObjects.get('Contact');
    testOpp.Contract_Signer__c = testContact.id;
    update testOpp;
    
    JavascriptButtonService.validateSignatureProceed(testOpp.Id);
    test.stopTest();

  }

  static testMethod void validateSignature3() {

    test.startTest();

    JavascriptButtonService.validateSignatureProceed('');
    JavascriptButtonService.validateSignatureProceed('BAD ID');

    test.stopTest();
  }


  // CSP-1306 Added by Nick Wu
  static testMethod void updateAutoCloseDate() {

    Map<String, SObject> testObjects = TestClassUtility.buildLocalData(true);

    test.startTest();
    JavascriptButtonService.updateAutoCloseDate('');
    JavascriptButtonService.updateAutoCloseDate('BAD ID');    
    Opportunity testOpportunity = (Opportunity)testObjects.get('Opportunity');
    JavascriptButtonService.updateAutoCloseDate(testOpportunity.id);
    test.stopTest();
  }

  static testMethod void updateEchosignExpirationDate(){
    
    Map<String, SObject> testObjects = TestClassUtility.buildLocalData(true);

    test.startTest();
    Opportunity testOpportunity = (Opportunity)testObjects.get('Opportunity');
    JavascriptButtonService.updateEchosignExpirationDate(testOpportunity.id);
    test.stopTest();
  }
}