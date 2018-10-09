public with sharing class LeadManualStorefrontFulfillmentContr {

  public Lead leadRecord {get; set;}
  public Lead originalLead {get; set;}
  public Boolean fulfillSF {get; set;}

  public static Boolean manualLeadFulfillment = false;

  public LeadManualStorefrontFulfillmentContr(ApexPages.StandardController stdController) {
    
    leadRecord = (Lead)stdController.getRecord();
    originalLead = leadRecord.clone(false, true);

    // CSP-2550 - The Status should not be modified
    //leadRecord.Status = 'Qualified';
    leadRecord.Storefront_Status__c = 'Unclaimed';

    fulfillSF = false;
  }

  public void saveData(){
    try{
      manualLeadFulfillment = true;
      update leadRecord;
      manualLeadFulfillment = false;
      fulfillSF = true;
    }catch(Exception E){
      fulfillSF = false;
    }
  }

  public void fulfillStorefront(){
    if(!XOGroupSettingUtility.getPartnerCalloutSetting()){
      ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Partner Fulfillment is currently off!');
          ApexPages.addMessage(myMsg);
          return;
    }
    
    RESTLocalStorefrontAPI.ObjectWrapper objWrapper = new RESTLocalStorefrontAPI.ObjectWrapper();
    objWrapper.locationId = leadRecord.DynamicsLeadId__c;

    OrderPayloadWrapper orderPayload = new OrderPayloadWrapper();
    orderPayload = PartnerCallouts.unclaimedVettedLead(objWrapper);

    Http h = new Http();
    HttpResponse res;
    HttpRequest req;
    try {
      // CSP-2651 Partners FulFillment JSON Token Functionality
      req = RestCalloutUtility.fulfillmentCallout(JSON.serialize(orderPayload));

      // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
      // HttpRequest req = new HttpRequest();
      // req.setTimeout(120000);
      // //http://qa-no-services.theknot.com/local-partners/salesfulfillment/v1/storefronts/fulfillments
      // req.setEndpoint('callout:Partners');
      // req.setMethod('POST');
      // req.setHeader('Content-Type', 'application/json');
      // req.setBody(JSON.serialize(orderPayload));
        
      // System.debug(LoggingLevel.INFO, '*** req.getBody(): ' + req.getBody());

      // Send the request, and return a response
      res = h.send(req);
      system.debug('222222222 req.getBody()' + req.getBody());
      system.debug('222222222 res.getBody()' + res.getBody());
    }
    catch (Exception ex) {
      XO_Exception__c xoException = ExceptionUtility.consumeException(ex, true);
    }

    PartnerCallouts.FulfillmentResponseWrapper partnerResponse = new PartnerCallouts.FulfillmentResponseWrapper();
    partnerResponse = (PartnerCallouts.FulfillmentResponseWrapper)JSON.deserialize(res.getBody(), PartnerCallouts.FulfillmentResponseWrapper.class);
    system.debug(partnerResponse);

    Partner_Fulfillment_Response__c partnerFulfilmentResponse = new Partner_Fulfillment_Response__c();
    partnerFulfilmentResponse.Response_JSON__c = res.getBody();
    if(String.isBlank(objWrapper.companyId)){
      partnerFulfilmentResponse.Object_Type__c = 'Lead';
    }else{
      partnerFulfilmentResponse.Object_Type__c = 'Account';
    }

    system.debug('333333333 ' + partnerFulfilmentResponse); 
    insert partnerFulfilmentResponse;

    Boolean anyError = false;
    if(partnerResponse.errors != null && !partnerResponse.errors.isEmpty()){
      ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, JSON.serializePretty(partnerResponse.errors));
        ApexPages.addMessage(myMsg);
        anyError = true;
    }else if(partnerResponse.locations != null && !partnerResponse.locations.isEmpty()){
    for(PartnerCallouts.FulfillmentLocationWrapper record : partnerResponse.locations){
      if(record.errors != null && !record.errors.isEmpty()){
        for(PartnerCallouts.FulfillmentErrorWrapper childRecord : record.errors){
          ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, childRecord.message);
              ApexPages.addMessage(myMsg);
              anyError = true;
            }
        }
      }
    }

    if(!anyError){
      ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO, 'Unclaimed Freemium Storefront Fulfilled');
          ApexPages.addMessage(myMsg);
    }
  }

  public PageReference recordPageRedirect(){
    PageReference pageRef = new PageReference('/'+leadRecord.Id);
    pageRef.setRedirect(true);

        return pageRef;
  }

}