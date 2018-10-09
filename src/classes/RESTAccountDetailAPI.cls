@RestResource(urlMapping='/AccountDetail/*')
global with sharing class RESTAccountDetailAPI {
	private static List<String> phoneFieldList = new List<String>{'Phone', 'HomePhone__c', 'MobilePhone', 'Fax'};
	private static List<String> acctPhoneFieldList = new List<String>{'Phone', 'Mobile__c', 'Vanity__c'};
	
	@HttpGet
    global static AccountDetailResponse getAccountDetail(){
    	String acctGUID = RestContext.request.params.get('acctGUID');

    	RestResponse res = RestContext.response;
        if (res == null) {
            res = new RestResponse();
            RestContext.response = res;
        }

    	AccountDetailResponse responseMessage = new AccountDetailResponse();
    	AccountDetailPayloadWrapper acctDetail = new AccountDetailPayloadWrapper();

    	try{
	    	Account acctData = [select Id, DynamicsAccID__c, Name, Credit_Hold__c, Website, Email__c, Phone, Mobile__c, Vanity__c, 
										BillingStreet, BillingCity, BillingStateCode, BillingState, BillingPostalCode, BillingCountry, BillingCountryCode,
										ShippingStreet, ShippingCity, ShippingStateCode, ShippingState, ShippingPostalCode, ShippingCountry, ShippingCountryCode,
										Local_Sales_Market__r.Market_ID__c, Primary_Category__r.Taxonomy_ID__c, 
										OwnerId, Owner.FirstName, Owner.LastName, Owner.Phone, Owner.Email, Fulfillment_Data__c,
										Strategy_Specialist__c, Strategy_Specialist__r.FirstName, Strategy_Specialist__r.LastName, Strategy_Specialist__r.Phone, Strategy_Specialist__r.Email,
										(select Id, Role, ContactId, Contact.FirstName, Contact.LastName, Contact.Email, Contact.Phone, Contact.MailingStreet,
											Contact.MailingCity, Contact.MailingStateCode, Contact.MailingState, Contact.MailingCountry, Contact.MailingCountryCode, Contact.MailingPostalCode
											from AccountContactRoles where Role IN ('Primary', 'Billing') order by Role)
										from Account where DynamicsAccID__c =: acctGUID];

			acctDetail.Id = stringFieldValue(acctData.DynamicsAccID__c);
			acctDetail.companyName = stringFieldValue(acctData.Name);
			acctDetail.creditHold = acctData.Credit_Hold__c;
			acctDetail.website = stringFieldValue(acctData.Website);
			acctDetail.email = stringFieldValue(acctData.Email__c);

			for(Integer i = 0; i < acctPhoneFieldList.size(); i++){
				if(acctData.get(acctPhoneFieldList[i]) != null){
					AccountDetailPayloadWrapper.PhoneNumberWrapper phoneData = new AccountDetailPayloadWrapper.PhoneNumberWrapper();
					phoneData.Type = acctPhoneFieldList[i];
					phoneData.phoneNumber = String.valueof(acctData.get(acctPhoneFieldList[i]));
					acctDetail.phones.add(phoneData);
				}
			}

			List<String> billingStreetList = new List<String>();
			if(String.isNotBlank(acctData.BillingStreet)){
				billingStreetList = acctData.BillingStreet.split('\\r\\n');
			}
			if(!billingStreetList.isEmpty()){
				acctDetail.address.street1 = billingStreetList[0];
				if(billingStreetList.size() > 1){
					acctDetail.address.street2 = billingStreetList[1];
				}
			}

			acctDetail.address.city = stringFieldValue(acctData.BillingCity);
			acctDetail.address.stateOrProvince = stringFieldValue(acctData.BillingStateCode);
			acctDetail.address.country = stringFieldValue(acctData.BillingCountryCode);
			acctDetail.address.postalCode = stringFieldValue(acctData.BillingPostalCode);

			acctDetail.salesrep.id = acctData.OwnerId;
			acctDetail.salesrep.firstName = stringFieldValue(acctData.Owner.FirstName);
			acctDetail.salesrep.lastName = stringFieldValue(acctData.Owner.LastName);
			acctDetail.salesrep.phone = stringFieldValue(acctData.Owner.Phone);
			acctDetail.salesrep.email = stringFieldValue(acctData.Owner.Email);

			acctDetail.strategySpecialist.id = acctData.Strategy_Specialist__c;
			acctDetail.strategySpecialist.firstName = stringFieldValue(acctData.Strategy_Specialist__r.FirstName);
			acctDetail.strategySpecialist.lastName = stringFieldValue(acctData.Strategy_Specialist__r.LastName);
			acctDetail.strategySpecialist.phone = stringFieldValue(acctData.Strategy_Specialist__r.Phone);
			acctDetail.strategySpecialist.email = stringFieldValue(acctData.Strategy_Specialist__r.Email);

			if(!acctData.AccountContactRoles.isEmpty()){
				Boolean billingContact = false;
				for(AccountContactRole record : acctData.AccountContactRoles){
					AccountDetailPayloadWrapper.ContactWrapper cont = new AccountDetailPayloadWrapper.ContactWrapper();
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
					acctDetail.contacts.add(cont);

					if(record.Role == 'Billing'){
						billingContact = true;
					}else if(!billingContact && record.Role == 'Primary'){
						AccountDetailPayloadWrapper.ContactWrapper billCont = new AccountDetailPayloadWrapper.ContactWrapper();
						billCont.contactId = record.ContactId;
						billCont.firstName = stringFieldValue(record.Contact.FirstName);
						billCont.lastName = stringFieldValue(record.Contact.LastName);
						billCont.email = stringFieldValue(record.Contact.Email);
						billCont.role = 'Billing';
						billCont.phone = stringFieldValue(record.Contact.Phone);
						billCont.address.city = stringFieldValue(record.Contact.MailingCity);
						billCont.address.stateOrProvince = stringFieldValue(record.Contact.MailingStateCode);
						billCont.address.country = stringFieldValue(record.Contact.MailingCountryCode);
						billCont.address.postalCode = stringFieldValue(record.Contact.MailingPostalCode);

						if(!mailingStreetList.isEmpty()){
							billCont.address.street1 = mailingStreetList[0];
							if(mailingStreetList.size() > 1){
								billCont.address.street2 = mailingStreetList[1];
							}
						}
						acctDetail.contacts.add(billCont);
					}
			 	}
			}

			responseMessage.status = 'success';
			responseMessage.statusCode = 200;
			responseMessage.message = 'SUCCESS: Account Found';
			responseMessage.accountDetail = acctDetail;
			res.statusCode = 200;
			//res.responseBody = Blob.valueOf(JSON.serialize(responseMessage));
		}Catch(Exception E){
			responseMessage.status = 'error';
			responseMessage.statusCode = 400;
			responseMessage.message = 'FAILED: Account Not Found';
			res.statusCode = 400;
			//res.responseBody = Blob.valueOf(JSON.serialize(responseMessage));
		}

    	system.debug(responseMessage);
    	return responseMessage;
    }

    private static String stringFieldValue(String val){
		return (String.isNotBlank(val)) ? val : '';
	}

	global class AccountDetailResponse{
		global String status {get; set;}
		global Integer statusCode {get; set;}
		global String message {get; set;}
		global AccountDetailPayloadWrapper accountDetail {get; set;}
	}

}