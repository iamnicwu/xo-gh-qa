/* 
<class>
  <name>QuoteRatePlanChargeTriggerHandler</name>
  <purpose>For handling save/update events on Zuora QuoteRatePlanCharge records</purpose>
  <created>
    <by>Jonathan Satterfield</by>
    <date>7/22/2015</date>
    <ticket>SF-598, SF-599, SF-601</ticket>
  </created>
</class>
*/
public class QuoteRatePlanChargeTriggerHandler {
    /* 
    <method>
      <name>UpdateIDsForCommissionTracking</name>
      <purpose>When QuoteRatePlanCharge records are created (when a Quote amending an existing Quote is saved), 
      record the SalesRepId, RenewalRepId, and the RSD_Id from the Quote on each QuoteRatePlanCharge record</purpose>
      <created>
        <by>Jonathan Satterfield</by>
        <date>7/22/2015</date>
        <ticket>SF-598, SF-599, SF-601, SF-1822</ticket>
      </created>
    </method>
    */
    public static void UpdateIDsForCommissionTracking(List<zqu__QuoteRatePlanCharge__c> newList) {
    	Set<Id> qrpIdSet = new Set<Id>();
        for (zqu__QuoteRatePlanCharge__c qrpc : newList) {
            qrpIdSet.add(qrpc.zqu__QuoteRatePlan__c);
        }

		Map<Id, zqu__QuoteRatePlan__c> qrpMap = new Map<Id, zqu__QuoteRatePlan__c>([SELECT Id, zqu__AmendmentType__c, zqu__SubscriptionRatePlanZuoraId__c, zqu__Quote__r.SalesRepId__c, zqu__Quote__r.RenewalRepId__c, zqu__Quote__r.RSD_Id__c FROM zqu__QuoteRatePlan__c WHERE zqu__AmendmentType__c != null AND Id IN :qrpIdSet]);

		// create a list for QuoteRatePlanCharges that don't exist on a current Subscription,
		// and a map for QuoteRatePlanCharges that do exist on a current Subscription
    	List<zqu__QuoteRatePlanCharge__c> qrpcNewList = new List<zqu__QuoteRatePlanCharge__c>();
    	Map<String, zqu__QuoteRatePlanCharge__c> qrpcUpdateMap = new Map<String, zqu__QuoteRatePlanCharge__c>();

    	// populate the list and the map
    	for (zqu__QuoteRatePlanCharge__c qrpcRec : newList) {
    		zqu__QuoteRatePlan__c qrpRec = qrpMap.get(qrpcRec.zqu__QuoteRatePlan__c);
    		// NOTE: may also want to include Amendment Type "TermsAndConditions"
    		if (qrpRec.zqu__AmendmentType__c == 'UpdateProduct') {
    			qrpcUpdateMap.put(qrpRec.zqu__SubscriptionRatePlanZuoraId__c, qrpcRec);
    		}
    		else {
    			qrpcNewList.add(qrpcRec);
    		}
    	}

    	// if there are QuoteRatePlanCharges that exist on a current Subscription, query the related SubscriptionProductCharge records
    	// and populate the QuoteRatePlanCharge record's SalesRep, RenewalRep, and RSD Id fields using the values from the SubscriptionProductCharge
    	if (!qrpcUpdateMap.isEmpty()) {
    		List<Zuora__SubscriptionProductCharge__c> spcList = [SELECT Id, Zuora__RatePlanId__c, SalesRepID__c, RenewalRepID__c, RSD_Id__c FROM Zuora__SubscriptionProductCharge__c WHERE Zuora__RatePlanId__c IN :qrpcUpdateMap.keySet()];
    		if (!spcList.isEmpty()) {
    			for (Zuora__SubscriptionProductCharge__c spcRec : spcList) {
    				zqu__QuoteRatePlanCharge__c updateQRPC = qrpcUpdateMap.remove(spcRec.Zuora__RatePlanId__c);
    				updateQRPC.SalesRepId__c = spcRec.SalesRepID__c;
    				updateQRPC.RenewalRepId__c = spcRec.RenewalRepID__c;
    				updateQRPC.RSD_Id__c = spcRec.RSD_Id__c;
    			}
    			// at the end, check to see if any qrpc records remain in "update" map, and if so, add them to the "new" list for processing
    			if (!qrpcUpdateMap.isEmpty()) {
    				for (zqu__QuoteRatePlanCharge__c extraQRPCRecord : qrpcUpdateMap.values()) {
    					qrpcNewList.add(extraQRPCRecord);
    				}
    			}
    		}
    		// if query doesn't return any SubscriptionProductCharge records, add all "update" QuoteRatePlanCharge records to the "new" map for processing
    		else {
    			qrpcNewList.addAll(qrpcUpdateMap.values());
    		}
    	}
        
        // for all new QuoteRatePlanCharges, populate the QuoteRatePlanCharge record's SalesRep, RenewalRep, and RSD Id fields using the values from the Quote
        if (!qrpcNewList.isEmpty()) {
            for (zqu__QuoteRatePlanCharge__c newQRPC : qrpcNewList) {
            	zqu__QuoteRatePlan__c tempQRP = qrpMap.get(newQRPC.zqu__QuoteRatePlan__c);
                newQRPC.SalesRepId__c = tempQRP.zqu__Quote__r.SalesRepId__c;
                newQRPC.RenewalRepId__c = tempQRP.zqu__Quote__r.RenewalRepId__c;
                newQRPC.RSD_Id__c = tempQRP.zqu__Quote__r.RSD_Id__c;
            }
        }

    }


  
    /* 
    <method>
      <name>RecordZProductJobType</name>
      <purpose>When QuoteRatePlanCharge records are created (when a Quote amending an existing Quote is saved), 
      record the Job Type & product Type from Zproducts on each QuoteRatePlanCharge record</purpose>
      <created>
        <by>Vijay ram</by>
        <date>7/29/2015</date>
        <ticket>SF-583</ticket>
      </created>
    </method>
    */
  
