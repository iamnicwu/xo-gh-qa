@isTest 
private class SalesDevAssignmentControllerTest {
	
	@isTest static void test_method_one() {
		Set<String> stringTypes = new Set<String>{'PICKLIST', 'STRING', 'MULTIPICKLIST', 'TEXTAREA'};
		Set<String> numberTypes = new Set<String>{'CURRENCY', 'DOUBLE', 'INTEGER'};
		Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
		Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
		Map<String,Schema.RecordTypeInfo> rtTSRFPMapByName = Schema.SObjectType.ThoughtStarter_RFP__c.getRecordTypeInfosByName();
		List<Schema.FieldSetMember> rfpFieldSetList = SObjectType.ThoughtStarter_RFP__c.FieldSets.Required_RFP_Fields.getFields();
		List<Schema.FieldSetMember> tsFieldSetList = SObjectType.ThoughtStarter_RFP__c.FieldSets.Required_ThoughtStarter_Fields.getFields();
		
		Test.startTest();
		Map<String, SObject> testObjects = TestClassUtility.buildLocalData(false);
		Test.stopTest();

		Account testAccount = (Account)testObjects.get('Account');

		//Create your product
		Product2 prod = new Product2(
			Name = 'Uncategorized Revenue',
			ProductCode = 'Pro-X',
			isActive = true
		);
		insert prod;

		Id pricebookId = Test.getStandardPricebookId();

		//Create your pricebook entry
		PricebookEntry pbEntry = new PricebookEntry(
			Pricebook2Id = pricebookId,
			Product2Id = prod.Id,
			UnitPrice = 100.00,
			IsActive = true
		);
		insert pbEntry;

		List<Opportunity> newOpportunityList = new List<Opportunity>();
		for(Integer i = 0; i < 50; i++){
			Opportunity testOpportunity = new Opportunity();
			testOpportunity.Name = 'Test Opportunity';
			testOpportunity.RecordTypeId = rtOppMapByName.get('National').getRecordTypeId();
			testOpportunity.AccountId = testAccount.Id;
			testOpportunity.StageName = 'Prospecting';
			testOpportunity.CloseDate = date.today().addDays(5);
			testOpportunity.AccStrategist__c = UserInfo.getUserId();
			testOpportunity.Amount = 50000;
			testOpportunity.Description = 'test data for test class';
			newOpportunityList.add(testOpportunity);
		}
		insert newOpportunityList;

		List<ThoughtStarter_RFP__c> tsList = new List<ThoughtStarter_RFP__c>();
		for(Integer i = 0; i < 25; i++){
			ThoughtStarter_RFP__c newThoughtStarter = new ThoughtStarter_RFP__c();
			newThoughtStarter.Opportunity__c = newOpportunityList[i].Id;
			newThoughtStarter.RecordTypeId = rtTSRFPMapByName.get('ThoughtStarter').getRecordTypeId();
			newThoughtStarter.Clicks__c = true;
			newThoughtStarter.CTR__c = 2;
			newThoughtStarter.Submitted_for_Production__c = true;
			newThoughtStarter.Account_Strategist__c = newOpportunityList[i].AccStrategist__c;
			for(Schema.FieldSetMember record : tsFieldSetList){
				String typeValue = String.valueof(record.getType());
				String fieldPathValue = String.valueof(record.getFieldPath());

				if(stringTypes.contains(typeValue) == true){
					newThoughtStarter.put(fieldPathValue, 'Test Value');
				}else if(numberTypes.contains(typeValue) == true){
					newThoughtStarter.put(fieldPathValue, 500);
				}else if(typeValue == 'DATE'){
					newThoughtStarter.put(fieldPathValue, Date.today().addDays(5));
				}
			}
			tsList.add(newThoughtStarter);
		}
		system.debug(tsList);
		insert tsList;

		List<ThoughtStarter_RFP__c> rfpList = new List<ThoughtStarter_RFP__c>();
		for(Integer i = 0; i < 25; i++){
			ThoughtStarter_RFP__c newRFP = new ThoughtStarter_RFP__c();
			newRFP.Opportunity__c = newOpportunityList[i].Id;
			newRFP.RecordTypeId = rtTSRFPMapByName.get('RFP').getRecordTypeId();
			newRFP.Clicks__c = true;
			newRFP.CTR__c = 2;
			newRFP.Submitted_for_Production__c = true;
			newRFP.Account_Strategist__c = newOpportunityList[i].AccStrategist__c;
			for(Schema.FieldSetMember record : rfpFieldSetList){
				String typeValue = String.valueof(record.getType());
				String fieldPathValue = String.valueof(record.getFieldPath());

				if(stringTypes.contains(typeValue) == true){
					newRFP.put(fieldPathValue, 'Test Value');
				}else if(numberTypes.contains(typeValue) == true){
					newRFP.put(fieldPathValue, 500);
				}else if(typeValue == 'DATE'){
					newRFP.put(fieldPathValue, Date.today().addDays(5));
				}
			}
			rfpList.add(newRFP);
		}
		
		SalesDevAssignmentController contr = new SalesDevAssignmentController(new ApexPages.StandardController(new ThoughtStarter_RFP__c()));
		contr.getUnassignedTSRFP();
		contr.refresh();

		system.debug(contr.hasNext);
		system.debug(contr.hasPrevious);
		system.debug(contr.pageNumber);
		contr.last();
		contr.first();
		contr.next();
		contr.previous();

		contr.filterObject.recordType = 'RFP';
		contr.filterObject.nameValues = 'T';
		contr.filterObject.repStrat = 'A';
		contr.filterObject.salesDev = 'a';
		contr.filterResults();
		contr.refresh();

		Id salesDevId = [select Id from User where UserRole.DeveloperName = 'Sales_Development' limit 1].id;

		for(ThoughtStarter_RFP__c record : (List<ThoughtStarter_RFP__c>)contr.setCon.getRecords()){
			record.Sales_Developer__c = salesDevId;
		}

		contr.saveSalesDeveloper();
		
		list<selectOption> testSO = contr.getSortByList();
		
	}
	
}