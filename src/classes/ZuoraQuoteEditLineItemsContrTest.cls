@isTest
public class ZuoraQuoteEditLineItemsContrTest{
    private static List<User> userList;
    private static Map<String,Schema.RecordTypeInfo> rtMapByName;
    private static Map<String,Schema.RecordTypeInfo> rtLeadMapByName;
    // CSP-1999 private static Map<String,Schema.RecordTypeInfo> rtBrandMapByName;
    private static Map<String,Schema.RecordTypeInfo> rtOppMapByName;
    private static Deactivate_Trigger__c dtatt;
    private static Generate_Quote_Pdf_Config__c GQPF;
    // CSP-1999 private static Brand__c testBrand;
    private static Region__c testRegion;
    private static Market__c testMarket;
    private static Category__c testCategory;
    private static MetroArea__c ma;
    private static Zip__c zip;

    static testMethod void TestUpdateLocalActiveStatus() {
        Inventory_Hold_Expiry_Date_Offsets__c invHoldExpDate = Inventory_Hold_Expiry_Date_Offsets__c.getOrgDefaults();
        invHoldExpDate.Account_Day_Offset__c = 2;
        upsert invHoldExpDate;
        
        
        createtestData();
        // CSP-1999
        // Account testAccount = TestClassUtility.createAccount(false, testBrand, testCategory, testMarket);
        Account testAccount = TestClassUtility.createAccount(false, testCategory, testMarket);
        testAccount.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
        testAccount.BU__c = 'Local';
        testAccount.Website = 'www.googleasf214.com';
        testAccount.Type = 'Agency';
        testAccount.BillingPostalCode = zip.ZipCode__c;
        testAccount.ShippingPostalCode = zip.ZipCode__c;
        testAccount.Operative_Owner__c = userList[0].Name;
        testAccount.ConciergePrgQua__c = '';
        testAccount.DynamicsAccID__c = 'this15auniquedynamicsid234234';
        insert testAccount;
        
        Test.startTest();
        Contact testContact = TestClassUtility.createContact(false, testAccount);
        testContact.Same_Address_as_Account__c = true;
        insert testContact;
        
        Opportunity testOpportunity = TestClassUtility.createOpportunity(false);
        testOpportunity.Name = 'Test Opportunity';
        testOpportunity.AccountId = testAccount.Id;
        testOpportunity.CloseDate = Date.Today()-10;
        testOpportunity.StageName = 'Prospecting';
        testOpportunity.RecordTypeId = rtOppMapByName.get('Local').getRecordTypeId();
        insert testOpportunity;
        
        Zuora__CustomerAccount__c testZuoraCustomerAccount = TestClassUtility.createCustomerAccount(false, testAccount);
        testZuoraCustomerAccount.Customer_Type__c='ACTIVE';
        testZuoraCustomerAccount.CreditHold__c = 'Yes';
        insert testZuoraCustomerAccount;
        
        zqu__Quote__c testZquQuote = TestClassUtility.createQuote(false, testOpportunity, testAccount, testContact);
        testZquQuote.Zqu__ValidUntil__c = Date.Today()-1;
        testZquQuote.zqu__ExistSubscriptionID__c = 'TestquoteId';        
        insert testZquQuote;
        
        zqu__QuoteAmendment__c testZquQuoteAmendment = TestClassUtility.createQuoteAmendment(true, testZquQuote);
        
        Product2 testProduct = TestClassUtility.createLocalProduct2(true);
        
        zqu__ProductRatePlan__c testZquProductRatePlan = TestClassUtility.createProductRatePlan(false);
        testZquProductRatePlan.zqu__Product__c = testProduct.id; 
        insert testZquProductRatePlan;
        
        zqu__ProductRatePlanCharge__c testZquProductRatePlanCharge = TestClassUtility.createProductRatePlanCharge(false);
        testZquProductRatePlanCharge.zqu__ProductRatePlan__c = testZquProductRatePlan.id; 
        insert testZquProductRatePlanCharge; 
        
        zqu__QuoteRatePlan__c testZquQuoteRatePlan = TestClassUtility.createQuoteRatePlan(false, testZquQuote, testZquProductRatePlan, testZquQuoteAmendment); 
        testZquQuoteRatePlan.zqu__SubscriptionRatePlanZuoraId__c = 'asdasdasdasdas';
        insert testZquQuoteRatePlan;
        
        zqu__QuoteRatePlanCharge__c testZquQuoteRatePlanCharge = TestClassUtility.createQuoteRatePlanCharge(true, testZquQuoteRatePlan, testZquProductRatePlanCharge);
        
        Zuora__Subscription__c testSubscription = TestClassUtility.createSubscription(true, testAccount);
        Zuora__Product__c testZuoraProduct = TestClassUtility.createZuoraProduct(true);
        Zuora__SubscriptionProductCharge__c testSubscriptionProductCharge = TestClassUtility.createSubscriptionProductCharge(false, testAccount, testSubscription,testZuoraProduct);
        testSubscriptionProductCharge.LocationVendorDynamicsAccountID__c = 'this15auniquedynamicsid234234';
        insert testSubscriptionProductCharge;
        Test.stopTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(testZquQuote);
        ZuoraQuoteEditLineItemsController testcase = new ZuoraQuoteEditLineItemsController(sc);
    }
    
