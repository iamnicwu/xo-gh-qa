/* 
<class>
  <name>BatchMoveCustomerToCreditHold</name>
  <purpose>The purpose of this batch class is to,
            1. Identify all those Invoices which has past due balance
            2. Move Account/customer associated with the invoice to credit Hold Status, if, the past due balance of any of the invoice is greater than Zero
            3. Revoke customer from Credit Hold Status if all the past due balance has been paid in Full
            4. Create promise to pay reminder for the ARR 
            5. Send out Invoice Past Due notification to the customers and track down the email sent in the acitivity history
  </purpose>
  <created>
    <by>Hari Mohan</by>
    <date>10/2/2015</date>
    <ticket>SF-1095, SF-1172, SF-1174, SF-1175, SF-1176, SF-1177, SF-1187, CSP-757</ticket>
  </created>
</class>
*/
global class BatchMoveCustomerToCreditHold implements Database.Batchable<sObject> {
    global BatchMoveCustomerToCreditHold() {
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Date dateToday = Date.today();
        //Date prevDay = Date.today().addDays(-15);
        String accountWithInvoiceQuery = 'SELECT '
                                        +   'Id '
                                    +   ' FROM '
                                        +   ' Account '
                                    +   ' WHERE '
                                        +   'RecordType.Name = \'Local\''
                                    +   ' AND '
                                        +   'Id IN (SELECT Zuora__Account__c FROM Zuora__ZInvoice__c WHERE Zuora__DueDate__c < :dateToday)';


        return Database.getQueryLocator(accountWithInvoiceQuery);
    }

    global void execute(Database.BatchableContext BC, List<Account> scope) {
        //A decimal field which holds the sum of due balances of all the invoices associated with an account
        Decimal dueBalance = 0;
        Boolean pastDueInvoice;
        Date longestPastDueDate;
        List<Account> accUpdList = new List<Account>();
        Map<id,Zuora__CustomerAccount__c> ZCAMap = new Map<id,Zuora__CustomerAccount__c>();
        String paymentType;
        
        Date dateToday = Date.today();
        String accountChildQuery = 'SELECT '
                                        +   'Id, '
                                        +   'Longest_Past_Due_Date__c, '
                                        +   'Past_Due_Invoice__c, '
                                        +   'Past_Due_Balance__c, '
                                        +   'Local_Paid_Status__c, '
                                        +   'Local_Active__c, '
                                        +   'Active_Status_Change_Date__c, '
                                        +   'Need_to_Create_CB_Case__c, '
                                        +   'Inactive_Reason__c, '
                                        +   'ProductType__c, '
                                        +   '(SELECT '
                                            +   'Id, '
                                            +   'Name, '
                                            +   'Zuora__Account__c, '
                                            +   'Zuora__Account__r.Owner.ARR__c, '
                                            +   'Zuora__Account__r.OwnerId, '
                                            +   'Promise_to_Pay_Date__c, '
                                            +   'Zuora__Balance2__c, '
                                            +   'Zuora__DueDate__c, '
                                            +   'Zuora__BillingAccount__c, '
                                            +   'Zuora__BillingAccount__r.Amount_Past_Due__c, '
                                            +   'Zuora__BillingAccount__r.Zuora__DefaultPaymentMethod__c '
                                        +   ' FROM '
                                            +   ' Zuora__Invoices__r '
                                        +   ' WHERE ' 
                                            +   ' Zuora__DueDate__c < :dateToday) '
                                    +   ' FROM '
                                        +   ' Account '
                                    +   ' WHERE '
                                        +   ' Id IN :scope';

        List<Account> accountsWithChildInvoices = Database.query(accountChildQuery);

        for(Integer i = 0; i < accountsWithChildInvoices.size(); i++) {
            Account acc = accountsWithChildInvoices[i];
            dueBalance = 0;
            longestPastDueDate = null;
            pastDueInvoice = False;
            paymentType = null;
            
            for(Integer j = 0; j < acc.Zuora__Invoices__r.size(); j++) {
                Zuora__ZInvoice__c zInv = acc.Zuora__Invoices__r[j];
                if(zInv.Zuora__Balance2__c > 0 && zInv.Zuora__DueDate__c < Date.Today()){
                    if(longestPastDueDate == null){
                        longestPastDueDate = zInv.Zuora__DueDate__c;
                        // csp-1326: Setting the payment type to check if its a check customer. This flag is used in BatchAccountPastDueBalanceEmailsAndTask
                        // to check if its a check customer and if they are 15 days past due. If they are we send out an email to the customer
                        // and create a task for the ARR
                        paymentType = zInv.Zuora__BillingAccount__r.Zuora__DefaultPaymentMethod__c; 
                    }else{
                        paymentType = longestPastDueDate > zInv.Zuora__DueDate__c ? zInv.Zuora__BillingAccount__r.Zuora__DefaultPaymentMethod__c : paymentType;
                        longestPastDueDate = longestPastDueDate > zInv.Zuora__DueDate__c ? zInv.Zuora__DueDate__c : longestPastDueDate;
                    }

                    dueBalance = dueBalance+zInv.Zuora__Balance2__c;
                    pastDueInvoice = True;
                    //zInv.Zuora__BillingAccount__r.Amount_Past_Due__c = zInv.Zuora__BillingAccount__r.Amount_Past_Due__c + zInv.Zuora__Balance2__c;
                    
                    if(!ZCAMap.containsKey(zInv.Zuora__BillingAccount__c)){
                        ZCAMap.put(zInv.Zuora__BillingAccount__c, new Zuora__CustomerAccount__c(id = zInv.Zuora__BillingAccount__c,Amount_Past_Due__c = zInv.Zuora__Balance2__c));
                    }else{
                        ZCAMap.get(zInv.Zuora__BillingAccount__c).Amount_Past_Due__c = ZCAMap.get(zInv.Zuora__BillingAccount__c).Amount_Past_Due__c + zInv.Zuora__Balance2__c;
                    }
                }
            }

            // this set is used to determine whether the account needs to also be update in Partners
            if(acc.Longest_Past_Due_Date__c != longestPastDueDate || acc.Past_Due_Invoice__c != pastDueInvoice || acc.Past_Due_Balance__c != dueBalance){
                acc.Longest_Past_Due_Date__c = longestPastDueDate;
                acc.Past_Due_Invoice__c = pastDueInvoice;
                acc.Past_Due_Balance__c = dueBalance;
            }
            if(paymentType != null) {
                acc.Payment_Type__c = paymentType;
            }

            // CSP-2782 Client Billing Case Open Logic
            // The new field Need_to_Create_CB_Case__c used for creating case
            // if the account's past due balance is greater 0 and the Payment_Type__c is ACH or CreditCard, 
            // and Longest_Past_Due_Date__c is 8 days past,  we should created a new client billing case
            if (acc.Past_Due_Balance__c > 0 
                && (acc.Payment_Type__c == 'ACH' || acc.Payment_Type__c == 'CreditCard')
                // && acc.Longest_Past_Due_Date__c <= Date.today().addDays(-8) 
                && acc.Need_to_Create_CB_Case__c == false) {

                 acc.Need_to_Create_CB_Case__c = true;
             } else if(acc.Past_Due_Balance__c > 0 
                && acc.Payment_Type__c == 'Check' 
                && acc.Longest_Past_Due_Date__c < Date.today().addDays(-15) 
                && acc.Need_to_Create_CB_Case__c == false){

                acc.Need_to_Create_CB_Case__c = true;
             }else if ((acc.Past_Due_Balance__c == 0 || acc.Past_Due_Balance__c == NULL) && acc.Need_to_Create_CB_Case__c == True) {
                 acc.Need_to_Create_CB_Case__c = false;
             }


            accUpdList.add(acc);
        }
        
        List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();
                       
        //Try updating all the Accounts in the accUpdList.. Ignore those records which cannot be updated due to certain error..
        if(!accUpdList.isEmpty()){
            Database.SaveResult[] dbSaveResult = Database.Update(accUpdList, false);
            xoExceptionList.addAll(ExceptionUtility.consumeException(dbSaveResult));
        }
        
        //Try updating all the Billing Account in the ZCAMap.. Ignore those records which cannot be updated due to certain error..
        if(!ZCAMap.isEmpty()){
            Map<id,Zuora__CustomerAccount__c> ZCAMAPOld  = new Map<id,Zuora__CustomerAccount__c>([select id,Amount_Past_Due__c from Zuora__CustomerAccount__c where id in : ZCAMap.keyset()]);
            for(id idstring : ZCAMap.keyset()){
                if(ZCAMAPOld.get(idstring).Amount_Past_Due__c == ZCAMap.get(idstring).Amount_Past_Due__c){
                    ZCAMap.remove(idstring);
                }
            }
            Database.SaveResult[] dbSaveResult = Database.Update(ZCAMap.values(), false);
            
            xoExceptionList.addAll(ExceptionUtility.consumeException(dbSaveResult));
        }
        
        if(xoExceptionList.size() > 0){
            insert xoExceptionList;
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        // the BatchLocalAccountActiveStatus needs to be run in a low batch size due to a subquery in the execute method
        Database.ExecuteBatch(new BatchLocalAccountActiveStatus(), 500);
    }
    
}