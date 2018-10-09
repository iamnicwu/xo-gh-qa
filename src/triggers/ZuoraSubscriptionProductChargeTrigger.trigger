trigger ZuoraSubscriptionProductChargeTrigger on Zuora__SubscriptionProductCharge__c (before insert, before update, after insert, after update, before delete, after delete) {
    
	/*  WARNING: as of 12/21/2016 there is no before or after update logic in this trigger.
	 *  However, in the ZuoraSubscriptionPCTriggerHandler.releaseCancelledReplaceInventory
	 *  method there is logic that can update Zuora__SubscriptionProductCharge__c records.
	 *  If you are adding before or after update logic, a static boolean flag will need to
	 *  be added to prevent recursive trigger execution from this method.
	 */

    List<Integer> indexList = new List<Integer>();   

    if(trigger.isInsert && trigger.isAfter){
	 	List<Inventory__c> invUpsertList = new List<Inventory__c>();
	    List<Inventory__c> invList = new List<Inventory__c>();
	 	Set<String> zRatePlanIdSet = new Set<String>();
	    Set<String> qRatePlanIdSet = new Set<String>();
	    
	    List<Zuora__SubscriptionProductCharge__c> spcList = new List<Zuora__SubscriptionProductCharge__c>();
	    
	    Map<String, Inventory__c> invQRPMap = new Map<String, Inventory__c>();
	    Map<String, Inventory__c> invSRPMap = new Map<String, Inventory__c>();
	    Map<String, List<Zuora__SubscriptionProductCharge__c>> spcMap = new Map<String, List<Zuora__SubscriptionProductCharge__c>>();
	    
	    DateTime myDateTime;
		String dayOfWeek = '';

		Boolean runMigratedSPCQueuedJob = False;
	
		Inventory_Hold_Expiry_Date_Offsets__c invHoldExpDate = Inventory_Hold_Expiry_Date_Offsets__c.getOrgDefaults();
    	
    	// gather the filtered list of charges.  Then query the database to get Subscription level fields that do not appear naturally in the trigger
    	List<Id> affectedSubscriptionProductChargeIdList = new List<Id>();
    	List<Zuora__SubscriptionProductCharge__c> affectedSubscriptionProductChargeList = new List<Zuora__SubscriptionProductCharge__c>();
    	
    	// only pass in items that have a capacity
    	Set<String> ratePlansTiedToSPC = new Set<String>();
    	
		for (Zuora__SubscriptionProductCharge__c spc : trigger.new)
		{
			System.Debug('Adding ' + spc.Product_SKU_Rate_Plan_Name__c.Replace('^','|'));
			ratePlansTiedToSPC.add(spc.Product_SKU_Rate_Plan_Name__c.Replace('^','|'));
		}
		
		// create a map of charge names that we want to ignore
		Map<String, String> chargeNameIgnore = new Map<String, String>();
		chargeNameIgnore.put('Charge #01', null);
		chargeNameIgnore.put('Charge #02', null);
		chargeNameIgnore.put('Charge #03', null);
		chargeNameIgnore.put('Charge #04', null);
		chargeNameIgnore.put('Charge #05', null);
		chargeNameIgnore.put('Charge #06', null);
		chargeNameIgnore.put('Charge #07', null);
		chargeNameIgnore.put('Charge #08', null);
		chargeNameIgnore.put('Charge #09', null);
		chargeNameIgnore.put('Charge #10', null);
		chargeNameIgnore.put('Charge #11', null);
		chargeNameIgnore.put('Charge #12', null);
		chargeNameIgnore.put('80% Balance Due', null);
		
		System.Debug('get the product rate plans that have capacity');
		List<zqu__ProductRatePlan__c> prpList = [Select Id, Product_SKU_Rate_Plan_Name__c from zqu__ProductRatePlan__c where Product_SKU_Rate_Plan_Name__c in :ratePlansTiedToSPC and Capacity__c != null];
		Map<String, zqu__ProductRatePlan__c> prpMap = new Map<String, zqu__ProductRatePlan__c>();
		for (zqu__ProductRatePlan__c prp : prpList) {
			prpMap.put(prp.Product_SKU_Rate_Plan_Name__c, prp);
		}
		
        for(Zuora__SubscriptionProductCharge__c spc : trigger.new){
        	System.Debug('spc id:' + spc.id);
        	if (prpMap.ContainsKey(spc.Product_SKU_Rate_Plan_Name__c.Replace('^','|')))
        	{
        		System.Debug('filter out charges that would duplicate the inventory');
        		if (!chargeNameIgnore.ContainsKey(spc.Name))
        		{
        			System.Debug('Found a candidate for creating inventory: ' + spc.Id);
		            affectedSubscriptionProductChargeIdList.add(spc.Id);   
        		}
        	}
        }
        
        // we have the filtered list of rate plan charges, now we need more information from the db
        if (affectedSubscriptionProductChargeIdList.size() > 0) {
        	affectedSubscriptionProductChargeList = [Select ID, Zuora__Subscription__r.Zuora__TermEndDate__c, Quote_Rate_Plan_ID__c, Zuora__RatePlanId__c, Product_SKU_Rate_Plan_Name__c, Do_not_create_inventory__c, Zuora_Id_of_Migrated_Charge__c from Zuora__SubscriptionProductCharge__c where Id in :affectedSubscriptionProductChargeIdList];
        }
        
        
        // now we have a list of all of the charges that need to be stored as inventory
    	for(SObject so : affectedSubscriptionProductChargeList){
    		Zuora__SubscriptionProductCharge__c record = (Zuora__SubscriptionProductCharge__c)so;
    		zRatePlanIdSet.add(record.Zuora__RatePlanId__c);
        	qRatePlanIdSet.add(record.Quote_Rate_Plan_ID__c);   	
        }
			
		invList = [SELECT id, Available__c, Date_Reserved__c, Inventory_Hold_Expiry_Date__c, Product_Rate_Plan__c,   
						Quote_Rate_Plan__c,	Subscription_RatePlan_Id__c, Subscription_Product_Charge__c, Waitlist_Account__c FROM Inventory__c 
							WHERE Quote_Rate_Plan__c IN : qRatePlanIdSet OR Subscription_RatePlan_Id__c IN : zRatePlanIdSet];
		
		for(Inventory__c i : invList){
			if(i.Quote_Rate_Plan__c != null){
				invQRPMap.put(i.Quote_Rate_Plan__c, i);
			}else if(i.Subscription_RatePlan_Id__c != null){
				invSRPMap.put(i.Subscription_RatePlan_Id__c, i);
			}				
		}

		for(SObject so : affectedSubscriptionProductChargeList){
			Zuora__SubscriptionProductCharge__c spc = (Zuora__SubscriptionProductCharge__c)so;
			if(invQRPMap.containsKey(spc.Quote_Rate_Plan_ID__c) && invQRPMap.get(spc.Quote_Rate_Plan_ID__c) != null){
				Inventory__c inventoryRecord = invQRPMap.remove(spc.Quote_Rate_Plan_ID__c);
				inventoryRecord.Quote_Rate_Plan__c = null;
				inventoryRecord.Waitlist_Account__c = null;
				inventoryRecord.Subscription_Product_Charge__c = spc.id;
				inventoryRecord.Subscription_RatePlan_Id__c = spc.Zuora__RatePlanId__c;
				inventoryRecord.Inventory_Hold_Expiry_Date__c = DateUtility.AddBusinessDays(spc.Zuora__Subscription__r.Zuora__TermEndDate__c, (Integer)invHoldExpDate.Subscription_Product_Charge_Day_Offset__c);
				invUpsertList.add(inventoryRecord);
			}
			else if(invSRPMap.containsKey(spc.Zuora__RatePlanId__c) && invSRPMap.get(spc.Zuora__RatePlanId__c) != null){
				Inventory__c inventoryRecord = invSRPMap.remove(spc.Zuora__RatePlanId__c);
				inventoryRecord.Quote_Rate_Plan__c = null;
				inventoryRecord.Waitlist_Account__c = null;
				inventoryRecord.Subscription_Product_Charge__c = spc.id;
				inventoryRecord.Subscription_RatePlan_Id__c = spc.Zuora__RatePlanId__c;
				inventoryRecord.Inventory_Hold_Expiry_Date__c = DateUtility.AddBusinessDays(spc.Zuora__Subscription__r.Zuora__TermEndDate__c, (Integer)invHoldExpDate.Subscription_Product_Charge_Day_Offset__c);
				invUpsertList.add(inventoryRecord);				
			}
			else{
				List<Zuora__SubscriptionProductCharge__c> tempSPCList;

				if (spcMap.containsKey(spc.Product_SKU_Rate_Plan_Name__c.Replace('^','|'))) {
					tempSPCList = spcMap.get(spc.Product_SKU_Rate_Plan_Name__c.Replace('^','|'));
				}
				else {
					tempSPCList = new List<Zuora__SubscriptionProductCharge__c>();
				}

				tempSPCList.add(spc);
				spcMap.put(spc.Product_SKU_Rate_Plan_Name__c.Replace('^','|'), tempSPCList);
			}
		}

		for (zqu__ProductRatePlan__c zprp : [SELECT id, Product_SKU_Rate_Plan_Name__c FROM zqu__ProductRatePlan__c where Product_SKU_Rate_Plan_Name__c IN : spcMap.KeySet()]) {
			if (spcMap.containsKey(zprp.Product_SKU_Rate_Plan_Name__c)) {
				for (Zuora__SubscriptionProductCharge__c spc : spcMap.get(zprp.Product_SKU_Rate_Plan_Name__c)) {
					
					if (spc.Do_not_create_inventory__c != 'Yes' && String.isBlank(spc.Zuora_Id_of_Migrated_Charge__c)) {
						Inventory__c invn = new Inventory__c();
						invn.Product_Rate_Plan__c = zprp.Id;
						invn.Quote_Rate_Plan__c = null;
						invn.Waitlist_Account__c = null;
						invn.Subscription_Product_Charge__c = spc.Id;
						invn.Subscription_RatePlan_Id__c = spc.Zuora__RatePlanId__c;
						invn.Inventory_Hold_Expiry_Date__c = DateUtility.AddBusinessDays(spc.Zuora__Subscription__r.Zuora__TermEndDate__c, (Integer)invHoldExpDate.Subscription_Product_Charge_Day_Offset__c);
						invUpsertList.add(invn);
					}
					else if (!String.isBlank(spc.Zuora_Id_of_Migrated_Charge__c) && !runMigratedSPCQueuedJob) {
						runMigratedSPCQueuedJob = True;
					}	
				}
			}
		}
        
        
    	if(!invUpsertList.isEmpty()){
            Database.upsert(invUpsertList, false);
        }

        // CSP-608 | run MigratedSubscriptionInventoryQueuedJob if boolean was set and the job isn't already queued up
        if (runMigratedSPCQueuedJob) {
        	List<AsyncApexJob> jobList = [SELECT Id, Status, ApexClass.Name FROM AsyncApexJob WHERE ApexClass.Name = 'MigratedSubscriptionInventoryQueuedJob' AND (Status = 'Holding' OR Status = 'Queued') LIMIT 1];
            if (jobList.isEmpty()) {
                System.enqueueJob(new MigratedSubscriptionInventoryQueuedJob.QueueableOne());
            }
        }
        
    }

    TriggerFactory.createAndExecuteHandler(ZuoraSubscriptionPCTriggerHandler.class, 'Zuora__SubscriptionProductCharge__c', null);
}