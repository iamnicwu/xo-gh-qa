global with sharing class JavascriptButtonService {
  
  //////////////////////
  // STATIC VARIABLES //
  //////////////////////

  // CSP-1306 Nick Wu modified
  // add one more field in the Opportunity query No_of_Times_To_Extend__c
  private static final String OPP_QUERY = 'SELECT '
                                            + 'Id, '
                                            + 'StageName, '
                                            + 'Contract_Signer__c, '
                                            + 'Three_Business_Days_From_Today__c, '
                                            + 'Opportunity_Expiration_Date__c, '
                                            + 'EchoSign_Contract_Due_Date__c, '
                                            + 'No_of_Times_To_Extend__c, '
                                            + 'AccountId, '
                                            + '(SELECT zqu__TermStartDate__c, zqu__SubscriptionType__c, zqu__BillToContact__c, zqu__SoldToContact__c FROM zqu__Quotes__r ORDER BY CreatedDate DESC) '
                                            + 'FROM '
                                            + 'Opportunity '
                                            + 'WHERE '
                                            + '{WHERECLAUSE}';

  private static final String ATTACHMENT_COUNT_QUERY = 'SELECT '
                                                        + 'COUNT()'
                                                      + ' FROM '
                                                        + ' Attachment '
                                                      + ' WHERE '
                                                        + ' ParentId = \'{ATTACHPARENTID}\''
                                                      + ' AND '
                                                        + ' Name LIKE \'%preview.pdf\'';

  // csp-2151
  private static final String AGREEMENT_TEMPLATE_QUERY = 'SELECT '
                                                        + 'Id'
                                                      + ' FROM '
                                                        + ' echosign_dev1__Agreement_Template__c '
                                                      + ' WHERE '
                                                        + ' Name = \'{AGREEMENT_TEMPLATE_NAME}\'';

  // CSP-2697 Run Assignment Rules on Accounts
  // Query Account information for assignment rule
  private static final String ACCOUNT_QUERY = 'SELECT '
                                              + ' Id, '
                                              + ' CreatedById, '
                                              + ' Local_Sales_Market__c, '
                                              + ' Primary_Category__c, '
                                              + ' BillingPostalCode, '
                                              + ' BillingCountryCode '
                                              + ' FROM '
                                              + ' ACCOUNT '
                                              + ' WHERE '
                                              + '{WHERECLAUSE}';

  /**
   *   Method/function used to validate that an Opportunity is ready to send an EchoSign agreement to a customer.
   *   Previously all of this logic existed in a javascript button and was doing unstable logic to process dates and
   *   compare them against one another. All logic has now been moved into a webservice method for stability and
   *   functionality. An Opportunity is only ready to send an agreement when the Stage is correct, there is a contract
   *   signer, the contract due date has not passed, and there is a PDF attachment created from the quote.
   *
   *   Upon determining that the Opportunity is valid for sending it has its "Three Business Days From Today" field updated
   *   to be five days from today. This field is actually being used as an EchoSign expiration field.
   *
   *   @author Justin
   *   @date   2016-05-18
   *   @param  {String}        oppId  The Opportunity Id of the Opportunity record which will need to be validated.
   *   @return {String}               The JSON representation of the "ButtonServiceReponse" object.
   */
  webservice static String validateSignatureProceed(String oppId) {
    ButtonServiceResponse response = new ButtonServiceResponse();
    response.success = false;

    if(String.isBlank(oppId)) {
      response.errorMessage = 'Invalid Opportunity ID Provided';
      return JSON.serialize(response);
    }

    String oppQuery = OPP_QUERY.replace('{WHERECLAUSE}', ' Id = :oppId');
    String attachCountQuery = ATTACHMENT_COUNT_QUERY.replace('{ATTACHPARENTID}', oppId);
    Opportunity currentOpp;
    Integer attachCount;
    try{
      currentOpp = Database.query(oppQuery);
      attachCount = Database.countQuery(attachCountQuery);
    } catch(Exception e) {
      response.errorMessage = e.getMessage();
      return (JSON.serialize(response));
    }

    //csp-2151
    String subscriptionType = currentOpp.zqu__Quotes__r[0].zqu__SubscriptionType__c;
    String agreementTemplateQuery;
    if(subscriptionType == 'Amend Subscription'){
      agreementTemplateQuery = AGREEMENT_TEMPLATE_QUERY.replace('{AGREEMENT_TEMPLATE_NAME}', 'Local Amendment Agreement Template 20160127');
    } else {
      agreementTemplateQuery = AGREEMENT_TEMPLATE_QUERY.replace('{AGREEMENT_TEMPLATE_NAME}', 'Local Standard Agreement Template 20170524');      
    }


    echosign_dev1__Agreement_Template__c currentAgreementTemplate;
    try {
      currentAgreementTemplate  = Database.query(agreementTemplateQuery);
      response.agreementTemplateId = currentAgreementTemplate.Id;
    } catch(Exception e) {
      response.errorMessage = e.getMessage();
      return (JSON.serialize(response));
    }
    // end of logic for csp-2151

    // CSP-2250 Inactive Contacts should not be available for QTC
    Set<Id> checkActiveContactIds = new Set<Id>();
    Map<Id, String> contactTypeMap = new Map<Id, String>(); 


    // CSP-1610 | validate Quote Term Start Dates
    List<String> quoteIdsWithTermStartDateLessThanToday = new List<String>();
    Map<String, String> quotesWithTermStartDateLessThanFiveBizDays = new Map<String, String>();
    Date earliestTermStartDate;
    for (Integer i = 0; i < currentOpp.zqu__Quotes__r.size(); i++) {
      zqu__Quote__c quote = currentOpp.zqu__Quotes__r[i];
      // CSP-2250 Inactive Contacts should not be available for QTC
      checkActiveContactIds.add(quote.zqu__BillToContact__c);
      contactTypeMap.put(quote.zqu__BillToContact__c, 'Bill to Contact' );
      checkActiveContactIds.add(quote.zqu__SoldToContact__c);
      contactTypeMap.put(quote.zqu__SoldToContact__c, 'Sold to Contact' );

      if (quote.zqu__TermStartDate__c < Date.today()) {
        quoteIdsWithTermStartDateLessThanToday.add(quote.Id);
        continue;
      }
      if (DateUtility.AddBusinessDays(Date.today(), 5) > quote.zqu__TermStartDate__c) {
        quotesWithTermStartDateLessThanFiveBizDays.put(quote.Id, quote.zqu__TermStartDate__c.format());
        if (earliestTermStartDate == null || quote.zqu__TermStartDate__c < earliestTermStartDate) {
          earliestTermStartDate = quote.zqu__TermStartDate__c;
        }
      }
    }

    // CSP-2250 Inactive Contacts should not be available for QTC
    checkActiveContactIds.add(currentOpp.Contract_Signer__c);
    contactTypeMap.put(currentOpp.Contract_Signer__c, 'Contract Signer');
    List<Contact> checkInactiveContactList = [Select Id, Name From Contact Where Id in :checkActiveContactIds  And Status__c = 'Inactive'];

    // CSP-1960 CONTACT VAL Error: Contact missing First and Last Name
    List<Contact> accContactList = [Select Id, Name, FirstName, LastName From Contact Where Id in 
    (Select ContactId From AccountContactRole Where AccountId = :currentOpp.AccountId AND (Role = 'Primary' OR Role = 'Billing')) Limit 1];
    
    // Begin logic/validation to determine if an error should be thrown. Errors are using Custom Labels so that the
    // message can be changed outside of code in production.
    if(currentOpp.StageName != 'Ready for Echo-Sign') {
      response.errorMessage = Label.Stage_Invalid_For_Signature;
    } else if(quoteIdsWithTermStartDateLessThanToday.size() > 0) {
      response.errorMessage = 'WARNING!\nThe following Quote\'s have a Term Start Date prior to today:\n';
      for (Integer i = 0; i < quoteIdsWithTermStartDateLessThanToday.size(); i++) {
        response.errorMessage += quoteIdsWithTermStartDateLessThanToday[i] + '\n';
      }
      response.errorMessage += 'Please edit the Term Start Dates to a future date and resubmit for approval.';
    } else if(String.isBlank(currentOpp.Contract_Signer__c)) {
      response.errorMessage = Label.No_Opp_Contract_Signer;
    } else if(attachCount < 1) {
      response.errorMessage = Label.Quote_PDF_Error;
    } else if(quotesWithTermStartDateLessThanFiveBizDays.size() > 0) {
      // if this message changes the Opportunity.Send_For_Signature button will need to be updated (used in button JS logic)
      response.errorMessage = 'WARNING!\nThe following Quote\'s have a Term Start Date of less than 5 business days from today:\n';
      for (String quoteId : quotesWithTermStartDateLessThanFiveBizDays.keySet()) {
        response.errorMessage += quoteId + ': ' + quotesWithTermStartDateLessThanFiveBizDays.get(quoteId) + '\n';
      }
      response.errorMessage += 'Your customer will have to sign by ' + earliestTermStartDate.format() + ' in order to fulfill services.\n';
      response.errorMessage += 'Would you like to proceed?';
    } else if(accContactList.size() > 0 && (String.isBlank(accContactList[0].FirstName) || String.isBlank(accContactList[0].LastName))){
      // CSP-1960 CONTACT VAL Error: Contact missing First and Last Name
      response.errorMessage = 'The Primary/Billing Contact must have a First Name and Last Name for fulfillment.\r\n ';
      response.errorMessage += '\r\nPress \"Okay\" to navigate to the Contact or \"Cancel\" to stay on the Opportunity';
      response.errorMessage += '\r\n\r\nContact: ' + accContactList[0].Name;
      response.errorMessage += '\r\nURL: ' + System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + accContactList[0].Id ;
      
    } else if(checkInactiveContactList.size() > 0){
      // CSP-2250 Inactive Contacts should not be available for QTC
      String contactType = contactTypeMap.get(checkInactiveContactList[0].Id) ;
      response.errorMessage = 'The ' + contactType + ' that you have selected is no longer active; please select an active contact for the ' + contactType + ' to continue.\r\n';
      response.errorMessage += '\r\n\r\nContact: ' + checkInactiveContactList[0].Name;
    }else {
      response.success = true;
      currentOpp.Three_Business_Days_From_Today__c = DateUtility.addBusinessDays(Date.today(), 5);
      // if the opp expiration date is less than the echosign contract due date (api name: Three_Business_Days_From_Today__c), align the dates
      currentOpp.Opportunity_Expiration_Date__c = currentOpp.Opportunity_Expiration_Date__c < currentOpp.Three_Business_Days_From_Today__c ? currentOpp.Three_Business_Days_From_Today__c : currentOpp.Opportunity_Expiration_Date__c;
      update currentOpp;
    }

    return JSON.serialize(response);
  }

    // CSP-1306 Nick Wu added
    // this webservice is used to update Opportunity auto close date by clicking that button
    webservice static String updateAutoCloseDate(String oppId) {
        ButtonServiceResponse response = new ButtonServiceResponse();
        response.success = false;

        if(String.isBlank(oppId)) {
            response.errorMessage = 'Invalid Opportunity ID Provided';
            return JSON.serialize(response);
        }

        String oppQuery = OPP_QUERY.replace('{WHERECLAUSE}', ' Id = :oppId');

        Opportunity currentOpp;
        Integer attachCount;
        try{
            currentOpp = Database.query(oppQuery);
            if(currentOpp.No_of_Times_To_Extend__c == null){
              currentOpp.No_of_Times_To_Extend__c = 0;
            }
            currentOpp.No_of_Times_To_Extend__c ++; // auto increase the #Of times to click the button
            update currentOpp;  // update the opp after increasing #Of times
            response.success = true;
            response.errorMessage='Extended the auto close day successfully!';
        } 
        catch(Exception e) {
            response.errorMessage = e.getMessage();
            return (JSON.serialize(response));
        }

        return JSON.serialize(response);
    }

  /**
   *   Updates the Opportunity's Echosign Expiration Date (Three_Business_Days_From_Today__c) to the soonest Term Start Date of the child Quotes
   *
   *   @author Jonathan
   *   @date   2016-12-02
   *   @param  {String}        oppId  The Opportunity Id of the Opportunity record which will need to be validated.
   *   @return {String}               The JSON representation of the "ButtonServiceReponse" object.
   */
    webservice static String updateEchosignExpirationDate(String oppId) {
        ButtonServiceResponse response = new ButtonServiceResponse();
        response.success = false;

        if (String.isBlank(oppId)) {
            response.errorMessage = 'Invalid Opportunity ID Provided';
            return JSON.serialize(response);
        }

        String oppQuery = OPP_QUERY.replace('{WHERECLAUSE}', ' Id = :oppId');
        Opportunity currentOpp;
        try {
          currentOpp = Database.query(oppQuery);
          Date earliestTermStartDate;
          for (Integer i = 0; i < currentOpp.zqu__Quotes__r.size(); i++) {
            zqu__Quote__c quote = currentOpp.zqu__Quotes__r[i];
            if (earliestTermStartDate == null || quote.zqu__TermStartDate__c < earliestTermStartDate) {
              earliestTermStartDate = quote.zqu__TermStartDate__c;
            }
          }
            currentOpp.Three_Business_Days_From_Today__c = earliestTermStartDate != null ? earliestTermStartDate : Date.today();
            // if the opp expiration date is less than the echosign contract due date (api name: Three_Business_Days_From_Today__c), align the dates
            currentOpp.Opportunity_Expiration_Date__c = currentOpp.Opportunity_Expiration_Date__c < currentOpp.Three_Business_Days_From_Today__c ? currentOpp.Three_Business_Days_From_Today__c : currentOpp.Opportunity_Expiration_Date__c;            
            update currentOpp;

            //csp-2590 add logic to check subscription type is Amendment or not
            String subscriptionType = currentOpp.zqu__Quotes__r[0].zqu__SubscriptionType__c;
            String agreementTemplateQuery;
            if(subscriptionType == 'Amend Subscription'){
              agreementTemplateQuery = AGREEMENT_TEMPLATE_QUERY.replace('{AGREEMENT_TEMPLATE_NAME}', 'Local Amendment Agreement Template 20160127');
            } else {
              agreementTemplateQuery = AGREEMENT_TEMPLATE_QUERY.replace('{AGREEMENT_TEMPLATE_NAME}', 'Local Standard Agreement Template 20170524');      
            }
            echosign_dev1__Agreement_Template__c currentAgreementTemplate;
            currentAgreementTemplate  = Database.query(agreementTemplateQuery);
            response.agreementTemplateId = currentAgreementTemplate.Id;
            //csp-2590 add logic end
            response.success = true;
        } 
        catch(Exception e) {
            response.errorMessage = e.getMessage();
            return (JSON.serialize(response));
        }

        return JSON.serialize(response);
    }

    /**
     * CSP-2544 validate website, phone and extension for lead convert button
     * @Author Nick
     * @Date   2017-11-16
     * @param  phone      phone number
     * @param  extension  phone extension
     * @param  website    website
     * @return            The JSON representation of the "ButtonServiceReponse" object.
     */

    WebService static String validLeadFields(String phone, String extension, String website){

      ButtonServiceResponse response = new ButtonServiceResponse();
      response.success = true;

      // phone format validation
      if (!String.isBlank(phone)) {
          DataUtility.ValidationResult phoneValidation = DataUtility.formatPhoneNumber(phone);
          // If phone invalid, return false and error message to custom button
          if(!phoneValidation.valid) {
            response.success = false;
            response.errorMessage = System.Label.Phone_Validation_Error;
            return JSON.serialize(response);
          }
      }

      // extension format validation
      if(!String.isBlank(extension)){
        DataUtility.ValidationResult extValidation = DataUtility.formatExt(extension);
        // If extension invalid, return false and error message to custom button
        if(!extValidation.valid) {
          response.success = false;
          response.errorMessage = System.Label.Ext_Validation_Error;
          return JSON.serialize(response);
        }
      }

      // website format validation
      if(!String.isBlank(website)){
        DataUtility.ValidationResult websiteValidation = DataUtility.validateWebsite(website);
        // If website invalid, return false and error message to custom button
        if(!websiteValidation.valid) {
          response.success = false;
          response.errorMessage = System.Label.Website_Validation_Error;
          return JSON.serialize(response);
        }
      }

      return JSON.serialize(response);
    }

    // CSP-2697 Run Assignment Rules on Accounts
    // Used for reassign the account owner based on assignment rules in account view page
    WebService static String reassignAccountOwner(String accId){

      ButtonServiceResponse response = new ButtonServiceResponse();
      response.success = false;

      if (String.isBlank(accId)) {
          response.errorMessage = 'Invalid Account ID Provided';
          return JSON.serialize(response);
      }

      // Query account info based on account Id
      String accQuery = ACCOUNT_QUERY.replace('{WHERECLAUSE}', ' Id = :accId');
      Account currentAcc;
      
      try {

        currentAcc = Database.query(accQuery);
        AssignmentRulesUtility.buildAssignmentMap(new List<Account>{currentAcc});
        Local_Sales_Rep_Assignment__c lsr = AssignmentRulesUtility.getRecordAssignment(currentAcc);

        if(lsr != NULL && lsr.Sales_Rep__c!= NULL && lsr.Sales_Rep__c != currentAcc.CreatedById){
          currentAcc.OwnerId = lsr.Sales_Rep__c;
        }

        update currentAcc;
        response.success = true;
      }
      catch(Exception e) {

        response.errorMessage = e.getMessage();
        return (JSON.serialize(response));
      }

      return JSON.serialize(response);
    }

    
    /**
     * CSP-2748 Link Cancel Case to Cancel Opportunity
     * @Author Ivan
     * @Date   2018-03-22
     * @param  ownerId      cancel case owner id
     * @param  caseNumber   case number
     * @param  accId        account id
     * @param  caseId       cancel case id
     * @return            The JSON representation of the "ButtonServiceReponse" object.
     */
    WebService static String generateCancelOpp(String ownerId,String caseNumber,String accId,String caseId){


      List<RecordType> recordTypeOfLocalList = [SELECT Id,Name FROM RecordType WHERE SobjectType='Opportunity' and RecordType.Name = 'Local' LIMIT 1];

      ButtonServiceResponse response = new ButtonServiceResponse();
      response.success = false;
      Opportunity newOpp = new Opportunity();
      
      if(!recordTypeOfLocalList.isEmpty()){
        newOpp.RecordTypeId = recordTypeOfLocalList[0].id;
      }
      newOpp.OwnerId = ownerId;
      newOpp.Name =  'Cancel Case ' +caseNumber +' Cancel Request';
      newOpp.Contract_Signer__c = Label.Contact_Signer_for_Cancel_Opp;
      newOpp.AccountId = accId;
      newOpp.CloseDate = Date.today().addDays(7);
      newOpp.Opportunity_Expiration_Date__c=Date.today().addDays(7);
      newOpp.StageName= 'Prospecting';
      newOpp.Type = 'Cancel';
      newOpp.Cancel_Case__c = caseId;

      try {
          insert newOpp;
          response.success = true;

      }
      catch (Exception ex) {
        response.errorMessage = ex.getMessage();
        return (JSON.serialize(response));
      }

      return JSON.serialize(response);
     
    }


  /**
   *   The response object for sending messages back to a javascript button.
   */
  global class ButtonServiceResponse {
    Boolean success;
    String errorMessage;
    String agreementTemplateId;
    global ButtonServiceResponse() {
    }

    global ButtonServiceResponse(Boolean paramSuccess, String paramError, String paramAgreementTemplateId) {
      success = paramSuccess;
      errorMessage = paramError;
      agreementTemplateId = paramAgreementTemplateId;
    }
  }
}