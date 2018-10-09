public without sharing class BoomiCallouts {
    /**
     *   For CSP-1454
     *   Main function/method used to send fulfillment message to boomi.
     *   if the account's flage Enrolled_in_Transactions__c have been changed, the fulfillment message will be send to boomi.
     *   @author Tony Liu
     *   @date   2016-09-18   
     */
//     @future(callout=true)   
//     public static void boomiOrderCallout(Map<String,Boolean> tranAccountIdMap){
//         if(!XOGroupSettingUtility.getPartnerCalloutSetting()){
//             return;
//         }
//         Map<String,list<String>> dynamicIdMap  = new Map<String,list<String>>();
//         set<Id> accIdList = new set<Id>();
//         List<account> accList = [select id,DynamicsAccID__c,Enrolled_in_Transactions__c, ParentId, Ignore_Parent_Account__c from account where DynamicsAccID__c in: tranAccountIdMap.keySet()];
//         List<String> locationIdList = new List<String>();

//         Map<Id,String> subCompanyMap = new Map<Id,String>();
//         Map<Id,Id> subParentMap = new Map<Id,Id>();
        
//         for(account acc: accList){
//             if(acc.Ignore_Parent_Account__c || acc.ParentId==Null){
//                 subCompanyMap.put(acc.id,acc.DynamicsAccID__c);
//             }else{
//                 subParentMap.put(acc.ParentId,acc.Id);
//             }
//         }
        
//         while(!subParentMap.isEmpty()){
//             List<account>  parentAccList = [select id,DynamicsAccID__c,ParentId,Ignore_Parent_Account__c from Account where Id in: subParentMap.KeySet()];
//             for(account acc : parentAccList){
//                 if(acc.Ignore_Parent_Account__c || acc.ParentId == Null){
//                     subCompanyMap.put(subParentMap.get(acc.id),acc.DynamicsAccID__c);
//                     subParentMap.remove(acc.id);
//                 }else{
//                     subParentMap.put(acc.ParentId,subParentMap.get(acc.id));
//                     subParentMap.remove(acc.id); 
//                 }
//             }
//         }

//         ObjectWrapper owCancel = new ObjectWrapper();
//         ObjectWrapper owAdd = new ObjectWrapper();
//         Map<String,Transactions> tranMap  = new Map<String,Transactions>();
//         for (account record : accList) {
//             if (tranMap.containsKey(subCompanyMap.get(record.id))) {
//                 transactions tranW = tranMap.get(subCompanyMap.get(record.id));

//                 location lString = new location();
//                 lString.locationId = record.DynamicsAccID__c;
//                 tranW.locations.add(lString);

//                 tranMap.put(subCompanyMap.get(record.id), tranW);
//             }else{
//                 transactions tranW = new transactions();
//                 tranW.companyId = subCompanyMap.get(record.id);
//                 if (!record.Enrolled_in_Transactions__c) {
//                     tranW.transactionType = 'Cancel Transaction';
//                 }else{
//                     tranW.transactionType = 'Add Transaction';
//                 }
//                 tranW.effectiveEndDate = Date.today().format();
//                 tranW.effectiveStartDate = Date.newInstance(2090, 12, 31).format();
//                 location lString = new location();
//                 lString.locationId = record.DynamicsAccID__c;
//                 tranW.locations.add(lString);
//                 tranMap.put(subCompanyMap.get(record.id), tranW);
//             }    
//         }

//         for (transactions  tranW: tranMap.values()) {
//             if (tranW.transactionType == 'Cancel Transaction') {
//                 owCancel.Transactions.add(tranW);
//             }else if (tranW.transactionType == 'Add Transaction') {
//                 owAdd.Transactions.add(tranW);
//             }
//         }

//         //////////For CSP-1454 , If a local user Enrolled some locations and Un-Enrolled some Locations at same time, 
//         /////////////break the fulfillment message to two call. 
//         if (!owAdd.Transactions.isempty()) {
//             fulfillclass(owAdd);
//         }
        
//         if (!owCancel.Transactions.isempty()) {
//             fulfillclass(owCancel);
//         }
        
//     }
//     /**
//      *   For CSP-905 and CSP-906
//      *   Main function/method used to send fulfillment message of transaction subscription to boomi.
//      *   if the transaction service is be created or cancelled, the fulfillment message will be send to boomi.
//      *   @author Tony Liu
//      *   @date   2016-05-04   
//      */
//     @future(callout=true)   
//     public static void boomiOrderCallout(set<Id> subIdSet){
//         if(!XOGroupSettingUtility.getPartnerCalloutSetting()){
//             return;
//         }
        
//         Set<Id> companyIdSet = new Set<Id>();
//         Map<Id,String> subCompanyMap = new Map<Id,String>();
//         Map<Id,Id> subParentMap = new Map<Id,Id>();
//         List<Zuora__Subscription__c> zsubList = [select id,Zuora__TermStartDate__c, Zuora__TermEndDate__c,True_Subscription_Status__c ,Zuora__Account__r.DynamicsAccID__c,
//                                                         Zuora__Account__c,Zuora__Account__r.Ignore_Parent_Account__c,Zuora__Account__r.ParentId
//                                                     from Zuora__Subscription__c
//                                                     where id in: subIdSet];
        
//         for(Zuora__Subscription__c zsub: zsubList){
//             if(zsub.Zuora__Account__r.Ignore_Parent_Account__c || zsub.Zuora__Account__r.ParentId==Null){
//                 subCompanyMap.put(zsub.id,zsub.Zuora__Account__r.DynamicsAccID__c);
//             }else{
//                 subParentMap.put(zsub.Zuora__Account__r.ParentId,zsub.id);
//             }
//         }
        
//         while(!subParentMap.isEmpty()){
//             List<account>  parentAccList = [select id,DynamicsAccID__c,ParentId,Ignore_Parent_Account__c from Account where Id in: subParentMap.KeySet()];
//             for(account acc : parentAccList){
//                 if(acc.Ignore_Parent_Account__c || acc.ParentId == Null){
//                     subCompanyMap.put(subParentMap.get(acc.id),acc.DynamicsAccID__c);
//                     subParentMap.remove(acc.id);
//                 }else{
//                     subParentMap.put(acc.ParentId,subParentMap.get(acc.id));
//                     subParentMap.remove(acc.id); 
//                 }
//             }
//         }

        
//         List<Zuora__SubscriptionProductCharge__c> spcList = [select id,LocationVendorDynamicsAccountID__c,Zuora__Subscription__c from Zuora__SubscriptionProductCharge__c where Zuora__Subscription__c in: subIdSet];
//         Map<id,List<String>> spcMap = new Map<id,List<String>>();
//         for (Zuora__SubscriptionProductCharge__c spc : spcList) {
//             if (spcMap.containsKey(spc.Zuora__Subscription__c)) {
//                 spcMap.get(spc.Zuora__Subscription__c).add(spc.LocationVendorDynamicsAccountID__c);
//             }else{
//                 List<String> dynamicIdList = new List<String>();
//                 dynamicIdList.add(spc.LocationVendorDynamicsAccountID__c);
//                 spcMap.put(spc.Zuora__Subscription__c,dynamicIdList);
//             }
            
//         }

//         ObjectWrapper ow = new ObjectWrapper();
//         for (Zuora__Subscription__c zsub: zsubList) {
//             transactions tranW = new transactions();
//             tranW.companyId = subCompanyMap.get(zsub.id);
//             tranW.effectiveStartDate = zsub.Zuora__TermStartDate__c.format();
//             tranW.effectiveEndDate = zsub.Zuora__TermEndDate__c.format();
//             if (zsub.True_Subscription_Status__c == 'Active') {
//                 tranW.transactionType = 'Add Transaction';
//             }else if(zsub.True_Subscription_Status__c == 'Cancelled'){
//                 tranW.transactionType = 'Cancel Transaction';
//             }
//             if (!spcMap.isEmpty() && spcMap.containsKey(zsub.id)) {
//                 for (String  dynamicId : spcMap.get(zsub.id)) {
//                     location lString = new location();
//                     lString.locationId = dynamicId;
//                     tranW.locations.add(lString);
//                 }
//             }
        
//             ow.Transactions.add(tranW);
//         }

//         fulfillclass(ow);
//         // system.debug(ow);
//         // system.debug(JSON.serialize(ow));
//         // system.debug(JSON.serializePretty(ow));
//         // // Instantiate a new http object
        
//         // String strJson = JSON.serialize(ow);
//         // strJson = strJson.replace('transactionType', 'Transaction Type');
//         // strJson = strJson.replace('companyId', 'Company Id');
//         // strJson = strJson.replace('effectiveEndDate', 'Effective End Date');
//         // strJson = strJson.replace('effectiveStartDate', 'Effective Start Date');
//         // system.debug('Json String After replace::::::::'+strJson);
//         // try{
//         //     Http h = new Http();

//         //     // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
//         //     HttpRequest req = new HttpRequest();
//         //     req.setTimeout(120000);
//         //     //http://STGBOOMi01.intranet.theknot.com/ws/simple/getTransactions
//         //     req.setEndpoint('callout:Boomi');
//         //     req.setMethod('PUT');
//         //     req.setHeader('Content-Type', 'application/json');
//         //     req.setBody(strJson);

//         //     system.debug(req);
//         //     system.debug(req.getBody());

//         //     // Send the request, and return a response
//         //     HttpResponse res = h.send(req);
//         //     system.debug(res.getBody());
//         //     system.debug(res.getStatus());

//         //     Partner_Fulfillment_Response__c partnerFulfilmentResponse = new Partner_Fulfillment_Response__c();
//         //     partnerFulfilmentResponse.Response_JSON__c = res.getBody();
//         //     partnerFulfilmentResponse.Type__c = 'Transaction';
//         //     insert partnerFulfilmentResponse;
//         // }catch(Exception E){
//         //     ExceptionUtility.consumeException(e,true);
//         // }

//     }

//     /**
//      *   For CSP-1454
//      *   Main function/method used to send fulfillment message of transaction subscription to boomi.
//      *   if the transaction service is be created or cancelled, the fulfillment message will be send to boomi.
//      *   @author Tony Liu
//      *   @date   2016-05-04   
//      */
//     public static void fulfillclass(ObjectWrapper ow){
//         Map<String,transactions> transMap  = new Map<String,transactions>();
//         for (transactions tranW : ow.Transactions) {
//             transMap.put(tranw.companyId, tranW);
//         }
//         system.debug(ow);
//         system.debug(JSON.serialize(ow));
//         system.debug(JSON.serializePretty(ow));
//         // Instantiate a new http object
        
//         String strJson = JSON.serialize(ow);
//         strJson = strJson.replace('transactionType', 'Transaction Type');
//         strJson = strJson.replace('companyId', 'Company Id');
//         strJson = strJson.replace('effectiveEndDate', 'Effective End Date');
//         strJson = strJson.replace('effectiveStartDate', 'Effective Start Date');
//         system.debug('Json String After replace::::::::'+strJson);
//         try{
//             Http h = new Http();

//             // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
//             HttpRequest req = new HttpRequest();
//             req.setTimeout(120000);
//             //http://STGBOOMi01.intranet.theknot.com/ws/simple/getTransactions
//             req.setEndpoint('callout:Boomi');
//             req.setMethod('PUT');
//             req.setHeader('Content-Type', 'application/json');
//             req.setBody(strJson);

//             system.debug(req);
//             system.debug(req.getBody());

//             // Send the request, and return a response
//             HttpResponse res = h.send(req);
//             system.debug(res.getBody());
//             system.debug(res.getStatus());

//             List<String> Slist = res.getBody().split('}');
            
//             if (!Slist.isEmpty()) {
//                 List<Partner_Fulfillment_Response__c> pfrlist = new list<Partner_Fulfillment_Response__c>();
//                 for (String sss : Slist) {
//                     sss = sss+ '}';

//                     Partner_Fulfillment_Response__c partnerFulfilmentResponse = new Partner_Fulfillment_Response__c();
//                     BoomiResponseWrapper fulfillResponse = (BoomiResponseWrapper)JSON.deserialize(sss, BoomiResponseWrapper.class);
//                     if (fulfillResponse.LocationId == Null  && transMap.containsKey(fulfillResponse.CompanyId)) {
//                         fulfillResponse.LocationId = new List<String>();
//                         for(location record : transMap.get(fulfillResponse.CompanyId).locations){
//                             fulfillResponse.LocationId.add(record.locationId);
//                         } 
//                         sss = JSON.serialize(fulfillResponse);
//                         partnerFulfilmentResponse.Event_Type__c = transMap.get(fulfillResponse.CompanyId).transactionType;
//                     }
                    
//                     partnerFulfilmentResponse.Response_JSON__c = sss;
//                     partnerFulfilmentResponse.Type__c = 'Transaction';
                    
//                     pfrlist.add(partnerFulfilmentResponse);
//                 }
//                 insert pfrlist;
//                 System.debug(LoggingLevel.INFO, '***Partner_Fulfillment_Response__c ::: pfrlist: ' + pfrlist);
//             }
//         }catch(Exception E){
//             System.debug(LoggingLevel.INFO, '*** e: ' + e);
//             System.debug(LoggingLevel.INFO, '*** currentException.getLineNumber();: ' + e.getLineNumber());
//             ExceptionUtility.consumeException(e,true);
//         }

//     }



//     //Request
//     public class ObjectWrapper{
//         public List<Transactions> Transactions {get; set;}
//         public ObjectWrapper(){
//             Transactions = new List<Transactions>();
//         }

//     }
//     public class Transactions{
//         public String companyId {get; set;}
//         public String effectiveStartDate {get; set;}
//         public String effectiveEndDate {get; set;}
//         public String transactionType {get; set;}
//         public List<location> locations {get; set;}

//         public transactions(){
//             companyId = '';
//             effectiveStartDate = '';
//             effectiveEndDate = '';
//             transactionType = '';
//             locations = new List<location>();
//         }
//     }

//     public class location{
//         public String locationId {get; set;}
//         public location(){
//             locationId = '';
//         }
//     }

//     //Response from Partners
//     public with sharing class FulfillTransactionWrapper {
//         public List<LocationWrapper> locations {get; set;}
//         public FulfillTransactionWrapper() {
//             locations = new List<LocationWrapper>();
//         }   
//     }

//     public class LocationWrapper{
//         public String locationId {get; set;}
//         public List<ServiceWrapper> ProfileFeatures {get; set;}
//         public LocationWrapper(){
//             ProfileFeatures = new List<ServiceWrapper>();
//             locationId = '';
//         }
//     }

//     public class ServiceWrapper{
//         public String Subscription {get; set;}
//         public String StartDate {get; set;}
//         public String SKU {get; set;}
//         public String RatePlanId {get; set;}
//         public String ChargeId {get; set;}
//         public String ServiceName {get; set;}
//         public String BillingAccountId {get; set;}
//         public String PaymentType {get; set;}
//         public String Status {get; set;}
//         public String CategoryId {get; set;}
//         public String EndDate {get; set;}

//         public ServiceWrapper(){
//             Subscription = '';
//             StartDate = '';
//             SKU = '';
//             RatePlanId = '';
//             ChargeId = '';
//             ServiceName = '';
//             BillingAccountId = '';
//             PaymentType = '';
//             Status = '';
//             CategoryId = '';
//             EndDate = '';
//         }
//     }

//     //Response from Boomi
//     public with sharing class BoomiResponseWrapper 
// {       public String Status {get; set;}
//         public String ErrorMessage {get; set;}
//         public String CompanyId {get; set;}
//         public list<String> LocationId{get; set;}
//         public BoomiResponseWrapper() {
//             Status = '';
//             ErrorMessage = '';
//             CompanyId = '';
//             LocationId = new list<String>();
//         }   
//     }
}