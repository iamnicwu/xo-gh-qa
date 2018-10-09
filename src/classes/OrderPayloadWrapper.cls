public with sharing class OrderPayloadWrapper {
	public String companyId {get; set;}
	public String companyName {get; set;}
	public Boolean creditHold {
		get;
		set {
			// get the value from the custom setting
			if (XOGroupSettingUtility.alwaysSetCreditHoldToFalse()) {
				creditHold = False;
			}
			else {
				creditHold = value;
			}
		}
	}
	//public Boolean claimed {get; set;}
	public String website {get; set;}
	public String email {get; set;}
	public List<PhoneNumberWrapper> phones {get; set;}
	public AddressWrapper address {get; set;}
	public UserWrapper salesrep {get; set;}
	public UserWrapper strategySpecialist {get; set;}
	public List<ContactWrapper> contacts {get; set;}
	public List<LocationWrapper> locations {get; set;}

	public OrderPayloadWrapper() {
		companyId = '';
		companyName = '';
		website = '';
		email = '';
		phones = new List<PhoneNumberWrapper>();
		contacts = new List<ContactWrapper>();
		address = new AddressWrapper();
		salesrep = new UserWrapper();
		strategySpecialist = new UserWrapper();
		locations = new List<LocationWrapper>();
	}

	public class PhoneNumberWrapper{
		public String type {get; set;}
		public String phoneNumber {get; set;}

		public PhoneNumberWrapper(){
			type = '';
			phoneNumber = '';
		}
	}

	public class AddressWrapper{
		public String street1 {get; set;}
		public String street2 {get; set;}
		public String city {get; set;}
		public String stateOrProvince {get; set;}
		public String postalCode {get; set;}
		public String country {get; set;}
		public Boolean geocodeOverride {
			get;
			set {
				// get the value from the custom setting
				if (XOGroupSettingUtility.alwaysSetGeocodeOverrideToTrue()) {
					geocodeOverride = True;
				}
				else {
					geocodeOverride = value;
				}
			}
		}


		public AddressWrapper(){
			street1 = '';
			street2 = '';
			city = '';
			stateOrProvince = '';
			postalCode = '';
			country = '';
			geocodeOverride = False;
		}
	}

	public class UserWrapper{
		public String id {get; set;}
		public String firstName {get; set;}
		public String lastName {get; set;}
		public String phone {get; set;}
		public String email {get; set;}

		public UserWrapper(){
			id = '';
			firstName = '';
			lastName = '';
			phone = '';
			email = '';
		}
	}

	public class ContactWrapper{
		public String contactId {get; set;}
		public String firstName {get; set;}
		public String lastName {get; set;}
		public String email {get; set;}
		public String phone {get; set;}
		//public List<PhoneNumberWrapper> phones {get; set;}
		public AddressWrapper address {get; set;}
		public String role {get; set;}

		public ContactWrapper(){
			contactId = '';
			firstName = '';
			lastName = '';
			email = '';
			role = '';
			phone = '';
			//phones = new List<PhoneNumberWrapper>();
			address = new AddressWrapper();
		}
	}

	public class LocationWrapper{
		public String locationId {get; set;}
		public String name {get; set;}
		public String website {get; set;}
		public String email {get; set;}
		public List<PhoneNumberWrapper> phones {get; set;}
		public AddressWrapper address {get; set;} // mapp to Shipping Address for Account Locations
		public List<ServiceWrapper> services {get; set;}
		public List<ServiceWrapper> addOns {get; set;}
		//public List<ReviewWrapper> reviews {get; set;}
		//public List<MediaWrapper> media {get; set;}
		public Map<String, Object> metadata {get; set;}

		public LocationWrapper(){
			locationId = '';
			name = '';
			website = '';
			email = '';
			phones = new List<PhoneNumberWrapper>();
			address = new AddressWrapper();
			services = new List<ServiceWrapper>();
			addOns = new List<ServiceWrapper>();
			//reviews = new List<ReviewWrapper>();
			//media = new List<MediaWrapper>();
			metadata = new Map<String, Object>();
		}
	}

	// USED FOR ADD ONS AS WELL
	public class ServiceWrapper{
		public String subscription {get; set;}
		public String name {get; set;}
		public String sku {get; set;}
		public String ratePlanId {get; set;}
		public String chargeId {get; set;}
		public String cesRecordId {get; set;}
		public String billingAccountId {get; set;}
		public String paymentType {get; set;}
		public String marketCode {get; set;}
		public String categoryId {get; set;}
		public String tier {get; set;}
		public String displayStatus {get; set;}

		public ServiceWrapper(){
			subscription = '';
			name = '';
			sku = '';
			ratePlanId = '';
			chargeId = '';
			cesRecordId = '';
			billingAccountId = '';
			paymentType = '';
			marketCode = '';
			categoryId = '';
			tier = '';
			displayStatus = '';
		}
	}

	/*public class ReviewWrapper{
		public String reviewId {get; set;}
		public String marketCode {get; set;}
		public String categoryId {get; set;}

		public ReviewWrapper(){
			reviewId = '';
			marketCode = '';
			categoryId = '';
		}
	}*/

	/*public class MediaWrapper{
		public String url {get; set;}
		public String id {get; set;}
		public String marketCode {get; set;}
		public String categoryId {get; set;}

		public MediaWrapper(){
			url = '';
			id = '';
			marketCode = '';
			categoryId = '';
		}
	}*/
	// END OF ORDER PAYLOAD WRAPPER CLASSES
}