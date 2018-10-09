public with sharing class LeadAccountAutoAssignController {

	private static final String autoAssignMetroQuery = 'select Id, Zip__c, ShippingPostalCode, ShippingCountryCode, BillingPostalCode, BillingCountryCode from Account where Zip__c = null and (ShippingPostalCode != null or BillingPostalCode != null) limit 10';
	private static final String autoAssignLeadOwnerQuery = 'select Id, Local_Sales_Market__c, Primary_Category__c, PostalCode, CountryCode from Lead where OwnerId = \'{selOwn}\' and PostalCode != null and Local_Sales_Market__c != null and Primary_Category__c != null and IsConverted = false';
	private static final String autoAssignAccountOwnerQuery = 'select Id, Local_Sales_Market__c, Primary_Category__c, ShippingPostalCode, ShippingCountryCode, BillingPostalCode, BillingCountryCode from Account where OwnerId = \'{selOwn}\' and ParentId = null and (ShippingPostalCode != null or BillingPostalCode != null) and Local_Sales_Market__c != null and Primary_Category__c != null';
	
    //private static final String autoAssignLeadOwnerQuery = 'select Id, Local_Sales_Market__c, Primary_Category__c, PostalCode, CountryCode from Lead where OwnerId = \'{selOwn}\' and Id = \'00Q7A000001HcHd\'';
    //private static final String autoAssignAccountOwnerQuery = 'select Id, Local_Sales_Market__c, Primary_Category__c, ShippingPostalCode, ShippingCountryCode, BillingPostalCode, BillingCountryCode from Account where ParentId = null and OwnerId = \'{selOwn}\' limit 1000';//and Id = \'0017A000007bwZT\'';

    private static final String OWNER_QUERY = 'select Id, SalesRepId__c, FirstName, LastName from User where Id != null {customFilters} order by FirstName';

	public String query {get; set;}

	public String ownerActiveFilter {get; set;}
	public String selectedProfile {get; set;}
	public String selectedRecordOwner {get; set;}
    public String aType {get; set;}

	public LeadAccountAutoAssignController() {
		ownerActiveFilter = 'Active';
		selectedProfile = 'service';
        aType = 'accountOwner';
	}

	public List<SelectOption> getActiveType(){
    	List<SelectOption> options = new List<SelectOption>();
    	options.add(new SelectOption('', 'All Record Owner'));
    	options.add(new SelectOption('Active', 'Active Owners Only'));
    	options.add(new SelectOption('Inactive', 'Inactive Owners Only'));
    	return options;
    }

    public List<SelectOption> getProfileList(){
    	List<SelectOption> options = new List<SelectOption>();
    	options.add(new SelectOption('', 'All User Profiles'));
    	options.add(new SelectOption('service', 'Service Accounts'));
        options.add(new SelectOption('admin', 'System Administrator'));
    	return options;
    }

    public List<SelectOption> getUserList(){
    	String userQuery = OWNER_QUERY;
		String userFilter = '';
    	if(String.isNotBlank(ownerActiveFilter)){
    		userFilter += ' and IsActive = ';
    		userFilter += (ownerActiveFilter == 'Active') ? true : false;
    	}
    	if(String.isNotBlank(selectedProfile)){
            if(selectedProfile == 'service'){
    		  userFilter += ' and Profile.Name like' + '\'%Service Account%\'';
            }else if(selectedProfile == 'admin'){
                userFilter += ' and Profile.Name like' + '\'%System Administrator%\'';
            }
    	}

    	userQuery = userQuery.replace('{customFilters}', userFilter);

    	List<SelectOption> options = new List<SelectOption>();
    	options.add(new SelectOption('', 'Select Record Owner'));
    	for(User record : Database.query(userQuery)){
    		String displayName = (String.isNotBlank(record.FirstName)) ? record.FirstName : '';
    		displayName += (String.isNotBlank(displayName)) ? ' ' + record.LastName : record.LastName;
    		displayName += (String.IsNotBlank(record.SalesRepID__c)) ? ' - ' + record.SalesRepID__c : '';
    		options.add(new SelectOption(record.Id, displayName));
    	}
    	return options;
    }

    public void reRenderPanel(){
    	selectedRecordOwner = '';
    }

    public List<SelectOption> getAssignType(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('accountOwner', 'Local Account Owner Auto Assignment'));
        options.add(new SelectOption('leadOwner', 'Local Lead Owner Auto Assignment'));
        options.add(new SelectOption('accountMetro', 'Local Account Metro Assignment'));
        return options;
    }

    public void executeBatchAssign(){
        if(aType != 'accountMetro' && String.isBlank(selectedRecordOwner)){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select a record owner!!!');
            ApexPages.addMessage(myMsg);
            return;
        }
        String qString;

        if(aType == 'accountOwner'){
            qString = autoAssignAccountOwnerQuery;
            qString = qString.replace('{selOwn}', selectedRecordOwner);
        }else if(aType == 'leadOwner'){
            qString = autoAssignLeadOwnerQuery;
            qString = qString.replace('{selOwn}', selectedRecordOwner);
        }else if(aType == 'accountMetro'){
            qString = autoAssignMetroQuery;
        }

        try{
            LeadAccountAutoAssignBatch b = new LeadAccountAutoAssignBatch(qString, aType);
            database.executebatch(b, 1000);
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Convert batch has been scheduled! Please go to Apex Jobs to view status!');
            ApexPages.addMessage(myMsg);
        }catch(Exception E){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, E.getMessage());
            ApexPages.addMessage(myMsg);
        }
    }

}