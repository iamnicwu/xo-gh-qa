@isTest(SeeAllData = true)
private class LocalSalesRepTeamAssignmentTest{
    @isTest static void test_method_one() {
        
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        
        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        
        LocalSalesRepTeamAssignmentController testcase = new LocalSalesRepTeamAssignmentController(); 
        testcase.saveSalesRepRecord();
        
    }
}