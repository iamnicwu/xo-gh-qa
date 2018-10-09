public without sharing class UpdateMarketplaceSaleabilityUtility {

    
    /**
     *   Function used to modifiy Marketplace Saleability field on the lead 
     *
     *   @author Mason Qiu
     *   @date   2018-01-26
     *   @param  List<Lead>           
     *   @return list<lead>          The result of the Modifiy and filter after.
    **/

    // public static list<lead> updateLeadMarketSaleability(List<Lead> originalLeadlist) {

    //   List<lead> leadlist = new List<lead>();
    //   List<lead> updateLeaList = new List<lead>();
      // String zipCodeAndCategory = '';
      // Map<String,String> externalStatuMap = new Map<String,String>();
      // Set<String> zipCodeAndCategorySet = new Set<String>();

      // for(Lead currentLead : originalLeadlist) {
      //     //Store zipcode+category, and associated to lead/Account 
      //     if(!String.isBlank(currentLead.PostalCode) && !String.isBlank(currentLead.Category_Code__c)) {
      //       if (currentLead.PostalCode.length() > 5 ) {
      //          zipCodeAndCategory = currentLead.PostalCode.left(5) + currentLead.Category_Code__c;
      //       }else {
      //          zipCodeAndCategory = currentLead.PostalCode + currentLead.Category_Code__c;
      //       }
      //       zipCodeAndCategorySet.add(zipCodeAndCategory);
      //       leadlist.add(currentLead);
      //     }
      //     else{
      //         //The Marketplace Saleability is "Not Rated" if the prospect is missing either Primary Category or Postal Code.
      //         // currentLead.Marketplace_Health__c = Label.MarketSaleabilityDefaultValue;
      //         updateLeaList.add(currentLead);
      //     }
      // }
      // if (!zipCodeAndCategorySet.isEmpty()) {
      //    //Get Marketplace Saleability data
      //    externalStatuMap = findSaleabilityMap(zipCodeAndCategorySet);
      // }

      // if(!leadlist.isEmpty()) {
      //     for(Lead currentLead : leadlist) {
      //         //When zip code length more than 5 character, only get 5 character
      //         if (currentLead.PostalCode.length() > 5 ) {
      //             zipCodeAndCategory = currentLead.PostalCode.left(5) + currentLead.Category_Code__c;
      //         }else {
      //             zipCodeAndCategory = currentLead.PostalCode + currentLead.Category_Code__c;
      //         }
      //         if(externalStatuMap.containsKey(zipCodeAndCategory)) {
      //             //Mapping Marketplace Saleability to lead 
      //             // currentLead.Marketplace_Health__c = externalStatuMap.get(zipCodeAndCategory);
      //         }
      //         else {
      //             //The Marketplace Saleability is "Not Rated" if cannot be found for the prospects Primary Category or Postal Code
      //             currentLead.Marketplace_Health__c = Label.MarketSaleabilityDefaultValue;
      //         }
      //         updateLeaList.add(currentLead);
      //     }
      // }
    //   return updateLeaList;
    // }

    /**
     *   Function used to Modifiy marketplace Saleability field on the Account 
     *
     *   @author Mason Qiu
     *   @date   2018-01-26
     *   @param  List<Account>           
     *   @return list<Account>          The result of the Modifiy and filter after.
    **/
    // public static list<Account> updateAcctMarketSaleability(List<Account> originalAccountlist) {
      
    //   List<Account> accountList = new List<Account>();
    //   List<Account> updateAcctList = new List<Account>();
      // String zipCodeAndCategory = '';
      // Map<String,String> externalStatuMap = new Map<String,String>();
      // Set<String> zipCodeAndCategorySet = new Set<String>();

      // for(Account currentAcct : originalAccountlist) {
      //     //Store zipcode+category, and associated to lead/Account 
      //     if(!String.isBlank(currentAcct.BillingPostalCode) && !String.isBlank(currentAcct.Category_Code__c)) {
      //         if (currentAcct.BillingPostalCode.length() > 5 ) {
      //            zipCodeAndCategory = currentAcct.BillingPostalCode.left(5) + currentAcct.Category_Code__c;
      //         }else {
      //            zipCodeAndCategory = currentAcct.BillingPostalCode + currentAcct.Category_Code__c;
      //         }
      //         zipCodeAndCategorySet.add(zipCodeAndCategory);
      //         accountList.add(currentAcct);
      //     }
      //     else{
      //         //The Marketplace Saleability is "Not Rated" if the prospect is missing either Primary Category or Postal Code.
      //         currentAcct.Marketplace_Health__c = Label.MarketSaleabilityDefaultValue;
      //         updateAcctList.add(currentAcct);

      //     }
      // }
      //  if (!zipCodeAndCategorySet.isEmpty()) {
      //     //Get Marketplace Saleability data
      //     externalStatuMap = findSaleabilityMap(zipCodeAndCategorySet);
      //   }

      // if(!accountList.isEmpty()) {
      //     for(Account currentAcct : accountList) {
      //         if (currentAcct.BillingPostalCode.length() > 5 ) {
      //            zipCodeAndCategory = currentAcct.BillingPostalCode.left(5) + currentAcct.Category_Code__c;
      //         }else {
      //            zipCodeAndCategory = currentAcct.BillingPostalCode + currentAcct.Category_Code__c;
      //         }
      //         if(externalStatuMap.containsKey(zipCodeAndCategory)) {
      //             //Mapping Marketplace Saleability to lead 
      //             currentAcct.Marketplace_Health__c = externalStatuMap.get(zipCodeAndCategory);
      //         }
      //         else {
      //             //The Marketplace Saleability is "Not Rated" if cannot be found for the prospects Primary Category or Postal Code
      //             currentAcct.Marketplace_Health__c = Label.MarketSaleabilityDefaultValue;
      //             System.debug(LoggingLevel.INFO, '*** zipCodeAndCategory: ' + zipCodeAndCategory);
      //         }
      //         updateAcctList.add(currentAcct);
      //     }
      // }
    //   return updateAcctList;
    // }

    /**
     *   Function used to find mapping data on Marketplace Saleability object
     *
     *   @author Mason Qiu
     *   @date   2018-01-26
     *   @param  Set<String>          
     *   @return Map<String,String>   map rule of the External_Key__c and Marketplace Saleability
    **/
    // public static Map<String,String> findSaleabilityMap(Set<String> zipCodeAndCategorySet) {

    //   Map<String,String> externalStatuMap = new Map<String,String>();

      // System.debug(LoggingLevel.INFO, '*** zipCodeAndCategorySet: ' + zipCodeAndCategorySet);
      // for(Marketplace_Health__c currentMS : [SELECT Category__r.Category_Code__c, Zip__r.ZipCode__c, Marketplace_Health__c, External_Key__c, Status__c 
      //                                             FROM Marketplace_Health__c 
      //                                             WHERE Category__c != '' AND Category__c != NULL
      //                                             AND Zip__c != '' AND Zip__c != NULL 
      //                                             AND Marketplace_Health__c != '' AND Marketplace_Health__c != NULL
      //                                             AND External_Key__c IN: zipCodeAndCategorySet]) {

      //   externalStatuMap.put(currentMS.External_Key__c,currentMS.Marketplace_Health__c);
      // }
    //   return externalStatuMap;
    // }
}