public without sharing class ZProductTriggerHandler implements XOTrigger {
    ////////////////////////
    // Instance Variables //
    ////////////////////////

    // CSP-2036 | delete "deleted" ZProducts after sync
    private Set<Id> deleteZProductIdSet = new Set<Id>();

    /**
    *   Method used to bulkify all data needed in any "before" action of a trigger.
    */
    public void bulkBefore() {

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
        zqu__ZProduct__c zProductRec = (zqu__ZProduct__c)so;
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
        zqu__ZProduct__c zProductRec = (zqu__ZProduct__c)so;
        zqu__ZProduct__c oldZProductRec = (zqu__ZProduct__c)oldSo;
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
        zqu__ZProduct__c zProductRec = (zqu__ZProduct__c)so;

        // CSP-2036 | delete "deleted" ZProducts after sync
        if (zProductRec.zqu__Deleted__c) {
            deleteZProductIdSet.add(zProductRec.Id);
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
        zqu__ZProduct__c zProductRec = (zqu__ZProduct__c)so;
        zqu__ZProduct__c oldZProductRec = (zqu__ZProduct__c)oldSo;

        // CSP-2036 | delete "deleted" ZProducts after sync
        if (zProductRec.zqu__Deleted__c) {
            deleteZProductIdSet.add(zProductRec.Id);
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
        // CSP-2036 | delete "deleted" ZProducts after sync
        if (deleteZProductIdSet.size() > 0) {
            deleteZProducts(deleteZProductIdSet);
        }
    }

    //////////////////////////
    // CUSTOM METHODS BELOW //
    //////////////////////////
    
    /**
     *   "deleteZProducts" deletes ZProducts where zqu__Deleted__c == true after they are synced
     *   down from Zuora. Previously there was a validation rule preventing these records from
     *   being inserted, but experience has shown us that validation rules cause all kinds of
     *   issues with the Zuora Sync.
     *
     *   @author Jonathan Satterfield
     *   @date   2017-04-05
     *   @param  {Set<Id>}
     */
    @future
    private static void deleteZProducts(Set<Id> deleteZProductIdSet) {
        List<zqu__ZProduct__c> deleteList = [SELECT Id FROM zqu__ZProduct__c WHERE Id IN :deleteZProductIdSet];
        if (deleteList.isEmpty()) {
            return;
        }
        Database.DeleteResult[] dbDeleteResult = Database.delete(deleteList, false);
        List<XO_Exception__c> xoExceptionList = ExceptionUtility.consumeException(dbDeleteResult);
        if (xoExceptionList.size() > 0) {
            insert xoExceptionList;
        }       
    }
}