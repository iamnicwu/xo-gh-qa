public class QuoteRatePlanTriggerHandler {


    /* 
    <method>
      <name>PopulateVendorLocationAccountDuringInternetAmendment</name>
      <purpose>When a Amendment Quote for an Internet Subscription is created, autopopulate the Vendor Location Account on the Quote Rate Plans</purpose>
	  <created>
	    <by>Jonathan Satterfield</by>
	    <date>12/17/2015</date>
	    <ticket>SF-1844</ticket>
	  </created>
    </method>
    */ 
	public static void PopulateVendorLocationAccountDuringInternetAmendment(List<zqu__QuoteRatePlan__c> newList) {

		// if the Quote is for an Internet Amendment, populate the Vendor 
		// Location lookup with the value from the previous version of the Subscription

		Map<Id, List<zqu__QuoteRatePlan__c>> quoteIdToQuoteRatePlanListMap = new Map<Id, List<zqu__QuoteRatePlan__c>>();

		for (zqu__QuoteRatePlan__c qrp : newList) {
			if (qrp.zqu__AmendmentType__c == 'UpdateProduct' && (qrp.Product_Type__c == 'Internet' || qrp.Product_Type__c == 'Direct Mail')) {
				List<zqu__QuoteRatePlan__c> qrpList;
				if (quoteIdToQuoteRatePlanListMap.containsKey(qrp.zqu__Quote__c)) {
					qrpList = quoteIdToQuoteRatePlanListMap.get(qrp.zqu__Quote__c);
					qrpList.add(qrp);
					quoteIdToQuoteRatePlanListMap.put(qrp.zqu__Quote__c, qrpList);
				}
				else {
					qrpList = new List<zqu__QuoteRatePlan__c>();
					qrpList.add(qrp);
					quoteIdToQuoteRatePlanListMap.put(qrp.zqu__Quote__c, qrpList);
				}
			}
		}

		if (!quoteIdToQuoteRatePlanListMap.isEmpty()) {
			
			Map<String, List<zqu__QuoteRatePlan__c>> subNameToQuoteRatePlanListMap = new Map<String, List<zqu__QuoteRatePlan__c>>();

			for (zqu__Quote__c quoteRec : [SELECT Id, zqu__Subscription_Name__c FROM zqu__Quote__c WHERE Id IN :quoteIdToQuoteRatePlanListMap.keyset()]) {
				subNameToQuoteRatePlanListMap.put(quoteRec.zqu__Subscription_Name__c, quoteIdToQuoteRatePlanListMap.get(quoteRec.Id));
			}

			// can now query Subscription Product Charge records directly
			List<Zuora__SubscriptionProductCharge__c> spcList = [SELECT Id, Zuora__Subscription__r.Name, LDE_Email_Launch_Date__c, LocationVendorDynamicsAccountID__c, Zuora__ProductName__c, Zuora__RatePlanName__c, Product_Type__c FROM Zuora__SubscriptionProductCharge__c WHERE Zuora__Subscription__r.Name IN :subNameToQuoteRatePlanListMap.keySet()];
			

			Set<String> locationVendorDynamicsAccountIDStringSet = new Set<String>();

			for (Zuora__SubscriptionProductCharge__c spc : spcList) {
				locationVendorDynamicsAccountIDStringSet.add(spc.LocationVendorDynamicsAccountID__c);
			}


			Map<String, Id> dynamicsAccountsIdStringToAccountIdMap = new Map<String, Id>();

			for (Account a : [SELECT Id, DynamicsAccID__c FROM Account WHERE DynamicsAccID__c IN :locationVendorDynamicsAccountIDStringSet]) {
				dynamicsAccountsIdStringToAccountIdMap.put(a.DynamicsAccID__c, a.Id);
			}


			for (Zuora__SubscriptionProductCharge__c spc : spcList) {
				if (subNameToQuoteRatePlanListMap.containsKey(spc.Zuora__Subscription__r.Name)) {
					List<zqu__QuoteRatePlan__c> zQRPList = subNameToQuoteRatePlanListMap.get(spc.Zuora__Subscription__r.Name);
					for (Integer i = 0; i < zQRPList.size(); i++) {
						// when a match is found...
						if (zQRPList[i].zqu__QuoteProductName__c == spc.Zuora__ProductName__c && zQRPList[i].Name == spc.Zuora__RatePlanName__c) {
							if (spc.Product_Type__c == 'Internet') {
								// set Location_Vendor__c field
								// Commented By Shashish on 27th july, 2017, CSP-1009
								//zQRPList[i].Location_Vendor__c = dynamicsAccountsIdStringToAccountIdMap.get(spc.LocationVendorDynamicsAccountID__c);
							}
							else if (spc.Product_Type__c == 'Direct Mail') {
								// set LDE_Email_Launch_Date__c field
								zQRPList[i].LDE_Email_Launch_Date__c = spc.LDE_Email_Launch_Date__c;
							}
							// remove zQRP from zQRPList and add it back to the subNameToQuoteRatePlanListMap
							zQRPList.remove(i);
							subNameToQuoteRatePlanListMap.put(spc.Zuora__Subscription__r.Name, zQRPList);
							// exit the inner loop
							break;
						}
					}
				}
			}

		}

	}
}