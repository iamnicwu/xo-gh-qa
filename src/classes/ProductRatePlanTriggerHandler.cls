public without sharing class ProductRatePlanTriggerHandler implements XOTrigger {
    ////////////////////////
    // Instance Variables //
    ////////////////////////
    
    private static final Date DATE_TODAY = Date.today();
    // CSP-2036 | delete "expired" ProductRatePlans after sync
    private Set<Id> deletePRPIdSet = new Set<Id>();    

    // CSP-2658 Create new field called Rate_Plans_With_Capacity__c on Product2
    private List<Product2> updateProductList = new List<Product2>();
    private Set<Id> updateProductSet = new Set<Id>();

    //csp-2743
    private Set<Id> prpIdSet = new Set<Id>();

    /**
    *   Method used to bulkify all data needed in any "before" action of a trigger.
    */
    public void bulkBefore() {

    }

    /**
    *   Method used to bulkify all data needed in any "after" action of a trigger.
    */
    public void bulkAfter() {

        // CSP-2658 Create new field called Rate_Plans_With_Capacity__c on Product2
        // Get the update product list
        Integer capacity = 0;


        if(Trigger.isInsert || Trigger.isUpdate){


            System.debug(LoggingLevel.INFO, '*** Trigger.new: ' + Trigger.new);

            for(zqu__ProductRatePlan__c prp : (List<zqu__ProductRatePlan__c>)Trigger.new){
                
                capacity = String.isBlank(prp.Capacity__c) ? 0: Integer.valueOf(prp.Capacity__c);
                // if(!prp.zqu__Deleted__c){
                    
                // }
                updateProductSet.add(prp.zqu__Product__c);
            }
        }

        else if(Trigger.isDelete){

        System.debug(LoggingLevel.INFO, '*** Trigger.old: ' + Trigger.old);

            for(zqu__ProductRatePlan__c prp : (List<zqu__ProductRatePlan__c>)Trigger.old){
                
                capacity = String.isBlank(prp.Capacity__c) ? 0: Integer.valueOf(prp.Capacity__c);
                // if(!prp.zqu__Deleted__c){
                //     updateProductSet.add(prp.zqu__Product__c);
                // }
                updateProductSet.add(prp.zqu__Product__c);
            }
        }

        System.debug(LoggingLevel.INFO, '*** updateProductSet: ' + updateProductSet);

        // query all products from updated rate plan
        Map<Id, Product2> prodMap = new Map<Id, Product2>([SELECT Id, Rate_Plans_With_Capacity__c FROM Product2 WHERE Id IN: updateProductSet]);

        // query all the rate plans, and sum up the capacity from above products and group by productId
        AggregateResult[] rateplanAGResult = [SELECT zqu__Product__c, SUM(Capacity_in_num__c) capsum FROM zqu__ProductRatePlan__c 
                                                WHERE zqu__Product__c IN: prodMap.keySet() AND 
                                                zqu__Deleted__c = FALSE AND Capacity__c<>NULL 
                                                GROUP BY zqu__Product__c]; 

        if(!rateplanAGResult.isEmpty()){
            for(AggregateResult ar : rateplanAGResult){
                Product2 p = prodMap.get(String.valueOf(ar.get('zqu__Product__c')));
                p.Rate_Plans_With_Capacity__c = Decimal.valueOf(String.valueOf(ar.get('capsum')));
                System.debug(LoggingLevel.INFO, '*** p: ' + p);
                updateProductList.add(p);
            }
        }
        
    }

    /**
    *   All before insert logic should be done here. This method is called iteratively and as such
    *   should contain no actions which could potentially hit limits or is considered bad practice 
    *   in the Salesforce environment.
    *   
    *   @param  {SObject}   so Single SObject representation of the object being acted upon.
    */
    public void beforeInsert(SObject so) {
        zqu__ProductRatePlan__c prpRec = (zqu__ProductRatePlan__c)so;
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
        zqu__ProductRatePlan__c prpRec = (zqu__ProductRatePlan__c)so;
        zqu__ProductRatePlan__c oldPRPRec = (zqu__ProductRatePlan__c)oldSo;
    }

    /**
    *   All before delete logic should be done here. This method is called iteratively and as such
    *   should contain no actions which could potentilly hit limits or is considered bad practice
    *   in the Salesforce environment.
    *
    *   @param  {SObject}   so Single SObject representation of the object being acted upon.
    */
    public void beforeDelete(SObject so) {
        zqu__ProductRatePlan__c prpRec = (zqu__ProductRatePlan__c)so;

        if (prpRec.Inventory_Held__c > 0) {
            prpRec.addError('This record cannot be deleted because it has Inventory records attached to it.');
        }
        if (prpRec.Waitlist_Count__c > 0) {
            prpRec.addError('This record cannot be deleted because it has Waitlist records attached to it.');
        }
    }

    /**
    *   All after insert logic should be done here. This method is called iteratively and as such
    *   should contain no actions which could potentilly hit limits or is considered bad practice
    *   in the Salesforce environment. 
    *
    *   @param  {SObject}   so Single SObject representation of the object being acted upon.
    */
    public void afterInsert(SObject so) {
        zqu__ProductRatePlan__c prpRec = (zqu__ProductRatePlan__c)so;

        // CSP-2036 | delete "expired" ProductRatePlans after sync (after insert only)
        if (prpRec.zqu__EffectiveEndDate__c < DATE_TODAY) {
            deletePRPIdSet.add(prpRec.Id);
        }

        // csp-2743
        if(prpRec.Capacity__c != null) {
            prpIdSet.add(prpRec.Id);
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
        zqu__ProductRatePlan__c prpRec = (zqu__ProductRatePlan__c)so;
        zqu__ProductRatePlan__c oldPRPRec = (zqu__ProductRatePlan__c)oldSo;

        // csp-2743
        if(prpRec.Capacity__c != oldPRPRec.Capacity__c) {
            if(prpRec.Capacity__c != null) {
                prpIdSet.add(prpRec.Id);
            }
        }
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

    }

    /**
    *   All final logic in the "after" context should be done at this point such as modification to objects outside of
    *   the current object. At this point all updates to the current trigger transaction should be
    *   complete and all validation done.
    */
    public void afterAndFinally() {
        if (deletePRPIdSet.size() > 0) {
            //deleteProductRatePlans(deletePRPIdSet);
        }

        // CSP-2658 Create new field called Rate_Plans_With_Capacity__c on Product2
        if(!updateProductList.isEmpty()){
            System.debug(LoggingLevel.INFO, '*** updateProductList: ' + updateProductList);
            List<Database.SaveResult> saveResultsList = Database.update(updateProductList);
            List<XO_Exception__c> xoExceptionList = ExceptionUtility.consumeException(saveResultsList);
            if (!xoExceptionList.isEmpty()) {
              insert xoExceptionList;
            }         
        }

        // csp-2743
        if(prpIdSet.size() > 0) {
            if(System.IsBatch() == false && System.isFuture() == false){ 
                updateCapacityFieldInZuora(prpIdSet);
            }
        }
    }

    //////////////////////////
    // CUSTOM METHODS BELOW //
    //////////////////////////
    
    /**
     *   "deleteProductRatePlans" deletes expired Product Rate Plans after they are synced
     *   down from Zuora. Previously there was a validation rule preventing these records from
     *   being inserted, but experience has shown us that validation rules cause all kinds of
     *   issues with the Zuora Sync.
     *
     *   @author Jonathan Satterfield
     *   @date   2017-04-05
     *   @param  {Set<Id>}
     */
    //@future
    //private static void deleteProductRatePlans(Set<Id> deletePRPIdSet) {
    //    List<zqu__ProductRatePlan__c> deleteList = [SELECT Id FROM zqu__ProductRatePlan__c WHERE Id IN :deletePRPIdSet];
    //    if (deleteList.isEmpty()) {
    //        return;
    //    }
    //    Database.DeleteResult[] dbDeleteResult = Database.delete(deleteList, false);
    //    List<XO_Exception__c> xoExceptionList = ExceptionUtility.consumeException(dbDeleteResult);
    //    if (xoExceptionList.size() > 0) {
    //        insert xoExceptionList;
    //    }       
    //}

    /**
     *   CSP-2743: This method is used to update the Capacity field in Zuora every time the field 
     *   is updated in Salesforce. This helps us to make sure that both Salesforce and 
     *   Zuora have same values and that syncing of values from Zuora to Salesforce do not 
     *   update the values in Salesforce
     *
     *   @author Ruchit Sontakke
     *   @date   2018-03-16
     *   @param  {Set of Product Rate Plan records ids}
     */
    @future(callout=true)
    private static void updateCapacityFieldInZuora(Set<Id> prpRecSetId) {

        List<zqu__ProductRatePlan__c> updatePRPZuoraRecList = [SELECT Id, zqu__ZuoraId__c, Capacity__c  
                                                               FROM zqu__ProductRatePlan__c 
                                                               WHERE Id 
                                                               IN :prpRecSetId];
        if(updatePRPZuoraRecList.isEmpty()) {
            return;
        }

        List<Zuora.zObject> zObjPRPList = new List<Zuora.zObject>();
        Zuora.ZApi zApiInstance = new Zuora.ZApi();
        // skip the login call if this is a test
        if (!Test.isRunningTest()) {
            Zuora.zApi.LoginResult loginResult = zApiInstance.zlogin();
        
            for(zqu__ProductRatePlan__c productRatePlanRec : updatePRPZuoraRecList) {
                Zuora.zObject productRatePlanRecObj = new Zuora.zObject('ProductRatePlan');
                productRatePlanRecObj.setValue('Id', productRatePlanRec.zqu__ZuoraId__c);
                productRatePlanRecObj.setValue('Capacity__c',productRatePlanRec.Capacity__c);
                zObjPRPList.add(productRatePlanRecObj);
            }
            
            if(!zObjPRPList.isEmpty()) {
                List<Zuora.zApi.SaveResult> results = new List<Zuora.zApi.SaveResult>();
                
                if (!Test.isRunningTest()) {
                    try {
                        results.addAll(zApiInstance.zupdate(zObjPRPList));
                    } 
                    catch (Exception e) {
                        ExceptionUtility.consumeException(e, true);
                    }
                }
            }
        }
    }

    // CSP-2658 Create new field called Rate_Plans_With_Capacity__c on Product2
    private class RatePlanWrapper{
        private Id productId;
        private String capacity;
        private List<zqu__ProductRatePlan__c> rateplanList;
    }
}