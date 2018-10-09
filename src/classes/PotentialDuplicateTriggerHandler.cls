public without sharing class PotentialDuplicateTriggerHandler implements XOTrigger{
  private List<Lead> leadList = new List<Lead>();
  private static final Map<String, Group> QUEUE_NAME_MAP; 
  // retrieve the Data Enrichment Queue
  static{
    if(QUEUE_NAME_MAP == null) {
      List<Group> queueGroupList = [SELECT Id, Name, (SELECT Id, UserOrGroupId FROM GroupMembers) FROM Group WHERE Type = 'Queue' AND Name = 'Data Enrichment'];

      Map<String, Group> tempGroupMap = new Map<String, Group>();
      for(Integer i = 0; i < queueGroupList.size(); i++) {
        Group currentGroup = queueGroupList[i];
        tempGroupMap.put(currentGroup.Name, currentGroup);
      }

      QUEUE_NAME_MAP = tempGroupMap;
    }

  }
  /**
   * Method used to bulkify all data needed in any "before" action of a trigger.
   */
  public void bulkBefore() {
    
  }

  /**
   *   Method used to bulkify all data needed in any "after" action of a trigger.
   */
  public void bulkAfter() {
    if(trigger.isInsert) {
      Set<Id> leadIdSet = new Set<Id>();
      Set<Id> duplicateWarningIdSet = new Set<Id>();
      for (CRMfusionDBR101__Potential_Duplicate__c record : (List<CRMfusionDBR101__Potential_Duplicate__c>)Trigger.New) {
        if (String.isNotBlank(record.CRMfusionDBR101__Lead__c)) {
          leadIdSet.add(record.CRMfusionDBR101__Lead__c);
        }

        if (String.isNotBlank(record.CRMfusionDBR101__Duplicate_Warning__c)) {
          duplicateWarningIdSet.add(record.CRMfusionDBR101__Duplicate_Warning__c);
        }
      }

      if (!duplicateWarningIdSet.isEmpty()) {
        List<CRMfusionDBR101__Potential_Duplicate__c> pdList = [SELECT Id, CRMfusionDBR101__Lead__c
                                                                FROM CRMfusionDBR101__Potential_Duplicate__c 
                                                                WHERE CRMfusionDBR101__Duplicate_Warning__c IN : duplicateWarningIdSet];
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
  public void beforeInsert(SObject so) {
    
    
  }

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
    CRMfusionDBR101__Potential_Duplicate__c currentPD = (CRMfusionDBR101__Potential_Duplicate__c)so;
    if (String.isNotBlank(currentPD.CRMfusionDBR101__Lead__c)) {
      Lead dupLead = new Lead();
      dupLead.Id = currentPD.CRMfusionDBR101__Lead__c;
      dupLead.Status = 'Ivalid';
      dupLead.Invalid_Reason__c = 'Duplicate';
      if(QUEUE_NAME_MAP.containsKey('Data Enrichment')) {
        dupLead.OwnerId = QUEUE_NAME_MAP.get('Data Enrichment').Id;
      }
      leadList.add(dupLead);
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
  public void afterUpdate(SObject oldSo, SObject so) {}

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
  public void afterAndFinally() {
    if (!leadList.isEmpty()) {
      update leadList;
    }
  }
}