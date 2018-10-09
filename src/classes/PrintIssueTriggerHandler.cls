public with sharing class PrintIssueTriggerHandler {
	public static void SetDateDefaults(List<Print_Issue__c> printIssues)
	{
		// get all of the custom setting date offsets
		Map<string, Print_Issue_Date_Offset__c> dateOffsets = Print_Issue_Date_Offset__c.getAll();
		
		List<Print_Issue__c> previousYearIssues = new List<Print_Issue__c>();
		List<Id> previousYearIssueIds = new List<Id>();
		
		// first, get the list of previousYearIssue Ids we may need.  These are any Print Issues that don't have a Selling Start date and also have a previous year issue defined.
		for (Print_Issue__c PI : printIssues)
		{
			// selling start date is dependent on the PREVIOUS YEAR's data
			if (PI.Selling_Start_Date__c == null)
			{
				if(PI.Previous_Years_Issue__c == null)
				{
					PI.Selling_Start_Date__c.AddError('Because the Previous Year\'s Issue was not specified, you must enter a Selling Start Date');
				}
				else
				{
					previousYearIssueIds.add(PI.Previous_Years_Issue__c);
				}
			}
		}
		
		// get the needed previous year's issues from the db
		if (previousYearIssueIds.size() > 0)
		{
			previousYearIssues = [select Id, Step_3__c from Print_Issue__c where id =:previousYearIssueIDs];
		}
		
		
		// if any of the various publication schedule dates are empty, set them based on the publication date
		// loop over the Print Issues being saved
		for (Print_Issue__c PI : printIssues)
		{
			// loop through the Custom Settings where the offsets are defined
			for (Print_Issue_Date_Offset__c dateOffset : dateOffsets.values())
			{
				Date tmp = (Date)PI.get(dateOffset.Name);
				// only override the null values
				if (tmp == null)
				{
					// add the days defined in the offset
					PI.put(dateOffset.Name, PI.Publish_1st_Cover_Ship__c.addDays((integer)dateOffset.Offset_in_Days__c));
				}
			}

			/* Selling Start and End Dates */
			// selling start date is dependent on the PREVIOUS YEAR's data
			if (PI.Selling_Start_Date__c == null)
			{
				// we added the error above if needed, no need to check again	
				if(PI.Previous_Years_Issue__c != null)
				{
					for (Print_Issue__c lastYearsIssue : previousYearIssues)
					{
						if (lastYearsIssue.Id == PI.Previous_Years_Issue__c)
						{
							PI.Selling_Start_Date__c = lastYearsIssue.Step_5__c.addDays(1);
							break;
						}
					}
				} 
			}
			
			// selling end date is equal to step 5 if not specified
			if (PI.Selling_End_Date__c == null)
			{
				PI.Selling_End_Date__c = PI.Step_5__c;
			}
		}
		
		
	}
	
	// assigns a 'Print Issue' name and overrides anything the user entered
	public static void SetNamingConvention(List<Print_Issue__c> printIssues)
	{
		// we need data from the related Editions
		Map<Id, Market__c> marketMap = new Map<id, Market__c>();
		List<Id> marketIds = new List<Id>();
		Map<Id, Edition__c> editionsMap = new Map<Id, Edition__c>();
		List<Id> editionIds = new List<Id>();
		
		// get the list of Edition Ids and Markets
		for (Print_Issue__c PI : printIssues)
		{
			editionIds.add(PI.Edition__c);
			marketIds.add(PI.Print_Market__c);
		}
		
		if (editionIds.size() > 0)
		{
			editionsMap = new Map<Id, Edition__c>([Select Id, Name, Short_Name__c, Publication__c, Publication__r.Name, Publication__r.Short_Name__c from Edition__c where Id = :editionIds]);
		}
		
		if (marketIds.size() > 0)
		{
			marketMap = new Map<Id, Market__c>([Select Id, Name from Market__c where Id = :marketIds]);
		}
		
		
		// we also need editions
		
		
		for (Print_Issue__c PI : printIssues)
		{
			if (!PI.Allow_Custom_Name__c)
			{
				PI.Name = editionsMap.get(PI.Edition__c).Publication__r.Name + ' ' + marketMap.get(PI.Print_Market__c).Name + ' ' + editionsMap.get(PI.Edition__c).Name;
				PI.Short_Name__c = editionsMap.get(PI.Edition__c).Publication__r.Short_Name__c + ' ' + marketMap.get(PI.Print_Market__c).Name + ' ' + editionsMap.get(PI.Edition__c).Short_Name__c;
			}
		}
	}
}