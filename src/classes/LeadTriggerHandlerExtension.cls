public without sharing class LeadTriggerHandlerExtension {

    // BEGIN SIVA VANKADARU CSP - 2927 07-23-2018
    private static List<CountryZipREGEX__c> countryRegExList = [select Id, Name, Active__c, CountryCode__c, RegExPattern__c from CountryZipREGEX__c where Active__c = true];

    // CSP-2544 - phone Validation
    public static Lead phoneValidation(Lead record, Lead oldRecord){
        if( (trigger.isUpdate && String.isNotBlank(record.Phone) && record.Phone != oldRecord.Phone ) || (trigger.isInsert && String.isNotBlank(record.Phone)) ) {
            DataUtility.ValidationResult phoneValidation = DataUtility.formatPhoneNumber(record.Phone);
            // If the Phone is valid then put the formatted value into the Phone field
            if(phoneValidation.valid) {
                record.Phone = phoneValidation.formattedValue;
            } 
            else {
                record.Phone.addError(System.Label.Phone_Validation_Error);
            }
        }
        return record;
    }

    public static Lead zipValidation(Lead record, Lead oldRecord){
        if ( 
            (oldRecord != Null && record.CountryCode != null && record.PostalCode != null && String.isNotBlank(record.Status) && 
            trigger.isUpdate && (record.IsConverted != oldRecord.IsConverted || record.CountryCode != oldRecord.CountryCode || record.PostalCode != oldRecord.PostalCode || record.Status != oldRecord.Status) 
            && String.isNotBlank(record.CountryCode) && String.isNotBlank(record.PostalCode) && String.isNotBlank(record.Status) ) 
            || ( trigger.isInsert && String.isNotBlank(record.CountryCode) && String.isNotBlank(record.PostalCode) && String.isNotBlank(record.Status))
            ){
                //CSP-2954: Allow Leads with incomplete (3-digit) Canadian postal codes
                //6-digit format postal code is required when we qualify a canadian lead or convert a canadian lead.
                if( (record.Status == 'Qualified' || record.IsConverted)                   
                    && !XOCustomValidationUtility.hasCompleteCanadianZip(record.CountryCode, record.PostalCode) ){
                    record.PostalCode.addError('6-digit postal code is required for the selected Country');
                }

                if(!XOCustomValidationUtility.validZip(record.CountryCode, record.PostalCode)){
                    record.PostalCode.addError('Not a valid zip code for the selected Country');
                }
        }
        return record;
    }

    public static Lead assignDynamicsleadid(Lead record){
        if(String.isBlank(record.DynamicsLeadID__c)){
            record.DynamicsLeadID__c = RandomStringUtils.randomUUID();
            record.Salesforce_Generated_GUID__c = true;
        }
        return record;
    }

    public static Lead assignCountry(Lead record){
        if(!countryRegExList.isEmpty() && String.isBlank(record.CountryCode) && String.isBlank(record.Country) && String.isNotBlank(record.PostalCode)){
            record = (Lead)XOCustomValidationUtility.assignCountryBasedOnZip(record, 'CountryCode', record.PostalCode);
            return record;
        }
        return record;
    }

    public static Lead assignLocalsalesmarket(Lead record, Map<String, Market__c> marketIdObjMap, Map<String, String> zipMarketMap, 
        Lead oldRecord, Map<String, Canadian_Postal_Code_Market_Mapping__c> canadaMarketMap, Map<String, String> stateCodeMarketId){

        // CSP-3075 Update Automation on Lead to fill in Market based on Canadian Zip Codes
        // Created lead or update postalCode to assign Zip logic     
        if((trigger.isInsert || (oldRecord != Null && trigger.isUpdate 
            && (record.PostalCode != oldRecord.PostalCode) 
            || (record.StateCode != oldRecord.StateCode)))) {
            
            if(record.CountryCode == 'CA') {
                // CSP-3075 Update Automation on Lead to fill in Market based on Canadian Zip Codes
                // Get sales market base on first 3 digits zip codes
                String zipCode = String.isNotBlank(record.PostalCode) ? record.PostalCode.left(3).toUpperCase() : ''; 
                if(String.isNotBlank(zipCode) 
                    && zipMarketMap.containsKey(zipCode) 
                    && zipMarketMap.get(zipCode) != record.Local_Sales_Market__c){

                    record.Local_Sales_Market__c = zipMarketMap.get(zipCode);
                } 
                // Set default local sales market for Canada
                else{
                    Market__c defaultMarket = DataUtility.getDefaultCanadaMarket(zipCode, record.StateCode, marketIdObjMap, canadaMarketMap, stateCodeMarketId);

                    if(defaultMarket != null && record.Local_Sales_Market__c != defaultMarket.Id) {
                        record.Local_Sales_Market__c = defaultMarket.Id;
                    }
                }
            }
            //CSP-3075 Update Automation on Lead to fill in Market based on Canadian Zip Codes
            //Arrange assign market logic when Country is US   
            else if (record.CountryCode == 'US'
                    && String.isNotBlank(record.PostalCode) 
                    && zipMarketMap.containsKey(record.PostalCode.left(5)) 
                    && zipMarketMap.get(record.PostalCode.left(5)) != record.Local_Sales_Market__c) {

                    record.Local_Sales_Market__c = zipMarketMap.get(record.PostalCode.left(5));
            }
            // For other country matching local sales market 
            else if(String.isNotBlank(record.PostalCode) 
                && zipMarketMap.containsKey(record.PostalCode)
                && zipMarketMap.get(record.PostalCode) != record.Local_Sales_Market__c) {

                 record.Local_Sales_Market__c = zipMarketMap.get(record.PostalCode);
            }
        }
        return record;
    }

    // CSP-2476 Default City/State from Postal Code
    // if the City/State is null, we should auto fufilled the City/State
    public static Lead assignCitystate(Lead record, Map<String, Zip__c> poastalCodeZipMap, Lead oldRecord){
        // CSP-3075 Update Automation on Lead to fill in Market based on Zip Codes
        // Created lead or update postalCode to assign City/State logic 
        Zip__c currentZip;
        if((trigger.isInsert || (oldRecord != Null && trigger.isUpdate &&  record.PostalCode != oldRecord.PostalCode))
            && (record.CountryCode == 'US' || record.CountryCode == 'CA') 
            && String.isNotBlank(record.PostalCode)) {

            // Get zip code record for Canada 
            if (record.CountryCode == 'CA' 
                && record.PostalCode.length() >= 3 
                && poastalCodeZipMap.containsKey(record.PostalCode.left(3).toUpperCase())){

               currentZip = poastalCodeZipMap.get(record.PostalCode.left(3).toUpperCase());      
            }
            // Get zip code record for US
            if (record.CountryCode == 'US' 
                && record.PostalCode.length() >= 5 
                && poastalCodeZipMap.containsKey(record.PostalCode.left(5))) {
                    
               currentZip = poastalCodeZipMap.get(record.PostalCode.left(5));      
            }
            // fill City/State info to lead from zip record 
            if(currentZip != null) {
                if (String.isNotBlank(currentZip.City__c)) {
                    record.City = currentZip.City__c;
                }
                if (String.isNotBlank(currentZip.State__c)) {
                    record.State = currentZip.State__c;
                }
            }
        }
        return record;       
    }

    public static Lead assignFulfillstorefront(Lead record){
        if ( (trigger.isInsert && (record.Storefront_Status__c == 'Claimed' || record.Storefront_Status__c == 'Unclaimed') ) 
            || (trigger.isUpdate && !record.Fulfill_Storefront__c && (record.Storefront_Status__c == 'Claimed' || record.Storefront_Status__c == 'Unclaimed'))){
            record.Fulfill_Storefront__c = true;
        }
        return record;
    }

    public static Lead assignStrategyspecialist(Lead record, Map<Id, Id> salesRepStrategySpecialistMap, Lead oldRecord){
        if ( (salesRepStrategySpecialistMap.containsKey(record.OwnerId) && trigger.isInsert) || (oldRecord != Null && !record.isConverted 
            && salesRepStrategySpecialistMap.containsKey(record.OwnerId) && (trigger.isUpdate) && (record.OwnerId != oldRecord.OwnerId 
                || String.isBlank(record.Strategy_Specialist__c))) ){
            record.Strategy_Specialist__c = salesRepStrategySpecialistMap.get(record.OwnerId);
        }
        return record;
    }

    //ss-6634, CSP-2791
    public static Lead assignZip(Lead record, Map<String, Id> zipNameToIdMap, Lead oldRecord){
        // CSP-3075 Update Automation on Lead to fill in Market based on Zip Codes
        // Created lead or update postalCode to assign Zip logic 
        if((trigger.isInsert || (oldRecord != Null && record.PostalCode != oldRecord.PostalCode && trigger.isUpdate))) {

            // CSP-3067 9 digit zips not populating marketplace health and portfolio fields
            // if the postal code length is greater than 5, we should get the 5th digit to assign zip
            if( record.CountryCode == 'US'
                && String.isNotBlank(record.PostalCode)
                && zipNameToIdMap.containsKey(record.PostalCode.left(5))){

                record.Zip__c = zipNameToIdMap.get(record.PostalCode.left(5));    
            }
            //CSP-3075 Update Automation on Lead to fill in Market based on the Canadian Zip Codes
            // get first three digits of Canadian Zip Code assign zip
            else if(record.CountryCode == 'CA'
                 && String.isNotBlank(record.PostalCode)
                 && zipNameToIdMap.containsKey(record.PostalCode.left(3).toUpperCase())){

                record.Zip__c = zipNameToIdMap.get(record.PostalCode.left(3).toUpperCase());  
            }
            else if(String.isNotBlank(record.PostalCode) 
                && zipNameToIdMap.containsKey(record.PostalCode)) {
                
               record.Zip__c = zipNameToIdMap.get(record.PostalCode); 
            }
            else{
               record.Zip__c = null;  
            }
        }
        return record;
    }
    // END SIVA VANKADARU CSP - 2927 07-23-2018
}