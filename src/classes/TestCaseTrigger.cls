@isTest
private class TestCaseTrigger {
  @testSetup static void createTestData(){
    TestClassUtility.createTriggerHandlerAccessSetting(true,'Case','CaseTriggerHandler');

  }

  @isTest static void createCaseWithoutRecordType() {
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard Platform User' LIMIT 1];
    User u = new User(
      Alias = 'standt', 
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8', 
      LastName = 'Testing', 
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US', 
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/Los_Angeles', 
      SalesRepID__c = '12345',
      UserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com'
    );

    System.runAs(u) {
      Case mockCase = new Case();
      Test.startTest();

      insert mockCase;
   
      Test.stopTest();  

      system.assert(mockCase.Id != null); 
    }  
  }

  @isTest static void testAssignRecentCaseOwners() {
    Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Case.getRecordTypeInfosByName();
    Account acc = TestClassUtility.createAccount(true);
    Contact con = TestClassUtility.createContact(true, acc);
    
    Set<Id> accountSet = new Set<Id>{acc.Id};
    Map<Id, Contact> relatedContactMap = new Map<Id, Contact>();
    relatedContactMap.put(con.Id, con);

    Case mockCase = new Case();
    mockCase.recordTypeId = rtMapByName.get('Inbound').getRecordTypeId();
    mockCase.AccountId = acc.id;
    insert mockCase;

    Test.startTest();

    List<Case> ownerAssignmentCaseList =  new List<Case>();
    Case mockCase0 = new Case();
    mockCase0.recordTypeId = rtMapByName.get('Inbound').getRecordTypeId();
    mockCase0.AccountId = acc.id;
    mockCase0.OwnerId = [SELECT Id FROM User WHERE Id !=: UserInfo.getUserId() LIMIT 1].Id;
    ownerAssignmentCaseList.add(mockCase0);

    Case mockCase1 = new Case();
    mockCase1.recordTypeId = rtMapByName.get('Inbound').getRecordTypeId();    
    mockCase1.ContactId = con.id;
    mockCase1.OwnerId = [SELECT Id FROM User WHERE Id !=: UserInfo.getUserId() LIMIT 1].Id;
    ownerAssignmentCaseList.add(mockCase1);

    CaseTriggerHandler.assignRecentCaseOwners(ownerAssignmentCaseList, accountSet, relatedContactMap);
    Test.stopTest();

    system.assert(mockCase0.OwnerId == UserInfo.getUserId());
    system.assert(mockCase1.OwnerId == UserInfo.getUserId());
  }

  @isTest static void createReviewCase() {
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard Platform User' LIMIT 1];
    User u = new User(
      Alias = 'standt', 
      isActive = true,
      title = 'Account Manager',
      Email = 'testEmail@test.com',
      EmailEncodingKey = 'UTF-8', 
      LastName = 'Testing', 
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US', 
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/Los_Angeles', 
      SalesRepID__c = '12345',
      UserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com'
    );
    insert u;

    Test.startTest();

    String content = 'Review Details:\r\n';
           content += 'Review Id: 1356749,\r\n';
           content += 'Storefront Id: 6fc9aed0-29c7-4cee-be59-a38f00f7a395,\r\n'; 
           content += 'Display Id: 665527,\r\n';
           content += 'Date: 10/3/2016 10:14 AM,\r\n';
           content += 'Reviewer: 2840263e-d206-4551-bcc5-6818d76772c2.\r\n';

    Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Case.getRecordTypeInfosByName();
    Map<String,Schema.RecordTypeInfo> rtAccMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
    Account acc = TestClassUtility.createAccount(false);
    acc.RecordTypeId = rtAccMapByName.get('Local').getRecordTypeId();
    acc.Email__c = 'testEmail@test.com';
    acc.Strategy_Specialist__c = UserInfo.getUserId();
    acc.OwnerId = u.Id;
    insert acc;

    Contact con = TestClassUtility.createContact(false, acc);
    con.Email = acc.Email__c;
    insert con;

    Contact con2 = TestClassUtility.createContact(false, acc);
    Database.DMLOptions newDMLO = new Database.DMLOptions();
    newDMLO.DuplicateRuleHeader.allowSave = true;
    Database.insert(con2, newDMLO);

    Case mockCase0 = new Case();
    mockCase0.Description = content;  
    mockCase0.recordTypeId = rtMapByName.get('Inbound').getRecordTypeId();
    mockCase0.SuppliedEmail = con.Email;
    mockCase0.AccountId = acc.id;

    Case mockCase1 = new Case();
    mockCase1.Description = content;
    mockCase1.recordTypeId = rtMapByName.get('3 - Reviews').getRecordTypeId();
    mockCase1.SuppliedEmail = con.Email;

    Case mockCase2 = new Case();
    mockCase2.recordTypeId = rtMapByName.get('3 - Reviews').getRecordTypeId();
    mockCase2.AccountId = acc.id;

    Case mockCase3 = new Case();
    mockCase3.recordTypeId = rtMapByName.get('3 - Reviews').getRecordTypeId();
    mockCase3.ContactId = con.id;

    Case mockCase4 = new Case();
    mockCase4.recordTypeId = rtMapByName.get('3 - Reviews').getRecordTypeId();
    mockCase4.ContactId = con.id;
    mockCase4.Status = 'new';

    Case mockCase5 = new Case();
    mockCase5.recordTypeId = rtMapByName.get('3 - Reviews').getRecordTypeId();
    mockCase5.ContactId = con.id;
    mockCase5.SuppliedEmail = con.Email;

    Case mockCase6 = new Case();
    mockCase6.Description = content;  
    mockCase6.recordTypeId = rtMapByName.get('Inbound').getRecordTypeId();
    mockCase6.SuppliedEmail = con.Email;

    insert new list<Case>{mockCase0, mockCase1, mockCase2, mockCase3, mockCase4, mockCase5, mockCase6};

    mockCase3.ContactId = con2.id;

    mockCase4.Status = 'Waiting on Edit';

    update new List<Case>{mockCase3, mockCase4};

    Test.stopTest();

    for(Case caseAssert : [SELECT Response_TimeStamp__c, Response_Times__c, Reported_by__c, SuppliedEmail, 
                            Auto_Reply_Flag__c, Reporter_User_Name__c, Reporter_Type__c
                            FROM Case]){
      if(caseAssert.Id == mockCase0.Id){
        system.assert(caseAssert.Reported_by__c == caseAssert.SuppliedEmail);
        system.assert(caseAssert.Auto_Reply_Flag__c == true);
      }else if(caseAssert.Id == mockCase4.Id){
        system.assert(caseAssert.Response_TimeStamp__c != null);
        system.assert(caseAssert.Response_Times__c != null);
      }
    }
  }

