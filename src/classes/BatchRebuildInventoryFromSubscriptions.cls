/* 
<Class>
  <name>BatchRebuildInventoryFromSubscriptions</name>
  <purpose>Creates inventory records based on the Subscription Product & Charge data
  </purpose>
  <created>
    <by>Steve O'Neal</by>
    <date>03/07/2016</date>
    <ticket>CSP-576</ticket>
  </created>
</Class>
*/
global class BatchRebuildInventoryFromSubscriptions implements Database.Batchable<sObject> {
	public string query = '';
	Map<String, Product2> productsMap = new Map<String, Product2>();
    Inventory_Hold_Expiry_Date_Offsets__c invHoldExpDate;
	
	global BatchRebuildInventoryFromSubscriptions()
	{
		invHoldExpDate = Inventory_Hold_Expiry_Date_Offsets__c.getOrgDefaults();
		
		List<Product2> productsWithCapacity = [select zqu__ZuoraId__c, Consolidate_Inventory__c from Product2 where zqu__Deleted__c = false];
		
		String queryRatePlanFilter = '';
		String comma = '';
		
		for (Product2 productWithCapacity : productsWithCapacity)
		{
			productsMap.put(productWithCapacity.zqu__ZuoraId__c, productWithCapacity);
			queryRatePlanFilter += comma + '\'' + productWithCapacity.zqu__ZuoraId__c + '\'';
			comma = ',';
		}
		
		query = ' SELECT ID, Name, Zuora__RatePlanName__c, Zuora__RatePlanEffectiveEndDate__c, Zuora__RatePlanId__c, Zuora__Subscription__r.Zuora__TermEndDate__c, Zuora__Product__r.Zuora__External_Id__c'
			  + ' FROM Zuora__SubscriptionProductCharge__c'
			  + ' WHERE Zuora__Product__r.Zuora__External_Id__c in (' + queryRatePLanFilter + ')'
			  + '   AND Zuora__Subscription__r.Zuora__TermEndDate__c >= TODAY'
			  + '   AND Name not in (\'Charge #01\',\'Charge #02\',\'Charge #03\',\'Charge #04\',\'Charge #05\',\'Charge #06\',\'Charge #07\',\'Charge #08\',\'Charge #09\',\'Charge #10\',\'Charge #11\',\'Charge #12\',\'80% Balance Due\')'
			  + '   AND Do_not_create_inventory__c != \'Yes\'';
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		Database.QueryLocator retVal = Database.getQueryLocator(query);
		return retVal;
	}
	
	global string NormalizeProductRatePlanName(string ratePlanName, string consolidateInventory)
	{
		string retVal = ratePlanName;

		// CSP-1766 | reduce retVal (ratePlanName) if charlength > 80; zqu__ProductRatePlan__c.Name has a max
		// length of 80 chars, but Zuora__SubscriptionProductCharge__c.Zuora__RatePlanName__c can be up to 255 chars
		if (retVal.length() > 80) {
			retVal = retVal.left(80);
		}
		
		retVal = retVal.Replace('^','|');
   		if (consolidateInventory == 'By Product and Market')
   		{
   			//if the ratePlanName is composed of ProductName and MarketName, we shouldn't do any thing
   			//if the ratePlanName is composed of ProductName and MarketName and CategoryName, we should delete the CategoryName from the ratePlanName
   			integer numberOfPipe = retVal.countMatches('|');
   			if(numberOfPipe > 1){
   				integer lastPipeIndex = retVal.lastIndexOf('|');
	   			if (lastPipeIndex > 0)
	   			{
	   				retVal = retVal.left(lastPipeIndex).trim();
	   			}
   			}
   		}
		return retVal;
	}

   	global void execute(Database.BatchableContext BC, List<Zuora__SubscriptionProductCharge__c> scope) {
		//System.Debug('Entering BatchRebuildInventoryFromSubscriptions.execute.');
   		List<Inventory__c> InventoryList = new List<Inventory__c>();
   		try
   		{
   			Set<string> ProductRatePlans = new Set<string>();
	   		for (Zuora__SubscriptionProductCharge__c spc : scope)
	   		{
	   			String ratePlanName = NormalizeProductRatePlanName(spc.Zuora__RatePlanName__c, productsMap.get(spc.Zuora__Product__r.Zuora__External_Id__c).Consolidate_Inventory__c);
	   			//System.Debug('Adding the rate plan ' + spc.Zuora__RatePlanName__c + ' to list as ' + ratePlanName);
	   			ProductRatePlans.add(ratePlanName);
	   		}
	   		
	   		//System.Debug('Fetch details for ' + ProductRatePlans.size() + ' rate plans');
			List<zqu__ProductRatePlan__c> productRatePlansWithCapacity = [Select Id, Name, zqu__Product__c, zqu__Product__r.zqu__ZuoraId__c from zqu__ProductRatePlan__c where Is_Inventory_Managed__c = true and zqu__Deleted__c = false and zqu__Product__r.zqu__Deleted__c = false and name in :ProductRatePlans];
			System.debug(LoggingLevel.INFO, '*** productRatePlansWithCapacity: ' + productRatePlansWithCapacity);

			//System.Debug('Create a map of the rate plans going forward and for legacy plans');
			Map<String, zqu__ProductRatePlan__c> productRatePlanConvertMap = new Map<String, zqu__ProductRatePlan__c>();
			for (zqu__ProductRatePlan__c prp : productRatePlansWithCapacity)
			{
				productRatePlanConvertMap.put(prp.Name, prp);
				productRatePlanConvertMap.put(prp.Name.Replace('|','^'), prp);
			}
			
	   		for (Zuora__SubscriptionProductCharge__c spc : scope)
	   		{
	   			String ratePlanName = NormalizeProductRatePlanName(spc.Zuora__RatePlanName__c, productsMap.get(spc.Zuora__Product__r.Zuora__External_Id__c).Consolidate_Inventory__c);
	   			if (productRatePlanConvertMap.ContainsKey(ratePlanName))
	   			{
		   			Inventory__c newInventory = new Inventory__c();
					newInventory.Product_Rate_Plan__c = productRatePlanConvertMap.get(ratePlanName).id;
					newInventory.Quote_Rate_Plan__c = null;
					newInventory.Waitlist_Account__c = null;
					newInventory.Subscription_Product_Charge__c = spc.id;
					newInventory.Subscription_RatePlan_Id__c = spc.Zuora__RatePlanId__c;
					newInventory.Inventory_Hold_Expiry_Date__c = DateUtility.AddBusinessDays(spc.Zuora__Subscription__r.Zuora__TermEndDate__c, (Integer)invHoldExpDate.Subscription_Product_Charge_Day_Offset__c);
					// set Held_By_Migrated_Subscription__c flag to true if held by migrated subscription
					if (spc.Name == 'Charge #00')
					{
						newInventory.Held_By_Migrated_Subscription__c = True;
					}
					if (newInventory.Inventory_Hold_Expiry_Date__c >= Date.Today())
					{
						InventoryList.add(newInventory);
					}
					else
					{
		   				//System.Debug('Inventory would have expired already - skipping inventory record for ' + spc.Zuora__RatePlanName__c + ' ' + spc.Name + '(' + spc.Id + ').');
					}
	   			}
	   			else
	   			{
	   				//System.Debug('Could not find a matching rate plan with capacity value - skipping inventory record for ' + spc.Zuora__RatePlanName__c + ' ' + spc.Name + '(' + spc.Id + ').');
	   			}
	   		}		
   		}
   		catch (Exception exceptionCreateInventory)
   		{
   			ExceptionUtility.consumeException(exceptionCreateInventory, true);		
   		}
   		
   		try
   		{
   			insert InventoryList;	
   		}
   		catch (Exception exceptionInsertInventory)
   		{
   			ExceptionUtility.consumeException(exceptionInsertInventory, true);
   		}
   		
   	}
   	
    global void finish(Database.BatchableContext BC)
    {
		// string BatchDelAvailInvName = 'BatchDeleteAvailableInventory';

		// Map<String, ChainBatchJob__c> chainBatchJob = ChainBatchJob__c.getAll();
		// ChainBatchJob__c bdaiChainBatchJob = new ChainBatchJob__c();
		// if (chainBatchJob.containsKey(BatchDelAvailInvName))
		// {
		// 	//System.Debug('Found a custom setting for ' + BatchDelAvailInvName);
		// 	bdaiChainBatchJob = chainBatchJob.get(BatchDelAvailInvName);
		// }
		// else
		// {
		// 	//System.Debug('Creating a new custom setting for ' + BatchDelAvailInvName);
		// 	bdaiChainBatchJob.Name = BatchDelAvailInvName;
		// }
		// //System.Debug('Turning on chaining for ' + BatchDelAvailInvName);
		// bdaiChainBatchJob.Chain_Next_Batch_Job__c = true;
		// upsert bdaiChainBatchJob;
		//   	//System.Debug('Exiting BatchRebuildInventoryFromSubscriptions.finish');

		//   	// CSP-1796 | immediately run this job after to convert waitlist records to inventory
		//  	BatchDeleteAvailableInventory b = new BatchDeleteAvailableInventory();
		// database.executebatch(b);
		// Created inventory for the renewal quote before movet the waitlist to inventory
		BatchCreateInventoryForRenewalQuote b = new BatchCreateInventoryForRenewalQuote();
		database.executebatch(b);
    }
}