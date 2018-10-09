public without sharing class OutOfOfficeTriggerHandler implements XOTrigger{
	/**
	* Class OutOfOfficeTriggerHandler
	*
	* Trigger Handler for the Out_Of_Office__c SObject. This class implements the ITrigger
	* interface to help ensure the trigger code is bulkified and all in one place.
	*/
	public List<Out_Of_Office__c> outOfOfficeList = new List<Out_Of_Office__c>();
	public Set<ID> outOfOfficeAssingFromUsrSet = new Set<Id>();
	
	public String errormsg = 'Sorry! We found a record that is already in the system with an overlapping Start and End date. Please try creating a new record with a different start and end date or modify the existing record.';

	// Constructor
	public OutOfOfficeTriggerHandler(){

	}
	
	/**
 	* bulkBefore
 	*
 	* This method is called prior to execution of a BEFORE trigger. Use this to cache
 	* any data required into maps prior execution of the trigger.
 	*/
	
	public void bulkBefore(){
		
		Set<String> OwnerIdSet = new Set<String>();
		Map<String, List<Out_Of_Office__c>> existingOOMap = new Map<String, List<Out_Of_Office__c>>();

		// save all new ownerIds
		for(SObject oooSObject : trigger.New){
			Out_Of_Office__c record = (Out_Of_Office__c)oooSObject;
			// assign the ownerid to the field assign from 
			if(record.Assign_From__c == null){
				record.Assign_From__c = record.ownerid;
			}
			OwnerIdSet.add(record.OwnerId);
		}

		// retrieve all existing ooo records by filtering ownerId
		List<Out_Of_Office__c> existingOOList = [
			SELECT id, Assign_From__c, Assign_Task_To__c, Start_Date__c, End_Date__c, OwnerId FROM 
			Out_Of_Office__c WHERE ownerid IN: OwnerIdSet
		];

		// put all existing ooo records in map group by ownerId
		for(Out_Of_Office__c ooo : existingOOList){
			if(!existingOOMap.containsKey(ooo.OwnerId)){
				existingOOMap.put(ooo.OwnerId, new List<Out_Of_Office__c>{ooo});
			}
			else{
				existingOOMap.get(ooo.OwnerId).add(ooo);
			}
		}

		for(SObject oooSObject : trigger.New){
			Out_Of_Office__c record = (Out_Of_Office__c)oooSObject;

			if(!existingOOMap.isEmpty() && existingOOMap.get(record.OwnerId) != null){
				for(Out_Of_Office__c existingRec : existingOOMap.get(record.OwnerId)){
					
					// if insert, then just compare the start date and end date
					// if update, then need to ignore the original record in the comparison
					if(Trigger.isInsert || (Trigger.isUpdate && record.Id!=existingRec.Id) ){
						if(record.End_Date__c >= existingRec.Start_Date__c && 
							record.Start_Date__c <= existingRec.End_Date__c){
							record.addError(errormsg);
						}
					}
				}
			}
		}

		

	}

	public void bulkAfter(){
		
	}
	
	public void beforeInsert(SObject so){
		//TO DO: implement before insert logic here
	}

	public void beforeUpdate(SObject oldSo, SObject so){
		//TO DO: implement before update logic here
	}
	
	
	/**
	* beforeDelete
	*
	* This method is called iteratively for each record to be deleted during a BEFORE
	* trigger.
	*/  
	
	
	public void beforeDelete(SObject so){
		//TO DO: implement before delete logic here
	}

	public void afterInsert(SObject so){
		//TO DO: implement after insert logic here
	}

	public void afterUpdate(SObject oldSo, SObject so){
		//TO DO: implement after update logic here
	}

	public void afterDelete(SObject so){
		//TO DO: implement after delete logic here
	}
	
	/**
	* beforeAndFinally
	*
	* This method is called once all records have been processed by the trigger in the "before" context. Use this
	* method to accomplish any final operations such as creation or updates of other records.
	*/
	public void beforeandfinally(){

	}
	/**
	* afterAndFinally
	*
	* This method is called once all records have been processed by the trigger in the "after" context. Use this
	* method to accomplish any final operations such as creation or updates of other records.
	*/
	public void afterandfinally(){
	}

}