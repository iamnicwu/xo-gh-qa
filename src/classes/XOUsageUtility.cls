public without sharing class XOUsageUtility {
	
	public static Boolean createUsage(String source, String initiatedFrom, String actionPerformed, String additionalInfo) {
		XO_Usage__c newUsage = new XO_Usage__c();
		newUsage.Name = (Datetime.now() + ' ' + source + '.' + initiatedFrom).left(80);
		newUsage.Source__c = source;
		newUsage.Initiated_From__c = initiatedFrom;
		newUsage.Action_Performed__c = actionPerformed;
		newUsage.Additional_Information__c = additionalInfo;

		Database.SaveResult insertResult = Database.insert(newUsage, false);
		System.debug('HERE IT IS: ' + newUsage.Id);
		if(insertResult.isSuccess()) {
			return true;
		}

		ExceptionUtility.consumeException(insertResult, true);
		return false;
	}
}