trigger EditionTrigger on Edition__c (before insert, before update) {

	if (trigger.isBefore && (trigger.isInsert || trigger.isUpdate))
	{
		// set naming convention
		EditionTriggerHandler.SetNamingConvention(trigger.new);
	}

}