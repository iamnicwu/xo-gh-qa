@istest(SeeallData = true)
public class TestSubscriptionProductChargeTotals{

    Static testmethod void insertSubProdCharge(){
       
       Test.startTest();
       
       Zuora__Subscription__c sub = new Zuora__Subscription__c();
       sub.Name = 'Subtest';
       sub.Zuora__Zuora_Id__c = 'zTest';
       sub.Zuora__TCV__c = 10000;
       sub.Zuora__MRR__c = 0;
       sub.GrossTotal__c = 20000;
       sub.DiscountTotal__c = 1000;
       sub.NetTotal__c = '10000';
       insert sub;
       
       Zuora__SubscriptionProductCharge__c spc = new Zuora__SubscriptionProductCharge__c ();
       spc.Name = 'SPCTest';
       spc.Zuora__Zuora_Id__c = 'ZTest';
       spc.Zuora__Subscription__c = sub.Id;
       spc.List_Price__c = '20000';
       spc.DiscountPrice__c = '10000';
       insert spc;
       
       update spc;
       
       delete spc;
           
       Test.stopTest();
    }

}