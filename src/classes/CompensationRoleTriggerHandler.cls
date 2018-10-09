public without sharing class CompensationRoleTriggerHandler implements XOTrigger {

    // CSP-2925 Compensation Roles - Set up Custom Object
    private Map<Id,List<Compensation_Role__c>> repIdCompRoleListMap = new Map<Id,List<Compensation_Role__c>>();
    //Use label to control date Overlap is validate or not 
    private String isValidateOverlap = label.Is_Validate_Overlap_Date.trim();
    /**
    * Method used to bulkify all data needed in any "before" action of a trigger.
    */
    public void bulkBefore() {}

    /**
     *   Method used to bulkify all data needed in any "after" action of a trigger.
     */
    public void bulkAfter() {

      // CSP-2925 Compensation Roles - Set up Custom Object
      if(trigger.isInsert || trigger.isUpdate) {

        if(isValidateOverlap.equalsIgnoreCase('true')) {
          Set<Id> salseRepIdSet = new Set<Id>();

          // Get all Sales Rep id in new list. 
          for(Compensation_Role__c compRole : (List<Compensation_Role__c>)Trigger.New) {
            if(String.isNotBlank(comprole.Sales_Rep__c)) {
              salseRepIdSet.add(comprole.Sales_Rep__c);
            }
          }
          // CSP-2925 Compensation Roles - Set up Custom Object
          // Get Compensation Role for these salse rep
          if(!salseRepIdSet.isEmpty()) {
            for(Compensation_Role__c compRole : [SELECT Id, Sales_Rep__c, End_Date__c, Start_Date__c, Compensation_Type__c 
                                                  FROM Compensation_Role__c 
                                                  WHERE Sales_Rep__c IN: salseRepIdSet]) {

              // Create map to mapping sales rep and list Compensation Role
              if(!repIdCompRoleListMap.containsKey(comprole.Sales_Rep__c)) {
                repIdCompRoleListMap.put(comprole.Sales_Rep__c, new list<Compensation_Role__c>());
              }
              repIdCompRoleListMap.get(comprole.Sales_Rep__c).add(compRole);
            }
          }
        }
      }
    }

    /**
     *   All before insert logic should be done here. This method is called iteratively and as such
     *   should contain no actions which could potentially hit limits or is considered bad practice 
     *   in the Salesforce environment.
     *   
     *   @param  {SObject}   so Single SObject representation of the object being acted upon.
     */
    public void beforeInsert(SObject so) {}

    /**
    *   All before update logic should be done here. This method is called iteratively and as such
    *   should contain no actions which could potentially hit limits or is considered bad practice
    *   in the Salesforce environment.
    *
    *   @param  {SObject}   oldSo Single SObject representation of the "old" copy of the current 
    *                             object being acted upon.
    *   @param  {SObject}   so    Single SObject representation of the object being acted upon.
    */
    public void beforeUpdate(SObject oldSo, SObject so) {}

  /**
    *   All before delete logic should be done here. This method is called iteratively and as such
    *   should contain no actions which could potentilly hit limits or is considered bad practice
    *   in the Salesforce environment.
    *
    *   @param  {SObject}   so Single SObject representation of the object being acted upon.
    */
    public void beforeDelete(SObject so) {}


    /**
    *   All after insert logic should be done here. This method is called iteratively and as such
    *   should contain no actions which could potentilly hit limits or is considered bad practice
    *   in the Salesforce environment. 
    *
    *   @param  {SObject}   so Single SObject representation of the object being acted upon.
    */
    public void afterInsert(SObject so) {
      Compensation_Role__c record = (Compensation_Role__c)so;

      // CSP-2925 Compensation Roles - Set up Custom Object
      // Prevents date ranges from overlapping
      if(isValidateOverlap.equalsIgnoreCase('true')) {
        validateOverlap(record);
      }
    }


    /**
    *   All after update logic should be done here. This method is called iteratively and as such
    *   should contain no actions which could potentilly hit limits or is considered bad practice
    *   in the Salesforce environment.
    *   
    *   @param  {SObject}   oldSo Single SObject representation of the "old" copy of the current 
    *                             object being acted upon.
    *   @param  {SObject}   so    Single SObject representation of the object being acted upon.
    */
    public void afterUpdate(SObject oldSo, SObject so) {
      Compensation_Role__c record = (Compensation_Role__c)so;
      Compensation_Role__c oldRecord = (Compensation_Role__c)oldSo;

      // CSP-2925 Compensation Roles - Set up Custom Object
      // Prevents date ranges from overlapping
      if(record.Sales_Rep__c != oldRecord.Sales_Rep__c 
        || record.Start_Date__c != oldRecord.Start_Date__c 
        || record.End_Date__c != oldRecord.End_Date__c) {

        if(isValidateOverlap.equalsIgnoreCase('true')) {
          validateOverlap(record);
        }
      } 
    }

    /**
    *   All after delete logic should be done here. This method is called iteratively and as such
    *   should contain no actions which could potentilly hit limits or is considered bad practice
    *   in the Salesforce environment. 
    *
    *   @param  {SObject}   so Single SObject representation of the object being acted upon.
    */
    public void afterDelete(SObject so) {}

    /**
    *   All final logic in the "before" context should be done at this point such as modification to objects outside of
    *   the current object. At this point all updates to the current trigger transaction should be
    *   complete and all validation done.
    */
    public void beforeAndFinally() {}


    /**
    *   All final logic in the "after" context should be done at this point such as modification to objects outside of
    *   the current object. At this point all updates to the current trigger transaction should be
    *   complete and all validation done.
    */
    public void afterAndFinally() {}
    
    /**
     * CSP-2925 Compensation Roles - Set up Custom Object
     * System prevents date ranges from overlapping
     * 
     * @Author Mason
     * @Date   2018-06-07
     * @param  Compensation_Role__c record
     * @return void
     *
     */  
    private void validateOverlap(Compensation_Role__c record) {
      if(repIdCompRoleListMap.containsKey(record.Sales_Rep__c) && !repIdCompRoleListMap.get(record.Sales_Rep__c).isEmpty()) {
        
        //Loop all compensation role of this Sales Rep
        for(Compensation_Role__c CompRole : repIdCompRoleListMap.get(record.Sales_Rep__c)) {
          if(record.Id != CompRole.Id 
            && DateUtility.isStrictOverlapDate(record.Start_Date__c, record.End_Date__c, CompRole.Start_Date__c, CompRole.End_Date__c)) {

            record.addError(label.Overlap_Date_Error);
            break;
          }
        }
      }
    }
}