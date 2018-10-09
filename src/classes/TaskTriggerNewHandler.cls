public without sharing class TaskTriggerNewHandler implements iTrigger{
    /**
    * Class TaskTriggerHandlerNew
    *
    * Trigger Handler for the Task SObject. This class implements the ITrigger
    * interface to help ensure the trigger code is bulkified and all in one place.
    */  
    public Map<id, Task> taskMap = new Map<id, Task>();

    // Constructor
    public TaskTriggerNewHandler(){

    }
    
    
    /**
    * bulkBefore
    *
    * This method is called prior to execution of a BEFORE trigger. Use this to cache
    * any data required into maps prior execution of the trigger.
    */
    
    public void bulkBefore(){
        // the logic had been move to TaskTriggerHandler
        // if(trigger.isInsert){
        //     for(SObject so : trigger.new){
        //         Task record = (Task)so;
        //         taskMap.put(record.ownerId, record);                
        //     }

        //     for(Out_Of_Office__c ooo : [Select id, Assign_Task_To__c, Assign_From__c, Active__c, Start_Date__c, End_Date__c From Out_Of_Office__c
        //                                     Where Assign_From__c IN : taskMap.KeySet() and Active__c = True]){
        //         Task newRecord = taskMap.get(ooo.Assign_From__c);
        //         if(ooo.Start_Date__c <= newRecord.ActivityDate && ooo.End_Date__c >= newRecord.ActivityDate){
        //             newRecord.OwnerId = ooo.Assign_Task_To__c;
        //         }
        //     }
        // }
    }
 
    public void bulkAfter(){
        if(trigger.isInsert){
            for(SObject so : trigger.new){
                Task record = (Task)so;                 
            }   
        }
    }   
    
    public void beforeInsert(SObject so){
        //TO DO: implement before insert logic here
        Task record = (Task)so;              
    }
 
    public void beforeUpdate(SObject oldSo, SObject so){
        //TO DO: implement before update logic here           
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
    }
 
    public void afterUpdate(SObject oldSo, SObject so){
        //TO DO: implement after update logic here
    }
 
    public void afterDelete(SObject so){
        //TO DO: implement after delete logic here
    }   
    
    /**
    * andFinally
    *
    * This method is called once all records have been processed by the trigger. Use this
    * method to accomplish any final operations such as creation or updates of other records.
    */
    
    
    public void andFinally(){
        //TO DO: Final Actions
    }  
}