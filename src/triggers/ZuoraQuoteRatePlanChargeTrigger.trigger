// NOTE: this trigger is currently inactive
trigger ZuoraQuoteRatePlanChargeTrigger on zqu__QuoteRatePlanCharge__c (before insert, before update, after insert, after update, before delete, after delete) {

	List<Integer> recordCountList = new List<Integer>();

	if (Trigger.isInsert || Trigger.isUpdate) {
        for (Integer i = 0; i < Trigger.new.size(); i++) {
        	recordCountList.add(i);
        }
    }
    else if (Trigger.isDelete) {
    	for (Integer i = 0; i < Trigger.old.size(); i++) {
    		recordCountList.add(i);
    	}
    }

	TriggerFactory.createAndExecuteHandler(ZuoraQuoteRatePlanChargeTriggerHandler.class, 'zqu__QuoteRatePlanCharge__c', recordCountList);
}