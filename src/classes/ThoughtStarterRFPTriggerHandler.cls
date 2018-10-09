public without sharing class ThoughtStarterRFPTriggerHandler implements XOTrigger{
    
    //  record type id map
    private Map<Id,Schema.RecordTypeInfo> rtMapById = Schema.SObjectType.ThoughtStarter_RFP__c.getRecordTypeInfosById();

    // the field list 
    private List<Schema.FieldSetMember> rfpFieldSetList = SObjectType.ThoughtStarter_RFP__c.FieldSets.Required_RFP_Fields.getFields();

    // the field sets which 
    private List<Schema.FieldSetMember> tsFieldSetList = SObjectType.ThoughtStarter_RFP__c.FieldSets.Required_ThoughtStarter_Fields.getFields();
    
    // the user id list the menber of group Sales Dev Team
    private List<Id> salesDevTeamIdList = new List<Id>();

    // the Recordtype Id and associated Opportunity Id Set Map, used for checking the duplicate recordtype 
    private Map<Id, Set<Id>> rtIdOppIdSetMap = new Map<Id, Set<Id>>();

    // the Opportunity Id Map
    private Map<Id, Opportunity> opportunityIdMap = new Map<Id, Opportunity>();

    private List<Task> newTaskList = new List<Task>();

    // When a new TS or RFP has been insert under the Opp without OpportunityLineItem, we should insert a new OpportunityLineItem
    private List<OpportunityLineItem> newOLIList = new List<OpportunityLineItem>();

    // The Map of existing OpportunityLineItem under the associated Opp
    private Map<Id, OpportunityLineItem> existingOLIMap = new Map<Id, OpportunityLineItem>();

    //  the Map of TSRFP which need to u
    private Map<Id, ThoughtStarter_RFP__c> opportunityNeedUncatRevUpdateMap = new Map<Id, ThoughtStarter_RFP__c>();

    private Id pbId;//PricebookEntry ID

    // the old salesdev task should be deleted
    private List<Id> tsRFPNewSalesDevList = new List<Id>();
    private Map<Id,Id> transerTaskTSRFPIdMap = new Map<Id,Id>();


    private static final String RFPSUBMITTEDTASKSUBJECT = system.label.RFPSubmittedTaskSubject;
    /**
     * Method used to bulkify all data needed in any "before" action of a trigger.
     */
    public void bulkBefore() {

        Set<Id> allOppIds = new Set<Id>();

        //for query all the associated Opporunity
        if (trigger.isInsert || trigger.isUpdate) {
            for (Integer i = 0; i< trigger.new.size(); i++) {
                ThoughtStarter_RFP__c currentTSRFP = (ThoughtStarter_RFP__c)trigger.new[i];
                allOppIds.add(currentTSRFP.Opportunity__c);

            }

            // get the all recordtypeId map
            for(Id record : rtMapById.keySet()){
          rtIdOppIdSetMap.put(record, new Set<Id>());
        }
            

            //  retrieve all Opportunity and the child TSRFP 
            //SIVA VANKADARU CSP-3148 09/11/2018 Added Account_Manager__c field to the below SOQL
            List<Opportunity> allOppList  = [SELECT Id, Name,AccStrategist__c, Account_Manager__c, Sales_Planner__c, Amount, 
                                                                                    (SELECT Id,RecordType.Name,RecordTypeId,Opportunity__c FROM ThoughtStarters_RFPs__r) 
                                                                            FROM Opportunity 
                                                                            WHERE Id IN : allOppIds];

            
            for (Integer i = 0 ; i< allOppList.size(); i++) {
                Opportunity currentOpportunity = (Opportunity)allOppList[i];

                // to generate the map of recordtypeId and Opportunity Id Set
                if (currentOpportunity.ThoughtStarters_RFPs__r.size()>0) {
                    for (ThoughtStarter_RFP__c currentTSRFP: currentOpportunity.ThoughtStarters_RFPs__r) {
                        if(rtIdOppIdSetMap.containsKey(currentTSRFP.RecordTypeId)){
                  rtIdOppIdSetMap.get(currentTSRFP.RecordTypeId).add(currentTSRFP.Opportunity__c);
              }
                    }
                }

                opportunityIdMap.put(currentOpportunity.id, currentOpportunity);
            }
        }
    }

    /**
     *   Method used to bulkify all data needed in any "after" action of a trigger.
     */
    public void bulkAfter() {
        if (trigger.isInsert || trigger.isUpdate) {

            // Retrive the active member of the group Sales_Dev_Team
            Set<Id> userIdSet = new Set<Id>();
            for(GroupMember currentGroupMenber : [select UserOrGroupId from GroupMember where Group.DeveloperName = 'Sales_Dev_Team']){
          userIdSet.add(currentGroupMenber.UserOrGroupId);
        }
        for(User currentUser : [SELECT Id FROM User WHERE Id in: userIdSet AND isActive = true]){
            salesDevTeamIdList.add(currentUser.Id);
        }

        // Id pbId;//PricebookEntry ID
        if(!Test.isRunningTest()){
          pbId = [select Id from PricebookEntry where Name = 'Uncategorized Revenue' and Pricebook2.IsActive = true and Pricebook2.IsStandard = true limit 1].Id;
        }else{
          pbId = [select Id from PricebookEntry where Name = 'Uncategorized Revenue' limit 1].Id;
        }


        List<OpportunityLineItem> newOLIList = new List<OpportunityLineItem>();

        // CSP-2278 Incorrect Opp Amount when both TS & RFP exist
        List<Id> oppIdList = new List<Id>();
        for (Integer i = 0; i< trigger.new.size(); i++) {
                ThoughtStarter_RFP__c currentTSRFP = (ThoughtStarter_RFP__c)trigger.new[i];
                oppIdList.add(currentTSRFP.Opportunity__c);

            }

        List<OpportunityLineItem>  oLIList= [select Id, UnitPrice, Start_Date__c, End_Date__c, OpportunityId from OpportunityLineItem 
                                                        where PricebookEntryId =: pbId and OpportunityId  IN :oppIdList];

        // Map of OpportunityId and OpportunityLineItem, use it to check existing OpportunityLineItem for each Opportunity.
        // 1. if Opportunity has an OpportunityLineItem, add a ThoughtStarter_RFP__c would update existing OpportunityLineItem, not add a new OpportunityLineItem.
        // 2. if Opportunity doesn't have an OpportunityLineItem, add a ThoughtStarter_RFP__c would add an OpportunityLineItem.
        for(OpportunityLineItem oli : oLIList){
          existingOLIMap.put(oli.OpportunityId, oli);
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
        ThoughtStarter_RFP__c currentTSRFP = (ThoughtStarter_RFP__c)so;

        //  validate the associated Opp only have one TS and only have one RFP
        if (rtIdOppIdSetMap.containsKey(currentTSRFP.RecordTypeId)) {
            if(rtIdOppIdSetMap.get(currentTSRFP.RecordTypeId).contains(currentTSRFP.Opportunity__c)){
        currentTSRFP.addError('The related Opportunity already has a ' + rtMapById.get(currentTSRFP.RecordTypeId).getName() + '!');
      }
        }

        // always set the field Submitted_for_Production__c to true when a record insert
        currentTSRFP.Submitted_for_Production__c = true;

        // get the recordtype name 
        String recordTypeName = rtMapById.get(currentTSRFP.RecordTypeId).getName();

        // generated the name of TS/RFP
        String recordName = '';

        if(recordTypeName.equals('ThoughtStarter')){
            recordName = 'TS';
      currentTSRFP.Sales_Dev_Needed__c = true;
    }else{
        recordName = recordTypeName;
    }

    Opportunity currentOpportunity = opportunityIdMap.get(currentTSRFP.Opportunity__c);
    recordName += '-' + currentOpportunity.Name;
    currentTSRFP.Name = recordName.left(80);

    // If the buget of TS/ Max Budget of RFP is null, set the value to associated Opportunity's Amount
    //SIVA VANKADARU CSP-3148 09/11/2018 replaced AccStrategist__c with Account_Manager__c in below 2 lines
    currentTSRFP.Account_Strategist__c = currentOpportunity.Account_Manager__c;
    currentTSRFP.Sales_Planner__c = currentOpportunity.Sales_Planner__c;
    if(recordTypeName.equals('ThoughtStarter') && currentTSRFP.Budget__c == null){
      currentTSRFP.Budget__c = currentOpportunity.Amount;
    }else if(recordTypeName.equals('RFP') && currentTSRFP.Maximum_Budget__c == null){
      currentTSRFP.Maximum_Budget__c = currentOpportunity.Amount;
    }

    // if the current TSRFP is RFP, and the associated Opp has a TS, assign the TS.id to the field Related_ThoughtStarter__c
    if (currentOpportunity.ThoughtStarters_RFPs__r.size()>0) {
        ThoughtStarter_RFP__c relatedTSFRP = currentOpportunity.ThoughtStarters_RFPs__r[0];
        if (relatedTSFRP.RecordType.Name == 'ThoughtStarter') {
                currentTSRFP.Related_ThoughtStarter__c = relatedTSFRP.Id;
        }
    }
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
        ThoughtStarter_RFP__c currentTSRFP = (ThoughtStarter_RFP__c)so;
        ThoughtStarter_RFP__c oldTSRFP = (ThoughtStarter_RFP__c)oldSo;

        // validate the associated Opp only have one TS and only have one RFP
        if (currentTSRFP.RecordTypeId != oldTSRFP.RecordTypeId) {
        if (rtIdOppIdSetMap.containsKey(currentTSRFP.RecordTypeId)) {
                if(rtIdOppIdSetMap.get(currentTSRFP.RecordTypeId).contains(currentTSRFP.Opportunity__c)){
              currentTSRFP.addError('The related Opportunity already has a ' + rtMapById.get(currentTSRFP.RecordTypeId).getName() + '!');
            }
            }
        }

        // always set the field Submitted_for_Production__c to true
        currentTSRFP.Submitted_for_Production__c = true;

        // get the recordtype name 
        String recordTypeName = rtMapById.get(currentTSRFP.RecordTypeId).getName();

        // generated the name of TS/RFP
        String recordName = '';

        if(recordTypeName.equals('ThoughtStarter')){
            recordName = 'TS';
    }else{
        recordName = recordTypeName;
    }

    recordName += '-' + opportunityIdMap.get(currentTSRFP.Opportunity__c).Name;
    currentTSRFP.Name = recordName.left(80);
    }

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
        ThoughtStarter_RFP__c currentTSRFP = (ThoughtStarter_RFP__c)so;
        String recordTypeName = rtMapById.get(currentTSRFP.RecordTypeId).getName();

        // if Sales Dev Needed has been checked, we should generate task for Sales Dev
        String purposeStr = 'Produce ' + recordTypeName + (recordTypeName.equals('RFP') ? ' Media Plan' : '');
        String subjectStr = RFPSUBMITTEDTASKSUBJECT;
        subjectStr = subjectStr.replace('RFP', recordTypeName);
        // if the record type is TS, the field Sales_Dev_Needed__c will auto set to true.
        if (recordTypeName.equalsIgnoreCase('ThoughtStarter')) {
        //  if Sales Developer is not Null, we should only generagte task for Sales Developer,  
            //  otherwise we should generate task for the Sales Developer Team
            if (String.isNotBlank(currentTSRFP.Sales_Developer__c)) {
                newTaskList.add(generateTask(currentTSRFP.Sales_Developer__c, currentTSRFP, purposeStr, subjectStr));
            }
            else{
                for(Integer i = 0; i < salesDevTeamIdList.size(); i++){
                    newTaskList.add(generateTask(salesDevTeamIdList[i], currentTSRFP, purposeStr, subjectStr));
                }
            }
        }
        else{
            //SIVA VANKADARU CSP-3148 09/11/2018 replaced Sales_Planner__c with AccStrategist__c in below 2 lines
            if (String.isNotBlank(currentTSRFP.Sales_Planner__c)) {
            newTaskList.add(generateTask(currentTSRFP.Sales_Planner__c, currentTSRFP, purposeStr, subjectStr));
            }
            //  When Sales_Dev_Needed__c is checked for RFP,
            //  if Sales Developer is not Null, we should only generagte task for Sales Developer  
            //  otherwise we should generate task for the Sales Developer Team 
            if (currentTSRFP.Sales_Dev_Needed__c && String.isNotBlank(currentTSRFP.Sales_Developer__c)) {
                newTaskList.add(generateTask(currentTSRFP.Sales_Developer__c, currentTSRFP, purposeStr, subjectStr));
            }
            else if(currentTSRFP.Sales_Dev_Needed__c){
                for(Integer i = 0; i < salesDevTeamIdList.size(); i++){
                    newTaskList.add(generateTask(salesDevTeamIdList[i], currentTSRFP, purposeStr, subjectStr));
                }
            }
        }

        // if an Opp has Opportunity Line Item, we should update the OLI, otherwise, we should created a new OLI for the OPP
        if (existingOLIMap.containsKey(currentTSRFP.Opportunity__c)) {
            if(recordTypeName.equalsIgnoreCase('RFP')){
                opportunityNeedUncatRevUpdateMap.put(currentTSRFP.Opportunity__c, currentTSRFP);
      }
      else if(recordTypeName.equalsIgnoreCase('ThoughtStarter')){
                opportunityNeedUncatRevUpdateMap.put(currentTSRFP.Opportunity__c, currentTSRFP);
      }
        }
        else{

            OpportunityLineItem newOLI = new OpportunityLineItem();
      newOLI.OpportunityId = currentTSRFP.Opportunity__c;
      newOLI.PricebookEntryId = pbId;
      newOLI.Quantity = 1;
      newOLI.UnitPrice = recordTypeName.equalsIgnoreCase('RFP') ? currentTSRFP.Maximum_Budget__c : currentTSRFP.Budget__c;
      newOLI.Start_Date__c = currentTSRFP.Campaign_Start_Date__c;
      newOLI.End_Date__c = currentTSRFP.Campaign_End_Date__c;
      newOLIList.add(newOLI);
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
        ThoughtStarter_RFP__c currentTSRFP = (ThoughtStarter_RFP__c)so;
        ThoughtStarter_RFP__c oldTSRFP = (ThoughtStarter_RFP__c)oldSo;

        String recordTypeName = rtMapById.get(currentTSRFP.RecordTypeId).getName();

        // update the OLI for the associated Opp
        if (currentTSRFP.Campaign_Start_Date__c != oldTSRFP.Campaign_Start_Date__c || 
                    currentTSRFP.Campaign_End_Date__c != oldTSRFP.Campaign_End_Date__c || 
                    (recordTypeName.equalsIgnoreCase('RFP') && currentTSRFP.Maximum_Budget__c != oldTSRFP.Maximum_Budget__c) ||
                    (recordTypeName.equalsIgnoreCase('ThoughtStarter') && currentTSRFP.Budget__c != oldTSRFP.Budget__c)) {

            opportunityNeedUncatRevUpdateMap.put(currentTSRFP.Opportunity__c, currentTSRFP);    
        }



        // if Sales Dev Needed has been checked, we should generate task for Sales Dev
        String purposeStr = 'Produce ' + recordTypeName + (recordTypeName.equals('RFP') ? ' Media Plan' : '');
        String subjectStr = RFPSUBMITTEDTASKSUBJECT;
        subjectStr = subjectStr.replace('RFP', recordTypeName);

        
        // if the field Sales_Dev_Needed__c has been changed to checked, we should create the task and assign to Sales_Developer__c
        if (currentTSRFP.Sales_Dev_Needed__c && !oldTSRFP.Sales_Dev_Needed__c) {
            if (String.isNotBlank(currentTSRFP.Sales_Developer__c)){
                newTaskList.add(generateTask(currentTSRFP.Sales_Developer__c, currentTSRFP, purposeStr, subjectStr));
            }else{
                for(Integer i = 0; i < salesDevTeamIdList.size(); i++){
                    newTaskList.add(generateTask(salesDevTeamIdList[i], currentTSRFP, purposeStr, subjectStr));
                }
            }
        }
        // if the field Sales_Dev_Needed__c has been changed to Unchecked, we should delete all the Sales Team Task
        else if (!currentTSRFP.Sales_Dev_Needed__c && oldTSRFP.Sales_Dev_Needed__c) {
            tsRFPNewSalesDevList.add(currentTSRFP.id);
        }
        // If the Sales_Developer__c changed, we should update the task for the Sales Team
        else if (currentTSRFP.Sales_Dev_Needed__c && currentTSRFP.Sales_Developer__c != oldTSRFP.Sales_Developer__c) {
            if (String.isNotBlank(currentTSRFP.Sales_Developer__c)) {
                transerTaskTSRFPIdMap.put(currentTSRFP.id,currentTSRFP.Sales_Developer__c);
                tsRFPNewSalesDevList.add(currentTSRFP.id);
            }
            else if(String.isBlank(currentTSRFP.Sales_Developer__c)){
                for(Integer i = 0; i < salesDevTeamIdList.size(); i++){
                    if (salesDevTeamIdList[i] != oldTSRFP.Sales_Developer__c) {
                    newTaskList.add(generateTask(salesDevTeamIdList[i], currentTSRFP, purposeStr, subjectStr));
                    }
                }
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
    public void beforeAndFinally() {

    }

    /**
    *   All final logic in the "after" context should be done at this point such as modification to objects outside of
    *   the current object. At this point all updates to the current trigger transaction should be
    *   complete and all validation done.
    */
    public void afterAndFinally() {
        List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();

        // if Developer has been changed, we should delete the task which assigned to other old developers.
        if (!tsRFPNewSalesDevList.isEmpty()) {

            List<Task> deleteTaskList = new List<Task>();
            List<Task> updateTaskList = new List<Task>();
            // get the all task which should be deleted
            for(ThoughtStarter_RFP__c currentTSRFP : [select Id, (select OwnerId, WhatId from Tasks where isClosed = false and Owner.UserRole.DeveloperName = 'Sales_Development') 
                                                    from ThoughtStarter_RFP__c where Id IN : tsRFPNewSalesDevList]){
                    
        if(currentTSRFP.Tasks.size() == 1 && transerTaskTSRFPIdMap.containsKey(currentTSRFP.id)){
            for(Task childRecord : currentTSRFP.Tasks){
                childRecord.OwnerId = transerTaskTSRFPIdMap.get(currentTSRFP.id);
            }
            }
            else if (currentTSRFP.Tasks.size() >1 && transerTaskTSRFPIdMap.containsKey(currentTSRFP.id)) {
                Id taskOwnerId = transerTaskTSRFPIdMap.get(currentTSRFP.id);
                for(Task childRecord : currentTSRFP.Tasks){
                    if (childRecord.OwnerId != taskOwnerId) {
                        deleteTaskList.add(childRecord);
                    }
            }
            }
            else if (currentTSRFP.Tasks.size() >= 1) {
                deleteTaskList.addAll(currentTSRFP.Tasks);
            }
            }   


            if (!deleteTaskList.isEmpty()) {
            delete deleteTaskList;
        }

        if (!updateTaskList.isEmpty()) {
            Database.DMLOptions dmlo = new Database.DMLOptions();
        dmlo.EmailHeader.triggerUserEmail = true;
        List<Database.SaveResult> saveResultsList = Database.update(updateTaskList, dmlo);
        xoExceptionList.addAll(ExceptionUtility.consumeException(saveResultsList));
        }
        }

        if (!newTaskList.isEmpty()) {
            Database.DMLOptions dmlo = new Database.DMLOptions();
      dmlo.EmailHeader.triggerUserEmail = true;
      List<Database.SaveResult> saveResultsList = Database.insert(newTaskList, dmlo);
      xoExceptionList.addAll(ExceptionUtility.consumeException(saveResultsList));
        }

        if(!newOLIList.isEmpty()){
            List<Database.SaveResult> saveResultsList = Database.insert(newOLIList,false);
      xoExceptionList.addAll(ExceptionUtility.consumeException(saveResultsList));
    }

    if(!opportunityNeedUncatRevUpdateMap.isEmpty()){
      List<OpportunityLineItem> updateOLIList = new List<OpportunityLineItem>();
      for(OpportunityLineItem currentOppLI : [select Id, UnitPrice, Start_Date__c, End_Date__c, OpportunityId from OpportunityLineItem 
                                        where PricebookEntryId =: pbId and OpportunityId IN: opportunityNeedUncatRevUpdateMap.keySet()]){
        
        ThoughtStarter_RFP__c currentTSRFP = opportunityNeedUncatRevUpdateMap.get(currentOppLI.OpportunityId);
        String recordTypeName = rtMapById.get(currentTSRFP.RecordTypeId).getName();
        if(recordTypeName.equalsIgnoreCase('ThoughtStarter')){
          currentOppLI.UnitPrice = currentTSRFP.Budget__c;
        }else{
          currentOppLI.UnitPrice = currentTSRFP.Maximum_Budget__c;
        }
        currentOppLI.Start_Date__c = currentTSRFP.Campaign_Start_Date__c;
        currentOppLI.End_Date__c = currentTSRFP.Campaign_End_Date__c;
        updateOLIList.add(currentOppLI);
      }

      List<Database.SaveResult> saveResultsList = Database.update(updateOLIList,false);
      xoExceptionList.addAll(ExceptionUtility.consumeException(saveResultsList));
    }

    if (xoExceptionList.size()>0) {
        insert xoExceptionList;
    }
    }

    /**
   *   [createTask: This method is used to create a task by using data from the current TS/RFP]
   *
   *   @author [Tony Liu]
   *   @date   2017-09-13
   */
  private static Task generateTask(Id ownerUserId, ThoughtStarter_RFP__c tsRFP, String purposeStr, String subjectStr){
        Task newTask = new Task();
    newTask.WhatId = tsRFP.Id;
    newTask.OwnerId = ownerUserId;
    newTask.Type = 'Other';
    newTask.Purpose__c = purposeStr;
    newTask.Subject = subjectStr;
    newTask.ActivityDate = tsRFP.Internal_Due_Date__c;

    return newTask;
    }
}