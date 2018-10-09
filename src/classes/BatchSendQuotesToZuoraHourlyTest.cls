@isTest
private class BatchSendQuotesToZuoraHourlyTest {

  //  static testMethod void testMethod1() {
  //      Map<String,Schema.RecordTypeInfo> rtZQMapByName = Schema.SObjectType.zqu__Quote__c.getRecordTypeInfosByName();
  //      Map<String,SObject> testObjects = TestClassUtility.buildLocalData(false);

  //      Map<String, SObject> testsub = TestClassUtility.buildSubscriptionData((Account)testObjects.get('Account'), 
  //                                                                           (Contact)testObjects.get('Contact'), 
  //                                                                           (Opportunity)testObjects.get('Opportunity') , 
  //                                                                           (Zuora__CustomerAccount__c)testObjects.get('Zuora__CustomerAccount__c'));

  //      SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
  //                                               'Complete',
  //                                               '{"companyName": "Test Account"}',
  //                                               null);
  //      Test.setMock(HttpCalloutMock.class, fakeResponse);
        
  //      Test.startTest();
       
  //      Opportunity testOpportunity = (Opportunity)testObjects.get('Opportunity');
  //      testOpportunity.StageName = 'Client Approved';
  //      testOpportunity.OwnerId = userInfo.getUserId();
  //      update testOpportunity;
  //      System.debug('zqu__Opportunity__c:1'+testOpportunity.Id);
  //      List<zqu__Quote__c>  quotelist = new List<zqu__Quote__c>();

  //      zqu__Quote__c testZquQuote = (zqu__Quote__c)testsub.get('zqu__Quote__c');
  //      testZquQuote.zqu__Status__c = 'New';
  //      testZquQuote.Old_Record_Type__c = String.valueOf(rtZQMapByName.get('Amendment').getRecordTypeId());
  //      testZquQuote.zqu__Service_Activation_Date__c = Date.newinstance(2016, 12, 15);
  //      testZquQuote.zqu__TermStartDate__c= Date.newinstance(2016, 12, 14);
  //      testZquQuote.zqu__BillCycleDay__c='1';
  //      testZquQuote.zqu__Opportunity__c = testOpportunity.Id;
		//quotelist.add(testZquQuote);
  //      update quotelist;
         
  //      zqu__QuoteRatePlan__c qrp = (zqu__QuoteRatePlan__c)TestClassUtility.createQuoteRatePlan(false);
  //      qrp.Location_Vendor__c = ((Account)testObjects.get('Account')).Id;
  //      qrp.zqu__Quote__c = testZquQuote.Id;
  //      qrp.zqu__QuoteAmendment__c =((zqu__QuoteAmendment__c)testsub.get('zqu__QuoteAmendment__c')).Id;
  //      insert qrp;

  //      zqu__QuoteRatePlanCharge__c qrpc = TestClassUtility.createQuoteRatePlanCharge(false,qrp,(zqu__ProductRatePlanCharge__c)testsub.get('zqu__ProductRatePlanCharge__c'));
  //      qrpc.Location_Vendor__c = ((Account)testObjects.get('Account')).Id;
  //      qrpc.LocationVendorDynamicsAccountID__c = 'aed02065-260b-4fb0-925b-f33e8602d202';
  //      insert qrpc;

		//Task_Creation_Settings__c taskCreateSetting = TestClassUtility.createTaskCreationSettings(true,'Error_sending_a_quote_to_Zuora',true);

  //      BatchSendQuotesToZuoraHourly bat = new BatchSendQuotesToZuoraHourly();
  //      bat.sendQuotesToBilling = false ;
  //      Database.executeBatch(bat,50);

  //      BatchSendQuotesToZuoraHourly bat2 = new BatchSendQuotesToZuoraHourly();
  //      bat2.quoteOwnerIdMap.put(testZquQuote.id,testOpportunity.OwnerId);
  //      bat2.failedOppIdSet.add(testOpportunity.id);
  //      bat2.quoteIdToErrorMessageMap.put(testZquQuote.id,'test menthod');
  //      bat2.sendQuotesToBilling = true ;
  //      Database.executeBatch(bat2,50);
        
  //      Test.stopTest();
  //  }

