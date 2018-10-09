public without sharing class RoomTriggerHandler implements XOTrigger{
    /**
   * Method used to bulkify all data needed in any "before" action of a trigger.
   */
  public void bulkBefore() {
		if (Trigger.isInsert) {

		}
		if (Trigger.isUpdate) {
			Set<Id> newRoomIdSet = new Set<Id>();
			Set<Id> oldRoomIdSet = new Set<Id>();
			for (Integer i = 0; i< trigger.new.size(); i++) {
        
        Room__c currentRoom = (Room__c)trigger.new[i];
        Room__c oldRoom = (Room__c)trigger.oldMap.get(currentRoom.id);
        if (String.isNotBlank(currentRoom.Parent_Room__c)) {
        	newRoomIdSet.add(currentRoom.Parent_Room__c);
        }
        if (String.isNotBlank(oldRoom.Parent_Room__c)) {
        	oldRoomIdSet.add(oldRoom.Parent_Room__c);
        }


      }


      if (!newRoomIdSet.isEmpty()) {
      	List<Room__c> newChildRoomList = [Select id,name from Room__c where Parent_Room__c in : newRoomIdSet];
      	System.debug(LoggingLevel.INFO, '***newChildRoomList : ' + newChildRoomList);
      }

      if (!oldRoomIdSet.isEmpty()) {
      	List<Room__c> oldChildRoomList = [Select id,name from Room__c where Parent_Room__c in : oldRoomIdSet];
      	System.debug(LoggingLevel.INFO, '***oldChildRoomList : ' + oldChildRoomList);
      }
		}

  }

  /**
   *   Method used to bulkify all data needed in any "after" action of a trigger.
   */
  public void bulkAfter() {

  	if (Trigger.isInsert) {

		}
		if (Trigger.isUpdate) {
			Set<Id> newRoomIdSet = new Set<Id>();
			Set<Id> oldRoomIdSet = new Set<Id>();
			for (Integer i = 0; i< trigger.new.size(); i++) {
        
        Room__c currentRoom = (Room__c)trigger.new[i];
        Room__c oldRoom = (Room__c)trigger.oldMap.get(currentRoom.id);
        if (String.isNotBlank(currentRoom.Parent_Room__c)) {
        	newRoomIdSet.add(currentRoom.Parent_Room__c);
        }
        if (String.isNotBlank(oldRoom.Parent_Room__c)) {
        	oldRoomIdSet.add(oldRoom.Parent_Room__c);
        }


      }


      if (!newRoomIdSet.isEmpty()) {
      	List<Room__c> newChildRoomList = [Select id,name from Room__c where Parent_Room__c in : newRoomIdSet];
      	System.debug(LoggingLevel.INFO, '***newChildRoomList1 : ' + newChildRoomList);
      }

      if (!oldRoomIdSet.isEmpty()) {
      	List<Room__c> oldChildRoomList = [Select id,name from Room__c where Parent_Room__c in : oldRoomIdSet];
      	System.debug(LoggingLevel.INFO, '***oldChildRoomList1 : ' + oldChildRoomList);
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
  public void beforeUpdate(SObject oldSo, SObject so) {
    
  }

  /**
  *   All before delete logic should be done here. This method is called iteratively and as such
  *   should contain no actions which could potentilly hit limits or is considered bad practice
  *   in the Salesforce environment.
  *
  *   @param  {SObject}   so Single SObject representation of the object being acted upon.
  */
  public void beforeDelete(SObject so) {
  	Room__c currentRoom = (Room__c)so;
  	// List<Room__c> rlist = [select id from Room__c where Parent_Room__c =: currentRoom.id];
  	// System.assert(false,rlist[0].id);
  	
  }

  /**
  *   All after insert logic should be done here. This method is called iteratively and as such
  *   should contain no actions which could potentilly hit limits or is considered bad practice
  *   in the Salesforce environment. 
  *
  *   @param  {SObject}   so Single SObject representation of the object being acted upon.
  */
  public void afterInsert(SObject so) {
    
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
    
  }

  /**
  *   All after delete logic should be done here. This method is called iteratively and as such
  *   should contain no actions which could potentilly hit limits or is considered bad practice
  *   in the Salesforce environment. 
  *
  *   @param  {SObject}   so Single SObject representation of the object being acted upon.
  */
  public void afterDelete(SObject so) {

  }

  /**
  *   All final logic in the "before" context should be done at this point such as modification to objects outside of
  *   the current object. At this point all updates to the current trigger transaction should be
  *   complete and all validation done.
  */
  public void beforeAndFinally() {
  	Map<String,Set<String>> accIdMap = new Map<String,Set<String>>();
		Set<String> testSet = new Set<String>();
		testSet.add('tttt');
		accIdMap.put('xogrp',testSet);


		Set<String> testSet1 = new Set<String>();
		testSet1.add('tttt1');
		accIdMap.put('xogrp1',testSet1);
    
		Map<String,Set<Id>> accIdMap1 = retrieveAccountId(accIdMap);

  }

  /**
  *   All final logic in the "after" context should be done at this point such as modification to objects outside of
  *   the current object. At this point all updates to the current trigger transaction should be
  *   complete and all validation done.
  */
  public void afterAndFinally() {
     
  }


  static Map<String,Set<Id>> retrieveAccountId(Map<String,Set<String>> testmap){
  	Map<String,Set<Id>> accIdMap = new Map<String,Set<Id>>();
  	return accIdMap;
  }

  public with sharing class testclass{
    public string testString;

    public testclass () {
       this.testString = '';
    }
  }
}