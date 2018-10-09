/*
    Created On: 09-Mar-2015
    Purpose: This class AP_OpportunityServices will creates a Task when Opportunity is Closed Won.
    --------------------------------------------------------------------------
    Modified By: Rusty Valino
    Modified On: 12-May-2015
    Change Description: Create tasks for ThoughtStarters/RFPs based on Opportunity Stage Changes
     
 */

public class AP_OpportunityServices {

    public static void createTask(Map<Id,Opportunity> newMap, Map<Id,Opportunity> oldMap) {
        List<Task> taskList = new List<Task>();
        Map<Id,Schema.RecordTypeInfo> rtMapById = Schema.SObjectType.Opportunity.getRecordTypeInfosById();
        List<National_Opp_Stage_Task_Email__c> nationalTaskOppStageMap = National_Opp_Stage_Task_Email__c.getAll().values();
        Map<Id, National_Opp_Stage_Task_Email__c> oppIdStageTaskEmailMap = new Map<Id, National_Opp_Stage_Task_Email__c>();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        
        for(Opportunity oppty: newMap.values()) { 
            if(rtMapById.get(oppty.RecordTypeId).getName().containsIgnoreCase('Concierge') && oppty.isWon && !oldMap.get(oppty.Id).isWon) {
                Task tsk = new Task();
                tsk.Subject = 'Please start onboarding';
                tsk.OwnerID = oppty.VenueRep__c != NULL ? oppty.VenueRep__c : label.ConciergeTaskAssignment ;
                tsk.ActivityDate = date.today().adddays(7);
                tsk.WhatId = oppty.id;
                taskList.add(tsk);
            }

            if(oppty.StageName != oldMap.get(oppty.Id).StageName && rtMapById.get(oppty.RecordTypeId).getName().containsIgnoreCase('National')){
                for(National_Opp_Stage_Task_Email__c record : nationalTaskOppStageMap){
                    if(record.Name.equalsIgnoreCase(oppty.StageName)){
                        oppIdStageTaskEmailMap.put(oppty.Id, record);
                    }
                }
            }
        
        }

        if(!taskList.isEmpty()){
            insert taskList;
        }

        if(!oppIdStageTaskEmailMap.isEmpty()){
            List<Task> newTaskList = new List<Task>();
            List<Id> salesDevTeamIdList = new List<Id>();

            for(GroupMember record : [select UserOrGroupId from GroupMember where Group.DeveloperName = 'Sales_Dev_Team']){
                salesDevTeamIdList.add(record.UserOrGroupId);
            }

            for(Opportunity record : [select Id, Name, OwnerId, StageName, (select Id, Sales_Dev_Needed__c, Account_Strategist__c, RecordType.Name, Sales_Developer__c from ThoughtStarters_RFPs__r) from Opportunity where ID in : oppIdStageTaskEmailMap.keySet()]){
                for(ThoughtStarter_RFP__c childRecord : record.ThoughtStarters_RFPs__r){
                    //Sales Rep Task and Email Notification
                    if(oppIdStageTaskEmailMap.get(record.Id).Create_Task_for_Sales_Rep__c && (oppIdStageTaskEmailMap.get(record.Id).Evaluate_for_ThoughtStarter__c && childRecord.RecordType.Name == 'ThoughtStarter' || oppIdStageTaskEmailMap.get(record.Id).Evaluate_for_RFP__c && childRecord.RecordType.Name == 'RFP')){
                        Task newTask = new Task();
                        newTask.Subject = oppIdStageTaskEmailMap.get(record.Id).Subject__c;
                        newTask.Purpose__c = oppIdStageTaskEmailMap.get(record.Id).Purpose__c;
                        newTask.WhatId = childRecord.Id;
                        newTask.OwnerId = record.OwnerId;
                        newTask.Type = 'Other';
                        newTaskList.add(newTask);
                    }
                    if(oppIdStageTaskEmailMap.get(record.Id).Email_Sales_Rep__c && (oppIdStageTaskEmailMap.get(record.Id).Evaluate_for_ThoughtStarter__c && childRecord.RecordType.Name == 'ThoughtStarter' || oppIdStageTaskEmailMap.get(record.Id).Evaluate_for_RFP__c && childRecord.RecordType.Name == 'RFP')){
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setTargetObjectId(record.OwnerId);

                        String subject = (String.isNotBlank(oppIdStageTaskEmailMap.get(record.Id).Subject__c)) ? record.Name + ': ' + oppIdStageTaskEmailMap.get(record.Id).Subject__c : record.Name + ': Update';
                        String bodyText = (String.isNotBlank(oppIdStageTaskEmailMap.get(record.Id).Comment__c)) ? oppIdStageTaskEmailMap.get(record.Id).Comment__c.replace('{Name}', record.Name) : record.Name + ': Update';

                        mail.setSubject(subject);
                        mail.setPlainTextBody(bodyText);
                        mail.saveAsActivity = false;
                        emailList.add(mail);
                    }

                    //Account Strategist Task and Email Notification
                    if(oppIdStageTaskEmailMap.get(record.Id).Create_Task_for_Account_Strategist__c && (oppIdStageTaskEmailMap.get(record.Id).Evaluate_for_ThoughtStarter__c && childRecord.RecordType.Name == 'ThoughtStarter' || oppIdStageTaskEmailMap.get(record.Id).Evaluate_for_RFP__c && childRecord.RecordType.Name == 'RFP')){
                        Task newTask = new Task();
                        newTask.Subject = oppIdStageTaskEmailMap.get(record.Id).Subject__c;
                        newTask.Purpose__c = oppIdStageTaskEmailMap.get(record.Id).Purpose__c;
                        newTask.WhatId = childRecord.Id;
                        newTask.OwnerId = childRecord.Account_Strategist__c;
                        newTask.Type = 'Other';
                        newTaskList.add(newTask);
                    }
                    if(oppIdStageTaskEmailMap.get(record.Id).Email_Account_Strategist__c && (oppIdStageTaskEmailMap.get(record.Id).Evaluate_for_ThoughtStarter__c && childRecord.RecordType.Name == 'ThoughtStarter' || oppIdStageTaskEmailMap.get(record.Id).Evaluate_for_RFP__c && childRecord.RecordType.Name == 'RFP')){
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setTargetObjectId(childRecord.Account_Strategist__c);

                        String subject = (String.isNotBlank(oppIdStageTaskEmailMap.get(record.Id).Subject__c)) ? record.Name + ': ' + oppIdStageTaskEmailMap.get(record.Id).Subject__c : record.Name + ': Update';
                        String bodyText = (String.isNotBlank(oppIdStageTaskEmailMap.get(record.Id).Comment__c)) ? oppIdStageTaskEmailMap.get(record.Id).Comment__c.replace('{Name}', record.Name) : record.Name + ': Update';

                        mail.setSubject(subject);
                        mail.setPlainTextBody(bodyText);
                        mail.saveAsActivity = false;
                        emailList.add(mail);
                    }

                    //Sales Dev Team Task and Email Notification
                    if(childRecord.Sales_Dev_Needed__c && oppIdStageTaskEmailMap.get(record.Id).Create_Task_for_Sales_Dev_Team__c && (oppIdStageTaskEmailMap.get(record.Id).Evaluate_for_ThoughtStarter__c && childRecord.RecordType.Name == 'ThoughtStarter' || oppIdStageTaskEmailMap.get(record.Id).Evaluate_for_RFP__c && childRecord.RecordType.Name == 'RFP')){
                        /*for(Id salesDevId : salesDevTeamIdList){
                            Task newTask = new Task();
                            newTask.Subject = oppIdStageTaskEmailMap.get(record.Id).Subject__c;
                            newTask.Purpose__c = oppIdStageTaskEmailMap.get(record.Id).Purpose__c;
                            newTask.WhatId = childRecord.Id;
                            newTask.OwnerId = salesDevId;
                            newTask.Type = 'Other';
                            newTaskList.add(newTask);
                        }*/
                        if(String.isNotBlank(childRecord.Sales_Developer__c)){
                            Task newTask = new Task();
                            newTask.Subject = oppIdStageTaskEmailMap.get(record.Id).Subject__c;
                            newTask.Purpose__c = oppIdStageTaskEmailMap.get(record.Id).Purpose__c;
                            newTask.WhatId = childRecord.Id;
                            newTask.OwnerId = childRecord.Sales_Developer__c;
                            newTask.Type = 'Other';
                            newTaskList.add(newTask);
                        }
                    }
                    if(childRecord.Sales_Dev_Needed__c && oppIdStageTaskEmailMap.get(record.Id).Email_Sales_Dev_Team__c && (oppIdStageTaskEmailMap.get(record.Id).Evaluate_for_ThoughtStarter__c && childRecord.RecordType.Name == 'ThoughtStarter' || oppIdStageTaskEmailMap.get(record.Id).Evaluate_for_RFP__c && childRecord.RecordType.Name == 'RFP')){
                        /*for(Id salesDevId : salesDevTeamIdList){
                            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                            mail.setTargetObjectId(salesDevId);

                            String subject = (String.isNotBlank(oppIdStageTaskEmailMap.get(record.Id).Subject__c)) ? record.Name + ': ' + oppIdStageTaskEmailMap.get(record.Id).Subject__c : record.Name + ': Update';
                            String bodyText = (String.isNotBlank(oppIdStageTaskEmailMap.get(record.Id).Comment__c)) ? oppIdStageTaskEmailMap.get(record.Id).Comment__c.replace('{Name}', record.Name) : record.Name + ': Update';

                            mail.setSubject(subject);
                            mail.setPlainTextBody(bodyText);
                            mail.saveAsActivity = false;
                            emailList.add(mail);
                        }*/
                        if(String.isNotBlank(childRecord.Sales_Developer__c)){
                            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                            mail.setTargetObjectId(childRecord.Sales_Developer__c);

                            String subject = (String.isNotBlank(oppIdStageTaskEmailMap.get(record.Id).Subject__c)) ? record.Name + ': ' + oppIdStageTaskEmailMap.get(record.Id).Subject__c : record.Name + ': Update';
                            String bodyText = (String.isNotBlank(oppIdStageTaskEmailMap.get(record.Id).Comment__c)) ? oppIdStageTaskEmailMap.get(record.Id).Comment__c.replace('{Name}', record.Name) : record.Name + ': Update';

                            mail.setSubject(subject);
                            mail.setPlainTextBody(bodyText);
                            mail.saveAsActivity = false;
                            emailList.add(mail);
                        }
                    }
                }
            }

            if(newTaskList != NULL && !newTaskList.isEmpty()) {
                Database.DMLOptions dmlo = new Database.DMLOptions();
                dmlo.EmailHeader.triggerUserEmail = true;
                dmlo.optAllOrNone = false;
                database.insert(newTaskList, dmlo);
                //Database.insert(newTaskList,false);
            }
        }

        if(!emailList.isEmpty()){
            Messaging.sendEmail(emailList);
        }
        
    }

}