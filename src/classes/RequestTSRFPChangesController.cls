public with sharing class RequestTSRFPChangesController {
	public Task changesTask {get; set;}
	public ThoughtStarter_RFP__c relatedTSRFP {get; set;}
	public Boolean salesDevNeeded {get; set;}
	public Boolean accountStrategistNeeded {get; set;}

	private String tsRFPRTName;

	public RequestTSRFPChangesController() {
		changesTask = new Task();
		relatedTSRFP = new ThoughtStarter_RFP__c();
		salesDevNeeded = false;
		accountStrategistNeeded = false;

		relatedTSRFP = [select Id, RecordType.Name, Account_Strategist__c, Sales_Dev_Needed__c, Opportunity__c, Opportunity__r.StageName, Submitted_for_Production__c, Sales_Developer__c from ThoughtStarter_RFP__c where Id =: ApexPages.currentPage().getParameters().get('whatId')];
		
		//  The field Submitted_for_Production__c is always assigned to true in the TSRFP trigger
		// if(!relatedTSRFP.Submitted_for_Production__c){
		// 	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please complete and submit the ' + relatedTSRFP.RecordType.Name));
		// }

		tsRFPRTName = relatedTSRFP.RecordType.Name;

		changesTask.WhatId = relatedTSRFP.Id;
		changesTask.Subject = 'Client has requested changes for the ' + tsRFPRTName;
		changesTask.Type = 'Other';

		if(tsRFPRTName.equalsIgnoreCase('ThoughtStarter')){
			salesDevNeeded = true;
		}else if(tsRFPRTName.equalsIgnoreCase('RFP') && !relatedTSRFP.Sales_Dev_Needed__c){
			accountStrategistNeeded = true;
		}
	}

	public pageReference save(){
		
		if(!salesDevNeeded && !accountStrategistNeeded){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select either Sales Dev Needed or Account Strategist Needed'));
			return null;
		}

		// get the active user Id which is the menber of group Sales_Dev_Team
		List<Id> salesDevTeamIdList = new List<Id>();
		Set<Id> userIdSet = new Set<Id>();
		for(GroupMember currentGroupMenber : [select UserOrGroupId from GroupMember where Group.DeveloperName = 'Sales_Dev_Team']){
			userIdSet.add(currentGroupMenber.UserOrGroupId);
		}
		for(User currentUser : [SELECT Id FROM User WHERE Id in: userIdSet AND isActive = true]){
    	salesDevTeamIdList.add(currentUser.Id);
    }
		

		List<Task> inserTaskList = new List<Task>();

		// if salesDevNeeded has been checked, we should create task and assign to the Dev team or Sales Developer
		if (salesDevNeeded) {
			String salesDevPurpose = (tsRFPRTName.equalsIgnoreCase('ThoughtStarter')) ? 'Produce ThoughtStarter' : 'Produce RFP Pitch Deck';

			if(String.isNotBlank(relatedTSRFP.Sales_Developer__c)){
				inserTaskList.add(generateTask(relatedTSRFP.Sales_Developer__c, changesTask, salesDevPurpose, tsRFPRTName));
			}else{
				for(Id currentOwnerId : userIdSet){
					inserTaskList.add(generateTask(currentOwnerId, changesTask, salesDevPurpose, tsRFPRTName));
				}
			}
		}

		// if accountStrategistNeeded is checked, we should create a task to the Account Strategist
		if (accountStrategistNeeded) {
		  Task mediaTask = changesTask.clone(false, true);
    	mediaTask.OwnerId = relatedTSRFP.Account_Strategist__c;
    	mediaTask.Subject += ' - Media Plan';
    	mediaTask.Purpose__c = 'Produce RFP Media Plan';
    	inserTaskList.add(mediaTask);  
		}

		//  insert the task and insert the exception if needed.
		Database.SaveResult[] taskSaveResults = Database.insert(inserTaskList, false);
		List<XO_Exception__c> exceptionList = ExceptionUtility.consumeException(
																														(List<Task>)inserTaskList, 
																														taskSaveResults, 
																														'Major', 
																														'Operative.One', 
																														false,
																														'WhatId'
																														);
		if (!exceptionList.isEmpty()) {
	    insert exceptionList;
		}
			


		// try{	
			//  comment all the code for the ticket CSP-1700, 
            //insert changesTask;
   //          List<Task> newTaskList = new List<Task>();

   //          if(salesDevNeeded){
   //          	String salesDevPurpose = (relatedTSRFP.RecordType.Name.equalsIgnoreCase('ThoughtStarter')) ? 'Produce ThoughtStarter' : 'Produce RFP Pitch Deck';
			// 	/*for(GroupMember record : [select UserOrGroupId from GroupMember where Group.DeveloperName = 'Sales_Dev_Team']){
			// 		Task newTask = changesTask.clone(false, true);
			// 		newTask.OwnerId = record.UserOrGroupId;
			// 		newTask.Purpose__c = salesDevPurpose;
			// 		newTask.Subject = (relatedTSRFP.RecordType.Name.equalsIgnoreCase('ThoughtStarter')) ? newTask.Subject : newTask.Subject + ' - Pitch Deck';
			// 		newTaskList.add(newTask);
			// 	}*/
			// 	if(String.isNotBlank(relatedTSRFP.Sales_Developer__c)){
			// 		Task newTask = changesTask.clone(false, true);
			// 		newTask.OwnerId = relatedTSRFP.Sales_Developer__c;
			// 		newTask.Purpose__c = salesDevPurpose;
			// 		newTask.Subject = (relatedTSRFP.RecordType.Name.equalsIgnoreCase('ThoughtStarter')) ? newTask.Subject : newTask.Subject + ' - Pitch Deck';
			// 		newTaskList.add(newTask);
			// 	}else{
			// 		for(GroupMember record : [select UserOrGroupId from GroupMember where Group.DeveloperName = 'Sales_Dev_Team']){
			// 			Task newTask = changesTask.clone(false, true);
			// 			newTask.OwnerId = record.UserOrGroupId;
			// 			newTask.Purpose__c = salesDevPurpose;
			// 			newTask.Subject = (relatedTSRFP.RecordType.Name.equalsIgnoreCase('ThoughtStarter')) ? newTask.Subject : newTask.Subject + ' - Pitch Deck';
			// 			newTaskList.add(newTask);
			// 		}
			// 	}
   //          }

   //          if(accountStrategistNeeded){
   //          	Task mediaTask = changesTask.clone(false, true);
   //          	mediaTask.OwnerId = relatedTSRFP.Account_Strategist__c;
   //          	mediaTask.Subject += ' - Media Plan';
   //          	mediaTask.Purpose__c = 'Produce RFP Media Plan';
   //          	newTaskList.add(mediaTask);

   //          	/*if(salesDevNeeded){
   //          		Task alignTask = changesTask.clone(false, true);
   //          		alignTask.OwnerId = relatedTSRFP.Account_Strategist__c;
   //          		alignTask.Subject += ' - Align Plan';
   //          		alignTask.Purpose__c = 'Ensure Media and Pitch Deck Align';
   //          		newTaskList.add(alignTask);
   //          	}*/
   //          }

   //          if(relatedTSRFP.RecordType.Name.equalsIgnoreCase('ThoughtStarter')){
   //          	relatedTSRFP.Opportunity__r.StageName = 'Stage 1.1: TS Change Request';
   //          }else if(relatedTSRFP.RecordType.Name.equalsIgnoreCase('RFP')){
   //          	relatedTSRFP.Opportunity__r.StageName = 'Stage 4.1: RFP Change Request';
   //          }

   //          Database.DMLOptions dmlo = new Database.DMLOptions();
			// dmlo.EmailHeader.triggerUserEmail = true;
   //          database.insert(newTaskList, dmlo);
            
   //          update relatedTSRFP.Opportunity__r;
    // }catch(Exception E){
    //     return null;
    // }

    PageReference viewPage = new ApexPages.StandardController(relatedTSRFP).view();
    viewPage.setRedirect(true);

    return viewPage;
	}

	public pageReference cancel(){
		PageReference viewPage = new ApexPages.StandardController(relatedTSRFP).view();
    viewPage.setRedirect(true);

    return viewPage;
	}


	/**
   *   [createTask: This method is used to create a task]
   *
   *   @author [Tony Liu]
   *   @date   2017-09-13
   */
  private static Task generateTask(Id ownerUserId, Task changesTask, String purposeStr, String tsRFPRTName){

		Task newTask = changesTask.clone(false, true);
		newTask.OwnerId = ownerUserId;
		newTask.Purpose__c = purposeStr;
		newTask.Subject = (tsRFPRTName.equalsIgnoreCase('ThoughtStarter')) ? newTask.Subject : newTask.Subject + ' - Pitch Deck';
    return newTask;

	}
}