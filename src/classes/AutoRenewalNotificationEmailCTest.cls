@isTest
private class AutoRenewalNotificationEmailCTest {
  public static String JsonStr = 
                                  '{"success" : true, '+
                                 '"contractedMrr" : 1065.000000000, '+
                                 '"totalContractedValue" : 12780.000000000, '+
                                 '"amount" : 12780.00, '+
                                 '"amountWithoutTax" : 12780.00, '+
                                 '"taxAmount" : 0.00, '+
                                 '"invoiceTargetDate" : "2018-06-06", '+
                                
                                 '"invoiceItems" : [ { '+
                                 '  "serviceStartDate" : "2016-07-15", '+
                                   '"serviceEndDate" : "2016-08-14", '+
                                   '"chargeAmount" : 70.00, '+
                                   '"chargeDescription" : null, '+
                                   '"chargeName" : " Charge", '+
                                   '"productName" : "Storefront", '+
                                   '"productRatePlanChargeId" : "2c92a0ff526932600152748622a93131", '+
                                   '"quantity" : 1, '+
                                   '"unitOfMeasure" : "" '+
                                 '}, { '+
                                   '"serviceStartDate" : "2016-07-15", '+
                                   '"serviceEndDate" : "2016-08-14", '+
                                   '"chargeAmount" : 1005.00, '+
                                   '"chargeDescription" : null, '+
                                   '"chargeName" : "Recurring Charge", '+
                                   '"productName" : "Premium Featured Vendor", '+
                                   '"productRatePlanChargeId" : "2c92a0fc5269262e015270ab7ff74e4a", '+
                                   '"quantity" : 1, '+
                                   '"unitOfMeasure" : "" '+
                                '}, { '+
                                   '"serviceStartDate" : "2016-01-15", '+
                                   '"serviceEndDate" : "2016-09-14",'+
                                   '"chargeAmount" : 60.00,'+
                                   '"chargeDescription" : null, '+
                                   '"chargeName" : "Recurring Charge", '+
                                   '"productName" : "Featured", '+
                                   '"productRatePlanChargeId" : "2c92a0ff526932600152748622a93131",'+
                                   '"quantity" : 1,'+
                                   '"unitOfMeasure" : "" '+
                                '}, { '+
                                
                                '"serviceStartDate" : "2016-01-15", '+
                                   '"serviceEndDate" : "2016-09-14",'+
                                   '"chargeAmount" : 90.00,'+
                                   '"chargeDescription" : null, '+
                                   '"chargeName" : "Weekly Charge", '+
                                   '"productName" : "Vendor", '+
                                   '"productRatePlanChargeId" : "2c92a0ff526932600152748622a93131",'+
                                   '"quantity" : 1,'+
                                   '"unitOfMeasure" : "" '+
                                '}, { '+
                                
                                '"serviceStartDate" : "2016-01-15", '+
                                   '"serviceEndDate" : "2016-09-14",'+
                                   '"chargeAmount" : 90.00,'+
                                   '"chargeDescription" : null, '+
                                   '"chargeName" : "Monthly Charge", '+
                                   '"productName" : "Premium", '+
                                   '"productRatePlanChargeId" : "2c92a0ff526932600152748622a93131",'+
                                   '"quantity" : 1,'+
                                   '"unitOfMeasure" : "" '+
                                '}, { '+
                                
