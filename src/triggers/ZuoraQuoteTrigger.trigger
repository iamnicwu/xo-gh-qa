/* 
<trigger>
  <name>ZuoraQuoteTrigger</name>
  <purpose>For handling save/update events on Zuora Quote records</purpose>
  <created>
    <by>Jonathan Satterfield</by>
    <date>7/22/2015</date>
    <ticket>SF-598, SF-599, SF-601</ticket>
  </created>
  <Update>
     <date>4/27/2015</date>
    <ticket>CSP-724</ticket>
  </Update>
</trigger> 
*/
trigger ZuoraQuoteTrigger on zqu__Quote__c (before insert, before update, after insert, after update, before delete, after delete) {
    /*if (Trigger.isAfter) {
        
        if (Trigger.isInsert || Trigger.isUpdate) {

            if (Trigger.isInsert) {
                ZuoraQuoteTriggerHandler.UpdateOpportunityforRenewal(Trigger.new);
            }

            if (Trigger.isUpdate) {
                ZuoraQuoteTriggerHandler.UpdateInventoryExpirationDates(Trigger.new, Trigger.oldMap);
                ZuoraQuoteTriggerHandler.UpdateOpportunityElectronicPaymentId(Trigger.new, trigger.oldMap);
                ZuoraQuoteTriggerHandler.RunProductRulesOnQuoteDetailsUpdate(Trigger.new, trigger.oldMap);
                ZuoraQuoteTriggerHandler.sendAutoRenewalNotification(Trigger.new, trigger.oldMap);
            }
        }
        
        if (Trigger.isDelete) {
            ZuoraQuoteTriggerHandler.SetApprovalProcessFlagDiscountAmountOnOpportunity(Trigger.old);
            ZuoraQuoteTriggerHandler.UpdatePotentialValueOfOpportunity(Trigger.old);
        } 
    }


    if (Trigger.isBefore) {

        if (Trigger.isInsert || Trigger.isUpdate) {
            system.debug('666666666 ');

            // if Trigger is before insert or before update...
            ZuoraQuoteTriggerHandler.PopulateOriginalSalesforceQuoteIDField(Trigger.new);
            ZuoraQuoteTriggerHandler.SetServiceActivationDateToTermStartDate(Trigger.new);
            ZuoraQuoteTriggerHandler.SetTransactionsQuoteDefaultValues(Trigger.new);

            // if Trigger is before insert...
            if (Trigger.isInsert) {
                ZuoraQuoteTriggerHandler.setValidUntilDateToOppExpirationDate(Trigger.new);
                ZuoraQuoteTriggerHandler.validateQuoteTermStartDates(Trigger.new);
                ZuoraQuoteTriggerHandler.PopulateIDsForCommissionTracking(Trigger.new);
                ZuoraQuoteTriggerHandler.RecordAmendmentCancellationRenewalQuoteProductLineAndTCV(Trigger.new);
                ZuoraQuoteTriggerHandler.SetQuoteElectronicPaymentId(Trigger.new);
            }

            // if Trigger is before update...
            if (Trigger.isUpdate) {
                ZuoraQuoteTriggerHandler.setValidUntilDateToOppExpirationDate(Trigger.new, Trigger.oldMap);
                ZuoraQuoteTriggerHandler.UpdateIDsForCommissionTracking(Trigger.new, Trigger.oldMap);
                ZuoraQuoteTriggerHandler.AssignPaymentMethodExpirationDate(Trigger.new, Trigger.oldMap); // csp-1281
            }
            
            //for CSP-999
            //get the SalesRepLookup__c and RenewalRepLookup__c field from user to find 'Junior Sales Reps' and 'Potentially Sales Ops'
            //and put then to a set 'salesRepRenwalRepIdSet'.
            Set<Id> salesRepRenwalRepIdSet= new Set<Id>();
            Set<Id> effectPriceQuoteSet = new Set<Id>();

            // CSP-1598 - Map used to transform Product Line into Quote Template name
            // CSP-1845 - Add Print to use LDE Quote Template
            Map<String, String> productLineToQuoteNameMap 
                = new Map<String, String>{'Direct Mail' => 'LDE Quote Template',
                                          'Print'       => 'LDE Quote Template'};

            Set<String> contactIdSet = new Set<String>();

            // Product Line Set:
            // Used to grab the correct quote templates and associate to the current Quote
            Set<String> quoteTemplateNameSet = new Set<String>();

            //////////////////
            // BULKING LOOP //
            //////////////////
            for(zqu__Quote__c currentQuote : Trigger.new) {
                if(currentQuote.SalesRepLookup__c != null){
                    salesRepRenwalRepIdSet.add(currentQuote.SalesRepLookup__c);
                }

                if(currentQuote.RenewalRepLookup__c != null){
                    salesRepRenwalRepIdSet.add(currentQuote.RenewalRepLookup__c);
                }

                // CSP-1414 - Enforce First Name and Last Name on contacts added to Bill To/Sold To
                if(String.isNotBlank(currentQuote.zqu__SoldToContact__c)) {
                    contactIdSet.add(currentQuote.zqu__SoldToContact__c);
                }

                // CSP-1414 - Enforce First Name and Last Name on contacts added to Bill To/Sold To
                if(String.isNotBlank(currentQuote.zqu__BillToContact__c)) {
                    contactIdSet.add(currentQuote.zqu__BillToContact__c);
                }

                /*
                    CSP-1598 - Getting all quotes being processed which have a non null True TCV value. This set
                    will be used to aggregate all Effective Prices from related Quote Rate Plan Charge Detail child records.
                    NOTE: Not checking to see if True_TCV__c field value is different from the old value because there
                    could be a scenario where modifications were made to the quote but the TCV somehow came out to be
                    exactly the same but the term price changed. Should be VERY rare but still possible?

                    NEW Logic added for LDE:
                    If "Direct Mail" or "Transactions" is the product line selected then DO NOT do a summation - LDE does not use summation
                    in the template so it is just wasting CPU/Processing time.

                    CSP-1845 - NEW Logic added for Print
                    If "Print" is the product line selected then also do not do summation - Print now does not need to use
                    summation in the template.
                 *//*
                if(Trigger.isUpdate && currentQuote.True_TCV__c != null && String.isNotBlank(currentQuote.Product_Line__c) && ('Direct Mail,Transactions,Print').indexOf(currentQuote.Product_Line__c) < 0) {
                    effectPriceQuoteSet.add(currentQuote.Id);
                }

                // CSP-1598 - Code used to set the Quote Template based on the Product Line of the Quote
                if(String.isNotBlank(currentQuote.Product_Line__c) && productLineToQuoteNameMap.containsKey(currentQuote.Product_Line__c)) {
                    quoteTemplateNameSet.add(productLineToQuoteNameMap.get(currentQuote.Product_Line__c));
                }
            }
            
            //for CSP-999
            //salesRepRenwalRepIdMap is record the 'Junior Sales Reps' and 'Potentially Sales Ops' corresponding user Id 
            //and Disallow_Sales_Rep_On_Quotes__c field in user object.
            Map<Id, User> salesRepRenwalRepIdMap=new Map<Id, User>();
            //for CSP-999
            //find the User which field Disallow_Sales_Rep_On_Quotes__c== true
            if(salesRepRenwalRepIdSet.size() > 0) {
                List<User> userList = [SELECT id, Disallow_Sales_Rep_On_Quotes__c FROM User WHERE id in : salesRepRenwalRepIdSet ];
                //for CSP-999
                //put the user id and user into the salesRepRenwalRepIdMap.
                for(User salesRepRenwalRepUser : userList){
                    salesRepRenwalRepIdMap.put(salesRepRenwalRepUser.id, salesRepRenwalRepUser);
                }
            }

            ///////////////////////////////////////////
            // LOGIC FOR RETRIEVING RELATED CONTACTS //
            ///////////////////////////////////////////
            Map<Id, Contact> contactMap = new Map<Id, Contact>();
            if(contactIdSet.size() > 0) {
                contactMap = new Map<Id, Contact>([SELECT Id, FirstName, LastName FROM Contact WHERE Id IN :contactIdSet]);
            }

            ////////////////////////////////////////////////
            // LOGIC FOR GETTING RELEVANT QUOTE TEMPLATES //
            ////////////////////////////////////////////////
            Map<String, zqu__Quote_Template__c> nameToQuoteTemplateMap = new Map<String, zqu__Quote_Template__c>();
            if(quoteTemplateNameSet.size() > 0) {
                List<zqu__Quote_Template__c> quoteTemplateList = [SELECT Id, Name FROM zqu__Quote_Template__c WHERE Name IN :quoteTemplateNameSet];
                for(Integer i = 0, len = quoteTemplateList.size(); i < len; i++) {
                    zqu__Quote_Template__c currentTemplate = quoteTemplateList[i];
                    nameToQuoteTemplateMap.put(currentTemplate.Name, currentTemplate);
                }
            }

            ///////////////////////////////////////
            // LOGIC FOR SUMMING EFFECTIVE PRICE //
            ///////////////////////////////////////
            Map<Id, Double> quoteToSumEffectivePriceMap = new Map<Id, Double>();
            if(effectPriceQuoteSet.size() > 0) {
                List<zqu__QuoteRatePlanCharge__c> quoteRPCList = [SELECT Id, zqu__EffectivePrice__c, zqu__QuoteRatePlan__r.zqu__Quote__c FROM zqu__QuoteRatePlanCharge__c WHERE zqu__QuoteRatePlan__r.zqu__Quote__c IN :effectPriceQuoteSet];
                for(Integer i = 0, len = quoteRPCList.size(); i < len; i++) {
                    zqu__QuoteRatePlanCharge__c quoteRPC = quoteRPCList[i];
                    // If the effective price is null or zero then just skip this quote rate plan charge. No reason to
                    // access the hash map to try and add a null value(error) or add nothing.
                    if(quoteRPC.zqu__EffectivePrice__c == null || quoteRPC.zqu__EffectivePrice__c == 0) {
                        continue;
                    }

                    // If a map value exists for the quote then just add to double value
                    if(quoteToSumEffectivePriceMap.containsKey(quoteRPC.zqu__QuoteRatePlan__r.zqu__Quote__c)) {
                        Double currentSum = quoteToSumEffectivePriceMap.get(quoteRPC.zqu__QuoteRatePlan__r.zqu__Quote__c);
                        quoteToSumEffectivePriceMap.put(quoteRPC.zqu__QuoteRatePlan__r.zqu__Quote__c, currentSum + quoteRPC.zqu__EffectivePrice__c);
                        continue;
                    }

                    // If no map value exists then create a new key and being the double with the current effective price
                    quoteToSumEffectivePriceMap.put(quoteRPC.zqu__QuoteRatePlan__r.zqu__Quote__c, quoteRPC.zqu__EffectivePrice__c);
                }
            }



            // For CSP-2048, use a public group to store the user or role who have the access to check the autorenewal flag of the quote with initial term less than 12
            //  
            Set<id> accessIdSet = new Set<Id>();
            Boolean haveAccessForUser = false;
            for (GroupMember currentGroupMember: [Select id,UserOrGroupId,GroupId from GroupMember where Group.DeveloperName = 'UserCanCheckAutoRenewalQuoteLess12']) {
                accessIdSet.add(currentGroupMember.UserOrGroupId);
            }
            for (Group currentGroup : [Select Id, RelatedId from Group where Id in: accessIdSet]) {
                accessIdSet.add(currentGroup.RelatedId);
            }
            System.debug(LoggingLevel.INFO, '*** accessIdSet: ' + accessIdSet);
            System.debug(LoggingLevel.INFO, '*** userInfo.getUserRoleId(): ' + userInfo.getUserRoleId());
            System.debug(LoggingLevel.INFO, '*** accessIdSet.contains(userInfo.getUserRoleId()): ' + accessIdSet.contains(userInfo.getUserRoleId()));
            if (accessIdSet.contains(userInfo.getUserId())) {
                haveAccessForUser = TRUE;
            }else If(accessIdSet.contains(userInfo.getUserRoleId())){
                haveAccessForUser = TRUE;
            }
            /////////////////////
            // PROCESSING LOOP //
            /////////////////////
            for(zqu__Quote__c quote : Trigger.new) {
                // Copy the payment method into custom field
                if(quote.zqu__PaymentMethod__c != NUll && quote.zqu__PaymentMethod__c != ''){
                    quote.Payment_Method__c = quote.zqu__PaymentMethod__c;
                }

                // CSP-1786 - ALWAYS set Zuora auto renew flag to False. Using a custom flag moving forward.
                quote.zqu__AutoRenew__c = false;

                if(quote.zqu__SubscriptionType__c == 'Amend Subscription') {
                    // CSP-1821 Remove Generate Invoice Option for Amendments
                    // only for amendment
                    quote.zqu__GenerateInvoice__c = false;
                    quote.zqu__ProcessPayment__c = false; 
                }

                //for CSP-999
                if(salesRepRenwalRepIdMap.containsKey(quote.SalesRepLookup__c) && salesRepRenwalRepIdMap.get(quote.SalesRepLookup__c).Disallow_Sales_Rep_On_Quotes__c){
                    quote.addError(system.Label.DisallowSalesRepOnQuotesErrorMessage);
                }

                if(salesRepRenwalRepIdMap.containsKey(quote.RenewalRepLookup__c) && salesRepRenwalRepIdMap.get(quote.RenewalRepLookup__c).Disallow_Sales_Rep_On_Quotes__c){
                    quote.addError(system.Label.DisallowRenewalRepOnQuotesErrorMessage);
                }

                // CSP-1414:
                // Add an error if the Bill To contact does not have a FirstName AND LastName
                if(String.isNotBlank(quote.zqu__BillToContact__c) && contactMap.containsKey(quote.zqu__BillToContact__c)) {
                    Contact currentContact = contactMap.get(quote.zqu__BillToContact__c);
                    if(String.isBlank(currentContact.FirstName)) {
                        quote.zqu__BillToContact__c.addError('Bill To Contact must have a First Name');
                    }

                    if(String.isBlank(currentContact.LastName)) {
                        quote.zqu__BillToContact__c.addError('Bill To Contact must have a Last Name');
                    }
                }

                // CSP-1414:
                // Add an error if the Sold To contact does not have a FirstName AND LastName
                if(String.isNotBlank(quote.zqu__SoldToContact__c) && contactMap.containsKey(quote.zqu__SoldToContact__c)) {
                    Contact currentContact = contactMap.get(quote.zqu__SoldToContact__c);
                    if(String.isBlank(currentContact.FirstName)) {
                        quote.zqu__SoldToContact__c.addError('Sold To Contact must have a First Name');
                    }

                    if(String.isBlank(currentContact.LastName)) {
                        quote.zqu__SoldToContact__c.addError('Sold To Contact must have a Last Name');
                    }
                }

                // CSP - 1470
                // Note: 12-09-2016 - Moved this to the processing loop AFTER validations occuring above
                if(quote.zqu__SubscriptionType__c != null && quote.zqu__SubscriptionType__c == 'Cancel Subscription'){
                    quote.zqu__GenerateInvoice__c = true;
                    quote.zqu__ProcessPayment__c = true;
                }

                // CSP-1598 - Populate the term total field with the summed effective prices
                if(quoteToSumEffectivePriceMap.containsKey(quote.Id)) {
                    quote.Term_Total__c = quoteToSumEffectivePriceMap.get(quote.Id);
                } else {
                    quote.Term_Total__c = 0;
                }

                // CSP-1598 - Populate the Quote Template ID. This is specifically for LDE's right now
                // CSP-1845 - Now in use for "Print" as well
                if(String.isNotBlank(quote.Product_Line__c) && productLineToQuoteNameMap.containsKey(quote.Product_Line__c)) {
                    String templateName = productLineToQuoteNameMap.get(quote.Product_Line__c);
                    if(nameToQuoteTemplateMap.containsKey(templateName)) {
                        zqu__Quote_Template__c currentTemplate = nameToQuoteTemplateMap.get(templateName);
                        quote.zqu__QuoteTemplate__c = currentTemplate.Id;
                    } else {
                        quote.zqu__QuoteTemplate__c = null;
                    }
                } else {
                    quote.zqu__QuoteTemplate__c = null;
                }

                if (String.isNotBlank(quote.Product_Line__c) && String.valueOf(system.Label.TheProductLineNotAllowAutoRenwal).contains(quote.Product_Line__c) && quote.AutoRenewal__c == 'YES') {
                    quote.addError(system.Label.DisallowAutoRenewalErrorMessage);
                }
                if (!haveAccessForUser && quote.zqu__InitialTerm__c<12 && quote.AutoRenewal__c == 'YES') {
                    quote.addError(system.Label.DisallowAutoRenewalErrorMessageTerms);
                }
            }

        }

        ///added by tony, for ticket CSP-1634
        if (Trigger.isDelete) {
            ZuoraQuoteTriggerHandler.ValidateBeforeDelete(Trigger.old);
        } 
    }*/

    XOTriggerFactory.createAndExecuteHandler(ZuoraQuoteTriggerHandler.class);
    
}