trigger AccountTrigger on Account (before insert, before update, after insert, after update) {
    // if(userInfo.getName() == 'Tony Liu'){
    XOTriggerFactory.createAndExecuteHandler(AccountTriggerHandler.class);
    // }else{
    //     Deactivate_Trigger__c dt = Deactivate_Trigger__c.getValues('Account');

    //     if (dt == null || (dt.Before_Insert__c && dt.Before_Update__c && dt.Before_Delete__c && dt.After_Insert__c && dt.After_Update__c && dt.After_Delete__c)) {
    //         List<Integer> localIndexList = new List<Integer>(); 
    //         if(trigger.isInsert || trigger.isUpdate){
    //             Map<Id,Schema.RecordTypeInfo> rtMapById = Schema.SObjectType.Account.getRecordTypeInfosById();
    //             Map<String, Schema.RecordTypeInfo> rtAccountMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();

    //             for(Integer i = 0; i < trigger.new.size(); i++){
    //                 Account record = trigger.new[i];

    //                 // Code used for leap mapping to ensure the correct record type is being assigned from Lead to Account
    //                 if(Trigger.isBefore && String.isNotBlank(record.Record_Type_Name__c) && rtAccountMapByName.containsKey(record.Record_Type_Name__c)) {
    //                     Schema.RecordTypeInfo currentRecordTypeSchema = rtAccountMapByName.get(record.Record_Type_Name__c);
    //                     if(Trigger.isInsert) {
    //                         record.RecordTypeId = currentRecordTypeSchema.getRecordTypeId();    
    //                     } else if(Trigger.isUpdate && record.Record_Type_Name__c != Trigger.oldMap.get(record.Id).Record_Type_Name__c) {
    //                         record.RecordTypeId = currentRecordTypeSchema.getRecordTypeId();
    //                     }
                        
    //                 }

    //                 if(rtMapById.get(record.RecordTypeId).getName().containsIgnoreCase('Local')){
    //                     localIndexList.add(i);
    //                 }
    //             }        
    //         }    
    //         TriggerFactory.createAndExecuteHandler(AccountLocalTriggerHandler.class, 'Account', localIndexList);
    //     }
    // }
}