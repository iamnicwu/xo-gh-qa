@isTest
private class RenewalDashboardControllerTest{


    private static testmethod void test_method_one() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Generate_Quote_Pdf_Config__c gcr = TestClassUtility.generateQuotePdfConfig(true);

        Test.startTest();
            Map<String, SObject> testData =TestClassUtility.buildLocalSubscriptionData();
        Test.stopTest();

        RenewalDashboardController rdc = new RenewalDashboardController();
        rdc.expiringDateQuote = null;
        rdc.renewalRepName = '';
        rdc.ascOrDesc = '';
        rdc.opportunityInfos = null;
        rdc.subscriptionId = '';
        rdc.getsubscriptionProductLineList();
        rdc.getsubscriptionTermStatusList();
        rdc.getvipCheckStatusList();
        Opportunity testOpp1 = rdc.opportunityInfos;
        rdc.getsubscriptionStatusList();
        rdc.getOwnershipScopeList();
        rdc.expiringDateQuote.zqu__StartDate__c = date.today();
        rdc.expiringDateQuote.zqu__TermStartDate__c = date.today();
        rdc.goSearch();
        rdc.expiringDateQuote.zqu__StartDate__c = date.today().adddays(-1);
        rdc.expiringDateQuote.zqu__TermStartDate__c = date.today();
        rdc.goSearch();
        Opportunity testOpp = (Opportunity)testData.get('Opportunity');
        testOpp.Type = 'Renewal';
        update testOpp;
        rdc.subscriptionTermStatus = 'Services less than 12 months';
        rdc.ownershipScope  = 'All subscriptions';
        rdc.subscriptionStatus = 'Removed';
        rdc.vipCheckStatus = 'VIP';
        rdc.pageNumber = 2;
        rdc.Previous();
        rdc.expiringDateQuote.RenewalRepLookup__c = UserInfo.getUserId();
        rdc.subscriptionProductLine = 'Internet';
        rdc.subscriptionStatus = 'Not Renewed';
        rdc.Next();
        rdc.End();
    }


    private static testmethod void test_method_seven() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Generate_Quote_Pdf_Config__c gcr = TestClassUtility.generateQuotePdfConfig(true);

        Test.startTest();

            Map<String, SObject> testData =TestClassUtility.buildLocalSubscriptionData();
            Zuora__Subscription__c testSub = (Zuora__Subscription__c)testData.get('Zuora__Subscription__c');
            testSub.Zuora__TermStartDate__c = Date.Today();
            testSub.Zuora__TermEndDate__c = Date.Today() + 365;
            update testsub;

        Test.stopTest();

        RenewalDashboardController rdc = new RenewalDashboardController();
        rdc.expiringDateQuote = null;
        rdc.renewalRepName = '';
        rdc.ascOrDesc = '';
        rdc.opportunityInfos = null;
        rdc.subscriptionId = '';
        rdc.getsubscriptionProductLineList();
        rdc.getvipCheckStatusList();
        rdc.getsubscriptionTermStatusList();
        Opportunity testOpp1 = rdc.opportunityInfos;
        rdc.getsubscriptionStatusList();
        rdc.getOwnershipScopeList();
        Opportunity testOpp = (Opportunity)testData.get('Opportunity');
        testOpp.Type = 'Renewal';
        testOpp.StageName = 'Closed Lost';
        testOpp.Lost_Reason__c = 'Moved';
        testOpp.Renew_Subscription__c = testSub.id;
        update testOpp;        
        rdc.expiringDateQuote.zqu__StartDate__c = date.today().adddays(-1);
        rdc.expiringDateQuote.zqu__TermStartDate__c = date.today().adddays(500);
        system.debug('testsub : ' + testsub);
        system.debug('testOpp : ' + testOpp);
        rdc.goSearch();
        rdc.subscriptionTermStatus = 'Services less than 12 months';
        rdc.ownershipScope  = 'My team\'s subscriptions';
        rdc.subscriptionStatus = 'Removed';
        rdc.vipCheckStatus = 'Non-VIP';
        rdc.pageNumber = 2;
        rdc.Beginning();
        rdc.Previous();
        rdc.expiringDateQuote.RenewalRepLookup__c = null;
        rdc.subscriptionProductLine = 'Internet';
        rdc.subscriptionStatus = 'Not Renewed';
        rdc.Next();
        rdc.End();
    }


    private static testmethod void test_method_eight() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Generate_Quote_Pdf_Config__c gcr = TestClassUtility.generateQuotePdfConfig(true);

        Test.startTest();

            Map<String, SObject> testData =TestClassUtility.buildLocalSubscriptionData();
            Zuora__Subscription__c testSub = (Zuora__Subscription__c)testData.get('Zuora__Subscription__c');
            testSub.Zuora__TermStartDate__c = Date.Today();
            testSub.Zuora__TermEndDate__c = Date.Today() + 365;
            update testsub;

        Test.stopTest();

        RenewalDashboardController rdc = new RenewalDashboardController();
        rdc.expiringDateQuote = null;
        rdc.renewalRepName = '';
        rdc.ascOrDesc = '';
        rdc.opportunityInfos = null;
        rdc.subscriptionId = '';
        rdc.getsubscriptionProductLineList();
        rdc.getvipCheckStatusList();
        rdc.getsubscriptionTermStatusList();
        Opportunity testOpp1 = rdc.opportunityInfos;
        rdc.getsubscriptionStatusList();
        rdc.getOwnershipScopeList();
        Opportunity testOpp = (Opportunity)testData.get('Opportunity');
        testOpp.Type = 'Renewal';
        testOpp.StageName = 'Qualifying';
        testOpp.Renew_Subscription__c = testSub.id;
        update testOpp;        
        rdc.expiringDateQuote.zqu__StartDate__c = date.today().adddays(-1);
        rdc.expiringDateQuote.zqu__TermStartDate__c = date.today().adddays(500);
        system.debug('testsub : ' + testsub);
        system.debug('testOpp : ' + testOpp);
        rdc.goSearch();
        rdc.subscriptionTermStatus = 'Services less than 12 months';
        rdc.ownershipScope  = 'My team\'s subscriptions';
        rdc.subscriptionStatus = 'Removed';
        rdc.vipCheckStatus = 'ALL';
        rdc.pageNumber = 2;
        rdc.Beginning();
        rdc.Previous();
        rdc.expiringDateQuote.RenewalRepLookup__c = null;
        rdc.subscriptionProductLine = 'Internet';
        rdc.subscriptionStatus = 'Not Renewed';
        rdc.Next();
        rdc.End();
    }


    private static testmethod void test_method_nine() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Generate_Quote_Pdf_Config__c gcr = TestClassUtility.generateQuotePdfConfig(true);

        Test.startTest();

            Map<String, SObject> testData =TestClassUtility.buildLocalSubscriptionData();
            Zuora__Subscription__c testSub = (Zuora__Subscription__c)testData.get('Zuora__Subscription__c');
            testSub.Zuora__TermStartDate__c = Date.Today();
            testSub.Zuora__TermEndDate__c = Date.Today() + 365;
            update testsub;

        Test.stopTest();

        RenewalDashboardController rdc = new RenewalDashboardController();
        rdc.expiringDateQuote = null;
        rdc.renewalRepName = '';
        rdc.ascOrDesc = '';
        rdc.opportunityInfos = null;
        rdc.subscriptionId = '';
        rdc.getsubscriptionProductLineList();
        rdc.getvipCheckStatusList();
        rdc.getsubscriptionTermStatusList();
        Opportunity testOpp1 = rdc.opportunityInfos;
        rdc.getsubscriptionStatusList();
        rdc.getOwnershipScopeList();
        Opportunity testOpp = (Opportunity)testData.get('Opportunity');
        testOpp.Type = 'Renewal';
        testOpp.StageName = 'Qualifying';
        testOpp.Renew_Subscription__c = testSub.id;
        update testOpp;        
        rdc.expiringDateQuote.zqu__StartDate__c = date.today().adddays(-1);
        rdc.expiringDateQuote.zqu__TermStartDate__c = date.today().adddays(500);
        system.debug('testsub : ' + testsub);
        system.debug('testOpp : ' + testOpp);
        rdc.subscriptionTermStatus = 'Services less than 12 months';
        rdc.ownershipScope  = 'My team\'s subscriptions';
        rdc.subscriptionStatus = 'Renewed';
        rdc.goSearch();
        rdc.vipCheckStatus = 'VIP';
        rdc.pageNumber = 2;
        rdc.Beginning();
        rdc.Previous();
        rdc.expiringDateQuote.RenewalRepLookup__c = null;
        rdc.subscriptionProductLine = 'Internet';
        rdc.subscriptionStatus = 'Not Renewed';
        rdc.Next();
        rdc.End();
    }


    private static testmethod void test_method_ten() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Generate_Quote_Pdf_Config__c gcr = TestClassUtility.generateQuotePdfConfig(true);

        Test.startTest();

            Map<String, SObject> testData =TestClassUtility.buildLocalSubscriptionData();
            Zuora__Subscription__c testSub = (Zuora__Subscription__c)testData.get('Zuora__Subscription__c');
            testSub.Zuora__TermStartDate__c = Date.Today();
            testSub.Zuora__TermEndDate__c = Date.Today() + 365;
            update testsub;

        Test.stopTest();

        RenewalDashboardController rdc = new RenewalDashboardController();
        rdc.expiringDateQuote = null;
        rdc.renewalRepName = '';
        rdc.ascOrDesc = '';
        rdc.opportunityInfos = null;
        rdc.subscriptionId = '';
        rdc.getsubscriptionProductLineList();
        rdc.getvipCheckStatusList();
        rdc.getsubscriptionTermStatusList();
        Opportunity testOpp1 = rdc.opportunityInfos;
        rdc.getsubscriptionStatusList();
        rdc.getOwnershipScopeList();
        Opportunity testOpp = (Opportunity)testData.get('Opportunity');
        testOpp.Type = 'Renewal';
        testOpp.StageName = 'Qualifying';
        testOpp.Renew_Subscription__c = testSub.id;
        update testOpp;        
        rdc.expiringDateQuote.zqu__StartDate__c = date.today().adddays(-1);
        rdc.expiringDateQuote.zqu__TermStartDate__c = date.today().adddays(500);
        system.debug('testsub : ' + testsub);
        system.debug('testOpp : ' + testOpp);
        rdc.subscriptionTermStatus = 'Without services less than 12 months';
        rdc.ownershipScope  = 'My team\'s subscriptions';
        rdc.subscriptionStatus = 'Renewed';
        rdc.goSearch();
        rdc.vipCheckStatus = 'Non-VIP';
        rdc.pageNumber = 2;
        rdc.Beginning();
        rdc.Previous();
        rdc.expiringDateQuote.RenewalRepLookup__c = null;
        rdc.subscriptionProductLine = 'Internet';
        rdc.subscriptionStatus = 'Not Renewed';
        rdc.Next();
        rdc.End();
    }

    
    private static testmethod void test_method_two() {

        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Generate_Quote_Pdf_Config__c gcr = TestClassUtility.generateQuotePdfConfig(true);

        Test.startTest();

            Map<String, SObject> testData =TestClassUtility.buildLocalSubscriptionData();
            Zuora__Subscription__c testSub = (Zuora__Subscription__c)testData.get('Zuora__Subscription__c');

        Test.stopTest();
        
        RenewalDashboardController rdc = new RenewalDashboardController();
        zqu__Quote__c testQuote = (zqu__Quote__c)testData.get('zqu__Quote__c');
        rdc.renewalRepName = '';
        rdc.ascOrDesc = '';
        rdc.opportunityInfos = null;
        rdc.subscriptionId = '';
        rdc.getsubscriptionProductLineList();
        rdc.getvipCheckStatusList();
        rdc.getsubscriptionTermStatusList();
        Opportunity testOpp1 = rdc.opportunityInfos;
        Opportunity testOpp = (Opportunity)testData.get('Opportunity');
        testOpp.Renew_Subscription__c = testSub.id;
        testOpp.Type = 'Renewal';
        testOpp.StageName = 'Closed Lost';
        testOpp.Lost_Reason__c = 'Moved';
        update testOpp;
        rdc.expiringDateQuote.zqu__TermStartDate__c = date.today().adddays(500);
        rdc.subscriptionTermStatus = 'Without services less than 12 months';
        rdc.ownershipScope  = 'My team\'s subscriptions';
        rdc.subscriptionStatus = 'Renewed';
        testQuote.zqu__Hidden_Subscription_Name__c = testSub.Name;
        testQuote.zqu__SubscriptionType__c = 'Renew Subscription';
        update testQuote;

    }

    private static testmethod void test_method_three() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Generate_Quote_Pdf_Config__c gcr = TestClassUtility.generateQuotePdfConfig(true);
        
        Test.startTest();

            Map<String, SObject> testData =TestClassUtility.buildLocalSubscriptionData();
            zqu__Quote__c testQuote = (zqu__Quote__c)testData.get('zqu__Quote__c');
            testQuote.zqu__SubscriptionType__c = 'Renew Subscription';
            update testQuote;
            Zuora__Subscription__c testSub = (Zuora__Subscription__c)testData.get('Zuora__Subscription__c');

        Test.stopTest();
        
        RenewalDashboardController rdc = new RenewalDashboardController();
        rdc.goRemove();        
        rdc.subscriptionId = testSub.id;
        rdc.opportunityInfos.Lost_Reason__c = 'Moved';
        rdc.goRemove();
        rdc.GoRenew();
    }

    
    private static testmethod void test_method_four() {
        
        
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        
        


        Generate_Quote_Pdf_Config__c gcr = TestClassUtility.generateQuotePdfConfig(true);
        
        Test.startTest();

            Map<String, SObject> testData =TestClassUtility.buildLocalSubscriptionData();
            zqu__Quote__c testQuote = (zqu__Quote__c)testData.get('zqu__Quote__c');
            testQuote.zqu__SubscriptionType__c = 'Renew Subscription';
            update testQuote;

        Test.stopTest();






        List<user> userList = [SELECT Id, Name, SalesRepID__c FROM User WHERE IsActive = true AND SalesRepID__c != null AND Disallow_Sales_Rep_On_Quotes__c = false LIMIT 2];
        Zuora__Subscription__c testSub = (Zuora__Subscription__c)testData.get('Zuora__Subscription__c');
        testSub.Zuora__TermEndDate__c = date.today().addmonths(1);
        testSub.Zuora__TermStartDate__c= date.today().adddays(1);
        testSub.Renewal_Rep__c = userList[0].Id;
        testSub.RenewalRepId__c = userList[0].SalesRepID__c;
        testSub.Zuora__TCV__c = 10;
        testSub.Zuora__MRR__c = 8;
        testSub.Zuora__AutoRenew__c = true;
        update testSub;
        
        Account testAccount = (Account)testData.get('Account');
        Zuora__Subscription__c testZquSubscription = TestClassUtility.createSubscription(true,testAccount);
        testZquSubscription.Zuora__Zuora_Id__c = 'abc123';
        testZquSubscription.OriginalSalesforceQuoteID__c = testQuote.Id;
        testZquSubscription.Zuora__TermEndDate__c = date.today().addmonths(2);
        testZquSubscription.Zuora__TermStartDate__c= date.today().adddays(1);
        testZquSubscription.Renewal_Rep__c = userList[1].id;
        testZquSubscription.RenewalRepId__c = userList[1].SalesRepID__c;
        testZquSubscription.Zuora__TCV__c = 11;
        testZquSubscription.Zuora__MRR__c = 5;
        testZquSubscription.Zuora__AutoRenew__c = true;
        update testZquSubscription;
        
        RenewalDashboardController rdc = new RenewalDashboardController();
        rdc.opportunityInfos = NEW opportunity();
        rdc.OwnershipScope = 'All subscriptions';
        rdc.goSearch();
        
        rdc.RenewalRepName = userList[1].name;
        rdc.columnName = 'SubscriptionName';
        rdc.ascOrDesc = '';
        rdc.cancelAndRefresh();
        List<subsentityWrapper> slist = new List<subsentityWrapper>();
        Opportunity testOpp = (Opportunity)testData.get('Opportunity');
        subsentityWrapper subw = new subsentityWrapper(testSub,false,false,'OppStageName',testOpp.Id,0,0,'AutoRenew');
        subsentityWrapper subw1 = new subsentityWrapper(testZquSubscription,false,false,'OppStageName',testOpp.ID, 0, 0,'AutoRenew');
        slist.add(subw);
        slist.add(subw1);
        slist.sort();
        
        subsentityWrapper.sortBy = 'SubscriptionName';
        subsentityWrapper.ASCORDESC = 'ASC';
        slist.sort();
        subsentityWrapper.ASCORDESC = 'DESC';
        slist.sort();
        
        subsentityWrapper.sortBy = 'Account';
        subsentityWrapper.ASCORDESC = 'DESC';
        slist.sort();
        subsentityWrapper.ASCORDESC = 'ASC';
        slist.sort();
        
        subsentityWrapper.sortBy = 'ReportingRep';
        subsentityWrapper.ASCORDESC = 'DESC';
        slist.sort();
        subsentityWrapper.ASCORDESC = 'ASC';
        slist.sort();
        
        subsentityWrapper.sortBy = 'RenewalRep';
        subsentityWrapper.ASCORDESC = 'DESC';
        slist.sort();
        subsentityWrapper.ASCORDESC = 'ASC';
        slist.sort();
        
        subsentityWrapper.sortBy = 'TermStartDate';
        subsentityWrapper.ASCORDESC = 'DESC';
        slist.sort();
        subsentityWrapper.ASCORDESC = 'ASC';
        slist.sort();
        
        subsentityWrapper.sortBy = 'TermEndDate';
        subsentityWrapper.ASCORDESC = 'ASC';
        slist.sort();
        subsentityWrapper.ASCORDESC = 'DESC';
        slist.sort();

        subsentityWrapper.sortBy = 'Total';
        subsentityWrapper.ASCORDESC = 'ASC';
        slist.sort();
        subsentityWrapper.ASCORDESC = 'DESC';
        slist.sort();
        
        subsentityWrapper.sortBy = 'MonthlyRate';
        subsentityWrapper.ASCORDESC = 'ASC';
        slist.sort();
        subsentityWrapper.ASCORDESC = 'DESC';
        slist.sort();
        
        subsentityWrapper.sortBy = 'AutoRenew';
        subsentityWrapper.ASCORDESC = 'ASC';
        slist.sort();
        subsentityWrapper.ASCORDESC = 'DESC';
        slist.sort();

        subsentityWrapper.sortBy = 'OpportunityStage';
        subsentityWrapper.ASCORDESC = 'ASC';
        slist.sort();
        subsentityWrapper.ASCORDESC = 'DESC';
        slist.sort();

        subsentityWrapper.sortBy = 'AccountCreditHoldStatus';
        subsentityWrapper.ASCORDESC = 'ASC';
        slist.sort();
        subsentityWrapper.ASCORDESC = 'DESC';
        slist.sort();
    }


    private static testmethod void test_method_five() {
        
        
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        Test.startTest(); 
            Map<String, SObject> localObjects = TestClassUtility.buildLocalData(false);
        Test.stopTest();

        Account testAccount = (Account)localObjects.get('Account');
        Opportunity testOpp = (Opportunity)localObjects.get('Opportunity');

        Zuora__Subscription__c testSubscription1 =  TestClassUtility.createSubscription(false, testAccount);
        Zuora__Subscription__c testSubscription2 =  TestClassUtility.createSubscription(false, testAccount);

        list<User> userList = [SELECT Id, Name FROM User WHERE IsActive = true AND SalesRepID__c != null LIMIT 2];
        testSubscription1.Zuora__TermEndDate__c = date.today().addmonths(1);
        testSubscription1.Zuora__TermStartDate__c= date.today().adddays(1);
        testSubscription1.Renewal_Rep__c = userList[0].Id;
        testSubscription1.Reporting_Rep__c = userList[0].Id;
        testSubscription1.Zuora__TCV__c = 10;
        testSubscription1.Zuora__MRR__c = 8;
        testSubscription1.Zuora__AutoRenew__c = true;
        testSubscription1.Name = 'test1';
        insert testSubscription1;
        
        testSubscription2.Zuora__Zuora_Id__c = 'abc123';
        testSubscription2.Zuora__TermEndDate__c = date.today().addmonths(2);
        testSubscription2.Zuora__TermStartDate__c= date.today().adddays(2);
        testSubscription2.Renewal_Rep__c = userList[1].id;
        testSubscription2.Reporting_Rep__c = userList[1].id;
        testSubscription2.Zuora__TCV__c = 11;
        testSubscription2.Zuora__MRR__c = 5;
        testSubscription2.Zuora__AutoRenew__c = false;
        testSubscription2.Name = 'test2';
        insert testSubscription2;

        List<subsentityWrapper> slist = new List<subsentityWrapper>();
        subsentityWrapper subw = new subsentityWrapper(testSubscription1,false,false,'OppStageName',testOpp.Id,0,0,'AutoRenew');
        subsentityWrapper subw1 = new subsentityWrapper(testSubscription2,false,false,'OppStageName1',testOpp.ID, 0, 0,'AutoRenew');
        slist.add(subw);
        slist.add(subw1);
        slist.sort();
        
        subsentityWrapper.sortBy = 'SubscriptionName';
        subsentityWrapper.ASCORDESC = 'ASC';
        slist.sort();
        subsentityWrapper.ASCORDESC = 'DESC';
        slist.sort();
        
        subsentityWrapper.sortBy = 'Account';
        subsentityWrapper.ASCORDESC = 'DESC';
        slist.sort();
        subsentityWrapper.ASCORDESC = 'ASC';
        slist.sort();
        
        subsentityWrapper.sortBy = 'ReportingRep';
        subsentityWrapper.ASCORDESC = 'DESC';
        slist.sort();
        subsentityWrapper.ASCORDESC = 'ASC';
        slist.sort();
        
        subsentityWrapper.sortBy = 'RenewalRep';
        subsentityWrapper.ASCORDESC = 'DESC';
        slist.sort();
        subsentityWrapper.ASCORDESC = 'ASC';
        slist.sort();
        
        subsentityWrapper.sortBy = 'TermStartDate';
        subsentityWrapper.ASCORDESC = 'DESC';
        slist.sort();
        subsentityWrapper.ASCORDESC = 'ASC';
        slist.sort();
        
        subsentityWrapper.sortBy = 'TermEndDate';
        subsentityWrapper.ASCORDESC = 'ASC';
        slist.sort();
        subsentityWrapper.ASCORDESC = 'DESC';
        slist.sort();

        subsentityWrapper.sortBy = 'Total';
        subsentityWrapper.ASCORDESC = 'ASC';
        slist.sort();
        subsentityWrapper.ASCORDESC = 'DESC';
        slist.sort();
        
        subsentityWrapper.sortBy = 'MonthlyRate';
        subsentityWrapper.ASCORDESC = 'ASC';
        slist.sort();
        subsentityWrapper.ASCORDESC = 'DESC';
        slist.sort();
        
        subsentityWrapper.sortBy = 'AutoRenew';
        subsentityWrapper.ASCORDESC = 'ASC';
        slist.sort();
        subsentityWrapper.ASCORDESC = 'DESC';
        slist.sort();

        subsentityWrapper.sortBy = 'OpportunityStage';
        subsentityWrapper.ASCORDESC = 'ASC';
        slist.sort();
        subsentityWrapper.ASCORDESC = 'DESC';
        slist.sort();

        subsentityWrapper.sortBy = 'AccountCreditHoldStatus';
        subsentityWrapper.ASCORDESC = 'ASC';
        slist.sort();
        subsentityWrapper.ASCORDESC = 'DESC';
        slist.sort();
    }


    private static testmethod void test_method_six() {

        RenewalDashboardController rdc = new RenewalDashboardController();
        rdc.subscriptionId = 'test';
        rdc.getsubscriptionStatusList();
        rdc.getsubscriptionProductLineList();
        rdc.getvipCheckStatusList();
        rdc.getOwnershipScopeList();
        rdc.getsubscriptionTermStatusList();

        RenewalDashboardController.SortData sd = new RenewalDashboardController.SortData('test', 'test');

        try {
            rdc.doSort();
        }
        catch(Exception e) {
            // don't do anything
        }

        rdc.renewalRepName = 'testSUb';
        rdc.columnName = 'TermEndDate';
        rdc.sortMap = new Map<String,RenewalDashboardController.sortData>();
        RenewalDashboardController.sortData testSortData = new RenewalDashboardController.sortData(rdc.columnName,'ASC');

        rdc.sortMap.put(rdc.renewalRepName,testSortData);
        try {
            rdc.doSort();
        }
        catch(Exception e) {
            // don't do anything
        }

        RenewalDashboardController.sortData testSortData1 = new RenewalDashboardController.sortData(rdc.columnName,'DESC');

        rdc.sortMap.put(rdc.renewalRepName,testSortData1);
        try {
            rdc.doSort();
        }
        catch(Exception e) {
            // don't do anything
        }

        RenewalDashboardController.sortData testSortData2 = new RenewalDashboardController.sortData('testColumn','DESC');

        rdc.sortMap.put(rdc.renewalRepName,testSortData2);
        try {
            rdc.doSort();
        }
        catch(Exception e) {
            // don't do anything
        }

    }

}