  @isTest static void createReviewCase2() {  
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard Platform User' LIMIT 1];
    User u = new User(
      Alias = 'standt', 
      Email = 'abc@abc.com',
      EmailEncodingKey = 'UTF-8', 
      isActive = true,
      LastName = 'Testing', 
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US', 
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/Los_Angeles', 
      SalesRepID__c = '12345',
      UserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com'
    );
    User u2 = new User(
      Alias = 'stand', 
      Email = 'abc@abc.com',
      EmailEncodingKey = 'UTF-8', 
      isActive = true,
      LastName = 'Testing2', 
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US', 
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/Los_Angeles', 
      SalesRepID__c = '54321',
      UserName = 'standarduser2' + DateTime.now().getTime() + '@testorg.com'
    );
    insert new list<User>{u, u2};

    Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Case.getRecordTypeInfosByName();
    Account acc = TestClassUtility.createAccount(false);
    acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Local').getRecordTypeId();
    acc.Strategy_Specialist__c = UserInfo.getUserId();
    acc.Email__c = 'abc@abc.com';

    Account acc2 = TestClassUtility.createAccount(false);
    acc2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Local').getRecordTypeId();
    acc2.Strategy_Specialist__c = UserInfo.getUserId();
    acc2.Email__c = 'abc@abc.com';

    insert new list<Account>{acc, acc2};

    Contact con = TestClassUtility.createContact(false, acc);
    con.Email = 'abc@abc.com';
    insert con;
    
    Case mockCase = new Case();
    
    mockCase.recordTypeId = rtMapByName.get('3 - Reviews').getRecordTypeId();
    mockCase.SuppliedEmail = 'abc@abc.com';

    Test.startTest();

    insert mockCase;

    Test.stopTest();

    Case caseAssert = [SELECT Reporter_User_Name__c,Reporter_Type__c FROM Case WHERE Id =: mockCase.Id Limit 1];
    system.assert(caseAssert.Reporter_User_Name__c == null);
    system.assert(caseAssert.Reporter_Type__c == null);
  }

