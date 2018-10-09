public without sharing class ProductRulesAssessor {

	public static void evaluateOpportunity(Id oppId) {

		/****************************/
		/* INITIALIZE CONTROL FLAGS */
		/****************************/

		Boolean evaluateInternetProducts = False;
		Boolean evaluatePrintProducts = False;
		Boolean evaluateLDEProducts = False;
		Boolean updateOpportunity = False;


		/************************/
		/* PERFORM BASE QUERIES */
		/************************/

		// To minimize queries, first query Opportunity and child Quote records...
		Opportunity opp = [SELECT Id, Approval_Process_Flag_Manager_Approval__c, Approval_Process_Flag_Autoreject__c, Approval_Process_Info_For_Approver__c, (SELECT Id, zqu__SubscriptionType__c, Product_Line__c, Approval_Process_Flag_Discount_Amount__c FROM zqu__Quotes__r) FROM Opportunity WHERE Id = :oppId LIMIT 1];
		
		// ...and then query QuoteRatePlan and QuoteRatePlanCharge records
		// note: all formula assessment fields (like "Requires2X__c") looking up to ProductRatePlan return TEXT values -- even "numerical" ones like "MinimumSubscriptionTerm__c"
		List<zqu__QuoteRatePlan__c> qrpList = [SELECT Id, zqu__QuoteProductName__c, Name, zqu__AmendmentType__c, zqu__Quote__c, zqu__Quote__r.zqu__Opportunity__c, Location_Vendor__c, CannotBeSoldPast__c, NoAutomatedDiscount__c, RequiresApproval__c, RequiresPaidStorefront__c, MaximumSubscriptionTerm__c, MinimumSubscriptionTerm__c, Requires2X__c, Print_Issue__c, Print_Issue_Next_Issue_ID__c, Print_Issue_Previous_Issue_ID__c, Print_Issue_Step_2_Date__c, Print_Issue_Step_3_Date__c, (SELECT Id, Name, Product_Name__c, Print_Issue__c, Location_Vendor__c, Steelbrick_Calculated_Discount__c, zqu__Discount__c, Discount_Override__c FROM zqu__Quote_Rate_Plan_Charges__r) FROM zqu__QuoteRatePlan__c WHERE zqu__Quote__r.zqu__Opportunity__c = :opp.Id];
	

		/***********************************/
		/* CREATE OPPORTUNITYQUOTESWRAPPER */
		/***********************************/

		OpportunityQuotesWrapper oqw = generateOpportunityQuotesWrapper(opp, qrpList);


		/*********************/
		/* SET CONTROL FLAGS */
		/*********************/

		for (QuotesWrapper qw : oqw.quotesWrapperList) {
			if (qw.quoteProductLine == 'Internet' && evaluateInternetProducts != True) {
				evaluateInternetProducts = True;
			}
			else if (qw.quoteProductLine == 'Print' && evaluatePrintProducts != True) {
				evaluatePrintProducts = True;
			}
			else if (qw.quoteProductLine == 'Direct Mail' && evaluateLDEProducts != True) {
				evaluateLDEProducts = True;
			}
		}


		/******************************************/
		/* RUN PRODUCT RULE EVALUATIONS AS NEEDED */
		/******************************************/

		// NOTE: each Product Line method also needs to evaluate their own cancellation rules
		// this applies to both 'cancellation' Quotes, and 'amendment' Quotes with line items being removed

		if (evaluateInternetProducts) {
			// add Internet method here
		}

		if (evaluatePrintProducts) {
			oqw = runPrintEvaluation(oqw);
		}

		if (evaluateLDEProducts) {
			// add LDE method here
		}


		/*********************/
		/* EVALUATE DISCOUNTS */
		/*********************/

		oqw = runDiscountEvaluation(oqw);


		/*****************************/
		/* UPDATE OPPORTUNITY RECORD */
		/*****************************/

		// if both reasonsForAutoreject and reasonsForManagerApproval have been updated, add them both to the Oppotunity.Approval_Process_Info_For_Approver__c field
		// and set the Opportunity.Approval_Process_Flag_Autoreject__c flag to True
		if (oqw.reasonsForAutoreject != '### REASONS FOR AUTOREJECT ###' && oqw.reasonsForManagerApproval != '### REASONS FOR MANAGER APPROVAL ###') {
			oqw.opp.Approval_Process_Info_For_Approver__c = oqw.reasonsForAutoreject + '\n\n' + oqw.reasonsForManagerApproval;
			oqw.opp.Approval_Process_Flag_Autoreject__c = True;
			updateOpportunity = True;
		}
		// if only reasonsForAutoreject has been updated, add it to the Oppotunity.Approval_Process_Info_For_Approver__c field
		// and set the Opportunity.Approval_Process_Flag_Autoreject__c flag to True
		else if (oqw.reasonsForAutoreject != '### REASONS FOR AUTOREJECT ###') {
			oqw.opp.Approval_Process_Info_For_Approver__c = oqw.reasonsForAutoreject;
			oqw.opp.Approval_Process_Flag_Autoreject__c = True;
			updateOpportunity = True;
		}
		// if only reasonsForManagerApproval has been updated, add it to the Oppotunity.Approval_Process_Info_For_Approver__c field
		// and set the Opportunity.Approval_Process_Flag_Manager_Approval__c flag to True
		else if (oqw.reasonsForManagerApproval != '### REASONS FOR MANAGER APPROVAL ###') {
			oqw.opp.Approval_Process_Info_For_Approver__c = oqw.reasonsForManagerApproval;
			oqw.opp.Approval_Process_Flag_Manager_Approval__c = True;
			updateOpportunity = True;			
		}
		else {
			//TODO: do we need to do anything for Autoapproval here? or just let it ride?
		}


		// finally, update the Opportunity if it doesn't qualify for Autoapproval
		if (updateOpportunity) {
			update oqw.opp;
		}
	}


	public static OpportunityQuotesWrapper generateOpportunityQuotesWrapper(Opportunity opp, List<zqu__QuoteRatePlan__c> qrpList) {
		// temporary map used to tie together the two query results
		// Key: ID of Quote | Value: QuotesWrapper instance
		Map<Id, QuotesWrapper> tempMap = new Map<Id, QuotesWrapper>();

		for (zqu__Quote__c qr : opp.zqu__Quotes__r) {
			QuotesWrapper qw = new QuotesWrapper();
			qw.quote = qr;
			qw.quoteProductLine = qr.Product_Line__c;
			qw.quoteSubscriptionType = qr.zqu__SubscriptionType__c;
			tempMap.put(qr.Id, qw);
		}

		for (zqu__QuoteRatePlan__c qrp : qrpList) {
			QuotesWrapper qWrap = tempMap.get(qrp.zqu__Quote__c);
			qWrap.quoteRatePlanChargeListMap.put(qrp.Id, qrp.zqu__Quote_Rate_Plan_Charges__r);
			qWrap.quoteRatePlanMap.put(qrp.Id, qrp);
		}

		OpportunityQuotesWrapper oqw = new OpportunityQuotesWrapper();
		oqw.opp = opp;
		oqw.quotesWrapperList = tempMap.values();

		// default the two Approval flags to False; if necessary, they'll be updated in the "UPDATE OPPORTUNITY RECORD"
		// section of the main evaluateOpportunity method above
		oqw.opp.Approval_Process_Flag_Autoreject__c = False;
		oqw.opp.Approval_Process_Flag_Manager_Approval__c = False;

		return oqw;
	}


	public class OpportunityQuotesWrapper {
		
		public Opportunity opp;
		public List<QuotesWrapper> quotesWrapperList;

		// whenever you append a string to reasonsForAutoreject or reasonsForManagerApproval,
		// be sure to always start with a newline symbol (e.g. "\n")
		public String reasonsForAutoreject;
		public String reasonsForManagerApproval;

		public OpportunityQuotesWrapper() {
			this.quotesWrapperList = new List<QuotesWrapper>();
			this.reasonsForAutoreject = '### REASONS FOR AUTOREJECT ###';
			this.reasonsForManagerApproval = '### REASONS FOR MANAGER APPROVAL ###';
		}
	}


	public class QuotesWrapper {

		public zqu__Quote__c quote;
		public String quoteProductLine;
		public String quoteSubscriptionType;

		// Key: ID of QuoteRatePlan | Value: QuoteRatePlan record
		public Map<Id, zqu__QuoteRatePlan__c> quoteRatePlanMap;

		// Key: ID of parent QuoteRatePlan | Value: list of QuoteRatePlanCharge records
		public Map<Id, List<zqu__QuoteRatePlanCharge__c>> quoteRatePlanChargeListMap;

		public QuotesWrapper() {
			this.quoteRatePlanMap = new Map<Id, zqu__QuoteRatePlan__c>();
			this.quoteRatePlanChargeListMap = new Map<Id, List<zqu__QuoteRatePlanCharge__c>>();
		}
	}


	public static OpportunityQuotesWrapper runPrintEvaluation(OpportunityQuotesWrapper oqw) {

		// add logic here; only record in the OpportunityQuotesWrapper you update is the Opportunity
		// note: in the QuotesWrapper, the two maps are initialized as empty maps, and then the "generateOpportunityQuotesWrapper"
		// method populates them if needed; in your code, it's probably a good idea to make sure these aren't empty before running logic

		// for Print, all "2x" products have to be on the same Quote, which makes evaluation simpler than Internet

		// Design Note: could potentially eliminate the nested FOR loops if we first added all the QuoteRatePlans
		// from all the "Print" QuotesWrappers to a single map; that said, doing so would make the "2x" evaluations trickier
		// and -- just a hunch/feeling -- could make it trickier to add additional functionality moving forward
		

		// this flag set to True when a Quote is for a Subscription Cancellation or when a line item is removed during a Subscription Amendment
		Boolean subscriptionCancellationOrProductRemovalFlag = False;

		// map initially populated for "2x" Print QuoteRatePlans, then processed at the end before Subscription Cancellations and Product Removals
		Map<String, List<zqu__QuoteRatePlan__c>> twoXMap = new Map<String, List<zqu__QuoteRatePlan__c>>();

		for (QuotesWrapper qw : oqw.quotesWrapperList) {
			if (qw.quoteProductLine == 'Print' && qw.quoteSubscriptionType == 'Cancel Subscription' && subscriptionCancellationOrProductRemovalFlag == False) {
				subscriptionCancellationOrProductRemovalFlag = True;
			}
			else if (qw.quoteProductLine == 'Print') {
				for (zqu__QuoteRatePlan__c qrp : qw.quoteRatePlanMap.values()) {
					if (qrp.zqu__AmendmentType__c == 'RemoveProduct' && subscriptionCancellationOrProductRemovalFlag == False) {
						subscriptionCancellationOrProductRemovalFlag = True;
					}
					else if (qrp.zqu__AmendmentType__c != 'RemoveProduct') {

						// NOTE: I forget, are we going to "autolink" Print Issue??
						// think we were going to do that, and also -- maybe -- automatically add the next Issue to the Quote
						// if so, we should create the Print_Issue__c lookup on the QuoteRatePlan, then populate info on QuoteRatePlanCharge if needed
						// PLUS, if lookup is populated then I can include it in the original query -- so we should do this
						// **** populate it using the value in the "Print Sequence" field!!! ****
						// 11-9-15 Note: already added "Print_Issue__c" lookup to QuoteRatePlan, as well as formula fields
						

						if (qrp.Requires2X__c == 'Yes') {
							// for now, populate the map above for processing after this FOR loop

							String keyString = qrp.zqu__QuoteProductName__c + String.valueOf(qrp.Print_Issue__c).left(15);
							// if map contains key, get and update list
							if (twoXMap.containsKey(keyString)) {
								List<zqu__QuoteRatePlan__c> tempQRPListFortwoXMap = twoXMap.get(keyString);
								tempQRPListFortwoXMap.add(qrp);
								twoXMap.put(keyString, tempQRPListFortwoXMap);
							}
							// otherwise create new list and add to map
							else {
								List<zqu__QuoteRatePlan__c> newQRPListFortwoXMap = new List<zqu__QuoteRatePlan__c>();
								newQRPListFortwoXMap.add(qrp);
								twoXMap.put(keyString, newQRPListFortwoXMap);
							}

						}

						// always requires approval (ex: BOW, at least for now)
						if (qrp.RequiresApproval__c == 'Yes') {
							oqw.reasonsForManagerApproval += '\nThe Product ' + qrp.zqu__QuoteProductName__c + ' always requires manager approval';
						}

						// NOTE: all these date evaluations assume that if the date isn't filled in on the Print Issue, then we should ignore the rule
						// Nick wu comment out these sell by dates restrictions of pritn issue for CSP-1114
						// if (qrp.CannotBeSoldPast__c == 'Step 2 Date') {
						// 	if (qrp.Print_Issue_Step_2_Date__c != null && qrp.Print_Issue_Step_2_Date__c < Date.today()) {
						// 		oqw.reasonsForManagerApproval += '\nThe Rate Plan ' + qrp.Name + ' for Product ' + qrp.zqu__QuoteProductName__c + ' cannot be sold past the Step 2 Date of the Print Issue';
						// 	}
						// }

						// if (qrp.CannotBeSoldPast__c == '3 Weeks Before Step 2 Date') {
						// 	if ((qrp.Print_Issue_Step_2_Date__c != null) && (qrp.Print_Issue_Step_2_Date__c - 21 < Date.today())) {
						// 		oqw.reasonsForManagerApproval += '\nThe Rate Plan ' + qrp.Name + ' for Product ' + qrp.zqu__QuoteProductName__c + ' cannot be sold after three weeks before the Step 2 Date of the Print Issue';
						// 	}
						// }

						// if (qrp.CannotBeSoldPast__c == 'Step 3 Date') {
						// 	if (qrp.Print_Issue_Step_3_Date__c != null && qrp.Print_Issue_Step_3_Date__c < Date.today()) {
						// 		oqw.reasonsForManagerApproval += '\nThe Rate Plan ' + qrp.Name + ' for Product ' + qrp.zqu__QuoteProductName__c + ' cannot be sold past the Step 3 Date of the Print Issue';
						// 	}
						// }
					}
				}
			}
		}

		if (!twoXMap.isEmpty()) {

			// TODO: add 2x logic here

		}

		if (subscriptionCancellationOrProductRemovalFlag) {
			oqw = printSubscriptionCancellationOrProductRemovalEvaluation(oqw);
		}

		return oqw;
	}



	// TODO: added "Location_Vendor__c" Account lookup to the QuoteRatePlan object, but needs to be populated!!!
	// 11-12-15 Note: the only LDE-specific rules are Cancellations, and Requires Paid Storefront "In Any Market/Category"
	public static OpportunityQuotesWrapper runLDEEvaluation(OpportunityQuotesWrapper oqw) {

		Boolean subscriptionCancellationOrProductRemovalFlag = False;

		List<zqu__QuoteRatePlan__c> ldeRequiresPaidStorefrontList = new List<zqu__QuoteRatePlan__c>();

		for (QuotesWrapper qw : oqw.quotesWrapperList) {
			if (qw.quoteProductLine == 'Direct Mail' && qw.quoteSubscriptionType == 'Cancel Subscription' && subscriptionCancellationOrProductRemovalFlag == False) {
				subscriptionCancellationOrProductRemovalFlag = True;
			}
			else if (qw.quoteProductLine == 'Direct Mail') {
				for (zqu__QuoteRatePlan__c qrp : qw.quoteRatePlanMap.values()) {
					if (qrp.zqu__AmendmentType__c == 'RemoveProduct' && subscriptionCancellationOrProductRemovalFlag == False) {
						subscriptionCancellationOrProductRemovalFlag = True;
					}
					else if (qrp.zqu__AmendmentType__c != 'RemoveProduct' && qrp.RequiresPaidStorefront__c == 'In Any Market/Category') {
						// add all "Requires Paid Storefront In Any Market/Category" LDE QRPs to a list
						ldeRequiresPaidStorefrontList.add(qrp);
					}
				}
			}
		}

		// if some of the LDE products require a paid storefront, run logic
		if (!ldeRequiresPaidStorefrontList.isEmpty()) {
			



		}

		if (subscriptionCancellationOrProductRemovalFlag) {
			oqw = ldeSubscriptionCancellationOrProductRemovalEvaluation(oqw);
		}

		return oqw;
	}



	public static OpportunityQuotesWrapper ldeSubscriptionCancellationOrProductRemovalEvaluation(OpportunityQuotesWrapper oqw) {

		for (QuotesWrapper qw : oqw.quotesWrapperList) {
			if (qw.quoteProductLine == 'Direct Mail' && qw.quoteSubscriptionType == 'Cancel Subscription') {
				oqw.reasonsForManagerApproval += '\nThe Quote with ID ' + String.valueOf(qw.quote.Id) + ' is for a Subscription Cancellation';
			}
			else if (qw.quoteProductLine == 'Direct Mail') {		
				for (zqu__QuoteRatePlan__c qrp : qw.quoteRatePlanMap.values()) {
					if (qrp.zqu__AmendmentType__c == 'RemoveProduct') {
						oqw.reasonsForManagerApproval += '\nA product is being removed/cancelled from an existing subscription - Product: ' + qrp.zqu__QuoteProductName__c + ' | Rate Plan: ' + qrp.Name;
					}
				}
			}
		}

		return oqw;
	}


















	public static OpportunityQuotesWrapper printSubscriptionCancellationOrProductRemovalEvaluation(OpportunityQuotesWrapper oqw) {

		for (QuotesWrapper qw : oqw.quotesWrapperList) {
			if (qw.quoteProductLine == 'Print' && qw.quoteSubscriptionType == 'Cancel Subscription') {
				oqw.reasonsForManagerApproval += '\nThe Quote with ID ' + String.valueOf(qw.quote.Id) + ' is for a Subscription Cancellation';
			}
			else if (qw.quoteProductLine == 'Print') {		
				for (zqu__QuoteRatePlan__c qrp : qw.quoteRatePlanMap.values()) {
					if (qrp.zqu__AmendmentType__c == 'RemoveProduct') {
						oqw.reasonsForManagerApproval += '\nA product is being removed/cancelled from an existing subscription - Product: ' + qrp.zqu__QuoteProductName__c + ' | Rate Plan: ' + qrp.Name;
					}
				}
			}
		}

		return oqw;
	}



    // SF-1336
    // TODO: remove the Discount flag fields on the Quote and the Opportunity records, no longer needed
    public static OpportunityQuotesWrapper runDiscountEvaluation(OpportunityQuotesWrapper oqw) {
    	
    	List<zqu__QuoteRatePlanCharge__c> qrpcList = new List<zqu__QuoteRatePlanCharge__c>();

		for (QuotesWrapper qw : oqw.quotesWrapperList) {
			if (qw.quoteSubscriptionType != 'Cancel Subscription' && !qw.quoteRatePlanChargeListMap.isEmpty()) {
				for (List<zqu__QuoteRatePlanCharge__c> eachList : qw.quoteRatePlanChargeListMap.values()) {
					qrpcList.addAll(eachList);
				}
			}
		}

		if (!qrpcList.isEmpty()) {
			for (zqu__QuoteRatePlanCharge__c qrpc : qrpcList) {
	    		if (qrpc.Discount_Override__c > qrpc.Steelbrick_Calculated_Discount__c) {
	    			oqw.reasonsForManagerApproval += '\nThe Rate Plan Charge "' + qrpc.Name + '" for Product "' + qrpc.Product_Name__c + '" has a Discount Override that is greater than what was autocalculated';
    			}			
			}
		}

		return oqw;
    }


}