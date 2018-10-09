@isTest(SeeAllData = false)

private class TestBatchInventoryNew {

    static testmethod void test() {
        // The query used by the batch job.
        
        String query =  'SELECT Id,Name,Capacity__c,Product_Rate_Plan__c,Available__c,Inventory_Held__c,Waitlist_Count__c,(Select Id,Account__c,Product_Rate_Plan__c FROM Waitlists__r ORDER BY Sort_Order__c) FROM zqu__ProductRatePlan__c where Available__c = true';

        Test.startTest();
        Map<String, SObject> testData =TestClassUtility.buildLocalData(false);
        Test.stopTest();
       
        Account testAccount = (Account)testData.get('Account');
       
        Zuora__Product__c testZuoraProduct = new Zuora__Product__c();
        testZuoraProduct.Zuora__Description__c = 'Test Product';
        testZuoraProduct.Zuora__EffectiveEndDate__c = Date.Today();
        testZuoraProduct.Zuora__External_Id__c = '123ed';
        testZuoraProduct.ProductType__c = 'Internet';
        testZuoraProduct.Zuora__SKU__c = 'SKU-00000044';
        insert testZuoraProduct;
       
        Zuora__Subscription__c testZquSubscription = new Zuora__Subscription__c();
        testZquSubscription.Name = 'Test Subscription';
        testZquSubscription.Zuora__SubscriptionStartDate__c = Date.Today();
        testZquSubscription.Zuora__SubscriptionEndDate__c = Date.Today() + 365;
        testZquSubscription.Zuora__Status__c = 'Active';
        testZquSubscription.NeedToUpdateSubscriptionCreator__c = False;
        insert testZquSubscription;
        
        Zuora__SubscriptionProductCharge__c testZquSubscriptionProductCharge = new Zuora__SubscriptionProductCharge__c();
        testZquSubscriptionProductCharge.Name = 'Test Subscription Product Charge';
        testZquSubscriptionProductCharge.Zuora__EffectiveEndDate__c = Date.newinstance(2015, 9, 10);
        testZquSubscriptionProductCharge.Zuora__RatePlanEffectiveEndDate__c = Date.newinstance(2015, 9, 30);
        testZquSubscriptionProductCharge.Zuora__Zuora_Id__c = 'zinrid12nd45oidl';
        testZquSubscriptionProductCharge.Quote_Rate_Plan_ID__c = 'qweqweqwe';
        testZquSubscriptionProductCharge.Zuora__RatePlanId__c = 'asdasdasdasdas';
        testZquSubscriptionProductCharge.Zuora__Subscription__c = testZquSubscription.id;
        testZquSubscriptionProductCharge.Zuora__ProductName__c = 'Test Product';
        testZquSubscriptionProductCharge.Zuora__RatePlanName__c = 'Test Product Rate Plan';
        testZquSubscriptionProductCharge.Zuora__Product__c = testZuoraProduct.id;
        testZquSubscriptionProductCharge.Zuora__ChargeNumber__c = 'asdasdasdasdas';
        insert testZquSubscriptionProductCharge;
        
        Zuora__SubscriptionProductCharge__c testZquSubscriptionProductCharge1 = new Zuora__SubscriptionProductCharge__c();
        testZquSubscriptionProductCharge1.Name = 'Test Subscription Product Charge';
        testZquSubscriptionProductCharge1.Zuora__EffectiveEndDate__c = Date.newinstance(2015, 9, 10);
        testZquSubscriptionProductCharge1.Zuora__RatePlanEffectiveEndDate__c = Date.newinstance(2015, 9, 28);
        testZquSubscriptionProductCharge1.Zuora__Zuora_Id__c = 'zinrid12nd45oidl';
        testZquSubscriptionProductCharge1.Quote_Rate_Plan_ID__c = 'qweqweqwe';
        testZquSubscriptionProductCharge1.Zuora__RatePlanId__c = 'asdasdasdasdas';
        testZquSubscriptionProductCharge1.Zuora__Subscription__c = testZquSubscription.id;
        testZquSubscriptionProductCharge1.Zuora__ProductName__c = 'Test Product';
        testZquSubscriptionProductCharge1.Zuora__RatePlanName__c = 'Test Product Rate Plan';
        testZquSubscriptionProductCharge1.Zuora__Product__c = testZuoraProduct.id;
        testZquSubscriptionProductCharge1.Zuora__ChargeNumber__c = 'asdasdasdasdasasas';
        insert testZquSubscriptionProductCharge1;

       
       Product2 testProduct= TestClassUtility.createLocalProduct2(true);
       testProduct.zqu__EffectiveStartDate__c = Date.today();
       testProduct.zqu__EffectiveEndDate__c = Date.today()+20;
       testProduct.ProductType__c = 'Internet';
       testProduct.zqu__SKU__c = 'test sku';
       testProduct.zqu__ZuoraId__c = '1000001';
       testProduct.name = 'Test Storefront';
       update testProduct;
       
       zqu__ProductRatePlan__c ProdPlan= new zqu__ProductRatePlan__c();
       ProdPlan.Capacity__c = '10';
       ProdPlan.zqu__Product__c = testProduct.Id;
       ProdPlan.zqu__ZuoraId__c = '1000001';
       //ProdPlan.Available__c = True;
       insert ProdPlan;
       
       Inventory__c Inv = new Inventory__c();  
       //Inv.Name = 'Inventory001';
       Inv.Inventory_Hold_Expiry_Date__c = Date.today()+5;
       Inv.Last_Expiry_Date_for_Account__c = Date.today()+10;
       Inv.Product_Rate_Plan__c = ProdPlan.Id;
       Inv.Subscription_RatePlan_Id__c = 'asdasdasdasdas';
       insert Inv;
       
       Inventory__c Inv1 = new Inventory__c();
       //Inv1.Name = 'Inventory002';
       Inv1.Inventory_Hold_Expiry_Date__c = Date.today()-5;
       //Inv1.Last_Expiry_Date_for_Account__c = '';
       Inv1.Product_Rate_Plan__c = ProdPlan.Id;
       //Inv1.Available__c= True;
       insert Inv1;
       
       Inventory__c Inv2 = new Inventory__c();    
       //Inv.Name = 'Inventory003';
       Inv2.Inventory_Hold_Expiry_Date__c = Date.today()+5;
       //Inv2.Last_Expiry_Date_for_Account__c = Date.today()+10;
       Inv2.Product_Rate_Plan__c = ProdPlan.Id;
       Inv2.Subscription_RatePlan_Id__c = 'asdasdasdasdasasas';
       //Inv.Available__c= True;
       insert Inv2;
       
       Inventory__c Inv3 = new Inventory__c();    
       //Inv.Name = 'Inventory003';
       Inv3.Inventory_Hold_Expiry_Date__c = Date.today()+5;
       //Inv3.Last_Expiry_Date_for_Account__c = Date.today()+10;
       Inv3.Product_Rate_Plan__c = ProdPlan.Id;
       Inv3.Subscription_RatePlan_Id__c = 'asdasdasdasdas';
       Inv3.Waitlist_Account__c = testAccount.Id;
       insert Inv3;
       
       Waitlist__c Wait = new Waitlist__c();
       //Wait.Name = 'WaitList1';
       wait.Product_Rate_Plan__c = ProdPlan.Id;
       wait.Sort_Order_Override__c = 1;
       insert wait;
       

       
       BatchInventoryNew c = new BatchInventoryNew();
       Database.executeBatch(c);
       

      
    }
}