public without sharing class CampaignMemberTriggerHandler implements XOTrigger{

    // CSP-3040 | Salesforce Sync Error in Hubspot - paid media and hot campaign conflicting
    private Map<Id,Lead> needUpdateLeadMap = new Map<Id,Lead>();
    private Map<Id,Account> needUpdateAccountMap = new Map<Id,Account>();

    private Map<Id,Id> leadIdMatchingCamMemberIdMap = new Map<Id,Id>();
    private Map<Id,Id> accIdmatchingCamMemberIdMap = new Map<Id,Id>();
  
    // CSP-2825 Re-engage an Account
    // Store CampaignMember and parent object info 
    private Map<Id,CampaignMember> camMemberMap = new map<Id,CampaignMember>();
    private static final Id distactAccountId;
    private static final String dataEnrichmentUserId = Label.DataEnrichmentUserId; 

    static {
    List<XO_Exception__c> exceptionList = new List<XO_Exception__c>();

    try {
      for (User currentUser : [SELECT Id,Name,Alias FROM User WHERE Alias = 'distacts' AND IsActive = true]) {
        distactAccountId = currentUser.Id;
      }
      } catch (Exception e) {
      XO_Exception__c xoException = ExceptionUtility.consumeException(e, false);
      xoException.Severity__c = 'Critical';
      xoException.Failure_Area__c = 'Lead Assignment Workflow Exception';
      exceptionList.add(xoException);
      }
    
    insert exceptionList;
  }
  /**
     * Method used to bulkify all data needed in any "before" action of a trigger.
     */
    public void bulkBefore() {
    }

    /**
     *   Method used to bulkify all data needed in any "after" action of a trigger.
     */
    public void bulkAfter() {

        // CSP-2825 Re-engage an Account
        // Merge insert and update for query Campaign Member and parent object info 
        if(trigger.isInsert || trigger.isUpdate) {

            List<Account> accountList = new List<Account>();

            // CSP-2825 Re-engage an Account
            // CSP-2645 Reassign Existing Paid Media Prospects to Distributable queue
            // CSP-2616 Hot Campaigns & DE
            // Get CampaignMember and parent object info 
            camMemberMap = new map<id,CampaignMember>([SELECT Id, CampaignId, LeadId, Campaign.Notify_Sales_Team__c, Campaign.Type, ContactId, 
                                                                                        Lead.RecordType.Name, Lead.Status, HasResponded, Contact.Account.DE_Backlog__c,
                                                                                        lead.DE_Backlog__c, Lead.Related_to_Paid_Media__c, Lead.IsConverted,  
                                                                                        Contact.AccountId, Contact.Account.Portfolio__c, Contact.Account.BillingPostalCode,
                                                                                        Contact.Account.Local_Paid_Status__c, Contact.Account.Related_to_Paid_Media__c, Contact.Name,
                                                                                        Contact.Account.Zip__r.ZipCode__c, Contact.Account.Local_Sales_Market__c, Contact.Account.Primary_Category__c, 
                                                                                        Contact.Account.RecordType.Name, Contact.Account.Account_Status__c, Status,Contact.Account.BillingCountryCode  
                                                                                FROM CampaignMember 
                                                                                WHERE Id IN: trigger.new]);
            for(CampaignMember camMember : camMemberMap.values()) {
                //Get all Local Account list if Campaign Member under contact 
                if(hasLocalAccount(camMember)){
                    Account camMemberAcc = camMember.Contact.Account;
                    accountList.add(camMemberAcc);
                }
                /**
                 *  CSP-3040 | Salesforce Sync Error in Hubspot - paid media and hot campaign conflicting
                 *  When Hubspot syncs information with Salesforce and a prospect has newly responded to both a paid media campaign and a hot campaign, 
                 *  the prospect routing logic for the paid media campaign should take precedence.
                 *  We need to update related lead and account when a propect has newly responded a hot campaign.
                 */
                if(hasHotCampaign(camMember)){                  
                  if(hasLocalUnconvertedLead(camMember) && !leadIdMatchingCamMemberIdMap.containsKey(camMember.LeadId)){
                    leadIdMatchingCamMemberIdMap.put(camMember.LeadId, camMember.Id);
                  }
                  
                  if(hasLocalAccount(camMember) && !accIdMatchingCamMemberIdMap.containsKey(camMember.Contact.AccountId)){
                    accIdMatchingCamMemberIdMap.put(camMember.Contact.AccountId, camMember.Id);
                  }
                }
                //A paid media campaign takes precedence over a hot campaign
                if(hasPaidMediaCampaign(camMember)){                  
                  if(hasLocalUnconvertedLead(camMember)){
                    leadIdMatchingCamMemberIdMap.put(camMember.LeadId, camMember.Id);
                  }
                  
                  if(hasLocalAccount(camMember)){
                    accIdMatchingCamMemberIdMap.put(camMember.Contact.AccountId, camMember.Id);
                  }
                }
            }
            System.debug(LoggingLevel.INFO, '*** leadIdMatchingCamMemberIdMap: ' + leadIdMatchingCamMemberIdMap);
            //Build Assignment Map
            if(!accountList.isEmpty()) {
              AssignmentRulesUtility.buildAssignmentMap(accountList);
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
    public void beforeInsert(SObject so) {}

    /**
    *   All before update logic should be done here. This method is called iteratively and as such
    *   should contain no actions which could potentially hit limits or is considered bad practice
    *   in the Salesforce environment.
    *
    *   @param  {SObject}   oldSo Single SObject representation of the "old" copy of the current 
    *                             object being acted upon.
    *   @param  {SObject}   so    Single SObject representation of the object being acted upon.
    */
    public void beforeUpdate(SObject oldSo, SObject so) {}

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

        CampaignMember newMember = (CampaignMember)so;

        if(camMemberMap.containsKey(newMember.id)) {
          CampaignMember camMember = camMemberMap.get(newMember.id);
            
          // Campaign Member under lead
          // CSP-2645 merge the code of CSP-2616, if the a lead or a contact has been associate to a paid media campaign, 
          // Update the Related_to_Paid_Media__c of the lead and account. update the DE_Backlog__c of lead when lead has been associated to 
          // a Campaign need to Notify_Sales_Team 
          if( hasLocalUnconvertedLead(camMember)
              // we do not need to update the lead if leadIdMatchingCamMemberIdMap doesn't contain it 
              && leadIdMatchingCamMemberIdMap.containsKey(camMember.LeadId)
              // needUpdateLeadMap is used to avoid update leads repeatedly
              && !needUpdateLeadMap.containsKey(camMember.LeadId)
              && leadIdMatchingCamMemberIdMap.get(camMember.LeadId) == camMember.Id) {
              
              Lead newLead = new Lead();
              newLead.Id = camMember.LeadId;

              //CSP-3040 - Paid Media Campaign takes precedence over hot campaign
              if(hasPaidMediaCampaign(camMember)){

                //CSP-2645 - Update the Related_to_Paid_Media__c of the lead and account
                newLead.Related_to_Paid_Media__c = true;

                //CSP-2645 - update the DE_Backlog__c of lead when lead has been associated to a Campaign need to Notify_Sales_Team 
                if(camMember.Campaign.Notify_Sales_Team__c == true && camMember.Lead.DE_Backlog__c == true ){
                  newLead.DE_Backlog__c = false;
                }

              }
              // CSP-2851 Hot Prospect Treatments - Fast-Track
              // hot campaign means Campaign.Notify_Sales_Team__c = true or Internal Referral campaigns that a prospect responded 
              else if(hasHotCampaign(camMember)){

                //CSP-2851 - set DE Backlog to false for leads
                newLead.DE_Backlog__c = false;

                //if the record is a Lead whose status is not "Invalid" or "Disqualified"
                if(camMember.Lead.Status != 'Invalid' && camMember.Lead.Status != 'Disqualified'){
                  //CSP-2851 - the Lead Status is updated to "Valid" if it was "New"
                  if(camMember.Lead.Status == 'New'){
                    newLead.Status = 'Valid';
                  }
                  //newLead.HotCampaign__c = True; // CSP-3042 SIVA VANKADARU 08/10/208
                }

              }
              
              needUpdateLeadMap.put(newLead.Id, newLead);
          }

          // CSP-2836 Hubspot updating owner on paid accounts after lead merge
          // Change the account owner to distact only if the Account Local Paid Status is not "Paid"
          // CSP-2825 Re-engage an Account
          // Change the account owner and Account Status if the Account Status is not "Active"
          // Campaign Member under Contact 
          if( hasLocalAccount(camMember)
              && accIdMatchingCamMemberIdMap.containsKey(camMember.Contact.AccountId)
              && !needUpdateAccountMap.containsKey(camMember.Contact.AccountId)
              && accIdMatchingCamMemberIdMap.get(camMember.Contact.AccountId) == camMember.Id) {

              Account camMemberAcc = camMember.Contact.Account;

              //Paid Media Campaign
              if(hasPaidMediaCampaign(camMember)){

                camMemberAcc.Related_to_Paid_Media__c = true;

                if(camMember.Contact.Account.Account_Status__c != 'Active'){
                  camMemberAcc.OwnerId = distactAccountId;
                  camMemberAcc = setAccountStatus(camMemberAcc);
                }

              }
              // CSP-2851 Hot Prospect Treatments - Fast-Track
              else if(hasHotCampaign(camMember)){

                //CSP-2851,CSP-2872 - the DE Backlog flag is set to "False"
                camMemberAcc.DE_Backlog__c = false;

                //if the record is an Account whose status is not "Active":
                if(camMember.Contact.Account.Account_Status__c != 'Active'){
                  //CSP-2851,CSP-2825 - the Account Status is updated to "Qualified" if it was "Disqualified" or "Dormant"
                  camMemberAcc = setAccountStatus(camMemberAcc);
                  //CSP-2825 - Change the account owner if the Account Status is not "Active"
                  camMemberAcc = accOwnerAssignment(camMemberAcc);
                }
              }
              
              needUpdateAccountMap.put(camMemberAcc.Id, camMemberAcc);
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
        CampaignMember newMember = (CampaignMember)so;
        CampaignMember oldMember = (CampaignMember)oldSo;

        if(camMemberMap.containsKey(newMember.id)) {
            CampaignMember currentMember = camMemberMap.get(newMember.id);

            if(hasLocalUnconvertedLead(currentMember)) {

              Lead newLead = new Lead();
              newLead.Id = currentMember.LeadId;
              // CSP-2851 Hot Prospect Treatments - Fast-Track
              if(currentMember.Status != oldMember.Status && hasHotCampaign(currentMember)){

                // set DE Backlog to false for leads
                newLead.DE_Backlog__c = false;

                //if the record is a Lead whose status is not "Invalid" or "Disqualified"
                if(currentMember.Lead.Status != 'Invalid' && currentMember.Lead.Status != 'Disqualified'){
                  //the Lead Status is updated to "Valid" if it was "New"
                  if(currentMember.Lead.Status == 'New'){
                    newLead.Status = 'Valid';
                  }
                  //newLead.HotCampaign__c = True; // CSP-3042 SIVA VANKADARU 08/10/208

                }         
              }
              needUpdateLeadMap.put(newLead.Id, newLead);
            }


            if(hasLocalAccount(currentMember)) {

              Account camMemberAcc = currentMember.Contact.Account;

              // CSP-2851 Hot Prospect Treatments - Fast-Track 
              if(currentMember.Status != oldMember.Status && hasHotCampaign(currentMember)){

                //CSP-2851 - the DE Backlog flag is set to "False"
                camMemberAcc.DE_Backlog__c = false;

                // CSP-2825 Re-engage an Account
                // Change the account owner and Account Status by responding to an Internal Referral Campaign 
                if(currentMember.Contact.Account.Account_Status__c != 'Active'){

                  camMemberAcc = setAccountStatus(camMemberAcc);   
                  camMemberAcc = accOwnerAssignment(camMemberAcc);

                }
              }

              needUpdateAccountMap.put(camMemberAcc.Id, camMemberAcc);
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
    public void beforeAndFinally() {}


    /**
    *   All final logic in the "after" context should be done at this point such as modification to objects outside of
    *   the current object. At this point all updates to the current trigger transaction should be
    *   complete and all validation done.
    */
    public void afterAndFinally() {

    List<XO_Exception__C> xoExceptionList = new List<XO_Exception__C>();

        //CSP-2616 logic End, Update lead DE backlog
        if(!needUpdateLeadMap.isEmpty()){
            List<Database.SaveResult> resultList = Database.update(needUpdateLeadMap.values(), false);
            xoExceptionList.addAll(ExceptionUtility.consumeException(resultList));
        }
        
        //CSP-2825 Re-engage an Account 
        //Update Account owner and Account status
        if(!needUpdateAccountMap.isEmpty()){
            List<Database.SaveResult> resultList = Database.update(needUpdateAccountMap.values(), false);
            xoExceptionList.addAll(ExceptionUtility.consumeException(resultList));
        }

        if(!xoExceptionList.isEmpty()){
          insert xoExceptionList;
        }
    }
    
    /**
     * CSP-3040 Salesforce Sync Error in Hubspot - paid media and hot campaign conflicting
     * If the campaignMember has a local unconverted lead, return true
     * 
     * @Author Steven
     * @Date   2018-08-13
     * @param  camMember
     * @return Boolean
     */
    private Boolean hasLocalUnconvertedLead(CampaignMember camMember) {
      Boolean hasLocalUnconvertedLead = false;
      if(camMember != null 
        && String.isNotBlank(camMember.LeadId) 
        && !camMember.Lead.IsConverted 
        && camMember.Lead.RecordType.Name.containsIgnoreCase('Local')){

        hasLocalUnconvertedLead = true;
      }
      return hasLocalUnconvertedLead;
    }

    /**
     * CSP-3040 Salesforce Sync Error in Hubspot - paid media and hot campaign conflicting
     * If the campaignMember has a local account, return true
     * 
     * @Author Steven
     * @Date   2018-08-13
     * @param  camMember
     * @return Boolean
     */
    private Boolean hasLocalAccount(CampaignMember camMember) {
      Boolean hasLocalAccount = false;
      if(camMember != null 
        && String.isNotBlank(camMember.ContactId) 
        && String.isNotBlank(camMember.Contact.AccountId) 
        && camMember.Contact.Account.RecordType.Name.equalsIgnoreCase('Local')){

        hasLocalAccount = true;
      }
      return hasLocalAccount;
    }

    /**
     * CSP-3040 Salesforce Sync Error in Hubspot - paid media and hot campaign conflicting
     * hot campaign means Campaign.Notify_Sales_Team__c = true or Internal Referral campaigns that a prospect responded
     * If the campaignMember has a hot campaign, return true
     * 
     * @Author Steven
     * @Date   2018-08-13
     * @param  camMember
     * @return Boolean
     */
    private Boolean hasHotCampaign(CampaignMember camMember) {
      Boolean hasHotCampaign = false;
      if(camMember != null
        && ((camMember.Campaign.Type == 'Internal Referral' && camMember.Status == 'Responded')
        || camMember.Campaign.Notify_Sales_Team__c)){

        hasHotCampaign = true;
      }
      return hasHotCampaign;
    }

    /**
     * CSP-3040 Salesforce Sync Error in Hubspot - paid media and hot campaign conflicting
     * If the campaignMember has a paid media campaign, return true
     * 
     * @Author Steven
     * @Date   2018-08-13
     * @param  camMember
     * @return Boolean
     */
    private Boolean hasPaidMediaCampaign(CampaignMember camMember) {
      Boolean hasPaidMediaCampaign = false;
      if(camMember != null && camMember.Campaign.Type == 'Paid Media'){
        
        hasPaidMediaCampaign = true;
      }
      return hasPaidMediaCampaign;
    }

    /**
     * CSP-2825 Re-engage an Account
     * Set Account Status to Qualified if it was dead or inactive
     * 
     * @Author Mason
     * @Date   2018-05-04
     * @param  acc
     * @return Account
     */
    private Account setAccountStatus(Account acc) {

        String accountStatus = acc.Account_Status__c;
        System.debug(LoggingLevel.INFO, '*** accountStatus: ' + accountStatus);
        //Updated to "Qualified" if it was dead or inactive
        if(String.isBlank(accountStatus) 
            || accountStatus == 'Disqualified'  
            || accountStatus == 'Dormant') {

            acc.Account_Status__c = 'Qualified';
            acc.Negative_Disposition_Reason__c = '';
        }
        return acc;
    }


      /**
       * CSP-2825 Re-engage an Account
     * Account owner Assignment
     *
     * * @Author Mason
     *   @Date   2018-05-21
     *   @param  acc
     *   @return Account
     */
    private Account accOwnerAssignment(Account acc) {

      // Account related to paid media or SSE Portfolio 
      if(acc.Related_to_Paid_Media__c || acc.Portfolio__c == 'Senior Sales Executive') {
        acc.OwnerId = distactAccountId;
      }
      // Execute assignment rule for Account
      else {
          Local_Sales_Rep_Assignment__c localSalesRepAssignmentRecord = AssignmentRulesUtility.getRecordAssignment(acc);

          if(localSalesRepAssignmentRecord != null) {
              // If there is an assignment record found, and have specific sales rep,
              // then will assign the account to this sales rep.
              if(localSalesRepAssignmentRecord.Sales_Rep__c != null) {
                acc.OwnerId = localSalesRepAssignmentRecord.Sales_Rep__c;
              }
              // CSP-3018 Re-engage an Account via DisE (when Sales Rep not assigned)
              // If there is an assignment record found, but the Sales rep is empty,
              // then it should assign out to distributable account.
              else{
                acc.OwnerId = distactAccountId;
              }
          }
          else {
              // If not find local user to do
              acc.OwnerId = dataEnrichmentUserId; 
              acc.Account_Status__c = 'Dormant';
              acc.Negative_Disposition_Reason__c = 'Missing Required Information';
          }
      }
      return acc; 
    }
}