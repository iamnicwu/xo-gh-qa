@IsTest
private class FeatureRequestedCanceledAuraCtrlTest {

  public static final String TEST_JSON_STRING = '[{"SubProductChargeNumber":"2","spcId":"a1Tq0000002NmOBEA0","Status":"Requested Cancelled","frcId":"a1Aq0000001JkyyEAC"},' +
      '{"SubProductChargeNumber":"4","spcId":"a1Tq0000002NmOLEA0","Status":"Cancelled","frcId":"a1Aq0000001Jkz0EAC"},' +
      '{"SubProductChargeNumber":"3","spcId":"a1Tq0000002NmOGEA0","Status":"Saved","frcId":"a1Aq0000001Jkz1EAC"}]';

  public static final String TEST_JSON_STRING_NOFRC = '[{"SubProductChargeNumber":"2","spcId":"{0}","Status":"Requested Cancelled"},' +
      '{"SubProductChargeNumber":"4","spcId":"{1}","Status":"Cancelled"},' +
      '{"SubProductChargeNumber":"3","spcId":"{2}","Status":"Saved"}]';

  public static Zuora__SubscriptionProductCharge__c generateSPC(Account account, String chargeNumber) {
    Zuora__Product__c zp = new Zuora__Product__c();
    zp.Name = 'Storefront';
    insert zp;

    Zuora__SubscriptionRatePlan__c zsp = new Zuora__SubscriptionRatePlan__c();
    zsp.Name = 'Storefront | MI-Grand Rpds/Northern | Florists';
    insert zsp;

    Zuora__Subscription__c subscription = new Zuora__Subscription__c();
    subscription.Name = 'Recurring Charge';
    subscription.Zuora__SubscriptionEndDate__c  = Date.valueOf('2019-06-15');
    insert subscription;

    Zuora__SubscriptionProductCharge__c zspc = new Zuora__SubscriptionProductCharge__c();
    zspc.Name = chargeNumber;
    zspc.Zuora__ChargeNumber__c = chargeNumber;
    zspc.Zuora__SubscriptionRatePlan__c = zsp.Id;
    zspc.LDE_Email_Launch_Date__c = Date.valueOf('2017-05-15');
    zspc.LocationVendorDynamicsAccountID__c = 'abc123';
    zspc.List_Price__c = '45';
    zspc.Zuora__Price__c = 45.01;
    zspc.Zuora__BillingPeriod__c = 'Month';
    zspc.Zuora__Product__c = zp.Id;
    zspc.Zuora__Account__c = account.Id;
    zspc.Zuora__Subscription__c = subscription.Id;

    insert zspc;

    return zspc;
  }

