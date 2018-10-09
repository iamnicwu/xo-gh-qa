public without sharing class DataUtility {
	////////////////////////////
	// STATIC FINAL VARIABLES //
	////////////////////////////
	// RegEx to find ONLY digits
	private static final Pattern ALL_DIGIT_PATTERN = Pattern.compile('(\\d+)');
	// RegEx to find only a valid URL at the end of a string(signified by the $ at the end of the RegEx)
	private static final Pattern WEBSITE_PATTERN = Pattern.compile('(www[.])??([a-zA-Z0-9]|-)+?([.][a-zA-Z0-9#(-|/|=|?)??]+?)+?$');
	// Protocol inclusion RegEx - (https?://)?(www[.])??([a-zA-Z0-9]|-)+?([.][a-zA-Z0-9#(-|/|=|?)??]+?)+?$

	/**
	 * 	 // CSP-3077 Update Automation on Account to fill in Market based on the first three digits of Canadian Zip Codes
	 *   Function used to get a picklist entry map from a picklist field.
	 *
	 *   @author Steven
	 *   @date   2018-09-07
	 *   @param  {String}           object API name
	 *   @param  {String}           picklist type field api name
	 *   @return {Map<String,String>}          map of picklist label and picklist value.
	 */
	public static Map<String,String> buildPicklistEntryMap(String objectAPIName, String picklistFieldAPIName) {
		Map<String,String> picklistLabelpicklistValueMap = new Map<String,String>();
		//get objectType 
		Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectAPIName); 
		
		//get field if objectType exists
		if(objectType != null){
			Schema.SobjectField pisklistField = objectType.getDescribe().fields.getMap().get(picklistFieldAPIName);
			//get picklist field result if pisklistField exists
			if(pisklistField != null){
				Schema.DescribeFieldResult fieldResult = pisklistField.getDescribe();
				//get field picklist entries
				List<Schema.PicklistEntry> picklistEntryList = fieldResult.getPicklistValues();
				
				//build field picklist label and picklist value map
				for(Schema.PicklistEntry picklistEntry : picklistEntryList){
					picklistLabelpicklistValueMap.put(picklistEntry.getLabel(), picklistEntry.getValue());
				}				
			}
		}
		
		return picklistLabelpicklistValueMap;
	}

	

	/**
	 *   Function used to validate if the passed String is considered "valid" based upon the RegEx in "WEBSITE_PATTERN".
	 *   Currently the RegEx ignores protocols(http, https, ftp, etc).
	 *
	 *   @author Justin
	 *   @date   2017-11-07
	 *   @param  {String}           strInput The string parameter to evaluate
	 *   @return {ValidationResult}          The result of the validation.
	 */
	public static ValidationResult validateWebsite(String strInput) {
		if(String.isBlank(strInput)) {
			return (new ValidationResult(false, strInput));
		}

		Matcher websiteMatcher = WEBSITE_PATTERN.matcher(strInput);
		if(!websiteMatcher.find()) {
			return (new ValidationResult(false, strInput));
		}

		websiteMatcher.reset();
		
		// Use RegEx to grab the valid portion of the website - this currently removes/ignores protocols
		String validWebsite = '';
		while(websiteMatcher.find()) {
			validWebsite += websiteMatcher.group();
		}

		return (new ValidationResult(true, validWebsite));
	}

	/**
	 *   Function used to strip all other characters from a provided String so that only digits/numbers remain
	 *
	 *   @author Justin
	 *   @date   2017-11-07
	 *   @param  {String}   strInput The parameter to remove all other characters except digits/numbers
	 *   @return {String}            The resulting String consisting of only digits/numbers or blank if none were present
	 */
	public static String getOnlyNumbers(String strInput) {
		String onlyNumbers = '';
		// If the String parameter is blank or null then return a blank string
		if(String.isBlank(strInput)) {
			return onlyNumbers;
		}

		// Create Matcher then loop through the input finding matches with the supplied Pattern
		Matcher allDigitMatcher = ALL_DIGIT_PATTERN.matcher(strInput);
		while(allDigitMatcher.find()) {
			onlyNumbers += allDigitMatcher.group();
		}

		return String.valueOf(onlyNumbers);
	}

	/**
	 *   Function used to format a number based upon a provided String. Format phone extension
	 *   
	 *
	 *   @author Nick
	 *   @date   2017-11-14
	 *   @param  {String}           strInput The parameter to validate, strip, and format
	 *   @return {ValidationResult}          The result of the validation
	 */
	public static ValidationResult formatExt(String strInput) {
		
		if(!String.isBlank(strInput) && !strInput.isNumeric()) {
			return (new ValidationResult(false, strInput));
		}
		else{
			return (new ValidationResult(true, strInput));
		}
	}

	/**
	 *   Function used to format a number based upon a provided String. The format is determined by the ticket CSP-2544 which
	 *   also means that there must be exactly 10 numbers present in the string when all other characters are removed.
	 *
	 *   @author Justin
	 *   @date   2017-11-07
	 *   @param  {String}           strInput The parameter to validate, strip, and format
	 *   @return {ValidationResult}          The result of the validation
	 */
	public static ValidationResult formatPhoneNumber(String strInput) {
		if(String.isBlank(strInput)) {
			return (new ValidationResult(false, strInput));
		}

		String onlyNumbers = getOnlyNumbers(strInput);
		// If there are no exactly 10 numbers after stripping out extra characters then it is not a valid number - CSP-2544
		if(onlyNumbers.length() != 10) {
			return (new ValidationResult(false, strInput));
		}

		// Format phone value to (###) ###-####, CSP-2544
		String formattedValue = '(' + onlyNumbers.substring(0, 3) + ')';
		formattedValue += ' ' + onlyNumbers.substring(3, 6) + '-';
		formattedValue += onlyNumbers.substring(6);

		return (new ValidationResult(true, formattedValue));
	}

	/**
	 *	 // CSP-3075 Update Automation on Lead to fill in Market based on Canadian Zip Codes
	 *   Function used to get default Canada local sales Market
	 *
	 *   @author Mason
	 *   @date   2018-08-29
	 *   @param  {String, String, Map<String,Market__c>}          
	 *   @return {Market__c}          The result of the Market__c record
	 */
		public static Market__c getDefaultCanadaMarket(String zipCode, String stateCode, Map<String, Market__c> marketIdObjMap, 
		Map<String, Canadian_Postal_Code_Market_Mapping__c> canadaMarketMap, Map<String, String> stateCodeMarketIdMap) {
		System.debug(LoggingLevel.INFO, '*** zipCode: ' + zipCode);
		System.debug(LoggingLevel.INFO, '*** stateCode: ' + stateCode);
		String marketId; 
		Market__c returnMarket;

		//According zip code to get defalut Market 
		if(string.isNotBlank(zipCode)) {
			//Where zip code first character is G or J or K. Use first 2 digit Zip Code to get market
			if((zipCode.left(1) == 'G' || zipCode.left(1) == 'J' || zipCode.left(1) == 'K')
				&& canadaMarketMap.containsKey(zipCode.left(2))) {

				marketId = canadaMarketMap.get(zipCode.left(2)).Market_Id__c;
				returnMarket = marketIdObjMap.get(marketId);
			}
			else if(canadaMarketMap.containsKey(zipCode.left(1))) {

				marketId = canadaMarketMap.get(zipCode.left(1)).Market_Id__c;
				returnMarket = marketIdObjMap.get(marketId);
			}
		}
		//According state code to get defalut Market if zipcode is null  
		else if(string.isNotBlank(stateCode)) {
				marketId = stateCodeMarketIdMap.get(stateCode);
				returnMarket = marketIdObjMap.get(marketId);
		}
		System.debug(LoggingLevel.INFO, '*** returnMarket : ' + returnMarket);
		return returnMarket;
  }

	public class ValidationResult {
		public Boolean valid;
		public String formattedValue;

		public ValidationResult(Boolean boolValid, String strFormattedValue) {
			valid = boolValid;
			formattedValue = strFormattedValue;
		}
	}
}