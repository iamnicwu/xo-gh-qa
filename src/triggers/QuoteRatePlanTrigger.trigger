/* 
<trigger>
  <name>QuoteRatePlan</name>
  <purpose>To copy down the required values on Quote Rate Plan to Quote Rate Plan Charge</purpose>
  <Created>
    <by>Om Vankayalapati</by>
    <date>11/15/2015</date>
    <ticket>SF-1852</ticket>
  </created>
</trigger>
*/

trigger QuoteRatePlanTrigger on zqu__QuoteRatePlan__c (After Update, Before Insert) {

	if (Trigger.isAfter && Trigger.isUpdate) {

		//List for Quote Rate Plans
		List<Id> qrpIdList = new List<Id>();
		string strQRPIdList = '';
	    string comma = '';
		
		// Map for Quote Rate Plan charges
		Map<Id,List<zqu__QuoteRatePlanCharge__c>> qrpcMap = new Map<Id,List<zqu__QuoteRatePlanCharge__c>>();
		
		// Update list all the values on QRPC from QRP
		List<zqu__QuoteRatePlanCharge__c> qrpcUpdateList = new List<zqu__QuoteRatePlanCharge__c>();
		
		for(zqu__QuoteRatePlan__c qrp : trigger.new){
		    qrpIdList.add(qrp.Id);
		    strQRPIdList += comma + '\'' + String.Valueof(qrp.Id).Left(15) + '\'';
		    comma = ',';
		}
		
		// get the rate plan charges from the db to copy values down
	    Map<String, String> fieldMap = new Map<String, String>();
	    fieldMap.put('ID', null);
	    fieldMap.put('Name', null);
	    fieldMap.put('zqu__QuoteRatePlan__c', null);
	    fieldMap.put('zqu__Discount__c', null);
	    for(Schema.FieldSetMember fldqrp : SObjectType.zqu__QuoteRatePlan__c.FieldSets.QRPC_To_QRP_Fieldset.getFields()) 
	    {
	    	fieldMap.put(fldqrp.getFieldPath(), null);
	    }
	    
	    comma = '';
	    string QRPC_query = 'SELECT ';
	    for (String f : fieldMap.keyset())
	    {
	    	QRPC_query += comma + f;
	    	comma = ', ';
	    }
		
		QRPC_query += ' from zqu__QuoteRatePlanCharge__c where zqu__QuoteRatePlan__c in (' + strQRPIdList + ') order by Product_Type__c asc';
		
		for(zqu__QuoteRatePlanCharge__c qrpc : Database.Query(QRPC_query)){
			if (!qrpcMap.containsKey(qrpc.zqu__QuoteRatePlan__c))
			{
				List<zqu__QuoteRatePlanCharge__c> qrpcList = new List<zqu__QuoteRatePlanCharge__c>();
				qrpcMap.put(qrpc.zqu__QuoteRatePlan__c,qrpcList);
			}
		    qrpcMap.get(qrpc.zqu__QuoteRatePlan__c).add(qrpc);
		}
		
		for(zqu__QuoteRatePlan__c qrp : trigger.new){
			List<zqu__QuoteRatePlanCharge__c> qrpcList = qrpcMap.get(qrp.Id);
			
			if (qrpcList != null && !qrpcList.isEmpty()) {
				for (zqu__QuoteRatePlanCharge__c qrpc : qrpcList)
				{
			        for(Schema.FieldSetMember fldqrp : SObjectType.zqu__QuoteRatePlan__c.FieldSets.QRPC_To_QRP_Fieldset.getFields()) 
			        {
			        	System.Debug('Adding field:' + fldqrp.getFieldPath() + ' value: ' + qrp.get(fldqrp.getFieldPath()) + ' qrpc ID:' + qrpc.Id);
			        	qrpc.put(fldqrp.getFieldPath(), qrp.get(fldqrp.getFieldPath()));
			        }
			        // there's one wierdo that we can't do dynamically, because one of the fields is custom and the other is managed, thus it has a different namespace
			        if (qrp.Discount_Override__c != null)
			        {
				        qrpc.zqu__Discount__c = qrp.Discount_Override__c;
			        }
				    qrpcUpdateList.add(qrpc);
				}
			}
		}

		if (!qrpcUpdateList.isEmpty()) {
			update qrpcUpdateList;
		}
	}


	if (Trigger.isBefore) {
		Set<Id> quoteIdSet = new Set<Id>();

		for(Integer i = 0; i < Trigger.new.size(); i++) {
			zqu__QuoteRatePlan__c currentQRP = Trigger.new[i];

			if(String.isNotBlank(currentQRP.zqu__Quote__c)) {
				quoteIdSet.add(currentQRP.zqu__Quote__c);
			}
		}

		//Map<Id, zqu__Quote__c> quoteMap = new Map<Id, zqu__Quote__c>([SELECT Id, Name, zqu__Account__c FROM zqu__Quote__c WHERE Id IN :quoteIdSet]);

		if(Trigger.isInsert) {
			QuoteRatePlanTriggerHandler.PopulateVendorLocationAccountDuringInternetAmendment(Trigger.new);
		}
		/* Commented By Shashish on 27th july, 2017, CSP-1009
			for(Integer i = 0; i < Trigger.new.size(); i++) {
				zqu__QuoteRatePlan__c currentQRP = Trigger.new[i];
				if(String.isNotBlank(currentQRP.zqu__Quote__c) && quoteMap.containsKey(currentQRP.zqu__Quote__c)) {
					zqu__Quote__c parentQuote = quoteMap.get(currentQRP.zqu__Quote__c);

					if(String.isBlank(currentQRP.Location_Vendor__c)) {
						currentQRP.Location_Vendor__c = parentQuote.zqu__Account__c;
					}
				}
			}
		} else if(Trigger.isUpdate) {
			for(Integer i = 0; i < Trigger.new.size(); i++) {
				zqu__QuoteRatePlan__c currentQRP = Trigger.new[i];
				if(String.isNotBlank(currentQRP.zqu__Quote__c) && quoteMap.containsKey(currentQRP.zqu__Quote__c)) {
					zqu__Quote__c parentQuote = quoteMap.get(currentQRP.zqu__Quote__c);

					if(String.isBlank(currentQRP.Location_Vendor__c)) {
						currentQRP.Location_Vendor__c = parentQuote.zqu__Account__c;
					}
				}
			}
		}*/
		
	}

}