  @isTest static void createCancelCase() {
    String content = 'Review Details:\r\n';
           content += 'Review Id: 1356749,\r\n';
           content += 'Storefront Id: 6fc9aed0-29c7-4cee-be59-a38f00f7a395,\r\n'; 
           content += 'Display Id: 665527,\r\n';
           content += 'Date: 10/3/2016 10:14 AM,\r\n';
           content += 'Reviewer: 2840263e-d206-4551-bcc5-6818d76772c2.\r\n';

    Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Case.getRecordTypeInfosByName();

    Account acc = TestClassUtility.createAccount(true);
    acc.Strategy_Specialist__c = UserInfo.getUserId();
    acc.ActiveSubscriptionTCVSummary__c = 5001;
    update acc;

    Account acc2 = TestClassUtility.createAccount(true);
    acc.Strategy_Specialist__c = UserInfo.getUserId();
    acc.ActiveSubscriptionTCVSummary__c = 4500;
    update acc2;

    Contact con = TestClassUtility.createContact(true, acc);
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard Platform User' LIMIT 1];
    User u = new User(
      Alias = 'standt', 
      Email = con.Email,
      EmailEncodingKey = 'UTF-8', 
      isActive = true,
      LastName = 'Testing', 
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US', 
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/Los_Angeles', 
      SalesRepID__c = '12345',
      UserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com'
    );
    insert u;
    
    Case mockCaseWithoutEmail = new Case();
    mockCaseWithoutEmail.recordTypeId = rtMapByName.get('1 - Cancels').getRecordTypeId();
    mockCaseWithoutEmail.Description = content;
    mockCaseWithoutEmail.AccountId = acc.id;
    mockCaseWithoutEmail.ContactId = con.id;

    Case mockCaseWithEmail = new Case();
    mockCaseWithEmail.recordTypeId = rtMapByName.get('1 - Cancels').getRecordTypeId();
    mockCaseWithEmail.Description = content;
    mockCaseWithEmail.ContactId = con.id;
    mockCaseWithEmail.SuppliedEmail = con.Email;

    Case mockCaseWithoutEmail2 = new Case();
    mockCaseWithoutEmail2.recordTypeId = rtMapByName.get('1 - Cancels').getRecordTypeId();
    mockCaseWithoutEmail2.Description = content;
    mockCaseWithoutEmail2.AccountId = acc2.id;
    mockCaseWithoutEmail2.ContactId = con.id;

    Case mockCaseWithoutAccount = new Case();
    mockCaseWithoutAccount.recordTypeId = rtMapByName.get('1 - Cancels').getRecordTypeId();
    mockCaseWithoutAccount.Description = content;
    mockCaseWithoutAccount.ContactId = con.id;

    Test.startTest();

    insert new list<Case>{mockCaseWithoutEmail, mockCaseWithEmail, mockCaseWithoutEmail2, mockCaseWithoutAccount};

    Test.stopTest();

    for(Case caseAssert : [SELECT Priority, Reporter_User_Name__c FROM Case]){
      if(caseAssert.Id == mockCaseWithEmail.Id){
        system.assert(caseAssert.Reporter_User_Name__c != null);
      }else if(caseAssert.Id == mockCaseWithoutEmail.Id){
        system.assert(caseAssert.Priority == 'High');
      }else if(caseAssert.Id == mockCaseWithoutEmail2.Id){
        system.assert(caseAssert.Priority == 'Medium');
      }
    }
  }

  @isTest static void updateCancelCase(){
    
    Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Case.getRecordTypeInfosByName();

    Account acct = TestClassUtility.createAccount(true);
    Contact cont = TestClassUtility.createContact(true);
    Zuora__Subscription__c Subscription = TestClassUtility.createSubscription(true, acct);

    Zuora__Product__c testProduct = TestClassUtility.createZuoraProduct(true);

    Zuora__SubscriptionProductCharge__c testSubscriptionProductCharge = TestClassUtility.createSubscriptionProductCharge(true, acct, Subscription, testProduct);

    Case testCaseWithAccId = new Case();
    testCaseWithAccId.Status = 'new';
    testCaseWithAccId.AccountId = acct.Id;
    testCaseWithAccId.recordTypeId = rtMapByName.get('1 - Cancels').getRecordTypeId();

    Case testCaseWithOwnerId = new Case();
    testCaseWithOwnerId.Status = 'new';
    testCaseWithOwnerId.AccountId = acct.Id;
    testCaseWithOwnerId.recordTypeId = rtMapByName.get('1 - Cancels').getRecordTypeId();

    Case testCaseWithoutAccId = new Case();
    testCaseWithoutAccId.Status = 'new';
    testCaseWithoutAccId.AccountId = acct.Id;
    testCaseWithoutAccId.ContactId = cont.Id;
    testCaseWithoutAccId.recordTypeId = rtMapByName.get('1 - Cancels').getRecordTypeId();

    Case testCaseWithAccId2 = new Case();
    testCaseWithAccId2.Status = 'new';
    testCaseWithAccId2.AccountId = acct.Id;
    testCaseWithAccId2.recordTypeId = rtMapByName.get('1 - Cancels').getRecordTypeId();

    insert new List<Case>{testCaseWithAccId, testCaseWithoutAccId, testCaseWithOwnerId, testCaseWithAccId2};

    Feature_Requested_Cancelled__c testCancelledFRC = new Feature_Requested_Cancelled__c();
    testCancelledFRC.Case__c = testCaseWithAccId.Id;
    testCancelledFRC.Status__c = 'Cancelled';
    testCancelledFRC.UniqueId__c = '1234';  

    Feature_Requested_Cancelled__c testNoCancelledFRC = new Feature_Requested_Cancelled__c();
    testNoCancelledFRC.Case__c = testCaseWithAccId2.Id;
    testNoCancelledFRC.Status__c = 'Cancelled';
    testNoCancelledFRC.Subscription_Product_Charge__c = testSubscriptionProductCharge.Id;
    testNoCancelledFRC.UniqueId__c = '123';  
    insert new List<Feature_Requested_Cancelled__c>{testCancelledFRC, testNoCancelledFRC};

    Test.startTest();
    testCaseWithOwnerId.OwnerId = [SELECT Id FROM User WHERE Id !=: UserInfo.getUserId() LIMIT 1].Id;

    testCaseWithoutAccId.AccountId = null;

    testCaseWithAccId2.Outcome__c = 'Cancelled';
    testCaseWithAccId2.Status = 'Closed';
    testCaseWithAccId2.Case_Closed_Flag__c = false;

    List<Case> caseListToUpdate = new List<Case>{testCaseWithOwnerId, testCaseWithoutAccId, testCaseWithAccId2};
    Database.update(caseListToUpdate, false);

    Integer invocations = Limits.getEmailInvocations();
    system.assert(invocations > 0);
    Test.stopTest();
  }

