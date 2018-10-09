trigger LeadTrigger on Lead (before insert, before update, after insert, after update) {   
  // CSP-2453 DE for Sr. Sales Executive
  // If frist time run trigger
  // CSP-2772 Multiple leads data loading issue - Urgent
  // comment out the trigger run once logic
  // if(TriggerUtility.isRunTrigger) {
   		XOTriggerFactory.createAndExecuteHandler(LeadTriggerHandler.class);   
   // }
  
}