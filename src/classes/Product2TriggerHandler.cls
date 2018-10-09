public without sharing class Product2TriggerHandler implements XOTrigger{
    ////////////////////////
    // Instance Variables //
    ////////////////////////

    // CSP-2036 | delete "deleted" Products after sync
    private Set<Id> deleteProductIdSet = new Set<Id>();

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
        Product2 productRec = (Product2)so;
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
        Product2 productRec = (Product2)so;
        Product2 oldproductRec = (Product2)oldSo;
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
        Product2 productRec = (Product2)so;

        // CSP-2036 | delete "deleted" Products after sync
        if (productRec.zqu__Deleted__c) {
            deleteProductIdSet.add(productRec.Id);
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
        Product2 productRec = (Product2)so;
        Product2 oldproductRec = (Product2)oldSo;

        // CSP-2036 | delete "deleted" Products after sync
        if (productRec.zqu__Deleted__c) {
            deleteProductIdSet.add(productRec.Id);
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
        if (deleteProductIdSet.size() > 0) {
            //deleteLocalProducts(deleteProductIdSet);
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
     *   Update by Ruchit: This method has been updated to delete Product2 records instead of ZProducts
     *   This was done as part of the Zuora Managed Upgrade process where products are now stored 
     *   in Salesforce standard product object instead of ZProduct    
     *
     *   @author Jonathan Satterfield
     *   @date   2017-04-05
     *   @param  {Set<Id>}
     */
    @future
    private static void deleteLocalProducts(Set<Id> deleteProductIdSet) {
        List<Product2> deleteList = [SELECT Id FROM Product2 WHERE Id IN :deleteProductIdSet];
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