/* 
<trigger>
  <name>NotesTrigger</name>
  <purpose>For handling save/update and delete events on an Notes</purpose>
  <created>
    <by>Harikrishnan Mohan</by>
    <date>8/7/2015</date>
    <ticket>SF-791</ticket>
  </created>
</trigger>
*/
/*
trigger NotesTrigger on Note (before insert, before update, after insert, after update, before delete, after delete) {

    Map<Id,Schema.RecordTypeInfo> rtMapById = Schema.SObjectType.Opportunity.getRecordTypeInfosById();

    List<Integer> businessLineIndexList = new List<Integer>();
    
    if(trigger.isInsert || trigger.isUpdate){
        for(Integer i = 0; i < trigger.new.size(); i++){
            Note record = trigger.new[i];
            businessLineIndexList.add(i);            
        }
    }else if(trigger.isDelete){
        for(Integer i = 0; i < trigger.old.size(); i++){
            Note record = trigger.old[i];
            businessLineIndexList.add(i);
        }
    }

    if(!businessLineIndexList.isEmpty()){
        TriggerFactory.createAndExecuteHandler(NotesTriggerHandler.class, 'Note', businessLineIndexList.size());
    }    
}
*/

trigger NotesTrigger on Note (before insert, before update, before delete, 
                                after insert, after update, after delete, after undelete) {

    Deactivate_Trigger__c dt = Deactivate_Trigger__c.getValues('Note');

    //before insert
    if(Trigger.isBefore && Trigger.isInsert && dt.Before_Insert__c){
        //before insert logic goes here
    }
    
    // before update
    else if(Trigger.isBefore && Trigger.isUpdate && dt.Before_Update__c){
        //NotesTriggerHandler.modifyNotes(Trigger.new);
    }

    //before delete
    else if(Trigger.isBefore && Trigger.isDelete && dt.Before_Delete__c){
        //NotesTriggerHandler.modifyNotes(Trigger.old);
        XOTriggerFactory.createAndExecuteHandler(NotesTriggerHandler.class);
    }

    //after insert
    else if(Trigger.isAfter && Trigger.isInsert && dt.After_Insert__c){
        //after insert logic goes here
    }
    
    // after update
    else if(Trigger.isAfter && Trigger.isUpdate && dt.After_Update__c){
        //after update logic goes here
    }
    
    //after delete
    else if(Trigger.isAfter && Trigger.isDelete && dt.After_Delete__c){
        //after delete logic goes here
    }

    else if(Trigger.isUnDelete){
      //undelete logic goes here
    }

}