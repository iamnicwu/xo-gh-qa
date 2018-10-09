public with sharing class LocalRenewalBookController {
	//public List<Zuora__Subscription__c> subscriptionList = new List<Zuora__Subscription__c>();
    public static Boolean renewalBookRunning = false;

    public Map<Id, Boolean> subSelectedMap {get; set;}
    public List<Zuora__Subscription__c> subscriptions {get; set;}

	public String resultSize {get; set;}
	public Integer noOfRecords {get; set;}
    public FilterFields filterObject {get; set;}
    public String sortBy {get; set;}
    public String ownerActiveFilter {get; set;}
    public String roleFilter {get; set;}

    private static final String OWNER_QUERY = 'select Id, SalesRepId__c, FirstName, LastName from User where Id != null {customFilters} order by FirstName';
    private static final String BASE_QUERY = 'select Id, Name, Zuora__Zuora_Id__c, Product_Line__c, Zuora__Account__c, Zuora__Account__r.Name, Zuora__Account__r.Local_Sales_Market__c, Zuora__Account__r.Primary_Category__c, Zuora__Account__r.BillingPostalCode, Sales_Rep__c, Renewal_Rep__c, Floater_Rep__c, RenewalRepId__c from Zuora__Subscription__c where Zuora__Status__c = \'Active\' {customFilters} order by {sortBy} limit 10000';
    private String filterString = '';

    public Zuora__Subscription__c newRepVariable {get; set;}
    public String salesRepToAssign {get; set;}

	public LocalRenewalBookController(ApexPages.StandardController controller) {
        subscriptions = new List<Zuora__Subscription__c>();
        newRepVariable = new Zuora__Subscription__c();
        salesRepToAssign = '';
		resultSize = String.valueof(25);
		filterObject = new FilterFields();
		sortBy = 'Name ASC';
        roleFilter = 'localAE';
        subSelectedMap = new Map<Id, Boolean>();

        populateSubscriptions();
        //filterObject.brandFilter = 

        //filterString += ' and Zuora__Account__r.Primary_Brand__c = \'' + String.escapeSingleQuotes(filterObject.marketCategoryFilter.Primary_Brand__c) + '\'';
	}

 	public ApexPages.StandardSetController setCon {
        get{
            if(setCon == null){
                string queryString = BASE_QUERY;
                if(String.isBlank(filterString)){
                    queryString = queryString.replace('{customFilters}', '');
                }else{
                    queryString = queryString.replace('{customFilters}', filterString);
                }
                queryString = queryString.replace('{sortBy}', sortBy);
                //queryString = queryString.replace('{resultSize}', resultSize);

                List<String> catFilterList = new List<String>();
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
                }


                setCon = new ApexPages.StandardSetController(Database.getQueryLocator(queryString));
                setCon.setPageSize(Integer.valueof(resultSize));
                noOfRecords = setCon.getResultSize();
            }
            return setCon;
        }set;
    }

    public void filterResults(){
        subSelectedMap = new Map<Id, Boolean>();
        filterString = '';
        // CSP-1999 
        // if(String.isNotBlank(filterObject.brandFilter)){
        //     filterString += ' and Zuora__Account__r.Primary_Brand__c = \'' + String.escapeSingleQuotes(filterObject.brandFilter) + '\'';
        // }
        if(!filterObject.marketFilter.isEmpty()){
            filterString += ' and Zuora__Account__r.Local_Sales_Market__c IN : mktFilterList';
        }
        if(!filterObject.categoryFilter.isEmpty()){
            filterString += ' and Zuora__Account__r.Primary_Category__c IN : catFilterList';
        }
        if(String.isNotBlank(filterObject.postalCodeSelected)){
            filterString += ' and Zuora__Account__r.BillingPostalCode LIKE \'' + String.escapeSingleQuotes(filterObject.postalCodeSelected) + '%\'';
        }

        if(String.isNotBlank(filterObject.subscriptionFilter.Sales_Rep__c)){
            filterString += ' and Sales_Rep__c = \'' + String.escapeSingleQuotes(filterObject.subscriptionFilter.Sales_Rep__c) + '\'';
        }
        if(String.isNotBlank(filterObject.subscriptionFilter.Renewal_Rep__c)){
            filterString += ' and Renewal_Rep__c = \'' + String.escapeSingleQuotes(filterObject.subscriptionFilter.Renewal_Rep__c) + '\'';
        }
        if(String.isNotBlank(filterObject.productLineFilter.Product_Line__c)){
            filterString += ' and Product_Line__c = \'' + String.escapeSingleQuotes(filterObject.productLineFilter.Product_Line__c) + '\'';
        }


        setCon = null;
        setCon.setPageNumber(1);
        populateSubscriptions();
    }

    public void brandFilterFunction(){
        filterObject.categoryFilter = new List<SelectOption>();
        filterObject.marketFilter = new List<SelectOption>();
        filterResults();
    }

    Public void populateSubscriptions(){
        List<Zuora__Subscription__c> subscriptionList = new List<Zuora__Subscription__c>();
        
        if(subSelectedMap.isEmpty()){
            for(Zuora__Subscription__c a : (List<Zuora__Subscription__c>)setCon.getRecords()){
                subscriptionList.add(a);
                subSelectedMap.put(a.Id, false);
            }
        }else{
            for(Zuora__Subscription__c a : (List<Zuora__Subscription__c>)setCon.getRecords()){
                subscriptionList.add(a);
            }
        }
        subscriptions = subscriptionList;
    }
     
    public pageReference refresh() {
        //selectedList = new List<String>();
        subSelectedMap = new Map<Id, Boolean>();
        filterObject = new FilterFields();
        filterString = '';
        setCon = null;
        sortBy = 'Name ASC';
        //getVenues();
        setCon.setPageNumber(1);
        populateSubscriptions();
        return null;
    }

    public void saveRenewalRep(){
        renewalBookRunning = true;
        List<Zuora__Subscription__c> updateSubList = new List<Zuora__Subscription__c>();
        List<String> zuoraIdList = new List<String>();
        
        try{
            for(Zuora__Subscription__c record : (List<Zuora__Subscription__c>)setCon.getRecords()){
                if(subSelectedMap.get(record.Id) && String.isNotBlank(salesRepToAssign) && salesRepToAssign != record.Renewal_Rep__c){//} && !salesDevTeamIdList.contains(record.Sales_Developer__c)){
                    record.Renewal_Rep__c = salesRepToAssign;
                    updateSubList.add(record);
                    zuoraIdList.add(record.Zuora__Zuora_Id__c);
                }
            }
            String repId = [select Id, SalesRepId__c from User where Id =: salesRepToAssign].SalesRepId__c;
            updateSubscription(zuoraIdList, repId, 'renewalRep');
            update updateSubList;
            Integer currentPage = setCon.getPageNumber();
            setCon = null;
            setCon.setPageNumber(currentPage);
            subSelectedMap.clear();
            populateSubscriptions();
        }catch(Exception e){
            setCon = null;
            populateSubscriptions();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()));
        }
        renewalBookRunning = false;
    }

    public void saveFloaterRep(){
        renewalBookRunning = true;
        List<Zuora__Subscription__c> updateSubList = new List<Zuora__Subscription__c>();
        List<String> zuoraIdList = new List<String>();
        
        try{
            for(Zuora__Subscription__c record : (List<Zuora__Subscription__c>)setCon.getRecords()){
                if(subSelectedMap.get(record.Id) && String.isNotBlank(salesRepToAssign) && salesRepToAssign != record.Floater_Rep__c){//} && !salesDevTeamIdList.contains(record.Sales_Developer__c)){
                    record.Floater_Rep__c = salesRepToAssign;
                    updateSubList.add(record);
                    zuoraIdList.add(record.Zuora__Zuora_Id__c);
                }
            }
            String repId = [select Id, SalesRepId__c from User where Id =: salesRepToAssign].SalesRepId__c;
            updateSubscription(zuoraIdList, repId, 'floaterRep');
            update updateSubList;
            Integer currentPage = setCon.getPageNumber();
            setCon = null;
            setCon.setPageNumber(currentPage);
            subSelectedMap.clear();
            populateSubscriptions();
        }catch(Exception e){
            setCon = null;
            populateSubscriptions();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()));
        }
        renewalBookRunning = false;
    }

    //@future(callout=true)
    private static void updateSubscription(List<String> zuoraIdList, String repId, String changeType){

        for(Integer x = 0; x <= zuoraIdList.size() / 50; x++){
            List<Zuora.zObject> zuoraZObjectList = new List<Zuora.zObject>();

            for(Integer y = (x * 50); y < 50 + (x * 50); y++){
                if(y > zuoraIdList.size()-1){
                    break;
                }
                Zuora.zObject sub = new Zuora.zObject('Subscription');
                sub.setValue('Id',zuoraIdList[y]);
                if(changeType == 'renewalRep'){
                    sub.setValue('RenewalRepId__c', repId);
                }else if(changeType == 'floaterRep'){
                    sub.setValue('FloaterRepID__c', repId);
                }
                //sub.setValue('Product_Line__c', 'Internet');
                zuoraZObjectList.add(sub);
            }

            if(!zuoraZObjectList.isEmpty()){
                Zuora.ZApi zApiInstance = new Zuora.ZApi();
                // skip the login call if this is a test
                if (!Test.isRunningTest()) {
                    Zuora.zApi.LoginResult loginResult = zApiInstance.zlogin();
                }

                List<Zuora.zApi.SaveResult> results = new List<Zuora.zApi.SaveResult>();

                if (!Test.isRunningTest()) {
                    // callout method documention is here: https://knowledgecenter.zuora.com/CA_Commerce/E_Development_Resources/B_Order_Builder/D_Programming_with_Order_Builder
                    results.addAll(zApiInstance.zupdate(zuoraZObjectList));
                }

                if (Test.isRunningTest()) {
                    // test Sucess
                    Zuora.zApi.SaveResult testSuccessSalesResult = new Zuora.zApi.SaveResult();
                    testSuccessSalesResult.Success = True;
                    results.add(testSuccessSalesResult);
                    // test Failure
                    Zuora.zApi.SaveResult testFailSalesResult = new Zuora.zApi.SaveResult();
                    testFailSalesResult.Success = False;
                    results.add(testSuccessSalesResult);
                }
               
                for (Zuora.zApi.SaveResult result : results) {
                    if (result.Success){
                        // if success, clear the "need to update" flag on the Subscription,
                        // then add the Subscription to the zuoraSubUpdateList
                        system.debug('success');
                    }else{
                        //failure, get the errors
                        System.debug('CALLOUT FAILED');
                        Zuora.zObject[] errors = result.errors;
                        for (Zuora.zObject error : errors) {
                            String errorCode = (String)error.getValue('Code');
                            String message = (String)error.getValue('Message');
                            System.debug(errorCode + ' ' + message);
                        }
                        throw new ApplicationException('Callout Failed');
                    }
                }
            }
        }

        /*List<Zuora.zObject> zuoraZObjectList = new List<Zuora.zObject>();

        for(String record : zuoraIdList){
            Zuora.zObject sub = new Zuora.zObject('Subscription');
            sub.setValue('Id',record);
            sub.setValue('RenewalRepId__c', repId);
            //sub.setValue('Product_Line__c', 'Internet');
            zuoraZObjectList.add(sub);
        }

        Zuora.ZApi zApiInstance = new Zuora.ZApi();
        // skip the login call if this is a test
        if (!Test.isRunningTest()) {
            Zuora.zApi.LoginResult loginResult = zApiInstance.zlogin();
        }

        List<Zuora.zApi.SaveResult> results = new List<Zuora.zApi.SaveResult>();

        if (!Test.isRunningTest()) {
            // callout method documention is here: https://knowledgecenter.zuora.com/CA_Commerce/E_Development_Resources/B_Order_Builder/D_Programming_with_Order_Builder
            results.addAll(zApiInstance.zupdate(zuoraZObjectList));
        }

        if (Test.isRunningTest()) {
            // test Sucess
            Zuora.zApi.SaveResult testSuccessSalesResult = new Zuora.zApi.SaveResult();
            testSuccessSalesResult.Success = True;
            results.add(testSuccessSalesResult);
            // test Failure
            Zuora.zApi.SaveResult testFailSalesResult = new Zuora.zApi.SaveResult();
            testFailSalesResult.Success = False;
            results.add(testSuccessSalesResult);
        }
       
        for (Zuora.zApi.SaveResult result : results) {
            if (result.Success){
                // if success, clear the "need to update" flag on the Subscription,
                // then add the Subscription to the zuoraSubUpdateList
                system.debug('success');
            }else{
                //failure, get the errors
                System.debug('CALLOUT FAILED');
                Zuora.zObject[] errors = result.errors;
                for (Zuora.zObject error : errors) {
                    String errorCode = (String)error.getValue('Code');
                    String message = (String)error.getValue('Message');
                    System.debug(errorCode + ' ' + message);
                }
                throw new ApplicationException('Callout Failed');
            }
        }*/
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
            subSelectedMap = new Map<Id, Boolean>();
            populateSubscriptions();
		} catch(Exception e){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, e.getMessage()));
		}
    }
  
    public void last() {
		try{
			setCon.last();
            subSelectedMap = new Map<Id, Boolean>();
            populateSubscriptions();
		} catch(Exception e){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, e.getMessage()));
		}
    }
  
    public void previous() {
		try{
			setCon.previous();
            subSelectedMap = new Map<Id, Boolean>();
            populateSubscriptions();
		} catch(Exception e){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, e.getMessage()));
		}
    }
  
    public void next() {
		try{
			setCon.next();
            subSelectedMap = new Map<Id, Boolean>();
            populateSubscriptions();
		} catch(Exception e){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, e.getMessage()));
		}
    }

	public List<SelectOption> getResultSizeOptions(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('10', '10'));
    	options.add(new SelectOption('25', '25'));
        options.add(new SelectOption('100', '100'));
        options.add(new SelectOption('500', '500'));
        return options;
    }

    public List<SelectOption> getBrandOptions(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', 'Selet a Brand'));
        // CSP-1999 
        // for(Brand__c record  : [select Id, Name, Division__c from Brand__c where Active__c = true order by Name]){
        //     options.add(new SelectOption(record.Id, record.Division__c + ' - ' + record.Name));
        // }
        return options;
    }

    public List<SelectOption> getCategoryOptions(){
        List<SelectOption> options = new List<SelectOption>();
        // CSP-1999 
        // for(Category__c record  : [select Id, Name from Category__c where Active__c = true and Primary_Brand__c =: filterObject.brandFilter order by Name]){
        for(Category__c record  : [select Id, Name from Category__c where Active__c = true  order by Name]){
            options.add(new SelectOption(record.Id, record.Name));
        }
        return options;
    }

    public List<SelectOption> getMarketOptions(){
        List<SelectOption> options = new List<SelectOption>();
        // CSP-1999 
        // for(Market__c record  : [select Id, Name from Market__c where Active__c = true and Local_Sales_Region__r.Primary_Brand__c =: filterObject.brandFilter order by Name]){
        for(Market__c record  : [select Id, Name from Market__c where Active__c = true order by Name]){
            options.add(new SelectOption(record.Id, record.Name));
        }
        return options;
    }

    public List<SelectOption> getSortByList(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Name ASC','Subscription Name Ascending'));
        options.add(new SelectOption('Name DESC','Subscription Name Descending'));
        options.add(new SelectOption('Product_Line__c ASC','Product Line Ascending'));
        options.add(new SelectOption('Product_Line__c DESC','Product Line Descending'));
        options.add(new SelectOption('Zuora__Account__r.Name ASC','Account Name Ascending'));
        options.add(new SelectOption('Zuora__Account__r.Name DESC','Account Name Descending'));
        options.add(new SelectOption('Zuora__Account__r.Primary_Category__c ASC','Primary Category Ascending'));
        options.add(new SelectOption('Zuora__Account__r.Primary_Category__c DESC','Primary Category Descending'));
        options.add(new SelectOption('Zuora__Account__r.Local_Sales_Market__c ASC','Local Sales Market Ascending'));
        options.add(new SelectOption('Zuora__Account__r.Local_Sales_Market__c DESC','Local Sales Market Descending'));
        options.add(new SelectOption('Zuora__Account__r.BillingPostalCode ASC','Billing Zip/Postal Code Ascending'));
        options.add(new SelectOption('Zuora__Account__r.BillingPostalCode DESC','Billing Zip/Postal Code Descending'));
        options.add(new SelectOption('Sales_Rep__c ASC','Original Rep Ascending'));
        options.add(new SelectOption('Sales_Rep__c DESC','Original Rep Descending'));
        options.add(new SelectOption('Renewal_Rep__c ASC','Renewal Rep Ascending'));
        options.add(new SelectOption('Renewal_Rep__c DESC','Renewal Rep Descending'));
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
        options.add(new SelectOption('', 'Select Sales Rep'));
        for(User record : Database.query(userQuery)){
            String displayName = (String.isNotBlank(record.FirstName)) ? record.FirstName : '';
            displayName += (String.isNotBlank(displayName)) ? ' ' + record.LastName : record.LastName;
            displayName += (String.IsNotBlank(record.SalesRepID__c)) ? ' - ' + record.SalesRepID__c : '';
            options.add(new SelectOption(record.Id, displayName));
        }
        return options;
    }

    public List<SelectOption> getUserRenewalList(){
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
        options.add(new SelectOption('', 'Select Renewal Rep'));
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
        options.add(new SelectOption('', 'All Users'));
        options.add(new SelectOption('Active', 'Active Users Only'));
        options.add(new SelectOption('Inactive', 'Inactive Users Only'));
        return options;
    }

    public List<SelectOption> getLocalAEOnly(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', 'All User Roles'));
        options.add(new SelectOption('localAE', 'Local Core Account Executive Role'));
        return options;
    }

    public void reRenderPanel(){
        filterObject.subscriptionFilter.Sales_Rep__c = null;
        filterObject.subscriptionFilter.Renewal_Rep__c = null;
        filterResults();
        //selectedRecordOwner = '';
    }

	public class FilterFields{
		//public String marketFilter {get; set;}
		//public String categoryFilter {get; set;}
        public String brandFilter {get; set;}
        public List<SelectOption> categoryFilter {get; set;}
        public List<SelectOption> marketFilter {get; set;}
        public String postalCodeSelected {get; set;}

		public Zuora__Subscription__c subscriptionFilter {get; set;}
        public zqu__Quote__c productLineFilter {get; set;}

		public FilterFields(){
            brandFilter = '';
            categoryFilter = new List<SelectOption>();
            marketFilter = new List<SelectOption>();

			subscriptionFilter = new Zuora__Subscription__c();
            productLineFilter = new zqu__Quote__c();
		}
	}
}