      public static void RecordZProductJobType(List<zqu__QuoteRatePlanCharge__c> newList) {
       set<id> PRPCset=new set<id>();
            // Collecting Product plan Charges to Update Job type & Product type
        for (zqu__QuoteRatePlanCharge__c qrpc : newList) {
        if(qrpc.zqu__ProductRatePlanCharge__c!=null)
            PRPCset.add(qrpc.zqu__ProductRatePlanCharge__c);
        } 
        set<id> prpset=new set<id>();
        map<id,id> prpmap=new map<id,id>(); 
        for(zqu__ProductRatePlanCharge__c prp:[select id,zqu__ProductRatePlan__c from zqu__ProductRatePlanCharge__c  where  id in:PRPCset limit 5000]) 
        {
           if(prp.zqu__ProductRatePlan__c !=null){
            prpset.add(prp.zqu__ProductRatePlan__c );
            prpmap.put(prp.id,prp.zqu__ProductRatePlan__c);
            }
        }       
        Map<id,String> jobtypemap=new Map<id,String>();
        Map<id,String> producttypemap=new Map<id,String>();
        // CSP-2669: updating ZProduct references to Product2
        for(zqu__ProductRatePlan__c prc:[select id,zqu__Product__r.Job_Type__c,zqu__Product__r.ProductType__c from zqu__ProductRatePlan__c  where id in:prpset limit 50000])   // Collecting Job type and Product type 
        {
            jobtypemap.put(prc.id,prc.zqu__Product__r.Job_Type__c);
            producttypemap.put(prc.id,prc.zqu__Product__r.ProductType__c);
        }
        Map<id,string> mainjobmap=new Map<id,string>();  //we are linking Job Type with product rate plan charge(we have relation ship with current object)
        
        
        Map<id,string> mainproductmap=new Map<id,string>();  //we are linking Product Type with product rate plan charge(we have relation ship with current object)
        for(id pid:prpmap.keyset())
        {
            if(prpmap.get(pid)!=null&&jobtypemap.get(prpmap.get(pid))!=null)
            {
              mainjobmap.put(pid,jobtypemap.get(prpmap.get(pid))); //getting job type using jobtypemap based on prpmap(product rate plan charge,product rate plan)
            }
            if(prpmap.get(pid)!=null&&producttypemap.get(prpmap.get(pid))!=null)
            {
              mainproductmap.put(pid,producttypemap.get(prpmap.get(pid))); //getting Product type using producttypemap based on prpmap(product rate plan charge,product rate plan)
            }
        }
        for (zqu__QuoteRatePlanCharge__c qrpc : newList)
        {
          if(qrpc.zqu__ProductRatePlanCharge__c!=null&&mainjobmap.get(qrpc.zqu__ProductRatePlanCharge__c)!=null)
          {
            qrpc.Job_Type__c=mainjobmap.get(qrpc.zqu__ProductRatePlanCharge__c);//updating jobtype based on product rate plan charge
          }
          if(qrpc.zqu__ProductRatePlanCharge__c!=null&&mainproductmap.get(qrpc.zqu__ProductRatePlanCharge__c)!=null)
          {
            qrpc.Product_Type__c=mainproductmap.get(qrpc.zqu__ProductRatePlanCharge__c);//updating Product Type based on product rate plan charge
          }

        } 
    
    }
 