    private static void createtestData(){
        userList = [select Id, Name, Alias, SalesRepID__c, Manager.SalesRepID__c from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        rtLeadMapByName = Schema.SObjectType.Lead.getRecordTypeInfosByName();
        // CSP-1999 rtBrandMapByName = Schema.SObjectType.Brand__c.getRecordTypeInfosByName();
        rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        
        if(Deactivate_Trigger__c.getValues('Attachment') == null){
            dtatt = TestClassUtility.createAttachmentDeactivateTriggerSetting(true);
              
        }
        
        //TestClassUtility.createCBSSCustomSettings();
        
        GQPF = TestClassUtility.generateQuotePdfConfig(false);
        GQPF.URL__c = 'www.baidu.com';
        insert GQPF;

        // CSP-1999 
        // testBrand = TestClassUtility.createBrand(false);
        // testBrand.RecordTypeId = rtBrandMapByName.get('Local').getRecordTypeId();
        // insert testBrand;
        // testRegion = TestClassUtility.createRegion(true, testBrand);
        testRegion = TestClassUtility.createRegion(true);
        
        testMarket = TestClassUtility.createMarket(false);
        testMarket.Market_ID__c = '222';
        testMarket.Active__c = true;
        testMarket.Local_Sales_Region__c = testRegion.id;
        insert testMarket;
        
        // CSP-1999 
        // testCategory = TestClassUtility.createCategory(true, testBrand);
        testCategory = TestClassUtility.createCategory(true);
        
        ma = TestClassUtility.createMetroArea(true);
        
        zip = TestClassUtility.createZip(false);
        zip.MetroArea__c = ma.id;
        zip.ZipCode__c = '99999';
        zip.name = '12121';
        zip.Local_Market__c = testMarket.id;
        insert zip; 
    
    }
    public static testMethod void test_method_one() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Test.startTest();
        Map<String, SObject> testObjects = TestClassUtility.buildZQUTestObjects(false);
        Test.stopTest();
        

        Map<String, SObject> testsub =TestClassUtility.buildSubscriptionData((Account)testObjects.get('Account'), 
                                                                            (Contact)testObjects.get('Contact'), 
                                                                            (Opportunity)testObjects.get('Opportunity') , 
                                                                            (Zuora__CustomerAccount__c)testObjects.get('Zuora__CustomerAccount__c'));

        Market__c testMkt = new Market__c();
        testMkt.Name = 'TX - Austin - 191';
        testMkt.Short_Description__c = 'TX-Austin';
        testMkt.Market_Id__c = '191';
        insert testmkt;

        Account testAcc = (Account)testObjects.get('Account');
        Contact testCon = (Contact)testObjects.get('Contact');
        Opportunity testOpp = (Opportunity)testObjects.get('Opportunity');

        zqu__Quote__c testQuote = (zqu__Quote__c)testsub.get('zqu__Quote__c');


        //Map<String,Schema.RecordTypeInfo> 
        rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        testMkt.Zuora_Description__c = 'Test Market';
        update testMkt;
        
        Publication__c testPublication = new Publication__c();
        testPublication.name = 'testPublication';
        testPublication.Short_Name__c = 'test';
        insert testPublication;
        
        Edition__c testEdition = new Edition__c();
        testEdition.name = 'st Rate Plan';
        testEdition.Publication__c = testPublication.id;
        insert testEdition;
        

        Print_Issue__c pi1 =new Print_Issue__c();
        pi1.name = 'test name';
        pi1.Edition__c = testEdition.id;
        pi1.Print_Market__c = testMkt.id;
        pi1.Selling_Start_Date__c = date.today();
        pi1.Publish_1st_Cover_Ship__c = date.today();
        insert pi1;
        
        Print_Issue__c pi2 =new Print_Issue__c();
        pi2.name = 'test name';
        pi2.Edition__c = testEdition.id;
        pi2.Print_Market__c = testMkt.id;
        pi2.Selling_Start_Date__c = date.today();
        pi2.Publish_1st_Cover_Ship__c = date.today();
        insert pi2;
        
        Print_Issue__c pi =new Print_Issue__c();
        pi.name = 'test name';
        pi.Previous_Issue__c = pi1.id;
        pi.Next_Issue__c = pi2.id;
        pi.Edition__c = testEdition.id;
        pi.Print_Market__c = testMkt.id;
        pi.Selling_Start_Date__c = date.today();
        pi.Publish_1st_Cover_Ship__c = date.today();
        pi.Step_2__c = date.today().adddays(-1);
        pi.Step_3__c = date.today().adddays(-1);
        insert pi;
        
        test.setCurrentPageReference(Page.ZuoraQuoteEditLineItems);

        ApexPages.StandardController sc = new ApexPages.StandardController(testQuote);
        ZuoraQuoteEditLineItemsController testcase = new ZuoraQuoteEditLineItemsController(sc); 
        
        String getImgUrl = testcase.getImgUrl();
        Boolean getPageIsInWizard = testcase.getPageIsInWizard();
        String BackButtonText = testcase.BackButtonText;
        String NextButtonText = testcase.NextButtonText;
        // testcase.navigateNext();
        testcase.navigateBack();
        testcase.cancel();
        testcase.standaloneCancel();
        testcase.standaloneSave();

    }

