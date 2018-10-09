/**
 * Class TriggerFactory
 *
 * Used to instantiate and execute Trigger Handlers associated with sObjects.
 */
public without sharing class TriggerFactory{
    /**
     * Public static method to create and execute a trigger handler
     *
     * Arguments:   Type t - Type of handler to instatiate
     *
     * Throws a TriggerException if no handler has been found.
     */
    public static void createAndExecuteHandler(Type t, String objectName, List<Integer> indexList){
        // Get a handler appropriate to the object being processed
        ITrigger handler = getHandler(t);
        
        // Make sure we have a handler registered, new handlers must be registered in the getHandler method.
        if (handler == null){
            throw new TriggerException('No Trigger Handler found named: ' + t.getName());
        }

        if(TriggerHandlerAccess__c.getValues(t.getName().left(38)) == null){
          // Create the Custom Setting record for turning on and turning off triggers
          TriggerHandlerAccess__c newTHA = new TriggerHandlerAccess__c();
          newTHA.Name = t.getName().left(38);
          newTHA.Active__c = true;
          newTHA.Handler_Name__c = t.getName();
          newTHA.Object__c = objectName;
          insert newTHA;
        }

        if(TriggerHandlerAccess__c.getValues(t.getName().left(38)).Active__c){
          // Execute the handler to fulfil the trigger
          execute(handler, indexList);
        }
    }

    /**
     * private static method to control the execution of the handler
     *
     * Arguments:   ITrigger handler - A Trigger Handler to execute
     */
    private static void execute(ITrigger handler, List<Integer> indexList){
        // Before Trigger
        if (Trigger.isBefore){
            // Call the bulk before to handle any caching of data and enable bulkification
            handler.bulkBefore();
 
            // Iterate through the records to be deleted passing them to the handler.
            if (Trigger.isDelete){
                if(indexList != null){
                    for (Integer i = 0; i < indexList.size(); i++){
                        handler.beforeDelete(trigger.old[indexList[i]]);
                    }
                }else{
                    for(SObject record : trigger.old){
                        handler.beforeDelete(record);
                    }
                }
            }
            // Iterate through the records to be inserted passing them to the handler.
            else if (Trigger.isInsert){
                if(indexList != null){
                    for (Integer i = 0; i < indexList.size(); i++){
                        handler.beforeInsert(trigger.new[indexList[i]]);
                    }
                }else{
                    for(SObject record : trigger.new){
                        handler.beforeInsert(record);
                    }
                }
            }
            // Iterate through the records to be updated passing them to the handler.
            else if (Trigger.isUpdate){
                if(indexList != null){
                    for (Integer i = 0; i < indexList.size(); i++){
                        handler.beforeUpdate(trigger.old[indexList[i]], trigger.new[indexList[i]]);
                    }
                }else{
                    for(SObject record : trigger.new){
                        handler.beforeUpdate(trigger.oldMap.get(record.Id), record);
                    }
                }
            }
        }else{
            // Call the bulk after to handle any caching of data and enable bulkification
            handler.bulkAfter();
 
            // Iterate through the records deleted passing them to the handler.
            if (Trigger.isDelete){
                if(indexList != null){
                    for (Integer i = 0; i < indexList.size(); i++){
                        handler.afterDelete(trigger.old[indexList[i]]);
                    }
                }else{
                    for(SObject record : trigger.old){
                        handler.afterDelete(record);
                    }
                }
            }
            // Iterate through the records inserted passing them to the handler.
            else if (Trigger.isInsert){
                if(indexList != null){
                    for (Integer i = 0; i < indexList.size(); i++){
                        handler.afterInsert(trigger.new[indexList[i]]);
                    }
                }else{
                    for(SObject record : trigger.new){
                        handler.afterInsert(record);
                    }
                }
            }
            // Iterate through the records updated passing them to the handler.
            else if (Trigger.isUpdate){
                if(indexList != null){
                    for (Integer i = 0; i < indexList.size(); i++){
                        handler.afterUpdate(trigger.old[indexList[i]], trigger.new[indexList[i]]);
                    }
                }else{
                    for(SObject record : trigger.new){
                        handler.afterUpdate(trigger.oldMap.get(record.Id), record);
                    }
                }
            }
        }
        
        // Perform any post processing
        handler.andFinally();
    }

    /**
     * private static method to get the named handler.
     *
     * Arguments:   Type t - Class of handler to instatiate
     *
     * Returns:     ITrigger - A trigger handler if one exists or null.
     */
    private static ITrigger getHandler(Type t){
        // Instantiate the type
        Object o = t.newInstance();

        // if its not an instance of ITrigger return null
        if (!(o instanceOf ITrigger)){
            return null;
        }

        return (ITrigger)o;
    }

    public class TriggerException extends Exception {}
}