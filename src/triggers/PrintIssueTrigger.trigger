trigger PrintIssueTrigger on Print_Issue__c (before insert, before update) {

	if (trigger.isBefore && (trigger.isInsert || trigger.isUpdate))
	{
		// set empty dates automatically
		PrintIssueTriggerHandler.SetDateDefaults(trigger.new);
		
		// set naming convention
		PrintIssueTriggerHandler.SetNamingConvention(trigger.new);
	}
}