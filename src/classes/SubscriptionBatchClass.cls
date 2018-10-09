global class SubscriptionBatchClass implements Database.Batchable<sObject> {
    
	/* To run this from "execute anonymous":
	SubscriptionBatchClass b = new SubscriptionBatchClass();
	database.executebatch(b);
	*/

    global Database.QueryLocator start(Database.BatchableContext BC) {
        //Subscription_Batch_Process_Run_History__c lastRunTime = Subscription_Batch_Process_Run_History__c.getAll();
        
		Subscription_Batch_Process_Run_History__c lastRunTime;
        try {
        	lastRunTime = [select Name,Last_Successfully_Completed__c from  Subscription_Batch_Process_Run_History__c limit 1];
        }
        catch (Exception e) {
        	lastRunTime = new Subscription_Batch_Process_Run_History__c();
        	lastRunTime.Last_Successfully_Completed__c = System.now();
        	lastRunTime.Name = 'Initial';
        }        
        //system.debug('lastRunTime :'+lastRunTime);
        //system.debug('lastRunTime :'+system.today());
        
        // AKA Scope variable from below
        return Database.getQueryLocator([SELECT Id,Name,Zuora__account__c,Zuora__status__c,lastmodifiedDate,Zuora__SubscriptionEndDate__c FROM Zuora__Subscription__c where 
                                         (Zuora__status__c = 'Active' and lastmodifiedDate >= :lastRunTime.Last_Successfully_Completed__c) OR Zuora__SubscriptionEndDate__c = :Date.today() - 1]);
    }
   
    global void execute(Database.BatchableContext BC, List<Zuora__Subscription__c> Scope) {
        Set<ID> AccountIds = new Set<ID>();
        Set<ID> SubscriptionIds = new Set<ID>();
        for(Zuora__Subscription__c Sub : Scope){
            AccountIds.add(Sub.Zuora__account__c);
            SubscriptionIds.add(Sub.Id);
        }
        
        List<Account> accountList = [SELECT Id, ProductType__c, Local_Paid_Status__c, Local_Active__c, Active_Status_Change_Date__c, Inactive_Reason__c, (SELECT Id FROM Account.Zuora__Subscriptions__r) FROM Account WHERE Id IN :AccountIds];

        Set<Id> zsIDSet = new Set<Id>();
        for (Account a : accountList) {
            for (Zuora__Subscription__c zs : a.Zuora__Subscriptions__r) {
                zsIDSet.add(zs.Id);
            }
        }

        List<Zuora__Subscription__c> subscriptionList = [Select Id, Is_Expired__c, Zuora__Account__c, Zuora__Status__c, (SELECT Id, Product_Type__c FROM Zuora__Subscription__c.Zuora__Subscription_Product_Charges__r) FROM Zuora__Subscription__c WHERE Id IN :zsIDSet];

        // Map of Account Id to List of Zuora Subscriptions and Zuora Subscription Product Charges
        Map<Id,List<Zuora__Subscription__c>> accountIDToSubscriptionMap = new Map<Id,List<Zuora__Subscription__c>>();

        for (Zuora__Subscription__c sub : subscriptionList) {
            // if Account Id not already in Map, add Subscription to a List and then add to Map
            if (!accountIDToSubscriptionMap.containsKey(sub.Zuora__Account__c)) {
                List<Zuora__Subscription__c> newSubList = new List<Zuora__Subscription__c>();
                newSubList.add(sub);
                accountIDToSubscriptionMap.put(sub.Zuora__Account__c,newSubList);
            }
            // otherwise, get existing List from Map, add Subscription to it, and update Map
            else {
                List<Zuora__Subscription__c> existingSubList = accountIDToSubscriptionMap.get(sub.Zuora__Account__c);
                existingSubList.add(sub);
                accountIDToSubscriptionMap.put(sub.Zuora__Account__c,existingSubList);
            }
        }

        // Run logic to update the Account Local_Paid_Status__c (SF-613) and ProductType__c (SF-612) fields
        for (Account a : accountList) {
            if (accountIDToSubscriptionMap.containsKey(a.Id)) {
                List<Zuora__Subscription__c> subList = accountIDToSubscriptionMap.get(a.Id);
                // these Integer variables used to set Local_Paid_Status__c field on Account (SF-613)
                Integer numberOfExpiredLocalSubscriptionProductCharges = 0;
                Integer numberOfNonExpiredLocalSubscriptionProductCharges = 0;

                // this String Set is used to set the ProductType__c field on Account (SF-612)
                Set<String> productTypeStringSet = new Set<String>();

                for (Zuora__Subscription__c zuoraSub : subList) {
                    // first update the above Integer variable numberOfExpiredLocalSubscriptionProductCharges
                    // only need to know if at least one expired Local Subscription exists for SF-613 logic
                    if (zuoraSub.Is_Expired__c && numberOfExpiredLocalSubscriptionProductCharges == 0) {
                        for (Zuora__SubscriptionProductCharge__c zspc : zuoraSub.Zuora__Subscription_Product_Charges__r) {
                            // the way we determine if it's a "Local" Subscription is by making sure it has a Subscription Product Charge not equal to Concierge Venue
                            if (zspc.Product_Type__c != 'Concierge Venue') {
                                numberOfExpiredLocalSubscriptionProductCharges++;
                                break;
                            }
                        }
                    }
                    // then, we populate the productTypeStringSet as well as update the numberOfNonExpiredLocalSubscriptionProductCharges variable if applicable
                    // also, check to make sure the Subscription doesn't have a "Cancelled" status
                    else if (!zuoraSub.Is_Expired__c && zuoraSub.Zuora__Status__c == 'Active') {
                        for (Zuora__SubscriptionProductCharge__c zspc : zuoraSub.Zuora__Subscription_Product_Charges__r) {
                            if (zspc.Product_Type__c != 'Concierge Venue') {
                                numberOfNonExpiredLocalSubscriptionProductCharges++;
                            }
                            if (zspc.Product_Type__c != '' && zspc.Product_Type__c != null) {
                                productTypeStringSet.add(zspc.Product_Type__c);
                            }                           
                        }
                    }
                }

                // after the two Integer variables and the String Set from above are populated,
                // update Account fields as appropriate

                // first, set Local_Paid_Status__c field
                // if at least nonexpired Local Subscription exists, Local_Paid_Status__c = 'Paid'
                if (numberOfNonExpiredLocalSubscriptionProductCharges > 0) {
                    a.Local_Paid_Status__c = 'Paid';
                }
                // else, if at least one expired Local Subscription exists, Local_Paid_Status__c = 'Expired'
                else if (numberOfExpiredLocalSubscriptionProductCharges > 0) {
                    a.Local_Paid_Status__c = 'Expired';
                    // JPS Note 9-28-15: populating additional "Expired" information for SF-1302
                    a.Local_Active__c = False;
                    // Commented by Tony for ticket CSP-1232
                    //a.Active_Status_Change_Date__c = Datetime.now();
                    a.Inactive_Reason__c = 'Expired';
                }
                // otherwise, Local_Paid_Status__c = 'Unpaid' (this is the default value for new accounts also)
                else {
                    a.Local_Paid_Status__c = 'Unpaid';
                }

                //finally, set the Account.ProductType__c text field
                String productTypeString = '';
                for (String s : productTypeStringSet) {
                    productTypeString = productTypeString + s + '; ';
                }
                productTypeString = productTypeString.removeEnd('; ');
                a.ProductType__c = productTypeString;
            }
        }

        // perform update on accountList
        update accountList;
    }   
        
    global void finish(Database.BatchableContext BC) {
        //Subscription_Batch_Process_Run_History__c lastRunTime = Subscription_Batch_Process_Run_History__c.getInstance('Last Successfully Completed ');
		Subscription_Batch_Process_Run_History__c lastRunTime;
        try {
        	lastRunTime = [select Name,Last_Successfully_Completed__c from  Subscription_Batch_Process_Run_History__c limit 1];
        }
        catch (Exception e) {
        	lastRunTime = new Subscription_Batch_Process_Run_History__c();
        	lastRunTime.Last_Successfully_Completed__c = System.now();
        	lastRunTime.Name = 'Initial';
        }        
        
        lastRunTime.Last_Successfully_Completed__c = DateTime.now();
        upsert lastRunTime;
    } 
}