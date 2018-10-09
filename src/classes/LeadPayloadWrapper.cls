global with sharing class LeadPayloadWrapper {
    global String companyId {get; set;}
    global String locationId {get; set;}
    global String companyName {get; set;}
    global String website {get; set;}
    global String email {get; set;}
    global String phone {get; set;}
    global List<AddressWrapper> address {get; set;}
    global ContactWrapper contact {get; set;}
    global Boolean isClaiming {get; set;}
    global String leadSourceId {get; set;}
    global FulfillData fulfillmentData {get; set;}
    global Object metadata {get; set;}
    global String tier {get; set;}

    global LeadPayloadWrapper() {
        companyId = '';
        locationId = '';
        companyName = '';
        website = '';
        email = '';
        phone = '';
        leadSourceId = '';
        address = new List<AddressWrapper>();
        contact = new ContactWrapper();
        fulfillmentData = new FulfillData();
        metadata = '';
        tier = '';
    }

    global class AddressWrapper{
        global String addressType {get; set;}
        global String street1 {get; set;}
        global String street2 {get; set;}
        global String city {get; set;}
        global String stateOrProvince {get; set;}
        global String postalCode {get; set;}
        global String country {get; set;}

        global AddressWrapper(){
            addressType = '';
            street1 = '';
            street2 = '';
            city = '';
            stateOrProvince = '';
            postalCode = '';
            country = '';
        }
    }

    global class ContactWrapper{
        global String firstName {get; set;}
        global String lastName {get; set;}
        global String email {get; set;}
        global String phone {get; set;}
        global AddressWrapper address {get; set;}

        global ContactWrapper(){
            firstName = '';
            lastName = ''; 
            email = '';
            phone = '';
            address = new AddressWrapper();
        }
    }

    global class FulfillData{
        global String tier {get; set;}
        global String marketCode {get; set;}
        global String categoryId {get; set;}
        global String parentGUID {get; set;}
        global Boolean multipleCategoryInterest {get; set;}

        global FulfillData(){
            tier = '';
            marketCode = '';
            categoryId = '';
            //reviewId = '';
            parentGUID = '';
        }
    }
}