/**
 *   CSP-1935
 *
 *   This trigger handler locates the duplicate lead record and updates its status and potential duplicate values. If 
 *   the lead is not from lead source TK Pro and is a duplicate, the status is updated to a 'Duplicate'. If no duplicates
 *   are found, the status is marked as 'New'. 
 *   
 *   Updated UAC: Marking all records in the duplicate record set as 'Invalid' with negative disposition reason
 *   of 'Duplicate' unless the record was created 2 hours prior to the current time
 *
 *   @author Ruchit Sontakke
 *   @date   09/19/2017
 */
public without sharing class DuplicateRecordSetTriggerHandler implements XOTrigger{


	private Map<Id, Lead> leadIdToLeadRecordMap = new Map<Id, Lead>();
	private List<Lead> leadRecordsToBeUpdatedLst = new List<Lead>();
	private Set<Lead> leadRecordsToBeUpdatedSet = new Set<Lead>();
	private Map<Id, DuplicateRecordSet> idToDuplicateRecordSetMap;

	// CSP-2779 Hot Path Duplicates Not Assigning to Data Enrichment
	// Store the queue Data Enrichment
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


	public void bulkBefore(){
	}

	public void bulkAfter(){
		if(trigger.isUpdate) {
			Set<Id> leadIdSet = new Set<Id>();
			System.debug(LoggingLevel.INFO, '***Trigger.New : ' + Trigger.New);
			// querying duplicate record items inside DuplicateRecordSet
			idToDuplicateRecordSetMap = new Map<Id, DuplicateRecordSet>([SELECT Id, (SELECT Id, RecordId, CreatedDate FROM DuplicateRecordItems) 
																		 FROM DuplicateRecordSet
																		 WHERE Id IN: Trigger.New]);
			// populating leadIdSet with lead ids which is later used to query leads that need to be upadted and the one that does not 
			// need to be updated
			for(DuplicateRecordSet recordSetItem : idToDuplicateRecordSetMap.values()) {
				for(DuplicateRecordItem duplicateRecordItem : recordSetItem.DuplicateRecordItems) {
        			if(String.valueOf(duplicateRecordItem.RecordId).startsWith('00Q')){
						leadIdSet.add(duplicateRecordItem.RecordId);
					}													
				}
			}
			// it is necessary to check if the leadIdSet is empty as this code is called after deleting lead records as well which 
			// causes an exception
			if(!leadIdSet.isEmpty()) {
		        // Lead id to lead record map is later used in afterUpdate() to update lead status and potential 
		        // duplicate fields for duplicate lead records 
		        // CSP-2104 Delete the current Lead Source object from Salesforce - remove Lead_Source__r.Name != 'TK Pro' filter
			    leadIdToLeadRecordMap = new Map<Id, Lead>([SELECT Id, Potential_Duplicates__c, Status, CreatedDate, OwnerId  
			    										   FROM Lead 
			    										   WHERE Id IN: leadIdSet And Potential_Duplicates__c = null]);
		    }
		}
	}

	public void beforeInsert(SObject so){}

	public void beforeUpdate(SObject oldSo, SObject so){}

	public void beforeDelete(SObject so){}

	public void afterInsert(SObject so){
	}

	public void afterUpdate(SObject oldSo, SObject so){

		DuplicateRecordSet dupRecordSetObj = (DuplicateRecordSet)so;
		System.debug(LoggingLevel.INFO, '***dupRecordSetObj1 : ' + dupRecordSetObj);
		DuplicateRecordSet olddupRecordSetObj = (DuplicateRecordSet)oldSo;

		System.debug(LoggingLevel.INFO, '***dupRecordSetObj.RecordCount : ' + dupRecordSetObj.RecordCount);
		System.debug(LoggingLevel.INFO, '***olddupRecordSetObj.RecordCount : ' + olddupRecordSetObj.RecordCount);
		// this helps to populate dupRecordSetObj all the child duplicate record item records which belong to the parent 
		// duplicate record set
		if(idToDuplicateRecordSetMap.containsKey(dupRecordSetObj.Id)) {
			dupRecordSetObj = idToDuplicateRecordSetMap.get(dupRecordSetObj.id);
		}
		System.debug(LoggingLevel.INFO, '***dupRecordSetObj2 : ' + dupRecordSetObj);
		System.debug(LoggingLevel.INFO, '***dupRecordSetObj.DuplicateRecordItems1 : ' + dupRecordSetObj.DuplicateRecordItems);
		// looping through all duplicate record item records and update its status and potential duplicate values
		for(DuplicateRecordItem dupRecordItem : dupRecordSetObj.DuplicateRecordItems) {
			if(leadIdToLeadRecordMap.containsKey(dupRecordItem.RecordId)) {
				Lead currentLeadRecord = leadIdToLeadRecordMap.get(dupRecordItem.RecordId);
				System.debug(LoggingLevel.INFO, '***currentLeadRecord : ' + currentLeadRecord);
				// marking all records in the duplicate record set as 'Invalid' with negative disposition reason
				// of 'Duplicate' unless the record was created 2 hours prior to the current time
				// First we need to check if the records fall on the same day and then compare the hours
				if(Datetime.now().dayGMT() == currentLeadRecord.createdDate.dayGMT()) {
					if(Datetime.now().hourGMT() - currentLeadRecord.createdDate.hourGMT() < 2) {
						currentLeadRecord.Status = 'Invalid';
						currentLeadRecord.Negative_Disposition_Reason__c = 'Duplicate';
						// CSP-2779 Hot Path Duplicates Not Assigning to Data Enrichment
						// if the lead is duplicated, we should assign the lead to Data Enrichment
						if(QUEUE_NAME_MAP.containsKey('Data Enrichment')) {
							currentLeadRecord.OwnerId = QUEUE_NAME_MAP.get('Data Enrichment').Id;
						}
					}	
				}
				currentLeadRecord.Potential_Duplicates__c = URL.getSalesforceBaseUrl().toExternalForm() + '/0GL?rlid=DuplicateRecordItem&id=' + dupRecordSetObj.Id;
				leadRecordsToBeUpdatedSet.add(currentLeadRecord);   
			}
		}
	}

	public void afterDelete(SObject so){}

	public void beforeAndFinally(){}

	public void afterAndFinally(){

		List<XO_Exception__C> xoExceptionList = new List<XO_Exception__C>();

		if(!leadRecordsToBeUpdatedSet.isEmpty()) {
			// we need to add the records first in a Set to prevent adding duplcaite lead records. This is an edge 
			// case that needs to be handled when a lead record can belong to different records sets. This happens 
			// when the lead record is matched with multuple records using differnt duplicate rules or same duplicate 
			// rule but a different criteria.
			leadRecordsToBeUpdatedLst = new List<Lead>(leadRecordsToBeUpdatedSet);

			Database.SaveResult[] updateResults = Database.update(leadRecordsToBeUpdatedLst, false);
			
			List<XO_Exception__C> exceptionList = ExceptionUtility.consumeException(updateResults);			
			if(exceptionList != null && exceptionList.Size() > 0){
			    xoExceptionList.addAll(exceptionList);
			}
		}

		if(!xoExceptionList.isEmpty()) {
		    insert xoExceptionList;
		}
	}
}