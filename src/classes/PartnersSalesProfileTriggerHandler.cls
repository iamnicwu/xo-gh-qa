public without sharing class PartnersSalesProfileTriggerHandler implements XOTrigger{

	private Set<Id> acctWithFreemium = new Set<Id>();
	private Set<Id> acctRemoveFreemium = new Set<Id>();

	private List<Account> updateAccountList = new List<Account>();

	public PartnersSalesProfileTriggerHandler() {

	}

	/**
    * bulkBefore
    *
    * This method is called prior to execution of a BEFORE trigger. Use this to cache
    * any data required into maps prior execution of the trigger.
    */
    
    public void bulkBefore(){

    }

    public void bulkAfter(){

    }   
    
    public void beforeInsert(SObject so){
    	Partners_SalesProfile__c record = (Partners_SalesProfile__c)so;

    }
 
    public void beforeUpdate(SObject oldSo, SObject so){
    	Partners_SalesProfile__c record = (Partners_SalesProfile__c)so;
    	Partners_SalesProfile__c oldRecord = (Partners_SalesProfile__c)oldSo;

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
        Partners_SalesProfile__c record = (Partners_SalesProfile__c)so;
        if(record.Tier__c == 'Freemium'){
        	acctWithFreemium.add(record.Location__c);
        }
    }
 	
 	
    public void afterUpdate(SObject oldSo, SObject so){
        Partners_SalesProfile__c record = (Partners_SalesProfile__c)so;
        Partners_SalesProfile__c oldRecord = (Partners_SalesProfile__c)oldSo;
        if(record.Tier__c != oldRecord.Tier__c && record.Tier__c == 'Freemium'){
        	acctWithFreemium.add(record.Location__c);
        }else if(record.Tier__c != oldRecord.Tier__c && record.Tier__c != 'Freemium'){
        	acctRemoveFreemium.add(record.Location__c);
        }
    }
 
    public void afterDelete(SObject so){

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
		acctRemoveFreemium.removeAll(acctWithFreemium);

    	if(!acctWithFreemium.isEmpty()){
    		accountFreemiumUpdate();
    	}

    	if(!acctRemoveFreemium.isEmpty()){
    		accountNoFreemiumUpdate();
    	}

    	if(!updateAccountList.isEmpty()){
    		update updateAccountList;
    	}
    }
	
    private void accountFreemiumUpdate(){
    	for(Account record : [select Id, ProductType__c, ParentId, Parent.ProductType__c, (select Id, Tier__c from Partners_SalesProfiles__r) from Account where Id IN : acctWithFreemium]){
    		if(String.isNotBlank(record.ProductType__c) && !record.ProductType__c.contains('Freemium')){
    			record.ProductType__c += ';Freemium';
    			updateAccountList.add(record);
    		}else if(String.isBlank(record.ProductType__c)){
    			record.ProductType__c = 'Freemium';
    			updateAccountList.add(record);
    		}

    		if(String.isNotBlank(record.ParentId) && String.isNotBlank(record.Parent.ProductType__c) && !record.Parent.ProductType__c.contains('Freemium')){
    			record.Parent.ProductType__c += ';Freemium';
    			updateAccountList.add(record.Parent);
    		}else if(String.isNotBlank(record.ParentId) && String.isBlank(record.Parent.ProductType__c)){
    			record.Parent.ProductType__c = 'Freemium';
    			updateAccountList.add(record.Parent);
    		}
    	}
    }

    private void accountNoFreemiumUpdate(){
    	Set<Id> parentAccountIdSet = new Set<Id>();
    	for(Account record : [select Id, ProductType__c, ParentId, (select Id, Tier__c from Partners_SalesProfiles__r) from Account where Id IN : acctRemoveFreemium]){
    		Boolean hasFreemium = false;
    		for(Partners_SalesProfile__c childRecord : record.Partners_SalesProfiles__r){
    			if(childRecord.Tier__c == 'Freemium'){
    				hasFreemium = true;
    				break;
    			}
    		}
    		if(hasFreemium){
    			if(String.isNotBlank(record.ProductType__c) && !record.ProductType__c.contains('Freemium')){
    				record.ProductType__c += ';Freemium';
    				updateAccountList.add(record);
    			}else if(String.isBlank(record.ProductType__c)){
    				record.ProductType__c = 'Freemium';
    				updateAccountList.add(record);
    			}
    		}else if(!hasFreemium){
    			if(String.isNotBlank(record.ProductType__c) && record.ProductType__c.contains('Freemium')){
    				record.ProductType__c = record.ProductType__c.remove('Freemium');
    				updateAccountList.add(record);
    			}
    		}
    	}
    }

}