public without sharing class RequestStorefrontRepublishController {

    public Account acct {get; set;}
    public static Boolean requestFulfillRunning = false;
    public String accountAction {get; set;} //publish or re-publish
    public String returnBack {get; set;} //on cancellation of the process or Back.
    public Boolean requestProcessed {get; set;}//once method is called, set it to true.
    public String pageMessages {get;set;}
    public Boolean isAccountUpdated {get; set;}
    
    public Boolean enableActionButton{get; set;}
    public Boolean enableCancelButton{get; set;}
    
    public RequestStorefrontRepublishController() {
        enableActionButton= true;
        enableCancelButton= true;
        requestProcessed = false;
        isAccountUpdated = false;
        pageMessages = '';
        accountAction = 'publish';
        
        String acctId = ApexPages.currentPage().getParameters().get('acctId');
        
        if(String.isNotBlank(acctId)){
            acct = [select Id, Fulfilled__c, DynamicsAccId__c, ParentId, Parent.DynamicsAccId__c, Name, Storefront_Republish_Requested__c, Fulfill_Storefront__c, (select Id from Zuora__Subscriptions__r) from Account where Id = : acctId];
            if(!acct.Zuora__Subscriptions__r.isEmpty()){
                accountAction = 'Re-publish';
            }else if(String.isNotBlank(acct.ParentId)){
                Account parentAcct = [select Id, DynamicsAccId__c, Name, Storefront_Republish_Requested__c, Fulfill_Storefront__c, (select Id from Zuora__Subscriptions__r) from Account where Id = : acct.ParentId];
                if(!parentAcct.Zuora__Subscriptions__r.isEmpty()){
                    accountAction = 'Re-publish';
                }
            }
        }
        
        returnBack = 'Cancel/Go Back';
    }
    
    public void initiateProcess(){
        enableActionButton= false;
        enableCancelButton= false;
        
        pageMessages = '';
        requestProcessed = true;
        returnBack = 'Go Back';
    }
    
    /**
     *@description : Update the account "FullFill Storefront" field to true.
     *
     */
    public void updateAccount(){
        enableActionButton= false;
        enableCancelButton= false;
        requestProcessed = true;
        returnBack = 'Go Back';
        
        acct.Fulfill_Storefront__c = true;
        requestFulfillRunning = true;
        Database.SaveResult saveResult = Database.update(acct, false);
        if (!saveResult.isSuccess()) {
        	
            for (Database.Error e : saveResult.getErrors()) {
            	pageMessages = 'ERROR:' +'\n'+e.getMessage();
                enableCancelButton=true;
                
                ExceptionUtility.createExceptionRecord(acct.id, pageMessages, true);
            }
        }else{
            isAccountUpdated = true;
        }
        
    }
    
    /**
     *@description : return vf page to related Account record.
     */
    public PageReference cancelProcess(){
        PageReference oldPage = new PageReference('/' + acct.id);
        oldPage.setRedirect(true);
        return oldPage;
    } 
    
    /**
     *@description : on any issue in process, revert the account changes.
     *
     */
    private void resetAccount(){
        acct.Fulfill_Storefront__c = false;
        Database.SaveResult saveResult = Database.update(acct, false);
        
    }
    
    /**
     *@description: call http request and create fulfillment response.
     *
     */
    public void fulfillStorefront(){
    	enableCancelButton=true;
        if(!XOGroupSettingUtility.getPartnerCalloutSetting()){
            pageMessages = 'ERROR: Partner Fulfillment is currently off!';
            resetAccount();
            
            ExceptionUtility.createExceptionRecord(acct.id, pageMessages, true);
            return;
        }
        
        RESTLocalStorefrontAPI.ObjectWrapper objWrapper = new RESTLocalStorefrontAPI.ObjectWrapper();
        objWrapper.locationId = acct.DynamicsAccId__c;
        if(String.isNotBlank(acct.ParentId) && acct.Ignore_Parent_Account__c == false){
            objWrapper.companyId = acct.Parent.DynamicsAccId__c;
        }else{
            objWrapper.companyId = acct.DynamicsAccId__c;
        }

        OrderPayloadWrapper orderPayload = new OrderPayloadWrapper();
        orderPayload = PartnerCallouts.claimedLocationWithExistingVendor(objWrapper);

        Http h = new Http();
        // CSP-2651 Partners FulFillment JSON Token Functionality
        HttpRequest req = RestCalloutUtility.fulfillmentCallout(JSON.serialize(orderPayload));
        
        // // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
        // HttpRequest req = new HttpRequest();
        // req.setTimeout(120000);
        // //http://qa-no-services.theknot.com/local-partners/salesfulfillment/v1/storefronts/fulfillments
        // req.setEndpoint('callout:Partners');
        // req.setMethod('POST');
        // req.setHeader('Content-Type', 'application/json');
        // req.setBody(JSON.serialize(orderPayload));
        System.debug(LoggingLevel.INFO, '*** req: ' + req.getBody());
        // Send the request, and return a response
        HttpResponse res = h.send(req);

        System.debug(LoggingLevel.INFO, '*** res: ' + res.getBody());
        
        Boolean anyError = false;
        PartnerCallouts.FulfillmentResponseWrapper partnerResponse = new PartnerCallouts.FulfillmentResponseWrapper();
        try{
            //partnerResponse = (PartnerCallouts.FulfillmentResponseWrapper)JSON.deserialize('dfasfsfasfsadfdsf', PartnerCallouts.FulfillmentResponseWrapper.class);
            partnerResponse = (PartnerCallouts.FulfillmentResponseWrapper)JSON.deserialize(res.getBody(), PartnerCallouts.FulfillmentResponseWrapper.class);
        }catch(exception e){
            
            resetAccount();
            
            pageMessages = 'ERROR: ' + e.getmessage();
            anyError = true;
            ExceptionUtility.createExceptionRecord(acct.id, pageMessages, true);
        }
        if(anyError)
            return;
        
        Partner_Fulfillment_Response__c partnerFulfilmentResponse = new Partner_Fulfillment_Response__c();
        partnerFulfilmentResponse.Response_JSON__c = res.getBody();
        if(String.isBlank(objWrapper.companyId)){
            partnerFulfilmentResponse.Object_Type__c = 'Lead';
        }else{
            partnerFulfilmentResponse.Object_Type__c = 'Account';
        }
        insert partnerFulfilmentResponse;
        
        if(partnerResponse.errors != null && !partnerResponse.errors.isEmpty()){
            pageMessages = 'ERROR: ' +'\n'+ JSON.serializePretty(partnerResponse.errors);
            anyError = true;
        }else if(partnerResponse.locations != null && !partnerResponse.locations.isEmpty()){
            for(PartnerCallouts.FulfillmentLocationWrapper record : partnerResponse.locations){
                if(record.errors != null && !record.errors.isEmpty()){
                    for(PartnerCallouts.FulfillmentErrorWrapper childRecord : record.errors){
                        pageMessages = 'ERROR: ' +'\n'+ childRecord.message;
                        anyError = true;
                    }
                }
            }
        }

        if(!anyError){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Storefront Fulfilled');
            ApexPages.addMessage(myMsg);
            pageMessages = 'Storefront Fulfilled Successfully';
        }else{
        	ExceptionUtility.createExceptionRecord(acct.id, pageMessages, true);
        }

    }
    
}