global class DefaultValues extends zqu.CreateQuoteController.PopulateDefaultFieldValuePlugin { 
    global override void populateDefaultFieldValue(SObject record, zqu.PropertyComponentController.ParentController pcc) {   
        if (!Test.isRunningTest()) {
            super.populateDefaultFieldValue(record, pcc); 
        } 
    
        String quoteId = apexpages.currentpage().getparameters().get('id');
    
        if(quoteId == NULL) {
            //Populate default values in the quote header 
            record.put('zqu__InitialTerm__c', 12);   
            record.put('zqu__RenewalTerm__c', 12);
            record.put('zqu__ValidUntil__c', Date.today()+10); 
            record.put('zqu__TermStartDate__c', Date.today()+14);   
            record.put('SalesRepLookup__c', UserInfo.getUserId());
            record.put('Reporting_Rep__c', UserInfo.getUserId());
            // CSP-1786 - ALWAYS set the Zuora AutoRenew flag to FiscalYearSettings
            record.put('zqu__AutoRenew__c', false); 
            record.put('zqu__GenerateInvoice__c', true); 
            record.put('zqu__ProcessPayment__c', true); 
            record.put('zqu__RenewalSetting__c', 'RENEW_WITH_SPECIFIC_TERM');
            record.put('zqu__Subscription_Term_Type__c', 'Termed');
            record.put('zqu__Currency__c', 'USD');
            record.put('zqu__Calculate_Quote_Metrics_Through__c', 'End Of Term');

            // Retrieve the account ID from the quote        
            Id OppId = (Id) record.get('zqu__Opportunity__c');
            Id accountId = (Id) record.get('zqu__Account__c');

            String subId = apexpages.currentpage().getparameters().get('subscriptionId');
        
            // CSP-2735 Zuora Amendments and Cancels fail
            // replace Zuora Id (Deprecated) Zuora__Zuora_Id__c to Zuora__External_Id__c, cause Zuora__Zuora_Id__c is deprecated and non index field
            List<Zuora__Subscription__c> subscriptionList = [Select Id, Zuora__InitialTerm__c, Name, Payment_Method__c, Preferred_Payment_Schedule__c from Zuora__Subscription__c where Zuora__External_Id__c =: subId];
        
            // Find the contacts associated with the account  
            // CSP-2250 Inactive Contacts should not be available for QTC     
            List<Contact> contacts = [SELECT Id, Name FROM Contact WHERE Id IN (SELECT ContactId FROM AccountContactRole WHERE AccountId = :accountId AND Role = 'Primary') AND Status__c = 'Active' LIMIT 1 ];  
            List<Zuora__CustomerAccount__c> BillingAccounts = [SELECT Id, Name FROM Zuora__CustomerAccount__c WHERE Zuora__Account__r.Id = :accountId];
        
            List<Opportunity> opportunities = [SELECT Id, Name FROM Opportunity where Id =: OppId];

            String billingAccountId = apexpages.currentpage().getparameters().get('billingAccountId');
            List<Zuora__CustomerAccount__c> ExistingBillingAccounts = [SELECT Id, Name, Zuora__DefaultPaymentMethod__c, Zuora__PaymentTerm__c FROM Zuora__CustomerAccount__c WHERE Zuora__Zuora_Id__c =: billingAccountId];
          

            If (opportunities.size() > 0) {
                // Code to Copy the Values on to the Amendment/Renewal quote from the Original/New Subscription
                If (record.get('zqu__SubscriptionType__c') == 'New Subscription') {
                    record.put('Preferred_Payment_Schedule__c','Month');
                    record.put('zqu__PaymentMethod__c', 'Credit Card');                 
                }

                If (record.get('zqu__SubscriptionType__c') == 'Amend Subscription') {
                    record.put('zqu__Amendment_Name__c', 'Amend '+opportunities[0].Name);

                    // CSP-1821 Remove Generate Invoice Option for Amendments
                    // only for amendment
                    record.put('zqu__GenerateInvoice__c', false);
                    record.put('zqu__ProcessPayment__c', false); 
                }

                If (record.get('zqu__SubscriptionType__c') == 'Renew Subscription') {
                    record.put('zqu__Amendment_Name__c', 'Renew ' + opportunities[0].Name);
                }
            }

            // Assuming the contacts are present set the billTo and soldTo to the first contact        

            if (contacts.size() > 0) {  
                if (BillingAccounts.size() ==0) {  
                    record.put('zqu__BillToContact__c', contacts[0].Id);            
                    record.put('zqu__SoldToContact__c', contacts[0].Id);            

                    if (!Test.isRunningTest()) {
                        // Beforeretrieving  the lookup  options, needs to populate the map first            
                        super.setLookupOptions(pcc);   
                    }         

                    if (!Test.isRunningTest()) {
                        // Now retrieve the lookup component options            
                        zqu.LookupComponentOptions billToOptions = super.getLookupOption('zqu__BillToContact__c');            
                        billToOptions.targetId = contacts[0].Id;            
                        billToOptions.targetName = contacts[0].Name;            
                        zqu.LookupComponentOptions soldToOptions  = super.getLookupOption('zqu__SoldToContact__c');            
                        soldToOptions.targetId = contacts[0].Id;            
                        soldToOptions.targetName = contacts[0].Name;
                    }
                }
            }
    
            if (subscriptionList.size() > 0) {
                record.put('zqu__PaymentMethod__c', subscriptionList[0].Payment_Method__c); 
                record.put('Preferred_Payment_Schedule__c', subscriptionList[0].Preferred_Payment_Schedule__c);
                // CSP-2974: Amending Subs Less than 12 Months
                // the initial term on the amendment is the same value as the original sub on the quote sent for signature as well as once it integrates with z-billing. 
                if(String.isNotBlank(subscriptionList[0].Zuora__InitialTerm__c)){
                    String monthNum = subscriptionList[0].Zuora__InitialTerm__c.subString(0,2).trim();
                    if(monthNum.isNumeric() && Integer.valueOf(monthNum) < 12){
                        record.put('zqu__InitialTerm__c', Integer.valueOf(monthNum)); 
                    }
                }
            }

            If (BillingAccounts.size() > 0) { 
                If (record.get('zqu__SubscriptionType__c') == 'New Subscription') {
                    If (ExistingBillingAccounts.size()>0) {
                        If (ExistingBillingAccounts[0].Zuora__DefaultPaymentMethod__c == 'CreditCard') {
                            record.put('zqu__PaymentMethod__c', 'Credit Card');
                        }
                        else {
                            record.put('zqu__PaymentMethod__c', ExistingBillingAccounts[0].Zuora__DefaultPaymentMethod__c);
                        }
                    }
                }
            } 
        }
    }
}