  @IsTest
  static void testGetFeatureRequestCanceledForCaseException() {
    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceExceptionMock()));

    Case c = new Case();
    insert c;
    try {
      Test.startTest();
      FeatureRequestedCanceledAuraController.getFeatureRequestCanceledForCase(c.Id);
      Test.stopTest();
      System.assert(false, 'Should have thrown exception.');
    } catch (AuraHandledException ae) {
      System.assertEquals('Failure.', ae.getMessage());
    }

  }

  @IsTest
  static void testGetFeatureRequestCanceledForCaseSPCException() {
    Case fakeCase = new Case();
    insert fakeCase;

    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceSuccessMock(fakeCase)));
    SubscriptionProductChargeService.setMock((SubscriptionProductChargeService) Test.createStub(SubscriptionProductChargeService.class,
        new SubscriptionProductChargeServiceExceptionMock()));

    try {
      Test.startTest();
      FeatureRequestedCanceledAuraController.getFeatureRequestCanceledForCase(fakeCase.Id);
      Test.stopTest();
      System.assert(false, 'Should have thrown exception.');
    } catch (AuraHandledException ae) {
      System.assertEquals('spc failure', ae.getMessage());
    }

  }

  @IsTest
  static void testGetFeatureRequestCanceledForCaseNoFRCs() {
    Case fakeCase = new Case();
    insert fakeCase;

    Map<String, SObject> testObjects = TestClassUtility.buildLocalData(false);
    Account account = (Account)testObjects.get('Account');

    List<Zuora__SubscriptionProductCharge__c> spcs = new List<Zuora__SubscriptionProductCharge__c>{
        generateSPC(account, '1'),
        generateSPC(account, '2')
    };

    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceSuccessMock(fakeCase)));
    SubscriptionProductChargeService.setMock((SubscriptionProductChargeService) Test.createStub(SubscriptionProductChargeService.class,
        new SubscriptionProductChargeServiceSuccessMock(spcs)));

    Test.startTest();
      Map<String, Object> result = FeatureRequestedCanceledAuraController.getFeatureRequestCanceledForCase(fakeCase.Id);
    Test.stopTest();

    System.assertNotEquals(null, result.get(FeatureRequestedCanceledAuraController.FRCS));
    List<FeatureRequestCanceledDTO> frcDTOs = (List<FeatureRequestCanceledDTO>) result.get(FeatureRequestedCanceledAuraController.FRCS);
    System.assertEquals(2, frcDTOs.size());
    System.assertEquals('1', frcDTOs[0].SubscriptionChargeName);
    System.assertEquals('2', frcDTOs[1].SubscriptionChargeName);

    // As long as the options are set we're good to go.
    System.assertNotEquals(null, result.get(FeatureRequestedCanceledAuraController.OPTIONS));

  }

  @IsTest
  static void testGetFeatureRequestCanceledForCaseExistingFCRs() {

    Map<String, SObject> testObjects = TestClassUtility.buildLocalData(false);
    Account account = (Account)testObjects.get('Account');

    Case fakeCase = new Case();
    insert fakeCase;

    String chargeNum = '1';
    Feature_Requested_Cancelled__c frc = new Feature_Requested_Cancelled__c();
    frc.Case__c = fakeCase.Id;
    frc.Sub_Product_Charge_Number__c = chargeNum;
    frc.Status__c = 'Cancelled';
    frc.UniqueId__c = 'sayitaintso';
    insert frc;

    List<Zuora__SubscriptionProductCharge__c> spcs = new List<Zuora__SubscriptionProductCharge__c>{
        generateSPC(account, chargeNum),
        generateSPC(account, '2')
    };

    Case fakeCaseWithFRC = CaseDAO.getInstance().getWithFeatureRequestCancelled(fakeCase.Id);
    System.assertNotEquals(null, fakeCaseWithFRC);

    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceSuccessMock(fakeCaseWithFRC)));
    SubscriptionProductChargeService.setMock((SubscriptionProductChargeService) Test.createStub(SubscriptionProductChargeService.class,
        new SubscriptionProductChargeServiceSuccessMock(spcs)));

    Test.startTest();
    Map<String, Object> result = FeatureRequestedCanceledAuraController.getFeatureRequestCanceledForCase(fakeCase.Id);
    Test.stopTest();

    System.assertNotEquals(null, result.get(FeatureRequestedCanceledAuraController.FRCS));
    List<FeatureRequestCanceledDTO> frcDTOs = (List<FeatureRequestCanceledDTO>) result.get(FeatureRequestedCanceledAuraController.FRCS);
    System.debug(frcDTOs);
    System.assertEquals(2, frcDTOs.size());
    System.assertEquals('1', frcDTOs[0].SubscriptionChargeName);
    System.assertEquals(frc.Id, frcDTOs[0].frcId);
    System.assertEquals(true, frcDTOs[0].isAdded);
    System.assertEquals('2', frcDTOs[1].SubscriptionChargeName);
    System.assertEquals(false, frcDTOs[1].isAdded);
    System.assertEquals(null, frcDTOs[1].frcId);


    // As long as the options are set we're good to go.
    System.assertNotEquals(null, result.get(FeatureRequestedCanceledAuraController.OPTIONS));

  }

  @IsTest
  static void testUpdateFRCsException() {

    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceExceptionMock()));

    Case c = new Case();
    insert c;
    try {
      Test.startTest();
      FeatureRequestedCanceledAuraController.updateFRCs(c.Id, '[]');
      Test.stopTest();
      System.assert(false, 'Should have thrown exception.');
    } catch (AuraHandledException ae) {
      System.assertEquals('Failure.', ae.getMessage());
    }

  }

  @IsTest
  static void testUpdateFRCsAllNew() {
    Map<String, SObject> testObjects = TestClassUtility.buildLocalData(false);
    Account account = (Account)testObjects.get('Account');

    Case fakeCase = new Case();
    fakeCase.accountId = account.Id;
    insert fakeCase;

    // values in fake json are 2, 3, 4
    List<Zuora__SubscriptionProductCharge__c> spcs = new List<Zuora__SubscriptionProductCharge__c>{
        generateSPC(account, '2'),
        generateSPC(account, '3'),
        generateSPC(account, '4')
    };

    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceSuccessMock(fakeCase)));

    SubscriptionProductChargeServiceSuccessMock spcMock = new SubscriptionProductChargeServiceSuccessMock(spcs);
    SubscriptionProductChargeService.setMock((SubscriptionProductChargeService) Test.createStub(SubscriptionProductChargeService.class,
      spcMock));

    FeatureRequestedCancelServiceSuccessMock frsMock = new FeatureRequestedCancelServiceSuccessMock();
    FeatureRequestedCancelService.setMock((FeatureRequestedCancelService) Test.createStub(FeatureRequestedCancelService.class,
        frsMock));

    Case c = new Case();
    insert c;

    List<Map<String, String>> frcs = FeatureRequestedCanceledAuraController.deserializeSPCList(TEST_JSON_STRING_NOFRC);
    frcs[0].put('spcId', spcs[0].Id);
    frcs[1].put('spcId', spcs[1].Id);
    frcs[2].put('spcId', spcs[2].Id);
    String updatedJson = JSON.serialize(frcs);
    // Update the json string to include the correct SPC Ids
    Test.startTest();
    FeatureRequestedCanceledAuraController.updateFRCs(c.Id, updatedJSON);
    Test.stopTest();

    System.assertEquals(0, frsMock.getDeleted().size());
    System.assertEquals(3, frsMock.getUpserted().size());
  }

  @IsTest
  static void testUpdateFRCsUpdateExisting() {
    Map<String, SObject> testObjects = TestClassUtility.buildLocalData(false);
    Account account = (Account)testObjects.get('Account');

    Case fakeCase = new Case();
    fakeCase.accountId = account.Id;
    insert fakeCase;

    // values in fake json are 2, 3, 4
    List<Zuora__SubscriptionProductCharge__c> spcs = new List<Zuora__SubscriptionProductCharge__c>{
        generateSPC(account, '2'),
        generateSPC(account, '3'),
        generateSPC(account, '4')
    };

    // Create a FRC object that is related to the case with Status 'Cancelled'
    Feature_Requested_Cancelled__c frc = new Feature_Requested_Cancelled__c();
    frc.Case__c = fakeCase.Id;
    frc.Status__c = 'Cancelled';
    frc.UniqueId__c = 'abc123';
    frc.Subscription_Product_Charge__c = spcs[0].Id;
    frc.Sub_Product_Charge_Number__c = '2';
    insert frc;

    fakeCase = CaseDAO.getInstance().getWithFeatureRequestCancelled(fakeCase.Id);
    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceSuccessMock(fakeCase)));

    SubscriptionProductChargeServiceSuccessMock spcMock = new SubscriptionProductChargeServiceSuccessMock(spcs);
    SubscriptionProductChargeService.setMock((SubscriptionProductChargeService) Test.createStub(SubscriptionProductChargeService.class,
        spcMock));

    FeatureRequestedCancelServiceSuccessMock frsMock = new FeatureRequestedCancelServiceSuccessMock();
    FeatureRequestedCancelService.setMock((FeatureRequestedCancelService) Test.createStub(FeatureRequestedCancelService.class,
        frsMock));

    List<Map<String, String>> frcs = FeatureRequestedCanceledAuraController.deserializeSPCList(TEST_JSON_STRING_NOFRC);
    frcs[0].put('spcId', spcs[0].Id);
    frcs[1].put('spcId', spcs[1].Id);
    frcs[2].put('spcId', spcs[2].Id);

    frcs[0].put('frcId', frc.Id);
    frcs[0].put('Status', 'Saved');

    String updatedJson = JSON.serialize(frcs);
    // Update the json string to include the correct SPC Ids
    Test.startTest();
    FeatureRequestedCanceledAuraController.updateFRCs(fakeCase.Id, updatedJSON);
    Test.stopTest();

    System.assertEquals(0, frsMock.getDeleted().size());
    System.assertEquals(3, frsMock.getUpserted().size());

    Feature_Requested_Cancelled__c updatedStatus = frsMock.getUpserted()[0];
    System.assertEquals('Saved', updatedStatus.Status__c);

  }

  @IsTest
  static void testUpdateFRCsDelete() {
    Map<String, SObject> testObjects = TestClassUtility.buildLocalData(false);
    Account account = (Account)testObjects.get('Account');

    Case fakeCase = new Case();
    fakeCase.accountId = account.Id;
    insert fakeCase;

    // values in fake json are 2, 3, 4
    List<Zuora__SubscriptionProductCharge__c> spcs = new List<Zuora__SubscriptionProductCharge__c>{
        generateSPC(account, '2'),
        generateSPC(account, '3'),
        generateSPC(account, '4')
    };
    Zuora__SubscriptionProductCharge__c spcToRemove = generateSPC(account, '5');

        // Create a FRC object that is related to the case that has a Sub_Product_Charge_Number__c not in the list.
    Feature_Requested_Cancelled__c frc = new Feature_Requested_Cancelled__c();
    frc.Case__c = fakeCase.Id;
    frc.Status__c = 'Cancelled';
    frc.UniqueId__c = 'abc123';
    frc.Subscription_Product_Charge__c = spcToRemove.Id;
    frc.Sub_Product_Charge_Number__c = spcToRemove.Zuora__ChargeNumber__c;
    insert frc;

    fakeCase = CaseDAO.getInstance().getWithFeatureRequestCancelled(fakeCase.Id);
    CaseService.setMock((CaseService) Test.createStub(CaseService.class,
        new CaseServiceSuccessMock(fakeCase)));

    SubscriptionProductChargeServiceSuccessMock spcMock = new SubscriptionProductChargeServiceSuccessMock(spcs);
    SubscriptionProductChargeService.setMock((SubscriptionProductChargeService) Test.createStub(SubscriptionProductChargeService.class,
        spcMock));

    FeatureRequestedCancelServiceSuccessMock frsMock = new FeatureRequestedCancelServiceSuccessMock();
    FeatureRequestedCancelService.setMock((FeatureRequestedCancelService) Test.createStub(FeatureRequestedCancelService.class,
        frsMock));

    List<Map<String, String>> frcs = FeatureRequestedCanceledAuraController.deserializeSPCList(TEST_JSON_STRING_NOFRC);
    frcs[0].put('spcId', spcs[0].Id);
    frcs[1].put('spcId', spcs[1].Id);
    frcs[2].put('spcId', spcs[2].Id);

    String updatedJson = JSON.serialize(frcs);
    // Update the json string to include the correct SPC Ids
    Test.startTest();
    FeatureRequestedCanceledAuraController.updateFRCs(fakeCase.Id, updatedJSON);
    Test.stopTest();

    System.assertEquals(1, frsMock.getDeleted().size());
    System.assertEquals(3, frsMock.getUpserted().size());

    Feature_Requested_Cancelled__c deletedFRC = frsMock.getDeleted()[0];
    System.assertEquals('5', deletedFRC.Sub_Product_Charge_Number__c);

  }

  @IsTest
  static void testGetFRCMapForCase() {

    Case testCase = new Case();
    insert testCase;

    Feature_Requested_Cancelled__c frc = new Feature_Requested_Cancelled__c();
    frc.Sub_Product_Charge_Number__c = '1';
    frc.UniqueId__c = '123abc';
    frc.Case__c = testCase.Id;
    insert frc;

    Feature_Requested_Cancelled__c frc2 = new Feature_Requested_Cancelled__c();
    frc2.Sub_Product_Charge_Number__c = '2';
    frc2.UniqueId__c = 'abc123';
    frc2.Case__c = testCase.Id;
    insert frc2;

    Case linkedCase = CaseDAO.getInstance().getWithFeatureRequestCancelled(testCase.Id);
    System.assertNotEquals(null, linkedCase);

    Test.startTest();
    Map<String, Feature_Requested_Cancelled__c> result = FeatureRequestedCanceledAuraController.getFRCMapForCase(linkedCase);
    Test.stopTest();

    System.assertEquals(2, result.size());

  }

  @IsTest
  static void testGetFRCMapForCaseNoResults() {

    Case testCase = new Case();
    insert testCase;

    Case linkedCase = CaseDAO.getInstance().getWithFeatureRequestCancelled(testCase.Id);
    System.assertNotEquals(null, linkedCase);

    Test.startTest();
    Map<String, Feature_Requested_Cancelled__c> result = FeatureRequestedCanceledAuraController.getFRCMapForCase(linkedCase);
    Test.stopTest();

    System.assertEquals(0, result.size());

  }

  @IsTest
  static void testGetFCRStatuses() {
    List<SelectOption> statusOptions = FeatureRequestedCancelService.getInstance().getStatusOptions();
    System.assertNotEquals(0, statusOptions.size());

    Test.startTest();
    List<Map<String, Object>> results = FeatureRequestedCanceledAuraController.getFCRStatuses();
    Test.stopTest();

    System.assertEquals(statusOptions.size(), results.size());
    for(SelectOption so: statusOptions) {
      Integer index = statusOptions.indexOf(so);
      Map<String, Object> result = results[index];
      System.assertEquals(so.getLabel(), result.get(FeatureRequestedCanceledAuraController.LABEL));
      System.assertEquals(so.getValue(), String.valueOf(result.get(FeatureRequestedCanceledAuraController.VALUE)));
    }
  }

  @IsTest
  static void testDeserializeSPCListEmpty() {

    String testJsonString = '[]';
    Test.startTest();
    List<Map<String, String>> result = FeatureRequestedCanceledAuraController.deserializeSPCList(testJsonString);
    Test.stopTest();

    System.assertEquals(0, result.size());
  }

  @IsTest
  static void testDeserializeSPCListHasValues() {

    Test.startTest();
    List<Map<String, String>> result = FeatureRequestedCanceledAuraController.deserializeSPCList(TEST_JSON_STRING);
    Test.stopTest();

    System.assertEquals(3, result.size());
    Map<String, String> item = result[0];
    System.assertEquals('2', item.get('SubProductChargeNumber'));
    System.assertEquals('a1Tq0000002NmOBEA0', item.get('spcId'));
    System.assertEquals('Requested Cancelled', item.get('Status'));
    System.assertEquals('a1Aq0000001JkyyEAC', item.get('frcId'));
  }

  class CaseServiceSuccessMock extends CaseServiceMock {
    Case caseValue;

    public CaseServiceSuccessMock(Case caseValue) {
      this.caseValue = caseValue;
    }

    public override Case getCaseWithFeatureRequestCancelled(Id caseId) {
      return this.caseValue;
    }
  }

  class CaseServiceExceptionMock extends CaseServiceMock {

    public override Case getCaseWithFeatureRequestCancelled(Id caseId) {
      throw new Exceptions.ServiceException('Failure.');
    }
  }

  class SubscriptionProductChargeServiceSuccessMock extends SubscriptionProductChargeServiceMock {
    List<Zuora__SubscriptionProductCharge__c> spcs;
    public SubscriptionProductChargeServiceSuccessMock(List<Zuora__SubscriptionProductCharge__c> spcs) {
      this.spcs = spcs;
    }

    public override List<Zuora__SubscriptionProductCharge__c> getActiveForAccount(Id accountId) {
      return this.spcs;
    }

  }

  class SubscriptionProductChargeServiceExceptionMock extends SubscriptionProductChargeServiceMock {

    public override List<Zuora__SubscriptionProductCharge__c> getActiveForAccount(Id accountId) {
      throw new Exceptions.ServiceException('spc failure');
    }

  }

  class FeatureRequestedCancelServiceSuccessMock extends FeatureRequestedCancelServiceMock {
    private List<Feature_Requested_Cancelled__c> upserted;
    private List<Feature_Requested_Cancelled__c> deleted;

    public FeatureRequestedCancelServiceSuccessMock() {
      this.upserted = new List<Feature_Requested_Cancelled__c>();
      this.deleted = new List<Feature_Requested_Cancelled__c>();
    }
    public List<Feature_Requested_Cancelled__c> getUpserted() {
      return this.upserted;
    }

    public List<Feature_Requested_Cancelled__c> getDeleted() {
      return this.deleted;
    }

    public override void upsertFRCs(List<Feature_Requested_Cancelled__c> frcs) {
      this.upserted = frcs;
    }

    public override void deleteFRCs(List<Feature_Requested_Cancelled__c> frcs) {
      this.deleted = frcs;
    }
  }

}