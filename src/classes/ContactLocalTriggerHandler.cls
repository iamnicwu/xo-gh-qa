public with sharing class ContactLocalTriggerHandler implements iTrigger{

    private List<String> fulfillmentFieldContactChangeValidateList = new List<String>{'FirstName', 'LastName', 'Email', 'Phone', 'MailingStreet', 'MailingCity', 'MailingStateCode', 'MailingPostalCode', 'MailingCountry'};
    private Set<Id> accountIdUpdateSet = new Set<Id>();
    private Set<Id> contactIdUpdateSet = new Set<Id>();

    // SF-2268; maps contacts to a list of open opportunities where that contact is the contract signer
    private Map<Id, List<Opportunity>> contactIdToOpenOppsWhereContractSigner = new Map<Id, List<Opportunity>>();

	public ContactLocalTriggerHandler() {
		
	}

	/**
    * bulkBefore
    *
    * This method is called prior to execution of a BEFORE trigger. Use this to cache
    * any data required into maps prior execution of the trigger.
    */
    
    public void bulkBefore(){
    	// SF-2268
    	Set<Id> conIdSet = new Set<Id>();
    	if (Trigger.isUpdate) {
    		for(sObject con : Trigger.new){
    			Contact newCon = (Contact)con;
   				Contact oldCon = (Contact)Trigger.oldMap.get(newCon.Id);
   				if (String.isBlank(newCon.Email) && !String.isBlank(oldCon.Email)) {
   					conIdSet.add(newCon.Id);
   				}
   			}
   			
   			List<Id> conIdList = new List<Id>();
   			conIdList.addAll(conIdSet);
   			
   			if (conIdList.size() > 0) {
   				for (Opportunity openOpp : [SELECT Id, Contract_Signer__c, StageName FROM Opportunity WHERE Contract_Signer__c IN :conIdList AND StageName != 'Closed Won' AND StageName != 'Closed Lost']) {
   					List<Opportunity> openOppList;
   					if (contactIdToOpenOppsWhereContractSigner.containsKey(openOpp.Contract_Signer__c)) {
   						openOppList = contactIdToOpenOppsWhereContractSigner.get(openOpp.Contract_Signer__c);
   					}
   					else {
   						openOppList = new List<Opportunity>();
   					}
   					openOppList.add(openOpp);
   					contactIdToOpenOppsWhereContractSigner.put(openOpp.Contract_Signer__c, openOppList);
   				}
   			}
    	}  
    }

    public void bulkAfter(){
    	if(trigger.isUpdate){

    	}
    }   
    
    public void beforeInsert(SObject so){
    	Contact record = (Contact)so;

        if(String.isNotBlank(record.MailingCountryCode) && String.isNotBlank(record.MailingPostalCode)){
            
            if(!XOCustomValidationUtility.validZip(record.MailingCountryCode, record.MailingPostalCode)){
                record.MailingPostalCode.addError('Not a valid zip code for the selected Country');
            }
        }

        if(String.isNotBlank(record.OtherCountryCode) && String.isNotBlank(record.OtherPostalCode)){

            if(!XOCustomValidationUtility.validZip(record.OtherCountryCode, record.OtherPostalCode)){
                record.OtherPostalCode.addError('Not a valid zip code for the selected Country');
            }
        }
    }
 
    public void beforeUpdate(SObject oldSo, SObject so){
        Contact record = (Contact)so;
        Contact oldRecord = (Contact)oldSo;

        if((record.MailingCountryCode != oldRecord.MailingCountryCode || record.MailingPostalCode != oldRecord.MailingPostalCode) && String.isNotBlank(record.MailingCountryCode) && String.isNotBlank(record.MailingPostalCode)){

            if(!XOCustomValidationUtility.validZip(record.MailingCountryCode, record.MailingPostalCode)){
                record.MailingPostalCode.addError('Not a valid zip code for the selected Country');
            }
        }

        if((record.OtherCountryCode != oldRecord.OtherCountryCode || record.OtherPostalCode != oldRecord.OtherPostalCode) && String.isNotBlank(record.OtherCountryCode) && String.isNotBlank(record.OtherPostalCode)){

            if(!XOCustomValidationUtility.validZip(record.OtherCountryCode, record.OtherPostalCode)){
                record.OtherPostalCode.addError('Not a valid zip code for the selected Country');
            }
        }

        // SF-2268
        if (contactIdToOpenOppsWhereContractSigner.containsKey(record.Id)) {
        	// if desired, we can list the specific Opportunities where the contact is the designated Contract Signer
        	// in the error message, but for now just going to leave it generic
        	record.Email.addError('Cannot remove email address on a Contact who is the Contract Signer for an open Opportunity');
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
 
    public void afterInsert(SObject so){
        Contact record = (Contact)so;

    }
 	
 	
    public void afterUpdate(SObject oldSo, SObject so){
        Contact record = (Contact)so;
        Contact oldRecord = (Contact)oldSo;

        if(String.isNotBlank(record.AccountId)){
	        for(String field : fulfillmentFieldContactChangeValidateList){
	            if(record.get(field) != oldRecord.get(field)){
	                accountIdUpdateSet.add(record.AccountId);
	                contactIdUpdateSet.add(record.Id);
	                break;
	            }
	        }
	    }
    }
 
    public void afterDelete(SObject so){

    }   
    
    /**
    * andFinally
    *
    * This method is called once all records have been processed by the trigger. Use this
    * method to accomplish any final operations such as creation or updates of other records.
    */
    
    
    public void andFinally(){
    	if(!accountIdUpdateSet.isEmpty()){
    		updatePartnerAccountData();
    	}
    }

    public void updatePartnerAccountData(){
    	List<RESTLocalStorefrontAPI.ObjectWrapper> accountUpdateList = new List<RESTLocalStorefrontAPI.ObjectWrapper>();
    	for(Account record : [select Id, DynamicsAccID__c, 
    								(select Id, Role, ContactId
										from AccountContactRoles where Role IN ('Primary', 'Billing Contact'))
								from Account where Id IN : accountIdUpdateSet and DynamicsAccID__c != null]){
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