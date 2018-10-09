public with sharing class EditionTriggerHandler {
	// assigns a 'Print Issue' name and overrides anything the user entered
	public static void SetNamingConvention(List<Edition__c> editions)
	{
		for (Edition__c ED : editions)
		{
			if (!ED.Allow_Custom_Name__c)
			{
				// there are two naming conventions - either using Season or Edition.
				// if season is blank, use edition instead
				if (ED.Season__c != null)
				{
					ED.Name = ED.Season__c + ' ' + ED.Year__c;
					ED.Short_Name__c = getSeasonAbbreviation(ED.Season__c) + ' ' + ED.Year__c;
				}
				else
				{
					ED.Name = 'Volume ' + ED.Volume__c + ' Edition ' + ED.Edition__c;
					ED.Short_Name__c = 'Vol ' + ED.Volume__c + ' Ed ' + ED.Edition__c;
				}
			}
		}
	}
	
	private static string getSeasonAbbreviation(string season)
	{
		string retVal = season;
		
		if (season.Length() <= 2)
		{
			retVal = season;
		}
		if (season.contains('/') && season.indexOf('/') < season.Length())
		{
			retVal = season.Left(1) + season.Substring(season.indexOf('/') + 1, season.indexOf('/') + 2);
		}
		else
		{
			retVal = season.Left(2);
		}
		
		
		return retVal.ToUpperCase();
	}

}