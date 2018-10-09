/* 
<class>
  <name>BatchRebuildInventoryTest</name>
  <purpose>For testing the BatchRebuildInventory class</purpose>
  <created>
    <by>Tony liu</by>
    <date>3/8/2016</date>
  </created>
</class>
*/
@isTest
private class BatchRebuildInventoryTest {
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
    
    private static Zuora__Subscription__c testZquSubscription;
    private static Zuora__Product__c testZuoraProduct;
    private static Zuora__SubscriptionProductCharge__c testZquSubscriptionProductCharge;
    
    @isTest static void test_method_two(){
        
        // CSP-2683 Fixing Test Classes
        // generate the invoice hold expire date
        Inventory_Hold_Expiry_Date_Offsets__c invHoldExpDate = TestClassUtility.generateInventoryExpireDateOffsets(TRUE);
        
        createtestData();
        CreateZQUTestObjects();

        Test.startTest();
        
        ChainBatchJob__c CBJ = new ChainBatchJob__c();
        CBJ.Name = 'BatchRebuildInventory';
        CBJ.Chain_Next_Batch_Job__c = true;
        insert CBJ;

        Test.stopTest();
    }
    
    private static void CreateZQUTestObjects(){
        // CSP-1999 
        // Account testAccount = TestClassUtility.createAccount(false, testBrand, testCategory, testMarket);
        Account testAccount = TestClassUtility.createAccount(false, testCategory, testMarket);
        testAccount.RecordTypeId = rtMapByName.get('Local').getRecordTypeId();
        testAccount.Record_Type_Name__c = 'Local';
        testAccount.BU__c = 'Local';
        testAccount.Type = 'Agency';
        testAccount.Operative_Owner__c = userList[0].Name;
        testAccount.Fulfillment_Data__c = '{ "tier" : "Freemium", "reviewId" : "review Id", "parentGUID" : "37e0c6b9-6f4f-4dd4-a3f4-9707e9dc4bbc", "marketCode" : "228", "categoryId" : "8aa9a07b-fcd8-46ed-a98f-8f3e12689dd2" }';
        testAccount.OwnerId = userList[0].Id;
        testAccount.CBBS__c = userList[1].Id;
        testAccount.BillingPostalCode = zip.ZipCode__c;
        testAccount.Operative_Owner__c = userList[0].Name;
        insert testAccount;
        
        Opportunity testOpportunity = TestClassUtility.createOpportunity(false);
        testOpportunity.RecordTypeId = rtOppMapByName.get('Local').getRecordTypeId();
        testOpportunity.AccStrategist__c = UserInfo.getUserId();
        testOpportunity.Amount = 50000;
        testOpportunity.OwnerId = UserInfo.getUserId();
        testOpportunity.StageName = 'Prospecting';
        
        testOpportunity.AccountId = testAccount.Id;
        testOpportunity.CloseDate = Date.Today()-10;
        testOpportunity.Potential_Value_Print__c = 1.23;
        testOpportunity.Potential_Value_Internet__c = 1.23;
        testOpportunity.Potential_Value_Direct_Marketing__c = 1.23;
        testOpportunity.NeedToSendToZBilling__c = false;
        insert testOpportunity;
        
        Contact testContact = TestClassUtility.createContact(false, testAccount);
        testContact.Same_Address_as_Account__c = true;
        insert testContact;

        zqu__Quote__c testZquQuote = TestClassUtility.createQuote(false, testOpportunity, testAccount, testContact);
        testZquQuote.Preferred_Payment_Schedule__c = 'Quarter';   
        testZquQuote.zqu__InitialTerm__c = 3;  
        testZquQuote.zqu__StartDate__c = date.today().adddays(1);       
        testZquQuote.Product_Line__c = 'Print';
        testZquQuote.zqu__Previewed_TCV__c = 7.22;
        insert testZquQuote;
        
        Product2 testProduct = TestClassUtility.createLocalProduct2(true);
        
        testZquSubscription = TestClassUtility.createSubscription(false, testAccount);
        testZquSubscription.Zuora__Zuora_Id__c = 'abc123';
        testZquSubscription.OriginalSalesforceQuoteID__c = testZquQuote.Id;
        insert testZquSubscription;
        
        
        zqu__ProductRatePlan__c testZquProductRatePlan = TestClassUtility.createProductRatePlan(false); 
        testZquProductRatePlan.Name = 'Rate Plan 1'; 
        testZquProductRatePlan.zqu__Product__c = testProduct.id; 
        testZquProductRatePlan.Capacity__c = '10';
        insert testZquProductRatePlan;
        
        
        Inventory__c testInventory = TestClassUtility.createInventory(false, testZquProductRatePlan);     
        testInventory.Subscription_RatePlan_Id__c = 'asdasdasdasdas';
        insert testInventory;

    }
    
    private static void createtestData(){
        userList = [select Id, Name, Alias from User where Id != :UserInfo.getUserId() and isActive = true  and ARR__c != null limit 2];
        rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        rtLeadMapByName = Schema.SObjectType.Lead.getRecordTypeInfosByName();
        // CSP-1999 rtBrandMapByName = Schema.SObjectType.Brand__c.getRecordTypeInfosByName();
        rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        if(Deactivate_Trigger__c.getValues('Attachment') == null){
            dtatt = TestClassUtility.createAttachmentDeactivateTriggerSetting(true);
              
        }
        
        GQPF = TestClassUtility.generateQuotePdfConfig(false);
        GQPF.URL__c = 'www.baidu.com';
        insert GQPF;

        testRegion = TestClassUtility.createRegion(true);
        testMarket = TestClassUtility.createMarket(false);
        testMarket.Market_ID__c = '222';
        testMarket.Active__c = true;
        testMarket.Local_Sales_Region__c = testRegion.id;
        insert testMarket;
        
        // CSP-1999
        testCategory = TestClassUtility.createCategory(true);
        ma = TestClassUtility.createMetroArea(true);
        
        zip = TestClassUtility.createZip(false);
        zip.MetroArea__c = ma.id;
        zip.ZipCode__c = '99999';
        zip.name = '12121';
        zip.Local_Market__c = testMarket.id;
        insert zip; 
    
    }
}