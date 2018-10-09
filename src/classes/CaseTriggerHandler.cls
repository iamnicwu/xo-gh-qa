public without sharing class CaseTriggerHandler implements XOTrigger{
  
  // Store the cases which need to auto fill up the ID fields from Description 
  private List<Case> caseList = new List<Case>();
  
  // Store the mapping relationship between email content to field api name
  private final String CASE_EMAIL_FIELD_MAPPING = System.Label.CaseEmailFieldMapping.toLowerCase();
  
  // Store the mapping between Priority and account TCV Range
  private final String CASE_PRIORITY_RANGE = System.Label.CasePriorityRange.toLowerCase();
  // delimiter for fieldmapping
  private static final String FIELDDELIM = '\n';
  private static final String VALUEDELIM = '->';
  private static final String DELIMITER = '\r\n';
  private static final Decimal HOURSRATE = 3600000.0;
  // CSP-2806 Mark Cancel Cases as BoB versus Service  - as default queue id 
  private static final Id DEFAULTQUEUEID;

  // related account map for assign the account to case
  private Set<Id> accountIdSet = new Set<Id>();
  private Map<Id, Account> relatedAccountMap = new Map<Id, Account>();
  // related contact map for assign the account to case
  private Set<Id> contactIdSet = new Set<Id>();
  private Map<Id, Contact> relatedContactMap = new Map<Id, Contact>();

  //get the current user Info and manager Info
  private User currentUser;
  
  // Store the new OwnerId when the case owner changed
  private Set<Id> newOwnerIdSet = new Set<Id>();

  // Store the owner and his manager
  private Map<Id,Id> ownerManagerMap = new Map<Id,Id>();

  // case recordtype map  
  private Map<Id, Schema.RecordTypeInfo> caseRecTypeIDMap = Schema.SObjectType.Case.getRecordTypeInfosById();
  private Map<String, Schema.RecordTypeInfo> caseRecTypeNameMap = Schema.SObjectType.Case.getRecordTypeInfosByName();

  //CSP-2185 Store the email address for the case which not found the contact.
  private Set<String> emailStrSet = new Set<String>();

  // the map to store the email-->account,contact,user
  private Map<String,Account> emailAccountMap = new Map<String,Account>(); 
  private Map<Id,Contact> accountIdContactMap = new Map<Id,Contact>();
  private Map<String,User> emailUserMap = new Map<String,User>();
  // CSP-2591
  private Map<String,User> cancelEmailUserMap = new Map<String,User>();

  // CSP-2261 default queue
  private List<Group> queueList = new List<Group>();
  
  // CSP-2417 get the email address which has created more than 10 cases in last one hour
  private Set<String> endLoopEmailSet = new Set<String>();

  // CSP-3195 Route All Onboarding Cases to Queue
  // store the onboarding Case Id to send email to customer
  private Set<Id> onboardingEmailCaseIdSet = new Set<Id>();

  // for CSP-2114, store the onboarding Case Id to generate task
  private Set<Id> onboardingTaskCaseIdSet = new Set<Id>();
  private static final Id onboardEmailTemplateId; 
  private static final OrgWideEmailAddress orgWideEmailAdd; 
  private Map<String, Schema.RecordTypeInfo> tastkRecTypeNameMap = Schema.SObjectType.Task.getRecordTypeInfosByName();
  private static List<BusinessHours> businessHourList;

  //for CSP-2484, store the caseID and user who need send Email when user close case
  private Map<Id,set<Id>> caseIdEmailListMap = new Map<Id,set<Id>>();  
  private list<Case> closeCaseList = new List<Case>() ;
  private list<Feature_Requested_Cancelled__c> cancelFRCList = new List<Feature_Requested_Cancelled__c>() ;
  private list<Id> closeCaseIdlist = new List<Id>() ;
  private static final Id closeCaseEmailTemplateId; 
  private static final OrgWideEmailAddress orgWideEmailAddForOutcome;

  // csp-2671
  private Set<Id> onboardingAccountIdSet = new Set<Id>();
  private Set<Id> onboardingContactIdSet = new Set<Id>();
  private Map<Id, Account> accountIdToAccountMap = new Map<Id, Account>();
  private Map<Id, Contact> contactIdToContactMap = new Map<Id, Contact>();
  private List<Account> onboardingAccsToBeUpdatedList = new List<Account>();
  private List<Contact> onboardingContactsToBeUpdatedList = new List<Contact>();

  //CSP-2946 Update Onboarding Assignment Logic for Pooling
  private Map<Id,Id> onboardingCaseIdToCaseOwnerMap = new Map<Id,Id>();
  private List<Task> onboardingTasksToBeUpdatedList = new List<Task>();

  // CSP-2659 Features Requested Cancelled Reporting
  private Set<Id> notAllowCloseCaseId = new Set<Id>();
  private final String CANCEL_CASE_CLOSE_ERROR_MESSAGE = Label.Cancel_Case_Close_Error_Message;
  
  // CSP-2704 Calculating Potential for In House Collections and Past Due Retention Cases
  // stored the account Id and account info
  private Map<Id,Account> pdbAccountIdMap = new Map<Id,Account>();
  
  // CSP-2806 Mark Cancel Cases as BoB versus Service
  private set<Id> closeCaseAccountIdSet = new set<Id>();
  // stored the account Id and account info
  private Map<Id,Account> closeAcctIdAndAcctMap = new Map<Id,Account>();
  // Stroed system queue id and developerName
  private static Map<Id,String> queueIdNameMap = new Map<Id,String>();
  // Title of Account owenr
  private static final String ACCOUNT_MANAGER = System.Label.Account_Manager;

  // CSP-2808 Cancel case revamp
  private static final Set<String> CANCEL_CASE_OUTCOME_SET = new Set<String>(); 

  // CSP-2750 inbound case
  // use a set to store all available record type
  private static Set<String> recordtypeSet = new Set<String>();
  // use to store all have accountId cases in the following record type: inbound, onboarding, Asset Collection
  private List<Case> ownerAssignmentCaseList = new List<Case>();
  private Map<Id,Id> ownerAssignmentCaseMap = new Map<Id,Id>();
  private Set<Id> accountSet = new Set<Id>();

  // use a set to store all cancel close status for CSP-2806
  private static Set<String> cancelCloseStatusSet = new Set<String>();
  private static Set<String> closeStatusSet = new Set<String>();
  

  static {
    try {
      businessHourList = [SELECT id FROM BusinessHours WHERE Name = 'XO Business Hours' LIMIT 1];
      for(OrgWideEmailAddress OWEA : [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress 
                                  WHERE Address =: Label.Onboarding_Email_From_Address OR Address =: Label.Case_Outcome_Email_Address ]) {
        
        //CSP-2114 send out Onboarding email need to used system email address
        if(OWEA.Address == Label.Onboarding_Email_From_Address) {
          orgWideEmailAdd = OWEA;
        } 
        
        //csp-2484 send out outcome email need to used system email address
        if(OWEA.Address == Label.Case_Outcome_Email_Address) {
          orgWideEmailAddForOutcome = OWEA;
        }
      }
      
      for (EmailTemplate currentET: [SELECT Id, Name, DeveloperName FROM EmailTemplate 
                                        WHERE DeveloperName = 'OnBoarding_Welcome_Auto' 
                                        OR DeveloperName = 'Notify_Internal_Case_Team_Cancels_Case']) {
        
        if (currentET.DeveloperName == 'OnBoarding_Welcome_Auto') {
          onboardEmailTemplateId = currentET.Id;
        }
        else{
          closeCaseEmailTemplateId = currentET.Id;
        }
      }

      // CSP-2261 default queue
      // CSP-2806 Mark Cancel Cases as BoB versus Service
      // Get all queue DeveloperName and id to the map
      for(Group currentQueue : [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue']) {
          if(currentQueue.DeveloperName == 'Case_Admin_Queue') {
            DEFAULTQUEUEID = currentQueue.Id;
          }
          
          queueIdNameMap.put(currentQueue.id,currentQueue.DeveloperName);
      }

      // CSP-2750 Inbound Case
      // add all available record types to the set
      // CSP-3195 Route All Onboarding Cases to Queue
      // We remove onboarding value from RecentOpenedCaseRecordType custom label because Asset Collections and Inbound Cases should no longer consider whether an onboarding case is open upon routing 
      if(String.isNotBlank(Label.RecentOpenedCaseRecordType)){
        for(String recType : Label.RecentOpenedCaseRecordType.split(DELIMITER)){
          recordtypeSet.add(recType.trim());
        }
      }

      // CSP-2806 Mark Cancel Cases as BoB versus Service
      // add all Close Status to the set for cancel record type
      if(String.isNotBlank(Label.Cancel_Case_Close_Status)){
         for(String Status : system.label.Cancel_Case_Close_Status.split('\r\n')) {
            cancelCloseStatusSet.add(Status.trim());
          }
      }
      // CSP-2806 Mark Cancel Cases as BoB versus Service
      // add all Close Status to the set for any record type
      if(String.isNotBlank(Label.Case_Close_Status)){
         for(String Status : system.label.Case_Close_Status.split('\r\n')) {
            closeStatusSet.add(Status.trim());
          }
      }

    } catch (Exception e) {
      XO_Exception__c xoException = ExceptionUtility.consumeException(e, true);
    }
  } 

  /**
   * Method used to bulkify all data needed in any "before" action of a trigger.
   */
  public void bulkBefore() {


    Id currentUserId = null;

    // CSP-2261 default queue
    // queueList = [SELECT Id FROM Group WHERE DeveloperName = 'Case_Admin_Queue' AND Type = 'Queue' limit 1];
    
    
    Set<Id> closeCancelCaseIdSet = new Set<Id>();

    // bulk before insert Logic//////////////////////////
    if (Trigger.isInsert) {

      // CSP-2417 get the email address set
      endLoopEmailSet = caseInfiniteLoopKiller();
      Set<String> cancelEmailStrSet = new Set<String>();

      for (Integer i = 0; i< trigger.new.size(); i++) {
        
        Case currentCase = (Case)trigger.new[i];

        // avoid emtpy record type records
        if(String.isBlank(currentCase.RecordTypeId)){
          // CSP-2261 assign to default queue and assign owner to default queue
          currentCase.RecordTypeId = caseRecTypeNameMap.get('Default').getRecordTypeId();
          // CSP-2806 Mark Cancel Cases as BoB versus Service
          // Merge code, get default queue id used DEFAULTQUEUEID 
          currentCase.OwnerId = DEFAULTQUEUEID;
          return;
        }

        // retrieve the record type name
        String rtName = caseRecTypeIDMap.get(currentCase.RecordTypeId).getName();

        // when manual create case, the current user id will assgin to currentUserId
        if (String.isBlank(currentCase.SuppliedEmail)) {
          currentUserId = UserInfo.getUserId();
        }

        

        // The Review and cancel logic
        // Get the email address 
        // for CSP-2591 Remove Auto-Contact/Account Population on E2C Cancellation Cases
        // if (rtName != '1 - Cancels') {
        // CSP-3022 Case Fields
        if (rtName != '1 - Cancels' && rtName != 'Rep Billing') {
          if (String.isBlank(currentCase.AccountId) && 
             String.isBlank(currentCase.ContactId) &&
            String.isNotBlank(currentCase.SuppliedEmail)) {

            emailStrSet.add(currentCase.SuppliedEmail);
          }
          else if (String.isBlank(currentCase.AccountId) && 
            String.isNotBlank(currentCase.ContactId)) {

            contactIdSet.add(currentCase.ContactId);
          }
          else if (String.isNotBlank(currentCase.AccountId)) {

            accountIdSet.add(currentCase.AccountId);
          }
        }
        // else if (rtName == '1 - Cancels' && String.isNotBlank(currentCase.SuppliedEmail)) {
        // CSP-3022 Case Fields
        // added the web email of rep billing case to the set, used for populate the Internal Report and Reporter type
        else if ((rtName == '1 - Cancels' || rtName == 'Rep Billing') && String.isNotBlank(currentCase.SuppliedEmail)) {
          cancelEmailStrSet.add(currentCase.SuppliedEmail);
        }
        else if(rtName == '1 - Cancels' && String.isBlank(currentCase.SuppliedEmail)){
          
          if (String.isBlank(currentCase.AccountId) && 
            String.isNotBlank(currentCase.ContactId)) {

            contactIdSet.add(currentCase.ContactId);
          }
          else if (String.isNotBlank(currentCase.AccountId)) {

            accountIdSet.add(currentCase.AccountId);
          }
        }
      }
    
      // Generate the emailAccountMap, accountIdContactMap
      // find the 1:1 contact for the Case Web Email, if found, added the account and contact to the emailAccountMap, accountIdContactMap 
      // and remove the email from emailStrSet 
      try{
        Set<String> emailSet = new Set<String>();//use for checking the contact,account,user is duplicate on email
        String emailStr = '';

        // If there is no 1:1 contact for the Case web Email, we should find the 1:1 account for the Case web Email, 
        // and if the contact has been found, added the account to the emailAccountMap, and remove the email from emailStrSet. 
        // then added the contact to the accountIdContactMap if there is only one contact under the 1:1 account.
        if(emailStrSet.size()>0){
          
          List<Account> accList = [SELECT Id, Name, Email__c, ActiveSubscriptionTCVSummary__c, Strategy_Specialist__r.IsActive, 
                                    Strategy_Specialist__c, Strategy_Specialist__r.ManagerId, (SELECT Id, Email FROM Contacts) 
                                    FROM Account 
                                    WHERE Recordtype.DeveloperName = 'AccConcierge' AND Email__c in: emailStrSet];
          
          if (accList.size()>0) {
            emailSet.clear();
            for (Account currentAccount : accList) {

              emailStr = currentAccount.Email__c.toLowerCase();

              // for 1:1, if there are more than 1 account has the same email, remove the data from the emailAccountMap and accountIdContactMap
              if (!emailSet.contains(emailStr)) {
                emailSet.add(emailStr);
                emailAccountMap.put(emailStr, currentAccount);
                //added the email to accountIdContactMap only when there one contact under account
                if (currentAccount.Contacts.size() == 1) {
                  accountIdContactMap.put(currentAccount.Id, currentAccount.Contacts[0]);
                }
                emailStrSet.remove(emailStr);
              }
              else{
                emailAccountMap.remove(emailStr);
                accountIdContactMap.remove(currentAccount.Id);
                emailStrSet.add(emailStr);
              }
            }
          }
        }

        // if there is no 1:1 contact and Account for  the Case Web Email, we should find the 1:1 user for the Case web Email, 
        if(emailStrSet.size()>0){

          //  Generate the emailUserMap
          List<User> userList = [SELECT Id,Email,Name,UserRole.Name FROM User WHERE Email in : emailStrSet AND isActive = TRUE];
          
          if (userList.size()>0) {
            emailSet.clear();
            
            for (User currentUser : userList) {
              
              emailStr = currentUser.Email.toLowerCase();
              // for 1:1, if there are more than 1 account has the same email, remove the data from the emailUserMap
              if (emailSet.contains(emailStr)) {
                emailUserMap.remove(emailStr);
              }
              else{
                emailSet.add(emailStr);
                emailUserMap.put(emailStr, currentUser);
              }
            }
          }
        }

        if (!cancelEmailStrSet.isEmpty()) {
          // CSP-2591 Generate the cancelEmailUserMap 
          List<User> userList = [SELECT Id,Email,Name,UserRole.Name FROM User WHERE Email in : cancelEmailStrSet AND isActive = TRUE];
          if (!userList.isEmpty()) {
            for (User currentUser : userList) {
              cancelEmailUserMap.put(currentUser.Email.toLowerCase(), currentUser);
            }
          }
        }
      }
      catch(Exception e){
        ExceptionUtility.consumeException(e, true);
      }

      if (currentUserId != null) {
        currentUser = [SELECT Id, ManagerId FROM User WHERE id =: currentUserId];
      }
    }

    // bulk before Update Logic//////////////////////////
    if (Trigger.isUpdate) {


      for (Integer i = 0; i< trigger.new.size(); i++) {
        
        Case currentCase = (Case)trigger.new[i];
        Case oldCase = (Case)trigger.oldMap.get(currentCase.id);

        // if (rtName.containsIgnoreCase('1 - Cancels')) {
        if(String.isNotBlank(currentCase.AccountId) && 
          currentCase.AccountId != oldCase.AccountId){

          accountIdSet.add(currentCase.AccountId);
        }
        else if(String.isBlank(currentCase.AccountId) && 
                String.isNotBlank(currentCase.ContactId) &&
                String.isNotBlank(oldCase.AccountId)
                ){

          contactIdSet.add(currentCase.ContactId);
        }
        else if(String.isNotBlank(currentCase.AccountId) && 
                String.isNotBlank(currentCase.ContactId) && 
                currentCase.ContactId != oldCase.ContactId){

          contactIdSet.add(currentCase.ContactId);
        }
      
        if (currentCase.OwnerId != oldCase.OwnerId) {

          newOwnerIdSet.add(currentCase.OwnerId);
        }

        // CSP-2659 Features Requested Cancelled Reporting
        // get all the cancelled cases Id which need to validate the FRC
        // CSP-2780 Trapped Cases 
        // if the user check the flag Skip_The_Notification_And_Validation__c when close the cancel case
        // we don't need to validate the FRC
        // CSP-2808 Cancel case revamp
        // use a label to store cancel case outcome picklist value
        String rtName = caseRecTypeIDMap.get(currentCase.RecordTypeId).getName();
        for(String outcomeValue : system.label.Cancel_Case_Outcome.split('\r\n') ){
          CANCEL_CASE_OUTCOME_SET.add(outcomeValue.trim());
        }

        if (rtName == '1 - Cancels' 
            && !currentCase.Skip_The_Notification_And_Validation__c 
            && currentCase.Status !=  oldCase.Status
            && (currentCase.Status == 'Closed' || currentCase.Status == 'Closed Duplicate') 
            && (CANCEL_CASE_OUTCOME_SET.contains(String.valueOf(currentCase.Outcome__c)))) {

          closeCancelCaseIdSet.add(currentCase.id);
        }
        // CSP-2806 Mark Cancel Cases as BoB versus Service
        // Get account id when user attempts to close case  
        if (rtName == '1 - Cancels' 
            && !currentCase.Case_Closed_Flag__c
            && cancelCloseStatusSet.contains(currentCase.Status)
            && !cancelCloseStatusSet.contains(oldCase.Status) 
            && String.isNotBlank(currentCase.AccountId)) {

            closeCaseAccountIdSet.add(currentCase.AccountId);
        }
      }
    }

    // Get Contact info when update case and on Account associated with the case
    if(!contactIdSet.isEmpty()){
      for(Contact currentContact : [SELECT Id, Account.Strategy_Specialist__r.IsActive, Account.Strategy_Specialist__c, Account.Strategy_Specialist__r.Manager.IsActive, 
                                    Account.Strategy_Specialist__r.ManagerId, Account.ActiveSubscriptionTCVSummary__c, AccountId  
                                    FROM Contact 
                                    WHERE Id IN :contactIdSet]){

        relatedContactMap.put(currentContact.Id, currentContact);
      }
    }

    // CSP-2806 Mark Cancel Cases as BoB versus Service
    // Add logic to query Account owner titile info
    // Get Account info when update case Account
    Set<Id> allAccountIdSet = new Set<Id>();
    allAccountIdSet.addAll(accountIdSet);
    allAccountIdSet.addAll(closeCaseAccountIdSet);
    if(!allAccountIdSet.isEmpty()){
      for(Account acc : [SELECT Id, Strategy_Specialist__r.IsActive, Strategy_Specialist__c, Strategy_Specialist__r.Manager.IsActive, 
                          Strategy_Specialist__r.ManagerId, ActiveSubscriptionTCVSummary__c, Owner.Title, Owner.Name, (SELECT Id, Email FROM Contacts) 
                          FROM Account 
                          WHERE Id IN :allAccountIdSet]){
        //Get Account info when Relate Account has changed 
        if(accountIdSet.contains(acc.Id)){
           relatedAccountMap.put(acc.Id, acc);
        }
        // CSP-2806 Mark Cancel Cases as BoB versus Service
        // Get Account owner title info when close of the case
        if(closeCaseAccountIdSet.contains(acc.Id)){
           closeAcctIdAndAcctMap.put(acc.Id, acc);
        }
      }
    }

    if (!newOwnerIdSet.isEmpty()) {
      
      for(User currentUser : [SELECT Id, ManagerId FROM User WHERE Id IN :newOwnerIdSet]){
        ownerManagerMap.put(currentUser.Id, currentUser.ManagerId);
      }
    }

    // CSP-2659 Features Requested Cancelled Reporting
    // get all the cancelled cases Id which is not allowed to close.
    if (!closeCancelCaseIdSet.isEmpty()) {
      List<Case> caseList = [Select Id, AccountId, 
                            (SELECT Id, Case__c, Status__c, Subscription_Product_Charge__c, UniqueId__c 
                              FROM Feature_Requested_Cancelled__r) FROM Case WHERE id IN: closeCancelCaseIdSet];

      Boolean allowClosed = TRUE;
      for (Case currentRecord : caseList) {
        if (currentRecord.Feature_Requested_Cancelled__r.isEmpty()) {
          allowClosed = FALSE;
        }
        else{
          for (Feature_Requested_Cancelled__c currentFRC : currentRecord.Feature_Requested_Cancelled__r) {
            if (currentFRC.Status__c == 'Requested Cancelled') {
              allowClosed = FALSE;
              break;
            }
            else if (String.isBlank(currentFRC.Subscription_Product_Charge__c)) {
              allowClosed = FALSE;
              break;
            } 
          }
        }

        if (!allowClosed) {
          notAllowCloseCaseId.add(currentRecord.Id);
        }
      }
    }

    // CSP-2704 Calculating Potential for In House Collections and Past Due Retention Cases
    // if the case insert or update accountid, we generated a account map stored the account id and account info
    if (Trigger.isInsert || Trigger.isUpdate) {
      Set<Id> caseAccountIdSet = new Set<Id>();
      for (Integer i = 0; i< trigger.new.size(); i++) {

        Case currentCase = (Case)trigger.new[i];

        if (String.isNotBlank(currentCase.AccountId)) {
          caseAccountIdSet.add(currentCase.AccountId);
        }
      }

      if (!caseAccountIdSet.isEmpty()) {
        pdbAccountIdMap = new map<Id,Account>([select Id,Account.Past_Due_Balance__c from Account where id IN: caseAccountIdSet]);
      }
    }
  }

  /**
   *   Method used to bulkify all data needed in any "after" action of a trigger.
   */
  public void bulkAfter() {

    // bulk after Update Logic//////////////////////////
    if (Trigger.isUpdate) {
      for(SObject currentObj : Trigger.new){
        Case currentCase = (Case)currentObj;
        Case oldCase = (Case)trigger.oldMap.get(currentCase.id);

        // retrieve the record type name
        String rtName = caseRecTypeIDMap.get(currentCase.RecordTypeId).getName();

        //CSP-2484 Collecting the case ID when user close case 
        // CSP-2780 Trapped Cases 
        // if the user check the flag Skip_The_Notification_And_Validation__c when close the case
        // the notification will not send out
        if(currentCase.Status != oldCase.Status 
              && !currentCase.Skip_The_Notification_And_Validation__c 
              && (currentCase.Status == 'Closed' || currentCase.Status == 'Closed Duplicate') 
              && rtName.containsIgnoreCase('1 - Cancels')){
          closeCaseIdlist.add(currentCase.Id);
        }

        //cp-2671
        if (rtName.containsIgnoreCase('2 - Onboarding') && currentCase.isClosed == True) {

          if (String.isNotBlank(currentCase.AccountId)) {
            onboardingAccountIdSet.add(currentCase.AccountId);
          }

          if (String.isNotBlank(currentCase.ContactId)) {
            onboardingContactIdSet.add(currentCase.ContactId);  
          }
        }
      }

      // csp-2671
      if(!onboardingAccountIdSet.isEmpty()) {
        List<Account> accountsToBeUpdatedList = [SELECT In_Business_Since__c, Website_Grade__c, Segment__c, Beta_Opt_Out__c, Instagram__c
                             FROM Account 
                             WHERE Id IN: onboardingAccountIdSet];
        for(Account currentAcc: accountsToBeUpdatedList) {
          accountIdToAccountMap.put(currentAcc.Id, currentAcc);
        }
      }

      if(!onboardingContactIdSet.isEmpty()) {
        List<Contact> contactsToBeUpdatedList = [SELECT Preferredcontactmethod__c 
                             FROM Contact 
                             WHERE Id IN: onboardingContactIdSet];
        for(Contact currentContact: contactsToBeUpdatedList) {
          contactIdToContactMap.put(currentContact.Id, currentContact);
        }
      }

      if(!closeCaseIdlist.isEmpty()){
        //CSP-2484 Find ID of the Acount SS, Account Owner and Internal Report 
        closeCaseList = [SELECT id, Reporter_User_Name__r.Id, Account.Owner.Id, Account.Strategy_Specialist__r.Id, Account.VIP_Program__c 
                            FROM Case  WHERE id IN: closeCaseIdlist AND Recordtype.Name = '1 - Cancels'];

        for (case currentCase : closeCaseList) {
            if(!caseIdEmailListMap.containsKey(currentCase.Id)){
                caseIdEmailListMap.put(currentCase.Id, new set<Id>());
            }
            caseIdEmailListMap.get(currentCase.id).add(currentCase.Account.Strategy_Specialist__r.Id);
            caseIdEmailListMap.get(currentCase.id).add(currentCase.Reporter_User_Name__r.Id);
            //CSP-2484 If Account field "VIP Program" = true, no notifications should go to "Account Owner"
            if(!currentCase.Account.VIP_Program__c) {
                caseIdEmailListMap.get(currentCase.id).add(currentCase.Account.Owner.Id);
            }
        }
        //CSP-2484 Find ID of the Sales Rep under Subscription 
        cancelFRCList = [SELECT id, Case__c, Subscription_Product_Charge__r.Zuora__Subscription__r.Sales_Rep__r.Id 
                            FROM Feature_Requested_Cancelled__c 
                            WHERE Case__c IN: closeCaseIdlist 
                            AND Subscription_Product_Charge__r.Zuora__Account__r.VIP_Program__c = false ];
        for(Feature_Requested_Cancelled__c currentFRC : cancelFRCList) {
          if(!caseIdEmailListMap.containsKey(currentFRC.Case__c)){
              //New key within Map Initialize set
              caseIdEmailListMap.put(currentFRC.Case__c, new set<Id>());
          }
          //add id and The corresponding case id. 
          caseIdEmailListMap.get(currentFRC.Case__c).add(currentFRC.Subscription_Product_Charge__r.Zuora__Subscription__r.Sales_Rep__r.Id);
        }
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
    
    Case caseObj = (Case)so;

    // avoid to empty record type
    if(String.isBlank(caseObj.RecordTypeId)){
      // CSP-2261 assign owner to default queue
      caseObj.RecordTypeId = caseRecTypeNameMap.get('Default').getRecordTypeId();
      // CSP-2806 Mark Cancel Cases as BoB versus Service
      // Merge code, get default queue id used DEFAULTQUEUEID
      caseObj.OwnerId = DEFAULTQUEUEID;
      return;
    }

    String rtName = caseRecTypeIDMap.get(caseObj.RecordTypeId).getName();

    // Added a new field Description(Description_Custom__c) to Store the Ture Description for ticket CSP-2324
    // the custom field can be added or removed from the page layout controlled by record type and profile
    if (String.isNotBlank(caseObj.Description) && String.isBlank(caseObj.Description_Custom__c)) {
      caseObj.Description_Custom__c = caseObj.Description;
    }


    // CSP-2750 Inbound Cases
    // run thru the inbound case logic
    // The review Case logic
    // for ticket CSP-2178
    // if the case Description is not null when case inserted or has been changed when case udpated, 
    // we should Auto fill data from description(email body) into Review Cases
    if (rtName.containsIgnoreCase('3 - Reviews') || rtName.containsIgnoreCase('Inbound')){
      if (String.isNotBlank(caseObj.SuppliedEmail) && endLoopEmailSet.contains(caseObj.SuppliedEmail)) {
        caseObj.Auto_Reply_Flag__c = FALSE;
      }
      else{
        caseObj.Auto_Reply_Flag__c = TRUE;
      }


      String searchKey = CASE_EMAIL_FIELD_MAPPING.split(FIELDDELIM)[0].split(VALUEDELIM)[0].trim();

      if (caseObj.Description_Custom__c != null && caseObj.Description_Custom__c.containsIgnoreCase(searchKey)) {
        caseList.add(caseObj);
      }
    }

    // the logic for '3 - Reviews' and '1 - Cancels' record type
    if (rtName.containsIgnoreCase('3 - Reviews') || rtName.containsIgnoreCase('1 - Cancels') || rtName.containsIgnoreCase('Inbound')) {

      // if the Web email in not null, assign the email address to the Reported_by__c
      if (String.isNotBlank(caseObj.SuppliedEmail) && String.isBlank(caseObj.Reported_by__c)) {
        caseObj.Reported_by__c = caseObj.SuppliedEmail;
      }

      // if the SuppliedEmail is not null, indicate the case created by email-to-case
      // we should update the Reporter_Type__c, OwnerId (Only for Cancel), Priority(Only for Cancel),  etc
      // the email can find the 1:1 contact
      if (String.isNotBlank(caseObj.SuppliedEmail) && 
            !rtName.containsIgnoreCase('1 - Cancels') && 
            String.isNotBlank(caseObj.ContactId) && 
            relatedContactMap.containsKey(caseObj.ContactId))  {
        
        caseObj.Reporter_Type__c = 'Customer';


        
        //CSP-2516 we should check whether the contact has an account
        if (String.isNotBlank(relatedContactMap.get(caseObj.ContactId).AccountId)) {

          Account caseAccount = relatedContactMap.get(caseObj.ContactId).Account; 
          caseObj.Account_SS__c = caseAccount.Strategy_Specialist__c;

        }
      }

      // the email can not find the 1:1 contact but can find 1:1 account
      else if(String.isNotBlank(caseObj.SuppliedEmail) && 
              !rtName.containsIgnoreCase('1 - Cancels') && 
              String.isBlank(caseObj.ContactId) && 
              emailAccountMap.containsKey(caseObj.SuppliedEmail)){
        
        caseObj.Reporter_Type__c = 'Customer';
        caseObj.AccountId = emailAccountMap.get(caseObj.SuppliedEmail).id;
        caseObj.Account_SS__c = emailAccountMap.get(caseObj.SuppliedEmail).Strategy_Specialist__c;

        // // if the 1:1 account only have one contact, we need to assign the contact to caseObj.ContactId
        if (accountIdContactMap.containsKey(caseObj.AccountId)) {
          caseObj.ContactId = accountIdContactMap.get(caseObj.AccountId).id;
        }
        
      }
      else if (String.isNotBlank(caseObj.SuppliedEmail) && 
               !rtName.containsIgnoreCase('1 - Cancels') && 
               String.isBlank(caseObj.ContactId) && 
              emailUserMap.containsKey(caseObj.SuppliedEmail)) {

          caseObj.Reporter_User_Name__c = emailUserMap.get(caseObj.SuppliedEmail).id; 
          caseObj.Reporter_Type__c = emailUserMap.get(caseObj.SuppliedEmail).UserRole.Name; 
      }

      // if the case created by manual, we only should udpate the Priority field for Cancel record type
      else if(String.isBlank(caseObj.SuppliedEmail) && 
                  String.isNotBlank(caseObj.AccountId) && 
                  relatedAccountMap.containsKey(caseObj.AccountId)) {
        
        caseObj.Account_SS__c = relatedAccountMap.get(caseObj.AccountId).Strategy_Specialist__c;
        
        if (currentUser != null) {
          caseObj.Owner_Manager__c = currentUser.ManagerId;
        }
        
        // record type is '1 - Cancels', we should re-assign Priority base on related account

        if (rtName.containsIgnoreCase('1 - Cancels')) {

          Account caseAccount = relatedAccountMap.get(caseObj.AccountId);
          // update case Priority base on related account
          updateCasePriority(caseAccount.ActiveSubscriptionTCVSummary__c, caseObj, FALSE);
        }
        
      }
      else if (String.isBlank(caseObj.SuppliedEmail) && 
                String.isBlank(caseObj.AccountId) && 
                String.isNotBlank(caseObj.ContactId)) {
        

        if (currentUser != null) {
          caseObj.Owner_Manager__c = currentUser.ManagerId;
        }

        // checking whether the contact has an account
        if (relatedContactMap.containsKey(caseObj.ContactId) && 
              String.isNotBlank(relatedContactMap.get(caseObj.ContactId).AccountId)) {

          Account caseAccount = relatedContactMap.get(caseObj.ContactId).Account;

          caseObj.Account_SS__c = caseAccount.Strategy_Specialist__c;

          // record type is '1 - Cancels', we should re-assign Priority base on related account

          if (rtName.containsIgnoreCase('1 - Cancels')) {

            // update case Priority base on related account
            updateCasePriority(caseAccount.ActiveSubscriptionTCVSummary__c, caseObj, FALSE);
          }
        }
      }
    }

    // CSP-2591 Remove Auto-Contact/Account Population on E2C Cancellation Cases
    // Internal Reporter is still populated 
    if (rtName.containsIgnoreCase('1 - Cancels') && String.isNotBlank(caseObj.SuppliedEmail) ){
      caseObj.AccountId = null;
      caseObj.ContactId = null;

      if (cancelEmailUserMap.containsKey(caseObj.SuppliedEmail)) {

        caseObj.Reporter_User_Name__c = cancelEmailUserMap.get(caseObj.SuppliedEmail).id; 
        caseObj.Reporter_Type__c = cancelEmailUserMap.get(caseObj.SuppliedEmail).UserRole.Name; 
      }
    }

    // CSP-3022 Case Fields
    // Internal Reporter and Reported by is populated for Rep Billing Case
    if (rtName.containsIgnoreCase('Rep Billing') && String.isNotBlank(caseObj.SuppliedEmail) ){
      caseObj.Reported_by__c = caseObj.SuppliedEmail;

      if (cancelEmailUserMap.containsKey(caseObj.SuppliedEmail)) {
        caseObj.Reporter_User_Name__c = cancelEmailUserMap.get(caseObj.SuppliedEmail).id; 
        caseObj.Reporter_Type__c = cancelEmailUserMap.get(caseObj.SuppliedEmail).UserRole.Name; 
      }
    }

    // CSP-2754 Update Cancel Case Assignment for Regional Pooling
    // for Cancel case, will check the case if have account, yes, then check account owner is AM, 
    // yes then assign the case owner to Account owner
    // No then assign the case owner to Account SS
    // else then assign the case owner to default queue
    // CSP-2873 Correct Cancel Case Assignment for Regional Pooling
    if(rtName.containsIgnoreCase('1 - Cancels') && 
      String.isNotBlank(caseObj.AccountId) &&
      relatedAccountMap.containsKey(caseObj.AccountId)){

      Account acc = relatedAccountMap.get(caseObj.AccountId);

      if(String.isNotBlank(acc.owner.title) && 
        acc.owner.title.equalsIgnoreCase('Account Manager')){

        caseObj.OwnerId = acc.OwnerId;
      }
    }

    // CSP-2704 Calculating Potential for In House Collections and Past Due Retention Cases
    // if a cancel case created, we copy the Past_Due_Balance__c to the Past_Due_Potential_Collections__c on case
    if ((rtName.containsIgnoreCase('1 - Cancels')) 
        && String.isNotBlank(caseObj.AccountId) 
        && pdbAccountIdMap.containsKey(caseObj.AccountId)) {

      caseObj.Past_Due_Potential_Collections__c = pdbAccountIdMap.get(caseObj.AccountId).Past_Due_Balance__c;
      
    }



    // CSP-2750 Inbound Case
    // the list stores all cases in the available record type, and also have accountId
    if(rtName.equalsIgnoreCase('Inbound') || rtName.equalsIgnoreCase('Asset Collection')){

      String accId = '';
      if(relatedContactMap.containsKey(caseObj.ContactId)){
        accId = relatedContactMap.get(caseObj.ContactId).AccountId;
      }

      if(String.isNotBlank(caseObj.AccountId)){
        accountSet.add(caseObj.AccountId);
      }
      else if(relatedContactMap.containsKey(caseObj.ContactId) && String.isNotBlank(accId)){
        accountSet.add(accId);
      }
      System.debug(LoggingLevel.INFO, '*** accountSet: ' + accountSet);
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
    Case caseObj = (Case)so;
    Case oldCase = (Case)oldSo;

    // avoid to empty record type
    if(String.isBlank(caseObj.RecordTypeId)){
      // CSP-2261 assign to default queue and assign owner to default queue
      caseObj.RecordTypeId = caseRecTypeNameMap.get('Default').getRecordTypeId();
      // CSP-2806 Mark Cancel Cases as BoB versus Service
      // Merge code, get default queue id used DEFAULTQUEUEID
      caseObj.OwnerId = DEFAULTQUEUEID;
      return;
    }

    // CSP-2659 Features Requested Cancelled Reporting
    // if the cancelled case need validate the FRC and not passed, the case cannot close.
    if (notAllowCloseCaseId.contains(caseObj.Id)) {
      caseObj.addError(CANCEL_CASE_CLOSE_ERROR_MESSAGE);
    }

    //CSP -2528 Calculated value for response time by calculating time from status "New" to any other status 
    if(caseObj.Response_Times__c == NULL  && oldCase.Status == 'New' 
      && caseObj.Status != 'New' 
      && !businessHourList.isEmpty()){
      
      Datetime createDate = caseObj.CreatedDate;
      Datetime nowTime = system.now();
      //Calculate time from create time of case to now.
      Long diffTime = BusinessHours.diff(businessHourList[0].Id, createDate, nowTime);
      //Keep two decimal places to store value
      caseObj.Response_Times__c = diffTime/HOURSRATE; 
      //Store update status time from New to any other status.
      caseObj.Response_TimeStamp__c = nowTime;

    }

    // CSP-2750 Inbound Case
    // To stamp the case status change from 'New' to closed 
    if(caseObj.Resolution_Times__c == NULL && 
      caseObj.Status.containsIgnoreCase('Closed') && 
      !oldCase.Status.containsIgnoreCase('Closed')){

        Datetime createDate = caseObj.CreatedDate;
        Datetime nowTime = system.now();
        //Calculate time from create time of case to now.
        Long diffTime = BusinessHours.diff(businessHourList[0].Id, createDate, nowTime);
        //Keep two decimal places to store value
        caseObj.Resolution_Times__c = diffTime/HOURSRATE;
        //Store update status time from New to any other status.
        caseObj.Resolution_Timestamp__c = nowTime;

    }

    // CSP-2806 Mark Cancel Cases as BoB versus Service
    // Save the time of the first close case
    if(caseObj.First_Closed_Date__c == NULL 
      && closeStatusSet.contains(caseObj.Status) 
      && !closeStatusSet.contains(oldCase.Status)){
        
        //Store first close time  
        caseObj.First_Closed_Date__c = system.now();
    }

    String rtName = caseRecTypeIDMap.get(caseObj.RecordTypeId).getName();

    // CSP-2750 Inbound Case
    if (rtName.equalsIgnoreCase('Inbound') || rtName.containsIgnoreCase('1 - Cancels') || rtName.containsIgnoreCase('3 - Reviews') ) {
      
      // if the case Account has been updated, we should update the priority base on the new account for cancel record type and update the Account_SS__C
      if (String.isNotBlank(caseObj.AccountId) && 
          caseObj.AccountId != oldCase.AccountId && 
          relatedAccountMap.containsKey(caseObj.AccountId)) {

        Account caseAccount = relatedAccountMap.get(caseObj.AccountId);
        caseObj.Account_SS__C = caseAccount.Strategy_Specialist__c;

        if (rtName.containsIgnoreCase('1 - Cancels')){

          // update case Priority base on related account
          updateCasePriority(caseAccount.ActiveSubscriptionTCVSummary__c, caseObj, TRUE);
        }
        
      }
      // if the case Account has been updated, we should update the priority base on the new account for cancel record type and update the Account_SS__C
      else if (String.isBlank(caseObj.AccountId) && 
              String.isNotBlank(caseObj.ContactId) && 
              (String.isNotBlank(oldCase.AccountId) || 
              caseObj.ContactId != oldCase.ContactId) && 
              relatedContactMap.containsKey(caseObj.ContactId)) {

        // checking whether the contact has an account
        if (String.isNotBlank(relatedContactMap.get(caseObj.ContactId).AccountId)) {

          Account caseAccount = relatedContactMap.get(caseObj.ContactId).Account;
          caseObj.Account_SS__C = caseAccount.Strategy_Specialist__c;
        
          if (rtName.containsIgnoreCase('1 - Cancels')){

            updateCasePriority(caseAccount.ActiveSubscriptionTCVSummary__c, caseObj, TRUE);
          }
        }
        
      }
      // if the case Account has been changed to null, we should update the priority to "Medium" for cancel record type and update the Account_SS__C to null
      else if(caseObj.AccountId == null && caseObj.ContactId == null){
        
        caseObj.Account_SS__C = null;
        if (rtName.containsIgnoreCase('1 - Cancels')){
          caseObj.Priority = 'Medium';
        }
      }


      // if the case owner had been changed, we should update the owner manager
      if (caseObj.OwnerId != oldCase.OwnerId && ownerManagerMap.containsKey(caseObj.OwnerId)) {
        caseObj.Owner_Manager__c = ownerManagerMap.get(caseObj.OwnerId);
      }
    }


    System.debug(LoggingLevel.INFO, '*** caseObj.AccountId: ' + caseObj.AccountId);
    System.debug(LoggingLevel.INFO, '*** : caseObj.ownerid' + caseObj.ownerid);
    
    // CSP-2754 Update Cancel Case Assignment for Regional Pooling
    // for Cancel case, will check the case if have account, yes, then check account owner is AM, 
    // yes then assign the case owner to Account owner
    // No then assign the case owner to Account SS
    // else assign the case owner to default queue
    // CSP-2873 Correct Cancel Case Assignment for Regional Pooling
    if(rtName.containsIgnoreCase('1 - Cancels') && 
      String.isNotBlank(caseObj.AccountId) &&
      relatedAccountMap.containsKey(caseObj.AccountId) &&
      caseObj.AccountId != oldCase.AccountId){

      Account acc = relatedAccountMap.get(caseObj.AccountId);

      if(String.isNotBlank(acc.owner.title) && 
        acc.owner.title.equalsIgnoreCase('Account Manager')){

        caseObj.OwnerId = acc.OwnerId; 
      } 
    }

    // CSP-2704 Calculating Potential for In House Collections and Past Due Retention Cases
    // if the account of a cancel case has been changed, 
    // we copy the new Past_Due_Balance__c of the new account to the Past_Due_Potential_Collections__c on case
    if ((rtName.containsIgnoreCase('1 - Cancels')) 
        && String.isNotBlank(caseObj.AccountId) 
        && caseObj.AccountId != oldCase.AccountId 
        && pdbAccountIdMap.containsKey(caseObj.AccountId)) {

      caseObj.Past_Due_Potential_Collections__c = pdbAccountIdMap.get(caseObj.AccountId).Past_Due_Balance__c;
      
    }

    // CSP-2780 Trapped Cases 
    // if the cancel case reopened, check the flag to skip the validation rule and notification

    if (rtName.containsIgnoreCase('1 - Cancels') 
        && (oldCase.Status == 'Closed' || oldCase.Status == 'Closed Duplicate')
        && caseObj.Status != 'Closed' 
        && caseObj.Status != 'Closed Duplicate'){

      caseObj.Skip_The_Notification_And_Validation__c = true;
      
    }

    // CSP-2806 Mark Cancel Cases as BoB versus Service
    // Update Cancel Case Type and Case Closed Flag to true if frist close of the case
    if (rtName.containsIgnoreCase('1 - Cancels')  
         && !caseObj.Case_Closed_Flag__c
         && cancelCloseStatusSet.contains(caseObj.Status)
         && !cancelCloseStatusSet.contains(oldCase.Status) 
         && String.isNotBlank(caseObj.AccountId)) {

      String accountOwnerTitle = '';
      caseObj.Case_Closed_Flag__c = true;

      if(String.valueOf(caseObj.OwnerId).startsWithIgnoreCase('005')) {
        //Stamp the Case Owner(Close) if Case owner is a user
        caseObj.Case_Owner_Close__c = caseObj.OwnerId;
      }
      else{
        if(queueIdNameMap.containsKey(caseObj.OwnerId)) {
            //Stamp the Case Owner(Close) if Case owner is a queue
            caseObj.Case_Queue_Close__c = queueIdNameMap.get(caseObj.OwnerId);
        }
      }

      if(closeAcctIdAndAcctMap.containsKey(caseObj.AccountId)) {
          caseObj.Account_Owner_Close__c = closeAcctIdAndAcctMap.get(caseObj.AccountId).OwnerId;
          accountOwnerTitle = closeAcctIdAndAcctMap.get(caseObj.AccountId).owner.title;

          if(String.isNotBlank(accountOwnerTitle)
              && accountOwnerTitle.containsIgnoreCase(ACCOUNT_MANAGER)){
              // Update Cance Case Type to Bob if Account Owner title is 'Account Manager' at close of case
              caseObj.Cancel_Case_Type__c = 'BoB';
          }else{
              // Update Cance Case Type to Service when Account Owner title is not 'Account Manager' at close of case
              caseObj.Cancel_Case_Type__c = 'Service';
          }
      }
    }

    // CSP-2750 Inbound Case
    // the list stores all cases in the available record type, and also have accountId
    if(rtName.equalsIgnoreCase('Inbound')){

      if(String.isNotBlank(caseObj.AccountId) && caseObj.AccountId != oldCase.AccountId){
        String accId = '';
        if(relatedContactMap.containsKey(caseObj.ContactId)){
          accId = relatedContactMap.get(caseObj.ContactId).AccountId;
        }

        if(String.isNotBlank(caseObj.AccountId)){
          accountSet.add(caseObj.AccountId);
        }
        else if(relatedContactMap.containsKey(caseObj.ContactId) && String.isNotBlank(accId)){
          accountSet.add(accId);
        }
        System.debug(LoggingLevel.INFO, '*** accountSet: ' + accountSet);
      }
      
    }
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
    Case caseObj = (Case)so;
    String rtName = caseRecTypeIDMap.get(caseObj.RecordTypeId).getName();
    // for the Onboarding case created, we should auto send email to customer and generate task
    // CSP-3070 Welcome email timing and template issues
    // if case owner is local team, system will not send welcome email out   
    if (rtName.containsIgnoreCase('2 - Onboarding')) {
      // CSP-3195 Route All Onboarding Cases to Queue
      // Welcome email should go out immediately after case creation
      onboardingEmailCaseIdSet.add(caseObj.id);

      if(String.valueOf(caseObj.OwnerId.getSObjectType()) == 'User' 
        && caseObj.OwnerId != label.LocalTeamUserId){
        // generate onboarding tasks only
        onboardingTaskCaseIdSet.add(caseObj.id);
      }
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
    Case caseObj = (Case)so;
    Case oldCase = (Case)oldSo;
    String rtName = caseRecTypeIDMap.get(caseObj.RecordTypeId).getName();
    // for the Onboarding case created, we should auto send email to customer and generate task 
    // CSP-3070 Welcome email timing and template issues
    // if owner change to other user from queue or local user, system will generate task 
    if (rtName.containsIgnoreCase('2 - Onboarding') 
        && String.isNotBlank(caseObj.OwnerId)
        && String.valueOf(caseObj.OwnerId.getSObjectType()) == 'User'
        && caseObj.OwnerId != label.LocalTeamUserId
        && (String.valueOf(oldCase.OwnerId.getSObjectType()) != 'User' || oldCase.OwnerId == label.LocalTeamUserId)) {

      onboardingTaskCaseIdSet.add(caseObj.id);
    }

    //CSP-2946 Update Onboarding Assignment Logic for Pooling
    if (rtName.containsIgnoreCase('2 - Onboarding') 
      && oldCase.OwnerId != caseObj.OwnerId
      && String.valueOf(caseObj.OwnerId.getSObjectType()) == 'User') {

        onboardingCaseIdToCaseOwnerMap.put(caseObj.Id, caseObj.OwnerId);
    }

    // csp-2671 - Update Account and Contact records based on changes made to case records on case close for '2 - OnBoarding'
    if (rtName.containsIgnoreCase('2 - onboarding')){
      if(accountIdToAccountMap.containsKey(caseObj.AccountId)) {
        Account currentAcc = accountIdToAccountMap.get(caseObj.AccountId);

        // update account data 
        if(currentAcc != null) {
          currentAcc.In_Business_Since__c = caseObj.InBusinessSince__c != null ? caseObj.InBusinessSince__c : currentAcc.In_Business_Since__c;
          currentAcc.Website_Grade__c = caseObj.WebsiteGrade__c != null ? caseObj.WebsiteGrade__c : currentAcc.Website_Grade__c;
          currentAcc.Segment__c = caseObj.Segment__c != null ? caseObj.Segment__c : currentAcc.Segment__c;
          currentAcc.Beta_Opt_Out__c = caseObj.BetaOptOut__c != null ? caseObj.BetaOptOut__c : currentAcc.Beta_Opt_Out__c;
          currentAcc.Instagram__c = caseObj.Instagram__c != null ? caseObj.Instagram__c : currentAcc.Instagram__c;
        }
        onboardingAccsToBeUpdatedList.add(currentAcc);
      }

      if(contactIdToContactMap.containsKey(caseObj.ContactId)) {
        Contact currentContact = contactIdToContactMap.get(caseObj.ContactId);
        
        // update contact data 
        if(currentContact != null) {
          currentContact.Preferredcontactmethod__c = caseObj.PreferredContactMethod__c != null ? caseObj.PreferredContactMethod__c : currentContact.Preferredcontactmethod__c;
        }
        onboardingContactsToBeUpdatedList.add(currentContact);
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

    // CSP-2750 Inbound Case
    if(Trigger.isInsert || Trigger.isUpdate){
      System.debug(LoggingLevel.INFO, '*** accountSet: ' + accountSet);
      if(!accountSet.isEmpty()){
        assignRecentCaseOwners((List<Case>)Trigger.new,accountSet,relatedContactMap);
      }

      if(caseList.size()>0) {
        // CSP-2178 Auto fill data from email into Review Cases, use to update the ID fields from description Strings
        updateFieldFromDescription(caseList);
      }
    }
  }

  /**
  *   All final logic in the "after" context should be done at this point such as modification to objects outside of
  *   the current object. At this point all updates to the current trigger transaction should be
  *   complete and all validation done.
  */
  public void afterAndFinally() {
    List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();
    List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();

    //CSP-2946 Update Onboarding Assignment Logic for Pooling
    if(trigger.isUpdate){
      // CSP-3195 Route All Onboarding Cases to Queue
      // When a case is reassigned by anyone, the child tasks to the case are assigned to the new case owner
      if(!onboardingCaseIdToCaseOwnerMap.isEmpty()){
        for(Task task : [SELECT Id, OwnerId, WhatId FROM Task WHERE WhatId IN: onboardingCaseIdToCaseOwnerMap.keySet()]){
          if(onboardingCaseIdToCaseOwnerMap.containsKey(task.WhatId)){
            task.OwnerId = onboardingCaseIdToCaseOwnerMap.get(task.WhatId);
          }    
          onboardingTasksToBeUpdatedList.add(task);
        }
        List<Database.SaveResult> saveTasksList = Database.update(onboardingTasksToBeUpdatedList); 
        xoExceptionList.addAll(ExceptionUtility.consumeException(saveTasksList));
      }
    }

    if (!onboardingTaskCaseIdSet.isEmpty() || !onboardingEmailCaseIdSet.isEmpty()) {
      try{
        List<Task> onboardingTaskList = new List<Task>(); 

        // retrieve the case info which will be used for creating welcome email and follow-up 1 task
        List<Case> caseList = [SELECT Id, CaseNumber, AccountId,ContactId,Contact.MobilePhone, OwnerId, Owner.Name 
                                FROM Case 
                                WHERE Id IN: onboardingTaskCaseIdSet OR Id IN: onboardingEmailCaseIdSet];

        for (Case currentCase : caseList) {
          // CSP-3195 Route All Onboarding Cases to Queue
          // Welcome email should go out immediately after case creation
          if(onboardingEmailCaseIdSet.contains(currentCase.Id)){
            Messaging.SingleEmailMessage newEmail = new Messaging.SingleEmailMessage();
            newEmail.setTemplateId(onboardEmailTemplateId);
            newEmail.setWhatId(currentCase.Id);
            newEmail.setTargetObjectId(currentCase.ContactId);
            newEmail.setOrgWideEmailAddressId(orgWideEmailAdd.Id);
            emailList.add(newEmail);
          }

          if(onboardingTaskCaseIdSet.contains(currentCase.Id)){
            Task newTask = new Task();
            newTask.RecordTypeId = tastkRecTypeNameMap.get('Standard Task').getRecordTypeId();
            newTask.WhatId = currentCase.Id;
            newTask.WhoId = currentCase.ContactId;
            newTask.Subject = 'Onboarding Follow-up 1';
            newTask.IsReminderSet = true;
            newTask.Purpose__c = 'Onboarding';

            if (!businessHourList.isEmpty()) {
              newTask.ActivityDate = DateUtility.AddBusinessDays(businessHourList[0].Id, Date.today(), 1);
              newTask.ReminderDateTime = Datetime.newInstance(DateUtility.AddBusinessDays(businessHourList[0].Id, Date.today(), 1), Time.newInstance(8, 0, 0, 0)) ;
            }else{
              newTask.ActivityDate = DateUtility.AddBusinessDays(Date.today(),1);
              newTask.ReminderDateTime = Datetime.newInstance(DateUtility.AddBusinessDays(Date.today(),1), Time.newInstance(8, 0, 0, 0)) ;
            }
            newTask.Mobile_Phone__c = currentCase.Contact.MobilePhone;
            newTask.Type = 'Call';
            newTask.Dispostition_Type__c = 'SS Core';
            // CSP-3064 Code Adjustments for new NVM disposition field 
            // Used Service Result replace Strategy Specialist Disposition Code
            newTask.ServiceResult__c = 'Onboarding Scheduling';  
            newTask.Status = 'Not Started';
            newTask.Priority = 'High';
            newTask.OwnerId = currentCase.OwnerId;
            
            onboardingTaskList.add(newTask);
          }
        }
        // generated task
        if (!onboardingTaskList.isEmpty()) {
          List<Database.SaveResult> taskSaveResultsList = Database.insert(onboardingTaskList); 
          xoExceptionList.addAll(ExceptionUtility.consumeException(taskSaveResultsList));
        }
      }catch(Exception ex){
        ExceptionUtility.consumeException(ex, true);
      }
    }

    // csp-2671
    if (!onboardingAccsToBeUpdatedList.isEmpty()) {
      List<Database.SaveResult> saveAccountsList = Database.update(onboardingAccsToBeUpdatedList); 
      xoExceptionList.addAll(ExceptionUtility.consumeException(saveAccountsList));
    }

    if (!onboardingContactsToBeUpdatedList.isEmpty()) {
      List<Database.SaveResult> saveContactsList = Database.update(onboardingContactsToBeUpdatedList); 
      xoExceptionList.addAll(ExceptionUtility.consumeException(saveContactsList));
    }

    // csp-2484 send email when user close case . 
    if(!caseIdEmailListMap.isEmpty()) {
      for(Id caseId : caseIdEmailListMap.keySet()) {
        if(!caseIdEmailListMap.get(caseId).isEmpty()) {
            for(Id targetId : caseIdEmailListMap.get(caseId)){
              //send email for every Account owner, Subscription sales rep, Account ss, Internal report.
              Messaging.SingleEmailMessage newEmail = new Messaging.SingleEmailMessage();
              newEmail.setTemplateId(closeCaseEmailTemplateId);
              newEmail.setWhatId(caseId);
              newEmail.setTargetObjectId(targetId);
              newEmail.setSaveAsActivity(false);
              newEmail.setOrgWideEmailAddressId(orgWideEmailAddForOutcome.Id);
              emailList.add(newEmail);
            }
        }
      }
    }

    // send email 
    if (!emailList.isEmpty()) {
      List<Messaging.SendEmailResult> results = Messaging.sendEmail(emailList, false);
      System.debug(LoggingLevel.INFO, '***  send email results: ' + results);
      xoExceptionList.addAll(ExceptionUtility.consumeException(results));
    }
    if (!xoExceptionList.isEmpty()) {
      insert xoExceptionList;
    } 
  }


/**
     *   CSP-2178 | Auto fill data from Description(email body) into Cases fields
     *
     *   @author Tony Liu
     *   @date   2017-06-02
     *   @param  List<Case>
     */
  public void updateFieldFromDescription (List<Case> caseList){
      
    // get the field mapping
    List<String> fieldmaps = CASE_EMAIL_FIELD_MAPPING.split(FIELDDELIM);
    System.debug(LoggingLevel.INFO, '*** fieldmaps: ' + fieldmaps);
    
    // parsing result map
    Map<String,String> resultMap = new Map<String,String>();

    // store the field label and api name in map
    Map<String,String> fieldMap = new Map<String,String>();
    // store field name in order
    List<String> fieldList = new List<String>();

    try {
      // save label and field api name as a map
      for(String str : fieldMaps){
        String strLabel = str.split(VALUEDELIM)[0].trim();
        String strField = str.split(VALUEDELIM)[1].trim();
        fieldMap.put(strLabel, strField);
        fieldList.add(strLabel);
      }

      // parsing the description content in case
      for(Case currentCase : caseList){
        
        String content = currentCase.Description_Custom__c.trim().toLowerCase();
        content = content.substring(content.indexOf(fieldList[0]));
        
        for(Integer i=0;i<fieldList.size();i++){
          
          Integer j = i+1;
          String result = '';
          String startField = fieldList[i];

          // get values
          if(j < fieldList.size()){
            String endField = fieldList[j];
            result = content.substringBetween(startField, endField).trim().removeEnd(',');
          }
          // get values from last index
          else if(j == fieldList.size()){
            result = content.substringBetween(startField, '.').trim().removeEnd('.');
          }

          System.debug(LoggingLevel.INFO, '*** result: ' + result);
          
          // if the special field like "StorefrontId__c" have a value, we should keep the field value, 
          if (String.valueOf(currentCase.get(fieldMap.get(startField))) == '' || String.valueOf(currentCase.get(fieldMap.get(startField))) == null) {
            // set object values ahd date value 
            if (startField.equalsIgnoreCase('Date:')) {
              
              if (result.equals('')) {
                currentCase.put(fieldMap.get(startField), null);
              }
              else{
                currentCase.put(fieldMap.get(startField), DateTime.parse(result));
              }
            }
            // set text field values
            else{
              currentCase.put(fieldMap.get(startField), result);
            }
          }
        }
      }
    }
    catch (Exception ex) {
      ExceptionUtility.consumeException(ex, true);
    }
  }

  /**
     *   CSP-2182 | Cancel Cases TCV Over $5K = High Priority
     *   if the parameter >=5000, return TRUE, else Return FALSE
     *   @author Tony Liu
     *   @date   2017-06-16
     *   @param  List<Case>
     */
  public void updateCasePriority (Decimal accountTCV, Case currentCase, Boolean isUpdate){
    currentCase.Account_TCV__c = accountTCV;

    String ITEM_DELMIN = ';';
    String LINE_DELMIN = '\n';

    /****
      * the label CASEPRIORITYRANGE store the string like follow: 
      * 0;Medium;5000
      * 5000;High
      * if 0<= accountTCV <5000, the priority is Medium, 
      * if 5000<= accountTCV, the priority is High
     *****/
    List<String> priorityList = CASE_PRIORITY_RANGE.split(LINE_DELMIN);
    
    for (Integer i = 0 ; i<priorityList.size(); i++) {
      
      List<String> priorityItemList = priorityList[i].split(ITEM_DELMIN);
      Decimal lowerTCV = Decimal.valueOf(priorityItemList[0].trim());
      
      if (i < priorityList.size()-1) {
        
        Decimal upperTCV = Decimal.valueOf(priorityItemList[2].trim());
        
        if (accountTCV >= lowerTCV && accountTCV < upperTCV) {
          currentCase.Priority = priorityItemList[1].trim();
          break;
        }
      }
      else if (i == priorityList.size()-1) {
        
        if (accountTCV >= lowerTCV) {
          currentCase.Priority = priorityItemList[1].trim();
          break;
        }
      }
    }
  }

  /**
     *   CSP-2417 Cases Loop Breaker -- Try to break the infinite loop for auto response case emails
     *   within "timeLength" and if it contains more than "numOfEmails" same case records
     *   @author Nick Wu
     *   @date   2017-09-18
     *   @lastmodifiedBy Tony Liu
     */ 
  public static Set<String> caseInfiniteLoopKiller(){

    Integer numOfEmails = Integer.valueOf(system.Label.Param_Kill_Case_Reply_Loop.split(VALUEDELIM)[1]);
    Integer timeLength = Integer.valueOf(system.Label.Param_Kill_Case_Reply_Loop.split(VALUEDELIM)[0]);
    Datetime durationTime = System.now().addMinutes(-timeLength);

    List<AggregateResult> subjectCount = [SELECT COUNT(Id) EmailCount, SuppliedEmail FROM Case WHERE 
                                          CreatedDate >: durationTime AND 
                                          SuppliedEmail <> NULL GROUP BY 
                                          SuppliedEmail HAVING COUNT(Id) >: numOfEmails
                                          ];

    // Map<String,Integer> emailLoopMap = new Map<String,Integer>();
    Set<String> emailEndLoopSet = new Set<String>();
    for (AggregateResult agg : subjectCount) {
      emailEndLoopSet.add(String.valueOf(agg.get('SuppliedEmail')));
    }
    return emailEndLoopSet;
  }

  // CSP-2750 Inbound case
  // Assign the recent case owner to new created inbound case
  public static void assignRecentCaseOwners(List<Case> ownerAssignmentCaseList, Set<Id> accountSet, Map<Id, Contact> relatedContactMap){

    Map<Id, Case> openedAccountWithCaseOwnerMap = new Map<Id, Case>();

    // CSP-2750 Inbound Cases
    // Query recently opened cases and owner based on accountset
    if(!accountSet.isEmpty()){

      // query all related opened cases with accountId
      List<Case> cases = [SELECT Id, OwnerId, AccountId, ContactId, Contact.AccountId, CreatedDate FROM Case 
                            WHERE isClosed = FALSE AND 
                            Recordtype.Name IN:recordtypeSet AND 
                            AccountId IN: accountSet
                            ORDER BY CreatedDate DESC];

      // put all the accounts and case into a map, Key= account, and value = recently Date/Time Opened (createddate)
      for(Case c : cases){

        // if the case contains accountId
        if(String.isNotBlank(c.AccountId)){

          if(!openedAccountWithCaseOwnerMap.containsKey(c.AccountId)){
            openedAccountWithCaseOwnerMap.put(c.accountId, c);
          }
        }
      }

      // check if the map is not empty
      if(!openedAccountWithCaseOwnerMap.isEmpty()){

        for(Case currentCase : ownerAssignmentCaseList){
          
          if(String.isNotBlank(currentCase.AccountId)){
            if(openedAccountWithCaseOwnerMap.containsKey(currentCase.AccountId)){
              currentCase.OwnerId = openedAccountWithCaseOwnerMap.get(currentCase.AccountId).OwnerId;
            }
          }
          else if(String.isNotBlank(currentCase.ContactId)){

            String accId = '';
            
            if(relatedContactMap.containsKey(currentCase.ContactId)){
              accId = relatedContactMap.get(currentCase.ContactId).accountId;
            }

            if(openedAccountWithCaseOwnerMap.containsKey(accId)){
              currentCase.OwnerId = openedAccountWithCaseOwnerMap.get(accId).OwnerId;
            }
          }
        }
      }
    }
  }
}