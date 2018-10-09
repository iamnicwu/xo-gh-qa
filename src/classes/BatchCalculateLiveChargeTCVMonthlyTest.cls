@isTest
private class BatchCalculateLiveChargeTCVMonthlyTest {
    static testMethod void testBatch() {
    	Map<String,SObject> loacalData = TestClassUtility.buildLocalData(true);
      Account TestAcc = (Account)loacalData.get('Account');
      TestAcc.Last_AM_Transfer__c = system.today();
      TestAcc.Live_at_Last_Month_Start__c = 100;
      TestAcc.Live_at_Month_Start__c = 0;
      update TestAcc;

      Zuora__SubscriptionProductCharge__c charge = (Zuora__SubscriptionProductCharge__c)loacalData.get('Zuora__SubscriptionProductCharge__c');
      charge.Zuora__Account__c = TestAcc.id;
      charge.Zuora__TotalContractValue__c = 100;
      charge.Zuora__EffectiveStartDate__c = system.today().addDays(-7);
      charge.Zuora__EffectiveEndDate__c = system.today().addDays(7);
      update charge;
     
      Zuora__SubscriptionProductCharge__c charge2 = charge.clone();
      insert charge2;
      
      Test.startTest();
      	database.executebatch(new BatchCalculateLiveChargeTCVMonthly());
      Test.stopTest();

      account acc = [select id, Live_at_Month_Start__c from Account where id =: TestAcc.Id ];
      system.assert(acc.Live_at_Month_Start__c == 200.00);

    }
}