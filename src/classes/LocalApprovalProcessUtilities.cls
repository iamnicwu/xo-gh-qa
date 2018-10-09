global without sharing class LocalApprovalProcessUtilities {
	// CSP-572 | webservice called from Local Opp record detail page from a custom "Submit for Approval" button
	webservice static Boolean submitLocalOppForApproval(Id oppId) {
		// CSP-2232 and CSP-2349 
		// Check and update Commission charge type before Submit for Approval 
		// Commented by SF release 4.05
		//ZuoraQuoteEditLineItemsController.updateCommissionChargeType(oppId);

		// run product rules first
		LocalProductRules.evaluateOpportunity(oppId);
		// then, submit the Opportunity for approval
		Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
		app.setObjectId(oppId);
		Approval.ProcessResult result = Approval.process(app);
		return result.isSuccess();
	}

	webservice static String checkSubmitForApproval(Id oppId){
		//CSP - 2485 Disallow Sending Internet Quotes to Zuora without LocationId
		//Check below in the Quote Rate Plan if missing location id and LocationVendorDynamicsAccountID 
		List<zqu__QuoteRatePlanCharge__c> QuoteRatePlanChargeList = [SELECT Id, zqu__QuoteRatePlan__r.zqu__Quote__r.Product_Line__c,Location_Vendor__c
                                                                 FROM zqu__QuoteRatePlanCharge__c 
                                                                 WHERE zqu__QuoteRatePlan__r.zqu__Quote__r.zqu__Opportunity__c =: oppId  
                                                                  AND zqu__QuoteRatePlan__r.zqu__Quote__r.Product_Line__c = 'Internet' 
                                                                  AND (Location_Vendor__c = null 
                                                                    or LocationVendorDynamicsAccountID__c = null 
                                                                    or LocationVendorDynamicsAccountID__c = ''
                                                                    OR zqu__QuoteRatePlan__r.Location_Vendor__c = null)];
		//Disallow approval opportunity.	
		if(!QuoteRatePlanChargeList.isEmpty()) {
			return System.Label.MessageWithoutLocationId;
		}else{
			return 'true';
		}
	}

	// CSP-1787
	webservice static Boolean setOppSkipEchoSignFlagIfApplicableWebservice(Id oppId, String oppType, String userProfileName) {
		return setOppSkipEchoSignFlagIfApplicable(oppId, oppType, userProfileName);
	}

	/**
	 *   CSP-1787 | setOppSkipEchoSignFlagIfApplicable sets the Opportunity.Approval_Process_Flag_Skip_EchoSign__c checkbox to true
	 *   if the submitting user's profile is either Local Core Sales Operations or Systems Administrator and the Opportunity.Type is Renewal
	 *
	 *   @author Jonathan Satterfield
	 *   @date   2016-12-29
	 *   @param  {Id}   oppId
	 *   @param  {String}   oppType
	 *   @param  {String}   userProfileName
	 *   @return {Boolean}
	 */
	public static Boolean setOppSkipEchoSignFlagIfApplicable(Id oppId, String oppType, String userProfileName) {
		// default return value is true
		Boolean success = true;
		Set<String> userProfilesThatCanSkipEchoSignForRenewals = new Set<String>{'Local Core Sales Operations', 'System Administrator'};
		if (userProfilesThatCanSkipEchoSignForRenewals.contains(userProfileName) && oppType == 'Renewal') {
			// normally shouldn't perform DML in loop, but this SOQL query is limited to 1 record
			for (Opportunity oppRec : [SELECT Id, Approval_Process_Flag_Skip_EchoSign__c FROM Opportunity WHERE Id = :oppId LIMIT 1]) {
				// only update the Opportunity if needed
				if (oppRec.Approval_Process_Flag_Skip_EchoSign__c) {
					break;
				}
				oppRec.Approval_Process_Flag_Skip_EchoSign__c = true;
				Database.SaveResult dbUpdateResult = Database.update(oppRec, false);
				if (!dbUpdateResult.isSuccess()) {
					ExceptionUtility.consumeException(dbUpdateResult, true);
					success = false;
				}
			}
		}
		return success;
	}
}