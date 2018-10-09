public without sharing class PartnerCallouts {
  private static List<String> phoneFieldList = new List<String>{'Phone', 'HomePhone__c', 'MobilePhone', 'Fax'};
  private static Map<String, String> phoneFieldMap = new Map<String, String>{'Phone' => 'Main', 'HomePhone__c' => 'Home', 'MobilePhone' => 'Mobile', 'Fax' => 'Fax'};

  private static List<String> acctPhoneFieldList = new List<String>{'Phone', 'Mobile__c', 'Vanity__c'};
  private static Map<String, String> acctPhoneFieldMap = new Map<String, String>{'Phone' => 'Main', 'Mobile__c' => 'Mobile', 'Vanity__c' => 'Vanity'};

  @future(callout=true)
    public static void partnerOrderCallout(String sfw){
      if(!XOGroupSettingUtility.getPartnerCalloutSetting()){
        return;
      }
      system.debug(sfw);
      List<RESTLocalStorefrontAPI.ObjectWrapper> objWrapperList = (List<RESTLocalStorefrontAPI.ObjectWrapper>) System.JSON.deserialize(sfw, List<RESTLocalStorefrontAPI.ObjectWrapper>.class);

      for(RESTLocalStorefrontAPI.ObjectWrapper objWrapper : objWrapperList){
        OrderPayloadWrapper orderPayload = new OrderPayloadWrapper();
        system.debug(objWrapper);

        if(String.isNotBlank(objWrapper.companyId)){

          // NEED TO FIND OUT HOW TO DIFFERENTIATE BETWEEN A SERVICE AND AN ADD ON <- don't need to do anymore since there won't be an add on for these and sending only current location

          // THIS IS ONLY POSSIBLE IF IT IS A CONVERTED LEAD AND THE LEAD PAYLOAD DIDN'T HAVE A COMPANYID
          if(objWrapper.companyId == objWrapper.locationId){
            system.debug('Account with No Parent');
            orderPayload = claimedLocationNewVendor(objWrapper);
        }else if(objWrapper.companyId != objWrapper.locationId){
          system.debug('Account with Parent');
          orderPayload = claimedLocationWithExistingVendor(objWrapper);
        }
      }else if(String.isNotBlank(objWrapper.locationId) && String.isBlank(objWrapper.companyId)){
        orderPayload = unclaimedVettedLead(objWrapper);
      }

      system.debug(orderPayload);
      system.debug(JSON.serialize(orderPayload));
      system.debug(JSON.serializePretty(orderPayload));
      // Instantiate a new http object
      Http h = new Http();
      // CSP-2651 Partners FulFillment JSON Token Functionality
      HttpRequest req = RestCalloutUtility.fulfillmentCallout(JSON.serialize(orderPayload));

      // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
      // HttpRequest req = new HttpRequest();
      // req.setTimeout(120000);
      // //http://qa-no-services.theknot.com/local-partners/salesfulfillment/v1/storefronts/fulfillments
      // req.setEndpoint('callout:Partners');
      // req.setMethod('POST');
      // req.setHeader('Content-Type', 'application/json');
      // req.setBody(JSON.serialize(orderPayload));

      // system.debug(req);
      // system.debug(req.getBody());

      // Send the request, and return a response
      HttpResponse res = h.send(req);
      system.debug(res.getBody());
      system.debug(res.getStatus());

      FulfillmentResponseWrapper partnerResponse = new FulfillmentResponseWrapper();
      partnerResponse = (FulfillmentResponseWrapper)JSON.deserialize(res.getBody(), FulfillmentResponseWrapper.class);
      system.debug(partnerResponse);

      Partner_Fulfillment_Response__c partnerFulfilmentResponse = new Partner_Fulfillment_Response__c();
      partnerFulfilmentResponse.Response_JSON__c = res.getBody();
      if(String.isBlank(objWrapper.companyId)){
        partnerFulfilmentResponse.Object_Type__c = 'Lead';
      }else{
        partnerFulfilmentResponse.Object_Type__c = 'Account';
      }
      insert partnerFulfilmentResponse;
    }
  }

  public static void nonFuturePartnerOrderCallout(String sfw){
    if(!XOGroupSettingUtility.getPartnerCalloutSetting()){
        return;
      }
      //system.debug(sfw);
      List<RESTLocalStorefrontAPI.ObjectWrapper> objWrapperList = (List<RESTLocalStorefrontAPI.ObjectWrapper>) System.JSON.deserialize(sfw, List<RESTLocalStorefrontAPI.ObjectWrapper>.class);

      for(RESTLocalStorefrontAPI.ObjectWrapper objWrapper : objWrapperList){
        OrderPayloadWrapper orderPayload = new OrderPayloadWrapper();
        system.debug(objWrapper);

        if(String.isNotBlank(objWrapper.companyId)){

          // NEED TO FIND OUT HOW TO DIFFERENTIATE BETWEEN A SERVICE AND AN ADD ON <- don't need to do anymore since there won't be an add on for these and sending only current location

          // THIS IS ONLY POSSIBLE IF IT IS A CONVERTED LEAD AND THE LEAD PAYLOAD DIDN'T HAVE A COMPANYID
          if(objWrapper.companyId == objWrapper.locationId){
            system.debug('Account with No Parent');
            orderPayload = claimedLocationNewVendor(objWrapper);
        }else if(objWrapper.companyId != objWrapper.locationId){
          system.debug('Account with Parent');
          orderPayload = claimedLocationWithExistingVendor(objWrapper);
        }
      }else if(String.isNotBlank(objWrapper.locationId) && String.isBlank(objWrapper.companyId)){
        orderPayload = unclaimedVettedLead(objWrapper);
      }

      system.debug(orderPayload);
      system.debug(JSON.serialize(orderPayload));
      system.debug(JSON.serializePretty(orderPayload));
      // Instantiate a new http object
      Http h = new Http();
      // CSP-2651 Partners FulFillment JSON Token Functionality
      HttpRequest req = RestCalloutUtility.fulfillmentCallout(JSON.serialize(orderPayload));
      
      // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
      // HttpRequest req = new HttpRequest();
      // req.setTimeout(120000);
      // //http://qa-no-services.theknot.com/local-partners/salesfulfillment/v1/storefronts/fulfillments
      // req.setEndpoint('callout:Partners');
      // req.setMethod('POST');
      // req.setHeader('Content-Type', 'application/json');
      // req.setBody(JSON.serialize(orderPayload));

      // system.debug(req);
      // system.debug(req.getBody());

      // Send the request, and return a response
      HttpResponse res = h.send(req);
      system.debug(res.getBody());
      system.debug(res.getStatus());

      FulfillmentResponseWrapper partnerResponse = new FulfillmentResponseWrapper();
      partnerResponse = (FulfillmentResponseWrapper)JSON.deserialize(res.getBody(), FulfillmentResponseWrapper.class);
      system.debug(partnerResponse);

      Partner_Fulfillment_Response__c partnerFulfilmentResponse = new Partner_Fulfillment_Response__c();
      partnerFulfilmentResponse.Response_JSON__c = res.getBody();
      if(String.isBlank(objWrapper.companyId)){
        partnerFulfilmentResponse.Object_Type__c = 'Lead';
      }else{
        partnerFulfilmentResponse.Object_Type__c = 'Account';
      }
      insert partnerFulfilmentResponse;
    }
  }

  private static String stringFieldValue(String val){
    return (String.isNotBlank(val)) ? val : '';
  }

  private static OrderPayloadWrapper claimedLocationNewVendor(RESTLocalStorefrontAPI.ObjectWrapper objWrapper){
    OrderPayloadWrapper orderPayload = new OrderPayloadWrapper();

    // NEED TO FIND OUT HOW TO DIFFERENTIATE BETWEEN A SERVICE AND AN ADD ON <- don't need to do anymore since there won't be an add on for these and sending only current location
    
        Account acctData = [select Id, DynamicsAccID__c, Name, Credit_Hold__c, Website, Email__c, Phone, Mobile__c, Vanity__c, 
                  BillingStreet, BillingCity, BillingStateCode, BillingPostalCode, BillingCountryCode,
                  ShippingStreet, ShippingCity, ShippingStateCode, ShippingPostalCode, ShippingCountryCode, 
                  Local_Sales_Market__r.Market_ID__c, Primary_Category__r.Taxonomy_ID__c, Partners_Metadata__c,
                  OwnerId, Owner.FirstName, Owner.LastName, Owner.Phone, Owner.Email, Fulfillment_Data__c,
                  Strategy_Specialist__c, Strategy_Specialist__r.FirstName, Strategy_Specialist__r.LastName, Strategy_Specialist__r.Phone, Strategy_Specialist__r.Email,
                  (select Id, Role, ContactId, Contact.FirstName, Contact.LastName, Contact.Email, Contact.Phone, Contact.MailingStreet,
                    Contact.MailingCity, Contact.MailingStateCode, Contact.MailingCountryCode, Contact.MailingPostalCode
                    from AccountContactRoles where Role IN ('Primary', 'Billing'))
                  from Account where DynamicsAccID__c =: objWrapper.companyId];

    orderPayload.companyId = stringFieldValue(acctData.DynamicsAccID__c);
    orderPayload.companyName = stringFieldValue(acctData.Name);
    orderPayload.creditHold = acctData.Credit_Hold__c;
    //orderPayload.claimed = true;
    orderPayload.website = stringFieldValue(acctData.Website);
    orderPayload.email = stringFieldValue(acctData.Email__c);

    for(Integer i = 0; i < acctPhoneFieldList.size(); i++){
      if(acctData.get(acctPhoneFieldList[i]) != null){
        OrderPayloadWrapper.PhoneNumberWrapper phoneData = new OrderPayloadWrapper.PhoneNumberWrapper();
        phoneData.Type = acctPhoneFieldMap.get(acctPhoneFieldList[i]);
        phoneData.phoneNumber = String.valueof(acctData.get(acctPhoneFieldList[i]));
        orderPayload.phones.add(phoneData);
      }
    }

    List<String> billingStreetList = new List<String>();
    if(String.isNotBlank(acctData.BillingStreet)){
      billingStreetList = acctData.BillingStreet.split('\\r\\n');
    }
    if(!billingStreetList.isEmpty()){
      orderPayload.address.street1 = billingStreetList[0];
      if(billingStreetList.size() > 1){
        orderPayload.address.street2 = billingStreetList[1];
      }
    }

    orderPayload.address.city = stringFieldValue(acctData.BillingCity);
    orderPayload.address.stateOrProvince = stringFieldValue(acctData.BillingStateCode);
    orderPayload.address.country = stringFieldValue(acctData.BillingCountryCode);
    orderPayload.address.postalCode = stringFieldValue(acctData.BillingPostalCode);

    orderPayload.salesrep.id = acctData.OwnerId;
    orderPayload.salesrep.firstName = stringFieldValue(acctData.Owner.FirstName);
    orderPayload.salesrep.lastName = stringFieldValue(acctData.Owner.LastName);
    orderPayload.salesrep.phone = stringFieldValue(acctData.Owner.Phone);
    orderPayload.salesrep.email = stringFieldValue(acctData.Owner.Email);

    orderPayload.strategySpecialist.id = acctData.Strategy_Specialist__c;
    orderPayload.strategySpecialist.firstName = stringFieldValue(acctData.Strategy_Specialist__r.FirstName);
    orderPayload.strategySpecialist.lastName = stringFieldValue(acctData.Strategy_Specialist__r.LastName);
    orderPayload.strategySpecialist.phone = stringFieldValue(acctData.Strategy_Specialist__r.Phone);
    orderPayload.strategySpecialist.email = stringFieldValue(acctData.Strategy_Specialist__r.Email);

    if(!acctData.AccountContactRoles.isEmpty()){
      for(AccountContactRole record : acctData.AccountContactRoles){
        OrderPayloadWrapper.ContactWrapper cont = new OrderPayloadWrapper.ContactWrapper();
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
        orderPayload.contacts.add(cont);
      }
    }

    OrderPayloadWrapper.LocationWrapper acctLocation = new OrderPayloadWrapper.LocationWrapper();
    acctLocation.locationId = stringFieldValue(acctData.DynamicsAccID__c);
    acctLocation.name = stringFieldValue(acctData.Name);
    acctLocation.website = stringFieldValue(acctData.Website);
    acctLocation.email = stringFieldValue(acctData.Email__c);

    for(Integer i = 0; i < acctPhoneFieldList.size(); i++){
      if(acctData.get(acctPhoneFieldList[i]) != null){
        OrderPayloadWrapper.PhoneNumberWrapper phoneData = new OrderPayloadWrapper.PhoneNumberWrapper();
        phoneData.Type = acctPhoneFieldMap.get(acctPhoneFieldList[i]);
        phoneData.phoneNumber = String.valueof(acctData.get(acctPhoneFieldList[i]));
        acctLocation.phones.add(phoneData);
      }
    }

    List<String> shippingStreetList = new List<String>();
    if(String.isNotBlank(acctData.ShippingStreet)){
      shippingStreetList = acctData.ShippingStreet.split('\\r\\n');
    }
    if(!shippingStreetList.isEmpty()){
      acctLocation.address.street1 = shippingStreetList[0];
      if(shippingStreetList.size() > 1){
        acctLocation.address.street2 = shippingStreetList[1];
      }
    }

    acctLocation.address.city = stringFieldValue(acctData.ShippingCity);
    acctLocation.address.stateOrProvince = stringFieldValue(acctData.ShippingStateCode);
    acctLocation.address.country = stringFieldValue(acctData.ShippingCountryCode);
    acctLocation.address.postalCode = stringFieldValue(acctData.ShippingPostalCode);

    if(String.isNotBlank(acctData.Partners_Metadata__c)){
      acctLocation.metadata = (Map<String, Object>)JSON.deserializeUntyped(acctData.Partners_Metadata__c);
    }

    OrderPayloadWrapper.ServiceWrapper service = new OrderPayloadWrapper.ServiceWrapper();
    service.categoryId = acctData.Primary_Category__r.Taxonomy_ID__c;
    service.marketCode = (XOGroupSettingUtility.sfLPMarketCodeMap().containsKey(acctData.Local_Sales_Market__r.Market_ID__c)) ? XOGroupSettingUtility.sfLPMarketCodeMap().get(acctData.Local_Sales_Market__r.Market_ID__c) : acctData.Local_Sales_Market__r.Market_ID__c;
    service.tier = 'Freemium';
    service.displayStatus = 'Active';
    acctLocation.services.add(service);

    orderPayload.locations.add(acctLocation);

    system.debug(orderPayload);
    system.debug('IT WORKED');
    
    return orderPayload;
  }

  public static OrderPayloadWrapper claimedLocationWithExistingVendor(RESTLocalStorefrontAPI.ObjectWrapper objWrapper){
    OrderPayloadWrapper orderPayload = new OrderPayloadWrapper();

    Account acctData = [select Id, DynamicsAccID__c, Name, Credit_Hold__c, Website, Email__c, Phone, Mobile__c, Vanity__c, 
                  BillingStreet, BillingCity, BillingStateCode, BillingPostalCode, BillingCountryCode,
                  ShippingStreet, ShippingCity, ShippingStateCode, ShippingPostalCode, ShippingCountryCode, 
                  Local_Sales_Market__r.Market_ID__c, Primary_Category__r.Taxonomy_ID__c, 
                  OwnerId, Owner.FirstName, Owner.LastName, Owner.Phone, Owner.Email, Fulfillment_Data__c,
                  Strategy_Specialist__c, Strategy_Specialist__r.FirstName, Strategy_Specialist__r.LastName, Strategy_Specialist__r.Phone, Strategy_Specialist__r.Email,
                  (select Id, Role, ContactId, Contact.FirstName, Contact.LastName, Contact.Email, Contact.Phone, Contact.MailingStreet,
                    Contact.MailingCity, Contact.MailingStateCode, Contact.MailingCountryCode, Contact.MailingPostalCode
                    from AccountContactRoles where Role IN ('Primary', 'Billing'))
                  from Account where DynamicsAccID__c =: objWrapper.companyId];

    orderPayload.companyId = stringFieldValue(acctData.DynamicsAccID__c);
    orderPayload.companyName = stringFieldValue(acctData.Name);
    orderPayload.creditHold = acctData.Credit_Hold__c;
    //orderPayload.claimed = true;
    orderPayload.website = stringFieldValue(acctData.Website);
    orderPayload.email = stringFieldValue(acctData.Email__c);

    for(Integer i = 0; i < acctPhoneFieldList.size(); i++){
      if(acctData.get(acctPhoneFieldList[i]) != null){
        OrderPayloadWrapper.PhoneNumberWrapper phoneData = new OrderPayloadWrapper.PhoneNumberWrapper();
        phoneData.Type = acctPhoneFieldMap.get(acctPhoneFieldList[i]);
        phoneData.phoneNumber = String.valueof(acctData.get(acctPhoneFieldList[i]));
        orderPayload.phones.add(phoneData);
      }
    }

    List<String> billingStreetList = new List<String>();
    if(String.isNotBlank(acctData.BillingStreet)){
      billingStreetList = acctData.BillingStreet.split('\\r\\n');
    }
    if(!billingStreetList.isEmpty()){
      orderPayload.address.street1 = billingStreetList[0];
      if(billingStreetList.size() > 1){
        orderPayload.address.street2 = billingStreetList[1];
      }
    }

    orderPayload.address.city = stringFieldValue(acctData.BillingCity);
    orderPayload.address.stateOrProvince = stringFieldValue(acctData.BillingStateCode);
    orderPayload.address.country = stringFieldValue(acctData.BillingCountryCode);
    orderPayload.address.postalCode = stringFieldValue(acctData.BillingPostalCode);

    orderPayload.salesrep.id = acctData.OwnerId;
    orderPayload.salesrep.firstName = stringFieldValue(acctData.Owner.FirstName);
    orderPayload.salesrep.lastName = stringFieldValue(acctData.Owner.LastName);
    orderPayload.salesrep.phone = stringFieldValue(acctData.Owner.Phone);
    orderPayload.salesrep.email = stringFieldValue(acctData.Owner.Email);

    orderPayload.strategySpecialist.id = acctData.Strategy_Specialist__c;
    orderPayload.strategySpecialist.firstName = stringFieldValue(acctData.Strategy_Specialist__r.FirstName);
    orderPayload.strategySpecialist.lastName = stringFieldValue(acctData.Strategy_Specialist__r.LastName);
    orderPayload.strategySpecialist.phone = stringFieldValue(acctData.Strategy_Specialist__r.Phone);
    orderPayload.strategySpecialist.email = stringFieldValue(acctData.Strategy_Specialist__r.Email);

    if(!acctData.AccountContactRoles.isEmpty()){
      for(AccountContactRole record : acctData.AccountContactRoles){
        OrderPayloadWrapper.ContactWrapper cont = new OrderPayloadWrapper.ContactWrapper();
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
        orderPayload.contacts.add(cont);
      }
    }

    Account locationData = [select Id, DynamicsAccID__c, Name, Credit_Hold__c, Website, Email__c, Phone, Mobile__c, Vanity__c, 
                  BillingStreet, BillingCity, BillingStateCode, BillingPostalCode, BillingCountryCode,
                  ShippingStreet, ShippingCity, ShippingStateCode, ShippingPostalCode, ShippingCountryCode, 
                  Local_Sales_Market__r.Market_ID__c, Primary_Category__r.Taxonomy_ID__c, Partners_Metadata__c,
                  OwnerId, Owner.FirstName, Owner.LastName, Owner.Phone, Owner.Email, Fulfillment_Data__c,
                  (select Id, Role, ContactId, Contact.FirstName, Contact.LastName, Contact.Email, Contact.Phone, Contact.MailingStreet,
                    Contact.MailingCity, Contact.MailingStateCode, Contact.MailingCountryCode, Contact.MailingPostalCode
                    from AccountContactRoles where Role IN ('Primary', 'Billing'))
                  from Account where DynamicsAccID__c =: objWrapper.locationId];

    OrderPayloadWrapper.LocationWrapper acctLocation = new OrderPayloadWrapper.LocationWrapper();
    acctLocation.locationId = stringFieldValue(locationData.DynamicsAccID__c);
    acctLocation.name = stringFieldValue(locationData.Name);
    acctLocation.website = stringFieldValue(locationData.Website);
    acctLocation.email = stringFieldValue(locationData.Email__c);
    
    for(Integer i = 0; i < acctPhoneFieldList.size(); i++){
      if(locationData.get(acctPhoneFieldList[i]) != null){
        OrderPayloadWrapper.PhoneNumberWrapper phoneData = new OrderPayloadWrapper.PhoneNumberWrapper();
        phoneData.Type = acctPhoneFieldMap.get(acctPhoneFieldList[i]);
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

    if(String.isNotBlank(locationData.Partners_Metadata__c)){
      acctLocation.metadata = (Map<String, Object>)JSON.deserializeUntyped(locationData.Partners_Metadata__c);
    }

    OrderPayloadWrapper.ServiceWrapper service = new OrderPayloadWrapper.ServiceWrapper();
    service.categoryId = locationData.Primary_Category__r.Taxonomy_ID__c;
    service.marketCode = (XOGroupSettingUtility.sfLPMarketCodeMap().containsKey(locationData.Local_Sales_Market__r.Market_ID__c)) ? XOGroupSettingUtility.sfLPMarketCodeMap().get(locationData.Local_Sales_Market__r.Market_ID__c) : locationData.Local_Sales_Market__r.Market_ID__c;
    service.tier = 'Freemium';
    service.displayStatus = 'Active';
    acctLocation.services.add(service);

    orderPayload.locations.add(acctLocation);

    system.debug(JSON.serializePretty(orderPayload));

    return orderPayload;
  }

  public static OrderPayloadWrapper unclaimedVettedLead(RESTLocalStorefrontAPI.ObjectWrapper objWrapper){
    OrderPayloadWrapper orderPayload = new OrderPayloadWrapper();

    Lead leadData = [select Id, DynamicsLeadID__c, Storefront_Status__c, Fulfillment_Data__c, Company, Website, Email, 
                Phone, HomePhone__c, MobilePhone, Fax, Street, City, StateCode, PostalCode, CountryCode, 
                FirstName, LastName, Local_Sales_Market__r.Market_ID__c, Primary_Category__r.Taxonomy_ID__c, Partners_Metadata__c,
                OwnerId, Owner.FirstName, Owner.LastName, Owner.Phone, Owner.Email,
                Strategy_Specialist__c, Strategy_Specialist__r.FirstName, Strategy_Specialist__r.LastName, Strategy_Specialist__r.Phone, Strategy_Specialist__r.Email
                from Lead where DynamicsLeadID__c =: objWrapper.locationId];
    List<String> streetList = new List<String>();
    if(String.isNotBlank(leadData.Street)){
      streetList = leadData.Street.split('\\r\\n');
    }

    //OrderPayloadWrapper orderPayload = new OrderPayloadWrapper();
    orderPayload.companyId = /*(leadData.Storefront_Status__c == 'Claimed') ? leadData.DynamicsLeadID__c :*/ '';
    orderPayload.companyName = stringFieldValue(leadData.Company);
    orderPayload.creditHold = false;
    //orderPayload.claimed = /*(leadData.Storefront_Status__c == 'Claimed') ? true :*/ false;
    orderPayload.website = stringFieldValue(leadData.Website);
    orderPayload.email = stringFieldValue(leadData.Email);
    orderPayload.phones = new List<OrderPayloadWrapper.PhoneNumberWrapper>();

    for(Integer i = 0; i < phoneFieldList.size(); i++){
      if(leadData.get(phoneFieldList[i]) != null){
        OrderPayloadWrapper.PhoneNumberWrapper phoneData = new OrderPayloadWrapper.PhoneNumberWrapper();
        phoneData.Type = phoneFieldMap.get(phoneFieldList[i]);
        phoneData.phoneNumber = String.valueof(leadData.get(phoneFieldList[i]));
        orderPayload.phones.add(phoneData);
      }
    }

    orderPayload.address.city = stringFieldValue(leadData.City);
    orderPayload.address.stateOrProvince = stringFieldValue(leadData.StateCode);
    orderPayload.address.country = stringFieldValue(leadData.CountryCode);
    orderPayload.address.postalCode = stringFieldValue(leadData.PostalCode);

    orderPayload.salesrep.id = leadData.OwnerId;
    orderPayload.salesrep.firstName = stringFieldValue(leadData.Owner.FirstName);
    orderPayload.salesrep.lastName = stringFieldValue(leadData.Owner.LastName);
    orderPayload.salesrep.phone = stringFieldValue(leadData.Owner.Phone);
    orderPayload.salesrep.email = stringFieldValue(leadData.Owner.Email);

    orderPayload.strategySpecialist.id = leadData.Strategy_Specialist__c;
    orderPayload.strategySpecialist.firstName = stringFieldValue(leadData.Strategy_Specialist__r.FirstName);
    orderPayload.strategySpecialist.lastName = stringFieldValue(leadData.Strategy_Specialist__r.LastName);
    orderPayload.strategySpecialist.phone = stringFieldValue(leadData.Strategy_Specialist__r.Phone);
    orderPayload.strategySpecialist.email = stringFieldValue(leadData.Strategy_Specialist__r.Email);

    OrderPayloadWrapper.ContactWrapper leadContact = new OrderPayloadWrapper.ContactWrapper();
    leadContact.firstName = stringFieldValue(leadData.FirstName);
    leadContact.lastName = stringFieldValue(leadData.LastName);
    leadContact.email = stringFieldValue(leadData.Email);
    leadContact.role = 'Primary';
    leadContact.address.city = stringFieldValue(leadData.City);
    leadContact.address.stateOrProvince = stringFieldValue(leadData.StateCode);
    leadContact.address.country = stringFieldValue(leadData.CountryCode);
    leadContact.address.postalCode = stringFieldValue(leadData.PostalCode);
    leadContact.phone = stringFieldValue(leadData.Phone);

    OrderPayloadWrapper.LocationWrapper leadLocation = new OrderPayloadWrapper.LocationWrapper();
    leadLocation.locationId = stringFieldValue(leadData.DynamicsLeadID__c);
    leadLocation.name = stringFieldValue(leadData.Company);
    leadLocation.website = stringFieldValue(leadData.Website);
    leadLocation.email = stringFieldValue(leadData.Email);

    // ADD PHONE LOGIC FOR LOCATION PHONE NUMBER // IMPORTANT
    // Added PHONE number to the location for ticket CSP-2117
    for(Integer i = 0; i < phoneFieldList.size(); i++){
      if(leadData.get(phoneFieldList[i]) != null){
        OrderPayloadWrapper.PhoneNumberWrapper phoneData = new OrderPayloadWrapper.PhoneNumberWrapper();
        phoneData.Type = phoneFieldMap.get(phoneFieldList[i]);
        phoneData.phoneNumber = String.valueof(leadData.get(phoneFieldList[i]));
        leadLocation.phones.add(phoneData);
      }
    }

    leadLocation.address.city = stringFieldValue(leadData.City);
    leadLocation.address.stateOrProvince = stringFieldValue(leadData.StateCode);
    leadLocation.address.country = stringFieldValue(leadData.CountryCode);
    leadLocation.address.postalCode = stringFieldValue(leadData.PostalCode);

    OrderPayloadWrapper.ServiceWrapper service = new OrderPayloadWrapper.ServiceWrapper();
    service.categoryId = leadData.Primary_Category__r.Taxonomy_ID__c;
    service.marketCode = (XOGroupSettingUtility.sfLPMarketCodeMap().containsKey(leadData.Local_Sales_Market__r.Market_ID__c)) ? XOGroupSettingUtility.sfLPMarketCodeMap().get(leadData.Local_Sales_Market__r.Market_ID__c) : leadData.Local_Sales_Market__r.Market_ID__c;
    service.tier = 'Freemium';
    service.displayStatus = 'Active';
    leadLocation.services.add(service);

    // MOVE ALL ADDRESS BUILDER HERE
    if(!streetList.isEmpty()){
      orderPayload.address.street1 = streetList[0];
      leadContact.address.street1 = streetList[0];
      leadLocation.address.street1 = streetList[0];
      if(streetList.size() > 1){
        orderPayload.address.street2 = streetList[1];
        leadContact.address.street2 = streetList[1];
        leadLocation.address.street2 = streetList[1];
      }
    }

    if(String.isNotBlank(leadData.Partners_Metadata__c)){
      leadLocation.metadata = (Map<String, Object>)JSON.deserializeUntyped(leadData.Partners_Metadata__c);
    }

    orderPayload.contacts.add(leadContact);
    orderPayload.locations.add(leadLocation);
    system.debug(JSON.serializePretty(orderPayload));

    //leadData.Fulfillment_Data__c = JSON.serializePretty(orderPayload);
    //update leadData;

    return orderPayload;
  }

  public class FulfillmentResponseWrapper{
    public List<FulfillmentLocationWrapper> locations {get; set;}
    public List<FulfillmentErrorWrapper> errors {get; set;} 
    public String companyId {get; set;}
  }

  public class FulfillmentLocationWrapper{
    public String locationId {get; set;}
    public Boolean success {get; set;}
    public List<FulfilledStorefrontWrapper> fulfilledStorefronts {get; set;}
    public List<FulfillmentErrorWrapper> errors {get; set;}
  }

  public class FulfilledStorefrontWrapper{
    public String storefrontId {get; set;}
    public String storefrontDisplayId {get; set;}
    public String storefrontName {get; set;}
    public String storefrontTier {get; set;}
    public String storefrontStatus {get; set;}
    public String marketCode {get; set;}
    public String categoryId {get; set;}
    public String subscriptionId {get; set;}
    public String lineItemId {get; set;}
    public List<FulfilledAddOnsWrapper> fulfilledAddOns;
  }

  public class FulfillmentErrorWrapper{
    public String message {get; set;}
  }

  public class FulfilledAddOnsWrapper {
    public String profileAddOnId;
    public String addOnName;
    public String marketCode;
    public String categoryId;
    public String subscriptionId;
    public String lineItemId;
    public String addOnStatusCode;
  }
}