    /* 
    <method>
      <name>UpdatePrintIssueIds</name>
      <purpose>When QuoteRatePlanCharge records are created (when a Quote amending an existing Quote is saved), 
      record the Print Issue id</purpose>
      <created>
        <by>Steve O'Neal</by>
        <date>8/3/2015</date>
        <ticket>SF-587</ticket>
      </created>
    </method>
    */
    public static void UpdatePrintIssueIds(List<zqu__QuoteRatePlanCharge__c> newList) {
        for (zqu__QuoteRatePlanCharge__c qrpc : newList) {
            try
            {
                if (qrpc.Print_Issue__c == null)
                {
                    qrpc.Print_Issue_Id__c = null;
                }
                else
                {
                    qrpc.Print_Issue_Id__c = String.ValueOf(qrpc.Print_Issue__c);
                }
            }
            catch (Exception e) 
            {
                qrpc.Print_Issue_Id__c = null;
            }
        }
    }


    /* 
    <method>
      <name>RecordMarketIdAndCategoryTaxonomyId</name>
      <purpose>When QuoteRatePlanCharge records are created, if the associated ProductRatePlan has a Market and/or Category specified,
      we need to query to Market__c and Category__c records to record the Market ID and the Category Taxonomy ID on the QuoteRatePlanCharge.
      This is used both for fulfillment purposes and for Product Rules.</purpose>
      <created>
        <by>Jonathan Satterfield</by>
        <date>11/9/2015</date>
        <ticket>SF-1821</ticket>
      </created>
    </method>
    */
    public static void RecordMarketIdAndCategoryTaxonomyId(List<zqu__QuoteRatePlanCharge__c> newList) {
    	Set<Id> qrpIdSet = new Set<Id>();
        for (zqu__QuoteRatePlanCharge__c qrpc : newList) {
            qrpIdSet.add(qrpc.zqu__QuoteRatePlan__c);
        }

		Map<Id, zqu__QuoteRatePlan__c> qrpMap = new Map<Id, zqu__QuoteRatePlan__c>([SELECT Id, zqu__ProductRatePlan__r.Market__c, zqu__ProductRatePlan__r.Category__c FROM zqu__QuoteRatePlan__c WHERE zqu__AmendmentType__c != null AND Id IN :qrpIdSet]);

    	Map<String, List<zqu__QuoteRatePlanCharge__c>> marketNameToQRPCMap = new Map<String, List<zqu__QuoteRatePlanCharge__c>>();
    	Map<String, List<zqu__QuoteRatePlanCharge__c>> categoryNameToQRPCMap = new Map<String, List<zqu__QuoteRatePlanCharge__c>>();

    	// populate the marketNameToQRPCMap and the categoryNameToQRPCMap
    	if (!qrpMap.isEmpty()) {
			for (zqu__QuoteRatePlanCharge__c qrpcRec : newList) {
				if (qrpMap.containsKey(qrpcRec.zqu__QuoteRatePlan__c)) {

					zqu__QuoteRatePlan__c parentQRP = qrpMap.get(qrpcRec.zqu__QuoteRatePlan__c);

					// populate marketNameToQRPCMap
					if (!String.isBlank(parentQRP.zqu__ProductRatePlan__r.Market__c)) {
						// if map contains key, get and update list
						if (marketNameToQRPCMap.containsKey(parentQRP.zqu__ProductRatePlan__r.Market__c)) {
							List<zqu__QuoteRatePlanCharge__c> tempQRPCListForMarket = marketNameToQRPCMap.get(parentQRP.zqu__ProductRatePlan__r.Market__c);
							tempQRPCListForMarket.add(qrpcRec);
							marketNameToQRPCMap.put(parentQRP.zqu__ProductRatePlan__r.Market__c, tempQRPCListForMarket);
						}
						// otherwise create new list and add to map
						else {
							List<zqu__QuoteRatePlanCharge__c> newQRPCListForMarket = new List<zqu__QuoteRatePlanCharge__c>();
							newQRPCListForMarket.add(qrpcRec);
							marketNameToQRPCMap.put(parentQRP.zqu__ProductRatePlan__r.Market__c, newQRPCListForMarket);
						}
					}

					// populate categoryNameToQRPCMap
					if (!String.isBlank(parentQRP.zqu__ProductRatePlan__r.Category__c)) {
						// if map contains key, get and update list
						if (categoryNameToQRPCMap.containsKey(parentQRP.zqu__ProductRatePlan__r.Category__c)) {
							List<zqu__QuoteRatePlanCharge__c> tempQRPCListForCategory = categoryNameToQRPCMap.get(parentQRP.zqu__ProductRatePlan__r.Category__c);
							tempQRPCListForCategory.add(qrpcRec);
							categoryNameToQRPCMap.put(parentQRP.zqu__ProductRatePlan__r.Category__c, tempQRPCListForCategory);
						}
						// otherwise create new list and add to map
						else {
							List<zqu__QuoteRatePlanCharge__c> newQRPCListForCategory = new List<zqu__QuoteRatePlanCharge__c>();
							newQRPCListForCategory.add(qrpcRec);
							categoryNameToQRPCMap.put(parentQRP.zqu__ProductRatePlan__r.Category__c, newQRPCListForCategory);
						}
					}
				}
			}
		}
        system.debug('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'+marketNameToQRPCMap);

    	// initialize empty lists for Market__c and Category__c
    	List<Market__c> marketList = new List<Market__c>();
    	List<Category__c> categoryList = new List<Category__c>();

    	// TODO: confirm "Short_Description__c" is the correct field to compare Market and Category names
    	if (!marketNameToQRPCMap.isEmpty()) {
    		marketList = [SELECT Id, Short_Description__c, Market_ID__c FROM Market__c WHERE Zuora_Description__c IN :marketNameToQRPCMap.keySet()];
    	}
        system.debug('mmmmmmmmmmmmmmmmmmm'+marketList);
    	if (!categoryNameToQRPCMap.isEmpty()) {
    		categoryList = [SELECT Id, Short_Description__c, Taxonomy_ID__c FROM Category__c WHERE Zuora_Description__c IN :categoryNameToQRPCMap.keySet()];
		}
        system.debug('cccccccccccccccccccc'+categoryList);
		// record the applicable Market ID on each QuoteRatePlanCharge
    	if (!marketList.isEmpty()) {
    		for (Market__c market : marketList) {
				for (zqu__QuoteRatePlanCharge__c qrpcMarketRecord : marketNameToQRPCMap.get(market.Short_Description__c)) {
					qrpcMarketRecord.Market_ID__c = market.Market_ID__c;
				}
    		}
    	}

    	// record the applicable Category Taxonomy ID on each QuoteRatePlanCharge
    	if (!categoryList.isEmpty()) {
    		for (Category__c category : categoryList) {
				for (zqu__QuoteRatePlanCharge__c qrpcCategoryRecord : categoryNameToQRPCMap.get(category.Short_Description__c)) {
					qrpcCategoryRecord.Category_Taxonomy_ID__c = category.Taxonomy_ID__c;
				}
    		}
    	}

	}

