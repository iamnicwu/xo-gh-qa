public with sharing class LocalSalesRepReAssignmentController {
	public String selectedObjectType {get; set;}
	public String selectedRecordOwner {get; set;}
	public String ownerActiveFilter {get; set;}
	public String roleFilter {get; set;}

	public String resultSize {get; set;}
	public Integer noOfRecords {get; set;}

	public Map<Id, Boolean> selectedRecordMap {get; set;}
    public List<SObject> sobjectList {get; set;}
    public ExtraObjectFilter objectFilter {get; set;}

    public String salesRepToAssign {get; set;}

	private static final String OWNER_QUERY = 'select Id, SalesRepId__c, FirstName, LastName from User where Id != null {customFilters} order by FirstName';
    private static final String LEAD_QUERY = 'select Id, Name, Company, OwnerId, Status, Primary_Category__c, Local_Sales_Market__c from Lead where RecordType.Name Like \'%Local%\' and IsConverted = false {customFilters} order by Company limit 10000';
    private static final String ACCOUNT_QUERY = 'select Id, Name, Local_Active__c, Primary_Category__c, Local_Sales_Market__c, OwnerId from Account where RecordType.Name Like \'%Local%\' {customFilters} order by Name limit 10000';
    private static final String OPPORTUNITY_QUERY = 'select Id, Name, StageName, Type, Primary_Category__c, Local_Sales_Market__c, OwnerId from Opportunity where RecordType.Name Like \'%Local%\' and Type = \'Winback\' {customFilters} order by Name limit 10000';
    // CSP-1999 private static final String LSR_ASSIGNMENT_QUERY = 'select Id, Name, Category__c, Market__c, Market__r.Primary_Brand__c, Sales_Rep__c, Zip_Code__c, OwnerId from Local_Sales_Rep_Assignment__c where Id != null {customFilters} order by Name limit 10000';
    private static final String LSR_ASSIGNMENT_QUERY = 'select Id, Name, Category__c, Market__c, Sales_Rep__c, Zip_Code__c, OwnerId from Local_Sales_Rep_Assignment__c where Id != null {customFilters} order by Name limit 10000';


    private String filterString = '';

	public LocalSalesRepReAssignmentController() {
		objectFilter = new ExtraObjectFilter();
		selectedObjectType = 'Lead';
		ownerActiveFilter = 'Inactive';
		roleFilter = 'localAE';
		selectedRecordOwner = '';
		selectedRecordMap = new Map<Id, Boolean>();
		resultSize = '25';
		filterString = '';
		filterResults();
		populateSObject();
	}

	public ApexPages.StandardSetController setCon {
        get{
            if(setCon == null){
                string queryString;

                if(selectedObjectType == 'Lead'){
                	queryString = LEAD_QUERY;
                }else if(selectedObjectType == 'Account'){
                	queryString = ACCOUNT_QUERY;
                }else if(selectedObjectType == 'Opportunity'){
                	queryString = OPPORTUNITY_QUERY;
                }else if(selectedObjectType == 'Local_Sales_Rep_Assignment__c'){
                	queryString = LSR_ASSIGNMENT_QUERY;
                }

                if(String.isBlank(filterString)){
                    queryString = queryString.replace('{customFilters}', '');
                }else{
                    queryString = queryString.replace('{customFilters}', filterString);
                }
                //queryString = queryString.replace('{sortBy}', sortBy);
                //queryString = queryString.replace('{resultSize}', resultSize);

                /*List<String> catFilterList = new List<String>();
                if(!filterObject.categoryFilter.isEmpty()){
                    for(SelectOption record : filterObject.categoryFilter){
                        catFilterList.add(record.getValue());
                    }
                }

                List<String> mktFilterList = new List<String>();
                if(!filterObject.marketFilter.isEmpty()){
                    for(SelectOption record : filterObject.marketFilter){
                        mktFilterList.add(record.getValue());
                    }
                }*/


                setCon = new ApexPages.StandardSetController(Database.getQueryLocator(queryString));
                setCon.setPageSize(Integer.valueof(resultSize));
                noOfRecords = setCon.getResultSize();
            }
            return setCon;
        }set;
    }

    public void filterResults(){
        selectedRecordMap = new Map<Id, Boolean>();
        filterString = '';
        if(String.isNotBlank(selectedRecordOwner) && selectedObjectType != 'Local_Sales_Rep_Assignment__c'){
            filterString += ' and OwnerId = : selectedRecordOwner';
        }else if(String.isNotBlank(selectedRecordOwner) && selectedObjectType == 'Local_Sales_Rep_Assignment__c'){
            filterString += ' and Sales_Rep__c = : selectedRecordOwner';
        }

        if(String.isNotBlank(selectedObjectType) && selectedObjectType == 'Lead'){
        	if(String.isNotBlank(objectFilter.leadFilter.Status)){
        		filterString += ' and Status = \'' + String.escapeSingleQuotes(objectFilter.leadFilter.Status) + '\'';
        	}
        }else if(String.isNotBlank(selectedObjectType) && selectedObjectType == 'Account'){
        	filterString += ' and Local_Active__c = ' + objectFilter.accountFilter.Local_Active__c;
    	}else if(String.isNotBlank(selectedObjectType) && selectedObjectType == 'Opportunity'){
    		filterString += ' and IsClosed = ' + objectFilter.opportunityFilter.Is_Record_Locked__c;
    	}

        setCon = null;
        setCon.setPageNumber(1);
        populateSObject();
    }

    Public void populateSObject(){
        sobjectList = new List<SObject>();
        
        if(selectedRecordMap.isEmpty()){
            for(SObject a : (List<SObject>)setCon.getRecords()){
                sobjectList.add(a);
                selectedRecordMap.put(a.Id, false);
            }
        }else{
            for(SObject a : (List<SObject>)setCon.getRecords()){
                sobjectList.add(a);
            }
        }
    }

    public void saveNewOwner(){
        List<SObject> updateRecords = new List<SObject>();
        
        try{
            for(SObject record : (List<SObject>)setCon.getRecords()){
                if(selectedObjectType != 'Local_Sales_Rep_Assignment__c' && selectedRecordMap.get((Id)record.get('Id')) && String.isNotBlank(salesRepToAssign) && record.get('OwnerId') != salesRepToAssign){//} && !salesDevTeamIdList.contains(record.Sales_Developer__c)){
                    record.put('OwnerId', salesRepToAssign);
                    updateRecords.add(record);
                }else if(selectedObjectType == 'Local_Sales_Rep_Assignment__c' && selectedRecordMap.get((Id)record.get('Id')) && String.isNotBlank(salesRepToAssign) && record.get('Sales_Rep__c') != salesRepToAssign){
                	record.put('Sales_Rep__c', salesRepToAssign);
                }
            }
            update updateRecords;
            Integer currentPage = setCon.getPageNumber();
            setCon = null;
            setCon.setPageNumber(currentPage);
            populateSObject();
        }catch(Exception e){
            setCon = null;
            populateSObject();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()));
        }
    }

	public List<SelectOption> getObjectTypes(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Lead', 'Leads'));
    	options.add(new SelectOption('Account', 'Accounts'));
        options.add(new SelectOption('Opportunity', 'Winbacks'));
        options.add(new SelectOption('Local_Sales_Rep_Assignment__c', 'Local Sales Rep Assignment'));
        return options;
    }

    public List<SelectOption> getUserList(){
    	String userQuery = OWNER_QUERY;
    	//ownerActiveFilter = 'Inactive';
		//roleFilter = 'localAE';
		String userFilter = '';
    	if(String.isNotBlank(ownerActiveFilter)){
    		userFilter += ' and IsActive = ';
    		userFilter += (ownerActiveFilter == 'Active') ? true : false;
    	}
    	if(String.isNotBlank(roleFilter)){
    		userFilter += ' and UserRole.Name like' + '\'%Local Core Account Executive%\'';
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

    public List<SelectOption> getLocalSalesRepActive(){
    	String userQuery = OWNER_QUERY;
    	//ownerActiveFilter = 'Inactive';
		//roleFilter = 'localAE';
		String userFilter = ' and IsActive = true and UserRole.Name like' + '\'%Local Core Account Executive%\'';

    	userQuery = userQuery.replace('{customFilters}', userFilter);

    	List<SelectOption> options = new List<SelectOption>();
    	options.add(new SelectOption('', 'Select User to Assign'));
    	for(User record : Database.query(userQuery)){
    		String displayName = (String.isNotBlank(record.FirstName)) ? record.FirstName : '';
    		displayName += (String.isNotBlank(displayName)) ? ' ' + record.LastName : record.LastName;
    		displayName += (String.IsNotBlank(record.SalesRepID__c)) ? ' - ' + record.SalesRepID__c : '';
    		options.add(new SelectOption(record.Id, displayName));
    	}
    	return options;
    }

    public List<SelectOption> getActiveType(){
    	List<SelectOption> options = new List<SelectOption>();
    	options.add(new SelectOption('', 'All Record Owner'));
    	options.add(new SelectOption('Active', 'Active Owners Only'));
    	options.add(new SelectOption('Inactive', 'Inactive Owners Only'));
    	return options;
    }

    public List<SelectOption> getLocalAEOnly(){
    	List<SelectOption> options = new List<SelectOption>();
    	options.add(new SelectOption('', 'All User Roles'));
    	options.add(new SelectOption('localAE', 'Local Core Account Executive Role'));
    	return options;
    }

    public List<SelectOption> getResultSizeOptions(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('10', '10'));
    	options.add(new SelectOption('25', '25'));
        options.add(new SelectOption('100', '100'));
        options.add(new SelectOption('500', '500'));
        return options;
    }

    public List<SelectOption> getLeadStatusValues(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', 'All Lead Status'));
    	options.add(new SelectOption('Open', 'Open'));
        options.add(new SelectOption('Qualified', 'Qualified'));
        options.add(new SelectOption('Disqualified', 'Disqualified'));
        return options;
    }

    public void reRenderPanel(){
    	selectedRecordOwner = '';
    }

    public Boolean hasNext {
        get {
            return setCon.getHasNext();
        }
        set;
    }
    public Boolean hasPrevious {
        get {
            return setCon.getHasPrevious();
        }
        set;
    }
  
    public Integer pageNumber {
        get {
            return setCon.getPageNumber();
        }
        set;
    }
  
    public void first() {
		try{
			setCon.first();
            selectedRecordMap = new Map<Id, Boolean>();
            populateSObject();
		} catch(Exception e){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, e.getMessage()));
		}
    }
  
    public void last() {
		try{
			setCon.last();
            selectedRecordMap = new Map<Id, Boolean>();
            populateSObject();
		} catch(Exception e){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, e.getMessage()));
		}
    }
  
    public void previous() {
		try{
			setCon.previous();
            selectedRecordMap = new Map<Id, Boolean>();
            populateSObject();
		} catch(Exception e){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, e.getMessage()));
		}
    }
  
    public void next() {
		try{
			setCon.next();
            selectedRecordMap = new Map<Id, Boolean>();
            populateSObject();
		} catch(Exception e){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, e.getMessage()));
		}
    }

    public class ExtraObjectFilter{
    	public Account accountFilter {get; set;}
    	public Lead leadFilter {get; set;}
    	public Opportunity opportunityFilter {get; set;}

    	public ExtraObjectFilter(){
    		accountFilter = new Account();
    		accountFilter.Local_Active__c = true;
    		accountFilter.RecordTypeId = [select Id from RecordType where Name = 'Local' and SobjectType = 'Account' limit 1].Id;
    		leadFilter = new Lead();
    		leadFilter.RecordTypeId = [select Id from RecordType where DeveloperName = 'Local' and SobjectType = 'Lead' limit 1].Id;
    		leadFilter.Status = '';
    		opportunityFilter = new Opportunity();
    	}
    }

}