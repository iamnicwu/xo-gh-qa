public without sharing class ContactTriggerHandler implements XOTrigger {
	////////////////////////////
	// STATIC FINAL VARIABLES //
	////////////////////////////
	
	// Contact Relational Query to get deeper relations
	private static final String CONTACT_RELATION_QUERY = 'SELECT '
																												+	'Id, '
																												+	'Name, '
																												// Bill To Billing Account Join
																												+	'(SELECT '
																													+	'Id, '
																													+	'Name, '
																													+	'Zuora__BillToName__c, '
																													+	'Zuora__BillToWorkPhone__c, '
																													+	'Zuora__BillToWorkEmail__c, '
																													+	'Zuora__BillToAddress1__c, '
																													+	'Zuora__BillToCity__c, '
																													+	'Zuora__BillToState__c, '
																													+	'Zuora__BillToPostalCode__c, '
																													+	'Zuora__BillToCountry__c '
																												+	' FROM '
																													+	'Bill_To_Billing_Accounts__r),'
																												// Sold To Billing Account Join
																												+	'(SELECT '
																													+	'Id, '
																													+	'Name, '
																													+	'Zuora__SoldToName__c, '
																													+	'SoldToAddress1__c, '
																													+	'SoldToCity__c, '
																													+	'SoldToState__c, '
																													+	'SoldToPostalCode__c, '
																													+	'SoldToCountry__c '
																												+	' FROM '
																													+ 'Sold_To_Billing_Accounts__r)'
																											+	' FROM '
																												+	' Contact '
																											+	' WHERE '
																												+	'{WHERECLAUSE}';

	// Fields being used to check for Fulfillment needs AND if Billing Accounts need to be updated - be very careful if
	// changing this variable as it is being used in two places which have different logic but share the same fields that
	// need to be checked against.
	private static final List<String> CONTACT_UPDATE_FIELD_CHECKS = new List<String>{	'FirstName', 
																																										'LastName', 
																																										'Email', 
																																										'Phone', 
																																										'MailingStreet', 
																																										'MailingCity', 
																																										'MailingStateCode', 
																																										'MailingPostalCode', 
																																										'MailingCountry'};

	////////////////////////
	// INSTANCE VARIABLES //
	////////////////////////
	private Map<Id, Contact> relationalContactMap;

	public List<Contact> localContactList = new List<Contact>();
	private Set<Id> accountIdUpdateSet = new Set<Id>();
	private Set<Id> contactIdUpdateSet = new Set<Id>();
	public Map<Id, Id> acctIdOwnerIdMap = new Map<Id, Id>();

	// CSP-2040 | if set to true, ContactTriggerHandler logic for setting the record owner is skipped
	public static Boolean accountTriggerUpdatingContactOwners = false;

	// CSP-2041 - Billing Accounts to update, using a map to prevent duplicates
	private Map<Id, Zuora__CustomerAccount__c> billingAccountUpdateMap = new Map<Id, Zuora__CustomerAccount__c>();

	// CSP-2080 - get the local account id Set, using for check the contact is associated to a local account
	private Set<Id> localAccountSet = new Set<Id>();

	/**
	* bulkBefore
	*
	* This method is called prior to execution of a BEFORE trigger. Use this to cache
	* any data required into maps prior execution of the trigger.
	*/
	public void bulkBefore(){
		// logic for setting Contact Owner
		if (!accountTriggerUpdatingContactOwners) {
			Set<Id> accountSet = new Set<Id>();
			for(Contact record : (List<Contact>)trigger.New){
				if(String.isNotBlank(record.AccountId)){
					accountSet.add(record.AccountId);
				}
			}
			//CSP-2981 National Contact Owners 
			//Olny change Contact Owner if related Local account
			for(Account record : [SELECT Id, OwnerId FROM Account WHERE Id IN :accountSet AND RecordType.Name = 'Local']) {
				acctIdOwnerIdMap.put(record.Id, record.OwnerId);
			}
		}
	}

	/**
	* bulkAfter
	*
	* This method is called prior to execution of an AFTER trigger. Use this to cache
	* any data required into maps prior execution of the trigger.
	*/
	public void bulkAfter(){

		Set<Id> contactAccountSet = new Set<Id>();
		// Set<Id> localAccountSet = new Set<Id>();

		// implement the logic from old ContactTrigger, try to put the accountId to a set
		for(Contact record : (List<Contact>)trigger.New){
			if(String.isNotBlank(record.AccountId)){
				contactAccountSet.add(record.AccountId);
			}
		}
		
		// implement the logic from old ContactTrigger, try to retrieve the local accounts
		for(Account record : [SELECT Id FROM Account WHERE Id IN :contactAccountSet AND RecordType.Name LIKE '%Local%']){
			localAccountSet.add(record.Id);
		}

		// CSP-2041 - Query with the dynamic CONTACT_RELATION_QUERY to get RELATIONAL objects associated with Contacts
		// being updated in this transaction.
		if(Trigger.isUpdate) {
			List<Contact> contactNewList = Trigger.new;
			relationalContactMap = new Map<Id, Contact>((List<Contact>)Database.query(CONTACT_RELATION_QUERY.replace('{WHERECLAUSE}', 'Id IN :contactNewList')));
		}
	}

	/**
	* beforeInsert
	*
	* This method is called iteratively for each record to be inserted during a BEFORE
	* trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
	*/
	public void beforeInsert(SObject so){
		Contact record = (Contact)so;

		if(acctIdOwnerIdMap.containsKey(record.AccountId) && record.OwnerId != acctIdOwnerIdMap.get(record.AccountId)){
			record.OwnerId = acctIdOwnerIdMap.get(record.AccountId);
		}

		// CSP-2544 - Phone Validation
    if(String.isNotBlank(record.Phone)) {
      DataUtility.ValidationResult phoneValidation = DataUtility.formatPhoneNumber(record.Phone);
      // If the Phone is valid then put the formatted value into the Phone field
      if(phoneValidation.valid) {
        record.Phone = phoneValidation.formattedValue;
      } else {
        record.Phone.addError(System.Label.Phone_Validation_Error);
      }
    }

    // CSP-2544 - extension Validation
    if(String.isNotBlank(record.Phone_Extension__c)){
        DataUtility.ValidationResult extValidation = DataUtility.formatExt(record.Phone_Extension__c);
        // If the extension is valid then put the formatted value into the Phone field
        if(extValidation.valid) {
            record.Phone_Extension__c = extValidation.formattedValue;
        } 
        else {
            record.Phone_Extension__c.addError(System.Label.Ext_Validation_Error);
        }
    }

    // CSP-2544 - Website Validation, custom field on Contact
    if(String.isNotBlank(record.Website__c)) {
      DataUtility.ValidationResult websiteValidation = DataUtility.validateWebsite(record.Website__c);
      // If the Website is valid put the formatted value into the Website field
      if(websiteValidation.valid) {
        record.Website__c = websiteValidation.formattedValue;
      } else {
        record.Website__c.addError(System.Label.Website_Validation_Error);
      }
    }

    if(String.isNotBlank(record.MailingCountryCode) && String.isNotBlank(record.MailingPostalCode)){
        //CSP-2954: Allow Leads with incomplete (3-digit) Canadian postal codes
        //Contact must have complete zip for Canada
        if(!XOCustomValidationUtility.hasCompleteCanadianZip(record.MailingCountryCode, record.MailingPostalCode)){
            record.MailingPostalCode.addError('6-digit postal code is required for the selected Country');
        }
        if(!XOCustomValidationUtility.validZip(record.MailingCountryCode, record.MailingPostalCode)){
            record.MailingPostalCode.addError('Not a valid zip code for the selected Country');
        }
    }

    if(String.isNotBlank(record.OtherCountryCode) && String.isNotBlank(record.OtherPostalCode)){
        //CSP-2954: Allow Leads with incomplete (3-digit) Canadian postal codes
        //Contact must have complete zip for Canada
        if(!XOCustomValidationUtility.hasCompleteCanadianZip(record.OtherCountryCode, record.OtherPostalCode) ){
            record.OtherPostalCode.addError('6-digit postal code is required for the selected Country');
        }

        if(!XOCustomValidationUtility.validZip(record.OtherCountryCode, record.OtherPostalCode)){
            record.OtherPostalCode.addError('Not a valid zip code for the selected Country');
        }
    }
	}

	/**
	* beforeUpdate
	*
	* This method is called iteratively for each record to be updated during a BEFORE
	* trigger.
	*/
	public void beforeUpdate(SObject oldSo, SObject so){
		Contact newRecord = (Contact)so;
		Contact oldRecord = (Contact)oldSo;

		// CSP-2040 | ensure the Contact Owner is the same as the parent Account's Owner
		if (!accountTriggerUpdatingContactOwners && newRecord.OwnerId != oldRecord.OwnerId && acctIdOwnerIdMap.containsKey(newRecord.AccountId)) {
			newRecord.OwnerId = acctIdOwnerIdMap.get(newRecord.AccountId);
		}

		// CSP-2544 - Phone Validation
    if(String.isNotBlank(newRecord.Phone) && !newRecord.Phone.equalsIgnoreCase(oldRecord.Phone)) {
        DataUtility.ValidationResult phoneValidation = DataUtility.formatPhoneNumber(newRecord.Phone);
        // If the Phone is valid then put the formatted value into the Phone field
        if(phoneValidation.valid) {
          newRecord.Phone = phoneValidation.formattedValue;
        } else {
          newRecord.Phone.addError(System.Label.Phone_Validation_Error);
        }
    }

    // CSP-2544 - extension Validation
    if(String.isNotBlank(newRecord.Phone_Extension__c) && !newRecord.Phone_Extension__c.equalsIgnoreCase(oldRecord.Phone_Extension__c)){
        DataUtility.ValidationResult extValidation = DataUtility.formatExt(newRecord.Phone_Extension__c);
        // If the extension is valid then put the formatted value into the Phone field
        if(extValidation.valid) {
            newRecord.Phone_Extension__c = extValidation.formattedValue;
        } 
        else {
            newRecord.Phone_Extension__c.addError(System.Label.Ext_Validation_Error);
        }
    }

    // CSP-2544 - Website Validation, custom field on Contact
    if(String.isNotBlank(newRecord.Website__c) && !newRecord.Website__c.equalsIgnoreCase(oldRecord.Website__c)) {
      DataUtility.ValidationResult websiteValidation = DataUtility.validateWebsite(newRecord.Website__c);
      // If the Website is valid put the formatted value into the Website field
      if(websiteValidation.valid) {
        newRecord.Website__c = websiteValidation.formattedValue;
      } else {
        newRecord.Website__c.addError(System.Label.Website_Validation_Error);
      }
    }

    if((newRecord.MailingCountryCode != oldRecord.MailingCountryCode || newRecord.MailingPostalCode != oldRecord.MailingPostalCode) && String.isNotBlank(newRecord.MailingCountryCode) && String.isNotBlank(newRecord.MailingPostalCode)){
        //CSP-2954: Allow Leads with incomplete (3-digit) Canadian postal codes
        //Contact must have complete zip for Canada
        if(!XOCustomValidationUtility.hasCompleteCanadianZip(newRecord.MailingCountryCode, newRecord.MailingPostalCode) ){
            newRecord.MailingPostalCode.addError('6-digit postal code is required for the selected Country');
        }

        if(!XOCustomValidationUtility.validZip(newRecord.MailingCountryCode, newRecord.MailingPostalCode)){
            newRecord.MailingPostalCode.addError('Not a valid zip code for the selected Country');
        }
    }

    if((newRecord.OtherCountryCode != oldRecord.OtherCountryCode || newRecord.OtherPostalCode != oldRecord.OtherPostalCode) && String.isNotBlank(newRecord.OtherCountryCode) && String.isNotBlank(newRecord.OtherPostalCode)){
        //CSP-2954: Allow Leads with incomplete (3-digit) Canadian postal codes
        //Contact must have complete zip for Canada
        if(!XOCustomValidationUtility.hasCompleteCanadianZip(newRecord.OtherCountryCode, newRecord.OtherPostalCode) ){
            newRecord.OtherPostalCode.addError('6-digit postal code is required for the selected Country');
        }

        if(!XOCustomValidationUtility.validZip(newRecord.OtherCountryCode, newRecord.OtherPostalCode)){
            newRecord.OtherPostalCode.addError('Not a valid zip code for the selected Country');
        }
    }
	}

	/**
	* beforeDelete
	*
	* This method is called iteratively for each record to be deleted during a BEFORE
	* trigger.
	*/
	public void beforeDelete(SObject so){

	}

	/**
	* afterInsert
	*
	* This method is called iteratively for each record inserted during an AFTER
	* trigger. Always put field validation in the 'After' methods in case another trigger
	* has modified any values. The record is 'read only' by this point.
	*/
	public void afterInsert(SObject so){

	}

	/**
	* afterUpdate
	*
	* This method is called iteratively for each record updated during an AFTER
	* trigger.
	*/
	public void afterUpdate(SObject oldSo, SObject so){
		Contact currentContact = (Contact)so;
		Contact oldContact = (Contact)oldSo;

		// CSP-2041 - Begin logic to check for field updates that need to be pushed down to the Billing Account
		for(Integer i = 0; i < CONTACT_UPDATE_FIELD_CHECKS.size(); i++) {
			String currentField = CONTACT_UPDATE_FIELD_CHECKS[i];
			if(relationalContactMap.containsKey(currentContact.Id) && currentContact.get(currentField) != oldContact.get(currentField)) {
				Contact relationalContact = relationalContactMap.get(currentContact.Id);
				// Get the Associated Sold To and Bill To Billing Accounts
				// Note: This could be the exact same Billing Account since there are two lookup fields which can point to the
				// 			 same Contact but this is accounted for in the code.
				List<Zuora__CustomerAccount__c> billToBillingAccountList = relationalContact.Bill_To_Billing_Accounts__r;
				List<Zuora__CustomerAccount__c> soldToBillingAccountList = relationalContact.Sold_To_Billing_Accounts__r;

				/*
					Using a single loop to process BOTH Bill To and Sold To Billing Accounts which should reduce the processing
					time slightly. The logic below determines what the biggest loop size is and uses that as the main looping
					control. Then within the loop it ensures the loop is greater or equal to that size(Index size) before trying
					to access the array.

					A map is being used to store Billing Accounts which need to have their data updated so that duplicate values
					are not added to the a list. The "Bill To" and "Sold To" information could need to be updated at the same time
					so the map will pull Billing Account if found, update the needed information, then put it back in.

					There is a method in ZuoraBillingAccountTriggerHandler which is being utilized to map the Contact information
					into the Billing Account. This trigger does the exact same operation but only when the lookup filter changes.
				 */
				Integer biggestListSize = billToBillingAccountList.size() > soldToBillingAccountList.size() ? billToBillingAccountList.size() : soldToBillingAccountList.size();
				for(Integer j = 0; j < biggestListSize; j++) {
					if(j < soldToBillingAccountList.size()) {
						Zuora__CustomerAccount__c soldToBillingAccount = soldToBillingAccountList[j];
						if(billingAccountUpdateMap.containsKey(soldToBillingAccount.Id)) {
							soldToBillingAccount = billingAccountUpdateMap.get(soldToBillingAccount.Id);
						}

						billingAccountUpdateMap.put(soldToBillingAccount.Id, ZuoraBillingAccountTriggerHandler.mapContactToBillingAccount(currentContact, soldToBillingAccount, 'SOLD_TO'));
					}

					if(j < billToBillingAccountList.size()) {
						Zuora__CustomerAccount__c billToBillingAccount = billToBillingAccountList[j];
						if(billingAccountUpdateMap.containsKey(billToBillingAccount.Id)) {
							billToBillingAccount = billingAccountUpdateMap.get(billToBillingAccount.Id);
						}

						billingAccountUpdateMap.put(billToBillingAccount.Id, ZuoraBillingAccountTriggerHandler.mapContactToBillingAccount(currentContact, billToBillingAccount, 'BILL_TO'));
					}
				}

				// No reason to keep looping through fields
				break;
			}
		}

		// CSP-2080, move the logic of accountIdUpdateSet and contactIdUpdateSet to afterupdate from bulkafter
		if(String.isNotBlank(currentContact.AccountId) && localAccountSet.contains(currentContact.AccountId)){
			for(String field : CONTACT_UPDATE_FIELD_CHECKS){
				if(currentContact.get(field) != oldContact.get(field)){
					accountIdUpdateSet.add(currentContact.AccountId);
					contactIdUpdateSet.add(currentContact.Id);
					break;
				}
			}
		}
		
	}

	/**
	* afterDelete
	*
	* This method is called iteratively for each record deleted during an AFTER
	* trigger.
	*/
	public void afterDelete(SObject so){

	}

	/**
	* beforeAndFinally
	*
	* This method is called once all records have been processed by the trigger in the "before" context. Use this
	* method to accomplish any final operations such as creation or updates of other records.
	*/
	public void beforeAndFinally(){

	}

	/**
	* afterAndFinally
	*
	* This method is called once all records have been processed by the trigger in the "after" context. Use this
	* method to accomplish any final operations such as creation or updates of other records.
	*/
	public void afterAndFinally(){

		// implement the logic from old ContactLocalTriggerHandler
		if(!accountIdUpdateSet.isEmpty()){
			updatePartnerAccountData();
		}

		// CSP-2041 - Update the associated Billing Accounts that need their values updated
		if(!billingAccountUpdateMap.isEmpty()) {
			update billingAccountUpdateMap.values();
		}
	}

	// implement the logic from old ContactLocalTriggerHandler
	public void updatePartnerAccountData(){
		List<RESTLocalStorefrontAPI.ObjectWrapper> accountUpdateList = new List<RESTLocalStorefrontAPI.ObjectWrapper>();
		for(Account record : [SELECT Id, DynamicsAccID__c, 
									(SELECT Id, Role, ContactId
										FROM AccountContactRoles WHERE Role IN ('Primary', 'Billing Contact'))
								FROM Account WHERE Id IN : accountIdUpdateSet AND DynamicsAccID__c != null]){
			
			for(AccountContactRole childRecord : record.AccountContactRoles){
				if(contactIdUpdateSet.contains(childRecord.ContactId)){
					RESTLocalStorefrontAPI.ObjectWrapper objWrapper = new RESTLocalStorefrontAPI.ObjectWrapper();
					objWrapper.companyId = record.DynamicsAccID__c;
					objWrapper.locationId = record.DynamicsAccID__c;
					accountUpdateList.add(objWrapper);
				}
			}
		}
		if(!accountUpdateList.isEmpty()){
			PartnerAccountUpdateCallout.accountUpdateCallout(JSON.serializePretty(accountUpdateList));
		}
	}

}