/**
 *   CSP-1281
 *   
 *   The purpose of this batch is to: 
 *   1) Send email notifications to associated sales rep if the client has not signed the echo sign agreement 48 hours prior 
 *      to the 10 day date payment method expiration date
 *   2) Create a task for associated sales rep if the payment method has expired 
 *
 *   @author Ruchit Sontakke
 *   @date   01/11/2017
 */
global class BatchPaymentMethodNotifications implements Database.Batchable<sObject>{
   
    private static final OrgWideEmailAddress orgWideEmailAdd; 
    static {
      try {
        orgWideEmailAdd = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address = 'theknotaccounting@xogrp.com' LIMIT 1];
      } catch (Exception e) {
        XO_Exception__c xoException = ExceptionUtility.consumeException(e, true);
      }
    } 

    global BatchPaymentMethodNotifications(){
    }
  
    global Database.QueryLocator start(Database.BatchableContext BC){
      
      //String query = 'Select zqu__ElectronicPaymentMethodId__c, zqu__Opportunity__r.Name, zqu__Opportunity__c, zqu__Account__r.Name, OwnerId, Payment_Method_Expiration_Date__c ' +
      //             + 'From zqu__Quote__c ' +
      //             + 'Where zqu__Opportunity__r.RecordType.Name LIKE \'%Local%\' '+
      //             + 'AND zqu__Status__c = \'New\' AND zqu__ZuoraAccountID__c = null AND zqu__ZuoraPaymentID__c = null AND (Payment_Method_Expiration_Date__c = NEXT_N_DAYS:2 OR Payment_Method_Expiration_Date__c < Today) AND (zqu__PaymentMethod__c = \'ACH\' OR zqu__PaymentMethod__c = \'Credit Card\')';
      //             
                 String query = 'Select zqu__ElectronicPaymentMethodId__c, zqu__Opportunity__r.Name, zqu__Opportunity__c, zqu__Account__r.Name, OwnerId, Payment_Method_Expiration_Date__c ' +
                   + 'From zqu__Quote__c ' +
                   + 'Where zqu__Opportunity__r.RecordType.Name LIKE \'%Local%\' '+
                   + 'AND zqu__Status__c = \'New\' AND zqu__ZuoraPaymentID__c = null AND (Payment_Method_Expiration_Date__c = NEXT_N_DAYS:2 OR Payment_Method_Expiration_Date__c < Today) AND (zqu__PaymentMethod__c = \'ACH\' OR zqu__PaymentMethod__c = \'Credit Card\')';
      
      return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<zqu__Quote__c> scope){

      List<Messaging.SingleEmailMessage> emailList= new List<Messaging.SingleEmailMessage>();
      List<Task> taskList = new List<Task>();

      for (zqu__Quote__c quote : scope){
        
        // 48 hours prior to the 10 day date, if the client has not signed the echo sign, send a email notification to sales rep
        // informing them that the payment method is about to expire
        system.debug('1111111 ' + quote);
        if(quote.Payment_Method_Expiration_Date__c == System.today().addDays(2)) { // check if the expiration is in 2 days
          system.debug('222222222 ' + quote.Payment_Method_Expiration_Date__c);
          // send email notification to associated sales rep
          Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

          String subtitle = Label.Echo_Sign_Notification_Subtitle;
          String title = Label.Echo_Sign_Two_Day_Title;
          String bodyText = 'The new billing information entered for ' +  quote.zqu__Account__r.Name + ' will expire in 2 days if the contract is not accepted by the customer. Please update ' + 
                            + 'the new billing information for the following Opportunity\'s quotes:' + '<br/><br/><a href = '  + System.URL.getSalesforceBaseURL().toExternalForm() + '/' + quote.zqu__Opportunity__c + '>' + quote.zqu__Opportunity__r.Name + '</a>'; 

          email.setSubject(Label.Echo_Sign_Two_Day_Subject);
          email.setHTMLBody(EmailUtility.createEmailBody(subtitle, title, bodyText));
          email.setTargetObjectId(quote.OwnerId);
          email.setOrgWideEmailAddressId(orgWideEmailAdd.Id);
          email.saveAsActivity = false;

          emailList.add(email);
        }

        // check if the payment method has expired 
        if(quote.Payment_Method_Expiration_Date__c < System.today()) {
     
          // cretae a task and send it to the associates sales rep stating that the payment method for that account has expired and 
          // needs to be re-entered 
          Task tsk = new Task();
          tsk.ActivityDate = Date.Today();
          tsk.WhatId = quote.Id;
          tsk.Type = 'Other';
          tsk.Purpose__c = 'Other';
          tsk.Status = 'Not Started';
          tsk.Subject = 'Payment method for ' + quote.zqu__Account__r.Name + ' has expired and needs to be re-entered';
          tsk.Description = 'Payment method for ' + quote.zqu__Account__r.Name + ' has expired and needs to be re-entered';
          tsk.OwnerId = quote.OwnerId;

          taskList.add(tsk);
        }
      }

      List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();
    
      //send email
      if(!emailList.isEmpty()) {
        List<Messaging.SendEmailResult> results = Messaging.sendEmail(emailList, false);
        xoExceptionList.addAll(ExceptionUtility.consumeException(results));
      }
 
      if(!taskList.isEmpty()) {
        Database.SaveResult[] srList = Database.Insert(taskList, false);
        xoExceptionList.addAll(ExceptionUtility.consumeException(srList));
      }

      if(xoExceptionList.size() >0){
        insert xoExceptionList;
      }
    }

    global void finish(Database.BatchableContext BC){
    }
}