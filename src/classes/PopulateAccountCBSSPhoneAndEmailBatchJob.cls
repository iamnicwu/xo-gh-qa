global class PopulateAccountCBSSPhoneAndEmailBatchJob implements Database.Batchable<sObject> {
	
	String defaultCBSSPhone;
	String defaultCBSSEmail;	
	String query;
	
	global PopulateAccountCBSSPhoneAndEmailBatchJob() {

		// set default phone and email values
		this.defaultCBSSPhone = '(800) 843-4983';
		this.defaultCBSSEmail = 'theknotaccounting@xogrp.com';

		// set query value
		Map<String, Schema.RecordTypeInfo> accountRecordTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByName();
		Id accountLocalRecordTypeId = accountRecordTypeInfo.get('Local').getRecordTypeId();
		this.query = 'SELECT Id, CBSS_Email__c, CBSS_Phone__c, CBBS__c, CBBS__r.Email, CBBS__r.Phone FROM Account WHERE RecordTypeId = \'' + String.valueOf(accountLocalRecordTypeId) + '\'';
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<Account> scope) {
		for (Account accountRecord : scope) {

			// if no CBSS lookup populated, set default values (remember, the API name is misspelled as CBBS__c)
			if (String.isBlank(accountRecord.CBBS__c)) {
				accountRecord.CBSS_Email__c = this.defaultCBSSEmail;
				accountRecord.CBSS_Phone__c = this.defaultCBSSPhone;
				continue;
			}

			// otherwise, if the CBSS user has email / phone data populated, set those values (if not, use the defaults)
			accountRecord.CBSS_Email__c = String.isBlank(accountRecord.CBBS__r.Email) ? this.defaultCBSSEmail : accountRecord.CBBS__r.Email;
			accountRecord.CBSS_Phone__c = String.isBlank(accountRecord.CBBS__r.Phone) ? this.defaultCBSSPhone : accountRecord.CBBS__r.Phone;
		}

		Database.update(scope, false);
	}
	
	global void finish(Database.BatchableContext BC) {
		// nothing
	}
	
}