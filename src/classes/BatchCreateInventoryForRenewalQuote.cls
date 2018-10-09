/**
 *	Created the inventory for renewal Quote when the inventory of the original subscription has been released 
 *  Created by Tony
 */


global class BatchCreateInventoryForRenewalQuote implements Database.Batchable<sObject> {
	public String query;
	private Inventory_Hold_Expiry_Date_Offsets__c invHoldExpDate;
	private Date inventoryExpiredDate;
	private Date todayDate;
	global BatchCreateInventoryForRenewalQuote() {
		invHoldExpDate = Inventory_Hold_Expiry_Date_Offsets__c.getOrgDefaults();
		inventoryExpiredDate = DateUtility.AddBusinessDays(date.today(), -(Integer)invHoldExpDate.Subscription_Product_Charge_Day_Offset__c);
		todayDate = Date.today();
		query = 'SELECT Id, zqu__ProductRatePlan__c, zqu__Quote__r.zqu__ValidUntil__c, (SELECT Id FROM Inventory__r) ';
		query += 'FROM zqu__QuoteRatePlan__c WHERE zqu__Quote__r.Subscription_Being_Renewed__c != NULL ';
		query += 'AND zqu__Quote__r.Subscription_Being_Renewed__r.Zuora__TermEndDate__c <: inventoryExpiredDate ';
		query += 'AND zqu__Quote__r.zqu__ValidUntil__c >=: todayDate ';
		query += 'AND zqu__Quote__r.zqu__Status__c != \'Sent to Z-Billing\' ';
		query += 'AND zqu__ProductRatePlan__r.Is_Inventory_Managed__c = TRUE ';
		query += 'AND zqu__ProductRatePlan__r.Number_Available__c >0 ';

	}

	global Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, list<zqu__QuoteRatePlan__c> scope) {
		List<Inventory__c> newInventoryList = new List<Inventory__c>();
		for (zqu__QuoteRatePlan__c qrp : scope){
			// only create inventory for the renewal quote with out inventory
			if (qrp.Inventory__r.size() < 1) {
				Inventory__c newInventory = new Inventory__c();
				newInventory.Product_Rate_Plan__c = qrp.zqu__ProductRatePlan__c;
				newInventory.Quote_Rate_Plan__c = qrp.Id;
				newInventory.Inventory_Hold_Expiry_Date__c = qrp.zqu__Quote__r.zqu__ValidUntil__c;
				newInventoryList.add(newInventory);
			}
		}
		if (!newInventoryList.isEmpty()) {
			List<Database.SaveResult> insertResultList = Database.insert(newInventoryList,false);
			List<XO_Exception__c> xoExceptionList = ExceptionUtility.consumeException(insertResultList);
			if (!xoExceptionList.isEmpty()) {
				insert xoExceptionList;
			}
		}
	}

	global void finish(Database.BatchableContext BC) {
		// run back the batch job BatchDeleteAvailableInventory
		string BatchDelAvailInvName = 'BatchDeleteAvailableInventory';
	
		Map<String, ChainBatchJob__c> chainBatchJob = ChainBatchJob__c.getAll();
		ChainBatchJob__c bdaiChainBatchJob = new ChainBatchJob__c();
		if (chainBatchJob.containsKey(BatchDelAvailInvName))
		{
			//System.Debug('Found a custom setting for ' + BatchDelAvailInvName);
			bdaiChainBatchJob = chainBatchJob.get(BatchDelAvailInvName);
		}
		else
		{
			//System.Debug('Creating a new custom setting for ' + BatchDelAvailInvName);
			bdaiChainBatchJob.Name = BatchDelAvailInvName;
		}
		//System.Debug('Turning on chaining for ' + BatchDelAvailInvName);
		bdaiChainBatchJob.Chain_Next_Batch_Job__c = true;
		upsert bdaiChainBatchJob;
  	//System.Debug('Exiting BatchRebuildInventoryFromSubscriptions.finish');
  	
  	// CSP-1796 | immediately run this job after to convert waitlist records to inventory
  	BatchDeleteAvailableInventory b = new BatchDeleteAvailableInventory();
		database.executebatch(b);
  }
}