    public static testMethod void test_method_two() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Test.startTest();
        Map<String, SObject> testObjects = TestClassUtility.buildZQUTestObjects(false);
        Test.stopTest();
        

        Map<String, SObject> testsub =TestClassUtility.buildSubscriptionData((Account)testObjects.get('Account'), 
                                                                            (Contact)testObjects.get('Contact'), 
                                                                            (Opportunity)testObjects.get('Opportunity') , 
                                                                            (Zuora__CustomerAccount__c)testObjects.get('Zuora__CustomerAccount__c'));

        Market__c testMkt = new Market__c();
        testMkt.Name = 'TX - Austin - 191';
        testMkt.Short_Description__c = 'TX-Austin';
        testMkt.Market_Id__c = '191';
        insert testmkt;

        Account testAcc = (Account)testObjects.get('Account');
        Contact testCon = (Contact)testObjects.get('Contact');
        Opportunity testOpp = (Opportunity)testObjects.get('Opportunity');

        zqu__Quote__c testQuote = (zqu__Quote__c)testsub.get('zqu__Quote__c');


        //Map<String,Schema.RecordTypeInfo> 
        rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        testMkt.Zuora_Description__c = 'Test Market';
        update testMkt;
        
        Publication__c testPublication = new Publication__c();
        testPublication.name = 'testPublication';
        testPublication.Short_Name__c = 'test';
        insert testPublication;
        
        Edition__c testEdition = new Edition__c();
        testEdition.name = 'st Rate Plan';
        testEdition.Publication__c = testPublication.id;
        insert testEdition;
        

        Print_Issue__c pi1 =new Print_Issue__c();
        pi1.name = 'test name';
        pi1.Edition__c = testEdition.id;
        pi1.Print_Market__c = testMkt.id;
        pi1.Selling_Start_Date__c = date.today();
        pi1.Publish_1st_Cover_Ship__c = date.today();
        insert pi1;
        
        Print_Issue__c pi2 =new Print_Issue__c();
        pi2.name = 'test name';
        pi2.Edition__c = testEdition.id;
        pi2.Print_Market__c = testMkt.id;
        pi2.Selling_Start_Date__c = date.today();
        pi2.Publish_1st_Cover_Ship__c = date.today();
        insert pi2;
        
        Print_Issue__c pi =new Print_Issue__c();
        pi.name = 'test name';
        pi.Previous_Issue__c = pi1.id;
        pi.Next_Issue__c = pi2.id;
        pi.Edition__c = testEdition.id;
        pi.Print_Market__c = testMkt.id;
        pi.Selling_Start_Date__c = date.today();
        pi.Publish_1st_Cover_Ship__c = date.today();
        pi.Step_2__c = date.today().adddays(-1);
        pi.Step_3__c = date.today().adddays(-1);
        insert pi;
        
        test.setCurrentPageReference(Page.ZuoraQuoteEditLineItems);

        ApexPages.StandardController sc = new ApexPages.StandardController(testQuote);
        ZuoraQuoteEditLineItemsController testcase = new ZuoraQuoteEditLineItemsController(sc); 
        
        String getImgUrl = testcase.getImgUrl();
        Boolean getPageIsInWizard = testcase.getPageIsInWizard();
        
        String NextButtonText = testcase.NextButtonText;
        testcase.navigateNext();

        testcase.SelectedRatePlanIdForWaitlistModal = 'testSelectedRatePlanIdForWaitlistModal ';
        //testcase.ViewWaitlist();
        ComponentControllerBase ccb =testcase.getMyComponentController();
        
       // testcase.addToWaitlist();
        List<ZuoraQuoteEditLineItemsController.RatePlanWrapper> RatePlanWrapperList = new List<ZuoraQuoteEditLineItemsController.RatePlanWrapper>();
        RatePlanWrapperList = testcase.getRatePlanList();
        
        testcase.checkInventory();

        try{
            testcase.addToWaitlist();
        }catch(exception e){}
        
        
        try{
            testcase.ViewWaitlist();
        }catch(exception e){}
 
        try{
            testcase.setComponentController(ccb);
        }catch(exception e){}


    }
    
    
    
}