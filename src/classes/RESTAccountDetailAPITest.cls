@isTest
private class RESTAccountDetailAPITest {
    
    @isTest static void test_method_one() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
    
        // building the data 
        // CSP-1999 Brand__c testBrand = TestClassUtility.createBrand(true);
        // Region__c testRegion = TestClassUtility.createRegion(true, testBrand);
        Region__c testRegion = TestClassUtility.createRegion(true);

        Market__c wtfMarket = TestClassUtility.createMarket(false, testRegion);
        wtfMarket.Market_ID__c = '222';
        insert wtfMarket;
        
        Account testAccount = TestClassUtility.createAccount(true);
        
        testAccount.DynamicsAccID__c = 'TestRestAPIDynamicsId';
        testAccount.BillingStreet = 'test \r\n test';
        update testAccount;

        Contact testContact = TestClassUtility.createContact(true, testAccount);

        AccountContactRole testAccContactRole = TestClassUtility.createAccountContactRole(true, testAccount, testContact);
    
        Test.startTest(); 
            //As Per Best Practice it is important to instantiate the Rest Context 
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
             
            req.requestURI = '/services/apexrest/AccountDetail';  
            req.addParameter('acctGUID', testAccount.DynamicsAccID__c);
            req.httpMethod = 'GET';
            RestContext.request = req;
            RestContext.response= res;
            RESTAccountDetailAPI.AccountDetailResponse responseMessage = RESTAccountDetailAPI.getAccountDetail();
        Test.stopTest();
    }    
}