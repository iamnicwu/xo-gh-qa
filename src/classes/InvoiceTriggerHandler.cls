/**
 * Class TaskTriggerHandlerNew
 *
 * Trigger Handler for the Zuora__ZInvoice__c SObject. This class implements the XOTrigger
 * interface to help ensure the trigger code is bulkified and all in one place.
 */ 
public without sharing class InvoiceTriggerHandler implements XOTrigger {
	//private Set<String> accountIdSet = new Set<String>();

    // CSP_2704 Calculating Potential for In House Collections and Past Due Retention Cases
    // store the account and the total amount which the cancel case should updated
    private Map<Id,Decimal> negativeAccIdAmoutMap = new Map<Id,Decimal>();
    // Constructor
    public InvoiceTriggerHandler(){

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
    	Zuora__ZInvoice__c invObj = (Zuora__ZInvoice__c) so;
        updatePromiseToPayField(invObj, null);
    }
 
    public void beforeUpdate(SObject oldSo, SObject so){
        //TO DO: implement before update logic here 
        Zuora__ZInvoice__c newInvObj = (Zuora__ZInvoice__c) so;
       	Zuora__ZInvoice__c oldInvObj = (Zuora__ZInvoice__c) oldSo;
        updatePromiseToPayField(newInvObj, oldInvObj);          
    }
    
    /**
    * beforeDelete
    *
    * This method is called iteratively for each record to be deleted during a BEFORE
    * trigger.
    */
    public void beforeDelete(SObject so){
        //TO DO: implement before delete logic here
    }
 
    public void afterInsert(SObject so){
        //TO DO: implement after insert logic here 
        Zuora__ZInvoice__c invObj = (Zuora__ZInvoice__c) so;
        /*Functionality is Reverted.
        if(invObj.Zuora__Account__c != null && invObj.Promise_to_Pay_Date__c != null){
        	accountIdSet.add(invObj.Zuora__Account__c);
        	
        }     */        

        // CSP_2704 Calculating Potential for In House Collections and Past Due Retention Cases
        // if the amount of the invoice is less than 0, we should updated the cancel case closed in 7 days
        if (invObj.Zuora__TotalAmount__c < 0 ) {
            if (negativeAccIdAmoutMap.containsKey(invObj.Zuora__Account__c)) {
                negativeAccIdAmoutMap.put(invObj.Zuora__Account__c, negativeAccIdAmoutMap.get(invObj.Zuora__Account__c) + invObj.Zuora__TotalAmount__c);
            }else{
                negativeAccIdAmoutMap.put(invObj.Zuora__Account__c, invObj.Zuora__TotalAmount__c);
            }
        }
    }
 
    public void afterUpdate(SObject oldSo, SObject so){
        //TO DO: implement after update logic here
       	Zuora__ZInvoice__c newInvObj = (Zuora__ZInvoice__c) so;
       	Zuora__ZInvoice__c oldInvObj = (Zuora__ZInvoice__c) oldSo; 
       	/*Functionality is Reverted.
       	if(newInvObj.Zuora__Account__c != oldInvObj.Zuora__Account__c 
       			|| newInvObj.Promise_to_Pay_Date__c != oldInvObj.Promise_to_Pay_Date__c
       			|| newInvObj.Zuora__Balance2__c != oldInvObj.Zuora__Balance2__c
       		){
        	accountIdSet.add(newInvObj.Zuora__Account__c);
        	accountIdSet.add(oldInvObj.Zuora__Account__c);
        } */     
    }
 
    public void afterDelete(SObject so){
        //TO DO: implement after delete logic here
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
    public void afterAndFinally(){
        //TO DO: Final Actions
        /* Functionality is Reverted.
        if(accountIdSet.size() > 0){
        	List<Account> accUpdateList = updateAccount(accountIdSet);
        	
        	if(accUpdateList.size() > 0){
        		update accUpdateList;
        	}
        }*/

        // CSP_2704 Calculating Potential for In House Collections and Past Due Retention Cases
        // if the amount of the invoice is less than 0, we should updated the cancel case closed in 7 days
        if (!negativeAccIdAmoutMap.isEmpty()) {
            List<Case> caseList = [SELECT id,Past_Due_Potential_Collections__c, PDPC_Date_Time_Stamp__c, Negative_Invoice_Value__c,AccountId 
                                    FROM Case WHERE AccountId in: negativeAccIdAmoutMap.keySet() 
                                        AND ClosedDate >: system.now().adddays(-7) 
                                        AND RecordType.Name = '1 - Cancels'];

            if (!caseList.isEmpty()) {
                List<Case> updateCaseList = new List<Case>();
                for (Case currentCase : caseList) {
                    if (negativeAccIdAmoutMap.containsKey(currentCase.AccountId)) {

                        Decimal pdpc = currentCase.Past_Due_Potential_Collections__c == null? 0 : currentCase.Past_Due_Potential_Collections__c; 
                        currentCase.Past_Due_Potential_Collections__c = pdpc + negativeAccIdAmoutMap.get(currentCase.AccountId);
                        currentCase.PDPC_Date_Time_Stamp__c = system.now();
                        currentCase.Negative_Invoice_Value__c = negativeAccIdAmoutMap.get(currentCase.AccountId);
                        updateCaseList.add(currentCase);
                    }
                } 

                if (!updateCaseList.isEmpty()) {

                    List<Database.SaveResult> saveResults = Database.update(updateCaseList,false);
                    List<XO_Exception__c> xoExceptionList = ExceptionUtility.consumeException(saveResults);

                    if(!xoExceptionList.isEmpty()){
                        insert xoExceptionList;
                    }
                }
            }
        }
       
    }
    
    /**
     *@description: Search if account has any "Promise to Pay" invoice where balance is also due, 
     *				update the related account "Customer on Payment Arrangement" field.
     *				Note: CSP-1302 :Functionality is Reverted.
     *
    public List<Account> updateAccount(Set<String> accountIdSet){
    	List<Account> accUpdateList = new List<Account>();
    	
    	List<Account> accList = [SELECT Id, Name, Customer_on_Payment_Arrangement__c, 
    								(SELECT Zuora__Balance2__c, Promise_to_Pay_Date__c FROM Zuora__Invoices__r
    								WHERE Zuora__Balance2__c > 0 AND Promise_to_Pay_Date__c != null)	
    							 FROM Account WHERE Id IN : accountIdSet];
    							 
    	for(Account accObj : accList){
    		if(accObj.Customer_on_Payment_Arrangement__c && (accObj.Zuora__Invoices__r == null || accObj.Zuora__Invoices__r.size() == 0)){
    			accObj.Customer_on_Payment_Arrangement__c = false;
    			accUpdateList.add(accObj);
    		}else if(!accObj.Customer_on_Payment_Arrangement__c && (accObj.Zuora__Invoices__r != null && accObj.Zuora__Invoices__r.size() > 0)){
    			accObj.Customer_on_Payment_Arrangement__c = true;
    			accUpdateList.add(accObj);
    		}
    	}
    	return accUpdateList;
    }*/
    
    /**
     *@description: if invoice balance is zero or null, update related field to null.
     *				Note: CSP-1302
     */
    private void updatePromiseToPayField(Zuora__ZInvoice__c newInvObj, Zuora__ZInvoice__c oldInvObj){
    	if((oldInvObj == null || (oldInvObj.Zuora__Balance2__c != null && oldInvObj.Zuora__Balance2__c != 0)) 
    			&& (newInvObj.Zuora__Balance2__c == null || newInvObj.Zuora__Balance2__c == 0)){
        	newInvObj.Promise_To_Pay_Amount__c = newInvObj.Zuora__Balance2__c;
        	newInvObj.Promise_to_Pay_Date__c = null;        	
        }
        
        if(newInvObj.Promise_to_Pay_Date__c != null){
        	newInvObj.Promise_To_Pay_Amount__c = newInvObj.Zuora__Balance2__c;
        	Date promiseToPayDate = newInvObj.Promise_to_Pay_Date__c;
        	//Promise To Pay Date can't be past date or today date.
        	newInvObj.Promise_to_Pay_Date__c = promiseToPayDate <= Date.today() ? Date.today().addDays(1) : promiseToPayDate;
        }
        
    }
      
}