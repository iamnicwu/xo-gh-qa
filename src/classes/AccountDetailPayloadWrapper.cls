global with sharing class AccountDetailPayloadWrapper {
	//global String status {get; set;}
	//global Integer statusCode {get; set;}
	global String id {get; set;}
	global String companyName {get; set;}
	global String website {get; set;}
	global String email {get; set;}
	global Boolean creditHold {get; set;}
	global List<PhoneNumberWrapper> phones {get; set;}
	global AddressWrapper address {get; set;}
	global UserWrapper salesrep {get; set;}
	global UserWrapper strategySpecialist {get; set;}
	global List<ContactWrapper> contacts {get; set;}

	global AccountDetailPayloadWrapper() {
		//status = '';
		id = '';
		companyName = '';
		website = '';
		email = '';
		phones = new List<PhoneNumberWrapper>();
		contacts = new List<ContactWrapper>();
		address = new AddressWrapper();
		salesrep = new UserWrapper();
		strategySpecialist = new UserWrapper();
	}

	global class PhoneNumberWrapper{
		global String type {get; set;}
		global String phoneNumber {get; set;}

		global PhoneNumberWrapper(){
			type = '';
			phoneNumber = '';
		}
	}

	global class AddressWrapper{
		global String street1 {get; set;}
		global String street2 {get; set;}
		global String city {get; set;}
		global String stateOrProvince {get; set;}
		global String postalCode {get; set;}
		global String country {get; set;}

		global AddressWrapper(){
			street1 = '';
			street2 = '';
			city = '';
			stateOrProvince = '';
			postalCode = '';
			country = ''; 
		}
	}

	global class UserWrapper{
		global String id {get; set;}
		global String firstName {get; set;}
		global String lastName {get; set;}
		global String phone {get; set;}
		global String email {get; set;}

		global UserWrapper(){
			id = '';
			firstName = '';
			lastName = '';
			phone = '';
			email = '';
		}
	}

	global class ContactWrapper{
		global String contactId {get; set;}
		global String firstName {get; set;}
		global String lastName {get; set;}
		global String email {get; set;}
		global String phone {get; set;}
		global AddressWrapper address {get; set;}
		global String role {get; set;}

		global ContactWrapper(){
			contactId = '';
			firstName = '';
			lastName = '';
			email = '';
			phone = '';
			address = new AddressWrapper();
			role = '';
		}
	}
}