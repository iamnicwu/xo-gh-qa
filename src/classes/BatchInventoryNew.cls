/* 
<Class>
<name>BatchInventory</name>
<purpose>For dealing with Inventory, making the slots available for the next account in the waitlist</purpose>
<created>
<by>Om Vankayalapati</by>
<date>09/03/2015</date>
<ticket>Generic - 1211_ Inventory Epic</ticket>
</created>
</Class>
*/
global class BatchInventoryNew implements Database.Batchable<sObject>{
    global Database.QueryLocator start(Database.BatchableContext BC){
        // Query to get All the Rate Plans
        // String query = 'SELECT Id,Name,Capacity__c,Available__c,Number_Available__c,Inventory_Held__c,Waitlist_Count__c,(Select Id,Account__c,Product_Rate_Plan__c FROM Waitlists__r ORDER BY Sort_Order__c) FROM zqu__ProductRatePlan__c WHERE Capacity__c != null';
        // CSP-3013 Waitlist Audit
        // For the waitlist audit, we only query the active waitlist to convert to Inventory.
        String query = 'SELECT '
                            + 'Id, '
                            + 'Name, '
                            + 'Capacity__c, '
                            + 'Available__c, '
                            + 'Number_Available__c, '
                            + 'Inventory_Held__c, '
                            + 'Waitlist_Count__c, '
                            + '(SELECT '
                                + 'Id, '
                                + 'Account__c, '
                                + 'Product_Rate_Plan__c, '
                                + 'Is_Active__c, '
                                + 'Inactive_Reason__c '
                              + 'FROM '
                                + 'Waitlists__r '
                              + 'WHERE '
                                + 'Is_Active__c = TRUE '
                                + 'ORDER BY Sort_Order__c) '
                        + 'FROM '
                            + 'zqu__ProductRatePlan__c '
                        + 'WHERE ' 
                            + 'Available__c = TRUE '
                        + 'AND '
                            + 'Waitlist_Count__c > 0';

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<zqu__ProductRatePlan__c> scope){
        //List for all Rate Plan Id's
        List<Id> rpIdList = new List<Id>();
        
        //List for getting all the inventories
        List<Inventory__c> invList = new List<Inventory__c>();
        
        //List for the Inventories that need to be updated
        List<Inventory__c> invupdateList = new List<Inventory__c>();
        
        List<String> subPList = new List<String>();
        
        //Inventory Delete List
        List<Inventory__c> invDelList = new List<Inventory__c>();
        
        //Map for Subscription Product Charges
        Map<String,Zuora__SubscriptionProductCharge__c> prodPlanMap = new Map<String,Zuora__SubscriptionProductCharge__c>();
        
        //List for subscription product charges
        List<Zuora__SubscriptionProductCharge__c> prodPList = new List<Zuora__SubscriptionProductCharge__c>();
        
        //List for getting all waitlists
        List<Waitlist__c> wList = new List<Waitlist__c>();
        
        DateTime myDateTime;
        String dayOfWeek = '';
        //Custom settings for Adding Business Days
        Inventory_Hold_Expiry_Date_Offsets__c invHoldExpDate = Inventory_Hold_Expiry_Date_Offsets__c.getOrgDefaults();
        
        // Map to hold the Inventory count
        Map<Id,Integer> prprInvCount = new Map<Id,Integer>();
        
        // map to hold the Waitlist Count
        Map<Id,Integer> prprWaitListCount = new Map<Id,Integer>();
        
        for(zqu__ProductRatePlan__c prp : scope){
            rpIdList.add(prp.Id);
        }
        
        for(zqu__ProductRatePlan__c prp : scope){
            if(prp.Capacity__c != NULL && prp.Inventory_Held__c != NULL)
                prprInvCount.put(prp.Id,Integer.valueOf(prp.Number_Available__c));
        }
        
        for(zqu__ProductRatePlan__c prp : scope){
            if(prp.Waitlist_Count__c != NULL)
                prprWaitListCount.put(prp.Id,Integer.valueOf(prp.Waitlist_Count__c));
        }
        
        String query = 'SELECT Id,Name,Product_Rate_Plan__c,Subscription_RatePlan_Id__c,Subscription_Product_Charge__c,Available__c,Waitlist_Account__c,Last_Expiry_Date_for_Account__c,Inventory_Hold_Expiry_Date__c FROM Inventory__c where Product_Rate_Plan__c IN: rpIdList';
        /* 
            steve - loop through all of the inventory for the rate plans in scope.
            if it's held by an account, Change the dates on the inventory record.
            OM- Done
        */
        invList = Database.Query(query);
        for(Inventory__c i : invList){
            if(i.Available__c == true){
                invDelList.add(i);
            }
            if(i.Waitlist_Account__c != NULL && i.Available__c != true){
                if(i.Last_Expiry_Date_for_Account__c == NULL){ 
                    invDelList.add(i); 
                    Integer count = prprInvCount.get(i.Product_Rate_Plan__c);
                    count = count+1;
                    prprInvCount.put(i.Product_Rate_Plan__c,count);
                    /* steve - you need a map where the prp is the key, and an integer is the value.  when you put an item in the invDelList, you need to increment the map for that PRP 
                    OM- Done*/
                    /* When the last expiration date is null, proceed with deletion. When ever it is not null, the inventory remains same. 
                    Om- Done*/
                }
                else{
                    i.Inventory_Hold_Expiry_Date__c = i.Last_Expiry_Date_for_Account__c;                
                    invupdateList.add(i);
                }
            } 
        }
        
        for(Inventory__c i : invList){
            /* steve - change this logic.
            check the record if it has a subscription rateplan ID but doesn't have a subscription rateplan, Then add it to the list
            OM-Done*/
            if((i.Subscription_Product_Charge__c == NULL) && (i.Subscription_RatePlan_Id__c != '' && i.Subscription_RatePlan_Id__c != NULL)){
                subPList.add(i.Subscription_RatePlan_Id__c);  
            }
        }
     
        /*
        steve - get the subscription rate plans from the db using subPList, repair as needed. I think this is actually ok, just verify once you put the above changes in that it works
        OM- Verified    */
        System.Debug('Whenever we find inventory that has a subscription product charge ID, but no corresponding lookup, discover if the charge was deleted or just updated.  If updated, fix the lookup and expiry date, if deleted, remove the inventory');
        prodPList = [Select Id,Name,Zuora__RatePlanId__c,Zuora__ChargeNumber__c,Zuora__RatePlanEffectiveEndDate__c from Zuora__SubscriptionProductCharge__c WHERE Zuora__ChargeNumber__c IN: subPList];
     
        for(Zuora__SubscriptionProductCharge__c p: prodPList){
            prodPlanMap.put(p.Zuora__ChargeNumber__c,p);
        }

        for(Inventory__c i : invList){
            if(i.Available__c == FALSE){
                if(prodPlanMap.get(i.Subscription_RatePlan_Id__c) != Null){

                    myDateTime = (DateTime)prodPlanMap.get(i.Subscription_RatePlan_Id__c).Zuora__RatePlanEffectiveEndDate__c;
                    if(myDateTime != NULL){
                        dayOfWeek = myDateTime.format('EEEE');
                    }
                    i.Subscription_Product_Charge__c = prodPlanMap.get(i.Subscription_RatePlan_Id__c).Id;
                    //Adding Business Days Logic-Date Utility Class
                    i.Inventory_Hold_Expiry_Date__c = DateUtility.AddBusinessDays(prodPlanMap.get(i.Subscription_RatePlan_Id__c).Zuora__RatePlanEffectiveEndDate__c,(Integer)invHoldExpDate.Subscription_Product_Charge_Day_Offset__c);
                }
                else{
                    i.Subscription_RatePlan_Id__c = '';
                }
            }   
        }
        
        update invList;
        
        delete invDelList;
        
        //Adding the waitlist to the inventory
        List<Inventory__c> invInsertList = new List<Inventory__c>();
        
        //Creating the waitlist delete List
        List<Waitlist__c> waitDelList = new List<Waitlist__c>();
        
        for(zqu__ProductRatePlan__c pr : scope){
            wList = new List<Waitlist__c>() ;                   
            
            if(prprWaitListCount.get(pr.Id) > 0){
                /* steve - use your prp deleted map to figure out if there really is capacity
                avaialableslots = Integer.valueOf(pr.Capacity__c) - Integer.valueOf(pr.Inventory_Held__c) + number deleted

                note: if this ends up being to risky or fragile, don't bother, the next batch will fix it in a minute
                OM- Done */
                //Checking out the available Inventory slots
                Integer availableSlots = prprInvCount.get(pr.Id);
                
                for(Waitlist__c wc: pr.Waitlists__r){
                    wList.add(wc);
                }
                
                //Iterating through and Updating the waitlist
                for (integer i = 0; i < availableSlots && i < wList.size(); i++){
                    Waitlist__c w = wList[i];
                    Inventory__c inv = new Inventory__c();
                    inv.Product_Rate_Plan__c = w.Product_Rate_Plan__c;
                    inv.Waitlist_Account__c = w.Account__c;
                    myDateTime = (DateTime)Date.today();
                    dayOfWeek = myDateTime.format('EEEE');
                    
                    //Adding Business Days Logic-Date Utility Class
                    inv.Inventory_Hold_Expiry_Date__c = DateUtility.AddBusinessDays(Date.today(),(Integer)invHoldExpDate.Account_Day_Offset__c);
                    invupdateList.add(inv);

                    // CSP-3013 Waitlist Audit 
                    // we marked the waitlist to inactive when it has been converted to inventory
                    w.Is_Active__c = FALSE;
                    w.InActive_Date__c = Date.today();
                    w.Inactive_Reason__c = 'Converted to Inventory';

                    waitDelList.add(w);
                    i++;
                }
            }
        }
        upsert invupdateList;

        // CSP-3013 Waitlist Audit
        // If the label Deleted_Converted_Waitlist set to "Yes", we delete the waitlist which has been converted to inventory
        String isDeleteWaitlist = Label.Deleted_Converted_Waitlist;
        if (isDeleteWaitlist.containsIgnoreCase('No')) {
            Database.Update(waitDelList, false);
        }
        // If the label Deleted_Converted_Waitlist set to "No", we delete the waitlist which has been converted to inventory
        else {
            Database.delete(waitDelList, false);
        }
    }

    global void finish(Database.BatchableContext BC){
    }
}
/* FYI- This is the Script to schedule the batch job, running for every 5 minutes- Just making sure that everything is in one place.
Execute this script in "Execute Anonymous" in developer console.
System.schedule('BatchInventory Job 0', '0 0 * * * ?', new BatchInventoryNewScheduledJob());
System.schedule('BatchInventory Job 5', '0 5 * * * ?', new BatchInventoryNewScheduledJob());
System.schedule('BatchInventory Job 10', '0 10 * * * ?', new BatchInventoryNewScheduledJob());
System.schedule('BatchInventory Job 15', '0 15 * * * ?', new BatchInventoryNewScheduledJob());
System.schedule('BatchInventory Job 20', '0 20 * * * ?', new BatchInventoryNewScheduledJob());
System.schedule('BatchInventory Job 25', '0 25 * * * ?', new BatchInventoryNewScheduledJob());
System.schedule('BatchInventory Job 30', '0 30 * * * ?', new BatchInventoryNewScheduledJob());
System.schedule('BatchInventory Job 35', '0 35 * * * ?', new BatchInventoryNewScheduledJob());
System.schedule('BatchInventory Job 40', '0 40 * * * ?', new BatchInventoryNewScheduledJob());
System.schedule('BatchInventory Job 45', '0 45 * * * ?', new BatchInventoryNewScheduledJob());
System.schedule('BatchInventory Job 50', '0 50 * * * ?', new BatchInventoryNewScheduledJob());
System.schedule('BatchInventory Job 55', '0 55 * * * ?', new BatchInventoryNewScheduledJob());

*/