// Be sure to add the "implements InterfaceClass" that will implement
// the interface class.
// Eg. public without sharing class {{ api_name }} implements InterfaceClass {
public without sharing class InventoryTriggerHandler implements XOTrigger {
    ////////////////////////
    // Instance Variables //
    ////////////////////////

    // CSP-919 instance variables
    Set<Id> subscriptionProductChargeIdSet = new Set<Id>();
    Map<Id,Zuora__SubscriptionProductCharge__c> subscriptionProductChargeMap = new Map<Id,Zuora__SubscriptionProductCharge__c>();
    Set<Id> renewalSubscriptionProductRatePlanIdSet = new Set<Id>();
    // CSP-1796 | delete newly inserted Inventory records if they are marked as "Available"
    Set<Id> inventoryToDeleteIdSet = new Set<Id>();

    /**
    *   Method used to bulkify all data needed in any "before" action of a trigger.
    */
    public void bulkBefore() {
        if (Trigger.isInsert) {
            subscriptionProductChargeIdSet = populateSubscriptionProductChargeIdSet(Trigger.new, subscriptionProductChargeIdSet);
        }
        if (Trigger.isUpdate) {
            subscriptionProductChargeIdSet = populateSubscriptionProductChargeIdSet(Trigger.new, Trigger.oldMap, subscriptionProductChargeIdSet);
        }
        // CSP-919 | populate the subscriptionProductChargeMap
        if (!subscriptionProductChargeIdSet.isEmpty()) {
            subscriptionProductChargeMap = new Map<Id,Zuora__SubscriptionProductCharge__c>([SELECT Id, Zuora__Subscription__r.Name, Zuora__Subscription__r.Zuora__Version__c FROM Zuora__SubscriptionProductCharge__c WHERE Id IN :subscriptionProductChargeIdSet]);
        }
    }

    /**
    *   Method used to bulkify all data needed in any "after" action of a trigger.
    */
    public void bulkAfter() {

    }

    /**
    *   All before insert logic should be done here. This method is called iteratively and as such
    *   should contain no actions which could potentially hit limits or is considered bad practice 
    *   in the Salesforce environment.
    *   
    *   @param  {SObject}   so Single SObject representation of the object being acted upon.
    */
    public void beforeInsert(SObject so) {
        Inventory__c invRec = (Inventory__c)so;
        renewalSubscriptionProductRatePlanIdSet = populateSubscriptionInfoAndDetermineIfRenewal(invRec, subscriptionProductChargeMap, renewalSubscriptionProductRatePlanIdSet);
    }

    /**
    *   All before update logic should be done here. This method is called iteratively and as such
    *   should contain no actions which could potentially hit limits or is considered bad practice
    *   in the Salesforce environment.
    *
    *   @param  {SObject}   oldSo Single SObject representation of the "old" copy of the current 
    *                             object being acted upon.
    *   @param  {SObject}   so    Single SObject representation of the object being acted upon.
    */
    public void beforeUpdate(SObject oldSo, SObject so) {
        Inventory__c invRec = (Inventory__c)so;
        Inventory__c oldInvRec = (Inventory__c)oldSo;
        renewalSubscriptionProductRatePlanIdSet = populateSubscriptionInfoAndDetermineIfRenewal(invRec, subscriptionProductChargeMap, renewalSubscriptionProductRatePlanIdSet);
    }

    /**
    *   All before delete logic should be done here. This method is called iteratively and as such
    *   should contain no actions which could potentilly hit limits or is considered bad practice
    *   in the Salesforce environment.
    *
    *   @param  {SObject}   so Single SObject representation of the object being acted upon.
    */
    public void beforeDelete(SObject so) {

    }

    /**
    *   All after insert logic should be done here. This method is called iteratively and as such
    *   should contain no actions which could potentilly hit limits or is considered bad practice
    *   in the Salesforce environment. 
    *
    *   @param  {SObject}   so Single SObject representation of the object being acted upon.
    */
    public void afterInsert(SObject so) {
    	Inventory__c invRec = (Inventory__c)so;

    	// CSP-1796 | delete newly inserted Inventory records if they are marked as "Available"
    	if (invRec.Available__c) {
    		inventoryToDeleteIdSet.add(invRec.Id);
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

    }

    /**
    *   All after delete logic should be done here. This method is called iteratively and as such
    *   should contain no actions which could potentilly hit limits or is considered bad practice
    *   in the Salesforce environment. 
    *
    *   @param  {SObject}   so Single SObject representation of the object being acted upon.
    */
    public void afterDelete(SObject so) {

    }

    /**
    *   All final logic in the "before" context should be done at this point such as modification to objects outside of
    *   the current object. At this point all updates to the current trigger transaction should be
    *   complete and all validation done.
    */
    public void beforeAndFinally() {
        // CSP-919 | this does NOT need to run during the BatchRebuildInventoryFromSubscriptions job as excess inventory will be automatically cleared
        // (future calls also can't be invoked from a batch or future call anyway)
        // so, don't call the removeExcessRenewalSubscriptionInventory future method during a batch or future call
        // ...we could get more granular by setting a static variable during the BatchRebuildInventoryFromSubscriptions job, but let's just cover all our bases
        // since we really only need to run this code during standard Subscription creation
        if (!renewalSubscriptionProductRatePlanIdSet.isEmpty() && !System.isBatch() && !System.isFuture()) {
            removeExcessRenewalSubscriptionInventory(renewalSubscriptionProductRatePlanIdSet);
        }
    }

    /**
    *   All final logic in the "after" context should be done at this point such as modification to objects outside of
    *   the current object. At this point all updates to the current trigger transaction should be
    *   complete and all validation done.
    */
    public void afterAndFinally() {
        // CSP-1796 | delete newly inserted Inventory records if they are marked as "Available"
        if (inventoryToDeleteIdSet.size() > 0 && !System.isFuture() && !System.isBatch()) {
        	deleteAvailableInventory(inventoryToDeleteIdSet);
        }
    }

    //////////////////////////
    // CUSTOM METHODS BELOW //
    //////////////////////////
    
    /**
     *   CSP-1796 | "deleteAvailableInventory" is a future method that deletes Inventory after being inserted into
     *   the database if the "Available__c" formula field evaluates to true.
     *
     *   @author Jonathan Satterfield
     *   @date   2017-02-03
     *   @param  {Set<Id>}
     */
    @future
    private static void deleteAvailableInventory(Set<Id> inventoryToDeleteIdSet) {
    	// populate a list of Inventory records to delete and then delete them
    	List<Inventory__c> inventoryDeleteList = new List<Inventory__c>();
    	for (Id inventoryId : inventoryToDeleteIdSet) {
    		inventoryDeleteList.add(new Inventory__c(Id = inventoryId));
    	}
		Database.DeleteResult[] dbDeleteResult = Database.delete(inventoryDeleteList, false);
		List<XO_Exception__c> xoExceptionList = ExceptionUtility.consumeException(dbDeleteResult);
		if (xoExceptionList.size() > 0) {
			insert xoExceptionList;
		}
    }


    // CSP-919 | method for populating the Subscription Product Charge Id set to be later used in a query that populates the subscriptionProductChargeMap
    private static Set<Id> populateSubscriptionProductChargeIdSet(List<Inventory__c> newList, Set<Id> subscriptionProductChargeIdSet) {
        for (Integer i = 0; i < newList.size(); i++) {
            Inventory__c newRec = newList[i];
            if (newRec.Subscription_Product_Charge__c != null) {
                subscriptionProductChargeIdSet.add(newRec.Subscription_Product_Charge__c);
            }
        }
        return subscriptionProductChargeIdSet;
    }


    // CSP-919 | overloaded method for populating the Subscription Product Charge Id set to be later used in a query that populates the subscriptionProductChargeMap
    private static Set<Id> populateSubscriptionProductChargeIdSet(List<Inventory__c> newList, Map<Id,SObject> oldMap, Set<Id> subscriptionProductChargeIdSet) {
        for (Integer i = 0; i < newList.size(); i++) {
            Inventory__c newRec = newList[i];
            Inventory__c oldRec = (Inventory__c)oldMap.get(newRec.Id);
            // only pass in records that meet the criteria below
            if (newRec.Subscription_Product_Charge__c != null && (newRec.Subscription_Product_Charge__c != oldRec.Subscription_Product_Charge__c || newRec.Subscription_Name__c != oldRec.Subscription_Name__c || newRec.Subscription_Version__c != oldRec.Subscription_Version__c)) {
                subscriptionProductChargeIdSet.add(newRec.Subscription_Product_Charge__c);
            }
        }
        return subscriptionProductChargeIdSet;
    }


    // CSP-919 | populates Subscription Name and Version on the Inventory Record, and if the Subscription isn't Version 1 add it to the renewalSubscriptionProductRatePlanIdSet
    private static Set<Id> populateSubscriptionInfoAndDetermineIfRenewal(Inventory__c invRec, Map<Id,Zuora__SubscriptionProductCharge__c> subscriptionProductChargeMap, Set<Id> renewalSubscriptionProductRatePlanIdSet) {
        if (String.isNotBlank(invRec.Subscription_Product_Charge__c) && subscriptionProductChargeMap.containsKey(invRec.Subscription_Product_Charge__c)) {
            Zuora__SubscriptionProductCharge__c spcRec = subscriptionProductChargeMap.get(invRec.Subscription_Product_Charge__c);
            invRec.Subscription_Name__c = spcRec.Zuora__Subscription__r.Name;
            invRec.Subscription_Version__c = spcRec.Zuora__Subscription__r.Zuora__Version__c;
            if (invRec.Subscription_Version__c > 1) {
                renewalSubscriptionProductRatePlanIdSet.add(invRec.Product_Rate_Plan__c);
            }
        }
        return renewalSubscriptionProductRatePlanIdSet;        
    }    


    // CSP-919 | remove "excess" inventory records that are leftover from a renewal subscription entering the system and creating new inventory 
    // both the new and the leftover inventory records will have the same Product Rate Plan and the same Subscription Name,
    // however the leftover record won't have a Subscription Product Charge lookup value and it's Subscription Version Number will be less the new record generated by the renewal
    @future
    public static void removeExcessRenewalSubscriptionInventory(Set<Id> renewalSubscriptionProductRatePlanIdSet) {

        List<Inventory__c> excessInventoryToDeleteList = new List<Inventory__c>();
        Map<String,List<Inventory__c>> subNameToExcessInventoryMap;

        // TODO: should i add sub version as a where clause also? at least need sub name to exclude inventory held by quotes / etc
        for (zqu__ProductRatePlan__c prpRec : [SELECT Id, (SELECT Id, Subscription_Product_Charge__c, Subscription_Name__c, Subscription_Version__c FROM Inventory__r WHERE Subscription_Name__c != null ORDER BY Subscription_Product_Charge__c NULLS FIRST) FROM zqu__ProductRatePlan__c WHERE Id IN :renewalSubscriptionProductRatePlanIdSet]) {
            
            // we need to reset this for each product rate plan to avoid incorrect matching
            // (Subscriptions can hold inventory across multiple Product Rate Plans, and even multiple inventory records within the same Product Rate Plan)
            subNameToExcessInventoryMap = new Map<String,List<Inventory__c>>();

            // only run the following logic if there are subscription-held inventory records w/o a subscription product charge lookup value 
            if (!prpRec.Inventory__r.isEmpty() && prpRec.Inventory__r[0].Subscription_Product_Charge__c == null) {
                for (Integer i = 0; i < prpRec.Inventory__r.size(); i++) {
                    Inventory__c invRec = prpRec.Inventory__r[i];
                    List<Inventory__c> invList;
                    // first populate lists of inventory records w/o a subscription product charge lookup value (a.k.a. excess inventory)
                    if (invRec.Subscription_Product_Charge__c == null) {
                        invList = subNameToExcessInventoryMap.containsKey(invRec.Subscription_Name__c) ? subNameToExcessInventoryMap.get(invRec.Subscription_Name__c) : new List<Inventory__c>();
                        invList.add(invRec);
                        subNameToExcessInventoryMap.put(invRec.Subscription_Name__c, invList);
                    }
                    // then determine if any these excess inventory fields should be deleted
                    else if (subNameToExcessInventoryMap.containsKey(invRec.Subscription_Name__c)) {
                        invList = subNameToExcessInventoryMap.get(invRec.Subscription_Name__c);
                        for (Integer n = 0; n < invList.size(); n++) {
                            Inventory__c excessInvRec = invList[n];
                            if (invRec.Subscription_Version__c > excessInvRec.Subscription_Version__c) {
                                excessInventoryToDeleteList.add(invList.remove(n));
                                // don't need to re-add invList to the map since it's a reference,
                                break;
                            }
                        }
                    }
                }
            }
        }
        if (!excessInventoryToDeleteList.isEmpty()) {
            Database.delete(excessInventoryToDeleteList, false);
        }
    }
}