public with sharing class LeadParentAccountController {
	// the parent account
	public Account parentAccount {get; set;}
	// the converted lead
	public Lead leadRecord {get; set;}

	//  the param determine to show the fulfilment option.
	public Boolean displayFulfillmentOption {get; set;}

	// the param determine to fulfill the lead to partners.
	public Boolean fulfillUnclaimedStorefront {get; set;}

	// the param determine to show the Continue Conversion Button.
	public Boolean displayContinueConversionButton {get; set;}

	// the Id of converted lead 
	private String leadId;

	// the Wrapper class param to deserialize the fulfilldata of the lead, used for got the parent account dynamic Id
	private LeadPayloadWrapper.FulfillData fillData = new LeadPayloadWrapper.FulfillData();

	public LeadParentAccountController() {
		parentAccount = new Account();
		leadRecord = new Lead();

		leadId = ApexPages.currentPage().getParameters().get('id');

		if(String.isNotBlank(leadId)){

			leadRecord = [SELECT Id, DynamicsLeadId__c, Fulfillment_Data__c, Storefront_Status__c, Name, FirstName, Country, PostalCode, Status, Email
										FROM Lead 
										WHERE Id = :leadId];

			if(String.isNotBlank(leadRecord.Fulfillment_Data__c)){
				// Retrive the parent account with parentGUID in the lead's fulfillmentData 
				try{
					fillData = (LeadPayloadWrapper.FulfillData)JSON.deserialize(leadRecord.Fulfillment_Data__c, LeadPayloadWrapper.FulfillData.class);

					if(String.isNotBlank(fillData.parentGUID) && fillData.parentGUID != 'null'){
						List<Account> accList = [SELECT Id, DynamicsAccId__c FROM Account WHERE DynamicsAccId__c =: fillData.parentGUID];
						if (!accList.isEmpty()) {
							parentAccount.ParentId = accList[0].id;
						}
						// parentAccount.ParentId = [SELECT Id, DynamicsAccId__c FROM Account WHERE DynamicsAccId__c =: fillData.parentGUID].Id;
					}
				}catch(Exception E){
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, E.getMessage()));
				}
			}

			// CSP-1966 | don't display the "Continue Conversion" button if certain fields are blank or status is not 'Qualified'
			if (leadRecord.Status != 'Qualified') {
				displayContinueConversionButton = false;
				String validationMsgString = 'You cannot convert a lead to an account before the lead\'s status has been set to \'Qualified\'';
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, validationMsgString));
			}
			else if (String.isBlank(leadRecord.FirstName) || String.isBlank(leadRecord.Country) || String.isBlank(leadRecord.PostalCode) || String.isBlank(leadRecord.Email)) {
				displayContinueConversionButton = false;
				String validationMsgString = 'A Lead is required to have a First Name, Email, Country, and Zip Code in order to convert to an Account.';
				validationMsgString += 'Please cancel and fill out this data on the Lead before you convert.';
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, validationMsgString));
			}
			else {
				displayContinueConversionButton = true;
			}
		}

		// CSP-1966 | if the Lead's Storefront_Status__c is null and the user is in the userProfilesThatCanFulfillUnclaimedStorefront,
		// display the "auto fulfill unclaimed storefront on conversion" checkbox
		// Set<String> userProfilesThatCanFulfillUnclaimedStorefront = new Set<String>{'System Administrator', 'Local Core Sales Operations', 'Local Core Account Executive'};
		String userProfilesThatCanFulfillUnclaimedStorefront = System.Label.Profile_can_auto_fulfill_a_unclaim_lead;
		for (Profile currentUserProfile : [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1]) {
			if (userProfilesThatCanFulfillUnclaimedStorefront.containsIgnoreCase(currentUserProfile.Name) && leadRecord.Storefront_Status__c == null) {
				displayFulfillmentOption = true;
				fulfillUnclaimedStorefront = true;
				break;
			}
			displayFulfillmentOption = false;
			fulfillUnclaimedStorefront = false;			
		}
	}


	public PageReference saveParent(){
	
		// CSP-1966 | fulfill unclaimed storefront if needed; if unclaimed callout fails (AKA the fulfillStorefront method returns false) stop execution flow
		if (fulfillUnclaimedStorefront && !Test.isRunningTest()) {
			if (!fulfillStorefront(leadRecord)) {
				return null;
			}
		}

		// if the Parent account is not null, we should generated the fulfilldata for the Lead
		if(String.isBlank(parentAccount.ParentId)){
			fillData.parentGUID = '';
		}else{
			fillData.parentGUID = [SELECT Id, DynamicsAccId__c FROM Account WHERE Id =: parentAccount.ParentId].DynamicsAccId__c;
		}
		system.debug(parentAccount);
		try{
			Lead saveLead = new Lead();
			saveLead.Id = leadId;
			saveLead.Fulfillment_Data__c = JSON.serializePretty(fillData);

			// update the Storefront_Status__c of lead when the user fulfill this lead.
			if (fulfillUnclaimedStorefront) {
				saveLead.Storefront_Status__c = 'Unclaimed';
			}
			
			update saveLead;
		}catch(Exception E){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, E.getMessage()));
			return null;
		}

		PageReference pageRef = new PageReference('/lead/leadconvert.jsp?retURL=%2F'+leadId+'&id='+leadId);
		pageRef.setRedirect(true);

		return pageRef;
	}

	public PageReference cancelConvert(){
		PageReference pageRef = new PageReference('/'+leadId);
		pageRef.setRedirect(true);

		return pageRef;
	}

	public static Boolean fulfillStorefront(Lead leadRecord){
		// default return value
		Boolean isSuccess = true;

		if(!XOGroupSettingUtility.getPartnerCalloutSetting()){
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Partner Fulfillment is currently off!');
			ApexPages.addMessage(myMsg);
			isSuccess = false;
			return isSuccess;
		}

		RESTLocalStorefrontAPI.ObjectWrapper objWrapper = new RESTLocalStorefrontAPI.ObjectWrapper();
		objWrapper.locationId = leadRecord.DynamicsLeadId__c;

		OrderPayloadWrapper orderPayload = new OrderPayloadWrapper();
		orderPayload = PartnerCallouts.unclaimedVettedLead(objWrapper);

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

		// system.debug(req);
		// system.debug(req.getBody());

		// Send the request, and return a response
		HttpResponse res = h.send(req);
		system.debug(res.getBody());
		system.debug(res.getStatus());

		// Analyze the fulfill response
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
		insert partnerFulfilmentResponse;

		//  if there is any error in fulfill process, we should stop this execution flow
		if(partnerResponse.errors != null && !partnerResponse.errors.isEmpty()){
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, JSON.serializePretty(partnerResponse.errors));
			ApexPages.addMessage(myMsg);
			isSuccess = false;
		}else if(partnerResponse.locations != null && !partnerResponse.locations.isEmpty()){
			for(PartnerCallouts.FulfillmentLocationWrapper record : partnerResponse.locations){
				if(record.errors != null && !record.errors.isEmpty()){
					for(PartnerCallouts.FulfillmentErrorWrapper childRecord : record.errors){
						ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, childRecord.message);
						ApexPages.addMessage(myMsg);
						isSuccess = false;
					}
				}
			}
		}

		return isSuccess;
	}

}