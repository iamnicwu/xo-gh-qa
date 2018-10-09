global class BatchProductRatePlanChargeTier implements Database.Batchable<sObject>, Database.AllowsCallouts {
	////////////////////////////
	// STATIC FINAL VARIABLES //
	////////////////////////////
	private static final String OBJECT_NAME = 'ProductRatePlanChargeTier';
	private static final String ID_FIELD_NAME = 'Id';
	private static final String PRICE_FIELD_NAME = 'Price';
	private static final String QUERY = 'SELECT '
																			+	'Id, '
																			+	'zqu__ZuoraId__c, '
																			+	'zqu__ProductRatePlanCharge__r.Id, '
																			+	'zqu__ProductRatePlanCharge__r.zqu__ListPrice__c, '
																			+	'zqu__Price__c, '
																			+	'Last_Update_Attempted__c, '
																			+	'Zuora_Update_Pending__c '
																		+	' FROM '
																			+ 'zqu__ProductRatePlanChargeTier__c'
																		+	' WHERE '
																			+	'Zuora_Update_Pending__c = true';
	
	global BatchProductRatePlanChargeTier() {
		
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(QUERY);
	}

  global void execute(Database.BatchableContext BC, List<zqu__ProductRatePlanChargeTier__c> scope) {
		Map<String, zqu__ProductRatePlanChargeTier__c> zuoraIdToChargeTierMap = new Map<String, zqu__ProductRatePlanChargeTier__c>();

		List<Zuora.zObject> zuoraObjectWrapperList = new List<Zuora.zObject>();
		List<Zuora.zAPI.SaveResult> zuoraUpdateResults = new List<Zuora.zAPI.SaveResult>();
		List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();

  	for(Integer i = 0; i < scope.size(); i++) {
  		zqu__ProductRatePlanChargeTier__c currentRecord = scope[i];
  		currentRecord.Last_Update_Attempted__c = Datetime.now();
  		zuoraIdToChargeTierMap.put(currentRecord.zqu__ZuoraId__c, currentRecord);

  		// Try to create a new Zuora zObject using the object name - generally this will fail if the Zuora WSDL is not
  		// up to date or missing an object.
  		try {
  			Zuora.zObject zuoraObjectWrapper = new Zuora.zObject(OBJECT_NAME);
				zuoraObjectWrapper.setValue(ID_FIELD_NAME, currentRecord.zqu__ZuoraId__c);
				zuoraObjectWrapper.setValue(PRICE_FIELD_NAME, currentRecord.zqu__Price__c);

				zuoraObjectWrapperList.add(zuoraObjectWrapper);
			} catch(Exception e) {
				XO_Exception__c newException = ExceptionUtility.consumeException(e, false);
				newException.Severity__c = 'Critical';
				newException.Failure_Area__c = 'Product Charge Tier Update';
				newException.Type__c = 'Zuora Update';

				xoExceptionList.add(newException);
			}

			/*
				There is a rough limit of 50 when sending updates to Zuora so if the zuoraObjectWrapperList has met this requirement
				or the interator is in its last iteration then we need to send the updates to Zuora then reset the list to begin
				adding the next round of updates.
			 */
			if(zuoraObjectWrapperList.size() == 50 || (i+1) == scope.size()) {
				Zuora.ZApi zuoraAPIInstance = new Zuora.ZApi();
				
				try {
					// Login to Zuora using built in package functions
					Zuora.zApi.LoginResult loginResult = zuoraAPIInstance.zlogin();
					// Perform update to zObjects in list and store results
					zuoraUpdateResults.addAll(zuoraAPIInstance.zUpdate(zuoraObjectWrapperList));
				} catch(Zuora.zRemoteException ex) {
					// Create exception
					XO_Exception__c newException = new XO_Exception__c();
					newException.Message__c = ex.getMessage() + '\\r\\n\\r\\n' + ex.code;
					newException.Failure_Area__c = 'Product Charge Tier Update';
					newException.Type__c = 'Zuora Update';
					newException.Severity__c = 'Major';

					xoExceptionList.add(newException);
				} catch(Zuora.zAPIException ex) {
					// Create exception
					XO_Exception__c newException = new XO_Exception__c();
					newException.Message__c = ex.getMessage() + '\\r\\n\\r\\n' + ex.code;
					newException.Failure_Area__c = 'Product Charge Tier Update';
					newException.Type__c = 'Zuora Update';
					newException.Severity__c = 'Major';

					xoExceptionList.add(newException);
				} catch(Zuora.zForceException ex) {
					// Create exception
					XO_Exception__c newException = new XO_Exception__c();
					newException.Message__c = ex.getMessage() + '\\r\\n\\r\\n' + ex.code;
					newException.Failure_Area__c = 'Product Charge Tier Update';
					newException.Type__c = 'Zuora Update';
					newException.Severity__c = 'Major';

					xoExceptionList.add(newException);
				}

				// Clear the object wrapper list
				zuoraObjectWrapperList.clear();
			}
  	}

	  ////////////////////////
  	// CHECK SAVE RESULTS //
	  ////////////////////////
	  // List used to hold charge tier updates
	  List<zqu__ProductRatePlanChargeTier__c> chargeTierUpdateList = new List<zqu__ProductRatePlanChargeTier__c>();
	  // List used to hold parent success updates
	  List<zqu__ProductRatePlanCharge__c> parentChargeSuccessList = new List<zqu__ProductRatePlanCharge__c>();
	  //CSP-2853 Update Price Adjustment Tool
	  //Store all update product rate plan charge id  
	  set<Id> productRatePlanChargeIdSet = new Set<Id>();
	  list<zqu__ProductRatePlanChargePriceSummary__c> PRPChargePriceSummaryList = new list<zqu__ProductRatePlanChargePriceSummary__c>();

	  for(Integer i = 0; i < zuoraUpdateResults.size(); i++) {
	  	Zuora.zAPI.SaveResult currentSaveResult = zuoraUpdateResults[i];

	  	if(currentSaveResult.Success && zuoraIdToChargeTierMap.containsKey(currentSaveResult.Id)) {
	  		zqu__ProductRatePlanChargeTier__c successRecord = zuoraIdToChargeTierMap.remove(currentSaveResult.Id);
	  		successRecord.Zuora_Update_Pending__c = false;
	  		successRecord.Last_Update_Attempted__c = null;

	  		chargeTierUpdateList.add(successRecord);

	  		// Update the parent record with the same price so that everything aligns
	  		zqu__ProductRatePlanCharge__c parentCharge = successRecord.zqu__ProductRatePlanCharge__r;
	  		parentCharge.zqu__ListPrice__c = successRecord.zqu__Price__c;
	  		parentChargeSuccessList.add(parentCharge);
	  		//CSP-2853 Update Price Adjustment Tool
	  		//Get all update product rate plan charge id 
	  		productRatePlanChargeIdSet.add(parentCharge.Id);
  		} else {
  			System.debug(currentSaveResult);
	  		System.debug('Errors ' + currentSaveResult.errors);

  			if(zuoraIdToChargeTierMap.containsKey(currentSaveResult.Id)) {
					zqu__ProductRatePlanChargeTier__c failureRecord = zuoraIdToChargeTierMap.remove(currentSaveResult.Id);
  				chargeTierUpdateList.add(failureRecord);
  				
  				XO_Exception__c newException = new XO_Exception__c(Message__c = '');
  				Zuora.zObject[] errors = currentSaveResult.errors;
					for (Zuora.zObject error : errors) {
					  String errorCode = (String)error.getValue('Code');
					  String message = (String)error.getValue('Message');
					  newException.Message__c += errorCode + ' - ' + message;
					}
					newException.Related_Object_Id__c = failureRecord.Id;
					newException.Failure_Area__c = 'Product Charge Tier Update';
					newException.Type__c = 'Zuora Update';
					newException.Severity__c = 'Major';

					xoExceptionList.add(newException);
  			}
  			
  		}
	  }

	  /*
			If for some reason these records were not in the SaveResult then they were not even attempted to send. Could have
			failed at the zUpdate method OR the zLogin method.
		 */
		if(!zuoraIdToChargeTierMap.isEmpty()) {
			List<String> keyValueList = new List<String>(zuoraIdToChargeTierMap.keySet());
			for(Integer i = 0; i < keyValueList.size(); i++) {
				String currentKeyValue = keyValueList[i];
				zqu__ProductRatePlanChargeTier__c currentTierCharge = zuoraIdToChargeTierMap.get(currentKeyValue);
				chargeTierUpdateList.add(currentTierCharge);

				XO_Exception__c newException = new XO_Exception__c();
				newException.Related_Object_Id__c = currentTierCharge.Id;
				newException.Message__c = 'This record failed to return a successful save result.';
				newException.Failure_Area__c = 'Product Charge Tier Update';
				newException.Type__c = 'Zuora Update';
				newException.Severity__c = 'Major';

				xoExceptionList.add(newException);
			}
		}

		// Update all charge tiers, this is mostly to stamp the datetime value of failures and uncheck values for successes
		// CSP-2853 Update Price Adjustment Tool
		// use database to update chargeTierUpdateList
		if(!chargeTierUpdateList.isEmpty()) {
      List<Database.SaveResult> saveTieResultList = Database.update(chargeTierUpdateList);
      List<XO_Exception__c> updateTieExceptionList = ExceptionUtility.consumeException(saveTieResultList);
    	xoExceptionList.addAll(updateTieExceptionList);
    }

	  // Update parent values for successful charge tier updates so the price is in line
	  // CSP-2853 Update Price Adjustment Tool
		// use database to update parentChargeSuccessList
	  if(!parentChargeSuccessList.isEmpty()) {
      List<Database.SaveResult> saveChargeResultList = Database.update(parentChargeSuccessList);
      List<XO_Exception__c> updateChargeExceptionList = ExceptionUtility.consumeException(saveChargeResultList);
    	xoExceptionList.addAll(updateChargeExceptionList);
    }
	  //CSP-2853 Update Price Adjustment Tool
	  //Get Product Rate Plan Charge Price Summary need to update 
	  PRPChargePriceSummaryList = setPriceSummaryToUpdate(productRatePlanChargeIdSet);

	  //CSP-2853 Update Price Adjustment Tool
	  // Update Product Rate Plan Charge Price Summary field
	  if(!PRPChargePriceSummaryList.isEmpty()) {
      List<Database.SaveResult> saveSummaryResultList = Database.update(PRPChargePriceSummaryList);
      List<XO_Exception__c> updateSummaryExceptionList = ExceptionUtility.consumeException(saveSummaryResultList);
    	xoExceptionList.addAll(updateSummaryExceptionList);
    }

	  // Insert all exceptions into the system
	  // CSP-2853 Update Price Adjustment Tool
		// Not insert if xoExceptionList is Empty
	  if(!xoExceptionList.isEmpty()){
	  	insert xoExceptionList;
	  }
	}

	  /**
     * CSP-2853 Update Price Adjustment Tool
     * This method to update price Summary on Product Rate Plan Charge Price Summary
     * 
     * @Author Mason
     * @Date   2018-05-07
     * @param  productRatePlanChargeIdSet
     * @return PRPChargePriceSummaryList
     */
	private list<zqu__ProductRatePlanChargePriceSummary__c> setPriceSummaryToUpdate(Set<Id> productRatePlanChargeIdSet) {

		// store charge price summary list need to update 
		list<zqu__ProductRatePlanChargePriceSummary__c> PRPChargePriceSummaryList = new list<zqu__ProductRatePlanChargePriceSummary__c>();

	  //Query Product Rate Plan Charge Price Summary for udpate price Summary
	  for(zqu__ProductRatePlanChargePriceSummary__c PRPChargePriceSummary : [SELECT id, zqu__ProductRatePlanCharge__r.zqu__ListPrice__c, 
	  																																				  zqu__ProductRatePlanCharge__r.zqu__Type__c,zqu__PriceSummary__c 
	  																																				  FROM zqu__ProductRatePlanChargePriceSummary__c 
																								  													  WHERE zqu__ProductRatePlanCharge__r.Id IN: productRatePlanChargeIdSet]) {

	  	String productRatePlanChargeType = PRPChargePriceSummary.zqu__ProductRatePlanCharge__r.zqu__Type__c;
	  	String listPriceStr = '0';
	  	//Convert list price type to String 
	  	if(PRPChargePriceSummary.zqu__ProductRatePlanCharge__r.zqu__ListPrice__c != null){
	  		Decimal listPriceDecimal = PRPChargePriceSummary.zqu__ProductRatePlanCharge__r.zqu__ListPrice__c.setScale(2);
	  		Integer listPriceInt = listPriceDecimal.intValue();
	  		//If the decimal places are all 0, get integers of List Price
	  		if(listPriceDecimal == listPriceInt){
						listPriceDecimal = listPriceInt;
				}
	  		listPriceStr = String.valueOf(listPriceDecimal);
	  	}

	  	if(string.isNotBlank(productRatePlanChargeType)) {
  			//charge Type is One-Time
	     	if(productRatePlanChargeType.equalsIgnoreCase('One-Time')){
	     		PRPChargePriceSummary.zqu__PriceSummary__c = 'USD' + listPriceStr;
	     	}
	     	//charge Type is Recurring and Price Summary starts with 'USD'
	     	else if(productRatePlanChargeType.equalsIgnoreCase('Recurring') 
	     					&& String.isNotBlank(PRPChargePriceSummary.zqu__PriceSummary__c) 
	     					&& PRPChargePriceSummary.zqu__PriceSummary__c.startsWithIgnoreCase('USD')){
					PRPChargePriceSummary.zqu__PriceSummary__c = 'USD' + listPriceStr;
	     	}
	     	//charge Type is Usage
	     	else if(productRatePlanChargeType.equalsIgnoreCase('Usage')) {
	     		PRPChargePriceSummary.zqu__PriceSummary__c = 'USD' + listPriceStr + '/Dollars';
	     	}
	     	PRPChargePriceSummaryList.add(PRPChargePriceSummary);
	  	}
	  }
	  return PRPChargePriceSummaryList;
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}