/* 
<trigger>
  <name>TaskTrigger</name>
  <purpose>For handling save/delete events on a Task</purpose>
  <created>
	<by>Jonathan Satterfield</by>
	<date>6/4/2015</date>
	<ticket>SF-542</ticket>
  </created>
</trigger>
*/
trigger TaskTrigger on Task (before insert, before update, after insert, after update, before delete, after delete) {
	XOTriggerFactory.createAndExecuteHandler(TaskTriggerHandler.class);
	// // before insert 
	// if (Trigger.isBefore && Trigger.isInsert) {
		
	// 	// populate a list of Task objects with Tasks related to Opportunities
	// 	String opportunityObjectPrefix = Schema.SObjectType.Opportunity.getKeyPrefix();
		
	// 	List<Task> newTasksForOpportunitiesList = new List<Task>();
		
	// 	for (Task t : Trigger.new) {
	// 		if (t.WhatId != null && ((String)t.WhatId).startsWith(opportunityObjectPrefix)) {
	// 			newTasksForOpportunitiesList.add(t);
	// 		}
	// 	}
		
	// 	if (!newTasksForOpportunitiesList.isEmpty()) {
			
	// 		// populate a list of Opportunity objects related to the Tasks in the Task list from above
	// 		Set<Id> opportunityIds = new Set<Id>();
			
	// 		for (Task t : newTasksForOpportunitiesList) {
	// 			opportunityIds.add(t.WhatId);
	// 		}
			
	// 		List<Opportunity> relatedOpportunitiesList = [SELECT Id, StageName FROM Opportunity WHERE Id in :opportunityIds and RecordType.Name != 'National'];
			
	// 		// populate a map of Opportunity Ids and the StageName for each Opportunity
	// 		Map<Id, String> opportunityIdAndStageNameMap = new Map<Id, String>();
			
	// 		for (Opportunity o : relatedOpportunitiesList) {
	// 			opportunityIdAndStageNameMap.put(o.Id, o.StageName);
	// 		}
			
	// 		// lastly, assign the Opportunity StageName to the related Task's Opportunity Stage field
	// 		for (Task t : newTasksForOpportunitiesList) {
	// 			t.Opportunity_Stage__c = opportunityIdAndStageNameMap.get(t.WhatId);
	// 		}
	// 	}
	// }

	// if(trigger.isBefore && trigger.isUpdate){
		
	// 	Set<Id> salesDevTeamIdSet = new Set<Id>();
	// 	Map<Id, Id> tsRFPIdSalesDevMap = new Map<Id, Id>();

	// 	for(GroupMember record : [select UserOrGroupId from GroupMember where Group.DeveloperName = 'Sales_Dev_Team']){
	// 		salesDevTeamIdSet.add(record.UserOrGroupId);
	// 	}

	// 	Set<Id> tsRFPIdSetNoSalesDev = new Set<Id>();
	// 	for(Task record : trigger.New){
	// 		Task oldRecord = trigger.oldMap.get(record.Id);
	// 		if(record.Status != oldRecord.Status && record.WhatId != null && record.WhatId.getSObjectType() === Schema.ThoughtStarter_RFP__c.getSObjectType()){
	// 			tsRFPIdSetNoSalesDev.add(record.WhatId);
	// 		}
	// 	}
		
	// 	for(ThoughtStarter_RFP__c record : [select Id, Sales_Developer__c from ThoughtStarter_RFP__c where ID IN : tsRFPIdSetNoSalesDev and Sales_Developer__c != null]){
	// 		tsRFPIdSetNoSalesDev.remove(record.Id);
	// 	}

	// 	List<ThoughtStarter_RFP__c> updateSalesDevList = new List<ThoughtStarter_RFP__c>();
	// 	for(Task record : trigger.New){
	// 		Task oldRecord = trigger.oldMap.get(record.Id);
	// 		if(record.Status != oldRecord.Status && record.WhatId != null && record.WhatId.getSObjectType() === Schema.ThoughtStarter_RFP__c.getSObjectType()){
				
	// 			if(String.isNotBlank(record.Purpose__c) && record.Status.equalsIgnoreCase('Completed') && salesDevTeamIdSet.contains(record.OwnerId)){
	// 				tsRFPIdSalesDevMap.put(record.WhatId, record.OwnerId);
	// 			}
	// 		}
	// 	}

	// 	for(ThoughtStarter_RFP__c record : [select Id, Sales_Developer__c from ThoughtStarter_RFP__c where Id in : tsRFPIdSalesDevMap.keySet() and Sales_Developer__c = null]){
	// 		record.Sales_Developer__c = tsRFPIdSalesDevMap.get(record.Id);
	// 		updateSalesDevList.add(record);
	// 	}
	// 	if(!updateSalesDevList.isEmpty()){
	// 		system.debug(updateSalesDevList);
	// 		update updateSalesDevList;
	// 	}
	// }

	// if(trigger.isAfter){
	// 	if(trigger.isUpdate){
	// 		List<National_TS_RFP_Task_Stage_Mapping__c> nationalTaskOppStageMap = National_TS_RFP_Task_Stage_Mapping__c.getAll().values();
	// 		Map<Id, National_TS_RFP_Task_Stage_Mapping__c> tsrfpIdStageMap = new  Map<Id, National_TS_RFP_Task_Stage_Mapping__c>();
			
	// 		Set<Id> salesDevTeamIdSet = new Set<Id>();
	// 		for(GroupMember record : [select UserOrGroupId from GroupMember where Group.DeveloperName = 'Sales_Dev_Team']){
	// 			salesDevTeamIdSet.add(record.UserOrGroupId);
	// 		}

	// 		for(Task record : trigger.New){
	// 			Task oldRecord = trigger.oldMap.get(record.Id);
	// 			if(record.Status != oldRecord.Status && record.WhatId != null && record.WhatId.getSObjectType() === Schema.ThoughtStarter_RFP__c.getSObjectType()){
	// 				for(National_TS_RFP_Task_Stage_Mapping__c taskStage : nationalTaskOppStageMap){
	// 					if(String.isNotBlank(record.Purpose__c) && record.Purpose__c.equalsIgnoreCase(taskStage.Task_Purpose__c) && record.Status.equalsIgnoreCase(taskStage.Task_Status__c)){
	// 						tsrfpIdStageMap.put(record.WhatId, taskStage);
	// 					}
	// 				}
	// 			}
	// 		}

	// 		List<Opportunity> updateOppStageList = new List<Opportunity>();

	// 		if(!tsrfpIdStageMap.isEmpty()){
	// 			for(ThoughtStarter_RFP__c record : [select Opportunity__c, Opportunity__r.Name, Opportunity__r.StageName, Opportunity__r.OwnerId, RecordType.Name, Account_Strategist__c, Sales_Dev_Needed__c, Sales_Developer__c, (select Id, Status, OwnerId, Purpose__c from Tasks) from ThoughtStarter_RFP__c where ID IN: tsrfpIdStageMap.keySet()]){
	// 				if(tsrfpIdStageMap.get(record.Id).Opportunity_Stage__c != record.Opportunity__r.StageName){
	// 					record.Opportunity__r.StageName = tsrfpIdStageMap.get(record.Id).Opportunity_Stage__c;
	// 					updateOppStageList.add(record.Opportunity__r);
	// 				}
	// 			}
	// 		}
	// 		update updateOppStageList;
	// 	}
	// }
}