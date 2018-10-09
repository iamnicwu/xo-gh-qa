/*******************************************************************************
 *  Summary	     : Test class for AddRemoveRatePlan
 *  Refer Object : 
 *  Author	     : Nick
 *  RefactorDate : 12 Dec 2016
 *  Change Log   : Refactoring by SF-2.6 release
 ******************************************************************************/
@isTest
private class AddRemoveRatePlanTest{

	private static testmethod void testAdd() {
		
		SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
												 'Complete',
												 '{"companyName": "Test Account"}',
												 null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);
		
		Map<String,SObject> testMap = TestClassUtility.buildLocalData(false);
		
		Test.startTest();
		
		List<String> addedRatePlans = new List<String>();
		
		Product2 zp = TestClassUtility.createLocalProduct2(true);
		 zqu__Quote__c q = TestClassUtility.createQuote(true, 
			(Opportunity)testMap.get('Opportunity') , 
			(Account)testMap.get('Account'), 
			(Contact)testMap.get('Contact'));
	
		zqu__ProductRatePlan__c prp = new zqu__ProductRatePlan__c(); 
		prp.Name = 'Rate Plan 1'; 
		prp.zqu__Product__c = zp.id; 
		prp.Capacity__c = '10';
		prp.Market__c = 'Test Market';
		prp.Category__c = 'Test Category';
		prp.zqu__ZuoraId__c = '2c92c0f94e4d3a3d014e655c28c50f5f';
		insert prp;

		zqu__ProductRatePlan__c prp2 = new zqu__ProductRatePlan__c();
		prp2.Name = 'NY - Long Island - Photographers'; 
		prp2.zqu__Product__c = zp.id; 
		prp2.Capacity__c = '10';
		prp2.Market__c = 'Test Market';
		prp2.Category__c = 'Test Category';
		prp2.zqu__ZuoraId__c = '2c92c0f94e4d3a3d014e655c28c50f5t';
		insert prp2;

		addedRatePlans.add(prp2.id);
		addedRatePlans.add(prp.id);

		String quoteId = q.id;
		AddRemoveRatePlan ARRP = new AddRemoveRatePlan();
		
		// avoid call out error in test class
		try {
			arrp.onAdd(quoteId,addedRatePlans);
		}
		catch (Exception e) {
		}

		Test.stopTest();
	}

	private static testmethod void testRemove() {
		
		SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
												 'Complete',
												 '{"companyName": "Test Account"}',
												 null);
		Test.setMock(HttpCalloutMock.class, fakeResponse);
		
		Map<String,SObject> testMap = TestClassUtility.buildLocalData(false);
		
		Test.startTest();

		List<String> addedRatePlans = new List<String>();
		
		Product2 zp =  TestClassUtility.createLocalProduct2(true);
		 zqu__Quote__c q = TestClassUtility.createQuote(true, 
			(Opportunity)testMap.get('Opportunity') , 
			(Account)testMap.get('Account'), 
			(Contact)testMap.get('Contact'));

		zqu__ProductRatePlan__c prp = new zqu__ProductRatePlan__c(); 
		prp.Name = 'Basic'; 
		prp.zqu__Product__c = zp.id; 
		prp.Capacity__c = '10';
		prp.Market__c = 'Test Market';
		prp.Category__c = 'Test Category';
		prp.zqu__ZuoraId__c = '2c92c0f94e4d3a3d014e655c28c50f5f';
		insert prp;

		List<String> removedRatePlans = new List<String>();
		removedRatePlans.add(prp.id);
		String quoteId = q.id;
		AddRemoveRatePlan ARRP = new AddRemoveRatePlan();

		// avoid call out error in test class
		try{
			arrp.onRemove(quoteId,removedRatePlans);
		}
		catch(exception e)
		{}
		Test.stopTest();
	}
}