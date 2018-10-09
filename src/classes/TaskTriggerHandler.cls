public without sharing class TaskTriggerHandler implements XOTrigger{

  // Define some maps, set to store the data used in beforeInsert(), beforeUpdate(), beforeAndFinally() 
  private static final String OPPORTUNITY_OBJECT_PREFIX = Schema.SObjectType.Opportunity.getKeyPrefix();

  // CSP-2686 Task View to Include Account
  // Case prefix
  private static final String CASE_OBJECT_PREFIX = Schema.SObjectType.Case.getKeyPrefix();
  // CSP-2686 Task View to Include Account
  // The map stored the onboarding case with onboarding case's account
  private static Map<Id, Id> onboardingCaseAccMap = new Map<Id, Id>();

  private Map<Id,Out_Of_Office__c> outOfOfficeMap = new Map<Id,Out_Of_Office__c>();
  private Map<Id, String> opportunityIdAndStageNameMap = new Map<Id, String>();
  private Set<Id> salesDevTeamIdSet = new Set<Id>();
  private Map<Id, Id> tsRFPIdSalesDevMap = new Map<Id, Id>();
  private Map<Id, National_TS_RFP_Task_Stage_Mapping__c> tsrfpIdStageMap = new  Map<Id, National_TS_RFP_Task_Stage_Mapping__c>();

  private Set<Id> tsrfpIdSet= new Set<Id>();
  private Set<Id> tsrfpUpdateOppIdSet= new Set<Id>();
  private List<Task> newTaskList = new List<Task>();

  // CSP-2554， if the task related to account, we should set the customer lookup field to current related object.
  private static final String ACCOUNT_OBJECT_PREFIX = Schema.SObjectType.Account.getKeyPrefix();
  private Map<Id, Account> accountIdMap = new Map<Id, Account>();
  
  // onboarding case
  private Map<Id, Case> onboardingCaseMap = new Map<Id, Case>();
  private List<Task> onboardingTaskList = new List<Task>();
  private Set<Id> onboardingCaseIds = new Set<Id>();
  private static List<Task> newTasks = new List<Task>();
  private static List<Case> updateCases = new List<Case>();
  private static List<Messaging.SingleEmailMessage> onboardEmails = new List<Messaging.SingleEmailMessage>();

  private static Map<String, Schema.RecordTypeInfo> taskRecTypeNameMap = Schema.SObjectType.Task.getRecordTypeInfosByName();

  private static String nsTemplate;
  private static String fuTemplate;
  private static String fu2Template;

  // CSP-2674 Add Onboard Outcome + Onboard Email Template
  private static String sclTemplate;

  private static OrgWideEmailAddress orgEmail;
  private static List<BusinessHours> businessHourList;

  // CSP-2709 POC:Quick View for Activity Notes
  // Key: Task Callobject identifier, value: notes
  private static Map<String, String> nvmNotesMap = new Map<String, String>();

  private static Set<String> callObjectIdentifierSet = new Set<String>();

  static{

    businessHourList = [SELECT Id FROM BusinessHours WHERE Name = 'XO Business Hours' LIMIT 1];

    // CSP-2674 Add Onboard Outcome + Onboard Email Template
    // adding the email template Send Calendar Link in the query
    List<EmailTemplate> templateList = [SELECT Id, Body, DeveloperName FROM EmailTemplate WHERE IsActive = True AND 
                    (DeveloperName = 'Follow_Up_1_Get_Started_Auto' OR 
                    DeveloperName = 'No_Show_Follow_Up_Sorry_I_Missed_You_Auto' OR 
                    DeveloperName ='Follow_Up_2_Auto' OR 
                    DeveloperName = 'Send_Calendar_Link')];

    String emailAddress = Label.Onboarding_Email_From_Address;

    List<OrgWideEmailAddress> oweAddresses = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :emailAddress LIMIT 1];
    if (!oweAddresses.isEmpty()) {
      orgEmail = oweAddresses[0];
    }

    // Set onboarding email templates
    if(!templateList.isEmpty()){

      for(EmailTemplate et : templateList){
        if(et.DeveloperName.equals('No_Show_Follow_Up_Sorry_I_Missed_You_Auto')){
          nsTemplate = et.id;
        }
        else if(et.DeveloperName.equals('Follow_Up_1_Get_Started_Auto')){
          fuTemplate = et.id;
        }
        else if(et.DeveloperName.equals('Follow_Up_2_Auto')){
          fu2Template = et.id;
        }
        else if(et.DeveloperName.equals('Send_Calendar_Link')){
          sclTemplate = et.Id;
        }
      }
    }

  }

  public void bulkBefore() {

    //////////////////////////////
    // BULK BEFORE INSERT LOGIC //
    //////////////////////////////
    if(trigger.isInsert){
      Set<Id> taskOwnerIdSet = new Set<Id>();

      // put the Opportunity objects related to the Tasks into the map opportunityIdAndStageNameMap
      Set<Id> opportunityIds = new Set<Id>();
      // CSP-2554
      Set<Id> accountIdSet = new Set<Id>();
      for (Task newTask : (List<Task>)Trigger.new) {
        if (String.isNotBlank(newTask.WhatId) && ((String)newTask.WhatId).startsWith(OPPORTUNITY_OBJECT_PREFIX)) {
          opportunityIds.add(newTask.WhatId);
        }

        // CSP-2554  if the task related to account, we should set the customer lookup field to current related object.
        if (String.isNotBlank(newTask.WhatId) && ((String)newTask.WhatId).startsWith(ACCOUNT_OBJECT_PREFIX)) {
          accountIdSet.add(newTask.WhatId);
        }

        taskOwnerIdSet.add(newTask.ownerId);
      }

      // CSP-2032 - Add logic to only query for Opportunities if the opportunityIds variable is not empty
      if(!opportunityIds.isEmpty()) {
        List<Opportunity> relatedOpportunitiesList = [SELECT Id, StageName FROM Opportunity 
                                                      WHERE Id IN :opportunityIds 
                                                      AND RecordType.Name != 'National'];

        if (!relatedOpportunitiesList.isEmpty()) {
          for (Integer i = 0; i< relatedOpportunitiesList.size() ; i++) {
            Opportunity currentOpportunity = relatedOpportunitiesList[i];
            opportunityIdAndStageNameMap.put(currentOpportunity.Id, currentOpportunity.StageName);
          }
        }
      }
      // CSP-2554  if the task related to account, we should set the customer lookup field to current related object.
      if(!accountIdSet.isEmpty()){
        for (Account currentAccount : [SELECT id, Longest_Past_Due_Date__c, Past_Due_Balance__c FROM Account 
                                      WHERE Past_Due_Balance__c > 0 AND id IN: accountIdSet]) {
          accountIdMap.put(currentAccount.Id,currentAccount);
        }
      }
      //put the Out_Of_Office__c objects related to the Tasks into the map opportunityIdAndStageNameMap
      List<Out_Of_Office__c> oooList = [SELECT Assign_Task_To__c, Assign_From__c, Active__c, Start_Date__c, End_Date__c
                                        FROM Out_Of_Office__c WHERE Assign_From__c IN :taskOwnerIdSet
                                        AND Active__c = True];

      if (!oooList.isEmpty()) {
        for (Integer i = 0; i < oooList.size() ; i++) {
          Out_Of_Office__c currentOutOfOffice = oooList[i];
          outOfOfficeMap.put(currentOutOfOffice.Assign_From__c,currentOutOfOffice);
        }  
      }
    }

    //////////////////////////////
    // BULK BEFORE UPDATE LOGIC //
    //////////////////////////////
    if(trigger.isUpdate){
      // ready the public data which will used in the before method and after method
      salesDevTeamIdSet = new Set<Id>();
      for(GroupMember currentGroupMember : [SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = 'Sales_Dev_Team']){
        salesDevTeamIdSet.add(currentGroupMember.UserOrGroupId);
      }
    }
    // CSP-2686 Task View to Include Account
    // Store all the tasks that relatedTo onboarding Cases
    if(trigger.isInsert || trigger.isUpdate){

      Set<Id> onboardingCaseIdSet = new Set<Id>();

      for(Task newTask : (List<Task>)Trigger.new){

        if (String.isNotBlank(newTask.WhatId) && ((String)newTask.WhatId).startsWith(CASE_OBJECT_PREFIX)){
          onboardingCaseIdSet.add(newTask.WhatId);
        }

        // CSP-2709 POC:Quick View for Activity Notes
        // put all identifier to a set for querying later
        // CSP-3087 Hotfox for Release 5.06 - Non-selective query against large object type
        // Avoid to put null value of call object to the set
        if(String.isNotBlank(newTask.CallObject)){
          callObjectIdentifierSet.add(newTask.CallObject);
        }
      }

      List<Case> onboardingCaseIdList = [SELECT Id, AccountId FROM Case WHERE Id IN: onboardingCaseIdSet 
                                          AND recordtype.Name = '2 - Onboarding' AND AccountId <> NULL];

      for(Case c : onboardingCaseIdList){
        onboardingCaseAccMap.put(c.id, c.AccountId);
      }

      // CSP-3087 Hotfox for Release 5.06 - Non-selective query against large object type
      // to ensure if the set is not empty
      if(!callObjectIdentifierSet.isEmpty()){
        // CSP-2709 POC:Quick View for Activity Notes
        // query NVM interaction event to retrieve the nvm event as well as the note details based on the identifier
        List<NVMContactWorld__InteractionEvent__c> ielist = [Select id, name, NVMContactWorld__Agent__c, NVMContactWorld__Agent__r.Name,
                    NVMContactWorld__IndexedCallObjectIdentifier__c, (SELECT Name,  CreatedDate, NVMContactWorld__Detail__c 
                    FROM NVMContactWorld__Interaction_Event_Notes__r ORDER BY lastmodifieddate DESC LIMIT 1) 
                    FROM NVMContactWorld__InteractionEvent__c WHERE 
                    NVMContactWorld__IndexedCallObjectIdentifier__c IN: callObjectIdentifierSet
                    ORDER BY NVMContactWorld__TimeStamp__c ASC NULLS FIRST];

        // CSP-2709 POC:Quick View for Activity Notes
        // Looping the event list
        for(NVMContactWorld__InteractionEvent__c ie : ielist){

          String detailNote = '';
          String identifierId = '';

          // make sure the identifier is not blank
          if(String.isNotBlank(ie.NVMContactWorld__IndexedCallObjectIdentifier__c)){
            identifierId = ie.NVMContactWorld__IndexedCallObjectIdentifier__c;
          }

          // getting the latest detail under the event record
          List<NVMContactWorld__InteractionEventNote__c> ienlist = ie.NVMContactWorld__Interaction_Event_Notes__r;

          if(!ienlist.isEmpty() && String.isNotBlank(ienlist[0].NVMContactWorld__Detail__c)){
            detailNote = ienlist[0].NVMContactWorld__Detail__c;
          }

          // if the note is empty then set the note to offical term
          if(identifierId!='' && !nvmNotesMap.containsKey(identifierId)){
            if(detailNote==''){
              detailNote = 'This agent saved no notes';
            }
            nvmNotesMap.put(identifierId, detailNote);
          }
        }
      }
    }
  }

  public void bulkAfter(){

    if(trigger.isUpdate){
      salesDevTeamIdSet = new Set<Id>();
      List<National_TS_RFP_Task_Stage_Mapping__c> nationalTaskOppStageMap = National_TS_RFP_Task_Stage_Mapping__c.getAll().values();

      for(GroupMember currentGroupMember : [SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = 'Sales_Dev_Team']){
        salesDevTeamIdSet.add(currentGroupMember.UserOrGroupId);
      }
    }

    // onboarding case
    if(Trigger.New != NULL && Trigger.oldMap!=NULL && Trigger.isUpdate){

      for (Task onboardTask : (List<Task>)Trigger.new) {
        
        if(Trigger.oldMap!=NULL && Trigger.oldMap.containsKey(onboardTask.Id)){

          Task oldTask = (Task)trigger.oldMap.get(onboardTask.Id);
          System.debug(LoggingLevel.INFO, '*** oldTask: ' + oldTask);

          if(onboardTask.WhatId != NULL && 
              onboardTask.WhatId.getSObjectType() == Schema.Case.getSObjectType() &&
              onboardTask.Purpose__c == 'Onboarding' &&
              onboardTask.Onboard_Automation__c &&
              onboardTask.Status == 'Completed' &&
              (oldTask.Status != 'Completed' || 
                (String.isNotBlank(onboardTask.Onboarding_Task_Outcome__c) && 
                  String.isBlank(oldTask.Onboarding_Task_Outcome__c)
                ) 
              ) 
          ){

            onboardingTaskList.add(onboardTask);
            onboardingCaseIds.add(onboardTask.WhatId);
          }
        }
      }

      if(!onboardingCaseIds.isEmpty()){

        onboardingCaseMap = new Map<Id, Case>();
        Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, ContactId, follow_up_attempts__c, No_Show_Attempts__c, Reschedule_Attempts__c, 
                                                  Attempts__c, Status, OwnerId FROM Case WHERE id =: onboardingCaseIds]);

        // Stored all related cases and map with task
        if(!onboardingTaskList.isEmpty()){

          for(Task t : onboardingTaskList){
            
            Case tempCase = caseMap.get(t.WhatId);
            onboardingCaseMap.put(t.Id, tempCase);

          }
        }
      }
    }
  }

  public void beforeInsert(SObject so){
    Task currentTask = (Task)so;
    // CSP-2554  if the task related to account, we should set the customer lookup field to current related object.
    if (String.isNotBlank(currentTask.WhatId) && accountIdMap.containsKey(currentTask.WhatId)) {
      Account currentAccount = accountIdMap.get(currentTask.WhatId);
      currentTask.Account__c = currentAccount.Id;
      currentTask.AccountLongestPastDueDate__c = currentAccount.Longest_Past_Due_Date__c;
      currentTask.AccountPastDueAmount__c = currentAccount.Past_Due_Balance__c;
    }
    if (String.isNotBlank(currentTask.WhatId) && opportunityIdAndStageNameMap.containsKey(currentTask.WhatId)) {
      currentTask.Opportunity_Stage__c = opportunityIdAndStageNameMap.get(currentTask.WhatId);
    }

    if (outOfOfficeMap.containsKey(currentTask.OwnerId)) {
      Out_Of_Office__c currentOutOfOffice = outOfOfficeMap.get(currentTask.OwnerId);
      if (currentOutOfOffice.Start_Date__c <= currentTask.ActivityDate && currentOutOfOffice.End_Date__c >= currentTask.ActivityDate) {
        currentTask.OwnerId = currentOutOfOffice.Assign_Task_To__c;
      }
    }

    // CSP-2165 - When a Task has the status of "Completed" stamp the field "Task Completion Date" with the datetime value
    if(String.isNotBlank(currentTask.Status) && currentTask.Status.equals('Completed')) {
      currentTask.Task_Completion_Date__c = Datetime.now();
    }

    // CSP-2152 - Hide the NVM GUID when specific criteria is met
    // CSP-3064 Code Adjustments for new NVM disposition field 
    // Used CBSS Result replace CBSS Disposition Code 
    // Used Service Result replace Strategy Specialist Disposition Code 
    if(String.isNotBlank(currentTask.CBSSResult__c) && (currentTask.CBSSResult__c.equals('Payment Information Provided') || currentTask.CBSSResult__c.equals('Took Payment'))) {
      currentTask = hideNVMGUID(currentTask);
    } else if(String.isNotBlank(currentTask.ServiceResult__c) && (currentTask.ServiceResult__c.equals('Payment Information Provided') || currentTask.ServiceResult__c.equals('Took Payment'))) {
      currentTask = hideNVMGUID(currentTask);
    }


    // CSP-2686 Task View to Include Account
    // update the account field in task for onboarding case
    System.debug(LoggingLevel.INFO, '*** onboardingCaseAccMap insert: ' + onboardingCaseAccMap);
    if(String.isNotBlank(currentTask.WhatId) && onboardingCaseAccMap.containsKey(currentTask.WhatId)){

      Id accId = onboardingCaseAccMap.get(currentTask.WhatId);

      // only assign to the account field if the new account is different to the original one
      if(currentTask.Account__c != accId){
        currentTask.Account__c = accId;
      }
    }

    // CSP-2709 POC:Quick View for Activity Notes
    if(nvmNotesMap.containsKey(currentTask.CallObject)){
      String str = nvmNotesMap.get(currentTask.CallObject).Left(255);
      currentTask.NVM_Notes_hidden__c = str;
      currentTask.NVM_Notes__c = str;
    }
    
  }

  public void beforeUpdate(SObject oldSo, SObject so){
    Task currentTask = (Task)so;
    Task oldTask = (Task)oldSo;

    if(currentTask.Status != oldTask.Status){
      if(String.isNotBlank(currentTask.Status) && currentTask.Status.equals('Completed')) {
        // CSP-2165 - When a Task has the status of "Completed" stamp the field "Task Completion Date" with the datetime value
        currentTask.Task_Completion_Date__c = Datetime.now();

        if(String.isNotBlank(currentTask.WhatId)) {
          // National Code
          if(currentTask.WhatId.getSObjectType() === Schema.ThoughtStarter_RFP__c.getSObjectType() && String.isNotBlank(currentTask.Purpose__c) && salesDevTeamIdSet.contains(currentTask.OwnerId)) {
            tsRFPIdSalesDevMap.put(currentTask.WhatId, currentTask.OwnerId);
          }
        }
      }
    }

    // CSP-2152 - Hide the NVM GUID when specific criteria is met
    // CSP-3064 Code Adjustments for new NVM disposition field 
    // Used CBSS Result replace CBSS Disposition Code 
    // Used Service Result replace Strategy Specialist Disposition Code 
    if(String.isNotBlank(currentTask.CBSSResult__c) && (currentTask.CBSSResult__c.equals('Payment Information Provided') || currentTask.CBSSResult__c.equals('Took Payment'))) {
      currentTask = hideNVMGUID(currentTask);
    } else if(String.isNotBlank(currentTask.ServiceResult__c) && (currentTask.ServiceResult__c.equals('Payment Information Provided') || currentTask.ServiceResult__c.equals('Took Payment'))) {
      currentTask = hideNVMGUID(currentTask);
    }

    // CSP-2686 Task View to Include Account
    // update the account field in task for onboarding case
    if(currentTask.WhatId != oldTask.WhatId &&
       String.isNotBlank(currentTask.WhatId) && 
       onboardingCaseAccMap.containsKey(currentTask.WhatId)){

      Id accId = onboardingCaseAccMap.get(currentTask.WhatId);

      // only assign to the account field if the new account is different to the original one
      if(currentTask.Account__c != accId){
        currentTask.Account__c = accId;
      }
    }

    // CSP-2709 POC:Quick View for Activity Notes
    if(nvmNotesMap.containsKey(currentTask.CallObject)){
      String str = nvmNotesMap.get(currentTask.CallObject).Left(255);
      currentTask.NVM_Notes_hidden__c = str;
      // in update section, the note is allowing to be modified by user manually, 
      // only if nvm have different notes, then will update the note field in Task
      if(oldTask.NVM_Notes_hidden__c != currentTask.NVM_Notes_hidden__c){
        currentTask.NVM_Notes__c = str;
      }
    }
  }

  public void beforeDelete(SObject so) {

  }

  public void afterInsert(SObject so) {

  }

  public void afterUpdate(SObject oldSo, SObject so) {
    Task currentTask = (Task)so;
    Task oldTask = (Task)oldSo;
    if (currentTask.Status != oldTask.Status && 
        currentTask.Status.equals('Completed') &&
        String.isNotBlank(currentTask.WhatId) && 
        currentTask.WhatId.getSObjectType() === Schema.ThoughtStarter_RFP__c.getSObjectType()){

      // if this task has been complete, we should created a task assigned to AE (Sales Rep/Opportunity Owner). added for CSP-1700
      if (currentTask.Subject.equals('ThoughtStarter has been submitted')) {
        tsrfpIdSet.add(currentTask.WhatId);
      }
      // this task completed, we should update the stage to 'Pitched' for the Opp and send email to AS,AE, Sales Developer. added for CSP-1700
      if (currentTask.Subject.equals('RFP has been approved and ready to be pitched to client!')) {
        tsrfpUpdateOppIdSet.add(currentTask.WhatId);
      }
    }
    if(!onboardingCaseMap.isEmpty() && onboardingCaseMap.containsKey(currentTask.Id)){

      Case currentCase = onboardingCaseMap.get(currentTask.Id);
      onboardingFollowUpTask(currentTask, oldTask, currentCase);
    }

  }

  public void afterDelete(SObject so) {

  }

  public void beforeAndFinally() {
    // update the related object ThoughtStarter_RFP__c
    // if one Sales Developer complete the task assigned to him, we should set up the field  Sales_Developer__c on TS/RFP.
    if (!tsRFPIdSalesDevMap.isEmpty()) {
      List<ThoughtStarter_RFP__c> updateSalesDevList = [SELECT Id, Sales_Developer__c FROM ThoughtStarter_RFP__c
                                                        WHERE Id IN : tsRFPIdSalesDevMap.keySet()
                                                        AND Sales_Developer__c = NULL];
      
      if (!updateSalesDevList.isEmpty()) {
        for (Integer i=0; i < updateSalesDevList.size() ; i++) {
          ThoughtStarter_RFP__c updateThoughtStarterRFP = updateSalesDevList[i];
          updateThoughtStarterRFP.Sales_Developer__c = tsRFPIdSalesDevMap.get(updateThoughtStarterRFP.Id);
        }

        List<Database.SaveResult> saveResultsList = Database.update(updateSalesDevList);
        List<XO_Exception__c> xoExceptionList = ExceptionUtility.consumeException(saveResultsList);
        if (!xoExceptionList.isEmpty()) {
          insert xoExceptionList;
        }
      }
    }
  }

  public void afterAndFinally() {
    List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();

    

    // added for CSP-1700, if the task "ThoughtStarter has been submitted" has been complete, we should create another taskfot the TS/RFP assign to AE
    if (!tsrfpIdSet.isEmpty()) {
      // List<ThoughtStarter_RFP__c> tsRFPList = [select id, name, Account_Strategist__c from ThoughtStarter_RFP__c where id in :tsrfpIdSet ];
      for (ThoughtStarter_RFP__c currentTSRFP : [SELECT Id, Name,Opportunity__r.OwnerId, Account_Strategist__c FROM ThoughtStarter_RFP__c WHERE id in :tsrfpIdSet ]) {
        Task newTask = new Task();
        newTask.Subject = 'Pitch ThoughtStarter to client';
        newTask.WhatId = currentTSRFP.Id;
        newTask.OwnerId = currentTSRFP.Opportunity__r.OwnerId;
        newTask.Purpose__c = 'Pitch ThoughtStarter';
        newTaskList.add(newTask);
      }

      if (!newTaskList.isEmpty()) {
        insert newTaskList; 
      }
    }

    // if the task has been complete, we should update the stage to 'Pitched' for the Opp and send email to AS,AE, Sales Developer
    if (!tsrfpUpdateOppIdSet.isEmpty()) {
      List<Opportunity> updateOppStageList = new List<Opportunity>();
      List<ThoughtStarter_RFP__c> ThoughtStarterRFPList = [SELECT Opportunity__c, Opportunity__r.Name, Opportunity__r.StageName,
                                                            Opportunity__r.OwnerId, RecordType.Name, Account_Strategist__c,
                                                            Sales_Dev_Needed__c, Sales_Developer__c FROM ThoughtStarter_RFP__c
                                                            WHERE Id IN: tsrfpUpdateOppIdSet];
      
      for (Integer i = 0; i < ThoughtStarterRFPList.size() ; i++) {

        ThoughtStarter_RFP__c currentTSRFP = ThoughtStarterRFPList[i];

        currentTSRFP.Opportunity__r.StageName = 'Pitched';
        updateOppStageList.add(currentTSRFP.Opportunity__r);

      }

      if (!updateOppStageList.isEmpty()) {
        List<Database.SaveResult> saveResultsList = Database.update(updateOppStageList);
        xoExceptionList.addAll(ExceptionUtility.consumeException(updateOppStageList,saveResultsList,'Major','Opportunity',false));

        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();

        for (ThoughtStarter_RFP__c currentTSRFP : ThoughtStarterRFPList) {

          String subject = currentTSRFP.Opportunity__r.Name + ': RFP has been pitched!';
          String bodyText = 'The RFP has been pitched for ' + currentTSRFP.Opportunity__r.Name + '!';

          // the email send to Sales Rep
          Messaging.SingleEmailMessage aeEmail = new Messaging.SingleEmailMessage();
          aeEmail.setTargetObjectId(currentTSRFP.Opportunity__r.OwnerId);
          aeEmail.setSubject(subject);
          aeEmail.setPlainTextBody(bodyText);
          aeEmail.saveAsActivity = false;
          emailList.add(aeEmail);

          // the email send to account strategist
          Messaging.SingleEmailMessage asEmail = new Messaging.SingleEmailMessage();
          asEmail.setTargetObjectId(currentTSRFP.Account_Strategist__c);
          asEmail.setSubject(subject);
          asEmail.setPlainTextBody(bodyText);
          asEmail.saveAsActivity = false;
          emailList.add(asEmail);

          //  the email send to Sales Developer
          if (String.isNotBlank(currentTSRFP.Sales_Developer__c)) {
            Messaging.SingleEmailMessage salesDeveloperEmail = new Messaging.SingleEmailMessage();
            salesDeveloperEmail.setTargetObjectId(currentTSRFP.Sales_Developer__c);
            salesDeveloperEmail.setSubject(subject);
            salesDeveloperEmail.setPlainTextBody(bodyText);
            salesDeveloperEmail.saveAsActivity = false;
            emailList.add(salesDeveloperEmail);
          }
        }

        if (!emailList.isEmpty()) {
           List<Messaging.SendEmailResult> emailResultList = Messaging.sendEmail(emailList,false); 
           xoExceptionList.addAll(ExceptionUtility.consumeException(emailResultList));
        }
      }
    }
    
    if(Trigger.isUpdate && !onboardingCaseMap.isEmpty()){

      // update cases
      if (!updateCases.isEmpty()) {
         List<Database.SaveResult> resultList = Database.update(updateCases, false);
         xoExceptionList.addAll(ExceptionUtility.consumeException(resultList));
      }

      // send onboarding emails
      if (!onboardEmails.isEmpty()) {
         List<Messaging.SendEmailResult> emailResultList = Messaging.sendEmail(onboardEmails,false);
      }

      // create onboarding tasks
      if (!newTasks.isEmpty()) {
         List<Database.SaveResult> resultList = Database.insert(newTasks, false);
         xoExceptionList.addAll(ExceptionUtility.consumeException(resultList));
      }

      if (!xoExceptionList.isEmpty()) {
        insert xoExceptionList;
      }
    }
  }

  /**
   *   Simple function to strip the NVM Call Recording Id from its normal field and place it into the hidden field.
   *
   *   @author Justin
   *   @date   2017-07-18
   *   @param  {Task}   currentTask The task with which to strip the call recording id
   *   @return {Task}               The task which has had its call recording id stripped
   */
  public static Task hideNVMGUID(Task currentTask) {
    if(String.isBlank(currentTask.CallObject)) {
      return currentTask;
    }

    currentTask.Hidden_NVM_Recording_GUID__c = currentTask.CallObject;
    currentTask.CallObject = '';

    return currentTask;
  }

  /**
   * CSP-2610 Cases Onboarding Automation
   * Applied the onboarding automation logic
   * 
   * 
   * @Author Nick
   * @Date   2017-12-13
   * @param  currentTask
   */
  public static void onboardingFollowUpTask(Task currentTask, Task oldTask, Case currentCase){
    
    Integer fuAttempts = currentCase.Follow_Up_Attempts__c == NULL? 0: Integer.valueOf(currentCase.Follow_Up_Attempts__c);
    Integer nsAttempts = currentCase.No_Show_Attempts__c == NULL? 0: Integer.valueOf(currentCase.No_Show_Attempts__c);
    Integer attempts = currentCase.Attempts__c == NULL? 0: Integer.valueOf(currentCase.Attempts__c);


    Messaging.SingleEmailMessage onboardEmail = new Messaging.SingleEmailMessage();
    Task followUpTask = new Task();

    followUpTask.Status= 'Not Started';
    followUpTask.Type = 'Call';
    followUpTask.Dispostition_Type__c = 'SS Core';
    followUpTask.Purpose__c = 'Onboarding';
    followUpTask.Priority= 'High';
    followUpTask.WhatId = currentTask.WhatId;
    followUpTask.WhoId = currentTask.WhoId;
    followUpTask.OwnerId = currentCase.OwnerId;
    followUpTask.Mobile_Phone__c = currentTask.Mobile_Phone__c;
    followUpTask.RecordTypeId = taskRecTypeNameMap.get('Standard Task').getRecordTypeId();

    System.debug(LoggingLevel.INFO, '*** currentTask: ' + currentTask);
    // before the onboarding logic, we need to ensure ss disposition code and onboarding task outcome should not be blanked
    if(String.isNotBlank(currentTask.ServiceResult__c) && String.isNotBlank(currentTask.Onboarding_Task_Outcome__c)){
      
      // will go into onboard call flow
      if(currentTask.ServiceResult__c.equals('Onboarding Call')){

        // reschedule flow
        if(currentTask.Onboarding_Task_Outcome__c.equals('Rescheduled Onboard')){

          // 1. create task
          // 2. update case
          followUpTask.Subject = 'Rescheduled Onboarding Call';
          
          if(currentTask.Onboarding_Date__c!=NULL){
            followUpTask.ActivityDate = currentTask.Onboarding_Date__c.date();
          }
          else{
            currentTask.addError(label.onboardingDateError2);
          }

          followUpTask.ServiceResult__c = 'Onboarding Call';
          
          currentCase.Attempts__c = String.valueOf(attempts+1);
          currentCase.Reschedule_Attempts__c +=1;
          currentCase.Status = 'Call Rescheduled';

          newTasks.add(followUpTask);
          updateCases.add(currentCase);
        }

        // cancelled flow
        else if(currentTask.Onboarding_Task_Outcome__c.equals('Cancelled Onboard')){

          // 1. send email
          // 2. create task
          // 3. update case

          if(fuAttempts<2){

            followUpTask.Subject ='Cancel Follow-up ' + (fuAttempts + 2);
            followUpTask.ActivityDate = DateUtility.AddBusinessDays(businessHourList[0].Id,System.today(), 2);
            followUpTask.ServiceResult__c = 'Onboarding Scheduling';

            currentCase.Status = 'Customer Cancelled';

            // CSP-2664 Update No Show Follow Up Disposition
            currentCase.Follow_up_attempts__c = String.valueOf(fuattempts+1);
            newTasks.add(followUpTask);

            
            onboardEmail = sendOnboardEmail(currentCase, nsTemplate);
            onboardEmails.add(onboardEmail);
          }
          else{

            currentCase.Status = 'Closed Customer Cancelled';

            // CSP-2664 Update No Show Follow Up Disposition
            currentCase.Follow_up_attempts__c = String.valueOf(fuattempts+1);
          }

          updateCases.add(currentCase);
        }

        // no show flow
        else if(currentTask.Onboarding_Task_Outcome__c.equals('No Show') ||
                currentTask.Onboarding_Task_Outcome__c.equals('Left Message')){

          // 1. send email
          // 2. Create task
          // 3. Case update

          if(nsAttempts<2){
            followUpTask.Subject ='No-Show Follow Up '+ (nsAttempts + 1);
            followUpTask.ActivityDate = DateUtility.AddBusinessDays(businessHourList[0].Id,System.today(), 1);
            //CSP-2664 Update No Show Follow Up Disposition
            followUpTask.ServiceResult__c = 'Onboarding Scheduling';

            currentCase.No_Show_Attempts__c = String.valueOf(nsAttempts+1);
            currentCase.Attempts__c = String.valueOf(attempts+1);
            currentCase.Status = 'Customer No Show';

            onboardEmail = sendOnboardEmail(currentCase,nsTemplate);
            onboardEmails.add(onboardEmail);
            newTasks.add(followUpTask);

          }
          else{
            currentCase.No_Show_Attempts__c = String.valueOf(nsAttempts+1);
            currentCase.Attempts__c = String.valueOf(attempts+1);
            
            // CSP-2674 Add Onboard Outcome + Onboard Email Template
            currentCase.Follow_up_attempts__c = String.valueOf(fuattempts+1);
            currentCase.Status = 'Closed No Show';
          }

          updateCases.add(currentCase);
        }

        else if(currentTask.Onboarding_Task_Outcome__c.equals('Completed Onboard')){

          // CSP-2664 Update No Show Follow Up Disposition
          currentCase.Follow_up_attempts__c = String.valueOf(fuattempts+1);
          currentCase.Attempts__c = String.valueOf(attempts+1);
          currentCase.Status = 'Closed Completed';

          updateCases.add(currentCase);
        }
        else if(currentTask.Onboarding_Task_Outcome__c.equals('Declined Onboard')){

          // CSP-2664 Update No Show Follow Up Disposition
          currentCase.Follow_up_attempts__c = String.valueOf(fuattempts+1);
          currentCase.Attempts__c = String.valueOf(attempts+1);
          currentCase.Status = 'Closed Declined';

          updateCases.add(currentCase);
        }
        // CSP-2674 Add Onboard Outcome + Onboard Email Template
        // Send calendar link logic
        else if(currentTask.Onboarding_Task_Outcome__c.equals('Send Calendar Link')){

          followUpTask.Subject = 'Onboarding Follow-up ' + (fuAttempts+2) ;
          followUpTask.ActivityDate = DateUtility.AddBusinessDays(businessHourList[0].Id,System.today(), 2);
          followUpTask.ServiceResult__c= 'Onboarding Scheduling';
          newTasks.add(followUpTask);

          onboardEmail = sendOnboardEmail(currentCase,sclTemplate);
          onboardEmails.add(onboardEmail);

          currentCase.Status= 'Attempts in Progress';
          currentCase.Follow_up_attempts__c = String.valueOf(fuattempts+1);
          currentCase.Attempts__c = String.valueOf(attempts+1);
          updateCases.add(currentCase);
        }
      }

      // will go into onboard non-schedule flow
      else if(currentTask.ServiceResult__c.equals('Onboarding Scheduling')){

        // Go into Immediate Onboard flow
        if(currentTask.Onboarding_Task_Outcome__c.equals('Immediate Onboard')){
          
          // 1. case update
          currentCase.Status= 'Closed Completed';
          currentCase.Attempts__c = String.valueOf(attempts+1);

          // CSP-2664 Update No Show Follow Up Disposition
          currentCase.Follow_up_attempts__c = String.valueOf(fuattempts+1);
          
          updateCases.add(currentCase);
        }
        // Go into Scheduled Onboard
        else if(currentTask.Onboarding_Task_Outcome__c.equals('Scheduled Onboard')){
          
          // 1. case update
          // 2. create task
          currentCase.Status= 'Call Scheduled';
          currentCase.Attempts__c = String.valueOf(attempts+1);

          // CSP-2664 Update No Show Follow Up Disposition
          // currentCase.Follow_up_attempts__c = String.valueOf(fuattempts+1);

          followUpTask.Subject = 'Scheduled Onboarding Call';
          followUpTask.ServiceResult__c = 'Onboarding Call';

          if(currentTask.onboarding_date__c != NULL){
            followUpTask.ActivityDate = currentTask.onboarding_date__c.date();
          } 
          else {
            currentTask.addError(Label.onboardingDateError);
          }

          updateCases.add(currentCase);
          newTasks.add(followUpTask);
        }
        // Go into Declined Onboard
        else if(currentTask.Onboarding_Task_Outcome__c.equals('Declined Onboard')){

          // 1.case update
          currentCase.Status = 'Closed Declined';
          currentCase.Attempts__c = String.valueOf(attempts+1);

          // CSP-2664 Update No Show Follow Up Disposition
          currentCase.Follow_up_attempts__c = String.valueOf(fuattempts+1);

          updateCases.add(currentCase);
        }
        // Go into No answer Left Message/ No Answer
        else if(currentTask.Onboarding_Task_Outcome__c.equals('No Answer') ||
                currentTask.Onboarding_Task_Outcome__c.equals('Left Message')){

          // 1. create task
          // 2. send email
          // 3. update case
          if(fuAttempts < 2){

            followUpTask.Subject = 'Onboarding Follow-up ' + (fuAttempts+2) ;
            followUpTask.ActivityDate = DateUtility.AddBusinessDays(businessHourList[0].Id,System.today(), 2);
            System.debug(LoggingLevel.INFO, '***System.today() : ' + System.today());
            System.debug(LoggingLevel.INFO, '*** ActivityDate: ' + followUpTask.ActivityDate);
            followUpTask.ServiceResult__c= 'Onboarding Scheduling';
            

            currentCase.Status= 'Attempts in Progress';
            currentCase.Attempts__c = String.valueOf(attempts+1);

            // CSP-2664 Update No Show Follow Up Disposition
            currentCase.Follow_up_attempts__c = String.valueOf(fuattempts+1);
            
            if(fuAttempts == 1){
              onboardEmail = sendOnboardEmail(currentCase, fu2Template);
            }
            else{
              onboardEmail = sendOnboardEmail(currentCase, fuTemplate);
            }

            newTasks.add(followUpTask);
            onboardEmails.add(onboardEmail);
          }
          else{
            currentCase.Status= 'Max Attempts';
            currentCase.Attempts__c = String.valueOf(attempts+1);

            // CSP-2664 Update No Show Follow Up Disposition
            currentCase.Follow_up_attempts__c = String.valueOf(fuattempts+1);
          }

          updateCases.add(currentCase);
        }
        //CSP-2664 Update No Show Follow Up Disposition
        //Go into Rescheduled Onboard
        else if(currentTask.Onboarding_Task_Outcome__c.equals('Rescheduled Onboard')){
          // 1. create task
          // 2. update case
          followUpTask.Subject = 'Rescheduled Onboarding Call';
          
          if(currentTask.Onboarding_Date__c!=NULL){
            followUpTask.ActivityDate = currentTask.Onboarding_Date__c.date();
          }
          else{
            currentTask.addError(label.onboardingDateError2);
          }

          followUpTask.ServiceResult__c = 'Onboarding Call';
          
          // CSP-2664 Update No Show Follow Up Disposition
          currentCase.Attempts__c = String.valueOf(attempts+1);
          currentCase.Reschedule_Attempts__c +=1;
          currentCase.Status = 'Call Rescheduled';

          newTasks.add(followUpTask);
          updateCases.add(currentCase);
        }
        // CSP-2674 Add Onboard Outcome + Onboard Email Template
        // Send calendar link logic
        else if(currentTask.Onboarding_Task_Outcome__c.equals('Send Calendar Link')){

          followUpTask.Subject = 'Onboarding Follow-up ' + (fuAttempts+2) ;
          followUpTask.ActivityDate = DateUtility.AddBusinessDays(businessHourList[0].Id,System.today(), 2);
          followUpTask.ServiceResult__c= 'Onboarding Scheduling';
          newTasks.add(followUpTask);

          onboardEmail = sendOnboardEmail(currentCase,sclTemplate);
          onboardEmails.add(onboardEmail);

          currentCase.Status= 'Attempts in Progress';
          currentCase.Follow_up_attempts__c = String.valueOf(fuattempts+1);
          currentCase.Attempts__c = String.valueOf(attempts+1);
          updateCases.add(currentCase);
        }
      }
    }
  }

  /**
   * Send Onboard Email 
   * @Author Nick
   * @Date   2017-12-13
   * @param  currentTask [description]
   */
  public static Messaging.SingleEmailMessage sendOnboardEmail(Case currentCase, String templateId){

    Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
    msg.setTemplateId(templateId);
    msg.setWhatId(currentCase.id);
    msg.setOrgWideEmailAddressId(orgEmail.Id);
    msg.setTargetObjectId(currentCase.ContactId);
    msg.setSaveAsActivity(true);
    return msg;
  }

}