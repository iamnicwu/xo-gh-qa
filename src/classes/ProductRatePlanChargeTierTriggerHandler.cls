public with sharing class ProductRatePlanChargeTierTriggerHandler implements XOTrigger {
	// Used to determine if a batch job needs to be fired off immediately
	private Boolean updateProductsNow = false;

	public void bulkBefore() {

	}

	public void bulkAfter(){

	}

	public void beforeInsert(SObject so){

	}

	public void beforeUpdate(SObject oldSo, SObject so) {
		zqu__ProductRatePlanChargeTier__c oldRecord = (zqu__ProductRatePlanChargeTier__c)oldSo;
		zqu__ProductRatePlanChargeTier__c currentRecord = (zqu__ProductRatePlanChargeTier__c)so;
		
		////////////////////////////////
		// PRICE UPDATE DETERMINATION //
		////////////////////////////////
		if(currentRecord.zqu__Price__c != oldRecord.zqu__Price__c) {
			currentRecord.Zuora_Update_Pending__c = true;
		}

		/////////////////////////////
		// ZUORA UPDATE NEEDED NOW //
		/////////////////////////////
		if(currentRecord.Update_Zuora_Immediately__c) {
			currentRecord.Update_Zuora_Immediately__c = false;

			if(!updateProductsNow && currentRecord.Zuora_Update_Pending__c) {
				updateProductsNow = true;
			}
		}
	}

	public void beforeDelete(SObject so) {

	}

	public void afterInsert(SObject so) {

	}

	public void afterUpdate(SObject oldSo, SObject so) {
		zqu__ProductRatePlanChargeTier__c oldRecord = (zqu__ProductRatePlanChargeTier__c)oldSo;
		zqu__ProductRatePlanChargeTier__c currentRecord = (zqu__ProductRatePlanChargeTier__c)so;

	}

	public void afterDelete(SObject so) {

	}

	public void beforeAndFinally() {
		if(updateProductsNow) {
			Database.executeBatch(new BatchProductRatePlanChargeTier());
		}
	}

	public void afterAndFinally() {
		
	}
}