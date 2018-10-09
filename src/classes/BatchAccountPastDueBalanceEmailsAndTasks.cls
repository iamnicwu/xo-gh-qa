global class BatchAccountPastDueBalanceEmailsAndTasks implements Database.Batchable<sObject>, Database.Stateful {
    ////////////////////////////
    // STATIC FINAL VARIABLES //
    ////////////////////////////
    public static final OrgWideEmailAddress THE_KNOT_ACC_ORG_WIDE_ADDR;
    private static final Map<Date, Invoice_Past_Due_Config__c> PAST_DUE_DATE_MAP;
    private static final Map<String, EmailTemplate> EMAIL_TEMPLATE_MAP;

    ////////////////////////////
    // PUBLIC CLASS VARIABLES //
    ////////////////////////////
    public String query; 
    public List<String> emailAttachmentAuthFormIdList;
    
    /////////////////////////////
    // PRIVATE CLASS VARIABLES //
    /////////////////////////////
    private Set<Id> missingContactSet;

    // CSP-2646 Update Past Due Notices to Paid Accounts
    // retrieve the active subscription under the paid account for send the 70 days email to sales rep on the subscription.
    // only send email to paid account for the past due balance
    private static final String queryStr = ' SELECT '
                                            +   'Id, '
                                            +   'Name, '
                                            +   'Longest_Past_Due_Date__c, '
                                            +   'Payment_Type__c, '
                                            +   'Customer_on_Payment_Arrangement__c, '
                                            +   'Past_Due_Balance__c, '
                                            +   'CBBS__c, '
                                            +   'CBBS__r.IsActive, '
                                            +   'CBBS__r.Name, '
                                            +   'CBBS__r.Email, '
                                            +   'CBBS__r.Phone, '
                                            +   'Owner.IsActive, '
                                            +   'OwnerId, '
                                            +   'Owner.ARR__c, '
                                            +   'Owner.Email, '
                                            +   'Owner.Arr__r.IsActive, '
                                            +   'Owner.ARR__r.Name, '
                                            +   'Owner.ARR__r.Email, '
                                            +   'Owner.ARR__r.Phone, '
                                            +   '( '
                                                +   'SELECT '
                                                    +   'Id, '
                                                    +   'Zuora__Account__c, '
                                                    +   'Zuora__BillToName__c, '
                                                    +   'Bill_To_Contact__c, '
                                                    +   'Bill_To_Contact__r.Email, '
                                                    +   'Bill_To_Contact__r.FirstName, '
                                                    +   'Zuora__BillToWorkEmail__c '
                                                +   'FROM '
                                                    +   'Zuora__R00N40000001kyLcEAI__r '
                                            +   '), '
                                            +   '( '
                                                +   'SELECT '
                                                    +   'Id, '
                                                    +   'Sales_Rep__c, '
                                                    +   'Sales_Rep__r.Email, '
                                                    +   'Sales_Rep__r.IsActive '
                                                +   'FROM '
                                                    +   'Zuora__Subscriptions__r '
                                                +   'WHERE '
                                                    +   'Zuora__TermEndDate__c > TODAY'
                                            +   ') '
                                        +   'FROM '
                                            +   'Account '
                                        +   'WHERE '
                                            +   'Past_Due_Balance__c > 10.00 '
                                        +   'AND '
                                            +   'Customer_on_Payment_Arrangement__c = false '
                                        +   'AND '
                                            +   'Local_Paid_Status__c = \'Paid\'' 
                                        +   'AND '
                                            +'{WHERECLAUSE}';
    ////////////////////////
    // STATIC INITIALIZER //
    ////////////////////////
    static {
        List<XO_Exception__c> exceptionList = new List<XO_Exception__c>();

        try {
            THE_KNOT_ACC_ORG_WIDE_ADDR = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address = 'theknotaccounting@xogrp.com' LIMIT 1];
        } catch (Exception e) {
            XO_Exception__c xoException = ExceptionUtility.consumeException(e, false);
            xoException.Severity__c = 'Critical';
            xoException.Failure_Area__c = 'Email Notification';

            exceptionList.add(xoException);
        }

        // RETRIEVE ALL NEEDED EMAL TEMPLATES
        List<EmailTemplate> emailTemplateList = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName IN ('Past_Due_Warning', 'Past_Due_Warning_Cancel')];
        Map<String, EmailTemplate> tempEmailTemplateMap = new Map<String, EmailTemplate>();
        for(Integer i = 0; i < emailTemplateList.size(); i++) {
            EmailTemplate currentTemplate = emailTemplateList[i];
            tempEmailTemplateMap.put(currentTemplate.DeveloperName, currentTemplate);
        }

        EMAIL_TEMPLATE_MAP = tempEmailTemplateMap;

        // CUSTOM SETTING RETRIEVAL AND MAP BUILDING
        Map<String, Invoice_Past_Due_Config__c> pastDueConfigMap = Invoice_Past_Due_Config__c.getAll();
        List<Invoice_Past_Due_Config__c> pastDueList = pastDueConfigMap.values();
        Map<Date, Invoice_Past_Due_Config__c> tempDateMap = new Map<Date, Invoice_Past_Due_Config__c>();
        for(Integer i = 0; i < pastDueList.size(); i++) {
            Invoice_Past_Due_Config__c currentPastDueCustomSetting = pastDueList[i];
            Date previousDate = Date.today().addDays((Integer)currentPastDueCustomSetting.Number_Of_Days_Past_Due__c * -1);
            tempDateMap.put(previousDate, currentPastDueCustomSetting);
        }

        // Set the final value for the map
        PAST_DUE_DATE_MAP = tempDateMap;

        insert exceptionList;
    }
    
    global BatchAccountPastDueBalanceEmailsAndTasks() {
        missingContactSet = new Set<Id>();

        // Transform Map keyset into Date list then send to method which builds query
        query = generateAccountPDBQueryString(new List<Date>(PAST_DUE_DATE_MAP.keySet()));

        // set attachment doc id
        emailAttachmentAuthFormIdList = new List<String>();
        for (Document authDoc : [SELECT Id FROM Document WHERE Name = 'TheKnot CC ACH Authorization Form' LIMIT 1]) {
            emailAttachmentAuthFormIdList.add(String.valueOf(authDoc.Id));
        }
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        Database.QueryLocator retVal = Database.getQueryLocator(query);
        return retVal;
    }

    global void execute(Database.BatchableContext BC, List<Account> scope) {
        // Retrieve fallback user for notifications
        User fallbackUser = getFallbackTaskUser();

        List<Messaging.SingleEmailMessage> emailList= new List<Messaging.SingleEmailMessage>();
        List<Task> taskList = new List<Task>();
        
        for(Account acc: scope) {
            if(!PAST_DUE_DATE_MAP.containsKey(acc.Longest_Past_Due_Date__c)) {
                continue;
            }

            Invoice_Past_Due_Config__c currentPastDueConfig = PAST_DUE_DATE_MAP.get(acc.Longest_Past_Due_Date__c);

            Integer daysLate = (Integer)currentPastDueConfig.Number_Of_Days_Past_Due__c;
            
            // CSP-2431 : Duplicate Past Due Tasks; We only created ONE task for an account
            // If the custom setting "Create ARR Task" value is checked then create a task for the Account ARR
            if (currentPastDueConfig.Create_ARR_Task__c) {
                createTask(acc, daysLate, taskList, fallbackUser);
            }
            
            // csp-2032 :dupEmailsSet was added to prevent multiple emails to be send for multiple billing accounts with the same email
            Set<String> dupEmailsSet = new Set<String>();
            
            for(Zuora__CustomerAccount__c billingAccountRec : acc.R00N40000001kyLcEAI) {
                // CSP-2294 - Skip records who end with .UAT to prevent hitting limits in test environment
                if(String.isNotBlank(billingAccountRec.Bill_To_Contact__r.Email) && 
                    billingAccountRec.Bill_To_Contact__r.Email.endsWith('.uat')) {
                    continue;
                }
                
                // if the contact is null, notify the administrator via email about the missing contact and then move on to the 
                // next record in the loop
                if(String.isBlank(billingAccountRec.Bill_To_Contact__c)) {
                    missingContactSet.add(billingAccountRec.Id);
                    continue;
                }
                
                // If the custom setting has the value "Send Email to Customer" checked then send email
                if(currentPastDueConfig.Send_Email_To_Customer__c && !dupEmailsSet.contains(billingAccountRec.Bill_To_Contact__r.Email)) {
                    createEmail(acc, billingAccountRec.Bill_To_Contact__c, daysLate, emailList);
                    dupEmailsSet.add(billingAccountRec.Bill_To_Contact__r.Email);
                }
                
                // Comment for ticket CSP-2431, the task is created for Account not for every Billing account, so this logig move out from the billing account loop
                // If the custom setting "Create ARR Task" value is checked then create a task for the Account ARR
                // if (currentPastDueConfig.Create_ARR_Task__c) {
                //     createTask(acc, daysLate, taskList, fallbackUser);
                // }
                // If the custom setting "Send Email To Account Owner" value is checked then send an email to the Account Owner
                if(currentPastDueConfig.Send_Email_To_Account_Owner__c && !dupEmailsSet.contains(billingAccountRec.Bill_To_Contact__r.Email)) {
                    emailList.add(createAccountOwnerEmail(acc));
                    dupEmailsSet.add(billingAccountRec.Bill_To_Contact__r.Email);
                }
            }
        }
        
        List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();
        
        //send email to the customer
        if(!emailList.isEmpty()) {
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(emailList, false);
            // CSP-2905 Notification for Failed Emails
            xoExceptionList.addAll(ExceptionUtility.consumeException(results, Label.Past_Due_Email_Exception));
        }

        //Try inserting all the task in the taskList.. Ignore those records which cannot be inserted due to certain error
        if(!taskList.isEmpty()) {
            Database.SaveResult[] srList = Database.Insert(taskList, false);
            xoExceptionList.addAll(ExceptionUtility.consumeException(srList));
        }

        if(xoExceptionList.size() >0){
            insert xoExceptionList;
        }
    }
    
    /**
     *   [createTask: This method is used to create a task by using date from the account]
     *   @author [Ruchit S]
     *   @date   2017-08-13
     *   @param  {[type]}   acc              [current account]
     *   @param  {[type]}   contactId        [contact id]
     *   @param  {[type]}   daysLate         [number of days the customer is late from making the payments]
     *   @param  {[type]}   emailsToSendList [list of emails to be send]
     */
    private void createEmail(Account acc, Id contactId, Integer daysLate, List<Messaging.SingleEmailMessage> emailsToSendList) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setTargetObjectId(contactId);
        if(daysLate < 60) {
            EmailTemplate pastDueTemplate = EMAIL_TEMPLATE_MAP.get('Past_Due_Warning');
            email.setTemplateId(pastDueTemplate.Id);
        } else {
            EmailTemplate pastDueTemplate = EMAIL_TEMPLATE_MAP.get('Past_Due_Warning_Cancel');
            email.setTemplateId(pastDueTemplate.Id);
        }                       
        email.setWhatId(acc.Id);
        // CSP-2416 : customer to be able to reply to past due notifications and have the CBSS receive it.
        if(String.isNotBlank(acc.CBBS__c) && String.isNotBlank(acc.CBBS__r.Email)){
            email.setReplyTo(acc.CBBS__r.Email);
        }
        email.setSaveAsActivity(true); // save email as activity on the targetObjId (i.e. Contact)
        if (daysLate >= 45) {
            List<String> ccEmailAddresses = new List<String>();
            ccEmailAddresses.add(acc.Owner.Email);
            email.setCcAddresses(ccEmailAddresses);
        }
        email.setOrgWideEmailAddressId(THE_KNOT_ACC_ORG_WIDE_ADDR.Id);
        emailsToSendList.add(email);
    }

    public static Messaging.SingleEmailMessage createAccountOwnerEmail(Account acc) {
        Messaging.SingleEmailMessage accountOwnerEmail = new Messaging.SingleEmailMessage();
                
        String title = Label.UPCOMING_CANCELLATION;
        String body = Label.PAST_DUE_85_DAYS + '\n'
        + '<br/><br/> Account Name: ' + acc.Name + '\n'
        + '<br/> Past Due Amount: ' + acc.Past_Due_Balance__c;

        accountOwnerEmail.setHtmlBody(EmailUtility.createEmailBody(title, body));
        accountOwnerEmail.setSubject(title);

        // CSP-2646 Update Past Due Notices to Paid Accounts
        // send 70 days email to the sales rep of active subscripiton under the account
        List<String> toAddressesList = new List<String>();
        Set<String> salesEmailDupeSet = new Set<String>();
        if (!acc.Zuora__Subscriptions__r.isEmpty()) {
            for (Zuora__Subscription__c cuurentSub :  acc.Zuora__Subscriptions__r) {
                if (!salesEmailDupeSet.contains(cuurentSub.Sales_Rep__r.Email)) {
                    toAddressesList.add(cuurentSub.Sales_Rep__r.Email);
                    salesEmailDupeSet.add(cuurentSub.Sales_Rep__r.Email);
                }
            }
        }
        else{
            toAddressesList.add(acc.Owner.Email);
        }

        accountOwnerEmail.setToAddresses(toAddressesList);

        // CSP-2416 : customer to be able to reply to past due notifications and have the CBSS receive it.
        if(String.isNotBlank(acc.CBBS__c) && String.isNotBlank(acc.CBBS__r.Email)){
            accountOwnerEmail.setReplyTo(acc.CBBS__r.Email);
        }
        accountOwnerEmail.setWhatId(acc.Id);
        accountOwnerEmail.setSaveAsActivity(true);
        accountOwnerEmail.setOrgWideEmailAddressId(THE_KNOT_ACC_ORG_WIDE_ADDR.Id);

        return accountOwnerEmail;
    }
    
    /**
     *   [createTask: This method is used to create a task by using data from the current account]
     *
     *   @author [Ruchit S]
     *   @date   2017-08-13
     */
    private void createTask(Account acc, Integer daysLate, List<Task> tasksToBeInsertedList, User fallbackUser){
        Task tsk = new Task();
        tsk.ActivityDate = Date.Today();
        tsk.WhatId = acc.Id;
        tsk.Type = 'Other';
        tsk.Purpose__c = 'Other';
        tsk.Status = 'Not Started';
        tsk.Subject = 'Account : '+ acc.Name + ' is ' + String.valueOf(daysLate) + ' days past Due date';
        tsk.Description = 'Account : '+ acc.Name + ' is ' + String.valueOf(daysLate) + ' days past Due date';

        // Determine what User should be assigned as the owner of the newly created task. Only Active Users can
        // have a task assigned to them. The next assignment order will be used if a User is found to not be
        // active. System Administrator is the final assignment option.
        // Order of assignment:
        //  1. Account CBSS
        //  2. Account Owner ARR
        //  3. Account Owner
        //  4. "Brandi Rojas" (CSP-1540)
        //  5. "System Administrator"
        if(String.isNotBlank(acc.CBBS__c) && acc.CBBS__r.IsActive) {
            tsk.OwnerId = acc.CBBS__c;
        } else if(String.isNotBlank(acc.Owner.ARR__c) && acc.Owner.ARR__r.IsActive) {
            tsk.OwnerId = acc.Owner.Arr__c;
        } else if(acc.Owner.IsActive) {
            tsk.OwnerId = acc.OwnerId;
        } else {
            tsk.OwnerId = fallbackUser.Id;
            // Adding additional message on Description field to dictate why this Task was assigned to them.
            tsk.Description += '\r\n'
                            +   'This task is being assigned you as all other available Users for assignment '
                            +   'on this Account were inactive or invalid.';
        }

        tasksToBeInsertedList.add(tsk);
    }

    //////////////////
    // FINISH BLOCK //
    //////////////////
    global void finish(Database.BatchableContext BC) {
        // If the contact set has values generate an email with an attachment to send to Sales Support
        if(!missingContactSet.isEmpty()) {
            BatchCCDeclinedReminder.notifyAdminAboutMissingContact(new List<Id>(missingContactSet));
            //notifyAdminAboutMissingContact(new List<Id>(missingContactSet));
        }

        // run the BatchCCDeclinedReminder job
        // CSP-2032
        // Set batch size from default(200) to 50. The sendEmail method is inserting a task in a FOR loop for every successful email
        // that is sent. This is causing the Task trigger to fire for every email that is sent. 
        Database.executebatch(new BatchCCDeclinedReminder(), 50);
    }
    
    private String generateAccountPDBQueryString(List<Date> dateList) {
        // futureDate is used as a default value for the query, this is used so in the event that the custom
        // setting doesn't contain any values, the query will still be valid but won't return any results 
        Date futureDate = Date.today().addDays(100);
        String baseQuery = queryStr;

        String whereClauseStr = '(Longest_Past_Due_Date__c = ' + String.valueOf(futureDate);
        for (Date overdueDate : dateList) {
            whereClauseStr += (' OR Longest_Past_Due_Date__c = ' + String.valueOf(overdueDate));
        }
        whereClauseStr += ')';

        baseQuery = baseQuery.replace('{WHERECLAUSE}', whereClauseStr);

        return baseQuery;
    }

    /**
     *   Method used to retrieve a fallback user which will be used if no other user is available. The current fallback
     *   User is "Brandi Rojas" as per CSP-1540 but also there is another fallback to a System Administrator in case
     *   the "Brandi Rojas" user goes inactive.
     *
     *   @author Justin
     *   @date   2016-11-04
     *   @return {User}     The fallback user which was found.
     */
    private static User getFallbackTaskUser() {
        for(User fallbackUser : [SELECT Id, Name FROM User WHERE Username = 'brojas@xogrp.com' AND IsActive = true LIMIT 1]) {
            return fallbackUser;
        }

        for(User fallbackUser : [SELECT Id, Name FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1]) {
            return fallbackUser;
        }

        return null;
    }
}