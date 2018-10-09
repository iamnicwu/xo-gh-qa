/**
* Class XOTriggerFactory
*
* Used to instantiate and execute Trigger Handlers associated with sObjects.
*/
global with sharing class XOTriggerFactory { 
  /**
   * Public static method to create and execute a trigger handler
   *
   * Arguments:   Type t - Type of handler to instantiate
   *
   * Throws a TriggerException if no handler has been found.
   */
  global static void createAndExecuteHandler(Type t) {
    //Don't allow null Types
    if (t == null) {
      throw new TriggerException('Why are you trying to hand me a null Type/Class, dingbat?');
    }
    
    // Get a handler appropriate to the object being processed
    XOTrigger handler = getHandler(t);
    String className = t.getName();
    String hashName = String.valueof(t.hashCode());

    Boolean executeTriggerHandler = true;
    
    String objectName;
    //Get objectName by current Trigger.old or Trigger.new
    if(Trigger.old != null && Trigger.old.size() > 0) {
      objectName = Trigger.old[0].getSObjectType().getDescribe().getName();
    } else if(Trigger.new != null && Trigger.new.size() > 0) {
      objectName = Trigger.new[0].getSObjectType().getDescribe().getName();
    } else {
      //throw potential error.
      throw new TriggerException('Invalid Trigger Object');
    }


    // Make sure we have a handler registered, new handlers must be registered in the getHandler method.
    if (handler == null) {
      throw new TriggerException('No Trigger Handler found named: ' + className);
    }
    

    String handlerName = t.getName();
    if(handlerName.length() > 38) {
      handlerName = handlerName.left(38);
    }

    TriggerHandlerAccess__c triggerHandler = TriggerHandlerAccess__c.getInstance(handlerName);

    // Add trigger handler if there is no custom setting for the provided handler.         
    if(triggerHandler == null){
        // Create the Custom Setting record for turning on and turning off triggers
        TriggerHandlerAccess__c newTHA = new TriggerHandlerAccess__c();
        newTHA.Name = handlerName;
        newTHA.Active__c = true;
        newTHA.Handler_Name__c = handlerName;
        newTHA.Object__c = objectName;
        insert newTHA;
        //Make sure triggerHandler is not null.
        triggerHandler = newTHA;
    }  

    /*
     * DISABLE_TRIGGERS turn off all triggers functionality
     * DISABLED_OBJECT_TRIGGERS turn off specific triggers functionality by 
     * setting the DISABLED_OBJECT_TRIGGERS
     */
    if(TestClassUtility.DISABLE_TRIGGERS){
      if(TestClassUtility.DISABLED_OBJECT_TRIGGERS == null){
        executeTriggerHandler = false;
      }else if (TestClassUtility.DISABLED_OBJECT_TRIGGERS.Contains(objectName)) {
        executeTriggerHandler = false;
      }
    }else if(!triggerHandler.Active__c){
        executeTriggerHandler = false;      
    }

    if(executeTriggerHandler){
      // Execute the handler to fulfil the trigger
      execute(handler);
    }
    
  }

  /**
   * private static method to control the execution of the handler
   *
   * Arguments:   XOTrigger handler - A Trigger Handler to execute
   */
  private static void execute(XOTrigger handler) {
    // Before Trigger
    if (Trigger.isBefore) {
      // Call the bulk before to handle any caching of data and enable bulkification
      handler.bulkBefore();

      // Iterate through the records to be deleted passing them to the handler.
      if (Trigger.isDelete) {
        for (Integer i = 0; i < Trigger.old.size(); i++) {
          handler.beforeDelete(Trigger.old[i]);
        }
      }
      // Iterate through the records to be inserted passing them to the handler.
      else if (Trigger.isInsert) {
        for (Integer i = 0; i < Trigger.new.size(); i++) {
          handler.beforeInsert(Trigger.new[i]);
        }
      }
      // Iterate through the records to be updated passing them to the handler.
      else if (Trigger.isUpdate) {
        for (Integer i = 0; i < Trigger.old.size(); i++) {
          handler.beforeUpdate(Trigger.old[i], Trigger.newMap.get(Trigger.old[i].Id));
        }
      }
      // Perform any post processing
      handler.beforeAndFinally();
    } else {
      // Call the bulk after to handle any caching of data and enable bulkification
      handler.bulkAfter();

      // Iterate through the records deleted passing them to the handler.
      if (Trigger.isDelete) {
        for (Integer i = 0; i < Trigger.old.size(); i++) {
          handler.afterDelete(Trigger.old[i]);
        }
      }
      // Iterate through the records inserted passing them to the handler.
      else if (Trigger.isInsert) {
        for (Integer i = 0; i < Trigger.new.size(); i++) {
          handler.afterInsert(Trigger.new[i]);
        }
      }
      // Iterate through the records updated passing them to the handler.
      else if (Trigger.isUpdate) {
        for (Integer i = 0; i < Trigger.old.size(); i++) {
          handler.afterUpdate(Trigger.old[i], Trigger.newMap.get(Trigger.old[i].Id));
        }
      }
      
      // Perform any post processing after trigger
      handler.afterAndFinally();        
    }
  }

  /**
   * private static method to get the named handler.
   *
   * Arguments:   Type t - Class of handler to instatiate
   *
   * Returns:     XOTrigger - A trigger handler if one exists or null.
   */
  private static XOTrigger getHandler(Type t) {
    // Instantiate the type
    Object o = t.newInstance();

    // if its not an instance of XOTrigger return null
    if (!(o instanceOf XOTrigger)) {
      return null;
    }

    return (XOTrigger)o;
  }

  public class TriggerException extends Exception {}
}