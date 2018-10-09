public without sharing class ZuoraBillingAccountTriggerHandler implements XOTrigger {
	////////////////////////////
  // STATIC FINAL VARIABLES //
  ////////////////////////////
  // Dynamic Account Query
  private static final String ACCOUNT_QUERY = 	'SELECT '
					  																			+ 'Id, '
					  																			+	'Name, '
					  																			+	'CBBS__r.Name, '
					  																			+	'CBSS_Phone__c, '
					  																			+	'CBSS_Email__c '
					  																		+	' FROM '
					  																			+	' Account '
					  																		+ ' WHERE '
					  																			+	' {WHERECLAUSE} ';

	// Dynamic Contact Query
	private static final String CONTACT_QUERY = 'SELECT '
																							+	'Id, '
																							+	'Name, '
																							+	'FirstName, '
																							+	'LastName, '
																							+	'Phone, '
																							+	'Email, '
																							+	'MailingCity, '
																							+	'MailingState, '
																							+	'MailingStreet, '
																							+	'MailingPostalCode, '
																							+	'MailingCountry '
																						+	' FROM '
																							+	'Contact'
																						+	' WHERE '
																							+	'{WHERECLAUSE}';

	// Dynamic Quote Query
	private static final String QUOTE_QUERY = 'SELECT '
																							+ 'Id, '
																							+	'Name, '
																							+	'zqu__ZuoraAccountID__c, '
																							+	'zqu__BillToContact__c, '
																							+	'zqu__SoldToContact__c '
																						+	' FROM '
																							+	'zqu__Quote__c'
																						+	' WHERE '
																							+	'{WHERECLAUSE}'
																						+	' ORDER BY LastModifiedDate DESC';

	// Contact to Billing Account Bill To Mapping
	private static final Map<String, String>
												CONTACT_TO_BILL_TO = new Map<String, String>{	'Phone'							=> 'Zuora__BillToWorkPhone__c',
																																			'Email'							=> 'Zuora__BillToWorkEmail__c',
																																			'MailingStreet' 		=> 'Zuora__BillToAddress1__c',
																																			'MailingCity' 			=> 'Zuora__BillToCity__c',
																																			'MailingState' 			=> 'Zuora__BillToState__c',
																																			'MailingPostalCode' => 'Zuora__BillToPostalCode__c',
																																			'MailingCountry' 		=> 'Zuora__BillToCountry__c'};

	// Contact to Billing Account Sold To Mapping 
	private static final Map<String, String> 
												CONTACT_TO_SOLD_TO = new Map<String, String>{	'MailingStreet' 		=> 'SoldToAddress1__c',
																																			'MailingCity' 			=> 'SoldToCity__c',
																																			'MailingState' 			=> 'SoldToState__c',
																																			'MailingPostalCode' => 'SoldToPostalCode__c',
																																			'MailingCountry' 		=> 'SoldToCountry__c'};

	// CSP-2041 - Quote Look Back Date - How far should the code look back for Quotes with the generating Zuora Account Id?
	private static final Date QUOTE_LOOK_BACK_DATE = Date.today().addDays(-10);

	//////////////////////
	// STATIC VARIABLES //
	//////////////////////
	// CSP-1659 | static boolean set by the BatchZuoraDataUpdater batch job to prevent recursion
	public static Boolean batchZuoraDataUpdaterRunning = false;
	// CSP-1659 | boolean flag set when data needs to be updated in Zuora
	private static Boolean runBatchZuoraDataUpdateJob = false;

	////////////////////////
	// INSTANCE VARIABLES //
	////////////////////////
	// CSP-1944 - Populate CBSS Phone and Email on insert of Billing Account
	private Map<Id, Account> idToAccountMap = new Map<Id, Account>();

	// CSP-2041 - Populate Bill To and Sold To Contact lookups on Insert
	private Map<String, zqu__Quote__c> zuoraAccountIdToQuoteMap = new Map<String, zqu__Quote__c>();

	// CSP-2041 - Populate Bill To and Sold To Contact information on Contact lookup change
	private Map<Id, Contact> idToContactMap = new Map<Id, Contact>();

	public void bulkBefore() {
		Set<Id> accountIdSet = new Set<Id>();
		Set<String> zuoraAccountIdSet = new Set<String>();
		Set<Id> contactIdSet = new Set<Id>();

		List<Zuora__CustomerAccount__c> billingAccountList = (List<Zuora__CustomerAccount__c>)Trigger.new;
		Map<Id, Zuora__CustomerAccount__c> oldBillingAccountMap;
		if(Trigger.isUpdate) {
			oldBillingAccountMap = (Map<Id, Zuora__CustomerAccount__c>)Trigger.oldMap;
		}

		for(Integer i = 0; i < billingAccountList.size(); i++) {
			Zuora__CustomerAccount__c currentBillingAccount = billingAccountList[i];
			
			// This relation is a master detail and is required so should never be blank but it is a managed package field
			// which can be modified outside of our control. Better safe than sorry.
			if(String.isNotBlank(currentBillingAccount.Zuora__Account__c)) {
				accountIdSet.add(currentBillingAccount.Zuora__Account__c);
			}

			//////////////////////////////
			// BULK BEFORE INSERT LOGIC //
			//////////////////////////////
			if(Trigger.isInsert) {
				/*
					CSP-2041
					This field should never be blank as this object is being sync'd from Zuora but someone could manually create
					this record in Salesforce which would cause issues.
				 */
				if(String.isNotBlank(currentBillingAccount.Zuora__Zuora_Id__c)) {
					zuoraAccountIdSet.add(currentBillingAccount.Zuora__Zuora_Id__c);
				}
			} 
			//////////////////////////////
			// BULK BEFORE UPDATE LOGIC //
			//////////////////////////////
			else if(Trigger.isUpdate) {
				Zuora__CustomerAccount__c oldBillingAccount = oldBillingAccountMap.get(currentBillingAccount.Id);

				/*
					CSP-2041
					If a User updates the Contact lookup field for either the Bill To or Sold To then we need to repopulate all the
					Bill To or Sold To information respectively on the Billing Account
				 */
				if(currentBillingAccount.Bill_To_Contact__c != oldBillingAccount.Bill_To_Contact__c) {
					contactIdSet.add(currentBillingAccount.Bill_To_Contact__c);
				}

				if(currentBillingAccount.Sold_To_Contact__c != oldBillingAccount.Sold_To_Contact__c) {
					contactIdSet.add(currentBillingAccount.Sold_To_Contact__c);
				}
			}
		}

		idToAccountMap = new Map<Id, Account>((List<Account>)Database.query(ACCOUNT_QUERY.replace('{WHERECLAUSE}', 'Id IN :accountIdSet')));
		
		if(zuoraAccountIdSet.size() > 0) {
			// Build Dynamic Query
			String quoteQuery = QUOTE_QUERY.replace('{WHERECLAUSE}', 'zqu__ZuoraAccountID__c IN :zuoraAccountIdSet AND LastModifiedDate > :QUOTE_LOOK_BACK_DATE');
			
			// Query Quotes
			List<zqu__Quote__c> quoteList = Database.query(quoteQuery);
			
			// Build Quote Map
			for(Integer i = 0; i < quoteList.size(); i++) {
				zqu__Quote__c currentQuote = quoteList[i];
				if(zuoraAccountIdToQuoteMap.containsKey(currentQuote.zqu__ZuoraAccountID__c)) {
					continue;
				}

				zuoraAccountIdToQuoteMap.put(currentQuote.zqu__ZuoraAccountID__c, currentQuote);
			}
		}

		// CSP-2041
		if(contactIdSet.size() > 0) {
			idToContactMap = new Map<Id, Contact>((List<Contact>)Database.query(CONTACT_QUERY.replace('{WHERECLAUSE}', 'Id IN :contactIdSet')));	
		}
	}
	
	/**
	 *   Method used to bulkify all data needed in any "after" action of a trigger.
	 */
	public void bulkAfter() {
		
	}
	
	/**
	 *   All before insert logic should be done here. This method is called iteratively and as such
	 *   should contain no actions which could potentially hit limits or is considered bad practice 
	 *   in the Salesforce environment.
	 *   
	 *   @param  {SObject}   so Single SObject representation of the object being acted upon.
	 */
	public void beforeInsert(SObject so) {
		Zuora__CustomerAccount__c newRecord = (Zuora__CustomerAccount__c)so;

		// CSP-1944
		// Populate the CBSS information from the Parent Account upon insert
		if(idToAccountMap.containsKey(newRecord.Zuora__Account__c)) {
			Account currentAccount = idToAccountMap.get(newRecord.Zuora__Account__c);
			if(String.isNotBlank(currentAccount.CBBS__c)) {
				newRecord.CBSS_Name__c = currentAccount.CBBS__r.Name;	
			}
			newRecord.CBSS_Email__c = currentAccount.CBSS_Email__c;
			newRecord.CBSS_Phone__c = currentAccount.CBSS_Phone__c;
		}

		// CSP-2041 - Populate Bill To and Sold To Contact Lookup fields using the Quote
		if(zuoraAccountIdToQuoteMap.containsKey(newRecord.Zuora__Zuora_Id__c)) {
			zqu__Quote__c associatedQuote = zuoraAccountIdToQuoteMap.get(newRecord.Zuora__Zuora_Id__c);

			newRecord.Bill_To_Contact__c = associatedQuote.zqu__BillToContact__c;
			newRecord.Sold_To_Contact__c = associatedQuote.zqu__SoldToContact__c;
		}

		// CSP-1659 | for newly created Accounts check this checkbox to sync down the "Sold To" Contact info,
		// and set the runBatchZuoraDataUpdateJob boolean flag to true
		newRecord.ZDU_RetrieveSoldToContact__c = true;
		runBatchZuoraDataUpdateJob = true;		
	}
	
	/**
	*   All before update logic should be done here. This method is called iteratively and as such
	*   should contain no actions which could potentially hit limits or is considered bad practice
	*   in the Salesforce environment.
	*
	*   @param  {SObject}   oldSo Single SObject representation of the "old" copy of the current 
	*                             object being acted upon.
	*   @param  {SObject}   so    Single SObject representation of the object being acted upon.
	*/
	public void beforeUpdate(SObject oldSo, SObject so) {
		Zuora__CustomerAccount__c newRecord = (Zuora__CustomerAccount__c)so;
		Zuora__CustomerAccount__c oldRecord = (Zuora__CustomerAccount__c)oldSo;

		// CSP-2041
		if(newRecord.Bill_To_Contact__c != oldRecord.Bill_To_Contact__c && idToContactMap.containsKey(newRecord.Bill_To_Contact__c)) {
			Contact billToContact = idToContactMap.get(newRecord.Bill_To_Contact__c);
			
			newRecord = mapContactToBillingAccount(billToContact, newRecord, 'BILL_TO');
		}
		
		// CSP-2041
		if(newRecord.Sold_To_Contact__c != oldRecord.Sold_To_Contact__c && idToContactMap.containsKey(newRecord.Sold_To_Contact__c)) {
			Contact soldToContact = idToContactMap.get(newRecord.Sold_To_Contact__c);

			newRecord = mapContactToBillingAccount(soldToContact, newRecord, 'SOLD_TO');
		}

		// Moved the zuora update batch check below record modification logic so it happens last
		if (batchZuoraDataUpdaterRunning == false) {
			// CSP-1659 | if Contact info is updated check the ZDU_UpdateContacts__c checkbox
			setUpdateContactsFlagOnContactUpdate(newRecord, oldRecord);
		}
	}

	/**
	*   All before delete logic should be done here. This method is called iteratively and as such
	*   should contain no actions which could potentilly hit limits or is considered bad practice
	*   in the Salesforce environment.
	*
	*   @param  {SObject}   so Single SObject representation of the object being acted upon.
	*/
	public void beforeDelete(SObject so) {

	}

	/**
	*   All after insert logic should be done here. This method is called iteratively and as such
	*   should contain no actions which could potentilly hit limits or is considered bad practice
	*   in the Salesforce environment. 
	*
	*   @param  {SObject}   so Single SObject representation of the object being acted upon.
	*/
	public void afterInsert(SObject so) {

	}
	
	/**
	*   All after update logic should be done here. This method is called iteratively and as such
	*   should contain no actions which could potentilly hit limits or is considered bad practice
	*   in the Salesforce environment.
	*   
	*   @param  {SObject}   oldSo Single SObject representation of the "old" copy of the current 
	*                             object being acted upon.
	*   @param  {SObject}   so    Single SObject representation of the object being acted upon.
	*/
	public void afterUpdate(SObject oldSo, SObject so) {
		Zuora__CustomerAccount__c newRecord = (Zuora__CustomerAccount__c)so;
		Zuora__CustomerAccount__c oldRecord = (Zuora__CustomerAccount__c)oldSo;

		// CSP-1414 - BillToName field must have at least one space within it
		if(String.isNotBlank(newRecord.Zuora__BillToName__c) && newRecord.Zuora__BillToName__c != oldRecord.Zuora__BillToName__c) {
			List<String> stringSplitList = newRecord.Zuora__BillToName__c.split(' ');
			if(stringSplitList.size() < 2) {
				newRecord.Zuora__BillToName__c.addError('Bill To Name must have a First Name and Last Name');
			}
		}

		// CSP-1414 - SoldToName field MUST have at least one space within it
		if(String.isNotBlank(newRecord.Zuora__SoldToName__c) && newRecord.Zuora__SoldToName__c != oldRecord.Zuora__SoldToName__c) {
			List<String> stringSplitList = newRecord.Zuora__SoldToName__c.split(' ');
			if(stringSplitList.size() < 2) {
				newRecord.Zuora__SoldToName__c.addError('Sold To Name must have a First Name and Last Name');
			}
		}

		// CSP-1659 | check to see if we need to run the BatchZuoraDataUpdate job after record update
		if (batchZuoraDataUpdaterRunning == false && runBatchZuoraDataUpdateJob == false && (newRecord.ZDU_UpdateAccount__c || newRecord.ZDU_UpdateContacts__c)) {
			runBatchZuoraDataUpdateJob = true;
		}
	}

	/**
	*   All after delete logic should be done here. This method is called iteratively and as such
	*   should contain no actions which could potentilly hit limits or is considered bad practice
	*   in the Salesforce environment. 
	*
	*   @param  {SObject}   so Single SObject representation of the object being acted upon.
	*/
	public void afterDelete(SObject so) {

	}

	/**
	*   All final logic in the "before" context should be done at this point such as modification to objects outside of
	*   the current object. At this point all updates to the current trigger transaction should be
	*   complete and all validation done.
	*/
	public void beforeAndFinally() {
		
	}
	
	/**
	*   All final logic in the "after" context should be done at this point such as modification to objects outside of
	*   the current object. At this point all updates to the current trigger transaction should be
	*   complete and all validation done.
	*/
	public void afterAndFinally() {
		
		// CSP-1659 | run BatchZuoraDataUpdater job if needed
		if (runBatchZuoraDataUpdateJob) {
			Set<String> asyncJobInProgressStatusSet = new Set<String>{'Holding', 'Queued', 'Preparing', 'Processing'};
			Integer runningBatchZuoraDataUpdaterJobCount = [SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = 'BatchZuoraDataUpdater' AND Status IN :asyncJobInProgressStatusSet LIMIT 1];
			if (runningBatchZuoraDataUpdaterJobCount == 0 && !System.isFuture() && !System.isBatch()) {
				Database.executebatch(new BatchZuoraDataUpdater());
			}
		}
	}

	/**
	 *   Method used to map Contact information to a specified Billing Account - the information being mapped is different
	 *   depending upon the contactInformation value sent. Currently this can only be two values, "BILL_TO" and "SOLD_TO"
	 *   but could grow later.
	 *
	 *   @author Justin
	 *   @date   2017-04-06
	 *   @param  {Contact}                    currentContact        This is the contact that is being used as a Parent
	 *   @param  {Zuora__CustomerAccount__c}  currentBillingAccount This is the billing account being used
	 *                                                              as the Child
	 *   @param  {String}                     contactInformation    The controlling field being used to determine what type
	 *                                                              of data needs to be stored
	 *   @return {Zuora__CustomerAccount__c}                        The Billing Account that has had its data mapped
	 */
	public static Zuora__CustomerAccount__c mapContactToBillingAccount(Contact currentContact, Zuora__CustomerAccount__c currentBillingAccount, String contactInformation) {
		// Variables used to store field mapping values to use later
		List<String> contactFields; 
		Map<String, String> contactMapping;

		// Determine which field mapping variable to use
		if(contactInformation == 'BILL_TO') {
			contactFields = new List<String>(CONTACT_TO_BILL_TO.keySet());
			contactMapping = CONTACT_TO_BILL_TO;

			// Can't just use the dynamic "Name" formula field because it is "NULL" in the Contact trigger unless specifically
			// queried. Appears to ONLY be populated if you specifically query for it.
			currentBillingAccount.Zuora__BillToName__c = currentContact.FirstName + ' ' + currentContact.LastName;
		} else {
			contactFields = new List<String>(CONTACT_TO_SOLD_TO.keySet());
			contactMapping = CONTACT_TO_SOLD_TO;

			// Can't just use the dynamic "Name" formula field because it is "NULL" in the Contact trigger unless specifically
			// queried. Appears to ONLY be populated if you specifically query for it.
			currentBillingAccount.Zuora__SoldToName__c = currentContact.FirstName + ' ' + currentContact.LastName;
		}

		// Begin dynamic field mapping
		for(Integer i = 0; i < contactFields.size(); i++) {
			String currentContactField = contactFields[i];
			String currentBillingAccountField = contactMapping.get(currentContactField);
			currentBillingAccount.put(currentBillingAccountField, currentContact.get(currentContactField));
		}

		// Return the Billing Account record with populated field mappings
		return currentBillingAccount;
	}

	/**
	 *   CSP-1659 | if Contact info is updated check the ZDU_UpdateContacts__c checkbox
	 *
	 *   @author Jonathan Satterfield
	 *   @date   2017-01-10
	 *   @param  {Zuora__CustomerAccount__c}
	 *   @param  {Zuora__CustomerAccount__c}
	 */
	public static void setUpdateContactsFlagOnContactUpdate(Zuora__CustomerAccount__c newRecord, Zuora__CustomerAccount__c oldRecord) {
		if (newRecord.Zuora__BillToWorkPhone__c != oldRecord.Zuora__BillToWorkPhone__c || 
			newRecord.Zuora__BillToName__c != oldRecord.Zuora__BillToName__c ||
			newRecord.Zuora__BillToWorkEmail__c != oldRecord.Zuora__BillToWorkEmail__c ||
			newRecord.Zuora__BillToAddress1__c != oldRecord.Zuora__BillToAddress1__c ||
			newRecord.Zuora__BillToAddress2__c != oldRecord.Zuora__BillToAddress2__c ||
			newRecord.Zuora__BillToCity__c != oldRecord.Zuora__BillToCity__c ||
			newRecord.Zuora__BillToState__c != oldRecord.Zuora__BillToState__c ||
			newRecord.Zuora__BillToPostalCode__c != oldRecord.Zuora__BillToPostalCode__c ||
			newRecord.Zuora__BillToCountry__c != oldRecord.Zuora__BillToCountry__c ||
			newRecord.Zuora__SoldToName__c != oldRecord.Zuora__SoldToName__c ||
			newRecord.SoldToAddress1__c != oldRecord.SoldToAddress1__c ||
			newRecord.SoldToAddress2__c != oldRecord.SoldToAddress2__c ||
			newRecord.SoldToCity__c != oldRecord.SoldToCity__c ||
			newRecord.SoldToState__c != oldRecord.SoldToState__c ||
			newRecord.SoldToPostalCode__c != oldRecord.SoldToPostalCode__c ||
			newRecord.SoldToCountry__c != oldRecord.SoldToCountry__c) {

			newRecord.ZDU_UpdateContacts__c = true;
		}
	}

}