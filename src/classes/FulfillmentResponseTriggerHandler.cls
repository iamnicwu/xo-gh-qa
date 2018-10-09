public without sharing class FulfillmentResponseTriggerHandler implements XOTrigger{

    private Set<Id> leadFulfilledIdSet = new Set<Id>();
    private Set<Id> accountFulfilledIdSet = new Set<Id>();

    public FulfillmentResponseTriggerHandler() {
        
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

    }
 
    public void beforeUpdate(SObject oldSo, SObject so){

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
        Fulfillment_Response__c record = (Fulfillment_Response__c)so;
        if(!record.Errors__c && String.isNotBlank(record.Account__c)){
            accountFulfilledIdSet.add(record.Account__c);
        }else if(!record.Errors__c && String.isNotBlank(record.Lead__c)){
            leadFulfilledIdSet.add(record.Lead__c);
        }
    }
    
    
    public void afterUpdate(SObject oldSo, SObject so){

    }
 
    public void afterDelete(SObject so){

    }

    public void beforeAndFinally(){

    }

    public void afterAndFinally(){
        if(!accountFulfilledIdSet.isEmpty()){
            List<Account> updateAccountList = new List<Account>();
            // CSP-1783 - Updated query to query for records with Fulfill_Storefront__c set to true
            for(Account record : [select Id, Fulfilled__c, Fulfill_Storefront__c FROM Account WHERE Id IN :accountFulfilledIdSet AND Fulfill_Storefront__c = TRUE]){
                record.Fulfilled__c = true;
                // CSP-1783 - New field representing the claimed status of the Account
                record.Storefront_Status__c = 'Claimed';
                // CSP-1783 - Uncheck the "Fulfil Storefront" field if it is checked. Basically resetting the field.
                record.Fulfill_Storefront__c = false;
                
                updateAccountList.add(record);
            }
            if(!updateAccountList.isEmpty()){
                try{
                    update updateAccountList;
                }catch(Exception E){
                    system.debug(E.getMessage());
                }
            }
        }
        
        if(!leadFulfilledIdSet.isEmpty()){
            List<Lead> updateLeadList = new List<Lead>();
            for(Lead record : [select Id, Fulfilled__c from Lead where Id IN : leadFulfilledIdSet and Fulfilled__c = false]){
                record.Fulfilled__c = true;
                // CSP-1783 - Uncheck the "Fulfil Storefront" field if it is checked. Basically resetting the field.
                if(record.Fulfill_Storefront__c) {
                    record.Fulfill_Storefront__c = false;
                }
                updateLeadList.add(record);
            }
            if(!updateLeadList.isEmpty()){
                try{
                    update updateLeadList;
                }catch(Exception E){
                    system.debug(E.getMessage());
                }
            }
        }
    } 
}