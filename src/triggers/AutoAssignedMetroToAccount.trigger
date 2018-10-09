/*
  Created: 10/12/2015
  Author: Tony Liu
  Purpose: metro areas are auto-assigned to vendor records based on zip and can be reported on via SF reports
*/
trigger AutoAssignedMetroToAccount on Account (before insert, before update) {
    // Private String errMessage = 'Please enter a valid zip code in order to save a Metro Area.';
    // Map<String,ID> BillZipmap = new Map<String,ID>();
    // Set<String> BillZipCodeList = new Set<String>();
    // Map<String,ID> ShipZipmap = new Map<String,ID>();
    // Set<String> ShipZipCodeList = new Set<String>();
    // for (Account acc : trigger.new) {
    //     if(trigger.isInsert){
    //         if (acc.ShippingPostalCode != null && (acc.ShippingCountryCode == 'US' || acc.ShippingCountry == 'United States')){
    //             if(acc.ShippingPostalCode.length()<5){
    //                 acc.addError('The Shipping Postal Code must be 5 byte or more');
    //             }else{
    //                 ShipZipCodeList.add(acc.ShippingPostalCode.left(5));
    //             }
    //         }
    //         if (acc.BillingPostalCode != null && acc.BillingPostalCode != '' && (acc.BillingCountryCode == 'US' || acc.ShippingCountry == 'United States')) {
    //             if(acc.BillingPostalCode.length()<5){
    //                 acc.addError('The Billing Postal Code must be 5 byte or more');
    //             }else{
    //                 BillZipCodeList.add(acc.BillingPostalCode.left(5));
    //             }
    //         }
    //     }else if(trigger.isUpdate && (acc.ShippingPostalCode  != trigger.oldMap.get(acc.Id).ShippingPostalCode || acc.BillingPostalCode != trigger.oldMap.get(acc.Id).BillingPostalCode || acc.ShippingCountryCode  != trigger.oldMap.get(acc.Id).ShippingCountryCode || acc.BillingCountryCode != trigger.oldMap.get(acc.Id).BillingCountryCode)){
    //         system.debug('*** account ' + acc.name + ' Change ShippingAddress or BillingAddress ');
    //         if (acc.ShippingPostalCode != null && acc.ShippingCountryCode == 'US') {
    //             if(acc.ShippingPostalCode.length()<5){
    //                 acc.addError('The Postal Code must be 5 byte or more');
    //             }else{
    //                 ShipZipCodeList.add(acc.ShippingPostalCode.left(5));
    //             }
    //         }
    //         if (acc.BillingPostalCode  != null && acc.BillingCountryCode == 'US') {
    //             if(acc.BillingPostalCode.length()<5){
    //                 acc.addError('The Postal Code must be 5 byte or more');
    //             }else{
    //                 BillZipCodeList.add(acc.BillingPostalCode.left(5));
    //             }
    //         }
    //         if(acc.BillingPostalCode == null && acc.ShippingPostalCode == null){
    //             acc.Zip__c = null;
    //         }
    //     }
    // }
    
    // if(ShipZipCodeList.size()>0 || BillZipCodeList.size()>0){
    //     List<Zip__c> ShipZipList = new List<Zip__c>();
    //     List<Zip__c> BillZipList = new List<Zip__c>();
    //     if (ShipZipCodeList.size()>0) {
    //         ShipZipList = [select ID,ZipCode__c,MetroArea__c from Zip__c where ZipCode__c in :ShipZipCodeList];
    //     }
    //     if(BillZipCodeList.size()>0) {
    //         BillZipList = [select ID,ZipCode__c,MetroArea__c from Zip__c where ZipCode__c in :BillZipCodeList];
            
    //     }

    //     if (ShipZipList.size()>0) {
    //         for (Zip__c z : ShipZipList) {
    //             ShipZipmap.put(z.ZipCode__c,z.ID);
    //         }
    //     }
    //     if (BillZipList.size()>0) {
    //         for (Zip__c z : BillZipList) {
    //             BillZipmap.put(z.ZipCode__c,z.ID);
    //         }
            
    //     }
 
    //     for (Account acc : trigger.new) {
        
    //         if (acc.ShippingPostalCode != null && ShipZipmap.containsKey(acc.ShippingPostalCode.left(5) )) {
    //             acc.Zip__c = ShipZipmap.get(acc.ShippingPostalCode.left(5));
    //         }else if(acc.BillingPostalCode != null && BillZipmap.containsKey(acc.BillingPostalCode.left(5))) {
    //             system.debug('***The value of field ShippingAddress in account ' + acc.name + ' is NULL or Shipping Zip Code is null or invalid. ');
    //             acc.Zip__c = BillZipmap.get(acc.BillingPostalCode.left(5));
    //         }else{
    //             //acc.addError(errMessage); per Steve, we will not throw an error and create a report that shows all Accounts with blank Zips
    //         }
    //     }
    // }
        
}