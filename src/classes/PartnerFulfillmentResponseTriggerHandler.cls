public without sharing class PartnerFulfillmentResponseTriggerHandler implements XOTrigger{

  List<Fulfillment_Response__c> fulfillmentResponseList = new List<Fulfillment_Response__c>();
  Set<String> DynamicIdSet = new Set<String>();
  Map<String, Map<String, String>> tranDynamicIdStatusMap = new Map<String, Map<String, String>>();
  Map<String,Boolean> responseMap = new Map<String,Boolean>();
  List<XO_Exception__C> xoExceptionList = new List<XO_Exception__C>();


  public PartnerFulfillmentResponseTriggerHandler() { 
  }
  
  public void bulkBefore(){
  }

  public void bulkAfter(){
  }
  
  public void beforeInsert(SObject so){
  }

  public void beforeUpdate(SObject oldSo, SObject so){
  }
  
  public void beforeDelete(SObject so){
  }
 
  public void afterInsert(SObject so){
    Partner_Fulfillment_Response__c record = (Partner_Fulfillment_Response__c)so;

    try{
      if(record.Type__c == 'Storefront Fulfillment' || String.isBlank(record.Type__c)){
                
        PartnerCallouts.FulfillmentResponseWrapper fulfillResponse = (PartnerCallouts.FulfillmentResponseWrapper)JSON.deserialize(record.Response_JSON__c, PartnerCallouts.FulfillmentResponseWrapper.class);

        buildLeadAccountStorefrontList(fulfillResponse, record.Object_Type__c, record);
        
      } else if(record.Type__c == 'Account Update'){
        Map<String, Object> jsonResponse = (Map<String, Object>)JSON.deserializeUntyped(record.Response_JSON__c);
        Account lookupAccount = new Account(DynamicsAccID__c = (String)jsonResponse.get('companyId'));

        Fulfillment_Response__c newResponse = assignResFromPartnerFulfillment(lookupAccount, record);

        if(jsonResponse.get('errors') != null){
          newResponse.Errors__c = true;
        }
        fulfillmentResponseList.add(newResponse);
      } 
      
    }
    catch(Exception ex){
      // ExceptionUtility.consumeException(exceptionResult, true);
      // CSP-1802 PartnerFulfillmentResponseTriggerHandler Error Handling
      // Fill up the Failure Area and Severity to better describe the errors, also not implement the DML action, 
      // will only adding to xoExceptionList and DML at the end of the transaction
      XO_Exception__c newException = ExceptionUtility.consumeException(ex, false);
      newException.Failure_Area__c = 'Local Partners';
      newException.Severity__c = 'Major';
      xoExceptionList.add(newException);
    }
  }
    
  public void afterUpdate(SObject oldSo, SObject so){
  }

  public void afterDelete(SObject so){
  }      
  
  public void beforeAndFinally(){
  }

  public void afterAndFinally(){

    // CSP-1802 using common list
    List<XO_Exception__C> exceptionList = new List<XO_Exception__c>();

    if(!fulfillmentResponseList.isEmpty()){

      // CSP-1802 PartnerFulfillmentResponseTriggerHandler Error Handling
      // support partial insert for fulfillmentResponseList
      Database.SaveResult[] insertResults = Database.insert(fulfillmentResponseList, false);
      exceptionList = ExceptionUtility.consumeException((List<Fulfillment_Response__c>)fulfillmentResponseList, 
                                                        insertResults,
                                                        'Major',
                                                        'Local Partners',
                                                        false);

      if(!exceptionList.isEmpty()){
        xoExceptionList.addAll(exceptionList);
      }
    }

    // CSP-1802 PartnerFulfillmentResponseTriggerHandler Error Handling
    // insert the exception list at the end
    if(!xoExceptionList.isEmpty()){
      insert xoExceptionList;
    }
    
  }

  /**
   *   [assignResFromPartnerFulfillment: Populating fulfillment response from partner fulfillment]
   *
   *   @author [Ruchit S]
   *   @date   2016-11-09
   *   @param  {[type]}                  lookupAccount              [Account record with DynamicsAccID__c populated]
   *   @param  {[type]}                  partnerFulfillmentResponse [Partner fulfillment response]
   *   @return {Fulfillment_Response__c}                            [Fulfillment reponse populated with Account, Location response and partnet fulfillment response]
   */
  public Fulfillment_Response__c assignResFromPartnerFulfillment(Account lookupAccount, Partner_Fulfillment_Response__c partnerFulfillmentResponse) {
    Fulfillment_Response__c newResponse = new Fulfillment_Response__c();
    newResponse.Account__r = lookupAccount;
    newResponse.Location_Response__c = partnerFulfillmentResponse.Response_JSON__c;
    newResponse.Partner_Fulfillment_Response__c = partnerFulfillmentResponse.Id;
    return newResponse;
  }

  /**
   *   [assignResFromLocationWrapper: Populating fulfillment response from fulfillment location wrapper]
   *
   *   @author [author]
   *   @date   2016-11-09
   *   @param  {[type]}                  objectType                 [Account or Lead]
   *   @param  {[type]}                  fulfillmentLocationWrapper [FulfillmentLocationWrapper]
   *   @param  {[type]}                  responseRecord             [partner fulfillment response]
   *   @return {Fulfillment_Response__c}                            [Fulfillment reponse populated with Account, Location response and partnet fulfillment response]
   */
  public Fulfillment_Response__c assignResFromLocationWrapper(String objectType, PartnerCallouts.FulfillmentLocationWrapper fulfillmentLocationWrapper, Partner_Fulfillment_Response__c responseRecord) {

    Fulfillment_Response__c newResponse = new Fulfillment_Response__c();

    if(objectType == 'Lead') {
      Lead lookupLead = new Lead(DynamicsLeadID__c = fulfillmentLocationWrapper.locationId);
      newResponse.Lead__r = lookupLead; 
    } else if(objectType == 'Account') {
      Account lookupAccount = new Account(DynamicsAccID__c = fulfillmentLocationWrapper.locationId);
      newResponse.Account__r = lookupAccount;
    }

    newResponse.Location_Response__c = JSON.serializePretty(fulfillmentLocationWrapper);
    newResponse.Partner_Fulfillment_Response__c = responseRecord.Id; 
    return newResponse;
  }

  /**
   *   [buildLeadAccountStorefrontList: Build partner fulfillment response record depending on the objects type]
   *   @date   2016-11-09
   *   @param  {[type]}   fulfillResponse [Fulfullment response wrapper containing data such as FulfillmentLocationWrapper, FulfullmentErrorWrapper and CompanyId]
   *   @param  {[type]}   objectType      [Type of object: Account or Lead]
   *   @param  {[type]}   responseRecord  [Partner_Fulfillment_Response__c]
   */
  private void buildLeadAccountStorefrontList(PartnerCallouts.FulfillmentResponseWrapper fulfillResponse, String objectType, Partner_Fulfillment_Response__c responseRecord){
    if(fulfillResponse.errors == null || fulfillResponse.errors.isEmpty()){
        
      if(fulfillResponse.locations != null && !fulfillResponse.locations.isEmpty()){
          
        for(PartnerCallouts.FulfillmentLocationWrapper record : fulfillResponse.locations){
            
          if(record.errors == null || record.errors.isEmpty()){
            responseMap.put(record.locationId,true);
            
            if(objectType == 'Lead'){
              Fulfillment_Response__c newResponse = assignResFromLocationWrapper(objectType, record, responseRecord);
              fulfillmentResponseList.add(newResponse);
            }else if(objectType == 'Account'){
              Fulfillment_Response__c newResponse = assignResFromLocationWrapper(objectType, record, responseRecord);
              fulfillmentResponseList.add(newResponse);
            }
          } else if(record.errors != null && !record.errors.isEmpty()){
            responseMap.put(record.locationId,false);
            
            if(objectType == 'Lead'){
              Fulfillment_Response__c newResponse = assignResFromLocationWrapper(objectType, record, responseRecord);
              newResponse.Errors__c = true;
              fulfillmentResponseList.add(newResponse);
            }else if(objectType == 'Account'){
              Fulfillment_Response__c newResponse = assignResFromLocationWrapper(objectType, record, responseRecord);
              newResponse.Errors__c = true;
              fulfillmentResponseList.add(newResponse);
              
              for(PartnerCallouts.FulfillmentErrorWrapper errorMessage :record.errors){
                if(errorMessage.message.contains(system.Label.IgnoreParentMessage1) || errorMessage.message.contains(system.Label.IgnoreParentMessage2)){
                  DynamicIdSet.add(record.locationId);
                }
              }
            }
          }
        }
      }
    }else if(fulfillResponse.errors != null && !fulfillResponse.errors.isEmpty() && String.isNotBlank(fulfillResponse.companyId)){
      responseMap.put(fulfillResponse.CompanyId,FALSE);
      Account lookupAccount = new Account(DynamicsAccID__c = fulfillResponse.companyId);

      Fulfillment_Response__c newResponse = new Fulfillment_Response__c();
      newResponse.Account__r = lookupAccount;
      newResponse.Location_Response__c = JSON.serializePretty(fulfillResponse);
      newResponse.Partner_Fulfillment_Response__c = responseRecord.Id;
      newResponse.Errors__c = true;

      fulfillmentResponseList.add(newResponse);
    }
  }
}