                                   '"serviceStartDate" : "2016-08-15",'+
                                   '"serviceEndDate" : "2016-09-14",'+
                                   '"chargeAmount" : 1005.00,'+
                                   '"chargeDescription" : null,'+
                                   '"chargeName" : "Recurring Charge",'+
                                   '"productName" : "Premium Featured Vendor",'+
                                   '"productRatePlanChargeId" : "2c92a0fc5269262e015270ab7ff74e4a",'+
                                   '"quantity" : 1,'+
                                   '"unitOfMeasure" : ""'+
                                '}, { '+
                                   '"serviceStartDate" : "2016-09-15",'+
                                   '"serviceEndDate" : "2016-10-14",'+
                                   '"chargeAmount" : 60.00,'+
                                   '"chargeDescription" : null,'+
                                   '"chargeName" : "Recurring Charge",'+
                                   '"productName" : "Storefront",'+
                                   '"productRatePlanChargeId" : "2c92a0ff526932600152748622a93131",'+
                                   '"quantity" : 1,'+
                                   '"unitOfMeasure" : ""'+
                                '}, { '+
                                   '"serviceStartDate" : "2016-09-15",'+
                                   '"serviceEndDate" : "2016-10-14",'+
                                   '"chargeAmount" : 1005.00,'+
                                   '"chargeDescription" : null,'+
                                   '"chargeName" : "Recurring Charge",'+
                                   '"productName" : "Premium Featured Vendor",'+
                                   '"productRatePlanChargeId" : "2c92a0fc5269262e015270ab7ff74e4a",'+
                                   '"quantity" : 1,'+
                                   '"unitOfMeasure" : ""'+
                                '}, { '+
                                   '"serviceStartDate" : "2016-10-15",'+
                                   '"serviceEndDate" : "2016-11-14",'+
                                   '"chargeAmount" : 60.00,'+
                                   '"chargeDescription" : null,'+
                                   '"chargeName" : "Recurring Charge",'+
                                   '"productName" : "Storefront",'+
                                   '"productRatePlanChargeId" : "2c92a0ff526932600152748622a93131",'+
                                   '"quantity" : 1,'+
                                   '"unitOfMeasure" : ""'+
                                '}, { '+
                                   '"serviceStartDate" : "2016-10-15",'+
                                   '"serviceEndDate" : "2016-11-14",'+
                                   '"chargeAmount" : 1005.00,'+
                                   '"chargeDescription" : null,'+
                                   '"chargeName" : "Recurring Charge",'+
                                   '"productName" : "Premium Featured Vendor",'+
                                   '"productRatePlanChargeId" : "2c92a0fc5269262e015270ab7ff74e4a",'+
                                   '"quantity" : 1,'+
                                   '"unitOfMeasure" : ""'+
                                 '}, { '+
                                   '"serviceStartDate" : "2016-11-15",'+
                                   '"serviceEndDate" : "2016-12-14",'+
                                   '"chargeAmount" : 60.00,'+
                                   '"chargeDescription" : null,'+
                                   '"chargeName" : "Recurring Charge",'+
                                   '"productName" : "Storefront",'+
                                   '"productRatePlanChargeId" : "2c92a0ff526932600152748622a93131",'+
                                   '"quantity" : 1,'+
                                   '"unitOfMeasure" : ""'+
                                '}, { '+
                                    '"serviceStartDate" : "2016-11-15",'+
                                   '"serviceEndDate" : "2016-12-14",'+
                                   '"chargeAmount" : 1005.00,'+
                                   '"chargeDescription" : null,'+
                                   '"chargeName" : "Recurring Charge",'+
                                   '"productName" : "Premium Featured Vendor",'+
                                   '"productRatePlanChargeId" : "2c92a0fc5269262e015270ab7ff74e4a",'+
                                   '"quantity" : 1,'+
                                   '"unitOfMeasure" : ""'+
                                 '}, { '+
                                   '"serviceStartDate" : "2016-12-15",'+
                                   '"serviceEndDate" : "2017-01-14",'+
                                   '"chargeAmount" : 99.00,'+
                                   '"chargeDescription" : null,'+
                                   '"chargeName" : "Recurring Charge",'+
                                   '"productName" : "Storefront",'+
                                   '"productRatePlanChargeId" : "2c92a0ff526932600152748622a93131",'+
                                   '"quantity" : 1,'+
                                   '"unitOfMeasure" : ""'+
                                 '}, { '+
                                   '"serviceStartDate" : "2016-12-15",'+
                                   '"serviceEndDate" : "2017-01-14",'+
                                   '"chargeAmount" : 1005.00,'+
                                   '"chargeDescription" : null,'+
                                   '"chargeName" : "Recurring Charge",'+
                                   '"productName" : "Premium Featured Vendor",'+
                                   '"productRatePlanChargeId" : "2c92a0fc5269262e015270ab7ff74e4a",'+
                                   '"quantity" : 1,'+
                                   '"unitOfMeasure" : ""'+
                                 '}, { '+
                                     '"serviceStartDate" : "2017-01-15",'+
                                   '"serviceEndDate" : "2017-02-14",'+
                                   '"chargeAmount" : 60.00,'+
                                   '"chargeDescription" : null,'+
                                   '"chargeName" : "Charge",'+
                                   '"productName" : "Storefront",'+
                                   '"productRatePlanChargeId" : "2c92a0ff526932600152748622a93131",'+
                                   '"quantity" : 1,'+
                                   '"unitOfMeasure" : ""'+
                                '}, { '+
                                   '"serviceStartDate" : "2017-01-15",'+
                                   '"serviceEndDate" : "2017-02-14",'+
                                   '"chargeAmount" : 1005.00,'+
                                   '"chargeDescription" : null,'+
                                   '"chargeName" : "Recurring",'+
                                   '"productName" : "Premium Featured Vendor",'+
                                   '"productRatePlanChargeId" : "2c92a0fc5269262e015270ab7ff74e4a",'+
                                   '"quantity" : 1,'+
                                   '"unitOfMeasure" : ""'+
                                '}, { '+
                                   '"serviceStartDate" : "2017-02-15",'+
                                   '"serviceEndDate" : "2017-03-14",'+
                                   '"chargeAmount" : 60.00,'+
                                   '"chargeDescription" : null,'+
                                   '"chargeName" : "Recurring Charge",'+
                                   '"productName" : "Storefront",'+
                                   '"productRatePlanChargeId" : "2c92a0ff526932600152748622a93131",'+
                                   '"quantity" : 1,'+
                                   '"unitOfMeasure" : ""'+
                                '}, { '+
                                   '"serviceStartDate" : "2017-02-15",'+
                                   '"serviceEndDate" : "2017-03-14",'+
                                   '"chargeAmount" : 1005.00,'+
                                   '"chargeDescription" : null,'+
                                   '"chargeName" : "Recurring Charge",'+
                                   '"productName" : "Premium Featured Vendor",'+
                                   '"productRatePlanChargeId" : "2c92a0fc5269262e015270ab7ff74e4a",'+
                                   '"quantity" : 1,'+
                                   '"unitOfMeasure" : ""'+
                                '}, { '+
                                   '"serviceStartDate" : "2017-03-15",'+
                                   '"serviceEndDate" : "2017-04-14",'+
                                   '"chargeAmount" : 60.00,'+
                                   '"chargeDescription" : null,'+
                                   '"chargeName" : "Recurring Charge",'+
                                   '"productName" : "Storefront",'+
                                   '"productRatePlanChargeId" : "2c92a0ff526932600152748622a93131",'+
                                   '"quantity" : 1,'+
                                   '"unitOfMeasure" : ""'+
                                '}, { '+
                                   '"serviceStartDate" : "2017-03-15",'+
                                   '"serviceEndDate" : "2017-04-14",'+
                                   '"chargeAmount" : 1005.00,'+
                                   '"chargeDescription" : null,'+
                                   '"chargeName" : "Recurring Charge",'+
                                   '"productName" : "Premium Featured Vendor",'+
                                   '"productRatePlanChargeId" : "2c92a0fc5269262e015270ab7ff74e4a",'+
                                   '"quantity" : 1,'+
                                   '"unitOfMeasure" : ""'+
                                '}, { '+
                                   '"serviceStartDate" : "2017-04-15",'+
                                   '"serviceEndDate" : "2017-05-14",'+
                                   '"chargeAmount" : 60.00,'+
                                   '"chargeDescription" : null,'+
                                   '"chargeName" : "Recurring Charge",'+
                                   '"productName" : "Storefront",'+
                                   '"productRatePlanChargeId" : "2c92a0ff526932600152748622a93131",'+
                                   '"quantity" : 1,'+
                                   '"unitOfMeasure" : ""'+
                                 '}, { '+
                                   '"serviceStartDate" : "2017-04-15",'+
                                   '"serviceEndDate" : "2017-05-14",'+
                                   '"chargeAmount" : 1005.00,'+
                                   '"chargeDescription" : null,'+
                                   '"chargeName" : "Recurring Charge",'+
                                   '"productName" : "Premium Featured Vendor",'+
                                   '"productRatePlanChargeId" : "2c92a0fc5269262e015270ab7ff74e4a",'+
                                   '"quantity" : 1,'+
                                   '"unitOfMeasure" : ""'+
                                 '}, { '+
                                   '"serviceStartDate" : "2017-05-15",'+
                                   '"serviceEndDate" : "2017-06-14",'+
                                   '"chargeAmount" : 60.00,'+
                                   '"chargeDescription" : null,'+
                                   '"chargeName" : "Recurring Charge",'+
                                   '"productName" : "Storefront",'+
                                   '"productRatePlanChargeId" : "2c92a0ff526932600152748622a93131",'+
                                   '"quantity" : 1,'+
                                   '"unitOfMeasure" : ""'+
                                '}, { '+
                                   '"serviceStartDate" : "2017-05-15",'+
                                   '"serviceEndDate" : "2017-06-14",'+
                                   '"chargeAmount" : 1005.00,'+
                                   '"chargeDescription" : null,'+
                                   '"chargeName" : "Recurring Charge",'+
                                   '"productName" : "Premium Featured Vendor",'+
                                   '"productRatePlanChargeId" : "2c92a0fc5269262e015270ab7ff74e4a",'+
                                   '"quantity" : 1,'+
                                   '"unitOfMeasure" : ""'+
                                 '}, { '+
                                   '"serviceStartDate" : "2017-06-15",'+
                                   '"serviceEndDate" : "2017-07-14",'+
                                   '"chargeAmount" : 60.00,'+
                                   '"chargeDescription" : null,'+
                                   '"chargeName" : "Recurring Charge",'+
                                   '"productName" : "Storefront",'+
                                   '"productRatePlanChargeId" : "2c92a0ff526932600152748622a93131",'+
                                   '"quantity" : 1,'+
                                   '"unitOfMeasure" : ""'+
                                 '}, { '+
                                   '"serviceStartDate" : "2017-06-15",'+
                                   '"serviceEndDate" : "2017-07-14",'+
                                   '"chargeAmount" : 1005.00,'+
                                   '"chargeDescription" : null,'+
                                   '"chargeName" : "Recurring Charge",'+
                                   '"productName" : "Premium Featured Vendor",'+
                                   '"productRatePlanChargeId" : "2c92a0fc5269262e015270ab7ff74e4a",'+
                                   '"quantity" : 1,'+
                                   '"unitOfMeasure" : "" '+
                                '}, { '+
                                
