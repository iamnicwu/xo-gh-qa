public with sharing class PartnerAccountUpdateCallout {
    private static List<String> phoneFieldList = new List<String>{'Phone', 'HomePhone__c', 'MobilePhone', 'Fax'};
    private static Map<String, String> phoneFieldMap = new Map<String, String>{'Phone' => 'Main', 'HomePhone__c' => 'Home', 'MobilePhone' => 'Mobile', 'Fax' => 'Fax'};

    private static List<String> acctPhoneFieldList = new List<String>{'Phone', 'Mobile__c', 'Vanity__c'};
    private static Map<String, String> acctPhoneFieldMap = new Map<String, String>{'Phone' => 'Main', 'Mobile__c' => 'Mobile', 'Vanity__c' => 'Vanity'};
     
    @future(callout=true)
    public static void accountUpdateCallout(String sfw){
        if(!XOGroupSettingUtility.getPartnerCalloutSetting()){
            return;
        }
        List<RESTLocalStorefrontAPI.ObjectWrapper> objWrapperList = (List<RESTLocalStorefrontAPI.ObjectWrapper>) System.JSON.deserialize(sfw, List<RESTLocalStorefrontAPI.ObjectWrapper>.class);
        List<Partner_Fulfillment_Response__c> pfrList = new List<Partner_Fulfillment_Response__c>();

        Set<String> companyDynamicsAccIdSet = new Set<String>();
        Set<String> locationDynamicsAccIdSet = new Set<String>();

        for(RESTLocalStorefrontAPI.ObjectWrapper objWrapper : objWrapperList){
            companyDynamicsAccIdSet.add(objWrapper.companyId);
            locationDynamicsAccIdSet.add(objWrapper.locationId);
        }

        Map<String, Account> dynamicsIdAccountMap = new Map<String, Account>();

        for(Account record : [select Id, DynamicsAccID__c, Name, Credit_Hold__c, Website, Email__c, Phone, Mobile__c, Vanity__c, 
                                        BillingStreet, BillingCity, BillingStateCode, BillingPostalCode, BillingCountryCode,
                                        ShippingStreet, ShippingCity, ShippingStateCode, ShippingPostalCode, ShippingCountryCode, 
                                        Local_Sales_Market__r.Market_ID__c, Primary_Category__r.Taxonomy_ID__c, 
                                        OwnerId, Owner.FirstName, Owner.LastName, Owner.Phone, Owner.Email, Fulfillment_Data__c,
                                        Strategy_Specialist__c, Strategy_Specialist__r.FirstName, Strategy_Specialist__r.LastName, Strategy_Specialist__r.Phone, Strategy_Specialist__r.Email,
                                        (select Id, Role, ContactId, Contact.FirstName, Contact.LastName, Contact.Email, Contact.Phone, Contact.MailingStreet,
                                            Contact.MailingCity, Contact.MailingState, Contact.MailingStateCode, Contact.MailingCountryCode, Contact.MailingCountry, Contact.MailingPostalCode
                                            from AccountContactRoles where Role IN ('Primary', 'Billing'))
                                        from Account where DynamicsAccID__c IN: companyDynamicsAccIdSet]){
            dynamicsIdAccountMap.put(record.DynamicsAccID__c, record);
        } 

        Map<String, Account> locationDynmicsIdAccountMap = new Map<String, Account>();

        for(Account record : [select Id, DynamicsAccID__c, Name, Credit_Hold__c, Website, Email__c, Phone, Mobile__c, Vanity__c, 
                                        BillingStreet, BillingCity, BillingStateCode, BillingPostalCode, BillingCountryCode,
                                        ShippingStreet, ShippingCity, ShippingStateCode, ShippingPostalCode, ShippingCountryCode, 
                                        Local_Sales_Market__r.Market_ID__c, Primary_Category__r.Taxonomy_ID__c
                                        from Account where DynamicsAccID__c IN: locationDynamicsAccIdSet]){
            locationDynmicsIdAccountMap.put(record.DynamicsAccID__c, record);
        }

        for(RESTLocalStorefrontAPI.ObjectWrapper objWrapper : objWrapperList){
            AccountUpdatePayloadWrapper accountUpdatePayload = new AccountUpdatePayloadWrapper();
            
            Account acctData = dynamicsIdAccountMap.get(objWrapper.companyId);

            accountUpdatePayload.companyId = stringFieldValue(acctData.DynamicsAccID__c);
            accountUpdatePayload.companyName = stringFieldValue(acctData.Name);
            accountUpdatePayload.creditHold = acctData.Credit_Hold__c;
            accountUpdatePayload.website = stringFieldValue(acctData.Website);
            accountUpdatePayload.email = stringFieldValue(acctData.Email__c);

            for(Integer i = 0; i < acctPhoneFieldList.size(); i++){
                if(acctData.get(acctPhoneFieldList[i]) != null){
                    AccountUpdatePayloadWrapper.PhoneNumberWrapper phoneData = new AccountUpdatePayloadWrapper.PhoneNumberWrapper();
                    phoneData.type = acctPhoneFieldMap.get(acctPhoneFieldList[i]);
                    phoneData.phoneNumber = String.valueof(acctData.get(acctPhoneFieldList[i]));
                    accountUpdatePayload.phones.add(phoneData);
                }
            }

            List<String> billingStreetList = new List<String>();
            if(String.isNotBlank(acctData.BillingStreet)){
                billingStreetList = acctData.BillingStreet.split('\\r\\n');
            }
            if(!billingStreetList.isEmpty()){
                accountUpdatePayload.address.street1 = billingStreetList[0];
                if(billingStreetList.size() > 1){
                    accountUpdatePayload.address.street2 = billingStreetList[1];
                }
            }

            accountUpdatePayload.address.city = stringFieldValue(acctData.BillingCity);
            accountUpdatePayload.address.stateOrProvince = stringFieldValue(acctData.BillingStateCode);
            accountUpdatePayload.address.country = stringFieldValue(acctData.BillingCountryCode);
            accountUpdatePayload.address.postalCode = stringFieldValue(acctData.BillingPostalCode);

            accountUpdatePayload.salesrep.id = acctData.OwnerId;
            accountUpdatePayload.salesrep.firstName = stringFieldValue(acctData.Owner.FirstName);
            accountUpdatePayload.salesrep.lastName = stringFieldValue(acctData.Owner.LastName);
            accountUpdatePayload.salesrep.phone = stringFieldValue(acctData.Owner.Phone);
            accountUpdatePayload.salesrep.email = stringFieldValue(acctData.Owner.Email);

            accountUpdatePayload.strategySpecialist.id = acctData.Strategy_Specialist__c;
            accountUpdatePayload.strategySpecialist.firstName = stringFieldValue(acctData.Strategy_Specialist__r.FirstName);
            accountUpdatePayload.strategySpecialist.lastName = stringFieldValue(acctData.Strategy_Specialist__r.LastName);
            accountUpdatePayload.strategySpecialist.phone = stringFieldValue(acctData.Strategy_Specialist__r.Phone);
            accountUpdatePayload.strategySpecialist.email = stringFieldValue(acctData.Strategy_Specialist__r.Email);

            if(!acctData.AccountContactRoles.isEmpty()){
                for(AccountContactRole record : acctData.AccountContactRoles){
                    AccountUpdatePayloadWrapper.ContactWrapper cont = new AccountUpdatePayloadWrapper.ContactWrapper();
                    cont.contactId = record.ContactId;
                    cont.firstName = stringFieldValue(record.Contact.FirstName);
                    cont.lastName = stringFieldValue(record.Contact.LastName);
                    cont.email = stringFieldValue(record.Contact.Email);
                    cont.role = stringFieldValue(record.Role);
                    cont.phone = stringFieldValue(record.Contact.Phone);
                    cont.address.city = stringFieldValue(record.Contact.MailingCity);
                    cont.address.stateOrProvince = stringFieldValue(record.Contact.MailingStateCode);
                    cont.address.country = stringFieldValue(record.Contact.MailingCountryCode);
                    cont.address.postalCode = stringFieldValue(record.Contact.MailingPostalCode);

                    List<String> mailingStreetList = new List<String>();
                    if(String.isNotBlank(record.Contact.MailingStreet)){
                        mailingStreetList = record.Contact.MailingStreet.split('\\r\\n');
                    }
                    if(!mailingStreetList.isEmpty()){
                        cont.address.street1 = mailingStreetList[0];
                        if(mailingStreetList.size() > 1){
                            cont.address.street2 = mailingStreetList[1];
                        }
                    }
                    accountUpdatePayload.contacts.add(cont);
                }
            }

            Account locationData = locationDynmicsIdAccountMap.get(objWrapper.locationId);

            AccountUpdatePayloadWrapper.LocationWrapper acctLocation = new AccountUpdatePayloadWrapper.LocationWrapper();
            acctLocation.locationId = stringFieldValue(locationData.DynamicsAccID__c);
            acctLocation.name = stringFieldValue(locationData.Name);
            acctLocation.website = stringFieldValue(locationData.Website);
            acctLocation.email = stringFieldValue(locationData.Email__c);

            for(Integer i = 0; i < acctPhoneFieldList.size(); i++){
                if(locationData.get(acctPhoneFieldList[i]) != null){
                    AccountUpdatePayloadWrapper.PhoneNumberWrapper phoneData = new AccountUpdatePayloadWrapper.PhoneNumberWrapper();
                    phoneData.type = acctPhoneFieldMap.get(acctPhoneFieldList[i]);
                    phoneData.phoneNumber = String.valueof(locationData.get(acctPhoneFieldList[i]));
                    acctLocation.phones.add(phoneData);
                }
            }

            List<String> shippingStreetList = new List<String>();
            if(String.isNotBlank(locationData.ShippingStreet)){
                shippingStreetList = locationData.ShippingStreet.split('\\r\\n');
            }
            if(!shippingStreetList.isEmpty()){
                acctLocation.address.street1 = shippingStreetList[0];
                if(shippingStreetList.size() > 1){
                    acctLocation.address.street2 = shippingStreetList[1];
                }
            }

            acctLocation.address.city = stringFieldValue(locationData.ShippingCity);
            acctLocation.address.stateOrProvince = stringFieldValue(locationData.ShippingStateCode);
            acctLocation.address.country = stringFieldValue(locationData.ShippingCountryCode);
            acctLocation.address.postalCode = stringFieldValue(locationData.ShippingPostalCode);

            accountUpdatePayload.locations.add(acctLocation);

            // Instantiate a new http object
            Http h = new Http();

            // CSP-2651 Partners FulFillment JSON Token Functionality
            HttpRequest req = RestCalloutUtility.accountUpdateCallout(JSON.serialize(accountUpdatePayload));

            System.debug(LoggingLevel.INFO, '*** req: ' + req.getBody());
            // // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
            // HttpRequest req = new HttpRequest();
            // req.setTimeout(120000);
            // //http://qa-no-services.theknot.com/local-partners/salesfulfillment/v1/storefronts/fulfillments
            // req.setEndpoint('callout:PartnersAccountUpdate');
            // req.setMethod('PUT');
            // req.setHeader('Content-Type', 'application/json');
            // req.setBody(JSON.serialize(accountUpdatePayload));

            // system.debug(req);
            // system.debug(req.getBody());

            // Send the request, and return a response
            HttpResponse res = h.send(req);
            System.debug(LoggingLevel.INFO, '*** res: ' + res.getBody());

            Partner_Fulfillment_Response__c partnerFulfilmentResponse = new Partner_Fulfillment_Response__c();
            partnerFulfilmentResponse.Response_JSON__c = res.getBody();
            partnerFulfilmentResponse.Object_Type__c = 'Account';
            partnerFulfilmentResponse.Type__c = 'Account Update';
            pfrList.add(partnerFulfilmentResponse);
            
            system.debug(JSON.serializePretty(accountUpdatePayload));
        }
        insert pfrList;
    }

    public static void accountUpdateCalloutNotFuture(String sfw){
        if(!XOGroupSettingUtility.getPartnerCalloutSetting()){
            return;
        }
        List<RESTLocalStorefrontAPI.ObjectWrapper> objWrapperList = (List<RESTLocalStorefrontAPI.ObjectWrapper>) System.JSON.deserialize(sfw, List<RESTLocalStorefrontAPI.ObjectWrapper>.class);
        List<Partner_Fulfillment_Response__c> responseList = new List<Partner_Fulfillment_Response__c>();

        Set<String> dynamicsAccIdSet = new Set<String>();

        for(RESTLocalStorefrontAPI.ObjectWrapper objWrapper : objWrapperList){
            dynamicsAccIdSet.add(objWrapper.companyId);
        }

        Map<String, Account> dynamicsIdAccountMap = new Map<String, Account>();

        for(Account record : [select Id, DynamicsAccID__c, Name, Credit_Hold__c, Website, Email__c, Phone, Mobile__c, Vanity__c, 
                                        BillingStreet, BillingCity, BillingStateCode, BillingPostalCode, BillingCountryCode,
                                        ShippingStreet, ShippingCity, ShippingStateCode, ShippingPostalCode, ShippingCountryCode, 
                                        Local_Sales_Market__r.Market_ID__c, Primary_Category__r.Taxonomy_ID__c, 
                                        OwnerId, Owner.FirstName, Owner.LastName, Owner.Phone, Owner.Email, Fulfillment_Data__c,
                                        Strategy_Specialist__c, Strategy_Specialist__r.FirstName, Strategy_Specialist__r.LastName, Strategy_Specialist__r.Phone, Strategy_Specialist__r.Email,
                                        (select Id, Role, ContactId, Contact.FirstName, Contact.LastName, Contact.Email, Contact.Phone, Contact.MailingStreet,
                                            Contact.MailingCity, Contact.MailingState, Contact.MailingStateCode, Contact.MailingCountryCode, Contact.MailingCountry, Contact.MailingPostalCode
                                            from AccountContactRoles where Role IN ('Primary', 'Billing'))
                                        from Account where DynamicsAccID__c IN: dynamicsAccIdSet]){
            dynamicsIdAccountMap.put(record.DynamicsAccID__c, record);
        }

        for(RESTLocalStorefrontAPI.ObjectWrapper objWrapper : objWrapperList){
            AccountUpdatePayloadWrapper accountUpdatePayload = new AccountUpdatePayloadWrapper();
            
            Account acctData = dynamicsIdAccountMap.get(objWrapper.companyId);

            accountUpdatePayload.companyId = stringFieldValue(acctData.DynamicsAccID__c);
            accountUpdatePayload.companyName = stringFieldValue(acctData.Name);
            accountUpdatePayload.creditHold = acctData.Credit_Hold__c;
            accountUpdatePayload.website = stringFieldValue(acctData.Website);
            accountUpdatePayload.email = stringFieldValue(acctData.Email__c);

            for(Integer i = 0; i < acctPhoneFieldList.size(); i++){
                if(acctData.get(acctPhoneFieldList[i]) != null){
                    AccountUpdatePayloadWrapper.PhoneNumberWrapper phoneData = new AccountUpdatePayloadWrapper.PhoneNumberWrapper();
                    phoneData.type = acctPhoneFieldMap.get(acctPhoneFieldList[i]);
                    phoneData.phoneNumber = String.valueof(acctData.get(acctPhoneFieldList[i]));
                    accountUpdatePayload.phones.add(phoneData);
                }
            }

            List<String> billingStreetList = new List<String>();
            if(String.isNotBlank(acctData.BillingStreet)){
                billingStreetList = acctData.BillingStreet.split('\\r\\n');
            }
            if(!billingStreetList.isEmpty()){
                accountUpdatePayload.address.street1 = billingStreetList[0];
                if(billingStreetList.size() > 1){
                    accountUpdatePayload.address.street2 = billingStreetList[1];
                }
            }

            accountUpdatePayload.address.city = stringFieldValue(acctData.BillingCity);
            accountUpdatePayload.address.stateOrProvince = stringFieldValue(acctData.BillingStateCode);
            accountUpdatePayload.address.country = stringFieldValue(acctData.BillingCountryCode);
            accountUpdatePayload.address.postalCode = stringFieldValue(acctData.BillingPostalCode);

            accountUpdatePayload.salesrep.id = acctData.OwnerId;
            accountUpdatePayload.salesrep.firstName = stringFieldValue(acctData.Owner.FirstName);
            accountUpdatePayload.salesrep.lastName = stringFieldValue(acctData.Owner.LastName);
            accountUpdatePayload.salesrep.phone = stringFieldValue(acctData.Owner.Phone);
            accountUpdatePayload.salesrep.email = stringFieldValue(acctData.Owner.Email);

            accountUpdatePayload.strategySpecialist.id = acctData.Strategy_Specialist__c;
            accountUpdatePayload.strategySpecialist.firstName = stringFieldValue(acctData.Strategy_Specialist__r.FirstName);
            accountUpdatePayload.strategySpecialist.lastName = stringFieldValue(acctData.Strategy_Specialist__r.LastName);
            accountUpdatePayload.strategySpecialist.phone = stringFieldValue(acctData.Strategy_Specialist__r.Phone);
            accountUpdatePayload.strategySpecialist.email = stringFieldValue(acctData.Strategy_Specialist__r.Email);

            if(!acctData.AccountContactRoles.isEmpty()){
                for(AccountContactRole record : acctData.AccountContactRoles){
                    AccountUpdatePayloadWrapper.ContactWrapper cont = new AccountUpdatePayloadWrapper.ContactWrapper();
                    cont.contactId = record.ContactId;
                    cont.firstName = stringFieldValue(record.Contact.FirstName);
                    cont.lastName = stringFieldValue(record.Contact.LastName);
                    cont.email = stringFieldValue(record.Contact.Email);
                    cont.role = stringFieldValue(record.Role);
                    cont.phone = stringFieldValue(record.Contact.Phone);
                    cont.address.city = stringFieldValue(record.Contact.MailingCity);
                    cont.address.stateOrProvince = stringFieldValue(record.Contact.MailingStateCode);
                    cont.address.country = stringFieldValue(record.Contact.MailingCountryCode);
                    cont.address.postalCode = stringFieldValue(record.Contact.MailingPostalCode);

                    List<String> mailingStreetList = new List<String>();
                    if(String.isNotBlank(record.Contact.MailingStreet)){
                        mailingStreetList = record.Contact.MailingStreet.split('\\r\\n');
                    }
                    if(!mailingStreetList.isEmpty()){
                        cont.address.street1 = mailingStreetList[0];
                        if(mailingStreetList.size() > 1){
                            cont.address.street2 = mailingStreetList[1];
                        }
                    }
                    accountUpdatePayload.contacts.add(cont);
                }
            }

            /*Account locationData = [select Id, DynamicsAccID__c, Name, Credit_Hold__c, Website, Email__c, Phone, Mobile__c, Vanity__c, 
                                        BillingStreet, BillingCity, BillingStateCode, BillingPostalCode, BillingCountryCode,
                                        ShippingStreet, ShippingCity, ShippingStateCode, ShippingPostalCode, ShippingCountryCode, 
                                        Local_Sales_Market__r.Market_ID__c, Primary_Category__r.Taxonomy_ID__c
                                        from Account where DynamicsAccID__c =: objWrapper.locationId];

            AccountUpdatePayloadWrapper.LocationWrapper acctLocation = new AccountUpdatePayloadWrapper.LocationWrapper();
            acctLocation.locationId = stringFieldValue(locationData.DynamicsAccID__c);
            acctLocation.name = stringFieldValue(locationData.Name);
            acctLocation.website = stringFieldValue(locationData.Website);
            acctLocation.email = stringFieldValue(locationData.Email__c);

            for(Integer i = 0; i < acctPhoneFieldList.size(); i++){
                if(locationData.get(acctPhoneFieldList[i]) != null){
                    AccountUpdatePayloadWrapper.PhoneNumberWrapper phoneData = new AccountUpdatePayloadWrapper.PhoneNumberWrapper();
                    phoneData.type = acctPhoneFieldMap.get(acctPhoneFieldList[i]);
                    phoneData.phoneNumber = String.valueof(locationData.get(acctPhoneFieldList[i]));
                    acctLocation.phones.add(phoneData);
                }
            }

            List<String> shippingStreetList = new List<String>();
            if(String.isNotBlank(locationData.ShippingStreet)){
                shippingStreetList = locationData.ShippingStreet.split('\\r\\n');
            }
            if(!shippingStreetList.isEmpty()){
                acctLocation.address.street1 = shippingStreetList[0];
                if(shippingStreetList.size() > 1){
                    acctLocation.address.street2 = shippingStreetList[1];
                }
            }

            acctLocation.address.city = stringFieldValue(locationData.ShippingCity);
            acctLocation.address.stateOrProvince = stringFieldValue(locationData.ShippingStateCode);
            acctLocation.address.country = stringFieldValue(locationData.ShippingCountryCode);
            acctLocation.address.postalCode = stringFieldValue(locationData.ShippingPostalCode);

            accountUpdatePayload.locations.add(acctLocation);*/

            // Instantiate a new http object
            Http h = new Http();

            // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
            HttpRequest req = new HttpRequest();
            req.setTimeout(120000);
            //http://qa-no-services.theknot.com/local-partners/salesfulfillment/v1/accounts
            req.setEndpoint('callout:PartnersAccountUpdate');
            req.setMethod('PUT');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(accountUpdatePayload));

            system.debug(req);
            system.debug(req.getBody());

            // Send the request, and return a response
            HttpResponse res = h.send(req);
            system.debug(res.getBody());
            system.debug(res.getStatus());

            Partner_Fulfillment_Response__c partnerFulfilmentResponse = new Partner_Fulfillment_Response__c();
            partnerFulfilmentResponse.Response_JSON__c = res.getBody();
            partnerFulfilmentResponse.Object_Type__c = 'Account';
            partnerFulfilmentResponse.Type__c = 'Account Update';
            responseList.add(partnerFulfilmentResponse);

            system.debug(JSON.serializePretty(accountUpdatePayload));
        }
        insert responseList;
    }

    private static String stringFieldValue(String val){
        return (String.isNotBlank(val)) ? val : '';
    }

}