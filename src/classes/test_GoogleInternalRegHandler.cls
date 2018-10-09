/**
For testing the Google SSO handler
 */
@isTest
private class test_GoogleInternalRegHandler {
    // an GoogleID that will match a User
    static String testUserEmailSuccess = 'qtarantino@xogrp.com';
    // an GoogleId that will fail to match a User
    static String testUserEmailFailure = 'xyz';
    static String testUserFirstName = 'Quentin';
    static String testUserLastName = 'Tarantino';
    
    static testMethod void testCreateAndUpdateUser() {
        // create the supporting objects
        GoogleInternalRegHandler handler = new GoogleInternalRegHandler();
        boolean exceptionThrown = false;
        
        // create a test user
        User u = new User();
        Profile p = [SELECT Id FROM profile WHERE name='Standard User'];
        u.username = testUserEmailSuccess + '.testsuccess';
        u.email = testUserEmailSuccess;
        u.lastName = testUserLastName;
        u.firstName = testUserFirstName;
        u.GoogleID__c = testUserEmailSuccess;
        String alias = testUserEmailSuccess;
        if(alias.length() > 8) {
            alias = alias.substring(0, 8);
        }
        u.alias = alias;
        u.languagelocalekey = 'en_US';
        u.localesidkey = 'en_US';
        u.emailEncodingKey = 'UTF-8';
        u.timeZoneSidKey = 'America/Los_Angeles';
        u.profileId = p.Id;
        u.SalesRepID__c = '11111';
        insert u;

        //***** testing CreateUser
        // test the exceptions
        // if no email passed, expect an exception
        Auth.UserData dataFailNoEmail = CreateTestUserDataForAuth('');
        try
        {
            exceptionThrown = false;
            User createUserFail = handler.createUser(null, dataFailNoEmail);
        }
        catch (Exception eEmail)
        {
            exceptionThrown = true;
        }
        System.assertEquals(exceptionThrown,true);
        
        // if the system passes an unmatched user, expect an exception
        Auth.UserData dataFail = CreateTestUserDataForAuth(testUserEmailFailure);
        try
        {
            exceptionThrown = false;
            User createUserFail = handler.createUser(null, dataFail);
        }
        catch (Exception e)
        {
            exceptionThrown = true;
        }
        System.assertEquals(exceptionThrown,true);
        
        // test the success
        Auth.UserData dataSuccess = CreateTestUserDataForAuth(testUserEmailSuccess);
        User createUserSuccess = handler.createUser(null, dataSuccess);
        System.assertEquals(testUserEmailSuccess, createUserSuccess.GoogleID__c);
        
        
        //***** testing UpdateUser
        
        // test the success
        handler.updateUser(createUserSuccess.Id, null, dataSuccess);
        User updatedUser = [SELECT userName, email, firstName, lastName, alias FROM user WHERE id=:createUserSuccess.Id];
        System.assertEquals(testUserLastName, updatedUser.lastName);
        System.assertEquals(testUserFirstName, updatedUser.firstName);
        

        // test the exception by passing an invalid ID
        try
        {
            exceptionThrown = false;
            handler.updateUser('xxxx' + String.ValueOf(createUserSuccess.Id), null, dataSuccess);
        }
        catch (Exception eBadID)
        {
            exceptionThrown = true;
        }
        System.assertEquals(exceptionThrown,true);

    }
    
    
    // Pass a GoogleID to create a test set of auth data
    private static Auth.UserData CreateTestUserDataForAuth(string GoogleID)
    {
        return new Auth.UserData(GoogleID, testUserFirstName, testUserLastName,
            testUserFirstName + ' ' + testUserLastName, GoogleID, null, 'testuserlong', 'en_US', 'Gmail',
            null, new Map<String, String>{'language' => 'en_US'});
    }
}