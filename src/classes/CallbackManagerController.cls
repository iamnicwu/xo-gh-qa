public with sharing class CallbackManagerController {
	//////////////////////
	// STATIC VARIABLES //
	//////////////////////

	// Callback Query
	private static final String CALLBACK_RECORD_QUERY = 'SELECT '
		+	'Id, '
		+	'Name, '
		+	'Account__c, '
		+	'Account__r.Name, '
		+	'Vendor_Contact__c, '
		+	'Vendor_Contact__r.Name, '
		+	'Vendor_Phone__c, '
		+	'Vendor_Email__c, '
		+	'Subscription_Name__c, '
		+	'Subscription_Product_Charge__c, '
		+	'Subscription_Product_Charge__r.Zuora__Subscription__c, '
		+	'Subscription_Product_Charge__r.Product_Type__c, ' 
		+	'Subscription_Product_Charge__r.LDE_Email_Launch_Date__c, '
		+	'Subscription_Product_Charge__r.Zuora__Subscription__r.Zuora__TermStartDate__c, '
		+	'Callback_Date__c, ' 
		+	'Owner.Name, '
		+	'OwnerId, '
		+	'VIP_Account__c, '
		+	'Status__c, '
		+	'Is_Possible_Renewal__c '
		+	'FROM '
		+	'Callback__c '
		+	'{WHERECLAUSE}'
		+	' ORDER BY '
		+	'{ORDERSTATEMENT}'
		+	'LIMIT :pageSize '
		+	'OFFSET :offset';


	// Callback Count Query
	private static final String CALLBACK_COUNT_QUERY = 'SELECT '
		+	'COUNT() '
		+	'FROM '
		+	'Callback__c '
		+	'{WHERECLAUSE}';


	private static String setQueryStringWhereClause(String queryStringBase, String whereClause) {
		String queryString = queryStringBase;
		return queryString.replace('{WHERECLAUSE}', whereClause);
	}


	private static String setQueryStringOrderStatement(String queryStringBase, String orderStatement) {
		String queryString = queryStringBase;
		return queryString.replace('{ORDERSTATEMENT}', orderStatement);
	}


	@AuraEnabled
	public static CallbackPagedResult getCallbacks(Decimal pageNumber, String ownerFilter, String typeFilter, 
													String statusFilter, String marketFilter, String categoryFilter, 
													String accountVIPStatusFilter, String orderStatement, String accountNameFilter,
													String subscriptionNumberFilter, String startingDateRangeFilter, String endingDateRangeFilter,
													String possibleRenewalFilter) {

		Integer pageSize = 25;
		Integer offset = ((Integer)pageNumber - 1) * pageSize;
		CallbackPagedResult cpr = new CallbackPagedResult();

		// build out query strings
		List<String> callbackQueryWhereClauseList = new List<String>();
		String callbackQueryWhereClause = '';
		if (!ownerFilter.equalsIgnoreCase('all')) {
			if (ownerFilter.equalsIgnoreCase('mine')) {
				callbackQueryWhereClauseList.add('OwnerId = \'' + (String)userInfo.getUserId() + '\'');
			}
			else {
				callbackQueryWhereClauseList.add('Owner.Name = \'' + ownerFilter + '\'');
			}
		}
		if (!typeFilter.equalsIgnoreCase('all')) {
			callbackQueryWhereClauseList.add('Subscription_Product_Charge__r.Product_Type__c = \'' + typeFilter + '\'');
		}
		if (!statusFilter.equalsIgnoreCase('all')) {
			if (statusFilter.equalsIgnoreCase('all open')) {
				callbackQueryWhereClauseList.add('Status__c NOT IN (\'Cancelled\', \'Complete\')');
			}
			else {
				callbackQueryWhereClauseList.add('Status__c = \'' + statusFilter + '\'');
			}
		}
		if (!marketFilter.equalsIgnoreCase('all')) {
			callbackQueryWhereClauseList.add('Market__r.Short_Description__c = \'' + marketFilter + '\'');
		}
		if (!categoryFilter.equalsIgnoreCase('all')) {
			callbackQueryWhereClauseList.add('Category__r.Name = \'' + categoryFilter + '\'');
		}
		if (!accountVIPStatusFilter.equalsIgnoreCase('all')) {
			String isVIPAccount = accountVIPStatusFilter.equalsIgnoreCase('Not VIP') ? 'false' : 'true';
			callbackQueryWhereClauseList.add('VIP_Account__c = ' + isVIPAccount);
		}
		if (String.isNotBlank(accountNameFilter)) {
			callbackQueryWhereClauseList.add('Account__r.Name LIKE \'%' + accountNameFilter + '%\'');
		}
		if (String.isNotBlank(subscriptionNumberFilter)) {
			callbackQueryWhereClauseList.add('Subscription_Name__c = \'' + subscriptionNumberFilter + '\'');
		}
		if (String.isNotBlank(startingDateRangeFilter)) {
			callbackQueryWhereClauseList.add('Callback_Date__c >= ' + startingDateRangeFilter);
		}
		if (String.isNotBlank(endingDateRangeFilter)) {
			callbackQueryWhereClauseList.add('Callback_Date__c <= ' + endingDateRangeFilter);
		}
		if (!possibleRenewalFilter.equalsIgnoreCase('all')) {
			callbackQueryWhereClauseList.add('Is_Possible_Renewal__c = \'' + possibleRenewalFilter + '\'');
		}
		for (Integer i = 0; i < callbackQueryWhereClauseList.size(); i++) {
			if (i == 0) {
				callbackQueryWhereClause += 'WHERE ';
			}
			else {
				callbackQueryWhereClause += ' AND ';				
			}
			callbackQueryWhereClause += callbackQueryWhereClauseList[i];
		}

		// set the where clause and the order statement
		String callbackQueryString = setQueryStringWhereClause(CALLBACK_RECORD_QUERY, callbackQueryWhereClause);
		callbackQueryString = setQueryStringOrderStatement(callbackQueryString, orderStatement);

		// record query
		cpr.callbacks = Database.query(callbackQueryString);
		// count query
		cpr.recordCount = Database.countQuery(setQueryStringWhereClause(CALLBACK_COUNT_QUERY, callbackQueryWhereClause));
		cpr.page = (Integer)pageNumber;
		return cpr;
	}

	@AuraEnabled
	public static List<String> getStatusPicklistValues() {
		List<String> statusPicklistValues = new List<String>();
		Schema.DescribeFieldResult fieldResult = Callback__c.Status__c.getDescribe();
		for (Schema.PicklistEntry picklistEntry : fieldResult.getPicklistValues()) {
			//System.debug('Field Value ' + f.getValue());
			statusPicklistValues.add(picklistEntry.getLabel());
		}
		statusPicklistValues.sort();
		return statusPicklistValues;
	}

	@AuraEnabled
	public static List<String> getMarketPicklistValues() {
		List<String> marketPicklistValues = new List<String>();
		for (Market__c marketRecord : [SELECT Short_Description__c FROM Market__c ORDER BY Short_Description__c ASC]) {
			if (String.isNotBlank(marketRecord.Short_Description__c)) {
				marketPicklistValues.add(marketRecord.Short_Description__c);
			}
		}
		return marketPicklistValues;
	}

	@AuraEnabled
	public static List<String> getCategoryPicklistValues() {
		List<String> categoryPicklistValues = new List<String>();
		for (Category__c categoryRecord : [SELECT Name FROM Category__c ORDER BY Name ASC]) {
			categoryPicklistValues.add(categoryRecord.Name);
		}
		return categoryPicklistValues;
	}	

	@AuraEnabled
	public static Boolean updateCallbackStatus(Id callbackRecordId, String callbackStatus) {
		List<Callback__c> callbackRecordList = [SELECT Id, Status__c FROM Callback__c WHERE Id = :callbackRecordId LIMIT 1];
		if (callbackRecordList.isEmpty()) {
			return false;
		}
		callbackRecordList[0].Status__c = callbackStatus;
		try {
			update callbackRecordList;
		}
		catch (Exception e) {
			ExceptionUtility.consumeException(e, true);
			return false;
		}
		return true;
	}

	@AuraEnabled
	public static List<User> getOwnerPicklistValues() {
		Set<Id> callbackOwnerIdSet = new Set<Id>();
		Set<String> excludedCallbackStatusValuesSet = new Set<String>{'Complete', 'Cancelled'};
		for (Callback__c callbackRecord : [SELECT OwnerId FROM Callback__c WHERE Status__c NOT IN :excludedCallbackStatusValuesSet]) {
			callbackOwnerIdSet.add(callbackRecord.OwnerId);
		}
		List<User> userList = [SELECT Id, Name FROM User WHERE (Profile.Name = 'Local Core Strategy Specialist' AND IsActive = true) OR Id IN :callbackOwnerIdSet ORDER BY Name];
		return userList;
	}

	@AuraEnabled
	public static List<String> getStrategySpecialistPicklistValues() {
		List<String> strategySpecialistNameList = new List<String>();
		// not filtering by User.IsActive here because they may use this tool to reassign Callback owners
		for (User strategySpecialist : [SELECT Name FROM User WHERE Profile.Name = 'Local Core Strategy Specialist' ORDER BY Name]) {
			strategySpecialistNameList.add(strategySpecialist.Name);
		}
		return strategySpecialistNameList;
	}

	@AuraEnabled
	public static Boolean updateCallbackOwner(Id callbackRecordId, Id callbackOwnerId) {
		List<Callback__c> callbackRecordList = [SELECT Id, OwnerId FROM Callback__c WHERE Id = :callbackRecordId LIMIT 1];
		if (callbackRecordList.isEmpty()) {
			return false;
		}
		callbackRecordList[0].OwnerId = callbackOwnerId;
		try {
			update callbackRecordList;
		}
		catch (Exception e) {
			ExceptionUtility.consumeException(e, true);
			return false;
		}
		return true;
	}

	@AuraEnabled
	public static Boolean updateCallbackDate(Id callbackRecordId, String callbackDate, Map<String, String> browserDetails) {
		List<Callback__c> callbackRecordList = [SELECT Id, Callback_Date__c FROM Callback__c WHERE Id = :callbackRecordId LIMIT 1];
		if (callbackRecordList.isEmpty()) {
			return false;
		}
		try {
			callbackRecordList[0].Callback_Date__c = Date.valueOf(callbackDate);
			update callbackRecordList;
		}
		catch (Exception e) {
			XO_Exception__c dateUpdateException = ExceptionUtility.consumeException(e, false);
			dateUpdateException.Message__c += ' | Browser Details: ' + JSON.serialize(browserDetails);
			insert dateUpdateException;
			return false;
		}
		return true;
	}		

	@AuraEnabled
	public static List<Zuora__SubscriptionProductCharge__c> getSubscriptionDetails(Id callbackRecordId) {
		List<Zuora__SubscriptionProductCharge__c> spcRecords = new List<Zuora__SubscriptionProductCharge__c>();
		List<Callback__c> callbackRecordList = [SELECT Subscription_Product_Charge__r.Zuora__Subscription__c FROM Callback__c WHERE Id = :callbackRecordId LIMIT 1];
		if (callbackRecordList.isEmpty()) {
			return spcRecords;
		}	
		Callback__c callbackRecord = callbackRecordList[0];
		spcRecords = [SELECT Zuora__Subscription__r.Zuora__TermStartDate__c, Zuora__Subscription__r.Zuora__TermEndDate__c, Zuora__RatePlanName__c FROM Zuora__SubscriptionProductCharge__c WHERE Zuora__Subscription__c = :callbackRecord.Subscription_Product_Charge__r.Zuora__Subscription__c];
		return spcRecords;
	}	

	@AuraEnabled
	public static List<Note> getCallbackNotes(Id callbackRecordId) {
		return [SELECT Body, CreatedBy.Name, CreatedDate FROM Note WHERE ParentId = :callbackRecordId ORDER BY CreatedDate ASC];
	}

	@AuraEnabled
	public static Note createCallbackNote(Id callbackRecordId, String body) {
		Note callbackNote = new Note();
		callbackNote.ParentId = callbackRecordId;
		callbackNote.Body = body;
		callbackNote.Title = 'Callback Note: ' + String.valueOf(Date.today());
		try {
			insert callbackNote;
			callbackNote = [SELECT Body, CreatedBy.Name, CreatedDate FROM Note WHERE Id = :callbackNote.Id LIMIT 1];
		}
		catch (Exception e) {
			ExceptionUtility.consumeException(e, true);
			return null;
		}
		return callbackNote;
	}
}