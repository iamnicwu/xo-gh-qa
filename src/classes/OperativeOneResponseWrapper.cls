global without sharing class OperativeOneResponseWrapper {
	global List<SalesOrderWrapper> salesOrders;
	global List<String> approvals;

	global OperativeOneResponseWrapper() {
		salesOrders = new List<SalesOrderWrapper>();
		approvals = new List<String>();
	}
	global class SalesOrderWrapper {

		global String name;
		global String owner;
		// global String orderCurrency;  // need to replace('\"currency\"','\"orderCurrency\"')
		global String description;
		global String status;
		global String primaryAdvertiser;
		global Date startDate;
		global Date endDate;
		global Date lineitemDefaultStartDate;
		global Date lineitemDefaultEndDate;
		global Boolean unreviewedNotes;
		global String primarySalesperson;
		global String rateCard;
		global Integer lineitemCount;
		global String billingAccount;
		global DateTime lastModifiedDate;
		global Integer totalOrderedImpressions;
		global DateTime createdDate;
		global String lastModifiedBy;
		global String endOfFlight;
		global Decimal netOrderValue;
		global Decimal ecpm;
		global String defaultMediaPlanName;
		global Integer id;

		// global ObjectNameWrapper timeZone;
		// global ObjectNameWrapper discountProfile;
		// global ObjectNameWrapper salesTeam;
		// global ObjectNameWrapper salesOrderType;
		// global ObjectNameWrapper defaultInvoicingOrganization;
		// global ObjectNameWrapper billingPeriodScheme;

		// global SalesStageWrapper salesStage;

		// global AccountsWrapper accounts;
		// global UsersWrapper users;
		// global CustomFieldsWrapper customFields;
		// global SalesOpportunityWrapper salesOpportunity;
		// global LineitemDiscountsWrapper lineitemDefaultDiscounts;

		global SalesOrderWrapper() {
			name = '';
			owner = '';
			// orderCurrency = '';
			description = '';
			status = '';
			primaryAdvertiser = '';
			startDate = null;
			endDate = null;
			lineitemDefaultStartDate = null;
			lineitemDefaultEndDate = null;
			unreviewedNotes = false;
			primarySalesperson = '';
			rateCard = '';
			lineitemCount = 0;
			billingAccount = '';
			lastModifiedDate = null;
			totalOrderedImpressions = 0;
			createdDate = null;
			lastModifiedBy = '';
			endOfFlight = '';
			netOrderValue = 0.00;
			ecpm = 0.00;
			defaultMediaPlanName = '';
			id = 0;

			// timeZone = new ObjectNameWrapper();

			// customFields = new CustomFieldsWrapper();

			// salesStage = new SalesStageWrapper();
			// discountProfile = new ObjectNameWrapper();
			// salesTeam = new ObjectNameWrapper();
			// salesOrderType = new ObjectNameWrapper();
			// defaultInvoicingOrganization = new ObjectNameWrapper();
			// billingPeriodScheme = new ObjectNameWrapper();

			// accounts = new AccountsWrapper();
			// salesOpportunity = new SalesOpportunityWrapper();

			// lineitemDefaultDiscounts = new LineitemDiscountsWrapper();
		}
		    
	}

	global class ObjectNameWrapper {
		global String objectName;
		global Integer id;
		global String name;

		global ObjectNameWrapper(){
			objectName = '';
			id = 0;
			name = '';
		}
	}

	global class CustomFieldsWrapper {
		List<CustomFieldWrapper> customFields;
 
		global CustomFieldsWrapper(){
			customFields = new List<CustomFieldWrapper>();
		}
	}

	global class CustomFieldWrapper {
		global String apiName;
		global Integer fieldId;
		global String value;
		global String name;

		global CustomFieldWrapper(){
			apiName = '';
			fieldId = 0;
			value = '';
			name = '';
		}
	}

	global class SalesStageWrapper {
		global String percentage;
		global Integer id;
		global String name;

		global SalesStageWrapper(){
			percentage = '';
			id = 0;
			name = '';
		}
	}


	global class AccountsWrapper{
		List<AccountWrapper> accounts;
		global AccountsWrapper(){
			accounts = new list<AccountWrapper>();
		}
	}

	global class AccountWrapper {
		global String name;
		global String creditStatus;
		global Integer id;
		global String state;
		global String type;
		global String country;
		global String status;
		global String email;
		global String fax;
		global String mobile;
		global String phone;
		global String externalId;
		global String addressline1;
		global String city;
		global String zip;
		global Boolean billingAccount;

		global RolesWrapper roles;
		global CrmSystemWrapper crmSystem;
		global ContactsWrapper contacts;

		global AccountWrapper(){
			name = '';
			creditStatus = '';
			state = '';
			type = '';
			country = '';
			status = '';
			email = '';
			fax = '';
			mobile = '';
			phone = '';
			externalId = '';
			addressline1 = '';
			city = '';
			zip = '';
			id = 0;
			billingAccount = false;

			roles = new RolesWrapper();
			crmSystem = new CrmSystemWrapper();
			contacts = new ContactsWrapper();
		}
	}

	global class RolesWrapper {
		global List<RoleWrapper> roles;

		global RolesWrapper(){
			roles = new List<RoleWrapper>();
		}
	}

	global class RoleWrapper {
		global String internalName;
		global String name;

		global RoleWrapper(){
			internalName = '';
			name = '';
		}
	}


	global class ContactsWrapper {
		global List<ContactWrapper> Contacts;

		global ContactsWrapper(){
			Contacts = new List<ContactWrapper>();
		}
	}

	global class ContactWrapper {
		global String email;
		global String firstName;
		global String status;

		global String city;
		global String country;
		global String externalId;
		global String addressline1;
		global String mobile;
		global String lastName;
		global String phone;
		global String fax;
		global String state;
		global String zip;
		global Integer id;

		global RolesWrapper roles;
		
		global ContactWrapper(){
			email = '';
			firstName = '';
			status = '';
			city = '';
			country = '';
			externalId = '';
			addressline1 = '';
			mobile = '';
			lastName = '';
			phone = '';
			fax = '';
			state = '';
			zip = '';
			id = 0;

			roles = new RolesWrapper();
		}
	}


	global class CrmSystemWrapper {
		global String mediaType;
		global String productionSystemTemplateName;
		global ObjectNameWrapper timeZone;
		global String memo;
		global String status;
		global Integer id;
		global String name;

		global CrmSystemWrapper(){
			mediaType = '';
			productionSystemTemplateName = '';
			memo = '';
			status = '';
			name = '';
			id = 0;
			timeZone = new ObjectNameWrapper();
		}
	}

	global class UsersWrapper {
		global List<UserWrapper> users;

		global UsersWrapper(){
			users = new List<UserWrapper>();
		}
	}

	global class UserWrapper {
		global String lastName;
		global String email;
		global String firstName;
		global String status;
		global String userLogin;

		global Integer id;

		global RolesWrapper roles;
		
		global UserWrapper(){

			lastName = '';
			email = '';
			firstName = '';
			status = '';
			userLogin = '';

			id = 0;

			roles = new RolesWrapper();
		}
	}

	global class SalesOpportunityWrapper {
		global String backSyncStatus;
		global String externalId;
		global DateTime lastModifiedOn;
		global Boolean merged;
		global CrmSystemWrapper crmSystem;
		global DateTime lastSyncedOn;

		global SalesOpportunityWrapper(){
			backSyncStatus = '';
			externalId = '';
			lastModifiedOn = DateTime.now();
			merged = false;
			crmSystem = new CrmSystemWrapper();
			lastSyncedOn = DateTime.now();
		}
	}

	global class LineitemDiscountsWrapper {
		global List<DiscountsWrapper> discounts;

		global LineitemDiscountsWrapper(){
			discounts = new List<DiscountsWrapper>();
		}
	}

	global class DiscountsWrapper {
		global Integer id;
		global Integer value;
		global String name;

		global DiscountsWrapper(){
			id = 0;
			value = 0;
			name = '';
		}
	}


	global class MediaPlansWrapper {
		global List<MediaPlenWrapper> mediaPlans;

		global MediaPlansWrapper(){
			mediaPlans = new List<MediaPlenWrapper>();
		}
	}

	global class MediaPlenWrapper {
		global Boolean mediaPlendefault; // // need to replace('\"default\"','\"mediaPlendefault\"')
		global Integer id;
		global NamedSectionsWrapper namedSections;
		global String name;

		global MediaPlenWrapper(){
			mediaPlendefault = false;
			name = '';
			id = 0;

			namedSections = new NamedSectionsWrapper();
		}
	}

	global class NamedSectionsWrapper {
		global List<NamedSectionWrapper> namedSections;

		global NamedSectionsWrapper(){
			namedSections = new List<NamedSectionWrapper>();
		}
	}

	global class NamedSectionWrapper {
		global String name;
		global Integer id;

		global SalesOrderLineitemsWrapper salesOrderLineitems;
		
		global NamedSectionWrapper(){
			name = '';
			id = 0;

			salesOrderLineitems = new SalesOrderLineitemsWrapper();
		}
	}

	global class SalesOrderLineitemsWrapper {
		global List<salesOrderLineitemWrapper> salesOrderLineitems;

		global SalesOrderLineitemsWrapper(){
			salesOrderLineitems = new List<salesOrderLineitemWrapper>();
		}
	}

	global class salesOrderLineitemWrapper {
		global Integer unitCostBeforeDiscountsWithPremium;
		global Integer sortOrder;
		global Integer productionQuantity;
		global Integer netUnitCost;
		global Integer floorPrice;
		global Integer allocationPercent;
		global Integer id;
		global Integer grossCost;
		global Integer targetingPremium;
		global Integer unitCostBeforeDiscounts;
		global Integer netCost;
		global Integer goalPrice;
		global Integer quantity;
		global Integer productionBuffer;
		global Integer totalDiscount;
		global Integer grossUnitCost;
		global Boolean canTarget;
		global Boolean editLock;
		global Boolean canDelete;
		global Boolean reserved;
		global String bookingType;
		global String costMethod;
		global String isMakegood;
		global String canProduce;
		global String makegoodNote;
		global String canInvoice;
		global String hasPerformance;
		global String name;
		global String unitType;
		global String canOutput;
		global String forecastCategory;
		global DateTime endDate;
		global DateTime startDate;
		global Decimal ratecardPrice;

		global CustomFieldsWrapper customFields;

		global List<Billable3RdPartyServersWrapper> billable3RdPartyServers;
		global List<RichMedia3RdPartyServersWrapper> richMedia3RdPartyServers;
		global List<Other3RdPartyServersWrapper> other3RdPartyServers;

		
		
		

		global salesOrderLineitemWrapper(){
			unitCostBeforeDiscountsWithPremium = 0;
			sortOrder = 0;
			productionQuantity = 0;
			netUnitCost = 0;
			floorPrice = 0;
			allocationPercent = 0;
			id = 0;
			grossCost = 0;
			targetingPremium = 0;
			unitCostBeforeDiscounts = 0;
			netCost = 0;
			goalPrice = 0;
			quantity = 0;
			productionBuffer = 0;
			totalDiscount = 0;
			grossUnitCost = 0;
			canTarget = false;
			editLock = false;
			canDelete = false;
			reserved = false;
			bookingType = '';
			costMethod = '';
			isMakegood = '';
			canProduce = '';
			makegoodNote = '';
			canInvoice = '';
			hasPerformance = '';
			name = '';
			unitType = '';
			canOutput = '';
			forecastCategory = '';
			endDate = Datetime.now();
			startDate = Datetime.now();
			ratecardPrice = 0.00;
			customFields = new CustomFieldsWrapper();

			billable3RdPartyServers = new List<Billable3RdPartyServersWrapper>();
			richMedia3RdPartyServers = new List<RichMedia3RdPartyServersWrapper>();
			other3RdPartyServers = new List<Other3RdPartyServersWrapper>();

		}
	}

	global class Billable3RdPartyServersWrapper {}
	global class RichMedia3RdPartyServersWrapper {}
	global class Other3RdPartyServersWrapper {}
}