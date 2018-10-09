@isTest
private class ContactTriggerTest {
    
    @isTest static void testNationalContact() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Test.startTest();
        Map<String, SObject> natDataMap = TestClassUtility.buildNationalData();
        Test.stopTest();

        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        User nationalUser = userList[0];

        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        
        Contact testContact = (Contact)natDataMap.get('Contact');
        testContact.OwnerId = nationalUser.id;
        update testContact;
    }
    
    @isTest static void testActiveRegularExpression() {

        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        Test.startTest();
        Map<String, SObject> natDataMap = TestClassUtility.buildLocalData(false);
        Test.stopTest();

        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
 
        CountryZipREGEX__c testCzrUS = TestClassUtility.createContryZipREGEX(true,'United States','US');
        CountryZipREGEX__c testCzrCA = TestClassUtility.createContryZipREGEX(false,'CANADA','CA');
        testCzrCA.RegExPattern__c = '^[ABCEGHJKLMNPRSTVXYabceghjklmnprstvxy]{1}\\d{1}[A-Za-z]{1} *(\\d{1}[A-Za-z]{1}\\d{1})?$';
        insert testCzrCA;

        Contact testContact = (Contact)natDataMap.get('Contact');
        testContact.OwnerId = userList[0].id ;
        testContact.OtherCountryCode = 'US';
        testContact.OtherPostalCode = '10005';
        update testContact;
        
        Contact testContact1 = (Contact)natDataMap.get('Contact');
        testContact1.OwnerId = userList[0].id ;
        testContact1.OtherCountryCode = 'CA';
        testContact1.OtherPostalCode = 'a1a 1a1';
        update testContact1;
        
        Account testAccount = (Account)natDataMap.get('Account');
        AccountContactRole testACR = TestClassUtility.createAccountContactRole(false,testAccount,testContact1);
        
        ContactLocalTriggerHandler clth = new ContactLocalTriggerHandler();
        try{
            clth.bulkBefore();
        }catch(exception e){}
        
        clth.beforeInsert(testContact);
        clth.beforeUpdate(testContact,testContact1);
        clth.beforeDelete(testContact);
        clth.afterInsert(testContact);
        clth.afterUpdate(testContact,testContact1);
        clth.afterDelete(testContact);
        clth.andFinally();

    }
    
    @isTest static void testInactiveRegularExpression() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        Test.startTest();
        Map<String, SObject> natDataMap = TestClassUtility.buildLocalData(false);
        Test.stopTest();

        CountryZipREGEX__c testCzr = TestClassUtility.createContryZipREGEX(false,'United States','US');
        CountryZipREGEX__c testCzr1 = TestClassUtility.createContryZipREGEX(false,'CANADA','CA');

        Contact testContact = (Contact)natDataMap.get('Contact');
        testContact.OwnerId = userInfo.getuserId();
        testContact.email = 'test@163.com';
        update testContact;

        Account testAccount = (Account)natDataMap.get('Account');
        AccountContactRole testACR = TestClassUtility.createAccountContactRole(false,testAccount,testContact);     
    }

    @isTest static void testDeleteContact() {
        Account testAccount = TestClassUtility.createAccount(true);              
        Contact testContact = TestClassUtility.createContact(false, testAccount);
        testContact.Phone_Extension__c = '654321';
        testContact.Website__c = 'www.test.com';

        Test.startTest();
        insert testContact;
        delete testContact;
        Test.stopTest();
    }

    @isTest static void testUpdateContact() {
        Account testAccount = TestClassUtility.createAccount(true);               
        Contact testContact = TestClassUtility.createContact(true, testAccount);
        testContact.Phone_Extension__c = '654321';
        testContact.Website__c = 'www.test.com';

        Test.startTest();
        update testContact;
        Test.stopTest();
    }


}