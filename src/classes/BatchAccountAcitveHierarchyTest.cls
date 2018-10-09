@isTest
private class BatchAccountAcitveHierarchyTest {
    static testMethod void testMethod1() {
    		
    		Test.startTest();
    	  Map<String,SObject> testMap = TestClassUtility.buildLocalData(false);
    	  System.debug(LoggingLevel.INFO, '*** Limits.getQueries(): ' + Limits.getQueries());
    	  Test.stopTest();
    	 
    	  Account testAccount = (Account)testMap.get('Account');
    	  testAccount.Need_to_Recalculate_Active_Hierarchy__c = 'Yes';
    	  update testAccount;

    	  BatchAccountAcitveHierarchy bat = new BatchAccountAcitveHierarchy();
    	  Database.executeBatch(bat);
    	 
    }

    static testMethod void testMethod2() {
    		
				Map<String,Schema.RecordTypeInfo> rtAccountMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();

				Category__c testCategory = TestClassUtility.createCategory(true);
				Region__c testRegion = TestClassUtility.createRegion(true);
				Market__c testMarket = TestClassUtility.createMarket(true, testRegion);

    	  Account testAccount = TestClassUtility.createAccount(false, testCategory, testMarket);
    	  testAccount.Need_to_Recalculate_Active_Hierarchy__c = 'Yes';
    	  testAccount.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
    	  insert testAccount;

    	  Account testAccount2 = TestClassUtility.createAccount(false, testCategory, testMarket);
    	  testAccount2.Need_to_Recalculate_Active_Hierarchy__c = 'Yes';
    	  testAccount2.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
    	  testAccount2.ParentId = testAccount.Id;
    	  insert testAccount2;

				Test.startTest();
    	  BatchAccountAcitveHierarchy bat = new BatchAccountAcitveHierarchy();
    	  Database.executeBatch(bat,10);

    	  Test.stopTest();

    }

    static testMethod void testMethod3() {
    		
				Map<String,Schema.RecordTypeInfo> rtAccountMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();

				TriggerHandlerAccess__c newTHA = new TriggerHandlerAccess__c();
        newTHA.Name = 'AccountTriggerHandler';
        newTHA.Active__c = false;
        newTHA.Handler_Name__c = 'AccountTriggerHandler';
        newTHA.Object__c = 'Account';
        insert 	newTHA;	

				Category__c testCategory = TestClassUtility.createCategory(true);
				Region__c testRegion = TestClassUtility.createRegion(true);
				Market__c testMarket = TestClassUtility.createMarket(true, testRegion);

    	  Account testAccount = TestClassUtility.createAccount(false);
    	  testAccount.Need_to_Recalculate_Active_Hierarchy__c = 'No';
    	  testAccount.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
    	  testAccount.ParentId = null;
    	  insert testAccount;

    	  Account testAccount2 = TestClassUtility.createAccount(false);
    	  testAccount2.Need_to_Recalculate_Active_Hierarchy__c = 'No';
    	  testAccount2.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
    	  testAccount2.ParentId = testAccount.Id;
    	  insert testAccount2;


    	  Account testAccount3 = TestClassUtility.createAccount(false);
    	  testAccount3.Need_to_Recalculate_Active_Hierarchy__c = 'Yes';
    	  testAccount3.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
    	  testAccount3.ParentId = testAccount2.Id;
    	  insert testAccount3;

				Test.startTest();
    	  BatchAccountAcitveHierarchy bat = new BatchAccountAcitveHierarchy();
    	  Database.executeBatch(bat,10);

    	  Test.stopTest();

    }

   static testMethod void testMethod4() {
    		
				Map<String,Schema.RecordTypeInfo> rtAccountMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();

				TriggerHandlerAccess__c newTHA = new TriggerHandlerAccess__c();
        newTHA.Name = 'AccountTriggerHandler';
        newTHA.Active__c = false;
        newTHA.Handler_Name__c = 'AccountTriggerHandler';
        newTHA.Object__c = 'Account';
        insert 	newTHA;	

				Category__c testCategory = TestClassUtility.createCategory(true);
				Region__c testRegion = TestClassUtility.createRegion(true);
				Market__c testMarket = TestClassUtility.createMarket(true, testRegion);

    	  Account testAccount = TestClassUtility.createAccount(false);
    	  testAccount.Need_to_Recalculate_Active_Hierarchy__c = 'No';
    	  testAccount.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
    	  testAccount.ParentId = null;
    	  insert testAccount;

    	  Account testAccount2 = TestClassUtility.createAccount(false);
    	  testAccount2.Need_to_Recalculate_Active_Hierarchy__c = 'No';
    	  testAccount2.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
    	  testAccount2.ParentId = testAccount.Id;
    	  insert testAccount2;


    	  Account testAccount3 = TestClassUtility.createAccount(false);
    	  testAccount3.Need_to_Recalculate_Active_Hierarchy__c = 'No';
    	  testAccount3.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
    	  testAccount3.ParentId = testAccount2.Id;
    	  insert testAccount3;


    	  Account testAccount4 = TestClassUtility.createAccount(false);
    	  testAccount4.Need_to_Recalculate_Active_Hierarchy__c = 'Yes';
    	  testAccount4.RecordTypeId = rtAccountMapByName.get('Local').getRecordTypeId();
    	  testAccount4.ParentId = testAccount3.Id;
    	  insert testAccount4;

				Test.startTest();
    	  BatchAccountAcitveHierarchy bat = new BatchAccountAcitveHierarchy();
    	  Database.executeBatch(bat,10);

    	  Test.stopTest();

    }

}