/* 
<class>
  <name>InventoryUtilities</name>
  <purpose>Contains methods to assist in Inventory management</purpose>
  <created>
    <by>Jonathan Satterfield</by>
    <date>9/15/2015</date>
    <ticket>SF-1211</ticket>
  </created>
</class>
*/
public without sharing class InventoryUtilities {

	/* 
	<method>
	  <name>IsInventoryAvailable</name>
	  <purpose>Checks to see if Inventory records are available or can be created/modified as appropriate</purpose>
	  <created>
	    <by>Steve O'Neal</by>
	    <date>11/15/2015</date>
	    <ticket>SF-1211</ticket>
	  </created>
	</method>
	*/
	public static Map<Id,Boolean> IsInventoryAvailable(Set<Id> productRatePlanIdSet, Set<Id> quoteRatePlanIdSet, Id oppId) 
	{
		// map of QuoteRatePlan to Boolean (whether or not Inventory is available)
		// each QuoteRatePlanCharge record on the page will check this
		Map<Id,Boolean> inventoryAvailableForQuoteRatePlan = new Map<Id,Boolean>();

		// CSP-608; count migrated inventory records held by that account for a specific product rate plan
		// key: account id + prp id | value: set of Zuora Ids for Subscription Product Charges holding migrated inventory for this account + prp combo
		Map<String,Set<String>> countOfMigratedInventoryForAccountAndPRP = new Map<String,Set<String>>();
		Map<String,Set<String>> countOfMigratedInventoryForAccountAndPRPClone = new Map<String,Set<String>>();

		if (productRatePlanIdSet.size() > 0 && quoteRatePlanIdSet.size() > 0)
		{
			List<Inventory__c> inventoryUpsertList = new List<Inventory__c>();

			List<zqu__ProductRatePlan__c> prpList = [SELECT Id, Available__c, Waitlist_Count__c, Number_Available__c, 
													(SELECT Id, Account_ID__c, Quote_Expiration_Date__c, zqu__ProductRatePlan__c, zqu__AmendmentType__c, Zuora_Id_of_Migrated_Charge__c FROM zqu__Quote_Rate_Plans__r WHERE Id IN :quoteRatePlanIdSet), 
													(SELECT Id, Waitlist_Account__c, Quote_Rate_Plan__c, Product_Rate_Plan__c, Inventory_Hold_Expiry_Date__c, Held_By_Migrated_Subscription__c, Subscription_Product_Charge__r.Zuora__Account__c, Subscription_Product_Charge__r.Zuora__Zuora_Id__c FROM Inventory__r), 
													(SELECT Id FROM zqu__QuoteChargeDetails__r WHERE zqu__Quote__r.zqu__Opportunity__c = :oppId AND Inventory_Freed_By_Cancellation__c = true) 
													FROM zqu__ProductRatePlan__c WHERE Id IN :productRatePlanIdSet];

			for (zqu__ProductRatePlan__c prp : prpList) {

				// number of available Inventory slots for this Product Rate Plan
				Integer numberAvailableSlots = (Integer)prp.Number_Available__c;

				// CSP-1610 | if this is a "renewal" Opportunity doing a cancel/replace, set this Product Rate Plan's numberAvailableSlotsFromCancellation 
				// by the number of Inventory slots that will be freed by the Cancellation Quote; this value will be checked below
				Integer numberAvailableSlotsFromCancellation = prp.zqu__QuoteChargeDetails__r.size();			

				// set of QuoteRatePlan record IDs for QRPs that already have an associated Inventory record
				Set<Id> quoteRatePlansWithInventory = new Set<Id>();
				
				// "waitlist" Inventory records
				Map<String,List<Inventory__c>> waitlistInventoryMap = new Map<String,List<Inventory__c>>();

				// all that we do when we loop through the Inventory records is populate lists and maps
				// to be used in the QuoteRatePlan loop below, which is where we perform all of our logic
				for (Inventory__c inv : prp.Inventory__r) {

					if (inv.Quote_Rate_Plan__c != null) {
						quoteRatePlansWithInventory.add(inv.Quote_Rate_Plan__c);
					}

					// CSP-608; populate migrated inventory maps
					else if (inv.Held_By_Migrated_Subscription__c) {
						String tempMigratedInventoryMapKey = (String)inv.Subscription_Product_Charge__r.Zuora__Account__c + (String)inv.Product_Rate_Plan__c;
						Set<String> spcZIDs;
						if (countOfMigratedInventoryForAccountAndPRP.containsKey(tempMigratedInventoryMapKey)) {						
							spcZIDs = countOfMigratedInventoryForAccountAndPRP.get(tempMigratedInventoryMapKey);
						}
						else {
							spcZIDs = new Set<String>();
						}
						spcZIDs.add(inv.Subscription_Product_Charge__r.Zuora__Zuora_Id__c);
						countOfMigratedInventoryForAccountAndPRP.put(tempMigratedInventoryMapKey, spcZIDs);
						countOfMigratedInventoryForAccountAndPRPClone.put(tempMigratedInventoryMapKey, spcZIDs);
					}

					else if (inv.Waitlist_Account__c != null && inv.Quote_Rate_Plan__c == null) {
						String tempKey = String.valueOf(inv.Waitlist_Account__c).left(15) + String.valueOf(inv.Product_Rate_Plan__c);
						if (!waitlistInventoryMap.containsKey(tempKey)) {
							List<Inventory__c> newInvList = new List<Inventory__c>();
							newInvList.add(inv);
							waitlistInventoryMap.put(tempKey, newInvList);                                                   
						}
						else {
							List<Inventory__c> existingInvList = waitlistInventoryMap.get(tempKey);
							existingInvList.add(inv);
							waitlistInventoryMap.put(tempKey, existingInvList);
						}
					}
				}

				for (zqu__QuoteRatePlan__c qrp : prp.zqu__Quote_Rate_Plans__r) {
					String tempKey2 = String.valueOf(qrp.Account_ID__c) + String.valueOf(qrp.zqu__ProductRatePlan__c);
					String migratedInventoryMapKey = (String)(Id)qrp.Account_ID__c + (String)qrp.zqu__ProductRatePlan__c;

					System.debug('migrated inventory key:');
					System.debug(migratedInventoryMapKey);

					// SCENARIO 1: QuoteRatePlan already has a child Inventory record or it is part of a Renewal Quote
					if (quoteRatePlansWithInventory.contains(qrp.Id) || qrp.zqu__AmendmentType__c.containsIgnoreCase('renewal')) {
						// don't do anything
					}
					// SCENARIO 2: (CSP-1610) Inventory is going to be freed by a related Cancellation Quote on the same Opportunity
					else if (numberAvailableSlotsFromCancellation > 0) {
						numberAvailableSlotsFromCancellation--;
						// need to remove this QuoteRatePlan from the Id set so the check for Inventory being created down below doesn't include this QuoteRatePlan
						quoteRatePlanIdSet.remove(qrp.Id);
						// add this QuoteRatePlan to the inventoryAvailableForQuoteRatePlan stating it does have Inventory available
						inventoryAvailableForQuoteRatePlan.put(qrp.Id, true);
					}
					// SCENARIO 3: there's a "waitlist" Inventory record that the QuoteRatePlan can take control over
					else if (waitlistInventoryMap.containsKey(tempKey2)) {
						
						List<Inventory__c> invList = waitlistInventoryMap.get(tempKey2);
						if (invList.size() == 1) {
							Inventory__c invRecord = invList.remove(0);
							invRecord.Quote_Rate_Plan__c = qrp.Id;
							invRecord.Inventory_Hold_Expiry_Date__c = qrp.Quote_Expiration_Date__c;
							inventoryUpsertList.add(invRecord);
							// remove the key-value pair from the waitlistInventoryMap since the value (list) is now empty
							waitlistInventoryMap.remove(tempKey2);
						}
						// if multiple applicable "waitlisted" Inventory records exist, choose the oldest one
						else if (invList.size() > 1) {
							Integer listPosition = 0;
							Inventory__c tempInvRecord = null;
							for (Integer i = 0; i < invList.size(); i++) {
								// note to self: older < newer = True
								if (tempInvRecord == null || invList[i].Inventory_Hold_Expiry_Date__c < tempInvRecord.Inventory_Hold_Expiry_Date__c) {
									listPosition = i;
									tempInvRecord = invList[i];
								}
							}
							invList.remove(listPosition);
							tempInvRecord.Quote_Rate_Plan__c = qrp.Id;
							tempInvRecord.Inventory_Hold_Expiry_Date__c = qrp.Quote_Expiration_Date__c;
							inventoryUpsertList.add(tempInvRecord);
							waitlistInventoryMap.put(tempKey2, invList);				
						}
					}
					// SCENARIO 4: check for migrated inventory (CSP-608)
					else if (countOfMigratedInventoryForAccountAndPRP.containsKey(migratedInventoryMapKey)) {

						System.debug('FOUND MIGRATED');
						System.debug(countOfMigratedInventoryForAccountAndPRP);

						Set<String> currentCount = countOfMigratedInventoryForAccountAndPRP.get(migratedInventoryMapKey);
						if (currentCount.size() == 1) {
							countOfMigratedInventoryForAccountAndPRP.remove(migratedInventoryMapKey);
						}
						else {
							// can't remove a single set value by index, have to do this instead = /
							for (String sKey : currentCount) {
								currentCount.remove(sKey);
								break;
							}
							countOfMigratedInventoryForAccountAndPRP.put(migratedInventoryMapKey, currentCount);
						}
					}
					// SCENARIO 5: no Inventory record at all; find out if any slots are available
					else {
						// if there are open slots and this is for a new product, create a new Inventory record
						if (numberAvailableSlots > 0 && qrp.zqu__AmendmentType__c == 'NewProduct' && String.isBlank(qrp.Zuora_Id_of_Migrated_Charge__c)) {
							numberAvailableSlots--;
							Inventory__c newInvRecord = new Inventory__c();
							newInvRecord.Quote_Rate_Plan__c = qrp.Id;
							newInvRecord.Product_Rate_Plan__c = prp.Id;
							newInvRecord.Inventory_Hold_Expiry_Date__c = qrp.Quote_Expiration_Date__c;
							inventoryUpsertList.add(newInvRecord);
						}
					}
				}				
			}

			Database.upsert(inventoryUpsertList, False);


			// populate inventoryAvailableForQuoteRatePlan map here using query
			// it's possible that some upsert operations could have failed, so run a query
			// to populate the map after the DML statement

			List<zqu__QuoteRatePlan__c> finalQRPWithInventoryCheckList = [SELECT Id, zqu__AmendmentType__c, Account_ID__c, zqu__ProductRatePlan__c, Zuora_Id_of_Migrated_Charge__c, (SELECT ID FROM Inventory__r) FROM zqu__QuoteRatePlan__c WHERE Id IN :quoteRatePlanIdSet];

			Boolean updateFinalQRPWithInventoryCheckList = False;

			for (zqu__QuoteRatePlan__c zQRP : finalQRPWithInventoryCheckList) {

				// need to first cast zQRP.Account_ID__c to an Id, then back to String, in order to get the 18-digit key
				String migratedInventoryCloneMapKey = (String)(Id)zQRP.Account_ID__c + (String)zQRP.zqu__ProductRatePlan__c;

				System.debug('migrated inventory clone map key!');
				System.debug(migratedInventoryCloneMapKey);
				System.debug('migrated inventory clone map!');
				System.debug(countOfMigratedInventoryForAccountAndPRPClone);

			    // if at least one Inventory record present for QuoteRatePlan, save Id to Map with a "True" value
			    // also, if the QuoteRatePlan isn't for a new product or it's part of a renewal quote, flag it as True as well
			    if (zQRP.Inventory__r.size() > 0 || zQRP.zqu__AmendmentType__c != 'NewProduct') {
			    	inventoryAvailableForQuoteRatePlan.put(zQRP.Id, True);
			    }
			    // CSP-608: check for migrated inventory
			    else if (countOfMigratedInventoryForAccountAndPRPClone.containsKey(migratedInventoryCloneMapKey)) {
					Set<String> migratedInventoryCount = countOfMigratedInventoryForAccountAndPRPClone.get(migratedInventoryCloneMapKey);
					String migratedSPCZID;
					if (migratedInventoryCount.size() == 1) {
						// can't reference a single set value by index, have to do this instead = /
						for (String zIDValue : migratedInventoryCount) {
							migratedSPCZID = zIDValue;
							break;
						}
						countOfMigratedInventoryForAccountAndPRPClone.remove(migratedInventoryCloneMapKey);
					}
					else {
						for (String zIDValue2 : migratedInventoryCount) {
							migratedSPCZID = zIDValue2;
							migratedInventoryCount.remove(zIDValue2);
							break;
						}
						countOfMigratedInventoryForAccountAndPRPClone.put(migratedInventoryCloneMapKey, migratedInventoryCount);
					}

					zQRP.Zuora_Id_of_Migrated_Charge__c = migratedSPCZID;
					
					if (!updateFinalQRPWithInventoryCheckList) {
						updateFinalQRPWithInventoryCheckList = True;
					}

					inventoryAvailableForQuoteRatePlan.put(zQRP.Id, True);
			    }
			    // otherwise, put "False"
			    else {
			    	inventoryAvailableForQuoteRatePlan.put(zQRP.Id, False);
			    }
			}

			if (updateFinalQRPWithInventoryCheckList) {
				update finalQRPWithInventoryCheckList;
			}
		}

		return inventoryAvailableForQuoteRatePlan;
	}

	/* 
	<method>
	  <name>IsInventoryAvailable</name>
	  <purpose>Checks to see if Inventory records are available or can be created/modified as appropriate</purpose>
	  <created>
	    <by>Steve O'Neal</by>
	    <date>11/15/2015</date>
	    <ticket>SF-1211</ticket>
	  </created>
	</method>
	*/
	public static Map<Id,Boolean> IsInventoryAvailable(List<zqu__QuoteRatePlan__c> qrpList, Id oppId) {
		Set<Id> productRatePlanIdSet = new Set<Id>();
		Set<Id> quoteRatePlanIdSet = new Set<Id>();
		if (qrpList.size() > 0) {
			for (zqu__QuoteRatePlan__c qrp : qrpList) {
				// CSP-1963
				if(String.isNotBlank(qrp.Zuora_Id_of_Migrated_Charge__c)) {
					continue;
				}
				productRatePlanIdSet.add(qrp.zqu__ProductRatePlan__c);
				quoteRatePlanIdSet.add(qrp.Id);
			}
		}
		
		return IsInventoryAvailable(productRatePlanIdSet, quoteRatePlanIdSet, oppId);
	}
}