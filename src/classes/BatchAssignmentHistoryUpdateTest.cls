@isTest
private class BatchAssignmentHistoryUpdateTest {
    @isTest 
    static void setup() {
    	Account testAcc = TestClassUtility.createAccount(true);

    	Category__c testCat = TestClassUtility.createCategory(true);
    	Market__c testMarket = TestClassUtility.createMarket(true);
    	Zip__c testZip = TestClassUtility.createZip(true); 

    	Local_Sales_Rep_Assignment__c localSalesAssgnRec = TestClassUtility.createLocalSalesRepAssignment(false, testCat, testMarket, testZip);
    	localSalesAssgnRec.Zip_Code__c = null;
    	insert localSalesAssgnRec;
                                                                      
    	Assignment_History__c assignmentHistoryRec = new Assignment_History__c();
    	assignmentHistoryRec.Local_Sales_Rep_Assignment__c = localSalesAssgnRec.Id;
    	insert assignmentHistoryRec;

    	Test.startTest();
        BatchAssignmentHistoryUpdate assignmentHistoryUpdateObj = new BatchAssignmentHistoryUpdate();
        Id batchId = Database.executeBatch(assignmentHistoryUpdateObj, 100);
        Test.stopTest();

    }
    
}