                                   '"serviceStartDate" : "2014-01-15", '+
                                   '"serviceEndDate" : "2014-09-14",'+
                                   '"chargeAmount" : 90.00,'+
                                   '"chargeDescription" : null, '+
                                   '"chargeName" : "Weekly Charge", '+
                                   '"productName" : "Vendor", '+
                                   '"productRatePlanChargeId" : "2c92a0ff526932600152748622a93131",'+
                                   '"quantity" : 1,'+
                                   '"unitOfMeasure" : "" '+
                                '}]}';


  static testMethod void testMethod1() {
    SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                             'Complete',
                                             '{"companyName": "Test Account"}',
                                             null);
    Test.setMock(HttpCalloutMock.class, fakeResponse);
    

    Test.startTest();
    Map<String, SObject> localObjects = TestClassUtility.buildLocalData(false);
    Test.stopTest();
    Account testAccount = (Account)localObjects.get('Account');
    Contact testContact = (Contact)localObjects.get('Contact');
    Opportunity testOpp = (Opportunity)localObjects.get('Opportunity');

    Map<String, SObject> subscriptionObjects = TestClassUtility.buildSubscriptionData((Account)localObjects.get('Account'),
                                                                                      (Contact)localObjects.get('Contact'),
                                                                                       testOpp,
                                                                                      (Zuora__CustomerAccount__c)localObjects.get('Zuora__CustomerAccount__c'));

  	zqu__Quote__c testQuote = (zqu__Quote__c)subscriptionObjects.get('zqu__Quote__c');
    testQuote.True_TCV_JSON_Response__c = JsonStr;
    testQuote.zqu__InitialTerm__c = 12;
    testQuote.zqu__TermStartDate__c = Date.today();
    testQuote.zqu__BillCycleDay__c = '12';
    testQuote.zqu__PaymentMethod__c = 'Check';
    testQuote.Preferred_Payment_Schedule__c = 'Annual';
    update testQuote;

  	AutoRenewalNotificationEmailController arnec = new AutoRenewalNotificationEmailController();
  	arnec.quoteId = testQuote.id;
  	zqu__Quote__c testQuote2 = arnec.zQuote;
    List<String> ratePlanNameList = arnec.ratePlanNameList;

    Decimal totalAmount = arnec.totalAmount;

    String totalAmountToBilled = arnec.totalAmountToBilled;

    String signatureDucomentId = arnec.signatureDucomentId;

  }
}