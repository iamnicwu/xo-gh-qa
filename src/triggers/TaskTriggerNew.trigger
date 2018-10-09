trigger TaskTriggerNew on Task (before insert, before update, after insert, after update, before delete, after delete) {
    // List<Integer> indexList = new List<Integer>();  
    // if(trigger.isInsert){
    //     for(Integer i = 0; i < trigger.new.size(); i++){
    //         indexList.add(i);           
    //     }        
    // }    
    // TriggerFactory.createAndExecuteHandler(TaskTriggerNewHandler.class, 'Task', indexList);
}