/* 
<trigger>
  <name>SubscriptionProductChargeTotals</name>
  <purpose>For calculating Gross Total, Discount Total and Net Total On a subscription</purpose>
  <created>
    <by>Om Vankayalapati</by>
    <date>7/17/2015</date>
    <ticket>SF-600</ticket>
  </created>
</trigger>
*/
trigger SubscriptionProductChargeTotals on Zuora__SubscriptionProductCharge__c (after insert, after update, after delete) 
{

 Set<Id> SubscriptionIds = new Set<Id>();
//Create New List to capture the Subscription Product charges
 List<Zuora__SubscriptionProductCharge__c> spcList = new List<Zuora__SubscriptionProductCharge__c>();
 Map<Id, List<Zuora__SubscriptionProductCharge__c>> subscriptionIdSPCListMap = new Map<Id, List<Zuora__SubscriptionProductCharge__c>>();
 List<Zuora__Subscription__c> sList = new List<Zuora__Subscription__c>();
 Map<Id, Double> subscriptionIdTotalGrossMap = new Map<Id, Double>();
 Map<Id, Double> subscriptionIdTotalDiscountMap = new Map<Id, Double>();
 //Before insert or Update 
    if(trigger.isinsert || trigger.isupdate){
        for(Zuora__SubscriptionProductCharge__c spc : trigger.New) {
            
                SubscriptionIds.add(spc.Zuora__Subscription__c);
        }
    }
    //If Trigger Deletes
    if(trigger.isdelete){
        for(Zuora__SubscriptionProductCharge__c spc : trigger.Old) {
            
                SubscriptionIds.add(spc.Zuora__Subscription__c);
        }
    }
    if(SubscriptionIds.size() > 0){
    
        // redux code starts here
        List<Zuora__Subscription__c> subList = [SELECT Id, GrossTotal__c, DiscountTotal__c, NetTotal__c, Zuora__TCV__c, Zuora__MRR__c, (SELECT Id, Gross_Total__c, Discount_Total__c FROM Zuora__Subscription_Product_Charges__r) FROM Zuora__Subscription__c WHERE ID IN : SubscriptionIds];
        system.debug('sublist====>'+sublist);
        for (Zuora__Subscription__c zSub : subList) {
            // temp Subscription financial variables
            Decimal tempGrossTotal = 0;
            Decimal tempDiscountTotal = 0;
            for (Zuora__SubscriptionProductCharge__c zSPC : zSub.Zuora__Subscription_Product_Charges__r) {
                if(zSPC.Gross_Total__c != Null){
                    tempGrossTotal = tempGrossTotal + zSPC.Gross_Total__c;
                }
                if(zSPC.Discount_Total__c != Null){
                    tempDiscountTotal = tempDiscountTotal + zSPC.Discount_Total__c;
                }
            }
            /*zSub.GrossTotal__c = String.valueof(tempGrossTotal);
            zSub.DiscountTotal__c = String.valueof(tempDiscountTotal); */     
            zSub.GrossTotal__c = tempGrossTotal;
            zSub.DiscountTotal__c = tempDiscountTotal;
        }
    
        update subList;
    
    }
}