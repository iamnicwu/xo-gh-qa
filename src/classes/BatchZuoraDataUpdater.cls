global class BatchZuoraDataUpdater implements Database.Batchable<sObject>, Database.AllowsCallouts {

	private static final String ZCA_COUNT_QUERY = 'SELECT '
		+   'COUNT() '
		+	'FROM '
		+	'Zuora__CustomerAccount__c '
		+   'WHERE '
		+   '(ZDU_RetrieveSoldToContact__c = true AND (ZDU_RetrieveSoldToContactFailureCount__c = null OR ZDU_RetrieveSoldToContactFailureCount__c < 3)) '
		+   'OR '
		+   '(ZDU_UpdateAccount__c = true AND (ZDU_UpdateAccountFailureCount__c = null OR ZDU_UpdateAccountFailureCount__c < 3)) '
		+   'OR '
		+   '(ZDU_UpdateContacts__c = true AND (ZDU_UpdateContactsFailureCount__c = null OR ZDU_UpdateContactsFailureCount__c < 3))';

	private static final String ZCA_RECORD_QUERY = 'SELECT '
		+   'Id, '
		+   'CBSS_Email__c, '
		+   'CBSS_Phone__c, '
		+   'Name, '
		+   'NeedToUpdateCBSS__c, '
		+   'NeedToUpdateCreditHold__c, '
		+   'NeedToUpdateCustomerType__c, '
		+   'NeedToUpdateSoldToContact__c, '
		+   'SoldToAddress1__c, '
		+   'SoldToAddress2__c, '
		+   'SoldToCity__c, '
		+   'SoldToCountry__c, '
		+   'SoldToPostalCode__c, '
		+   'SoldToState__c, '
		+   'Zuora__Account__r.CBBS__r.Email, '
		+   'Zuora__Account__r.CBBS__r.Name, '
		+   'Zuora__Account__r.CBBS__r.Phone, '
		+   'Zuora__Account__r.CBBS__r.SalesRepID__c, '
		+   'Zuora__Account__r.CreditHold__c, '
		+   'Zuora__Account__r.Customer_Type__c, '
		+   'Zuora__BillToAddress1__c, '
		+   'Zuora__BillToAddress2__c, '
		+   'Zuora__BillToCity__c, '
		+   'Zuora__BillToCountry__c, '
		+   'Zuora__BillToId__c, '
		+   'Zuora__BillToName__c, '
		+   'Zuora__BillToPostalCode__c, '
		+   'Zuora__BillToState__c, '
		+   'Zuora__BillToWorkEmail__c, '
		+   'Zuora__BillToWorkPhone__c, '
		+   'Zuora__SalesRepName__c, '
		+   'Zuora__SoldToId__c, '
		+   'Zuora__SoldToName__c, '
		+   'Zuora__Zuora_Id__c, '
		+   'ZDU_RetrieveSoldToContact__c, '
		+   'ZDU_RetrieveSoldToContactFailureCount__c, '
		+   'ZDU_UpdateAccount__c, '
		+   'ZDU_UpdateAccountFailureCount__c, '
		+   'ZDU_UpdateContacts__c, '
		+   'ZDU_UpdateContactsFailureCount__c '
		+	'FROM '
		+	'Zuora__CustomerAccount__c '
		+   'WHERE '
		+   '(ZDU_RetrieveSoldToContact__c = true AND (ZDU_RetrieveSoldToContactFailureCount__c = null OR ZDU_RetrieveSoldToContactFailureCount__c < 3)) '
		+   'OR '
		+   '(ZDU_UpdateAccount__c = true AND (ZDU_UpdateAccountFailureCount__c = null OR ZDU_UpdateAccountFailureCount__c < 3)) '
		+   'OR '
		+   '(ZDU_UpdateContacts__c = true AND (ZDU_UpdateContactsFailureCount__c = null OR ZDU_UpdateContactsFailureCount__c < 3))';		

	private String query;
	
	global BatchZuoraDataUpdater() {
		this.query = ZCA_RECORD_QUERY;
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<Zuora__CustomerAccount__c> scope) {

		// first set trigger flag to prevent trigger update logic from running
		ZuoraBillingAccountTriggerHandler.batchZuoraDataUpdaterRunning = true;

		ZuoraDataUpdateWrapper dataWrapper = new ZuoraDataUpdateWrapper(scope);

		if (dataWrapper.retrieveSoldToContactIdSet.size() > 0) {
			dataWrapper = retrieveSoldToContacts(dataWrapper);
		}
		if (dataWrapper.updateAccountIdSet.size() > 0) {
			dataWrapper = updateZuoraAccounts(dataWrapper);
		}
		if (dataWrapper.updateContactsIdSet.size() > 0) {
			dataWrapper = updateZuoraContacts(dataWrapper);
		}

		// TODO: add exception logging? could be row locking issues from zuora sync
		Database.update(dataWrapper.zuoraCustomerAccountMap.values(), false);
	}
	
	global void finish(Database.BatchableContext BC) {
		Integer recordsToUpdateCount = Database.countQuery(ZCA_COUNT_QUERY);
		if (recordsToUpdateCount > 0) {
			Database.executebatch(new BatchZuoraDataUpdater());
		}
	}


	/**
	 *   CSP-1659 | "retrieveSoldToContacts" queries Zuora for Customer Account's "Sold To" Contact information
	 *   and populates those values on the related Zuora__CustomerAccount__c record in Salesforce. The Zuora
	 *   360 managed package already does this for the "Bill To" Contact information, so not sure why they
	 *   skipped the "Sold To" Contact info, but there you have it! This logic was originally implemented for
	 *   ticket SF-2177 back in February 2016.
	 *
	 *   @author Jonathan Satterfield
	 *   @date   2017-01-09
	 *   @param  {ZuoraDataUpdateWrapper}
	 *   @return {ZuoraDataUpdateWrapper}
	 */
	private static ZuoraDataUpdateWrapper retrieveSoldToContacts(ZuoraDataUpdateWrapper dataWrapper) {

		// populate list of all customer account records for which we need to retrieve Sold To Contact info
		List<Zuora__CustomerAccount__c> retrieveSoldToContactList = new List<Zuora__CustomerAccount__c>();
		for (Id customerAccountId : dataWrapper.retrieveSoldToContactIdSet) {
			if (!dataWrapper.zuoraCustomerAccountMap.containsKey(customerAccountId)) {
				continue;
			}
			retrieveSoldToContactList.add(dataWrapper.zuoraCustomerAccountMap.get(customerAccountId));
		}

		// NOTE: if we set batch size to <= 200 we don't need to do all this overhead, but adding here just in case.
		// Can only retrieve 200 records at a time, so break up the retrieveSoldToContactList into groups of 200
		// and add to "groupOf200RecordsList" list for processing.
		// Also, even though the groupOf200Records is being added to the groupOf200RecordsList before the Zuora__CustomerAccount__c
		// is added to the groupOf200Records, the Zuora__CustomerAccount__c is still added due to how referencing works
		// in Salesforce/Apex
		List<List<Zuora__CustomerAccount__c>> groupOf200RecordsList = new List<List<Zuora__CustomerAccount__c>>();
		List<Zuora__CustomerAccount__c> groupOf200Records;
		for (Integer i = 0; i < retrieveSoldToContactList.size(); i++) {
			if (Math.mod(i, 200) == 0) {
				groupOf200Records = new List<Zuora__CustomerAccount__c>();
				groupOf200RecordsList.add(groupOf200Records);
			}
			groupOf200Records.add(retrieveSoldToContactList[i]);
		}

		// main loop
		for (List<Zuora__CustomerAccount__c> customerAccountList : groupOf200RecordsList) {
			// map of ZuoraID to record
			Map<String, Zuora__CustomerAccount__c> zuoraSoldToContactIdToCustomerAccountMap = new Map<String, Zuora__CustomerAccount__c>();		
			// zoql query string
			String zoqlQueryString = 'SELECT Id, AccountId, Address1, Address2, City, Country, FirstName, LastName, State, PostalCode FROM Contact WHERE Id = ';

			// populate zoql query string
			Boolean firstRun = true;
			for (Zuora__CustomerAccount__c customerAccount : customerAccountList) {
				if (firstRun) {
					zoqlQueryString += ('\'' + customerAccount.Zuora__SoldToId__c + '\'');
					firstRun = false;
				}
				else {
					zoqlQueryString += (' OR Id = \'' + customerAccount.Zuora__SoldToId__c + '\'');
				}
				zuoraSoldToContactIdToCustomerAccountMap.put(customerAccount.Zuora__SoldToId__c, customerAccount);
			}

			// authenticate with zuora and perform query
			Zuora.ZApi zApiInstance;
			Zuora.zApi.LoginResult loginResult;
			List<Zuora.zObject> zuoraZObjectList = new List<Zuora.zObject>();

			if (!Test.isRunningTest()) {
				try {
					zApiInstance = new Zuora.ZApi();
					loginResult = zApiInstance.zlogin();
					zuoraZObjectList.addAll(zApiInstance.zquery(zoqlQueryString));
				}
				catch (Exception e) {
					// record the exception
					ExceptionUtility.consumeException(e, true);
					// increment the ZDU_RetrieveSoldToContactFailureCount__c for each record
					for (Zuora__CustomerAccount__c customerAccountRecord : customerAccountList) {
						customerAccountRecord.ZDU_RetrieveSoldToContactFailureCount__c = customerAccountRecord.ZDU_RetrieveSoldToContactFailureCount__c == null ? 1 : customerAccountRecord.ZDU_RetrieveSoldToContactFailureCount__c + 1;
						dataWrapper.zuoraCustomerAccountMap.put(customerAccountRecord.Id, customerAccountRecord);
					}
					// continue to escape execution of the main FOR loop
					continue;
				}
			}

			// for the records returned from zuora, update the customer account record with the Sold To data and add to update list
			for (Zuora.zObject zuoraQueryResult : zuoraZObjectList) {
				String soldToContactId = (String)zuoraQueryResult.getValue('Id');
				if (zuoraSoldToContactIdToCustomerAccountMap.containsKey(soldToContactId)) {
					Zuora__CustomerAccount__c zca = zuoraSoldToContactIdToCustomerAccountMap.remove(soldToContactId);
					zca.SoldToCity__c = (String)zuoraQueryResult.getValue('City');
					zca.SoldToCountry__c = (String)zuoraQueryResult.getValue('Country');
					zca.SoldToAddress1__c = (String)zuoraQueryResult.getValue('Address1');
					zca.SoldToAddress2__c = (String)zuoraQueryResult.getValue('Address2');
					zca.SoldToState__c = (String)zuoraQueryResult.getValue('State');
					zca.SoldToPostalCode__c = (String)zuoraQueryResult.getValue('PostalCode');
					zca.ZDU_RetrieveSoldToContact__c = false;
					zca.ZDU_RetrieveSoldToContactFailureCount__c = 0;
					dataWrapper.zuoraCustomerAccountMap.put(zca.Id, zca);
				}	
			}
			
			// for records NOT returned from zuora, also update the record to note the failure and add to update list
			for (Zuora__CustomerAccount__c customerAccountRecord : zuoraSoldToContactIdToCustomerAccountMap.values()) {
				customerAccountRecord.ZDU_RetrieveSoldToContactFailureCount__c = customerAccountRecord.ZDU_RetrieveSoldToContactFailureCount__c == null ? 1 : customerAccountRecord.ZDU_RetrieveSoldToContactFailureCount__c + 1;
				dataWrapper.zuoraCustomerAccountMap.put(customerAccountRecord.Id, customerAccountRecord);
			}
		}

		return dataWrapper;
	}
	

	/**
	 *   CSP-1659 | "updateZuoraAccounts" updates the following info on the Zuora Customer Account when
	 *   these values are updated in Salesforce:
	 *   	Account Name
	 *   	CBSS_Name__c
	 *   	SalesRepName
	 *   	CBSS_SalesRepId__c
	 *   	CBSS_Email__c
	 *   	CBSS_Phone__c
	 *   	CreditHold__c
	 *   	Customer_Type__c
	 *
	 *   @author Jonathan Satterfield
	 *   @date   2017-01-09
	 *   @param  {ZuoraDataUpdateWrapper}
	 *   @return {ZuoraDataUpdateWrapper}
	 */
	private static ZuoraDataUpdateWrapper updateZuoraAccounts(ZuoraDataUpdateWrapper dataWrapper) {

		// populate list of all Salesforce customer account records for which we need to update the related record in Zuora
		List<Zuora__CustomerAccount__c> updateZuoraAccountsList = new List<Zuora__CustomerAccount__c>();
		for (Id customerAccountId : dataWrapper.updateAccountIdSet) {
			if (!dataWrapper.zuoraCustomerAccountMap.containsKey(customerAccountId)) {
				continue;
			}
			updateZuoraAccountsList.add(dataWrapper.zuoraCustomerAccountMap.get(customerAccountId));
		}

		// can only update 50 records at a time, so break up the updateZuoraAccountsList into groups of 50
		// and add to "groupOf50RecordsList" list for processing
		// Also, even though the groupOf50Records is being added to the groupOf50RecordsList before the Zuora__CustomerAccount__c
		// is added to the groupOf50Records, the Zuora__CustomerAccount__c is still added due to how referencing works
		// in Salesforce/Apex
		List<List<Zuora__CustomerAccount__c>> groupOf50RecordsList = new List<List<Zuora__CustomerAccount__c>>();
		List<Zuora__CustomerAccount__c> groupOf50Records;
		for (Integer i = 0; i < updateZuoraAccountsList.size(); i++) {
			if (Math.mod(i, 50) == 0) {
				groupOf50Records = new List<Zuora__CustomerAccount__c>();
				groupOf50RecordsList.add(groupOf50Records);
			}
			groupOf50Records.add(updateZuoraAccountsList[i]);
		}

		// main loop
		for (List<Zuora__CustomerAccount__c> customerAccountList : groupOf50RecordsList) {

			List<Zuora.zObject> zuoraZObjectList = new List<Zuora.zObject>();

			Map<String, Zuora__CustomerAccount__c> zuoraIdToCustomerAccountRecordMap = new Map<String, Zuora__CustomerAccount__c>();

			for (Zuora__CustomerAccount__c customerAccountRecord : customerAccountList) {
				Zuora.zObject acc = !Test.isRunningTest() ? setAccountUpdateValues(new Zuora.zObject('Account'), customerAccountRecord, dataWrapper) : null;
				zuoraZObjectList.add(acc);
				zuoraIdToCustomerAccountRecordMap.put(customerAccountRecord.Zuora__Zuora_Id__c, customerAccountRecord);
			}

			// authenticate with zuora and perform update
			Zuora.ZApi zApiInstance;
			Zuora.zApi.LoginResult loginResult;
			List<Zuora.zApi.SaveResult> updateResults = new List<Zuora.zApi.SaveResult>();

			if (!Test.isRunningTest()) {
				try {
					zApiInstance = new Zuora.ZApi();
					loginResult = zApiInstance.zlogin();
					// callout method documention is here: https://knowledgecenter.zuora.com/CA_Commerce/E_Development_Resources/B_Order_Builder/D_Programming_with_Order_Builder
					updateResults.addAll(zApiInstance.zupdate(zuoraZObjectList));
				}
				catch (Exception e) {
					// record the exception
					ExceptionUtility.consumeException(e, true);
					// increment the ZDU_UpdateAccountFailureCount__c for each record
					for (Zuora__CustomerAccount__c customerAccountRecord : customerAccountList) {
						customerAccountRecord.ZDU_UpdateAccountFailureCount__c = customerAccountRecord.ZDU_UpdateAccountFailureCount__c == null ? 1 : customerAccountRecord.ZDU_UpdateAccountFailureCount__c + 1;
						dataWrapper.zuoraCustomerAccountMap.put(customerAccountRecord.Id, customerAccountRecord);
					}
					// continue to escape execution of the main FOR loop
					continue;
				}
			}

			for (Zuora.zApi.SaveResult updateResult : updateResults) {
				if (!zuoraIdToCustomerAccountRecordMap.containsKey(updateResult.Id)) {
					continue;
				}
				Zuora__CustomerAccount__c customerAccountRecord = zuoraIdToCustomerAccountRecordMap.remove(updateResult.Id);
				if (updateResult.Success) {
					// update all customer account fields for sync flags, CBSS, Credit Hold, Customer Type, etc
					customerAccountRecord = setAccountUpdateValues(customerAccountRecord, dataWrapper);
				}
				else {
					customerAccountRecord.ZDU_UpdateAccountFailureCount__c = customerAccountRecord.ZDU_UpdateAccountFailureCount__c == null ? 1 : customerAccountRecord.ZDU_UpdateAccountFailureCount__c + 1;
				}
				dataWrapper.zuoraCustomerAccountMap.put(customerAccountRecord.Id, customerAccountRecord);
			}

			// for records NOT returned from zuora, also update the record to note the failure and add to update list
			for (Zuora__CustomerAccount__c customerAccountRecord : zuoraIdToCustomerAccountRecordMap.values()) {
				customerAccountRecord.ZDU_UpdateAccountFailureCount__c = customerAccountRecord.ZDU_UpdateAccountFailureCount__c == null ? 1 : customerAccountRecord.ZDU_UpdateAccountFailureCount__c + 1;
				dataWrapper.zuoraCustomerAccountMap.put(customerAccountRecord.Id, customerAccountRecord);
			}
		}

		return dataWrapper;
	}


	/**
	 *   CSP-1659 | "updateZuoraContacts" updates the Bill To and Sold To Contacts in Zuora when contact data
	 *   is updated on the Zuora__CustomerAccount__c record in Salesforce. If the Bill To and Sold To Contacts
	 *   are the same (aka have the same Zuora Id), the Bill To Contact information will be used.
	 *
	 *   @author Jonathan Satterfield
	 *   @date   2017-01-09
	 *   @param  {ZuoraDataUpdateWrapper}
	 *   @return {ZuoraDataUpdateWrapper}
	 */
	private static ZuoraDataUpdateWrapper updateZuoraContacts(ZuoraDataUpdateWrapper dataWrapper) {

		// populate list of all Salesforce customer account records for which we need to update the related record in Zuora
		List<Zuora__CustomerAccount__c> updateZuoraAccountsList = new List<Zuora__CustomerAccount__c>();
		for (Id customerAccountId : dataWrapper.updateContactsIdSet) {
			if (!dataWrapper.zuoraCustomerAccountMap.containsKey(customerAccountId)) {
				continue;
			}
			updateZuoraAccountsList.add(dataWrapper.zuoraCustomerAccountMap.get(customerAccountId));
		}

		// can only update 50 records at a time, so break up the updateZuoraAccountsList into groups of 25
		// and add to "groupOf25RecordsList" list for processing. the reason for choosing 25 accounts is the
		// customer account record can have a Bill To Contact and a Sold To Contact (2 x 25 = 50)
		// Also, even though the groupOf25Records is being added to the groupOf25RecordsList before the Zuora__CustomerAccount__c
		// is added to the groupOf25Records, the Zuora__CustomerAccount__c is still added due to how referencing works
		// in Salesforce/Apex
		List<List<Zuora__CustomerAccount__c>> groupOf25RecordsList = new List<List<Zuora__CustomerAccount__c>>();
		List<Zuora__CustomerAccount__c> groupOf25Records;
		for (Integer i = 0; i < updateZuoraAccountsList.size(); i++) {
			if (Math.mod(i, 25) == 0) {
				groupOf25Records = new List<Zuora__CustomerAccount__c>();
				groupOf25RecordsList.add(groupOf25Records);
			}
			groupOf25Records.add(updateZuoraAccountsList[i]);
		}

		// main loop
		for (List<Zuora__CustomerAccount__c> customerAccountList : groupOf25RecordsList) {

			Map<String, String> zuoraContactIdToCustomerAccountIdMap = new Map<String, String>();
			Map<String, Zuora__CustomerAccount__c> zuoraAccountIdToCustomerAccountRecordMap = new Map<String, Zuora__CustomerAccount__c>();
			List<Zuora.zObject> zuoraZObjectList = new List<Zuora.zObject>();

			for (Zuora__CustomerAccount__c customerAccountRecord : customerAccountList) {
				// contact logic; unfortunately we're 3 FOR loops deep here, but setContactUpdateValues will return at maximum two records
				for (Zuora.zObject zContact : setContactUpdateValues(customerAccountRecord)) {
					zuoraContactIdToCustomerAccountIdMap.put((String)zContact.getValue('Id'), customerAccountRecord.Zuora__Zuora_Id__c);
					zuoraAccountIdToCustomerAccountRecordMap.put(customerAccountRecord.Zuora__Zuora_Id__c, customerAccountRecord);
					zuoraZObjectList.add(zContact);
				}
			}

			// authenticate with zuora and perform update
			Zuora.ZApi zApiInstance;
			Zuora.zApi.LoginResult loginResult;
			List<Zuora.zApi.SaveResult> updateResults = new List<Zuora.zApi.SaveResult>();

			if (!Test.isRunningTest()) {
				try {
					zApiInstance = new Zuora.ZApi();
					loginResult = zApiInstance.zlogin();
					// callout method documention is here: https://knowledgecenter.zuora.com/CA_Commerce/E_Development_Resources/B_Order_Builder/D_Programming_with_Order_Builder
					updateResults.addAll(zApiInstance.zupdate(zuoraZObjectList));
				}
				catch (Exception e) {
					// record the exception
					ExceptionUtility.consumeException(e, true);
					// increment the ZDU_UpdateContactsFailureCount__c for each record
					for (Zuora__CustomerAccount__c customerAccountRecord : customerAccountList) {
						customerAccountRecord.ZDU_UpdateContactsFailureCount__c = customerAccountRecord.ZDU_UpdateContactsFailureCount__c == null ? 1 : customerAccountRecord.ZDU_UpdateContactsFailureCount__c + 1;
						dataWrapper.zuoraCustomerAccountMap.put(customerAccountRecord.Id, customerAccountRecord);
					}
					// continue to escape execution of the main FOR loop
					continue;
				}
			}

			// this results-checking logic is different from the results-checking logic in the retrieveSoldToContacts and updateZuoraAccounts methods.
			// in those methods, we first check for successful updates/queries; in this method, we check for failures and base our logic around that.
			// the reason for this is there are two possible Contact record updates per customer account, and if either of those updates fail, we need
			// to increment the ZDU_UpdateContactsFailureCount__c field. tldr: it's easier to work around failures in this case rather than successes.
			for (Zuora.zApi.SaveResult updateResult : updateResults) {
				if (!zuoraContactIdToCustomerAccountIdMap.containsKey(updateResult.Id)) {
					continue;
				}
				String customerAccountRecordId = zuoraContactIdToCustomerAccountIdMap.remove(updateResult.Id);
				if (!updateResult.Success && zuoraAccountIdToCustomerAccountRecordMap.containsKey(customerAccountRecordId)) {
					Zuora__CustomerAccount__c customerAccountRecord = zuoraAccountIdToCustomerAccountRecordMap.remove(customerAccountRecordId);
					customerAccountRecord.ZDU_UpdateContactsFailureCount__c = customerAccountRecord.ZDU_UpdateContactsFailureCount__c == null ? 1 : customerAccountRecord.ZDU_UpdateContactsFailureCount__c + 1;
					dataWrapper.zuoraCustomerAccountMap.put(customerAccountRecord.Id, customerAccountRecord);
				}
			}
			for (Zuora__CustomerAccount__c customerAccountRecord : zuoraAccountIdToCustomerAccountRecordMap.values()) {
				customerAccountRecord.ZDU_UpdateContacts__c = false;
				customerAccountRecord.ZDU_UpdateContactsFailureCount__c = 0;
				dataWrapper.zuoraCustomerAccountMap.put(customerAccountRecord.Id, customerAccountRecord);
			}
		}

		return dataWrapper;
	}


	/**
	 *   CSP-1659 | "setContactUpdateValues" is called in the "updateZuoraContacts" method to create Zuora.zObject
	 *   objects for the Bill To / Sold To Contact data update, and set the appropriate values.
	 *
	 *   @author Jonathan Satterfield
	 *   @date   2017-01-10
	 *   @param  {Zuora__CustomerAccount__c}
	 *   @return {List<Zuora.zObject>}
	 */
	private static List<Zuora.zObject> setContactUpdateValues(Zuora__CustomerAccount__c customerAccountRecord) {

		List<Zuora.zObject> zContactList = new List<Zuora.zObject>();

		if (Test.isRunningTest()) {
			return zContactList;
		}

		// first set Bill To Contact info
		Zuora.zObject billToContact = new Zuora.zObject('Contact');                                                       
		billToContact.setValue('Id', customerAccountRecord.Zuora__BillToId__c);
		// set first and last name
		billToContact = setContactName(billToContact, customerAccountRecord.Zuora__BillToName__c);
		billToContact.setValue('Address1', String.isNotBlank(customerAccountRecord.Zuora__BillToAddress1__c) ? customerAccountRecord.Zuora__BillToAddress1__c : '');
		billToContact.setValue('Address2', String.isNotBlank(customerAccountRecord.Zuora__BillToAddress2__c) ? customerAccountRecord.Zuora__BillToAddress2__c : '');
		billToContact.setValue('City', String.isNotBlank(customerAccountRecord.Zuora__BillToCity__c) ? customerAccountRecord.Zuora__BillToCity__c : '');
		billToContact.setValue('State', String.isNotBlank(customerAccountRecord.Zuora__BillToState__c) ? customerAccountRecord.Zuora__BillToState__c : '');
		billToContact.setValue('PostalCode', String.isNotBlank(customerAccountRecord.Zuora__BillToPostalCode__c) ? customerAccountRecord.Zuora__BillToPostalCode__c : '');
		billToContact.setValue('Country', String.isNotBlank(customerAccountRecord.Zuora__BillToCountry__c) ? customerAccountRecord.Zuora__BillToCountry__c : '');
		billToContact.setValue('WorkEmail', String.isNotBlank(customerAccountRecord.Zuora__BillToWorkEmail__c) ? customerAccountRecord.Zuora__BillToWorkEmail__c : '');
		billToContact.setValue('WorkPhone', String.isNotBlank(customerAccountRecord.Zuora__BillToWorkPhone__c) ? customerAccountRecord.Zuora__BillToWorkPhone__c : '');
		zContactList.add(billToContact);	

		// if the Bill To Contact and Sold To Contact are the same Contact record in Zuora, the Bill To Contact's info will be used
		if (customerAccountRecord.Zuora__BillToId__c == customerAccountRecord.Zuora__SoldToId__c) {
			return zContactList;
		}		

		// otherwise set Sold To Contact info if needed
		Zuora.zObject soldToContact = new Zuora.zObject('Contact');                                                       
		soldToContact.setValue('Id', customerAccountRecord.Zuora__SoldToId__c);
		// set first and last name
		soldToContact = setContactName(soldToContact, customerAccountRecord.Zuora__SoldToName__c);
		soldToContact.setValue('Address1', String.isNotBlank(customerAccountRecord.SoldToAddress1__c) ? customerAccountRecord.SoldToAddress1__c : '');
		soldToContact.setValue('Address2', String.isNotBlank(customerAccountRecord.SoldToAddress2__c) ? customerAccountRecord.SoldToAddress2__c : '');
		soldToContact.setValue('City', String.isNotBlank(customerAccountRecord.SoldToCity__c) ? customerAccountRecord.SoldToCity__c : '');
		soldToContact.setValue('State', String.isNotBlank(customerAccountRecord.SoldToState__c) ? customerAccountRecord.SoldToState__c : '');
		soldToContact.setValue('PostalCode', String.isNotBlank(customerAccountRecord.SoldToPostalCode__c) ? customerAccountRecord.SoldToPostalCode__c : '');
		soldToContact.setValue('Country', String.isNotBlank(customerAccountRecord.SoldToCountry__c) ? customerAccountRecord.SoldToCountry__c : '');
		zContactList.add(soldToContact);

		return zContactList;
	}


	/**
	 *   CSP-1659 | "setContactName" splits the Bill To / Sold To Contact's full name for the data update
	 *   (we only have the contact's full name on the Zuora__CustomerAccount__c record in Salesforce, but
	 *   in Zuora the Contact has separate fields for both first and last name).
	 *
	 *   @author Justin Lisbon / Jonathan Satterfield
	 *   @date   2017-01-10
	 *   @param  {Zuora.zObject}
	 *   @param  {String}
	 *   @return {Zuora.zObject}
	 */
	private static Zuora.zObject setContactName(Zuora.zObject zContact, String fullName) {
		// Get the single string of the name
		//List<String> nameSplit = customerAccountRecord.Zuora__BillToName__c.split(' ');
		List<String> nameSplit = fullName.split(' ');
		String firstName = '';
		String lastName = '';

		// Determine the "half way" point of the name split on spaces. If the number is not divisible by two make an
		// assumption and round down. This will take the less half of the split as the first name and the greater half
		// as the last name. For example: 
		// Joe Bob Smith would end up as
		// FirstName = "Joe"
		// LastName = "Bob Smith"
		Integer nameHalfPoint = (nameSplit.size() / 2);
		for (Integer i = 0; i < nameSplit.size(); i++) {
			if ((i + 1) <= nameHalfPoint) {
				firstName += ' ' + nameSplit[i];
				continue;
			}
			lastName += ' ' + nameSplit[i];
		}

		// Trim the strings to get rid of the leading space
		firstName = firstName.trim();
		lastName = lastName.trim();

		zContact.setValue('FirstName', firstName);
		zContact.setValue('LastName', String.isNotBlank(lastName) ? lastName : '');

		return zContact;
	}


	/**
	 *   CSP-1659 | "setAccountUpdateValues" is used in the "updateZuoraAccounts" method to set
	 *   values for the Account update.
	 *
	 *   @author Jonathan Satterfield
	 *   @date   2017-01-10
	 *   @param  {Zuora.zObject}
	 *   @param  {Zuora__CustomerAccount__c}
	 *   @param  {ZuoraDataUpdateWrapper}
	 *   @return {Zuora.zObject}
	 */
	private static Zuora.zObject setAccountUpdateValues(Zuora.zObject acc, Zuora__CustomerAccount__c customerAccountRecord, ZuoraDataUpdateWrapper dataWrapper) {
		// Zuora Account Id
		acc.setValue('Id', customerAccountRecord.Zuora__Zuora_Id__c);
		// Account Name
		acc.setValue('Name', customerAccountRecord.Name);
		// CBSS Name
		String cbssName = String.isNotBlank(customerAccountRecord.Zuora__Account__r.CBBS__r.Name) ? customerAccountRecord.Zuora__Account__r.CBBS__r.Name : 'n/a';
		acc.setValue('CBSS_Name__c', cbssName);
		// Sales rep name csp-1603
		String salesRepName = String.isNotBlank(customerAccountRecord.Zuora__SalesRepName__c) ? customerAccountRecord.Zuora__SalesRepName__c : '';
		acc.setValue('SalesRepName', salesRepName);
		// CBSS Sales Rep Id
		String salesRepId = String.isNotBlank(customerAccountRecord.Zuora__Account__r.CBBS__r.SalesRepID__c) ? customerAccountRecord.Zuora__Account__r.CBBS__r.SalesRepID__c : 'n/a';
		acc.setValue('CBSS_SalesRepId__c', salesRepId);					
		// CBSS Email
		if (dataWrapper.defaultCBSSValue.Email__c != null) {
			String cbssEmail = String.isNotBlank(customerAccountRecord.Zuora__Account__r.CBBS__r.Email) ? customerAccountRecord.Zuora__Account__r.CBBS__r.Email : dataWrapper.defaultCBSSValue.Email__c;
			acc.setValue('CBSS_Email__c', cbssEmail);
		}
		// CBSS Phone
		if (dataWrapper.defaultCBSSValue.Phone__c != null) {
			String cbssPhone = String.isNotBlank(customerAccountRecord.Zuora__Account__r.CBBS__r.Phone) ? customerAccountRecord.Zuora__Account__r.CBBS__r.Phone : dataWrapper.defaultCBSSValue.Phone__c;
			acc.setValue('CBSS_Phone__c', cbssPhone);
		}
		// Credit Hold
		if (customerAccountRecord.NeedToUpdateCreditHold__c) {
			acc.setValue('CreditHold__c', customerAccountRecord.Zuora__Account__r.CreditHold__c);
		}
		// Customer Type
		if (customerAccountRecord.NeedToUpdateCustomerType__c) {
			// CSP-2005 | if Zuora__Account__r.Customer_Type__c is blank, set value to "NONE"
			String customerAccountValue = String.isBlank(customerAccountRecord.Zuora__Account__r.Customer_Type__c) ? 'NONE' : customerAccountRecord.Zuora__Account__r.Customer_Type__c;
			acc.setValue('Customer_Type__c', customerAccountValue);
		}
		return acc;
	}


	/**
	 *   CSP-1659 | "setAccountUpdateValues" is used in the "updateZuoraAccounts" method to set
	 *   values for the Account update. This overloaded version of the method is used to set the appropriate
	 *   values on the Zuora__CustomerAccount__c record after the related Customer Account record
	 *   is successfully updated in Zuora.
	 *
	 *   @author Jonathan Satterfield
	 *   @date   2017-01-10
	 *   @param  {Zuora__CustomerAccount__c}
	 *   @param  {ZuoraDataUpdateWrapper}
	 *   @return {Zuora__CustomerAccount__c}
	 */
	private static Zuora__CustomerAccount__c setAccountUpdateValues(Zuora__CustomerAccount__c customerAccountRecord, ZuoraDataUpdateWrapper dataWrapper) {
		// CBSS Name
		customerAccountRecord.CBSS_Name__c = String.isNotBlank(customerAccountRecord.Zuora__Account__r.CBBS__r.Name) ? customerAccountRecord.Zuora__Account__r.CBBS__r.Name : 'n/a';
		// Sales rep name csp-1603
		customerAccountRecord.Zuora__SalesRepName__c = String.isNotBlank(customerAccountRecord.Zuora__SalesRepName__c) ? customerAccountRecord.Zuora__SalesRepName__c : 'n/a';
		// CBSS Sales Rep Id
		customerAccountRecord.CBSS_SalesRepId__c = String.isNotBlank(customerAccountRecord.Zuora__Account__r.CBBS__r.SalesRepID__c) ? customerAccountRecord.Zuora__Account__r.CBBS__r.SalesRepID__c : 'n/a';				
		// CBSS Email
		if (dataWrapper.defaultCBSSValue.Email__c != null) {
			customerAccountRecord.CBSS_Email__c = String.isNotBlank(customerAccountRecord.Zuora__Account__r.CBBS__r.Email) ? customerAccountRecord.Zuora__Account__r.CBBS__r.Email : dataWrapper.defaultCBSSValue.Email__c;
		}
		// CBSS Phone
		if (dataWrapper.defaultCBSSValue.Phone__c != null) {
			customerAccountRecord.CBSS_Phone__c = String.isNotBlank(customerAccountRecord.Zuora__Account__r.CBBS__r.Phone) ? customerAccountRecord.Zuora__Account__r.CBBS__r.Phone : dataWrapper.defaultCBSSValue.Phone__c;
		}
		// Credit Hold
		if (customerAccountRecord.NeedToUpdateCreditHold__c) {
			customerAccountRecord.CreditHold__c = customerAccountRecord.Zuora__Account__r.CreditHold__c;
		}
		// Customer Type
		if (customerAccountRecord.NeedToUpdateCustomerType__c) {
			// CSP-2005 | if Zuora__Account__r.Customer_Type__c is blank, set value to "NONE"
			customerAccountRecord.Customer_Type__c = String.isBlank(customerAccountRecord.Zuora__Account__r.Customer_Type__c) ? 'NONE' : customerAccountRecord.Zuora__Account__r.Customer_Type__c;
		}
		// Uncheck the "NeedToUpdateAccountDetails__c" flag -- created for CSP-1603
		customerAccountRecord.NeedToUpdateAccountDetails__c = false;
		// reset the "ZDU_UpdateAccountFailureCount__c" flag to 0
		customerAccountRecord.ZDU_UpdateAccountFailureCount__c = 0;
		return customerAccountRecord;
	}


	public class ZuoraDataUpdateWrapper {

		public Map<Id, Zuora__CustomerAccount__c> zuoraCustomerAccountMap;
		public Set<Id> retrieveSoldToContactIdSet;
		public Set<Id> updateAccountIdSet;
		public Set<Id> updateContactsIdSet;
		public DefaulCBSSValues__c defaultCBSSValue;

		public ZuoraDataUpdateWrapper(List<Zuora__CustomerAccount__c> scope) {
			// instantiate class members
			this.zuoraCustomerAccountMap = new Map<Id, Zuora__CustomerAccount__c>();
			this.retrieveSoldToContactIdSet = new Set<Id>();
			this.updateAccountIdSet = new Set<Id>();
			this.updateContactsIdSet = new Set<Id>();

			// populate data
			for (Integer i = 0; i < scope.size(); i++) {
				Zuora__CustomerAccount__c customerAccount = scope[i];
				this.zuoraCustomerAccountMap.put(customerAccount.Id, customerAccount);
				if (customerAccount.ZDU_RetrieveSoldToContact__c) {
					this.retrieveSoldToContactIdSet.add(customerAccount.Id);
				}
				if (customerAccount.ZDU_UpdateAccount__c) {
					this.updateAccountIdSet.add(customerAccount.Id);
				}
				if (customerAccount.ZDU_UpdateContacts__c) {
					this.updateContactsIdSet.add(customerAccount.Id);
				}
			}

			// get email and phone from custom settings DefaultCBSSValues
			this.defaultCBSSValue = DefaulCBSSValues__c.getInstance('InvoiceTemplate');
		}
	}
}