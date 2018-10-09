public without sharing class LocalSalesRepAssignmentTriggerHandler implements XOTrigger{
  ////////////////////////////
  // STATIC FINAL VARIABLES //
  ////////////////////////////
  private static final String QUEUE_QUERY = 'SELECT '
                                              + 'Id, '
                                              + 'Queue.DeveloperName, '
                                              + 'Queue.Id '
                                            + ' FROM '
                                              + 'QueueSobject'
                                            + ' WHERE '
                                              + '{WHERECLAUSE}';

  private static Map<String, QueueSobject> queueNameMap = new Map<String, QueueSobject>();

	/**
  * bulkBefore
  *
  * This method is called prior to execution of a BEFORE trigger. Use this to cache
  * any data required into maps prior execution of the trigger.
  */
  public void bulkBefore() {
  	Set<String> queueDevNameSet = new Set<String>();

  	for(Integer i = 0; i < Trigger.new.size(); i++) {
  		if(Trigger.isInsert) {
			Local_Sales_Rep_Assignment__c currentAssignment = (Local_Sales_Rep_Assignment__c)Trigger.new[i];

			if(String.isNotBlank(currentAssignment.Lead_Distribution_Queue_Name__c)) {
  				queueDevNameSet.add(currentAssignment.Lead_Distribution_Queue_Name__c);
  			}
  		} else if(Trigger.isUpdate) {
  			Local_Sales_Rep_Assignment__c currentAssignment = (Local_Sales_Rep_Assignment__c)Trigger.new[i];
  			Local_Sales_Rep_Assignment__c oldAssignment = (Local_Sales_Rep_Assignment__c)Trigger.oldMap.get(currentAssignment.Id);

  			if(String.isNotBlank(currentAssignment.Lead_Distribution_Queue_Name__c) && currentAssignment.Lead_Distribution_Queue_Name__c != oldAssignment.Lead_Distribution_Queue_Name__c) {
  				queueDevNameSet.add(currentAssignment.Lead_Distribution_Queue_Name__c);
  			}
  		}
  	}

    	// Build queue name map using names added in records
  	if(!queueDevNameSet.isEmpty()) {
      String queueQuery = QUEUE_QUERY.replace('{WHERECLAUSE}', 'SObjectType = \'Lead\' AND Queue.DeveloperName IN :queueDevNameSet');
  		List<QueueSobject> queueList = Database.query(queueQuery);

      for(Integer i = 0; i < queueList.size(); i++) {
        QueueSobject currentQueue = queueList[i];
        if(queueNameMap.containsKey(currentQueue.Queue.DeveloperName)) {
            continue;
        }

        queueNameMap.put(currentQueue.Queue.DeveloperName, currentQueue);
      }
	  }
  }

  public void bulkAfter(){

  }   
    
  public void beforeInsert(SObject so){
  	Local_Sales_Rep_Assignment__c currentRecord = (Local_Sales_Rep_Assignment__c)so;

    // CSP-2448
    if(String.isNotBlank(currentRecord.Lead_Distribution_Queue_Name__c)) {
      if(queueNameMap.containsKey(currentRecord.Lead_Distribution_Queue_Name__c)) {
        QueueSobject currentQueue = queueNameMap.get(currentRecord.Lead_Distribution_Queue_Name__c);
        currentRecord.Lead_Distribution_Queue_Id__c = currentQueue.Queue.Id;
      } else {
        currentRecord.Lead_Distribution_Queue_Name__c.addError('The Lead Distribution Queue Name \'' + currentRecord.Lead_Distribution_Queue_Name__c + '\' is not a valid queue name.');
      }
    }
  }
 
  public void beforeUpdate(SObject oldSo, SObject so){
    Local_Sales_Rep_Assignment__c currentRecord = (Local_Sales_Rep_Assignment__c)so;
    Local_Sales_Rep_Assignment__c oldRecord = (Local_Sales_Rep_Assignment__c)oldSo;

    // CSP-2448
    if(String.isNotBlank(currentRecord.Lead_Distribution_Queue_Name__c) && currentRecord.Lead_Distribution_Queue_Name__c != oldRecord.Lead_Distribution_Queue_Name__c) {
      if(queueNameMap.containsKey(currentRecord.Lead_Distribution_Queue_Name__c)) {
        QueueSobject currentQueue = queueNameMap.get(currentRecord.Lead_Distribution_Queue_Name__c);
        currentRecord.Lead_Distribution_Queue_Id__c = currentQueue.Queue.Id;
      } else {
        currentRecord.Lead_Distribution_Queue_Name__c.addError('The Lead Distribution Queue Name \'' + currentRecord.Lead_Distribution_Queue_Name__c + '\' is not a valid queue name.');
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

  public void afterandfinally(){

  }
  public void beforeandfinally(){

  }

  public void afterInsert(SObject so){

  }
	
	
  public void afterUpdate(SObject oldSo, SObject so){

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

  }
}