public class VendorLookupController {
  /////////////////////////
  // FRONT END VARIABLES //
  /////////////////////////
  public List<Account> vendorList {get; set;}
	public Boolean haveResult {get; set;}
  public String currentSortField {get; set;}
  public String currentDirection {get; set;}

  ///////////////////////
  // PRIVATE VARIABLES //
  ///////////////////////
  private Set<String> accIdSet;
  private String accId;
  // private String productLine;

  // Query string for querying Account locations
  private static final String ACCOUNT_LOCATION_QUERY = 'SELECT '
                                                        + 'Id, '
                                                        + 'Name, '
                                                        + 'ParentId, '
                                                        + 'Ignore_Parent_Account__c, '
                                                        + 'DynamicsAccID__c, '
                                                        + 'Primary_Category__r.Name, '
                                                        + 'Local_Sales_Market__r.Name, '
                                                        + 'Fulfilled__c'
                                                      + ' FROM '
                                                        + ' Account '
                                                      + '{WHERECLAUSE}';

	public VendorLookupController(){
		accIdSet = new Set<String>();
		accId = System.currentPageReference().getParameters().get('accId');
    // productLine = System.currentPageReference().getParameters().get('productLine');
		if(accId != null && accId != ''){
			accIdSet.add(accId);
    }

    // Default Sort Field and Direction on page load
    currentSortField = 'Name';
    currentDirection = 'asc';
		
  	search();
    if(!vendorList.isEmpty()){
      haveResult = True;  
    }
	}

  public PageReference serverSort() {
    // Get the parameters sent to the ActionFunction on the front end
    String fieldName = ApexPages.CurrentPage().getParameters().get('fieldname');
    String sortDirection = ApexPages.CurrentPage().getParameters().get('sortdirection');


    if(String.isNotBlank(fieldName)) {
      currentSortField = fieldName;
    }

    if(String.isNotBlank(sortDirection)) {
      currentDirection = sortDirection;
    }

    // When doing a search initiated from the front end the sort direction needs to be reversed to the opposite direction
    // that was sent. The direction sent from front end is the CURRENT sort direction.
    currentDirection = currentDirection == 'asc' ? 'desc' : 'asc';

    search();

    return null;
  }
	
	public PageReference search() {

  	vendorList = performSearch();
  	
  	if(vendorList!= null){
  		String parentAccId = '';
  		for(Account acc : vendorList){
  			if(acc.id == accId && acc.ParentId != null && acc.Ignore_Parent_Account__c == false) {
  				parentAccId = acc.ParentId;
        }
  			
  		}
  		if(parentAccId != null && parentAccId != ''){
  			accIdSet.add(parentAccId);
  			vendorList = performSearch();
  		}
  	}
  	return null;
  }

	private List<Account> performSearch() {
    if(accIdSet.size() < 1) {
      return null;
    }

		String soql = ACCOUNT_LOCATION_QUERY.replace('{WHERECLAUSE}', 'WHERE (Id = :accIdSet OR ParentId = :accIdSet)');
    // CSP-1475 Allow Sorting
    soql += ' ORDER BY ' + currentSortField + ' ' + currentDirection;

    return database.query(soql);
	}

  public string getFormTag() {
    return System.currentPageReference().getParameters().get('frm');
  }
  
  public string getTextBox() {
    return System.currentPageReference().getParameters().get('txt');
  }
}