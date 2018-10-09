public class ZuoraTCVAndPaymentSchedule {

	// static variables
	public static String zuoraRESTAPIPath;

	// generic exception used throughout the entire process
	public class tcvException extends Exception {}

	// virtual classes
	public virtual class BaseClass {
		public String initialTermPeriodType;
		public Integer initialTerm;
		public String customerAcceptanceDate;
		public String serviceActivationDate;
		public String contractEffectiveDate;
		public String invoiceTargetDate;
		public String termType;
		public List<ZuoraTCVAndPaymentSchedule.SubscribeToRatePlan> subscribeToRatePlans;
	}

	public virtual class NewAccount extends BaseClass {
		public ZuoraTCVAndPaymentSchedule.PreviewAccountInfo previewAccountInfo;
	}

	public virtual class ExistingAccount extends BaseClass {
		public String accountKey;
	}

	public virtual class ChargeOverride {
		public Double price;
		public String productRatePlanChargeId;
		public String description;
	}

	// non-virtual classes
	public class PreviewAccountInfo {
		public Integer billCycleDay;
		public ZuoraTCVAndPaymentSchedule.BillToContact billToContact;
		public String previewAccountInfoCurrency;
	}

	public class BillToContact {
		public String state;
		public String county;
		public String city;
		public String country;
		public String zipCode;
	}

	public class SubscribeToRatePlan {
		public String productRatePlanId;
		public List<ZuoraTCVAndPaymentSchedule.ChargeOverride> chargeOverrides;
	}

	// classes for specific scenarios (for charge overrides)
	// L66 (direct mail requires two separate overrides, one for the first charge and another for the second charge)
	public class ChargeOverrideDirectMail extends ChargeOverride {
		public String triggerDate;
		public String triggerEvent;
	}

	public class ChargeOverrideInternetWithoutBillingPeriodAlignment extends ChargeOverride {
		public String billingPeriod;
	}

	//CSP-2898 Enable Discounts for a Promotional Period (Switch Pitch)
	//For 3 months free model Without Billing Period
	public class ChargeOverrideInternetWithoutBillingPeriodAlignmentProm extends ChargeOverride {
	public String billingPeriod;
	public String endDateCondition;
	public String triggerDate;
	public String triggerEvent;
	public String specificEndDate;
 }

	public class ChargeOverrideInternetWithBillingPeriodAlignment extends ChargeOverride {
		public String billingPeriod;
		public String billingPeriodAlignment;
	}

	//CSP-2898 Enable Discounts for a Promotional Period (Switch Pitch)
	//For 3 months free model Wit hBilling Period
	public class ChargeOverrideInternetWithBillingPeriodAlignmentProm extends ChargeOverride {
		public String billingPeriod;
		public String billingPeriodAlignment;
		public String endDateCondition;
		public String triggerDate;
		public String triggerEvent;
		public String specificEndDate;
	}

	public class ChargeOverridePrintNonMonthlySub extends ChargeOverride {
		public String billingPeriod;
		public String endDateCondition;
		public Integer upToPeriods;
		public String upToPeriodsType;
		public String triggerDate;
		public String triggerEvent;
		public String billingPeriodAlignment;
	}

	public class ChargeOverridePrintMonthlySubNewAccount extends ChargeOverride {
		public String billingPeriod;
		public String triggerDate;
		public String triggerEvent;
	}

	public class ChargeOverridePrintMonthlySubExistingAccount extends ChargeOverride {
		public String billingPeriod;
		public String endDateCondition;
		public Integer upToPeriods;
		public String upToPeriodsType;
		public String triggerDate;
		public String triggerEvent;		
	}

	// START AMENDMENT CLASSES

	// virtual classes
	public virtual class AmendmentBaseClass {
		public Boolean includeExistingDraftInvoiceItems;
		public String previewType;
		public Boolean preview;
		public String currentTermPeriodType;
		public Integer currentTerm;
		public String invoiceTargetDate;
		public String termType;
	}

	// non-virtual classes
	public class ProductUpdate extends AmendmentBaseClass {
		public List<Update_Z> update_Z;
	}

	public class ProductAdd extends AmendmentBaseClass {
		public List<Add> add;
	}

	public class ProductRemove extends AmendmentBaseClass {
		public List<Remove> remove;
	}

	public class ProductUpdateAdd extends AmendmentBaseClass {
		public List<Update_Z> update_Z;
		public List<Add> add;
	}

	public class ProductUpdateRemove extends AmendmentBaseClass {
		public List<Update_Z> update_Z;
		public List<Remove> remove;
	}

	public class ProductAddRemove extends AmendmentBaseClass {
		public List<Add> add;
		public List<Remove> remove;
	}

	public class ProductUpdateAddRemove extends AmendmentBaseClass {
		public List<Update_Z> update_Z;
		public List<Add> add;
		public List<Remove> remove;
	}

	public class Add {
		public List<ChargeOverride> chargeOverrides;
		public String customerAcceptanceDate;
		public String serviceActivationDate;
		public String contractEffectiveDate;
		public String productRatePlanId;
	}

	public class ChargeUpdateDetails {
		public Double price; 
		public String ratePlanChargeId;
		public String description;
	}
	
	public class Remove {
		public String customerAcceptanceDate;
		public String serviceActivationDate;
		public String contractEffectiveDate;
		public String ratePlanId;
	}
	
	public class Update_Z {
		public String customerAcceptanceDate;
		public String serviceActivationDate; 
		public String contractEffectiveDate;
		public List<ChargeUpdateDetails> chargeUpdateDetails;
		public String ratePlanId;
	}

	// END AMENDMENT CLASSES

	public class OpportunityQuotesWrapper {
		public Opportunity opp;
		public List<QuotesWrapper> quotesWrapperList;
	}

	public class QuotesWrapper {
		public zqu__Quote__c quote;
		public Id quoteId;
		public String quoteProductLine;
		public String quoteSubscriptionType;
		public Decimal tcvAmount;
		public Map<Id, zqu__QuoteRatePlan__c> quoteRatePlanMap; // Key: ID of QuoteRatePlan | Value: QuoteRatePlan record
		public Map<Id, List<zqu__QuoteRatePlanCharge__c>> quoteRatePlanChargeListMap; // Key: ID of parent QuoteRatePlan | Value: list of QuoteRatePlanCharge records
		// CSP-2667 Adding more than 60 services
		// used to store the response json string if the string is too long
		public Attachment tcvJSONAttachment;

		public QuotesWrapper() {
			this.quoteRatePlanMap = new Map<Id, zqu__QuoteRatePlan__c>();
			this.quoteRatePlanChargeListMap = new Map<Id, List<zqu__QuoteRatePlanCharge__c>>();
			this.tcvJSONAttachment = new Attachment();
		}
	}

	public static OpportunityQuotesWrapper generateOpportunityQuotesWrapper(Id oppId) {


		// To minimize queries, first query Opportunity and child Quote records...
		Opportunity opp = [SELECT Id, Potential_Value_Direct_Marketing__c, Potential_Value_Internet__c, Potential_Value_Print__c, StageName,
							(SELECT Id, True_TCV__c, True_TCV_JSON_Response__c, zqu__ExistSubscriptionID__c, zqu__BillCycleDay__c, zqu__Subscription_Term_Type__c, zqu__InvoiceTargetDate__c, zqu__StartDate__c, zqu__Service_Activation_Date__c, zqu__Customer_Acceptance_Date__c, zqu__ZuoraAccountID__c, zqu__InitialTerm__c, zqu__SubscriptionType__c, Product_Line__c FROM zqu__Quotes__r) FROM Opportunity WHERE Id = :oppId LIMIT 1];
		

		system.debug('2222222 opp' + opp);

		system.debug('2222222 opp.zqu__Quotes__r ' + opp.zqu__Quotes__r); 

		// ...and then query QuoteRatePlan and QuoteRatePlanCharge records
		// note: all formula assessment fields (like "Requires2X__c") looking up to ProductRatePlan return TEXT values -- even "numerical" ones like "MinimumSubscriptionTerm__c"
		List<zqu__QuoteRatePlan__c> qrpList = [SELECT Id, zqu__ProductRatePlanZuoraId__c, zqu__Quote__c, zqu__AmendmentType__c, zqu__SubscriptionRatePlanZuoraId__c, 
																									(SELECT Id, zqu__Model__c, zqu__ProductRatePlanChargeZuoraId__c, zqu__Total__c, 
																											zqu__BillingPeriodAlignment__c, zqu__TriggerEvent__c, zqu__TriggerDate__c, 
																											zqu__Upto_How_Many_Periods_Type__c, zqu__Upto_How_Many_Periods__c, 
																											zqu__EndDateCondition__c, zqu__Period__c, zqu__SubscriptionRatePlanChargeZuoraId__c, 
																											Preferred_Payment_Schedule__c, True_TCV__c, zqu__ChargeType__c, zqu__SpecificEndDate__c 
																										FROM zqu__Quote_Rate_Plan_Charges__r) 
																					FROM zqu__QuoteRatePlan__c 
																					WHERE zqu__Quote__r.zqu__Opportunity__c = :opp.Id];

		system.debug('2222222 qrpList' + qrpList);

		// temporary map used to tie together the two query results
		// Key: ID of Quote | Value: QuotesWrapper instance
		Map<Id, QuotesWrapper> tempMap = new Map<Id, QuotesWrapper>();
		for (zqu__Quote__c qr : opp.zqu__Quotes__r) {
			QuotesWrapper qw = new QuotesWrapper();
			qw.quote = qr;
			qw.quoteId = qr.Id;
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

		system.debug('2222222 oqw' + oqw);

		return oqw;
	}


	// pass in new direct mail quote, return SubscribeToRatePlans list
	public static List<SubscribeToRatePlan> buildSTRPListForNewDirectMailSubs(QuotesWrapper qw) {
		List<SubscribeToRatePlan> strpList = new List<SubscribeToRatePlan>();
		for (zqu__QuoteRatePlan__c qrp : qw.quoteRatePlanMap.values()) {
			SubscribeToRatePlan strp = new SubscribeToRatePlan();
			strp.productRatePlanId = qrp.zqu__ProductRatePlanZuoraId__c;
			strp.chargeOverrides = new List<ChargeOverride>();
			for (zqu__QuoteRatePlanCharge__c qrpc : qw.quoteRatePlanChargeListMap.get(qrp.Id)) {
				// charge override logic here
				// for direct mail there will be two charges per QuoteRatePlan: one 20% and one 80%
				// the 20% uses the regular ChargeOverride class while the 80% uses the ChargeOverrideDirectMail class
				// the difference on the QuoteRatePlanCharges is that the 80% will have a value in the TriggerEvent and TriggerDate fields,
				// while the 20% will not have values in these fields
				// logic for 80%:
				if (String.isNotBlank(qrpc.zqu__TriggerEvent__c) && qrpc.zqu__TriggerDate__c != null) {
					ChargeOverrideDirectMail co80 = new ChargeOverrideDirectMail();
					co80.productRatePlanChargeId = qrpc.zqu__ProductRatePlanChargeZuoraId__c;
					co80.price = qrpc.zqu__Total__c;
					// right now this only covers the TriggerEvent being set to SpecificDate
					//co80.triggerEvent = qrpc.zqu__TriggerEvent__c;
					co80.triggerEvent = setQuoteRatePlanChargeTriggerEventCode(qrpc.zqu__TriggerEvent__c);
					co80.triggerDate = String.valueOf(qrpc.zqu__TriggerDate__c);
					co80.description = qrpc.Id;
					strp.chargeOverrides.add(co80);
				}
				// logic for 20%:
				else {
					ChargeOverride co20 = new ChargeOverride();
					co20.productRatePlanChargeId = qrpc.zqu__ProductRatePlanChargeZuoraId__c;
					co20.price = qrpc.zqu__Total__c;
					co20.description = qrpc.Id;
					strp.chargeOverrides.add(co20);
				}
			}
			strpList.add(strp);
		}
		return strpList;
	}

	public static List<SubscribeToRatePlan> buildSTRPListForNewInternetSubs(QuotesWrapper qw) {
		List<SubscribeToRatePlan> strpList = new List<SubscribeToRatePlan>();
		for (zqu__QuoteRatePlan__c qrp : qw.quoteRatePlanMap.values()) {
			SubscribeToRatePlan strp = new SubscribeToRatePlan();
			strp.productRatePlanId = qrp.zqu__ProductRatePlanZuoraId__c;
			strp.chargeOverrides = new List<ChargeOverride>();
			for (zqu__QuoteRatePlanCharge__c qrpc : qw.quoteRatePlanChargeListMap.get(qrp.Id)) {
				// CSP-1681 | one-time Internet charge -- assumes the charge is configured to be active Upon Service Activation
				if (String.isNotBlank(qrpc.zqu__ChargeType__c) && qrpc.zqu__ChargeType__c == 'One-Time') {
					ChargeOverride coOneTime = new ChargeOverride();
					coOneTime.productRatePlanChargeId = qrpc.zqu__ProductRatePlanChargeZuoraId__c;
					coOneTime.price = qrpc.zqu__Total__c;
					coOneTime.description = qrpc.Id;
					strp.chargeOverrides.add(coOneTime);
				}
				// charge override logic here
				else if (String.isNotBlank(qrpc.zqu__BillingPeriodAlignment__c)) {
					// CSP-2898 Enable Discounts for a Promotional Period (Switch Pitch)
					// update Payment Schedule code for 3 months free
					if(qrpc.zqu__TriggerDate__c != null || qrpc.zqu__SpecificEndDate__c != null) {
						ChargeOverrideInternetWithBillingPeriodAlignmentProm coWithBPA = new ChargeOverrideInternetWithBillingPeriodAlignmentProm();
						if(qrpc.zqu__TriggerDate__c != null) {
							coWithBPA.triggerEvent = setQuoteRatePlanChargeTriggerEventCode(qrpc.zqu__TriggerEvent__c);
							coWithBPA.triggerDate = String.valueOf(qrpc.zqu__TriggerDate__c);
						}
						if(qrpc.zqu__SpecificEndDate__c != null) {
							coWithBPA.endDateCondition = 'Specific_End_Date';
							coWithBPA.specificEndDate = String.valueOf(qrpc.zqu__SpecificEndDate__c);
						}
						coWithBPA.productRatePlanChargeId = qrpc.zqu__ProductRatePlanChargeZuoraId__c;
						coWithBPA.price = qrpc.zqu__Total__c;
						coWithBPA.billingPeriod = qrpc.zqu__Period__c.containsIgnoreCase('semi-annual') ? 'Semi_Annual' : qrpc.zqu__Period__c; // weird format for semi-annual for the preview api
						coWithBPA.billingPeriodAlignment = qrpc.zqu__BillingPeriodAlignment__c;
						coWithBPA.description = qrpc.Id;
						strp.chargeOverrides.add(coWithBPA);
					}
					//Normal quote rate plan charge to Calculation TCV 
					else {
						ChargeOverrideInternetWithBillingPeriodAlignment coWithBPA = new ChargeOverrideInternetWithBillingPeriodAlignment();
						coWithBPA.productRatePlanChargeId = qrpc.zqu__ProductRatePlanChargeZuoraId__c;
						coWithBPA.price = qrpc.zqu__Total__c;
						coWithBPA.billingPeriod = qrpc.zqu__Period__c.containsIgnoreCase('semi-annual') ? 'Semi_Annual' : qrpc.zqu__Period__c; // weird format for semi-annual for the preview api
						coWithBPA.billingPeriodAlignment = qrpc.zqu__BillingPeriodAlignment__c;
						coWithBPA.description = qrpc.Id;
						strp.chargeOverrides.add(coWithBPA);
					}
				}
				else {
					// CSP-2898 Enable Discounts for a Promotional Period (Switch Pitch)
					// update Payment Schedule code for 3 months free
					if(qrpc.zqu__TriggerDate__c != null || qrpc.zqu__SpecificEndDate__c != null) {
						ChargeOverrideInternetWithoutBillingPeriodAlignmentProm coWithoutBPA = new ChargeOverrideInternetWithoutBillingPeriodAlignmentProm();
						if(qrpc.zqu__TriggerDate__c != null){
							coWithoutBPA.triggerEvent = setQuoteRatePlanChargeTriggerEventCode(qrpc.zqu__TriggerEvent__c);
							coWithoutBPA.triggerDate = String.valueOf(qrpc.zqu__TriggerDate__c);
						}
						if(qrpc.zqu__SpecificEndDate__c != null){
							coWithoutBPA.endDateCondition = 'Specific_End_Date';
							coWithoutBPA.specificEndDate = String.valueOf(qrpc.zqu__SpecificEndDate__c);
						}
						coWithoutBPA.productRatePlanChargeId = qrpc.zqu__ProductRatePlanChargeZuoraId__c;
						coWithoutBPA.price = qrpc.zqu__Total__c;
						coWithoutBPA.billingPeriod = qrpc.zqu__Period__c.containsIgnoreCase('semi-annual') ? 'Semi_Annual' : qrpc.zqu__Period__c; // weird format for semi-annual for the preview api
						coWithoutBPA.description = qrpc.Id;
						strp.chargeOverrides.add(coWithoutBPA);
					}
					//Normal quote rate plan charge to Calculation TCV  
					else{
						ChargeOverrideInternetWithoutBillingPeriodAlignment coWithoutBPA = new ChargeOverrideInternetWithoutBillingPeriodAlignment();
						coWithoutBPA.productRatePlanChargeId = qrpc.zqu__ProductRatePlanChargeZuoraId__c;
						coWithoutBPA.price = qrpc.zqu__Total__c;
						coWithoutBPA.billingPeriod = qrpc.zqu__Period__c.containsIgnoreCase('semi-annual') ? 'Semi_Annual' : qrpc.zqu__Period__c; // weird format for semi-annual for the preview api
						coWithoutBPA.description = qrpc.Id;
						strp.chargeOverrides.add(coWithoutBPA);
					}
				}
			}
			strpList.add(strp);
		}
		return strpList;
	}

	public static List<SubscribeToRatePlan> buildSTRPListForNewPrintSubs(QuotesWrapper qw) {
		List<SubscribeToRatePlan> strpList = new List<SubscribeToRatePlan>();
		for (zqu__QuoteRatePlan__c qrp : qw.quoteRatePlanMap.values()) {
			SubscribeToRatePlan strp = new SubscribeToRatePlan();
			strp.productRatePlanId = qrp.zqu__ProductRatePlanZuoraId__c;
			strp.chargeOverrides = new List<ChargeOverride>();
			for (zqu__QuoteRatePlanCharge__c qrpc : qw.quoteRatePlanChargeListMap.get(qrp.Id)) {
				// charge override logic here
				// non-monthly subscription (both new and existing accounts)
				if (!qrpc.zqu__Period__c.containsIgnoreCase('month')) {
					ChargeOverridePrintNonMonthlySub coPNMS = new ChargeOverridePrintNonMonthlySub();
					coPNMS.productRatePlanChargeId = qrpc.zqu__ProductRatePlanChargeZuoraId__c;
					coPNMS.price = qrpc.zqu__Total__c;
					coPNMS.billingPeriod = qrpc.zqu__Period__c.containsIgnoreCase('semi-annual') ? 'Semi_Annual' : qrpc.zqu__Period__c; // weird format for semi-annual for the preview api
					coPNMS.billingPeriodAlignment = qrpc.zqu__BillingPeriodAlignment__c;
					coPNMS.endDateCondition = 'Fixed_Period'; // special format for zqu__EndDateCondition__c
					coPNMS.upToPeriods = Integer.valueOf(qrpc.zqu__Upto_How_Many_Periods__c);
					coPNMS.upToPeriodsType = 'Billing_Periods'; // special format for zqu__Upto_How_Many_Periods_Type__c
					coPNMS.triggerEvent = qrpc.Preferred_Payment_Schedule__c == 'Annual' ? 'USD' : setQuoteRatePlanChargeTriggerEventCode(qrpc.zqu__TriggerEvent__c); // special logic for annual print charges (they're set up differently in the ZuoraQuoteChooseNextActionController.RecalculateQuoteCharges method)
					coPNMS.triggerDate = qrpc.Preferred_Payment_Schedule__c == 'Annual' ? String.valueOf(qw.quote.zqu__Service_Activation_Date__c) : String.valueOf(qrpc.zqu__TriggerDate__c); // special logic for annual print charges (they're set up differently in the ZuoraQuoteChooseNextActionController.RecalculateQuoteCharges method)
					coPNMS.description = qrpc.Id;
					strp.chargeOverrides.add(coPNMS);
				}
				// monthly subscription, new account
				else if (String.isBlank(qw.quote.zqu__ZuoraAccountID__c)) {
					ChargeOverridePrintMonthlySubNewAccount coPMSNA = new ChargeOverridePrintMonthlySubNewAccount();
					coPMSNA.productRatePlanChargeId = qrpc.zqu__ProductRatePlanChargeZuoraId__c;
					coPMSNA.price = qrpc.zqu__Total__c;
					coPMSNA.billingPeriod = qrpc.zqu__Period__c.containsIgnoreCase('semi-annual') ? 'Semi_Annual' : qrpc.zqu__Period__c; // weird format for semi-annual for the preview api
					coPMSNA.triggerEvent = setQuoteRatePlanChargeTriggerEventCode(qrpc.zqu__TriggerEvent__c);
					coPMSNA.triggerDate = String.valueOf(qrpc.zqu__TriggerDate__c);
					coPMSNA.description = qrpc.Id;
					strp.chargeOverrides.add(coPMSNA);
				}
				// monthly subscription, existing account
				else {
					ChargeOverridePrintMonthlySubExistingAccount coPMSEA = new ChargeOverridePrintMonthlySubExistingAccount();
					coPMSEA.productRatePlanChargeId = qrpc.zqu__ProductRatePlanChargeZuoraId__c;
					coPMSEA.price = qrpc.zqu__Total__c;
					coPMSEA.billingPeriod = qrpc.zqu__Period__c.containsIgnoreCase('semi-annual') ? 'Semi_Annual' : qrpc.zqu__Period__c; // weird format for semi-annual for the preview api
					coPMSEA.endDateCondition = 'Fixed_Period'; // special format for zqu__EndDateCondition__c
					coPMSEA.upToPeriods = Integer.valueOf(qrpc.zqu__Upto_How_Many_Periods__c);
					coPMSEA.upToPeriodsType = 'Billing_Periods'; // special format for zqu__Upto_How_Many_Periods_Type__c
					coPMSEA.triggerEvent = setQuoteRatePlanChargeTriggerEventCode(qrpc.zqu__TriggerEvent__c);
					coPMSEA.triggerDate = String.valueOf(qrpc.zqu__TriggerDate__c);
					coPMSEA.description = qrpc.Id;
					strp.chargeOverrides.add(coPMSEA);
				}
			}
			strpList.add(strp);
		}
		return strpList;
	}

	public static PreviewAccountInfo buildPreviewAccountInfo(QuotesWrapper qw) {
		PreviewAccountInfo pai = new PreviewAccountInfo();
		pai.billCycleDay = Integer.valueOf(qw.quote.zqu__BillCycleDay__c);
		// need to provide values for BillToContact, but the actual values don't really matter for our purposes
		pai.billToContact = new BillToContact();
		pai.billToContact.state = 'California';
		pai.billToContact.county = 'Contra Consta';
		pai.billToContact.city = 'Walnut Creek';
		pai.billToContact.country = 'United States';
		pai.billToContact.zipCode = '94549';
		pai.previewAccountInfoCurrency = 'USD';
		return pai;
	}

	public static Object populateBaseClassFields(QuotesWrapper qw) {
		BaseClass bc = new BaseClass();
		//bc.contractEffectiveDate = String.valueOf(qw.quote.zqu__StartDate__c);
		bc.contractEffectiveDate = String.valueOf(qw.quote.zqu__Service_Activation_Date__c); // JPS NOTE 8-8-2016: based on our current config, charges start on the Service Activation Date
		bc.customerAcceptanceDate = String.valueOf(qw.quote.zqu__Customer_Acceptance_Date__c);
		bc.initialTerm = Integer.valueOf(qw.quote.zqu__InitialTerm__c);
		bc.initialTermPeriodType = 'Month'; // this is always set to Month because of how the product catalog is configured
		bc.invoiceTargetDate = '2099-01-01'; // set this to a date way out in the future to pick up all charges
		bc.serviceActivationDate = String.valueOf(qw.quote.zqu__Service_Activation_Date__c);
		bc.termType = qw.quote.zqu__Subscription_Term_Type__c.containsIgnoreCase('termed') ? 'TERMED' : 'EVERGREEN'; // this is case-sensitive for the Preview API
		return (Object)bc;
	}

	public static Object populateAmendmentBaseClassFields(QuotesWrapper qw) {
		AmendmentBaseClass abc = new AmendmentBaseClass();
		abc.currentTerm = Test.isRunningTest() ? 12 : getSubscriptionCurrentTerm(qw.quote.zqu__ExistSubscriptionID__c);
		abc.currentTermPeriodType = 'Month'; // this is always set to Month because of how the product catalog is configured
		abc.invoiceTargetDate = '2099-01-01'; // set this to a date way out in the future to pick up all charges
		abc.termType = qw.quote.zqu__Subscription_Term_Type__c.containsIgnoreCase('termed') ? 'TERMED' : 'EVERGREEN'; // this is case-sensitive for the Preview API
		abc.preview = true;
		abc.previewType = 'InvoiceItem';
		abc.includeExistingDraftInvoiceItems = false;
		return (Object)abc;
	}

	public static NewAccount castBaseClassObjectAsNewAccount(Object bcObject) {
		return (NewAccount)JSON.deserialize(JSON.serialize(bcObject), Type.forName('ZuoraTCVAndPaymentSchedule.NewAccount'));
	}

	public static ExistingAccount castBaseClassObjectAsExistingAccount(Object bcObject) {
		return (ExistingAccount)JSON.deserialize(JSON.serialize(bcObject), Type.forName('ZuoraTCVAndPaymentSchedule.ExistingAccount'));
	}

	// All
	public static String buildNewAccountNewSubWrapper(QuotesWrapper qw) {
		NewAccount newAccountWrapper = castBaseClassObjectAsNewAccount(populateBaseClassFields(qw));
		newAccountWrapper.previewAccountInfo = buildPreviewAccountInfo(qw);
		if (qw.quoteProductLine == 'Internet') {
			newAccountWrapper.subscribetoRatePlans = buildSTRPListForNewInternetSubs(qw);
		}
		else if (qw.quoteProductLine == 'Print') {
			newAccountWrapper.subscribetoRatePlans = buildSTRPListForNewPrintSubs(qw);
		}
		else if (qw.quoteProductLine == 'Direct Mail') {
			newAccountWrapper.subscribetoRatePlans = buildSTRPListForNewDirectMailSubs(qw);
		}
		return JSON.serialize(newAccountWrapper,true);
	}

	public static String buildExistingAccountNewSubWrapper(QuotesWrapper qw) {
		ExistingAccount existingAccountWrapper = castBaseClassObjectAsExistingAccount(populateBaseClassFields(qw));
		existingAccountWrapper.accountKey = qw.quote.zqu__ZuoraAccountID__c;
		if (qw.quoteProductLine == 'Internet') {
			existingAccountWrapper.subscribetoRatePlans = buildSTRPListForNewInternetSubs(qw);
		}
		else if (qw.quoteProductLine == 'Print') {
			existingAccountWrapper.subscribetoRatePlans = buildSTRPListForNewPrintSubs(qw);
		}
		else if (qw.quoteProductLine == 'Direct Mail') {
			existingAccountWrapper.subscribetoRatePlans = buildSTRPListForNewDirectMailSubs(qw);
		}
		return JSON.serialize(existingAccountWrapper, true);
	}

	public static Add buildAddWrapper(QuotesWrapper qw, zqu__QuoteRatePlan__c qrp) {
		Add addWrapper = new Add();
		addWrapper.chargeOverrides = new List<ChargeOverride>();
		for (zqu__QuoteRatePlanCharge__c qrpc : qw.quoteRatePlanChargeListMap.get(qrp.Id)) {
			// charge override logic here
			if (String.isNotBlank(qrpc.zqu__BillingPeriodAlignment__c)) {
				ChargeOverrideInternetWithBillingPeriodAlignment coWithBPA = new ChargeOverrideInternetWithBillingPeriodAlignment();
				coWithBPA.productRatePlanChargeId = qrpc.zqu__ProductRatePlanChargeZuoraId__c;
				coWithBPA.price = qrpc.zqu__Total__c;
				coWithBPA.billingPeriod = qrpc.zqu__Period__c.containsIgnoreCase('semi-annual') ? 'Semi_Annual' : qrpc.zqu__Period__c; // weird format for semi-annual for the preview api
				coWithBPA.billingPeriodAlignment = qrpc.zqu__BillingPeriodAlignment__c;
				coWithBPA.description = qrpc.Id;
				addWrapper.chargeOverrides.add(coWithBPA);
			}
			else {
				ChargeOverrideInternetWithoutBillingPeriodAlignment coWithoutBPA = new ChargeOverrideInternetWithoutBillingPeriodAlignment();
				coWithoutBPA.productRatePlanChargeId = qrpc.zqu__ProductRatePlanChargeZuoraId__c;
				coWithoutBPA.price = qrpc.zqu__Total__c;
				coWithoutBPA.billingPeriod = qrpc.zqu__Period__c.containsIgnoreCase('semi-annual') ? 'Semi_Annual' : qrpc.zqu__Period__c; // weird format for semi-annual for the preview api
				coWithoutBPA.description = qrpc.Id;
				addWrapper.chargeOverrides.add(coWithoutBPA);
			}	
		}
		addWrapper.customerAcceptanceDate = String.valueOf(qw.quote.zqu__Customer_Acceptance_Date__c);
		addWrapper.contractEffectiveDate = String.valueOf(qw.quote.zqu__StartDate__c);
		addWrapper.serviceActivationDate = String.valueOf(qw.quote.zqu__Service_Activation_Date__c);
		addWrapper.productRatePlanId = qrp.zqu__ProductRatePlanZuoraId__c;
		return addWrapper;
	}

	public static Update_Z buildUpdateWrapper(QuotesWrapper qw, zqu__QuoteRatePlan__c qrp) {
		Update_Z updateWrapper = new Update_Z();
		updateWrapper.chargeUpdateDetails = new List<ChargeUpdateDetails>();
		for (zqu__QuoteRatePlanCharge__c qrpc : qw.quoteRatePlanChargeListMap.get(qrp.Id)) {
			// charge override logic here
			ChargeUpdateDetails chargeUpdateDetail = new ChargeUpdateDetails();
			chargeUpdateDetail.price = qrpc.zqu__Total__c;
			chargeUpdateDetail.ratePlanChargeId = qrpc.zqu__SubscriptionRatePlanChargeZuoraId__c;
			chargeUpdateDetail.description = qrpc.Id;
			updateWrapper.chargeUpdateDetails.add(chargeUpdateDetail);
		}
		updateWrapper.customerAcceptanceDate = String.valueOf(qw.quote.zqu__Customer_Acceptance_Date__c);
		updateWrapper.contractEffectiveDate = String.valueOf(qw.quote.zqu__StartDate__c);
		updateWrapper.serviceActivationDate = String.valueOf(qw.quote.zqu__Service_Activation_Date__c);
		updateWrapper.ratePlanId = qrp.zqu__SubscriptionRatePlanZuoraId__c;
		return updateWrapper;
	}

	public static Remove buildRemoveWrapper(QuotesWrapper qw, zqu__QuoteRatePlan__c qrp) {
		Remove removeWrapper = new Remove();
		removeWrapper.customerAcceptanceDate = String.valueOf(qw.quote.zqu__Customer_Acceptance_Date__c);
		removeWrapper.contractEffectiveDate = String.valueOf(qw.quote.zqu__StartDate__c);
		removeWrapper.serviceActivationDate = String.valueOf(qw.quote.zqu__Service_Activation_Date__c);
		removeWrapper.ratePlanId = qrp.zqu__SubscriptionRatePlanZuoraId__c;
		return removeWrapper;
	}

	public static Integer getSubscriptionCurrentTerm(String subZuoraId) {
		HttpRequest req = new HttpRequest();
		req.setTimeout(120000); 
		req.setMethod('GET');
		req.setHeader('Content-Type', 'application/json');
		req.setHeader('Accept', 'application/json');
		req.setEndpoint('callout:Zuora_REST_API' + zuoraRESTAPIPath + '/v1/subscriptions/' + subZuoraId);
		Http http = new Http();
		Integer currentTerm;
		if (!Test.isRunningTest()) {
			try {
				//Execute web service call here		
				HTTPResponse res = http.send(req);
				//Helpful debug messages
				System.debug(res.toString());
				System.debug('STATUS:'+res.getStatus());
				System.debug('STATUS_CODE:'+res.getStatusCode());
				System.debug(res.getBody());
				Object resObj = JSON.deserializeUntyped(res.getBody());
				Map<String, Object> resObjMap = (Map<String, Object>)resObj;
				System.debug('current term:');
				currentTerm = (Integer)resObjMap.get('currentTerm');
				System.debug(currentTerm);
			} 
			catch(Exception e) {
				throw new tcvException(e.getMessage());
			}
		}
		return currentTerm;
	}

	public static String buildAmendmentSubWrapper(QuotesWrapper qw) {
		List<Add> addList = new List<Add>();
		List<Update_Z> updateList = new List<Update_Z>();
		List<Remove> removeList = new List<Remove>();
		for (zqu__QuoteRatePlan__c qrp : qw.quoteRatePlanMap.values()) {
			if (qrp.zqu__AmendmentType__c.containsIgnoreCase('new') && qw.quoteRatePlanChargeListMap.containsKey(qrp.Id)) {
				addList.add(buildAddWrapper(qw, qrp));
			}
			else if (qrp.zqu__AmendmentType__c.containsIgnoreCase('update') && qw.quoteRatePlanChargeListMap.containsKey(qrp.Id)) {
				System.debug('found update!!!!!!!');
				updateList.add(buildUpdateWrapper(qw, qrp));
			}
			else if (qrp.zqu__AmendmentType__c.containsIgnoreCase('remove') && qw.quoteRatePlanChargeListMap.containsKey(qrp.Id)) {
				removeList.add(buildRemoveWrapper(qw, qrp));
			}
		}
		// determine what kinds of amendments are happening in this quote and use the appropriate wrapper class
		Object amendmentBaseClassObj = populateAmendmentBaseClassFields(qw);
		String amendmentSubJSON = '';
		// subscription amendment scenario: add, update, remove
		if (!addList.isEmpty() && !updateList.isEmpty() && !removeList.isEmpty()) {
			ProductUpdateAddRemove puar = (ProductUpdateAddRemove)JSON.deserialize(JSON.serialize(amendmentBaseClassObj), Type.forName('ZuoraTCVAndPaymentSchedule.ProductUpdateAddRemove'));
			puar.add = addList;
			puar.update_Z = updateList;
			puar.remove = removeList;
			amendmentSubJSON = JSON.serialize(puar);
		}
		// subscription amendment scenario: add, update
		else if (!addList.isEmpty() && !updateList.isEmpty()) {
			ProductUpdateAdd pua = (ProductUpdateAdd)JSON.deserialize(JSON.serialize(amendmentBaseClassObj), Type.forName('ZuoraTCVAndPaymentSchedule.ProductUpdateAdd'));
			pua.add = addList;
			pua.update_Z = updateList;
			amendmentSubJSON = JSON.serialize(pua);		
		}
		// subscription amendment scenario: add, remove
		else if (!addList.isEmpty() && !removeList.isEmpty()) {
			ProductAddRemove par = (ProductAddRemove)JSON.deserialize(JSON.serialize(amendmentBaseClassObj), Type.forName('ZuoraTCVAndPaymentSchedule.ProductAddRemove'));
			par.add = addList;
			par.remove = removeList;
			amendmentSubJSON = JSON.serialize(par);
		}
		// subscription amendment scenario: update, remove
		else if (!updateList.isEmpty() && !removeList.isEmpty()) {
			ProductUpdateRemove pur = (ProductUpdateRemove)JSON.deserialize(JSON.serialize(amendmentBaseClassObj), Type.forName('ZuoraTCVAndPaymentSchedule.ProductUpdateRemove'));
			pur.update_Z = updateList;
			pur.remove = removeList;
			amendmentSubJSON = JSON.serialize(pur);
		}
		// subscription amendment scenario: add
		else if (!addList.isEmpty()) {
			ProductAdd pa = (ProductAdd)JSON.deserialize(JSON.serialize(amendmentBaseClassObj), Type.forName('ZuoraTCVAndPaymentSchedule.ProductAdd'));
			pa.add = addList;
			amendmentSubJSON = JSON.serialize(pa);
		}
		// subscription amendment scenario: update
		else if (!updateList.isEmpty()) {
			ProductUpdate pu = (ProductUpdate)JSON.deserialize(JSON.serialize(amendmentBaseClassObj), Type.forName('ZuoraTCVAndPaymentSchedule.ProductUpdate'));
			pu.update_Z = updateList;
			amendmentSubJSON = JSON.serialize(pu);
		}
		// subscription amendment scenario: remove
		else if (!removeList.isEmpty()) {
			ProductRemove pr = (ProductRemove)JSON.deserialize(JSON.serialize(amendmentBaseClassObj), Type.forName('ZuoraTCVAndPaymentSchedule.ProductRemove'));			
			pr.remove = removeList;
			amendmentSubJSON = JSON.serialize(pr);
		}		
		return amendmentSubJSON;
	}

	public static void authenticateWithZuoraRESTAPI() {
		Http http = new Http();
		HttpRequest req = new HttpRequest();
		req.setTimeout(120000); 
		req.setMethod('GET');
		req.setHeader('Content-Type', 'application/json');
		req.setHeader('Accept', 'application/json');
		req.setEndpoint('callout:Zuora_REST_API' + zuoraRESTAPIPath + '/v1/connections');
		try {   
		    HTTPResponse res = http.send(req);  
		    System.debug(res.toString());
		    System.debug('STATUS:'+res.getStatus());
		    System.debug('STATUS_CODE:'+res.getStatusCode());
		    System.debug(res.getBody());
		} 
		// this catches both callout exceptions and process exceptions
		catch (Exception e) {
			if (!Test.isRunningTest()) {
				throw new tcvException(e.getMessage(), e);
			}
		}
	}

	public static QuotesWrapper retrieveSubscriptionPreview(QuotesWrapper qw) {
		// 1. set this environment's specific base REST API path (i.e. /rest or /apps)
		// one of the few "global" static variables
		zuoraRESTAPIPath = getZuoraRESTAPIPath();
		
		// 1.1 authenticate with Connections endpoint (https://knowledgecenter.zuora.com/DC_Developers/REST_API/B_REST_API_reference/Connections)
		authenticateWithZuoraRESTAPI();

		// 2. setup HTTPRequest object (details will vary depending on subscription type)
		System.debug('quote id');
		System.debug(qw.quoteId);
		System.debug('subscription type');
		System.debug(qw.quoteSubscriptionType);
		Boolean isAmendment = (qw.quoteSubscriptionType == 'Amend Subscription');
		HttpRequest req = new HttpRequest();
		req.setTimeout(120000);
		req.setMethod(isAmendment ? 'PUT' : 'POST');
		req.setHeader('Content-Type', 'application/json');
		req.setHeader('Accept', 'application/json');
		req.setEndpoint(isAmendment ? 'callout:Zuora_REST_API' + zuoraRESTAPIPath + '/v1/subscriptions/' + qw.quote.zqu__ExistSubscriptionID__c : 'callout:Zuora_REST_API' + zuoraRESTAPIPath + '/v1/subscriptions/preview');

		System.debug('ENDPOINT URL!!!');
		System.debug(req.getEndpoint());

		// 3. build and set body string
		String bodyString = '';
		System.debug('before bodystring');
		if (isAmendment) {
			bodyString = buildAmendmentSubWrapper(qw);
		}
		else {
			bodyString = String.isBlank(qw.quote.zqu__ZuoraAccountID__c) ? buildNewAccountNewSubWrapper(qw) : buildExistingAccountNewSubWrapper(qw);
		}
		System.debug('after body string');
		System.debug(bodyString);

		// HACK ALERT! 'currency' and 'update' are reserved words in apex, so we need to call them something else in their respective wrapper classes and then relabel them here
		bodyString = bodyString.replace('previewAccountInfoCurrency', 'currency');
		bodyString = bodyString.replace('update_Z', 'update');
		System.debug('bodyString');
		System.debug(bodyString);
		req.setBody(bodyString);

		// 4. do callout and retrieve preview
		Http http = new Http();
		try {
			//Execute web service call here
			HTTPResponse res = http.send(req);	

			//Helpful debug messages
			System.debug(res.toString());
			System.debug('STATUS:'+res.getStatus());
			System.debug('STATUS_CODE:'+res.getStatusCode());
			System.debug(res.getBody());
			Object resObj = JSON.deserializeUntyped(res.getBody());
			System.debug('resObj');
			System.debug(resObj);
			Map<String, Object> resObjMap = (Map<String, Object>)resObj;
			System.debug('resObjMap');
			System.debug(resObjMap);
			System.debug('isSuccess');
			System.debug((Boolean)resObjMap.get('success'));
			System.debug('amount');
			System.debug((Decimal)resObjMap.get('amount'));

			if ((Boolean)resObjMap.get('success')) {
				qw.quote.True_TCV__c = (Decimal)resObjMap.get('amount');
				// CSP-2667 Adding more than 60 services
				// used to store the response json string if the string is too long
				if (qw.quoteRatePlanMap.size() > Integer.valueOf(Label.quoteRatePlanSize)) {
					qw.tcvJSONAttachment.parentID=qw.quote.id;
					qw.tcvJSONAttachment.Body = blob.valueof(res.getBody());
					qw.tcvJSONAttachment.Name = String.valueOf(qw.quote.id) + 'JSON.txt';
				}
				else {
					qw.quote.True_TCV_JSON_Response__c = res.getBody();
				}

				// CSP-1334 functionality
				// basically tally up and set the value for each Quote Rate Plan Charge's "True_TCV__c" field
				ZuoraSubscriptionPreview zsp = (ZuoraSubscriptionPreview)JSON.deserializeStrict(res.getBody(), ZuoraSubscriptionPreview.class);
				Map<Id, Decimal> qrpcIdToChargeAmountMap = new Map<Id, Decimal>();
				Map<String, Decimal> nullChargeDescriptionPRPCIdToChargeAmountMap = new Map<String, Decimal>();
				for (ZuoraSubscriptionPreview.InvoiceItems invoiceItem : zsp.InvoiceItems) {
					System.debug('charge description!!!');
					System.debug(invoiceItem.chargeDescription);
					System.debug(invoiceItem.productRatePlanChargeId);
					if (String.isNotBlank(invoiceItem.chargeDescription)) {
						Decimal chargeAmount = qrpcIdToChargeAmountMap.containsKey(invoiceItem.chargeDescription) ? qrpcIdToChargeAmountMap.get(invoiceItem.chargeDescription) : 0.00;
						chargeAmount += invoiceItem.chargeAmount;
						qrpcIdToChargeAmountMap.put(invoiceItem.chargeDescription, chargeAmount);
					}
					// Zuora assigns a null value to the Invoice Item's chargeDescription field for negative-value Amendment charges (for proration)
					// if null, add to map and down below match with the first QuoteRatePlanCharge that matches the productRatePlanChargeId value
					else {
						Decimal chargeAmount = nullChargeDescriptionPRPCIdToChargeAmountMap.containsKey(invoiceItem.productRatePlanChargeId) ? nullChargeDescriptionPRPCIdToChargeAmountMap.get(invoiceItem.productRatePlanChargeId) : 0.00;
						chargeAmount += invoiceItem.chargeAmount;
						nullChargeDescriptionPRPCIdToChargeAmountMap.put(invoiceItem.productRatePlanChargeId, chargeAmount);						
					}
				}
				for (List<zqu__QuoteRatePlanCharge__c> zspQRPCList : qw.quoteRatePlanChargeListMap.values()) {
					for (zqu__QuoteRatePlanCharge__c zspQRPC : zspQRPCList) {
						zspQRPC.True_TCV__c = 0.00;
						if (qrpcIdToChargeAmountMap.containsKey(zspQRPC.Id)) {
							zspQRPC.True_TCV__c += qrpcIdToChargeAmountMap.get(zspQRPC.Id);
						}
						if (nullChargeDescriptionPRPCIdToChargeAmountMap.containsKey(zspQRPC.zqu__ProductRatePlanChargeZuoraId__c)) {
							zspQRPC.True_TCV__c += nullChargeDescriptionPRPCIdToChargeAmountMap.remove(zspQRPC.zqu__ProductRatePlanChargeZuoraId__c); // remove in case there's more than one QRPC for the same PRPC; we don't want to double count this
						}						
					}
				}
			}
			else {
				List<Object> reasonsListObj = (List<Object>)resObjMap.get('reasons');
				System.debug(reasonsListObj);
				if (!reasonsListObj.isEmpty()) {
					Map<String, Object> reasonsObjMap = (Map<String, Object>)reasonsListObj[0];
					String code = String.valueOf((Integer)reasonsObjMap.get('code'));
					String message = (String)reasonsObjMap.get('message');
					System.debug(code + ' | ' + message);
					throw new tcvException(code + ' | ' + message);
				}
				else {
					throw new tcvException('Callout succeeded, but no reason returned by Zuora API');
				}
			}
		}
		// this catches both callout exceptions and process exceptions
		catch (Exception e) {

			throw new tcvException(e.getMessage(), e);
		}

		// 5. return QuoteWrapper
		return qw;
	}

	/*
	ContractEffective = UCE
	ServiceActivation = USA
	CustomerAcceptance = UCA
	SpecificDate = USD
	*/
	public static String setQuoteRatePlanChargeTriggerEventCode(String triggerEvent) {
		if (triggerEvent == 'ContractEffective') {
			return 'UCE';
		}
		if (triggerEvent == 'ServiceActivation') {
			return 'USA';
		}
		if (triggerEvent == 'CustomerAcceptance') {
			return 'UCA';
		}
		if (triggerEvent == 'SpecificDate') {
			return 'USD';
		}
		// otherwise, just return the passed-in value
		return triggerEvent;
	}

	public static String getZuoraRESTAPIPath() {
		Organization o = [SELECT IsSandbox FROM Organization LIMIT 1];
		Map<String, Zuora_Environment_URL__c> zuoraEnvMap = Zuora_Environment_URL__c.getAll();
		String zRESTAPIPath = '';
		// scenario: production
		if (!o.IsSandbox) {
			System.debug('use Zuora production REST API');
			zRESTAPIPath = zuoraEnvMap.containsKey('Production') ? zuoraEnvMap.get('Production').Zuora_REST_API_Path__c : '/rest';
			return zRESTAPIPath;
		}
		// scenario: sandbox listed in the custom setting
		String sfdcEnvironmentBaseURL = URL.getSalesforceBaseUrl().toExternalForm();
		for (String sfdcEnvName : zuoraEnvMap.keySet()) {
			if (sfdcEnvironmentBaseURL.containsIgnoreCase(sfdcEnvName)) {
				zRESTAPIPath = zuoraEnvMap.get(sfdcEnvName).Zuora_REST_API_Path__c;
				return zRESTAPIPath;
			}
		}
		// scenario: default sandbox URL (if not found it assigns an empty string)
		zRESTAPIPath = zuoraEnvMap.containsKey('SandboxDefault') ? zuoraEnvMap.get('SandboxDefault').Zuora_REST_API_Path__c : '';
		if (String.isBlank(zRESTAPIPath)) {
			throw new tcvException('Failed to retrieve the Base URL of the Zuora API endpoint');
		}
		return zRESTAPIPath;
	}

	public static Boolean setTrueTCV(Id oppId) {

		system.debug('22222222 ' );
		// there are MANY places in this process that a exception or general process failure can occur
		// this try/catch block will catch platform exceptions like DmlException, etc
		// to handle general process failures (like not retrieving the Zuora API endpoint URL from the custom setting, a record not existing in Zuora, etc),
		// a generic exception named "tcvException" is used to stop the process and record the failure details
		try {

			system.debug('22222222 oppId ' + oppId);
			OpportunityQuotesWrapper oqw = generateOpportunityQuotesWrapper(oppId);
			List<zqu__Quote__c> quoteList = new List<zqu__Quote__c>();
			List<zqu__QuoteRatePlanCharge__c> qrpcUpdateList = new List<zqu__QuoteRatePlanCharge__c>();
			// CSP-2667 Adding more than 60 services
			List<Attachment> attList = new List<Attachment>();
			Set<Id> quoteIdSet = new Set<Id>();
			oqw.opp.Potential_Value_Internet__c = 0.00;
			oqw.opp.Potential_Value_Print__c = 0.00;
			oqw.opp.Potential_Value_Direct_Marketing__c = 0.00;
			// define which product lines require the TCV calculation
			Set<String> subPreviewProductLineSet = new Set<String>{'Internet', 'Print', 'Direct Mail'};		
			for (QuotesWrapper qw : oqw.quotesWrapperList) {
				if (subPreviewProductLineSet.contains(qw.quoteProductLine) && qw.quoteSubscriptionType != 'Cancel Subscription') {
					qw = retrieveSubscriptionPreview(qw);
					if (qw.quoteProductLine == 'Internet') {
						oqw.opp.Potential_Value_Internet__c	+= qw.quote.True_TCV__c;			
					}
					else if (qw.quoteProductLine == 'Print') {
						oqw.opp.Potential_Value_Print__c += qw.quote.True_TCV__c;
					}
					else if (qw.quoteProductLine == 'Direct Mail') {
						oqw.opp.Potential_Value_Direct_Marketing__c += qw.quote.True_TCV__c;
					}
					quoteList.add(qw.quote);
					
					// CSP-2667 Adding more than 60 services
					// we should store the quote Id for query the old attachments to delete.
					quoteIdSet.add(qw.quote.Id);
					// if the attachment is not null, we should add to the attlist, and insert to system.
					if (qw.tcvJSONAttachment != NULL && String.isNotBlank(qw.tcvJSONAttachment.ParentId)) {
						attList.add(qw.tcvJSONAttachment);
					}

					for (List<zqu__QuoteRatePlanCharge__c> qrpcList : qw.quoteRatePlanChargeListMap.values()) {
						qrpcUpdateList.addAll(qrpcList);
					}					
				}
			}
			if (!quoteList.isEmpty()) {
				update quoteList;
			}
			if (!qrpcUpdateList.isEmpty()) {
				update qrpcUpdateList;
			}
			// CSP-2667 Adding more than 60 services
			// delete the old attachment when the quote has been updated
			if (!quoteIdSet.isEmpty()) {
				List<Attachment> deleteAttList = [SELECT Id FROM Attachment WHERE ParentId in :quoteIdSet AND Name LIKE '%JSON.txt'];
				if (!deleteAttList.isEmpty()) {
					delete deleteAttList;
				}
			}
			// insert the response attachment when the response json is too long
			if (!attList.isEmpty()) {
				insert attList;
			}
			
			update oqw.opp;
		}
		catch (Exception e) {
			// insert XO Exception record
			System.debug('caught the exception!!!!!!!!!!!!!!');
			System.debug(e.getMessage());
			System.debug(e.getLineNumber());
			System.debug(e.getCause());
			ExceptionUtility.consumeException(e, true);
			/*
			// set Opportunity stage to 'TCV Calculation Failed' 
			Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Id = :oppId LIMIT 1];
			opp.StageName = 'TCV Calculation Failed';
			update opp;
			*/
			return false;
		}
		return true;
	}
}