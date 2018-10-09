trigger ThoughtStarterRFPTrigger on ThoughtStarter_RFP__c (before insert, before update, after insert, after update, before delete, after delete) {
	XOTriggerFactory.createAndExecuteHandler(ThoughtStarterRFPTriggerHandler.class);

		// Map<Id,Schema.RecordTypeInfo> rtMapById = Schema.SObjectType.ThoughtStarter_RFP__c.getRecordTypeInfosById();
		// List<Schema.FieldSetMember> rfpFieldSetList = SObjectType.ThoughtStarter_RFP__c.FieldSets.Required_RFP_Fields.getFields();
		// List<Schema.FieldSetMember> tsFieldSetList = SObjectType.ThoughtStarter_RFP__c.FieldSets.Required_ThoughtStarter_Fields.getFields();

		// List<Id> salesDevTeamIdList = new List<Id>();
		// for(GroupMember record : [select UserOrGroupId from GroupMember where Group.DeveloperName = 'Sales_Dev_Team']){
		//     salesDevTeamIdList.add(record.UserOrGroupId);
		// }

		// if(trigger.isBefore){
		//     if(trigger.isInsert || trigger.isUpdate){
		//         Set<Id> opportunityIdSet = new Set<Id>();
		//         Set<Id> oppRFPIdSet = new Set<Id>();
		//         Set<Id> allOppIds = new Set<Id>();

		//         for(ThoughtStarter_RFP__c record : trigger.New){
		//             Boolean validateFields = false;

		//             if(record.Opportunity__c != null){
		//                 allOppIds.add(record.Opportunity__c);

		//                 if(trigger.isInsert){
		//                     validateFields = (record.Submitted_for_Production__c) ? true : false;
		//                     opportunityIdSet.add(record.Opportunity__c);

		//                     if(rtMapById.get(record.RecordTypeId).getName().equals('ThoughtStarter')){
		//                         record.Sales_Dev_Needed__c = true;
		//                     }else if(rtMapById.get(record.RecordTypeId).getName().equals('RFP')){
		//                         oppRFPIdSet.add(record.Opportunity__c);
		//                     }

		//                     Boolean errorAdded = false;
		//                     List<Schema.FieldSetMember> fieldSetList = (rtMapById.get(record.RecordTypeId).getName().equals('RFP')) ? rfpFieldSetList : tsFieldSetList;

		//                     for(Schema.FieldSetMember f : fieldSetList) {
		//                         if(String.valueof(f.getType()) != 'STRING' && record.get(f.getFieldPath()) == null){
		//                             errorAdded = true;
		//                         }else if(String.valueof(f.getType()) == 'STRING' && String.isBlank((String)record.get(f.getFieldPath()))){
		//                             errorAdded = true;
		//                         }
		//                     }

		//                     if(!errorAdded){
		//                         record.Submitted_for_Production__c = true;
		//                     }
		//                 }else if(trigger.isUpdate){
		//                     ThoughtStarter_RFP__c oldRecord = trigger.oldMap.get(record.Id);
		//                     record.Submitted_for_Production__c = true;
		//                     validateFields = (record.Submitted_for_Production__c) ? true : false;
		//                     if(record.RecordTypeId != oldRecord.RecordTypeId){
		//                         opportunityIdSet.add(record.Opportunity__c);
		//                     }
		//                 }

		//                 if(validateFields){
		//                     String buildErrorString = rtMapById.get(record.RecordTypeId).getName() + ' could not be submitted!<br/>Please review the following errors:<br/>';
		//                     Boolean errorAdded = false;
		//                     List<Schema.FieldSetMember> fieldSetList = (rtMapById.get(record.RecordTypeId).getName().equals('RFP')) ? rfpFieldSetList : tsFieldSetList;

		//                     for(Schema.FieldSetMember f : fieldSetList) {
		//                         if(String.valueof(f.getType()) != 'STRING' && record.get(f.getFieldPath()) == null){
		//                             buildErrorString += f.getLabel() + ' can not be null!<br/>';
		//                             errorAdded = true;
		//                         }else if(String.valueof(f.getType()) == 'STRING' && String.isBlank((String)record.get(f.getFieldPath()))){
		//                             buildErrorString += f.getLabel() + ' can not be null!<br/>';
		//                             errorAdded = true;
		//                         }
		//                     }

		//                     if(errorAdded){
		//                         record.addError(buildErrorString, false);
		//                     }
		//                 }
		//             }
		//         }
						
		//         Map<Id, Set<Id>> rtIdOppMap = new Map<Id, Set<Id>>();
		//         Map<Id, Opportunity> opportunityAccStratMap = new Map<Id, Opportunity>();
		//         Map<Id, Id> oppTSconvertedRFPMap = new Map<Id, Id>();
		//         Map<Id, String> oppNameMap = new Map<Id, String>();

		//         for(Id record : rtMapById.keySet()){
		//             rtIdOppMap.put(record, new Set<Id>());
		//         }

		//         //Need to combine this with the query below
		//         for(ThoughtStarter_RFP__c record : [select Id, Opportunity__c, Opportunity__r.AccStrategist__c, RecordTypeId from ThoughtStarter_RFP__c where Opportunity__c IN : opportunityIdSet]){
		//             if(rtIdOppMap.containsKey(record.RecordTypeId)){
		//                 rtIdOppMap.get(record.RecordTypeId).add(record.Opportunity__c);
		//             }
		//         }

		//         //Need to combine this with query above
		//         if(trigger.isInsert){
		//             for(Opportunity record : [select Id, AccStrategist__c, Amount, (select Id from ThoughtStarters_RFPs__r where RecordType.Name = 'ThoughtStarter') from Opportunity where Id IN : opportunityIdSet or Id IN : oppRFPIdSet]){
		//                 opportunityAccStratMap.put(record.Id, record);

		//                 if(record.ThoughtStarters_RFPs__r.size() > 0){
		//                     oppTSconvertedRFPMap.put(record.Id, record.ThoughtStarters_RFPs__r[0].Id);
		//                 }
		//             }
		//         }

		//         for(Opportunity record : [select Id, Name from Opportunity where Id IN : allOppIds]){
		//             oppNameMap.put(record.Id, record.Name);
		//         }

		//         for(ThoughtStarter_RFP__c record : trigger.New){
		//             String recordName = (rtMapById.get(record.RecordTypeId).getName().equals('ThoughtStarter')) ? 'TS' : rtMapById.get(record.RecordTypeId).getName();
		//             recordName += '-' + oppNameMap.get(record.Opportunity__c);
		//             record.Name = recordName.left(80);

		//             if(rtIdOppMap.containsKey(record.RecordTypeId)){
		//                 if(rtIdOppMap.get(record.RecordTypeId).contains(record.Opportunity__c)){
		//                     record.addError('The related Opportunity already has a ' + rtMapById.get(record.RecordTypeId).getName() + '!');
		//                 }
		//             }
		//             if(trigger.isInsert && opportunityAccStratMap.containsKey(record.Opportunity__c)){
		//                 record.Account_Strategist__c = opportunityAccStratMap.get(record.Opportunity__c).AccStrategist__c;
		//                 if(rtMapById.get(record.RecordTypeId).getName().equals('ThoughtStarter') && record.Budget__c == null){
		//                     record.Budget__c = opportunityAccStratMap.get(record.Opportunity__c).Amount;
		//                 }else if(rtMapById.get(record.RecordTypeId).getName().equals('RFP') && record.Maximum_Budget__c == null){
		//                     record.Maximum_Budget__c = opportunityAccStratMap.get(record.Opportunity__c).Amount;
		//                 }
		//             }
		//             if(trigger.isInsert && oppTSconvertedRFPMap.containsKey(record.Opportunity__c)){
		//                 record.Related_ThoughtStarter__c = oppTSconvertedRFPMap.get(record.Opportunity__c);
		//             }
		//         }
		//     }
		// }


		// if(trigger.isAfter){
		//     if(trigger.isInsert || trigger.isUpdate){
		//         List<Task> newTaskList = new List<Task>();
		//         Map<Id, Id> oppAccStrategistIdMap = new Map<Id, Id>();
		//         List<Id> tsRFPNewSalesDevList = new List<Id>();
		//         Id pbId;//PricebookEntry ID
		//         if(!Test.isRunningTest()){
		//             pbId = [select Id from PricebookEntry where Name = 'Uncategorized Revenue' and Pricebook2.IsActive = true and Pricebook2.IsStandard = true limit 1].Id;
		//         }else{
		//             pbId = [select Id from PricebookEntry where Name = 'Uncategorized Revenue' limit 1].Id;
		//         }
		//         List<OpportunityLineItem> newOLIList = new List<OpportunityLineItem>();
		//         Map<Id, ThoughtStarter_RFP__c> opportunityNeedUncatRevUpdateMap = new Map<Id, ThoughtStarter_RFP__c>();

		//         List<Id> tsRFPRemoveSalesDevTask = new List<Id>();

		//         for(ThoughtStarter_RFP__c record : trigger.New){
		//             Boolean createTaskAccountStrategist = false;
		//             Boolean createTaskSalesDev = false;

		//             if(trigger.isInsert){
		//                 if(record.Submitted_for_Production__c){
		//                     if(record.Account_Strategist__c != null){
		//                         createTaskAccountStrategist = true;
		//                     }

		//                     if(record.Sales_Dev_Needed__c){
		//                         createTaskSalesDev = true;
		//                     }
		//                 }
		//                 if(rtMapById.get(record.RecordTypeId).getName() == 'RFP' && record.Campaign_Start_Date__c != null && record.Campaign_End_Date__c != null && record.Maximum_Budget__c != null){
		//                     OpportunityLineItem newOLI = new OpportunityLineItem();
		//                     newOLI.OpportunityId = record.Opportunity__c;
		//                     newOLI.PricebookEntryId = pbId;
		//                     newOLI.Quantity = 1;
		//                     newOLI.UnitPrice = record.Maximum_Budget__c;
		//                     newOLI.Start_Date__c = record.Campaign_Start_Date__c;
		//                     newOLI.End_Date__c = record.Campaign_End_Date__c;
		//                     newOLIList.add(newOLI);
		//                 }else if(rtMapById.get(record.RecordTypeId).getName() == 'ThoughtStarter' && record.Campaign_Start_Date__c != null && record.Campaign_End_Date__c != null && record.Budget__c != null){
												
		//                     OpportunityLineItem newOLI = new OpportunityLineItem();
		//                     newOLI.OpportunityId = record.Opportunity__c;
		//                     newOLI.PricebookEntryId = pbId;
		//                     newOLI.Quantity = 1;
		//                     newOLI.UnitPrice = record.Budget__c;
		//                     newOLI.Start_Date__c = record.Campaign_Start_Date__c;
		//                     newOLI.End_Date__c = record.Campaign_End_Date__c;
		//                     newOLIList.add(newOLI);
		//                 }
		//             }else if(trigger.isUpdate){
		//                 ThoughtStarter_RFP__c oldRecord = trigger.oldMap.get(record.Id);

		//                 if(record.Submitted_for_Production__c && !oldRecord.Submitted_for_Production__c){
		//                     if(record.Account_Strategist__c != null){
		//                         createTaskAccountStrategist = true;
		//                     }

		//                     if(record.Sales_Dev_Needed__c){
		//                         createTaskSalesDev = true;
		//                     }
		//                 }else if(record.Submitted_for_Production__c){
		//                     if(record.Account_Strategist__c != null && record.Account_Strategist__c != oldRecord.Account_Strategist__c){
		//                         createTaskAccountStrategist = true;
		//                     }

		//                     if(record.Sales_Dev_Needed__c && record.Sales_Dev_Needed__c != oldRecord.Sales_Dev_Needed__c){
		//                         createTaskSalesDev = true;
		//                     }

		//                     if(!record.Sales_Dev_Needed__c && oldRecord.Sales_Dev_Needed__c){
		//                         tsRFPRemoveSalesDevTask.add(record.Id);
		//                     }
		//                 }

		//                 if(record.Sales_Developer__c != oldRecord.Sales_Developer__c){
		//                     tsRFPNewSalesDevList.add(record.Id);
		//                 }
		//                 if(rtMapById.get(record.RecordTypeId).getName() == 'RFP' && record.Campaign_Start_Date__c != null && record.Campaign_End_Date__c != null && record.Maximum_Budget__c != null && (record.Campaign_Start_Date__c != oldRecord.Campaign_Start_Date__c || record.Campaign_End_Date__c != oldRecord.Campaign_End_Date__c || record.Maximum_Budget__c != oldRecord.Maximum_Budget__c)){
		//                     opportunityNeedUncatRevUpdateMap.put(record.Opportunity__c, record);
		//                 }else if(rtMapById.get(record.RecordTypeId).getName() == 'ThoughtStarter' && record.Campaign_Start_Date__c != null && record.Campaign_End_Date__c != null && record.Budget__c != null && (record.Campaign_Start_Date__c != oldRecord.Campaign_Start_Date__c || record.Campaign_End_Date__c != oldRecord.Campaign_End_Date__c || record.Budget__c != oldRecord.Budget__c)){
		//                     opportunityNeedUncatRevUpdateMap.put(record.Opportunity__c, record);
		//                 }
		//             }

		//             if(createTaskAccountStrategist && rtMapById.get(record.RecordTypeId).getName().equals('RFP')){
		//                 Task newTask = new Task();
		//                 newTask.OwnerId = record.Account_Strategist__c;
		//                 newTask.WhatId = record.Id;
		//                 newTask.Type = 'Other';
		//                 newTask.Purpose__c = 'Produce ' + rtMapById.get(record.RecordTypeId).getName() + (rtMapById.get(record.RecordTypeId).getName().equals('RFP') ? ' Media Plan' : '');
		//                 newTask.ActivityDate = record.Internal_Due_Date__c;
		//                 newTask.Subject = rtMapById.get(record.RecordTypeId).getName() + ' has been submitted';

		//                 newTaskList.add(newTask);
		//             }else if(createTaskAccountStrategist && rtMapById.get(record.RecordTypeId).getName().equals('ThoughtStarter')){
		//                 oppAccStrategistIdMap.put(record.Opportunity__c, record.Account_Strategist__c);
		//             }

		//             if(createTaskSalesDev && String.isNotBlank(record.Sales_Developer__c)){
		//                 Task newTask = new Task();
		//                 newTask.OwnerId = record.Sales_Developer__c;
		//                 newTask.WhatId = record.Id;
		//                 newTask.Type = 'Other';
		//                 newTask.Purpose__c = 'Produce ' + rtMapById.get(record.RecordTypeId).getName() + (rtMapById.get(record.RecordTypeId).getName().equals('RFP') ? ' Pitch Deck' : '');
		//                 newTask.ActivityDate = record.Internal_Due_Date__c;
		//                 newTask.Subject = rtMapById.get(record.RecordTypeId).getName() + ' has been submitted';

		//                 newTaskList.add(newTask);
		//             }else if(createTaskSalesDev){
		//                 for(Integer i = 0; i < salesDevTeamIdList.size(); i++){
		//                     Task newTask = new Task();
		//                     newTask.OwnerId = salesDevTeamIdList[i];
		//                     newTask.WhatId = record.Id;
		//                     newTask.Type = 'Other';
		//                     newTask.Purpose__c = 'Produce ' + rtMapById.get(record.RecordTypeId).getName() + (rtMapById.get(record.RecordTypeId).getName().equals('RFP') ? ' Pitch Deck' : '');
		//                     newTask.ActivityDate = record.Internal_Due_Date__c;
		//                     newTask.Subject = rtMapById.get(record.RecordTypeId).getName() + ' has been submitted';

		//                     newTaskList.add(newTask);
		//                 }
		//             }
		//         }

		//         if(!tsRFPRemoveSalesDevTask.isEmpty()){
		//             List<Task> cancelTaskList = new List<Task>();
		//             for(ThoughtStarter_RFP__c record : [select Id, (select OwnerId, WhatId from Tasks where isClosed = false and Owner.UserRole.DeveloperName = 'Sales_Development') from ThoughtStarter_RFP__c where Id IN : tsRFPRemoveSalesDevTask]){
		//                 for(Task childRecord : record.Tasks){
		//                     childRecord.Status = 'Cancelled';
		//                     if(String.isNotBlank(ChildRecord.Description)){
		//                         childRecord.Description = 'Cancelled because sales development was not needed! ' + childRecord.Description;
		//                     }else{
		//                         childRecord.Description = 'Cancelled because sales development was not needed!';
		//                     }
		//                     cancelTaskList.add(childRecord); 
		//                 }
		//             }
		//             if(!cancelTaskList.isEmpty()){
		//                 update cancelTaskList;
		//             }
		//         }

		//         if(!tsRFPNewSalesDevList.isEmpty()){
		//             List<Task> updateTaskOwnerList = new List<Task>();
		//             List<Task> deleteTaskList = new List<Task>();
		//             for(ThoughtStarter_RFP__c record : [select Id, (select OwnerId, WhatId from Tasks where isClosed = false and Owner.UserRole.DeveloperName = 'Sales_Development') from ThoughtStarter_RFP__c where Id IN : tsRFPNewSalesDevList]){
		//                 if(record.Tasks.size() == 1 && record.Tasks[0].OwnerId != trigger.newMap.get(record.Id).Sales_Developer__c){
		//                     record.Tasks[0].OwnerId = trigger.newMap.get(record.Id).Sales_Developer__c;
		//                     updateTaskOwnerList.add(record.Tasks[0]);
		//                 }else if(record.Tasks.size() > 1){
		//                     Boolean needTaskAssign = true;
		//                     for(Task childRecord : record.Tasks){
		//                         if(childRecord.OwnerId == trigger.newMap.get(record.Id).Sales_Developer__c){
		//                             needTaskAssign = false;
		//                         }else{
		//                             deleteTaskList.add(childRecord);
		//                         }
		//                     }
		//                     if(needTaskAssign){
		//                         deleteTaskList[(deleteTaskList.size() - 1)].OwnerId = trigger.newMap.get(record.Id).Sales_Developer__c;
		//                         updateTaskOwnerList.add(deleteTaskList[deleteTaskList.size() - 1]);
		//                         system.debug(updateTaskOwnerList);
		//                         deleteTaskList.remove(deleteTaskList.size() - 1);
		//                     }
		//                 }
		//             }


		//             Database.DMLOptions dmlo = new Database.DMLOptions();
		//             dmlo.EmailHeader.triggerUserEmail = true;
		//             database.update(updateTaskOwnerList, dmlo);
		//             if(!deleteTaskList.isEmpty()){
		//                 delete deleteTaskList;
		//             }
		//         }

		//         if(!newTaskList.isEmpty()){
		//             Database.DMLOptions dmlo = new Database.DMLOptions();
		//             dmlo.EmailHeader.triggerUserEmail = true;
		//             database.insert(newTaskList, dmlo);
		//         }

		//         if(!oppAccStrategistIdMap.isEmpty()){
		//             List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();

		//             for(Opportunity record : [select Id, Name from Opportunity where Id IN : oppAccStrategistIdMap.keySet()]){
		//                 Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		//                 mail.setTargetObjectId(oppAccStrategistIdMap.get(record.Id));

		//                 String subject = record.Name + ': ThoughtStarter Submitted!';
		//                 String bodyText = 'A ThoughtStarter has been submitted for Opportunity: <a href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + record.Id + '">' + record.Name + '</a>';

		//                 mail.setSubject(subject);
		//                 mail.setHTMLBody(bodyText);
		//                 mail.saveAsActivity = false;
		//                 emailList.add(mail);
		//             }

		//             Messaging.sendEmail(emailList);
		//         }

		//         if(!newOLIList.isEmpty()){
		//             insert newOLIList;
		//         }
						
		//         if(!opportunityNeedUncatRevUpdateMap.isEmpty()){
		//             List<OpportunityLineItem> updateOLIList = new List<OpportunityLineItem>();
		//             for(OpportunityLineItem record : [select Id, UnitPrice, Start_Date__c, End_Date__c, OpportunityId from OpportunityLineItem where PricebookEntryId =: pbId and OpportunityId IN: opportunityNeedUncatRevUpdateMap.keySet()]){
		//                 if(rtMapById.get(opportunityNeedUncatRevUpdateMap.get(record.OpportunityId).RecordTypeId).getName() == 'ThoughtStarter'){
		//                     record.UnitPrice = opportunityNeedUncatRevUpdateMap.get(record.OpportunityId).Budget__c;
		//                 }else{
		//                     record.UnitPrice = opportunityNeedUncatRevUpdateMap.get(record.OpportunityId).Maximum_Budget__c;
		//                 }
		//                 record.Start_Date__c = opportunityNeedUncatRevUpdateMap.get(record.OpportunityId).Campaign_Start_Date__c;
		//                 record.End_Date__c = opportunityNeedUncatRevUpdateMap.get(record.OpportunityId).Campaign_End_Date__c;
		//                 updateOLIList.add(record);
		//             }
		//             update updateOLIList;
		//         }
		//     }
		// }
}