  @isTest static void updateOnboardingCase(){
    User u = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
    Group testGroup;
    QueuesObject testQueue;
    System.runAs(u){
      testGroup = new Group(Name = 'test group', type = 'Queue');
      insert testGroup;

      testQueue = new QueueSObject(QueueID = testGroup.id, SobjectType = 'Case');
      insert testQueue;
    }
    
    Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Case.getRecordTypeInfosByName();

    Account acct = TestClassUtility.createAccount(false);
    acct.Name = 'testAccount1';
    Account acct2 = TestClassUtility.createAccount(false);
    acct2.Name = 'testAccount2';
    insert new List<Account>{acct, acct2};

    Contact cont = TestClassUtility.createContact(false);
    cont.FirstName = 'Stuck';
    cont.LastName = 'testContact1';
    Contact cont2 = TestClassUtility.createContact(false);
    cont2.FirstName = 'Rogers';
    cont2.LastName = 'testContact2';
    insert new List<Contact>{cont, cont2};


    Zuora__Subscription__c Subscription = TestClassUtility.createSubscription(true, acct);
    Zuora__Product__c testProduct = TestClassUtility.createZuoraProduct(true);

    Zuora__SubscriptionProductCharge__c testSubscriptionProductCharge = TestClassUtility.createSubscriptionProductCharge(true, acct, Subscription, testProduct);

    Case testNoCancelledCase = new Case();
    testNoCancelledCase.Status = 'new';
    testNoCancelledCase.AccountId = acct.Id;
    testNoCancelledCase.ContactId = cont.Id;
    testNoCancelledCase.recordTypeId = rtMapByName.get('2 - Onboarding').getRecordTypeId();

    Case testCaseWithQueue = new Case();
    testCaseWithQueue.Status = 'new';
    testCaseWithQueue.AccountId = acct2.Id;
    testCaseWithQueue.ContactId = cont2.Id;
    testCaseWithQueue.OwnerId = testGroup.Id;
    testCaseWithQueue.recordTypeId = rtMapByName.get('2 - Onboarding').getRecordTypeId();
    Test.startTest();
    insert new List<Case>{testNoCancelledCase, testCaseWithQueue};
    
    Feature_Requested_Cancelled__c testNoCancelledFRC = new Feature_Requested_Cancelled__c();
    testNoCancelledFRC.Case__c = testNoCancelledCase.Id;
    testNoCancelledFRC.Status__c = 'Cancelled';
    testNoCancelledFRC.Subscription_Product_Charge__c = testSubscriptionProductCharge.Id;
    testNoCancelledFRC.UniqueId__c = '123';  
    insert testNoCancelledFRC;

    testCaseWithQueue.OwnerId = UserInfo.getUserId();
    testNoCancelledCase.Outcome__c = 'Cancelled';
    testNoCancelledCase.Status = 'Closed';
    testNoCancelledCase.Case_Closed_Flag__c = false;
    update new List<Case>{testNoCancelledCase, testCaseWithQueue};
   
    Test.stopTest();

    List<Task> onboardingTaskList = [SELECT Id FROM Task WHERE Purpose__c = 'Onboarding'];
    system.assert(onboardingTaskList.size() > 0);
  }
}