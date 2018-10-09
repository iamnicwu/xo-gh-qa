/*******************************************************************************
 *  Summary      : Test class for BatchCloseExpiredLocalOppsSchedJob
 *  Refer Object : 
 *  Author       : Tony
 *  RefactorDate : 19 Dec 2016
 *  Change Log   : Refactoring by CSP-1686
 ******************************************************************************/
@isTest
private class BatchUpdateLocalAccountCBSSTest {
    static testMethod void testOne() {
    	Test.startTest();
        //Map<String, SObject> testObjects = TestClassUtility.buildZQUTestObjects(false);
        Map<String, SObject> testObjects = TestClassUtility.buildLocalData(FALSE);
        Set<Id> userIdSet = new Set<Id>();
        List<User> userList = [select Id, Name, ARR__c from User where Id != :UserInfo.getUserId() and isActive = true and ARR__c != null limit 2];
        for (User userRecord : userList) {
            userIdSet.add(userRecord.Id);
        }

        Account testAccount = (Account)testObjects.get('Account');
        // CSP-2315 Update CBSS Information on Account and Billing Account
        // testAccount.OwnerId = userList[0].id;
        testAccount.Override_Account_CBSS__c = True;
        testAccount.CBBS__c =userList[0].id;
        update testAccount;
        System.assertEquals(userList.size(),2);
        Test.stopTest();
        
        BatchUpdateLocalAccountCBSS bb = new BatchUpdateLocalAccountCBSS(userIdSet);
        Database.executeBatch(bb);
    }
}