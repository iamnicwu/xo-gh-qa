public with sharing class AccountUpdatePayloadWrapper {
    public String companyId {get; set;}
    public String companyName {get; set;}
    public String website {get; set;} 
    public String email {get; set;}
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
    public List<PhoneNumberWrapper> phones {get; set;}
    public AddressWrapper address {get; set;}
    public UserWrapper salesrep {get; set;}
    public UserWrapper strategySpecialist {get; set;}
    public List<ContactWrapper> contacts {get; set;}
    public List<LocationWrapper> locations {get; set;}
    public SubscriptionDataWrapper subsData {get; set;}

    public AccountUpdatePayloadWrapper() {
        companyId = '';
        companyName = '';
        website = '';
        email = '';
        phones = new List<PhoneNumberWrapper>();
        contacts = new List<ContactWrapper>();
        locations = new List<LocationWrapper>();
        address = new AddressWrapper();
        salesrep = new UserWrapper();
        strategySpecialist = new UserWrapper();
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
        public AddressWrapper address {get; set;}
        public String role {get; set;}

        public ContactWrapper(){
            contactId = '';
            firstName = '';
            lastName = '';
            email = '';
            phone = '';
            address = new AddressWrapper();
            role = '';
        }
    }

    public class LocationWrapper{
        public String locationId {get; set;}
        public String name {get; set;}
        public String website {get; set;}
        public String email {get; set;}
        public List<PhoneNumberWrapper> phones {get; set;}
        public AddressWrapper address {get; set;} // mapp to Shipping Address for Account Locations

        public LocationWrapper(){
            locationId = '';
            name = '';
            website = '';
            email = '';
            phones = new List<PhoneNumberWrapper>();
            address = new AddressWrapper();
        }
    }

    // This is created to store subscription and billing information after the json is parsed in PartnerAccountUpdateCallout.cls
    public class SubscriptionDataWrapper{
        public String Account_CRM_Id {get; set;}
        public String SubscriptionName {get; set;}
        public String SubscriptionID {get; set;}
        public Date Request_timestamp {get; set;}
        public String BillingAccountName {get; set;}
        public String BillingAccountID {get; set;}
        public Date ServiceActivationDate {get; set;}
        public Date SubscriptionEndDate {get; set;}
        public String UserID {get; set;}
        public String UserName {get; set;}

        public SubscriptionDataWrapper() {
            Account_CRM_Id = '';
            SubscriptionName = '';
            SubscriptionID = '';
            BillingAccountName = '';
            BillingAccountID = '';
            UserID = '';
            UserName = '';
        }
    }
}