// This file was updated as part of the Zuora Managed Package upgrade. Referencees to ZProducts were updated to Product2
// Updated by - Ruchit S

public without sharing class WaitlistManagementController extends PageControllerBase{
	public string FilterProduct {get;set;}
	public string FilterAvailable {get;set;}
	public string FilterCategory {get;set;}
	public string FilterMarket {get;set;}
	
	public integer getMaximumQueryOrOffsetSize()
	{
		return maximumQueryOrOffsetSize;
	}
	
	private integer maximumQueryOrOffsetSize = 2000;
	
	private transient List<Product2> productData = new List<Product2>();
	private transient List<Category__c> categoryData = new List<Category__c>();
	private transient List<Market__c> marketData = new List<Market__c>();
	public List<SelectOption> searchableProducts {get;set;}{searchableProducts = new List<SelectOption>();}
	public List<SelectOption> categories {get;set;}{categories = new List<SelectOption>();}
	public List<SelectOption> markets {get;set;}{markets = new List<SelectOption>();}
	
	// pagination
	private integer counter=0;  //keeps track of the offset
	public integer list_size=20; //sets the page size or number of rows
   	public integer total_size; //used to show user the total size of the list
   	public integer previous_total_size = 0;
   	
   	public boolean ShowModal {get;set;}{ShowModal = false;}
   	
   	private transient List<zqu__ProductRatePlan__c> ProductRatePlans = new List<zqu__ProductRatePlan__c>();
	/* 
	 * Begin MODAL WAITLIST CODE
   	 * This section is needed in order to control the modal window.  Keep in mind this only works if you extend this class with PageControllerBase 
   	 */
   	 
   	public String SelectedRatePlanIdForWaitlistModal {get;set;} {SelectedRatePlanIdForWaitlistModal = '';}
   	public void ViewWaitlist()
   	{
   		myWaitlistModalController.OpenModal(SelectedRatePlanIdForWaitlistModal);
   	}
   	
   	public WaitlistModalController myWaitlistModalController {get;set;}
   	
   	public override void setComponentController(ComponentControllerBase compController) {
	    myWaitlistModalController = (WaitlistModalController)compController;
	}

	public override ComponentControllerBase getMyComponentController() {
	    return myWaitlistModalController;
	}
   	/* 
   	 * End MODAL WAITLIST CODE 
   	 */

	public WaitlistManagementController()
	{
		System.Debug('making a new rate plan');
		
		// get all the rate plans that have inventory controllers
		productData = [Select Id, Name
					   from Product2
					   where zqu__Deleted__c = false	 
					   and Rate_Plans_With_Capacity__c > 0
					   order by Name asc];

		System.debug(LoggingLevel.INFO, '*** FilterProduct: ' + FilterProduct);

		marketData = [Select Id, Name, Short_Description__c
					  from Market__c
					  where Active__c = true];
					  
		categoryData = [Select Id, Name, Short_Description__c
					    from Category__c
					    where Active__c = true];
					  		
		Map<Id, String> inventoryControlledProductMap = new Map<Id, String>();
		Map<String, String> inventoryControlledCategoryMap = new Map<String, String>();
		Map<String, String> inventoryControlledMarketMap = new Map<String, String>();
		
		//searchableProducts = new List<SelectOption>();
		searchableProducts.add(new SelectOption('','--None--'));
		categories.add(new SelectOption('','--None--'));
		markets.add(new SelectOption('','--None--'));
		
		for (Product2 eachProductItem : productData)
		{
			if (!inventoryControlledProductMap.containsKey(eachProductItem.Id))
			{
				inventoryControlledProductMap.put(eachProductItem.Id, eachProductItem.Name);
				searchableProducts.add(new SelectOption(eachProductItem.Id, eachProductItem.Name));
			}			
		}
		
		for (Category__c c : categoryData)
		{
			if (!inventoryControlledCategoryMap.containsKey(c.Short_Description__c))
			{
				inventoryControlledCategoryMap.put(c.Short_Description__c, c.Short_Description__c);
				categories.add(new SelectOption(c.Short_Description__c, c.Short_Description__c));								
			}
		}

		for (Market__c m : marketData)
		{
			if (!inventoryControlledMarketMap.containsKey(m.Short_Description__c))
			{
				inventoryControlledMarketMap.put(m.Short_Description__c, m.Short_Description__c);
				markets.add(new SelectOption(m.Short_Description__c, m.Short_Description__c));								
			}
		}

		// CSP-516 | sort the Market and Category dropdowns by alphabetical order
		categories.sort();
		markets.sort();
	}


	public List<zqu__ProductRatePlan__c> getProductRatePlans()
	{
		ProductRatePlans = new List<zqu__ProductRatePlan__c>();
		//string soql = '';
		string soql = 'Select Id, Name, Available__c, Capacity__c, Inventory_Held__c, Number_Available__c, Next_Inventory_Available__c, Waitlist_Count__c, Market__c, Category__c, zqu__Product__r.Name, zqu__Product__c';
		string soqlCount = 'select count()';
		string soqlFromWhere = ' from zqu__ProductRatePlan__c where Is_Inventory_Managed__c = true and zqu__Deleted__c = false and Is_Expired__c = false';
		
		if (FilterProduct != null && FilterProduct != '')
		{
			//soqlFromWhere += ' and zqu__ZProduct__c = \'' + FilterProduct + '\'';
			soqlFromWhere += ' and zqu__Product__c = \'' + FilterProduct + '\'';

		}
		
		if (FilterCategory != null && FilterCategory != '')
		{
			soqlFromWhere += ' and Category__c = \'' + string.escapeSingleQuotes(FilterCategory) + '\'';
		}

		if (FilterMarket != null && FilterMarket != '')
		{
			soqlFromWhere += ' and Market__c = \'' + string.escapeSingleQuotes(FilterMarket) + '\'';
		}
		
		if (FilterAvailable != null && FilterAvailable != '')
		{
			soqlFromWhere += ' and Available__c = ' + string.escapeSingleQuotes(FilterAvailable) ;
		}
		
		soqlCount += soqlFromWhere;
		soqlCount += ' limit ' + maximumQueryOrOffsetSize;
		System.Debug(soqlCount);
		
		total_size = database.countquery(soqlCount);
		if (total_size != previous_total_size)
		{
			counter = 0;
		}
		previous_total_size = total_size;

		soql += soqlFromWhere;
		soql += ' limit ' + list_size;
		soql += ' offset ' + TheCounter;

		ProductRatePlans = database.query(soql);
		System.Debug('Found rate plans: ' + ProductRatePlans.size());
		
		// get the first avaialable date for each unavailable inventory
		Map<ID, Date> nextAvailableMap = new Map<Id, Date>();
		for (zqu__ProductRatePlan__c prp : ProductRatePlans)
		{
			if (!prp.Available__c)
			{
				if (!nextAvailableMap.ContainsKey(prp.Id))
				{
					nextAvailableMap.put(prp.Id, Date.newinstance(1900,1,1));
				}
			}
		}
		
		if (nextAvailableMap.size() > 0)
		{
			// get the inventory
			List<Inventory__c> inventory = [Select Id, Inventory_Hold_Expiry_Date__c, Product_Rate_Plan__c 
											from Inventory__c 
											where Product_Rate_Plan__c in :nextAvailableMap.keyset() 
											order by Product_Rate_Plan__c, Inventory_Hold_Expiry_Date__c asc];
			for (Inventory__c inv : inventory)
			{
				nextAvailableMap.put(inv.Product_Rate_Plan__c, inv.Inventory_Hold_Expiry_Date__c);
			}
		}
		
		for (zqu__ProductRatePlan__c prp : ProductRatePlans)
		{
			if (nextAvailableMap.containsKey(prp.Id))
			{
				prp.Next_Inventory_Available__c = nextAvailableMap.get(prp.Id);
			}
		}
				
		return ProductRatePlans;
	}
	
	
	public boolean getOkToDisplayList()
	{
		return ProductRatePlans.size() > 0;
	}
	
	
   public integer TheCounter
   {
   		get
   		{
   			return counter;
   		}
   		set
   		{
   			counter = value;
   			if (counter > maximumQueryOrOffsetSize)
   			{
   				counter = maximumQueryOrOffsetSize;
   			}
   		}
   }

   public PageReference Beginning() { //user clicked beginning
      TheCounter = 0;
      return null;
   }

   public PageReference Previous() { //user clicked previous button
      TheCounter -= list_size;
      return null;
   }

   public PageReference Next() { //user clicked next button
      TheCounter += list_size;
      return null;
   }

   public PageReference End() { //user clicked end
      TheCounter = total_size - math.mod(total_size, list_size);
      return null;
   }

   public Boolean getDisablePrevious() { 
      //this will disable the previous and beginning buttons
      if (TheCounter>0) return false; else return true;
   }

   public Boolean getDisableNext() { //this will disable the next and end buttons
      if (TheCounter + list_size < total_size) return false; else return true;
   }

   public Integer getTotal_size() {
      return total_size;
   }

   public Integer getPageNumber() {
	  System.Debug(TheCounter);
	  System.Debug(list_size);
	  System.Debug(TheCounter/list_size);
      return TheCounter/list_size + 1;
   }

   public Integer getTotalPages() {
      if (math.mod(total_size, list_size) > 0) {
         return total_size/list_size + 1;
      } else {
         return (total_size/list_size);
      }
   }
}