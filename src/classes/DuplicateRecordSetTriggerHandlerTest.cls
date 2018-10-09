@isTest
public class DuplicateRecordSetTriggerHandlerTest {

	static testMethod void unitTest() {

        List<XO_Exception__c> exceptionList = new List<XO_Exception__c>();
        DuplicateRecordSet duplicateRecordSetRec;

		try {
    		DuplicateRule duplicateRuleRec = [SELECT Id FROM DuplicateRule WHERE DeveloperName = 'Local_Lead_to_Lead_Duplicate_Rule' LIMIT 1];
    		duplicateRecordSetRec = new DuplicateRecordSet(DuplicateRuleId = duplicateRuleRec.id);
		    if(duplicateRecordSetRec != null) {
		    	insert duplicateRecordSetRec;
			}
    	} catch (Exception e) {
            XO_Exception__c xoException = ExceptionUtility.consumeException(e, false);
            xoException.Severity__c = 'Minor';
            xoException.Failure_Area__c = 'DuplicateRecordSetTriggerHandlerTest.cls';
            exceptionList.add(xoException);
        }

        if(!exceptionList.isEmpty()) {
        	insert exceptionList;
    	}

		Test.startTest();
        	Map<String, SObject> testLocalDate = TestClassUtility.buildLocalData(false);
        Test.stopTest();

        Category__c testCategory = (Category__c)testLocalDate.get('Category__c');
        Market__c testMarket = (Market__c)testLocalDate.get('Market__c');

        Lead leadRecord = TestClassUtility.createLead(false,testMarket,testCategory); 
        leadRecord.Email = 'testDuplicateRec@test.com';
        leadRecord.PostalCode = '78731';
        insert leadRecord;

        // this gives us the ability to insert duplicate record 
        Database.DMLOptions insertDML = new Database.DMLOptions(); 
        insertDML.DuplicateRuleHeader.AllowSave = true; 

        Lead duplicateLeadRecord = TestClassUtility.createLead(false,testMarket,testCategory); 
        duplicateLeadRecord.Email = 'testDuplicateRec@test.com';
        duplicateLeadRecord.PostalCode = '78731';
        Database.SaveResult sr = Database.insert(duplicateLeadRecord, insertDML);

        // inserting duplicate record item record
        DuplicateRecordItem duplicateRecordItemRec = new DuplicateRecordItem(DuplicateRecordSetId = duplicateRecordSetRec.id, RecordId=duplicateLeadRecord.id);
        insert duplicateRecordItemRec;
    }
}