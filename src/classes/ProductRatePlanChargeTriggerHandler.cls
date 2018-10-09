public without sharing class ProductRatePlanChargeTriggerHandler implements XOTrigger {

	Map<Id, zqu__ProductRatePlan__c> productRatePlanMap;

	public ProductRatePlanChargeTriggerHandler() {

	}

	public void bulkBefore() {
		// querying data from parent zqu__ParentRatePlan__c records
		Set<Id> productRatePlanIdSet = new Set<Id>();
		for (SObject so : Trigger.new) {
			zqu__ProductRatePlanCharge__c record = (zqu__ProductRatePlanCharge__c)so;
			productRatePlanIdSet.add(record.zqu__ProductRatePlan__c);
		}
		productRatePlanMap = new Map<Id, zqu__ProductRatePlan__c>([SELECT Id, Product_Line__c FROM zqu__ProductRatePlan__c WHERE Id IN :productRatePlanIdSet]);
	}

	public void bulkAfter() {

	}   
	
	public void beforeInsert(SObject so) {
		zqu__ProductRatePlanCharge__c record = (zqu__ProductRatePlanCharge__c)so;
		setPrintUpToHowManyPeriodsDefaultValue(record, productRatePlanMap);
	}
 
	public void beforeUpdate(SObject oldSo, SObject so) {
		zqu__ProductRatePlanCharge__c record = (zqu__ProductRatePlanCharge__c)so;
		setPrintUpToHowManyPeriodsDefaultValue(record, productRatePlanMap);
	}
	
	public void beforeDelete(SObject so) {

	}

	public void afterandfinally() {

	}

	public void beforeandfinally() {

	}
 
	public void afterInsert(SObject so) {

	}
	
	public void afterUpdate(SObject oldSo, SObject so) {

	}
 
	public void afterDelete(SObject so) {

	}   
	
	public void andFinally() {

	}

	/**
	 *   CSP-1353 | For Print zqu__ProductRatePlanCharge__c records, if no value is provided in the zqu__Upto_How_Many_Periods__c field
	 *   set the default value to 6. The problem is that the logic that calculates the price of non-monthly Print charges (a.k.a. the 
	 *   ZuoraQuoteChooseNextActionController.RecalculateQuoteCharges method) is expecting a value in the Product Rate Plan Charge's "Up To How Many Periods" 
	 *   field (API name: zqu_Upto_How_Many_Periods_c). Oddly enough, the value in the field doesn't seem to matter so much as long as it isn't null, 
	 *   although the other Print Product Rate Plan Charges all have 6 as the value.
	 *
	 *   @author Jonathan Satterfield
	 *   @date   2016-08-24
	 *   @param  {zqu__ProductRatePlanCharge__c}   record
	 */
	public static void setPrintUpToHowManyPeriodsDefaultValue(zqu__ProductRatePlanCharge__c record, Map<Id, zqu__ProductRatePlan__c> productRatePlanMap) {
		if (productRatePlanMap.containsKey(record.zqu__ProductRatePlan__c)) {
			zqu__ProductRatePlan__c prp = productRatePlanMap.get(record.zqu__ProductRatePlan__c);
			if (prp.Product_Line__c == 'Print' && record.zqu__Upto_How_Many_Periods__c == null) {
				record.zqu__Upto_How_Many_Periods__c = 6;
			}
		}
	}
}