	/**
	 *   CSP-996, CSP-1397 | if Billing Period isn't equal to Month, set the Billing Period Alignment to Align to Subscription Start
	 *   CSP-1822 | only set Billing Period Alignment for new products (don't set on Update Amendments)
	 *
	 *   @author Jonathan Satterfield
	 *   @date   2016-06-21
	 *   @param  {zqu__QuoteRatePlanCharge__c}   newRecord 
	 */
	public static void SetBillingPeriodAlignment(zqu__QuoteRatePlanCharge__c newRecord) {
		newRecord.zqu__BillingPeriodAlignment__c = newRecord.Preferred_Payment_Schedule__c != 'Month' && newRecord.zqu__Period__c != 'Month' && newRecord.Quote_Rate_Plan_Amendment_Type__c == 'NewProduct' ? 'AlignToSubscriptionStart' : '';
	}

	/**
	 *   CSP-1869 | before new zqu__QuoteRatePlanCharge__c records are inserted set the
	 *   "Is_Possible_Renewal__c" custom picklist to 'Yes' if the Opportunity Type is 'Renewal'
	 *
	 *   @author Jonathan Satterfield
	 *   @date   2017-01-31
	 *   @param  {List<zqu__QuoteRatePlanCharge__c>}
	 */
	public static void setIsPossibleRenewalPicklistValue(List<zqu__QuoteRatePlanCharge__c> newList) {

		Map<Id, List<zqu__QuoteRatePlanCharge__c>> qrpIdToQRPCListMap = new Map<Id, List<zqu__QuoteRatePlanCharge__c>>();

		// populate qrpIdToQRPCListMap
		for (Integer i = 0; i < newList.size(); i++) {
			zqu__QuoteRatePlanCharge__c qrpcRecord = newList[i];
			if (qrpcRecord.zqu__QuoteRatePlan__c == null) {
				continue;
			}
			List<zqu__QuoteRatePlanCharge__c> qrpcList = qrpIdToQRPCListMap.containsKey(qrpcRecord.zqu__QuoteRatePlan__c) ? qrpIdToQRPCListMap.get(qrpcRecord.zqu__QuoteRatePlan__c) : new List<zqu__QuoteRatePlanCharge__c>();
			qrpcList.add(qrpcRecord);
			qrpIdToQRPCListMap.put(qrpcRecord.zqu__QuoteRatePlan__c, qrpcList);
		}

		// if qrpIdToQRPCListMap is empty there's no need to execute the rest of the code
		if (qrpIdToQRPCListMap.isEmpty()) {
			return;
		}

		for (zqu__QuoteRatePlan__c qrpRecord : [SELECT Id, zqu__Quote__r.zqu__Opportunity__r.Type FROM zqu__QuoteRatePlan__c WHERE Id IN :qrpIdToQRPCListMap.keySet()]) {
			if (!qrpIdToQRPCListMap.containsKey(qrpRecord.Id)) {
				continue;
			}
			for (zqu__QuoteRatePlanCharge__c qrpcRecord : qrpIdToQRPCListMap.remove(qrpRecord.Id)) {
				qrpcRecord.Is_Possible_Renewal__c = qrpRecord.zqu__Quote__r.zqu__Opportunity__r.Type == 'Renewal' ? 'Yes' : 'No'; 
			}
		}
	}

}