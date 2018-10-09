trigger PaymentMethodNewTrigger on Zuora__PaymentMethod__c (after insert, after update) {
    List<Integer> indexList = new List<Integer>(); 
    if(checkRecursive.runTwice()){
	    if(trigger.isInsert || trigger.isUpdate){
	        for(Integer i = 0; i < trigger.new.size(); i++){
	            indexList.add(i);           
	        }        
	    }    
	    // Refactor Handler with XOTriggerFactory
	    XOTriggerFactory.createAndExecuteHandler(PaymentMethodNewTriggerHandler.class);
	    // TriggerFactory.createAndExecuteHandler(PaymentMethodNewTriggerHandler.class, 'Zuora__PaymentMethod__c', indexList);
	}
}