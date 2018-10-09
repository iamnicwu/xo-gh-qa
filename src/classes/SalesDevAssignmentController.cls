public with sharing class SalesDevAssignmentController {
    public Integer noOfRecords {get; set;}
    public Integer size {get;set;}
    //public List<String> selectedList {get; set;}
    public FilterFields filterObject {get; set;}
    public Boolean onlyOpenTasks {get; set;}
    public String sortBy {get; set;}


    private static final String TSRFP_QUERY = 'Select Id, Name, Opportunity__c, Internal_Due_Date__c, Opportunity__r.OwnerId, Opportunity__r.Owner.Name, Opportunity__r.Name, Opportunity__r.StageName, Opportunity__r.Account.Name, Opportunity__r.AccountId, Account_Strategist__c, Account_Strategist__r.Name, Sales_Developer__c, RecordTypeId, CreatedDate, (select id from Tasks where isClosed = false and Owner.UserRole.DeveloperName = \'Sales_Development\') from ThoughtStarter_RFP__c where (Sales_Developer__c = null or Sales_Developer__c in : salesDevTeamIdList) and Opportunity__r.isClosed = false and Sales_Dev_Needed__c = true {customFilters} order by Sales_Developer__c Nulls First {sortBy}';
    private String filterString = '';
    private Set<Id> salesDevTeamIdList = new Set<Id>();
    private Set<Id> openTaskTSRFPIdSet = new Set<Id>();

    public SalesDevAssignmentController(ApexPages.StandardController controller) {
        filterObject = new FilterFields();
        onlyOpenTasks = true;
        sortBy = ', CreatedDate DESC';
        //selectedList = new List<String>();
        for(GroupMember record : [select UserOrGroupId from GroupMember where Group.DeveloperName = 'Sales_Dev_Team']){
	        salesDevTeamIdList.add(record.UserOrGroupId);
	    }
    }

    public List<SelectOption> getSortByList(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption(', CreatedDate ASC','Created Date Ascending'));
        options.add(new SelectOption(', CreatedDate DESC','Created Date Descending'));
        options.add(new SelectOption(', Internal_Due_Date__c ASC','Internal Due Date Ascending'));
        options.add(new SelectOption(', Internal_Due_Date__c DESC','Internal Due Date Descending'));
        return options;
    }

    public ApexPages.StandardSetController setCon {
        get{
            if(setCon == null){
                if(onlyOpenTasks){
                    string queryString = TSRFP_QUERY;
                    if(String.isBlank(filterString)){
                        queryString = queryString.replace('{customFilters}', '');
                    }else{
                        queryString = queryString.replace('{customFilters}', filterString);
                    }
                    queryString = queryString.replace('{sortBy}', sortBy);
                    for(ThoughtStarter_RFP__c record : Database.query(queryString)){
                        if(record.Tasks.size() > 0){
                            openTaskTSRFPIdSet.add(record.Id);
                        }
                    }
                    filterString += ' and Id IN : openTaskTSRFPIdSet';
                }

                size = 25;
                string queryString = TSRFP_QUERY;
                if(String.isBlank(filterString)){
                    queryString = queryString.replace('{customFilters}', '');
                }else{
                    queryString = queryString.replace('{customFilters}', filterString);
                }
                queryString = queryString.replace('{sortBy}', sortBy);
                setCon = new ApexPages.StandardSetController(Database.getQueryLocator(queryString));
                setCon.setPageSize(size);
                noOfRecords = setCon.getResultSize();
            }
            return setCon;
        }set;
    }

    public void filterResults(){
        filterString = '';
        if(String.isNotBlank(filterObject.recordType)){
            filterString += ' and RecordType.Name LIKE \'%' + String.escapeSingleQuotes(filterObject.recordType) + '%\'';
        }
        if(String.isNotBlank(filterObject.nameValues)){
            filterString += ' and (Opportunity__r.Account.Name LIKE \'%' + String.escapeSingleQuotes(filterObject.nameValues) + '%\' or Name LIKE \'%' + String.escapeSingleQuotes(filterObject.nameValues) + '%\' or Opportunity__r.Name LIKE \'%' + String.escapeSingleQuotes(filterObject.nameValues) + '%\')';
        }
        if(String.isNotBlank(filterObject.repStrat)){
            filterString += ' and (Opportunity__r.Owner.Name LIKE \'%' + String.escapeSingleQuotes(filterObject.repStrat) + '%\' or Account_Strategist__r.Name LIKE \'%' + String.escapeSingleQuotes(filterObject.repStrat) + '%\')';
        }
        if(String.isNotBlank(filterObject.salesDev)){
            filterString += ' and (Sales_Developer__r.Name LIKE \'%' + String.escapeSingleQuotes(filterObject.salesDev) + '%\' or Sales_Developer__c = null)';
        }

        /*if(onlyOpenTasks){
            string queryString = TSRFP_QUERY;
            if(String.isBlank(filterString)){
                queryString = queryString.replace('{customFilters}', '');
            }else{
                queryString = queryString.replace('{customFilters}', filterString);
            }
            for(ThoughtStarter_RFP__c record : Database.query(queryString)){
                if(record.Tasks.size() > 0){
                    openTaskTSRFPIdSet.add(record.Id);
                }
            }
            filterString += ' and Id IN : openTaskTSRFPIdSet';
        }*/


        setCon = null;
        getUnassignedTSRFP();
        setCon.setPageNumber(1);
    }
     
    Public List<ThoughtStarter_RFP__c> getUnassignedTSRFP(){
        List<ThoughtStarter_RFP__c> accList = new List<ThoughtStarter_RFP__c>();
        for(ThoughtStarter_RFP__c a : (List<ThoughtStarter_RFP__c>)setCon.getRecords())
            accList.add(a);
        return accList;
    }
     
    public pageReference refresh() {
        //selectedList = new List<String>();
        filterObject = new FilterFields();
        filterString = '';
        setCon = null;
        //getVenues();
        setCon.setPageNumber(1);
        return null;
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
        } catch(Exception e){
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, e.getMessage()));
    	}
    }
  
    public void last() {
        try{
        	setCon.last();
        } catch(Exception e){
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, e.getMessage()));
    	}
    }
  
    public void previous() {
    	try{
        	setCon.previous();
    	} catch(Exception e){
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, e.getMessage()));
    	}
    }
  
    public void next() {
    	try{
        	setCon.next();
    	} catch(Exception e){
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, e.getMessage()));
    	}
    }

    public void saveSalesDeveloper(){
        Map<Id, ThoughtStarter_RFP__c> idTSRFPOldValueMap = new Map<Id, ThoughtStarter_RFP__c>();
        for(ThoughtStarter_RFP__c record : [select Id, Sales_Developer__c from ThoughtStarter_RFP__c where Id IN : setCon.getRecords()]){
            idTSRFPOldValueMap.put(record.Id, record);
        }

    	List<ThoughtStarter_RFP__c> updateTSRFPList = new List<ThoughtStarter_RFP__c>();
    	for(ThoughtStarter_RFP__c record : (List<ThoughtStarter_RFP__c>)setCon.getRecords()){
    		if(String.isNotBlank(record.Sales_Developer__c) && record.Sales_Developer__c != idTSRFPOldValueMap.get(record.Id).Sales_Developer__c){//} && !salesDevTeamIdList.contains(record.Sales_Developer__c)){
    			updateTSRFPList.add(record);
    		}
    	}
    	try{
	        update updateTSRFPList;
	        refresh();
        }catch(Exception e){
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()));
        }
    }

    public class FilterFields{
        public String recordType {get; set;}
        public String nameValues {get; set;}
        public String repStrat {get; set;}
        public String salesDev {get; set;}

        public FilterFields(){
            recordType = '';
            nameValues = '';
            repStrat = '';
            salesDev = '';
        }
    }

}