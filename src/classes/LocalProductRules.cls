public without sharing class LocalProductRules {
    ////////////////////////////
    // STATIC FINAL VARIABLES //
    ////////////////////////////
    // CSP-2437 - User Id Set from the Backdate Allow Group - WARNING: This value is used elsewhere, check before modifying
    // CSP-2727 
     public static final Set<Id> backdateUserSet;

     static {
         List<GroupMember> backdateMemberList = [SELECT Id, UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = 'Backdate_Allowed'];

         Set<Id> userIdSet = new Set<Id>();
         for(Integer i = 0; i < backdateMemberList.size(); i++) {
             GroupMember currentMember = backdateMemberList[i];

             if(currentMember.UserOrGroupId.getSobjectType() != Schema.User.SObjectType) {
                 continue;
             }

             userIdSet.add(currentMember.UserOrGroupId);
         }

         backdateUserSet = userIdSet;
     }

    public static void evaluateOpportunity(Id oppId) {

        /****************************/
        /* INITIALIZE CONTROL FLAGS */
        /****************************/

        Boolean evaluateSubscriptionAmendment = False;
        Boolean evaluateInternetProducts = False;
        Boolean evaluatePrintProducts = False;
        Boolean evaluateLDEProducts = False;
        Boolean evaluateMigratedContractProducts = False;


        /************************/
        /* PERFORM BASE QUERIES */
        /************************/

        // To minimize queries, first query Opportunity and child Quote records...
        Opportunity opp = [SELECT Id, Type, AccountId, Account.Email__c, Account.BillingPostalCode, 
                                Account.BillingCountryCode, Account.DynamicsAccID__c, 
                                Approval_Process_Flag_Manager_Approval__c, Approval_Process_Flag_Autoreject__c, 
                                Approval_Process_Flag_Cancel_Approval__c, Approval_Process_Info_For_Approver__c, 
                                (SELECT Id, zqu__PaymentMethod__c, zqu__SubscriptionType__c, zqu__ElectronicPaymentMethodId__c, 
                                    zqu__ZuoraAccountID__c, zqu__InitialTerm__c, Product_Line__c, zqu__ZuoraSubscriptionID__c, 
                                    zqu__ExistSubscriptionID__c, zqu__CancellationDate__c,
                                    Approval_Process_Flag_Discount_Amount__c, zqu__TermStartDate__c FROM zqu__Quotes__r) 
                                FROM Opportunity WHERE Id = :oppId LIMIT 1];
        
        // CSP-1858 | if the Opportunity is Closed Won or Closed Lost, there's no need to perform any of the following logic, so exit immediately
        if (opp.Type.containsIgnoreCase('closed')) {
            return;
        }

        // ...and then query QuoteRatePlan and QuoteRatePlanCharge records
        // note: all formula assessment fields (like "Requires2X__c") looking up to ProductRatePlan return TEXT values -- even "numerical" ones like "MinimumSubscriptionTerm__c"
        List<zqu__QuoteRatePlan__c> qrpList = [SELECT Id, zqu__ProductRatePlanZuoraId__c, zqu__ProductRatePlan__r.Name, zqu__QuoteProductName__c, 
                                                ZProduct_Name__c, zqu__ProductRatePlan__r.zqu__Product__r.zqu__SKU__c, zqu__Quote__r.zqu__InitialTerm__c, Name, 
                                                zqu__AmendmentType__c, zqu__Quote__c, zqu__Quote__r.zqu__Opportunity__c, Location_Vendor__c, 
                                                Location_Vendor__r.Email__c, Location_Vendor__r.ShippingPostalCode, Location_Vendor__r.ShippingCountryCode, 
                                                CannotBeSoldPast__c, NoAutomatedDiscount__c, RequiresApproval__c, RequiresPaidStorefront__c, 
                                                MaximumSubscriptionTerm__c, MinimumSubscriptionTerm__c, Requires2X__c, Print_Issue__c, 
                                                Print_Issue_Next_Issue_ID__c, Print_Issue_Previous_Issue_ID__c, Print_Issue_Step_2_Date__c, 
                                                Print_Issue_Step_3_Date__c, AvoidDuplicates__c, zqu__Quote__r.zqu__TermStartDate__c,Is_Clone__c, Location_Vendor__r.DynamicsAccID__c,
                                                zqu__Quote__r.zqu__SubscriptionType__c,zqu__Quote__r.zqu__SubscriptionTermEndDate__c,zqu__Quote__r.zqu__Service_Activation_Date__c,
                                                zqu__Quote__r.zqu__ZuoraSubscriptionID__c, zqu__Quote__r.zqu__ExistSubscriptionID__c, zqu__Quote__r.zqu__SubscriptionTermStartDate__c,
                                                    (SELECT Id, LocationVendorDynamicsAccountID__c, Name, Product_Name__c, Print_Issue__c, Location_Vendor__c, Location_Vendor__r.Name, 
                                                        Market_ID__c, Category_Taxonomy_ID__c, zqu__QuoteRatePlan__c, zqu__QuoteRatePlan__r.zqu__AmendmentType__c, 
                                                        zqu__QuoteRatePlan__r.ZProduct_Name__c, Steelbrick_Calculated_Discount__c, zqu__Discount__c, Discount_Override__c 
                                                        FROM zqu__Quote_Rate_Plan_Charges__r) 
                                                FROM zqu__QuoteRatePlan__c WHERE zqu__Quote__r.zqu__Opportunity__c = :opp.Id];


        /***********************************/
        /* CREATE OPPORTUNITYQUOTESWRAPPER */
        /***********************************/

        OpportunityQuotesWrapper oqw = generateOpportunityQuotesWrapper(opp, qrpList);


        /*********************/
        /* SET CONTROL FLAGS */
        /*********************/

        for (QuotesWrapper qw : oqw.quotesWrapperList) {
            if (qw.quoteSubscriptionType == 'Amend Subscription' && evaluateSubscriptionAmendment != True) {
                evaluateSubscriptionAmendment = True;
            }
            if (qw.quoteProductLine == 'Internet' && evaluateInternetProducts != True) {
                evaluateInternetProducts = True;
            }
            else if (qw.quoteProductLine == 'Print' && evaluatePrintProducts != True) {
                evaluatePrintProducts = True;
            }
            else if (qw.quoteProductLine == 'Direct Mail' && evaluateLDEProducts != True) {
                evaluateLDEProducts = True;
            }
            else if (qw.quoteProductLine == 'Migrated Contract' && evaluateMigratedContractProducts != True) {
                evaluateMigratedContractProducts = True;
            }
        }


        /******************************************/
        /* RUN PRODUCT RULE EVALUATIONS AS NEEDED */
        /******************************************/

        if (evaluateSubscriptionAmendment) {
            oqw = runSubscriptionAmendmentEvaluation(oqw);
        }

        // NOTE: each Product Line method also needs to evaluate their own cancellation rules
        // this applies to both 'cancellation' Quotes, and 'amendment' Quotes with line items being removed

        if (evaluateInternetProducts) {
            oqw = runInternetEvaluation(oqw);
        }

        if (evaluatePrintProducts) {
            oqw = runPrintEvaluation(oqw);
        }

        if (evaluateLDEProducts) {
            oqw = runLDEEvaluation(oqw);
        }

        if (evaluateMigratedContractProducts) {
            oqw = runMigratedContractEvaluation(oqw);
        }

        /*********************/
        /* EVALUATE DISCOUNTS */
        /*********************/

        oqw = runDiscountEvaluation(oqw);


        /*****************************************************************/
        /* MAKE SURE QUOTES FOR NEW SUBSCRIPTIONS HAVE PRODUCTS SELECTED */
        /*****************************************************************/        

        oqw = determineIfNewSubscriptionQuotesHaveAnyProductsSelected(oqw);


        /******************************************************************************/
        /* MAKE SURE QUOTES FOR AMENDMENT SUBSCRIPTIONS HAVE A CHILD AMENDMENT RECORD */
        /******************************************************************************/

        oqw = determineIfAmendmentQuotesHaveAChildQuoteAmendmentRecord(oqw);


        /*********************************************/
        /* RUN PARTNERS FULFILLMENT VALIDATION RULES */
        /*********************************************/

        oqw = runPartnersFulfillmentValidationRules(oqw);


        /****************************************/
        /* RUN QUOTE TERM START DATE VALIDATION */
        /****************************************/

        oqw = runQuoteTermStartDateValidation(oqw);


        /****************************************************/
        /* RUN DUPLICATE INTERNET QUOTERATEPLANS VALIDATION */
        /****************************************************/

        oqw = runDuplicateInternetQuoteRatePlansCheck(oqw);


        /*****************************************************/
        /* RUN ELECTRONIC PAYMENT BILLING ACCOUNT VALIDATION */
        /*****************************************************/

        oqw = runNewElectronicPaymentBillingAccountValidation(oqw);


        /*****************************/
        /* UPDATE OPPORTUNITY RECORD */
        /*****************************/

        if (oqw.reasonsForAutoreject != '### REASONS FOR AUTOREJECT ###') {
            oqw.opp.Approval_Process_Info_For_Approver__c += oqw.reasonsForAutoreject + '\n\n';
            oqw.opp.Approval_Process_Flag_Autoreject__c = True;
        }

        if (oqw.reasonsForManagerApproval != '### REASONS FOR MANAGER APPROVAL ###') {
            oqw.opp.Approval_Process_Info_For_Approver__c += oqw.reasonsForManagerApproval + '\n\n';
            oqw.opp.Approval_Process_Flag_Manager_Approval__c = True;
        }

        if (oqw.reasonsForCancellationApproval != '### REASONS FOR CANCELLATION APPROVAL ###') {
            oqw.opp.Approval_Process_Info_For_Approver__c += oqw.reasonsForCancellationApproval + '\n\n';
            oqw.opp.Approval_Process_Flag_Cancel_Approval__c = True;
        }

        //CSP-3010 cancel subscription should auto-approve even if account is past due 
        //add remove product rate plan info to opportunity
        if (oqw.reasonsForRemoveApproval != '### REASONS FOR REMOVE APPROVAL ###') {
            oqw.opp.Approval_Process_Info_For_Approver__c += oqw.reasonsForRemoveApproval + '\n\n';
            oqw.opp.Approval_Process_Flag_Remove_Approval__c = True;
        }

        //CSP-3010 cancel subscription should auto-approve even if account is past due 
        //update add/update product rate plan info to opportunity
        if (oqw.reasonsForAddOrUpdateApproval != '### REASONS FOR ADD/UPDATE APPROVAL ###') {
            oqw.opp.Approval_Process_Info_For_Approver__c += oqw.reasonsForAddOrUpdateApproval + '\n\n';
            oqw.opp.Approval_Process_Flag_Add_Approval__c = True;
        }

        // finally, update the Opportunity
        update oqw.opp;
    }


    public static OpportunityQuotesWrapper runPrintEvaluation(OpportunityQuotesWrapper oqw) {

        // add logic here; only record in the OpportunityQuotesWrapper you update is the Opportunity
        // note: in the QuotesWrapper, the two maps are initialized as empty maps, and then the "generateOpportunityQuotesWrapper"
        // method populates them if needed; in your code, it's probably a good idea to make sure these aren't empty before running logic

        // for Print, all "2x" products have to be on the same Quote, which makes evaluation simpler than Internet

        // Design Note: could potentially eliminate the nested FOR loops if we first added all the QuoteRatePlans
        // from all the "Print" QuotesWrappers to a single map; that said, doing so would make the "2x" evaluations trickier
        // and -- just a hunch/feeling -- could make it trickier to add additional functionality moving forward
        

        // this flag set to True when a Quote is for a Subscription Cancellation or when a line item is removed during a Subscription Amendment
        Boolean subscriptionCancellationOrProductRemovalFlag = False;

        // map initially populated for "2x" Print QuoteRatePlans, then processed at the end before Subscription Cancellations and Product Removals
        Map<Id, List<zqu__QuoteRatePlan__c>> twoXMap = new Map<Id, List<zqu__QuoteRatePlan__c>>();

        for (QuotesWrapper qw : oqw.quotesWrapperList) {
            if (qw.quoteProductLine == 'Print' && qw.quoteSubscriptionType == 'Cancel Subscription' && subscriptionCancellationOrProductRemovalFlag == False) {
                subscriptionCancellationOrProductRemovalFlag = True;
            }
            else if (qw.quoteProductLine == 'Print') {
                for (zqu__QuoteRatePlan__c qrp : qw.quoteRatePlanMap.values()) {
                    // CSP-3010 Cancel subscription should auto-approve even if account is past due
                    // Set flag to true for updata opportunity flag
                    if (qrp.zqu__AmendmentType__c == 'NewProduct' || qrp.zqu__AmendmentType__c == 'UpdateProduct') {

                        oqw.reasonsForAddOrUpdateApproval += '\nA product is being Add/Update - Product: ' + qrp.zqu__QuoteProductName__c + ' | Rate Plan: ' + qrp.Name;
                    }
                    if (qrp.zqu__AmendmentType__c == 'RemoveProduct' && subscriptionCancellationOrProductRemovalFlag == False) {
                        subscriptionCancellationOrProductRemovalFlag = True;
                    }
                    else if (qrp.zqu__AmendmentType__c != 'RemoveProduct') {

                        // for now, populate the map above for processing after this FOR loop
                        if (qrp.Requires2X__c == 'Yes') {

                            // if map contains key, get and update list
                            if (twoXMap.containsKey(qw.quoteId)) {
                                List<zqu__QuoteRatePlan__c> tempQRPListFortwoXMap = twoXMap.get(qw.quoteId);
                                tempQRPListFortwoXMap.add(qrp);
                                twoXMap.put(qw.quoteId, tempQRPListFortwoXMap);
                            }
                            // otherwise create new list and add to map
                            else {
                                List<zqu__QuoteRatePlan__c> newQRPListFortwoXMap = new List<zqu__QuoteRatePlan__c>();
                                newQRPListFortwoXMap.add(qrp);
                                twoXMap.put(qw.quoteId, newQRPListFortwoXMap);
                            }
                        }

                        // always requires approval (ex: BOW, at least for now)
                        if (qrp.RequiresApproval__c == 'Yes') {
                            oqw.reasonsForManagerApproval += '\nThe Product ' + qrp.zqu__QuoteProductName__c + ' always requires manager approval';
                        }

                        // NOTE: all these date evaluations assume that if the date isn't filled in on the Print Issue, then we should ignore the rule

                        // Nick wu comment out these sell by dates restrictions of pritn issue for CSP-1114
                        
                        // if (qrp.CannotBeSoldPast__c == 'Step 2 Date') {
                        //     if (qrp.Print_Issue_Step_2_Date__c != null && qrp.Print_Issue_Step_2_Date__c < Date.today()) {
                        //         oqw.reasonsForManagerApproval += '\nThe Rate Plan ' + qrp.Name + ' for Product ' + qrp.zqu__QuoteProductName__c + ' cannot be sold past the Step 2 Date of the Print Issue';
                        //     }
                        // }

                        // if (qrp.CannotBeSoldPast__c == '3 Weeks Before Step 2 Date') {
                        //     if ((qrp.Print_Issue_Step_2_Date__c != null) && (qrp.Print_Issue_Step_2_Date__c - 21 < Date.today())) {
                        //         oqw.reasonsForManagerApproval += '\nThe Rate Plan ' + qrp.Name + ' for Product ' + qrp.zqu__QuoteProductName__c + ' cannot be sold after three weeks before the Step 2 Date of the Print Issue';
                        //     }
                        // }

                        // if (qrp.CannotBeSoldPast__c == 'Step 3 Date') {
                        //     if (qrp.Print_Issue_Step_3_Date__c != null && qrp.Print_Issue_Step_3_Date__c < Date.today()) {
                        //         oqw.reasonsForManagerApproval += '\nThe Rate Plan ' + qrp.Name + ' for Product ' + qrp.zqu__QuoteProductName__c + ' cannot be sold past the Step 3 Date of the Print Issue';
                        //     }
                        // }

                        if (qw.quoteSubscriptionType == 'New Subscription' && (Integer.ValueOf(qrp.zqu__Quote__r.zqu__InitialTerm__c) < 12)){
                            oqw.reasonsForManagerApproval += '\nThe Product "' + qrp.zqu__QuoteProductName__c + '" should be sold for minimum subscription term of 12 month(s)';
                        } 
                    }
                }
            }
        }

        if (!twoXMap.isEmpty()) {
            // "quote specific" because 2x products have to have a matching 2x product in the same Quote
            for (List<zqu__QuoteRatePlan__c> quoteSpecificQRPList : twoXMap.values()) {
                Map<String, List<TwoXWrapper>> wrapperKeyToTwoXWrapperMap = generateTwoXWrapperMap(quoteSpecificQRPList);

                List<zqu__QuoteRatePlan__c> qrpWarningList = new List<zqu__QuoteRatePlan__c>();

                qrpWarningList = evaluateTwoXProductsAndReturnQRPWarningList(wrapperKeyToTwoXWrapperMap);

                if (!qrpWarningList.isEmpty()) {
                    for (zqu__QuoteRatePlan__c qrp2xWarningRecord : qrpWarningList) {
                        oqw.reasonsForManagerApproval += '\nOn Quote Id ' + qrp2xWarningRecord.zqu__Quote__c + ', the Rate Plan ' + qrp2xWarningRecord.Name + ' for Product ' + qrp2xWarningRecord.zqu__QuoteProductName__c + ' is a "2x" product and does not seem to have a related Product / Print Issue in the Quote';
                    }
                }
            }
        }

        if (subscriptionCancellationOrProductRemovalFlag) {
            oqw = SubscriptionCancellationOrProductRemovalEvaluation(oqw);
        }

        return oqw;
    }


    // 11-12-15 Note: the only LDE-specific rules are Cancellations, and Requires Paid Storefront "In Any Market/Category"
    public static OpportunityQuotesWrapper runLDEEvaluation(OpportunityQuotesWrapper oqw) {

        Boolean subscriptionCancellationOrProductRemovalFlag = False;
        Boolean storefrontQRPForParentAccountOnOpportunity = False;

        List<zqu__QuoteRatePlan__c> ldeRequiresPaidStorefrontList = new List<zqu__QuoteRatePlan__c>();

        for (QuotesWrapper qw : oqw.quotesWrapperList) {
            if (qw.quoteProductLine == 'Direct Mail' && qw.quoteSubscriptionType == 'Cancel Subscription' && subscriptionCancellationOrProductRemovalFlag == False) {
                subscriptionCancellationOrProductRemovalFlag = True;
            }
            else if (qw.quoteProductLine == 'Direct Mail' && !qw.quoteRatePlanMap.isEmpty()) {
                for (zqu__QuoteRatePlan__c qrp : qw.quoteRatePlanMap.values()) {
                    //3010 Cancel subscription should auto-approve even if account is past due
                    // Set flag to true for updata opportunity flag
                   if (qrp.zqu__AmendmentType__c == 'NewProduct' || qrp.zqu__AmendmentType__c == 'UpdateProduct') {

                        oqw.reasonsForAddOrUpdateApproval += '\nA product is being Add/Update - Product: ' + qrp.zqu__QuoteProductName__c + ' | Rate Plan: ' + qrp.Name;
                    }
                    if (qrp.zqu__AmendmentType__c == 'RemoveProduct' && subscriptionCancellationOrProductRemovalFlag == False) {
                        subscriptionCancellationOrProductRemovalFlag = True;
                    }
                    if (qrp.zqu__AmendmentType__c != 'RemoveProduct' && qrp.RequiresPaidStorefront__c == 'In Any Market/Category') {
                        // add all "Requires Paid Storefront In Any Market/Category" LDE QRPs to a list
                        ldeRequiresPaidStorefrontList.add(qrp);
                    }
                    if (qw.quoteSubscriptionType == 'New Subscription' && (Integer.ValueOf(qrp.zqu__Quote__r.zqu__InitialTerm__c) < 12)){
                        oqw.reasonsForManagerApproval += '\nThe Product "' + qrp.zqu__QuoteProductName__c + '" should be sold for minimum subscription term of 12 month(s)';
                    }
                    // always requires approval (ex: BOW, at least for now)
                    if (qrp.RequiresApproval__c == 'Yes') {
                        oqw.reasonsForManagerApproval += '\nThe Product ' + qrp.zqu__QuoteProductName__c + ' always requires manager approval';
                    }                    
                }
            }
            else if (qw.quoteProductLine == 'Internet' && qw.quoteSubscriptionType != 'Cancel Subscription' && !qw.quoteRatePlanMap.isEmpty() && storefrontQRPForParentAccountOnOpportunity != True) {
                for (zqu__QuoteRatePlan__c iqrp : qw.quoteRatePlanMap.values()) {
                    // TODO: check to make sure the Location_Vendor evaluation doesn't get messed up by 15 vs 18 char IDs -- if both are ID comparison it's fine
                    if (iqrp.zqu__QuoteProductName__c.containsIgnoreCase('Storefront') && iqrp.Location_Vendor__c == oqw.opp.AccountId) {
                        storefrontQRPForParentAccountOnOpportunity = True;
                    }
                }
            }
        }

        // if any LDE products require a paid Storefront, run logic
        // Opportunity QuoteRatePlans are checked above, if nothing was found the final step is to check active Subscriptions
        if (!ldeRequiresPaidStorefrontList.isEmpty() && !storefrontQRPForParentAccountOnOpportunity) {

            // As of 11-19-2015 the LocationVendorDynamicsAccountID__c field on SubscriptionProductCharge is being populated with Account Id, but it should be Dynamics Id; using both in query to be safe
            String oppAccountIdString = String.valueOf(oqw.opp.AccountId).left(15);
            String oppAccountDynamicsAccountIdString = oqw.opp.Account.DynamicsAccID__c;

            List<Zuora__SubscriptionProductCharge__c> spcList = new List<Zuora__SubscriptionProductCharge__c>();

            if (String.isNotBlank(oppAccountIdString) && String.isNotBlank(oppAccountDynamicsAccountIdString)) {
                spcList = Database.query('SELECT Id, Zuora__ProductName__c, LocationVendorDynamicsAccountID__c FROM Zuora__SubscriptionProductCharge__c WHERE Zuora__ProductName__c = \'Storefront\' AND LocationVendorDynamicsAccountID__c = \'' + oppAccountDynamicsAccountIdString + '\' LIMIT 1');
            }
            
            // if no applicable Subscription Storefronts were found, add warning message
            if (spcList.isEmpty()) {
                for (zqu__QuoteRatePlan__c ldeQRP : ldeRequiresPaidStorefrontList) {
                    oqw.reasonsForManagerApproval += '\nA Paid Storefront is required in order to purchase Product: ' + ldeQRP.zqu__QuoteProductName__c + ' | Rate Plan: ' + ldeQRP.Name;
                }
            }
        }

        if (subscriptionCancellationOrProductRemovalFlag) {
            oqw = SubscriptionCancellationOrProductRemovalEvaluation(oqw);
        }

        return oqw;
    }


    public static OpportunityQuotesWrapper runInternetEvaluation(OpportunityQuotesWrapper oqw) {
        Set<Id> qrpIds = new Set<Id>();
        Set<String> locIds = new Set<String>();
        //Set<String> reasonsForAutoRejectSet = new Set<String>();

        String productName = 'Storefront';

        Integer Counter = 0;

        Boolean subscriptionCancellationOrProductRemovalFlagInternet = False;
     

        // Key: ID of Location Id | Value: list of subscription product charge records
        Map<String, List<Zuora__SubscriptionProductCharge__c>> locSubPrdChargeMap = new Map<String, List<Zuora__SubscriptionProductCharge__c>>();       
        
        List<zqu__QuoteRatePlanCharge__c> qrpcList = new List<zqu__QuoteRatePlanCharge__c>();
        List<RestrictedCategories__c> rc = RestrictedCategories__c.getall().values();   

        //retrieve all the locations and quote rate plan charge tied to quote rate plan records and hold it in locIds set and qrpcList
        for (QuotesWrapper qw : oqw.quotesWrapperList) {
            if (qw.quoteProductLine == 'Internet') {
                for (zqu__QuoteRatePlan__c qrp : qw.quoteRatePlanMap.values()) {
                    for(zqu__QuoteRatePlanCharge__c qrpc : qw.quoteRatePlanChargeListMap.get(qrp.Id)){
                        // Do not add blank or null values as this causes the query to become unselective
                        if(String.isBlank(qrpc.LocationVendorDynamicsAccountID__c)) {
                            continue;
                        }
                        
                        locIds.add(qrpc.LocationVendorDynamicsAccountID__c);
                        qrpcList.add(qrpc);
                    }           
                }
            }
        }

        //query all the subscription production charges tied to the parent location    
        List<Zuora__SubscriptionProductCharge__c> spcList = [SELECT Zuora__Account__c, LocationVendorDynamicsAccountID__c, Category_Taxonomy_ID__c, Market_ID__c, Product_Type__c, Zuora__ProductName_Product__c, Zuora__ProductName__c FROM Zuora__SubscriptionProductCharge__c where LocationVendorDynamicsAccountID__c IN : locIds];
        
        //create a map of (Key:) Location Id and the corresponding (Value:)list of subscrition product charge
        for(Zuora__SubscriptionProductCharge__c zSpc : spcList){
            List<Zuora__SubscriptionProductCharge__c> spcNewList = new List<Zuora__SubscriptionProductCharge__c>();
            if(locSubPrdChargeMap.containsKey(zSpc.LocationVendorDynamicsAccountID__c)){         
                System.Debug('updating the map for ' + zSpc.LocationVendorDynamicsAccountID__c);
                locSubPrdChargeMap.get(zSpc.LocationVendorDynamicsAccountID__c).add(zSpc);
            }else{
                System.Debug('adding a new guy for ' + zSpc.LocationVendorDynamicsAccountID__c);
                spcNewList = new List<Zuora__SubscriptionProductCharge__c>();
                spcNewList.add(zSpc);
                locSubPrdChargeMap.put(zSpc.LocationVendorDynamicsAccountID__c, spcNewList);
            }
        }
        
        for (QuotesWrapper qw : oqw.quotesWrapperList) {
            if (qw.quoteProductLine == 'Internet' && qw.quoteSubscriptionType == 'Cancel Subscription' && subscriptionCancellationOrProductRemovalFlagInternet == False) {
                subscriptionCancellationOrProductRemovalFlagInternet = True;
            }
            else if (qw.quoteProductLine == 'Internet') {
                for (zqu__QuoteRatePlan__c qrp : qw.quoteRatePlanMap.values()) {
                    // CSP-3010 Cancel subscription should auto-approve even if account is past due
                    // Set flag to true for updata opportunity flag
                   if (qrp.zqu__AmendmentType__c == 'NewProduct' || qrp.zqu__AmendmentType__c == 'UpdateProduct') {

                         oqw.reasonsForAddOrUpdateApproval += '\nA product is being Add/Update - Product: ' + qrp.zqu__QuoteProductName__c + ' | Rate Plan: ' + qrp.Name;
                    }                
                    if (qrp.zqu__AmendmentType__c == 'RemoveProduct' && subscriptionCancellationOrProductRemovalFlagInternet == False) {
                        subscriptionCancellationOrProductRemovalFlagInternet = True;
                    }
                    else {
                        for(zqu__QuoteRatePlanCharge__c qrpc : qw.quoteRatePlanChargeListMap.get(qrp.Id)){
                            String str = '';
                            if(!qrpIds.contains(qrp.Id)){
                                qrpIds.add(qrp.Id);
                                // check minimum subscription term length only for new Subscriptions
                                if(qw.quoteSubscriptionType == 'New Subscription'){
                                    if(Integer.ValueOf(qrp.zqu__Quote__r.zqu__InitialTerm__c) < 12){
                                        oqw.reasonsForManagerApproval += '\nThe Product "' + qrp.zqu__QuoteProductName__c + '" should be sold for minimum subscription term of 12 month(s)';
                                    }
                                }

                                //check if the category associated with quote rate plan can be sold to the location tied to the rate plan or not
                                for(Integer i = 0; i < rc.Size(); i++){
                                    str = '';
                                    if(rc[i].Category_Taxonomy_Id__c == qrpc.Category_Taxonomy_ID__c && qrp.zqu__ProductRatePlan__r.zqu__Product__r.zqu__SKU__c == rc[i].Name){                                        
                                        oqw.reasonsForManagerApproval += '\nThe Product "' + qrp.zqu__QuoteProductName__c + '" is tied to Menswear category and hence requires approval';
                                    }
                                }
                                
                                //check if there are any duplicate storefront products sold for the same location
                                if(!String.IsBlank(qrp.AvoidDuplicates__c)){
                                    Set<String> psfLocName = new Set<String>();
                                    counter = 0;
                                    //compare each rate plan with complete list of rate plan associated with the opportunity in context and increment the counter if a duplicate is found
                                    for(zqu__QuoteRatePlanCharge__c qrpch : qrpcList){
                                        if(qrpc.zqu__QuoteRatePlan__c <> qrpch.zqu__QuoteRatePlan__c){
                                            if(qrp.AvoidDuplicates__c == 'In Any Market/Category' && qrpch.zqu__QuoteRatePlan__r.ZProduct_Name__c == qrp.ZProduct_Name__c){
                                                psfLocName.add(qrpc.Location_Vendor__r.Name);
                                                counter++;                                              
                                            }else if(qrp.AvoidDuplicates__c == 'In Same Market' && qrpch.zqu__QuoteRatePlan__r.ZProduct_Name__c == qrp.ZProduct_Name__c && qrpc.Market_ID__c == qrpch.Market_ID__c){
                                                psfLocName.add(qrpc.Location_Vendor__r.Name);
                                                counter++;
                                            }else if(qrp.AvoidDuplicates__c == 'In Same Category' && qrpch.zqu__QuoteRatePlan__r.ZProduct_Name__c == qrp.ZProduct_Name__c && qrpc.Category_Taxonomy_ID__c == qrpch.Category_Taxonomy_ID__c){
                                                psfLocName.add(qrpc.Location_Vendor__r.Name);
                                                counter++;
                                            }else if(qrp.AvoidDuplicates__c == 'In Same Market/Category' && qrpch.zqu__QuoteRatePlan__r.ZProduct_Name__c == qrp.ZProduct_Name__c && qrpc.Market_ID__c == qrpch.Market_ID__c && qrpc.Category_Taxonomy_ID__c == qrpch.Category_Taxonomy_ID__c){
                                                psfLocName.add(qrpc.Location_Vendor__r.Name);
                                                counter++;
                                            }
                                        }                                                                               
                                    }
                                    
                                    //Check if we have any duplicate storefront subscription product charge record in any of the location associated with the quote rate plan
                                    if(locSubPrdChargeMap.get(qrpc.LocationVendorDynamicsAccountID__c) <> null){
                                        for(Zuora__SubscriptionProductCharge__c zspc : locSubPrdChargeMap.get(qrpc.LocationVendorDynamicsAccountID__c)){                                        
                                            if(qrp.AvoidDuplicates__c == 'In Any Market/Category' && qrp.zqu__AmendmentType__c == 'NewProduct' && zspc.Zuora__ProductName__c == qrpc.zqu__QuoteRatePlan__r.ZProduct_Name__c){
                                                psfLocName.add(qrpc.Location_Vendor__r.Name);
                                                counter++;                                              
                                            }else if(qrp.AvoidDuplicates__c == 'In Same Market' && qrp.zqu__AmendmentType__c == 'NewProduct' && zspc.Zuora__ProductName__c == qrpc.zqu__QuoteRatePlan__r.ZProduct_Name__c && zspc.Market_Id__c == qrpc.Market_ID__c){
                                                psfLocName.add(qrpc.Location_Vendor__r.Name);
                                                counter++;
                                            }else if(qrp.AvoidDuplicates__c == 'In Same Category' && qrp.zqu__AmendmentType__c == 'NewProduct' && zspc.Zuora__ProductName__c == qrpc.zqu__QuoteRatePlan__r.ZProduct_Name__c && zspc.Category_Taxonomy_ID__c == qrpc.Category_Taxonomy_ID__c){
                                                psfLocName.add(qrpc.Location_Vendor__r.Name);
                                                counter++;
                                            }else if(qrp.AvoidDuplicates__c == 'In Same Market/Category' && qrp.zqu__AmendmentType__c == 'NewProduct' && zspc.Zuora__ProductName__c == qrpc.zqu__QuoteRatePlan__r.ZProduct_Name__c && zspc.Market_Id__c == qrpc.Market_ID__c && zspc.Category_Taxonomy_ID__c == qrpc.Category_Taxonomy_ID__c){
                                                psfLocName.add(qrpc.Location_Vendor__r.Name);
                                                counter++;
                                            }
                                        }
                                    }   
                                    
                                    if(counter > 0){
                                        oqw.reasonsForAutoreject += '\nA duplicate "'+qrp.zqu__QuoteProductName__c+'" product found for this account/location :'+psfLocName;
                                    }
                                }
                                
                                //check if a product requires a paid store front in any/same market/category
                                if(!String.IsBlank(qrp.RequiresPaidStorefront__c)){
                                    counter = 0;
                                    for(zqu__QuoteRatePlanCharge__c qrpch : qrpcList){ 
                                        if(qrpc.zqu__QuoteRatePlan__c <> qrpch.zqu__QuoteRatePlan__c){
                                            if(qrp.RequiresPaidStorefront__c == 'In Any Market/Category' && (qrpch.zqu__QuoteRatePlan__r.ZProduct_Name__c).containsIgnoreCase(productName)){
                                                counter++;                                              
                                            }else if(qrp.RequiresPaidStorefront__c == 'In Same Market' && (qrpch.zqu__QuoteRatePlan__r.ZProduct_Name__c).containsIgnoreCase(productName) && qrpc.Market_ID__c == qrpch.Market_ID__c){
                                                counter++;
                                            }else if(qrp.RequiresPaidStorefront__c == 'In Same Category' && (qrpch.zqu__QuoteRatePlan__r.ZProduct_Name__c).containsIgnoreCase(productName) && qrpc.Category_Taxonomy_ID__c == qrpch.Category_Taxonomy_ID__c){
                                                counter++;
                                            }else if(qrp.RequiresPaidStorefront__c == 'In Same Market/Category' && (qrpch.zqu__QuoteRatePlan__r.ZProduct_Name__c).containsIgnoreCase(productName) && qrpc.Market_ID__c == qrpch.Market_ID__c && qrpc.Category_Taxonomy_ID__c == qrpch.Category_Taxonomy_ID__c){
                                                counter++;
                                            }
                                        }
                                    }
                                    
                                    if(locSubPrdChargeMap.containsKey(qrpc.LocationVendorDynamicsAccountID__c)){ 
                                        System.Debug('Subscriptions to loop through: ' + locSubPrdChargeMap.size());                                       
                                        for(Zuora__SubscriptionProductCharge__c zspc : locSubPrdChargeMap.get(qrpc.LocationVendorDynamicsAccountID__c)){                                        
                                            System.Debug('Counter: ' + counter);
                                            System.Debug(zspc.Zuora__ProductName__c);
                                            System.Debug(productName);
                                            System.Debug(qrpc.Market_ID__c);
                                            System.Debug(zspc.Market_ID__c);
                                            System.Debug(qrpc.Category_Taxonomy_ID__c);
                                            System.Debug(zspc.Category_Taxonomy_ID__c);

                                            if(qrp.RequiresPaidStorefront__c == 'In Any Market/Category' && (zspc.Zuora__ProductName__c).containsIgnoreCase(productName)){
                                                counter++;                                              
                                            }else if(qrp.RequiresPaidStorefront__c == 'In Same Market' && (zspc.Zuora__ProductName__c).containsIgnoreCase(productName) && zspc.Market_Id__c == qrpc.Market_ID__c){
                                                counter++;
                                            }else if(qrp.RequiresPaidStorefront__c == 'In Same Category' && (zspc.Zuora__ProductName__c).containsIgnoreCase(productName) && zspc.Category_Taxonomy_ID__c == qrpc.Category_Taxonomy_ID__c){
                                                counter++;
                                            }else if(qrp.RequiresPaidStorefront__c == 'In Same Market/Category' && (zspc.Zuora__ProductName__c).containsIgnoreCase(productName) && zspc.Market_Id__c == qrpc.Market_ID__c && zspc.Category_Taxonomy_ID__c == qrpc.Category_Taxonomy_ID__c){
                                                counter++;
                                            }
                                        }
                                    }
                                    
                                    if(counter == 0){
                                        oqw.reasonsForAutoreject += '\nThe Product "' + qrp.zqu__QuoteProductName__c + '" should have a paid Storefront ';
                                    }
                                }
                                
                                if (qrp.RequiresApproval__c == 'Yes') {
                                    oqw.reasonsForManagerApproval += '\nThe Product "' + qrp.zqu__QuoteProductName__c + '" always requires manager approval';
                                }
                            }
                        }                       
                    }
                }
            }
        }
        
        if (subscriptionCancellationOrProductRemovalFlagInternet) {
            oqw = SubscriptionCancellationOrProductRemovalEvaluation(oqw);
        }

        return oqw;
    }



    // SF-2157
    public static OpportunityQuotesWrapper runMigratedContractEvaluation(OpportunityQuotesWrapper oqw) {

        Boolean subscriptionCancellationOrProductRemovalFlag = False;
    

        for (QuotesWrapper qw : oqw.quotesWrapperList) {
            if (qw.quoteProductLine == 'Migrated Contract' && qw.quoteSubscriptionType == 'Cancel Subscription' && subscriptionCancellationOrProductRemovalFlag == False) {
                subscriptionCancellationOrProductRemovalFlag = True;
            }
            else if (qw.quoteProductLine == 'Migrated Contract' && !qw.quoteRatePlanMap.isEmpty()) {
                for (zqu__QuoteRatePlan__c qrp : qw.quoteRatePlanMap.values()) {
                    if (qrp.zqu__AmendmentType__c == 'RemoveProduct' && subscriptionCancellationOrProductRemovalFlag == False) {
                        subscriptionCancellationOrProductRemovalFlag = True;
                    }
                    //CSP- 3010 Cancel subscription should auto-approve even if account is past due
                    // Set flag to true for updata opportunity flag
                    else if (qrp.zqu__AmendmentType__c == 'NewProduct' || qrp.zqu__AmendmentType__c == 'UpdateProduct') {

                        oqw.reasonsForAddOrUpdateApproval += '\nA product is being Add/Update - Product: ' + qrp.zqu__QuoteProductName__c + ' | Rate Plan: ' + qrp.Name;
                    }
                }
            }
        }

        if (subscriptionCancellationOrProductRemovalFlag) {
            oqw = SubscriptionCancellationOrProductRemovalEvaluation(oqw);
        }

        return oqw;
    }

    public static OpportunityQuotesWrapper SubscriptionCancellationOrProductRemovalEvaluation(OpportunityQuotesWrapper oqw) {

        for (QuotesWrapper qw : oqw.quotesWrapperList) {
            if (qw.quoteSubscriptionType == 'Cancel Subscription') {
                oqw.reasonsForCancellationApproval += '\nThe Quote with ID ' + String.valueOf(qw.quote.Id) + ' is for a Subscription Cancellation';
            }
            else {     
                for (zqu__QuoteRatePlan__c qrp : qw.quoteRatePlanMap.values()) {
                    if (qrp.zqu__AmendmentType__c == 'RemoveProduct') {
                        oqw.reasonsForRemoveApproval += '\nA product is being removed from an existing subscription - Product: ' + qrp.zqu__QuoteProductName__c + ' | Rate Plan: ' + qrp.Name;
                    }
                }
            }
        }

        return oqw;
    }



    // SF-1336
    // TODO: remove the Discount flag fields on the Quote and the Opportunity records, no longer needed
    public static OpportunityQuotesWrapper runDiscountEvaluation(OpportunityQuotesWrapper oqw) {

        List<zqu__QuoteRatePlanCharge__c> qrpcList = new List<zqu__QuoteRatePlanCharge__c>();

        for (QuotesWrapper qw : oqw.quotesWrapperList) {
            if (qw.quoteSubscriptionType != 'Cancel Subscription' && !qw.quoteRatePlanChargeListMap.isEmpty()) {
                for (List<zqu__QuoteRatePlanCharge__c> eachList : qw.quoteRatePlanChargeListMap.values()) {
                    qrpcList.addAll(eachList);
                }
            }
        }

        if (!qrpcList.isEmpty()) {
            for (zqu__QuoteRatePlanCharge__c qrpc : qrpcList) {
                if (qrpc.Discount_Override__c > qrpc.Steelbrick_Calculated_Discount__c) {
                    oqw.reasonsForManagerApproval += '\nThe Rate Plan Charge "' + qrpc.Name + '" for Product "' + qrpc.Product_Name__c + '" has a Discount Override that is greater than what was autocalculated';
                }           
            }
        }

        return oqw;
    }



    // CSP-314
    public static OpportunityQuotesWrapper runSubscriptionAmendmentEvaluation(OpportunityQuotesWrapper oqw) {
        for (QuotesWrapper qw : oqw.quotesWrapperList) {
            if (qw.quoteSubscriptionType == 'Amend Subscription') {
                oqw.reasonsForManagerApproval += '\nThe Quote with ID "' + (String)qw.quoteId + '" is an amendment for an existing Subscription';
            }
        }
        return oqw;
    }



    // CSP-1601; on non-Cancellation Quote record insert sure the Term Start Date is greater than or equal to today, otherwise autoreject
    public static OpportunityQuotesWrapper runQuoteTermStartDateValidation(OpportunityQuotesWrapper oqw) {
        for (QuotesWrapper qw : oqw.quotesWrapperList) {
            // csp-2727- allowing backdating for certain users
            if (qw.quote.zqu__SubscriptionType__c != 'Cancel Subscription' && qw.quote.zqu__TermStartDate__c < Date.today() && !backdateUserSet.contains(System.UserInfo.getUserId())) {
                oqw.reasonsForAutoreject += '\nThe Quote with ID "' + (String)qw.quoteId + '" has a Term Start Date set to prior to today; please edit the Term Start Date to a future date and resubmit for approval.';
            }
        }
        return oqw;
    }



    // SF-2291; make sure Quotes for New Subscriptions have at least one product selected; if not, autoreject
    public static OpportunityQuotesWrapper determineIfNewSubscriptionQuotesHaveAnyProductsSelected(OpportunityQuotesWrapper oqw) {
        for (QuotesWrapper qw : oqw.quotesWrapperList) {
            if (qw.quoteSubscriptionType == 'New Subscription' && qw.quoteRatePlanMap.isEmpty()) {
                oqw.reasonsForAutoreject += '\nThe Quote with ID "' + (String)qw.quoteId + '" does not have any products selected';
            }
        }
        return oqw;
    }



    // SF-2291; make sure Quotes for Amendment Subscriptions have at least one child Quote Amendment record; if not, autoreject
    // note: this code can be updated in the future if we want to add additional logic around what type of amendments are being added,
    // but right now all it does is evaluate whether or not the Quote even has a child Quote Amendment record
    public static OpportunityQuotesWrapper determineIfAmendmentQuotesHaveAChildQuoteAmendmentRecord(OpportunityQuotesWrapper oqw) {
        
        Map<Id, QuotesWrapper> quoteIdToQWMap = new Map<Id, QuotesWrapper>();

        for (QuotesWrapper qw : oqw.quotesWrapperList) {
            if (qw.quoteSubscriptionType == 'Amend Subscription' && qw.quoteRatePlanMap.isEmpty()) {
                quoteIdToQWMap.put(qw.quoteId, qw);
            }
        }

        if (!quoteIdToQWMap.isEmpty()) {
            Map<Id, List<zqu__QuoteAmendment__c>> quoteIdToQuoteAmendmentListMap = new Map<Id, List<zqu__QuoteAmendment__c>>();
            for (zqu__QuoteAmendment__c qa : [SELECT Id, zqu__Quote__c FROM zqu__QuoteAmendment__c WHERE zqu__Quote__c IN :quoteIdToQWMap.keySet()]) {
                List<zqu__QuoteAmendment__c> qaList;
                if (quoteIdToQuoteAmendmentListMap.containsKey(qa.zqu__Quote__c)) {
                    qaList = quoteIdToQuoteAmendmentListMap.get(qa.zqu__Quote__c);
                }
                else {
                    qaList = new List<zqu__QuoteAmendment__c>();
                }
                qaList.add(qa);
                quoteIdToQuoteAmendmentListMap.put(qa.zqu__Quote__c, qaList);
            }
            for (QuotesWrapper aqw : quoteIdToQWMap.values()) {
                if (!quoteIdToQuoteAmendmentListMap.containsKey(aqw.quoteId)) {
                    oqw.reasonsForAutoreject += '\nThe Amendment Quote with ID "' + (String)aqw.quoteId + '" does not contains any Terms and Conditions or Product amendments';
                }
            }
        }

        return oqw;
    }


    // CSP-572
    public static OpportunityQuotesWrapper runPartnersFulfillmentValidationRules(OpportunityQuotesWrapper oqw) {
        // Comment by ticket CSP-1215, Remove the constraint in the rule that the role has to be associated with the account on the opp 
        /*
            First: Make sure the Account has a Contact who is also designated as the Accounts Primary or Billing Contact
            
            CSP-1215:
            Additional requirements to REMOVE the associate that the Contact MUST lookup to the same Account that the
            Opportunity is looking up to.
            Code remove: "AND Contact.AccountId = :oqw.opp.AccountId"
         */
        List<AccountContactRole> acrList = [SELECT Id FROM AccountContactRole WHERE (Role = 'Primary' OR Role = 'Billing') AND AccountId = :oqw.opp.AccountId LIMIT 1];
        if (acrList.isEmpty()) {
            oqw.reasonsForAutoreject += '\nThe Opportunity\'s Account does not have a Contact who is the Account\'s designated Primary Contact';
        }
        // then make sure the Account's Email__c field is populated
        if (String.isBlank(oqw.opp.Account.Email__c)) {
            oqw.reasonsForAutoreject += '\nThe Opportunity\'s Account does not have an Email Address';
        }
        // then make sure the Account's BillingPostalCode and BillingCountryCode fields are populated...
        if (String.isBlank(oqw.opp.Account.BillingCountryCode) || String.isBlank(oqw.opp.Account.BillingPostalCode)) {
            oqw.reasonsForAutoreject += '\nThe Opportunity\'s Account does not have a Billing Postal Code and/or a Billing Country Code';
        }
        // ...and if they are populated, make sure they pass the zip code validation
        else if (!XOCustomValidationUtility.validZip(oqw.opp.Account.BillingCountryCode, oqw.opp.Account.BillingPostalCode)) {
            oqw.reasonsForAutoreject += '\nThe Opportunity\'s Account does not have a valid Billing Postal Code and Billing Country Code combination';
        }
        // lastly, check data on the Quote Rate Plan Location Accounts (required on certain products during the Quote creation workflow) 
        for (QuotesWrapper qw : oqw.quotesWrapperList) {
            for (zqu__QuoteRatePlan__c qrp : qw.quoteRatePlanMap.values()) {
                if (String.isNotBlank(qrp.Location_Vendor__c)) {
                    // make sure the Location Account's Email__c field is populated
                    if (String.isBlank(qrp.Location_Vendor__r.Email__c)) {
                        oqw.reasonsForAutoreject += '\nA Quote Rate Plan\'s (ID: ' + String.valueOf(qrp.Id) + ') Location Account (ID: ' + String.valueOf(qrp.Location_Vendor__c) + ') does not have an Email Address';
                    }
                    // then make sure the Location Account's ShippingPostalCode and ShippingCountryCode fields are populated...
                    if (String.isBlank(qrp.Location_Vendor__r.ShippingCountryCode) || String.isBlank(qrp.Location_Vendor__r.ShippingPostalCode)) {
                        oqw.reasonsForAutoreject += '\nA Quote Rate Plan\'s (ID: ' + String.valueOf(qrp.Id) + ') Location Account (ID: ' + String.valueOf(qrp.Location_Vendor__c) + ') does not have a Shipping Postal Code and/or a Shipping Country Code';
                    }
                    // ...and if they are populated, make sure they pass the zip code validation
                    else if (!XOCustomValidationUtility.validZip(qrp.Location_Vendor__r.ShippingCountryCode, qrp.Location_Vendor__r.ShippingPostalCode)) {
                        oqw.reasonsForAutoreject += '\nA Quote Rate Plan\'s (ID: ' + String.valueOf(qrp.Id) + ') Location Account (ID: ' + String.valueOf(qrp.Location_Vendor__c) + ') does not have a valid Shipping Postal Code and Shipping Country Code combination';
                    }
                }
            }
        }
        return oqw;
    }


    /**
     *   CSP-1183 | "runDuplicateInternetQuoteRatePlansCheck" checks for duplicate Internet QuoteRatePlans. "Duplicate" in
     *   this case is defined as the QuoteRatePlans for the same ProductRatePlan that have the same Location selected.
     *
     *   @author Jonathan Satterfield
     *   @date   2017-02-07
     *   @param  {OpportunityQuotesWrapper}
     *   @return {OpportunityQuotesWrapper}
     */
    public static OpportunityQuotesWrapper runDuplicateInternetQuoteRatePlansCheck(OpportunityQuotesWrapper oqw) {
        // the "keys" are zqu__QuoteRatePlan__c.zqu__ProductRatePlanZuoraId__c + zqu__QuoteRatePlan__c.Location_Vendor__c
        Set<String> duplicateProductRatePlanNameSet = new Set<String>();
        // CSP-2835 Update Duplicate Approval Rule to Recognize Term Start and End Dates
        // CSP-2901 Instance of Dupe Quote Rate Plan still occurring
        Map<String, List<DateWrapper>> KeyAndDateWrapperMap = new map<String, List<DateWrapper>>();
        Map<String, Date> subscriptionZuoraIdCancelDateMap = new map<String, Date>();
        Map<String, DateWrapper> amendPRPNameWrapperMap = new map<String, DateWrapper>();
        Set<String> subscriptionZuoraIdSet = new Set<String>();
        Date currentQRPStarDate;
        Date currentQRPEndDate;

        for (QuotesWrapper qw : oqw.quotesWrapperList) {
            // skip non-Internet QuoteWrappers
            if (qw.quoteProductLine != 'Internet') {
                continue;
            }
            //CSP-2901 Instance of Dupe Quote Rate Plan still occurring
            //Stroe Cancel Subscription zuora id if we want cancel subscription for query charge
            if(qw.quote.zqu__SubscriptionType__c == 'Cancel Subscription'
                && String.isNotBlank(qw.quote.zqu__ExistSubscriptionID__c)) {

                //Add Zuora Subscription ID for query subscription charge
                subscriptionZuoraIdSet.add(qw.quote.zqu__ExistSubscriptionID__c);
                //store which subscription and cancel date
                subscriptionZuoraIdCancelDateMap.put(qw.quote.zqu__ExistSubscriptionID__c, qw.quote.zqu__CancellationDate__c);
            }

            for (zqu__QuoteRatePlan__c qrp : qw.quoteRatePlanMap.values()) {


                 String keyString;
                // skip null QuoteRatePlans with a null Location_Vendor__c value (aka Location isn't required for this QuoteRatePlan) and don't skip RemoveProduct QRP
                // CSP-2901 Instance of Dupe Quote Rate Plan still occurring
                // skip cloned QuoteRatePlans for csp-2898 Switch Pitch  
                if ((qrp.Location_Vendor__c == null && qrp.zqu__AmendmentType__c != 'RemoveProduct') 
                    || qrp.Is_Clone__c) {
                    continue;
                }
                //CSP-2901 Instance of Dupe Quote Rate Plan still occurring
                //Get Quote Rate Plan start date and end data 
                //Product Rate Plan Name + & + Dynamics ID as key string
                if(qrp.Location_Vendor__c != null) {
                    keyString = qrp.zqu__ProductRatePlan__r.Name + label.String_Split_Sign + qrp.Location_Vendor__r.DynamicsAccID__c;

                    if(!KeyAndDateWrapperMap.containsKey(keyString)) {
                        KeyAndDateWrapperMap.put(keyString, new List<DateWrapper>());
                    } 
                }

                // New Subscription and New Quote
                if(qrp.zqu__Quote__r.zqu__SubscriptionType__c == 'New Subscription' ) {

                    currentQRPStarDate = qrp.zqu__Quote__r.zqu__TermStartDate__c;
                    currentQRPEndDate = currentQRPStarDate.addMonths(Integer.valueOf(qrp.zqu__Quote__r.zqu__InitialTerm__c));
                }
                // Amend Subscription and Add product
                else if(qrp.zqu__Quote__r.zqu__SubscriptionType__c == 'Amend Subscription'
                    && qrp.zqu__AmendmentType__c == 'NewProduct'
                    && qrp.zqu__Quote__r.zqu__SubscriptionTermEndDate__c != null
                    && String.isNotBlank(qrp.zqu__Quote__r.zqu__ExistSubscriptionID__c)) {

                    currentQRPStarDate = qrp.zqu__Quote__r.zqu__Service_Activation_Date__c;
                    currentQRPEndDate = qrp.zqu__Quote__r.zqu__SubscriptionTermEndDate__c;

                    //Add Zuora Subscription ID for query subscription charge
                    subscriptionZuoraIdSet.add(qrp.zqu__Quote__r.zqu__ExistSubscriptionID__c);
                }
                // Amend Subscription and removed Product
                else if(qrp.zqu__Quote__r.zqu__SubscriptionType__c == 'Amend Subscription'
                    && qrp.zqu__AmendmentType__c == 'RemoveProduct') {

                    currentQRPStarDate = qrp.zqu__Quote__r.zqu__SubscriptionTermStartDate__c;
                    currentQRPEndDate = qrp.zqu__Quote__r.zqu__Service_Activation_Date__c;
                    amendPRPNameWrapperMap.put(qrp.zqu__ProductRatePlan__r.Name, new DateWrapper(currentQRPStarDate, currentQRPEndDate));
                    //Add Zuora Subscription ID for query subscription charge
                    subscriptionZuoraIdSet.add(qrp.zqu__Quote__r.zqu__ExistSubscriptionID__c);
                }

                if(qrp.Location_Vendor__c != null) {
                    DateWrapper wrap = new DateWrapper(currentQRPStarDate, currentQRPEndDate); 
                    KeyAndDateWrapperMap.get(keyString).add(wrap);
                }
               
            }
        }
        System.debug(LoggingLevel.INFO, '*** KeyAndDateWrapperMap1: ' + KeyAndDateWrapperMap);
        //CSP-2901 Instance of Dupe Quote Rate Plan still occurring
        //Get cancel Subscription Product Charge and new product rate plan start date and end data 
        if(!subscriptionZuoraIdSet.isEmpty()) {
            for(Zuora__SubscriptionProductCharge__c currentSPC : [SELECT Id, Zuora__RatePlanName__c, Zuora__EffectiveStartDate__c, Zuora__EffectiveEndDate__c, 
                                                                         Zuora__Account__c, LocationVendorDynamicsAccountID__c, Zuora__Subscription__r.Zuora__External_Id__c 
                                                                    FROM Zuora__SubscriptionProductCharge__c 
                                                                    WHERE Zuora__Subscription__r.Zuora__External_Id__c IN : subscriptionZuoraIdSet]) {

                // Product Rate Plan Name + & + Dynamics ID as key string
                String keyString = currentSPC.Zuora__RatePlanName__c + label.String_Split_Sign + currentSPC.LocationVendorDynamicsAccountID__c;

                if(!KeyAndDateWrapperMap.containsKey(keyString)) {
                   KeyAndDateWrapperMap.put(keyString, new List<DateWrapper>());
                }
                
                Date startDate; 
                Date endDate;
                //Get cancel of date from quote info if Subscription Type is Cancel Subscription
                Date cancelDate = subscriptionZuoraIdCancelDateMap.get(currentSPC.Zuora__Subscription__r.Zuora__External_Id__c);
                Date effectiveStartDate = currentSPC.Zuora__EffectiveStartDate__c;
                Date effectiveEndDate = currentSPC.Zuora__EffectiveEndDate__c;
                // get Sub charge  service period when Cancel Subscription 
                if(cancelDate != null) {
                    //Get Sub Charge date period when Cancel subscription within the service time
                    if(cancelDate >= effectiveStartDate && cancelDate <= effectiveEndDate) {
                        startDate = effectiveStartDate;
                        endDate = cancelDate;
                    }
                    //Skip this Sub charge into map when Cancel the subscription before the service starts
                    else if(cancelDate < effectiveStartDate) {
                        continue;
                    }
                    //Get Sub Charge date period when Cancel the subscription after the service Ends
                    else if(cancelDate > effectiveEndDate) {
                        startDate = effectiveStartDate;
                        endDate = effectiveEndDate;
                    }
                }
                // Get Sub Charge service period when amend-remove product rate plan.
                else if(amendPRPNameWrapperMap.keySet().contains(currentSPC.Zuora__RatePlanName__c)) {
                    //Get corresponding service period by remove product Service Activation Date
                    //Because Switch Pitch (CSP-2898) has two Sub Charge the same name of Product Rate Plan
                    Date removeSubDate = amendPRPNameWrapperMap.get(currentSPC.Zuora__RatePlanName__c).endDate;
                    if(removeSubDate >= effectiveStartDate && removeSubDate <= effectiveEndDate) {
                        startDate = effectiveStartDate;
                        endDate = removeSubDate;
                    }
                    else{
                        startDate = effectiveStartDate; 
                        endDate = effectiveEndDate;
                    }
                }
                //Get Sub Charge service period when new product rate plan under amend quote
                else {
                    startDate = effectiveStartDate; 
                    endDate = effectiveEndDate;
                }
                
                DateWrapper wrap = new DateWrapper(startDate, endDate); 
                KeyAndDateWrapperMap.get(keyString).add(wrap); 
            }
        }
        System.debug(LoggingLevel.INFO, '*** KeyAndDateWrapperMap2: ' + KeyAndDateWrapperMap);

        //CSP-2901 Instance of Dupe Quote Rate Plan still occurring
        //loop all wrapper to validation time is overlap or not 
        for(String keyStr : KeyAndDateWrapperMap.keySet()) {
          for(Integer i = 0; i < KeyAndDateWrapperMap.get(keyStr).size(); i++ ) {
            
            DateWrapper DateWrapper1 = KeyAndDateWrapperMap.get(keyStr)[i];
            for(Integer j = i+1; j < KeyAndDateWrapperMap.get(keyStr).size(); j++ ) {

              DateWrapper DateWrapper2 = KeyAndDateWrapperMap.get(keyStr)[j];
              //Validation date is overlap and put rate plan name in set
              if(DateWrapper1 != null && DateWrapper2 != null 
                && DateUtility.isOverlapDate(DateWrapper1.startDate, DateWrapper1.endDate, DateWrapper2.startDate, DateWrapper2.endDate)) {

                duplicateProductRatePlanNameSet.add(keyStr.split(label.String_Split_Sign)[0]); 
              }
            }
          }   
        }

        //There is duplicate porduct rate plan will auto reject approval 
        for (String duplicateProductRatePlanName : duplicateProductRatePlanNameSet) {
            oqw.reasonsForAutoreject += '\nDuplicate QuoteRatePlans were found for ' + duplicateProductRatePlanName + ', please either remove or update to a different Location.';
        }
        return oqw;
    }


    /**
     *   CSP-2094 | "runNewElectronicPaymentBillingAccountValidation" checks to make sure a credit card or ACH info was entered during 
     *   the Q2C workflow for new Billing Accounts designated as having an electronic payment method. A Quote can end up in this state
     *   if users start to create a Quote, but then exit prior to entering the electronic payment information.
     *
     *   @author Jonathan Satterfield
     *   @date   2017-04-18
     *   @param  {OpportunityQuotesWrapper}
     *   @return {OpportunityQuotesWrapper}
     */
    public static OpportunityQuotesWrapper runNewElectronicPaymentBillingAccountValidation(OpportunityQuotesWrapper oqw) {
        Set<Id> ccBillingAccountValidationIdSet = new Set<Id>();
        for (QuotesWrapper qw : oqw.quotesWrapperList) {
            // if all these criteria are true, the user will need to go back and enter a credit card in the Q2C workflow
            if ((qw.quote.zqu__PaymentMethod__c == 'Credit Card' || qw.quote.zqu__PaymentMethod__c == 'ACH')
                && qw.quote.zqu__SubscriptionType__c == 'New Subscription'
                && String.isBlank(qw.quote.zqu__ElectronicPaymentMethodId__c)
                && String.isBlank(qw.quote.zqu__ZuoraAccountID__c)) {

                ccBillingAccountValidationIdSet.add(qw.quoteId);
            }
        }

        for (Id missingCCQuoteId : ccBillingAccountValidationIdSet) {
            oqw.reasonsForAutoreject += '\nThe Quote with ID ' + (String)missingCCQuoteId + ' requires an electronic payment method; please go back to the Quote and re-enter payment information.';
        }

        return oqw;
    }


    public static List<zqu__QuoteRatePlan__c> evaluateTwoXProductsAndReturnQRPWarningList(Map<String, List<TwoXWrapper>> mainMap) {

        Map<String, List<TwoXWrapper>> holdMap = new Map<String, List<TwoXWrapper>>();
        List<zqu__QuoteRatePlan__c> qrpWarningList = new List<zqu__QuoteRatePlan__c>();

        while (!mainMap.isEmpty() || !holdMap.isEmpty()) {

            if (mainMap.isEmpty() && !holdMap.isEmpty()) {
                mainMap.putAll(holdMap);
                holdMap.clear();
            }

            for (String mapKey : mainMap.keySet()) {

                List<TwoXWrapper> tempTXWList = mainMap.get(mapKey);
                TwoXWrapper txwRecord;

                // first make sure a value was found in the map
                if (tempTXWList == null) {
                    break;
                }
                // check the size of the list; if it's 1, remove the key-value pair from the map
                // otherwise, just remove the wrapper instance from the list and put the updated list back in the mainMap
                else if (tempTXWList.size() == 1) {
                    txwRecord = tempTXWList[0];
                    mainMap.remove(mapKey);
                }
                else {
                    txwRecord = tempTXWList.remove(0);
                    mainMap.put(mapKey, tempTXWList);
                }

                // reasons to add to qrpWarningList
                if ((!mainMap.containsKey(txwRecord.previousWrapperKey) && !mainMap.containsKey(txwRecord.nextWrapperKey)) &&
                    (!holdMap.containsKey(txwRecord.previousWrapperKey) && !holdMap.containsKey(txwRecord.nextWrapperKey))) {
                    qrpWarningList.add(txwRecord.qrpRecord);
                    break;
                }

                // reasons to move from mainMap to holdMap (a.k.a. both previousWrapperKey and nextWrapperKey are in a map)
                if ((mainMap.containsKey(txwRecord.previousWrapperKey) && mainMap.containsKey(txwRecord.nextWrapperKey)) ||
                    (holdMap.containsKey(txwRecord.previousWrapperKey) && holdMap.containsKey(txwRecord.nextWrapperKey)) ||
                    (mainMap.containsKey(txwRecord.previousWrapperKey) && holdMap.containsKey(txwRecord.nextWrapperKey)) ||
                    (holdMap.containsKey(txwRecord.previousWrapperKey) && mainMap.containsKey(txwRecord.nextWrapperKey))) {

                    // check to see if key is already in holdMap; if yes, add to existing list and update holdMap
                    // otherwise create new list and add to holdMap
                    List<TwoXWrapper> tempListForHoldMap;
                    if (holdMap.containsKey(mapKey)) {
                        tempListForHoldMap = holdMap.get(mapKey);
                    }
                    else {
                        tempListForHoldMap = new List<TwoXWrapper>();
                    }
                    tempListForHoldMap.add(txwRecord);
                    holdMap.put(mapKey, tempListForHoldMap);
                    break;
                }

                // reasons to remove values from mainMap and/or holdMap (a.k.a. either previousWrapperKey or nextWrapperKey is in a map)
                // because logic is the same for all, first figure out the map and key combo, then perform logic
                Map<String, List<TwoXWrapper>> mapReference;
                String keyString;
                if (mainMap.containsKey(txwRecord.previousWrapperKey)) {
                    mapReference = mainMap;
                    keyString = txwRecord.previousWrapperKey;
                }
                else if (mainMap.containsKey(txwRecord.nextWrapperKey)) {
                    mapReference = mainMap;
                    keyString = txwRecord.nextWrapperKey;
                }
                else if (holdMap.containsKey(txwRecord.previousWrapperKey)) {
                    mapReference = holdMap;
                    keyString = txwRecord.previousWrapperKey;
                }
                else if (holdMap.containsKey(txwRecord.nextWrapperKey)) {
                    mapReference = holdMap;
                    keyString = txwRecord.nextWrapperKey;
                }
                else {
                    // if somehow we get here, something went REALLY wrong, so add to qrpWarningList
                    // then explictly exit the FOR loop
                    qrpWarningList.add(txwRecord.qrpRecord);
                    break;
                }

                tempTXWList = mapReference.get(keyString);

                // check the size of the list; if it's 1, remove the key-value pair from the map
                // otherwise, just remove the wrapper instance from the list and put the updated list back in the mainMap
                if (tempTXWList.size() == 1) {
                    mapReference.remove(keyString);
                }
                else {
                    txwRecord = tempTXWList.remove(0);
                    mapReference.put(keyString, tempTXWList);
                }
            }
        }

        return qrpWarningList;
    }


    public static OpportunityQuotesWrapper generateOpportunityQuotesWrapper(Opportunity opp, List<zqu__QuoteRatePlan__c> qrpList) {
        // temporary map used to tie together the two query results
        // Key: ID of Quote | Value: QuotesWrapper instance
        Map<Id, QuotesWrapper> tempMap = new Map<Id, QuotesWrapper>();

        for (zqu__Quote__c qr : opp.zqu__Quotes__r) {
            QuotesWrapper qw = new QuotesWrapper();
            qw.quote = qr;
            qw.quoteId = qr.Id;
            qw.quoteProductLine = qr.Product_Line__c;
            qw.quoteSubscriptionType = qr.zqu__SubscriptionType__c;
            tempMap.put(qr.Id, qw);
        }

        for (zqu__QuoteRatePlan__c qrp : qrpList) {
            QuotesWrapper qWrap = tempMap.get(qrp.zqu__Quote__c);
            qWrap.quoteRatePlanChargeListMap.put(qrp.Id, qrp.zqu__Quote_Rate_Plan_Charges__r);
            qWrap.quoteRatePlanMap.put(qrp.Id, qrp);
        }

        OpportunityQuotesWrapper oqw = new OpportunityQuotesWrapper();
        oqw.opp = opp;
        oqw.quotesWrapperList = tempMap.values();

        // default these fields to empty/False; if necessary, they'll be updated in the "UPDATE OPPORTUNITY RECORD"
        // section of the main evaluateOpportunity method above
        oqw.opp.Approval_Process_Info_For_Approver__c = '';
        oqw.opp.Approval_Process_Flag_Autoreject__c = False;
        oqw.opp.Approval_Process_Flag_Manager_Approval__c = False;        
        oqw.opp.Approval_Process_Flag_Cancel_Approval__c = False;

        //CSP-3010 cancel subscription should auto-approve even if account is past due 
        //Add two flag for remove prodcut and add product approval 
        oqw.opp.Approval_Process_Flag_Remove_Approval__c = False;
        oqw.opp.Approval_Process_Flag_Add_Approval__c = False;

        return oqw;
    }


    public static Map<String, List<TwoXWrapper>> generateTwoXWrapperMap(List<zqu__QuoteRatePlan__c> qrpList) {

        Map<String, List<TwoXWrapper>> wrapperKeyToTwoXWrapperMap = new Map<String, List<TwoXWrapper>>();

        // create wrapper records and populate map
        for (zqu__QuoteRatePlan__c qrpRecord : qrpList) {

            TwoXWrapper txw = new TwoXWrapper(qrpRecord);

            // if map contains key, get and update list
            if (wrapperKeyToTwoXWrapperMap.containsKey(txw.wrapperKey)) {
                List<TwoXWrapper> tempListForWrapperKeyToTwoXWrapperMap = wrapperKeyToTwoXWrapperMap.get(txw.wrapperKey);
                tempListForWrapperKeyToTwoXWrapperMap.add(txw);
                wrapperKeyToTwoXWrapperMap.put(txw.wrapperKey, tempListForWrapperKeyToTwoXWrapperMap);
            }
            // otherwise create new list and add to map
            else {
                List<TwoXWrapper> newListForWrapperKeyToTwoXWrapperMap = new List<TwoXWrapper>();
                newListForWrapperKeyToTwoXWrapperMap.add(txw);
                wrapperKeyToTwoXWrapperMap.put(txw.wrapperKey, newListForWrapperKeyToTwoXWrapperMap);
            }
        }

        return wrapperKeyToTwoXWrapperMap;
    }


    public class OpportunityQuotesWrapper {
        
        public Opportunity opp;
        public List<QuotesWrapper> quotesWrapperList;

        // whenever you append a string to reasonsForAutoreject, reasonsForManagerApproval, or reasonsForCancellationApproval,
        // be sure to always start with a newline symbol (e.g. "\n")
        public String reasonsForAutoreject;
        public String reasonsForManagerApproval;
        public String reasonsForCancellationApproval;
        //CSP-3010 cancel subscription should auto-approve even if account is past due
        public String reasonsForRemoveApproval;
        public String reasonsForAddOrUpdateApproval;

        public OpportunityQuotesWrapper() {
            this.quotesWrapperList = new List<QuotesWrapper>();
            this.reasonsForAutoreject = '### REASONS FOR AUTOREJECT ###';
            this.reasonsForManagerApproval = '### REASONS FOR MANAGER APPROVAL ###';
            this.reasonsForCancellationApproval = '### REASONS FOR CANCELLATION APPROVAL ###';
            //CSP-3010 cancel subscription should auto-approve even if account is past due
            this.reasonsForRemoveApproval = '### REASONS FOR REMOVE APPROVAL ###';
            this.reasonsForAddOrUpdateApproval = '### REASONS FOR ADD/UPDATE APPROVAL ###';
        }
    }


    public class QuotesWrapper {

        public zqu__Quote__c quote;
        public Id quoteId;
        public String quoteProductLine;
        public String quoteSubscriptionType;

        // Key: ID of QuoteRatePlan | Value: QuoteRatePlan record
        public Map<Id, zqu__QuoteRatePlan__c> quoteRatePlanMap;

        // Key: ID of parent QuoteRatePlan | Value: list of QuoteRatePlanCharge records
        public Map<Id, List<zqu__QuoteRatePlanCharge__c>> quoteRatePlanChargeListMap;

        public QuotesWrapper() {
            this.quoteRatePlanMap = new Map<Id, zqu__QuoteRatePlan__c>();
            this.quoteRatePlanChargeListMap = new Map<Id, List<zqu__QuoteRatePlanCharge__c>>();
        }
    }


    public class TwoXWrapper {

        public zqu__QuoteRatePlan__c qrpRecord;
        public String wrapperKey;
        public String previousWrapperKey;
        public String nextWrapperKey;

        public TwoXWrapper(zqu__QuoteRatePlan__c qrpRecord) {
            this.qrpRecord = qrpRecord;
            this.wrapperKey = qrpRecord.zqu__QuoteProductName__c + String.valueOf(qrpRecord.Print_Issue__c).left(15);
            if (!String.isBlank(qrpRecord.Print_Issue_Previous_Issue_ID__c)) {
                this.previousWrapperKey = qrpRecord.zqu__QuoteProductName__c + String.valueOf(qrpRecord.Print_Issue_Previous_Issue_ID__c);
            }
            if (!String.isBlank(qrpRecord.Print_Issue_Next_Issue_ID__c)) {
                this.nextWrapperKey = qrpRecord.zqu__QuoteProductName__c + String.valueOf(qrpRecord.Print_Issue_Next_Issue_ID__c);
            }       
        }
    }

    //CSP-2901 Instance of Dupe Quote Rate Plan still occurring
    //Store startDate and endDate
    public class DateWrapper {
      Date startDate;
      Date endDate;

      public DateWrapper(Date startDate, Date endDate) {
        this.startDate = startDate;
        this.endDate = endDate;
      }
    }
}