    static testMethod void testMethod2() {
        Map<String,Schema.RecordTypeInfo> rtZQMapByName = Schema.SObjectType.zqu__Quote__c.getRecordTypeInfosByName();
        Map<String,SObject> testObjects = TestClassUtility.buildLocalData(false);
        List<RecordType> localRecordTypeList = [SELECT Id, Name, SObjectType FROM RecordType WHERE Name LIKE '%local%' AND IsActive = true];
        Map<String, Id> localRecordTypeMap = new Map<String, Id>();
        for(Integer i = 0; i < localRecordTypeList.size(); i++) {
          RecordType currentRecordType = localRecordTypeList[i];
          localRecordTypeMap.put(currentRecordType.SObjectType, currentRecordType.Id);
        }

        Test.startTest();
        Map<String, SObject> testsub = TestClassUtility.buildSubscriptionData((Account)testObjects.get('Account'), 
                                                                             (Contact)testObjects.get('Contact'), 
                                                                             (Opportunity)testObjects.get('Opportunity') , 
                                                                             (Zuora__CustomerAccount__c)testObjects.get('Zuora__CustomerAccount__c'));

        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        //Opportunity testOpportunity = (Opportunity)testObjects.get('Opportunity');
        Opportunity testOpportunity = new Opportunity();
        testOpportunity.Name = 'Test Opportunity';
        testOpportunity.StageName = 'Client Approved';
        testOpportunity.Type= 'New';
        testOpportunity.Approval_Process_AR_Assignment__c = false;
        testOpportunity.Approval_Process_Manager_Assignment__c = false;
        testOpportunity.Opportunity_Expiration_Date__c = Date.today().addDays(14);
        testOpportunity.CloseDate = testOpportunity.Opportunity_Expiration_Date__c;
        testOpportunity.Approval_Process_Flag_Skip_EchoSign__c = false;
        testOpportunity.RecordTypeId = localRecordTypeMap.get('Opportunity');
        testOpportunity.OwnerId = userInfo.getUserId();
        insert testOpportunity;
        System.debug('zqu__Opportunity__c:2'+testOpportunity);

        zqu__Quote__c testQuote = new zqu__Quote__c();
        testQuote.Name = 'Test Quote';
        testQuote.zqu__Status__c = 'New';
        testQuote.zqu__Account__c = ((Account)testObjects.get('Account')).Id;
        testQuote.Zqu__ValidUntil__c = Date.Today()-1;
        testQuote.SalesRepLookup__c = userInfo.getUserId();
        testQuote.Reporting_Rep__c = userInfo.getUserId();
        testQuote.zqu__Service_Activation_Date__c = system.today();
        //testQuote.zqu__TermStartDate__c= Date.newinstance(2016, 12, 14);
        testQuote.zqu__BillCycleDay__c='1';
        testQuote.zqu__Opportunity__c = testOpportunity.Id;
        testQuote.Product_Line__c = 'Internet';
        testQuote.zqu__ZuoraAccountID__c = ((Account)testObjects.get('Account')).Id;
        insert testQuote;
        System.debug('testQuote:'+testQuote);

        

        zqu__QuoteRatePlan__c qrp = new zqu__QuoteRatePlan__c();
        qrp.Name = 'Test Rate Plan';
        qrp.zqu__AmendmentType__c = 'New Product'; 
        qrp.zqu__ProductRatePlanZuoraId__c = '2c92c0f94e4d3a3d014e655c28c50f5f'; 
        qrp.zqu__QuoteProductName__c = 'Featured Vendor';
        qrp.Location_Vendor__c = ((Account)testObjects.get('Account')).Id;
        qrp.zqu__Quote__c = testQuote.Id;
        qrp.zqu__QuoteAmendment__c = ((zqu__QuoteAmendment__c)testsub.get('zqu__QuoteAmendment__c')).Id;
        insert qrp;
        System.debug('qrp:'+qrp);

        zqu__QuoteRatePlanCharge__c qrpc = new zqu__QuoteRatePlanCharge__c();
        qrpc.Name = 'Test Quote Rate Plan Charge';
        qrpc.Location_Vendor__c = ((Account)testObjects.get('Account')).Id;
        qrpc.LocationVendorDynamicsAccountID__c = 'aed02065-260b-4fb0-925b-f33e8602d202';
        qrpc.zqu__QuoteRatePlan__c = qrp.Id;
        insert qrpc;
        System.debug('qrpc:'+qrpc);


        Task_Creation_Settings__c taskCreateSetting = TestClassUtility.createTaskCreationSettings(true,'Error_sending_a_quote_to_Zuora',true);

        BatchSendQuotesToZuoraHourly bat = new BatchSendQuotesToZuoraHourly();
        bat.quoteOwnerIdMap.put(testQuote.id,testOpportunity.OwnerId);
        bat.successOppIdSet.add(testOpportunity.id);
        bat.quoteIdToErrorMessageMap.put(testQuote.id,'test menthod');
        bat.sendQuotesToBilling = false ;
        Database.executeBatch(bat,1);

        BatchSendQuotesToZuoraHourly bat2 = new BatchSendQuotesToZuoraHourly();
        bat2.quoteOwnerIdMap.put(testQuote.id,testOpportunity.OwnerId);
        bat2.successOppIdSet.add(testOpportunity.id);
        bat2.quoteIdToErrorMessageMap.put(testQuote.id,'test menthod');
        bat2.sendQuotesToBilling = true ;
        Database.executeBatch(bat2,1);

        Map<id,String>  TestMap = new Map<id,String>();
        TestMap.put(testQuote.Id,'test menthod!');
        bat.createErrorTasks(TestMap);
        
        Test.stopTest();
    }


}