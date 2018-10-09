global class BatchGenerateQuoteRatePlans implements Database.Batchable<sObject>, Database.Stateful {
	// Subscription being processed
	Zuora__Subscription__c currentSubscription;
	// New quote being generated
	zqu__Quote__c newQuote;
	// Map used to product rate plan
	Map<String, zqu__ProductRatePlan__c> nameToProductRateNameMap;
	// Processed rate plans in batch
	Set<String> ratePlansProcessed;
	// Opportunity being used to attach quote and line items
	Opportunity currentOpp;
	
	global BatchGenerateQuoteRatePlans(Id subscriptionId, Opportunity currentOpp) {
		zqu__CommunicationProfile__c defaultCommProfile;
		try {
			defaultCommProfile = [SELECT Id, Name FROM zqu__CommunicationProfile__c WHERE Name = 'Default Profile' LIMIT 1];
		} catch(Exception e) {
			ExceptionUtility.consumeException(e, true);
		}

		/*
			Try to query the Primary Contact role associated to the Opportunity AccountId lookup for the Opportunity Id that
			was provided. If this query fails(no primary or billing exists) then log error and instantiate and blank AccountContactRole
			which will cause the code below to populate blank values in Contact lookups.
		 */
		AccountContactRole primaryContactRole = ZuoraSubscriptionUtility.retrievePrimaryContactRole(currentOpp.Id);

		currentSubscription = Database.query(ZuoraSubscriptionUtility.SUBSCRIPTION_QUERY.replace('{WHERECLAUSE}', 'Id = :subscriptionId'));

		try {
			newQuote = ZuoraSubscriptionUtility.generateQuote(currentSubscription, currentOpp.Id, primaryContactRole, true);
		} catch(Exception e) {
			// Nothing to really rollback at this point but better safe than sorry
			delete newQuote;
			ExceptionUtility.consumeException(e, true);
			newQuote = null;
			return;	
		}

		// CSP-2323 - Only create quote for Print
		if(newQuote.Product_Line__c == 'Print') {
			return;
		}

		nameToProductRateNameMap = ZuoraSubscriptionUtility.buildProductRatePlanMap(currentSubscription.Zuora__Subscription_Product_Charges__r);

		ratePlansProcessed = new Set<String>();
		this.currentOpp = currentOpp;
	}
	
	// Iterable Batch Job - Not query selector
	global Iterable<SObject> start(Database.BatchableContext BC) {
		return currentSubscription.Zuora__Subscription_Product_Charges__r;
	}

  global void execute(Database.BatchableContext BC, List<SObject> scope) {
		// CSP-2323 - Only create quote for Print
		if(newQuote.Product_Line__c == 'Print') {
			return;
		}

		List<zqu__QuoteRatePlan__c> newQuoteRatePlanList = new List<zqu__QuoteRatePlan__c>();

		for(Integer i = 0; i < scope.size(); i++) {
			Zuora__SubscriptionProductCharge__c currentSubProductCharge = (Zuora__SubscriptionProductCharge__c)scope[i];

			// CSP-2167 - Same product but different location
			String uniqueKey = currentSubProductCharge.Zuora__RatePlanName__c + '' + currentSubProductCharge.LocationVendorDynamicsAccountID__c;
			if(!nameToProductRateNameMap.containsKey(currentSubProductCharge.Zuora__RatePlanName__c) || ratePlansProcessed.contains(uniqueKey)) {
				continue;
			}

			zqu__ProductRatePlan__c currentProductRatePlan = nameToProductRateNameMap.get(currentSubProductCharge.Zuora__RatePlanName__c);
			List<zqu__ProductRatePlanCharge__c> productRatePlanChargesList = currentProductRatePlan.R00N40000001mFVKEA2__r;
			
			Map<String, zqu__QuoteAmendment__c> prodRPCIdToQuoteAmendmentMap = new Map<String, zqu__QuoteAmendment__c>();
			for(Integer j = 0; j < productRatePlanChargesList.size(); j++) {
				zqu__ProductRatePlanCharge__c currentProdRatePlanCharge = productRatePlanChargesList[j];

				////////////////////////////
				// CREATE QUOTE AMENDMENT //
				////////////////////////////
				zqu__QuoteAmendment__c newQuoteAmendment = ZuoraSubscriptionUtility.generateQuoteAmendment(newQuote, currentProdRatePlanCharge, currentProductRatePlan, currentSubProductCharge);
				prodRPCIdToQuoteAmendmentMap.put(currentProdRatePlanCharge.Id, newQuoteAmendment);
			}

			// Insert in a FOR loop - Need the Quote Amendment Id's to create the Quote Rate Plan. Unfortunately can't get past
			// this and it is needed. This code will fail with large amounts of data being created - shouldn't be an issue for
			// 99% of the use cases.
			try {
				insert prodRPCIdToQuoteAmendmentMap.values();	
			} catch(Exception e) {
				delete newQuote;
				ExceptionUtility.consumeException(e, true);
				newQuote = null;
				return;
			}
			

			for(Integer j = 0; j < productRatePlanChargesList.size(); j++) {
				zqu__ProductRatePlanCharge__c currentProdRatePlanCharge = productRatePlanChargesList[j];
				// Shouldn't be possible - but just in case
				if(!prodRPCIdToQuoteAmendmentMap.containsKey(currentProdRatePlanCharge.Id)) {
					continue;
				}

				zqu__QuoteAmendment__c newQuoteAmendment = prodRPCIdToQuoteAmendmentMap.get(currentProdRatePlanCharge.Id);

				////////////////////////////
				// CREATE QUOTE RATE PLAN //
				////////////////////////////
				// Add Quote Rate Plan to list for insertion
				newQuoteRatePlanList.add(ZuoraSubscriptionUtility.generateQuoteRatePlan(newQuote, newQuoteAmendment, currentProductRatePlan, currentSubProductCharge));
				ratePlansProcessed.add(uniqueKey);
			}

			try {
				insert newQuoteRatePlanList;	
			} catch(Exception e) {
				delete newQuote;
				ExceptionUtility.consumeException(e, true);
				newQuote = null;
				return;
			}

			List<zqu__QuoteChargeSummary__c> newQuoteChargeSummaryList = new List<zqu__QuoteChargeSummary__c>();
			for(Integer j = 0; j < newQuoteRatePlanList.size(); j++) {
				zqu__QuoteRatePlan__c currentQuoteRatePlan = newQuoteRatePlanList[j];
				if(!nameToProductRateNameMap.containsKey(currentQuoteRatePlan.Name)) {
					continue;
				}

				currentProductRatePlan = nameToProductRateNameMap.get(currentQuoteRatePlan.Name);
				Map<String, zqu__QuoteRatePlanCharge__c> prodRPCIdToQuoteRatePlanChargeMap = new Map<String, zqu__QuoteRatePlanCharge__c>();

				for(Integer k = 0; k < productRatePlanChargesList.size(); k++) {
					zqu__ProductRatePlanCharge__c currentProdRatePlanCharge = productRatePlanChargesList[k];

					///////////////////////////////////
					// CREATE QUOTE RATE PLAN CHARGE //
					///////////////////////////////////
					zqu__QuoteRatePlanCharge__c newQuoteRatePlanCharge = ZuoraSubscriptionUtility.generateQuoteRatePlanCharge(currentQuoteRatePlan, currentProdRatePlanCharge);
					prodRPCIdToQuoteRatePlanChargeMap.put(currentProdRatePlanCharge.Id, newQuoteRatePlanCharge);				
				}

				// Insert in a FOR loop - Need the Quote Rate Plan Charge Id's to create the Quote Charge Summary. Unfortunately can't get past
				// this and it is needed. This code will fail with large amounts of data being created - shouldn't be an issue for
				// 99% of the use cases.
				try {
					insert prodRPCIdToQuoteRatePlanChargeMap.values();	
				} catch(Exception e) {
					delete newQuote;
					ExceptionUtility.consumeException(e, true);
					newQuote = null;
					return;
				}
				

				for(Integer k = 0; k < productRatePlanChargesList.size(); k++) {
					zqu__ProductRatePlanCharge__c currentProdRatePlanCharge = productRatePlanChargesList[k];
					if(!prodRPCIdToQuoteRatePlanChargeMap.containsKey(currentProdRatePlanCharge.Id)) {
						continue;
					}

					zqu__QuoteRatePlanCharge__c newQuoteRatePlanCharge = prodRPCIdToQuoteRatePlanChargeMap.get(currentProdRatePlanCharge.Id);

					/////////////////////////////////
					// CREATE QUOTE CHARGE SUMMARY //
					/////////////////////////////////
					newQuoteChargeSummaryList.add(ZuoraSubscriptionUtility.generateQuoteChargeSummary(currentProdRatePlanCharge, currentOpp.Id, newQuoteRatePlanCharge, currentQuoteRatePlan));
				}
			}

			// Insert the list of all new quote charge summaries
			try {
				insert newQuoteChargeSummaryList;
			} catch(Exception e) {
				delete newQuote;
				ExceptionUtility.consumeException(e, true);
				newQuote = null;
				return;
			}
		}
		
	}
	
	global void finish(Database.BatchableContext BC) {
		/////////////
		// FAILURE //
		/////////////
		if(newQuote == null) {
			Approval.unlock(currentOpp);

			currentOpp.StageName = 'Quote Generation Failed';
			update currentOpp;

			// Query used to get the current Opportunity being worked on so we can get the OwnerId for sending an email
			currentOpp = [SELECT Id, OwnerId, StageName, Name FROM Opportunity WHERE Id = :currentOpp.Id];

			OrgWideEmailAddress orgEmail = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@xogrp.com' LIMIT 1];

			String bodyText;

			bodyText = 'The auto renewal quote generation for <a href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + currentOpp.Id + '">' + currentOpp.Name + '</a> has failed. Manual generation is needed.';

			// Create Email about failure
			Messaging.SingleEmailMessage failureEmail = new Messaging.SingleEmailMessage();
			failureEmail.setHtmlBody(EmailUtility.createEmailBody('FAILURE', 'Renewal Quote Generation', bodyText));
      failureEmail.setSubject('Renewal Quote Generation Failure');
      failureEmail.setTargetObjectId(currentOpp.OwnerId);
      failureEmail.setSaveAsActivity(false);
      failureEmail.setOrgWideEmailAddressId(orgEmail.Id);

      try {
      	Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{failureEmail});
      } catch(Exception e) {
      	ExceptionUtility.consumeException(e, true);
      }

			return;
		}

		/////////////
		// SUCCESS //
		/////////////
		Approval.unlock(currentOpp);

		// CSP-2276 - Need to ensure all quote rate plans and charges align to the Preferred Payment Schedule on the Quote
		try {
			newQuote = ZuoraQuoteChooseNextActionController.RecalculateQuoteCharges(newQuote);	
		} catch(Exception e) {
			XO_Exception__c newException = ExceptionUtility.consumeException(e, false);
			newException.Related_Object_Id__c = newQuote.Id;
			newException.Failure_Area__c = 'Renewal Quote RecalculateQuoteCharges';
			newException.Severity__c = 'Minor';

			insert newException;
		}
		
		
		currentOpp.StageName = 'Prospecting';
		try {
			update currentOpp;	
		} catch(Exception e) {
			XO_Exception__c newException = ExceptionUtility.consumeException(e, false);
			newException.Related_Object_Id__c = currentOpp.Id;
			newException.Failure_Area__c = 'Opportunity';
			newException.Severity__c = 'Minor';

			insert newException;
		}
		
	}
	
}