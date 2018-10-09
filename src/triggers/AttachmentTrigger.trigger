/* 
<trigger>
  <name>AttachmentTrigger</name>
  <purpose>For handling save/update and delete events on an Attachment</purpose>
  <created>
    <by>Harikrishnan Mohan</by>
    <date>8/7/2015</date>
    <ticket>SF-791</ticket>
  </created>
</trigger>
*/
trigger AttachmentTrigger on Attachment (before insert, before update, before delete, 
                                            after insert, after update, after delete, after undelete) {    
    
    Deactivate_Trigger__c dt = Deactivate_Trigger__c.getValues('Attachment');

    System.debug('********************'+dt);
    
    //before insert
    if(Trigger.isBefore && Trigger.isInsert && (dt.Before_Insert__c <> null)){
        //before insert logic goes here
    }    
    
    // before update
    else if(Trigger.isBefore && Trigger.isUpdate && dt.Before_Update__c){
        AttachmentTriggerHanlder.modifyAttachments(Trigger.new);
    }
    
    //before delete
    else if(Trigger.isBefore && Trigger.isDelete && dt.Before_Delete__c){
        AttachmentTriggerHanlder.modifyAttachments(Trigger.old);
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